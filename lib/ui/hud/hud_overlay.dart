// lib/ui/hud/hud_overlay.dart
import 'package:flutter/material.dart';
import '../../state/pet.dart';
import '../widgets/status_badges.dart';

/// The real-game main HUD (spr_MainHUD) drawn as a full-box overlay, with
/// interactive regions positioned over its art: the name plate (top-left), the
/// status badges (top-centre), the care actions on the bottom hex slots, and a
/// menu button on the bottom-right slot. Coordinates are fractions of the 538x300
/// HUD box (the box shares the HUD's aspect ratio, so they map 1:1, undistorted).
class HudOverlay extends StatelessWidget {
  const HudOverlay({
    super.key,
    required this.name,
    required this.pet,
    required this.onFeed,
    required this.onClean,
    required this.onMedicine,
    required this.onPlay,
    required this.onMenu,
    required this.feedEnabled,
    required this.cleanEnabled,
    required this.medicineEnabled,
    required this.playEnabled,
  });

  final String name;
  final Pet pet;
  final VoidCallback onFeed, onClean, onMedicine, onPlay, onMenu;
  final bool feedEnabled, cleanEnabled, medicineEnabled, playEnabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;

      Widget slot(double fx, double fy, String asset, VoidCallback onTap,
          bool enabled) {
        final s = w * 0.085;
        return Positioned(
          left: fx * w - s / 2,
          top: fy * h - s / 2,
          width: s,
          height: s,
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: GestureDetector(
              onTap: enabled ? onTap : null,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(s * 0.12),
                child: Image.asset(asset, filterQuality: FilterQuality.medium),
              ),
            ),
          ),
        );
      }

      return Stack(
        children: [
          // The HUD frame itself (pixel-perfect, non-interactive).
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset('assets/game/ui/main_hud.png',
                  fit: BoxFit.fill, filterQuality: FilterQuality.none),
            ),
          ),
          // Name, over the top-left tech plate.
          Positioned(
            left: w * 0.05,
            top: h * 0.045,
            width: w * 0.16,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: h * 0.05,
                  fontWeight: FontWeight.w700),
            ),
          ),
          // Needs, over the top-centre gauge area.
          Positioned(
            left: w * 0.34,
            top: h * 0.03,
            child: StatusBadges(pet: pet),
          ),
          // Care actions on the bottom hex slots.
          slot(0.105, 0.865, 'assets/ui/fe_feed.png', onFeed, feedEnabled),
          slot(0.207, 0.865, 'assets/ui/fe_clean.png', onClean, cleanEnabled),
          slot(0.309, 0.865, 'assets/ui/fe_medicine.png', onMedicine,
              medicineEnabled),
          slot(0.411, 0.865, 'assets/ui/fe_play.png', onPlay, playEnabled),
          // Menu on the bottom-right slot.
          Positioned(
            left: w * 0.915,
            top: h * 0.80,
            width: w * 0.07,
            height: w * 0.07,
            child: GestureDetector(
              key: const ValueKey('hud_menu'),
              onTap: onMenu,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.menu, color: Colors.white, size: w * 0.042),
            ),
          ),
        ],
      );
    });
  }
}
