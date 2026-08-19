-- Tiermetry V1 asset-failure recovery.
-- The owner reports physical asset state. This migration makes the booking
-- consequence, replacement selection, credit calculation, and audit trail
-- server-authoritative and idempotent.

-- ---------------------------------------------------------------------------
-- 1. Durable recovery records and append-only customer credit ledger
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.service_recovery_resolutions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  booking_item_id uuid NOT NULL REFERENCES public.booking_items(id) ON DELETE CASCADE,
  original_service_unit_id uuid NOT NULL REFERENCES public.service_units(id),
  replacement_service_unit_id uuid REFERENCES public.service_units(id),
  session_id uuid REFERENCES public.sessions(id) ON DELETE SET NULL,
  recovery_key text NOT NULL UNIQUE,
  resolution_type text NOT NULL CHECK (resolution_type IN (
    'pending',
    'reassigned',
    'credit_issued',
    'active_session_reassigned',
    'active_session_credit_issued'
  )),
  fulfilled_minutes integer NOT NULL DEFAULT 0 CHECK (fulfilled_minutes >= 0),
  unfulfilled_minutes integer NOT NULL DEFAULT 0 CHECK (unfulfilled_minutes >= 0),
  credit_amount numeric NOT NULL DEFAULT 0 CHECK (credit_amount >= 0),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_service_recovery_resolutions_booking_id
  ON public.service_recovery_resolutions(booking_id);
CREATE INDEX IF NOT EXISTS idx_service_recovery_resolutions_original_unit
  ON public.service_recovery_resolutions(original_service_unit_id);

CREATE TABLE IF NOT EXISTS public.tiermetry_credit_ledger (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  booking_id uuid NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  recovery_resolution_id uuid NOT NULL UNIQUE
    REFERENCES public.service_recovery_resolutions(id) ON DELETE RESTRICT,
  amount numeric NOT NULL CHECK (amount > 0),
  currency text NOT NULL DEFAULT 'INR' CHECK (currency = 'INR'),
  entry_type text NOT NULL DEFAULT 'credit' CHECK (entry_type = 'credit'),
  reason text NOT NULL DEFAULT 'venue_service_failure'
    CHECK (reason = 'venue_service_failure'),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tiermetry_credit_ledger_user_created
  ON public.tiermetry_credit_ledger(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tiermetry_credit_ledger_booking_id
  ON public.tiermetry_credit_ledger(booking_id);

ALTER TABLE public.service_recovery_resolutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tiermetry_credit_ledger ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can view their service recovery resolutions"
  ON public.service_recovery_resolutions FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = service_recovery_resolutions.booking_id
        AND b.user_id = auth.uid()
    )
  );

CREATE POLICY "Owners can view their venue service recovery resolutions"
  ON public.service_recovery_resolutions FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = service_recovery_resolutions.booking_id
        AND public.is_venue_owner(b.venue_id)
    )
  );

CREATE POLICY "Customers can view their Tiermetry credits"
  ON public.tiermetry_credit_ledger FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Owners can view service recovery credits for their venue"
  ON public.tiermetry_credit_ledger FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = tiermetry_credit_ledger.booking_id
        AND public.is_venue_owner(b.venue_id)
    )
  );

-- The authenticated client must not bypass these functions by changing an
-- asset status directly. Metadata writes remain available through the existing
-- owner policy; status transitions are performed by SECURITY DEFINER RPCs.
REVOKE UPDATE ON public.service_units FROM authenticated;
GRANT UPDATE (name, description, price, image, service_id) ON public.service_units TO authenticated;

-- Do not permit a session whose item has already been resolved with credit to
-- become active again through a stale client request.
CREATE OR REPLACE FUNCTION public.prevent_recovery_credit_session_start()
RETURNS trigger AS $$
BEGIN
  IF NEW.status = 'active' AND EXISTS (
    SELECT 1
    FROM public.service_recovery_resolutions r
    WHERE r.booking_id = NEW.booking_id
      AND r.original_service_unit_id = OLD.service_unit_id
      AND r.resolution_type IN ('credit_issued', 'active_session_credit_issued')
  ) THEN
    RAISE EXCEPTION 'This session was resolved through Tiermetry Credits and cannot be started.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_prevent_recovery_credit_session_start ON public.sessions;
