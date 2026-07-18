// lib/ui/shell/room_screen.dart
import 'package:flutter/material.dart';
import 'room_config.dart';

/// A room reached from the menu. Renders the real background pixel-perfect; a
/// stub overlays a "em breve" state, a real screen renders [config.content].
class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key, required this.config});
  final RoomConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B17),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(config.backgroundAsset,
              fit: BoxFit.cover, filterQuality: FilterQuality.none),
          if (config.comingSoon) Container(color: const Color(0x99080610)),
          if (!config.comingSoon && config.content != null)
            config.content!(context),
          if (config.comingSoon)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(config.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFF9D42),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('em breve',
                        style: TextStyle(
                            color: Color(0xFF0D0B17),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2)),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: const Color(0x66000000),
                  shape: const CircleBorder(),
                  child: IconButton(
                    key: const ValueKey('room_back'),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
