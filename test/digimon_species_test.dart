import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/biome.dart';
import 'package:digimon/state/digimon_species.dart';

void main() {
  final json = {
    'agumon': {
      'name': 'Agumon',
      'tier': 'rookie',
      'biome': 'jungle',
      'sprite': {
        'sheet': 'sprites/Agumon.png',
        'frameWidth': 16, 'frameHeight': 16, 'columns': 3, 'rows': 4,
        'idleFrames': [0, 1], 'stepTime': 0.5,
      },
      'evolvesTo': [
        {'toId': 'greymon', 'afterMs': 75000, 'condition': 'always'},
      ],
    },
  };

  test('DigimonSpecies.fromJson parses all fields', () {
    final s = DigimonSpecies.fromJson('agumon', json['agumon']!);
    expect(s.id, 'agumon');
    expect(s.name, 'Agumon');
    expect(s.tier, StageTier.rookie);
    expect(s.biome, Biome.jungle);
    expect(s.sprite.sheet, 'sprites/Agumon.png');
    expect(s.sprite.frameWidth, 16);
    expect(s.sprite.idleFrames, [0, 1]);
    expect(s.sprite.stepTime, 0.5);
    expect(s.evolvesTo.single.toId, 'greymon');
    expect(s.evolvesTo.single.afterMs, 75000);
    expect(s.evolvesTo.single.condition, EvoCondition.always);
    expect(s.stats, isNull);
  });

  test('SpeciesRegistry lookup, operator[], contains', () {
    final reg = SpeciesRegistry.fromJson(json);
    expect(reg.contains('agumon'), true);
    expect(reg.lookup('agumon')!.name, 'Agumon');
    expect(reg.lookup('nope'), isNull);
    expect(reg['agumon'].id, 'agumon');
    expect(() => reg['nope'], throwsArgumentError);
    expect(reg.ids, contains('agumon'));
  });

  test('Evolution / SpriteRef round-trip through toJson', () {
    final e = Evolution.fromJson(
        {'toId': 'x', 'afterMs': 10, 'condition': 'careScoreHigh'});
    expect(Evolution.fromJson(e.toJson()).condition, EvoCondition.careScoreHigh);
    final sr = SpriteRef.fromJson(json['agumon']!['sprite'] as Map<String, dynamic>);
    expect(SpriteRef.fromJson(sr.toJson()).columns, 3);
  });
}
