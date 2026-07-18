import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/ui/shell/menu_sheet.dart';
import 'package:digimon/ui/shell/room_config.dart';

void main() {
  testWidgets('menu lists doors and a door opens its room', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => Scaffold(
          body: Center(
            child: ElevatedButton(
                onPressed: () => showMenuSheet(c),
                child: const Text('menu')),
          ),
        ),
      ),
    ));
    await t.tap(find.text('menu'));
    await t.pumpAndSettle();
    expect(find.text('Treino'), findsOneWidget);
    expect(find.text('Batalha'), findsOneWidget);
    await t.tap(find.text('Treino'));
    await t.pumpAndSettle();
    expect(find.text('em breve'), findsOneWidget); // pushed the stub room
  });

  test('kRooms is the six socket-ordered rooms', () {
    expect(kRooms.length, 6);
    expect(kRooms.map((r) => r.title).toList(), [
      'DigiVice',
      'Loja',
      'Treino',
      'Evo / Bios',
      'Database',
      'Batalha',
    ]);
  });
}
