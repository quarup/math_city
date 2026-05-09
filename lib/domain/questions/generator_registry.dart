import 'dart:math';

import 'package:math_dash/domain/questions/generated_question.dart';
import 'package:math_dash/domain/questions/generators/add_sub_generators.dart';
import 'package:math_dash/domain/questions/generators/fraction_generators.dart';
import 'package:math_dash/domain/questions/generators/mult_div_generators.dart';
import 'package:math_dash/domain/questions/generators/time_generators.dart';

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
    // Fractions
    'fraction_a_over_b': fractionAOverB,
    'compare_fractions_same_denom': compareFractionsSameDenom,
    'equivalent_fractions_visual': equivalentFractionsVisual,
    'add_fractions_like_denom': addFractionsLikeDenom,
    // Time
    'time_to_hour_half': timeToHourHalf,
    'time_to_5_min': timeTo5Min,
  };
}
