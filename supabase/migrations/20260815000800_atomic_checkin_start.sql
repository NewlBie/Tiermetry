-- Migration: 20260815000800_atomic_checkin_start.sql
-- Enforces atomic arrival and session start for online bookings

-- Drop existing overloads of start_session_atomic
DROP FUNCTION IF EXISTS public.start_session_atomic(uuid, uuid);
DROP FUNCTION IF EXISTS public.start_session_atomic(uuid, uuid, text);

CREATE OR REPLACE FUNCTION public.start_session_atomic(
  p_booking_id uuid,
  p_session_id uuid DEFAULT NULL,
  p_internal_bypass boolean DEFAULT false
) RETURNS void AS $$
DECLARE
  v_booking record;
  v_settings record;
  v_now timestamptz := now();
  v_duration interval;
  v_new_end timestamptz;
  v_conflict_count integer := 0;
  v_policy_applied text := 'fixed_booking_end';
BEGIN
  -- 1. Fetch & lock booking
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF v_booking IS NULL THEN
    RAISE EXCEPTION 'Booking not found.';
  END IF;

  IF NOT public.is_venue_owner(v_booking.venue_id) AND auth.uid() != v_booking.user_id THEN
    RAISE EXCEPTION 'Unauthorized.';
  END IF;

  -- ENFORCE: Online bookings must be started via the customer check-in flow
  IF v_booking.source = 'online' AND NOT p_internal_bypass THEN
    RAISE EXCEPTION 'Online bookings cannot be manually started. The customer must verify their arrival via PIN or QR code.';
  END IF;

  -- 2. Read Venue Settings
  SELECT * INTO v_settings
  FROM public.venue_booking_settings
  WHERE venue_id = v_booking.venue_id;

  v_duration := v_booking.end_time - v_booking.start_time;

  -- 3. Calculate Session End Time based on session_end_policy with conflict check
  IF v_settings.session_end_policy = 'full_duration' THEN
    v_new_end := v_now + v_duration;
    v_policy_applied := 'full_duration';

    -- If extending beyond original booking end, verify no downstream booking / hold conflicts on assigned units
    IF v_new_end > v_booking.end_time THEN
      SELECT count(*) INTO v_conflict_count
      FROM (
        -- Confirmed or active bookings
        SELECT bi.service_unit_id
        FROM public.booking_items bi
        JOIN public.bookings b ON bi.booking_id = b.id
        WHERE bi.service_unit_id IN (
          SELECT COALESCE(s.service_unit_id, bi2.service_unit_id)
          FROM public.sessions s
          LEFT JOIN public.booking_items bi2 ON bi2.booking_id = s.booking_id
          WHERE s.booking_id = p_booking_id
            AND (p_session_id IS NULL OR s.id = p_session_id)
        )
          AND b.id != p_booking_id
          AND b.status IN ('confirmed', 'pending', 'active')
          AND b.start_time < v_new_end
          AND b.end_time > v_booking.end_time
        UNION ALL
        -- Active holds
        SELECT rhi.service_unit_id
        FROM public.reservation_hold_items rhi
        JOIN public.reservation_holds rh ON rhi.hold_id = rh.id
        WHERE rhi.service_unit_id IN (
          SELECT COALESCE(s.service_unit_id, bi2.service_unit_id)
          FROM public.sessions s
          LEFT JOIN public.booking_items bi2 ON bi2.booking_id = s.booking_id
          WHERE s.booking_id = p_booking_id
            AND (p_session_id IS NULL OR s.id = p_session_id)
        )
          AND rh.status = 'active'
          AND rh.expires_at > now()
          AND rh.start_time < v_new_end
          AND rh.end_time > v_booking.end_time
      ) conflicts;

      IF v_conflict_count > 0 THEN
        -- Fall back safely to original booking end to preserve downstream customer reservation
        v_new_end := v_booking.end_time;
        v_policy_applied := 'fixed_booking_end_fallback_conflict';
      END IF;
    END IF;
  ELSE
    v_new_end := v_booking.end_time;
    v_policy_applied := 'fixed_booking_end';
  END IF;

  -- 4. Update Sessions
  UPDATE public.sessions
  SET
    status = 'active',
    started_at = v_now,
    scheduled_end_at = v_new_end,
    checked_in_at = COALESCE(checked_in_at, v_now),
    updated_at = v_now
  WHERE booking_id = p_booking_id
    AND (p_session_id IS NULL OR id = p_session_id)
    AND status IN ('not_started', 'checked_in');

  -- 5. Update Booking Status
  UPDATE public.bookings
  SET status = 'active', updated_at = v_now
  WHERE id = p_booking_id AND status != 'active';

  -- 6. Log Audit Event
  PERFORM public.log_booking_event(
    p_booking_id, p_session_id, 'SESSION_STARTED', auth.uid(),
    CASE WHEN public.is_venue_owner(v_booking.venue_id) THEN 'owner' ELSE 'customer' END,
    jsonb_build_object('started_at', v_now, 'scheduled_end_at', v_new_end, 'policy_applied', v_policy_applied)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


CREATE OR REPLACE FUNCTION public.check_in_booking(
  p_booking_id uuid,
  p_method text DEFAULT 'qr',
  p_code text DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_booking record;
  v_settings record;
  v_now timestamptz := now();
  v_earliest_check_in timestamptz;
  v_latest_check_in timestamptz;
  v_is_owner boolean := false;
BEGIN
  -- 1. Fetch and lock booking
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF v_booking IS NULL THEN
    RAISE EXCEPTION 'Booking not found.';
  END IF;

  IF v_booking.status IN ('cancelled', 'completed') THEN
    RAISE EXCEPTION 'Cannot check in a % booking.', v_booking.status;
  END IF;
  
  IF v_booking.status = 'active' THEN
    -- Idempotent operation: If already active, just return gracefully
    RETURN;
  END IF;

  v_is_owner := public.is_venue_owner(v_booking.venue_id);

  -- Customer authorization
  IF NOT v_is_owner AND (auth.uid() IS NULL OR auth.uid() != v_booking.user_id) THEN
    RAISE EXCEPTION 'Unauthorized.';
  END IF;

  -- Verify check_in_code if code method used
  IF p_method = 'code' AND p_code IS NOT NULL THEN
    IF v_booking.check_in_code != p_code THEN
      RAISE EXCEPTION 'Invalid check-in code.';
    END IF;
  END IF;

  -- 2. Fetch Venue Settings
  SELECT * INTO v_settings
  FROM public.venue_booking_settings
  WHERE venue_id = v_booking.venue_id;

  -- 3. Calculate Check-In Window
  IF v_settings.allow_early_check_in THEN
    v_earliest_check_in := v_booking.start_time - (v_settings.early_check_in_minutes || ' minutes')::interval;
  ELSE
    v_earliest_check_in := v_booking.start_time;
  END IF;

  v_latest_check_in := v_booking.start_time + (COALESCE(v_settings.check_in_grace_period_minutes, 15) || ' minutes')::interval;

  -- Validate time window (owner can override)
  IF NOT v_is_owner THEN
    IF v_now < v_earliest_check_in THEN
      RAISE EXCEPTION 'Check-in is not open yet. Please check in starting at %', to_char(v_earliest_check_in, 'HH24:MI');
    END IF;

    IF v_now > v_latest_check_in THEN
      RAISE EXCEPTION 'Check-in window has passed (grace period ended at %).', to_char(v_latest_check_in, 'HH24:MI');
    END IF;
  END IF;

  -- 4. Log Audit Event for successful credential verification
  PERFORM public.log_booking_event(
    p_booking_id, NULL, 'CHECK_IN', auth.uid(),
    CASE WHEN v_is_owner THEN 'owner' ELSE 'customer' END,
    jsonb_build_object('method', p_method, 'checked_in_at', v_now)
  );

  -- 5. Atomically Start Session
  PERFORM public.start_session_atomic(p_booking_id, NULL, true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
