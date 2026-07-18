# Phase 0+1 — Data-Driven Creatures Foundation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the pet's identity, evolution, biome, and sprite geometry from hardcoded enums/switches to a data-driven `species.json` model, proven on the Botamon→SkullGreymon line, with behavior preserved 1:1.

**Architecture:** A new pure `DigimonSpecies`/`SpeciesRegistry` model in `lib/state/` is seeded by `assets/data/species.json`. `Pet` is keyed by `speciesId` (old saves migrate). `pet_logic.checkEvolution` reads `species.evolvesTo`; `PetComponent` reads `species.sprite` geometry; biome becomes a species field. The Flame layer loads the JSON once and injects the pure registry into logic/render. The cutover is incremental: a temporary `LifeStage get stage` bridge on `Pet` keeps every consumer compiling so each task ends green; the bridge and the `LifeStage` enum are deleted in the final task.

**Tech Stack:** Flutter 3.44.x · Flame 1.37 · Dart 3.12 · `shared_preferences` · pure Dart JSON.

## Global Constraints

- `lib/state/` MUST NOT import Flutter or Flame — it is the pure, unit-tested layer. `DigimonSpecies`/`SpeciesRegistry` live here and only `fromJson(Map)` / plain Dart.
- Logic functions take an explicit `nowMs` (deterministic; no `DateTime.now()` inside logic).
- No native/NDK code; offline-first; care-loop behavior preserved exactly.
- Keep `flutter analyze` clean; use `.toARGB32()` not `Color.value`.
- Golden/headless tests can't render `Image.asset` — sprite visuals are verified on-device (Task 8), not in widget tests.
- TDD: write the failing test first; commit after each green task.
- **Flutter env (this machine):** Flutter is NOT on PATH. Before any `flutter` command run:
  `$env:Path += ";C:\Users\felip\flutter\bin"; $env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"`
  (or invoke the `/vpet-verify` skill, which sets this and runs analyze + test).
- `species.json` `afterMs` values are pre-scaled for the current build pace (`gameSpeed = 12`); evolution timing no longer scales with `gameSpeed` (a deliberate Phase-1 simplification — stat rates still do).

---

### Task 1: DigimonSpecies data model (pure)

**Files:**
- Create: `lib/state/digimon_species.dart`
- Test: `test/digimon_species_test.dart`

**Interfaces:**
- Consumes: `Biome` from `lib/state/biome.dart` (existing enum).
- Produces: `enum StageTier { fresh, inTraining, rookie, champion, ultimate }`;
  `enum EvoCondition { always, careScoreHigh, careScoreLow }`;
  `class Evolution { String toId; int afterMs; EvoCondition condition; }` + `fromJson`/`toJson`;
  `class Stats { int hp, attack, defense, speed; }` + `fromJson`/`toJson`;
  `class SpriteRef { String sheet; int frameWidth, frameHeight, columns, rows; List<int> idleFrames; double stepTime; }` + `fromJson`/`toJson`;
  `class DigimonSpecies { String id, name; StageTier tier; Biome biome; SpriteRef sprite; List<Evolution> evolvesTo; Stats? stats; }` + `DigimonSpecies.fromJson(String id, Map)`;
  `class SpeciesRegistry` with `factory SpeciesRegistry.fromJson(Map)`, `DigimonSpecies? lookup(String)`, `DigimonSpecies operator [](String)` (throws on miss), `bool contains(String)`, `Iterable<String> get ids`.

- [ ] **Step 1: Write the failing test**

Create `test/digimon_species_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/biome.dart';
import 'package:digimon/state/digimon_species.dart';

void main() {
  final json = {
    'agumon': {
      'name': 'Agumon',
      'tier': 'rookie',
      'biome': 'jungle',
      'sprite': {
        'sheet': 'sprites/Agumon.png',
        'frameWidth': 16, 'frameHeight': 16, 'columns': 3, 'rows': 4,
        'idleFrames': [0, 1], 'stepTime': 0.5,
      },
      'evolvesTo': [
        {'toId': 'greymon', 'afterMs': 75000, 'condition': 'always'},
      ],
    },
  };

  test('DigimonSpecies.fromJson parses all fields', () {
    final s = DigimonSpecies.fromJson('agumon', json['agumon']!);
    expect(s.id, 'agumon');
    expect(s.name, 'Agumon');
    expect(s.tier, StageTier.rookie);
    expect(s.biome, Biome.jungle);
    expect(s.sprite.sheet, 'sprites/Agumon.png');
    expect(s.sprite.frameWidth, 16);
    expect(s.sprite.idleFrames, [0, 1]);
    expect(s.sprite.stepTime, 0.5);
    expect(s.evolvesTo.single.toId, 'greymon');
    expect(s.evolvesTo.single.afterMs, 75000);
    expect(s.evolvesTo.single.condition, EvoCondition.always);
    expect(s.stats, isNull);
  });

  test('SpeciesRegistry lookup, operator[], contains', () {
    final reg = SpeciesRegistry.fromJson(json);
    expect(reg.contains('agumon'), true);
    expect(reg.lookup('agumon')!.name, 'Agumon');
    expect(reg.lookup('nope'), isNull);
    expect(reg['agumon'].id, 'agumon');
    expect(() => reg['nope'], throwsArgumentError);
    expect(reg.ids, contains('agumon'));
  });

  test('Evolution / SpriteRef round-trip through toJson', () {
    final e = Evolution.fromJson(
        {'toId': 'x', 'afterMs': 10, 'condition': 'careScoreHigh'});
    expect(Evolution.fromJson(e.toJson()).condition, EvoCondition.careScoreHigh);
    final sr = SpriteRef.fromJson(json['agumon']!['sprite'] as Map<String, dynamic>);
    expect(SpriteRef.fromJson(sr.toJson()).columns, 3);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/digimon_species_test.dart`
