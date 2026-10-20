import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/economy/expected_seconds.dart';
import 'package:math_city/domain/questions/scratch_pad.dart';

void main() {
  group('usesScratchPad', () {
    test('the long algorithms and multi-step work get the pad', () {
      for (final id in const [
        'mult_2digit_by_2digit',
        'mult_multidigit_standard_alg',
        'div_4digit_by_2digit',
        'add_multidigit_standard_alg',
        'solve_two_step_eq',
        'solve_system_elimination',
        'word_problem_two_step_eq',
        'mad',
        'sub_mixed_unlike_denom',
        // pre-algebra at any length
        'solve_one_step_eq_mult',
        'solve_one_step_eq_addition',
        'evaluate_expression',
        'expand_linear_expression',
      ]) {
        expect(usesScratchPad(id), isTrue, reason: id);
      }
    });

    test('quick recall does not', () {
      for (final id in const [
        'mult_facts_within_100',
        'add_within_10',
        'count_to_20',
        'even_odd',
        // pre-algebra vocabulary and recall
        'missing_addend_within_20',
        'identify_parts_expression',
        'qualitative_graph_features',
      ]) {
        expect(usesScratchPad(id), isFalse, reason: id);
      }
    });

    test('the override lists win over the threshold', () {
      for (final id in scratchPadAlways) {
        expect(
          expectedSecondsByConcept[id],
          lessThan(kScratchPadFromSeconds),
          reason: '$id is already over the threshold; drop it from the list',
        );
        expect(usesScratchPad(id), isTrue, reason: id);
      }
      for (final id in scratchPadNever) {
        final slow = expectedSecondsByConcept[id]! >= kScratchPadFromSeconds;
        final algebra = findConceptById(id)!.categoryId == kScratchPadCategory;
        expect(
          slow || algebra,
          isTrue,
          reason: '$id would not be padded anyway; drop it from the list',
        );
        expect(usesScratchPad(id), isFalse, reason: id);
      }
    });

    test('every override names a real concept', () {
      final known = allConcepts.map((c) => c.id).toSet();
      for (final id in {...scratchPadAlways, ...scratchPadNever}) {
        expect(known, contains(id));
      }
    });

    test('an unknown concept gets no pad', () {
      expect(usesScratchPad('no_such_concept'), isFalse);
    });

    test('roughly a quarter of the catalogue is paper work', () {
      final padded = allConcepts.where((c) => usesScratchPad(c.id)).length;
      expect(padded, inInclusiveRange(70, 120), reason: '$padded padded');
    });

    test('pre-algebra is padded at any length, bar the never list', () {
      for (final c in allConcepts.where(
        (c) => c.categoryId == kScratchPadCategory,
      )) {
        expect(
          usesScratchPad(c.id),
          !scratchPadNever.contains(c.id),
          reason: c.id,
        );
      }
    });
  });
}
