// lib/ui/widgets/top_status_bar.dart
import 'package:flutter/widgets.dart';
import 'glass_panel.dart';

class TopStatusBar extends StatelessWidget {
  const TopStatusBar(
      {super.key, required this.label, required this.accent, this.onSettings});
  final String label;
  final Color accent;
  final VoidCallback? onSettings;

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
          GestureDetector(
            key: const ValueKey('settings_gear'),
            onTap: onSettings,
            behavior: HitTestBehavior.opaque,
            child: const Icon(_gear, size: 18, color: Color(0x99FFFFFF)),
          ),
        ],
      ),
    );
  }
}

// Material "settings" glyph without importing the whole Material library.
const IconData _gear = IconData(0xe8b8, fontFamily: 'MaterialIcons');
