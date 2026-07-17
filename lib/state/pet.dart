// lib/state/pet.dart
import 'game_config.dart';

enum LifeStage { baby1, baby2, child, adult, perfectMetal, perfectSkull }

enum HealthStatus { healthy, sick }

/// Immutable pet state.
///
/// Time-driven stats (hunger, happiness, poop) each carry their own "since"
/// anchor timestamp — the instant from which the next whole unit is measured.
/// applyElapsed advances an anchor only by the whole units it actually
/// consumed, so sub-unit remainders survive across many small ticks (a 1s
/// Flame tick no longer silently rounds to zero).
class Pet {
  final LifeStage stage;
  final int hunger; // 0 = full .. hungerMax = starving
  final int happiness; // 0 = sad .. happinessMax = happy
  final int poopCount;
  final HealthStatus health;
  final double careScore; // 0..1, decides Metal vs Skull
  final int stageStartedAtMs;

  // Per-stat accumulation anchors.
  final int hungerSinceMs;
  final int happinessSinceMs;
  final int poopSinceMs;

  // Neglect / illness event timestamps (null = not currently in that state).
  final int? starvingSinceMs; // when hunger first reached max
  final int? messySinceMs; // when poop first reached messPoopThreshold
  final int? sickSinceMs; // when sickness onset

  final bool isDead;

  const Pet({
    required this.stage,
    required this.hunger,
    required this.happiness,
    required this.poopCount,
    required this.health,
    required this.careScore,
    required this.stageStartedAtMs,
    required this.hungerSinceMs,
    required this.happinessSinceMs,
    required this.poopSinceMs,
    this.starvingSinceMs,
    this.messySinceMs,
    this.sickSinceMs,
    this.isDead = false,
  });

  factory Pet.newborn(int nowMs) => Pet(
        stage: LifeStage.baby1,
        hunger: 0,
        happiness: GameConfig.happinessMax,
        poopCount: 0,
        health: HealthStatus.healthy,
        careScore: 0.5,
        stageStartedAtMs: nowMs,
        hungerSinceMs: nowMs,
        happinessSinceMs: nowMs,
        poopSinceMs: nowMs,
      );

  Pet copyWith({
    LifeStage? stage,
    int? hunger,
    int? happiness,
    int? poopCount,
    HealthStatus? health,
    double? careScore,
    int? stageStartedAtMs,
    int? hungerSinceMs,
    int? happinessSinceMs,
    int? poopSinceMs,
    int? starvingSinceMs,
    bool clearStarvingSince = false,
    int? messySinceMs,
    bool clearMessySince = false,
    int? sickSinceMs,
    bool clearSickSince = false,
    bool? isDead,
  }) =>
      Pet(
        stage: stage ?? this.stage,
        hunger: hunger ?? this.hunger,
        happiness: happiness ?? this.happiness,
        poopCount: poopCount ?? this.poopCount,
        health: health ?? this.health,
        careScore: careScore ?? this.careScore,
        stageStartedAtMs: stageStartedAtMs ?? this.stageStartedAtMs,
        hungerSinceMs: hungerSinceMs ?? this.hungerSinceMs,
        happinessSinceMs: happinessSinceMs ?? this.happinessSinceMs,
        poopSinceMs: poopSinceMs ?? this.poopSinceMs,
        starvingSinceMs:
            clearStarvingSince ? null : (starvingSinceMs ?? this.starvingSinceMs),
        messySinceMs:
            clearMessySince ? null : (messySinceMs ?? this.messySinceMs),
        sickSinceMs: clearSickSince ? null : (sickSinceMs ?? this.sickSinceMs),
        isDead: isDead ?? this.isDead,
      );

  Map<String, dynamic> toJson() => {
        'stage': stage.index,
        'hunger': hunger,
        'happiness': happiness,
        'poopCount': poopCount,
        'health': health.index,
        'careScore': careScore,
        'stageStartedAtMs': stageStartedAtMs,
        'hungerSinceMs': hungerSinceMs,
        'happinessSinceMs': happinessSinceMs,
        'poopSinceMs': poopSinceMs,
        'starvingSinceMs': starvingSinceMs,
        'messySinceMs': messySinceMs,
        'sickSinceMs': sickSinceMs,
        'isDead': isDead,
      };

  factory Pet.fromJson(Map<String, dynamic> j) => Pet(
        stage: LifeStage.values[j['stage'] as int],
        hunger: j['hunger'] as int,
        happiness: j['happiness'] as int,
        poopCount: j['poopCount'] as int,
        health: HealthStatus.values[j['health'] as int],
        careScore: (j['careScore'] as num).toDouble(),
        stageStartedAtMs: j['stageStartedAtMs'] as int,
        hungerSinceMs: j['hungerSinceMs'] as int,
        happinessSinceMs: j['happinessSinceMs'] as int,
        poopSinceMs: j['poopSinceMs'] as int,
        starvingSinceMs: j['starvingSinceMs'] as int?,
        messySinceMs: j['messySinceMs'] as int?,
        sickSinceMs: j['sickSinceMs'] as int?,
        isDead: j['isDead'] as bool,
      );
}
