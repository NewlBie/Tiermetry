# Tiermetry Home UI Contract

## Core Diagnosis

Tiermetry already has a strong visual family: dark surfaces, bright accents, heavy display type, rounded containers, and energetic imagery. The risk is semantic flattening: too many different objects use the same visual sentence of image, title, metadata, and pill.

The system should be unified through shared foundations, not identical card composition.

Use this ratio:

- 70% shared brand foundations.
- 20% content-type-specific structure.
- 10% campaign or promotional personality.

## Semantic Archetypes

| Type | User Question | Required Recognition Cue | Recommended Shape | Primary Metadata | Action |
|---|---|---|---|---|---|
| Venue/Arena | Where can I go? | Distance/open status | Wide 4:3 card | Rating, distance, price, availability | View slots |
| Event | When is it happening? | Date rail or calendar block | Ticket-like horizontal card | Date, time, venue, cost | Get tickets |
| Skill/Class | What can I learn? | Category/instructor/session cue | Taller editorial card | Level, duration, next session | Enroll |
| Activity Shortcut | What category should I browse? | Icon/symbol first | Compact tile | Label, optional count | Explore |
| Booking | What have I already reserved? | Status and confirmation structure | Compact row | Date, people, venue, status | Manage |
| Premium Promotion | Why upgrade? | One benefit-led hero surface | Full-width panel | Short benefit copy | Upgrade |

## Differentiation Rule

Before adding or changing a card, identify the content type and provide at least three non-color differentiators:

- Silhouette or aspect ratio.
- Fixed cue placement.
- Metadata order.
- Image role.
- Primary action language.
- Section composition.
- Empty/loading/error behavior.

If the only difference is copy or color, the design is not sufficiently semantic.

## Home Sequence

Recommended Home order:

1. Greeting and location context.
2. Intent search or mode entry.
3. Compact quick routes.
4. Next booking, only when available.
5. Live Around You.
6. Events This Week.
7. Trending Activities.
8. Featured Skills.
9. Curated collection or Premium prompt.

This sequence lets the user understand the app, act quickly, browse useful inventory, then consider deeper discovery or upgrades.

## Implementation Rules

- Prefer shared primitives over shared full-card layouts.
- Shared primitives may include surfaces, media frames, metadata rows, badges, price labels, and section headers.
- Full card layouts should remain semantic: event cards should not inherit from venue cards, and skill cards should not inherit from event cards.
- Missing images must preserve the content type cue. For example, event date rails remain visible even when images fail.
- Promotional sections should appear after at least one useful inventory section.

## Review Checklist

- Can a user classify the object without reading the title?
- Does the first visible cue match the user job?
- Does the component still work in grayscale?
- Does it survive long names, missing images, empty states, and loading states?
- Does it use existing tokens where practical?
- Does the section have one clear purpose?
