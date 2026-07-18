import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/biome.dart';
import 'package:digimon/state/digimon_species.dart';

SpeciesRegistry loadSeed() => SpeciesRegistry.fromJson(
    jsonDecode(File('assets/data/species.json').readAsStringSync())
        as Map<String, dynamic>);

void main() {
  test('seed contains the full Botamon->SkullGreymon line', () {
    final reg = loadSeed();
    for (final id in const [
      'botamon', 'koromon', 'agumon', 'greymon', 'metalgreymon', 'skullgreymon'
    ]) {
      expect(reg.contains(id), true, reason: 'missing $id');
    }
  });

  test('line is fully reachable from botamon and reaches both ultimates', () {
    final reg = loadSeed();
    final reached = <String>{};
    final queue = <String>['botamon'];
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      if (!reached.add(id)) continue;
      for (final e in reg[id].evolvesTo) {
        expect(reg.contains(e.toId), true, reason: '${e.toId} not in registry');
        queue.add(e.toId);
      }
    }
    expect(reached, containsAll(['metalgreymon', 'skullgreymon']));
  });

  test('biomes preserve the pre-refactor mapping', () {
    final reg = loadSeed();
    expect(reg['botamon'].biome, Biome.nursery);
    expect(reg['koromon'].biome, Biome.meadow);
    expect(reg['agumon'].biome, Biome.jungle);
    expect(reg['greymon'].biome, Biome.savanna);
    expect(reg['metalgreymon'].biome, Biome.chrome);
    expect(reg['skullgreymon'].biome, Biome.wasteland);
  });

  test('greymon forks Metal (high care) vs Skull (low care)', () {
    final g = loadSeed()['greymon'];
    expect(g.evolvesTo.map((e) => e.toId),
        containsAll(['metalgreymon', 'skullgreymon']));
    expect(
        g.evolvesTo.firstWhere((e) => e.toId == 'metalgreymon').condition,
        EvoCondition.careScoreHigh);
    expect(
        g.evolvesTo.firstWhere((e) => e.toId == 'skullgreymon').condition,
        EvoCondition.careScoreLow);
  });

  test('each species sprite has idle and its frame counts match files on disk', () {
    final reg = loadSeed();
    const ids = ['botamon', 'koromon', 'agumon', 'greymon', 'metalgreymon', 'skullgreymon'];
    for (final id in ids) {
      final sprite = reg[id].sprite;
      expect(sprite.clip(CareAnim.idle).frameCount, greaterThan(0), reason: '$id idle');
      sprite.clips.forEach((state, clip) {
        for (var i = 0; i < clip.frameCount; i++) {
          final f = File('assets/creatures/$id/${state.name}_$i.png');
          expect(f.existsSync(), true, reason: 'missing ${f.path}');
        }
      });
    }
    // Botamon has no sick art -> resolves to idle.
    expect(reg['botamon'].sprite.resolve(CareAnim.sick), CareAnim.idle);
  });

  test('pet display heights are the rebalanced (smaller) values', () {
    final reg = loadSeed();
    expect(reg['botamon'].sprite.displayHeight, 45);
    expect(reg['koromon'].sprite.displayHeight, 57);
    expect(reg['agumon'].sprite.displayHeight, 68);
    expect(reg['greymon'].sprite.displayHeight, 99);
    expect(reg['metalgreymon'].sprite.displayHeight, 128);
    expect(reg['skullgreymon'].sprite.displayHeight, 125);
  });
}
