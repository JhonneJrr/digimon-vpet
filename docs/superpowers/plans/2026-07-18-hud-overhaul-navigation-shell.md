# HUD Overhaul + Navigation Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the procedural world with real map backgrounds in a framed scene, blend real-game UI into the glass HUD, and add a navigation shell (home + menu doors to 5 stub rooms) that opens cleanly for future combat/training.

**Architecture:** A new Flame `MapBackgroundComponent` renders the current biome's real map sprite pixel-perfect, replacing `WorldBackground`. The Flutter home screen frames the Flame `GameWidget` in a scene container with the glass HUD around it, and a `☰` menu opens a glass sheet whose doors `Navigator.push` a reusable `RoomScreen(RoomConfig)`. Stubs render a real room background + "em breve"; a `content` builder slot is where real mechanics mount later. `lib/state/` is untouched.

**Tech Stack:** Flutter 3.44 · Flame 1.37 · Dart. Assets: real PNGs copied into `assets/game/`.

## Global Constraints

- `lib/state/` stays Flutter/Flame-free (pure, unit-tested). No new logic goes there this plan.
- Pixel art must render crisp: every scaled draw uses `FilterQuality.none` / `isAntiAlias = false`.
- `flutter analyze` clean; use `.toARGB32()` never `Color.value`.
- Extracted art is IP: only the copied subset under `assets/game/` is committed (private repo).
- Env: Flutter at `C:\Users\felip\flutter\bin` (prepend PATH), `JAVA_HOME=C:\Program Files\Android\Android Studio\jbr`. Use `/vpet-verify` and `/vpet-run`.
- Biome enum values (verbatim): `nursery, meadow, jungle, savanna, chrome, wasteland`.

---

## File Structure

- Create `assets/game/backgrounds/` — 6 biome maps (`biome_<name>.png`) + 5 room bgs (`room_<name>.png`).
- Create `lib/game/map_background.dart` — `mapAssetForBiome()` + `MapBackgroundComponent`.
- Modify `lib/game/vpet_game.dart` — swap `WorldBackground` → `MapBackgroundComponent`.
- Delete `lib/game/world_background.dart` (+ its test) — procedural world retired. Keep `groundTopFraction` by moving the const into `map_background.dart`.
- Modify `lib/ui/widgets/top_status_bar.dart` — add `onMenu` + menu icon.
- Create `lib/ui/shell/room_config.dart` — `RoomConfig` + `kRooms` registry.
- Create `lib/ui/shell/room_screen.dart` — `RoomScreen` widget.
- Create `lib/ui/shell/menu_sheet.dart` — `showMenuSheet()` glass bottom sheet.
- Modify `lib/ui/home_screen.dart` — framed scene layout + wire `☰` → `showMenuSheet`.
- Modify `pubspec.yaml` — register `assets/game/backgrounds/`.

---

### Task 1: Asset pipeline

**Files:**
- Create: `assets/game/backgrounds/*.png` (copied), `tools/sprite-library/copy_app_assets.sh`
- Modify: `pubspec.yaml`

**Interfaces:**
- Produces: asset paths `assets/game/backgrounds/biome_<biome>.png` (biome ∈ the 6 enum names) and
  `assets/game/backgrounds/room_{training,battle,map,shop,evo}.png`.

- [ ] **Step 1: Write the copy script** `tools/sprite-library/copy_app_assets.sh`

```bash
#!/usr/bin/env bash
# Copies the selected real backgrounds from the organized/ library into the app's
# committed assets. Source is git-ignored (IP); only this subset ships.
set -euo pipefail
SRC="/c/Users/felip/Documents/DigitalTamers02_extracted/organized/backgrounds"
DST="/c/Users/felip/Documents/digimon/assets/game/backgrounds"
mkdir -p "$DST"
declare -A MAP=(
  [biome_nursery]=bg_AgumonHouse_0
  [biome_meadow]=bg_Btl_Dina_Plains_0
  [biome_jungle]=bg_Btl_Boot_Jungle_0
  [biome_savanna]=bg_Btl_Drive_Savanna_0
  [biome_chrome]=bg_Btl_Chrome_Mines_0
  [biome_wasteland]=bg_Btl_Magma_Mountain_0
  [room_training]=BG_TrainingRoom_0
  [room_battle]=bg_Btl_Magma_Mountain_0
  [room_map]=BG_SelectMap_0
  [room_shop]=BG_Loja_0
  [room_evo]=BG_EvoRoom_0
)
for name in "${!MAP[@]}"; do cp "$SRC/${MAP[$name]}.png" "$DST/$name.png"; done
echo "copied ${#MAP[@]} backgrounds to $DST"
ls -1 "$DST"
```

