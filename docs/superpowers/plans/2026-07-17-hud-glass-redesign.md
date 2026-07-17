# HUD Glass Redesign — Implementation Plan (Plan 1: Visual Core / Beta)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the placeholder MVP HUD with the approved glass/liquid look — a biome-tinted parallax world the pet stands on, a glass action dock + status badges (now including happiness), all driven by the pet's existing life stage — with no new pub dependency.

**Architecture:** Extend the existing two-layer split. World/parallax and the pet's motion are Flame components under `lib/game/` (behind the pet). HUD chrome (dock, badges, top bar) are Flutter widgets under `lib/ui/`, composited over the `GameWidget` in `HomeScreen`'s existing `Stack`, using Flutter's built-in `BackdropFilter` for the frosted-glass effect. A pure `biomeForStage` function in `lib/state/` is the seam that maps life stage → biome; a `BiomePalette` lookup in `lib/game/` turns a biome into colors (including the HUD accent).

**Tech Stack:** Flutter + Flame 1.37 (both already in `pubspec.yaml`). No new packages in this plan — glass = `BackdropFilter`, haptics = `HapticFeedback` (built-in), world = Flame components, icons = bundled PNGs.

## Global Constraints

- `lib/state/` stays **pure Dart** — no `package:flutter` or `package:flame` imports there. (Enforced by the flutter-flame-reviewer agent and existing tests.)
- Logic functions take an explicit `int nowMs` — no `DateTime.now()`/`Random()` inside logic.
- No new native/NDK code; no dependency that reintroduces a native toolchain.
- Offline-first — no runtime network calls.
- Pet state persists as one JSON blob via `PetRepository`; **do not** add HUD/prefs fields to `Pet`.
- Icons are **Fluent Emoji 3D** (`microsoft/fluentui-emoji`, MIT) — an accepted placeholder set.
- Verify every code task with the **`/vpet-verify`** skill (analyze + test). Verify visual/world tasks additionally with **`/vpet-run`** (on-device screenshot). Review substantial changes with the **flutter-flame-reviewer** agent.
- Existing behavior (care loop, evolution, death, timing) is unchanged. `happiness` already exists on `Pet`; it only becomes *visible*.

## Out of Scope (deferred to Plan 2)

- Preferences store (`hudColorOverride`, `soundMuted`), the Settings screen, and player-locked HUD color. Plan 1 ships the **biome-derived** accent only (the default case).
- Audio (`flame_audio` + SFX assets) and the mute toggle.
- Final/commissioned icon art.

## File Structure

**Create:**
- `lib/state/biome.dart` — `Biome` enum + pure `biomeForStage(LifeStage)`.
- `lib/game/biome_palette.dart` — `BiomePalette` (colors) + `paletteForBiome(Biome)`.
- `lib/game/world_background.dart` — Flame components: sky, parallax layers, ground, marker; a `WorldBackground` that lays them out and re-tints on biome change.
- `lib/ui/hud_theme.dart` — `Color hudAccentFor(Pet)` (biome-derived accent) + shared glass constants.
- `lib/ui/widgets/glass_panel.dart` — reusable frosted-glass container.
- `lib/ui/widgets/action_dock.dart` — the 4-action glass dock.
- `lib/ui/widgets/status_badges.dart` — conditional glass status badges (hunger/mess/sick/happiness).
- `lib/ui/widgets/top_status_bar.dart` — name/stage label + accent dot + gear (gear is inert in Plan 1).
- `test/biome_test.dart`, `test/hud/glass_panel_golden_test.dart`, `test/hud/action_dock_golden_test.dart`, `test/hud/status_badges_golden_test.dart`.
- `assets/ui/fe_*.png` — Fluent Emoji icons.

**Modify:**
- `lib/state/game_config.dart` — add `happinessWarnThreshold`.
- `lib/game/pet_component.dart` — add a gentle idle "breathing" pulse.
- `lib/game/vpet_game.dart` — add the world behind the pet; re-tint on stage change; expose current biome.
- `lib/ui/home_screen.dart` — compose the new HUD widgets over the canvas.
- `pubspec.yaml` — (assets/ui/ is already declared; only touch if adding a new asset subfolder — not needed).

---

## Task 1: Biome enum + `biomeForStage` (pure logic)

**Files:**
- Create: `lib/state/biome.dart`
- Test: `test/biome_test.dart`

