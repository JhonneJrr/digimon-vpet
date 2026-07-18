# Graph Report - digimon  (2026-07-18)

## Corpus Check
- 91 files · ~122,787 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 812 nodes · 867 edges · 64 communities (54 shown, 10 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `4c267980`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Digimon V-Pet Game Implementation Plan
- vpet_game.dart
- pet_component.dart
- game_config.dart
- room_config.dart
- pet.dart
- home_screen.dart
- main.dart
- pet_logic.dart
- Digimon V-Pet Game — Design Document
- pet_repository.dart
- death_screen.dart
- notifications.dart
- package:flutter/material.dart
- Phase 4 Report — Local Notifications + Periodic Reminder
- Verified sprite-sheet frame mapping (Task 2.1)
- Phase 1 — Core State Logic — Implementation Report
- MainActivity
- digimon
- make_icons.py
- graphify reference: extra exports and benchmark
- graphify reference: query, path, explain
- graphify reference: add a URL and watch a folder
- graphify reference: commit hook and native CLAUDE.md integration
- graphify reference: incremental update and cluster-only
- graphify reference: GitHub clone and cross-repo merge
- graphify reference: transcribe video and audio
- CLAUDE.md
- CLAUDE.md
- extraction-spec.md
- Procedure
- /vpet-verify
- Flutter/Flame Reviewer — Digimon V-Pet
- Plan 2 — Settings, Lockable HUD Color & Audio — Implementation Plan
- digimon_species.dart
- Global Constraints
- checkpoint.md
- Sprite library reorganization — hybrid name + line taxonomy
- build_manifest.py
- Sprite library builder — Digital Tamers Reborn art
- pet_component.dart
- wander.dart
- vpet_game_test.dart
- File Structure
- pet_repository.dart
- species_seed_test.dart
- top_status_bar_test.dart
- pet_logic_test.dart
- action_dock_test.dart
- copy_app_assets.sh
- hud_overlay.dart
- action_dock.dart
- package:flutter_test/flutter_test.dart
- pet_tap_target.dart
- vpet_game_test.dart
- action_dock.dart
- StatelessWidget
- package:digimon/state/biome.dart
- MapBackgroundComponent

## God Nodes (most connected - your core abstractions)
1. `HUD Glass Redesign — Implementation Plan (Plan 1: Visual Core / Beta)` - 17 edges
2. `Digimon V-Pet Game — Design Document` - 14 edges
3. `Phase 0+1 — Data-Driven Creatures Foundation — Design` - 14 edges
4. `Plan 2 — Settings, Lockable HUD Color & Audio — Implementation Plan` - 13 edges
5. `What You Must Do When Invoked` - 12 edges
6. `Digimon V-Pet — Plan 2: Settings, Lockable HUD Color & Audio — Design Document` - 12 edges
7. `Digimon Game — Progress & Roadmap` - 11 edges
8. `Digimon V-Pet — HUD & Visual Redesign — Design Document` - 11 edges
9. `/graphify` - 10 edges
10. `Digimon V-Pet Game Implementation Plan` - 10 edges

## Surprising Connections (you probably didn't know these)
- `_FakeRepo` --implements--> `PetRepository`  [EXTRACTED]
  test/vpet_game_test.dart → lib/state/pet_repository.dart

## Import Cycles
- None detected.

## Communities (64 total, 10 thin omitted)

### Community 0 - "Digimon V-Pet Game Implementation Plan"
Cohesion: 0.07
Nodes (29): Digimon V-Pet Game Implementation Plan, File Structure, Global Constraints, Phase 0 — Environment & Scaffolding, Phase 1 — Core State Logic (pure, TDD), Phase 2 — Game Rendering (Flame), Phase 3 — UI Assets, Phase 4 — Notifications (+21 more)

### Community 1 - "vpet_game.dart"
Cohesion: 0.05
Nodes (43): Biome get, DigimonSpecies get, Future, _accum, _act, backgroundColor, careMenuOpen, clean (+35 more)

### Community 2 - "pet_component.dart"
Cohesion: 0.12
Nodes (15): Addendum — as-built (2026-07-17): real art + per-state animations, Art, `assets/data/species.json` (seed — illustrative shape), Data model (`lib/state/`, pure, tested), Decisions (from brainstorm), Error handling / edge cases, Evolution logic (`pet_logic.dart`), Goal (+7 more)

### Community 3 - "game_config.dart"
Cohesion: 0.06
Nodes (30): careBumpClean, careBumpFeed, careBumpMedicine, careBumpPlay, careDecayOnSick, careDecayPerHungerPoint, careDecayPerPoop, careScoreThreshold (+22 more)

### Community 4 - "room_config.dart"
Cohesion: 0.14
Nodes (13): File Structure, Global Constraints, Notes for the implementer, Radial Care Menu + Real HUD Menu Buttons — Implementation Plan, Task 1: Copy real button + care icons + Database room bg; register in pubspec, Task 2: Shrink the pet line (data-only species.json), Task 3: VpetGame — pet-anchor getters + `careMenuOpen` wander gate, Task 4: `CareRadial` — the four care bubbles (pure widget) (+5 more)

### Community 5 - "pet.dart"
Cohesion: 0.09
Nodes (21): int?, careScore, copyWith, fromJson, happiness, happinessSinceMs, health, HealthStatus (+13 more)

### Community 6 - "home_screen.dart"
Cohesion: 0.06
Nodes (38): death_screen.dart, FlameGame, ../game/vpet_game.dart, hud/care_radial.dart, hud/hud_overlay.dart, hud/pet_tap_target.dart, VpetGame, build (+30 more)

### Community 7 - "main.dart"
Cohesion: 0.12
Nodes (14): @pragma, careCheckTaskName, careCheckUniqueName, main, setEnabledSystemUIMode, setPreferredOrientations, callbackDispatcher, notifications.dart (+6 more)

### Community 8 - "pet_logic.dart"
Cohesion: 0.20
Nodes (8): package:digimon/game/wander.dart, package:digimon/state/game_config.dart, package:digimon/ui/widgets/status_badges.dart, package:flutter_test/flutter_test.dart, main, main, _pet, main

### Community 9 - "Digimon V-Pet Game — Design Document"
Cohesion: 0.13
Nodes (14): 10. Notifications & Background, 11. Testing, 12. Out of Scope (This Version), 13. Tooling Note, 1. Overview, 2. Tech Stack, 3. Project Structure, 4. Assets & Visual Direction (+6 more)

### Community 10 - "pet_repository.dart"
Cohesion: 0.13
Nodes (12): package:digimon/ui/death_screen.dart, package:digimon/ui/hud/hud_overlay.dart, package:digimon/ui/shell/menu_sheet.dart, package:digimon/ui/shell/room_config.dart, package:digimon/ui/shell/room_screen.dart, package:digimon/ui/widgets/glass_panel.dart, package:flutter/material.dart, main (+4 more)

### Community 11 - "death_screen.dart"
Cohesion: 0.08
Nodes (24): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+16 more)

