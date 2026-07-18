// lib/ui/hud/pet_tap_target.dart
import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// A transparent, tappable box centred on the Digimon. Positioned by fractions
/// of the enclosing 538x300 stage; opens/closes the care radial. Pure widget.
class PetTapTarget extends StatelessWidget {
  const PetTapTarget({
    super.key,
    required this.anchorX,
    required this.groundFraction,
    required this.heightFraction,
    required this.onTap,
  });

  final double anchorX, groundFraction, heightFraction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Positioned requires a Stack as its immediate render-object ancestor, so
    // LayoutBuilder (itself a RenderObjectWidget) can't sit directly between
    // them. Positioned.fill inherits the outer Stack's box for LayoutBuilder
    // to measure, then an inner Stack hosts the actual Positioned tap zone.
    return Positioned.fill(
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final side = math.max(44.0, heightFraction * h);
        final cx = anchorX * w;
        final bottom = groundFraction * h;
        return Stack(children: [
          Positioned(
            left: cx - side / 2,
            top: bottom - side,
            width: side,
            height: side,
            child: GestureDetector(
              key: const ValueKey('pet_tap'),
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: const SizedBox.expand(),
            ),
          ),
        ]);
      }),
    );
  }
}
