// lib/ui/death_screen.dart
import 'package:flutter/material.dart';

/// Shown when the pet dies. Offers a single restart action.
class DeathScreen extends StatefulWidget {
  const DeathScreen({super.key, required this.onRestart});
  final Future<void> Function() onRestart;

  @override
  State<DeathScreen> createState() => _DeathScreenState();
}

class _DeathScreenState extends State<DeathScreen> {
  // Guards against a double-tap: onRestart restarts the game AND pops this
  // route, so a second tap during the await would pop again and remove
  // HomeScreen too, leaving a blank screen. Disable after the first tap.
  bool _restarting = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your Digimon has returned to the Digital World.',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _restarting
                    ? null
                    : () async {
                        setState(() => _restarting = true);
                        await widget.onRestart();
                      },
                child: const Text('Hatch a new egg'),
              ),
            ],
          ),
        ),
      );
}
