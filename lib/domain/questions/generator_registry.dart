import 'dart:math';

import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generators/add_sub_generators.dart';
import 'package:math_city/domain/questions/generators/advanced_generators.dart';
import 'package:math_city/domain/questions/generators/decimal_generators.dart';
import 'package:math_city/domain/questions/generators/equation_generators.dart';
import 'package:math_city/domain/questions/generators/fraction_generators.dart';
import 'package:math_city/domain/questions/generators/geometry_generators.dart';
import 'package:math_city/domain/questions/generators/integer_generators.dart';
import 'package:math_city/domain/questions/generators/mult_div_generators.dart';
import 'package:math_city/domain/questions/generators/number_theory_generators.dart';
import 'package:math_city/domain/questions/generators/percent_generators.dart';
import 'package:math_city/domain/questions/generators/place_value_generators.dart';
import 'package:math_city/domain/questions/generators/probability_generators.dart';
import 'package:math_city/domain/questions/generators/ratio_generators.dart';
import 'package:math_city/domain/questions/generators/rationals_generators.dart';
import 'package:math_city/domain/questions/generators/statistics_generators.dart';
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
    'absolute_value': absoluteValue,
    'opposites_and_zero': oppositesAndZero,
    // Number theory
    'factors_of_n': factorsOfN,
    'multiples_of_n': multiplesOfN,
    'gcf_two_numbers': gcfTwoNumbers,
    'lcm_two_numbers': lcmTwoNumbers,
    'prime_or_composite': primeOrComposite,
    'exponents_whole_number': exponentsWholeNumber,
    'order_of_operations_with_exp': orderOfOperationsWithExp,
    'sqrt_perfect_squares': sqrtPerfectSquares,
    'cbrt_perfect_cubes': cbrtPerfectCubes,
    'scientific_notation_read': scientificNotationRead,
    'scientific_notation_write': scientificNotationWrite,
    'integer_exponent_props': integerExponentProps,
    'scientific_notation_ops': scientificNotationOps,
    // Late-grade / cross-category
    'pythagorean_apply_2d': pythagoreanApply2d,
    'volume_rect_prism_formula': volumeRectPrismFormula,
    'compare_order_rationals': compareOrderRationals,
    'irrational_recognize': irrationalRecognize,
    // Rationals
    'rationals_add_sub': rationalsAddSub,
    'rationals_multiply_divide': rationalsMultiplyDivide,
    // Decimals
    'decimal_notation_tenths': decimalNotationTenths,
    'decimal_notation_hundredths': decimalNotationHundredths,
    'compare_decimals_hundredths': compareDecimalsHundredths,
    'add_decimals': addDecimals,
    'sub_decimals': subDecimals,
    'mult_decimal_by_whole': multDecimalByWhole,
    'mult_decimals': multDecimals,
    'decimal_to_thousandths_read': decimalToThousandthsRead,
    'compare_decimals_thousandths': compareDecimalsThousandths,
    'round_decimals': roundDecimals,
    'div_decimal_by_whole': divDecimalByWhole,
    'div_by_decimal': divByDecimal,
    'decimal_to_fraction': decimalToFraction,
    'fraction_to_decimal': fractionToDecimal,
    'decimals_fluent_4ops': decimalsFluent4ops,
    'repeating_decimal_recognize': repeatingDecimalRecognize,
    'repeating_decimal_to_fraction': repeatingDecimalToFraction,
    // Percent
    'percent_intro': percentIntro,
    'percent_of_quantity': percentOfQuantity,
    'find_whole_from_part_percent': findWholeFromPartPercent,
    'percent_change': percentChange,
    'simple_interest': simpleInterest,
    'commission': commission,
    'markup_markdown': markupMarkdown,
    'sales_tax_tip': salesTaxTip,
    'convert_fraction_decimal_percent': convertFractionDecimalPercent,
    // Ratios
    'ratio_intro': ratioIntro,
    'ratio_language': ratioLanguage,
    'equivalent_ratios': equivalentRatios,
    'unit_rate': unitRate,
    'constant_speed': constantSpeed,
    'unit_pricing': unitPricing,
    'convert_units_using_ratio': convertUnitsUsingRatio,
    'proportional_relationship': proportionalRelationship,
    'constant_of_proportionality': constantOfProportionality,
    'proportional_equation': proportionalEquation,
    // Expressions / equations
    'order_of_operations_no_exp': orderOfOperationsNoExp,
    'nested_grouping': nestedGrouping,
    'evaluate_expression': evaluateExpression,
    'solve_one_step_eq_addition': solveOneStepEqAddition,
    'solve_one_step_eq_mult': solveOneStepEqMult,
    'solve_two_step_eq': solveTwoStepEq,
    'expand_linear_expression': expandLinearExpression,
    'add_subtract_linear_expressions': addSubtractLinearExpressions,
    'equivalent_expressions_props': equivalentExpressionsProps,
    'substitute_to_check': substituteToCheck,
    'factor_linear_expression': factorLinearExpression,
    'solve_two_step_eq_distributive': solveTwoStepEqDistributive,
    'solve_linear_eq_one_solution': solveLinearEqOneSolution,
    // Geometry
    'area_rectangle_formula': areaRectangleFormula,
    'perimeter_polygon': perimeterPolygon,
    'perimeter_unknown_side': perimeterUnknownSide,
    'area_triangle': areaTriangle,
    'area_parallelogram': areaParallelogram,
    'area_trapezoid': areaTrapezoid,
    // Probability
    'probability_zero_to_one': probabilityZeroToOne,
    'probability_simple_event': probabilitySimpleEvent,
    'experimental_probability': experimentalProbability,
    'sample_space_list': sampleSpaceList,
    // Statistics
    'mean': meanGenerator,
    'median': medianGenerator,
    'mode': modeGenerator,
    'range_data': rangeDataGenerator,
    'iqr': iqrGenerator,
    'mad': madGenerator,
  };
}
