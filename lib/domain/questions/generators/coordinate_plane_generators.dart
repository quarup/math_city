import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Coordinate-plane generators using the [CoordinatePlaneSpec] /
/// `CoordinatePlane` widget.
///
/// `plot_*_quadrant` show four candidate points labelled A–D and ask
/// "Which point is at (x, y)?" Distractor points are designed to bait the
/// most common misconceptions (swap x/y, off-by-one in either axis).
///
/// `read_first_quadrant` shows a single labelled point A and asks "What
/// are its coordinates?" with the same misconception distractors as
/// answer choices.

const _minus = '−'; // U+2212

String _coord(int x, int y) {
  String fmt(int n) => n >= 0 ? '$n' : '$_minus${-n}';
  return '(${fmt(x)}, ${fmt(y)})';
}

/// Pick three distractor points for a target `(x, y)` so the four points
/// (target + 3 distractors) are pairwise distinct and all lie inside the
/// box `[minX, maxX] × [minY, maxY]`. Distractor strategy: swap, x-off,
/// y-off — falls back to wider deltas if the first picks collide.
List<List<int>> _pickDistractorPoints(
  int x,
  int y,
  Random rand, {
  required int minX,
  required int maxX,
  required int minY,
  required int maxY,
}) {
  // Candidate distractors, ordered by misconception strength.
  final swapped = [y, x];

  bool inBox(int xx, int yy) =>
      xx >= minX && xx <= maxX && yy >= minY && yy <= maxY;

  // Deltas to try in order; shuffle so distractor positions vary across
  // seeds without changing the "off by one in x" / "off by one in y"
  // categories.
  final deltas = <int>[1, -1, 2, -2]..shuffle(rand);

  int? pickXOff() {
    for (final d in deltas) {
      final xx = x + d;
      if (xx == x) continue;
      if (!inBox(xx, y)) continue;
      // Avoid colliding with the swap-distractor.
      if (xx == swapped[0] && y == swapped[1]) continue;
      return xx;
    }
    return null;
  }

  int? pickYOff() {
    for (final d in deltas) {
      final yy = y + d;
      if (yy == y) continue;
      if (!inBox(x, yy)) continue;
      if (x == swapped[0] && yy == swapped[1]) continue;
      return yy;
    }
    return null;
  }

  final xOff = pickXOff();
  final yOff = pickYOff();

  final out = <List<int>>[];
  final seen = <String>{'$x,$y'};
  void tryAdd(List<int> p) {
    final key = '${p[0]},${p[1]}';
    if (seen.add(key)) out.add(p);
  }

  if (inBox(swapped[0], swapped[1])) tryAdd(swapped);
  if (xOff != null) tryAdd([xOff, y]);
  if (yOff != null) tryAdd([x, yOff]);

  // Fallback: any in-box point distinct from those already chosen.
  for (final dx in <int>[1, -1, 2, -2, 3, -3]) {
    if (out.length >= 3) break;
    for (final dy in <int>[1, -1, 2, -2, 3, -3]) {
      if (out.length >= 3) break;
      final p = [x + dx, y + dy];
      if (inBox(p[0], p[1])) tryAdd(p);
    }
  }
  return out.take(3).toList();
}

// ─────────────────────────────────────────────────────────────────────────
// plot_first_quadrant (Grade 5)
// ─────────────────────────────────────────────────────────────────────────