**Interfaces:**
- Consumes: `LifeStage` from `lib/state/pet.dart`.
- Produces: `enum Biome { nursery, meadow, jungle, savanna, chrome, wasteland }`; `Biome biomeForStage(LifeStage stage)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/biome_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/biome.dart';
import 'package:digimon/state/pet.dart';

void main() {
  test('every life stage maps to its biome', () {
    expect(biomeForStage(LifeStage.baby1), Biome.nursery);
    expect(biomeForStage(LifeStage.baby2), Biome.meadow);
    expect(biomeForStage(LifeStage.child), Biome.jungle);
    expect(biomeForStage(LifeStage.adult), Biome.savanna);
    expect(biomeForStage(LifeStage.perfectMetal), Biome.chrome);
    expect(biomeForStage(LifeStage.perfectSkull), Biome.wasteland);
  });

  test('biomeForStage is total over LifeStage (no throw for any value)', () {
    for (final s in LifeStage.values) {
      expect(() => biomeForStage(s), returnsNormally);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run (via `/vpet-verify` env): `flutter test test/biome_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'digimon' ... biome.dart` / `biomeForStage` undefined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/state/biome.dart
import 'pet.dart';

/// Ambient world theme shown behind the pet.
///
/// Currently derived 1:1 from the life stage, but modeled as its own concept
/// so a future location/movement mechanic can drive it without touching any
/// rendering code (this function is the only seam that would change).
enum Biome { nursery, meadow, jungle, savanna, chrome, wasteland }

Biome biomeForStage(LifeStage stage) {
  switch (stage) {
    case LifeStage.baby1:
      return Biome.nursery;
    case LifeStage.baby2:
      return Biome.meadow;
    case LifeStage.child:
      return Biome.jungle;
    case LifeStage.adult:
      return Biome.savanna;
    case LifeStage.perfectMetal:
      return Biome.chrome;
    case LifeStage.perfectSkull:
      return Biome.wasteland;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/biome_test.dart`
Expected: PASS (both tests).

- [ ] **Step 5: Commit**

```bash
git add lib/state/biome.dart test/biome_test.dart
git commit -m "feat: Biome enum + pure biomeForStage mapping"
```

---

## Task 2: `happinessWarnThreshold` config constant

**Files:**
- Modify: `lib/state/game_config.dart`
- Test: `test/biome_test.dart` is unrelated; add to a new `test/game_config_test.dart`

**Interfaces:**
- Produces: `GameConfig.happinessWarnThreshold` (int). Badge shows when `pet.happiness <= happinessWarnThreshold`.

- [ ] **Step 1: Write the failing test**

```dart
// test/game_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/game_config.dart';

void main() {
  test('happinessWarnThreshold is a low, in-range value', () {
    expect(GameConfig.happinessWarnThreshold, greaterThanOrEqualTo(0));
    expect(GameConfig.happinessWarnThreshold,
        lessThan(GameConfig.happinessMax));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game_config_test.dart`
Expected: FAIL — `happinessWarnThreshold` isn't defined on `GameConfig`.

- [ ] **Step 3: Add the constant**

In `lib/state/game_config.dart`, after `happinessMax`:

```dart
  static const int happinessMax = 4;

  /// Happiness at/below which the UI shows the "sad" status badge.
  static const int happinessWarnThreshold = 1;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/game_config_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/state/game_config.dart test/game_config_test.dart
git commit -m "feat: add happinessWarnThreshold for the sad-status badge"
```

---

## Task 3: Bundle the Fluent Emoji icon assets

**Files:**
- Create: `assets/ui/fe_feed.png`, `fe_clean.png`, `fe_medicine.png`, `fe_play.png`, `fe_mess.png`, `fe_sick.png`, `fe_happy_low.png`
- (No `pubspec.yaml` change — `assets/ui/` is already declared.)

**Interfaces:**
- Produces: seven asset paths under `assets/ui/` that widgets in later tasks load via `Image.asset('assets/ui/fe_*.png')`.

- [ ] **Step 1: Download the icons (3D style, MIT) from the Fluent Emoji repo**

```bash
cd "C:/Users/felip/Documents/digimon/assets/ui"
base="https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets"
curl -sL -o fe_feed.png     "$base/Meat%20on%20bone/3D/meat_on_bone_3d.png"
curl -sL -o fe_clean.png    "$base/Sparkles/3D/sparkles_3d.png"
curl -sL -o fe_medicine.png "$base/Pill/3D/pill_3d.png"
curl -sL -o fe_play.png     "$base/Red%20heart/3D/red_heart_3d.png"
curl -sL -o fe_mess.png     "$base/Pile%20of%20poo/3D/pile_of_poo_3d.png"
curl -sL -o fe_sick.png     "$base/Face%20with%20thermometer/3D/face_with_thermometer_3d.png"
curl -sL -o fe_happy_low.png "$base/Pensive%20face/3D/pensive_face_3d.png"
```

- [ ] **Step 2: Verify all seven are valid PNGs**

```bash
cd "C:/Users/felip/Documents/digimon/assets/ui"
file fe_*.png
```
Expected: each line reports `PNG image data, 256 x 256`. If `fe_happy_low.png` is 0 bytes / not a PNG, the folder name differs — list candidates with:
`gh api "repos/microsoft/fluentui-emoji/contents/assets" --jq '.[].name' | grep -iE "pensive|sad|cry|disappoint"` and re-download from the matching `<Name>/3D/<snake_name>_3d.png`.

- [ ] **Step 3: Commit**

```bash
cd "C:/Users/felip/Documents/digimon"
git add assets/ui/fe_*.png
git commit -m "assets: add Fluent Emoji 3D HUD icons (MIT)"
```

---

## Task 4: `BiomePalette` + `paletteForBiome`

**Files:**
- Create: `lib/game/biome_palette.dart`
- Test: `test/biome_palette_test.dart`

