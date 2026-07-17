// test/hud/action_dock_test.dart
//
// Behavioral + structural widget test for ActionDock.
//
// NOTE: No golden/pixel comparison here. Headless `flutter test` does not
// load real Image.asset bytes, so a golden of this widget would only ever
// capture blank icons — misleading rather than useful. Instead we assert on
// widget structure (keys, Opacity descendants) and behavior (tap callbacks),
// which is meaningful regardless of whether the asset image itself renders.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digimon/ui/widgets/action_dock.dart';

void main() {
  Widget wrap(Widget child) =>
      Directionality(textDirection: TextDirection.ltr, child: child);

  testWidgets('all four dock buttons render with expected keys',
      (tester) async {
    await tester.pumpWidget(wrap(ActionDock(
      onFeed: () {},
      onClean: () {},
      onMedicine: () {},
      onPlay: () {},
      feedEnabled: true,
      cleanEnabled: true,
      medicineEnabled: true,
      playEnabled: true,
    )));

    expect(find.byKey(const ValueKey('dock_feed')), findsOneWidget);
    expect(find.byKey(const ValueKey('dock_clean')), findsOneWidget);
    expect(find.byKey(const ValueKey('dock_medicine')), findsOneWidget);
    expect(find.byKey(const ValueKey('dock_play')), findsOneWidget);
  });

  testWidgets('disabled action does not fire on tap', (tester) async {
    var cleanTapped = false;

    await tester.pumpWidget(wrap(ActionDock(
      onFeed: () {},
      onClean: () => cleanTapped = true,
      onMedicine: () {},
      onPlay: () {},
      feedEnabled: true,
      cleanEnabled: false,
      medicineEnabled: true,
      playEnabled: true,
    )));

    await tester.tap(find.byKey(const ValueKey('dock_clean')));
    await tester.pump();

    expect(cleanTapped, isFalse);
  });

  testWidgets('enabled action fires on tap', (tester) async {
    var feedTapped = false;

    await tester.pumpWidget(wrap(ActionDock(
      onFeed: () => feedTapped = true,
      onClean: () {},
      onMedicine: () {},
      onPlay: () {},
      feedEnabled: true,
      cleanEnabled: true,
      medicineEnabled: true,
      playEnabled: true,
    )));

    await tester.tap(find.byKey(const ValueKey('dock_feed')));
    await tester.pump();

    expect(feedTapped, isTrue);
  });

  testWidgets('disabled buttons are dimmed, enabled buttons are not',
      (tester) async {
    await tester.pumpWidget(wrap(ActionDock(
      onFeed: () {},
      onClean: () {},
      onMedicine: () {},
      onPlay: () {},
      feedEnabled: true,
      cleanEnabled: false,
      medicineEnabled: true,
      playEnabled: true,
    )));

    final cleanOpacity = tester.widget<Opacity>(find.descendant(
      of: find.byKey(const ValueKey('dock_clean')),
      matching: find.byType(Opacity),
    ));
    expect(cleanOpacity.opacity, 0.35);

    final feedOpacity = tester.widget<Opacity>(find.descendant(
      of: find.byKey(const ValueKey('dock_feed')),
      matching: find.byType(Opacity),
    ));
    expect(feedOpacity.opacity, 1.0);
  });
}
