// lib/ui/hud/hud_overlay.dart
import 'package:flutter/material.dart';
import '../../state/pet.dart';
import '../shell/room_config.dart';
import '../widgets/status_badges.dart';

/// The real-game main HUD (spr_MainHUD) drawn as a full-box overlay. The six
/// hexagonal sockets carry the real menu-button art (spr_MainButtons_ENG) and
/// navigate to rooms via [onOpenRoom]; the name plate and status badges sit over
/// the top gauges. Coordinates are fractions of the 538x300 HUD box.
class HudOverlay extends StatelessWidget {
  const HudOverlay({
    super.key,
    required this.name,
    required this.pet,
    required this.onOpenRoom,
  });

  final String name;
  final Pet pet;
  final void Function(RoomConfig room) onOpenRoom;

  // Socket centres as fractions of the HUD box: five bottom-left + one right.
  static const _socketX = [0.105, 0.207, 0.309, 0.411, 0.513, 0.915];
  static const _socketY = 0.865;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;

      Widget socket(int i) {
        final s = w * 0.105;
        return Positioned(
          key: ValueKey('hud_socket_$i'),
          left: _socketX[i] * w - s / 2,
          top: _socketY * h - s / 2,
          width: s,
          height: s,
          child: GestureDetector(
            onTap: () => onOpenRoom(kRooms[i]),
            behavior: HitTestBehavior.opaque,
            child: Image.asset('assets/game/ui/menu_buttons/btn_$i.png',
                filterQuality: FilterQuality.none,
                errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ),
        );
      }

      return Stack(
        children: [
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
          // Needs badges — shifted left+down so they clear the centre level gauge.
          Positioned(
            left: w * 0.27,
            top: h * 0.14,
            child: StatusBadges(pet: pet),
          ),
          for (var i = 0; i < 6; i++) socket(i),
        ],
      );
    });
  }
}
