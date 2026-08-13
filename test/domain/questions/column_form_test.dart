import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/column_form.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

GeneratedQuestion _q(
  String prompt, {
  String answer = '0',
  DiagramSpec? explanationDiagram,
}) => GeneratedQuestion(
  conceptId: 'test',
  prompt: prompt,
  correctAnswer: answer,
  distractors: const ['a', 'b', 'c'],
  explanation: const ['because'],
  explanationDiagram: explanationDiagram,
);

void main() {
  group('columnForm converts an inline chain', () {
    test('two-operand addition', () {
      final q = columnForm(_q('358 + 274 = ?', answer: '632'));
      expect(q.prompt, 'Add.');
      final diagram = q.diagram! as ColumnArithmeticSpec;
      expect(diagram.operands, [358, 274]);
      expect(diagram.op, ColumnArithmeticOp.add);
      expect(diagram.result, isNull);
    });

    test('subtraction uses the U+2212 minus the generators emit', () {
      final q = columnForm(_q('900 − 432 = ?', answer: '468'));
      expect(q.prompt, 'Subtract.');
      final diagram = q.diagram! as ColumnArithmeticSpec;
      expect(diagram.operands, [900, 432]);
      expect(diagram.op, ColumnArithmeticOp.sub);
    });

    test('chain of four addends', () {
      final q = columnForm(_q('35 + 48 + 12 + 20 = ?', answer: '115'));
      expect(
        (q.diagram! as ColumnArithmeticSpec).operands,
        [35, 48, 12, 20],
      );
    });

    test('carries the answer and the choices through untouched', () {
      final q = columnForm(_q('358 + 274 = ?', answer: '632'));
      expect(q.correctAnswer, '632');
      expect(q.distractors, ['a', 'b', 'c']);
      expect(q.explanation, ['because']);
    });

    test('explanation gets the same column with the result filled in', () {
      final q = columnForm(_q('358 + 274 = ?', answer: '632'));
      final diagram = q.explanationDiagram! as ColumnArithmeticSpec;
      expect(diagram.operands, [358, 274]);
      expect(diagram.result, 632);
    });

    test('an explanation diagram the generator already set is kept', () {
      final existing = ColumnArithmeticSpec(
        operands: [358, 274],
        op: ColumnArithmeticOp.add,
        result: 632,
        carries: [1],
      );
      final q = columnForm(
        _q('358 + 274 = ?', answer: '632', explanationDiagram: existing),
      );
      expect(q.explanationDiagram, same(existing));
    });
  });

  group('columnForm leaves alone what it cannot lay out', () {
    for (final prompt in const [
      'Work out 60 + 4.', // prose, not an equation
      '5 × 4 = ?', // not a ± chain
      '12 + 8 − 3 = ?', // mixed operators have no single column op
      '358 + 274 = 632', // states the answer, asks nothing
      '−5 + 3 = ?', // negative operands are out of column scope
    ]) {
      test('"$prompt"', () {
        final q = _q(prompt);
        final out = columnForm(q);
        expect(out.prompt, prompt);
        expect(out.diagram, isNull);
      });
    }

    test('a non-integer answer still lays out, minus the post-mortem', () {
      final q = columnForm(_q('358 + 274 = ?', answer: 'six hundred'));
      expect(q.diagram, isA<ColumnArithmeticSpec>());
      expect(q.explanationDiagram, isNull);
    });
  });
}
