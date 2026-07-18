import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/game/map_background.dart';
import 'package:digimon/state/biome.dart';

void main() {
  test('every biome maps to a game/backgrounds asset', () {
    for (final b in Biome.values) {
      final a = mapAssetForBiome(b);
      expect(a, startsWith('game/backgrounds/biome_'));
      expect(a, endsWith('.png'));
    }
  });
  test('mapping is distinct per biome', () {
    final all = Biome.values.map(mapAssetForBiome).toSet();
    expect(all.length, Biome.values.length);
  });
}
