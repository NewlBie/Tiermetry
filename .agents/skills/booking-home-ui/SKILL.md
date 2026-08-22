---
name: booking-home-ui
description: Design, implement, or review Tiermetry homepage UI, discovery sections, event cards, arena cards, skill cards, activity shortcuts, booking rows, premium surfaces, or navigation hierarchy. Use when changing Flutter UI for recreational booking experiences, card archetypes, visual hierarchy, Home screen sections, or premium marketplace feel.
---

# Booking Home UI Workflow

1. Read the relevant design docs before changing UI:
   - `docs/design/home_ui_contract.md`
   - `docs/design/card_archetypes.md`
   - `docs/design/homepage_architecture.md`

2. Identify the content object before choosing a component:
   - Scheduled occurrence: event card.
   - Persistent place: venue/arena card.
   - Guided learning: skill/class card.
   - Category entry: activity shortcut.
   - Existing reservation: booking row.
   - Upgrade message: premium promotion.

3. Do not create a universal card for unrelated object types.

4. Confirm at least three non-color differentiators:
   - Silhouette or aspect ratio.
   - Fixed cue placement.
   - Metadata hierarchy.
   - Image role.
   - Interaction model.
   - Section composition.

5. Reuse existing tokens in `lib/core/theme` and shared primitives in `lib/core/widgets`.

6. Preserve semantic recognition in failure states:
   - Missing images.
   - Loading placeholders.
   - Empty states.
   - Long titles.
   - Large text.

7. Verify with:
   - `dart format` on changed Dart files.
   - `flutter analyze`.
   - Widget or golden tests when component structure changes.

8. Report:
   - Components changed.
   - Archetype selected.
   - Intentional differentiators.
   - Verification performed.
   - Remaining UX risks.
