// lib/game/pet_component.dart
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/animation.dart' show Curves;
import '../state/pet.dart';
import 'sprite_map.dart';

/// Renders the pet's current life stage as a looping 2-frame idle animation
/// and provides a quick scale-bounce for button-press feedback (the reaction
/// frames differ per stage sheet so they are not used — see
/// sprite-mapping-verified.md).
class PetComponent extends SpriteAnimationComponent with HasGameReference {
  LifeStage? _currentStage;
  int _loadGen = 0;

  LifeStage stageOf(Pet pet) => pet.stage;

  Future<void> showFor(Pet pet) async {
    if (_currentStage == pet.stage && animation != null) return;
    final gen = ++_loadGen;
    final image = await game.images.load(spriteSheetForStage(pet.stage));
    // If another showFor started while we awaited the image load, its result
    // is newer — drop ours so we never strand a stale sprite.
    if (gen != _loadGen) return;
    _currentStage = pet.stage;
    final sheet = SpriteSheet(
      image: image,
      srcSize: Vector2.all(frameSize.toDouble()),
    );
    animation = SpriteAnimation.spriteList(
      [sheet.getSpriteById(idleFrameA), sheet.getSpriteById(idleFrameB)],
      stepTime: 0.5,
    );
    size = Vector2.all(frameSize.toDouble() * 6); // scale up for phone screen
  }

  /// Quick "press feedback" bounce: scale up then back down.
  void reactBounce() {
    add(
      ScaleEffect.by(
        Vector2.all(1.15),
        EffectController(
          duration: 0.1,
          reverseDuration: 0.1,
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  /// Gentle continuous "breathing" — a subtle scale pulse, so the pet reads as
  /// alive while the world scrolls under it. Scale-based (not position-based)
  /// so it never fights VpetGame's centering/ground placement.
  void startIdlePulse() {
    add(
      ScaleEffect.by(
        Vector2.all(1.04),
        EffectController(
          duration: 0.9,
          reverseDuration: 0.9,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }
}
