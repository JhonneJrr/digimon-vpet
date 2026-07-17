import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/biome.dart';
import 'package:digimon/state/pet.dart';

void main() {
  test('every life stage maps to its biome', () {
    expect(biomeForStage(LifeStage.baby1), Biome.nursery);
    expect(biomeForStage(LifeStage.baby2), Biome.meadow);
    expect(biomeForStage(LifeStage.child), Biome.jungle);
    expect(biomeForStage(LifeStage.adult), Biome.savanna);
    expect(biomeForStage(LifeStage.perfectMetal), Biome.chrome);
    expect(biomeForStage(LifeStage.perfectSkull), Biome.wasteland);
  });

  test('biomeForStage is total over LifeStage (no throw for any value)', () {
    for (final s in LifeStage.values) {
      expect(() => biomeForStage(s), returnsNormally);
    }
  });
}
