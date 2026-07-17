# Digimon Game — Progress & Roadmap

_Last updated: 2026-07-17_

Human-readable status log + roadmap. Specs live in `docs/superpowers/specs/`, plans in
`docs/superpowers/plans/`, the per-plan execution ledger in `.superpowers/sdd/progress.md`.

---

## ▶️ RESUME POINT (read this first after a context clear)

**Where we are:** mid-**brainstorm** for the first sub-project of a big new direction.

- **Git:** on branch **`feat/plan2-settings-audio`** (this branch has the parked Plan 2 docs +
  the `.gitignore` protection for the extracted old game). `master` = `c4dff28` (v0.2 HUD redesign
  merged). Working tree clean apart from regenerable `graphify-out/` churn.
- **The pivot:** we reverse-engineered the user's own old game **"Digital Tamers Reborn"** and
  recovered its assets (see §"Extracted assets"). Decision: **rebuild it as a full, modern game**
  in this Flutter/Flame project — treated as a multi-phase **PROGRAM** (see §Roadmap).
- **Current sub-project:** Program **Phase 0+1** (asset pipeline + data-driven creature
  foundation). First increment scoped to **prove the data-driven architecture on ONE evolution
  line** (Botamon→Koromon→Agumon→Greymon→MetalGreymon/SkullGreymon) with the real Reborn art.
- **NEXT ACTION:** re-present the **Phase-1 design** (§"Phase 1 — pending design") and get the
  user's approval; then `superpowers:writing-plans` → execute via subagent-driven-development.
  (The design was presented but not yet approved when we saved & cleared.)

---

## Status timeline

- ✅ **v0.1 MVP** — care/evolve/death loop. **PR #1 merged** to `master`.
- ✅ **v0.2 HUD glass redesign** — glass HUD + biome-tinted parallax world + Fluent icons +
  haptics + happiness badge. Built via subagent-driven-development (13 commits, whole-branch
  review, on-device smoke test). **PR #2 merged** to `master` (`c4dff28`). 49 tests pass.
- ⏸️ **Plan 2 (settings + lockable HUD color + audio)** — spec + plan written and committed on
  branch `feat/plan2-settings-audio`, but **PARKED / not executed** (superseded by the pivot).
  Its audio work folds into the new program; its settings screen returns in a later phase.
- 🔀 **PIVOT → full game** — see Roadmap below. Currently brainstorming Phase 1.

---

## Extracted assets — "Digital Tamers Reborn" (the user's own old game)

Reverse-engineered **statically (game never run)**: the distributed `.exe` is a self-extracting
installer with a Microsoft **CAB** embedded → extracted with Windows' native `expand.exe` → yields
a GameMaker: Studio **`data.win`** (bytecode v15) + loose OGGs. `data.win` parsed for assets.

- **Location (git-ignored, kept local):** `para estudo reborn/extracted/`
  - `audio_embedded/` — 149 embedded SFX/voice OGGs
  - `music/` — 25 loose BGM/SFX OGGs (BGM_*, snd_*) incl. `BGM_evolution`, `BGM_HatchEgg`
  - `textures/` — 69 atlas PNGs (2048×2048) — all the sprite art
  - `meta/` — `strings_all.txt` (16,945 strings) + `INVENTORY.md` (roster/asset name index)
  - `data.win` — the GameMaker bundle (master source for future deep extraction)
  - `splash.png`, `options.ini`
- **Inventory:** 6,188 sprites, 555 objects, 111 rooms, 174 sounds, 4,642 GML code entries.
- **Still TODO for full reuse:** per-sprite slicing (6,188) + GML decompilation → use
  **UndertaleModTool** (opens `data.win`); hand-rolling the format is unsafe (a raw parse bug
  once filled the disk with a 33 GB file — killed & cleaned; guards added since).
- **IP:** the whole game is Bandai/Toei IP (art, names, sounds) — **personal use, private repo
  only**, same stance as the community sprites. `para estudo reborn/` is git-ignored so the 200 MB
  exe + assets never get committed.

---

## 🗺️ Roadmap — Program: "Digital Tamers, modern" (Flutter/Flame)

Rebuilding the full game incrementally on top of the current V-Pet. Each phase = its own
brainstorm → spec → plan → build cycle. Cost is estimated per phase; one phase at a time.

| Phase | What | Status |
|---|---|---|
| **0. Asset pipeline** | Slice sprites (UndertaleModTool) + organize audio | in progress (folded into Ph.1) |
| **1. Data & creatures foundation** | Data-driven Digimon (roster, evolution trees, stats), real animated sprites, care loop reads data | **brainstorming now** |
| **2. Battle system** | Turn-based combat: moves, damage, AI, battle UI/animation | planned |
| **3. World & progression** | Screens (lobby/lab/store), items/economy, championship/story, exploration | planned |
| **4. Polish & meta** | Settings (Plan 2 folds here), audio integration, save/profile, balancing | planned |

Build order: 0 → 1 → 2 → 3, with 4 woven throughout.

### Phase 1 — pending design (present again for approval, then write spec)

