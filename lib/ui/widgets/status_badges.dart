// lib/ui/widgets/status_badges.dart
import 'package:flutter/widgets.dart';
import '../../state/pet.dart';
import '../../state/game_config.dart';
import 'glass_panel.dart';

class StatusBadges extends StatelessWidget {
  const StatusBadges({super.key, required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (pet.hunger >= GameConfig.hungerWarnThreshold)
        _badge('assets/ui/fe_feed.png', const Color(0xFFFF5C5C)),
      if (pet.poopCount > 0)
        _badge('assets/ui/fe_mess.png', const Color(0xFFC8965A)),
      if (pet.health == HealthStatus.sick)
        _badge('assets/ui/fe_sick.png', const Color(0xFFFF5C5C)),
      if (pet.happiness <= GameConfig.happinessWarnThreshold)
        _badge('assets/ui/fe_happy_low.png', const Color(0xFF6EA0FF)),
    ];
    if (badges.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final b in badges) Padding(padding: const EdgeInsets.only(bottom: 8), child: b),
      ],
    );
  }

  Widget _badge(String asset, Color ring) => GlassPanel(
        radius: 22,
        padding: const EdgeInsets.all(6),
        borderColor: ring,
        child: Image.asset(asset, width: 22, height: 22,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox(width: 22, height: 22)),
      );
}
