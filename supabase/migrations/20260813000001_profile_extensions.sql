-- Migration 20260813000001: Extend Profiles table
-- Adds missing fields required by the UI while maintaining RLS security.

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS avatar_url text,
ADD COLUMN IF NOT EXISTS location text,
ADD COLUMN IF NOT EXISTS level text DEFAULT 'Beginner',
ADD COLUMN IF NOT EXISTS tier text DEFAULT 'Bronze I',
ADD COLUMN IF NOT EXISTS tier_progress numeric DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS tiergies numeric DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS age integer;

-- Ensure RLS is still strictly enforced
-- Users can only UPDATE their own profile
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
