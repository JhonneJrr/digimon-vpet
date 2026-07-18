// lib/ui/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/vpet_game.dart';
import '../state/notifications.dart';
import '../state/pet.dart';
import '../state/pet_repository.dart';
import 'death_screen.dart';
import 'hud/care_radial.dart';
import 'hud/hud_overlay.dart';
import 'hud/pet_tap_target.dart';
import 'shell/room_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final VpetGame game;
  final Notifications _notifications = Notifications();
  bool _careOpen = false;

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
    // The game is landscape: a 538x300 stage (the real map + MainHUD aspect)
    // centred in the screen with dark side bars, so nothing distorts.
    return Scaffold(
      backgroundColor: const Color(0xFF07060D),
      body: Center(
        child: AspectRatio(
          aspectRatio: 538 / 300,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GameWidget(game: game),
                // Tap the pet to toggle the care radial.
                if (game.isReady)
                  PetTapTarget(
                    anchorX: game.petAnchorXFraction,
                    groundFraction: game.petGroundFraction,
                    heightFraction: game.petHeightFraction,
                    onTap: _toggleCare,
                  ),
                // Close-catcher behind the bubbles while the menu is open.
                if (_careOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _closeCare,
                    ),
                  ),
                _careRadial(),
                _hud(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleCare() => _setCare(!_careOpen);
  void _closeCare() => _setCare(false);
  void _setCare(bool open) {
    setState(() => _careOpen = open);
    game.careMenuOpen = open;
  }

  Future<void> _doCare(Future<void> Function() action) async {
    _closeCare();
    await action();
  }

  Widget _careRadial() {
    final ready = game.isReady;
    final p = ready ? game.pet : null;
    final anchorX = ready ? game.petAnchorXFraction : 0.5;
    // Anchor the arc on the pet's mid-body (feet minus half its height).
    final anchorY = ready
        ? (game.petGroundFraction - game.petHeightFraction * 0.5)
        : 0.6;
    return CareRadial(
      open: _careOpen,
      anchorX: anchorX,
      anchorY: anchorY,
      feedEnabled: p != null && p.hunger > 0,
      cleanEnabled: p != null && p.poopCount > 0,
      medicineEnabled: p != null && p.health == HealthStatus.sick,
      playEnabled: p != null,
      onFeed: () => _doCare(game.feed),
      onClean: () => _doCare(game.clean),
      onMedicine: () => _doCare(game.medicine),
      onPlay: () => _doCare(game.play),
    );
  }

  Widget _hud() {
    final ready = game.isReady;
    final name = ready ? game.currentSpecies.name : 'Botamon';
    return HudOverlay(
      name: name,
      pet: _petOrNull(),
      onOpenRoom: (room) {
        _closeCare();
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => RoomScreen(config: room)));
      },
    );
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
}
