// lib/ui/widgets/action_dock.dart
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter/widgets.dart';
import 'glass_panel.dart';

class ActionDock extends StatelessWidget {
  const ActionDock({
    super.key,
    required this.onFeed,
    required this.onClean,
    required this.onMedicine,
    required this.onPlay,
    required this.feedEnabled,
    required this.cleanEnabled,
    required this.medicineEnabled,
    required this.playEnabled,
  });

  final VoidCallback onFeed, onClean, onMedicine, onPlay;
  final bool feedEnabled, cleanEnabled, medicineEnabled, playEnabled;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn('dock_feed', 'assets/ui/fe_feed.png', feedEnabled, onFeed),
          _btn('dock_clean', 'assets/ui/fe_clean.png', cleanEnabled, onClean),
          _btn('dock_medicine', 'assets/ui/fe_medicine.png', medicineEnabled, onMedicine),
          _btn('dock_play', 'assets/ui/fe_play.png', playEnabled, onPlay),
        ],
      ),
    );
  }

  Widget _btn(String key, String asset, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      key: ValueKey(key),
      behavior: HitTestBehavior.opaque,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Image.asset(asset, width: 40, height: 40,
            errorBuilder: (_, _, _) =>
                const SizedBox(width: 40, height: 40)),
      ),
    );
  }
}
