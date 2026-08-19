-- Migration: 20260815000500_enable_realtime_for_booking_engine.sql
-- Enables Supabase Realtime for the Universal Booking & Session Engine tables.

DO $$
BEGIN
  -- Add public.sessions
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'sessions') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sessions;
  END IF;

  -- Add public.booking_events
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'booking_events') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_events;
  END IF;

  -- Add public.venue_booking_settings
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'venue_booking_settings') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.venue_booking_settings;
  END IF;

  -- Add public.payments
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'payments') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;
  END IF;

  -- bookings and booking_items were added in 20260815000300, but checking defensively
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'bookings') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'booking_items') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_items;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'service_units') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.service_units;
  END IF;
END $$;

-- Set Replica Identity for tables that require non-PK columns for RLS evaluation on UPDATE/DELETE
ALTER TABLE public.sessions REPLICA IDENTITY FULL;
ALTER TABLE public.booking_events REPLICA IDENTITY FULL;
ALTER TABLE public.payments REPLICA IDENTITY FULL;
ALTER TABLE public.bookings REPLICA IDENTITY FULL;

-- venue_booking_settings has venue_id as PK, so DEFAULT is sufficient for RLS evaluation.
-- booking_items has DEFAULT (PK only) since RLS is likely basic or inherited.
-- service_units uses DEFAULT if it doesn't need full old row for RLS on update/delete.
