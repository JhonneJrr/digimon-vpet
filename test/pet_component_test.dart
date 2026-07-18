// test/pet_component_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/game/pet_component.dart';

void main() {
  test('PetComponent constructs; exposes the species-driven animation API', () {
    // Real rendering needs a mounted game + assets (verified on-device), so here
    // we only assert the component and its new API surface exist and don't throw.
    final c = PetComponent();
    expect(c, isNotNull);
    expect(c.showFor, isA<Function>());
    expect(c.playReaction, isA<Function>());
  });
}
