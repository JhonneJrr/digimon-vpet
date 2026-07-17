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
}
