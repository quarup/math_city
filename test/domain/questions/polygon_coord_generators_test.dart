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
