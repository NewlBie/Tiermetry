-- Migration: 20260815000600_production_hardening_fixes.sql
-- Hardens Universal Booking Engine: Conflict detection on full duration,
-- missing settings columns, pg_cron scheduling for lifecycle engine,
-- and comprehensive idempotent Supabase Realtime publication setup.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. EXTEND VENUE BOOKING SETTINGS WITH MISSING PERSISTED COLUMNS
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'venue_booking_settings' AND column_name = 'require_waiver_signature') THEN
    ALTER TABLE public.venue_booking_settings ADD COLUMN require_waiver_signature boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'venue_booking_settings' AND column_name = 'off_peak_discount_percentage') THEN
    ALTER TABLE public.venue_booking_settings ADD COLUMN off_peak_discount_percentage numeric DEFAULT 0.0 CHECK (off_peak_discount_percentage BETWEEN 0 AND 100);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'venue_booking_settings' AND column_name = 'enable_waitlist_auto_promotion') THEN
    ALTER TABLE public.venue_booking_settings ADD COLUMN enable_waitlist_auto_promotion boolean DEFAULT false;
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. ENSURE BOOKINGS STATUS CONSTRAINT SUPPORTS ALL SERVER-AUTHORITATIVE STATES
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_status_check;
ALTER TABLE public.bookings ADD CONSTRAINT bookings_status_check
  CHECK (status IN ('pending', 'confirmed', 'active', 'cancelled', 'completed', 'expired', 'no_show'));

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. HARDEN start_session_atomic WITH DOWNSTREAM CONFLICT PREVENTION
-- ─────────────────────────────────────────────────────────────────────────────

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
    jsonb_build_object(
      'started_at', v_now,
      'scheduled_end_at', v_new_end,
      'policy_applied', v_policy_applied,
      'downstream_conflict_avoided', (v_conflict_count > 0)
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. SCHEDULE SERVER-AUTHORITATIVE LIFECYCLE RECONCILIATION CRON
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  -- Check if pg_cron extension exists
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- Unschedule existing job if already registered to prevent duplicates
    PERFORM cron.unschedule('booking-lifecycle-tick-job')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'booking-lifecycle-tick-job');

    -- Schedule lifecycle reconciliation tick to run every minute
    PERFORM cron.schedule(
      'booking-lifecycle-tick-job',
      '* * * * *',
      'SELECT public.run_booking_lifecycle_tick()'
    );
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- Non-fatal if pg_cron permissions or extension is handled at DB manager level
  RAISE NOTICE 'pg_cron job scheduling skipped or not supported in current role context: %', SQLERRM;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. COMPLETE IDEMPOTENT SUPABASE REALTIME PUBLICATION SETUP
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  -- bookings
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'bookings') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
  END IF;

  -- booking_items
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'booking_items') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_items;
  END IF;

  -- sessions
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'sessions') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sessions;
  END IF;

  -- booking_events
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'booking_events') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_events;
  END IF;

  -- venue_booking_settings
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'venue_booking_settings') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.venue_booking_settings;
  END IF;

  -- payments
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'payments') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;
  END IF;

  -- service_units
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'service_units') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.service_units;
  END IF;

  -- booking_participants
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'booking_participants') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_participants;
  END IF;
END $$;

-- Set REPLICA IDENTITY FULL for tables where RLS queries non-PK columns on UPDATE/DELETE
ALTER TABLE public.bookings REPLICA IDENTITY FULL;
ALTER TABLE public.sessions REPLICA IDENTITY FULL;
ALTER TABLE public.booking_events REPLICA IDENTITY FULL;
ALTER TABLE public.payments REPLICA IDENTITY FULL;
ALTER TABLE public.venue_booking_settings REPLICA IDENTITY FULL;
ALTER TABLE public.booking_participants REPLICA IDENTITY FULL;