- [ ] **Step 2: Run it** — `bash tools/sprite-library/copy_app_assets.sh`
  Expected: `copied 11 backgrounds` and 11 `.png` files listed.

- [ ] **Step 3: Register the dir in `pubspec.yaml`** under `flutter: assets:` (append):

```yaml
    - assets/game/backgrounds/
```

- [ ] **Step 4: Verify** — `/vpet-verify` (flutter pub get + analyze). Expected: no asset errors.

- [ ] **Step 5: Commit**

```bash
git add assets/game/backgrounds/ pubspec.yaml tools/sprite-library/copy_app_assets.sh
git commit -m "feat(assets): ship real map/room backgrounds for the overhaul"
```

---

### Task 2: MapBackgroundComponent + biome→map mapping

**Files:**
- Create: `lib/game/map_background.dart`
- Test: `test/map_background_test.dart`

**Interfaces:**
- Consumes: `Biome` from `lib/state/biome.dart`; the Task 1 asset paths.
- Produces: `String mapAssetForBiome(Biome)`; `const double groundTopFraction`;
  `class MapBackgroundComponent` with `Future<void> applyBiome(Biome)`.

- [ ] **Step 1: Write the failing test** `test/map_background_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/game/map_background.dart';
import 'package:digimon/state/biome.dart';

void main() {
  test('every biome maps to a game/backgrounds asset', () {
    for (final b in Biome.values) {
      final a = mapAssetForBiome(b);
      expect(a, startsWith('game/backgrounds/biome_'));
      expect(a, endsWith('.png'));
    }
  });
  test('mapping is distinct per biome', () {
    final all = Biome.values.map(mapAssetForBiome).toSet();
    expect(all.length, Biome.values.length);
  });
}
```

- [ ] **Step 2: Run it, expect fail** — `flutter test test/map_background_test.dart`
  Expected: FAIL (map_background.dart / mapAssetForBiome missing).

- [ ] **Step 3: Implement** `lib/game/map_background.dart`

```dart
// lib/game/map_background.dart
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import '../state/biome.dart';

/// Fraction of screen height where the pet's feet rest (kept from the old world).
const double groundTopFraction = 0.30;

/// The real map sprite shown behind the pet for a given biome. Paths are
/// relative to the game's `Images(prefix: 'assets/')` cache.
String mapAssetForBiome(Biome b) {
  switch (b) {
    case Biome.nursery:   return 'game/backgrounds/biome_nursery.png';
    case Biome.meadow:    return 'game/backgrounds/biome_meadow.png';
    case Biome.jungle:    return 'game/backgrounds/biome_jungle.png';
    case Biome.savanna:   return 'game/backgrounds/biome_savanna.png';
    case Biome.chrome:    return 'game/backgrounds/biome_chrome.png';
    case Biome.wasteland: return 'game/backgrounds/biome_wasteland.png';
  }
}

/// Draws the current biome's map, cover-fit and pixel-perfect, behind the pet.
class MapBackgroundComponent extends PositionComponent with HasGameReference {
  Sprite? _sprite;
  Biome? _biome;
  final ui.Paint _paint = ui.Paint()
    ..filterQuality = ui.FilterQuality.none
    ..isAntiAlias = false;

  /// Loads the map for [b] if it changed. Cheap no-op when already current.
  Future<void> applyBiome(Biome b) async {
    if (b == _biome && _sprite != null) return;
    _biome = b;
    _sprite = Sprite(await game.images.load(mapAssetForBiome(b)));
  }

  @override
  void render(ui.Canvas canvas) {
    final s = _sprite;
    if (s == null) return;
    final vw = game.size.x, vh = game.size.y;
    final sw = s.srcSize.x, sh = s.srcSize.y;
    final k = (vw / sw) > (vh / sh) ? (vw / sw) : (vh / sh); // cover = max ratio
    final w = sw * k, h = sh * k;
    s.render(canvas,
        position: Vector2((vw - w) / 2, (vh - h) / 2),
        size: Vector2(w, h),
        overridePaint: _paint);
  }
}
```

