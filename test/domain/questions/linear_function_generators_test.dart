import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

const _iterations = 300;
const _minus = '−';

GeneratedQuestion _gen(GeneratorRegistry r, String id, [int seed = 13]) =>
    r.generate(id, random: Random(seed));

void _expectThreeDistinctDistractors(GeneratedQuestion q) {
  expect(q.distractors, hasLength(3));
  expect(q.distractors.toSet(), hasLength(3));
  expect(q.distractors, isNot(contains(q.correctAnswer)));
}

int _parseSigned(String s) {
  if (s.startsWith(_minus)) return -int.parse(s.substring(_minus.length));
  return int.parse(s);
}

List<int>? _parseCoord(String s) {
  final m = RegExp(r'^\((−?\d+), (−?\d+)\)$').firstMatch(s);
  if (m == null) return null;
  return [_parseSigned(m.group(1)!), _parseSigned(m.group(2)!)];
}

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('identify_linear_vs_nonlinear', () {
    test(
      'correctAnswer is "Linear" iff the parsed table has constant Δy; '
      'both Linear and Nonlinear appear across seeds',
      () {
        final answersSeen = <String>{};
        final tableRe = RegExp(
          r'^These \(x, y\) pairs come from one relationship: (.+)\. Is it',
        );
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'identify_linear_vs_nonlinear', i);
          final m = tableRe.firstMatch(q.prompt);
          expect(m, isNotNull, reason: q.prompt);
          final pairs = m!.group(1)!.split('; ');
          expect(pairs, hasLength(4));
          final ys = <int>[];
          for (final p in pairs) {
            final coord = RegExp(r'^\((-?\d+), (-?\d+)\)$').firstMatch(p);
            expect(coord, isNotNull);
            ys.add(int.parse(coord!.group(2)!));
          }
          // Constant Δy iff "Linear".
          final deltas = [
            for (var j = 1; j < ys.length; j++) ys[j] - ys[j - 1],
          ];
          final isArithmetic = deltas.every((d) => d == deltas.first);
          final expectedAnswer = isArithmetic ? 'Linear' : 'Nonlinear';
          expect(q.correctAnswer, expectedAnswer);
          answersSeen.add(q.correctAnswer);

          // Binary question, binary choices.
          expect(
            q.distractors.toSet(),
            {
              if (isArithmetic) 'Nonlinear' else 'Linear',
            },
          );
        }
        expect(answersSeen, {'Linear', 'Nonlinear'});
      },
    );
  });

  group('solve_system_by_graphing', () {
    test(
      'two lines on the plane with distinct slopes; both lines pass '
      'through the answer coordinate; answer ∈ [-3, 3]²',
      () {
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'solve_system_by_graphing', i);
          expect(q.diagram, isA<CoordinatePlaneSpec>());
          final spec = q.diagram! as CoordinatePlaneSpec;
          expect(spec.lines, hasLength(2));

          final ans = _parseCoord(q.correctAnswer);
          expect(ans, isNotNull);
          final ax = ans![0];
          final ay = ans[1];
          expect(ax, inInclusiveRange(-3, 3));
          expect(ay, inInclusiveRange(-3, 3));

          // Each line passes through (ax, ay). Derive m from the two
          // anchor points and confirm ay == m·ax + bIntercept where
          // bIntercept = y1 - m·x1.
          final slopes = <int>{};
          for (final line in spec.lines) {
            final m = ((line.y2 - line.y1) / (line.x2 - line.x1)).round();
            final bInt = (line.y1 - m * line.x1).round();
            expect(
              m * ax + bInt,
              ay,
              reason: 'line $line does not pass through ($ax, $ay)',
            );
            slopes.add(m);
          }
          // Distinct slopes — otherwise no unique intersection.
          expect(slopes, hasLength(2));
          _expectThreeDistinctDistractors(q);
        }
      },
    );
  });
}
