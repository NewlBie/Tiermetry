-- Migration: 20260815000400_universal_booking_and_session_engine.sql
-- Tiermetry Universal Booking, Concurrency, Session Lifecycle & Operational Engine

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. VENUE BOOKING SETTINGS TABLE & SEEDING
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.venue_booking_settings (
  venue_id uuid PRIMARY KEY REFERENCES public.venues(id) ON DELETE CASCADE,
  confirmation_mode text DEFAULT 'instant' CHECK (confirmation_mode IN ('instant', 'owner_approval')),
  hold_duration_minutes integer DEFAULT 10 CHECK (hold_duration_minutes BETWEEN 2 AND 60),
  advance_booking_days integer DEFAULT 30 CHECK (advance_booking_days BETWEEN 1 AND 365),
  min_advance_booking_minutes integer DEFAULT 0 CHECK (min_advance_booking_minutes >= 0),
  require_check_in boolean DEFAULT true,
  check_in_methods text[] DEFAULT ARRAY['qr', 'manual', 'code'],
  allow_early_check_in boolean DEFAULT false,
  early_check_in_minutes integer DEFAULT 10,
  check_in_grace_period_minutes integer DEFAULT 10,
  no_show_behavior text DEFAULT 'automatic_release' CHECK (no_show_behavior IN ('automatic_release', 'owner_decides')),
  session_end_policy text DEFAULT 'fixed_booking_end' CHECK (session_end_policy IN ('fixed_booking_end', 'full_duration')),
  late_arrival_policy text DEFAULT 'lose_unused_time' CHECK (late_arrival_policy IN ('lose_unused_time', 'extend_if_available', 'owner_decides')),
  cancellation_allowed boolean DEFAULT true,
  free_cancellation_window_minutes integer DEFAULT 30,
  refund_percentage numeric DEFAULT 100.0 CHECK (refund_percentage BETWEEN 0 AND 100),
  cancellation_fee numeric DEFAULT 0.0 CHECK (cancellation_fee >= 0),
  rescheduling_allowed boolean DEFAULT true,
  max_reschedules integer DEFAULT 1 CHECK (max_reschedules >= 0),
  rescheduling_cutoff_minutes integer DEFAULT 30,
  buffer_before_minutes integer DEFAULT 0 CHECK (buffer_before_minutes >= 0),
  buffer_after_minutes integer DEFAULT 0 CHECK (buffer_after_minutes >= 0),
  owner_manual_booking_enabled boolean DEFAULT true,
  enable_notifications boolean DEFAULT true,
  created_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Seed default settings for all existing venues
INSERT INTO public.venue_booking_settings (venue_id)
SELECT id FROM public.venues
ON CONFLICT (venue_id) DO NOTHING;

-- Trigger to auto-create default booking settings when a new venue is added
CREATE OR REPLACE FUNCTION public.handle_new_venue_booking_settings()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.venue_booking_settings (venue_id)
  VALUES (NEW.id)
  ON CONFLICT (venue_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_new_venue_booking_settings ON public.venues;
CREATE TRIGGER trg_new_venue_booking_settings
  AFTER INSERT ON public.venues
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_venue_booking_settings();

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. EXTEND BOOKINGS TABLE
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'source') THEN
    ALTER TABLE public.bookings ADD COLUMN source text DEFAULT 'online' CHECK (source IN ('online', 'owner_app', 'walk_in', 'phone', 'admin', 'partner'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'booking_code') THEN
    ALTER TABLE public.bookings ADD COLUMN booking_code text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'reschedule_count') THEN
    ALTER TABLE public.bookings ADD COLUMN reschedule_count integer DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'notes') THEN
    ALTER TABLE public.bookings ADD COLUMN notes text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'cancel_reason') THEN
    ALTER TABLE public.bookings ADD COLUMN cancel_reason text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'check_in_code') THEN
    ALTER TABLE public.bookings ADD COLUMN check_in_code text;
  END IF;
END $$;

-- Populate booking_code and check_in_code for existing rows
UPDATE public.bookings
SET
  booking_code = COALESCE(booking_code, 'BK-' || UPPER(SUBSTRING(id::text FROM 1 FOR 6))),
  check_in_code = COALESCE(check_in_code, LPAD((FLOOR(RANDOM() * 9000) + 1000)::text, 4, '0'))
WHERE booking_code IS NULL OR check_in_code IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. SESSIONS TABLE (Physical Usage Separation)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid REFERENCES public.bookings(id) ON DELETE CASCADE NOT NULL,
  venue_id uuid REFERENCES public.venues(id) ON DELETE CASCADE NOT NULL,
  service_unit_id uuid REFERENCES public.service_units(id) ON DELETE SET NULL,
  status text DEFAULT 'not_started' CHECK (status IN ('not_started', 'checked_in', 'active', 'ended', 'force_ended')),
  scheduled_start_at timestamptz NOT NULL,
  scheduled_end_at timestamptz NOT NULL,
  checked_in_at timestamptz,
  started_at timestamptz,
  ended_at timestamptz,
  check_in_method text CHECK (check_in_method IN ('qr', 'manual', 'code', 'nfc', 'auto')),
  created_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sessions_booking_id ON public.sessions(booking_id);
CREATE INDEX IF NOT EXISTS idx_sessions_venue_id ON public.sessions(venue_id);
CREATE INDEX IF NOT EXISTS idx_sessions_service_unit_id ON public.sessions(service_unit_id);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON public.sessions(status);
CREATE INDEX IF NOT EXISTS idx_sessions_time_range ON public.sessions(scheduled_start_at, scheduled_end_at);