Expected: FAIL — `digimon_species.dart` / types not defined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/state/digimon_species.dart`:

```dart
// lib/state/digimon_species.dart
//
// Pure, data-driven creature model (no Flutter/Flame imports). Seeded by
// assets/data/species.json and injected into the logic/render layers.
import 'biome.dart';

enum StageTier { fresh, inTraining, rookie, champion, ultimate }

enum EvoCondition { always, careScoreHigh, careScoreLow }

class Evolution {
  final String toId;
  final int afterMs; // time in the source stage before this transition is eligible
  final EvoCondition condition;
  const Evolution(
      {required this.toId, required this.afterMs, required this.condition});

  factory Evolution.fromJson(Map<String, dynamic> j) => Evolution(
        toId: j['toId'] as String,
        afterMs: j['afterMs'] as int,
        condition: EvoCondition.values.byName(j['condition'] as String),
      );

  Map<String, dynamic> toJson() =>
      {'toId': toId, 'afterMs': afterMs, 'condition': condition.name};
}

/// Battle stats — RESERVED for a future phase; parsed if present, unused now.
class Stats {
  final int hp, attack, defense, speed;
  const Stats(
      {this.hp = 0, this.attack = 0, this.defense = 0, this.speed = 0});

  factory Stats.fromJson(Map<String, dynamic> j) => Stats(
        hp: j['hp'] as int? ?? 0,
        attack: j['attack'] as int? ?? 0,
        defense: j['defense'] as int? ?? 0,
        speed: j['speed'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'hp': hp, 'attack': attack, 'defense': defense, 'speed': speed};
}

/// Sprite-sheet geometry as data (replaces the old const frameSize + hardcoded
/// idle frames), so a species can carry differently-sized frames.
class SpriteRef {
  final String sheet; // asset path relative to assets/, e.g. "sprites/Agumon.png"
  final int frameWidth, frameHeight, columns, rows;
  final List<int> idleFrames;
  final double stepTime;
  const SpriteRef({
    required this.sheet,
    required this.frameWidth,
    required this.frameHeight,
    required this.columns,
    required this.rows,
    required this.idleFrames,
    required this.stepTime,
  });

