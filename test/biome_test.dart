import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/biome.dart';
import 'package:digimon/state/digimon_species.dart';

void main() {
  test('each species carries its biome (mapping preserved)', () {
    final reg = SpeciesRegistry.fromJson(
        jsonDecode(File('assets/data/species.json').readAsStringSync())
            as Map<String, dynamic>);
    expect(reg['botamon'].biome, Biome.nursery);
    expect(reg['koromon'].biome, Biome.meadow);
    expect(reg['agumon'].biome, Biome.jungle);
    expect(reg['greymon'].biome, Biome.savanna);
    expect(reg['metalgreymon'].biome, Biome.chrome);
    expect(reg['skullgreymon'].biome, Biome.wasteland);
  });
}
