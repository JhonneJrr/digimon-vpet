// lib/state/pet.dart
import 'game_config.dart';

/// Legacy life-stage tier. Retained only as a transitional bridge while the
/// codebase migrates to speciesId; removed once all consumers read the species.
enum LifeStage { baby1, baby2, child, adult, perfectMetal, perfectSkull }

enum HealthStatus { healthy, sick }

/// Ordered ids of the seed line, indexed by the legacy LifeStage index. Used to
/// migrate old saves and to back the temporary `stage` bridge.
const List<String> _lineIds = [
  'botamon', 'koromon', 'agumon', 'greymon', 'metalgreymon', 'skullgreymon',
];

/// Immutable pet state. Identity is [speciesId]; time-driven stats each carry
/// their own "since" anchor (see applyElapsed).
class Pet {
  final String speciesId;
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
  final int? starvingSinceMs;
  final int? messySinceMs;
  final int? sickSinceMs;

  final bool isDead;

  const Pet({
    required this.speciesId,
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

  /// TEMPORARY bridge: legacy consumers still read `pet.stage`. Removed in the
  /// final migration task once biome/label/sprite all read the species.
  LifeStage get stage {
    final i = _lineIds.indexOf(speciesId);
    return i >= 0 ? LifeStage.values[i] : LifeStage.baby1;
  }

  factory Pet.newborn(int nowMs) => Pet(
        speciesId: 'botamon',
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
    String? speciesId,
    LifeStage? stage, // bridge: maps to speciesId (removed in Task 7)
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
        speciesId:
            speciesId ?? (stage != null ? _lineIds[stage.index] : this.speciesId),
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
        'speciesId': speciesId,
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
        // New saves carry speciesId; legacy saves carry a `stage` int index.
        speciesId: j['speciesId'] as String? ?? _lineIds[j['stage'] as int],
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
