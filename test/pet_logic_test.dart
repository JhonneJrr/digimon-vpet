import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/pet.dart';
import 'package:digimon/state/pet_logic.dart';
import 'package:digimon/state/game_config.dart';

void main() {
  test('Pet JSON round-trips', () {
    final p = Pet.newborn(1000).copyWith(hunger: 3, careScore: 0.7);
    final back = Pet.fromJson(p.toJson());
    expect(back.hunger, 3);
    expect(back.careScore, 0.7);
    expect(back.stage, LifeStage.baby1);
    expect(back.stageStartedAtMs, 1000);
  });

  group('applyElapsed', () {
    test('no time passed -> unchanged stats', () {
      final p = Pet.newborn(0);
      final r = PetLogic.applyElapsed(p, 0);
      expect(r.hunger, 0);
      expect(r.lastTickMs, 0);
    });

    test('hunger rises with elapsed time and clamps at max', () {
      final p = Pet.newborn(0);
      final r = PetLogic.applyElapsed(p, GameConfig.msPerHungerPoint * 10);
      expect(r.hunger, GameConfig.hungerMax);
    });

    test('poop appears after msPerPoop', () {
      final p = Pet.newborn(0);
      final r = PetLogic.applyElapsed(p, GameConfig.msPerPoop);
      expect(r.poopCount, greaterThanOrEqualTo(1));
    });

    test('prolonged max hunger makes the pet sick', () {
      final p = Pet.newborn(0);
      final r = PetLogic.applyElapsed(
          p, GameConfig.msPerHungerPoint * GameConfig.hungerMax + GameConfig.sickTimeoutMs);
      expect(r.health, HealthStatus.sick);
    });

    test('sick and untreated past deathTimeout -> dead', () {
      final p = Pet.newborn(0);
      final r = PetLogic.applyElapsed(
          p, GameConfig.msPerHungerPoint * GameConfig.hungerMax +
              GameConfig.sickTimeoutMs + GameConfig.deathTimeoutMs);
      expect(r.isDead, true);
    });
  });
}
