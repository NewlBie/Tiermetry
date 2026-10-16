-- Migration 20260813000002: Discovery Optimization
-- Adds indexes and search capabilities to venues and events tables.

-- 1. Enable pg_trgm extension for fuzzy ilike search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. Venues Optimization
-- Index for activity filtering
CREATE INDEX IF NOT EXISTS idx_venues_activity ON public.venues(activity);

-- Index for rating/sorting
CREATE INDEX IF NOT EXISTS idx_venues_rating ON public.venues(rating DESC);

-- Trigram index for fuzzy search on name and location
CREATE INDEX IF NOT EXISTS idx_venues_name_trgm ON public.venues USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_venues_location_trgm ON public.venues USING gin (short_address gin_trgm_ops);

-- 3. Events Optimization
-- Index for status filtering (already exists in 000000 but good to ensure)
CREATE INDEX IF NOT EXISTS idx_events_status ON public.events(status);

-- Index for start_time sorting (already exists in 000000)
CREATE INDEX IF NOT EXISTS idx_events_start_time ON public.events(start_time);

-- Index for points sorting
CREATE INDEX IF NOT EXISTS idx_events_points ON public.events(points DESC);

-- Trigram index for fuzzy search on title
CREATE INDEX IF NOT EXISTS idx_events_title_trgm ON public.events USING gin (title gin_trgm_ops);
