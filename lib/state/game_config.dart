// lib/state/game_config.dart
import 'pet.dart';

class GameConfig {
  /// Master multiplier. >1 = faster. Accelerated pace for this build.
  static const double gameSpeed = 12.0;

  static const int hungerMax = 4;
  static const int happinessMax = 4;

  // Base (real-time) rates, divided by gameSpeed to accelerate.
  static int get msPerHungerPoint => (60 * 1000 ~/ gameSpeed);   // hunger +1
  static int get msPerHappinessDrop => (90 * 1000 ~/ gameSpeed); // happiness -1
  static int get msPerPoop => (75 * 1000 ~/ gameSpeed);          // +1 poop

  // Neglect -> sick after this long at max hunger OR with poop uncleaned.
  static int get sickTimeoutMs => (120 * 1000 ~/ gameSpeed);
  // Sick + untreated OR starving this long after sick -> death.
  static int get deathTimeoutMs => (180 * 1000 ~/ gameSpeed);

  static const double careScoreThreshold = 0.6;

  static Map<LifeStage, int> get stageDurationMs => {
        LifeStage.baby1: (60 * 1000 ~/ gameSpeed).round(),
        LifeStage.baby2: (5 * 60 * 1000 ~/ gameSpeed).round(),
        LifeStage.child: (15 * 60 * 1000 ~/ gameSpeed).round(),
        LifeStage.adult: (20 * 60 * 1000 ~/ gameSpeed).round(),
      };
}
