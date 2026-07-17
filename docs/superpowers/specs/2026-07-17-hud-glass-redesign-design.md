# Digimon V-Pet — HUD & Visual Redesign — Design Document

**Date:** 2026-07-17
**Status:** Approved design, ready for implementation planning

## 1. Overview

The v0.1 MVP shipped with a **functional-first HUD**: solid green LCD background, the
pet rendered by Flame, a couple of status icons that appear when a stat is bad, and a
row of pixel-art action buttons. It was built to validate mechanics, not to look good.

This spec covers a **visual/HUD redesign only** — the care loop, stats, evolution, and
persistence from the MVP are unchanged. The goal is to replace the placeholder HUD with
a real, cohesive look, while structuring the new "world" concept so it can grow into a
gameplay feature later without a rewrite.

Direction was explored interactively with the user via a series of live HTML/CSS
mockups (browser-based brainstorming companion, not committed to the repo — session
scratch under `.superpowers/brainstorm/`, gitignored). This document is the durable
record of what was decided.

## 2. Goals & Non-Goals

**Goals:**
- Replace the flat-color background + bare icon HUD with a modern, "glass" visual
  language (frosted translucent panels, soft depth, rounded organic shapes).
- Give the screen a sense of depth and life via a parallax scrolling background themed
  to the pet's current life stage.
- Keep the door open for the background/world concept to become a real mechanic later
  (multiple biomes, player-influenced movement) **without redesigning it twice**.
- Replace the current pixel-art icon set, which doesn't fit the new visual language.

**Non-goals (explicitly deferred — see Section 10):**
- No new gameplay mechanics. The Digimon does not actually move/travel; evolution,
  care actions, and death rules are unchanged from the MVP.
- No player-controlled movement or multiple distinct locations — one continuously
  scrolling background per current life stage.
- No commissioned/final icon art — the icon set chosen here is a working placeholder,
  explicitly called out by the user as "good enough for now, not final."

## 3. Visual Direction

