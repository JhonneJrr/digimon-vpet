// lib/ui/hud/hud_overlay.dart
import 'package:flutter/material.dart';
import '../shell/room_config.dart';

/// The real-game main HUD (spr_MainHUD) drawn as a full-box overlay. The six
/// hexagonal sockets carry the real menu-button art (spr_MainButtons_ENG) and
/// navigate to rooms via [onOpenRoom]; the name plate sits over the top-left
/// tech plate. Need indicators live over the Digimon (see [CareIndicators]), not
/// here. Coordinates are fractions of the 538x300 HUD box.
class HudOverlay extends StatelessWidget {
  const HudOverlay({
    super.key,
    required this.name,
    required this.onOpenRoom,
  });

  final String name;
  final void Function(RoomConfig room) onOpenRoom;

  // Button centres + size as fractions of the 538x300 HUD box, CALIBRATED to the
  // real game: measured from a reference screenshot of Reborn 2 (whose buttons
  // seat 1:1 in this same spr_MainHUD art). The buttons sit slightly left of and
  // below the decorative socket holes and tile edge-to-edge along the base.
  static const _socketX = [0.065, 0.180, 0.302, 0.423, 0.543, 0.927];
  static const _socketY = 0.895;
  static const _btnWFrac = 0.132;
  static const _btnHFrac = 0.158;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;

      Widget socket(int i) {
        final bw = w * _btnWFrac, bh = h * _btnHFrac;
        return Positioned(
          key: ValueKey('hud_socket_$i'),
          left: _socketX[i] * w - bw / 2,
          top: _socketY * h - bh / 2,
          width: bw,
          height: bh,
          child: GestureDetector(
            onTap: () => onOpenRoom(kRooms[i]),
            behavior: HitTestBehavior.opaque,
            child: Image.asset('assets/game/ui/menu_buttons/btn_$i.png',
                fit: BoxFit.fill, filterQuality: FilterQuality.none,
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
          for (var i = 0; i < 6; i++) socket(i),
        ],
      );
    });
  }
}
