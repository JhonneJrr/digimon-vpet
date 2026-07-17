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
