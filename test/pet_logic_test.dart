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

  group('care actions', () {
    test('feed lowers hunger and raises careScore', () {
      final p = Pet.newborn(0).copyWith(hunger: 3, careScore: 0.5);
      final r = PetLogic.feed(p);
      expect(r.hunger, 2);
      expect(r.careScore, greaterThan(0.5));
    });
    test('clean removes all poop', () {
      final p = Pet.newborn(0).copyWith(poopCount: 2);
      expect(PetLogic.clean(p).poopCount, 0);
    });
    test('medicine cures a sick pet only', () {
      final sick = Pet.newborn(0)
          .copyWith(health: HealthStatus.sick, sickSinceMs: 10);
      final cured = PetLogic.giveMedicine(sick);
      expect(cured.health, HealthStatus.healthy);
      expect(cured.sickSinceMs, isNull);
      final healthy = Pet.newborn(0);
      expect(PetLogic.giveMedicine(healthy).health, HealthStatus.healthy);
    });
    test('play raises happiness capped at max', () {
      final p = Pet.newborn(0).copyWith(happiness: GameConfig.happinessMax);
      expect(PetLogic.play(p).happiness, GameConfig.happinessMax);
    });
  });

  group('evolution', () {
    test('baby1 evolves to baby2 after its duration', () {
      final p = Pet.newborn(0);
      final r = PetLogic.checkEvolution(p, GameConfig.stageDurationMs[LifeStage.baby1]!);
      expect(r.stage, LifeStage.baby2);
      expect(r.stageStartedAtMs, GameConfig.stageDurationMs[LifeStage.baby1]!);
    });
    test('well-cared adult -> MetalGreymon', () {
      final p = Pet.newborn(0)
          .copyWith(stage: LifeStage.adult, careScore: 0.9, stageStartedAtMs: 0);
      final r = PetLogic.checkEvolution(p, GameConfig.stageDurationMs[LifeStage.adult]!);
      expect(r.stage, LifeStage.perfectMetal);
    });
    test('neglected adult -> SkullGreymon', () {
      final p = Pet.newborn(0)
          .copyWith(stage: LifeStage.adult, careScore: 0.2, stageStartedAtMs: 0);
      final r = PetLogic.checkEvolution(p, GameConfig.stageDurationMs[LifeStage.adult]!);
      expect(r.stage, LifeStage.perfectSkull);
    });
    test('perfect stage does not evolve', () {
      final p = Pet.newborn(0).copyWith(stage: LifeStage.perfectMetal);
      final r = PetLogic.checkEvolution(p, 999999999);
      expect(r.stage, LifeStage.perfectMetal);
    });
  });
}