-- Populate initial sessions for existing confirmed/active bookings
INSERT INTO public.sessions (booking_id, venue_id, service_unit_id, status, scheduled_start_at, scheduled_end_at, started_at, ended_at)
SELECT
  b.id,
  b.venue_id,
  bi.service_unit_id,
  CASE
    WHEN b.status = 'completed' THEN 'ended'
    WHEN b.status = 'confirmed' AND now() >= b.start_time AND now() <= b.end_time THEN 'active'
    WHEN b.status = 'confirmed' AND now() > b.end_time THEN 'ended'
    ELSE 'not_started'
  END AS status,
  b.start_time,
  b.end_time,
  CASE WHEN b.status = 'completed' OR now() >= b.start_time THEN b.start_time ELSE NULL END AS started_at,
  CASE WHEN b.status = 'completed' OR now() > b.end_time THEN b.end_time ELSE NULL END AS ended_at
FROM public.bookings b
LEFT JOIN public.booking_items bi ON bi.booking_id = b.id
WHERE b.status IN ('confirmed', 'completed')
  AND NOT EXISTS (SELECT 1 FROM public.sessions s WHERE s.booking_id = b.id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. BOOKING AUDIT EVENTS TABLE (Immutable Audit Trail)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.booking_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid REFERENCES public.bookings(id) ON DELETE CASCADE NOT NULL,
  session_id uuid REFERENCES public.sessions(id) ON DELETE SET NULL,
  event_type text NOT NULL,
  actor_id uuid REFERENCES public.profiles(id),
  actor_type text NOT NULL CHECK (actor_type IN ('customer', 'owner', 'staff', 'system')),
  metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
  created_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_booking_events_booking_id ON public.booking_events(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_events_created_at ON public.booking_events(created_at);

-- Helper procedure to log booking audit events
CREATE OR REPLACE FUNCTION public.log_booking_event(
  p_booking_id uuid,
  p_session_id uuid,
  p_event_type text,
  p_actor_id uuid,
  p_actor_type text,
  p_metadata jsonb DEFAULT '{}'::jsonb
) RETURNS void AS $$
BEGIN
  INSERT INTO public.booking_events (
    booking_id, session_id, event_type, actor_id, actor_type, metadata, created_at
  ) VALUES (
    p_booking_id, p_session_id, p_event_type, p_actor_id, p_actor_type, p_metadata, now()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. BOOKING PARTICIPANTS TABLE
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.booking_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid REFERENCES public.bookings(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  phone text,
  is_primary boolean DEFAULT false,
  waiver_signed boolean DEFAULT true,
  created_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_booking_participants_booking_id ON public.booking_participants(booking_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. ROW-LEVEL SECURITY POLICIES
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.venue_booking_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_participants ENABLE ROW LEVEL SECURITY;

-- venue_booking_settings: anyone can view; owner can update
CREATE POLICY "Venue settings viewable by everyone"
  ON public.venue_booking_settings FOR SELECT
  USING (true);

CREATE POLICY "Owners can update their venue settings"
  ON public.venue_booking_settings FOR UPDATE
  TO authenticated
  USING (public.is_venue_owner(venue_id))
  WITH CHECK (public.is_venue_owner(venue_id));

-- sessions: customer can view own; owner can view and manage
CREATE POLICY "Customers can view their own sessions"
  ON public.sessions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = sessions.booking_id
        AND b.user_id = auth.uid()
    )
  );

CREATE POLICY "Owners can view their venue sessions"
  ON public.sessions FOR SELECT
  USING (public.is_venue_owner(venue_id));

CREATE POLICY "Owners can update their venue sessions"
  ON public.sessions FOR UPDATE
  TO authenticated
  USING (public.is_venue_owner(venue_id))
  WITH CHECK (public.is_venue_owner(venue_id));

-- booking_events: customer can view own; owner can view venue's
CREATE POLICY "Customers can view their booking events"
  ON public.booking_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = booking_events.booking_id
        AND b.user_id = auth.uid()
    )
  );

CREATE POLICY "Owners can view their venue booking events"
  ON public.booking_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = booking_events.booking_id
        AND public.is_venue_owner(b.venue_id)
    )
  );

-- booking_participants: customer can view/insert own; owner can view
CREATE POLICY "Customers can view their booking participants"
  ON public.booking_participants FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = booking_participants.booking_id
        AND b.user_id = auth.uid()
    )
  );

CREATE POLICY "Customers can insert their booking participants"
  ON public.booking_participants FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = booking_participants.booking_id
        AND b.user_id = auth.uid()
    )
  );

CREATE POLICY "Owners can view their venue booking participants"
  ON public.booking_participants FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = booking_participants.booking_id
        AND public.is_venue_owner(b.venue_id)
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. ATOMIC BUSINESS LOGIC FUNCTIONS & RPCS
-- ─────────────────────────────────────────────────────────────────────────────

-- 7.1. Available Units Function (with Buffers & Operational States)
CREATE OR REPLACE FUNCTION public.get_available_units(
  p_service_id uuid,
  p_start_time timestamptz,
  p_end_time timestamptz
) RETURNS SETOF public.service_units AS $$
DECLARE
  v_venue_id uuid;
  v_buffer_before interval := interval '0 minutes';
  v_buffer_after interval := interval '0 minutes';
