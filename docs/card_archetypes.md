# Tiermetry Card Archetypes

## Venue/Arena Card

- Job: help the user choose a place.
- First cue: image of the place/activity environment plus distance/open state.
- Metadata: rating, distance, availability, starting price.
- Action: `View slots`.
- Avoid: date-first layouts unless showing a specific event inside a venue.

## Event Card

- Job: help the user choose a scheduled occurrence.
- First cue: date rail or calendar block.
- Metadata: start time, venue/location, cost, availability.
- Action: `Get tickets`, `Remind me`, or `Join`.
- Missing image behavior: keep date rail, title, time, and action visible.

## Skill/Class Card

- Job: help the user choose a guided learning session.
- First cue: category, instructor/provider, level, duration.
- Metadata: level, duration, rating, next session.
- Action: `Enroll`.
- Avoid: making it look like a venue by leading only with place imagery.

## Activity Shortcut

- Job: route the user into a category.
- First cue: icon or symbol.
- Metadata: short label and optional count.
- Action: tile tap.
- Repetition is acceptable here because all tiles have the same job.

## Booking Row

- Job: manage an existing plan.
- First cue: status and confirmation.
- Metadata: date/time, people, venue, payment or ticket state.
- Action: `Manage`.
- Avoid: discovery-card visuals; bookings are operational.

## Community Card

- Job: help the user find people to do an activity with.
- First cue: shared-interest symbol plus member or local status.
- Metadata: actual member count, city, category, and joined state.
- Action: `View community`, followed by one clear join or leave action on details.
- Details: use an action-first hierarchy: compact community and host identity, one date-led `Next up` Community Plan with meeting point, skill level, capacity, RSVP state, and what-to-bring guidance, then progressive disclosure for About, purpose, and guidelines, followed by the latest creator announcement. Use golden-ratio typography tokens, generous whitespace, solid tonal surfaces, and no gradients or decorative outlines. Every join, RSVP, plan, and update action explains what happens next; creator updates remain announcements rather than an infinite social feed.
- Ownership: the current creator can transfer the sole host role to an existing member or permanently delete the community through an explicit confirmation flow; both actions remain server-authoritative.
- Avoid: venue pricing cues, event date rails, chat-channel complexity, and every form of paid access or promotion.
