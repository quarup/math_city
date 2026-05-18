// Renders the bake-off comparison to a PNG committed under
// `test/spike/goldens/`. The PNG is the deliverable — view it directly on
// GitHub. Regenerate with:
//
//   flutter test test/spike/building_bakeoff_golden_test.dart --update-goldens
//
// This isn't a regression test in the usual sense; we don't expect pixel
// stability across font / antialiasing tweaks. It's a screenshot harness.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/spike/building_bakeoff/comparison_view.dart';

void main() {
  testWidgets('bake-off comparison renders three panels', (tester) async {
    tester.view.physicalSize = const Size(1800, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: BakeoffComparisonView(),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(BakeoffComparisonView),
      matchesGoldenFile('goldens/comparison.png'),
    );
  });
}