BEGIN
  -- Resolve venue_id from service
  SELECT venue_id INTO v_venue_id FROM public.services WHERE id = p_service_id;

  IF v_venue_id IS NOT NULL THEN
    SELECT
      (buffer_before_minutes || ' minutes')::interval,
      (buffer_after_minutes || ' minutes')::interval
    INTO
      v_buffer_before,
      v_buffer_after
    FROM public.venue_booking_settings
    WHERE venue_id = v_venue_id;
  END IF;

  RETURN QUERY
  SELECT su.*
  FROM public.service_units su
  WHERE su.service_id = p_service_id
    AND su.status = 'available'
    AND NOT EXISTS (
      -- Check confirmed/active bookings (including buffers)
      SELECT 1
      FROM public.booking_items bi
      JOIN public.bookings b ON bi.booking_id = b.id
      WHERE bi.service_unit_id = su.id
        AND b.status IN ('confirmed', 'pending', 'active')
        AND (b.start_time - v_buffer_after) < p_end_time
        AND (b.end_time + v_buffer_before) > p_start_time
    )
    AND NOT EXISTS (
      -- Check active reservation holds
      SELECT 1
      FROM public.reservation_hold_items rhi
      JOIN public.reservation_holds rh ON rhi.hold_id = rh.id
      WHERE rhi.service_unit_id = su.id
        AND rh.status = 'active'
        AND rh.expires_at > now()
        AND (rh.start_time - v_buffer_after) < p_end_time
        AND (rh.end_time + v_buffer_before) > p_start_time
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7.2. Dynamic Hold Creation (with Configurable Hold Duration)
CREATE OR REPLACE FUNCTION public.create_reservation_hold_atomic(
  p_venue_id uuid,
  p_start_time timestamptz,
  p_end_time timestamptz,
  p_service_unit_ids uuid[]
) RETURNS uuid AS $$
DECLARE
  v_hold_id uuid;
  v_total_amount numeric;
  v_hours numeric;
  v_conflict_count integer;
  v_unit_count integer;
  v_service_count integer;
  v_hold_duration_mins integer := 10;
  v_buffer_before interval := interval '0 minutes';
  v_buffer_after interval := interval '0 minutes';
BEGIN
  -- 1. Authentication
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 2. Input Validation
  IF p_start_time IS NULL OR p_end_time IS NULL THEN
    RAISE EXCEPTION 'Start time and end time are required';
  END IF;

  IF p_end_time <= p_start_time THEN
    RAISE EXCEPTION 'End time must be after start time';
  END IF;

  IF p_service_unit_ids IS NULL OR array_length(p_service_unit_ids, 1) = 0 THEN
    RAISE EXCEPTION 'At least one service unit must be selected';
  END IF;

  IF (SELECT count(DISTINCT id) FROM unnest(p_service_unit_ids) AS id) != array_length(p_service_unit_ids, 1) THEN
    RAISE EXCEPTION 'Duplicate service unit IDs provided';
  END IF;

  -- 3. Read Venue Settings for Hold Duration & Buffers
  SELECT
    COALESCE(hold_duration_minutes, 10),
    (COALESCE(buffer_before_minutes, 0) || ' minutes')::interval,
    (COALESCE(buffer_after_minutes, 0) || ' minutes')::interval
  INTO
    v_hold_duration_mins,
    v_buffer_before,
    v_buffer_after
  FROM public.venue_booking_settings
  WHERE venue_id = p_venue_id;

  v_hours := extract(epoch FROM (p_end_time - p_start_time)) / 3600;

  -- 4. Resource Validation & Inventory Lock
  PERFORM 1
  FROM public.service_units su
  JOIN public.services s ON su.service_id = s.id
  WHERE su.id = ANY(p_service_unit_ids)
    AND s.venue_id = p_venue_id
    AND su.status = 'available'
  FOR UPDATE;

  SELECT
    count(*),
    count(DISTINCT su.service_id)
  INTO
    v_unit_count,
    v_service_count
  FROM public.service_units su
  JOIN public.services s ON su.service_id = s.id
  WHERE su.id = ANY(p_service_unit_ids)
    AND s.venue_id = p_venue_id
    AND su.status = 'available';

  IF v_unit_count != array_length(p_service_unit_ids, 1) THEN
    RAISE EXCEPTION 'One or more units are invalid, in maintenance, or belong to another venue.';
  END IF;

  -- 5. Conflict Check
  SELECT count(*) INTO v_conflict_count
  FROM (
    SELECT service_unit_id FROM public.booking_items bi
    JOIN public.bookings b ON bi.booking_id = b.id
    WHERE bi.service_unit_id = ANY(p_service_unit_ids)
      AND b.status IN ('confirmed', 'pending', 'active')
      AND (b.start_time - v_buffer_after) < p_end_time
      AND (b.end_time + v_buffer_before) > p_start_time
    UNION ALL
    SELECT service_unit_id FROM public.reservation_hold_items rhi
    JOIN public.reservation_holds rh ON rhi.hold_id = rh.id
    WHERE rhi.service_unit_id = ANY(p_service_unit_ids)
      AND rh.status = 'active'
      AND rh.expires_at > now()
      AND (rh.start_time - v_buffer_after) < p_end_time
      AND (rh.end_time + v_buffer_before) > p_start_time
  ) t;

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'One or more selected resources were just booked by someone else.';
  END IF;

  -- 6. Authoritative Pricing
  SELECT sum(price) * v_hours INTO v_total_amount
  FROM public.service_units
  WHERE id = ANY(p_service_unit_ids);

  -- 7. Create Hold
  INSERT INTO public.reservation_holds (
    user_id, venue_id, start_time, end_time, total_amount, status, expires_at
  )
  VALUES (
    auth.uid(), p_venue_id, p_start_time, p_end_time, v_total_amount, 'active',
    now() + (v_hold_duration_mins || ' minutes')::interval
  )
  RETURNING id INTO v_hold_id;

  -- 8. Create Hold Items
  INSERT INTO public.reservation_hold_items (hold_id, service_unit_id)
  SELECT v_hold_id, id
  FROM public.service_units
  WHERE id = ANY(p_service_unit_ids);

  RETURN v_hold_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7.3. Secure Internal Hold Conversion (with Session Initialization)
CREATE OR REPLACE FUNCTION public._convert_hold_to_booking_internal(p_hold_id uuid)
RETURNS uuid AS $$
DECLARE
  v_hold record;
  v_booking_id uuid;
  v_conflict_count integer;
  v_booking_code text;
  v_check_in_code text;
  v_unit_id uuid;
BEGIN
  -- 1. Lock and Verify Hold
  SELECT * INTO v_hold
  FROM public.reservation_holds
  WHERE id = p_hold_id
  FOR UPDATE;

  IF v_hold IS NULL THEN
    RAISE EXCEPTION 'Hold not found.';
  END IF;

  IF v_hold.status != 'active' THEN
    RAISE EXCEPTION 'Hold is no longer active (Status: %).', v_hold.status;
  END IF;

  IF v_hold.expires_at < now() THEN
    RAISE EXCEPTION 'Hold has expired.';
  END IF;

  -- 2. Lock associated service units
  PERFORM 1
  FROM public.service_units su
  JOIN public.reservation_hold_items rhi ON su.id = rhi.service_unit_id
  WHERE rhi.hold_id = p_hold_id
  FOR UPDATE;

  -- 3. Final Integrity Re-Check
  SELECT count(*) INTO v_conflict_count
  FROM public.booking_items bi
  JOIN public.bookings b ON bi.booking_id = b.id
  WHERE bi.service_unit_id IN (SELECT service_unit_id FROM public.reservation_hold_items WHERE hold_id = p_hold_id)
    AND b.status IN ('confirmed', 'active')
    AND b.start_time < v_hold.end_time
    AND b.end_time > v_hold.start_time;

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'Inventory conflict detected during conversion.';
  END IF;

  -- 4. Generate Codes
  v_booking_code := 'BK-' || UPPER(SUBSTRING(gen_random_uuid()::text FROM 1 FOR 6));
  v_check_in_code := LPAD((FLOOR(RANDOM() * 9000) + 1000)::text, 4, '0');

  -- 5. Create Real Booking
  INSERT INTO public.bookings (
    user_id, venue_id, start_time, end_time, total_amount, status, confirmed_at, source, booking_code, check_in_code
  )
  VALUES (
    v_hold.user_id, v_hold.venue_id, v_hold.start_time, v_hold.end_time,
    v_hold.total_amount, 'confirmed', now(), 'online', v_booking_code, v_check_in_code
  )
  RETURNING id INTO v_booking_id;

  -- 6. Create Booking Items
  INSERT INTO public.booking_items (booking_id, service_unit_id, price_at_booking)
  SELECT v_booking_id, rhi.service_unit_id, su.price
  FROM public.reservation_hold_items rhi
  JOIN public.service_units su ON rhi.service_unit_id = su.id
  WHERE rhi.hold_id = p_hold_id;

  -- 7. Create Physical Session (Separation of Booking and Session)
  FOR v_unit_id IN
    SELECT service_unit_id FROM public.reservation_hold_items WHERE hold_id = p_hold_id
  LOOP
    INSERT INTO public.sessions (
      booking_id, venue_id, service_unit_id, status, scheduled_start_at, scheduled_end_at
    )
    VALUES (
      v_booking_id, v_hold.venue_id, v_unit_id, 'not_started', v_hold.start_time, v_hold.end_time
    );
  END LOOP;

  -- 8. Mark Hold as Converted
  UPDATE public.reservation_holds
  SET status = 'converted', converted_booking_id = v_booking_id, updated_at = now()
  WHERE id = p_hold_id;

  -- 9. Log Audit Events
  PERFORM public.log_booking_event(
    v_booking_id, NULL, 'BOOKING_CONFIRMED', v_hold.user_id, 'customer',
    jsonb_build_object('hold_id', p_hold_id, 'amount', v_hold.total_amount, 'booking_code', v_booking_code)
  );

  RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7.4. Process Successful Payment (Idempotent Payment Handler)
CREATE OR REPLACE FUNCTION public.process_successful_payment(p_order_id text)
RETURNS void AS $$
DECLARE
  v_hold_id uuid;
  v_user_id uuid;
  v_payment_status text;
  v_payment_amount numeric;
  v_hold_amount numeric;
  v_hold_status text;
  v_hold_expires_at timestamptz;
  v_booking_id uuid;
BEGIN
  -- 1. Lock payment and related hold
  SELECT
    p.hold_id, p.status, p.amount, rh.user_id, rh.total_amount, rh.status, rh.expires_at
  INTO
    v_hold_id, v_payment_status, v_payment_amount, v_user_id, v_hold_amount, v_hold_status, v_hold_expires_at
  FROM public.payments p
  JOIN public.reservation_holds rh ON p.hold_id = rh.id
  WHERE p.order_id = p_order_id
  FOR UPDATE;

  IF v_hold_id IS NULL THEN
    RAISE EXCEPTION 'Order ID % or associated hold not found', p_order_id;
  END IF;

  -- 2. Ownership & Role Validation
  IF auth.role() <> 'service_role' THEN
    IF auth.uid() IS NULL OR auth.uid() <> v_user_id THEN
      RAISE EXCEPTION 'Unauthorized: Payment can only be processed by the hold owner.';
    END IF;
  END IF;

  -- 3. Idempotency Check (Repeated webhooks do not duplicate bookings)
  IF v_payment_status = 'paid' THEN
    RETURN;
  END IF;

  -- 4. Authoritative Amount Validation
  IF v_payment_amount != v_hold_amount THEN
    RAISE EXCEPTION 'Amount mismatch: Payment initiated for % but hold requires %', v_payment_amount, v_hold_amount;
  END IF;

  IF v_hold_status != 'active' OR v_hold_expires_at < now() THEN
    RAISE EXCEPTION 'Reservation hold is no longer valid or has expired.';
  END IF;

  -- 5. Transition payment status to paid
  UPDATE public.payments
  SET status = 'paid', updated_at = now()
  WHERE order_id = p_order_id;

  -- 6. Authoritatively convert hold to booking
  v_booking_id := public._convert_hold_to_booking_internal(v_hold_id);

  -- 7. Link booking to payment record
  UPDATE public.payments
  SET booking_id = v_booking_id
  WHERE order_id = p_order_id;

  -- 8. Log Payment Event
  PERFORM public.log_booking_event(
    v_booking_id, NULL, 'PAYMENT_CONFIRMED', v_user_id, 'customer',
    jsonb_build_object('order_id', p_order_id, 'amount', v_payment_amount)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7.5. Check-In Booking RPC
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

  -- 4. Transition Sessions to checked_in
  UPDATE public.sessions
  SET
    status = 'checked_in',
    checked_in_at = v_now,
    check_in_method = p_method,
    updated_at = v_now
  WHERE booking_id = p_booking_id
    AND status = 'not_started';

  -- 5. Log Audit Event
  PERFORM public.log_booking_event(
    p_booking_id, NULL, 'CHECK_IN', auth.uid(),
    CASE WHEN v_is_owner THEN 'owner' ELSE 'customer' END,
    jsonb_build_object('method', p_method, 'checked_in_at', v_now)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7.6. Start Session Atomic RPC
CREATE OR REPLACE FUNCTION public.start_session_atomic(
  p_booking_id uuid,
  p_session_id uuid DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_booking record;
  v_settings record;
  v_now timestamptz := now();
  v_duration interval;
  v_new_end timestamptz;
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

  -- 2. Read Venue Settings
  SELECT * INTO v_settings
  FROM public.venue_booking_settings
  WHERE venue_id = v_booking.venue_id;

  v_duration := v_booking.end_time - v_booking.start_time;

  -- 3. Calculate Session End Time based on session_end_policy
  IF v_settings.session_end_policy = 'full_duration' THEN
    v_new_end := v_now + v_duration;
  ELSE
    v_new_end := v_booking.end_time;
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
    jsonb_build_object('started_at', v_now, 'scheduled_end_at', v_new_end)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7.7. End Session Atomic RPC
CREATE OR REPLACE FUNCTION public.end_session_atomic(
  p_session_id uuid,
  p_reason text DEFAULT 'normal_completion'
) RETURNS void AS $$
DECLARE
  v_session record;
  v_booking record;
  v_now timestamptz := now();
  v_remaining_active integer;
BEGIN
  -- 1. Fetch and lock session
  SELECT * INTO v_session
  FROM public.sessions
  WHERE id = p_session_id
  FOR UPDATE;

  IF v_session IS NULL THEN
    RAISE EXCEPTION 'Session not found.';
  END IF;

  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = v_session.booking_id;

  IF NOT public.is_venue_owner(v_session.venue_id) AND auth.uid() != v_booking.user_id THEN
    RAISE EXCEPTION 'Unauthorized.';
  END IF;

  -- 2. Transition Session to ended
  UPDATE public.sessions
  SET
    status = 'ended',
    ended_at = v_now,
    updated_at = v_now
  WHERE id = p_session_id;

  -- 3. Check if all sessions for this booking have ended
  SELECT count(*) INTO v_remaining_active
  FROM public.sessions
  WHERE booking_id = v_session.booking_id
    AND status IN ('not_started', 'checked_in', 'active');

  IF v_remaining_active = 0 THEN
    UPDATE public.bookings
    SET status = 'completed', updated_at = v_now
    WHERE id = v_session.booking_id;
  END IF;

  -- 4. Log Audit Event
  PERFORM public.log_booking_event(
    v_session.booking_id, p_session_id, 'SESSION_ENDED', auth.uid(),
    CASE WHEN public.is_venue_owner(v_session.venue_id) THEN 'owner' ELSE 'customer' END,
    jsonb_build_object('ended_at', v_now, 'reason', p_reason)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7.8. Extend Session Atomic RPC
CREATE OR REPLACE FUNCTION public.extend_session_atomic(
  p_session_id uuid,
  p_extra_minutes integer,
  p_extra_charge numeric DEFAULT 0.0
) RETURNS void AS $$
DECLARE
  v_session record;
  v_booking record;
  v_settings record;
  v_new_end timestamptz;
  v_conflict_count integer;
  v_buffer_after interval := interval '0 minutes';
BEGIN
  -- 1. Validate inputs
  IF p_extra_minutes <= 0 THEN
    RAISE EXCEPTION 'Extension minutes must be greater than zero.';
  END IF;

  SELECT * INTO v_session
  FROM public.sessions
  WHERE id = p_session_id
  FOR UPDATE;

  IF v_session IS NULL THEN
    RAISE EXCEPTION 'Session not found.';
  END IF;

  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = v_session.booking_id;

  IF NOT public.is_venue_owner(v_session.venue_id) THEN
    RAISE EXCEPTION 'Only venue owners/staff can extend sessions.';
  END IF;

  SELECT * INTO v_settings
  FROM public.venue_booking_settings
  WHERE venue_id = v_session.venue_id;

  v_buffer_after := (COALESCE(v_settings.buffer_after_minutes, 0) || ' minutes')::interval;
  v_new_end := v_session.scheduled_end_at + (p_extra_minutes || ' minutes')::interval;

  -- 2. Concurrency Check on Downstream Conflicts
  SELECT count(*) INTO v_conflict_count
  FROM public.booking_items bi
  JOIN public.bookings b ON bi.booking_id = b.id
  WHERE bi.service_unit_id = v_session.service_unit_id
    AND b.id != v_session.booking_id
    AND b.status IN ('confirmed', 'pending', 'active')
    AND b.start_time < (v_new_end + v_buffer_after)
    AND b.end_time > v_session.scheduled_end_at;

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'Cannot extend: this rig/resource is booked by an upcoming customer.';
  END IF;

  -- 3. Update Session and Booking Times
  UPDATE public.sessions
  SET scheduled_end_at = v_new_end, updated_at = now()
  WHERE id = p_session_id;

  UPDATE public.bookings
  SET
    end_time = GREATEST(end_time, v_new_end),
    total_amount = total_amount + p_extra_charge,
    updated_at = now()
  WHERE id = v_session.booking_id;

  -- 4. Log Audit Event
  PERFORM public.log_booking_event(
    v_session.booking_id, p_session_id, 'SESSION_EXTENDED', auth.uid(), 'owner',
    jsonb_build_object('extra_minutes', p_extra_minutes, 'extra_charge', p_extra_charge, 'new_end_time', v_new_end)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7.9. Cancel Booking Atomic RPC
CREATE OR REPLACE FUNCTION public.cancel_booking_atomic(
  p_booking_id uuid,
  p_reason text DEFAULT 'Customer requested'
) RETURNS jsonb AS $$
DECLARE
  v_booking record;
  v_settings record;
  v_is_owner boolean := false;
  v_now timestamptz := now();
  v_mins_until_start numeric;
  v_refund_percentage numeric := 100.0;
  v_refund_amount numeric := 0.0;
BEGIN
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF v_booking IS NULL THEN
    RAISE EXCEPTION 'Booking not found.';
  END IF;

  IF v_booking.status = 'cancelled' THEN
    RAISE EXCEPTION 'Booking is already cancelled.';
  END IF;

  IF v_booking.status = 'completed' THEN
    RAISE EXCEPTION 'Cannot cancel a completed booking.';
  END IF;

  v_is_owner := public.is_venue_owner(v_booking.venue_id);

  IF NOT v_is_owner AND (auth.uid() IS NULL OR auth.uid() != v_booking.user_id) THEN
    RAISE EXCEPTION 'Unauthorized.';
  END IF;

  SELECT * INTO v_settings
  FROM public.venue_booking_settings
  WHERE venue_id = v_booking.venue_id;

  -- Calculate Refund
  IF v_is_owner THEN
    v_refund_percentage := 100.0;
    v_refund_amount := v_booking.total_amount;
  ELSE
    IF NOT v_settings.cancellation_allowed THEN
      RAISE EXCEPTION 'Cancellations are not allowed by this venue.';
    END IF;

    v_mins_until_start := extract(epoch FROM (v_booking.start_time - v_now)) / 60;

    IF v_mins_until_start >= v_settings.free_cancellation_window_minutes THEN
      v_refund_percentage := COALESCE(v_settings.refund_percentage, 100.0);
      v_refund_amount := (v_booking.total_amount * (v_refund_percentage / 100.0)) - COALESCE(v_settings.cancellation_fee, 0.0);
      v_refund_amount := GREATEST(0.0, v_refund_amount);
    ELSE
      v_refund_percentage := 0.0;
      v_refund_amount := 0.0;
    END IF;
  END IF;

  -- Perform Transitions
  UPDATE public.bookings
  SET
    status = 'cancelled',
    cancel_reason = p_reason,
    updated_at = v_now
  WHERE id = p_booking_id;

  UPDATE public.sessions
  SET
    status = 'ended',
    ended_at = v_now,
    updated_at = v_now
  WHERE booking_id = p_booking_id
    AND status != 'ended';

  -- Log Audit Event
  PERFORM public.log_booking_event(
    p_booking_id, NULL, 'BOOKING_CANCELLED', auth.uid(),
    CASE WHEN v_is_owner THEN 'owner' ELSE 'customer' END,
    jsonb_build_object(
      'reason', p_reason,
      'refund_amount', v_refund_amount,
      'refund_percentage', v_refund_percentage,
      'cancelled_by_owner', v_is_owner
    )
  );

  RETURN jsonb_build_object(
    'booking_id', p_booking_id,
    'status', 'cancelled',
    'refund_amount', v_refund_amount,
    'refund_percentage', v_refund_percentage
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7.10. Reschedule Booking Atomic RPC (Atomic Slot Swap)
CREATE OR REPLACE FUNCTION public.reschedule_booking_atomic(
  p_booking_id uuid,
  p_new_start_time timestamptz,
  p_new_end_time timestamptz,
  p_new_service_unit_ids uuid[]
) RETURNS void AS $$
DECLARE
  v_booking record;
  v_settings record;
  v_conflict_count integer;
  v_is_owner boolean := false;
  v_mins_until_start numeric;
BEGIN
  -- 1. Lock existing booking
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF v_booking IS NULL THEN
    RAISE EXCEPTION 'Booking not found.';
  END IF;

  IF v_booking.status IN ('cancelled', 'completed', 'active') THEN
    RAISE EXCEPTION 'Cannot reschedule a % booking.', v_booking.status;
  END IF;

  v_is_owner := public.is_venue_owner(v_booking.venue_id);

  IF NOT v_is_owner AND (auth.uid() IS NULL OR auth.uid() != v_booking.user_id) THEN
    RAISE EXCEPTION 'Unauthorized.';
  END IF;

  -- 2. Read Venue Settings & Policy Validation
  SELECT * INTO v_settings
  FROM public.venue_booking_settings
  WHERE venue_id = v_booking.venue_id;

  IF NOT v_is_owner THEN
    IF NOT v_settings.rescheduling_allowed THEN
      RAISE EXCEPTION 'Rescheduling is not allowed by this venue.';
    END IF;

    IF v_booking.reschedule_count >= v_settings.max_reschedules THEN
      RAISE EXCEPTION 'Maximum reschedule limit reached (% allowed).', v_settings.max_reschedules;
    END IF;

    v_mins_until_start := extract(epoch FROM (v_booking.start_time - now())) / 60;
    IF v_mins_until_start < v_settings.rescheduling_cutoff_minutes THEN
      RAISE EXCEPTION 'Rescheduling cutoff passed (% mins before start required).', v_settings.rescheduling_cutoff_minutes;
    END IF;
  END IF;

  -- 3. Lock new units & check conflict
  PERFORM 1
  FROM public.service_units
  WHERE id = ANY(p_new_service_unit_ids)
  FOR UPDATE;

  SELECT count(*) INTO v_conflict_count
  FROM public.booking_items bi
  JOIN public.bookings b ON bi.booking_id = b.id
  WHERE bi.service_unit_id = ANY(p_new_service_unit_ids)
    AND b.id != p_booking_id
    AND b.status IN ('confirmed', 'pending', 'active')
    AND b.start_time < p_new_end_time
    AND b.end_time > p_new_start_time;

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'The selected new time slot is no longer available.';
  END IF;

  -- 4. Atomic Swap: Update Booking & Sessions
  UPDATE public.bookings
  SET
    start_time = p_new_start_time,
    end_time = p_new_end_time,
    reschedule_count = reschedule_count + 1,
    updated_at = now()
  WHERE id = p_booking_id;

  -- Delete old items & sessions, replace with new
  DELETE FROM public.booking_items WHERE booking_id = p_booking_id;
  DELETE FROM public.sessions WHERE booking_id = p_booking_id;

  INSERT INTO public.booking_items (booking_id, service_unit_id, price_at_booking)
  SELECT p_booking_id, su.id, su.price
  FROM public.service_units su
  WHERE su.id = ANY(p_new_service_unit_ids);

  INSERT INTO public.sessions (booking_id, venue_id, service_unit_id, status, scheduled_start_at, scheduled_end_at)
  SELECT p_booking_id, v_booking.venue_id, su.id, 'not_started', p_new_start_time, p_new_end_time
  FROM public.service_units su
  WHERE su.id = ANY(p_new_service_unit_ids);

  -- 5. Log Audit Event
  PERFORM public.log_booking_event(
    p_booking_id, NULL, 'BOOKING_RESCHEDULED', auth.uid(),
    CASE WHEN v_is_owner THEN 'owner' ELSE 'customer' END,
    jsonb_build_object(
      'new_start_time', p_new_start_time,
      'new_end_time', p_new_end_time,
      'reschedule_count', v_booking.reschedule_count + 1
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7.11. Owner Manual Walk-In Booking Creation
CREATE OR REPLACE FUNCTION public.create_owner_manual_booking_atomic(
  p_venue_id uuid,
  p_start_time timestamptz,
  p_end_time timestamptz,
  p_service_unit_ids uuid[],
  p_customer_name text,
  p_customer_phone text DEFAULT NULL,
  p_source text DEFAULT 'walk_in',
  p_notes text DEFAULT NULL,
  p_party_size integer DEFAULT 1
) RETURNS uuid AS $$
DECLARE
  v_booking_id uuid;
  v_total_amount numeric := 0.0;
  v_hours numeric;
  v_conflict_count integer;
  v_booking_code text;
  v_check_in_code text;
  v_unit_id uuid;
BEGIN
  IF NOT public.is_venue_owner(p_venue_id) THEN
    RAISE EXCEPTION 'Only authorized venue owners can create manual bookings.';
  END IF;

  v_hours := extract(epoch FROM (p_end_time - p_start_time)) / 3600;

  -- Lock service units
  PERFORM 1
  FROM public.service_units
  WHERE id = ANY(p_service_unit_ids)
  FOR UPDATE;

  -- Check conflicts
  SELECT count(*) INTO v_conflict_count
  FROM public.booking_items bi
  JOIN public.bookings b ON bi.booking_id = b.id
  WHERE bi.service_unit_id = ANY(p_service_unit_ids)
    AND b.status IN ('confirmed', 'pending', 'active')
    AND b.start_time < p_end_time
    AND b.end_time > p_start_time;

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'One or more selected resources are already booked for this time period.';
  END IF;

  SELECT sum(price) * v_hours INTO v_total_amount
  FROM public.service_units
  WHERE id = ANY(p_service_unit_ids);

  v_booking_code := 'BK-' || UPPER(SUBSTRING(gen_random_uuid()::text FROM 1 FOR 6));
  v_check_in_code := LPAD((FLOOR(RANDOM() * 9000) + 1000)::text, 4, '0');

  -- Create booking
  INSERT INTO public.bookings (
    user_id, venue_id, start_time, end_time, total_amount, status, confirmed_at, source, booking_code, check_in_code, notes
  )
  VALUES (
    auth.uid(), p_venue_id, p_start_time, p_end_time, v_total_amount, 'confirmed', now(), p_source, v_booking_code, v_check_in_code, p_notes
  )
  RETURNING id INTO v_booking_id;

  -- Create booking items & sessions
  INSERT INTO public.booking_items (booking_id, service_unit_id, price_at_booking)
  SELECT v_booking_id, su.id, su.price
  FROM public.service_units su
  WHERE su.id = ANY(p_service_unit_ids);

  FOR v_unit_id IN SELECT unnest(p_service_unit_ids) LOOP
    INSERT INTO public.sessions (
      booking_id, venue_id, service_unit_id, status, scheduled_start_at, scheduled_end_at
    )
    VALUES (
      v_booking_id, p_venue_id, v_unit_id, 'not_started', p_start_time, p_end_time
    );
  END LOOP;

  -- Add Participant
  INSERT INTO public.booking_participants (booking_id, name, phone, is_primary)
  VALUES (v_booking_id, p_customer_name, p_customer_phone, true);

  -- Log Audit Event
  PERFORM public.log_booking_event(
    v_booking_id, NULL, 'BOOKING_CREATED', auth.uid(), 'owner',
    jsonb_build_object('source', p_source, 'customer_name', p_customer_name, 'total_amount', v_total_amount)
  );

  RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7.12. Automatic Lifecycle Engine Tick RPC
CREATE OR REPLACE FUNCTION public.run_booking_lifecycle_tick()
RETURNS jsonb AS $$
DECLARE
  v_expired_holds_count integer := 0;
  v_no_shows_count integer := 0;
  v_completed_sessions_count integer := 0;
  v_now timestamptz := now();
  v_booking record;
BEGIN
  -- 1. Expire stale holds
  UPDATE public.reservation_holds
  SET status = 'expired', updated_at = v_now
  WHERE status = 'active' AND expires_at <= v_now;
  GET DIAGNOSTICS v_expired_holds_count = ROW_COUNT;

  -- 2. Process No-Shows for un-checked-in bookings whose grace period passed
  FOR v_booking IN
    SELECT b.id, b.venue_id, b.start_time, s.check_in_grace_period_minutes
    FROM public.bookings b
    JOIN public.venue_booking_settings s ON b.venue_id = s.venue_id
    WHERE b.status = 'confirmed'
      AND s.require_check_in = true
      AND s.no_show_behavior = 'automatic_release'
      AND v_now > (b.start_time + (s.check_in_grace_period_minutes || ' minutes')::interval)
      AND NOT EXISTS (
        SELECT 1 FROM public.sessions ses
        WHERE ses.booking_id = b.id
          AND ses.status IN ('checked_in', 'active', 'ended')
      )
  LOOP
    UPDATE public.bookings
    SET status = 'no_show', updated_at = v_now
    WHERE id = v_booking.id;

    UPDATE public.sessions
    SET status = 'ended', ended_at = v_now, updated_at = v_now
    WHERE booking_id = v_booking.id;

    PERFORM public.log_booking_event(
      v_booking.id, NULL, 'NO_SHOW', NULL, 'system',
      jsonb_build_object('reason', 'Grace period expired without check-in', 'detected_at', v_now)
    );

    v_no_shows_count := v_no_shows_count + 1;
  END LOOP;

  -- 3. Complete expired active sessions
  UPDATE public.sessions
  SET status = 'ended', ended_at = scheduled_end_at, updated_at = v_now
  WHERE status = 'active' AND scheduled_end_at <= v_now;
  GET DIAGNOSTICS v_completed_sessions_count = ROW_COUNT;

  -- Update bookings where all sessions are ended
  UPDATE public.bookings b
  SET status = 'completed', updated_at = v_now
  WHERE b.status = 'active'
    AND NOT EXISTS (
      SELECT 1 FROM public.sessions ses
      WHERE ses.booking_id = b.id AND ses.status IN ('not_started', 'checked_in', 'active')
    );

  RETURN jsonb_build_object(
    'expired_holds', v_expired_holds_count,
    'no_shows', v_no_shows_count,
    'completed_sessions', v_completed_sessions_count,
    'tick_time', v_now
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. REALTIME REPLICATION CONFIGURATION
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'sessions') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sessions;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'booking_events') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_events;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'booking_participants') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_participants;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'venue_booking_settings') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.venue_booking_settings;
  END IF;
END $$;

ALTER TABLE public.sessions REPLICA IDENTITY FULL;
ALTER TABLE public.booking_events REPLICA IDENTITY FULL;
ALTER TABLE public.venue_booking_settings REPLICA IDENTITY FULL;
ALTER TABLE public.booking_participants REPLICA IDENTITY FULL;
