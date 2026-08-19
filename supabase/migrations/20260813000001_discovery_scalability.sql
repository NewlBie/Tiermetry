-- Migration 20260813000001: Discovery Scalability Indexes
-- This migration adds performance indexes for search, filtering, and sorting in discovery surfaces.

-- Enable pg_trgm extension for fuzzy searching
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 1. Venues (Arena) Performance Indexes
-- B-tree indexes for filtering and sorting
CREATE INDEX IF NOT EXISTS idx_venues_activity ON public.venues(activity);
CREATE INDEX IF NOT EXISTS idx_venues_price_tier ON public.venues(price_tier);
CREATE INDEX IF NOT EXISTS idx_venues_rating ON public.venues(rating DESC);
CREATE INDEX IF NOT EXISTS idx_venues_is_open ON public.venues(is_open);

-- GIN Trigram indexes for efficient ILIKE searching
-- We use gin_trgm_ops for columns involved in the search OR clause
CREATE INDEX IF NOT EXISTS idx_venues_name_trgm ON public.venues USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_venues_short_address_trgm ON public.venues USING gin (short_address gin_trgm_ops);

-- 2. Events Performance Indexes
-- B-tree indexes for filtering and sorting (status and start_time already indexed in previous migration)
CREATE INDEX IF NOT EXISTS idx_events_points ON public.events(points);

-- GIN Trigram indexes for efficient ILIKE searching
CREATE INDEX IF NOT EXISTS idx_events_title_trgm ON public.events USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_events_description_trgm ON public.events USING gin (description gin_trgm_ops);

-- Index for the 'cost' filter which uses ILIKE '%free%'
CREATE INDEX IF NOT EXISTS idx_events_cost_trgm ON public.events USING gin (cost gin_trgm_ops);

-- 3. Composite/Specialized Indexes
-- For event search by venue (via joined venues table in queries)
-- venue_id is already a FK, but we ensure it's indexed for the join
CREATE INDEX IF NOT EXISTS idx_events_venue_id ON public.events(venue_id);
