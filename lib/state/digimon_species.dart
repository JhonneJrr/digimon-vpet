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

/// Sprite-sheet geometry as data (replaces the old const frameSize + hardcoded
/// idle frames), so a species can carry differently-sized frames.
class SpriteRef {
  final String sheet; // asset path relative to assets/, e.g. "sprites/Agumon.png"
  final int frameWidth, frameHeight, columns, rows;
  final List<int> idleFrames;
  final double stepTime;
  const SpriteRef({
    required this.sheet,
    required this.frameWidth,
    required this.frameHeight,
    required this.columns,
    required this.rows,
    required this.idleFrames,
    required this.stepTime,
  });

  factory SpriteRef.fromJson(Map<String, dynamic> j) => SpriteRef(
        sheet: j['sheet'] as String,
        frameWidth: j['frameWidth'] as int,
        frameHeight: j['frameHeight'] as int,
        columns: j['columns'] as int,
        rows: j['rows'] as int,
        idleFrames:
            (j['idleFrames'] as List).map((e) => e as int).toList(growable: false),
        stepTime: (j['stepTime'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'sheet': sheet,
        'frameWidth': frameWidth,
        'frameHeight': frameHeight,
        'columns': columns,
        'rows': rows,
        'idleFrames': idleFrames,
        'stepTime': stepTime,
      };
}

class DigimonSpecies {
  final String id;
  final String name;
  final StageTier tier;
  final Biome biome;
  final SpriteRef sprite;
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
        sprite: SpriteRef.fromJson(j['sprite'] as Map<String, dynamic>),
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
