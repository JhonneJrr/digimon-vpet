# Graph Report - digimon  (2026-07-17)

## Corpus Check
- 29 files · ~15,014 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 288 nodes · 296 edges · 23 communities (20 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `0495b917`
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

## God Nodes (most connected - your core abstractions)
1. `Digimon V-Pet Game — Design Document` - 14 edges
2. `Digimon V-Pet Game Implementation Plan` - 10 edges
3. `Digimon V-Pet — Progress Ledger` - 8 edges
4. `Phase 4 Report — Local Notifications + Periodic Reminder` - 7 edges
5. `Phase 1 — Core State Logic (pure, TDD)` - 7 edges
6. `Verified sprite-sheet frame mapping (Task 2.1)` - 6 edges
7. `Phase 1 — Core State Logic — Implementation Report` - 6 edges
8. `Phase 2 — Game Rendering (Flame)` - 6 edges
9. `PetComponent` - 4 edges
10. `PetRepository` - 4 edges

## Surprising Connections (you probably didn't know these)
- `_FakeRepo` --implements--> `PetRepository`  [EXTRACTED]
  test/vpet_game_test.dart → lib/state/pet_repository.dart

## Import Cycles
- None detected.

## Communities (23 total, 3 thin omitted)

### Community 0 - "Digimon V-Pet Game Implementation Plan"
Cohesion: 0.07
Nodes (29): Digimon V-Pet Game Implementation Plan, File Structure, Global Constraints, Phase 0 — Environment & Scaffolding, Phase 1 — Core State Logic (pure, TDD), Phase 2 — Game Rendering (Flame), Phase 3 — UI Assets, Phase 4 — Notifications (+21 more)

### Community 1 - "vpet_game.dart"
Cohesion: 0.07
Nodes (28): dart:ui, Future, _accum, _act, backgroundColor, clean, _deathNotified, feed (+20 more)

### Community 2 - "pet_component.dart"
Cohesion: 0.09
Nodes (21): HasGameReference, _currentStage, _loadGen, PetComponent, reactBounce, showFor, stageOf, frameSize (+13 more)

### Community 3 - "game_config.dart"
Cohesion: 0.09
Nodes (22): careBumpClean, careBumpFeed, careBumpMedicine, careBumpPlay, careDecayOnSick, careDecayPerHungerPoint, careDecayPerPoop, careScoreThreshold (+14 more)

### Community 4 - "vpet_game_test.dart"
Cohesion: 0.11
Nodes (18): Pet, package:digimon/game/pet_component.dart, package:digimon/game/vpet_game.dart, package:digimon/state/game_config.dart, package:digimon/state/pet.dart, package:digimon/state/pet_logic.dart, package:digimon/state/pet_repository.dart, package:flame/game.dart (+10 more)

### Community 5 - "pet.dart"
Cohesion: 0.10
Nodes (20): int?, careScore, copyWith, fromJson, happiness, happinessSinceMs, health, HealthStatus (+12 more)

### Community 6 - "home_screen.dart"
Cohesion: 0.11
Nodes (18): death_screen.dart, FlameGame, ../game/vpet_game.dart, VpetGame, _btn, build, _buttonRow, createState (+10 more)

### Community 7 - "main.dart"
Cohesion: 0.12
Nodes (14): @pragma, careCheckTaskName, careCheckUniqueName, main, callbackDispatcher, notifications.dart, package:digimon/ui/death_screen.dart, package:flutter/material.dart (+6 more)

### Community 8 - "pet_logic.dart"
Cohesion: 0.13
Nodes (14): dart:math, game_config.dart, applyElapsed, _bump, checkEvolution, _clamp01, clean, feed (+6 more)

### Community 9 - "Digimon V-Pet Game — Design Document"
Cohesion: 0.13
Nodes (14): 10. Notifications & Background, 11. Testing, 12. Out of Scope (This Version), 13. Tooling Note, 1. Overview, 2. Tech Stack, 3. Project Structure, 4. Assets & Visual Direction (+6 more)

### Community 10 - "pet_repository.dart"
Cohesion: 0.20
Nodes (10): dart:convert, clear, _key, load, PetRepository, PrefsPetRepository, save, pet.dart (+2 more)

### Community 11 - "death_screen.dart"
Cohesion: 0.22
Nodes (10): build, createState, DeathScreen, _DeathScreenState, _restarting, HomeScreen, _HomeScreenState, State (+2 more)

### Community 12 - "notifications.dart"
Cohesion: 0.22
Nodes (8): cancelAll, init, _needsYouId, Notifications, _plugin, scheduleNeedsYou, package:flutter_local_notifications/flutter_local_notifications.dart, static const int

### Community 13 - "Digimon V-Pet — Progress Ledger"
Cohesion: 0.22
Nodes (8): BASE for Phase 2 review: 54bffc6, Digimon V-Pet — Progress Ledger, Minor findings deferred to final review, Phase 2 COMPLETE (reviewed + fixed + on-device verified), Phase 2 update (on-device verified), Phase 4 COMPLETE (reworked + verified), Status, Verified facts for downstream

### Community 14 - "Phase 4 Report — Local Notifications + Periodic Reminder"
Cohesion: 0.25
Nodes (7): Commit range, Files changed, lib/state and lib/game, Phase 4 Report — Local Notifications + Periodic Reminder, Plugin-API deviations from the plan's reference code, Status: DONE, Verify results

### Community 15 - "Verified sprite-sheet frame mapping (Task 2.1)"
Cohesion: 0.29
Nodes (6): Cross-stage reliable mapping (USE THIS), Decision for the MVP, NOT cross-stage reliable (do NOT assume a shared index), Sheet geometry (CONFIRMED), spriteSheetForStage mapping (unchanged from plan), Verified sprite-sheet frame mapping (Task 2.1)

### Community 16 - "Phase 1 — Core State Logic — Implementation Report"
Cohesion: 0.29
Nodes (6): Commits (Task order), Deviations from the plan and why, Files created, Final `flutter test` output summary, Phase 1 — Core State Logic — Implementation Report, Scope confirmation

## Knowledge Gaps
- **175 isolated node(s):** `_currentStage`, `_loadGen`, `stageOf`, `showFor`, `reactBounce` (+170 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Pet` connect `vpet_game_test.dart` to `vpet_game.dart`, `pet.dart`?**
  _High betweenness centrality (0.089) - this node is a cross-community bridge._
- **Why does `PetRepository` connect `pet_repository.dart` to `vpet_game.dart`?**
  _High betweenness centrality (0.070) - this node is a cross-community bridge._
- **Why does `Notifications` connect `notifications.dart` to `home_screen.dart`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **What connects `_currentStage`, `_loadGen`, `stageOf` to the rest of the system?**
  _175 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Digimon V-Pet Game Implementation Plan` be split into smaller, more focused modules?**
  _Cohesion score 0.06666666666666667 - nodes in this community are weakly interconnected._
- **Should `vpet_game.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._
- **Should `pet_component.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.08695652173913043 - nodes in this community are weakly interconnected._