- [ ] **Step 4: Run tests, expect pass** — `flutter test test/map_background_test.dart` → PASS.

- [ ] **Step 5: Commit** — `git add lib/game/map_background.dart test/map_background_test.dart && git commit -m "feat(game): MapBackgroundComponent + biome->map mapping"`

---

### Task 3: Wire MapBackground into VpetGame; retire WorldBackground

**Files:**
- Modify: `lib/game/vpet_game.dart`
- Delete: `lib/game/world_background.dart`, `test/world_background_test.dart` (if present)
- Test: existing `test/vpet_game_test.dart` (must stay green)

**Interfaces:**
- Consumes: `MapBackgroundComponent`, `mapAssetForBiome`, `groundTopFraction` from Task 2.

- [ ] **Step 1: Check for a world_background test** — `ls test/*world_background* 2>/dev/null` — delete any found.

- [ ] **Step 2: Edit `vpet_game.dart`** — replace the import and field, and the three call sites.

Replace `import 'world_background.dart';` with `import 'map_background.dart';`.
Replace the `worldBackground` field:

```dart
  final MapBackgroundComponent mapBackground = MapBackgroundComponent();
```

In `onLoad`, replace the three `worldBackground` lines:

```dart
    mapBackground.priority = -1; // behind everything
    await add(mapBackground);
    await mapBackground.applyBiome(currentBiome);
```

In `update`, replace `worldBackground.applyPalette(paletteForBiome(currentBiome));` with:

```dart
      mapBackground.applyBiome(currentBiome); // fire-and-forget; no-op unless biome changed
```

In `restart`, replace `worldBackground.applyPalette(paletteForBiome(currentBiome));` with:

```dart
    await mapBackground.applyBiome(currentBiome);
```

