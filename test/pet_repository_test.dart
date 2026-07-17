import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digimon/state/pet.dart';
import 'package:digimon/state/pet_repository.dart';

void main() {
  test('save then load returns an equal pet', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsPetRepository();
    final pet = Pet.newborn(1234).copyWith(hunger: 2, careScore: 0.8);
    await repo.save(pet);
    final loaded = await repo.load();
    expect(loaded, isNotNull);
    expect(loaded!.hunger, 2);
    expect(loaded.careScore, 0.8);
    expect(loaded.stageStartedAtMs, 1234);
  });

  test('load returns null when nothing saved', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await PrefsPetRepository().load(), isNull);
  });
}
