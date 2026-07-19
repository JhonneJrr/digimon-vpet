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

  // Socket centres as fractions of the 538x300 HUD box (five bottom-left + one
  // right), MEASURED from the dark hex-hole centres in `main_hud.png`.
  static const _socketX = [0.103, 0.224, 0.345, 0.466, 0.587, 0.966];
  static const _socketY = 0.862;
  // The menu-button art is 65x45 native; render it at that exact size in the
  // 538x300 space (so it seats in the socket undistorted, not stretched square).
  static const _btnWFrac = 65 / 538;
  static const _btnHFrac = 45 / 300;

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
