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
}
