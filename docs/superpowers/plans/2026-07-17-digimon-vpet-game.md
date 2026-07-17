# Digimon V-Pet Game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an accelerated-pace Tamagotchi/Digivice-style virtual pet game for Android where a Digimon grows hungry, messes, gets sick, evolves, and can die from neglect.

**Architecture:** Pure Dart game logic (stats, time, evolution, death) lives in `lib/state` as side-effect-free functions tested with `flutter test`. Flame renders the pet and screen in `lib/game`; Flutter hosts non-canvas screens in `lib/ui`. State is recomputed from a persisted `lastTick` timestamp on app resume (no reliable background ticking on Android).

**Tech Stack:** Flutter (stable) + Flame, `shared_preferences` (JSON persistence), `flutter_local_notifications`, `workmanager`. Dart null-safety.

## Global Constraints

- Platform: **Android** only for this version.
- Language: **Dart**, null-safety enabled.
- All time-dependent game logic takes an explicit `nowMs` (int, milliseconds since epoch) parameter — pure functions never read the clock directly, for deterministic tests.
- A single `GameConfig.gameSpeed` multiplier controls all rates; set to accelerated.
- UI is ORIGINAL pixel-art (no Bandai device art / logo). Character sprites only, from `assets/sprites/`.
- No battles, no home-screen widget, no discipline system beyond `careScore` (see spec §12).
- Existing Android SDK at `C:\Users\felip\AppData\Local\Android\Sdk`; bundled JDK at `C:\Program Files\Android\Android Studio\jbr`. Flutter must be pointed at these, not a fresh install.

---

## File Structure

```
digimon/
  assets/
    sprites/                 # existing character sheets (Botamon.png ... SkullGreymon.png)
    ui/                      # pixel-art status icons (created in Task 3.1)
  lib/
    main.dart                # app entry, bootstraps game + persistence
    state/
      game_config.dart       # tuning constants + gameSpeed
      pet.dart               # Pet model, enums, toJson/fromJson, copyWith
      pet_logic.dart         # pure functions: applyElapsed, feed, clean, ...
      pet_repository.dart    # persistence interface + shared_preferences impl
    game/
      sprite_map.dart        # stage -> sheet path + frame-index -> animation map
      pet_component.dart     # Flame SpriteAnimationComponent for the pet
      vpet_game.dart         # FlameGame wiring component + logic + timer
    ui/
      home_screen.dart       # main screen: game canvas + button row + status icons
      death_screen.dart      # death + restart
  test/
    pet_logic_test.dart
    pet_repository_test.dart
  docs/superpowers/{specs,plans}/
```

---

## Phase 0 — Environment & Scaffolding

### Task 0.1: Install Flutter toolchain and wire it to the existing Android SDK/JDK

**Files:** none (environment only).

**Interfaces:**
- Produces: a working `flutter` on PATH; `flutter doctor` passing for Android.

> ⚠️ Installing Flutter needs admin elevation. If the automated command is blocked, the user must run it via the `! <command>` prompt in the session. Prefer the Chocolatey path since `choco` is present.

- [ ] **Step 1: Install Flutter via Chocolatey (elevated)**

Run (PowerShell, admin):
```powershell
choco install flutter -y
```
Expected: Chocolatey reports Flutter installed and added to PATH. If elevation is refused, fall back to Step 1b.

- [ ] **Step 1b (fallback): Manual Flutter install**

Download the latest stable Flutter SDK zip from https://docs.flutter.dev/get-started/install/windows, extract to `C:\src\flutter`, and add `C:\src\flutter\bin` to the user PATH:
```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", "User")
```

- [ ] **Step 2: Verify flutter runs (new shell)**

Run:
```powershell
flutter --version
```
Expected: prints Flutter + Dart versions, no "command not found".

- [ ] **Step 3: Point Flutter at the existing Android SDK and JDK**

Run:
```powershell
flutter config --android-sdk "C:\Users\felip\AppData\Local\Android\Sdk"
flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"
```
Expected: "Setting ... value to ..." confirmations.

- [ ] **Step 4: Install Android cmdline-tools if missing, then accept licenses**

The SDK's `cmdline-tools` folder is empty. Install it via Android Studio's SDK Manager, or:
```powershell
& "C:\Users\felip\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.exe" "cmdline-tools;latest"
flutter doctor --android-licenses
```
Accept all licenses (`y`). If `sdkmanager` is absent, open Android Studio → SDK Manager → SDK Tools → check "Android SDK Command-line Tools" → Apply, then rerun `flutter doctor --android-licenses`.

- [ ] **Step 5: Run flutter doctor**

Run:
```powershell
flutter doctor
```
Expected: `[✓] Flutter` and `[✓] Android toolchain` are checked. Chrome/VS Code/Studio items may warn — those are fine for an Android build.

### Task 0.2: Scaffold the Flutter project in-place and initialize git

**Files:**
- Create: entire Flutter project under `C:\Users\felip\Documents\digimon` (keeps existing `assets`/`docs`).

**Interfaces:**
- Produces: a runnable Flutter app; git repo with first commit.

- [ ] **Step 1: Create the Flutter project in the current folder**

Run from `C:\Users\felip\Documents\digimon`:
```powershell
flutter create --project-name digimon --org com.digimon.vpet --platforms android .
```
Expected: files generated (`lib/main.dart`, `android/`, `pubspec.yaml`) alongside existing `assets/`, `docs/`, and the sprite PNGs.

- [ ] **Step 2: Initialize git and make the first commit**

Run:
```powershell
git init
git add -A
git commit -m "chore: scaffold Flutter Android project with existing sprite assets"
```
Expected: initial commit created. (`flutter create` writes a suitable `.gitignore`.)

- [ ] **Step 3: Smoke-test the scaffold builds**

Run:
```powershell
flutter analyze
```
Expected: "No issues found!" (or only info-level lints).

- [ ] **Step 4: Commit any analyzer fixes if needed**