Remove the now-unused `import 'biome_palette.dart';` **only if** nothing else in the file uses it
(it doesn't after this change).

- [ ] **Step 3: Delete** `lib/game/world_background.dart`.

- [ ] **Step 4: Run the game tests** — `flutter test test/vpet_game_test.dart test/pet_component_test.dart`
  Expected: PASS. If a test referenced `worldBackground`, update it to `mapBackground` / remove the
  palette assertion.

- [ ] **Step 5: Full verify + commit** — `/vpet-verify`; then
  `git add -A lib/game test && git commit -m "feat(game): render real biome maps, retire procedural world"`

---

### Task 4: Hybrid HUD — menu button in the top bar

**Files:**
- Modify: `lib/ui/widgets/top_status_bar.dart`
- Test: `test/hud/top_status_bar_test.dart`

**Interfaces:**
- Produces: `TopStatusBar(... , VoidCallback? onMenu)` with a tappable menu icon keyed
  `ValueKey('hud_menu')`.

- [ ] **Step 1: Add a failing test** to `test/hud/top_status_bar_test.dart`

```dart
testWidgets('tapping the menu icon fires onMenu', (t) async {
  var tapped = false;
  await t.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: TopStatusBar(
        label: 'Botamon', accent: const Color(0xFFFFFFFF),
        onMenu: () => tapped = true),
  ));
  await t.tap(find.byKey(const ValueKey('hud_menu')));
  expect(tapped, isTrue);
});
```

- [ ] **Step 2: Run, expect fail** — `flutter test test/hud/top_status_bar_test.dart` (no `onMenu` param).

- [ ] **Step 3: Edit `top_status_bar.dart`** — add the field + a leading menu button.

Add to the constructor/fields: `this.onMenu` and `final VoidCallback? onMenu;`. Insert before the
`Spacer()` (or as the trailing action, replacing the gear when settings is null) a menu icon:

```dart
          GestureDetector(
            key: const ValueKey('hud_menu'),
            onTap: onMenu,
            behavior: HitTestBehavior.opaque,
            child: const Icon(_menu, size: 20, color: Color(0xCCFFFFFF)),
          ),
          if (onSettings != null) const SizedBox(width: 12),
```

Add the glyph: `const IconData _menu = IconData(0xe5d2, fontFamily: 'MaterialIcons'); // hamburger`.

- [ ] **Step 4: Run, expect pass** — `flutter test test/hud/top_status_bar_test.dart` → PASS.

- [ ] **Step 5: Commit** — `git add lib/ui/widgets/top_status_bar.dart test/hud/top_status_bar_test.dart && git commit -m "feat(hud): add menu button to top status bar"`

---

### Task 5: RoomConfig + RoomScreen (stub rooms)

**Files:**
- Create: `lib/ui/shell/room_config.dart`, `lib/ui/shell/room_screen.dart`
- Test: `test/shell/room_screen_test.dart`

**Interfaces:**
- Produces: `class RoomConfig {String title; String backgroundAsset; bool comingSoon; WidgetBuilder? content;}`,
  `const List<RoomConfig> kRooms`, `class RoomScreen extends StatelessWidget { final RoomConfig config; }`.

- [ ] **Step 1: Write the failing test** `test/shell/room_screen_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/ui/shell/room_config.dart';
import 'package:digimon/ui/shell/room_screen.dart';

void main() {
  testWidgets('stub room shows title, "em breve", and a working back button',
      (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(builder: (c) => Scaffold(
        body: Center(child: ElevatedButton(
          onPressed: () => Navigator.of(c).push(MaterialPageRoute(
            builder: (_) => const RoomScreen(config: RoomConfig(
              title: 'Treino',
              backgroundAsset: 'assets/game/backgrounds/room_training.png')))),
          child: const Text('go'))),
      )),
    ));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.text('Treino'), findsOneWidget);
    expect(find.text('em breve'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('room_back')));
    await t.pumpAndSettle();
    expect(find.text('Treino'), findsNothing);
  });
}
```

- [ ] **Step 2: Run, expect fail** — `flutter test test/shell/room_screen_test.dart`.

- [ ] **Step 3: Implement** `lib/ui/shell/room_config.dart`

```dart
// lib/ui/shell/room_config.dart
import 'package:flutter/widgets.dart';

/// One navigable room. Stubs set [comingSoon]; real screens pass [content].
class RoomConfig {
  const RoomConfig({
    required this.title,
    required this.backgroundAsset,
    this.comingSoon = true,
    this.content,
  });
  final String title;
  final String backgroundAsset;
  final bool comingSoon;
  final WidgetBuilder? content;
}

/// The doors shown in the menu. Order = display order.
const List<RoomConfig> kRooms = [
  RoomConfig(title: 'Treino',     backgroundAsset: 'assets/game/backgrounds/room_training.png'),
  RoomConfig(title: 'Batalha',    backgroundAsset: 'assets/game/backgrounds/room_battle.png'),
  RoomConfig(title: 'Mapa',       backgroundAsset: 'assets/game/backgrounds/room_map.png'),
  RoomConfig(title: 'Loja',       backgroundAsset: 'assets/game/backgrounds/room_shop.png'),
  RoomConfig(title: 'Evo / Bios', backgroundAsset: 'assets/game/backgrounds/room_evo.png'),
];
```

- [ ] **Step 4: Implement** `lib/ui/shell/room_screen.dart`

```dart
// lib/ui/shell/room_screen.dart
import 'package:flutter/material.dart';
import 'room_config.dart';

/// A room reached from the menu. Renders the real background pixel-perfect; a
/// stub overlays a "em breve" state, a real screen renders [config.content].
class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key, required this.config});
  final RoomConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B17),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(config.backgroundAsset,
              fit: BoxFit.cover, filterQuality: FilterQuality.none),
          Container(
              color: config.comingSoon ? const Color(0x99080610) : null),
          if (!config.comingSoon && config.content != null)
            config.content!(context),
          if (config.comingSoon)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(config.title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFF9D42),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('em breve',
                        style: TextStyle(
                            color: Color(0xFF0D0B17), fontWeight: FontWeight.w700,
                            letterSpacing: 2)),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: const Color(0x66000000),
                  shape: const CircleBorder(),
                  child: IconButton(
                    key: const ValueKey('room_back'),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run, expect pass; commit** — `flutter test test/shell/room_screen_test.dart` → PASS;
  `git add lib/ui/shell test/shell && git commit -m "feat(shell): reusable RoomScreen + room registry"`

---

### Task 6: MenuSheet + wire the home screen

**Files:**
- Create: `lib/ui/shell/menu_sheet.dart`
- Modify: `lib/ui/home_screen.dart`
- Test: `test/shell/menu_sheet_test.dart`

**Interfaces:**
- Consumes: `kRooms`, `RoomScreen`, `RoomConfig` (Task 5); `TopStatusBar.onMenu` (Task 4).
- Produces: `Future<void> showMenuSheet(BuildContext)`.

- [ ] **Step 1: Write the failing test** `test/shell/menu_sheet_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/ui/shell/menu_sheet.dart';

void main() {
  testWidgets('menu lists doors and a door opens its room', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(builder: (c) => Scaffold(
        body: Center(child: ElevatedButton(
          onPressed: () => showMenuSheet(c), child: const Text('menu'))),
      )),
    ));
    await t.tap(find.text('menu'));
    await t.pumpAndSettle();
    expect(find.text('Treino'), findsOneWidget);
    expect(find.text('Batalha'), findsOneWidget);
    await t.tap(find.text('Treino'));
    await t.pumpAndSettle();
    expect(find.text('em breve'), findsOneWidget); // pushed the stub room
  });
}
```

- [ ] **Step 2: Run, expect fail** — `flutter test test/shell/menu_sheet_test.dart`.

- [ ] **Step 3: Implement** `lib/ui/shell/menu_sheet.dart`

```dart
// lib/ui/shell/menu_sheet.dart
import 'package:flutter/material.dart';
import 'room_config.dart';
import 'room_screen.dart';