**Interfaces:**
- Consumes: `Biome` from `lib/state/biome.dart`.
- Produces: `class BiomePalette { final Color skyTop, skyBottom, far, mid, ground, accent; const BiomePalette({...}); }` and `BiomePalette paletteForBiome(Biome b)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/biome_palette_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/biome.dart';
import 'package:digimon/game/biome_palette.dart';

void main() {
  test('every biome has a palette', () {
    for (final b in Biome.values) {
      expect(() => paletteForBiome(b), returnsNormally);
    }
  });

  test('accents are distinct enough to read as different biomes', () {
    final accents = Biome.values.map((b) => paletteForBiome(b).accent.value).toSet();
    expect(accents.length, Biome.values.length); // no two biomes share an accent
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/biome_palette_test.dart`
Expected: FAIL — `biome_palette.dart` / `paletteForBiome` undefined.

- [ ] **Step 3: Write the implementation**

```dart
// lib/game/biome_palette.dart
import 'dart:ui' show Color;
import '../state/biome.dart';

/// Colors for one biome. `accent` is also the HUD's derived accent color.
/// Values are first-pass and tunable; alpha-encoded ARGB (0xAARRGGBB).
class BiomePalette {
  final Color skyTop;
  final Color skyBottom;
  final Color far; // distant hills (low-alpha over sky)
  final Color mid; // decorative blobs (low-alpha)
  final Color ground; // solid ground band
  final Color accent; // HUD accent (dots, rings, highlights)

  const BiomePalette({
    required this.skyTop,
    required this.skyBottom,
    required this.far,
    required this.mid,
    required this.ground,
    required this.accent,
  });
}

const Map<Biome, BiomePalette> _palettes = {
  Biome.nursery: BiomePalette(
    skyTop: Color(0xFF4A3B8B), skyBottom: Color(0xFFF7A8C4),
    far: Color(0x1AFFFFFF), mid: Color(0x33FFE0F0),
    ground: Color(0xFF6FC3A0), accent: Color(0xFFFF9FCE)),
  Biome.meadow: BiomePalette(
    skyTop: Color(0xFF3A2B6B), skyBottom: Color(0xFFFF8A7A),
    far: Color(0x1AFFFFFF), mid: Color(0x33FFD6A5),
    ground: Color(0xFF3FC27D), accent: Color(0xFF7BE0C9)),
  Biome.jungle: BiomePalette(
    skyTop: Color(0xFF163A2B), skyBottom: Color(0xFF57C084),
    far: Color(0x1AFFFFFF), mid: Color(0x3357C084),
    ground: Color(0xFF2A9660), accent: Color(0xFFFFC24B)),
  Biome.savanna: BiomePalette(
    skyTop: Color(0xFF6B3A16), skyBottom: Color(0xFFFFB25C),
    far: Color(0x22FFFFFF), mid: Color(0x33FFD6A5),
    ground: Color(0xFFC98A4B), accent: Color(0xFFFF7A3D)),
  Biome.chrome: BiomePalette(
    skyTop: Color(0xFF0F2027), skyBottom: Color(0xFF2C5364),
    far: Color(0x1AFFFFFF), mid: Color(0x334A6A7A),
    ground: Color(0xFF3A4A55), accent: Color(0xFF5FFBF1)),
  Biome.wasteland: BiomePalette(
    skyTop: Color(0xFF1A1420), skyBottom: Color(0xFF4A2C4A),
    far: Color(0x14FFFFFF), mid: Color(0x33553355),
    ground: Color(0xFF2A2233), accent: Color(0xFFB98CFF)),
};

BiomePalette paletteForBiome(Biome b) => _palettes[b]!;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/biome_palette_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/game/biome_palette.dart test/biome_palette_test.dart
git commit -m "feat: BiomePalette + per-biome color lookup"
```

---

## Task 5: World background components (Flame)

**Files:**
- Create: `lib/game/world_background.dart`

**Interfaces:**
- Consumes: `BiomePalette` (Task 4).
- Produces: `class WorldBackground extends PositionComponent with HasGameReference` exposing `void applyPalette(BiomePalette p)` and a fixed `double groundTopFraction` (portion of height that is ground; used by `VpetGame` to place the pet + marker). Internally: a full-screen sky (vertical gradient), two scrolling layers (far hills, mid blobs), a solid ground band, and a scrolling ground texture.

- [ ] **Step 1: Implement the components**