Explored 14+ mockup directions across two rounds (retro-Digivice-styled options, then a
modern/glass-styled second round after the user redirected toward "algo mais atual,
mais fluido e rápido, um visual meio glass, com aspectos bem interativos"). Landed on:

- **No physical device chrome.** Full-bleed screen — the "world" is the background,
  with glass HUD elements floating on top. No bezel/border pretending to be a
  handheld device (this rules out the earlier retro-Digivice-frame directions).
- **Frosted glass surfaces** for every HUD element: translucent white fill, backdrop
  blur, a thin light border, and a soft outer shadow + inset highlight — Flutter's
  `BackdropFilter`/`ImageFilter.blur` achieves this natively, no package required.
- **Organic/liquid shapes** over sharp rectangles where practical (the pet itself, the
  ground-marker ring) — informed by the "liquid blob" direction the user picked from
  the style gallery, but HUD chrome (bars, dock, badges) uses simple rounded-rect/pill
  shapes for legibility, not full blob morphing.
- **A living, scrolling background** (Section 4.1) rather than a static color, themed
  per life stage.
- **Interactivity is expressed via glass reacting on press/hover** (brighten + glow),
  not via ambient/idle motion — the user explicitly rejected a continuously
  color-cycling background as distracting. Motion in the final direction is limited to:
  the parallax scroll itself (has clear directional purpose), the pet's idle
  walk-in-place bob, and press feedback.

## 4. Architecture & Components

**Chosen approach:** extend the existing two-layer split (`lib/game/` = Flame
rendering, `lib/ui/` = Flutter chrome) rather than introducing a third rendering
system. Two alternatives were considered and rejected:

- *Pre-rendered art/media per biome* — richer visual ceiling, but real art-production
  and licensing overhead (same caution as the existing sprite situation), heavier APK,
  and each new biome would mean new art rather than a palette swap — directly against
  the "stay extensible" goal.
- *Ship the glass HUD reskin now, defer the parallax world to a later spec* — smaller
  slice, but the scrolling world was the part the user got most excited about and
  explicitly approved; deferring it would under-deliver against this brainstorm.

### 4.1 World / parallax background (`lib/game/`)

New Flame components added to the existing `VpetGame`, behind/below the pet:

- **Sky**: a static (non-animated) gradient fill, colored by the current biome palette.
- **Far layer**: small, muted hill silhouettes, slow horizontal scroll, tiled/looped.
- **Mid layer**: soft decorative blob shapes (clouds/bushes), medium scroll speed,
  lower opacity — purely decorative depth cue.
- **Ground plane**: a solid, flat band anchored to the bottom of the screen — **not**
  bumpy hill shapes — with a subtle repeating edge texture, fastest scroll speed. This
  is deliberately a flat plane (per user feedback during mockup iteration) so the pet
  visibly stands on solid, level ground rather than floating over terrain.
- **Ground marker**: a soft, static (non-animated) glowing ring on the ground plane at
  the pet's fixed screen position — signals "this is where the Digimon stands" now
  that the world scrolls under/behind it.
- All scrolling layers use Flame's `Effect`/`EffectController` system (already
  partially used for the pet's scale-bounce feedback) via a duplicated-tile technique
  for seamless looping, **not** a new package.
- **No new art assets.** Every layer is flat-shaded procedural shapes, so a new biome
  is a new palette entry, not new artwork.

The pet itself keeps its existing sprite-sheet idle animation, extended with a subtle
vertical bob (Flame `Effect`, looping) to read as "walking in place" while the ground
scrolls under it. Horizontal position is fixed — the pet does not actually move.

### 4.2 Biome system (`lib/state/`)

- A pure function `Biome biomeForStage(LifeStage stage)` in `lib/state/`, tested the
  same way as the rest of the pure logic layer. **Decision: biomes map 1:1 to the six
  existing life stages** (Botamon, Koromon, Agumon, Greymon, MetalGreymon,
  SkullGreymon) — no new state field, it's derived from data that already exists on
  `Pet`.
- A `BiomePalette` lookup (sky/far/mid/ground/accent colors) keyed by `Biome`, living
  in the rendering layer (`lib/game/` or `lib/ui/`) since color values are a
  presentation concern, not core logic.
- This is the seam that makes the world "decorative but extensible": introducing a
  real location/movement mechanic later only means changing what feeds `Biome`, not
  the rendering code.

### 4.3 HUD chrome (`lib/ui/`)

Flutter widgets layered in the existing `Stack` alongside `GameWidget`, re-skinned
with the glass treatment (Section 3):

- **Top status bar**: pet name/stage label, a small colored dot reflecting the current
  HUD accent color (Section 4.4), and a settings (gear) affordance.
- **Status badges** (top-right, stacked): small circular glass badges, each showing an
  icon with a colored "urgency ring" around it. **Only rendered when the underlying
  stat crosses its existing warning threshold** — this preserves the MVP's current
  behavior (`if (condition) Image.asset(...)` in `home_screen.dart`) exactly, just
  re-skinned. Covers hunger, mess (poop), sickness, **and now happiness** (see 4.5).
- **Action dock** (bottom): a single glass pill bar containing the four existing
  action buttons (feed/clean/medicine/play), replacing the current bare `IconButton`
  row. Existing enable/dim logic (`p.hunger > 0`, `p.poopCount > 0`, etc.) is
  unchanged — only the visual container and icon assets change.

### 4.4 HUD color customization

**Decision: both.** Default accent color is derived automatically from the current
`BiomePalette` (Section 4.2) — zero extra UI needed for the default case. A new
**Settings screen** (new, was not part of the MVP) lets the player optionally lock a
preferred accent color, overriding the biome-derived default. The override, if set, is
persisted in the new settings store (Section 5) — kept separate from `Pet`.

### 4.5 Status stats shown

**Decision: add happiness as a fifth visible status badge.** It's already modeled and
updated in `pet_logic.dart` but was never surfaced in the MVP UI. Since the badge
mechanism (4.3) already exists for the other three stats, surfacing happiness is a
small addition, not a new subsystem.

Two small details left for implementation time, non-blocking:
- **Icon**: pick a visually distinct glyph from the same Fluent Emoji 3D set (Section
  6) — the mockups already used "Red heart" for the *play action* button, so happiness
  needs a different glyph (e.g. a smiling-face or star emoji), not a reused one.
- **Threshold**: hunger/poop/sickness already have a concrete "bad" condition in
  `pet_logic.dart` today; happiness does not, since it was never surfaced before. Add
  an equivalent low-happiness threshold constant in `GameConfig`, following the same
  pattern as the existing `hungerWarnThreshold`.

## 5. Data Model Changes

- `Pet`/persistence: no changes to existing fields. `happiness` already exists; it
  only becomes *visible*, not newly tracked.
- New, small settings concern (separate from `Pet`): `hudColorOverride` (nullable
  color) and `soundMuted` (bool). These are player preferences, not pet state — keep
  them out of `PetRepository`/the pet JSON blob (scope/ownership stays clean) and add
  a minimal separate preference store (still `shared_preferences` — no new persistence
  package needed, this is two extra scalar values, not a new data shape).

## 6. Assets & Licensing

- **Icon set: Fluent Emoji, "3D" style** (`microsoft/fluentui-emoji` on GitHub, **MIT
  licensed**). Confirmed via the repo's `LICENSE` file. This is Microsoft's own
  original artwork — unlike the character sprites, there is **no third-party
  (Bandai/Toei) IP question here**, and no repo-privacy implication.
- Icons chosen so far (bundled as local PNG assets, replacing `assets/ui/*.png`):
  - Feed → `Meat on bone`
  - Clean → `Sparkles`
  - Medicine → `Pill`
  - Play (action) → `Red heart`
  - Mess status → `Pile of poo`
  - Sickness status → `Face with thermometer` (replaces the current skull — judged too
    harsh for the new visual language; thermometer reads as "unwell" without the
    heavier "death" connotation)
  - Happiness status → not yet chosen (Section 4.5)
- **Explicitly a placeholder set**, per direct user feedback ("não achei os melhores,
  mas por enquanto vamos manter eles até ter melhores"). Revisiting the icon art is
  tracked as a follow-up, not blocking this implementation.

## 7. Audio & Haptics

**Decision: sound on by default, with a mute toggle.** Short SFX on the main actions
(feed/clean/medicine/play) and on evolution, via `flame_audio` (official Flame-team
package, bundled local assets only — no network, fits the offline-first constraint).
Mute preference lives in the new settings store (Section 5). `HapticFeedback` (Flutter
built-in, no package) fires on each of the four action-dock button presses.

## 8. Settings Screen (new)

A new, minimal screen — not part of the MVP — reachable from the top status bar's gear
affordance:

- Toggle: lock HUD accent color (color swatch picker) vs. auto (biome-derived).
- Toggle: mute sound.

Kept intentionally small: no other preferences are in scope for this spec.

## 9. Testing Approach

- Existing pure-logic tests (`pet_logic_test.dart`, `pet_repository_test.dart`, etc.)
  are unaffected — no changes to game rules or persisted `Pet` shape.
- New pure function `biomeForStage` gets unit tests the same way, in `lib/state/`.
- New HUD widgets get golden-file coverage via `matchesGoldenFile` (built into
  `flutter_test`, already part of the toolchain — no new package). Flame-side world
  components (ground plane, parallax layers) are simple enough to verify visually
  on-device rather than via `flame_test`, given they're flat procedural shapes with no
  sprite-frame correctness to protect.
- `BackdropFilter` blur performance must be verified on a real device (the project's
  existing sideload-APK verification loop), since blur compositing is the one part of
  this redesign with a real perf question on lower-end phones.

## 10. Out of Scope (This Version) / Deferred

- Actual pet movement or player-influenced location — the world remains decorative;
  `biomeForStage` is the seam for a future mechanic, not an implementation of one.
- Biomes beyond the six existing life stages.
- Final/commissioned icon art (Section 6) — current set is an accepted placeholder.
- Any change to care-loop mechanics, evolution rules, `careScore` tuning, or death
  conditions — all unchanged from the MVP.
- Rive or any vector-rig character animation (would reintroduce the native/NDK
  dependency deliberately removed after the v0.1 startup-crash fix).
