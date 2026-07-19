import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/ui/hud/care_indicators.dart';

void main() {
  Widget wrap(Widget child) => Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 538, height: 300, child: Stack(children: [child])),
      );

  CareIndicators build({
    bool hungry = false,
    bool messy = false,
    bool sick = false,
    bool unhappy = false,
  }) =>
      CareIndicators(
        anchorX: 0.5,
        headY: 0.5,
        hungry: hungry,
        messy: messy,
        sick: sick,
        unhappy: unhappy,
      );

  testWidgets('shows one icon per active need', (t) async {
    await t.pumpWidget(wrap(build(hungry: true, sick: true)));
    await t.pump();
    expect(find.byKey(const ValueKey('need_hunger')), findsOneWidget);
    expect(find.byKey(const ValueKey('need_sick')), findsOneWidget);
    expect(find.byKey(const ValueKey('need_mess')), findsNothing);
    expect(find.byKey(const ValueKey('need_unhappy')), findsNothing);
  });

  testWidgets('all four needs render all four icons', (t) async {
    await t.pumpWidget(
        wrap(build(hungry: true, messy: true, sick: true, unhappy: true)));
    await t.pump();
    for (final k in ['hunger', 'mess', 'sick', 'unhappy']) {
      expect(find.byKey(ValueKey('need_$k')), findsOneWidget);
    }
  });

  testWidgets('no active needs renders nothing', (t) async {
    await t.pumpWidget(wrap(build()));
    await t.pump();
    for (final k in ['hunger', 'mess', 'sick', 'unhappy']) {
      expect(find.byKey(ValueKey('need_$k')), findsNothing);
    }
  });
}
