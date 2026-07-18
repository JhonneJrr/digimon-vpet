// test/vpet_game_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:digimon/game/vpet_game.dart';
import 'package:digimon/state/biome.dart';
import 'package:digimon/state/pet.dart';
import 'package:digimon/state/pet_repository.dart';

/// In-memory PetRepository fake — deterministic, no shared_preferences.
class _FakeRepo implements PetRepository {
  Pet? stored;

  @override
  Future<Pet?> load() async => stored;

  @override
  Future<void> save(Pet pet) async => stored = pet;

  @override
  Future<void> clear() async => stored = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('feed() lowers game.pet.hunger and persists it', () async {
    var fakeNow = 0;
    final repo = _FakeRepo()
      ..stored = Pet.newborn(0).copyWith(hunger: 2, careScore: 0.5);
    final game = VpetGame(repo: repo, clock: () => fakeNow);

    // Mirror what GameWidget does: size the canvas, then load.
    game.onGameResize(Vector2(400, 600));
    await game.onLoad();

    expect(game.pet.hunger, 2);

    await game.feed();

    expect(game.pet.hunger, 1);
    expect(repo.stored?.hunger, 1, reason: 'feed() should persist via repo');
  });

  test('isReady flag is false before onLoad and true after', () async {
    final game = VpetGame(repo: _FakeRepo(), clock: () => 0);
    expect(game.isReady, false);
    game.onGameResize(Vector2(400, 600));
    await game.onLoad();
    expect(game.isReady, true);
  });

  test('persisted state stays consistent after rapid un-awaited actions',
      () async {
    var fakeNow = 0;
    final repo = _FakeRepo()..stored = Pet.newborn(0).copyWith(hunger: 4);
    final game = VpetGame(repo: repo, clock: () => fakeNow);
    game.onGameResize(Vector2(400, 600));
    await game.onLoad();

    // Fire several feeds without awaiting each; serialized saves must leave
    // the persisted state equal to the final in-memory state (no stale write).
    await Future.wait([game.feed(), game.feed(), game.feed()]);

    expect(game.pet.hunger, 1);
    expect(repo.stored?.hunger, game.pet.hunger);
  });

  test('restart() resets to a fresh newborn pet', () async {
    var fakeNow = 1000;
    final repo = _FakeRepo()
      ..stored = Pet.newborn(0).copyWith(hunger: 3, isDead: true);
    final game = VpetGame(repo: repo, clock: () => fakeNow);
    game.onGameResize(Vector2(400, 600));
    await game.onLoad();
    expect(game.pet.isDead, true);

    await game.restart();

    expect(game.pet.isDead, false);
    expect(game.pet.hunger, 0);
    expect(game.pet.speciesId, 'botamon');
  });

  test('world is present and pet stands on the ground line after load', () async {
    final game = VpetGame(repo: _FakeRepo(), clock: () => 0);
    // Mirror exactly what GameWidget's loader does (game_widget.dart):
    // resize -> load -> mount -> first update(0). Without `mount()`, the
    // root itself is never marked mounted, so children added during
    // onLoad() stay staged and Flame's own component-tree walk visits them
    // (and their nested effects) before their onMount() has run.
    game.onGameResize(Vector2(400, 600));
    await game.onLoad();
    // `mount()` is @internal to Flame; GameWidget calls it in exactly this
    // spot (game_widget.dart) and there's no public substitute for a
    // headless test that needs the tree actually mounted (not just staged).
    // ignore: invalid_use_of_internal_member
    game.mount();
    game.update(0);
    expect(game.mapBackground.isMounted, isTrue);
    expect(game.currentBiome, Biome.nursery); // newborn = baby1
    // Pet anchored to its feet, below vertical center (on the ground band).
    expect(game.petComponent.position.y, greaterThan(game.size.y / 2));
  });

  test('pet anchor getters expose fractional position after load', () async {
    final game = VpetGame(repo: _FakeRepo(), clock: () => 0);
    game.onGameResize(Vector2(400, 600));
    await game.onLoad();
    // Newborn = Botamon in the nursery biome (ground fraction 0.78).
    expect(game.petGroundFraction, 0.78);
    // Botamon displayHeight 45 over a 600-tall stage.
    expect(game.petHeightFraction, closeTo(45 / 600, 1e-9));
    expect(game.petAnchorXFraction, inInclusiveRange(0.0, 1.0));
  });

  test('careMenuOpen pauses the pet wander (position x holds)', () async {
    final game = VpetGame(repo: _FakeRepo(), clock: () => 0);
    game.onGameResize(Vector2(400, 600));
    await game.onLoad();
    // ignore: invalid_use_of_internal_member
    game.mount();
    game.update(0);
    game.careMenuOpen = true;
    final x0 = game.petComponent.position.x;
    for (var i = 0; i < 30; i++) {
      game.update(0.5);
    }
    expect(game.petComponent.position.x, x0,
        reason: 'wander must not advance while the care menu is open');
  });

  test('petAnchorX notifier tracks petAnchorXFraction after wander moves',
      () async {
    final game = VpetGame(repo: _FakeRepo(), clock: () => 0);
    game.onGameResize(Vector2(400, 600));
    await game.onLoad();
    // ignore: invalid_use_of_internal_member
    game.mount();
    game.update(0);
    for (var i = 0; i < 30; i++) {
      game.update(0.5);
    }
    expect(game.petAnchorX.value, game.petAnchorXFraction,
        reason: 'the per-frame anchor notifier must stay in sync with the '
            'fractional getter used to position the tap hitbox');
    expect(game.petAnchorX.value, inInclusiveRange(0.0, 1.0));
  });
}
