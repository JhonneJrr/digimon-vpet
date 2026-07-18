import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/ui/hud/pet_tap_target.dart';

void main() {
  testWidgets('tapping the pet region fires onTap', (t) async {
    var tapped = false;
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 538,
        height: 300,
        child: Stack(children: [
          PetTapTarget(
            anchorX: 0.5,
            groundFraction: 0.78,
            heightFraction: 0.25,
            onTap: () => tapped = true,
          ),
        ]),
      ),
    ));
    await t.tap(find.byKey(const ValueKey('pet_tap')));
    await t.pump();
    expect(tapped, isTrue);
  });
}
