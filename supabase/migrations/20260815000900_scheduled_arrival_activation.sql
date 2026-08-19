-- Migration: 20260815000900_scheduled_arrival_activation.sql
-- Separates early arrival verification (ARRIVED) from scheduled activation (ACTIVE)

-- 1. Update check_in_booking to only auto-start if the scheduled time has arrived
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

  -- 4. Mark Sessions as Checked In
  UPDATE public.sessions
  SET
    status = 'checked_in',
    checked_in_at = COALESCE(checked_in_at, v_now),
    check_in_method = p_method,
    updated_at = v_now
  WHERE booking_id = p_booking_id
    AND status = 'not_started';

  -- 5. Log Audit Event for successful credential verification
  PERFORM public.log_booking_event(
    p_booking_id, NULL, 'CHECK_IN', auth.uid(),
    CASE WHEN v_is_owner THEN 'owner' ELSE 'customer' END,
    jsonb_build_object('method', p_method, 'checked_in_at', v_now, 'is_early', v_now < v_booking.start_time)
  );

  -- 6. Atomically Start Session IF scheduled time has arrived
  IF v_now >= v_booking.start_time THEN
    PERFORM public.start_session_atomic(p_booking_id, NULL, true);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Update run_booking_lifecycle_tick to auto-start mature checked-in sessions
CREATE OR REPLACE FUNCTION public.run_booking_lifecycle_tick()
RETURNS jsonb AS $$
DECLARE
  v_expired_holds_count integer := 0;
  v_no_shows_count integer := 0;
  v_completed_sessions_count integer := 0;
  v_auto_started_count integer := 0;
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
    WHERE b.status IN ('confirmed', 'upcoming', 'pending')
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

  -- 3. Auto-start 'checked_in' bookings whose scheduled start time has arrived
  FOR v_booking IN
    SELECT DISTINCT b.id
    FROM public.bookings b
    JOIN public.sessions ses ON b.id = ses.booking_id
    WHERE ses.status = 'checked_in'
      AND b.start_time <= v_now
      AND b.status != 'active'
  LOOP
    BEGIN
      -- Invoke the safe atomic start method for each arrived booking
      PERFORM public.start_session_atomic(v_booking.id, NULL, true);
      v_auto_started_count := v_auto_started_count + 1;
    EXCEPTION WHEN OTHERS THEN
      -- If one fails (e.g. conflict fallback failure), log it and continue so the tick doesn't die
      PERFORM public.log_booking_event(
        v_booking.id, NULL, 'SYSTEM_ERROR', NULL, 'system',
        jsonb_build_object('action', 'auto_start_arrived', 'error', SQLERRM)
      );
    END;
  END LOOP;

  -- 4. Complete expired active sessions
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
    'auto_started_sessions', v_auto_started_count,
    'completed_sessions', v_completed_sessions_count,
    'tick_time', v_now
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
