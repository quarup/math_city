import 'dart:math';

import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generators/add_sub_generators.dart';
import 'package:math_city/domain/questions/generators/fraction_generators.dart';
import 'package:math_city/domain/questions/generators/integer_generators.dart';
import 'package:math_city/domain/questions/generators/mult_div_generators.dart';
import 'package:math_city/domain/questions/generators/place_value_generators.dart';
import 'package:math_city/domain/questions/generators/rationals_generators.dart';
import 'package:math_city/domain/questions/generators/time_generators.dart';
import 'package:math_city/domain/questions/word_problems/word_problem_generators.dart';

/// A pure function that produces one question for a given concept.
typedef QuestionGenerator = GeneratedQuestion Function(Random rand);

/// Registry of question generators keyed by concept ID.
///
/// The wheel and DAG drip-feed both consult this registry to determine
/// which concepts are *implemented* — concepts in the catalog with no
/// matching entry here are skipped.
class GeneratorRegistry {
  GeneratorRegistry._(this._byConceptId);

  /// The default registry wired with all Phase 5 generators.
  factory GeneratorRegistry.defaultRegistry() =>
      GeneratorRegistry._(_buildDefault());

  /// Test seam: build a registry from an explicit map.
  factory GeneratorRegistry.fromMap(
    Map<String, QuestionGenerator> generators,
  ) => GeneratorRegistry._(Map.unmodifiable(generators));

  final Map<String, QuestionGenerator> _byConceptId;

  bool isImplemented(String conceptId) => _byConceptId.containsKey(conceptId);

  Iterable<String> get implementedConceptIds => _byConceptId.keys;

  GeneratedQuestion generate(String conceptId, {Random? random}) {
    final gen = _byConceptId[conceptId];
    if (gen == null) {
      throw ArgumentError('No generator registered for concept "$conceptId"');
    }
    return gen(random ?? Random());
  }

  static Map<String, QuestionGenerator> _buildDefault() => {
    // Addition / subtraction
    'add_within_5': addWithinN(5),
    'sub_within_5': subWithinN(5),
    'add_within_10': addWithinN(10),
    'sub_within_10': subWithinN(10),
    'add_within_20': addWithinN(20),
    'sub_within_20': subWithinN(20),
    'add_within_100': addWithinN(100),
    'sub_within_100': subWithinN(100),
    'add_2digit_carry': addWithCarry,
    'sub_2digit_borrow': subWithBorrow,
    'add_within_1000': addWithinN(1000),
    'sub_within_1000': subWithinN(1000),
    'add_multidigit_standard_alg': addMultidigit,
    'sub_multidigit_standard_alg': subMultidigit,
    // Multiplication / division
    'mult_facts_within_100': multFactsWithin100,
    'div_facts_within_100': divFactsWithin100,
    'div_with_remainder': divWithRemainder,
    'mult_4digit_by_1digit': mult4digitBy1digit,
    'mult_2digit_by_2digit': mult2digitBy2digit,
    'mult_multidigit_standard_alg': multMultidigitStandardAlg,
    'div_4digit_by_1digit': div4digitBy1digit,
    'div_4digit_by_2digit': div4digitBy2digit,
    // Fractions
    'fraction_a_over_b': fractionAOverB,
    'compare_fractions_same_denom': compareFractionsSameDenom,
    'compare_fractions_same_num': compareFractionsSameNum,
    'compare_fractions_unlike': compareFractionsUnlike,
    'equivalent_fractions_visual': equivalentFractionsVisual,
    'equivalent_fractions_compute': equivalentFractionsCompute,
    'simplify_fraction': simplifyFraction,
    'improper_to_mixed': improperToMixed,
    'mixed_to_improper': mixedToImproper,
    'add_fractions_like_denom': addFractionsLikeDenom,
    'sub_fractions_like_denom': subFractionsLikeDenom,
    'add_fractions_unlike_denom': addFractionsUnlikeDenom,
    'sub_fractions_unlike_denom': subFractionsUnlikeDenom,
    'mult_fraction_by_whole': multFractionByWhole,
    'mult_fractions_proper': multFractionsProper,
    'div_unit_fraction_by_whole': divUnitFractionByWhole,
    'div_whole_by_unit_fraction': divWholeByUnitFraction,
    'div_fraction_by_fraction': divFractionByFraction,
    'fraction_as_division': fractionAsDivision,
    'whole_number_as_fraction': wholeNumberAsFraction,
    'add_mixed_like_denom': addMixedLikeDenom,
    'sub_mixed_like_denom': subMixedLikeDenom,
    'add_mixed_unlike_denom': addMixedUnlikeDenom,
    'sub_mixed_unlike_denom': subMixedUnlikeDenom,
    'mult_mixed_numbers': multMixedNumbers,
    'mult_as_scaling': multAsScaling,
    // Time
    'time_to_hour_half': timeToHourHalf,
    'time_to_5_min': timeTo5Min,
    // Word problems
    'add_word_problems_within_100': addSubWordProblemsWithin100,
    'add_sub_2step_word_problems': addSub2stepWordProblems,
    'mult_compare_word': multCompareWord,
    // Place value
    'place_value_2digit': placeValue2digit,
    'place_value_3digit': placeValue3digit,
    'place_value_multidigit': placeValueMultidigit,
    // Rounding
    'round_to_10': roundTo10,
    'round_to_100': roundTo100,
    'round_multidigit_any_place': roundMultidigitAnyPlace,
    // Signed-integer arithmetic
    'integers_add': integersAdd,
    'integers_subtract': integersSubtract,
    'integers_multiply_divide': integersMultiplyDivide,
    // Rationals
    'rationals_add_sub': rationalsAddSub,
    'rationals_multiply_divide': rationalsMultiplyDivide,
  };
}
