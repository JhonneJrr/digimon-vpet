// lib/ui/hud/care_indicators.dart
import 'package:flutter/material.dart';

/// Reborn-2-style need pop-ups that float just above the Digimon's head: a small
/// row of icons, one per active need (hunger / mess / sick / unhappy), gently
/// bobbing. Positioned by fractions of the 538x300 stage relative to the pet
/// anchor. Pure/presentational (no game imports); non-interactive.
class CareIndicators extends StatefulWidget {
  const CareIndicators({
    super.key,
    required this.anchorX,
    required this.headY,
    required this.hungry,
    required this.messy,
    required this.sick,
    required this.unhappy,
  });

  /// Pet centre x, fraction of box width [0,1].
  final double anchorX;

  /// Top of the pet's head, fraction of box height [0,1] (icons sit above it).
  final double headY;
  final bool hungry, messy, sick, unhappy;

  @override
  State<CareIndicators> createState() => _CareIndicatorsState();
}

class _CareIndicatorsState extends State<CareIndicators>
    with SingleTickerProviderStateMixin {
  // Created eagerly in initState (NOT a lazy `late` field): an empty-needs build
  // returns before touching it, and a lazy init from dispose() would look up an
  // ancestor on a deactivated element and crash.
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  static const _hunger = ('hunger', 'assets/game/ui/needs/hunger.png');
  static const _mess = ('mess', 'assets/game/ui/needs/mess.png');
  static const _sick = ('sick', 'assets/game/ui/needs/sick.png');
  static const _unhappy = ('unhappy', 'assets/game/ui/needs/unhappy.png');

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = <(String, String)>[
      if (widget.hungry) _hunger,
      if (widget.messy) _mess,
      if (widget.sick) _sick,
      if (widget.unhappy) _unhappy,
    ];
    if (active.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final icon = w * 0.05; // per-icon bubble size
        final gap = icon * 0.28;
        final rowW = active.length * icon + (active.length - 1) * gap;
        final cx = widget.anchorX * w;
        final top = widget.headY * h - icon - h * 0.02; // just above the head
        return Stack(children: [
          Positioned(
            left: cx - rowW / 2,
            top: top,
            width: rowW,
            height: icon + 6,
            child: AnimatedBuilder(
              animation: _bob,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -_bob.value * 3),
                child: child,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < active.length; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    _chip(active[i], icon),
                  ],
                ],
              ),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _chip((String, String) def, double size) => SizedBox(
        key: ValueKey('need_${def.$1}'),
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x99000000),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x40FFFFFF), width: 0.5),
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.15),
            child: Image.asset(def.$2,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ),
        ),
      );
}
