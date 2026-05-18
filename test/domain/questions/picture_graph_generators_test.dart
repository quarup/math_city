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

PictureGraphSpec _spec(GeneratedQuestion q) => q.diagram! as PictureGraphSpec;

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('classify_count_categories', () {
    test('2 rows, counts 1..5 distinct, answer is one of the row values', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'classify_count_categories', i);
        final spec = _spec(q);
        expect(spec.rowLabels, hasLength(2));
        expect(spec.values, hasLength(2));
        expect(spec.scale, 1);
        for (final v in spec.values) {
          expect(v, inInclusiveRange(1, 5));
        }
        expect(spec.values.toSet().length, 2);
        expect(spec.values, contains(int.parse(q.correctAnswer)));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('three_category_data', () {
    test('3 rows, counts 1..6 distinct; answer is a row or the total', () {
      final flavors = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'three_category_data', i);
        final spec = _spec(q);
        expect(spec.rowLabels, hasLength(3));
        expect(spec.values, hasLength(3));
        for (final v in spec.values) {
          expect(v, inInclusiveRange(1, 6));
        }
        expect(spec.values.toSet().length, 3);
        final correct = int.parse(q.correctAnswer);
        final total = spec.values.reduce((a, b) => a + b);
        if (correct == total) {
          flavors.add('total');
        } else {
          expect(spec.values, contains(correct));
          flavors.add('one-row');
        }
        _expectThreeDistinctDistractors(q);
      }
      expect(flavors, {'total', 'one-row'});
    });
  });

  group('picture_graph_read', () {
    test('4 rows, counts 2..9 distinct; "how many" or difference flavor', () {
      final flavors = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'picture_graph_read', i);
        final spec = _spec(q);
        expect(spec.rowLabels, hasLength(4));
        expect(spec.values, hasLength(4));
        for (final v in spec.values) {
          expect(v, inInclusiveRange(2, 9));
        }
        expect(spec.values.toSet().length, 4);
        final correct = int.parse(q.correctAnswer);
        if (spec.values.contains(correct)) {
          flavors.add('one-row');
        } else {
          // Difference flavor: answer is values[i] - values[j] for some i, j.
          var found = false;
          for (var i2 = 0; i2 < 4; i2++) {
            for (var j2 = 0; j2 < 4; j2++) {
              if (i2 != j2 &&
                  spec.values[i2] - spec.values[j2] == correct &&
                  correct > 0) {
                found = true;
              }
            }
          }
          expect(found, isTrue, reason: 'unexpected answer ${q.correctAnswer}');
          flavors.add('compare');
        }
        _expectThreeDistinctDistractors(q);
      }
      expect(flavors, {'one-row', 'compare'});
    });
  });

  group('scaled_picture_graph', () {
    test('scale ∈ {2,5,10}, answer = drawnIcons × scale', () {
      final scalesSeen = <int>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'scaled_picture_graph', i);
        final spec = _spec(q);
        expect([2, 5, 10], contains(spec.scale));
        scalesSeen.add(spec.scale);
        for (final v in spec.values) {
          expect(v % spec.scale, 0);
          final iconCount = v ~/ spec.scale;
          expect(iconCount, inInclusiveRange(1, 7));
        }
        final correct = int.parse(q.correctAnswer);
        expect(spec.values, contains(correct));
        _expectThreeDistinctDistractors(q);
      }
      expect(scalesSeen, {2, 5, 10});
    });
  });
}
