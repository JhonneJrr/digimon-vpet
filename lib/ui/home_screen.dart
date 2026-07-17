// lib/ui/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/vpet_game.dart';
import '../state/notifications.dart';
import '../state/pet.dart';
import '../state/pet_repository.dart';
import 'death_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final VpetGame game;
  final Notifications _notifications = Notifications();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifications.init();
    game = VpetGame(repo: PrefsPetRepository())
      ..onPetChanged = () {
        if (mounted) setState(() {});
      }
      ..onDeath = _goToDeath;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _notifications.scheduleNeedsYou();
        break;
      case AppLifecycleState.resumed:
        _notifications.cancelAll();
        break;
      default:
        break;
    }
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

  Widget _buttonRow() {
    // Until the game has loaded its pet, every button is disabled so a tap
    // can't reach the `late` pet field. Once loaded, dim buttons that are not
    // currently relevant (spec: "irrelevant buttons are dimmed").
    final p = game.isReady ? game.pet : null;
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn('assets/ui/food.png', game.feed, p != null && p.hunger > 0),
          _btn('assets/ui/clean.png', game.clean, p != null && p.poopCount > 0),
          _btn('assets/ui/medicine.png', game.medicine,
              p != null && p.health == HealthStatus.sick),
          _btn('assets/ui/heart.png', game.play, p != null),
        ],
      ),
    );
  }

  Widget _btn(String asset, Future<void> Function() onTap, bool enabled) =>
      IconButton(
        iconSize: 40,
        onPressed: enabled ? () => onTap() : null,
        icon: Opacity(
          opacity: enabled ? 1.0 : 0.35,
          child: Image.asset(
            asset,
            width: 40,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.circle_outlined),
          ),
        ),
      );
}
