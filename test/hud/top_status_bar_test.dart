// test/hud/top_status_bar_test.dart
//
// Behavioral widget test for TopStatusBar.
//
// NOTE: No golden/pixel comparison here. Headless `flutter test` renders
// fonts and icon glyphs inconsistently across machines, so we assert on
// text content (stageLabel) and tap behavior instead of pixels.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digimon/state/pet.dart';
import 'package:digimon/ui/widgets/top_status_bar.dart';

void main() {
  Widget wrap(Widget child) =>
      Directionality(textDirection: TextDirection.ltr, child: child);

  testWidgets('newborn pet shows stage label "Botamon"', (tester) async {
    final pet = Pet.newborn(0);

    await tester.pumpWidget(wrap(TopStatusBar(pet: pet)));

    expect(find.text('Botamon'), findsOneWidget);
  });

  testWidgets('tapping the gear fires onSettings', (tester) async {
    var settingsTapped = false;
    final pet = Pet.newborn(0);

    await tester.pumpWidget(wrap(TopStatusBar(
      pet: pet,
      onSettings: () => settingsTapped = true,
    )));

    await tester.tap(find.byKey(const ValueKey('settings_gear')));
    await tester.pump();

    expect(settingsTapped, isTrue);
  });
}
