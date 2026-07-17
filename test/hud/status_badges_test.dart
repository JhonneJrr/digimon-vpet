import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/pet.dart';
import 'package:digimon/state/game_config.dart';
import 'package:digimon/ui/widgets/status_badges.dart';

Pet _pet({int hunger = 0, int poop = 0, HealthStatus health = HealthStatus.healthy, int happiness = GameConfig.happinessMax}) =>
    Pet.newborn(0).copyWith(hunger: hunger, poopCount: poop, health: health, happiness: happiness);

void main() {
  testWidgets('healthy well-fed pet shows no badges', (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: StatusBadges(pet: _pet()),
    ));
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('sick + starving + sad shows three badges', (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFF6A3FA0),
        child: StatusBadges(pet: _pet(
          hunger: GameConfig.hungerMax,
          health: HealthStatus.sick,
          happiness: 0,
        )),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(3));
  });
}