/// A glass bottom sheet of doors. Tapping one closes the sheet and pushes its
/// [RoomScreen]. This is the navigation seam for future mechanics.
Future<void> showMenuSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xE6161226),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10, top: 2),
            child: Text('IR PARA',
                style: TextStyle(
                    color: Color(0x99FFFFFF), fontSize: 11, letterSpacing: 3,
                    fontWeight: FontWeight.w700)),
          ),
          for (final room in kRooms)
            ListTile(
              title: Text(room.title,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              trailing: const Icon(Icons.chevron_right, color: Color(0x99FFFFFF)),
              onTap: () {
                Navigator.of(sheetCtx).pop(); // close sheet
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RoomScreen(config: room)));
              },
            ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 4: Wire the home screen** — in `lib/ui/home_screen.dart`:
  - Add `import 'shell/menu_sheet.dart';`.
  - In both `_topBar()` return sites, pass `onMenu: () => showMenuSheet(context)`.
  - (Optional, matches the mockup) frame the game: wrap the `GameWidget` in a `ClipRRect`
    inside the column instead of `Positioned.fill` — keep this minimal if time-boxed; the menu
    wiring is the required deliverable.

Concretely, change `_topBar()`'s two `TopStatusBar(...)` calls to include `onMenu: () => showMenuSheet(context)`.

- [ ] **Step 5: Run, expect pass** — `flutter test test/shell/menu_sheet_test.dart` → PASS.

- [ ] **Step 6: Full verify + commit** — `/vpet-verify` (all tests + analyze);
  `git add -A lib/ui test/shell && git commit -m "feat(shell): menu sheet + wire home screen doors"`

---

### Task 7: On-device smoke

**Files:** none (verification).

- [ ] **Step 1:** Run `/vpet-run` — launch on the `digimon_test` AVD, screenshot the home screen.
- [ ] **Step 2:** Confirm visually: real map behind the pet (crisp pixels, not blurry), glass HUD
  legible over it, `☰` opens the menu, a door opens its stub room with the real background + "em
  breve", back returns home.
- [ ] **Step 3:** If rendering is blurry, verify `FilterQuality.none` on both the Flame paint
  (Task 2) and the `Image.asset` (Task 5). Re-run.

---

## Self-Review

- **Spec coverage:** framed real-map scene → Tasks 2,3 (+6 optional framing); hybrid HUD → Task 4;
  navigation shell (AppShell/menu/RoomScreen/stubs) → Tasks 5,6 (Navigator used directly instead of
  a separate `AppShell` class — YAGNI, noted); asset pipeline → Task 1; extensibility (`content`
  slot) → Task 5 `RoomConfig.content`; state untouched → no `lib/state/` edits; testing → per-task
  widget/unit tests + Task 7 on-device. All covered.
- **Placeholders:** none — every code step is complete.
- **Type consistency:** `mapAssetForBiome`, `MapBackgroundComponent.applyBiome`, `groundTopFraction`,
  `RoomConfig{title,backgroundAsset,comingSoon,content}`, `kRooms`, `RoomScreen(config:)`,
  `showMenuSheet(context)`, `TopStatusBar(onMenu:)` are used consistently across tasks.