```powershell
git add -A && git commit -m "chore: clean up scaffold lints" --allow-empty
```

### Task 0.3: Add dependencies and register sprite assets

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Produces: `flame`, `shared_preferences`, `flutter_local_notifications`, `workmanager` available; `assets/sprites/` and `assets/ui/` bundled.

- [ ] **Step 1: Add packages**

Run:
```powershell
flutter pub add flame shared_preferences flutter_local_notifications workmanager
```
Expected: `pubspec.yaml` updated, `flutter pub get` runs clean.

- [ ] **Step 2: Register asset folders in pubspec.yaml**

Under `flutter:` add:
```yaml
  assets:
    - assets/sprites/
    - assets/ui/
```

- [ ] **Step 3: Create the ui asset folder placeholder**

Run:
```powershell
New-Item -ItemType Directory -Force assets/ui | Out-Null
New-Item -ItemType File assets/ui/.gitkeep | Out-Null
```

- [ ] **Step 4: Verify pub get and commit**

```powershell
flutter pub get
git add -A && git commit -m "chore: add flame + persistence + notification deps, register assets"
```
Expected: clean `pub get`, commit created.

---

## Phase 1 — Core State Logic (pure, TDD)

### Task 1.1: GameConfig tuning constants

**Files:**
- Create: `lib/state/game_config.dart`
- Test: covered indirectly by later logic tests.

**Interfaces:**
- Produces:
  - `GameConfig.gameSpeed` (double)
  - `GameConfig.hungerMax` (int = 4), `GameConfig.happinessMax` (int = 4)
  - `GameConfig.msPerHungerPoint` (int), `GameConfig.msPerHappinessDrop` (int), `GameConfig.msPerPoop` (int)
  - `GameConfig.sickTimeoutMs` (int), `GameConfig.deathTimeoutMs` (int)
  - `GameConfig.stageDurationMs` (Map<LifeStage,int>), `GameConfig.careScoreThreshold` (double)

- [ ] **Step 1: Write the config**

```dart
// lib/state/game_config.dart
import 'pet.dart';

class GameConfig {
  /// Master multiplier. >1 = faster. Accelerated pace for this build.
  static const double gameSpeed = 12.0;

  static const int hungerMax = 4;
  static const int happinessMax = 4;

  // Base (real-time) rates, divided by gameSpeed to accelerate.
  static int get msPerHungerPoint => (60 * 1000 ~/ gameSpeed);   // hunger +1
  static int get msPerHappinessDrop => (90 * 1000 ~/ gameSpeed); // happiness -1
  static int get msPerPoop => (75 * 1000 ~/ gameSpeed);          // +1 poop

  // Neglect -> sick after this long at max hunger OR with poop uncleaned.
  static int get sickTimeoutMs => (120 * 1000 ~/ gameSpeed);
  // Sick + untreated OR starving this long after sick -> death.
  static int get deathTimeoutMs => (180 * 1000 ~/ gameSpeed);

  static const double careScoreThreshold = 0.6;

  static Map<LifeStage, int> get stageDurationMs => {
        LifeStage.baby1: (60 * 1000 ~/ gameSpeed).round(),
        LifeStage.baby2: (5 * 60 * 1000 ~/ gameSpeed).round(),
        LifeStage.child: (15 * 60 * 1000 ~/ gameSpeed).round(),
        LifeStage.adult: (20 * 60 * 1000 ~/ gameSpeed).round(),
      };
}
```

- [ ] **Step 2: Analyze and commit**

```powershell
flutter analyze lib/state/game_config.dart
git add -A && git commit -m "feat: add GameConfig tuning constants"
```
Expected: no errors (LifeStage resolves after Task 1.2 — if analyzed alone it will complain; run after Task 1.2 or accept the transient import error and commit together with 1.2). **Note:** implement Task 1.2 before analyzing.

### Task 1.2: Pet model + enums + JSON

**Files:**
- Create: `lib/state/pet.dart`
- Test: `test/pet_logic_test.dart` (serialization round-trip)

**Interfaces:**
- Produces:
  - `enum LifeStage { baby1, baby2, child, adult, perfectMetal, perfectSkull }`
  - `enum HealthStatus { healthy, sick }`
  - `class Pet` with fields: `LifeStage stage`, `int hunger`, `int happiness`, `int poopCount`, `HealthStatus health`, `double careScore`, `int stageStartedAtMs`, `int lastTickMs`, `int? sickSinceMs`, `int? starvingSinceMs`, `bool isDead`
  - `Pet.newborn(int nowMs)` factory (baby1, hunger 0, happiness max, healthy, careScore 0.5)
  - `Pet copyWith({...})`
  - `Map<String,dynamic> toJson()` / `Pet.fromJson(Map<String,dynamic>)`

- [ ] **Step 1: Write the model**