CREATE TRIGGER trg_prevent_recovery_credit_session_start
  BEFORE UPDATE OF status ON public.sessions
  FOR EACH ROW EXECUTE FUNCTION public.prevent_recovery_credit_session_start();

-- ---------------------------------------------------------------------------
-- 2. Replacement discovery and idempotent credit issuance helpers
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.find_service_recovery_replacement(
  p_venue_id uuid,
  p_service_id uuid,
  p_excluded_service_unit_id uuid,
  p_booking_id uuid,
  p_start_time timestamptz,
  p_end_time timestamptz
) RETURNS uuid AS $$
DECLARE
  v_buffer_before interval := interval '0 minutes';
  v_buffer_after interval := interval '0 minutes';
  v_replacement_id uuid;
BEGIN
  SELECT
    (buffer_before_minutes || ' minutes')::interval,
    (buffer_after_minutes || ' minutes')::interval
  INTO v_buffer_before, v_buffer_after
  FROM public.venue_booking_settings
  WHERE venue_id = p_venue_id;

  SELECT su.id INTO v_replacement_id
  FROM public.service_units su
  WHERE su.service_id = p_service_id
    AND su.id <> p_excluded_service_unit_id
    AND su.status = 'available'
    AND NOT EXISTS (
      SELECT 1
      FROM public.booking_items bi
      JOIN public.bookings b ON b.id = bi.booking_id
      WHERE bi.service_unit_id = su.id
        AND b.id <> p_booking_id
        AND b.status IN ('pending', 'confirmed', 'active')
        AND (b.start_time - v_buffer_after) < p_end_time
        AND (b.end_time + v_buffer_before) > p_start_time
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.reservation_hold_items rhi
      JOIN public.reservation_holds rh ON rh.id = rhi.hold_id
      WHERE rhi.service_unit_id = su.id
        AND rh.status = 'active'
        AND rh.expires_at > now()
        AND (rh.start_time - v_buffer_after) < p_end_time
        AND (rh.end_time + v_buffer_before) > p_start_time
    )
  ORDER BY su.created_at, su.id
  FOR UPDATE SKIP LOCKED
  LIMIT 1;

  RETURN v_replacement_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.issue_service_recovery_credit(
  p_resolution_id uuid,
  p_user_id uuid,
  p_booking_id uuid,
  p_amount numeric,
  p_metadata jsonb
) RETURNS boolean AS $$
DECLARE
  v_inserted_count bigint := 0;
BEGIN
  IF p_amount <= 0 THEN
    RETURN false;
  END IF;

  INSERT INTO public.tiermetry_credit_ledger (
    user_id, booking_id, recovery_resolution_id, amount, metadata
  ) VALUES (
    p_user_id, p_booking_id, p_resolution_id, p_amount, p_metadata
  ) ON CONFLICT (recovery_resolution_id) DO NOTHING;

  GET DIAGNOSTICS v_inserted_count = ROW_COUNT;
  RETURN v_inserted_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- 3. Standard maintenance transition: active sessions are blocked; future
--    and checked-in bookings are recovered before the RPC returns.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.set_service_unit_maintenance(
  p_service_unit_id uuid,
  p_reason text DEFAULT 'maintenance'
) RETURNS jsonb AS $$
DECLARE
  v_unit record;
  v_booking record;
  v_item record;
  v_resolution_id uuid;
  v_replacement_id uuid;
  v_credit_amount numeric;
  v_recovery_key text;
  v_affected_bookings integer := 0;
  v_reassigned integer := 0;
  v_credits integer := 0;
  v_credit_inserted boolean;
  v_summary jsonb := '[]'::jsonb;
