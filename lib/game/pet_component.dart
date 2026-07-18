// lib/game/pet_component.dart
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;
import '../state/digimon_species.dart';

/// Renders the pet from the species' [CreatureSprite]. Two kinds of animation:
/// a looping *locomotion* state (idle / walk / sick) driven each frame by the
/// game, and one-shot *reactions* (eat / happy) that play once then return to
/// the current loop. Frames load by convention: `creatures/<id>/<state>_<i>.png`.
class PetComponent extends SpriteAnimationComponent with HasGameReference {
  String? _speciesId;
  CareAnim _loop = CareAnim.idle; // desired looping state
  CareAnim? _playing; // resolved state currently animating (null until first play)
  bool _reacting = false;
  int _facing = 1; // 1 = right, -1 = left (art faces right by default)
  double _scale = 1;
  int _loadGen = 0;

  /// True while a one-shot reaction is playing — the game pauses wandering.
  bool get isReacting => _reacting;

  /// Set the looping state (idle/walk/sick). Idempotent: a per-frame call in the
  /// steady state is a no-op, so it never restarts the loop or fights a reaction.
  Future<void> setLoop(DigimonSpecies species, CareAnim state) async {
    final resolved = species.sprite.resolve(state); // missing state -> idle
    final speciesChanged = species.id != _speciesId;
    if (!speciesChanged &&
        _loop == state &&
        _playing == resolved &&
        !_reacting &&
        animation != null) {
      return; // steady state
    }
    _speciesId = species.id;
    _loop = state;
    if (speciesChanged) {
      final idleImg = await game.images.load('creatures/${species.id}/idle_0.png');
      _scale = species.sprite.displayHeight / idleImg.height;
    }
    if (_reacting) return; // a reaction owns the sprite; it resumes _loop on finish
    await _playResolved(species, resolved, loop: true);
  }

  /// Convenience wrapper kept for existing callers: idle, or sick when unwell.
  Future<void> showFor(DigimonSpecies species, {required bool sick}) =>
      setLoop(species, sick ? CareAnim.sick : CareAnim.idle);

  /// Play a one-shot [reaction] (eat/happy), then fall back to the current loop.
  Future<void> playReaction(DigimonSpecies species, CareAnim reaction) async {
    _reacting = true;
    final resolved = species.sprite.resolve(reaction);
    await _playResolved(species, resolved, loop: false, onComplete: () {
      _reacting = false;
      if (species.id == _speciesId) {
        _playResolved(species, species.sprite.resolve(_loop), loop: true);
      }
    });
  }

  Future<void> _playResolved(DigimonSpecies species, CareAnim resolved,
      {required bool loop, void Function()? onComplete}) async {
    final gen = ++_loadGen;
    if (loop) _playing = resolved;
    final clip = species.sprite.clip(resolved);
    final sprites = <Sprite>[];
    for (var i = 0; i < clip.frameCount; i++) {
      final img =
          await game.images.load('creatures/${species.id}/${resolved.name}_$i.png');
      sprites.add(Sprite(img));
    }
    if (gen != _loadGen) return; // superseded
    if (sprites.isEmpty) return; // misconfigured species: fail safe
    animation = SpriteAnimation.spriteList(sprites, stepTime: clip.stepTime, loop: loop);
    size = sprites.first.srcSize * _scale;
    if (!loop && onComplete != null) {
      animationTicker?.onComplete = onComplete;
    }
  }

  /// Face [dir] (1 right, -1 left). Flips the sprite around its centre only when
  /// the direction actually changes (independent of the idle-pulse scale effect).
  void setFacing(int dir) {
    if (dir == 0 || dir == _facing) return;
    _facing = dir;
    flipHorizontallyAroundCenter();
  }

  /// Quick "press feedback" bounce: scale up then back down.
  void reactBounce() {
    add(ScaleEffect.by(
      Vector2.all(1.15),
      EffectController(
          duration: 0.1, reverseDuration: 0.1, curve: Curves.easeOut),
    ));
  }

  /// Gentle continuous "breathing" scale pulse so the pet reads as alive.
  void startIdlePulse() {
    add(ScaleEffect.by(
      Vector2.all(1.04),
      EffectController(
          duration: 0.9,
          reverseDuration: 0.9,
          infinite: true,
          curve: Curves.easeInOut),
    ));
  }
}
