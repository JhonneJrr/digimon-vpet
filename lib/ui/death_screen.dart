// lib/ui/death_screen.dart
import 'package:flutter/material.dart';

class DeathScreen extends StatelessWidget {
  const DeathScreen({super.key, required this.onRestart});
  final Future<void> Function() onRestart;

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
                onPressed: onRestart,
                child: const Text('Hatch a new egg'),
              ),
            ],
          ),
        ),
      );
}
