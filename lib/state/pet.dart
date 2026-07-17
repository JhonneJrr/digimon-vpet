// lib/state/pet.dart
import 'game_config.dart';

enum LifeStage { baby1, baby2, child, adult, perfectMetal, perfectSkull }
enum HealthStatus { healthy, sick }

class Pet {
  final LifeStage stage;
  final int hunger;        // 0 = full .. hungerMax = starving
  final int happiness;     // 0 = sad .. happinessMax = happy
  final int poopCount;
  final HealthStatus health;
  final double careScore;  // 0..1, decides Metal vs Skull
  final int stageStartedAtMs;
  final int lastTickMs;
  final int? sickSinceMs;
  final int? starvingSinceMs;
  final bool isDead;

  const Pet({
    required this.stage,
    required this.hunger,
    required this.happiness,
    required this.poopCount,
    required this.health,
    required this.careScore,
    required this.stageStartedAtMs,
    required this.lastTickMs,
    this.sickSinceMs,
    this.starvingSinceMs,
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
        lastTickMs: nowMs,
      );

  Pet copyWith({
    LifeStage? stage,
    int? hunger,
    int? happiness,
    int? poopCount,
    HealthStatus? health,
    double? careScore,
    int? stageStartedAtMs,
    int? lastTickMs,
    int? sickSinceMs,
    bool clearSickSince = false,
    int? starvingSinceMs,
    bool clearStarvingSince = false,
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
        lastTickMs: lastTickMs ?? this.lastTickMs,
        sickSinceMs: clearSickSince ? null : (sickSinceMs ?? this.sickSinceMs),
        starvingSinceMs:
            clearStarvingSince ? null : (starvingSinceMs ?? this.starvingSinceMs),
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
        'lastTickMs': lastTickMs,
        'sickSinceMs': sickSinceMs,
        'starvingSinceMs': starvingSinceMs,
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
        lastTickMs: j['lastTickMs'] as int,
        sickSinceMs: j['sickSinceMs'] as int?,
        starvingSinceMs: j['starvingSinceMs'] as int?,
        isDead: j['isDead'] as bool,
      );
}
