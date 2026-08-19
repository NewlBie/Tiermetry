-- Migration 20260818214600: Add create_venue_for_owner RPC
-- Creates a new venue for the authenticated owner and initializes default settings.

CREATE OR REPLACE FUNCTION public.create_venue_for_owner(
  p_name text,
  p_address text DEFAULT ''
) RETURNS uuid AS $$
DECLARE
  v_venue_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO public.venues (id, name, description, address, owner_id, rating, review_count, is_open, price_tier, is_verified)
  VALUES (
    gen_random_uuid(),
    p_name,
    'Recreational Venue',
    p_address,
    auth.uid(),
    5.0,
    0,
    true,
    1,
    true
  )
  RETURNING id INTO v_venue_id;

  -- Create default booking settings for the new venue
  INSERT INTO public.venue_booking_settings (venue_id)
  VALUES (v_venue_id)
  ON CONFLICT (venue_id) DO NOTHING;

  RETURN v_venue_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
