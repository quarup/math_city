import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

const _iterations = 300;

GeneratedQuestion _gen(GeneratorRegistry r, String id, [int seed = 13]) =>
    r.generate(id, random: Random(seed));

void _expectThreeDistinctDistractors(GeneratedQuestion q) {
  expect(q.distractors, hasLength(3));
  expect(q.distractors.toSet(), hasLength(3));
  expect(q.distractors, isNot(contains(q.correctAnswer)));
}

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('right_acute_obtuse_angle', () {
    test('all three classes appear and label matches the drawn angle', () {
      const opts = ['Acute', 'Right', 'Obtuse'];
      final seen = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'right_acute_obtuse_angle', i);
        expect(opts, contains(q.correctAnswer));
        seen.add(q.correctAnswer);
        final spec = q.diagram! as AngleSpec;
        expect(spec.rayAnglesDeg, hasLength(2));
        final measure = spec.rayAnglesDeg[1] - spec.rayAnglesDeg[0];
        switch (q.correctAnswer) {
          case 'Acute':
            expect(measure, lessThan(90));
          case 'Right':
            expect(measure, 90);
          case 'Obtuse':
            expect(measure, greaterThan(90));
            expect(measure, lessThan(180));
        }
        _expectThreeDistinctDistractors(q);
      }
      expect(seen, containsAll(opts));
    });
  });

  group('angle_addition', () {
    test('correct = a + b; both subangles labelled on the figure', () {
      final re = RegExp(
        '^An angle has been split into two adjacent angles measuring '
        r'(\d+)° and (\d+)°\. What is the total angle measure\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'angle_addition', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        expect(q.correctAnswer, '${a + b}');
        final spec = q.diagram! as AngleSpec;
        expect(spec.rayAnglesDeg, hasLength(3));
        expect(spec.rayAnglesDeg[1] - spec.rayAnglesDeg[0], a);
        expect(spec.rayAnglesDeg[2] - spec.rayAnglesDeg[1], b);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('fraction_on_number_line', () {
    test('numerator/denominator matches the marked tick position', () {
      final re = RegExp(r'^(\d+)/(\d+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'fraction_on_number_line', i);
        final m = re.firstMatch(q.correctAnswer);
        expect(m, isNotNull, reason: q.correctAnswer);
        final n = int.parse(m!.group(1)!);
        final d = int.parse(m.group(2)!);
        expect(n, greaterThanOrEqualTo(1));
        expect(n, lessThan(d));
        final spec = q.diagram! as NumberLineSpec;
        expect(spec.min, 0);
        expect(spec.max, 1);
        expect(spec.divisions, d);
        expect(spec.markedPoints, hasLength(1));
        expect(spec.markedPoints.single, closeTo(n / d, 1e-9));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('retrofitted angle diagrams', () {
    test('supplementary_angles emits AngleSpec with labelled wedge', () {
      final re = RegExp(
        r'^Two angles are supplementary\. One is (\d+)°\. '
        r'What is the other\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'supplementary_angles', i);
        final m = re.firstMatch(q.prompt)!;
        final a = int.parse(m.group(1)!);
        final spec = q.diagram! as AngleSpec;
        expect(spec.rayAnglesDeg, [0, a, 180]);
        // First wedge label = "${a}°"; second = "?".
        expect(spec.wedgeLabels, hasLength(2));
        expect(spec.wedgeLabels[0].label, '$a°');
        expect(spec.wedgeLabels[1].label, '?');
      }
    });

    test('triangle_angle_sum emits TriangleAnglesSpec with sum 180°', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'triangle_angle_sum', i);
        final spec = q.diagram! as TriangleAnglesSpec;
        expect(spec.angleDegA + spec.angleDegB + spec.angleDegC, 180);
        expect(spec.labelC, '?');
      }
    });

    test('exterior_angle_triangle shows the exterior marker at C', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'exterior_angle_triangle', i);
        final spec = q.diagram! as TriangleAnglesSpec;
        expect(spec.angleDegA + spec.angleDegB + spec.angleDegC, 180);
        expect(spec.showExteriorAtC, isTrue);
        expect(spec.labelC, '?');
      }
    });

    test('vertical_angles flags different wedges for vert vs adjacent', () {
      final re = RegExp('(vertical to|adjacent to)');
      final modes = <String, Set<int>>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'vertical_angles', i);
        final relation = re.firstMatch(q.prompt)!.group(1)!;
        final spec = q.diagram! as AngleSpec;
        expect(spec.rayAnglesDeg, hasLength(4));
        // Find the "?" wedge.
        final qWedge = spec.wedgeLabels.firstWhere((w) => w.label == '?');
        modes.putIfAbsent(relation, () => <int>{}).add(qWedge.rayIndex);
      }
      // Vertical wedge sits at ray index 2 (opposite the "given" wedge at 0).
      expect(modes['vertical to'], {2});
      // Adjacent wedge at ray index 1.
      expect(modes['adjacent to'], {1});
    });

    test('adjacent_angles wedges sum to 90° or 180°', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'adjacent_angles', i);
        final spec = q.diagram! as AngleSpec;
        expect(spec.rayAnglesDeg, hasLength(3));
        final total = spec.rayAnglesDeg[2] - spec.rayAnglesDeg[0];
        expect([90, 180], contains(total));
      }
    });
  });
}
