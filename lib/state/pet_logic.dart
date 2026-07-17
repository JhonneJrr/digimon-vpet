// lib/state/pet_logic.dart
import 'dart:math' as math;
import 'pet.dart';
import 'game_config.dart';

class PetLogic {
  /// Advance the pet to wall-clock time [nowMs].
  ///
  /// Correct for BOTH a single large jump (app reopened after an absence) and
  /// frequent small ticks (Flame timer while the app is open): each stat keeps
  /// its own accumulation anchor, so sub-unit remainders are never lost.
  static Pet applyElapsed(Pet pet, int nowMs) {
    if (pet.isDead) return pet; // dead stats are frozen

    // --- hunger (rises) ---
    final hGained = _units(pet.hungerSinceMs, nowMs, GameConfig.msPerHungerPoint);
    final prevHunger = pet.hunger;
    final hunger = (prevHunger + hGained).clamp(0, GameConfig.hungerMax);
    final hungerSinceMs = pet.hungerSinceMs + hGained * GameConfig.msPerHungerPoint;

    // --- happiness (decays) ---
    final hapGained =
        _units(pet.happinessSinceMs, nowMs, GameConfig.msPerHappinessDrop);
    final happiness =
        (pet.happiness - hapGained).clamp(0, GameConfig.happinessMax);
    final happinessSinceMs =
        pet.happinessSinceMs + hapGained * GameConfig.msPerHappinessDrop;

    // --- poop (accumulates) ---
    final pGained = _units(pet.poopSinceMs, nowMs, GameConfig.msPerPoop);
    final prevPoop = pet.poopCount;
    final poopCount = prevPoop + pGained;
    final poopSinceMs = pet.poopSinceMs + pGained * GameConfig.msPerPoop;

    // --- starving window: when hunger first reached max ---
    int? starvingSinceMs = pet.starvingSinceMs;
    if (hunger >= GameConfig.hungerMax) {
      if (starvingSinceMs == null) {
        // Exact crossing = anchor + time to climb from prevHunger to max.
        final crossing = pet.hungerSinceMs +
            (GameConfig.hungerMax - prevHunger) * GameConfig.msPerHungerPoint;
        starvingSinceMs = math.min(crossing, nowMs);
      }
    } else {
      starvingSinceMs = null;
    }

    // --- filth window: when poop first reached the threshold ---
    int? messySinceMs = pet.messySinceMs;
    if (poopCount >= GameConfig.messPoopThreshold) {
      if (messySinceMs == null) {
        final needed = (GameConfig.messPoopThreshold - prevPoop);
        final crossing =
            pet.poopSinceMs + math.max(0, needed) * GameConfig.msPerPoop;
        messySinceMs = math.min(crossing, nowMs);
      }
    } else {
      messySinceMs = null;
    }

    // --- sickness: earliest neglect onset that has already elapsed ---
    var health = pet.health;
    int? sickSinceMs = pet.sickSinceMs;
    var careScore = pet.careScore;
    if (health == HealthStatus.healthy) {
      final onsets = <int>[
        if (starvingSinceMs != null) starvingSinceMs + GameConfig.sickTimeoutMs,
        if (messySinceMs != null) messySinceMs + GameConfig.sickTimeoutMs,
      ].where((o) => o <= nowMs);
      if (onsets.isNotEmpty) {
        health = HealthStatus.sick;
        sickSinceMs = onsets.reduce(math.min);
        careScore = _clamp01(careScore - GameConfig.careDecayOnSick);
      }
    }

    // --- careScore decay from neglect that occurred this window ---
    careScore = _clamp01(careScore -
        GameConfig.careDecayPerHungerPoint * hGained -
        GameConfig.careDecayPerPoop * pGained);

    // --- death: sick and untreated past the death timeout ---
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
      careScore: careScore,
      hungerSinceMs: hungerSinceMs,
      happinessSinceMs: happinessSinceMs,
      poopSinceMs: poopSinceMs,
      starvingSinceMs: starvingSinceMs,
      clearStarvingSince: starvingSinceMs == null,
      messySinceMs: messySinceMs,
      clearMessySince: messySinceMs == null,
      sickSinceMs: sickSinceMs,
      isDead: isDead,
    );
  }

  /// Whole units elapsed from [sinceMs] to [nowMs] at [rateMs]. Returns 0 on a
  /// backward or stalled clock so a hiccup never rewinds or double-counts.
  static int _units(int sinceMs, int nowMs, int rateMs) =>
      nowMs > sinceMs ? (nowMs - sinceMs) ~/ rateMs : 0;

  static double _clamp01(double v) => v.clamp(0.0, 1.0);

  static double _bump(double s, double d) => _clamp01(s + d);

  /// True when the (living) pet is in a state worth a "come back" reminder:
  /// starving, living in filth, or sick. Used by the background reminder task
  /// so a well-tended pet never nags the player.
  static bool needsAttention(Pet p) =>
      !p.isDead &&
      (p.hunger >= GameConfig.hungerMax ||
          p.poopCount >= GameConfig.messPoopThreshold ||
          p.health == HealthStatus.sick);

  // --- care actions (no-ops on a dead pet; its stats are frozen) ---
  //
  // Each takes [nowMs] and resets the anchor of the stat it changes, so the
  // relief lasts a fresh full period. Without this the sub-period time already
  // "banked" against the old anchor would be re-applied by the very next
  // applyElapsed tick — e.g. a fed pet bouncing back to starving ~1s later.

  static Pet feed(Pet p, int nowMs) {
    if (p.isDead) return p;
    final hunger = (p.hunger - 1).clamp(0, GameConfig.hungerMax);
    return p.copyWith(
      hunger: hunger,
      hungerSinceMs: nowMs, // fresh full period before the next hunger point
      careScore: _bump(p.careScore, GameConfig.careBumpFeed),
      // Below max again -> no longer starving.
      clearStarvingSince: hunger < GameConfig.hungerMax,
    );
  }

  static Pet clean(Pet p, int nowMs) {
    if (p.isDead) return p;
    return p.copyWith(
      poopCount: 0,
      poopSinceMs: nowMs, // fresh full period before the next poop
      clearMessySince: true,
      careScore: _bump(p.careScore, GameConfig.careBumpClean),
    );
  }

  static Pet giveMedicine(Pet p, int nowMs) {
    if (p.isDead) return p;
    // No time-anchored stat changes here; nowMs kept for a uniform action
    // signature (see VpetGame._act).
    return p.health == HealthStatus.sick
        ? p.copyWith(
            health: HealthStatus.healthy,
            clearSickSince: true,
            careScore: _bump(p.careScore, GameConfig.careBumpMedicine),
          )
        : p;
  }

  static Pet play(Pet p, int nowMs) {
    if (p.isDead) return p;
    return p.copyWith(
      happiness: (p.happiness + 1).clamp(0, GameConfig.happinessMax),
      happinessSinceMs: nowMs, // fresh full period before the next decay
      careScore: _bump(p.careScore, GameConfig.careBumpPlay),
    );
  }

  /// Advance through as many stage thresholds as [nowMs] has crossed, starting
  /// each new stage's clock at the instant its predecessor's requirement was
  /// met (not the arbitrary check time), so infrequent polling never strands
  /// the pet a stage behind.
  static Pet checkEvolution(Pet p, int nowMs) {
    if (p.isDead) return p;
    var stage = p.stage;
    var startedAt = p.stageStartedAtMs;
    while (true) {
      final dur = GameConfig.stageDurationMs[stage];
      if (dur == null) break; // perfect stages have no further duration
      if (nowMs - startedAt < dur) break;
      final next = _nextStage(stage, p.careScore);
      if (next == null) break;
      startedAt += dur;
      stage = next;
    }
    if (stage == p.stage && startedAt == p.stageStartedAtMs) return p;
    return p.copyWith(stage: stage, stageStartedAtMs: startedAt);
  }

  static LifeStage? _nextStage(LifeStage stage, double careScore) {
    switch (stage) {
      case LifeStage.baby1:
        return LifeStage.baby2;
      case LifeStage.baby2:
        return LifeStage.child;
      case LifeStage.child:
        return LifeStage.adult;
      case LifeStage.adult:
        return careScore >= GameConfig.careScoreThreshold
            ? LifeStage.perfectMetal
            : LifeStage.perfectSkull;
      case LifeStage.perfectMetal:
      case LifeStage.perfectSkull:
        return null;
    }
  }
}
