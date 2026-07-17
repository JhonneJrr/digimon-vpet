// lib/game/vpet_game.dart
import 'dart:ui' show Color;
import 'package:flame/cache.dart';
import 'package:flame/components.dart' show Anchor, Vector2;
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

  /// True once [onLoad] has initialised [pet]. The UI gates its care buttons
  /// on this so a tap before load can't read the `late` field and throw.
  /// (Named `isReady`, not `loaded` — Flame's Component already defines a
  /// `loaded` Future.)
  bool isReady = false;

  double _accum = 0;
  bool _deathNotified = false;
  // Serialises writes: without this, un-awaited saves from update() and button
  // taps could complete out of order and persist a stale snapshot.
  Future<void> _saveChain = Future<void>.value();
  VoidCallback? onPetChanged;
  VoidCallback? onDeath;

  int nowMs() => _clock();

  @override
  Color backgroundColor() => const Color(0xFF9BBC0F); // LCD green, matches UI

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
    isReady = true;
    await _persistAndNotify();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Keep the pet centred across rotation / window-size changes.
    if (petComponent.isMounted) {
      petComponent.position = size / 2;
    }
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

  Future<void> _persistAndNotify() {
    // Snapshot now, then queue the save behind any in-flight one so writes
    // land in issue order and never clobber a newer state with an older one.
    final snapshot = pet;
    final save = _saveChain.then((_) => repo.save(snapshot));
    _saveChain = save.catchError((_) {}); // a failed save must not break the chain
    onPetChanged?.call();
    // Only fire once per death: care-action button taps still reach _act()
    // for a dead pet (each PetLogic action is a no-op on it) and would
    // otherwise re-trigger navigation to DeathScreen on every tap.
    if (snapshot.isDead && !_deathNotified) {
      _deathNotified = true;
      onDeath?.call();
    } else if (!snapshot.isDead) {
      _deathNotified = false;
    }
    return save;
  }

  Future<void> _act(Pet Function(Pet, int) action) async {
    pet = action(pet, nowMs());
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