First increment = **prove the data-driven architecture on ONE evolution line**, real art:

1. **Line:** the existing Botamon→Koromon→Agumon→Greymon→MetalGreymon/SkullGreymon (continuity;
   evolution logic already exists), but now from data + real Reborn art.
2. **Data model** (`lib/state/`, pure/tested): `DigimonSpecies` (id, name, stage, sprite/anim
   refs, `evolvesTo` + condition, and stat fields reserved-but-unused for future battles) +
   `species.json` asset seeding the line. `Pet` references a species by id; `pet_logic` reads
   `species.evolvesTo`/condition instead of the hardcoded `switch`.
3. **Rendering:** `PetComponent` loads the species' real Reborn sprite sheet, mapping frames to
   care states (idle/eat/happy/sick) — via a verified `species-sprite-map` (like the MVP did).
4. **Care loop:** mechanically unchanged (feed/clean/medicine/play/evolve/death) — just
   data-driven + real art. Training/battles are later phases.
5. **Prereq (Phase 0 embedded):** slice just this line's ~6 sprites — recommended a **targeted,
   hard-guarded** slice by us to keep momentum (UndertaleModTool reserved for scaling the full
   roster later).
6. **Testing:** pure-logic tests for data-driven evolution (species swap by condition); on-device
   for real art animating.
7. **Out of scope:** battles, full roster, training, big-game screens.

---

## Current app (v0.2) — what it does

- Life stages Botamon→…→MetalGreymon/SkullGreymon; care loop (feed/clean/medicine/play); needs
  (hunger/mess/sickness/happiness/careScore); neglect→sickness→death→hatch; background reminder.
- **Glass HUD** (`BackdropFilter`): top status bar (stage label + biome-tinted accent dot + gear),
  conditional status badges (incl. happiness), glass action dock (Fluent Emoji icons) + haptics.
- **Biome-tinted parallax world** behind the pet (Flame): gradient sky, scrolling hill/blob
  layers, flat ground the pet stands on; biome derived 1:1 from life stage.

## Architecture (current)

```
lib/
  main.dart                 # app entry; workmanager + runApp(HomeScreen)
  state/                    # PURE, TESTED (no Flutter/Flame imports)
    game_config.dart        #   tuning constants + gameSpeed + happinessWarnThreshold
    pet.dart                #   Pet model, LifeStage/HealthStatus, JSON, per-stat anchors
    pet_logic.dart          #   applyElapsed, care actions, evolution, death, needsAttention
    pet_repository.dart      #   persistence interface + shared_preferences impl
    biome.dart              #   Biome enum + pure biomeForStage(LifeStage)  [Plan 1]
    notifications.dart / background.dart
  game/                     # Flame
    sprite_map.dart, pet_component.dart (idle anim + bounce + idle pulse), vpet_game.dart
    biome_palette.dart      #   BiomePalette + paletteForBiome  [Plan 1]
    world_background.dart   #   sky/parallax layers/ground (worldBackground field on VpetGame) [Plan 1]
  ui/
    home_screen.dart, death_screen.dart
    hud_theme.dart          #   hudAccentFor(pet) + glass constants  [Plan 1]
    widgets/                #   glass_panel, action_dock, status_badges, top_status_bar  [Plan 1]
test/                       # 49 tests
assets/sprites/ (community art)  assets/ui/ (fe_*.png Fluent icons + old pixel icons)
```

Notes: `lib/state/` stays Flutter/Flame-free (unit-tested logic surface). Logic fns take explicit
`nowMs` (deterministic). `VpetGame.world` was renamed **`worldBackground`** (Flame 1.37 defines
`FlameGame.world`).

## Dev helpers (this project)

- Skill **`/vpet-verify`** — sets Flutter env (PATH + JAVA_HOME) + `flutter analyze` + `flutter test`.
- Skill **`/vpet-run`** — launches the `digimon_test` AVD, runs the app, screenshots.
- Agent **`flutter-flame-reviewer`** — read-only reviewer with project invariants baked in.

## Build / run

```powershell
$env:Path += ";C:\Users\felip\flutter\bin"; $env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
cd C:\Users\felip\Documents\digimon
flutter test ; flutter run ; flutter build apk --release
```
Flutter 3.44.6. AVD `digimon_test` (android-34). App package `com.digimon.vpet.digimon`.

## Gotchas fixed (still relevant)

- NDK removed (no native code). Core library desugaring enabled for `flutter_local_notifications`.
- **R8 disabled for release** (`isMinifyEnabled=false`) — R8 stripped a reflectively-loaded
  WorkManager class → release crash. Debug is unaffected.
- Flutter 3.44 deprecates `Color.value` → use `.toARGB32()` (bit us twice; keep analyze clean).
- Golden tests can't render `Image.asset` headless → use behavioral tests for icon widgets;
  verify visuals on-device.

## Tech stack

Flutter + Flame 1.37 · `shared_preferences` (JSON) · `flutter_local_notifications` + `workmanager`.
Planned new dep (Plan 2 / Phase 4): `flame_audio`. Repo: private `JhonneJrr/digimon-vpet`.
