// lib/state/digimon_species.dart
//
// Pure, data-driven creature model (no Flutter/Flame imports). Seeded by
// assets/data/species.json and injected into the logic/render layers.
import 'biome.dart';

enum StageTier { fresh, inTraining, rookie, champion, ultimate }

enum EvoCondition { always, careScoreHigh, careScoreLow }

class Evolution {
  final String toId;
  final int afterMs; // time in the source stage before this transition is eligible
  final EvoCondition condition;
  const Evolution(
      {required this.toId, required this.afterMs, required this.condition});

  factory Evolution.fromJson(Map<String, dynamic> j) => Evolution(
        toId: j['toId'] as String,
        afterMs: j['afterMs'] as int,
        condition: EvoCondition.values.byName(j['condition'] as String),
      );

  Map<String, dynamic> toJson() =>
      {'toId': toId, 'afterMs': afterMs, 'condition': condition.name};
}

/// Battle stats — RESERVED for a future phase; parsed if present, unused now.
class Stats {
  final int hp, attack, defense, speed;
  const Stats(
      {this.hp = 0, this.attack = 0, this.defense = 0, this.speed = 0});

  factory Stats.fromJson(Map<String, dynamic> j) => Stats(
        hp: j['hp'] as int? ?? 0,
        attack: j['attack'] as int? ?? 0,
        defense: j['defense'] as int? ?? 0,
        speed: j['speed'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'hp': hp, 'attack': attack, 'defense': defense, 'speed': speed};
}

/// Care-driven animation states the renderer can show.
enum CareAnim { idle, walk, eat, happy, sick }

/// One animation clip: frame count + timing. Frame image paths are built by
/// convention at render time: `creatures/<speciesId>/<state>_<i>.png`.
class AnimClip {
  final int frameCount;
  final double stepTime;
  final bool loop;
  const AnimClip(
      {required this.frameCount, required this.stepTime, required this.loop});

  factory AnimClip.fromJson(Map<String, dynamic> j) => AnimClip(
        frameCount: j['frames'] as int,
        stepTime: (j['stepTime'] as num).toDouble(),
        loop: j['loop'] as bool,
      );

  Map<String, dynamic> toJson() =>
      {'frames': frameCount, 'stepTime': stepTime, 'loop': loop};
}

/// A creature's animation set. `idle` is required; a missing state resolves to
/// idle (e.g. Botamon has no `sick` art). [displayHeight] is the on-screen
/// height (logical px) of the idle pose — it encodes visible growth across
/// stages; the renderer scales every clip by the same idle-derived factor.
class CreatureSprite {
  final double displayHeight;
  final Map<CareAnim, AnimClip> clips;
  const CreatureSprite({required this.displayHeight, required this.clips});

  /// The state actually available for [a] (itself if present, else idle).
  CareAnim resolve(CareAnim a) => clips.containsKey(a) ? a : CareAnim.idle;

  /// The clip to play for care state [a] (the idle clip if [a] is absent).
  AnimClip clip(CareAnim a) => clips[resolve(a)]!;

  factory CreatureSprite.fromJson(Map<String, dynamic> j) {
    final clips = <CareAnim, AnimClip>{};
    (j['states'] as Map<String, dynamic>).forEach((k, v) =>
        clips[CareAnim.values.byName(k)] =
            AnimClip.fromJson(v as Map<String, dynamic>));
    if (!clips.containsKey(CareAnim.idle)) {
      throw ArgumentError('Species sprite is missing the required "idle" state');
    }
    return CreatureSprite(
      displayHeight: (j['displayHeight'] as num).toDouble(),
      clips: clips,
    );
  }
}

class DigimonSpecies {
  final String id;
  final String name;
  final StageTier tier;
  final Biome biome;
  final CreatureSprite sprite;
  final List<Evolution> evolvesTo; // empty = terminal
  final Stats? stats;
  const DigimonSpecies({
    required this.id,
    required this.name,
    required this.tier,
    required this.biome,
    required this.sprite,
    required this.evolvesTo,
    this.stats,
  });

  factory DigimonSpecies.fromJson(String id, Map<String, dynamic> j) =>
      DigimonSpecies(
        id: id,
        name: j['name'] as String,
        tier: StageTier.values.byName(j['tier'] as String),
        biome: Biome.values.byName(j['biome'] as String),
        sprite: CreatureSprite.fromJson(j['sprite'] as Map<String, dynamic>),
        evolvesTo: ((j['evolvesTo'] as List?) ?? const [])
            .map((e) => Evolution.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        stats: j['stats'] == null
            ? null
            : Stats.fromJson(j['stats'] as Map<String, dynamic>),
      );
}

/// Immutable id->species lookup, built from the parsed species.json map.
class SpeciesRegistry {
  final Map<String, DigimonSpecies> _byId;
  const SpeciesRegistry(this._byId);

  factory SpeciesRegistry.fromJson(Map<String, dynamic> j) {
    final map = <String, DigimonSpecies>{};
    j.forEach((id, data) =>
        map[id] = DigimonSpecies.fromJson(id, data as Map<String, dynamic>));
    return SpeciesRegistry(map);
  }

  DigimonSpecies? lookup(String id) => _byId[id];
  DigimonSpecies operator [](String id) =>
      _byId[id] ?? (throw ArgumentError('Unknown species id: $id'));
  bool contains(String id) => _byId.containsKey(id);
  Iterable<String> get ids => _byId.keys;
}