BEGIN
  SELECT su.*, s.venue_id INTO v_unit
  FROM public.service_units su
  JOIN public.services s ON s.id = su.service_id
  WHERE su.id = p_service_unit_id
  FOR UPDATE;

  IF v_unit IS NULL THEN
    RAISE EXCEPTION 'Service unit not found.';
  END IF;
  IF NOT public.is_venue_owner(v_unit.venue_id) THEN
    RAISE EXCEPTION 'Unauthorized.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.sessions ses
    WHERE ses.service_unit_id = p_service_unit_id AND ses.status = 'active'
  ) THEN
    RETURN jsonb_build_object(
      'success', false,
      'asset_status', v_unit.status,
      'blocked_reason', 'active_session',
      'affected_booking_count', 0,
      'automatically_reassigned_count', 0,
      'credits_issued_count', 0,
      'resolution_summary', jsonb_build_array()
    );
  END IF;

  UPDATE public.service_units SET status = 'maintenance'
  WHERE id = p_service_unit_id;

  FOR v_item IN
    SELECT bi.id, bi.booking_id, bi.price_at_booking
    FROM public.booking_items bi
    JOIN public.bookings b ON b.id = bi.booking_id
    WHERE bi.service_unit_id = p_service_unit_id
      AND b.status IN ('pending', 'confirmed', 'active')
    ORDER BY b.start_time, bi.id
    FOR UPDATE OF bi, b
  LOOP
    SELECT b.id, b.user_id, b.venue_id, b.start_time, b.end_time
    INTO v_booking
    FROM public.bookings b WHERE b.id = v_item.booking_id;

    v_recovery_key := 'maintenance:' || p_service_unit_id::text || ':' || v_item.id::text;
    INSERT INTO public.service_recovery_resolutions (
      booking_id, booking_item_id, original_service_unit_id, recovery_key,
      resolution_type, metadata
    ) VALUES (
      v_booking.id, v_item.id, p_service_unit_id, v_recovery_key, 'pending',
      jsonb_build_object('reason', p_reason, 'service_id', v_unit.service_id)
    ) ON CONFLICT (recovery_key) DO NOTHING
    RETURNING id INTO v_resolution_id;

    IF v_resolution_id IS NULL THEN
      CONTINUE;
    END IF;

    v_affected_bookings := v_affected_bookings + 1;
    PERFORM public.log_booking_event(
      v_booking.id, NULL, 'ASSET_UNAVAILABLE', auth.uid(), 'owner',
      jsonb_build_object('asset_id', p_service_unit_id, 'reason', p_reason)
    );
    PERFORM public.log_booking_event(
      v_booking.id, NULL, 'BOOKING_AFFECTED', auth.uid(), 'system',
      jsonb_build_object('asset_id', p_service_unit_id, 'booking_item_id', v_item.id)
    );

    v_replacement_id := public.find_service_recovery_replacement(
      v_booking.venue_id, v_unit.service_id, p_service_unit_id, v_booking.id,
      v_booking.start_time, v_booking.end_time
    );

    IF v_replacement_id IS NOT NULL THEN
      UPDATE public.booking_items SET service_unit_id = v_replacement_id
      WHERE id = v_item.id;
      UPDATE public.sessions
      SET service_unit_id = v_replacement_id, updated_at = now()
      WHERE booking_id = v_booking.id
        AND service_unit_id = p_service_unit_id
        AND status IN ('not_started', 'checked_in');
      UPDATE public.service_recovery_resolutions
      SET replacement_service_unit_id = v_replacement_id,
          resolution_type = 'reassigned', updated_at = now()
      WHERE id = v_resolution_id;
      PERFORM public.log_booking_event(
        v_booking.id, NULL, 'BOOKING_ASSET_REASSIGNED', auth.uid(), 'system',
        jsonb_build_object(
          'resolution_id', v_resolution_id,
          'original_asset_id', p_service_unit_id,
          'replacement_asset_id', v_replacement_id,
          'booking_item_id', v_item.id,
          'time_preserved', true,
          'price_preserved', true
        )
      );
      v_summary := v_summary || jsonb_build_array(jsonb_build_object(
        'booking_id', v_booking.id,
        'booking_item_id', v_item.id,
        'resolution', 'reassigned',
        'replacement_asset_id', v_replacement_id
      ));
      v_reassigned := v_reassigned + 1;
    ELSE
      v_credit_amount := GREATEST(0, v_item.price_at_booking);
      UPDATE public.sessions
      SET status = 'ended', ended_at = now(), updated_at = now()
      WHERE booking_id = v_booking.id
        AND service_unit_id = p_service_unit_id
        AND status IN ('not_started', 'checked_in');
      UPDATE public.service_recovery_resolutions
      SET resolution_type = 'credit_issued', credit_amount = v_credit_amount,
          unfulfilled_minutes = GREATEST(0, floor(extract(epoch FROM (v_booking.end_time - v_booking.start_time)) / 60))::integer,
          updated_at = now()
      WHERE id = v_resolution_id;
      v_credit_inserted := public.issue_service_recovery_credit(
        v_resolution_id, v_booking.user_id, v_booking.id, v_credit_amount,
        jsonb_build_object(
          'original_booking_amount', v_item.price_at_booking,
          'fulfilled_value', 0,
          'unfulfilled_value', v_credit_amount,
          'asset_id', p_service_unit_id,
          'service_id', v_unit.service_id,
          'booking_item_id', v_item.id
        )
      );
      IF v_credit_inserted THEN
        PERFORM public.log_booking_event(
          v_booking.id, NULL, 'SERVICE_RECOVERY_CREDIT_ISSUED', auth.uid(), 'system',
          jsonb_build_object(
            'resolution_id', v_resolution_id,
            'amount', v_credit_amount,
            'asset_id', p_service_unit_id,
            'booking_item_id', v_item.id
          )
        );
      END IF;
      v_summary := v_summary || jsonb_build_array(jsonb_build_object(
        'booking_id', v_booking.id,
        'booking_item_id', v_item.id,
        'resolution', 'credit_issued',
        'credit_amount', v_credit_amount
      ));
      v_credits := v_credits + 1;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'success', true,
    'asset_status', 'maintenance',
    'blocked_reason', NULL,
    'affected_booking_count', v_affected_bookings,
    'automatically_reassigned_count', v_reassigned,
    'credits_issued_count', v_credits,
    'resolution_summary', v_summary
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- 4. Explicit active-session failure path. Normal maintenance remains blocked
--    while an asset is in use; this RPC is for a real failure and preserves the
--    remaining session window on a compatible replacement.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.report_service_unit_failure(
  p_service_unit_id uuid,
  p_reason text DEFAULT 'asset_failure'
) RETURNS jsonb AS $$
DECLARE
  v_unit record;
  v_session record;
  v_booking record;
  v_item record;
  v_resolution_id uuid;
  v_replacement_id uuid;
  v_recovery_key text;
  v_total_minutes integer;
  v_remaining_minutes integer;
  v_credit_amount numeric;
  v_credit_inserted boolean;
  v_reassigned integer := 0;
  v_credits integer := 0;
  v_follow_up jsonb;
