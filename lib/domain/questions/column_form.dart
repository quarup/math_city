import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Concepts whose *bundled dataset* items need re-laying-out as stacked
/// columns (or a long-division house). Their algorithmic generators call
/// [columnForm] directly; the dataset half of the same concept arrives as
/// plain text, and a kid should not get a different presentation depending
/// on which side of the mix served the question.
///
/// Generator-only column concepts (`add_up_to_4_2digit`,
/// `add_multidigit_standard_alg`, `sub_multidigit_standard_alg`, the
/// division concepts) are deliberately absent — there is no dataset pool to
/// convert.
const columnFormConcepts = <String>{
  'add_within_1000',
  'sub_within_1000',
  'mult_2digit_by_2digit',
  'mult_4digit_by_1digit',
  'mult_multidigit_standard_alg',
};

/// Matches a bare chain of non-negative integers joined by a single
/// repeated `+` or `−` (U+2212), asking for the result: `358 + 274 = ?`,
/// `35 + 48 + 48 = ?`, `900 − 432 = ?`.
final _inlineChain = RegExp(r'^(\d+)((?: [+−] \d+)+) = \?$');

/// A bare product or quotient: `609 × 74 = ?`, `5372 ÷ 68 = ?`. Anything
/// after the `?` on its own line (the remainder concept's "Answer like
/// 3R1." hint) is kept out of the figure but allowed.
final _inlineMulDiv = RegExp(
  r'^(\d+) ([×÷]) (\d+) = \?(?:\n.*)?$',
  dotAll: true,
);

/// The worked line every multiplication dataset item carries as its first
/// explanation step: `263 × 40 = 10520`.
final _workedProduct = RegExp(r'^(\d+) × (\d+) = (\d+)$');

/// Re-presents a bare `a + b = ?` question as stacked column arithmetic:
/// operands one per line, right-aligned so the place values sit above
/// each other, with a `?` under the rule. The prompt shrinks to the
/// instruction (`Add.` / `Subtract.`) since the expression now lives in
/// the diagram.
///
/// Multi-digit ± is taught column-wise, and lining the digits up is half
/// the work — an inline expression makes the kid do that alignment in
/// their head before they can start.
///
/// `a × b = ?` becomes the same stacked figure with `×`, and `a ÷ b = ?`
/// the long-division house, so the long algorithms land on the scratch
/// pad already set out the way a kid writes them (prd.md *Scratch pad*).
///
/// Returns [q] unchanged when its prompt isn't such a chain. Bundled
/// dataset items are third-party text and phrase their prompts in several
/// ways ("Calculate 263 × 40.", "2347 times 1198", "What is the product of
/// 2 and 185?"); for those the factors are read off the worked line in the
/// explanation instead, provided the prompt mentions exactly those two
/// numbers and no others — a word problem keeps its story.
GeneratedQuestion columnForm(GeneratedQuestion q) {
  final chain = _inlineChain.firstMatch(q.prompt);
  if (chain != null) return _chainForm(q, chain);
  final mulDiv = _inlineMulDiv.firstMatch(q.prompt);
  if (mulDiv != null) {
    final a = int.parse(mulDiv.group(1)!);
    final b = int.parse(mulDiv.group(3)!);
    final op = mulDiv.group(2) == '×'
        ? ColumnArithmeticOp.mul
        : ColumnArithmeticOp.div;
    return _withColumn(q, [a, b], op);
  }
  if (q.explanation.isNotEmpty) {
    final worked = _workedProduct.firstMatch(q.explanation.first);
    if (worked != null) {
      final a = worked.group(1)!;
      final b = worked.group(2)!;
      final numbers = RegExp(
        r'\d+',
      ).allMatches(q.prompt).map((m) => m.group(0)).toList();
      if (numbers.length == 2 && numbers.contains(a) && numbers.contains(b)) {
        return _withColumn(q, [
          int.parse(a),
          int.parse(b),
        ], ColumnArithmeticOp.mul);
      }
    }
  }
  return q;
}

GeneratedQuestion _chainForm(GeneratedQuestion q, RegExpMatch m) {
  final rest = m.group(2)!.trim().split(' '); // ['+', '48', '+', '48']
  final opChar = rest[0];
  // A mixed chain (a + b − c) has no single column operator.
  for (var i = 0; i < rest.length; i += 2) {
    if (rest[i] != opChar) return q;
  }
  final operands = [
    int.parse(m.group(1)!),
    for (var i = 1; i < rest.length; i += 2) int.parse(rest[i]),
  ];
  final op = opChar == '+' ? ColumnArithmeticOp.add : ColumnArithmeticOp.sub;
  return _withColumn(q, operands, op);
}

GeneratedQuestion _withColumn(
  GeneratedQuestion q,
  List<int> operands,
  ColumnArithmeticOp op,
) {
  // The remainder concept answers "3R1": no single number to fill in.
  final result = int.tryParse(q.correctAnswer);
  return GeneratedQuestion(
    conceptId: q.conceptId,
    prompt: switch (op) {
      ColumnArithmeticOp.add => 'Add.',
      ColumnArithmeticOp.sub => 'Subtract.',
      ColumnArithmeticOp.mul => 'Multiply.',
      ColumnArithmeticOp.div => 'Divide.',
    },
    correctAnswer: q.correctAnswer,
    distractors: q.distractors,
    explanation: q.explanation,
    diagram: ColumnArithmeticSpec(operands: operands, op: op, result: null),
    // Show the same column filled in on the wrong-answer screen, so the
    // post-mortem is laid out the way the question was.
    explanationDiagram:
        q.explanationDiagram ??
        (result == null || result < 0
            ? null
            : ColumnArithmeticSpec(
                operands: operands,
                op: op,
                result: result,
              )),
    answerFormat: q.answerFormat,
    answerShape: q.answerShape,
    multipleChoiceOnly: q.multipleChoiceOnly,
  );
}