### Community 12 - "notifications.dart"
Cohesion: 0.05
Nodes (41): Color, dart:ui, EdgeInsets, ../game/biome_palette.dart, ../hud_theme.dart, accent, BiomePalette, far (+33 more)

### Community 13 - "package:flutter/material.dart"
Cohesion: 0.12
Nodes (14): showMenuSheet, backgroundAsset, comingSoon, content, kRooms, RoomConfig, title, build (+6 more)

### Community 14 - "Phase 4 Report — Local Notifications + Periodic Reminder"
Cohesion: 0.11
Nodes (17): File Structure, Global Constraints, HUD Glass Redesign — Implementation Plan (Plan 1: Visual Core / Beta), Out of Scope (deferred to Plan 2), Self-Review (against the spec), Task 10: Top status bar, Task 11: Compose the new HUD in HomeScreen, Task 12: Whole-feature review + verification pass (+9 more)

### Community 15 - "Verified sprite-sheet frame mapping (Task 2.1)"
Cohesion: 0.11
Nodes (17): 10. Versioning / Docs, 11. Out of Scope (This Version), 1. Overview, 2. Goals & Non-Goals, 3.1 Nature of the sounds (research finding), 3.2 Asset sourcing (IP note), 3.3 Sound events, 3.4 Design (+9 more)

### Community 16 - "Phase 1 — Core State Logic — Implementation Report"
Cohesion: 0.12
Nodes (16): 10. Out of Scope (This Version) / Deferred, 1. Overview, 2. Goals & Non-Goals, 3. Visual Direction, 4.1 World / parallax background (`lib/game/`), 4.2 Biome system (`lib/state/`), 4.3 HUD chrome (`lib/ui/`), 4.4 HUD color customization (+8 more)

### Community 23 - "graphify reference: extra exports and benchmark"
Cohesion: 0.22
Nodes (8): graphify reference: extra exports and benchmark, Step 6b - Wiki (only if --wiki flag), Step 7 - Neo4j export (only if --neo4j or --neo4j-push flag), Step 7a - FalkorDB export (only if --falkordb or --falkordb-push flag), Step 7b - SVG export (only if --svg flag), Step 7c - GraphML export (only if --graphml flag), Step 7d - MCP server (only if --mcp flag), Step 8 - Token reduction benchmark (only if total_words > 5000)

