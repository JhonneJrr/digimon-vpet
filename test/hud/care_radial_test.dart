import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/ui/hud/care_radial.dart';

void main() {
  Widget wrap(Widget child) => Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 538, height: 300, child: Stack(children: [child])),
      );

  CareRadial build({
    bool open = true,
    bool feed = true,
    bool clean = true,
    bool medicine = true,
    bool play = true,
    void Function()? onFeed,
    void Function()? onClean,
    void Function()? onMedicine,
    void Function()? onPlay,
  }) =>
      CareRadial(
        open: open,
        anchorX: 0.5,
        anchorY: 0.6,
        feedEnabled: feed,
        cleanEnabled: clean,
        medicineEnabled: medicine,
        playEnabled: play,
        onFeed: onFeed ?? () {},
        onClean: onClean ?? () {},
        onMedicine: onMedicine ?? () {},
        onPlay: onPlay ?? () {},
      );

  testWidgets('renders four bubbles with expected keys', (t) async {
    await t.pumpWidget(wrap(build()));
    expect(find.byKey(const ValueKey('care_feed')), findsOneWidget);
    expect(find.byKey(const ValueKey('care_clean')), findsOneWidget);
    expect(find.byKey(const ValueKey('care_medicine')), findsOneWidget);
    expect(find.byKey(const ValueKey('care_play')), findsOneWidget);
  });

  testWidgets('enabled bubble fires its callback', (t) async {
    var fed = false;
    await t.pumpWidget(wrap(build(onFeed: () => fed = true)));
    await t.tap(find.byKey(const ValueKey('care_feed')));
    await t.pump();
    expect(fed, isTrue);
  });

  testWidgets('disabled bubble does not fire and is dimmed', (t) async {
    var medded = false;
    await t.pumpWidget(wrap(build(medicine: false, onMedicine: () => medded = true)));
    await t.tap(find.byKey(const ValueKey('care_medicine')), warnIfMissed: false);
    await t.pump();
    expect(medded, isFalse);
    final op = t.widget<Opacity>(find.descendant(
      of: find.byKey(const ValueKey('care_medicine')),
      matching: find.byType(Opacity),
    ));
    expect(op.opacity, 0.4);
  });

  testWidgets('closed radial ignores pointer', (t) async {
    var fed = false;
    await t.pumpWidget(wrap(build(open: false, onFeed: () => fed = true)));
    await t.tap(find.byKey(const ValueKey('care_feed')), warnIfMissed: false);
    await t.pump();
    expect(fed, isFalse);
  });
}
