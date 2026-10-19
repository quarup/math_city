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

  group('columnForm lays out long × and ÷', () {
    test('a product becomes a stacked × column', () {
      final q = columnForm(_q('609 × 74 = ?', answer: '45066'));
      expect(q.prompt, 'Multiply.');
      final d = q.diagram! as ColumnArithmeticSpec;
      expect(d.operands, [609, 74]);
      expect(d.op, ColumnArithmeticOp.mul);
      expect(d.result, isNull);
      expect((q.explanationDiagram! as ColumnArithmeticSpec).result, 45066);
    });

    test('a quotient becomes the division house, dividend first', () {
      final q = columnForm(_q('5372 ÷ 68 = ?', answer: '79'));
      expect(q.prompt, 'Divide.');
      final d = q.diagram! as ColumnArithmeticSpec;
      expect(d.operands, [5372, 68]);
      expect(d.op, ColumnArithmeticOp.div);
    });

    test('the remainder hint line is allowed and the post-mortem skipped', () {
      final q = columnForm(_q('23 ÷ 4 = ?\n(Answer like 3R1.)', answer: '5R3'));
      expect(q.prompt, 'Divide.');
      expect((q.diagram! as ColumnArithmeticSpec).operands, [23, 4]);
      expect(q.explanationDiagram, isNull);
    });

    for (final prompt in const [
      'Calculate 263 × 40.',
      '2347 times 1198',
      'Work out 971 × 10.',
      '27 × 23',
      'What is the product of 2 and 185?',
    ]) {
      test('dataset phrasing "$prompt" is read off the worked line', () {
        final nums = RegExp(r'\d+').allMatches(prompt).map((m) => m.group(0)!);
        final a = int.parse(nums.first);
        final b = int.parse(nums.last);
        final q = columnForm(
          GeneratedQuestion(
            conceptId: 'mult_multidigit_standard_alg',
            prompt: prompt,
            correctAnswer: '${a * b}',
            distractors: const ['1', '2', '3'],
            explanation: ['$a × $b = ${a * b}'],
          ),
        );
        expect(q.prompt, 'Multiply.');
        final d = q.diagram! as ColumnArithmeticSpec;
        expect(d.operands, [a, b]);
        expect(d.op, ColumnArithmeticOp.mul);
      });
    }

    test('a word problem with a worked line keeps its story', () {
      final q = columnForm(
        const GeneratedQuestion(
          conceptId: 'mult_div_word_2step',
          prompt:
              'Kenji buys 27 boxes of 23 pens for 5 classes. How many pens?',
          correctAnswer: '621',
          distractors: ['1', '2', '3'],
          explanation: ['27 × 23 = 621'],
        ),
      );
      expect(q.diagram, isNull);
      expect(q.prompt, startsWith('Kenji'));
    });
  });
}