### Community 24 - "graphify reference: query, path, explain"
Cohesion: 0.33
Nodes (5): For /graphify explain, For /graphify path, graphify reference: query, path, explain, Step 0 — Constrained query expansion (REQUIRED before traversal), Step 1 — Traversal

### Community 25 - "graphify reference: add a URL and watch a folder"
Cohesion: 0.50
Nodes (3): For /graphify add, For --watch, graphify reference: add a URL and watch a folder

### Community 26 - "graphify reference: commit hook and native CLAUDE.md integration"
Cohesion: 0.50
Nodes (3): For git commit hook, For native CLAUDE.md integration, graphify reference: commit hook and native CLAUDE.md integration

### Community 27 - "graphify reference: incremental update and cluster-only"
Cohesion: 0.50
Nodes (3): For --cluster-only, For --update (incremental re-extraction), graphify reference: incremental update and cluster-only

### Community 30 - "CLAUDE.md"
Cohesion: 0.10
Nodes (18): Digimon V-Pet — project guide, How to work here — always use Superpowers, Navigating the code — use graphify, Architecture (current), Build / run, Current app (v0.2) — what it does, Dev helpers (this project), Digimon Game — Progress & Roadmap (+10 more)

### Community 33 - "Procedure"
Cohesion: 0.20
Nodes (9): 1. Is a device already connected?, 2. Launch the emulator (only if none connected), 3. Run the app (background — `flutter run` stays alive), 4. Screenshot, 5. Stop when done, Environment, Notes / gotchas, Procedure (+1 more)

### Community 34 - "/vpet-verify"
Cohesion: 0.29
Nodes (6): Notes, Reading the result, Run it, The environment (why this skill exists), /vpet-verify, When to use

