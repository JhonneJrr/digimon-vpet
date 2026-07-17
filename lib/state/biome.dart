import 'pet.dart';

/// Ambient world theme shown behind the pet.
///
/// Currently derived 1:1 from the life stage, but modeled as its own concept
/// so a future location/movement mechanic can drive it without touching any
/// rendering code (this function is the only seam that would change).
enum Biome { nursery, meadow, jungle, savanna, chrome, wasteland }

Biome biomeForStage(LifeStage stage) {
  switch (stage) {
    case LifeStage.baby1:
      return Biome.nursery;
    case LifeStage.baby2:
      return Biome.meadow;
    case LifeStage.child:
      return Biome.jungle;
    case LifeStage.adult:
      return Biome.savanna;
    case LifeStage.perfectMetal:
      return Biome.chrome;
    case LifeStage.perfectSkull:
      return Biome.wasteland;
  }
}