BEGIN
  SELECT su.*, s.venue_id INTO v_unit
  FROM public.service_units su
  JOIN public.services s ON s.id = su.service_id
  WHERE su.id = p_service_unit_id
  FOR UPDATE;

  IF v_unit IS NULL THEN
    RAISE EXCEPTION 'Service unit not found.';
  END IF;
  IF NOT public.is_venue_owner(v_unit.venue_id) THEN
    RAISE EXCEPTION 'Unauthorized.';
  END IF;

  UPDATE public.service_units SET status = 'maintenance'
  WHERE id = p_service_unit_id;

  FOR v_session IN
    SELECT * FROM public.sessions
    WHERE service_unit_id = p_service_unit_id AND status = 'active'
    FOR UPDATE
  LOOP
    SELECT b.*, bi.id AS booking_item_id, bi.price_at_booking
    INTO v_booking
    FROM public.bookings b
    JOIN public.booking_items bi
      ON bi.booking_id = b.id AND bi.service_unit_id = p_service_unit_id
    WHERE b.id = v_session.booking_id
    FOR UPDATE OF b, bi;

    IF v_booking IS NULL THEN
      RAISE EXCEPTION 'Active session has no matching booking item.';
    END IF;

    v_recovery_key := 'active-failure:' || p_service_unit_id::text || ':' || v_booking.booking_item_id::text || ':' || v_session.id::text;
    INSERT INTO public.service_recovery_resolutions (
      booking_id, booking_item_id, original_service_unit_id, session_id,
      recovery_key, resolution_type, metadata
    ) VALUES (
      v_booking.id, v_booking.booking_item_id, p_service_unit_id, v_session.id,
      v_recovery_key, 'pending',
      jsonb_build_object('reason', p_reason, 'service_id', v_unit.service_id)
    ) ON CONFLICT (recovery_key) DO NOTHING
    RETURNING id INTO v_resolution_id;

    IF v_resolution_id IS NULL THEN
      CONTINUE;
    END IF;

    v_total_minutes := GREATEST(1, floor(extract(epoch FROM (v_session.scheduled_end_at - v_session.scheduled_start_at)) / 60))::integer;
    v_remaining_minutes := GREATEST(0, ceil(extract(epoch FROM (v_session.scheduled_end_at - now())) / 60))::integer;
    v_replacement_id := public.find_service_recovery_replacement(
      v_booking.venue_id, v_unit.service_id, p_service_unit_id, v_booking.id,
      now(), v_session.scheduled_end_at
    );

    PERFORM public.log_booking_event(
      v_booking.id, v_session.id, 'SESSION_INTERRUPTED', auth.uid(), 'owner',
      jsonb_build_object('asset_id', p_service_unit_id, 'reason', p_reason, 'remaining_minutes', v_remaining_minutes)
    );

    IF v_replacement_id IS NOT NULL THEN
      UPDATE public.booking_items SET service_unit_id = v_replacement_id
      WHERE id = v_booking.booking_item_id;
      UPDATE public.sessions
      SET service_unit_id = v_replacement_id, updated_at = now()
      WHERE id = v_session.id;
      UPDATE public.service_recovery_resolutions
      SET replacement_service_unit_id = v_replacement_id,
          resolution_type = 'active_session_reassigned',
          fulfilled_minutes = GREATEST(0, v_total_minutes - v_remaining_minutes),
          unfulfilled_minutes = 0, updated_at = now()
      WHERE id = v_resolution_id;
      PERFORM public.log_booking_event(
        v_booking.id, v_session.id, 'SESSION_RECOVERED', auth.uid(), 'system',
        jsonb_build_object(
          'resolution_id', v_resolution_id,
          'original_asset_id', p_service_unit_id,
          'replacement_asset_id', v_replacement_id,
          'remaining_minutes_preserved', v_remaining_minutes
        )
      );
      v_reassigned := v_reassigned + 1;
    ELSE
      v_credit_amount := round(
        GREATEST(0, v_booking.price_at_booking) * v_remaining_minutes / v_total_minutes,
        2
      );
      UPDATE public.sessions
      SET status = 'ended', ended_at = now(), updated_at = now()
      WHERE id = v_session.id;
      UPDATE public.service_recovery_resolutions
      SET resolution_type = 'active_session_credit_issued',
          fulfilled_minutes = GREATEST(0, v_total_minutes - v_remaining_minutes),
          unfulfilled_minutes = v_remaining_minutes,
          credit_amount = v_credit_amount, updated_at = now()
      WHERE id = v_resolution_id;
      v_credit_inserted := public.issue_service_recovery_credit(
        v_resolution_id, v_booking.user_id, v_booking.id, v_credit_amount,
        jsonb_build_object(
          'original_booking_amount', v_booking.price_at_booking,
          'fulfilled_value', round(GREATEST(0, v_booking.price_at_booking) * (v_total_minutes - v_remaining_minutes) / v_total_minutes, 2),
          'unfulfilled_value', v_credit_amount,
          'asset_id', p_service_unit_id,
          'service_id', v_unit.service_id,
          'booking_item_id', v_booking.booking_item_id,
          'session_id', v_session.id,
          'remaining_minutes', v_remaining_minutes
        )
      );
      IF v_credit_inserted THEN
        PERFORM public.log_booking_event(
          v_booking.id, v_session.id, 'SERVICE_RECOVERY_CREDIT_ISSUED', auth.uid(), 'system',
          jsonb_build_object('resolution_id', v_resolution_id, 'amount', v_credit_amount, 'asset_id', p_service_unit_id)
        );
      END IF;
      UPDATE public.bookings b
      SET status = 'completed', updated_at = now()
      WHERE b.id = v_booking.id
        AND NOT EXISTS (
          SELECT 1 FROM public.sessions s
          WHERE s.booking_id = b.id AND s.status IN ('not_started', 'checked_in', 'active')
        );
      v_credits := v_credits + 1;
    END IF;
  END LOOP;

  -- Resolve any future/checked-in assignments on the same failed unit using
  -- the normal flow. The active sessions above have already moved or ended.
  v_follow_up := public.set_service_unit_maintenance(p_service_unit_id, p_reason);

  RETURN jsonb_build_object(
    'success', true,
    'asset_status', 'maintenance',
    'blocked_reason', NULL,
    'affected_booking_count', COALESCE((v_follow_up->>'affected_booking_count')::integer, 0) + v_reassigned + v_credits,
    'automatically_reassigned_count', COALESCE((v_follow_up->>'automatically_reassigned_count')::integer, 0) + v_reassigned,
    'credits_issued_count', COALESCE((v_follow_up->>'credits_issued_count')::integer, 0) + v_credits,
    'resolution_summary', jsonb_build_object('reason', p_reason, 'active_session_failure', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Controlled restoration and retirement use the same server authorization
-- boundary. Maintenance itself delegates to the recovery workflow above.
CREATE OR REPLACE FUNCTION public.transition_service_unit_status(
  p_service_unit_id uuid,
  p_target_status text
) RETURNS jsonb AS $$
DECLARE
  v_unit record;
BEGIN
  IF p_target_status = 'maintenance' THEN
    RETURN public.set_service_unit_maintenance(p_service_unit_id, 'maintenance');
  END IF;
  IF p_target_status NOT IN ('available', 'retired') THEN
    RAISE EXCEPTION 'Unsupported service-unit status transition.';
  END IF;

  SELECT su.*, s.venue_id INTO v_unit
  FROM public.service_units su JOIN public.services s ON s.id = su.service_id
  WHERE su.id = p_service_unit_id FOR UPDATE;
  IF v_unit IS NULL THEN RAISE EXCEPTION 'Service unit not found.'; END IF;
  IF NOT public.is_venue_owner(v_unit.venue_id) THEN RAISE EXCEPTION 'Unauthorized.'; END IF;
  IF EXISTS (SELECT 1 FROM public.sessions ses WHERE ses.service_unit_id = p_service_unit_id AND ses.status = 'active') THEN
    RETURN jsonb_build_object('success', false, 'asset_status', v_unit.status, 'blocked_reason', 'active_session');
  END IF;

  UPDATE public.service_units SET status = p_target_status WHERE id = p_service_unit_id;
  RETURN jsonb_build_object(
    'success', true, 'asset_status', p_target_status,
    'affected_booking_count', 0, 'automatically_reassigned_count', 0,
    'credits_issued_count', 0, 'blocked_reason', NULL,
    'resolution_summary', jsonb_build_object()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.find_service_recovery_replacement(uuid, uuid, uuid, uuid, timestamptz, timestamptz) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.issue_service_recovery_credit(uuid, uuid, uuid, numeric, jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.set_service_unit_maintenance(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.report_service_unit_failure(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.transition_service_unit_status(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_service_unit_maintenance(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.report_service_unit_failure(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.transition_service_unit_status(uuid, text) TO authenticated;

-- ---------------------------------------------------------------------------
-- 5. Realtime publication. Booking events drive booking-screen refreshes; the
--    ledger publication supports the transaction/wallet view independently.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public'
      AND tablename = 'service_recovery_resolutions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.service_recovery_resolutions;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public'
      AND tablename = 'tiermetry_credit_ledger'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.tiermetry_credit_ledger;
  END IF;
END $$;

ALTER TABLE public.service_recovery_resolutions REPLICA IDENTITY FULL;
ALTER TABLE public.tiermetry_credit_ledger REPLICA IDENTITY FULL;
