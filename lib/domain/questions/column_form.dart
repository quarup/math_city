import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Concepts whose *bundled dataset* items need re-laying-out as stacked
/// columns. Their algorithmic generators call [columnForm] directly; the
/// dataset half of the same concept arrives as plain text, and a kid
/// should not get a different presentation depending on which side of
/// the mix served the question.
///
/// Generator-only column concepts (`add_up_to_4_2digit`,
/// `add_multidigit_standard_alg`, `sub_multidigit_standard_alg`) are
/// deliberately absent — there is no dataset pool to convert.
const columnFormConcepts = <String>{'add_within_1000', 'sub_within_1000'};

/// Matches a bare chain of non-negative integers joined by a single
/// repeated `+` or `−` (U+2212), asking for the result: `358 + 274 = ?`,
/// `35 + 48 + 48 = ?`, `900 − 432 = ?`.
final _inlineChain = RegExp(r'^(\d+)((?: [+−] \d+)+) = \?$');

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
/// Returns [q] unchanged when its prompt isn't such a chain. Bundled
/// dataset items are third-party text and a few phrase their prompts
/// differently; those stay inline rather than being mangled.
GeneratedQuestion columnForm(GeneratedQuestion q) {
  final m = _inlineChain.firstMatch(q.prompt);
  if (m == null) return q;

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
  final result = int.tryParse(q.correctAnswer);

  return GeneratedQuestion(
    conceptId: q.conceptId,
    prompt: op == ColumnArithmeticOp.add ? 'Add.' : 'Subtract.',
    correctAnswer: q.correctAnswer,
    distractors: q.distractors,
    explanation: q.explanation,
    diagram: ColumnArithmeticSpec(
      operands: operands,
      op: op,
      result: null,
    ),
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
