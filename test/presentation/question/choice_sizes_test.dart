import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/presentation/question/question_screen.dart';
import 'package:math_city/presentation/theme/app_theme.dart';
import 'package:math_city/state/player_provider.dart';

/// The choice buttons on a side must stop growing on a tablet (issue #137:
/// 174 dp pills around 24 sp labels in the scratch-pad layout) while a
/// phone, upright or on its side, keeps its exact pre-cap geometry.
///
/// A question without the pad and one with it, since the side layout is
/// built in two places; the geometry must come out the same.
const _plain = GeneratedQuestion(
  conceptId: 'arrays_repeated_addition',
  prompt: 'How many dots are in the array?',
  correctAnswer: '9',
  distractors: ['6', '12', '3/4'],
  explanation: ['3 rows of 3 is 9.'],
  diagram: AreaGridSpec(rows: 3, cols: 3, shadedRows: 3, shadedCols: 3),
);

const _padded = GeneratedQuestion(
  conceptId: 'mad',
  prompt: '8 is 20% of what number?',
  correctAnswer: '40',
  distractors: ['16', '160', '4'],
  explanation: ['20% is one fifth, so the whole is 5 × 8 = 40.'],
);

/// Choices made of words get a speaker beside each button; the longest
/// is the forty-odd characters a sentence choice runs to.
const _words = GeneratedQuestion(
  conceptId: 'arrays_repeated_addition',
  prompt: 'How do you find the number of dots in the array?',
  correctAnswer: 'Multiply the number of rows by the number of columns',
  distractors: [
    'Add the number of rows to the number of columns',
    'Count the rows only',
    'Count the columns only',
  ],
  explanation: ['Rows times columns gives the total.'],
  diagram: AreaGridSpec(rows: 3, cols: 3, shadedRows: 3, shadedCols: 3),
);

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  Future<void> pump(
    WidgetTester tester,
    Size size,
    GeneratedQuestion question,
  ) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    final scope = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(scope.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: QuestionScreen(
            conceptId: question.conceptId,
            band: ProficiencyBand.challenging,
            debugMode: true,
            question: question,
          ),
        ),
      ),
    );
    // The screen never settles (the site bar pulses); a few timed frames.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  }

  /// The four choice buttons' rectangles, in layout order.
  List<Rect> choiceRects(WidgetTester tester) =>
      find.byType(OutlinedButton).evaluate().map((e) {
        final box = e.renderObject! as RenderBox;
        return box.localToGlobal(Offset.zero) & box.size;
      }).toList();

  double labelFontSize(WidgetTester tester) => tester
      .widget<OutlinedButton>(find.byType(OutlinedButton).first)
      .style!
      .textStyle!
      .resolve({})!
      .fontSize!;

  void expectRects(List<Rect> actual, List<Rect> expected) {
    expect(actual, hasLength(expected.length));
    for (final (i, r) in actual.indexed) {
      expect(r.left, closeTo(expected[i].left, 0.01), reason: 'left of $i');
      expect(r.top, closeTo(expected[i].top, 0.01), reason: 'top of $i');
      expect(r.right, closeTo(expected[i].right, 0.01), reason: 'right of $i');
      expect(
        r.bottom,
        closeTo(expected[i].bottom, 0.01),
        reason: 'bottom of $i',
      );
    }
  }

  group('a tablet on its side (1280 × 800, Pixel Tablet)', () {
    // The right pane: 20 dp of padding, 11/19 of the remaining 1216 dp for
    // the prompt, a 24 dp gutter, then 512 dp for the answers; 54 dp down
    // from the 44 dp bar and 10 dp of padding, 734 dp tall.
    const paneLeft = 20 + 1216 * 11 / 19 + 24;
    const paneWidth = 1216 * 8 / 19;
    const paneTop = 54.0;
    const paneHeight = 800 - 54 - 12.0;

    final capped = [
      for (var i = 0; i < 4; i++)
        Rect.fromLTWH(
          paneLeft + (paneWidth - kMaxSideChoiceWidth) / 2,
          paneTop + (paneHeight - 4 * 78) / 2 + 5 + i * 78,
          kMaxSideChoiceWidth,
          kMaxSideChoiceHeight,
        ),
    ];

    for (final (kind, q) in [
      ('without the pad', _plain),
      ('with it', _padded),
    ]) {
      testWidgets('the choices stop at the cap and centre in the pane, '
          '$kind', (tester) async {
        await pump(tester, const Size(1280, 800), q);
        expectRects(choiceRects(tester), capped);
        expect(labelFontSize(tester), 24);
      });
    }

    testWidgets('word choices keep their speaker inside the capped width '
        'and a long one wraps without overflow', (tester) async {
      await pump(tester, const Size(1280, 800), _words);
      final rects = choiceRects(tester);
      expect(rects, hasLength(4));
      for (final (i, r) in rects.indexed) {
        // The 36 dp speaker slot and its 12 dp gap sit inside the cap.
        expect(r.left, closeTo(capped[i].left + 48, 0.01));
        expect(r.right, closeTo(capped[i].right, 0.01));
        expect(r.top, closeTo(capped[i].top, 0.01));
        expect(r.height, closeTo(kMaxSideChoiceHeight, 0.01));
      }
      expect(
        find.text('Multiply the number of rows by the number of columns'),
        findsOneWidget,
      );
    });
  });

  group('a phone on its side (914 × 411, Pixel 7)', () {
    // Under the width cap and 33 dp over the height cap: the stack of
    // four 78 dp rows is centred in the 345 dp pane, as it was before.
    const paneLeft = 20 + 850 * 11 / 19 + 24;
    const paneRight = 914 - 20.0;
    final phone = [
      for (var i = 0; i < 4; i++)
        Rect.fromLTRB(
          paneLeft,
          75.5 + i * 78,
          paneRight,
          75.5 + i * 78 + 68,
        ),
    ];

    for (final (kind, q) in [
      ('without the pad', _plain),
      ('with it', _padded),
    ]) {
      testWidgets('the choices fill the pane as before, $kind', (
        tester,
      ) async {
        await pump(tester, const Size(914, 411), q);
        expectRects(choiceRects(tester), phone);
        expect(labelFontSize(tester), 24);
      });
    }
  });

  group('an upright phone (411 × 914, Pixel 7)', () {
    testWidgets('the choices are the stack of 68 dp pills as before', (
      tester,
    ) async {
      await pump(tester, const Size(411, 914), _plain);
      expectRects(choiceRects(tester), [
        for (var i = 0; i < 4; i++)
          Rect.fromLTWH(24, 576 + i * 80, 411 - 48, 68),
      ]);
      expect(labelFontSize(tester), 24);
    });

    testWidgets('with the pad, the 2 × 2 grid of 54 dp pills as before', (
      tester,
    ) async {
      await pump(tester, const Size(411, 914), _padded);
      expectRects(choiceRects(tester), const [
        Rect.fromLTRB(20, 780, 200.5, 834),
        Rect.fromLTRB(210.5, 780, 391, 834),
        Rect.fromLTRB(20, 844, 200.5, 898),
        Rect.fromLTRB(210.5, 844, 391, 898),
      ]);
    });
  });
}
