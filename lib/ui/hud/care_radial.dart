// lib/ui/hud/care_radial.dart
import 'package:flutter/material.dart';

/// Four care-action bubbles arranged in a shallow arc above the Digimon.
/// Positions are fractions of the enclosing box (the 538x300 stage), taken
/// relative to the pet anchor. Pure/presentational — no game imports.
class CareRadial extends StatelessWidget {
  const CareRadial({
    super.key,
    required this.open,
    required this.anchorX,
    required this.anchorY,
    required this.feedEnabled,
    required this.cleanEnabled,
    required this.medicineEnabled,
    required this.playEnabled,
    required this.onFeed,
    required this.onClean,
    required this.onMedicine,
    required this.onPlay,
  });

  final bool open;
  final double anchorX, anchorY;
  final bool feedEnabled, cleanEnabled, medicineEnabled, playEnabled;
  final VoidCallback onFeed, onClean, onMedicine, onPlay;

  // dx = fraction of box WIDTH, dy = fraction of box HEIGHT, from the anchor.
  // Arc: two outer-low, two inner-high (the approved "arco superior").
  static const _feedOff = Offset(-0.31, -0.24);
  static const _cleanOff = Offset(-0.12, -0.37);
  static const _medOff = Offset(0.12, -0.37);
  static const _playOff = Offset(0.31, -0.24);

  static const _feedAccent = Color(0xFFE0A24A);
  static const _cleanAccent = Color(0xFFB98CFF);
  static const _medAccent = Color(0xFFFF6B8B);
  static const _playAccent = Color(0xFF4BB4FF);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !open,
      child: AnimatedOpacity(
        opacity: open ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth, h = c.maxHeight;
          final s = w * 0.082; // bubble diameter
          Widget bubble(String key, Offset off, String asset, Color accent,
              bool enabled, VoidCallback onTap) {
            final cx = (anchorX + off.dx) * w;
            final cy = (anchorY + off.dy) * h;
            return AnimatedPositioned(
              key: ValueKey(key),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              left: cx - s / 2,
              top: (open ? cy : anchorY * h) - s / 2,
              width: s,
              height: s,
              child: Opacity(
                opacity: enabled ? 1 : 0.4,
                child: GestureDetector(
                  onTap: enabled ? onTap : null,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.alphaBlend(
                          accent.withValues(alpha: 0.20), const Color(0xCC0D1420)),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.55), width: 1),
                      boxShadow: [
                        BoxShadow(
                            color: accent.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: -2),
                      ],
                    ),
                    padding: EdgeInsets.all(s * 0.18),
                    child: Image.asset(asset,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, _, _) => const SizedBox.shrink()),
                  ),
                ),
              ),
            );
          }

          return Stack(children: [
            bubble('care_feed', _feedOff, 'assets/game/ui/care/feed.png',
                _feedAccent, feedEnabled, onFeed),
            bubble('care_clean', _cleanOff, 'assets/game/ui/care/clean.png',
                _cleanAccent, cleanEnabled, onClean),
            bubble('care_medicine', _medOff, 'assets/game/ui/care/medicine.png',
                _medAccent, medicineEnabled, onMedicine),
            bubble('care_play', _playOff, 'assets/game/ui/care/play.png',
                _playAccent, playEnabled, onPlay),
          ]);
        }),
      ),
    );
  }
}
