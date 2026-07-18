// lib/ui/widgets/top_status_bar.dart
import 'package:flutter/widgets.dart';
import 'glass_panel.dart';

class TopStatusBar extends StatelessWidget {
  const TopStatusBar(
      {super.key,
      required this.label,
      required this.accent,
      this.onSettings,
      this.onMenu});
  final String label;
  final Color accent;
  final VoidCallback? onSettings;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: accent, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13)),
          const Spacer(),
          if (onSettings != null) ...[
            GestureDetector(
              key: const ValueKey('settings_gear'),
              onTap: onSettings,
              behavior: HitTestBehavior.opaque,
              child: const Icon(_gear, size: 18, color: Color(0x99FFFFFF)),
            ),
            const SizedBox(width: 12),
          ],
          GestureDetector(
            key: const ValueKey('hud_menu'),
            onTap: onMenu,
            behavior: HitTestBehavior.opaque,
            child: const Icon(_menu, size: 20, color: Color(0xCCFFFFFF)),
          ),
        ],
      ),
    );
  }
}

// Material glyphs without importing the whole Material library.
const IconData _gear = IconData(0xe8b8, fontFamily: 'MaterialIcons');
const IconData _menu = IconData(0xe5d2, fontFamily: 'MaterialIcons'); // hamburger
