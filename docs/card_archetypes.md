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
