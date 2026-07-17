# Phase 0+1 — Data-Driven Creatures Foundation — Design

_Date: 2026-07-17 · Status: approved (brainstorm) → ready for writing-plans_

Part of the "Digital Tamers, modern" program (see `PROGRESS.md` roadmap). This is the
**first increment**: prove the data-driven creature architecture on ONE evolution line, with the
care loop reading data instead of hardcoded `switch`es. No battles.

## Goal

Convert the pet's identity, evolution, and rendering from hardcoded enums/switches to a
**data-driven** model seeded by `species.json`, proven end-to-end on the existing line
Botamon → Koromon → Agumon → Greymon → MetalGreymon / SkullGreymon. Behavior (care loop, timings,
biomes, visuals) is **preserved exactly**; only the source of truth moves from code to data.

## Scope

**In:** data model + `species.json` seed for the 6-stage line; `Pet` keyed by `speciesId` (with
save migration); `pet_logic` evolution reads `species.evolvesTo`; rendering geometry as data;
pure `SpeciesRegistry` loaded by the Flame layer; full test coverage; on-device visual check.

**Out:** battles, full roster, training, big-game screens, and **real Reborn-art extraction**
(tracked separately as a Phase-0 spike — see §Art & §Open items).

## Decisions (from brainstorm)

- **Q1 = Decouple.** Build the architecture on the existing **community sprites** (already in
  `assets/sprites/`, all 6 at 48×64). Real Reborn art is a later, gated, optional swap — evidence
  showed the roster art exists only packed/unlabeled across the 68 atlas pages, not as named
  sprites, and carries IP/extraction uncertainty. See memory `reborn-roster-art-packed-in-atlas-pages`.
- **Q2 = Transitions list.** `evolvesTo` is a list of `{ toId, afterMs, condition }` with an
  enumerated `condition` (`always | careScoreHigh | careScoreLow`). Mirrors today's logic 1:1; no
  generic rules engine (YAGNI).
- **Q3 = `speciesId` identity.** `Pet` references a species by id; the stage "tier" becomes a
  species property. Old saves migrate.
- **Q4 = Geometry as data, idle only.** Sprite geometry moves into the species; `PetComponent`
  stays idle + bounce (no care-state frame mapping — community reaction frames are unreliable and
  no richer art is available yet).
- **Q5 = JSON source, pure registry.** `species.json` is the source of truth; the Flame layer
  loads it and parses into pure `DigimonSpecies`/`SpeciesRegistry` objects in `lib/state/`
  (no Flutter imports), injected into logic.

## Data model (`lib/state/`, pure, tested)

```dart
enum StageTier { fresh, inTraining, rookie, champion, ultimate } // canonical Digimon terms
enum EvoCondition { always, careScoreHigh, careScoreLow }

class Evolution {
  final String toId;        // target species id
  final int afterMs;        // time in the source stage before this transition is eligible
  final EvoCondition condition;
}

class Stats {               // RESERVED for future battles; parsed but unused in Phase 1
  final int hp, attack, defense, speed; // (exact fields TBD in battle phase; keep minimal now)
}

class SpriteRef {           // geometry as data — replaces const frameSize + hardcoded idle frames
  final String sheet;       // e.g. "sprites/Botamon.png" (asset path, relative to assets/)
  final int frameWidth, frameHeight;
  final int columns, rows;
  final List<int> idleFrames; // e.g. [0, 1]
  final double stepTime;      // idle animation step (e.g. 0.5)
}

class DigimonSpecies {
  final String id;          // "botamon"
  final String name;        // "Botamon"
  final StageTier tier;
  final Biome biome;        // moved out of biomeForStage() into data (preserves chrome vs wasteland)
  final SpriteRef sprite;
  final List<Evolution> evolvesTo; // empty = terminal (ultimate)
  final Stats? stats;       // nullable/reserved
}
```

`SpeciesRegistry` — a pure lookup (`Map<String, DigimonSpecies>`) built via `fromJson(Map)`. No
Flutter imports. Provides `DigimonSpecies operator [](String id)` / `lookup(id)` and validation.

### `assets/data/species.json` (seed — illustrative shape)

```json
{
  "botamon":  { "name": "Botamon",  "tier": "fresh",      "biome": "nursery",  "sprite": {"sheet":"sprites/Botamon.png","frameWidth":16,"frameHeight":16,"columns":3,"rows":4,"idleFrames":[0,1],"stepTime":0.5}, "evolvesTo": [ {"toId":"koromon","afterMs":<config>,"condition":"always"} ] },
  "koromon":  { "name": "Koromon",  "tier": "inTraining", "biome": "meadow",   "sprite": {"...":"..."}, "evolvesTo": [ {"toId":"agumon","afterMs":<config>,"condition":"always"} ] },
  "agumon":   { "name": "Agumon",   "tier": "rookie",     "biome": "jungle",   "sprite": {"...":"..."}, "evolvesTo": [ {"toId":"greymon","afterMs":<config>,"condition":"always"} ] },
  "greymon":  { "name": "Greymon",  "tier": "champion",   "biome": "savanna",  "sprite": {"...":"..."}, "evolvesTo": [ {"toId":"metalgreymon","afterMs":<config>,"condition":"careScoreHigh"}, {"toId":"skullgreymon","afterMs":<config>,"condition":"careScoreLow"} ] },
  "metalgreymon": { "name": "MetalGreymon", "tier": "ultimate", "biome": "chrome",    "sprite": {"...":"..."}, "evolvesTo": [] },
  "skullgreymon": { "name": "SkullGreymon", "tier": "ultimate", "biome": "wasteland", "sprite": {"...":"..."}, "evolvesTo": [] }
}
```

