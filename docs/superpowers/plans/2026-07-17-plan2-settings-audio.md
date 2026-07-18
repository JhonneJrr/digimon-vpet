# Plan 2 — Settings, Lockable HUD Color & Audio — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the visual/UX arc — a settings screen (via the top-bar gear), player-lockable HUD accent (biome-auto default + preset swatches), event-based V-Pet SFX with a mute toggle, and the gear-icon fix.

**Architecture:** Preferences (`soundMuted`, `hudColorOverride`) persist as their own JSON blob via a new `PreferencesRepository` (separate from `Pet`). Audio goes through an `AudioService` that depends on a small `SoundPlayer` interface (production impl wraps `flame_audio`; a fake is used in tests), driven by `VpetGame` on care actions + evolution/death. The settings screen (Flutter, glass-styled) edits preferences and restarts the pet; `HomeScreen` loads preferences and injects the accent override into the HUD and the mute flag into the audio.

**Tech Stack:** Flutter + Flame 1.37 (present). One new dependency: `flame_audio` (offline, bundled-asset SFX). `shared_preferences` (already present) for the new prefs blob. A Python script authors placeholder beep WAVs.

## Global Constraints

- `lib/state/` stays **pure Dart** — no `package:flutter`/`package:flame` imports. `AppPreferences` (value object) + `PreferencesRepository` (interface + `shared_preferences` impl) live there and stay pure.
- Player preferences are **not** pet state — never add `soundMuted`/`hudColorOverride` to `Pet`/`PetRepository`; they use a separate key (`app_prefs`).
- Audio must be **offline** (bundled assets only) and **testable**: `AudioService` depends on a `SoundPlayer` interface; the real `flame_audio` impl is never instantiated in unit tests.
- SFX are **per event, shared across Digimon** (eat/care/clean/medicine/evolve/death), matching the original Ver.1–6 device. Original recordings are Bandai IP (repo already private); any event without a clean original clip gets an **authored placeholder beep** (public-domain, ours).
- No new native/NDK code. Existing behavior (care loop, evolution, death-once, restart, persistence, per-stat anchors, the Plan-1 HUD) is unchanged except where a task says so.
- No pixel golden tests for icon/asset-bearing widgets (Plan-1 lesson: `Image.asset` doesn't render headless) — behavioral tests + on-device checks instead.
- Gate every task with the **`/vpet-verify`** skill (analyze + full suite). Verify audio/settings on-device with **`/vpet-run`**. Final whole-branch review with the **flutter-flame-reviewer** agent.

## File Structure

**Create:**
- `lib/state/app_preferences.dart` — `AppPreferences` value object + `PreferencesRepository` interface + `SharedPrefsPreferencesRepository`.
- `lib/game/audio_service.dart` — `SfxEvent` enum, `SoundPlayer` interface, `AudioService`.
- `lib/game/flame_audio_sound_player.dart` — `flame_audio`-backed `SoundPlayer`.
- `lib/ui/settings_screen.dart` — the settings screen + preset swatch list.
- `lib/app_version.dart` — `const String kAppVersion`.
- `scripts/make_beeps.py` — authors placeholder beep WAVs.
- `assets/audio/*.wav` — SFX (authored placeholders, some swapped for sourced originals).
- Tests: `test/app_preferences_test.dart`, `test/hud_theme_test.dart`, `test/audio_service_test.dart`, `test/hud/settings_screen_test.dart`, plus additions to `test/vpet_game_test.dart`.

**Modify:**
- `lib/ui/hud_theme.dart` — `hudAccentFor` gains an `override`.
- `lib/game/vpet_game.dart` — inject `AudioService`; play events on actions/evolution/death.
- `lib/ui/widgets/top_status_bar.dart` — real settings icon; accept an accent override.
- `lib/ui/home_screen.dart` — load prefs, build `AudioService`, wire the gear → settings, inject override + mute.
- `pubspec.yaml` — add `flame_audio`; declare `assets/audio/`; bump version to `0.2.0`.
- `PROGRESS.md` — refresh (see Task 8).

---

## Task 1: AppPreferences + PreferencesRepository

**Files:**
- Create: `lib/state/app_preferences.dart`
- Test: `test/app_preferences_test.dart`

**Interfaces:**
- Produces: `class AppPreferences { final bool soundMuted; final int? hudColorOverride; const AppPreferences({this.soundMuted = false, this.hudColorOverride}); AppPreferences copyWith({bool? soundMuted, int? hudColorOverride, bool clearOverride}); Map<String,dynamic> toJson(); factory AppPreferences.fromJson(Map<String,dynamic>); }`; `abstract class PreferencesRepository { Future<AppPreferences> load(); Future<void> save(AppPreferences prefs); }`; `class SharedPrefsPreferencesRepository implements PreferencesRepository`.

- [ ] **Step 1: Write the failing test**

```dart
// test/app_preferences_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digimon/state/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppPreferences JSON round-trips, incl. null override', () {
    const a = AppPreferences(soundMuted: true, hudColorOverride: 0xFF7BE0C9);
    expect(AppPreferences.fromJson(a.toJson()).soundMuted, isTrue);
    expect(AppPreferences.fromJson(a.toJson()).hudColorOverride, 0xFF7BE0C9);
    const b = AppPreferences();
    expect(b.soundMuted, isFalse);
    expect(AppPreferences.fromJson(b.toJson()).hudColorOverride, isNull);
  });

  test('copyWith clearOverride sets override back to null', () {
    const a = AppPreferences(hudColorOverride: 0xFFFFFFFF);
    expect(a.copyWith(clearOverride: true).hudColorOverride, isNull);
    expect(a.copyWith(soundMuted: true).hudColorOverride, 0xFFFFFFFF);
  });

  test('SharedPrefs repo persists and reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = SharedPrefsPreferencesRepository();
    expect((await repo.load()).soundMuted, isFalse); // default when unset
    await repo.save(const AppPreferences(soundMuted: true, hudColorOverride: 0xFFB98CFF));
    final loaded = await repo.load();
    expect(loaded.soundMuted, isTrue);
    expect(loaded.hudColorOverride, 0xFFB98CFF);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run (via `/vpet-verify` env): `flutter test test/app_preferences_test.dart`
Expected: FAIL — `app_preferences.dart` / `AppPreferences` undefined.

- [ ] **Step 3: Write the implementation**

```dart
// lib/state/app_preferences.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Player preferences — NOT pet state. Persisted separately from `Pet`.
class AppPreferences {
  final bool soundMuted;
  final int? hudColorOverride; // ARGB; null = follow biome (auto)

  const AppPreferences({this.soundMuted = false, this.hudColorOverride});

  AppPreferences copyWith({
    bool? soundMuted,
    int? hudColorOverride,
    bool clearOverride = false,
  }) =>
      AppPreferences(
        soundMuted: soundMuted ?? this.soundMuted,
        hudColorOverride:
            clearOverride ? null : (hudColorOverride ?? this.hudColorOverride),
      );

  Map<String, dynamic> toJson() => {
        'soundMuted': soundMuted,
        'hudColorOverride': hudColorOverride,
      };

  factory AppPreferences.fromJson(Map<String, dynamic> j) => AppPreferences(
        soundMuted: (j['soundMuted'] as bool?) ?? false,
        hudColorOverride: j['hudColorOverride'] as int?,
      );
}

abstract class PreferencesRepository {
  Future<AppPreferences> load();
  Future<void> save(AppPreferences prefs);
}

class SharedPrefsPreferencesRepository implements PreferencesRepository {
  static const _key = 'app_prefs';

  @override
  Future<AppPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const AppPreferences();
    return AppPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(AppPreferences prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(prefs.toJson()));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/app_preferences_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/state/app_preferences.dart test/app_preferences_test.dart
git commit -m "feat: AppPreferences + PreferencesRepository (separate from pet state)"
```

---

## Task 2: hudAccentFor override

**Files:**
- Modify: `lib/ui/hud_theme.dart`
- Test: `test/hud_theme_test.dart`

**Interfaces:**
- Produces: `Color hudAccentFor(Pet pet, {Color? override})` — returns `override` when non-null, else the biome accent. Existing positional call `hudAccentFor(pet)` keeps working.

- [ ] **Step 1: Write the failing test**

```dart
// test/hud_theme_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/pet.dart';
import 'package:digimon/state/biome.dart';
import 'package:digimon/game/biome_palette.dart';
import 'package:digimon/ui/hud_theme.dart';

void main() {
  test('override wins; null falls back to biome accent', () {
    final pet = Pet.newborn(0); // baby1 -> nursery
    final biomeAccent = paletteForBiome(biomeForStage(pet.stage)).accent;
    expect(hudAccentFor(pet), biomeAccent);
    expect(hudAccentFor(pet, override: const Color(0xFF123456)),
        const Color(0xFF123456));
    expect(hudAccentFor(pet, override: null), biomeAccent);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/hud_theme_test.dart`
Expected: FAIL — `hudAccentFor` doesn't accept `override:`.

- [ ] **Step 3: Edit the function**

In `lib/ui/hud_theme.dart`, replace the `hudAccentFor` line:

```dart
Color hudAccentFor(Pet pet, {Color? override}) =>
    override ?? paletteForBiome(biomeForStage(pet.stage)).accent;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/hud_theme_test.dart` then `flutter analyze`.
Expected: PASS; analyze clean (existing `hudAccentFor(pet)` call in `top_status_bar.dart` still compiles).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/hud_theme.dart test/hud_theme_test.dart
git commit -m "feat: hudAccentFor supports an optional color override"
```

---

## Task 3: SfxEvent + SoundPlayer + AudioService

**Files:**
- Create: `lib/game/audio_service.dart`
- Test: `test/audio_service_test.dart`

**Interfaces:**
- Produces: `enum SfxEvent { eat, care, clean, medicine, evolve, death, call }`; `abstract class SoundPlayer { Future<void> preload(List<String> assets); void play(String asset); }`; `class AudioService { AudioService(this.player, {this.muted = false}); final SoundPlayer player; bool muted; static String assetFor(SfxEvent e); Future<void> preloadAll(); void play(SfxEvent e); }`.

- [ ] **Step 1: Write the failing test**

```dart
// test/audio_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/game/audio_service.dart';

class _FakePlayer implements SoundPlayer {
  final played = <String>[];
  final preloaded = <String>[];
  @override
  void play(String asset) => played.add(asset);
  @override
  Future<void> preload(List<String> assets) async => preloaded.addAll(assets);
}

void main() {
  test('play routes each event to a distinct asset when not muted', () {
    final p = _FakePlayer();
    final audio = AudioService(p);
    for (final e in SfxEvent.values) {
      audio.play(e);
    }
    expect(p.played.length, SfxEvent.values.length);
    expect(p.played.toSet().length, SfxEvent.values.length); // all distinct
    expect(p.played.first, AudioService.assetFor(SfxEvent.eat));
  });

  test('muted suppresses playback', () {
    final p = _FakePlayer();
    final audio = AudioService(p, muted: true);
    audio.play(SfxEvent.evolve);
    expect(p.played, isEmpty);
    audio.muted = false;
    audio.play(SfxEvent.evolve);
    expect(p.played, [AudioService.assetFor(SfxEvent.evolve)]);
  });

  test('preloadAll preloads every event asset', () async {
    final p = _FakePlayer();
    await AudioService(p).preloadAll();
    expect(p.preloaded.toSet(),
        SfxEvent.values.map(AudioService.assetFor).toSet());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/audio_service_test.dart`
Expected: FAIL — `audio_service.dart` undefined.

- [ ] **Step 3: Write the implementation**

```dart
// lib/game/audio_service.dart

/// A care/lifecycle event that has a sound. Shared across all Digimon (the
/// original Ver.1-6 device had per-event beeps, not per-monster voices).
enum SfxEvent { eat, care, clean, medicine, evolve, death, call }

/// Abstraction over sound playback so tests can inject a fake (the real impl
/// wraps flame_audio — see flame_audio_sound_player.dart).
abstract class SoundPlayer {
  Future<void> preload(List<String> assets);
  void play(String asset);
}

/// Plays per-event SFX unless muted. Asset names are bare filenames resolved
/// under assets/audio/ by the flame_audio-backed player.
class AudioService {
  AudioService(this.player, {this.muted = false});

  final SoundPlayer player;
  bool muted;

  static String assetFor(SfxEvent e) {
    switch (e) {
      case SfxEvent.eat:
        return 'eat.wav';
      case SfxEvent.care:
        return 'care.wav';
      case SfxEvent.clean:
        return 'clean.wav';
      case SfxEvent.medicine:
        return 'medicine.wav';
      case SfxEvent.evolve:
        return 'evolve.wav';
      case SfxEvent.death:
        return 'death.wav';
      case SfxEvent.call:
        return 'call.wav';
    }
  }

  Future<void> preloadAll() =>
      player.preload(SfxEvent.values.map(assetFor).toList());

  void play(SfxEvent e) {
    if (muted) return;
    player.play(assetFor(e));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/audio_service_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/game/audio_service.dart test/audio_service_test.dart
git commit -m "feat: AudioService + SoundPlayer interface + SfxEvent (mute-gated)"
```

---

## Task 4: flame_audio player + placeholder beep assets

**Files:**
- Create: `lib/game/flame_audio_sound_player.dart`, `scripts/make_beeps.py`, `assets/audio/*.wav`
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: `SoundPlayer` (Task 3).
- Produces: `class FlameAudioSoundPlayer implements SoundPlayer` (wraps `FlameAudio`); seven WAVs `eat/care/clean/medicine/evolve/death/call.wav` under `assets/audio/`.

- [ ] **Step 1: Add the dependency + declare assets**

```bash
export PATH="/c/Users/felip/flutter/bin:$PATH"
export JAVA_HOME="C:/Program Files/Android/Android Studio/jbr"
cd "C:/Users/felip/Documents/digimon"
flutter pub add flame_audio
```
Then in `pubspec.yaml` under `flutter: assets:` add a line `- assets/audio/` (next to the existing `- assets/ui/`).

- [ ] **Step 2: Author placeholder beep WAVs (guaranteed working audio)**

Create `scripts/make_beeps.py` — generates seven short square-wave WAVs (public-domain, ours):

```python
# scripts/make_beeps.py — authors placeholder V-Pet-style beeps.
import math, struct, wave, os

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)

def square(freq, ms, vol=0.35):
    n = int(RATE * ms / 1000)
    half = max(1, int(RATE / (2 * freq)))
    frames = bytearray()
    for i in range(n):
        s = vol if (i // half) % 2 == 0 else -vol
        # simple fade-out to avoid clicks
        s *= max(0.0, 1.0 - i / n)
        frames += struct.pack("<h", int(s * 32767))
    return frames

def melody(notes):  # notes: list of (freq, ms)
    data = bytearray()
    for f, ms in notes:
        data += square(f, ms)
    return data

# each event = a short recognizable motif
MOTIFS = {
    "eat":      [(880, 60), (990, 60)],
    "care":     [(660, 60), (880, 80)],
    "clean":    [(1200, 50), (900, 50)],
    "medicine": [(700, 70), (700, 70)],
    "evolve":   [(660, 80), (880, 80), (1180, 140)],
    "death":    [(500, 120), (380, 200)],
    "call":     [(1046, 90), (1046, 90)],
}

for name, notes in MOTIFS.items():
    path = os.path.join(OUT, f"{name}.wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(melody(notes))
    print("wrote", path)
```

Run it (this machine's Python is at `/c/Python314/python`):
```bash
/c/Python314/python scripts/make_beeps.py
ls -la assets/audio/
file assets/audio/*.wav   # each: "RIFF (little-endian) data, WAVE audio"
```

- [ ] **Step 3: (Best-effort) swap in original device clips**

Attempt to source the real per-event device sounds from the Digivice soundboard
(`https://www.101soundboards.com/boards/199036-digivice-soundboard`) — download the clips that
map cleanly to eat/care/clean/medicine/evolve/death/call and replace the corresponding
`assets/audio/*.wav` (convert to WAV if needed). For any event without a clean/appropriate clip,
KEEP the authored placeholder from Step 2. Record in the task report which files are original vs
placeholder. (These are Bandai audio for personal use — repo is already private. If none can be
obtained cleanly, ship the authored placeholders; the system is swap-friendly.)

- [ ] **Step 4: Implement the flame_audio player**

```dart
// lib/game/flame_audio_sound_player.dart
import 'package:flame_audio/flame_audio.dart';
import 'audio_service.dart';

/// Real SoundPlayer: plays bundled assets under assets/audio/ via flame_audio.
class FlameAudioSoundPlayer implements SoundPlayer {
  @override
  Future<void> preload(List<String> assets) => FlameAudio.audioCache.loadAll(assets);

  @override
  void play(String asset) {
    // fire-and-forget; short SFX
    FlameAudio.play(asset);
  }
}
```

- [ ] **Step 5: Verify build (no unit test for the real player — it's the flame_audio seam)**

Run: `flutter analyze` → `No issues found!`. Then `flutter test` → the full suite still passes (nothing references the new player yet). On-device playback is verified in Task 9.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/game/flame_audio_sound_player.dart scripts/make_beeps.py assets/audio/
git commit -m "feat: flame_audio player + placeholder V-Pet beep assets"
```

---

## Task 5: Wire audio into VpetGame

**Files:**
- Modify: `lib/game/vpet_game.dart`
- Test: `test/vpet_game_test.dart`

**Interfaces:**
- Consumes: `AudioService`, `SfxEvent`.
- Produces: `VpetGame({required repo, AudioService? audio, int Function()? clock})` — audio optional; care actions + evolution + death play their event. Evolution/death fire once each per occurrence.

- [ ] **Step 1: Write the failing test**

Add to `test/vpet_game_test.dart` (import `package:digimon/game/audio_service.dart`):

```dart
class _RecordingPlayer implements SoundPlayer {
  final played = <String>[];
  @override
  void play(String asset) => played.add(asset);
  @override
  Future<void> preload(List<String> assets) async {}
}

// ... inside main():
test('care actions and lifecycle transitions play their SFX', () async {
  final p = _RecordingPlayer();
  final audio = AudioService(p);
  int now = 0;
  final game = VpetGame(repo: _FakeRepo(), audio: audio, clock: () => now);
  await game.onLoad();
  p.played.clear();

  await game.feed();
  expect(p.played, contains(AudioService.assetFor(SfxEvent.eat)));

  // Force evolution baby1 -> baby2 by advancing past its duration, then tick.
  p.played.clear();
  now += 60 * 1000; // well past accelerated baby1 duration
  game.update(1.1); // one 1s tick -> checkEvolution runs
  expect(p.played, contains(AudioService.assetFor(SfxEvent.evolve)));
});

test('muted audio plays nothing on actions', () async {
  final p = _RecordingPlayer();
  final game = VpetGame(repo: _FakeRepo(), audio: AudioService(p, muted: true), clock: () => 0);
  await game.onLoad();
  p.played.clear();
  await game.feed();
  expect(p.played, isEmpty);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/vpet_game_test.dart`
Expected: FAIL — `VpetGame` has no `audio:` parameter / no SFX played.

- [ ] **Step 3: Edit VpetGame**

In `lib/game/vpet_game.dart`:

Add import: `import 'audio_service.dart';`

Add the constructor param + field (extend the existing constructor):
```dart
  VpetGame({required this.repo, AudioService? audio, int Function()? clock})
      : _audio = audio,
        _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch) {
    images = Images(prefix: 'assets/');
  }

  final AudioService? _audio;
```
(Keep the existing `images = Images(...)` body.)

Add a transition helper:
```dart
  /// Play evolve/death SFX when [before] -> [pet] crossed those transitions.
  void _playTransitions(Pet before) {
    if (before.stage != pet.stage && !pet.isDead) {
      _audio?.play(SfxEvent.evolve);
    }
    if (!before.isDead && pet.isDead) {
      _audio?.play(SfxEvent.death);
    }
  }
```

In `update`, capture `before` and call the helper after mutation:
```dart
  @override
  void update(double dt) {
    super.update(dt);
    if (pet.isDead) return;
    _accum += dt;
    if (_accum >= 1.0) {
      _accum = 0;
      final before = pet;
      pet = PetLogic.checkEvolution(PetLogic.applyElapsed(pet, nowMs()), nowMs());
      worldBackground.applyPalette(paletteForBiome(currentBiome));
      _playTransitions(before);
      petComponent.showFor(pet);
      _persistAndNotify();
    }
  }
```
(The world field is named `worldBackground` in the current file — Plan 1 renamed it from `world` to avoid clashing with `FlameGame.world`. Match the existing name exactly; only the `_playTransitions(before)` line is new here.)

Change `_act` to take the action's SFX and play it + transitions:
```dart
  Future<void> _act(Pet Function(Pet, int) action, SfxEvent? sfx) async {
    final before = pet;
    pet = action(pet, nowMs());
    if (sfx != null) _audio?.play(sfx);
    _playTransitions(before);
    await petComponent.showFor(pet);
    petComponent.reactBounce();
    await _persistAndNotify();
  }

  Future<void> feed() => _act(PetLogic.feed, SfxEvent.eat);
  Future<void> clean() => _act(PetLogic.clean, SfxEvent.clean);
  Future<void> play() => _act(PetLogic.play, SfxEvent.care);
  Future<void> medicine() => _actMedicine();

  Future<void> _actMedicine() async {
    final before = pet;
    pet = PetLogic.giveMedicine(pet, nowMs());
    // only sound if it actually cured (giveMedicine is a no-op when not sick)
    if (before.health == HealthStatus.sick && pet.health == HealthStatus.healthy) {
      _audio?.play(SfxEvent.medicine);
    }
    _playTransitions(before);
    await petComponent.showFor(pet);
    petComponent.reactBounce();
    await _persistAndNotify();
  }
```
(`HealthStatus` is already imported via `../state/pet.dart`.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/vpet_game_test.dart` then the full suite `flutter test`.
Expected: PASS — new SFX tests green; all existing game tests still pass (the `audio:` param is optional/nullable, so tests that omit it are unaffected).

- [ ] **Step 5: Commit**

```bash
git add lib/game/vpet_game.dart test/vpet_game_test.dart
git commit -m "feat: play per-event SFX on care actions, evolution, and death"
```

---

## Task 6: Settings screen

**Files:**
- Create: `lib/ui/settings_screen.dart`
- Test: `test/hud/settings_screen_test.dart`

**Interfaces:**
- Consumes: `AppPreferences`, `PreferencesRepository`, `GlassPanel`, `BiomePalette` accents, `kAppVersion`.
- Produces: `class SettingsScreen extends StatefulWidget` with `{ required AppPreferences initial, required PreferencesRepository repo, required Future<void> Function() onRestart, required ValueChanged<AppPreferences> onChanged }`; `const List<Color> kHudSwatches`.

- [ ] **Step 1: Write the failing behavioral tests**

```dart
// test/hud/settings_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/app_preferences.dart';
import 'package:digimon/ui/settings_screen.dart';

class _FakeRepo implements PreferencesRepository {
  AppPreferences saved = const AppPreferences();
  @override
  Future<AppPreferences> load() async => saved;
  @override
  Future<void> save(AppPreferences prefs) async => saved = prefs;
}

void main() {
  Future<void> pump(WidgetTester t, {required AppPreferences initial,
      required _FakeRepo repo, AppPreferences? out, VoidCallback? onRestart}) {
    return t.pumpWidget(MaterialApp(
      home: SettingsScreen(
        initial: initial,
        repo: repo,
        onRestart: () async => onRestart?.call(),
        onChanged: (p) => out = p,
      ),
    ));
  }

  testWidgets('mute toggle flips + persists', (t) async {
    final repo = _FakeRepo();
    AppPreferences? out;
    await t.pumpWidget(MaterialApp(home: SettingsScreen(
      initial: const AppPreferences(soundMuted: false), repo: repo,
      onRestart: () async {}, onChanged: (p) => out = p)));
    await t.tap(find.byKey(const ValueKey('mute_toggle')));
    await t.pump();
    expect(out!.soundMuted, isTrue);
    expect(repo.saved.soundMuted, isTrue);
  });

  testWidgets('picking a swatch sets override; auto clears it', (t) async {
    final repo = _FakeRepo();
    AppPreferences? out;
    await t.pumpWidget(MaterialApp(home: SettingsScreen(
      initial: const AppPreferences(), repo: repo,
      onRestart: () async {}, onChanged: (p) => out = p)));
    await t.tap(find.byKey(const ValueKey('swatch_0')));
    await t.pump();
    expect(out!.hudColorOverride, kHudSwatches.first.toARGB32());
    await t.tap(find.byKey(const ValueKey('hud_auto')));
    await t.pump();
    expect(out!.hudColorOverride, isNull);
  });

  testWidgets('restart asks for confirmation then calls onRestart', (t) async {
    final repo = _FakeRepo();
    var restarted = false;
    await t.pumpWidget(MaterialApp(home: SettingsScreen(
      initial: const AppPreferences(), repo: repo,
      onRestart: () async => restarted = true, onChanged: (_) {})));
    await t.tap(find.byKey(const ValueKey('restart_button')));
    await t.pumpAndSettle();
    expect(restarted, isFalse); // dialog shown, not yet confirmed
    await t.tap(find.byKey(const ValueKey('restart_confirm')));
    await t.pumpAndSettle();
    expect(restarted, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/hud/settings_screen_test.dart`
Expected: FAIL — `settings_screen.dart` / `SettingsScreen` / `kHudSwatches` undefined.

- [ ] **Step 3: Implement the settings screen**

```dart
// lib/ui/settings_screen.dart
import 'package:flutter/material.dart';
import '../app_version.dart';
import '../game/biome_palette.dart';
import '../state/app_preferences.dart';
import '../state/biome.dart';
import 'widgets/glass_panel.dart';

/// Preset HUD accent colors: the six biome accents + two neutrals.
final List<Color> kHudSwatches = [
  ...Biome.values.map((b) => paletteForBiome(b).accent),
  const Color(0xFFFFFFFF),
  const Color(0xFFB0B0C0),
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.initial,
    required this.repo,
    required this.onRestart,
    required this.onChanged,
  });

  final AppPreferences initial;
  final PreferencesRepository repo;
  final Future<void> Function() onRestart;
  final ValueChanged<AppPreferences> onChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppPreferences _prefs = widget.initial;

  Future<void> _update(AppPreferences next) async {
    setState(() => _prefs = next);
    await widget.repo.save(next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2140),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Cor do HUD', Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                key: const ValueKey('hud_auto'),
                title: const Text('Seguir o bioma (auto)',
                    style: TextStyle(color: Colors.white)),
                value: _prefs.hudColorOverride == null,
                onChanged: (auto) =>
                    _update(_prefs.copyWith(clearOverride: auto,
                        hudColorOverride: auto ? null : kHudSwatches.first.toARGB32())),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (var i = 0; i < kHudSwatches.length; i++)
                  GestureDetector(
                    key: ValueKey('swatch_$i'),
                    onTap: () => _update(
                        _prefs.copyWith(hudColorOverride: kHudSwatches[i].toARGB32())),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: kHudSwatches[i], shape: BoxShape.circle,
                        border: Border.all(
                          color: _prefs.hudColorOverride == kHudSwatches[i].toARGB32()
                              ? Colors.white : Colors.white24,
                          width: _prefs.hudColorOverride == kHudSwatches[i].toARGB32() ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ]),
            ],
          )),
          _section('Som', SwitchListTile(
            key: const ValueKey('mute_toggle'),
            title: const Text('Mudo', style: TextStyle(color: Colors.white)),
            value: _prefs.soundMuted,
            onChanged: (m) => _update(_prefs.copyWith(soundMuted: m)),
          )),
          _section('Recomeçar', Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              key: const ValueKey('restart_button'),
              onPressed: _confirmRestart,
              child: const Text('Chocar um novo ovo'),
            ),
          )),
          _section('Créditos', const Text(
            'Ícones: Fluent Emoji (Microsoft, MIT).\n'
            'Sprites: coleção da comunidade (IP Bandai/Toei).\n'
            'Sons: aparelho Digimon V-Pet (Bandai), preservados por fãs.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          )),
          const SizedBox(height: 24),
          Center(child: Text('Digimon V-Pet · $kAppVersion',
              style: const TextStyle(color: Colors.white38, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );

  Future<void> _confirmRestart() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recomeçar?'),
        content: const Text('Isso apaga o Digimon atual e choca um novo ovo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            key: const ValueKey('restart_confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Recomeçar'),
          ),
        ],
      ),
    );
    if (ok == true) await widget.onRestart();
  }
}
```

Note: create `lib/app_version.dart` now so this compiles (its own task, Task 8, expands it):
```dart
// lib/app_version.dart
const String kAppVersion = 'v0.2.0-beta';
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/hud/settings_screen_test.dart` then `flutter analyze`.
Expected: PASS (3 tests); analyze clean.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/settings_screen.dart lib/app_version.dart test/hud/settings_screen_test.dart
git commit -m "feat: glass settings screen (HUD color swatches, mute, restart, credits, version)"
```

---

## Task 7: Wire gear → settings + HUD override + audio in HomeScreen

**Files:**
- Modify: `lib/ui/widgets/top_status_bar.dart`, `lib/ui/home_screen.dart`
- Test: `test/hud/top_status_bar_test.dart` (extend for the override)

**Interfaces:**
- `top_status_bar.dart`: real settings icon; `TopStatusBar({required Pet pet, VoidCallback? onSettings, Color? accentOverride})` — accent uses `hudAccentFor(pet, override: accentOverride)`.
- `home_screen.dart`: loads `AppPreferences`, builds `AudioService(FlameAudioSoundPlayer(), muted: prefs.soundMuted)`, injects it into `VpetGame`, passes the override to the HUD, opens `SettingsScreen` from the gear and applies changes.

- [ ] **Step 1: Fix the gear icon + add the override to TopStatusBar**

In `lib/ui/widgets/top_status_bar.dart`:
- Change the import from `package:flutter/widgets.dart` to `package:flutter/material.dart` (for `Icons`).
- Delete the bottom `const IconData _gear = IconData(0xe8b8, ...)` line.
- Use `Icons.settings` in the gear, and add the override param:

```dart
class TopStatusBar extends StatelessWidget {
  const TopStatusBar({super.key, required this.pet, this.onSettings, this.accentOverride});
  final Pet pet;
  final VoidCallback? onSettings;
  final Color? accentOverride;

  @override
  Widget build(BuildContext context) {
    final accent = hudAccentFor(pet, override: accentOverride);
    return GlassPanel(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(stageLabel(pet.stage),
              style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13)),
          const Spacer(),
          GestureDetector(
            key: const ValueKey('settings_gear'),
            onTap: onSettings,
            behavior: HitTestBehavior.opaque,
            child: const Icon(Icons.settings, size: 18, color: Color(0x99FFFFFF)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Extend the top-bar test for the override**

Add to `test/hud/top_status_bar_test.dart`:
```dart
testWidgets('accentOverride tints the accent dot', (t) async {
  await t.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: TopStatusBar(pet: Pet.newborn(0),
        accentOverride: const Color(0xFF00FF00)),
  ));
  final dot = t.widget<Container>(find.byWidgetPredicate((w) =>
      w is Container && w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).shape == BoxShape.circle).first);
  expect(((dot.decoration as BoxDecoration).color), const Color(0xFF00FF00));
});
```
Run: `flutter test test/hud/top_status_bar_test.dart` → PASS (old + new).

- [ ] **Step 3: Wire HomeScreen (prefs + audio + settings navigation)**

In `lib/ui/home_screen.dart`:

Add imports:
```dart
import '../game/audio_service.dart';
import '../game/flame_audio_sound_player.dart';
import '../state/app_preferences.dart';
import 'settings_screen.dart';
```

Add state fields + prefs/audio setup in `initState` (build `AudioService`, inject into game, load prefs async):
```dart
  late final VpetGame game;
  final Notifications _notifications = Notifications();
  final PreferencesRepository _prefsRepo = SharedPrefsPreferencesRepository();
  final AudioService _audio = AudioService(FlameAudioSoundPlayer());
  AppPreferences _prefs = const AppPreferences();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifications.init();
    game = VpetGame(repo: PrefsPetRepository(), audio: _audio)
      ..onPetChanged = () { if (mounted) setState(() {}); }
      ..onDeath = _goToDeath;
    _audio.preloadAll();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await _prefsRepo.load();
    if (!mounted) return;
    setState(() {
      _prefs = p;
      _audio.muted = p.soundMuted;
    });
  }
```

Pass the override into `TopStatusBar` in `build`:
```dart
    TopStatusBar(
      pet: _petOrNull(),
      accentOverride: _prefs.hudColorOverride == null
          ? null : Color(_prefs.hudColorOverride!),
      onSettings: _openSettings,
    ),
```

Add the settings opener:
```dart
  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsScreen(
        initial: _prefs,
        repo: _prefsRepo,
        onRestart: () async {
          await game.restart();
          if (mounted) Navigator.of(context).pop();
        },
        onChanged: (p) {
          if (!mounted) return;
          setState(() {
            _prefs = p;
            _audio.muted = p.soundMuted;
          });
        },
      ),
    ));
  }
```

- [ ] **Step 4: Verify**

Run (via `/vpet-verify`): `flutter analyze` then `flutter test`.
Expected: analyze clean; full suite passes (HomeScreen isn't unit-tested — its integration is checked on-device in Task 9; the widget-level pieces it uses are tested).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/widgets/top_status_bar.dart lib/ui/home_screen.dart test/hud/top_status_bar_test.dart
git commit -m "feat: wire settings gear, HUD color override, and audio into HomeScreen"
```

---

## Task 8: Version bump + PROGRESS.md refresh

**Files:**
- Modify: `pubspec.yaml`, `PROGRESS.md`
- (`lib/app_version.dart` already created in Task 6.)

- [ ] **Step 1: Bump the pubspec version**

In `pubspec.yaml` change `version: 1.0.0+1` to `version: 0.2.0+2`. Confirm `kAppVersion` in `lib/app_version.dart` reads `v0.2.0-beta`.

- [ ] **Step 2: Refresh PROGRESS.md**

Update `PROGRESS.md` to reflect reality: v0.1 MVP shipped (PR #1 merged), the HUD glass redesign shipped (PR #2 merged), this Plan 2 (settings/color/audio) in progress on `feat/plan2-settings-audio`, and the roadmap's next cycle = **gameplay expansion (training/battles)**. Remove the stale "PR #1 open" line and the "backlog intentionally empty" note.

- [ ] **Step 3: Verify + commit**

Run: `flutter analyze` (clean — a version change doesn't affect analysis).
```bash
git add pubspec.yaml PROGRESS.md
git commit -m "chore: bump to v0.2.0; refresh PROGRESS.md roadmap"
```

---

## Task 9: Whole-feature review + on-device verification

**Files:** none (review only)

- [ ] **Step 1: Full gate**

Use `/vpet-verify`: `flutter analyze` (clean) + `flutter test` (all pass, including the new prefs/audio/settings tests).

- [ ] **Step 2: Adversarial review**

Dispatch the **flutter-flame-reviewer** agent over `git diff master...HEAD`. Confirm: `lib/state/` stayed pure; prefs are not in `Pet`; audio is behind the `SoundPlayer` interface (real flame_audio never in unit tests); no new native deps beyond flame_audio; existing behavior intact.

- [ ] **Step 3: On-device smoke test**

Use `/vpet-run`: confirm on the emulator — SFX play on feed/clean/medicine/play and on evolution/death; the mute toggle silences them; the gear opens the settings screen; a locked swatch changes the HUD accent immediately and persists across relaunch; "auto" restores biome color; restart hatches a fresh egg. Note whether sourced-original vs placeholder beeps are in place.

- [ ] **Step 4: Fix findings, final commit**

Address anything the review or smoke test surfaced (each re-verified via `/vpet-verify`), then commit.

---

## Self-Review (against the spec)

- **§3 Audio (event-based, asset-agnostic, mute, IP note):** Tasks 3–5 (system + wiring), Task 4 (real player + assets + best-effort original sourcing + authored fallback). ✓
- **§4 Preferences store (separate from Pet):** Task 1. ✓
- **§5 Settings screen (color/mute/restart-confirm/credits/version):** Task 6; gear navigation Task 7. ✓
- **§5.1 preset swatches:** Task 6 (`kHudSwatches`). ✓
- **§6 HUD color resolution (override precedence):** Task 2 (`hudAccentFor` override) + Task 7 (HomeScreen injects it). ✓
- **§7 gear icon fix:** Task 7. ✓
- **§8 wiring (audio injected into VpetGame; HomeScreen owns prefs/audio):** Tasks 5, 7. ✓
- **§9 testing (unit + behavioral, no pixel goldens, on-device):** every task's tests + Task 9. ✓
- **§10 versioning/docs (kAppVersion, pubspec bump, PROGRESS.md):** Tasks 6, 8. ✓
- **Out of scope (music, full picker, per-Digimon cries, gameplay):** honored — none built. ✓
