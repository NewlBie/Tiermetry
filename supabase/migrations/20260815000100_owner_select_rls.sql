-- Migration: 20260815000100_owner_select_rls.sql
-- Step 2A: Read-only owner SELECT access for child tables.
--
-- Adds owner SELECT policies for: services, service_units, bookings,
-- booking_items, and payments.
--
-- All policies are PERMISSIVE and additive -- existing customer policies
-- are preserved and unchanged.
--
-- Uses is_venue_owner(venue_id) from migration 20260815000000_add_venue_ownership.sql.
-- No new helper functions are required.
--
-- CRITICAL: Does NOT add owner INSERT / UPDATE / DELETE on any table.
-- Does NOT modify booking, reservation, or payment business logic functions.

-- Indexes
-- These indexes support the new owner SELECT predicate traversal paths.

-- services: owner queries services by venue_id
CREATE INDEX IF NOT EXISTS idx_services_venue_id
  ON public.services (venue_id);

-- booking_items: owner queries booking_items by booking_id
CREATE INDEX IF NOT EXISTS idx_booking_items_booking_id
  ON public.booking_items (booking_id);

-- payments: owner queries payments by booking_id
CREATE INDEX IF NOT EXISTS idx_payments_booking_id
  ON public.payments (booking_id);

-- Owner SELECT Policies

-- services
-- Ownership path: services.venue_id -> venues.owner_id = auth.uid()
CREATE POLICY "Owners can view their venue's services"
  ON public.services
  FOR SELECT
  USING (
    public.is_venue_owner(venue_id)
  );

-- service_units
-- Ownership path: service_units.service_id -> services.venue_id -> venues.owner_id
-- NOTE: service_units has no venue_id column; traversal goes through services.
CREATE POLICY "Owners can view their venue's service units"
  ON public.service_units
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.services s
      WHERE s.id = service_units.service_id
        AND public.is_venue_owner(s.venue_id)
    )
  );

-- bookings
-- Ownership path: bookings.venue_id -> venues.owner_id = auth.uid()
-- Customer policy ("Users can view their own bookings") is preserved unchanged.
CREATE POLICY "Owners can view their venue's bookings"
  ON public.bookings
  FOR SELECT
  USING (
    public.is_venue_owner(venue_id)
  );

-- booking_items
-- Ownership path: booking_items.booking_id -> bookings.venue_id -> venues.owner_id
-- Customer policy ("Users can view their own booking items") is preserved unchanged.
CREATE POLICY "Owners can view their venue's booking items"
  ON public.booking_items
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.bookings b
      WHERE b.id = booking_items.booking_id
        AND public.is_venue_owner(b.venue_id)
    )
  );

-- payments
-- Ownership path: payments.booking_id -> bookings.venue_id -> venues.owner_id
-- NOTE: payments has no venue_id column.
-- NOTE: booking_id is nullable (null during active reservation hold phase).
--       The booking_id IS NOT NULL guard ensures owners only see confirmed
--       payments and not in-flight pre-booking hold payments.
-- Customer policies are preserved unchanged.
CREATE POLICY "Owners can view their venue's payments"
  ON public.payments
  FOR SELECT
  USING (
    booking_id IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM public.bookings b
      WHERE b.id = payments.booking_id
        AND public.is_venue_owner(b.venue_id)
    )
  );