```dart
// lib/game/world_background.dart
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'biome_palette.dart';

/// Fraction of screen height occupied by the flat ground band (bottom).
const double groundTopFraction = 0.30;

/// A horizontally-scrolling, seamlessly-looping strip drawn from a tile painter.
/// `speed` is px/s; the world "moves" while the pet stays put.
class ScrollingLayer extends PositionComponent with HasGameReference {
  ScrollingLayer({
    required this.speed,
    required this.tileWidth,
    required this.painter,
    required super.priority,
  });

  final double speed;
  final double tileWidth;
  final void Function(ui.Canvas canvas, double dx, double h) painter;
  double _offset = 0;

  @override
  void update(double dt) {
    _offset = (_offset + speed * dt) % tileWidth;
  }

  @override
  void render(ui.Canvas canvas) {
    final w = game.size.x, h = game.size.y;
    // Draw one extra tile on each side so the wrap is seamless.
    for (double dx = -tileWidth - _offset; dx < w + tileWidth; dx += tileWidth) {
      painter(canvas, dx, h);
    }
  }
}

/// Full-screen vertical gradient sky.
class SkyComponent extends PositionComponent with HasGameReference {
  SkyComponent({required super.priority});
  ui.Color _top = const ui.Color(0xFF3A2B6B);
  ui.Color _bottom = const ui.Color(0xFFFF8A7A);
  void setColors(ui.Color top, ui.Color bottom) {
    _top = top;
    _bottom = bottom;
  }

  @override
  void render(ui.Canvas canvas) {
    final w = game.size.x, h = game.size.y;
    final rect = ui.Rect.fromLTWH(0, 0, w, h);
    final paint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(0, 0), ui.Offset(0, h), [_top, _bottom]);
    canvas.drawRect(rect, paint);
  }
}

/// Solid flat ground band anchored to the bottom `groundTopFraction` of height.
class GroundComponent extends PositionComponent with HasGameReference {
  GroundComponent({required super.priority});
  ui.Color _color = const ui.Color(0xFF3FC27D);
  void setColor(ui.Color c) => _color = c;

  @override
  void render(ui.Canvas canvas) {
    final w = game.size.x, h = game.size.y;
    final top = h * (1 - groundTopFraction);
    canvas.drawRect(
        ui.Rect.fromLTWH(0, top, w, h - top), ui.Paint()..color = _color);
    // Bright horizon line.
    canvas.drawRect(ui.Rect.fromLTWH(0, top, w, 3),
        ui.Paint()..color = const ui.Color(0x55FFFFFF));
  }
}

/// Assembles the world and re-tints it when the biome changes.
class WorldBackground extends PositionComponent with HasGameReference {
  late final SkyComponent _sky;
  late final GroundComponent _ground;
  late final ScrollingLayer _far;
  late final ScrollingLayer _mid;
  late final ScrollingLayer _groundTex;
  BiomePalette? _current;

  @override
  Future<void> onLoad() async {
    _sky = SkyComponent(priority: 0);
    _far = ScrollingLayer(
      speed: 12, tileWidth: 180, priority: 1,
      painter: (c, dx, h) {
        final base = h * (1 - groundTopFraction);
        final p = ui.Paint()..color = _current?.far ?? const ui.Color(0x1AFFFFFF);
        final path = ui.Path()
          ..moveTo(dx, base)
          ..lineTo(dx + 60, base - 46)
          ..lineTo(dx + 120, base)
          ..close();
        c.drawPath(path, p);
      },
    );
    _mid = ScrollingLayer(
      speed: 34, tileWidth: 140, priority: 2,
      painter: (c, dx, h) {
        final cy = h * (1 - groundTopFraction) - 18;
        c.drawOval(
          ui.Rect.fromCenter(center: ui.Offset(dx + 40, cy), width: 54, height: 30),
          ui.Paint()..color = _current?.mid ?? const ui.Color(0x33FFD6A5),
        );
      },
    );
    _ground = GroundComponent(priority: 3);
    _groundTex = ScrollingLayer(
      speed: 90, tileWidth: 40, priority: 4,
      painter: (c, dx, h) {
        final top = h * (1 - groundTopFraction) + 6;
        c.drawRRect(
          ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(dx, top, 10, 12), const ui.Radius.circular(3)),
          ui.Paint()..color = const ui.Color(0x14FFFFFF),
        );
      },
    );
    await addAll([_sky, _far, _mid, _ground, _groundTex]);
  }

  void applyPalette(BiomePalette p) {
    _current = p;
    _sky.setColors(p.skyTop, p.skyBottom);
    _ground.setColor(p.ground);
  }
}
```

- [ ] **Step 2: Compile check**

