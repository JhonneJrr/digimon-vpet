// lib/ui/widgets/top_status_bar.dart
import 'package:flutter/widgets.dart';
import '../../state/pet.dart';
import '../hud_theme.dart';
import 'glass_panel.dart';

String stageLabel(LifeStage s) {
  switch (s) {
    case LifeStage.baby1: return 'Botamon';
    case LifeStage.baby2: return 'Koromon';
    case LifeStage.child: return 'Agumon';
    case LifeStage.adult: return 'Greymon';
    case LifeStage.perfectMetal: return 'MetalGreymon';
    case LifeStage.perfectSkull: return 'SkullGreymon';
  }
}

class TopStatusBar extends StatelessWidget {
  const TopStatusBar({super.key, required this.pet, this.onSettings});
  final Pet pet;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final accent = hudAccentFor(pet);
    return GlassPanel(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(stageLabel(pet.stage),
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
