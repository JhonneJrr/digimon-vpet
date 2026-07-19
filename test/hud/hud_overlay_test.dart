import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/ui/hud/hud_overlay.dart';
import 'package:digimon/ui/shell/room_config.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 538, height: 300, child: Stack(children: [child])),
        ),
      );

  testWidgets('renders six socket buttons', (t) async {
    await t.pumpWidget(wrap(HudOverlay(
      name: 'Agumon',
      onOpenRoom: (_) {},
    )));
    for (var i = 0; i < 6; i++) {
      expect(find.byKey(ValueKey('hud_socket_$i')), findsOneWidget);
    }
  });

  testWidgets('tapping socket 2 opens kRooms[2] (Treino)', (t) async {
    RoomConfig? opened;
    await t.pumpWidget(wrap(HudOverlay(
      name: 'Agumon',
      onOpenRoom: (r) => opened = r,
    )));
    await t.tap(find.byKey(const ValueKey('hud_socket_2')));
    await t.pump();
    expect(opened, same(kRooms[2]));
    expect(opened?.title, 'Treino');
  });
}
