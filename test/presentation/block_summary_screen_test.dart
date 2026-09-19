import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/concepts/dag_engine.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/presentation/block/block_summary_screen.dart';
import 'package:math_city/presentation/theme/app_theme.dart';
import 'package:math_city/presentation/widgets/concept_icon_badge.dart';

QuestionBlock _blockUnlocking(List<String> conceptIds) {
  final block = QuestionBlock(
    conceptId: 'equal_groups_intro',
    band: ProficiencyBand.comfortable,
    size: 1,
  );
  return block..record(
    AnswerReward(
      correct: true,
      coins: 15,
      streakCount: 3,
      unlocks: [
        for (final id in conceptIds)
          UnlockEvent(newConcept: findConceptById(id)!),
      ],
    ),
  );
}

void main() {
  testWidgets('unlock card names each new concept next to its badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlockSummaryScreen(
          block: _blockUnlocking(['array_repeated_addition', 'mult_facts_2']),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(newTopicsHeadline(2)), findsOneWidget);
    expect(
      find.text(findConceptById('array_repeated_addition')!.name),
      findsOneWidget,
    );
    expect(find.text(findConceptById('mult_facts_2')!.name), findsOneWidget);
    expect(find.byType(ConceptIconBadge), findsNWidgets(2));
  });
}
