// lib/state/pet_logic.dart
import 'pet.dart';
import 'game_config.dart';

class PetLogic {
  static Pet applyElapsed(Pet pet, int nowMs) {
    if (pet.isDead || nowMs <= pet.lastTickMs) {
      return pet.copyWith(lastTickMs: nowMs);
    }
    final elapsed = nowMs - pet.lastTickMs;

    // Hunger rises.
    final hunger =
        (pet.hunger + elapsed ~/ GameConfig.msPerHungerPoint).clamp(0, GameConfig.hungerMax);
    // Happiness decays.
    final happiness =
        (pet.happiness - elapsed ~/ GameConfig.msPerHappinessDrop).clamp(0, GameConfig.happinessMax);
    // Poop accumulates.
    final poopCount = pet.poopCount + elapsed ~/ GameConfig.msPerPoop;

    // Track starving window.
    int? starvingSinceMs = pet.starvingSinceMs;
    if (hunger >= GameConfig.hungerMax) {
      starvingSinceMs ??= nowMs - (elapsed - GameConfig.msPerHungerPoint * GameConfig.hungerMax)
          .clamp(0, elapsed);
    } else {
      starvingSinceMs = null;
    }

    // Sickness from prolonged starving or heavy mess.
    var health = pet.health;
    int? sickSinceMs = pet.sickSinceMs;
    final starvedLongEnough = starvingSinceMs != null &&
        nowMs - starvingSinceMs >= GameConfig.sickTimeoutMs;
    final messyLongEnough = poopCount >= 3;
    if (health == HealthStatus.healthy && (starvedLongEnough || messyLongEnough)) {
      health = HealthStatus.sick;
      // If triggered by prolonged starving, backdate sickSinceMs to the
      // moment sickness actually began within this elapsed window (so a
      // single large applyElapsed jump that also crosses deathTimeoutMs
      // correctly marks the pet dead). Otherwise (mess-triggered), sickness
      // begins now.
      sickSinceMs = starvedLongEnough
          ? starvingSinceMs + GameConfig.sickTimeoutMs
          : nowMs;
    }

    // Death from untreated sickness.
    var isDead = pet.isDead;
    if (health == HealthStatus.sick &&
        sickSinceMs != null &&
        nowMs - sickSinceMs >= GameConfig.deathTimeoutMs) {
      isDead = true;
    }

    return pet.copyWith(
      hunger: hunger,
      happiness: happiness,
      poopCount: poopCount,
      health: health,
      sickSinceMs: sickSinceMs,
      starvingSinceMs: starvingSinceMs,
      clearStarvingSince: starvingSinceMs == null,
      isDead: isDead,
      lastTickMs: nowMs,
    );
  }

  static double _bump(double s, double d) => (s + d).clamp(0.0, 1.0);

  static Pet feed(Pet p) =>
      p.copyWith(hunger: (p.hunger - 1).clamp(0, GameConfig.hungerMax),
                 careScore: _bump(p.careScore, 0.05));

  static Pet clean(Pet p) =>
      p.copyWith(poopCount: 0, careScore: _bump(p.careScore, 0.05));

  static Pet giveMedicine(Pet p) => p.health == HealthStatus.sick
      ? p.copyWith(health: HealthStatus.healthy, clearSickSince: true,
                   careScore: _bump(p.careScore, 0.1))
      : p;

  static Pet play(Pet p) =>
      p.copyWith(happiness: (p.happiness + 1).clamp(0, GameConfig.happinessMax),
                 careScore: _bump(p.careScore, 0.05));

  static Pet checkEvolution(Pet p, int nowMs) {
    final dur = GameConfig.stageDurationMs[p.stage];
    if (dur == null || p.isDead) return p; // perfect stages have no duration
    if (nowMs - p.stageStartedAtMs < dur) return p;
    late LifeStage next;
    switch (p.stage) {
      case LifeStage.baby1: next = LifeStage.baby2; break;
      case LifeStage.baby2: next = LifeStage.child; break;
      case LifeStage.child: next = LifeStage.adult; break;
      case LifeStage.adult:
        next = p.careScore >= GameConfig.careScoreThreshold
            ? LifeStage.perfectMetal
            : LifeStage.perfectSkull;
        break;
      default: return p;
    }
    return p.copyWith(stage: next, stageStartedAtMs: nowMs);
  }
}
