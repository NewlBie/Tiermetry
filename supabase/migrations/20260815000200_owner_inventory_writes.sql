-- Migration: 20260815000200_owner_inventory_writes.sql
-- Step 3F: Controlled owner write access for services and service_units.
--
-- Enables authenticated venue owners to:
-- 1. Insert, update, and safely delete services belonging to their own venue.
-- 2. Insert, update (including operational status), and safely delete service_units belonging to their own services.
--
-- Dependency / Safety Invariant:
-- Physical deletion of a service_unit is permitted ONLY when zero booking_items reference it.
-- Units with historical bookings must be retired (status = 'retired') rather than deleted.
-- Physical deletion of a service is permitted ONLY when none of its service units have historical bookings.
--
-- All existing customer SELECT policies remain unchanged.
-- Booking, concurrency, and payment functions remain untouched.

-- ============================================================================
-- 1. SERVICES WRITE POLICIES
-- ============================================================================

-- Owner INSERT on services
-- Allowed only if the service's venue is owned by the authenticated user.
CREATE POLICY "Owners can insert services for their own venue"
  ON public.services
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_venue_owner(venue_id)
  );

-- Owner UPDATE on services
-- Allowed only if both the existing row and the new row belong to the authenticated owner's venue.
-- Prevents reassigning services across venues.
CREATE POLICY "Owners can update their own venue's services"
  ON public.services
  FOR UPDATE
  TO authenticated
  USING (
    public.is_venue_owner(venue_id)
  )
  WITH CHECK (
    public.is_venue_owner(venue_id)
  );

-- Owner DELETE on services
-- Allowed only if the venue is owned by the authenticated user AND none of the attached service units
-- have historical booking records in booking_items.
CREATE POLICY "Owners can delete their own venue's services without booking history"
  ON public.services
  FOR DELETE
  TO authenticated
  USING (
    public.is_venue_owner(venue_id)
    AND NOT EXISTS (
      SELECT 1
      FROM public.service_units su
      JOIN public.booking_items bi ON bi.service_unit_id = su.id
      WHERE su.service_id = services.id
    )
  );

-- ============================================================================
-- 2. SERVICE UNITS WRITE POLICIES
-- ============================================================================

-- Owner INSERT on service_units
-- Allowed only if the referenced service belongs to a venue owned by the authenticated user.
CREATE POLICY "Owners can insert service units for their own services"
  ON public.service_units
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.services s
      WHERE s.id = service_units.service_id
        AND public.is_venue_owner(s.venue_id)
    )
  );

-- Owner UPDATE on service_units
-- Allowed only if both the existing service and the new service belong to the authenticated owner's venue.
-- Allows updating name, description, price, image, and operational status ('available', 'maintenance', 'retired').
-- Prevents moving units to another owner's service or venue.
CREATE POLICY "Owners can update their own venue's service units"
  ON public.service_units
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.services s
      WHERE s.id = service_units.service_id
        AND public.is_venue_owner(s.venue_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.services s
      WHERE s.id = service_units.service_id
        AND public.is_venue_owner(s.venue_id)
    )
  );

-- Owner DELETE on service_units
-- Allowed only if the service belongs to the owner's venue AND zero booking_items reference this unit.
-- Units with booking history must be retired (status = 'retired') instead.
CREATE POLICY "Owners can delete their own venue's service units without booking history"
  ON public.service_units
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.services s
      WHERE s.id = service_units.service_id
        AND public.is_venue_owner(s.venue_id)
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.booking_items bi
      WHERE bi.service_unit_id = service_units.id
    )
  );
