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
import 'map_background.dart';
import 'pet_component.dart';
import 'wander.dart';

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
  // The real biome map behind the pet (replaces the old procedural world).
  final MapBackgroundComponent mapBackground = MapBackgroundComponent();
  /// Drives the pet's idle ambling within the scene's walkable ground band.
  final WanderController wander = WanderController();
  Biome? _placedBiome;

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

    mapBackground.priority = -1; // behind everything
    await add(mapBackground);
    await mapBackground.applyBiome(currentBiome);

    petComponent.anchor = Anchor.bottomCenter;
    petComponent.priority = 10;
    // Attach to the tree before showFor(): PetComponent's HasGameReference
    // resolves `game` via the parent chain, which only exists once added.
    add(petComponent);
    _placeForBiome(initial: true);
    await petComponent.showFor(currentSpecies, sick: _isSick);
    petComponent.startIdlePulse();

    isReady = true;
    await _persistAndNotify();
  }

  /// Set the walkable band + ground height for the current biome. Keeps the
  /// pet's current x on a re-place (evolve/resize) so it doesn't teleport;
  /// [initial] centres it instead.
  void _placeForBiome({bool initial = false}) {
    final minX = size.x * 0.14;
    final maxX = size.x * 0.86;
    wander.setBand(minX, maxX, startX: initial ? size.x / 2 : null);
    petComponent.position =
        Vector2(wander.x, size.y * groundFractionForBiome(currentBiome));
    _placedBiome = currentBiome;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isReady && petComponent.isMounted) {
      _placeForBiome();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isReady || pet.isDead) return;

    // Per-frame life: amble along the ground (unless sick or mid-reaction) and
    // keep the sprite's loop + facing in sync with the motion.
    final sick = _isSick;
    if (!sick && !petComponent.isReacting) {
      wander.update(dt);
      petComponent.position.x = wander.x;
      petComponent.setFacing(wander.facing);
    }
    petComponent.setLoop(
      currentSpecies,
      sick ? CareAnim.sick : (wander.isWalking ? CareAnim.walk : CareAnim.idle),
    );

    // Once a second: advance needs/evolution; swap the map on a biome change.
    _accum += dt;
    if (_accum >= 1.0) {
      _accum = 0;
      pet = PetLogic.checkEvolution(
          PetLogic.applyElapsed(pet, nowMs()), nowMs(), _species);
      if (currentBiome != _placedBiome) {
        mapBackground.applyBiome(currentBiome); // no-op unless changed
        _placeForBiome();
      }
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
    await mapBackground.applyBiome(currentBiome);
    _placeForBiome(initial: true);
    await petComponent.showFor(currentSpecies, sick: _isSick);
    await _persistAndNotify();
  }
}
