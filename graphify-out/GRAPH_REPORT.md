# Graph Report - digimon  (2026-07-17)

## Corpus Check
- 65 files · ~63,120 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 620 nodes · 661 edges · 41 communities (33 shown, 8 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `e5384829`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Digimon V-Pet Game Implementation Plan
- vpet_game.dart
- pet_component.dart
- game_config.dart
- vpet_game_test.dart
- pet.dart
- home_screen.dart
- main.dart
- pet_logic.dart
- Digimon V-Pet Game — Design Document
- pet_repository.dart
- death_screen.dart
- notifications.dart
- Digimon V-Pet — Progress Ledger
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
- pet_component.dart
- PetComponent

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

## Communities (41 total, 8 thin omitted)

### Community 0 - "Digimon V-Pet Game Implementation Plan"
Cohesion: 0.07
Nodes (29): Digimon V-Pet Game Implementation Plan, File Structure, Global Constraints, Phase 0 — Environment & Scaffolding, Phase 1 — Core State Logic (pure, TDD), Phase 2 — Game Rendering (Flame), Phase 3 — UI Assets, Phase 4 — Notifications (+21 more)

### Community 1 - "vpet_game.dart"
Cohesion: 0.05
Nodes (36): Biome get, bool get, DigimonSpecies get, Future, _accum, _act, backgroundColor, clean (+28 more)

### Community 2 - "pet_component.dart"
Cohesion: 0.12
Nodes (15): Addendum — as-built (2026-07-17): real art + per-state animations, Art, `assets/data/species.json` (seed — illustrative shape), Data model (`lib/state/`, pure, tested), Decisions (from brainstorm), Error handling / edge cases, Evolution logic (`pet_logic.dart`), Goal (+7 more)

### Community 3 - "game_config.dart"
Cohesion: 0.06
Nodes (30): careBumpClean, careBumpFeed, careBumpMedicine, careBumpPlay, careDecayOnSick, careDecayPerHungerPoint, careDecayPerPoop, careScoreThreshold (+22 more)

### Community 4 - "vpet_game_test.dart"
Cohesion: 0.08
Nodes (24): dart:math, digimon_species.dart, game_config.dart, applyElapsed, _bump, checkEvolution, _clamp01, clean (+16 more)

### Community 5 - "pet.dart"
Cohesion: 0.09
Nodes (22): int?, careScore, copyWith, fromJson, happiness, happinessSinceMs, health, HealthStatus (+14 more)

### Community 6 - "home_screen.dart"
Cohesion: 0.07
Nodes (31): death_screen.dart, FlameGame, ../game/vpet_game.dart, VpetGame, build, createState, DeathScreen, _DeathScreenState (+23 more)

### Community 7 - "main.dart"
Cohesion: 0.15
Nodes (11): @pragma, careCheckTaskName, careCheckUniqueName, main, callbackDispatcher, notifications.dart, package:workmanager/workmanager.dart, pet_logic.dart (+3 more)

### Community 8 - "pet_logic.dart"
Cohesion: 0.05
Nodes (39): dart:convert, dart:io, Function, package:digimon/game/biome_palette.dart, package:digimon/game/pet_component.dart, package:digimon/game/vpet_game.dart, package:digimon/state/biome.dart, package:digimon/state/digimon_species.dart (+31 more)

### Community 9 - "Digimon V-Pet Game — Design Document"
Cohesion: 0.13
Nodes (14): 10. Notifications & Background, 11. Testing, 12. Out of Scope (This Version), 13. Tooling Note, 1. Overview, 2. Tech Stack, 3. Project Structure, 4. Assets & Visual Direction (+6 more)

### Community 10 - "pet_repository.dart"
Cohesion: 0.06
Nodes (34): bool feedEnabled, cleanEnabled, medicineEnabled,, glass_panel.dart, IconData, Pet, ActionDock, _btn, build, onPlay (+26 more)

### Community 11 - "death_screen.dart"
Cohesion: 0.08
Nodes (24): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+16 more)

### Community 12 - "notifications.dart"
Cohesion: 0.07
Nodes (27): Color, dart:ui, EdgeInsets, ../game/biome_palette.dart, ../hud_theme.dart, accent, BiomePalette, far (+19 more)

### Community 13 - "Digimon V-Pet — Progress Ledger"
Cohesion: 0.09
Nodes (26): biome_palette.dart, HasGameReference, applyPalette, _bottom, _color, _current, _far, _ground (+18 more)

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
Cohesion: 0.12
Nodes (15): Digimon V-Pet — project guide, How to work here — always use Superpowers, Navigating the code — use graphify, Architecture (current), Build / run, Current app (v0.2) — what it does, Dev helpers (this project), Digimon Game — Progress & Roadmap (+7 more)

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
Cohesion: 0.05
Nodes (35): biome.dart, int hp, attack, defense,, Iterable, Biome, afterMs, AnimClip, biome, _byId (+27 more)

### Community 38 - "Global Constraints"
Cohesion: 0.17
Nodes (11): Global Constraints, Phase 0+1 — Data-Driven Creatures Foundation — Implementation Plan, Self-Review, Task 1: DigimonSpecies data model (pure), Task 2: species.json seed + asset wiring, Task 3: Pet keyed by speciesId (with migration + LifeStage bridge), Task 4: Data-driven evolution, Task 5: Data-driven sprite rendering (+3 more)

### Community 45 - "pet_component.dart"
Cohesion: 0.12
Nodes (15): _base, _loadGen, _play, playReaction, reactBounce, _scale, showFor, _speciesId (+7 more)

## Knowledge Gaps
- **400 isolated node(s):** `skyTop`, `skyBottom`, `far`, `mid`, `ground` (+395 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Notifications` connect `game_config.dart` to `home_screen.dart`?**
  _High betweenness centrality (0.054) - this node is a cross-community bridge._
- **Why does `Pet` connect `pet_repository.dart` to `pet_logic.dart`, `vpet_game.dart`, `pet.dart`?**
  _High betweenness centrality (0.054) - this node is a cross-community bridge._
- **Why does `SpeciesRegistry` connect `digimon_species.dart` to `vpet_game.dart`?**
  _High betweenness centrality (0.038) - this node is a cross-community bridge._
- **What connects `skyTop`, `skyBottom`, `far` to the rest of the system?**
  _400 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Digimon V-Pet Game Implementation Plan` be split into smaller, more focused modules?**
  _Cohesion score 0.06666666666666667 - nodes in this community are weakly interconnected._
- **Should `vpet_game.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05405405405405406 - nodes in this community are weakly interconnected._
- **Should `pet_component.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._