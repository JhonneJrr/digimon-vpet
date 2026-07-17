import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/state/game_config.dart';

void main() {
  test('happinessWarnThreshold is a low, in-range value', () {
    expect(GameConfig.happinessWarnThreshold, greaterThanOrEqualTo(0));
    expect(GameConfig.happinessWarnThreshold,
        lessThan(GameConfig.happinessMax));
  });
}
