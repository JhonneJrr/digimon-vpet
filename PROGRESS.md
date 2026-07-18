# Digimon Game — Progress & Roadmap

_Last updated: 2026-07-18_

Human-readable status log + roadmap. Specs live in `docs/superpowers/specs/`, plans in
`docs/superpowers/plans/`, the per-plan execution ledger in `.superpowers/sdd/progress.md`.

---

## ▶️ RESUME POINT (read this first after a context clear)

**Branch:** `feat/hud-overhaul-shell` @ `4c26798` (stacked on `feat/sprite-library-taxonomy`;
**nothing merged to `master` this session** — Phase 0+1 is the last thing on master, PR #3).

**This session (2026-07-18) shipped, all committed on the branch above, 82/82 tests + `flutter
analyze` clean + on-device verified:**
1. **graphify hook fix** + **Sprite library reorganization** (67,755 frames → `organized/`) + the
   **HUD overhaul + navigation shell** and its landscape "2nd overhaul" (see §HUD overhaul).
2. **Radial care menu + real HUD menu buttons DONE** (see §Radial care menu) — the six hex sockets are
   now the real `spr_MainButtons_ENG` menu buttons wired to the RoomScreen shell (mapping triangulated
   from decompiled `obj_MainButtons` GML); the four care actions moved to a **top-arc radial menu that
   opens on tapping the Digimon** (meat/poop/bandage/ball, real dump art); the pet line was **shrunk
   ~0.71** so it reads in the landscape. Spec + plan under `docs/superpowers/`; SDD ledger:
   `.superpowers/sdd/progress.md`.

**Next step (awaiting the user's pick):** (a) **open a PR** of this branch → `master` (carries the
sprite-library + HUD-overhaul + radial-care commits), or (b) start **heavy mechanics** (Phase 2 battle
and/or training, mounting into a socket's `RoomScreen` — Treino/Batalha/Loja/Evo/Database/DigiVice stubs
already exist). Deferred cleanup (from the final review): delete the now-orphaned `menu_sheet.dart`;
add a geometry assertion to `pet_tap_target_test`; add a stubbed home-assembly widget test.

- **Git:** **PR #3 merged to `master`** (2026-07-18 UTC). Phase 1 = data-driven creatures on the real
  extracted art; 60/60 tests, `flutter analyze` clean, on-device verified (Botamon idle-animates with
  the real art, HUD reads the species name, nursery biome). Ledger: `.superpowers/sdd/progress.md`.
- **The pivot:** rebuilding the user's own game "Digital Tamers Reborn" as a modern Flutter/Flame
  game, a multi-phase PROGRAM (see §Roadmap).
- **✅ ART SOURCE DECIDED (2026-07-17):** the full art is recovered. From **v2** of the game
  (`C:\Users\felip\Documents\DigitalTamers02\data.win`, 604 MB, GameMaker bytecode v17) we
  extracted via **UndertaleModTool CLI** (headless) **67,755 pre-cropped RGBA sprite frames from
  10,319 sprites** → `C:\Users\felip\Documents\DigitalTamers02_extracted\` (KEEP git-ignored — IP).
  A verified `meta\digimon-id-map.md` maps **658/665** ids→names. Our line: Botamon **d1**,
  Koromon **d2**, Agumon **d3**, Greymon **d5**, MetalGreymon **d85**, SkullGreymon **d87**,
  WarGreymon **d151** — each with named poses (idle/eat/walk/angry/win/lose/dmg/atk…). The dump
  also has button/power/HUD/background art. **This is the canonical art for the game** (supersedes
  the community sprites and the Vital Bracelet BE source). Sprites are per-frame PNGs, per-creature
  sizes, real alpha (no chroma-key).
- **✅ STACK DECIDED:** stay on **Flutter/Flame + Dart**. The assets are portable PNGs/audio, our
  data-driven architecture was built to consume them, and we keep the tested logic layer + agentic
  workflow. GameMaker was considered and rejected (restart from scratch, weaker dev/agentic +
  version-control workflow, export licensing, closer to cloning the original than building ours).
- **NEXT ACTION (on resume):** confirm the user's pick from the three options above, then:
  - **(a) HUD calibration** — in `lib/ui/hud/hud_overlay.dart`, the `slot(fx, fy, …)` calls place the
    4 action icons at `fy: 0.865`; they sit a touch high in the hex sockets (nudge `fy` up ~0.88–0.90
    and/or reduce icon padding) and the `StatusBadges` at `left: w*0.34, top: h*0.03` slightly overlaps
    the level gauge (shift left/down). Re-verify with `/vpet-run` (landscape; dismiss the one-time
    "Viewing full screen" Android dialog).
  - **(b) Heavy mechanics** — fresh brainstorm → spec → plan → build. Battle sprites are under
    `organized/digimon/<name>/battle/`, arenas under `organized/backgrounds/bg_Btl_*`, effects under
    `organized/effects/`. Wire into `RoomScreen.content` (Batalha/Treino doors already exist).
  - **(c) Open PR** — `feat/hud-overhaul-shell` → `master` (it also carries the sprite-library commits).
- **Env reminder:** Flutter not on PATH → `$env:Path="C:\Users\felip\flutter\bin;"+$env:Path`;
  `$env:JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"`. Use `/vpet-verify` + `/vpet-run`.
  Note: the accelerated game clock kills the pet in seconds during manual on-device testing (expected,
  not a bug) — hatch and screenshot quickly.

### ✅ Sprite library (DONE — `feat/sprite-library-taxonomy`)

Reorganized the 67,755 flat frames in `DigitalTamers02_extracted/sprites/` into a browsable
`DigitalTamers02_extracted/organized/` (git-ignored, IP). **Hybrid name+line taxonomy**, built by
`tools/sprite-library/` (versioned, reproducible). Spec:
`docs/superpowers/specs/2026-07-17-sprite-line-taxonomy-design.md`.

- `organized/digimon/<name>/` — **666** Digimon, one folder each; `<pose>/` overworld + `battle/<pose>/`
  battle frames. Say a name → open its folder (e.g. `digimon/agumon/`).
- `organized/lines/<rookie>/` — **7 hand-curated** evolution families (agumon, gabumon, guilmon,
  patamon, v-mon, renamon, impmon) as directory junctions, each with its **canonical predisposed baby
  chain** and every spine edge verified reachable in the game's evolution graph. Add more via
  `tools/sprite-library/curated_lines.json`.
- `organized/{ui,effects,backgrounds,items,npcs,misc}` — non-Digimon art (1005 `spr_` classified,
  312 → misc).
- **Key findings:** `b<N>` battle sprites map 1:1 to `d<N>` ids (confirmed via GML `sprite_index =
  b3_idle`); the evolution graph is a dense **522-node mesh** (no clean auto-lines → curation).
  Materialized with hardlinks + junctions (~0 extra disk; `sprites/` untouched).
- **📌 REMINDER — add more curated lines:** only **7 of ~81 rookie lines** exist so far. Add any by
  appending to `tools/sprite-library/curated_lines.json` (member ids from `meta/digimon-id-map.md`,
  spine as `[parent,child]` pairs) then re-running build+materialize. Wishlist to revisit: Wormmon/
  Stingmon, Terriermon, Dracomon, Hawkmon, Armadillomon, Veemon's Imperialdramon/Paildramon jogress
  branch, plus the Black/X-Antibody variant lines.

### ✅ HUD overhaul + navigation shell (DONE — `feat/hud-overhaul-shell`)

First-pass **hybrid** redesign (a deeper 2nd visual overhaul is deferred by choice). Spec:
`docs/superpowers/specs/2026-07-18-hud-overhaul-navigation-shell-design.md`; plan:
`docs/superpowers/plans/2026-07-18-hud-overhaul-navigation-shell.md`. 64/64 tests, analyze clean,
on-device verified (real map renders pixel-perfect; biome-driven map swaps on evolution; ☰ opens the
doors).

- **Real map scene:** `lib/game/map_background.dart` `MapBackgroundComponent` draws the biome's real
  map (`assets/game/backgrounds/biome_<biome>.png`) cover-fit + `FilterQuality.none`, replacing the
  procedural `world_background.dart` (deleted). Biome→map is a `switch` in `mapAssetForBiome`.
- **Hybrid HUD:** kept the glass top bar + dock; added a `☰` menu button (`TopStatusBar.onMenu`).
- **Navigation shell** (`lib/ui/shell/`): `showMenuSheet` (glass sheet of doors) → pushes a reusable
  `RoomScreen(RoomConfig{title, backgroundAsset, comingSoon, content})`. 5 stub rooms (Treino/Batalha/
  Mapa/Loja/Evo) show the real room background + "em breve". **`RoomConfig.content` is the slot where
  future combat/training UIs mount — no shell refactor needed.**
- **Assets:** `tools/sprite-library/copy_app_assets.sh` copies the shipped subset from `organized/`
  into `assets/game/backgrounds/` (committed, private repo). `lib/state/` untouched.
- **Iterated after on-device feedback → the "2nd overhaul" (landscape):** the app is now **locked
  landscape** (`main.dart`, immersive) so the 538×300 maps fill naturally and the pet reads small.
  Home is a centred **538/300 stage** with the **real `spr_MainHUD`** overlaid (`lib/ui/hud/hud_overlay.dart`):
  name on the top-left plate, status badges over the gauges, the 4 care actions on the bottom **hex
  slots**, menu on the bottom-right slot. The glass top-bar/dock are retired on home (widgets kept).
- **Living stage:** the pet **ambles** the map — `lib/game/wander.dart` (pure, tested) drives
  idle↔walk + horizontal facing; per-biome ground line (`groundFractionForBiome`) places it correctly;
  `walk` frames added to `assets/creatures/*` + `species.json` + `CareAnim`. Wander pauses while sick
  or mid care-reaction.
- **📌 FUTURE idea (user, 2026-07-18):** swap the home map based on the player's position on the
  **world map** (exploration), instead of biome-driven — belongs to the world/exploration phase.

### ✅ Radial care menu + real HUD buttons (DONE — `feat/hud-overhaul-shell`)

Superseded the earlier "care actions on the hex slots" first pass (and its calibration TODO). Spec:
`docs/superpowers/specs/2026-07-18-radial-care-menu-and-real-hud-buttons-design.md`; plan:
`docs/superpowers/plans/2026-07-18-radial-care-menu-and-real-hud-buttons.md`. 82/82 tests, analyze
clean, on-device verified (landscape).

- **Hex sockets = real menu buttons:** the six `spr_MainHUD` sockets now render the real
  `spr_MainButtons_ENG` frames 0–5 and navigate the RoomScreen shell. Frame→room mapping was
  triangulated from decompiled `obj_MainButtons` GML (`meta/dump/CodeEntries/…Mouse_7.gml`):
  0 DigiVice, 1 Shop/Loja, 2 Training/Treino, 3 Evolution/Evo, 4 Database, 5 Digitize-Battle/Batalha
  (frame 6 Battle-Items is battle-context, not on home). `kRooms` is the six socket-ordered rooms
  (`lib/ui/hud/hud_overlay.dart` `_socketX`/`onOpenRoom`; `lib/ui/shell/room_config.dart`). The old
  `☰`/`showMenuSheet` is retired from home (`menu_sheet.dart` orphaned — cleanup pending). Mapa dropped
  from the sockets (returns in the world/exploration phase).
- **Care loop → radial menu:** tapping the Digimon opens a top-arc menu of the four care actions
  (`lib/ui/hud/care_radial.dart`, pure widget; `lib/ui/hud/pet_tap_target.dart` = the tap zone).
  Real dump art: Feed `spr_Meat_0`, Clean `spr_poop_0`, Medicine `spr_Items_3` (the **Bandage** item),
  Play `spr_Ball_0` (copied via `copy_app_assets.sh` → `assets/game/ui/{menu_buttons,care}/`). Wander
  pauses while the menu is open (`VpetGame.careMenuOpen`); the anchor tracks a walking pet per-frame via
  `VpetGame.petAnchorX` (`ValueNotifier`) + a `ValueListenableBuilder` (final-review fix).
- **Pet scale rebalance (data-only):** `species.json displayHeight` shrunk ~0.71 across the line
  (Botamon 64→45 … MetalGreymon 180→128) so the pet reads as a creature in the landscape.

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