Run (via `/vpet-verify`): `flutter analyze`
Expected: `No issues found!` (world isn't wired into the game yet; this only type-checks the file).

- [ ] **Step 3: Commit**

```bash
git add lib/game/world_background.dart
git commit -m "feat: parallax world background (sky, hills, blobs, ground)"
```

---

## Task 6: Wire the world into VpetGame + idle pulse

**Files:**
- Modify: `lib/game/vpet_game.dart`
- Modify: `lib/game/pet_component.dart`
- Test: `test/vpet_game_test.dart` (extend — game still loads and stays consistent)

**Interfaces:**
- Consumes: `WorldBackground`, `paletteForBiome`, `biomeForStage`.
- Produces: `VpetGame.currentBiome` getter; world sits behind the pet and re-tints on stage change; the pet stands on the ground line (not screen center); `PetComponent.startIdlePulse()`.

- [ ] **Step 1: Add the idle pulse to PetComponent**

In `lib/game/pet_component.dart`, add after `reactBounce()`:

```dart
  /// Gentle continuous "breathing" — a subtle scale pulse, so the pet reads as
  /// alive while the world scrolls under it. Scale-based (not position-based)
  /// so it never fights VpetGame's centering/ground placement.
  void startIdlePulse() {
    add(
      ScaleEffect.by(
        Vector2.all(1.04),
        EffectController(
          duration: 0.9,
          reverseDuration: 0.9,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }
```

- [ ] **Step 2: Extend VpetGame to own the world**

In `lib/game/vpet_game.dart`:

Add imports:
```dart
import '../state/biome.dart';
import 'biome_palette.dart';
import 'world_background.dart';
```

Add a field next to `petComponent`:
```dart
  final WorldBackground world = WorldBackground();
```

Add a getter:
```dart
  Biome get currentBiome => biomeForStage(pet.stage);
```

Replace `onLoad`'s body so the world loads first (behind the pet), the pet is placed on the ground line, the pulse starts, and the palette is applied:

```dart
  @override
  Future<void> onLoad() async {
    final saved = await repo.load();
    pet = saved ?? Pet.newborn(nowMs());
    pet = PetLogic.checkEvolution(PetLogic.applyElapsed(pet, nowMs()), nowMs());

    world.priority = -1; // behind everything
    await add(world);
    world.applyPalette(paletteForBiome(currentBiome));

    petComponent.anchor = Anchor.bottomCenter;
    petComponent.position = _petFootPosition();
    petComponent.priority = 10;
    add(petComponent);
    await petComponent.showFor(pet);
    petComponent.startIdlePulse();

    isReady = true;
    await _persistAndNotify();
  }

  /// The pet's feet rest just above the ground horizon line.
  Vector2 _petFootPosition() =>
      Vector2(size.x / 2, size.y * (1 - groundTopFraction) + 6);
```

Update `onGameResize` to reposition the pet onto the ground line:
```dart
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (petComponent.isMounted) {
      petComponent.position = _petFootPosition();
    }
  }
```

In `update`, after evolution/apply, keep the world tint in sync (stage may have changed):
```dart
  @override
  void update(double dt) {
    super.update(dt);
    if (pet.isDead) return;
    _accum += dt;
    if (_accum >= 1.0) {
      _accum = 0;
      pet = PetLogic.checkEvolution(PetLogic.applyElapsed(pet, nowMs()), nowMs());
      world.applyPalette(paletteForBiome(currentBiome));
      petComponent.showFor(pet);
      _persistAndNotify();
    }
  }
```

Also re-tint in `restart()` (new egg → nursery) after `showFor`:
```dart
  Future<void> restart() async {
    pet = Pet.newborn(nowMs());
    world.applyPalette(paletteForBiome(currentBiome));
    await petComponent.showFor(pet);
    await _persistAndNotify();
  }
```

`backgroundColor()` can stay (fully covered by the sky) or be removed; leave it.

- [ ] **Step 3: Update the existing game test for the new placement**

`test/vpet_game_test.dart` currently asserts nothing about position, but confirm it still loads. Add:

```dart
  test('world is present and pet stands on the ground line after load', () async {
    final game = VpetGame(repo: _FakeRepo(), clock: () => 0);
    await game.onLoad();
    expect(game.world.isMounted, isTrue);
    expect(game.currentBiome, Biome.nursery); // newborn = baby1
    // Pet anchored to its feet, below vertical center (on the ground band).
    expect(game.petComponent.position.y, greaterThan(game.size.y / 2));
  });
```
(Add the needed imports `package:digimon/state/biome.dart` at the top of the test file.)

- [ ] **Step 4: Verify**

Run (via `/vpet-verify`): `flutter analyze` then `flutter test`
Expected: analyze clean; all tests pass (existing 34 + the new ones).

- [ ] **Step 5: Visual check on device**

Use the `/vpet-run` skill: launch `digimon_test`, run the app, screenshot. Confirm: gradient sky, distant hills + blobs scrolling at different speeds, a flat ground band with the pet standing on it, subtle breathing. Iterate colors/speeds/`groundTopFraction` if it reads wrong, then re-commit.

- [ ] **Step 6: Commit**

```bash
git add lib/game/vpet_game.dart lib/game/pet_component.dart test/vpet_game_test.dart
git commit -m "feat: parallax world behind pet, pet on ground line, idle pulse"
```

---

## Task 7: `GlassPanel` reusable widget

**Files:**
- Create: `lib/ui/widgets/glass_panel.dart`
- Create: `lib/ui/hud_theme.dart`
- Test: `test/hud/glass_panel_golden_test.dart`

**Interfaces:**
- Produces: `class GlassPanel extends StatelessWidget` with `{ required Widget child, EdgeInsets padding, double radius, Color? tint, Color? borderColor }`. And `lib/ui/hud_theme.dart`: `Color hudAccentFor(Pet pet)` + glass constants `kGlassBlur`, `kGlassFill`.

- [ ] **Step 1: Write `hud_theme.dart`**

```dart
// lib/ui/hud_theme.dart
import 'package:flutter/widgets.dart';
import '../state/pet.dart';
import '../state/biome.dart';
import '../game/biome_palette.dart';

/// HUD accent color, derived from the pet's current biome (Plan 1 default;
/// Plan 2 adds an optional player override).
Color hudAccentFor(Pet pet) => paletteForBiome(biomeForStage(pet.stage)).accent;

const double kGlassBlur = 10.0;
const Color kGlassFill = Color(0x24FFFFFF); // ~14% white
const Color kGlassBorder = Color(0x66FFFFFF);
```

- [ ] **Step 2: Write the golden test (fails: widget doesn't exist)**

```dart
// test/hud/glass_panel_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/ui/widgets/glass_panel.dart';

void main() {
  testWidgets('GlassPanel renders a frosted rounded container', (tester) async {
    await tester.pumpWidget(
      Container(
        color: const Color(0xFF6A3FA0),
        alignment: Alignment.center,
        child: const GlassPanel(
          child: SizedBox(width: 80, height: 40),
        ),
      ),
    );
    await expectLater(
      find.byType(GlassPanel),
      matchesGoldenFile('goldens/glass_panel.png'),
    );
  });
}
```

- [ ] **Step 3: Run to confirm it fails**

Run: `flutter test test/hud/glass_panel_golden_test.dart`
Expected: FAIL — `glass_panel.dart` / `GlassPanel` not defined.

- [ ] **Step 4: Implement `GlassPanel`**

```dart
// lib/ui/widgets/glass_panel.dart
import 'dart:ui' show ImageFilter;
import 'package:flutter/widgets.dart';
import '../hud_theme.dart';

/// A frosted-glass surface: blurred backdrop, translucent fill, light border,
/// soft shadow. The building block for every HUD element.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 20,
    this.tint,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? tint;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kGlassBlur, sigmaY: kGlassBlur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? kGlassFill,
            borderRadius: r,
            border: Border.all(color: borderColor ?? kGlassBorder, width: 1),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 4)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Generate the golden baseline and inspect it**

Run: `flutter test --update-goldens test/hud/glass_panel_golden_test.dart`
Then open `test/hud/goldens/glass_panel.png` (or `Read` it) — confirm it looks like a frosted rounded panel. Re-run without `--update-goldens` to confirm it now PASSES.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/hud_theme.dart lib/ui/widgets/glass_panel.dart test/hud/
git commit -m "feat: GlassPanel frosted-glass widget + hud accent theme"
```

---

## Task 8: Glass action dock

**Files:**
- Create: `lib/ui/widgets/action_dock.dart`
- Test: `test/hud/action_dock_golden_test.dart`

**Interfaces:**
- Consumes: `GlassPanel`, the `fe_*` icon assets, `HapticFeedback`.
- Produces: `class ActionDock extends StatelessWidget` with callbacks `onFeed/onClean/onMedicine/onPlay` and per-action `bool` enabled flags. Each tap fires `HapticFeedback.lightImpact()` then its callback. Disabled buttons dim to 35% (mirrors the MVP).

- [ ] **Step 1: Write the golden test (fails)**

```dart
// test/hud/action_dock_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/ui/widgets/action_dock.dart';

void main() {
  testWidgets('ActionDock renders four glass action buttons', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: const Color(0xFF6A3FA0),
          child: ActionDock(
            onFeed: () {}, onClean: () {}, onMedicine: () {}, onPlay: () {},
            feedEnabled: true, cleanEnabled: false,
            medicineEnabled: false, playEnabled: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ActionDock),
      matchesGoldenFile('goldens/action_dock.png'),
    );
  });

  testWidgets('disabled action does not fire its callback', (tester) async {
    var cleaned = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ActionDock(
          onFeed: () {}, onClean: () => cleaned = true,
          onMedicine: () {}, onPlay: () {},
          feedEnabled: true, cleanEnabled: false,
          medicineEnabled: false, playEnabled: true,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('dock_clean')));
    await tester.pump();
    expect(cleaned, isFalse);
  });
}
```

- [ ] **Step 2: Run to confirm it fails**

Run: `flutter test test/hud/action_dock_golden_test.dart`
Expected: FAIL — `ActionDock` not defined.

- [ ] **Step 3: Implement `ActionDock`**

```dart
// lib/ui/widgets/action_dock.dart
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter/widgets.dart';
import 'glass_panel.dart';

class ActionDock extends StatelessWidget {
  const ActionDock({
    super.key,
    required this.onFeed,
    required this.onClean,
    required this.onMedicine,
    required this.onPlay,
    required this.feedEnabled,
    required this.cleanEnabled,
    required this.medicineEnabled,
    required this.playEnabled,
  });

  final VoidCallback onFeed, onClean, onMedicine, onPlay;
  final bool feedEnabled, cleanEnabled, medicineEnabled, playEnabled;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn('dock_feed', 'assets/ui/fe_feed.png', feedEnabled, onFeed),
          _btn('dock_clean', 'assets/ui/fe_clean.png', cleanEnabled, onClean),
          _btn('dock_medicine', 'assets/ui/fe_medicine.png', medicineEnabled, onMedicine),
          _btn('dock_play', 'assets/ui/fe_play.png', playEnabled, onPlay),
        ],
      ),
    );
  }

  Widget _btn(String key, String asset, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      key: ValueKey(key),
      behavior: HitTestBehavior.opaque,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Image.asset(asset, width: 40, height: 40,
            errorBuilder: (_, __, ___) =>
                const SizedBox(width: 40, height: 40)),
      ),
    );
  }
}
```

- [ ] **Step 4: Generate golden + verify both tests pass**

Run: `flutter test --update-goldens test/hud/action_dock_golden_test.dart`
Inspect `test/hud/goldens/action_dock.png` (clean disabled → dimmed). Then run without `--update-goldens`:
`flutter test test/hud/action_dock_golden_test.dart`
Expected: PASS (both tests).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/widgets/action_dock.dart test/hud/
git commit -m "feat: glass action dock with Fluent icons + haptics"
```

---

## Task 9: Status badges (incl. happiness)

**Files:**
- Create: `lib/ui/widgets/status_badges.dart`
- Test: `test/hud/status_badges_golden_test.dart`

**Interfaces:**
- Consumes: `GlassPanel`, `Pet`, `GameConfig`, the `fe_*` status icons.
- Produces: `class StatusBadges extends StatelessWidget` taking a `Pet pet`, rendering a vertical stack of glass badges — each shown ONLY when its condition holds: hunger (`hunger >= hungerWarnThreshold`), mess (`poopCount > 0`), sick (`health == sick`), sad (`happiness <= happinessWarnThreshold`). Renders `SizedBox.shrink()` when none apply.

- [ ] **Step 1: Write the golden + logic tests (fail)**

```dart
// test/hud/status_badges_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/pet.dart';
import 'package:digimon/state/game_config.dart';
import 'package:digimon/ui/widgets/status_badges.dart';

Pet _pet({int hunger = 0, int poop = 0, HealthStatus health = HealthStatus.healthy, int happiness = GameConfig.happinessMax}) =>
    Pet.newborn(0).copyWith(hunger: hunger, poopCount: poop, health: health, happiness: happiness);

void main() {
  testWidgets('healthy well-fed pet shows no badges', (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: StatusBadges(pet: _pet()),
    ));
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('sick + starving + sad shows three badges', (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFF6A3FA0),
        child: StatusBadges(pet: _pet(
          hunger: GameConfig.hungerMax,
          health: HealthStatus.sick,
          happiness: 0,
        )),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(3));
    await expectLater(find.byType(StatusBadges),
        matchesGoldenFile('goldens/status_badges_three.png'));
  });
}
```

- [ ] **Step 2: Run to confirm it fails**

Run: `flutter test test/hud/status_badges_golden_test.dart`
Expected: FAIL — `StatusBadges` not defined.

- [ ] **Step 3: Implement `StatusBadges`**

```dart
// lib/ui/widgets/status_badges.dart
import 'package:flutter/widgets.dart';
import '../../state/pet.dart';
import '../../state/game_config.dart';
import 'glass_panel.dart';