  factory SpriteRef.fromJson(Map<String, dynamic> j) => SpriteRef(
        sheet: j['sheet'] as String,
        frameWidth: j['frameWidth'] as int,
        frameHeight: j['frameHeight'] as int,
        columns: j['columns'] as int,
        rows: j['rows'] as int,
        idleFrames:
            (j['idleFrames'] as List).map((e) => e as int).toList(growable: false),
        stepTime: (j['stepTime'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'sheet': sheet,
        'frameWidth': frameWidth,
        'frameHeight': frameHeight,
        'columns': columns,
        'rows': rows,
        'idleFrames': idleFrames,
        'stepTime': stepTime,
      };
}

class DigimonSpecies {
  final String id;
  final String name;
  final StageTier tier;
  final Biome biome;
  final SpriteRef sprite;
  final List<Evolution> evolvesTo; // empty = terminal
  final Stats? stats;
  const DigimonSpecies({
    required this.id,
    required this.name,
    required this.tier,
    required this.biome,
    required this.sprite,
    required this.evolvesTo,
    this.stats,
  });

  factory DigimonSpecies.fromJson(String id, Map<String, dynamic> j) =>
      DigimonSpecies(
        id: id,
        name: j['name'] as String,
        tier: StageTier.values.byName(j['tier'] as String),
        biome: Biome.values.byName(j['biome'] as String),
        sprite: SpriteRef.fromJson(j['sprite'] as Map<String, dynamic>),
        evolvesTo: ((j['evolvesTo'] as List?) ?? const [])
            .map((e) => Evolution.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        stats: j['stats'] == null
            ? null
            : Stats.fromJson(j['stats'] as Map<String, dynamic>),
      );
}

/// Immutable id->species lookup, built from the parsed species.json map.
class SpeciesRegistry {
  final Map<String, DigimonSpecies> _byId;
  const SpeciesRegistry(this._byId);

  factory SpeciesRegistry.fromJson(Map<String, dynamic> j) {
    final map = <String, DigimonSpecies>{};
    j.forEach((id, data) =>
        map[id] = DigimonSpecies.fromJson(id, data as Map<String, dynamic>));
    return SpeciesRegistry(map);
  }

  DigimonSpecies? lookup(String id) => _byId[id];
  DigimonSpecies operator [](String id) =>
      _byId[id] ?? (throw ArgumentError('Unknown species id: $id'));
  bool contains(String id) => _byId.containsKey(id);
  Iterable<String> get ids => _byId.keys;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/digimon_species_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/state/digimon_species.dart test/digimon_species_test.dart
git commit -m "feat: add pure DigimonSpecies/SpeciesRegistry data model"
```

---

### Task 2: species.json seed + asset wiring

**Files:**
- Create: `assets/data/species.json`
- Modify: `pubspec.yaml:64-66` (add `assets/data/` to the assets list)
- Test: `test/species_seed_test.dart`

**Interfaces:**
- Consumes: `SpeciesRegistry.fromJson` (Task 1).
- Produces: the real seed asset (6-species line) loadable at `assets/data/species.json`;
  ids `botamon, koromon, agumon, greymon, metalgreymon, skullgreymon`.

- [ ] **Step 1: Write the failing test**

Create `test/species_seed_test.dart` (reads the real asset from disk via `dart:io`, so it validates the shipped seed, not a fixture):

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/biome.dart';
import 'package:digimon/state/digimon_species.dart';

SpeciesRegistry loadSeed() => SpeciesRegistry.fromJson(
    jsonDecode(File('assets/data/species.json').readAsStringSync())
        as Map<String, dynamic>);

void main() {
  test('seed contains the full Botamon->SkullGreymon line', () {
    final reg = loadSeed();
    for (final id in const [
      'botamon', 'koromon', 'agumon', 'greymon', 'metalgreymon', 'skullgreymon'
    ]) {
      expect(reg.contains(id), true, reason: 'missing $id');
    }
  });

  test('line is fully reachable from botamon and reaches both ultimates', () {
    final reg = loadSeed();
    final reached = <String>{};
    final queue = <String>['botamon'];
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      if (!reached.add(id)) continue;
      for (final e in reg[id].evolvesTo) {
        expect(reg.contains(e.toId), true, reason: '${e.toId} not in registry');
        queue.add(e.toId);
      }
    }
    expect(reached, containsAll(['metalgreymon', 'skullgreymon']));
  });

  test('biomes preserve the pre-refactor mapping', () {
    final reg = loadSeed();
    expect(reg['botamon'].biome, Biome.nursery);
    expect(reg['koromon'].biome, Biome.meadow);
    expect(reg['agumon'].biome, Biome.jungle);
    expect(reg['greymon'].biome, Biome.savanna);
    expect(reg['metalgreymon'].biome, Biome.chrome);
    expect(reg['skullgreymon'].biome, Biome.wasteland);
  });

  test('greymon forks Metal (high care) vs Skull (low care)', () {
    final g = loadSeed()['greymon'];
    expect(g.evolvesTo.map((e) => e.toId),
        containsAll(['metalgreymon', 'skullgreymon']));
    expect(
        g.evolvesTo.firstWhere((e) => e.toId == 'metalgreymon').condition,
        EvoCondition.careScoreHigh);
    expect(
        g.evolvesTo.firstWhere((e) => e.toId == 'skullgreymon').condition,
        EvoCondition.careScoreLow);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/species_seed_test.dart`
Expected: FAIL — `assets/data/species.json` does not exist.

- [ ] **Step 3: Create the seed asset**

Create `assets/data/species.json` (afterMs values = today's `GameConfig.stageDurationMs` at `gameSpeed=12`: 5000 / 25000 / 75000 / 100000):

```json
{
  "botamon": {
    "name": "Botamon",
    "tier": "fresh",
    "biome": "nursery",
    "sprite": { "sheet": "sprites/Botamon.png", "frameWidth": 16, "frameHeight": 16, "columns": 3, "rows": 4, "idleFrames": [0, 1], "stepTime": 0.5 },
    "evolvesTo": [ { "toId": "koromon", "afterMs": 5000, "condition": "always" } ]
  },
  "koromon": {
    "name": "Koromon",
    "tier": "inTraining",
    "biome": "meadow",
    "sprite": { "sheet": "sprites/Koromon.png", "frameWidth": 16, "frameHeight": 16, "columns": 3, "rows": 4, "idleFrames": [0, 1], "stepTime": 0.5 },
    "evolvesTo": [ { "toId": "agumon", "afterMs": 25000, "condition": "always" } ]
  },
  "agumon": {
    "name": "Agumon",
    "tier": "rookie",
    "biome": "jungle",
    "sprite": { "sheet": "sprites/Agumon.png", "frameWidth": 16, "frameHeight": 16, "columns": 3, "rows": 4, "idleFrames": [0, 1], "stepTime": 0.5 },
    "evolvesTo": [ { "toId": "greymon", "afterMs": 75000, "condition": "always" } ]
  },
  "greymon": {
    "name": "Greymon",
    "tier": "champion",
    "biome": "savanna",
    "sprite": { "sheet": "sprites/Greymon.png", "frameWidth": 16, "frameHeight": 16, "columns": 3, "rows": 4, "idleFrames": [0, 1], "stepTime": 0.5 },
    "evolvesTo": [
      { "toId": "metalgreymon", "afterMs": 100000, "condition": "careScoreHigh" },
      { "toId": "skullgreymon", "afterMs": 100000, "condition": "careScoreLow" }
    ]
  },
  "metalgreymon": {
    "name": "MetalGreymon",
    "tier": "ultimate",
    "biome": "chrome",
    "sprite": { "sheet": "sprites/MetalGreymon.png", "frameWidth": 16, "frameHeight": 16, "columns": 3, "rows": 4, "idleFrames": [0, 1], "stepTime": 0.5 },
    "evolvesTo": []
  },
  "skullgreymon": {
    "name": "SkullGreymon",
    "tier": "ultimate",
    "biome": "wasteland",
    "sprite": { "sheet": "sprites/SkullGreymon.png", "frameWidth": 16, "frameHeight": 16, "columns": 3, "rows": 4, "idleFrames": [0, 1], "stepTime": 0.5 },
    "evolvesTo": []
  }
}
```

- [ ] **Step 4: Register the asset folder in pubspec**

In `pubspec.yaml`, under `flutter: assets:`, add the `assets/data/` line so it reads:

```yaml
  assets:
    - assets/sprites/
    - assets/ui/
    - assets/data/
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/species_seed_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add assets/data/species.json pubspec.yaml test/species_seed_test.dart
git commit -m "feat: add species.json seed for the Botamon->SkullGreymon line"
```

---

### Task 3: Pet keyed by speciesId (with migration + LifeStage bridge)

**Files:**
- Modify: `lib/state/pet.dart` (whole file — see below)
- Test: `test/pet_logic_test.dart:7-15` (round-trip assertion) + add a migration test

**Interfaces:**
- Consumes: nothing new.
- Produces: `Pet.speciesId` (String, the new identity); `Pet.copyWith({String? speciesId, LifeStage? stage, ...})`; `LifeStage get stage` (temporary bridge); `Pet.fromJson` migrates legacy `{'stage': int}`. `Pet.newborn` starts at `botamon`. `LifeStage` enum retained for now (removed in Task 7).

- [ ] **Step 1: Write the failing test**

In `test/pet_logic_test.dart`, replace the round-trip test's stage assertion and add a migration test. Change line 12 from `expect(back.stage, LifeStage.baby1);` to:

```dart
    expect(back.speciesId, 'botamon');
```

Then add, right after the round-trip test (after line 15):

```dart
  test('legacy save {stage:int} migrates to speciesId', () {
    final legacy = {
      'stage': 3, // old LifeStage.adult index
      'hunger': 1, 'happiness': 2, 'poopCount': 0, 'health': 0,
      'careScore': 0.7, 'stageStartedAtMs': 500,
      'hungerSinceMs': 500, 'happinessSinceMs': 500, 'poopSinceMs': 500,
      'starvingSinceMs': null, 'messySinceMs': null, 'sickSinceMs': null,
      'isDead': false,
    };
    final p = Pet.fromJson(legacy);
    expect(p.speciesId, 'greymon');
    expect(p.stage, LifeStage.adult); // bridge still resolves
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/pet_logic_test.dart`
Expected: FAIL — `Pet.speciesId` not defined.

- [ ] **Step 3: Rewrite `lib/state/pet.dart`**

Replace the whole file with:

```dart
// lib/state/pet.dart
import 'game_config.dart';

/// Legacy life-stage tier. Retained only as a transitional bridge while the
/// codebase migrates to speciesId; removed once all consumers read the species.
enum LifeStage { baby1, baby2, child, adult, perfectMetal, perfectSkull }

enum HealthStatus { healthy, sick }

/// Ordered ids of the seed line, indexed by the legacy LifeStage index. Used to
/// migrate old saves and to back the temporary `stage` bridge.
const List<String> _lineIds = [
  'botamon', 'koromon', 'agumon', 'greymon', 'metalgreymon', 'skullgreymon',
];

/// Immutable pet state. Identity is [speciesId]; time-driven stats each carry
/// their own "since" anchor (see applyElapsed).
class Pet {
  final String speciesId;
  final int hunger; // 0 = full .. hungerMax = starving
  final int happiness; // 0 = sad .. happinessMax = happy
  final int poopCount;
  final HealthStatus health;
  final double careScore; // 0..1, decides Metal vs Skull
  final int stageStartedAtMs;

  // Per-stat accumulation anchors.
  final int hungerSinceMs;
  final int happinessSinceMs;
  final int poopSinceMs;

  // Neglect / illness event timestamps (null = not currently in that state).
  final int? starvingSinceMs;
  final int? messySinceMs;
  final int? sickSinceMs;

  final bool isDead;

  const Pet({
    required this.speciesId,
    required this.hunger,
    required this.happiness,
    required this.poopCount,
    required this.health,
    required this.careScore,
    required this.stageStartedAtMs,
    required this.hungerSinceMs,
    required this.happinessSinceMs,
    required this.poopSinceMs,
    this.starvingSinceMs,
    this.messySinceMs,
    this.sickSinceMs,
    this.isDead = false,
  });

  /// TEMPORARY bridge: legacy consumers still read `pet.stage`. Removed in the
  /// final migration task once biome/label/sprite all read the species.
  LifeStage get stage {
    final i = _lineIds.indexOf(speciesId);
    return i >= 0 ? LifeStage.values[i] : LifeStage.baby1;
  }

  factory Pet.newborn(int nowMs) => Pet(
        speciesId: 'botamon',
        hunger: 0,
        happiness: GameConfig.happinessMax,
        poopCount: 0,
        health: HealthStatus.healthy,
        careScore: 0.5,
        stageStartedAtMs: nowMs,
        hungerSinceMs: nowMs,
        happinessSinceMs: nowMs,
        poopSinceMs: nowMs,
      );

  Pet copyWith({
    String? speciesId,
    LifeStage? stage, // bridge: maps to speciesId (removed in Task 7)
    int? hunger,
    int? happiness,
    int? poopCount,
    HealthStatus? health,
    double? careScore,
    int? stageStartedAtMs,
    int? hungerSinceMs,
    int? happinessSinceMs,
    int? poopSinceMs,
    int? starvingSinceMs,
    bool clearStarvingSince = false,
    int? messySinceMs,
    bool clearMessySince = false,
    int? sickSinceMs,
    bool clearSickSince = false,
    bool? isDead,
  }) =>
      Pet(
        speciesId:
            speciesId ?? (stage != null ? _lineIds[stage.index] : this.speciesId),
        hunger: hunger ?? this.hunger,
        happiness: happiness ?? this.happiness,
        poopCount: poopCount ?? this.poopCount,
        health: health ?? this.health,
        careScore: careScore ?? this.careScore,
        stageStartedAtMs: stageStartedAtMs ?? this.stageStartedAtMs,
        hungerSinceMs: hungerSinceMs ?? this.hungerSinceMs,
        happinessSinceMs: happinessSinceMs ?? this.happinessSinceMs,
        poopSinceMs: poopSinceMs ?? this.poopSinceMs,
        starvingSinceMs:
            clearStarvingSince ? null : (starvingSinceMs ?? this.starvingSinceMs),
        messySinceMs:
            clearMessySince ? null : (messySinceMs ?? this.messySinceMs),
        sickSinceMs: clearSickSince ? null : (sickSinceMs ?? this.sickSinceMs),
        isDead: isDead ?? this.isDead,
      );

  Map<String, dynamic> toJson() => {
        'speciesId': speciesId,
        'hunger': hunger,
        'happiness': happiness,
        'poopCount': poopCount,
        'health': health.index,
        'careScore': careScore,
        'stageStartedAtMs': stageStartedAtMs,
        'hungerSinceMs': hungerSinceMs,
        'happinessSinceMs': happinessSinceMs,
        'poopSinceMs': poopSinceMs,
        'starvingSinceMs': starvingSinceMs,
        'messySinceMs': messySinceMs,
        'sickSinceMs': sickSinceMs,
        'isDead': isDead,
      };

  factory Pet.fromJson(Map<String, dynamic> j) => Pet(
        // New saves carry speciesId; legacy saves carry a `stage` int index.
        speciesId: j['speciesId'] as String? ?? _lineIds[j['stage'] as int],
        hunger: j['hunger'] as int,
        happiness: j['happiness'] as int,
        poopCount: j['poopCount'] as int,
        health: HealthStatus.values[j['health'] as int],
        careScore: (j['careScore'] as num).toDouble(),
        stageStartedAtMs: j['stageStartedAtMs'] as int,
        hungerSinceMs: j['hungerSinceMs'] as int,
        happinessSinceMs: j['happinessSinceMs'] as int,
        poopSinceMs: j['poopSinceMs'] as int,
        starvingSinceMs: j['starvingSinceMs'] as int?,
        messySinceMs: j['messySinceMs'] as int?,
        sickSinceMs: j['sickSinceMs'] as int?,
        isDead: j['isDead'] as bool,
      );
}
```

- [ ] **Step 4: Run the full suite to verify green (bridge keeps consumers compiling)**

Run: `flutter test`
Expected: PASS — all existing tests still pass (consumers read `pet.stage` via the bridge; evolution still uses the old `checkEvolution`), plus the new migration test.

- [ ] **Step 5: Commit**

```bash
git add lib/state/pet.dart test/pet_logic_test.dart
git commit -m "feat: key Pet by speciesId with legacy-save migration and stage bridge"
```

---

### Task 4: Data-driven evolution

**Files:**
- Modify: `lib/state/pet_logic.dart` (`checkEvolution` + remove `_nextStage`)
- Modify: `lib/game/vpet_game.dart` (load species.json, hold registry, `currentSpecies`, pass registry to `checkEvolution`)
- Test: `test/pet_logic_test.dart` (rewrite the `evolution` group) + `test/vpet_game_test.dart:81` (restart assertion)

**Interfaces:**
- Consumes: `SpeciesRegistry`, `DigimonSpecies`, `Evolution`, `EvoCondition` (Task 1); `assets/data/species.json` (Task 2); `Pet.speciesId` (Task 3).
- Produces: `PetLogic.checkEvolution(Pet, int nowMs, SpeciesRegistry)`; `VpetGame.currentSpecies` getter (`DigimonSpecies`).

- [ ] **Step 1: Rewrite the evolution tests (failing)**

In `test/pet_logic_test.dart`, add imports at the top:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:digimon/state/digimon_species.dart';
```

Add a seed loader above `void main()`:

```dart
SpeciesRegistry seed() => SpeciesRegistry.fromJson(
    jsonDecode(File('assets/data/species.json').readAsStringSync())
        as Map<String, dynamic>);
```

Replace the entire `group('evolution', ...)` block with:

```dart
  group('evolution', () {
    test('botamon evolves to koromon after its duration', () {
      final reg = seed();
      final after = reg['botamon'].evolvesTo.first.afterMs;
      final r = PetLogic.checkEvolution(Pet.newborn(0), after, reg);
      expect(r.speciesId, 'koromon');
      expect(r.stageStartedAtMs, after);
    });

    test('cascades through multiple stages, clock anchored to each threshold', () {
      final reg = seed();
      final b1 = reg['botamon'].evolvesTo.first.afterMs;
      final b2 = reg['koromon'].evolvesTo.first.afterMs;
      final now = b1 + b2 + 5000; // 5s into agumon
      final r = PetLogic.checkEvolution(Pet.newborn(0), now, reg);
      expect(r.speciesId, 'agumon');
      expect(r.stageStartedAtMs, b1 + b2); // not `now`
    });

    test('well-cared greymon -> metalgreymon', () {
      final reg = seed();
      final after = reg['greymon'].evolvesTo.first.afterMs;
      final p = Pet.newborn(0)
          .copyWith(speciesId: 'greymon', careScore: 0.9, stageStartedAtMs: 0);
      final r = PetLogic.checkEvolution(p, after, reg);
      expect(r.speciesId, 'metalgreymon');
    });

    test('neglected greymon -> skullgreymon', () {
      final reg = seed();
      final after = reg['greymon'].evolvesTo.first.afterMs;
      final p = Pet.newborn(0)
          .copyWith(speciesId: 'greymon', careScore: 0.2, stageStartedAtMs: 0);
      final r = PetLogic.checkEvolution(p, after, reg);
      expect(r.speciesId, 'skullgreymon');
    });

    test('ultimate stage does not evolve', () {
      final reg = seed();
      final p = Pet.newborn(0).copyWith(speciesId: 'metalgreymon');
      final r = PetLogic.checkEvolution(p, 999999999, reg);
      expect(r.speciesId, 'metalgreymon');
    });

    test('unknown speciesId is left unchanged (safe)', () {
      final reg = seed();
      final p = Pet.newborn(0).copyWith(speciesId: 'ghost');
      expect(PetLogic.checkEvolution(p, 999999999, reg).speciesId, 'ghost');
    });
  });
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/pet_logic_test.dart`
Expected: FAIL — `checkEvolution` still takes 2 args / uses `stage`.

- [ ] **Step 3: Rewrite `checkEvolution` in `lib/state/pet_logic.dart`**

Add the import at the top of the file (after the existing imports):

```dart
import 'digimon_species.dart';
```

Replace the `checkEvolution` method and the `_nextStage` method (lines 181-214) with:

```dart
  /// Advance through as many stage thresholds as [nowMs] has crossed, starting
  /// each new stage's clock at the instant its predecessor's requirement was met
  /// (not the poll time), so infrequent polling never strands the pet a stage
  /// behind. Data-driven: reads each species' evolvesTo transitions.
  static Pet checkEvolution(Pet p, int nowMs, SpeciesRegistry registry) {
    if (p.isDead) return p;
    var speciesId = p.speciesId;
    var startedAt = p.stageStartedAtMs;
    while (true) {
      final species = registry.lookup(speciesId);
      if (species == null) break; // unknown id -> leave as-is
      final evo = _pickEvolution(species.evolvesTo, nowMs - startedAt, p.careScore);
      if (evo == null) break;
      startedAt += evo.afterMs;
      speciesId = evo.toId;
    }
    if (speciesId == p.speciesId && startedAt == p.stageStartedAtMs) return p;
    return p.copyWith(speciesId: speciesId, stageStartedAtMs: startedAt);
  }

  /// First eligible transition (enough time elapsed AND its condition holds).
  /// Conditions on a fork are complementary, so at most one fires.
  static Evolution? _pickEvolution(
      List<Evolution> options, int elapsedMs, double careScore) {
    for (final e in options) {
      if (elapsedMs < e.afterMs) continue;
      final ok = switch (e.condition) {
        EvoCondition.always => true,
        EvoCondition.careScoreHigh => careScore >= GameConfig.careScoreThreshold,
        EvoCondition.careScoreLow => careScore < GameConfig.careScoreThreshold,
      };
      if (ok) return e;
    }
    return null;
  }
```

- [ ] **Step 4: Wire the registry into `lib/game/vpet_game.dart`**

Add imports at the top:

```dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../state/digimon_species.dart';
```

Add a field after `late Pet pet;` (line 36):

```dart
  late SpeciesRegistry _species;

  /// The current pet's species; falls back to the line start if a save
  /// references an unknown id.
  DigimonSpecies get currentSpecies =>
      _species.lookup(pet.speciesId) ?? _species['botamon'];
```

In `onLoad`, replace lines 61-63:

```dart
    final saved = await repo.load();
    final jsonStr = await rootBundle.loadString('assets/data/species.json');
    _species = SpeciesRegistry.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>);
    pet = saved ?? Pet.newborn(nowMs());
    if (!_species.contains(pet.speciesId)) {
      pet = pet.copyWith(speciesId: 'botamon'); // normalize corrupt/removed id
    }
    pet = PetLogic.checkEvolution(
        PetLogic.applyElapsed(pet, nowMs()), nowMs(), _species);
```

In `update`, replace line 101:

```dart
      pet = PetLogic.checkEvolution(
          PetLogic.applyElapsed(pet, nowMs()), nowMs(), _species);
```

- [ ] **Step 5: Fix the restart assertion in `test/vpet_game_test.dart`**

Change line 81 from `expect(game.pet.stage, LifeStage.baby1);` to:

```dart
    expect(game.pet.speciesId, 'botamon');
```

- [ ] **Step 6: Run the full suite**

Run: `flutter test`
Expected: PASS — evolution now data-driven; `vpet_game_test.onLoad` loads the real `species.json` via `rootBundle`.

- [ ] **Step 7: Commit**

```bash
git add lib/state/pet_logic.dart lib/game/vpet_game.dart test/pet_logic_test.dart test/vpet_game_test.dart
git commit -m "feat: data-driven evolution reads species.evolvesTo via registry"
```

---

### Task 5: Data-driven sprite rendering

**Files:**
- Delete: `lib/game/sprite_map.dart`
- Modify: `lib/game/pet_component.dart` (whole file)
- Modify: `lib/game/vpet_game.dart` (4 `showFor` call sites)
- Test: `test/pet_component_test.dart` (whole file)

**Interfaces:**
- Consumes: `DigimonSpecies`/`SpriteRef` (Task 1); `VpetGame.currentSpecies` (Task 4).
- Produces: `PetComponent.showFor(DigimonSpecies species)`; `const double kPetDisplayHeight = 96;`.

- [ ] **Step 1: Rewrite `test/pet_component_test.dart` (failing)**

```dart
// test/pet_component_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/game/pet_component.dart';

void main() {
  test('PetComponent constructs; showFor is the species-driven API', () {
    final c = PetComponent();
    // showFor loads images asynchronously in-game and needs a mounted game
    // reference, so here we only assert construction wiring exists.
    expect(c, isNotNull);
    expect(c.showFor, isA<Function>());
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/pet_component_test.dart`
Expected: FAIL — old test referenced `stageOf`/`LifeStage`; new one may fail to compile until `pet_component.dart` is updated (that's the failing state).

- [ ] **Step 3: Rewrite `lib/game/pet_component.dart`**

```dart
// lib/game/pet_component.dart
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/animation.dart' show Curves;
import '../state/digimon_species.dart';

/// On-screen height (logical px) the pet renders at, regardless of source frame
/// size — so future larger sprites read at a consistent size.
const double kPetDisplayHeight = 96;

/// Renders the current species as a looping idle animation built from its
/// data-driven [SpriteRef] geometry, plus a press-feedback bounce.
class PetComponent extends SpriteAnimationComponent with HasGameReference {
  String? _currentSpeciesId;
  int _loadGen = 0;

  Future<void> showFor(DigimonSpecies species) async {
    if (_currentSpeciesId == species.id && animation != null) return;
    final gen = ++_loadGen;
    final image = await game.images.load(species.sprite.sheet);
    // Drop a stale load if a newer showFor started while we awaited.
    if (gen != _loadGen) return;
    _currentSpeciesId = species.id;
    final sr = species.sprite;
    final sheet = SpriteSheet(
      image: image,
      srcSize: Vector2(sr.frameWidth.toDouble(), sr.frameHeight.toDouble()),
    );
    animation = SpriteAnimation.spriteList(
      sr.idleFrames.map(sheet.getSpriteById).toList(),
      stepTime: sr.stepTime,
    );
    final scale = kPetDisplayHeight / sr.frameHeight;
    size = Vector2(sr.frameWidth * scale, sr.frameHeight * scale);
  }

  /// Quick "press feedback" bounce: scale up then back down.
  void reactBounce() {
    add(
      ScaleEffect.by(
        Vector2.all(1.15),
        EffectController(
            duration: 0.1, reverseDuration: 0.1, curve: Curves.easeOut),
      ),
    );
  }

  /// Gentle continuous "breathing" scale pulse so the pet reads as alive.
  void startIdlePulse() {
    add(
      ScaleEffect.by(
        Vector2.all(1.04),
        EffectController(
            duration: 0.9,
            reverseDuration: 0.9,
            infinite: true,
            curve: Curves.easeInOut),
      ),
    );
  }
}
```

- [ ] **Step 4: Update `showFor` call sites in `lib/game/vpet_game.dart`**

Change each `petComponent.showFor(pet)` to `petComponent.showFor(currentSpecies)`. There are 4:
- `onLoad` (was line 75): `await petComponent.showFor(currentSpecies);`
- `update` (was line 103): `petComponent.showFor(currentSpecies);`
- `_act` (was line 129): `await petComponent.showFor(currentSpecies);`
- `restart` (was line 142): `await petComponent.showFor(currentSpecies);`

- [ ] **Step 5: Delete the dead sprite_map**

```bash
git rm lib/game/sprite_map.dart
```

- [ ] **Step 6: Run the full suite**

Run: `flutter test`
Expected: PASS. (`pet_component.dart` no longer imports `sprite_map.dart`; nothing else references it.)

- [ ] **Step 7: Commit**

```bash
git add lib/game/pet_component.dart lib/game/vpet_game.dart test/pet_component_test.dart
git commit -m "feat: data-driven sprite geometry; PetComponent.showFor(species); drop sprite_map"
```

---

### Task 6: Biome as a species field; HUD reads the species

**Files:**
- Modify: `lib/state/biome.dart` (drop `biomeForStage` + `pet.dart` import; keep the enum)
- Modify: `lib/ui/hud_theme.dart` (`hudAccentFor(Biome)`)
- Modify: `lib/ui/widgets/top_status_bar.dart` (take `label` + `accent`)
- Modify: `lib/game/vpet_game.dart` (`currentBiome` → `currentSpecies.biome`)
- Modify: `lib/ui/home_screen.dart` (pass `species.name` + accent)
- Test: `test/biome_test.dart` (whole file)

**Interfaces:**
- Consumes: `DigimonSpecies.biome`/`.name` (Task 1); `VpetGame.currentSpecies` (Task 4).
- Produces: `hudAccentFor(Biome biome)`; `TopStatusBar({required String label, required Color accent, VoidCallback? onSettings})`; `VpetGame.currentBiome` (unchanged name, now species-backed).

- [ ] **Step 1: Rewrite `test/biome_test.dart` (failing)**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/biome.dart';
import 'package:digimon/state/digimon_species.dart';

void main() {
  test('each species carries its biome (mapping preserved)', () {
    final reg = SpeciesRegistry.fromJson(
        jsonDecode(File('assets/data/species.json').readAsStringSync())
            as Map<String, dynamic>);
    expect(reg['botamon'].biome, Biome.nursery);
    expect(reg['koromon'].biome, Biome.meadow);
    expect(reg['agumon'].biome, Biome.jungle);
    expect(reg['greymon'].biome, Biome.savanna);
    expect(reg['metalgreymon'].biome, Biome.chrome);
    expect(reg['skullgreymon'].biome, Biome.wasteland);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/biome_test.dart`
Expected: FAIL — old test called `biomeForStage`, which we are about to remove; compile/lookup mismatch.

- [ ] **Step 3: Trim `lib/state/biome.dart`**

```dart
/// Ambient world theme shown behind the pet. Now a field on each species
/// (data-driven), decoupled from any stage enum.
enum Biome { nursery, meadow, jungle, savanna, chrome, wasteland }
```

- [ ] **Step 4: Change `lib/ui/hud_theme.dart`**

```dart
// lib/ui/hud_theme.dart
import 'package:flutter/widgets.dart';
import '../state/biome.dart';
import '../game/biome_palette.dart';

/// HUD accent color, derived from a biome.
Color hudAccentFor(Biome biome) => paletteForBiome(biome).accent;

const double kGlassBlur = 10.0;
const Color kGlassFill = Color(0x24FFFFFF); // ~14% white
const Color kGlassBorder = Color(0x66FFFFFF);
```

- [ ] **Step 5: Change `lib/ui/widgets/top_status_bar.dart`**

```dart
// lib/ui/widgets/top_status_bar.dart
import 'package:flutter/widgets.dart';
import 'glass_panel.dart';

class TopStatusBar extends StatelessWidget {
  const TopStatusBar(
      {super.key, required this.label, required this.accent, this.onSettings});
  final String label;
  final Color accent;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: accent, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13)),
          const Spacer(),
          GestureDetector(
            key: const ValueKey('settings_gear'),
            onTap: onSettings,
            behavior: HitTestBehavior.opaque,
            child: const Icon(_gear, size: 18, color: Color(0x99FFFFFF)),
          ),
        ],
      ),
    );
  }
}

// Material "settings" glyph without importing the whole Material library.
const IconData _gear = IconData(0xe8b8, fontFamily: 'MaterialIcons');
```

- [ ] **Step 6: Change `currentBiome` in `lib/game/vpet_game.dart`**

Replace line 54 (`Biome get currentBiome => biomeForStage(pet.stage);`) with:

```dart
  Biome get currentBiome => currentSpecies.biome;
```

- [ ] **Step 7: Update `lib/ui/home_screen.dart` to pass label + accent**

Add imports:

```dart
import '../state/biome.dart';
import '../state/digimon_species.dart';
import 'hud_theme.dart';
```

Replace the `TopStatusBar(pet: _petOrNull(), onSettings: null)` line (line 79) with `_topBar()`, and add this method to `_HomeScreenState`:

```dart
  Widget _topBar() {
    if (game.isReady) {
      final DigimonSpecies sp = game.currentSpecies;
      return TopStatusBar(
          label: sp.name, accent: hudAccentFor(sp.biome), onSettings: null);
    }
    // Pre-load neutral default (mirrors the newborn fallback intent).
    return TopStatusBar(
        label: 'Botamon',
        accent: hudAccentFor(Biome.nursery),
        onSettings: null);
  }
```

- [ ] **Step 8: Run the full suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/state/biome.dart lib/ui/hud_theme.dart lib/ui/widgets/top_status_bar.dart lib/game/vpet_game.dart lib/ui/home_screen.dart test/biome_test.dart
git commit -m "feat: biome is a species field; HUD label/accent read the species"
```

---

### Task 7: Remove the LifeStage bridge

**Files:**
- Modify: `lib/state/pet.dart` (remove `LifeStage` enum, `stage` getter, `stage` copyWith param)
- Modify: `lib/state/game_config.dart` (remove `stageDurationMs` + the `pet.dart` import)
- Verify: no `LifeStage` / `stageDurationMs` / `biomeForStage` references remain anywhere.

**Interfaces:**
- Consumes: nothing.
- Produces: a codebase with `speciesId` as the sole identity; `_lineIds` (String list) kept in `pet.dart` only for legacy-save migration.

- [ ] **Step 1: Confirm remaining references before editing**

Run: `grep -rn "LifeStage\|stageDurationMs\|biomeForStage\|\.stage\b" lib test`
Expected: matches only in `lib/state/pet.dart` (the bridge) and `lib/state/game_config.dart` (`stageDurationMs`). If any other file still references them, fix that file in its own task first — do not proceed until only these two remain.

- [ ] **Step 2: Trim `lib/state/pet.dart`**

- Delete the `enum LifeStage { ... }` declaration.
- Delete the `LifeStage get stage { ... }` getter.
- In `copyWith`, delete the `LifeStage? stage,` parameter and simplify the `speciesId` line back to:

```dart
        speciesId: speciesId ?? this.speciesId,
```

Keep `const List<String> _lineIds = [...]` (still used by `Pet.fromJson` migration).

- [ ] **Step 3: Trim `lib/state/game_config.dart`**

- Delete `import 'pet.dart';` (line 2).
- Delete the entire `static Map<LifeStage, int> get stageDurationMs => {...};` block (lines 42-47).

- [ ] **Step 4: Run analyze + full suite**

Run: `flutter analyze`
Expected: No issues.

Run: `flutter test`
Expected: PASS — all tests green with `LifeStage` fully removed.

- [ ] **Step 5: Confirm the enum is gone**

Run: `grep -rn "LifeStage" lib test`
Expected: no matches.

- [ ] **Step 6: Commit**

```bash
git add lib/state/pet.dart lib/state/game_config.dart
git commit -m "refactor: remove LifeStage bridge; speciesId is the sole identity"
```

---

### Task 8: On-device visual verification

**Files:** none (verification only).

**Interfaces:**
- Consumes: the running app on the emulator.

- [ ] **Step 1: Run the app and screenshot**

Invoke the `/vpet-run` skill (launches the `digimon_test` AVD, runs the app, captures a screenshot).

- [ ] **Step 2: Verify data-driven rendering**

Confirm on screen:
- The pet renders at the newborn stage (Botamon) via the data-driven geometry, at the same ~96px on-screen size as before.
- The idle animation loops (two-frame breathing) — proving `SpriteRef.idleFrames`/`stepTime` drive it.
- The top status bar shows the species name ("Botamon") and the nursery-tinted accent dot.
- (Optional, faster to observe with a temporarily lowered `gameSpeed` bump or by editing `species.json` afterMs down) evolving swaps the sheet to the next species with no fl! or crash.

- [ ] **Step 3: Record the result**

If it renders and animates correctly, the phase is visually verified. If not, open a `superpowers:systematic-debugging` session — do not patch blindly.

---

## Self-Review

**Spec coverage:**
- Data model (`DigimonSpecies`, `Evolution`, `EvoCondition`, `Stats`, `SpriteRef`, `SpeciesRegistry`) → Task 1. ✓
- `species.json` seed + biome-preserving mapping → Task 2. ✓
- `Pet.speciesId` identity + legacy migration → Task 3. ✓
- Data-driven `checkEvolution` + registry injection + fork by careScore → Task 4. ✓
- Geometry-as-data + `PetComponent.showFor(species)` (idle only) → Task 5. ✓
- Biome as species field; pure layer stays Flutter-free (registry loaded by Flame layer) → Tasks 4/6. ✓
- Error handling (unknown id fallback; normalize on load) → Tasks 4 (`currentSpecies` fallback, `onLoad` normalize) + 4 test. ✓
- Care loop unchanged → untouched `applyElapsed`/`feed`/`clean`/`giveMedicine`/`play`. ✓
- Tests: species round-trip, registry, evolution, migration, reachability, biome → Tasks 1-6. ✓
- On-device visual check → Task 8. ✓
- Out of scope (battles/roster/real-art) → not planned. ✓

**Placeholder scan:** No "TBD/TODO/handle edge cases" — every step shows concrete code/commands. `Stats` is intentionally reserved-and-unused per spec (documented), not a placeholder.

**Type consistency:** `speciesId` (String) used consistently; `checkEvolution(Pet, int, SpeciesRegistry)` signature matches its call sites (Task 4) and tests; `showFor(DigimonSpecies)` matches its call sites (Task 5); `hudAccentFor(Biome)` matches `TopStatusBar`/`home_screen` (Task 6); `currentSpecies`/`currentBiome` names stable.

**Purity check:** `lib/state/` files (`digimon_species.dart`, `pet.dart`, `pet_logic.dart`, `biome.dart`, `game_config.dart`) import only Dart/other-state — the `rootBundle`/`dart:convert` JSON load lives in `lib/game/vpet_game.dart` (Flame layer). ✓
