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

  group('polygon_on_coordinate_plane', () {
    test(
      '4-vertex axis-aligned rectangle ABCD; answer matches the asked '
      'quantity (area or perimeter); both kinds appear; vertices labelled '
      'A/B/C/D',
      () {
        final kindsSeen = <String>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'polygon_on_coordinate_plane', i);
          expect(q.diagram, isA<CoordinatePlaneSpec>());
          final spec = q.diagram! as CoordinatePlaneSpec;
          expect(spec.polygons, hasLength(1));
          final poly = spec.polygons.single;
          expect(poly.vertices, hasLength(4));
          final labels = poly.vertices.map((v) => v.label).toList();
          expect(labels, ['A', 'B', 'C', 'D']);
          // Axis-aligned: A and B share y; B and C share x; D and C share y;
          // A and D share x.
          final a = poly.vertices[0];
          final b = poly.vertices[1];
          final c = poly.vertices[2];
          final d = poly.vertices[3];
          expect(a.y, b.y);
          expect(b.x, c.x);
          expect(c.y, d.y);
          expect(a.x, d.x);

          final w = (b.x - a.x).abs();
          final h = (c.y - b.y).abs();
          expect(w, inInclusiveRange(2, 6));
          expect(h, inInclusiveRange(2, 6));

          final correct = int.parse(q.correctAnswer);
          if (q.prompt.contains('area')) {
            expect(correct, w * h);
            kindsSeen.add('area');
          } else if (q.prompt.contains('perimeter')) {
            expect(correct, 2 * (w + h));
            kindsSeen.add('perimeter');
          } else {
            fail('Unrecognised prompt: ${q.prompt}');
          }
          _expectThreeDistinctDistractors(q);
        }
        expect(kindsSeen, {'area', 'perimeter'});
      },
    );
  });

  group('transformations_translation', () {
    test(
      'preimage + image polygons; correctAnswer equals preimage vertex '
      'plus (dx, dy) where (dx, dy) recovered from any matching pair',
      () {
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'transformations_translation', i);
          expect(q.diagram, isA<CoordinatePlaneSpec>());
          final spec = q.diagram! as CoordinatePlaneSpec;
          expect(spec.polygons, hasLength(2));
          final pre = spec.polygons[0];
          final img = spec.polygons[1];
          expect(pre.style, CoordinatePlanePolygonStyle.solid);
          expect(img.style, CoordinatePlanePolygonStyle.dashed);
          expect(pre.vertices, hasLength(3));
          expect(img.vertices, hasLength(3));

          // Translation: every image vertex = preimage vertex + same delta.
          final dx = img.vertices[0].x - pre.vertices[0].x;
          final dy = img.vertices[0].y - pre.vertices[0].y;
          for (var k = 1; k < 3; k++) {
            expect(img.vertices[k].x - pre.vertices[k].x, dx);
            expect(img.vertices[k].y - pre.vertices[k].y, dy);
          }
          // Non-zero translation.
          expect(dx == 0 && dy == 0, isFalse);

          // Identify the asked vertex via the prompt's "A' / B' / C'".
          final m = RegExp(r"coordinates of (\w)'\?").firstMatch(q.prompt);
          expect(m, isNotNull, reason: q.prompt);
          final letter = m!.group(1)!;
          final idx = 'ABC'.indexOf(letter);
          expect(idx, isNonNegative);
          final ans = _parseCoord(q.correctAnswer);
          expect(ans, isNotNull);
          expect(ans![0], pre.vertices[idx].x + dx);
          expect(ans[1], pre.vertices[idx].y + dy);
          _expectThreeDistinctDistractors(q);
        }
      },
    );
  });

  group('transformations_rotation', () {
    test(
      'rotation matches the prompt degrees; all 3 rotations appear',
      () {
        final degsSeen = <int>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'transformations_rotation', i);
          expect(q.diagram, isA<CoordinatePlaneSpec>());
          final spec = q.diagram! as CoordinatePlaneSpec;
          expect(spec.polygons, hasLength(2));
          final pre = spec.polygons[0].vertices;
          final img = spec.polygons[1].vertices;
          expect(pre, hasLength(3));
          expect(img, hasLength(3));

          final m = RegExp(r'Rotate the triangle (\d+)°').firstMatch(q.prompt);
          expect(m, isNotNull);
          final deg = int.parse(m!.group(1)!);
          expect(deg, isIn(const [90, 180, 270]));
          degsSeen.add(deg);
          // Each image vertex matches the rotation rule.
          for (var k = 0; k < 3; k++) {
            final p = pre[k];
            final iV = img[k];
            switch (deg) {
              case 90:
                expect(iV.x, -p.y);
                expect(iV.y, p.x);
              case 180:
                expect(iV.x, -p.x);
                expect(iV.y, -p.y);
              case 270:
                expect(iV.x, p.y);
                expect(iV.y, -p.x);
            }
          }
          _expectThreeDistinctDistractors(q);
        }
        expect(degsSeen, {90, 180, 270});
      },
    );
  });

  group('transformations_dilation', () {
    test(
      'image vertex = k × preimage vertex; k ∈ {2, 3}; both factors appear',
      () {
        final kSeen = <int>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'transformations_dilation', i);
          expect(q.diagram, isA<CoordinatePlaneSpec>());
          final spec = q.diagram! as CoordinatePlaneSpec;
          expect(spec.polygons, hasLength(2));
          final pre = spec.polygons[0].vertices;
          final img = spec.polygons[1].vertices;
          expect(pre, hasLength(3));
          expect(img, hasLength(3));

          final m = RegExp(r'factor (\d+)').firstMatch(q.prompt);
          expect(m, isNotNull);
          final k = int.parse(m!.group(1)!);
          expect(k, isIn(const [2, 3]));
          kSeen.add(k);
          for (var i = 0; i < 3; i++) {
            expect(img[i].x, k * pre[i].x);
            expect(img[i].y, k * pre[i].y);
          }
          _expectThreeDistinctDistractors(q);
        }
        expect(kSeen, {2, 3});
      },
    );
  });

  group('congruence_via_transformations', () {
    test(
      'correctAnswer is one of {Yes, No}; image vertices match a rigid '
      'transformation iff Yes, or are a (k≥2)× scaling of preimage iff No; '
      'both outcomes appear',
      () {
        final outcomesSeen = <String>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'congruence_via_transformations', i);
          expect(q.diagram, isA<CoordinatePlaneSpec>());
          final spec = q.diagram! as CoordinatePlaneSpec;
          expect(spec.polygons, hasLength(2));
          final pre = spec.polygons[0].vertices;
          final img = spec.polygons[1].vertices;
          expect(pre, hasLength(3));
          expect(img, hasLength(3));

          final isCongruent = q.correctAnswer.startsWith('Yes');
          outcomesSeen.add(isCongruent ? 'yes' : 'no');

          // Confirm: if congruent, side lengths preserved; if not,
          // image is a scaling so all image vertices are k × preimage
          // for some k > 1.
          double dist(CoordinatePlanePoint a, CoordinatePlanePoint b) {
            final dx = (a.x - b.x).toDouble();
            final dy = (a.y - b.y).toDouble();
            return dx * dx + dy * dy;
          }

          final preSides = [
            dist(pre[0], pre[1]),
            dist(pre[1], pre[2]),
            dist(pre[2], pre[0]),
          ];
          final imgSides = [
            dist(img[0], img[1]),
            dist(img[1], img[2]),
            dist(img[2], img[0]),
          ];
          if (isCongruent) {
            // Same multiset of squared lengths.
            preSides.sort();
            imgSides.sort();
            for (var k = 0; k < 3; k++) {
              expect(imgSides[k], closeTo(preSides[k], 1e-6));
            }
          } else {
            // Squared side ratios all equal and > 1.
            final ratios = [
              for (var k = 0; k < 3; k++) imgSides[k] / preSides[k],
            ];
            expect(ratios[0], greaterThan(1));
            expect(ratios[1], closeTo(ratios[0], 1e-6));
            expect(ratios[2], closeTo(ratios[0], 1e-6));
          }
          _expectThreeDistinctDistractors(q);
        }
        expect(outcomesSeen, {'yes', 'no'});
      },
    );
  });

  group('similarity_via_transformations', () {
    test(
      'correctAnswer is one of {Yes, No}; image side ratios are uniform '
      'iff Yes; both outcomes appear',
      () {
        final outcomesSeen = <String>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'similarity_via_transformations', i);
          expect(q.diagram, isA<CoordinatePlaneSpec>());
          final spec = q.diagram! as CoordinatePlaneSpec;
          expect(spec.polygons, hasLength(2));
          final pre = spec.polygons[0].vertices;
          final img = spec.polygons[1].vertices;

          final isSimilar = q.correctAnswer.startsWith('Yes');
          outcomesSeen.add(isSimilar ? 'yes' : 'no');

          double dist(CoordinatePlanePoint a, CoordinatePlanePoint b) {
            final dx = (a.x - b.x).toDouble();
            final dy = (a.y - b.y).toDouble();
            return dx * dx + dy * dy;
          }

          final preSides = [
            dist(pre[0], pre[1]),
            dist(pre[1], pre[2]),
            dist(pre[2], pre[0]),
          ];
          final imgSides = [
            dist(img[0], img[1]),
            dist(img[1], img[2]),
            dist(img[2], img[0]),
          ];
          // For similar figures: side ratios are constant (within tolerance).
          // For non-similar: at least one side ratio differs from the others.
          final r0 = imgSides[0] / preSides[0];
          final r1 = imgSides[1] / preSides[1];
          final r2 = imgSides[2] / preSides[2];
          final maxDelta = [
            (r0 - r1).abs(),
            (r1 - r2).abs(),
            (r0 - r2).abs(),
          ].reduce((a, b) => a > b ? a : b);
          if (isSimilar) {
            expect(
              maxDelta,
              lessThan(1e-6),
              reason: 'similar figures should have uniform side ratios',
            );
          } else {
            expect(
              maxDelta,
              greaterThan(1e-6),
              reason: 'non-similar figures should have varying ratios',
            );
          }
          _expectThreeDistinctDistractors(q);
        }
        expect(outcomesSeen, {'yes', 'no'});
      },
    );
  });

  group('transformations_reflection', () {
    test(
      'preimage + image polygons; axis taken from prompt; image vertex = '
      'preimage with appropriate sign flip; both axes appear',
      () {
        final axesSeen = <String>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'transformations_reflection', i);
          expect(q.diagram, isA<CoordinatePlaneSpec>());
          final spec = q.diagram! as CoordinatePlaneSpec;
          expect(spec.polygons, hasLength(2));
          final pre = spec.polygons[0];
          final img = spec.polygons[1];
          expect(pre.vertices, hasLength(3));
          expect(img.vertices, hasLength(3));

          final acrossX = q.prompt.contains('x-axis');
          axesSeen.add(acrossX ? 'x' : 'y');
          for (var k = 0; k < 3; k++) {
            final p = pre.vertices[k];
            final iV = img.vertices[k];
            if (acrossX) {
              expect(iV.x, p.x);
              expect(iV.y, -p.y);
            } else {
              expect(iV.x, -p.x);
              expect(iV.y, p.y);
            }
          }

          final m = RegExp(r"coordinates of (\w)'\?").firstMatch(q.prompt);
          expect(m, isNotNull);
          final letter = m!.group(1)!;
          final idx = 'ABC'.indexOf(letter);
          final ans = _parseCoord(q.correctAnswer);
          expect(ans, isNotNull);
          expect(ans![0], img.vertices[idx].x);
          expect(ans[1], img.vertices[idx].y);
          _expectThreeDistinctDistractors(q);
        }
        expect(axesSeen, {'x', 'y'});
      },
    );
  });
}
