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
    case Biome.nursery:
      return 'game/backgrounds/biome_nursery.png';
    case Biome.meadow:
      return 'game/backgrounds/biome_meadow.png';
    case Biome.jungle:
      return 'game/backgrounds/biome_jungle.png';
    case Biome.savanna:
      return 'game/backgrounds/biome_savanna.png';
    case Biome.chrome:
      return 'game/backgrounds/biome_chrome.png';
    case Biome.wasteland:
      return 'game/backgrounds/biome_wasteland.png';
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
