import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/game/wander.dart';

void main() {
  test('ambles toward the target and faces the travel direction (right)', () {
    final w = WanderController(
        speed: 100, pauseMin: 1, pauseMax: 1, rng: () => 0.9);
    w.setBand(0, 100, startX: 50);
    w.update(1.0); // end the initial pause, pick target = 90
    expect(w.facing, 1);
    w.update(0.1); // step 10 -> x 60
    expect(w.x, closeTo(60, 1e-6));
    expect(w.isWalking, isTrue);
    for (var i = 0; i < 10; i++) {
      w.update(0.1); // reach 90
    }
    expect(w.x, closeTo(90, 1e-6));
    expect(w.isWalking, isFalse); // arrived -> pausing
  });

  test('walks left when the target is behind it', () {
    final w = WanderController(
        speed: 100, pauseMin: 1, pauseMax: 1, rng: () => 0.1);
    w.setBand(0, 100, startX: 50);
    w.update(1.0); // target = 10
    expect(w.facing, -1);
  });

  test('a degenerate band never walks', () {
    final w = WanderController();
    w.setBand(50, 50);
    w.update(1.0);
    w.update(1.0);
    expect(w.isWalking, isFalse);
  });

  test('stays within the band', () {
    final w = WanderController(speed: 1000, rng: () => 1.0);
    w.setBand(10, 90, startX: 50);
    for (var i = 0; i < 50; i++) {
      w.update(0.1);
      expect(w.x, inInclusiveRange(10, 90));
    }
  });
}
