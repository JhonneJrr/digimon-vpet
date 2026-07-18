// lib/game/vpet_game.dart
import 'dart:convert';
import 'dart:ui' show Color;
import 'package:flame/cache.dart';
import 'package:flame/components.dart' show Anchor, Vector2;
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../state/biome.dart';
import '../state/digimon_species.dart';
import '../state/pet.dart';
import '../state/pet_logic.dart';
import '../state/pet_repository.dart';
import 'biome_palette.dart';
import 'pet_component.dart';
import 'world_background.dart';

/// Top-level Flame game: owns the [Pet] state, ticks it forward once per
/// second while running, persists it, and renders it via [PetComponent].
class VpetGame extends FlameGame {
  VpetGame({required this.repo, int Function()? clock})
    : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch) {
    // PetComponent loads creature animation frames by convention
    // (creatures/<speciesId>/<state>_<i>.png) via game.images, relative to
    // assets/ (not Flame's default "assets/images/" prefix). Use a dedicated
    // cache (rather than mutating the global Flame.images) so this doesn't
    // leak across game instances or tests.
    images = Images(prefix: 'assets/');
  }

  final PetRepository repo;
  final int Function() _clock;
  final PetComponent petComponent = PetComponent();
  // Named `worldBackground`, not `world`: FlameGame already defines a `world`
  // member (the camera's `World` component), and this is a plain background
  // component, not a Flame `World` subclass.
  final WorldBackground worldBackground = WorldBackground();

  late Pet pet;

  late SpeciesRegistry _species;

  /// The current pet's species; falls back to the line start if a save
  /// references an unknown id.
  DigimonSpecies get currentSpecies =>
      _species.lookup(pet.speciesId) ?? _species['botamon'];

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

  Biome get currentBiome => currentSpecies.biome;

  bool get _isSick => pet.health == HealthStatus.sick;

  @override
  Color backgroundColor() => const Color(0xFF9BBC0F); // LCD green, matches UI

  @override
  Future<void> onLoad() async {
    final saved = await repo.load();
    final jsonStr = await rootBundle.loadString('assets/data/species.json');
    _species = SpeciesRegistry.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>);
    pet = saved ?? Pet.newborn(nowMs());
    if (!_species.contains(pet.speciesId)) {
      // Corrupt/removed species id: fall back to the line start AND reset the
      // stage clock — otherwise a stale stageStartedAtMs would instant-cascade
      // the freshly-reset Botamon through every stage on the next check.
      debugPrint(
          'VpetGame: unknown speciesId "${pet.speciesId}" -> reset to botamon');
      pet = pet.copyWith(speciesId: 'botamon', stageStartedAtMs: nowMs());
    }
    pet = PetLogic.checkEvolution(
        PetLogic.applyElapsed(pet, nowMs()), nowMs(), _species);

    worldBackground.priority = -1; // behind everything
    await add(worldBackground);
    worldBackground.applyPalette(paletteForBiome(currentBiome));

    petComponent.anchor = Anchor.bottomCenter;
    petComponent.position = _petFootPosition();
    petComponent.priority = 10;
    // Attach to the tree before showFor(): PetComponent's HasGameReference
    // resolves `game` via the parent chain, which only exists once added.
    add(petComponent);
    await petComponent.showFor(currentSpecies, sick: _isSick);
    petComponent.startIdlePulse();

    isReady = true;
    await _persistAndNotify();
  }

  /// The pet's feet rest just above the ground horizon line.
  Vector2 _petFootPosition() =>
      Vector2(size.x / 2, size.y * (1 - groundTopFraction) + 6);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (petComponent.isMounted) {
      petComponent.position = _petFootPosition();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (pet.isDead) return;
    _accum += dt;
    if (_accum >= 1.0) {
      _accum = 0;
      pet = PetLogic.checkEvolution(
          PetLogic.applyElapsed(pet, nowMs()), nowMs(), _species);
      worldBackground.applyPalette(paletteForBiome(currentBiome));
      petComponent.showFor(currentSpecies, sick: _isSick);
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

  Future<void> _act(Pet Function(Pet, int) action, {CareAnim? reaction}) async {
    pet = action(pet, nowMs());
    if (reaction != null) {
      await petComponent.playReaction(currentSpecies, reaction);
    } else {
      await petComponent.showFor(currentSpecies, sick: _isSick);
    }
    petComponent.reactBounce();
    await _persistAndNotify();
  }

  Future<void> feed() => _act(PetLogic.feed, reaction: CareAnim.eat);
  Future<void> clean() => _act(PetLogic.clean);
  Future<void> medicine() => _act(PetLogic.giveMedicine);
  Future<void> play() => _act(PetLogic.play, reaction: CareAnim.happy);

  Future<void> restart() async {
    pet = Pet.newborn(nowMs());
    worldBackground.applyPalette(paletteForBiome(currentBiome));
    await petComponent.showFor(currentSpecies, sick: _isSick);
    await _persistAndNotify();
  }
}
