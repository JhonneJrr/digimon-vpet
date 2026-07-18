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
import 'shell/menu_sheet.dart';
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
      backgroundColor: const Color(0xFF0D0B17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _topBar(),
              const SizedBox(height: 10),
              // Framed "stage": a wide scene window showing most of the real map,
              // with the pet ambling in it. Centred in the free vertical space.
              Expanded(child: Center(child: _stage())),
              const SizedBox(height: 10),
              _dock(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stage() {
    return AspectRatio(
      aspectRatio: 3 / 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x33FFFFFF)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GameWidget(game: game),
              Positioned(
                top: 8,
                right: 8,
                child: StatusBadges(pet: _petOrNull()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    if (game.isReady) {
      final DigimonSpecies sp = game.currentSpecies;
      return TopStatusBar(
          label: sp.name,
          accent: hudAccentFor(sp.biome),
          onMenu: () => showMenuSheet(context));
    }
    // Pre-load neutral default (mirrors the newborn fallback intent).
    return TopStatusBar(
        label: 'Botamon',
        accent: hudAccentFor(Biome.nursery),
        onMenu: () => showMenuSheet(context));
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
