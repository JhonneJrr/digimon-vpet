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
    expect(back.hungerSinceMs, 1000);
  });

  group('applyElapsed', () {
    test('no time passed -> unchanged stats', () {
      final p = Pet.newborn(0);
      final r = PetLogic.applyElapsed(p, 0);
      expect(r.hunger, 0);
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

    test('INCREMENTAL ticking matches a single equivalent jump', () {
      // 10 one-second ticks must accumulate the same as one 10s jump.
      final rate = GameConfig.msPerHungerPoint; // 5000ms
      final tick = rate ~/ 5; // 1000ms — smaller than one hunger unit
      var incremental = Pet.newborn(0);
      for (var t = tick; t <= rate * 2; t += tick) {
        incremental = PetLogic.applyElapsed(incremental, t);
      }
      final jumped = PetLogic.applyElapsed(Pet.newborn(0), rate * 2);
      expect(incremental.hunger, 2);
      expect(incremental.hunger, jumped.hunger);
    });

    test('prolonged max hunger makes the pet sick', () {
      final p = Pet.newborn(0);
      final r = PetLogic.applyElapsed(
          p,
          GameConfig.msPerHungerPoint * GameConfig.hungerMax +
              GameConfig.sickTimeoutMs);
      expect(r.health, HealthStatus.sick);
    });

    test('sick and untreated past deathTimeout -> dead (single jump)', () {
      final p = Pet.newborn(0);
      final r = PetLogic.applyElapsed(
          p,
          GameConfig.msPerHungerPoint * GameConfig.hungerMax +
              GameConfig.sickTimeoutMs +
              GameConfig.deathTimeoutMs);
      expect(r.isDead, true);
    });

    test('starving backdate respects nonzero starting hunger', () {
      // hunger already 3: reaches max fast, so death should fire in one jump.
      final p = Pet.newborn(0).copyWith(hunger: 3);
      final r = PetLogic.applyElapsed(p, 40000);
      expect(r.isDead, true);
    });

    test('backward clock does not double-count elapsed time', () {
      final p = Pet.newborn(100000);
      final rewound = PetLogic.applyElapsed(p, 50000); // clock hiccup backward
      expect(rewound.poopCount, 0);
      final forward = PetLogic.applyElapsed(rewound, 118750);
      final direct = PetLogic.applyElapsed(p, 118750);
      expect(forward.poopCount, direct.poopCount);
      expect(forward.poopCount, 3); // only the real 18750ms counted
    });
  });

  group('care actions', () {
    test('feed lowers hunger and raises careScore', () {
      final p = Pet.newborn(0).copyWith(hunger: 3, careScore: 0.5);
      final r = PetLogic.feed(p, 0);
      expect(r.hunger, 2);
      expect(r.careScore, greaterThan(0.5));
    });
    test('feeding resets the hunger anchor so relief lasts a full period', () {
      // Age the pet so its anchor sits a full period behind `now`.
      final now = GameConfig.msPerHungerPoint * 4;
      final aged = PetLogic.applyElapsed(Pet.newborn(0), now);
      expect(aged.hunger, GameConfig.hungerMax); // starving
      final fed = PetLogic.feed(aged, now);
      expect(fed.hunger, GameConfig.hungerMax - 1);
      // Just under one period later, hunger must NOT re-increment.
      final later =
          PetLogic.applyElapsed(fed, now + GameConfig.msPerHungerPoint - 1);
      expect(later.hunger, GameConfig.hungerMax - 1,
          reason: 'fed relief must not bounce back within a period');
    });
    test('clean removes all poop and clears filth window', () {
      final p = Pet.newborn(0).copyWith(poopCount: 5, messySinceMs: 10);
      final r = PetLogic.clean(p, 0);
      expect(r.poopCount, 0);
      expect(r.messySinceMs, isNull);
    });
    test('medicine cures a sick pet only', () {
      final sick =
          Pet.newborn(0).copyWith(health: HealthStatus.sick, sickSinceMs: 10);
      final cured = PetLogic.giveMedicine(sick, 0);
      expect(cured.health, HealthStatus.healthy);
      expect(cured.sickSinceMs, isNull);
      final healthy = Pet.newborn(0);
      expect(PetLogic.giveMedicine(healthy, 0).health, HealthStatus.healthy);
    });
    test('play raises happiness capped at max', () {
      final p = Pet.newborn(0).copyWith(happiness: GameConfig.happinessMax);
      expect(PetLogic.play(p, 0).happiness, GameConfig.happinessMax);
    });

    test('a dead pet is frozen against all care actions', () {
      final dead = Pet.newborn(0).copyWith(
        isDead: true,
        hunger: 4,
        poopCount: 5,
        health: HealthStatus.sick,
        careScore: 0.5,
      );
      expect(PetLogic.feed(dead, 0).hunger, 4);
      expect(PetLogic.clean(dead, 0).poopCount, 5);
      expect(PetLogic.giveMedicine(dead, 0).health, HealthStatus.sick);
      expect(PetLogic.play(dead, 0).careScore, 0.5);
      expect(PetLogic.applyElapsed(dead, 999999).hunger, 4);
    });
  });

  group('careScore direction', () {
    test('neglect lowers careScore below its start', () {
      final p = Pet.newborn(0).copyWith(careScore: 0.5);
      final r = PetLogic.applyElapsed(p, 20000); // hunger + poop accumulate
      expect(r.careScore, lessThan(0.5));
    });
    test('care actions raise careScore', () {
      final p = Pet.newborn(0).copyWith(careScore: 0.5);
      expect(PetLogic.play(p, 0).careScore, greaterThan(0.5));
    });
    test('careScore never leaves [0,1]', () {
      final p = Pet.newborn(0).copyWith(careScore: 0.01);
      final r = PetLogic.applyElapsed(p, 200000); // heavy neglect
      expect(r.careScore, greaterThanOrEqualTo(0.0));
      final happy = Pet.newborn(0).copyWith(careScore: 0.99);
      expect(PetLogic.play(happy, 0).careScore, lessThanOrEqualTo(1.0));
    });
  });

  group('needsAttention', () {
    test('a fresh, healthy pet does not need attention', () {
      expect(PetLogic.needsAttention(Pet.newborn(0)), false);
    });
    test('starving, filthy, or sick each need attention', () {
      final base = Pet.newborn(0);
      expect(
          PetLogic.needsAttention(base.copyWith(hunger: GameConfig.hungerMax)),
          true);
      expect(
          PetLogic.needsAttention(
              base.copyWith(poopCount: GameConfig.messPoopThreshold)),
          true);
      expect(PetLogic.needsAttention(base.copyWith(health: HealthStatus.sick)),
          true);
    });
    test('a dead pet never needs attention', () {
      final dead = Pet.newborn(0).copyWith(
        isDead: true,
        hunger: GameConfig.hungerMax,
        health: HealthStatus.sick,
      );
      expect(PetLogic.needsAttention(dead), false);
    });
  });

  group('evolution', () {
    test('baby1 evolves to baby2 after its duration', () {
      final p = Pet.newborn(0);
      final r = PetLogic.checkEvolution(
          p, GameConfig.stageDurationMs[LifeStage.baby1]!);
      expect(r.stage, LifeStage.baby2);
      expect(r.stageStartedAtMs, GameConfig.stageDurationMs[LifeStage.baby1]!);
    });

    test('cascades through multiple stages, clock anchored to each threshold',
        () {
      final b1 = GameConfig.stageDurationMs[LifeStage.baby1]!;
      final b2 = GameConfig.stageDurationMs[LifeStage.baby2]!;
      final now = b1 + b2 + 5000; // 5s into child
      final r = PetLogic.checkEvolution(Pet.newborn(0), now);
      expect(r.stage, LifeStage.child);
      expect(r.stageStartedAtMs, b1 + b2); // not `now`
    });

    test('well-cared adult -> MetalGreymon', () {
      final p = Pet.newborn(0)
          .copyWith(stage: LifeStage.adult, careScore: 0.9, stageStartedAtMs: 0);
      final r = PetLogic.checkEvolution(
          p, GameConfig.stageDurationMs[LifeStage.adult]!);
      expect(r.stage, LifeStage.perfectMetal);
    });

    test('neglected adult -> SkullGreymon', () {
      final p = Pet.newborn(0)
          .copyWith(stage: LifeStage.adult, careScore: 0.2, stageStartedAtMs: 0);
      final r = PetLogic.checkEvolution(
          p, GameConfig.stageDurationMs[LifeStage.adult]!);
      expect(r.stage, LifeStage.perfectSkull);
    });

    test('perfect stage does not evolve', () {
      final p = Pet.newborn(0).copyWith(stage: LifeStage.perfectMetal);
      final r = PetLogic.checkEvolution(p, 999999999);
      expect(r.stage, LifeStage.perfectMetal);
    });
  });
}
