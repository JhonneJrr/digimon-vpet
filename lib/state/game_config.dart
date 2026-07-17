// lib/state/game_config.dart
import 'pet.dart';

class GameConfig {
  /// Master multiplier. >1 = faster. Accelerated pace for this build.
  static const double gameSpeed = 12.0;

  static const int hungerMax = 4;
  static const int happinessMax = 4;

  // Base (real-time) rates, divided by gameSpeed to accelerate.
  static int get msPerHungerPoint => (60 * 1000 ~/ gameSpeed); // hunger +1
  static int get msPerHappinessDrop => (90 * 1000 ~/ gameSpeed); // happiness -1
  static int get msPerPoop => (75 * 1000 ~/ gameSpeed); // +1 poop

  /// Poop count at/above which the pet counts as living in filth.
  static const int messPoopThreshold = 3;

  // Neglect (max hunger OR filth) must persist this long before sickness.
  static int get sickTimeoutMs => (120 * 1000 ~/ gameSpeed);
  // Sick + untreated this long -> death.
  static int get deathTimeoutMs => (180 * 1000 ~/ gameSpeed);

  // careScore movement. Care actions raise it; neglect lowers it, so the
  // Metal (well-cared) vs Skull (neglected) branch is actually reachable.
  static const double careScoreThreshold = 0.6;
  static const double careBumpFeed = 0.05;
  static const double careBumpClean = 0.05;
  static const double careBumpPlay = 0.05;
  static const double careBumpMedicine = 0.10;
  static const double careDecayPerHungerPoint = 0.02; // per hunger point risen
  static const double careDecayPerPoop = 0.03; // per new poop that appears
  static const double careDecayOnSick = 0.15; // one-off when sickness onsets

  static Map<LifeStage, int> get stageDurationMs => {
        LifeStage.baby1: (60 * 1000 ~/ gameSpeed).round(),
        LifeStage.baby2: (5 * 60 * 1000 ~/ gameSpeed).round(),
        LifeStage.child: (15 * 60 * 1000 ~/ gameSpeed).round(),
        LifeStage.adult: (20 * 60 * 1000 ~/ gameSpeed).round(),
      };
}
