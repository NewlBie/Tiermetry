# Implementation Plan: Production-Scalable Search, Filtering & Pagination

Audit and implement production-scalable discovery systems for Arena and Events, ensuring performance with larger datasets while maintaining the existing architecture.

## User Review Required

> [!IMPORTANT]
> **Search Strategy:** I am proposing using PostgreSQL GIN indexes with `pg_trgm` for efficient `ilike` searching. This avoids the complexity of Full Text Search while being significantly faster than unindexed scans.
> **Sorting:** The "Nearest" sort for Arenas currently defaults to name-based sorting as server-side distance calculation requires geospatial functions (PostGIS) or client-side location passing. I will stick to name-based sorting for now to avoid introducing new dependencies.

## Proposed Changes

### Database Layer

#### [NEW] [20260813000001_discovery_scalability.sql](file:///C:/Users/Neal/StudioProjects/tiermetry/supabase/migrations/20260813000001_discovery_scalability.sql)
Create indexes to support efficient filtering, sorting, and search for venues and events.

### Arena Module

#### [MODIFY] [arena_repo_impl.dart](file:///C:/Users/Neal/StudioProjects/tiermetry/lib/features/arena/data/repositories/arena_repo_impl.dart)
- Refine `getArenas` to ensure stable sorting by always appending `id` to the order clause.
- Ensure all filters are applied correctly before pagination.

#### [MODIFY] [arena_screen.dart](file:///C:/Users/Neal/StudioProjects/tiermetry/lib/features/arena/presentation/screens/arena_screen.dart)
- Update the empty state to provide "Clear Filters" action when no matches are found.

### Event Module

#### [MODIFY] [event_repo_impl.dart](file:///C:/Users/Neal/StudioProjects/tiermetry/lib/features/event/data/repositories/event_repo_impl.dart)
- Refine the "Online" category filter to be more robust.
- Ensure stable sorting.

#### [MODIFY] [event_browser_screen.dart](file:///C:/Users/Neal/StudioProjects/tiermetry/lib/features/event/presentation/screens/event_browser_screen.dart)
- Update the empty state to provide "Clear Filters" action.

## Verification Plan

### Automated Tests
- No new automated tests requested, but will verify via UI.

### Manual Verification
- **Pagination:** Scroll to the bottom of Arena and Event lists and verify "Load More" triggers and appends data.
- **Search:** Search for specific venues/events and verify results are relevant and debounced correctly.
- **Filtering:** Change categories and verify the list updates.
- **Refresh:** Pull-to-refresh and verify it resets pagination and fetches fresh data.
- **Empty States:** Filter with a string that won't match anything and verify the "No matching found" state with a clear action.
