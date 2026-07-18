// lib/ui/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/vpet_game.dart';
import '../state/biome.dart';
import '../state/digimon_species.dart';
import '../state/notifications.dart';
import '../state/pet.dart';
import '../state/pet_repository.dart';
import 'death_screen.dart';
import 'hud_theme.dart';
import 'widgets/action_dock.dart';
import 'widgets/status_badges.dart';
import 'widgets/top_status_bar.dart';

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
    // Reminders are posted by the background workmanager task (which reliably
    // runs in its own isolate), NOT from here: calling the notification plugin
    // during `paused` gets deferred by the engine until the app resumes, which
    // is both unreliable and pointless. On resume we just clear any reminder
    // the player has now answered by opening the app.
    if (state == AppLifecycleState.resumed) {
      _notifications.cancelAll();
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
      backgroundColor: const Color(0xFF1A1420),
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: game)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _topBar(),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.topRight,
                    child: StatusBadges(pet: _petOrNull()),
                  ),
                  const Spacer(),
                  _dock(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    if (game.isReady) {
      final DigimonSpecies sp = game.currentSpecies;
      return TopStatusBar(
          label: sp.name, accent: hudAccentFor(sp.biome), onSettings: null);
    }
    // Pre-load neutral default (mirrors the newborn fallback intent).
    return TopStatusBar(
        label: 'Botamon',
        accent: hudAccentFor(Biome.nursery),
        onSettings: null);
  }

  Pet _petOrNull() {
    // game.pet is `late`; before load, show a neutral newborn so the HUD can
    // render without throwing (mirrors the MVP's null-guard intent).
    try {
      return game.pet;
    } catch (_) {
      return Pet.newborn(0);
    }
  }

  Widget _dock() {
    final ready = game.isReady;
    final p = ready ? game.pet : null;
    return ActionDock(
      onFeed: game.feed,
      onClean: game.clean,
      onMedicine: game.medicine,
      onPlay: game.play,
      feedEnabled: p != null && p.hunger > 0,
      cleanEnabled: p != null && p.poopCount > 0,
      medicineEnabled: p != null && p.health == HealthStatus.sick,
      playEnabled: p != null,
    );
  }
}
