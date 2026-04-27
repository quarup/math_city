import 'dart:math';

import 'package:math_dash/domain/concepts/concept_registry.dart';
import 'package:math_dash/domain/questions/question.dart';

/// Generates algorithmic arithmetic questions for [add1Digit] and [sub1Digit].
///
/// Distractor strategy (per plan.md Domain Specs):
///   - off-by-one (correct ± 1)
///   - random values within ±5 of correct
/// Results are always non-negative.
class ArithmeticGenerator {
  ArithmeticGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  Question generateForConcept(String conceptId) {
    if (conceptId == add1Digit.id) return _generateAdd();
    if (conceptId == sub1Digit.id) return _generateSub();
    throw ArgumentError('Unknown concept: $conceptId');
  }

  Question _generateAdd() {
    final a = _random.nextInt(10); // 0–9
    final b = _random.nextInt(10); // 0–9
    final correct = a + b;
    return Question(
      conceptId: add1Digit.id,
      prompt: '$a + $b = ?',
      correctAnswer: correct.toString(),
      distractors: _buildDistractors(correct),
      explanation: '$a + $b = $correct',
    );
  }

  Question _generateSub() {
    // Ensure minuend ≥ subtrahend so difference is never negative.
    final b = _random.nextInt(10); // 0–9
    final a = b + _random.nextInt(10); // a ∈ [b, b+9] ⊆ [0, 18]
    final correct = a - b;
    return Question(
      conceptId: sub1Digit.id,
      prompt: '$a − $b = ?', // U+2212 minus sign
      correctAnswer: correct.toString(),
      distractors: _buildDistractors(correct),
      explanation: '$a − $b = $correct',
    );
  }

  /// Returns exactly three distractors: distinct, non-negative, != [correct].
  List<String> _buildDistractors(int correct) {
    // Collection-if avoids consecutive `.add()` calls on the same receiver.
    final candidates = <int>{
      correct + 1,
      if (correct - 1 >= 0) correct - 1,
    };

    // Random values within ±5, non-negative
    for (var attempt = 0; attempt < 40 && candidates.length < 8; attempt++) {
      final offset = _random.nextInt(5) + 1;
      final sign = _random.nextBool() ? 1 : -1;
      final v = correct + sign * offset;
      if (v >= 0) candidates.add(v);
    }

    candidates.remove(correct);

    // Fallback: sequential positives (guarantees we always return 3)
    for (var fallback = 1; candidates.length < 3; fallback++) {
      if (fallback != correct) candidates.add(fallback);
    }

    final list = candidates.toList()..shuffle(_random);
    return list.take(3).map((n) => n.toString()).toList();
  }
}