class StatusBadges extends StatelessWidget {
  const StatusBadges({super.key, required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (pet.hunger >= GameConfig.hungerWarnThreshold)
        _badge('assets/ui/fe_feed.png', const Color(0xFFFF5C5C)),
      if (pet.poopCount > 0)
        _badge('assets/ui/fe_mess.png', const Color(0xFFC8965A)),
      if (pet.health == HealthStatus.sick)
        _badge('assets/ui/fe_sick.png', const Color(0xFFFF5C5C)),
      if (pet.happiness <= GameConfig.happinessWarnThreshold)
        _badge('assets/ui/fe_happy_low.png', const Color(0xFF6EA0FF)),
    ];
    if (badges.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final b in badges) Padding(padding: const EdgeInsets.only(bottom: 8), child: b),
      ],
    );
  }

  Widget _badge(String asset, Color ring) => GlassPanel(
        radius: 22,
        padding: const EdgeInsets.all(6),
        borderColor: ring,
        child: Image.asset(asset, width: 22, height: 22,
            errorBuilder: (_, __, ___) => const SizedBox(width: 22, height: 22)),
      );
}
```

- [ ] **Step 4: Generate golden + verify**

Run: `flutter test --update-goldens test/hud/status_badges_golden_test.dart`
Inspect `test/hud/goldens/status_badges_three.png`. Then:
`flutter test test/hud/status_badges_golden_test.dart`
Expected: PASS (both tests).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/widgets/status_badges.dart test/hud/
git commit -m "feat: conditional glass status badges incl. happiness"
```

