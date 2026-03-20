# NASA Exp Interface System

## Direction

- Feel: cinematic, futuristic, precise, editorial.
- Metaphor: mission control + orbital observatory.
- Tone: immersive but readable, high-tech without becoming cold.
- Platform focus: iPhone-first, single-hand browsing, media-led exploration.

## Domain Signals

- Deep-space darkness
- Observatory glass and instrument panels
- Telemetry overlays
- Orbital glow and atmospheric light
- Scientific archive cards

## Color World

- Night-sky navy for canvas
- Cyan electric accents for active states and data energy
- Warm solar amber for secondary action emphasis
- Mist blue text hierarchy for readable depth
- Soft star white for primary content

## Depth Strategy

- Use layered surface color shifts and subtle borders.
- Avoid heavy shadows.
- Base surfaces live in one blue-black hue family.
- Elevated cards get slightly brighter, not radically different.
- Strong emphasis uses border glow, not thick outlines.

## Tokens

- Background: `backgroundTop`, `backgroundBottom`, `backgroundGlow`
- Surfaces: `surfaceBase`, `surfaceElevated`, `surfaceHighlight`
- Accent: `accent`, `accentSecondary`, `accentMuted`
- Text: `textPrimary`, `textSecondary`, `textTertiary`
- Borders: `border`, `borderStrong`

## Typography

- Typeface: Avenir Next.
- Display/headline style should feel editorial and mission-log inspired.
- Use `display` for major screen headers.
- Use `bodyStrong` for card titles and primary CTA text.
- Use `micro` for telemetry labels, pills, and section metadata.

## Spacing

- Base unit: 4pt.
- Keep current scale via `AppSpacing`.
- Prefer generous vertical spacing around hero content.
- Keep card interiors consistent and symmetrical.

## Components

### SpaceBackground

- Must use gradient canvas plus radial glow.
- Optional star field points are subtle, never decorative noise.

### HeroCard

- Purpose: feature a mission, media story, or state with presence.
- Structure: icon node, telemetry tag, large title, supporting copy.
- Use for empty/error/feature intro states.

### SectionHeader

- Must include a small telemetry-style kicker.
- Large title + softer supporting subtitle.

### InfoPill

- Use as telemetry tags.
- Keep uppercase-ish short content.
- Never use for long prose.

### SurfacePanel

- Use for filters and grouped controls.
- Maintain subtle border and layered fill.

### ActionCapsule

- Primary CTA uses cyan emphasis.
- Secondary CTA uses amber-muted treatment.
- Keep full-width in scroll sections when possible.

## Screen Patterns

- APOD: editorial hero + immersive image + concise action row.
- Rovers: control panel filters + telemetry grid cards.
- EPIC: Earth-view archive with orbital framing and coordinate metadata.
- Favorites: personal archive ledger with native detail routing.

## Avoid

- Flat white cards
- Generic dashboard purple
- Heavy shadows
- Random gradients without purpose
- Mixed visual metaphors within the same screen
- Tiny touch targets or cramped CTA rows
