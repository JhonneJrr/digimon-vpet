// test/death_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/ui/death_screen.dart';

void main() {
  testWidgets('restart button ignores a second tap while restarting',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: DeathScreen(
        onRestart: () async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
        },
      ),
    ));

    final btn = find.text('Hatch a new egg');
    await tester.tap(btn);
    await tester.pump(); // setState disables the button
    await tester.tap(btn); // second tap — should be ignored
    await tester.pump(const Duration(milliseconds: 100));

    expect(calls, 1, reason: 'double-tap must not restart/pop twice');
  });
}
