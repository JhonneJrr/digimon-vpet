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
        'displayHeight': 96,
        'states': {
          'idle': {'frames': 6, 'stepTime': 0.25, 'loop': true},
          'eat': {'frames': 2, 'stepTime': 0.2, 'loop': false},
          'happy': {'frames': 2, 'stepTime': 0.2, 'loop': false},
          'sick': {'frames': 1, 'stepTime': 0.4, 'loop': true},
        },
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
    expect(s.sprite.displayHeight, 96);
    expect(s.sprite.clip(CareAnim.idle).frameCount, 6);
    expect(s.sprite.clip(CareAnim.idle).loop, true);
    expect(s.sprite.clip(CareAnim.eat).frameCount, 2);
    expect(s.sprite.clip(CareAnim.eat).loop, false);
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

  test('Evolution round-trip through toJson', () {
    final e = Evolution.fromJson(
        {'toId': 'x', 'afterMs': 10, 'condition': 'careScoreHigh'});
    expect(Evolution.fromJson(e.toJson()).condition, EvoCondition.careScoreHigh);
  });

  test('CreatureSprite.resolve falls back to idle for a missing state', () {
    final s = CreatureSprite.fromJson({
      'displayHeight': 40,
      'states': {
        'idle': {'frames': 8, 'stepTime': 0.25, 'loop': true},
        'eat': {'frames': 2, 'stepTime': 0.2, 'loop': false},
      },
    });
    expect(s.resolve(CareAnim.sick), CareAnim.idle); // no sick -> idle
    expect(s.clip(CareAnim.sick).frameCount, 8); // returns the idle clip
    expect(s.resolve(CareAnim.eat), CareAnim.eat); // present -> itself
  });

  test('CreatureSprite.fromJson requires an idle state', () {
    expect(
      () => CreatureSprite.fromJson({
        'displayHeight': 40,
        'states': {
          'eat': {'frames': 2, 'stepTime': 0.2, 'loop': false},
        },
      }),
      throwsArgumentError,
    );
  });
}
