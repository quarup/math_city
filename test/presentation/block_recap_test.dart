import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/concepts/dag_engine.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/presentation/block/block_recap.dart';
import 'package:math_city/presentation/theme/app_theme.dart';
import 'package:math_city/presentation/widgets/concept_icon_badge.dart';

QuestionBlock _block({
  List<String> unlocks = const [],
  List<BandCrossingBonus> bonuses = const [],
  bool correct = true,
}) {
  final block = QuestionBlock(
    conceptId: 'equal_groups_intro',
    band: ProficiencyBand.comfortable,
    size: 1,
  );
  return block..record(
    AnswerReward(
      correct: correct,
      coins: correct ? 15 : 0,
      streakCount: correct ? 3 : 0,
      bandBonuses: bonuses,
      unlocks: [
        for (final id in unlocks) UnlockEvent(newConcept: findConceptById(id)!),
      ],
    ),
  );
}

Future<void> _pump(WidgetTester tester, QuestionBlock block) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: BlockRecapCard(block: block)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('recap shows coins, score and streak for a good block', (
    tester,
  ) async {
    await _pump(tester, _block());
    expect(find.text('Perfect block!'), findsOneWidget);
    expect(find.text('1 of 1 correct'), findsOneWidget);
    expect(find.textContaining('15'), findsWidgets);
  });

  testWidgets('a block that earned nothing says keep going', (tester) async {
    await _pump(tester, _block(correct: false));
    expect(find.text('Keep going!'), findsOneWidget);
    expect(find.text('0 of 1 correct'), findsOneWidget);
  });

  testWidgets('unlocks are named next to their badges', (tester) async {
    await _pump(
      tester,
      _block(unlocks: ['array_repeated_addition', 'mult_facts_2']),
    );
    expect(find.text(newTopicsHeadline(2)), findsOneWidget);
    expect(
      find.text(findConceptById('array_repeated_addition')!.name),
      findsOneWidget,
    );
    expect(find.text(findConceptById('mult_facts_2')!.name), findsOneWidget);
    expect(find.byType(ConceptIconBadge), findsNWidgets(2));
  });

  testWidgets('a band crossing gets its own line', (tester) async {
    await _pump(
      tester,
      _block(
        bonuses: const [
          BandCrossingBonus(
            conceptId: 'equal_groups_intro',
            band: ProficiencyBand.mastered,
            coins: 12,
          ),
        ],
      ),
    );
    expect(
      find.textContaining(bandBonusHeadline(ProficiencyBand.mastered)),
      findsOneWidget,
    );
  });
}
