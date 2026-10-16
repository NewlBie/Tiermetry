-- Migration: 20260815000300_fix_booking_realtime.sql
-- Step 3E: Fix Booking Realtime Publication
--
-- This migration enables Supabase Realtime for the bookings and booking_items tables.
-- It also sets REPLICA IDENTITY FULL for the bookings table to support venue_id filtering
-- on UPDATE and DELETE events in the Owner application.

-- 1. Enable Realtime for bookings and booking_items
-- We add them to the supabase_realtime publication if not already present.
-- Note: Supabase creates this publication by default.

DO $$
BEGIN
  -- Add public.bookings to supabase_realtime
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND schemaname = 'public'
    AND tablename = 'bookings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
  END IF;

  -- Add public.booking_items to supabase_realtime
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND schemaname = 'public'
    AND tablename = 'booking_items'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_items;
  END IF;
END $$;

-- 2. Set Replica Identity for bookings
-- Full replica identity ensures that the venue_id (and other columns)
-- are included in UPDATE and DELETE event payloads, allowing filters to work.
ALTER TABLE public.bookings REPLICA IDENTITY FULL;

-- Note: booking_items does not currently use a venue_id filter in the Owner app,
-- so DEFAULT replica identity (PK only) remains sufficient for now.