### Community 35 - "Flutter/Flame Reviewer — Digimon V-Pet"
Cohesion: 0.33
Nodes (5): First, orient (don't grep blind), Flutter/Flame Reviewer — Digimon V-Pet, Hard invariants — a violation is at least Important, usually Critical, Output format, Project-specific quality checks

### Community 36 - "Plan 2 — Settings, Lockable HUD Color & Audio — Implementation Plan"
Cohesion: 0.14
Nodes (13): File Structure, Global Constraints, Plan 2 — Settings, Lockable HUD Color & Audio — Implementation Plan, Self-Review (against the spec), Task 1: AppPreferences + PreferencesRepository, Task 2: hudAccentFor override, Task 3: SfxEvent + SoundPlayer + AudioService, Task 4: flame_audio player + placeholder beep assets (+5 more)

### Community 37 - "digimon_species.dart"
Cohesion: 0.06
Nodes (34): biome.dart, int hp, attack, defense,, Iterable, afterMs, AnimClip, biome, _byId, clip (+26 more)

### Community 38 - "Global Constraints"
Cohesion: 0.17
Nodes (11): Global Constraints, Phase 0+1 — Data-Driven Creatures Foundation — Implementation Plan, Self-Review, Task 1: DigimonSpecies data model (pure), Task 2: species.json seed + asset wiring, Task 3: Pet keyed by speciesId (with migration + LifeStage bridge), Task 4: Data-driven evolution, Task 5: Data-driven sprite rendering (+3 more)

### Community 40 - "Sprite library reorganization — hybrid name + line taxonomy"
Cohesion: 0.15
Nodes (12): Context, Design, Execution pipeline, Folder layout, Goals, Line-cutting rules (the core semantics), Non-goals, Pose & battle-sprite mapping (+4 more)

### Community 42 - "Sprite library builder — Digital Tamers Reborn art"
Cohesion: 0.33
Nodes (5): Files, Regenerate, Sprite library builder — Digital Tamers Reborn art, What it produces (`DigitalTamers02_extracted/organized/`), Why lines are curated, not automatic

### Community 45 - "pet_component.dart"
Cohesion: 0.13
Nodes (14): Architecture / files, Asset pipeline, Context, Design, Extensibility for combat/training, Future (out of scope here), Goals, HUD — hybrid (+6 more)

### Community 46 - "wander.dart"
Cohesion: 0.12
Nodes (16): bool get, double get, double pauseMin,, int get, _facing, isWalking, _minX, _pause (+8 more)

### Community 47 - "vpet_game_test.dart"
Cohesion: 0.22
Nodes (8): IconData, accent, build, _gear, label, _menu, onMenu, onSettings

### Community 48 - "File Structure"
Cohesion: 0.17
Nodes (11): File Structure, Global Constraints, HUD Overhaul + Navigation Shell Implementation Plan, Self-Review, Task 1: Asset pipeline, Task 2: MapBackgroundComponent + biome→map mapping, Task 3: Wire MapBackground into VpetGame; retire WorldBackground, Task 4: Hybrid HUD — menu button in the top bar (+3 more)

### Community 49 - "pet_repository.dart"
Cohesion: 0.06
Nodes (32): applyBiome, _biome, groundFractionForBiome, groundTopFraction, mapAssetForBiome, _paint, render, _sprite (+24 more)

### Community 50 - "species_seed_test.dart"
Cohesion: 0.17
Nodes (11): dart:convert, dart:io, package:digimon/state/digimon_species.dart, package:digimon/state/pet_logic.dart, main, json, main, main (+3 more)

### Community 51 - "top_status_bar_test.dart"
Cohesion: 0.13
Nodes (14): double anchorX,, anchorY, build, _cleanAccent, _cleanOff, _feedAccent, _feedOff, _medAccent (+6 more)

### Community 52 - "pet_logic_test.dart"
Cohesion: 0.17
Nodes (11): A. Hex sockets → real menu buttons, B. Care loop → radial menu around the Digimon, C. Assets, Components & boundaries, D. Pet scale rebalance (data-only), Design, Design — Radial care menu + real HUD menu buttons, Out of scope (+3 more)

### Community 53 - "action_dock_test.dart"
Cohesion: 0.08
Nodes (23): digimon_species.dart, game_config.dart, applyElapsed, _bump, checkEvolution, _clamp01, clean, feed (+15 more)

### Community 55 - "hud_overlay.dart"
Cohesion: 0.22
Nodes (8): build, name, pet, _socketX, _socketY, ../shell/room_config.dart, ../../state/pet.dart, ../widgets/status_badges.dart

### Community 56 - "action_dock.dart"
Cohesion: 0.25
Nodes (7): bool feedEnabled, cleanEnabled, medicineEnabled,, ActionDock, _btn, build, onPlay, playEnabled, VoidCallback onFeed, onClean, onMedicine,

### Community 57 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.50
Nodes (3): Function, package:digimon/game/pet_component.dart, main

### Community 58 - "pet_tap_target.dart"
Cohesion: 0.25
Nodes (7): dart:math, double anchorX, groundFraction,, build, heightFraction, onTap, PetTapTarget, VoidCallback?

### Community 59 - "vpet_game_test.dart"
Cohesion: 0.17
Nodes (11): package:digimon/game/vpet_game.dart, package:digimon/state/pet.dart, package:digimon/state/pet_repository.dart, package:flame/game.dart, package:shared_preferences/shared_preferences.dart, main, clear, load (+3 more)

### Community 60 - "action_dock.dart"
Cohesion: 0.29
Nodes (6): glass_panel.dart, Pet, _badge, build, pet, ../../state/game_config.dart

### Community 61 - "StatelessWidget"
Cohesion: 0.33
Nodes (6): CareRadial, HudOverlay, GlassPanel, StatusBadges, TopStatusBar, StatelessWidget

### Community 62 - "package:digimon/state/biome.dart"
Cohesion: 0.29
Nodes (5): package:digimon/game/biome_palette.dart, package:digimon/game/map_background.dart, package:digimon/state/biome.dart, main, main

### Community 63 - "MapBackgroundComponent"
Cohesion: 0.40
Nodes (5): HasGameReference, MapBackgroundComponent, PetComponent, PositionComponent, SpriteAnimationComponent

## Knowledge Gaps
- **519 isolated node(s):** `BiomePalette`, `skyTop`, `skyBottom`, `far`, `mid` (+514 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Pet` connect `action_dock.dart` to `vpet_game.dart`, `vpet_game_test.dart`, `pet.dart`, `hud_overlay.dart`?**
  _High betweenness centrality (0.042) - this node is a cross-community bridge._
- **Why does `Notifications` connect `game_config.dart` to `home_screen.dart`?**
  _High betweenness centrality (0.041) - this node is a cross-community bridge._
- **Why does `Biome` connect `pet_repository.dart` to `vpet_game.dart`, `digimon_species.dart`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **What connects `BiomePalette`, `skyTop`, `skyBottom` to the rest of the system?**
  _519 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Digimon V-Pet Game Implementation Plan` be split into smaller, more focused modules?**
  _Cohesion score 0.06666666666666667 - nodes in this community are weakly interconnected._
- **Should `vpet_game.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.045454545454545456 - nodes in this community are weakly interconnected._
- **Should `pet_component.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._