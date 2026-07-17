// lib/ui/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/vpet_game.dart';
import '../state/pet.dart';
import '../state/pet_repository.dart';
import 'death_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final VpetGame game;

  @override
  void initState() {
    super.initState();
    game = VpetGame(repo: PrefsPetRepository())
      ..onPetChanged = () {
        if (mounted) setState(() {});
      }
      ..onDeath = _goToDeath;
  }

  void _goToDeath() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeathScreen(
          onRestart: () async {
            await game.restart();
            if (mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9BBC0F), // vpet-green LCD vibe
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  GameWidget(game: game),
                  _statusIcons(),
                ],
              ),
            ),
            _buttonRow(),
          ],
        ),
      ),
    );
  }

  Widget _statusIcons() {
    // game.pet is `late` and only set once onLoad completes; guard against
    // reading it during the first build.
    Pet? p;
    try {
      p = game.pet;
    } catch (_) {
      p = null;
    }
    if (p == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          if (p.hunger >= 3) Image.asset('assets/ui/hunger.png', width: 24),
          if (p.poopCount > 0) Image.asset('assets/ui/poop.png', width: 24),
          if (p.health == HealthStatus.sick)
            Image.asset('assets/ui/skull.png', width: 24),
        ],
      ),
    );
  }

  Widget _buttonRow() => Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _btn('assets/ui/food.png', game.feed),
            _btn('assets/ui/clean.png', game.clean),
            _btn('assets/ui/medicine.png', game.medicine),
            _btn('assets/ui/heart.png', game.play),
          ],
        ),
      );

  Widget _btn(String asset, Future<void> Function() onTap) => IconButton(
        iconSize: 40,
        onPressed: () => onTap(),
        icon: Image.asset(
          asset,
          width: 40,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.circle_outlined),
        ),
      );
}
