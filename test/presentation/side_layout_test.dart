import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/beat_registry.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/citizen.dart';
import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/domain/questions/answer_check.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/presentation/city/celebration_overlay.dart';
import 'package:math_city/presentation/city/city_screen.dart';
import 'package:math_city/presentation/city/letter_overlay.dart';
import 'package:math_city/presentation/city/times_overlay.dart';
import 'package:math_city/presentation/home/home_screen.dart';
import 'package:math_city/presentation/question/question_screen.dart';
import 'package:math_city/presentation/question/scratch_pad.dart';
import 'package:math_city/presentation/result/result_screen.dart';
import 'package:math_city/presentation/theme/app_theme.dart';
import 'package:math_city/state/player_provider.dart';

/// Every screen with a side layout must fit without overflow on each of
/// these (logical pixels left after the system bars): a small Android
/// phone, an iPhone, a Pixel 7 upright and on its side (no status bar on
/// a side), an iPad both ways.
const _sizes = <String, Size>{
  'small phone': Size(360, 616),
  'iPhone': Size(390, 763),
  'Pixel 7': Size(411, 866),
  'Pixel 7 on its side': Size(915, 412),
  'iPhone on its side': Size(844, 390),
  'iPad': Size(820, 1100),
  'iPad on its side': Size(1180, 740),
};

const _question = GeneratedQuestion(
  conceptId: 'arrays_repeated_addition',
  prompt:
      'Which addition sentence matches the array? Count each row and '
      'add the rows together.',
  correctAnswer: '3 + 3 + 3',
  distractors: ['2 + 2 + 2', '3 + 3', '3 + 3 + 3 + 3'],
  explanation: [
    'Count the rows: there are 3 rows.',
    'Each row has 3 dots.',
    'There are 3 groups of 3: 3 + 3 + 3.',
    'So the array shows 3 + 3 + 3 = 9.',
  ],
  diagram: AreaGridSpec(rows: 3, cols: 3, shadedRows: 3, shadedCols: 3),
  explanationDiagram: AreaGridSpec(
    rows: 3,
    cols: 3,
    shadedRows: 3,
    shadedCols: 3,
  ),
);

const _numeric = GeneratedQuestion(
  conceptId: 'arrays_repeated_addition',
  prompt: 'How many dots are in the array?',
  correctAnswer: '9',
  distractors: ['6', '12', '3/4'],
  explanation: ['3 rows of 3 is 9.'],
  diagram: AreaGridSpec(rows: 3, cols: 3, shadedRows: 3, shadedCols: 3),
);

/// A padded concept (long multiplication) with its column figure, which is
/// printed on the paper with no prompt card.
final _longMult = GeneratedQuestion(
  conceptId: 'mult_multidigit_standard_alg',
  prompt: 'Multiply.',
  correctAnswer: '45066',
  distractors: const ['45065', '45070', '45061'],
  explanation: const ['609 × 74 = 45066'],
  diagram: ColumnArithmeticSpec(
    operands: [609, 74],
    op: ColumnArithmeticOp.mul,
    result: null,
  ),
);

/// A padded concept with a diagram the paper carries at its top and a
/// prompt card above the paper.
final _mad = GeneratedQuestion(
  conceptId: 'mad',
  prompt: 'Find the mean absolute deviation of the data shown.',
  correctAnswer: '5',
  distractors: const ['6', '10', '0'],
  explanation: const [
    'The mean is 10.',
    'The deviations are 8, 4, 4, 0, 4, 4, 8.',
  ],
  diagram: DotPlotSpec(
    title: 'Data',
    axisLabel: 'Value',
    values: [2, 6, 6, 10, 14, 14, 18],
    minX: 0,
    maxX: 20,
  ),
);

