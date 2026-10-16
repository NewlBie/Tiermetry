-- Migration 20260815000000: Add Venue Ownership (Corrected)
-- Add nullable owner_id column to venues table, create index, helper function, and owner update/delete policies.

-- 1. Add owner_id to venues table referencing public.profiles(id)
ALTER TABLE public.venues
ADD COLUMN owner_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 2. Create index on public.venues(owner_id)
CREATE INDEX IF NOT EXISTS idx_venues_owner_id ON public.venues(owner_id);

-- 3. Create helper function to check venue ownership
CREATE OR REPLACE FUNCTION public.is_venue_owner(p_venue_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Return false if the user is not authenticated
  IF auth.uid() IS NULL THEN
    RETURN false;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.venues
    WHERE id = p_venue_id
      AND owner_id = auth.uid()
  );
END;
$$;

-- 4. Add owner access policies (update, delete) to venues
-- Existing policy: "Public venues are viewable by everyone" remains untouched.
-- INSERT access is NOT allowed for anyone (must be controlled administratively).

CREATE POLICY "Owners can update their own venues" ON public.venues
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can delete their own venues" ON public.venues
  FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);
