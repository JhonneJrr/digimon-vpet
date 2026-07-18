import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/ui/shell/room_config.dart';
import 'package:digimon/ui/shell/room_screen.dart';

void main() {
  testWidgets('stub room shows title, "em breve", and a working back button',
      (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(c).push(MaterialPageRoute(
                  builder: (_) => const RoomScreen(
                      config: RoomConfig(
                          title: 'Treino',
                          backgroundAsset:
                              'assets/game/backgrounds/room_training.png')))),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.text('Treino'), findsOneWidget);
    expect(find.text('em breve'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('room_back')));
    await t.pumpAndSettle();
    expect(find.text('Treino'), findsNothing);
  });
}
