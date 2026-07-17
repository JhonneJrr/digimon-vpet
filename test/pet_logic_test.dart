import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/pet.dart';

void main() {
  test('Pet JSON round-trips', () {
    final p = Pet.newborn(1000).copyWith(hunger: 3, careScore: 0.7);
    final back = Pet.fromJson(p.toJson());
    expect(back.hunger, 3);
    expect(back.careScore, 0.7);
    expect(back.stage, LifeStage.baby1);
    expect(back.stageStartedAtMs, 1000);
  });
}
