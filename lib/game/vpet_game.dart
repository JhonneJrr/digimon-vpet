// lib/game/vpet_game.dart
import 'package:flame/cache.dart';
import 'package:flame/components.dart' show Anchor;
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import '../state/pet.dart';
import '../state/pet_logic.dart';
import '../state/pet_repository.dart';
import 'pet_component.dart';

/// Top-level Flame game: owns the [Pet] state, ticks it forward once per
/// second while running, persists it, and renders it via [PetComponent].
class VpetGame extends FlameGame {
  VpetGame({required this.repo, int Function()? clock})
    : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch) {
    // sprite_map.dart paths are relative to assets/ (e.g. "sprites/Botamon
    // .png"), not Flame's default "assets/images/" prefix, and this project
    // bundles them under assets/sprites/ + assets/ui/. Use a dedicated cache
    // (rather than mutating the global Flame.images) so this doesn't leak
    // across game instances or tests.
    images = Images(prefix: 'assets/');
  }

  final PetRepository repo;
  final int Function() _clock;
  final PetComponent petComponent = PetComponent();

  late Pet pet;
  double _accum = 0;
  bool _deathNotified = false;
  VoidCallback? onPetChanged;
  VoidCallback? onDeath;

  int nowMs() => _clock();

  @override
  Future<void> onLoad() async {
    final saved = await repo.load();
    pet = saved ?? Pet.newborn(nowMs());
    pet = PetLogic.checkEvolution(PetLogic.applyElapsed(pet, nowMs()), nowMs());
    petComponent.anchor = Anchor.center;
    petComponent.position = size / 2;
    // Attach to the tree before showFor(): PetComponent's HasGameReference
    // resolves `game` via the parent chain, which only exists once added.
    add(petComponent);
    await petComponent.showFor(pet);
    await _persistAndNotify();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (pet.isDead) return;
    _accum += dt;
    if (_accum >= 1.0) {
      _accum = 0;
      pet = PetLogic.checkEvolution(PetLogic.applyElapsed(pet, nowMs()), nowMs());
      petComponent.showFor(pet);
      _persistAndNotify();
    }
  }

  Future<void> _persistAndNotify() async {
    await repo.save(pet);
    onPetChanged?.call();
    // Only fire once per death: care-action button taps still reach _act()
    // for a dead pet (each PetLogic action is a no-op on it) and would
    // otherwise re-trigger navigation to DeathScreen on every tap.
    if (pet.isDead && !_deathNotified) {
      _deathNotified = true;
      onDeath?.call();
    } else if (!pet.isDead) {
      _deathNotified = false;
    }
  }

  Future<void> _act(Pet Function(Pet) action) async {
    pet = action(pet);
    await petComponent.showFor(pet);
    petComponent.reactBounce();
    await _persistAndNotify();
  }

  Future<void> feed() => _act(PetLogic.feed);
  Future<void> clean() => _act(PetLogic.clean);
  Future<void> medicine() => _act(PetLogic.giveMedicine);
  Future<void> play() => _act(PetLogic.play);

  Future<void> restart() async {
    pet = Pet.newborn(nowMs());
    await petComponent.showFor(pet);
    await _persistAndNotify();
  }
}
