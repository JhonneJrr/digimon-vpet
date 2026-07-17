import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/biome.dart';
import 'package:digimon/game/biome_palette.dart';

void main() {
  test('every biome has a palette', () {
    for (final b in Biome.values) {
      expect(() => paletteForBiome(b), returnsNormally);
    }
  });

  test('accents are distinct enough to read as different biomes', () {
    final accents = Biome.values.map((b) => paletteForBiome(b).accent).toSet();
    expect(accents.length, Biome.values.length); // no two biomes share an accent
  });
}
