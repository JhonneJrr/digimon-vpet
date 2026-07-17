// lib/game/sprite_map.dart
//
// Sprite sheet geometry and stage->sheet mapping.
//
// Verified against the actual assets (see .superpowers/sdd/sprite-mapping-
// verified.md): every sheet is 48x64px = 3 cols x 4 rows of 16x16 frames.
// Idle is reliably frames 0 and 1 across every stage; reaction frames differ
// per stage so they are intentionally NOT mapped here. Reaction feedback is
// instead a Flame effect on PetComponent (see reactBounce).
import '../state/pet.dart';

const int frameSize = 16;

/// Idle animation frame ids (cross-stage reliable).
const int idleFrameA = 0;
const int idleFrameB = 1;

String spriteSheetForStage(LifeStage stage) {
  switch (stage) {
    case LifeStage.baby1:
      return 'sprites/Botamon.png';
    case LifeStage.baby2:
      return 'sprites/Koromon.png';
    case LifeStage.child:
      return 'sprites/Agumon.png';
    case LifeStage.adult:
      return 'sprites/Greymon.png';
    case LifeStage.perfectMetal:
      return 'sprites/MetalGreymon.png';
    case LifeStage.perfectSkull:
      return 'sprites/SkullGreymon.png';
  }
}