---

## Task 10: Top status bar

**Files:**
- Create: `lib/ui/widgets/top_status_bar.dart`

**Interfaces:**
- Consumes: `GlassPanel`, `Pet`, `hudAccentFor`.
- Produces: `class TopStatusBar extends StatelessWidget` taking `Pet pet` and `VoidCallback? onSettings` (inert in Plan 1), rendering a glass bar with an accent dot, a `"<Stage> · <label>"` text, and a gear icon on the right.

- [ ] **Step 1: Implement (no golden — text rendering is font-fragile across machines; verify via /vpet-run)**

```dart
// lib/ui/widgets/top_status_bar.dart
import 'package:flutter/widgets.dart';
import '../../state/pet.dart';
import '../hud_theme.dart';
import 'glass_panel.dart';

String stageLabel(LifeStage s) {
  switch (s) {
    case LifeStage.baby1: return 'Botamon';
    case LifeStage.baby2: return 'Koromon';
    case LifeStage.child: return 'Agumon';
    case LifeStage.adult: return 'Greymon';
    case LifeStage.perfectMetal: return 'MetalGreymon';
    case LifeStage.perfectSkull: return 'SkullGreymon';
  }
}

class TopStatusBar extends StatelessWidget {
  const TopStatusBar({super.key, required this.pet, this.onSettings});
  final Pet pet;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final accent = hudAccentFor(pet);
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

- [ ] **Step 2: Compile check**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/ui/widgets/top_status_bar.dart
git commit -m "feat: glass top status bar (stage label + accent dot + gear)"
```

---

## Task 11: Compose the new HUD in HomeScreen

**Files:**
- Modify: `lib/ui/home_screen.dart`

