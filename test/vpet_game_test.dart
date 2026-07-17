// test/vpet_game_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:digimon/game/vpet_game.dart';
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
    expect(game.pet.stage, LifeStage.baby1);
  });
}
