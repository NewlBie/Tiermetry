-- Migration 20260813000000: Implement Events and Event Registrations
-- This migration creates the core Events schema and a secure registration RPC.

-- 1. Create events table
CREATE TABLE IF NOT EXISTS public.events (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  title text NOT NULL,
  description text,
  image text,
  venue_id uuid REFERENCES public.venues(id) ON DELETE SET NULL,
  start_time timestamp with time zone NOT NULL,
  end_time timestamp with time zone NOT NULL,
  registration_start timestamp with time zone NOT NULL,
  registration_end timestamp with time zone NOT NULL,
  max_participants integer,
  registration_type text DEFAULT 'individual' CHECK (registration_type IN ('individual', 'team')),
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'cancelled', 'completed')),
  cost text DEFAULT 'Free',
  points integer DEFAULT 0,
  tags text[] DEFAULT '{}',
  perks jsonb DEFAULT '[]',
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create event_registrations table
CREATE TABLE IF NOT EXISTS public.event_registrations (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id uuid REFERENCES public.events(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status text DEFAULT 'registered' CHECK (status IN ('registered', 'attended', 'cancelled')),
  registered_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(event_id, user_id) -- Prevent duplicate registration
);

-- 3. Enable RLS
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- Events are public if published
DROP POLICY IF EXISTS "Anyone can view published events" ON public.events;
CREATE POLICY "Anyone can view published events"
  ON public.events FOR SELECT
  USING (status = 'published');

-- Registrations are private to the user
DROP POLICY IF EXISTS "Users can view their own registrations" ON public.event_registrations;
CREATE POLICY "Users can view their own registrations"
  ON public.event_registrations FOR SELECT
  USING (auth.uid() = user_id);

-- 5. Secure Event Registration RPC
-- Hardened for Tiermetry architecture: uses locking and server-side validation.
CREATE OR REPLACE FUNCTION public.register_for_event(p_event_id uuid)
RETURNS uuid AS $$
DECLARE
  v_event record;
  v_registration_id uuid;
  v_current_enrollments integer;
BEGIN
  -- 1. Authentication Check
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 2. Lock event row to prevent capacity race conditions
  SELECT * INTO v_event
  FROM public.events
  WHERE id = p_event_id
  FOR UPDATE;

  -- 3. Integrity Checks
  IF v_event IS NULL THEN
    RAISE EXCEPTION 'Event not found';
  END IF;

  IF v_event.status != 'published' THEN
    RAISE EXCEPTION 'Registration is not available for this event';
  END IF;

  -- 4. Registration Window Validation
  IF now() < v_event.registration_start THEN
    RAISE EXCEPTION 'Registration has not opened yet';
  END IF;

  IF now() > v_event.registration_end THEN
    RAISE EXCEPTION 'Registration has closed';
  END IF;

  -- 5. Capacity Validation
  IF v_event.max_participants IS NOT NULL THEN
    SELECT count(*) INTO v_current_enrollments
    FROM public.event_registrations
    WHERE event_id = p_event_id
      AND status = 'registered';

    IF v_current_enrollments >= v_event.max_participants THEN
      RAISE EXCEPTION 'Event is full';
    END IF;
  END IF;

  -- 6. Duplicate Prevention
  IF EXISTS (
    SELECT 1 FROM public.event_registrations
    WHERE event_id = p_event_id
      AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'You are already registered for this event';
  END IF;

  -- 7. Atomic Insert
  INSERT INTO public.event_registrations (event_id, user_id)
  VALUES (p_event_id, auth.uid())
  RETURNING id INTO v_registration_id;

  RETURN v_registration_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6. Permissions Hardening
REVOKE ALL ON FUNCTION public.register_for_event(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.register_for_event(uuid) TO authenticated;

-- 7. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_event_registrations_event_id ON public.event_registrations(event_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_user_id ON public.event_registrations(user_id);
CREATE INDEX IF NOT EXISTS idx_events_status ON public.events(status);
CREATE INDEX IF NOT EXISTS idx_events_start_time ON public.events(start_time);
