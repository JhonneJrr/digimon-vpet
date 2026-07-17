// test/pet_component_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/game/pet_component.dart';
import 'package:digimon/state/pet.dart';

void main() {
  test('PetComponent constructs and accepts a pet', () {
    final c = PetComponent();
    // showFor loads images asynchronously in-game; here we just assert the
    // component and stage-selection wiring exist and don't throw.
    expect(() => c.stageOf(Pet.newborn(0)), returnsNormally);
    expect(c.stageOf(Pet.newborn(0)), LifeStage.baby1);
  });
}