ScratchInk _someInk() {
  final c = ScratchPadController()
    ..paperSize = const Size(320, 480)
    ..begin(const Offset(40, 60))
    ..extend(const Offset(120, 140))
    ..end();
  return c.ink;
}

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  Future<ProviderContainer> container() async {
    final db = AppDatabase(NativeDatabase.memory());
    for (final name in ['Sam', 'Zed', 'Mirzakhani', 'qq', 'Hi', 'Ada']) {
      await db.createPlayer(name: name, gradeLevel: 2, avatarConfigJson: '{}');
    }
    final c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> pump(
    WidgetTester tester,
    Size size,
    Widget child, {
    ProviderContainer? scope,
    bool settle = true,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final app = MaterialApp(theme: AppTheme.light, home: child);
    await tester.pumpWidget(
      scope == null
          ? ProviderScope(child: app)
          : UncontrolledProviderScope(container: scope, child: app),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Screens with a never-settling animation or a loading future get a
      // handful of timed frames instead.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }

  final demand = beatRegistry.firstWhere(
    (b) => b.kind == BeatKind.demand && b.event == null,
  );
  final praise = beatRegistry.firstWhere((b) => b.kind == BeatKind.praise);
  final bakery = findBuildingTypeById('bakery')!;

  for (final MapEntry(key: label, value: size) in _sizes.entries) {
    group(label, () {
      testWidgets('question with choices fits', (tester) async {
        await pump(
          tester,
          size,
          QuestionScreen(
            conceptId: _question.conceptId,
            band: ProficiencyBand.challenging,
            debugMode: true,
            question: _question,
          ),
          scope: await container(),
          settle: false,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('3 + 3 + 3'), findsOneWidget);
        expect(find.text('3 + 3 + 3 + 3'), findsOneWidget);
      });

      testWidgets('question with the keypad fits', (tester) async {
        await pump(
          tester,
          size,
          QuestionScreen(
            conceptId: _numeric.conceptId,
            band: ProficiencyBand.comfortable,
            debugMode: true,
            question: _numeric,
          ),
          scope: await container(),
          settle: false,
        );
        expect(tester.takeException(), isNull);
        // The pad is up, with the fraction key the choices call for.
        expect(find.text('7'), findsOneWidget);
        expect(find.text('/'), findsOneWidget);
        await tester.tap(find.text('9'));
        await tester.pump();
        expect(find.text('9'), findsNWidgets(2));
      });

      testWidgets('padded question with the keypad fits, open and shut', (
        tester,
      ) async {
        await pump(
          tester,
          size,
          QuestionScreen(
            conceptId: _longMult.conceptId,
            band: ProficiencyBand.comfortable,
            debugMode: true,
            question: _longMult,
          ),
          scope: await container(),
          settle: false,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(ScratchPaper), findsOneWidget);
        // The one-word prompt is left out: the figure says it.
        expect(find.text('Multiply.'), findsNothing);
        // Phones fold the keypad behind Answer; an iPad on its side keeps
        // it beside the paper.
        final answer = find.text('Answer');
        if (answer.evaluate().isNotEmpty) {
          await tester.tap(answer);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('9'));
          await tester.pump();
          expect(find.text('9'), findsNWidgets(2));
          await tester.tap(find.byTooltip('Hide keypad'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        } else {
          expect(find.text('7'), findsOneWidget);
        }
      });

      testWidgets('padded question with choices fits', (tester) async {
        await pump(
          tester,
          size,
          QuestionScreen(
            conceptId: _mad.conceptId,
            band: ProficiencyBand.challenging,
            debugMode: true,
            question: _mad,
          ),
          scope: await container(),
          settle: false,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(ScratchPaper), findsOneWidget);
        expect(find.textContaining('mean absolute deviation'), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
      });

      testWidgets("red result with the player's work fits", (tester) async {
        await pump(
          tester,
          size,
          ResultScreen(
            question: _longMult,
            selectedAnswer: '45065',
            outcome: AnswerOutcome.wrong,
            debugMode: true,
            ink: _someInk(),
          ),
          scope: await container(),
          settle: false,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('YOUR WORK'), findsOneWidget);
        expect(find.text('THE ANSWER'), findsOneWidget);
      });

      testWidgets('red result fits', (tester) async {
        await pump(
          tester,
          size,
          const ResultScreen(
            question: _question,
            selectedAnswer: '2 + 2 + 2',
            outcome: AnswerOutcome.wrong,
            debugMode: true,
          ),
          scope: await container(),
          settle: false,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Not quite…'), findsOneWidget);
        expect(find.text('THE ANSWER'), findsOneWidget);
        expect(find.text('Try another'), findsOneWidget);
      });

      testWidgets('green result fits', (tester) async {
        await pump(
          tester,
          size,
          const ResultScreen(
            question: _numeric,
            selectedAnswer: '9',
            outcome: AnswerOutcome.canonical,
            debugMode: true,
          ),
          scope: await container(),
          settle: false,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Correct!'), findsOneWidget);
        expect(find.text('THE ANSWER'), findsNothing);
      });

      testWidgets('letter fits', (tester) async {
        await pump(
          tester,
          size,
          Scaffold(
            body: LetterOverlay(
              beat: demand,
              citizen: citizenForBeat(demand),
              playerName: 'Mirzakhani',
              target: bakery,
              onBuild: () {},
              onClose: () {},
            ),
          ),
          settle: false,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Dear Mayor Mirzakhani,'), findsOneWidget);
        expect(find.text('Build it!'), findsOneWidget);
        expect(find.text('Later'), findsOneWidget);
      });

      testWidgets('front page fits', (tester) async {
        await pump(
          tester,
          size,
          Scaffold(
            body: TimesOverlay(
              beat: praise,
              cityName: 'Mirzakhani’s city',
              target: bakery,
              onBuild: () {},
              onClose: () {},
            ),
          ),
          settle: false,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('THE MATH CITY TIMES'), findsOneWidget);
      });

      testWidgets('celebration fits', (tester) async {
        await pump(
          tester,
          size,
          Scaffold(
            body: CelebrationOverlay(
              title: 'Bakery is finished!',
              reply: praise,
              replyFrom: citizenForBeat(praise),
              playerName: 'Zed',
              onDone: () {},
            ),
          ),
          settle: false,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Congratulations!'), findsOneWidget);
        expect(find.text('Thanks!'), findsOneWidget);
      });

      testWidgets('city fits', (tester) async {
        final scope = await container();
        final players = await scope.read(appDatabaseProvider).getAllPlayers();
        scope.read(activePlayerIdProvider.notifier).selected = players.first.id;
        await pump(
          tester,
          size,
          const CityScreen(),
          scope: scope,
          settle: false,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Sam’s city'), findsOneWidget);
        // The catalog is up, as a strip or a rail.
        expect(find.text('Single home'), findsWidgets);
      });

      testWidgets('home fits with six players', (tester) async {
        await pump(
          tester,
          size,
          const HomeScreen(),
          scope: await container(),
          settle: false,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Who is playing?'), findsOneWidget);
        expect(find.text('Mirzakhani'), findsOneWidget);
        expect(find.text('Add'), findsOneWidget);
      });
    });
  }
}
