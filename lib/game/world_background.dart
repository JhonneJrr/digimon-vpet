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