**Interfaces:**
- Consumes: `TopStatusBar`, `StatusBadges`, `ActionDock`, and the existing `VpetGame` API (`game.feed/clean/medicine/play`, `game.pet`, `game.isReady`).
- Produces: the assembled screen — `GameWidget` full-bleed, HUD widgets in a `SafeArea` `Stack` on top.

- [ ] **Step 1: Rewrite the `build`/helpers of `_HomeScreenState`**

Replace the `build` method and the old `_statusIcons`/`_buttonRow`/`_btn` helpers in `lib/ui/home_screen.dart` with:

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1420),
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: game)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TopStatusBar(pet: _petOrNull(), onSettings: null),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.topRight,
                    child: StatusBadges(pet: _petOrNull()),
                  ),
                  const Spacer(),
                  _dock(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Pet _petOrNull() {
    // game.pet is `late`; before load, show a neutral newborn so the HUD can
    // render without throwing (mirrors the MVP's null-guard intent).
    try {
      return game.pet;
    } catch (_) {
      return Pet.newborn(0);
    }
  }

  Widget _dock() {
    final ready = game.isReady;
    final p = ready ? game.pet : null;
    return ActionDock(
      onFeed: game.feed,
      onClean: game.clean,
      onMedicine: game.medicine,
      onPlay: game.play,
      feedEnabled: p != null && p.hunger > 0,
      cleanEnabled: p != null && p.poopCount > 0,
      medicineEnabled: p != null && p.health == HealthStatus.sick,
      playEnabled: p != null,
    );
  }
```

Update the imports at the top of `home_screen.dart` — remove the now-unused `game_config.dart` import if the analyzer flags it, and add:
```dart
import 'widgets/action_dock.dart';
import 'widgets/status_badges.dart';
import 'widgets/top_status_bar.dart';
```
(Keep `game_config.dart` only if still referenced; the analyzer will tell you.)

- [ ] **Step 2: Verify (analyze + full suite)**

Run (via `/vpet-verify`): `flutter analyze` then `flutter test`
Expected: analyze clean (fix any unused-import warning); all tests pass. The existing death-screen/game tests are unaffected.

- [ ] **Step 3: Visual check on device**

Use `/vpet-run`: confirm the full composition — glass top bar with the biome accent dot, badges appearing top-right only when a stat is bad, the glass dock at the bottom with irrelevant actions dimmed, over the scrolling biome world. Neglect the pet (or fast-forward via `GameConfig.gameSpeed`) to confirm badges appear and the dock enables medicine when sick.

- [ ] **Step 4: Commit**

```bash
git add lib/ui/home_screen.dart
git commit -m "feat: compose glass HUD over the world in HomeScreen"
```

---

## Task 12: Whole-feature review + verification pass

**Files:** none (review only)

- [ ] **Step 1: Run the full gate**

Use `/vpet-verify`: `flutter analyze` (clean) + `flutter test` (all pass, including the new biome/palette/HUD tests).

- [ ] **Step 2: Adversarial review**

Dispatch the **flutter-flame-reviewer** agent over the branch diff (`git diff master...HEAD`). Confirm no Critical/Important findings — especially: `lib/state/biome.dart` imports nothing from Flutter/Flame; no HUD/pref state leaked into `Pet`; no new native deps; blur layers flagged for on-device perf were actually checked via `/vpet-run`.

- [ ] **Step 3: On-device beta smoke test**

Use `/vpet-run` on the release build (`flutter run --release -d emulator-5554`) and confirm the glass blur stays smooth (no obvious jank) through a full care loop and at least one evolution (biome + accent change). Record the result.

- [ ] **Step 4: Fix any findings, then final commit**

Address anything the review or smoke test surfaced (each fix re-verified via `/vpet-verify`), then:
```bash
git add -A
git commit -m "chore: address HUD-redesign review findings"
```

---

## Self-Review (against the spec)

- **§4.1 world/parallax (sky/far/mid/ground/marker, no new art):** Tasks 5–6. *(Note: the ground-marker ring from §4.1 is folded into the world as a fixed highlight; if a distinct dashed ring is wanted, add it as a `render` call in `GroundComponent` at `_petFootPosition().x` — flagged for the /vpet-run visual pass in Task 6 Step 5.)*
- **§4.2 biome system (pure `biomeForStage`, palette in render layer):** Tasks 1, 4. ✓
- **§4.3 HUD chrome (top bar, badges incl. happiness, dock):** Tasks 8–11. ✓
- **§4.4 HUD color — biome-derived default:** Task 7 (`hudAccentFor`) + Task 10. *Player override + Settings screen: deferred to Plan 2 (documented in Out of Scope).*
- **§4.5 happiness badge + threshold:** Tasks 2, 9. ✓
- **§6 Fluent Emoji icons bundled:** Task 3. ✓
- **§7 audio + haptics:** Haptics ✓ (Task 8). *Audio deferred to Plan 2 (needs sourced SFX).* 
- **§9 testing (biome unit tests, HUD goldens, blur on-device):** Tasks 1/4 unit, 7–9 goldens, 6/11/12 on-device. ✓
- **§10 no Rive / no native / offline:** Enforced by Global Constraints + Task 12 review. ✓

**Deferred to Plan 2 (tracked, not dropped):** preferences store, Settings screen, player-locked HUD color, `flame_audio` + SFX + mute toggle.
