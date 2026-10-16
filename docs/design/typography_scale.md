# Tiermetry Typography System: The Golden Ratio Scale

To ensure the highest level of visual harmony across Tiermetry, the app's entire typography scale is mathematically derived using the **Golden Ratio (1.618)** and its modular intermediate step (the square root, **1.272**), anchored around a base **16px** card title.

## The Mathematical Scale (Base: 16px)

By traversing up and down from the 16px anchor point, we generate a perfectly rhythmic scale of font sizes:

- **10px** (`label`) = `16 / 1.618`
  - *Usage*: Tiny UI elements, badges (e.g., "FREE", "AUG", "CREATIVE").
- **13px** (`caption`, `bodySmall`, `action`) = `10 * 1.272`
  - *Usage*: Metadata (time, location, stats), subtitles, secondary body text, and CTA buttons (e.g., "Enroll").
- **16px** (`titleSmall`) = **Base Anchor**
  - *Usage*: Standard card titles (Upcoming Events, Featured Skills, Live Around You).
- **20px** (`title`) = `16 * 1.272`
  - *Usage*: Core section headers (e.g., "Trending", "Featured").
- **26px** (`display`) = `16 * 1.618`
  - *Usage*: Massive page greetings and top-level headers.

*(Next step up if needed: `26 * 1.272 = 33px`)*

## Implementation Rules
1. **Never hardcode font sizes** in UI components. Always use the central tokens from `TiermetryTypography` (e.g., `TiermetryTypography.caption()`).
2. **Never override the sizes** at the call site unless absolutely necessary for a one-off graphical exception.
3. Keep the visual hierarchy consistent: A card title should never be larger than 16px, and card metadata should never be larger than 13px.
