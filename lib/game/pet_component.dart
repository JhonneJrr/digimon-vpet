// lib/game/pet_component.dart
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;
import '../state/digimon_species.dart';

/// Renders the pet as a per-care-state animation built from the species'
/// [CreatureSprite]. A looping base state (idle, or sick when unwell) plus
/// one-shot eat/happy reactions. Frame images are loaded by convention:
/// `creatures/<speciesId>/<state>_<i>.png`.
class PetComponent extends SpriteAnimationComponent with HasGameReference {
  String? _speciesId;
  CareAnim _base = CareAnim.idle;
  double _scale = 1;
  int _loadGen = 0;

  /// Show [species] at its base state (sick loop if [sick], else idle loop).
  /// No-op when species AND base are unchanged, so a per-tick call never
  /// interrupts a running reaction or restarts the loop.
  Future<void> showFor(DigimonSpecies species, {required bool sick}) async {
    final desiredBase = sick ? CareAnim.sick : CareAnim.idle;
    if (species.id == _speciesId && desiredBase == _base && animation != null) {
      return; // steady state
    }
    final speciesChanged = species.id != _speciesId;
    _speciesId = species.id;
    _base = desiredBase;
    if (speciesChanged) {
      final idleImg = await game.images.load('creatures/${species.id}/idle_0.png');
      _scale = species.sprite.displayHeight / idleImg.height;
    }
    await _play(species, _base);
  }

  /// Play a one-shot [reaction] (e.g. eat/happy), then return to the base state.
  Future<void> playReaction(DigimonSpecies species, CareAnim reaction) =>
      _play(species, reaction, oneShotThenBase: true);

  Future<void> _play(DigimonSpecies species, CareAnim state,
      {bool oneShotThenBase = false}) async {
    final gen = ++_loadGen;
    final eff = species.sprite.resolve(state);
    final clip = species.sprite.clip(state);
    final sprites = <Sprite>[];
    for (var i = 0; i < clip.frameCount; i++) {
      final img = await game.images.load('creatures/${species.id}/${eff.name}_$i.png');
      sprites.add(Sprite(img));
    }
    if (gen != _loadGen) return; // a newer _play superseded us
    final loop = oneShotThenBase ? false : clip.loop;
    animation =
        SpriteAnimation.spriteList(sprites, stepTime: clip.stepTime, loop: loop);
    size = sprites.first.srcSize * _scale;
    if (oneShotThenBase) {
      // When the one-shot finishes, fall back to the current base state.
      animationTicker?.onComplete = () => _play(species, _base);
    }
  }

  /// Quick "press feedback" bounce: scale up then back down.
  void reactBounce() {
    add(
      ScaleEffect.by(
        Vector2.all(1.15),
        EffectController(
            duration: 0.1, reverseDuration: 0.1, curve: Curves.easeOut),
      ),
    );
  }

  /// Gentle continuous "breathing" scale pulse so the pet reads as alive.
  void startIdlePulse() {
    add(
      ScaleEffect.by(
        Vector2.all(1.04),
        EffectController(
            duration: 0.9,
            reverseDuration: 0.9,
            infinite: true,
            curve: Curves.easeInOut),
      ),
    );
  }
}
