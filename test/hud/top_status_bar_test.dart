// test/hud/top_status_bar_test.dart
//
// Behavioral widget test for TopStatusBar.
//
// NOTE: No golden/pixel comparison here. Headless `flutter test` renders
// fonts and icon glyphs inconsistently across machines, so we assert on
// text content (label) and tap behavior instead of pixels.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digimon/ui/widgets/top_status_bar.dart';

void main() {
  Widget wrap(Widget child) =>
      Directionality(textDirection: TextDirection.ltr, child: child);

  testWidgets('shows the given label', (tester) async {
    await tester.pumpWidget(wrap(const TopStatusBar(
      label: 'Botamon',
      accent: Color(0xFF000000),
    )));

    expect(find.text('Botamon'), findsOneWidget);
  });

  testWidgets('tapping the gear fires onSettings', (tester) async {
    var settingsTapped = false;

    await tester.pumpWidget(wrap(TopStatusBar(
      label: 'Botamon',
      accent: const Color(0xFF000000),
      onSettings: () => settingsTapped = true,
    )));

    await tester.tap(find.byKey(const ValueKey('settings_gear')));
    await tester.pump();

    expect(settingsTapped, isTrue);
  });
}