```dart
// lib/state/pet.dart
import 'game_config.dart';

enum LifeStage { baby1, baby2, child, adult, perfectMetal, perfectSkull }
enum HealthStatus { healthy, sick }

class Pet {
  final LifeStage stage;
  final int hunger;        // 0 = full .. hungerMax = starving
  final int happiness;     // 0 = sad .. happinessMax = happy
  final int poopCount;
  final HealthStatus health;
  final double careScore;  // 0..1, decides Metal vs Skull
  final int stageStartedAtMs;
  final int lastTickMs;
  final int? sickSinceMs;
  final int? starvingSinceMs;
  final bool isDead;

  const Pet({
    required this.stage,
    required this.hunger,
    required this.happiness,
    required this.poopCount,
    required this.health,
    required this.careScore,
    required this.stageStartedAtMs,
    required this.lastTickMs,
    this.sickSinceMs,
    this.starvingSinceMs,
    this.isDead = false,
  });

  factory Pet.newborn(int nowMs) => Pet(
        stage: LifeStage.baby1,
        hunger: 0,
        happiness: GameConfig.happinessMax,
        poopCount: 0,
        health: HealthStatus.healthy,
        careScore: 0.5,
        stageStartedAtMs: nowMs,
        lastTickMs: nowMs,
      );

  Pet copyWith({
    LifeStage? stage,
    int? hunger,
    int? happiness,
    int? poopCount,
    HealthStatus? health,
    double? careScore,
    int? stageStartedAtMs,
    int? lastTickMs,
    int? sickSinceMs,
    bool clearSickSince = false,
    int? starvingSinceMs,
    bool clearStarvingSince = false,
    bool? isDead,
  }) =>
      Pet(
        stage: stage ?? this.stage,
        hunger: hunger ?? this.hunger,
        happiness: happiness ?? this.happiness,
        poopCount: poopCount ?? this.poopCount,
        health: health ?? this.health,
        careScore: careScore ?? this.careScore,
        stageStartedAtMs: stageStartedAtMs ?? this.stageStartedAtMs,
        lastTickMs: lastTickMs ?? this.lastTickMs,
        sickSinceMs: clearSickSince ? null : (sickSinceMs ?? this.sickSinceMs),
        starvingSinceMs:
            clearStarvingSince ? null : (starvingSinceMs ?? this.starvingSinceMs),
        isDead: isDead ?? this.isDead,
      );

  Map<String, dynamic> toJson() => {
        'stage': stage.index,
        'hunger': hunger,
        'happiness': happiness,
        'poopCount': poopCount,
        'health': health.index,
        'careScore': careScore,
        'stageStartedAtMs': stageStartedAtMs,
        'lastTickMs': lastTickMs,
        'sickSinceMs': sickSinceMs,
        'starvingSinceMs': starvingSinceMs,
        'isDead': isDead,
      };

  factory Pet.fromJson(Map<String, dynamic> j) => Pet(
        stage: LifeStage.values[j['stage'] as int],
        hunger: j['hunger'] as int,
        happiness: j['happiness'] as int,
        poopCount: j['poopCount'] as int,
        health: HealthStatus.values[j['health'] as int],
        careScore: (j['careScore'] as num).toDouble(),
        stageStartedAtMs: j['stageStartedAtMs'] as int,
        lastTickMs: j['lastTickMs'] as int,
        sickSinceMs: j['sickSinceMs'] as int?,
        starvingSinceMs: j['starvingSinceMs'] as int?,
        isDead: j['isDead'] as bool,
      );
}
```

- [ ] **Step 2: Write the failing round-trip test**

```dart
// test/pet_logic_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/pet.dart';

void main() {
  test('Pet JSON round-trips', () {
    final p = Pet.newborn(1000).copyWith(hunger: 3, careScore: 0.7);
    final back = Pet.fromJson(p.toJson());
    expect(back.hunger, 3);
    expect(back.careScore, 0.7);
    expect(back.stage, LifeStage.baby1);
    expect(back.stageStartedAtMs, 1000);
  });
}
```

- [ ] **Step 3: Run test to verify it passes**

Run: `flutter test test/pet_logic_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```powershell
git add -A && git commit -m "feat: Pet model, enums, JSON round-trip"
```

### Task 1.3: applyElapsed — time-driven stat accumulation

**Files:**
- Create: `lib/state/pet_logic.dart`
- Test: `test/pet_logic_test.dart` (append)

**Interfaces:**
- Consumes: `Pet`, `GameConfig`.
- Produces: `Pet PetLogic.applyElapsed(Pet pet, int nowMs)` — advances hunger, happiness decay, poop, sickness, and starving/death timers based on `nowMs - pet.lastTickMs`; sets `lastTickMs = nowMs`. Idempotent when `nowMs == lastTickMs`.

- [ ] **Step 1: Write the failing tests**

```dart
// append to test/pet_logic_test.dart
import 'package:digimon/state/pet_logic.dart';
import 'package:digimon/state/game_config.dart';

