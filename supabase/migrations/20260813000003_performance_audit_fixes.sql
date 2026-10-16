-- Migration 20260813000003: Performance Audit Fixes
-- This migration adds missing indexes identified during the performance audit.

-- 1. Reservation Holds Indexes
-- Critical for get_available_units and create_reservation_hold_atomic
CREATE INDEX IF NOT EXISTS idx_reservation_hold_items_unit_id ON public.reservation_hold_items(service_unit_id);
CREATE INDEX IF NOT EXISTS idx_reservation_holds_active_range ON public.reservation_holds(status, expires_at, start_time, end_time)
  WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_reservation_holds_user_id ON public.reservation_holds(user_id);

-- 2. Venues/Arena Indexes
-- is_verified is often used in filtering or display logic
CREATE INDEX IF NOT EXISTS idx_venues_verified ON public.venues(is_verified);

-- 3. Bookings Indexes
-- status and user_id are frequently queried
CREATE INDEX IF NOT EXISTS idx_bookings_user_status ON public.bookings(user_id, status);

-- 4. Events Indexes
-- registration window checks in register_for_event
CREATE INDEX IF NOT EXISTS idx_events_registration_window ON public.events(registration_start, registration_end);