`afterMs` values are seeded **from the current `GameConfig.stageDurationMs`** (per stage) so timing
is preserved exactly — not invented. Biome values preserve today's `biomeForStage` mapping 1:1.

## `Pet` identity + migration

- Replace `Pet.stage: LifeStage` with `Pet.speciesId: String`. `toJson` writes `speciesId`.
- `Pet.fromJson`: if `speciesId` is present, use it; else if legacy `stage: int` is present, map
  it (`0→botamon, 1→koromon, 2→agumon, 3→greymon, 4→metalgreymon, 5→skullgreymon`). One migration
  function, unit-tested against a legacy JSON fixture.
- `Pet.newborn` starts at `speciesId: "botamon"`.
- `stageStartedAtMs` unchanged (per-stage clock).
- `LifeStage` enum is retired from `Pet`; the tier concept lives on the species (`StageTier`).
  `Biome` enum stays (display concept); its stage→biome mapping moves into `species.json`, so
  `biomeForStage(LifeStage)` is replaced by reading `species.biome`.

## Evolution logic (`pet_logic.dart`)

- Delete `_nextStage` (the hardcoded `switch`) and the `GameConfig.stageDurationMs` dependency
  inside `checkEvolution`.
- `checkEvolution(Pet p, int nowMs, SpeciesRegistry species)`: loop as today — while the current
  species has an eligible transition (`nowMs - stageStartedAtMs >= afterMs`), pick the transition
  whose `condition` holds (`careScoreHigh` = `careScore >= GameConfig.careScoreThreshold`,
  `careScoreLow` = complement, `always` = linear), advance `speciesId` and `stageStartedAtMs`
  (start the next stage's clock at the instant the requirement was met, as today). Terminal when
  `evolvesTo` is empty or no condition matches.
- Greymon carries both Metal/Skull transitions; conditions are complementary so exactly one fires.
- `applyElapsed`, `feed`, `clean`, `giveMedicine`, `play`, `needsAttention` are **unchanged**
  (generic stats + global rates). Only `checkEvolution` gains the `registry` parameter.

## Rendering (`pet_component.dart`, `sprite_map.dart`)

- Remove the hardcoded `frameSize`/idle-frame constants and the `spriteSheetForStage` switch;
  geometry comes from `species.sprite` (`SpriteRef`).
- `PetComponent.showFor(DigimonSpecies species)`: build the `SpriteSheet` from `frameWidth/Height`
  + `columns/rows`, the idle `SpriteAnimation` from `idleFrames` + `stepTime`, and scale the
  component to a **consistent on-screen target height** (so future larger frames render at the same
  size). Guard against stale async loads by species id (same pattern as today's `_loadGen`).
- `reactBounce` / `startIdlePulse` unchanged.

## Loading & purity (`vpet_game.dart`)

- `VpetGame.onLoad` loads `assets/data/species.json` (via `rootBundle`/Flame asset loading),
  parses to `SpeciesRegistry` (pure), and holds it.
- `VpetGame` resolves `final species = registry[pet.speciesId]`, passes it to `checkEvolution` and
  `PetComponent.showFor`. `lib/state/` never imports Flutter/Flame.

## Error handling / edge cases

- `speciesId` missing from registry (e.g. a save referencing a removed species): fall back to the
  line start (`botamon`) and log; never crash.
- Malformed `species.json` at startup: fail fast with a clear error (it's a bundled dev asset, not
  user data).
- No matching evolution condition: stay put (don't evolve) — safe default.
- A test asserts the seeded line is complete and fully reachable from `botamon`.

## Testing

**Pure (unit):**
- `DigimonSpecies` / `Stats` / `SpriteRef` / `Evolution` JSON round-trip.
- `SpeciesRegistry.fromJson` + lookups + missing-id fallback.
- Data-driven `checkEvolution`: linear stages advance by time; Greymon → MetalGreymon when
  `careScore` high, → SkullGreymon when low; multi-threshold catch-up loop still works; terminal
  at ultimate.
- Save migration: legacy `{stage: int}` fixture → correct `speciesId`; new-format round-trip.
- Line reachability: walking from `botamon` reaches both ultimates.

**On-device (behavioral):** each of the 6 community sheets renders and idle-animates via the
data-driven geometry (golden/headless can't render `Image.asset` — verify on device, per project
gotcha).

## Art

Phase 1 ships the **community sprites** (ready, 48×64, wired). Real Reborn art is a **separate
Phase-0 extraction spike**: a full visual sweep of the 68 atlas pages is underway to locate the
line and inventory everything extractable; its output feeds the spike doc, not this design. Any
later swap is a single `sprite.sheet`/geometry edit per species in `species.json` — no code change.

## Open items (not blocking this design)

- Real-art extraction spike: locate the 6 line sprites across the atlas pages, crop/re-author to
  the sheet convention, and clear the IP/licensing question before any swap.
- Exact `Stats` fields are deferred to the battle phase; keep the reserved shape minimal now.