// ... inside main():
  group('applyElapsed', () {
    test('no time passed -> unchanged stats', () {
      final p = Pet.newborn(0);
      final r = PetLogic.applyElapsed(p, 0);
      expect(r.hunger, 0);
      expect(r.lastTickMs, 0);
    });

    test('hunger rises with elapsed time and clamps at max', () {
      final p = Pet.newborn(0);
      final r = PetLogic.applyElapsed(p, GameConfig.msPerHungerPoint * 10);
      expect(r.hunger, GameConfig.hungerMax);
    });

    test('poop appears after msPerPoop', () {
      final p = Pet.newborn(0);
      final r = PetLogic.applyElapsed(p, GameConfig.msPerPoop);
      expect(r.poopCount, greaterThanOrEqualTo(1));
    });

    test('prolonged max hunger makes the pet sick', () {
      final p = Pet.newborn(0);
      final r = PetLogic.applyElapsed(
          p, GameConfig.msPerHungerPoint * GameConfig.hungerMax + GameConfig.sickTimeoutMs);
      expect(r.health, HealthStatus.sick);
    });

    test('sick and untreated past deathTimeout -> dead', () {
      final p = Pet.newborn(0);
      final r = PetLogic.applyElapsed(
          p, GameConfig.msPerHungerPoint * GameConfig.hungerMax +
              GameConfig.sickTimeoutMs + GameConfig.deathTimeoutMs);
      expect(r.isDead, true);
    });
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/pet_logic_test.dart`
Expected: FAIL ("PetLogic" undefined).

- [ ] **Step 3: Implement applyElapsed**

```dart
// lib/state/pet_logic.dart
import 'pet.dart';
import 'game_config.dart';

class PetLogic {
  static Pet applyElapsed(Pet pet, int nowMs) {
    if (pet.isDead || nowMs <= pet.lastTickMs) {
      return pet.copyWith(lastTickMs: nowMs);
    }
    final elapsed = nowMs - pet.lastTickMs;

    // Hunger rises.
    final hunger =
        (pet.hunger + elapsed ~/ GameConfig.msPerHungerPoint).clamp(0, GameConfig.hungerMax);
    // Happiness decays.
    final happiness =
        (pet.happiness - elapsed ~/ GameConfig.msPerHappinessDrop).clamp(0, GameConfig.happinessMax);
    // Poop accumulates.
    final poopCount = pet.poopCount + elapsed ~/ GameConfig.msPerPoop;

    // Track starving window.
    int? starvingSinceMs = pet.starvingSinceMs;
    if (hunger >= GameConfig.hungerMax) {
      starvingSinceMs ??= nowMs - (elapsed - GameConfig.msPerHungerPoint * GameConfig.hungerMax)
          .clamp(0, elapsed);
    } else {
      starvingSinceMs = null;
    }

    // Sickness from prolonged starving or heavy mess.
    var health = pet.health;
    int? sickSinceMs = pet.sickSinceMs;
    final starvedLongEnough = starvingSinceMs != null &&
        nowMs - starvingSinceMs >= GameConfig.sickTimeoutMs;
    final messyLongEnough = poopCount >= 3;
    if (health == HealthStatus.healthy && (starvedLongEnough || messyLongEnough)) {
      health = HealthStatus.sick;
      sickSinceMs = nowMs;
    }

    // Death from untreated sickness.
    var isDead = pet.isDead;
    if (health == HealthStatus.sick &&
        sickSinceMs != null &&
        nowMs - sickSinceMs >= GameConfig.deathTimeoutMs) {
      isDead = true;
    }

    return pet.copyWith(
      hunger: hunger,
      happiness: happiness,
      poopCount: poopCount,
      health: health,
      sickSinceMs: sickSinceMs,
      starvingSinceMs: starvingSinceMs,
      clearStarvingSince: starvingSinceMs == null,
      isDead: isDead,
      lastTickMs: nowMs,
    );
  }
}
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/pet_logic_test.dart`
Expected: PASS (all applyElapsed cases). If the "makes sick" test is off by rounding, adjust the sick trigger to `starvedLongEnough` using `hunger >= hungerMax` plus an explicit elapsed check — keep the test as the source of truth.

- [ ] **Step 5: Commit**

```powershell
git add -A && git commit -m "feat: applyElapsed time-driven stat/sickness/death logic"
```

### Task 1.4: Care actions (feed, clean, medicine, play) + careScore

**Files:**
- Modify: `lib/state/pet_logic.dart`
- Test: `test/pet_logic_test.dart` (append)

**Interfaces:**
- Produces on `PetLogic`:
  - `Pet feed(Pet)` — hunger -1 (min 0), nudges careScore up
  - `Pet clean(Pet)` — poopCount 0, nudges careScore up
  - `Pet giveMedicine(Pet)` — if sick: healthy, clears sickSinceMs, careScore up; else no-op
  - `Pet play(Pet)` — happiness +1 (max), careScore up
  - private `double _bump(double score, double delta)` clamped 0..1

- [ ] **Step 1: Write failing tests**

```dart
  group('care actions', () {
    test('feed lowers hunger and raises careScore', () {
      final p = Pet.newborn(0).copyWith(hunger: 3, careScore: 0.5);
      final r = PetLogic.feed(p);
      expect(r.hunger, 2);
      expect(r.careScore, greaterThan(0.5));
    });
    test('clean removes all poop', () {
      final p = Pet.newborn(0).copyWith(poopCount: 2);
      expect(PetLogic.clean(p).poopCount, 0);
    });
    test('medicine cures a sick pet only', () {
      final sick = Pet.newborn(0)
          .copyWith(health: HealthStatus.sick, sickSinceMs: 10);
      final cured = PetLogic.giveMedicine(sick);
      expect(cured.health, HealthStatus.healthy);
      expect(cured.sickSinceMs, isNull);
      final healthy = Pet.newborn(0);
      expect(PetLogic.giveMedicine(healthy).health, HealthStatus.healthy);
    });
    test('play raises happiness capped at max', () {
      final p = Pet.newborn(0).copyWith(happiness: GameConfig.happinessMax);
      expect(PetLogic.play(p).happiness, GameConfig.happinessMax);
    });
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/pet_logic_test.dart`
Expected: FAIL (feed/clean/... undefined).

- [ ] **Step 3: Implement the actions**

```dart
// add inside class PetLogic
  static double _bump(double s, double d) => (s + d).clamp(0.0, 1.0);

  static Pet feed(Pet p) =>
      p.copyWith(hunger: (p.hunger - 1).clamp(0, GameConfig.hungerMax),
                 careScore: _bump(p.careScore, 0.05));

  static Pet clean(Pet p) =>
      p.copyWith(poopCount: 0, careScore: _bump(p.careScore, 0.05));

  static Pet giveMedicine(Pet p) => p.health == HealthStatus.sick
      ? p.copyWith(health: HealthStatus.healthy, clearSickSince: true,
                   careScore: _bump(p.careScore, 0.1))
      : p;

  static Pet play(Pet p) =>
      p.copyWith(happiness: (p.happiness + 1).clamp(0, GameConfig.happinessMax),
                 careScore: _bump(p.careScore, 0.05));
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/pet_logic_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add -A && git commit -m "feat: care actions feed/clean/medicine/play with careScore"
```

### Task 1.5: Evolution + Metal/Skull branch

**Files:**
- Modify: `lib/state/pet_logic.dart`
- Test: `test/pet_logic_test.dart` (append)

**Interfaces:**
- Produces: `Pet PetLogic.checkEvolution(Pet pet, int nowMs)` — if `nowMs - stageStartedAtMs >= stageDurationMs[stage]`, advance one stage and reset `stageStartedAtMs = nowMs`. Order: baby1→baby2→child→adult→(perfectMetal if careScore>=threshold else perfectSkull). perfect stages don't evolve further. Applies at most one evolution per call.

- [ ] **Step 1: Write failing tests**

```dart
  group('evolution', () {
    test('baby1 evolves to baby2 after its duration', () {
      final p = Pet.newborn(0);
      final r = PetLogic.checkEvolution(p, GameConfig.stageDurationMs[LifeStage.baby1]!);
      expect(r.stage, LifeStage.baby2);
      expect(r.stageStartedAtMs, GameConfig.stageDurationMs[LifeStage.baby1]!);
    });
    test('well-cared adult -> MetalGreymon', () {
      final p = Pet.newborn(0)
          .copyWith(stage: LifeStage.adult, careScore: 0.9, stageStartedAtMs: 0);
      final r = PetLogic.checkEvolution(p, GameConfig.stageDurationMs[LifeStage.adult]!);
      expect(r.stage, LifeStage.perfectMetal);
    });
    test('neglected adult -> SkullGreymon', () {
      final p = Pet.newborn(0)
          .copyWith(stage: LifeStage.adult, careScore: 0.2, stageStartedAtMs: 0);
      final r = PetLogic.checkEvolution(p, GameConfig.stageDurationMs[LifeStage.adult]!);
      expect(r.stage, LifeStage.perfectSkull);
    });
    test('perfect stage does not evolve', () {
      final p = Pet.newborn(0).copyWith(stage: LifeStage.perfectMetal);
      final r = PetLogic.checkEvolution(p, 999999999);
      expect(r.stage, LifeStage.perfectMetal);
    });
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/pet_logic_test.dart` → FAIL (checkEvolution undefined).

- [ ] **Step 3: Implement checkEvolution**

```dart
// add inside class PetLogic
  static Pet checkEvolution(Pet p, int nowMs) {
    final dur = GameConfig.stageDurationMs[p.stage];
    if (dur == null || p.isDead) return p; // perfect stages have no duration
    if (nowMs - p.stageStartedAtMs < dur) return p;
    late LifeStage next;
    switch (p.stage) {
      case LifeStage.baby1: next = LifeStage.baby2; break;
      case LifeStage.baby2: next = LifeStage.child; break;
      case LifeStage.child: next = LifeStage.adult; break;
      case LifeStage.adult:
        next = p.careScore >= GameConfig.careScoreThreshold
            ? LifeStage.perfectMetal
            : LifeStage.perfectSkull;
        break;
      default: return p;
    }
    return p.copyWith(stage: next, stageStartedAtMs: nowMs);
  }
```

- [ ] **Step 4: Run to verify pass** → `flutter test test/pet_logic_test.dart` PASS.

- [ ] **Step 5: Commit**

```powershell
git add -A && git commit -m "feat: evolution with Metal/Skull branch on careScore"
```

### Task 1.6: PetRepository persistence (shared_preferences JSON)

**Files:**
- Create: `lib/state/pet_repository.dart`
- Test: `test/pet_repository_test.dart`

**Interfaces:**
- Produces:
  - `abstract class PetRepository { Future<Pet?> load(); Future<void> save(Pet pet); Future<void> clear(); }`
  - `class PrefsPetRepository implements PetRepository` (uses `SharedPreferences`, key `'pet_state'`, JSON-encoded)

- [ ] **Step 1: Write failing test with an in-memory prefs fake**

```dart
// test/pet_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digimon/state/pet.dart';
import 'package:digimon/state/pet_repository.dart';

void main() {
  test('save then load returns an equal pet', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsPetRepository();
    final pet = Pet.newborn(1234).copyWith(hunger: 2, careScore: 0.8);
    await repo.save(pet);
    final loaded = await repo.load();
    expect(loaded, isNotNull);
    expect(loaded!.hunger, 2);
    expect(loaded.careScore, 0.8);
    expect(loaded.stageStartedAtMs, 1234);
  });

  test('load returns null when nothing saved', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await PrefsPetRepository().load(), isNull);
  });
}
```

- [ ] **Step 2: Run to verify failure** → FAIL (PrefsPetRepository undefined).

- [ ] **Step 3: Implement the repository**

```dart
// lib/state/pet_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'pet.dart';

abstract class PetRepository {
  Future<Pet?> load();
  Future<void> save(Pet pet);
  Future<void> clear();
}

class PrefsPetRepository implements PetRepository {
  static const _key = 'pet_state';

  @override
  Future<Pet?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return Pet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(Pet pet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(pet.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
```

- [ ] **Step 4: Run to verify pass** → `flutter test test/pet_repository_test.dart` PASS.

- [ ] **Step 5: Commit**

```powershell
git add -A && git commit -m "feat: PetRepository with shared_preferences JSON persistence"
```

---

## Phase 2 — Game Rendering (Flame)

### Task 2.1: Sprite map — determine and document frame layout

**Files:**
- Create: `lib/game/sprite_map.dart`

**Interfaces:**
- Produces:
  - `String spriteSheetForStage(LifeStage stage)` → asset path (e.g. `sprites/Agumon.png`)
  - `const Map<PetAnim, int> frameIndex` where `enum PetAnim { idleA, idleB, eat, happy, angry, sad, sick, sleep, ... }`
  - frame dimensions constant `frameSize = 16` (verified: Botamon.png is 48×64 = 3×4 grid of 16px)

- [ ] **Step 1: Empirically confirm the sheet grid and frame order**

Open `assets/sprites/Agumon.png` (and Botamon) in an image viewer. Confirm 3 columns × 4 rows of 16×16 frames (48×64). Read the frames left-to-right, top-to-bottom, and note what each frame depicts (idle, walking, eating, happy, refusing, angry, sad, sick, sleeping, etc.). **Do not guess** — the community collection has a fixed order; document what you actually see.

- [ ] **Step 2: Write sprite_map.dart from the observed order**

```dart
// lib/game/sprite_map.dart
import '../state/pet.dart';

enum PetAnim { idleA, idleB, walkA, walkB, eat, happy, refuse, angry, sad, sick, sleep, extra }

const int frameSize = 16;
const int sheetCols = 3;
const int sheetRows = 4;

// NOTE: indices below reflect the observed left-to-right, top-to-bottom order
// of the community sheets. Adjust to match what Step 1 documented.
const Map<PetAnim, int> frameIndex = {
  PetAnim.idleA: 0,
  PetAnim.idleB: 1,
  PetAnim.walkA: 2,
  PetAnim.walkB: 3,
  PetAnim.eat: 4,
  PetAnim.happy: 5,
  PetAnim.refuse: 6,
  PetAnim.angry: 7,
  PetAnim.sad: 8,
  PetAnim.sick: 9,
  PetAnim.sleep: 10,
  PetAnim.extra: 11,
};

String spriteSheetForStage(LifeStage stage) {
  switch (stage) {
    case LifeStage.baby1: return 'sprites/Botamon.png';
    case LifeStage.baby2: return 'sprites/Koromon.png';
    case LifeStage.child: return 'sprites/Agumon.png';
    case LifeStage.adult: return 'sprites/Greymon.png';
    case LifeStage.perfectMetal: return 'sprites/MetalGreymon.png';
    case LifeStage.perfectSkull: return 'sprites/SkullGreymon.png';
  }
}
```

- [ ] **Step 3: Analyze and commit**

```powershell
flutter analyze lib/game/sprite_map.dart
git add -A && git commit -m "feat: sprite sheet + frame-index mapping (verified layout)"
```

### Task 2.2: PetComponent — render current stage/animation

**Files:**
- Create: `lib/game/pet_component.dart`
- Test: `test/pet_component_test.dart` (loads a sheet, asserts it builds)

**Interfaces:**
- Consumes: `sprite_map.dart`, `Pet`.
- Produces: `class PetComponent extends SpriteAnimationComponent` with `void showFor(Pet pet)` picking sheet by stage and an idle 2-frame animation; `void playOnce(PetAnim anim)` for eat/happy reactions.

- [ ] **Step 1: Write a build/smoke test**

```dart
// test/pet_component_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/cache.dart';
import 'package:digimon/game/pet_component.dart';
import 'package:digimon/state/pet.dart';

void main() {
  test('PetComponent constructs and accepts a pet', () {
    final c = PetComponent();
    // showFor should not throw for each stage (image load is async in-game;
    // here we assert the component and stage selection wiring exist).
    expect(() => c.stageOf(Pet.newborn(0)), returnsNormally);
  });
}
```

- [ ] **Step 2: Run to verify failure** → FAIL (PetComponent undefined).

- [ ] **Step 3: Implement PetComponent**

```dart
// lib/game/pet_component.dart
import 'package:flame/components.dart';
import '../state/pet.dart';
import 'sprite_map.dart';

class PetComponent extends SpriteAnimationComponent with HasGameReference {
  LifeStage? _currentStage;

  LifeStage stageOf(Pet pet) => pet.stage;

  Future<void> showFor(Pet pet) async {
    if (_currentStage == pet.stage && animation != null) return;
    _currentStage = pet.stage;
    final image = await game.images.load(spriteSheetForStage(pet.stage));
    final sheet = SpriteSheet(image: image, srcSize: Vector2.all(frameSize.toDouble()));
    // Idle = two-frame loop between idleA and idleB.
    animation = SpriteAnimation.spriteList(
      [sheet.getSpriteById(frameIndex[PetAnim.idleA]!),
       sheet.getSpriteById(frameIndex[PetAnim.idleB]!)],
      stepTime: 0.5,
    );
    size = Vector2.all(frameSize.toDouble() * 6); // scale up for phone screen
  }
}
```

- [ ] **Step 4: Run to verify pass** → `flutter test test/pet_component_test.dart` PASS.

- [ ] **Step 5: Commit**

```powershell
git add -A && git commit -m "feat: PetComponent renders stage-based idle animation"
```

### Task 2.3: VpetGame — wire logic, timer, and component

**Files:**
- Create: `lib/game/vpet_game.dart`

**Interfaces:**
- Consumes: `PetLogic`, `PetRepository`, `PetComponent`.
- Produces: `class VpetGame extends FlameGame` holding `Pet pet`; on load: `applyElapsed`→`checkEvolution` from persisted state; `update` ticks a 1s accumulator applying `applyElapsed`+`checkEvolution` and refreshing the component; exposes `feed()/clean()/medicine()/play()` that mutate `pet`, persist, and refresh; a `nowMs()` seam (defaults to `DateTime.now().millisecondsSinceEpoch`) for testability; `VoidCallback? onPetChanged` and `onDeath`.

- [ ] **Step 1: Implement VpetGame**

```dart
// lib/game/vpet_game.dart
import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import '../state/pet.dart';
import '../state/pet_logic.dart';
import '../state/pet_repository.dart';
import 'pet_component.dart';

class VpetGame extends FlameGame {
  VpetGame({required this.repo, int Function()? clock})
      : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final PetRepository repo;
  final int Function() _clock;
  final PetComponent _petComponent = PetComponent();

  late Pet pet;
  double _accum = 0;
  VoidCallback? onPetChanged;
  VoidCallback? onDeath;

  int nowMs() => _clock();

  @override
  Future<void> onLoad() async {
    final saved = await repo.load();
    pet = saved ?? Pet.newborn(nowMs());
    pet = PetLogic.checkEvolution(PetLogic.applyElapsed(pet, nowMs()), nowMs());
    await _petComponent.showFor(pet);
    _petComponent.anchor = Anchor.center;
    _petComponent.position = size / 2;
    add(_petComponent);
    await _persistAndNotify();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (pet.isDead) return;
    _accum += dt;
    if (_accum >= 1.0) {
      _accum = 0;
      pet = PetLogic.checkEvolution(PetLogic.applyElapsed(pet, nowMs()), nowMs());
      _petComponent.showFor(pet);
      _persistAndNotify();
    }
  }

  Future<void> _persistAndNotify() async {
    await repo.save(pet);
    onPetChanged?.call();
    if (pet.isDead) onDeath?.call();
  }

  Future<void> _act(Pet Function(Pet) action) async {
    pet = action(pet);
    await _petComponent.showFor(pet);
    await _persistAndNotify();
  }

  Future<void> feed() => _act(PetLogic.feed);
  Future<void> clean() => _act(PetLogic.clean);
  Future<void> medicine() => _act(PetLogic.giveMedicine);
  Future<void> play() => _act(PetLogic.play);

  Future<void> restart() async {
    pet = Pet.newborn(nowMs());
    await _petComponent.showFor(pet);
    await _persistAndNotify();
  }
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/game/vpet_game.dart`
Expected: no errors.

- [ ] **Step 3: Commit**

```powershell
git add -A && git commit -m "feat: VpetGame wires logic, resume-time recompute, 1s tick, actions"
```

### Task 2.4: HomeScreen — canvas + button row + status icons

**Files:**
- Create: `lib/ui/home_screen.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `VpetGame`, `PrefsPetRepository`.
- Produces: `HomeScreen` widget hosting `GameWidget<VpetGame>`, a bottom `Row` of 4 buttons (feed/clean/medicine/play) calling game methods, and status icons (hunger/poop/skull) shown conditionally from `game.pet`; navigates to `DeathScreen` on death.

- [ ] **Step 1: Implement HomeScreen**

```dart
// lib/ui/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/vpet_game.dart';
import '../state/pet.dart';
import '../state/pet_repository.dart';
import 'death_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final VpetGame game;

  @override
  void initState() {
    super.initState();
    game = VpetGame(repo: PrefsPetRepository())
      ..onPetChanged = () { if (mounted) setState(() {}); }
      ..onDeath = _goToDeath;
  }

  void _goToDeath() {
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DeathScreen(onRestart: () async {
        await game.restart();
        if (mounted) Navigator.of(context).pop();
      }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9BBC0F), // vpet-green LCD vibe
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  GameWidget(game: game),
                  _statusIcons(),
                ],
              ),
            ),
            _buttonRow(),
          ],
        ),
      ),
    );
  }

  Widget _statusIcons() {
    // Only rebuilds via onPetChanged setState; guard before onLoad completes.
    Pet? p;
    try { p = game.pet; } catch (_) { p = null; }
    if (p == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(children: [
        if (p.hunger >= 3) Image.asset('assets/ui/hunger.png', width: 24),
        if (p.poopCount > 0) Image.asset('assets/ui/poop.png', width: 24),
        if (p.health == HealthStatus.sick) Image.asset('assets/ui/skull.png', width: 24),
      ]),
    );
  }

  Widget _buttonRow() => Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _btn('assets/ui/food.png', game.feed),
            _btn('assets/ui/clean.png', game.clean),
            _btn('assets/ui/medicine.png', game.medicine),
            _btn('assets/ui/heart.png', game.play),
          ],
        ),
      );

  Widget _btn(String asset, Future<void> Function() onTap) => IconButton(
        iconSize: 40,
        onPressed: () => onTap(),
        icon: Image.asset(asset, width: 40, errorBuilder: (_, __, ___) =>
            const Icon(Icons.circle_outlined)),
      );
}
```

- [ ] **Step 2: Point main.dart at HomeScreen**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'ui/home_screen.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    ));
```

- [ ] **Step 3: Analyze** → `flutter analyze` expected no errors (DeathScreen resolves after Task 2.5; implement 2.5 before analyzing, or stub it now).

- [ ] **Step 4: Commit**

```powershell
git add -A && git commit -m "feat: HomeScreen with game canvas, buttons, status icons"
```

### Task 2.5: DeathScreen + restart

**Files:**
- Create: `lib/ui/death_screen.dart`

**Interfaces:**
- Consumes: nothing from game directly (callback-driven).
- Produces: `class DeathScreen extends StatelessWidget` with `final Future<void> Function() onRestart;` — shows a simple "your Digimon has passed on" message and a Restart button.

- [ ] **Step 1: Implement DeathScreen**

```dart
// lib/ui/death_screen.dart
import 'package:flutter/material.dart';

class DeathScreen extends StatelessWidget {
  const DeathScreen({super.key, required this.onRestart});
  final Future<void> Function() onRestart;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your Digimon has returned to the Digital World.',
                  style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onRestart, child: const Text('Hatch a new egg')),
            ],
          ),
        ),
      );
}
```

- [ ] **Step 2: Analyze full project** → `flutter analyze` expected "No issues found!".

- [ ] **Step 3: Commit**

```powershell
git add -A && git commit -m "feat: DeathScreen with restart-from-egg"
```

---

## Phase 3 — UI Assets

### Task 3.1: Create original pixel-art status/menu icons

**Files:**
- Create: `assets/ui/food.png`, `hunger.png`, `poop.png`, `clean.png`, `medicine.png`, `heart.png`, `skull.png`

**Interfaces:**
- Produces: seven small (32×32) pixel-art PNG icons referenced by `home_screen.dart`.

- [ ] **Step 1: Generate the icons with a small Pillow script**

Since Python + pip are available, install Pillow and draw simple, original 32×32 icons (flat pixel shapes — a meat-on-bone for food, a brown swirl for poop, a red heart, a pill, a skull, etc.). Keep them original (not Bandai's LCD glyphs).

```powershell
python -m pip install pillow
python scripts/make_icons.py   # writes the seven PNGs into assets/ui/
```

Write `scripts/make_icons.py` to draw each icon on a transparent 32×32 canvas using `PIL.ImageDraw` primitives (ellipses/rectangles/polygons) and `save()` to the exact filenames above. Verify each file opens and is 32×32 RGBA.

- [ ] **Step 2: Confirm the app finds them (no errorBuilder fallback)**

Run the app (Task 5.1 flow) and confirm real icons render, not the `Icons.circle_outlined` fallback.

- [ ] **Step 3: Commit**

```powershell
git add -A && git commit -m "feat: original pixel-art UI icons"
```

---

## Phase 4 — Notifications

### Task 4.1: Local notification on app background

**Files:**
- Create: `lib/state/notifications.dart`
- Modify: `lib/ui/home_screen.dart` (schedule on `AppLifecycleState.paused`)
- Modify: `android/app/src/main/AndroidManifest.xml` (POST_NOTIFICATIONS permission)

**Interfaces:**
- Produces: `class Notifications { Future<void> init(); Future<void> scheduleNeedsYou(); Future<void> cancelAll(); }` wrapping `flutter_local_notifications`.

- [ ] **Step 1: Implement Notifications**

```dart
// lib/state/notifications.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications {
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleNeedsYou() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails('care', 'Care reminders',
          importance: Importance.defaultImportance),
    );
    await _plugin.show(1, 'Your Digimon misses you',
        'Come back and check on it!', details);
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
```

- [ ] **Step 2: Init in main and fire on pause**

In `main()`, `await Notifications().init()` (make the instance accessible to HomeScreen, e.g. construct in HomeScreen's `initState`). Add `WidgetsBindingObserver` to `_HomeScreenState`; in `didChangeAppLifecycleState`, call `scheduleNeedsYou()` on `AppLifecycleState.paused` and `cancelAll()` on `resumed`.

- [ ] **Step 3: Add the manifest permission**

In `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

- [ ] **Step 4: Analyze + manual verify on device**

Run the app, background it, confirm a notification appears. Commit:
```powershell
git add -A && git commit -m "feat: local 'needs you' notification on background"
```

### Task 4.2: Periodic reminder via workmanager

**Files:**
- Modify: `lib/main.dart` (register `workmanager` callback)
- Create: `lib/state/background.dart`

**Interfaces:**
- Produces: a registered periodic task (min 15 min on Android) that fires the same `Notifications.scheduleNeedsYou()`. Does NOT mutate game state (spec §10).

- [ ] **Step 1: Implement the background entrypoint**

```dart
// lib/state/background.dart
import 'package:workmanager/workmanager.dart';
import 'notifications.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    final n = Notifications();
    await n.init();
    await n.scheduleNeedsYou();
    return true;
  });
}
```

- [ ] **Step 2: Register in main()**

```dart
// in main(), before runApp:
Workmanager().initialize(callbackDispatcher);
Workmanager().registerPeriodicTask('care-check', 'careCheck',
    frequency: const Duration(minutes: 15));
```
(Import `background.dart` and `package:workmanager/workmanager.dart`; wrap `main` in `WidgetsFlutterBinding.ensureInitialized()`.)

- [ ] **Step 3: Manual verify + commit**

Confirm the app still builds and launches. Note: exact timing is throttled by Doze — 15 min is the floor. Commit:
```powershell
git add -A && git commit -m "feat: periodic care reminder via workmanager"
```

---

## Phase 5 — Build & Tooling

### Task 5.1: Build and run the debug APK

**Files:** none.

- [ ] **Step 1: Start an emulator or connect a device**

```powershell
flutter devices
# if none: flutter emulators --launch <id>   (from `flutter emulators`)
```
Expected: at least one Android device listed.

- [ ] **Step 2: Run the app**

```powershell
flutter run
```
Expected: app launches; pet renders; buttons respond; leaving it running accumulates hunger/poop at the accelerated pace.

- [ ] **Step 3: Build the debug APK**

```powershell
flutter build apk --debug
```
Expected: `build\app\outputs\flutter-apk\app-debug.apk` produced (auto-signed with the debug key — no keystore needed).

- [ ] **Step 4: Run the full test suite**

```powershell
flutter test
```
Expected: all `pet_logic_test`, `pet_repository_test`, `pet_component_test` PASS.

- [ ] **Step 5: Commit**

```powershell
git add -A && git commit -m "chore: verify debug APK build and full test suite"
```

### Task 5.2: Activate graphify knowledge graph (deferred tooling)

**Files:**
- Modify: project root (`graphify-out/`, `CLAUDE.md`, `.claude/` hook) via graphify installer.

**Interfaces:**
- Produces: a queryable code graph + Claude Code PreToolUse hook.

- [ ] **Step 1: Check Dart support**

Confirm whether graphify's tree-sitter grammar set covers Dart. If not, graphify still indexes docs/config/folder structure — proceed but expect shallower Dart parsing.

- [ ] **Step 2: Build the graph**

From the project root, run graphify over the repo (per its CLI: `graphify` build / `/graphify .`). Binary at `C:\Users\felip\AppData\Roaming\Python\Python314\Scripts\graphify.exe`.

- [ ] **Step 3: Wire the Claude Code hook**

```powershell
& "C:\Users\felip\AppData\Roaming\Python\Python314\Scripts\graphify.exe" claude install --project
```
Expected: writes `.claude/skills/graphify/SKILL.md` + a CLAUDE.md directive + PreToolUse hook.

- [ ] **Step 4: Commit**

```powershell
git add -A && git commit -m "chore: activate graphify code graph + Claude Code hook"
```

---

## Self-Review Notes

- **Spec coverage:** stack (Phase 0), data model (1.2), time model (1.3), actions (1.4), evolution + Metal/Skull (1.5), death (1.3 + 2.5), persistence (1.6), sprites/animation (2.1–2.2), original UI + icons (2.4, 3.1), notifications/background (4.1–4.2), testing (throughout), build (5.1), graphify (5.2). All spec sections mapped.
- **Deviation:** persistence uses `shared_preferences` (JSON blob) instead of Hive — simpler, no codegen, same behavior; spec §2 allowed either.
- **Known verification point:** Task 2.1 frame-index order must be confirmed visually against the actual sheets before trusting the animation mapping.
