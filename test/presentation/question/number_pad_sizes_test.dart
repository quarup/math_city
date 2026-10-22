import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/presentation/question/number_pad_widget.dart';
import 'package:math_city/presentation/theme/app_theme.dart';

/// The keypad's `fill` layout must stop growing on a tablet (issue #137:
/// 160 dp rings around 24 sp digits) while a phone's sheet, which is
/// under the cap, keeps its exact pre-cap geometry.
void main() {
  /// Pumps the pad in a box of [size] at the top-left of the screen so
  /// positions are easy to reason about.
  Future<void> pump(
    WidgetTester tester, {
    required Size size,
    bool fill = true,
    List<String> extraChars = const [],
  }) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: NumberPadWidget(
                onSubmit: (_) {},
                extraChars: extraChars,
                fill: fill,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Iterable<Size> keySizes(WidgetTester tester) => [
    ...find.byType(OutlinedButton).evaluate(),
    ...find.byType(ElevatedButton).evaluate(),
  ].map((e) => (e.renderObject! as RenderBox).size);

  double digitFontSize(WidgetTester tester, String digit) => tester
      .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, digit))
      .style!
      .textStyle!
      .resolve({})!
      .fontSize!;

  Finder answerBox() =>
      find.ancestor(of: find.text('?'), matching: find.byType(Container)).first;

  group('fill layout on a tablet on its side (640 × 760 pane)', () {
    testWidgets('keys stop at the cap and keep a pill shape', (tester) async {
      await pump(tester, size: const Size(640, 760));
      final sizes = keySizes(tester).toList();
      expect(sizes, hasLength(12));
      for (final s in sizes) {
        expect(s.width, closeTo(kMaxFillKeyWidth, 0.01));
        expect(s.height, closeTo(kMaxFillKeyHeight, 0.01));
      }
    });

    testWidgets('the pad centres in the pane and the answer box matches '
        'its width', (tester) async {
      await pump(tester, size: const Size(640, 760));
      // 3 columns × (104 + 8) = 336 wide; 52 + 4 + 4 × (72 + 8) = 376 tall.
      final box = tester.getRect(answerBox());
      expect(box.width, closeTo(336, 0.01));
      expect(box.left, closeTo((640 - 336) / 2, 0.01));
      expect(box.top, closeTo((760 - 376) / 2, 0.01));

      final seven = tester.getRect(find.widgetWithText(OutlinedButton, '7'));
      expect(seven.left, closeTo((640 - 336) / 2 + 4, 0.01));
      final check = tester.getRect(
        find.ancestor(
          of: find.byIcon(Icons.check_rounded),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(check.right, closeTo((640 + 336) / 2 - 4, 0.01));
      expect(check.bottom, closeTo((760 + 376) / 2 - 4, 0.01));
    });

    testWidgets('digits grow with the key, in proportion to the phone', (
      tester,
    ) async {
      await pump(tester, size: const Size(640, 760));
      // 72 / 54 × 24 sp.
      expect(digitFontSize(tester, '7'), closeTo(32, 0.01));
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_rounded));
      expect(icon.size, closeTo(32, 0.01));
    });

    testWidgets('a symbol column widens the pad by one key', (tester) async {
      await pump(tester, size: const Size(640, 760), extraChars: ['/']);
      for (final s in keySizes(tester)) {
        expect(s.width, closeTo(kMaxFillKeyWidth, 0.01));
        expect(s.height, closeTo(kMaxFillKeyHeight, 0.01));
      }
      expect(tester.getSize(answerBox()).width, closeTo(448, 0.01));
    });
  });

  group('fill layout in a phone keypad sheet (296 × 304 interior)', () {
    // A Pixel 7 on its side: the 320 dp sheet less its 12 dp side
    // padding, and 412 dp less the toolbar, the sheet's padding and the
    // hide button. Under the cap in both directions.
    const phone = Size(296, 304);

    testWidgets('keys fill the sheet exactly as before the cap', (
      tester,
    ) async {
      await pump(tester, size: phone);
      for (final s in keySizes(tester)) {
        expect(s.width, closeTo(296 / 3 - 8, 0.01));
        expect(s.height, closeTo((304 - 56) / 4 - 8, 0.01));
      }
      expect(tester.getRect(answerBox()), const Rect.fromLTWH(0, 0, 296, 52));
    });

    testWidgets('digits and icons keep the phone size', (tester) async {
      await pump(tester, size: phone);
      expect(digitFontSize(tester, '7'), 24);
      expect(tester.widget<Icon>(find.byIcon(Icons.check_rounded)).size, null);
    });

    testWidgets('a shorter sheet (iPhone) shrinks keys without shrinking '
        'the digit', (tester) async {
      await pump(tester, size: const Size(296, 282));
      for (final s in keySizes(tester)) {
        expect(s.height, closeTo((282 - 56) / 4 - 8, 0.01));
      }
      expect(digitFontSize(tester, '7'), 24);
    });
  });

  testWidgets('upright phone layout is untouched: 60 dp keys', (
    tester,
  ) async {
    await pump(tester, size: const Size(371, 500), fill: false);
    for (final s in keySizes(tester)) {
      expect(s.height, 60);
      expect(s.width, closeTo(371 / 3 - 8, 0.01));
    }
    expect(tester.getSize(answerBox()).width, 371);
  });
}