/// "Which point is at (3, 5)?" → "B". Diagram shows four labelled
/// points (A, B, C, D) in the first quadrant; one is at the target, the
/// other three are at the swap and off-by-one misconceptions.
GeneratedQuestion plotFirstQuadrant(Random rand) {
  // Target in [1, 8] × [1, 8] with x != y so the swap distractor is
  // genuinely a different point.
  late int x;
  late int y;
  do {
    x = rand.nextInt(8) + 1;
    y = rand.nextInt(8) + 1;
  } while (x == y);

  final distractors = _pickDistractorPoints(
    x, y, rand,
    minX: 0, maxX: 10, minY: 0, maxY: 10,
  );

  // Shuffle four (point, label) pairs.
  final allPoints = <List<int>>[
    [x, y],
    ...distractors,
  ];
  final labels = ['A', 'B', 'C', 'D'];
  final order = List<int>.generate(4, (i) => i)..shuffle(rand);

  final points = <CoordinatePlanePoint>[];
  late String correctLabel;
  for (var i = 0; i < 4; i++) {
    final p = allPoints[order[i]];
    final label = labels[i];
    points.add(CoordinatePlanePoint(x: p[0], y: p[1], label: label));
    if (order[i] == 0) correctLabel = label;
  }

  return GeneratedQuestion(
    conceptId: 'plot_first_quadrant',
    prompt: 'Which point is at ${_coord(x, y)}?',
    diagram: CoordinatePlaneSpec(
      minX: 0, maxX: 10, minY: 0, maxY: 10,
      points: points,
    ),
    correctAnswer: correctLabel,
    distractors: labels.where((l) => l != correctLabel).toList(),
    explanation: [
      'Find x = $x on the bottom axis, then go up to y = $y.',
      'Point $correctLabel is at ${_coord(x, y)}.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// read_first_quadrant (Grade 5)
// ─────────────────────────────────────────────────────────────────────────

/// "What are the coordinates of point A?" → "(3, 5)". Diagram shows one
/// labelled point A; MC distractors are the swap and off-by-one
/// misconception coordinates.
GeneratedQuestion readFirstQuadrant(Random rand) {
  late int x;
  late int y;
  do {
    x = rand.nextInt(8) + 1;
    y = rand.nextInt(8) + 1;
  } while (x == y);

  final distractorPoints = _pickDistractorPoints(
    x, y, rand,
    minX: 0, maxX: 10, minY: 0, maxY: 10,
  );

  return GeneratedQuestion(
    conceptId: 'read_first_quadrant',
    prompt: 'What are the coordinates of point A?',
    diagram: CoordinatePlaneSpec(
      minX: 0, maxX: 10, minY: 0, maxY: 10,
      points: [CoordinatePlanePoint(x: x, y: y, label: 'A')],
    ),
    correctAnswer: _coord(x, y),
    distractors: distractorPoints.map((p) => _coord(p[0], p[1])).toList(),
    explanation: [
      'Read the x-coordinate first: A sits above x = $x.',
      'Then the y-coordinate: A sits across from y = $y.',
      'So A = ${_coord(x, y)}.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// plot_four_quadrants (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Which point is at (−2, 3)?" → "C". Same shape as
/// [plotFirstQuadrant] but the target's x and y can each be negative;
/// neither is allowed to be 0 (axis points are visually ambiguous on a
/// small grid).
GeneratedQuestion plotFourQuadrants(Random rand) {
  int pickNonZero() {
    final n = rand.nextInt(11) - 5; // -5..5
    return n == 0 ? (rand.nextBool() ? 1 : -1) : n;
  }

  late int x;
  late int y;
  do {
    x = pickNonZero();
    y = pickNonZero();
  } while (x == y);

  final distractors = _pickDistractorPoints(
    x, y, rand,
    minX: -5, maxX: 5, minY: -5, maxY: 5,
  );

  final allPoints = <List<int>>[
    [x, y],
    ...distractors,
  ];
  final labels = ['A', 'B', 'C', 'D'];
  final order = List<int>.generate(4, (i) => i)..shuffle(rand);

  final points = <CoordinatePlanePoint>[];
  late String correctLabel;
  for (var i = 0; i < 4; i++) {
    final p = allPoints[order[i]];
    final label = labels[i];
    points.add(CoordinatePlanePoint(x: p[0], y: p[1], label: label));
    if (order[i] == 0) correctLabel = label;
  }

  return GeneratedQuestion(
    conceptId: 'plot_four_quadrants',
    prompt: 'Which point is at ${_coord(x, y)}?',
    diagram: CoordinatePlaneSpec(
      minX: -5, maxX: 5, minY: -5, maxY: 5,
      points: points,
    ),
    correctAnswer: correctLabel,
    distractors: labels.where((l) => l != correctLabel).toList(),
    explanation: [
      'x is ${x >= 0 ? "right" : "left"} of the y-axis.',
      'y is ${y >= 0 ? "above" : "below"} the x-axis.',
      'Point $correctLabel is at ${_coord(x, y)}.',
    ],
    answerFormat: AnswerFormat.string,
  );
}
