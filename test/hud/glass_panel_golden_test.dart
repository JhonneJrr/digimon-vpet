import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digimon/ui/widgets/glass_panel.dart';

void main() {
  testWidgets('GlassPanel renders a frosted rounded container', (tester) async {
    await tester.pumpWidget(
      Container(
        color: const Color(0xFF6A3FA0),
        alignment: Alignment.center,
        child: const GlassPanel(
          child: SizedBox(width: 80, height: 40),
        ),
      ),
    );
    await expectLater(
      find.byType(GlassPanel),
      matchesGoldenFile('goldens/glass_panel.png'),
    );
  });
}
