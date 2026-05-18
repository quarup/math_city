import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Polygon-on-coordinate-plane generators (`geometry` category, G6 + G8).
///
/// `polygon_on_coordinate_plane` (G6) shows one axis-aligned rectangle
/// or right triangle and asks for its perimeter or area.
///
/// `transformations_translation` (G8) shows a preimage triangle + its
/// image after translating by (Δx, Δy); asks for the image coordinates
/// of one labelled vertex.
///
/// `transformations_reflection` (G8) shows the preimage + its reflection
/// across the x-axis or y-axis; asks for the image coords of a vertex.

const _minus = '−'; // U+2212

String _signed(int n) => n >= 0 ? '$n' : '$_minus${-n}';

String _coord(int x, int y) => '(${_signed(x)}, ${_signed(y)})';

/// Three unique string distractors that differ from [correct].
List<String> _distinctStrings(String correct, List<String> candidates) {
  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  if (out.length < 3) {
    throw StateError(
      'distractor pool exhausted: correct="$correct" candidates=$candidates',
    );
  }
  return out;
}

/// Three unique stringified-integer distractors.
List<String> _distinctIntStrings(int correct, List<String> candidates) {
  final out = <String>[];
  final seen = <String>{'$correct'};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  for (var i = 1; out.length < 3 && i < 30; i++) {
    for (final delta in <int>[i, -i]) {
      final v = correct + delta;
      if (v < 0) continue;
      final s = '$v';
      if (seen.add(s)) out.add(s);
      if (out.length >= 3) break;
    }
  }
  return out.take(3).toList();
}

// ─────────────────────────────────────────────────────────────────────────
// polygon_on_coordinate_plane (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// Show an axis-aligned rectangle plotted with labelled vertices A/B/C/D
/// on a 4-quadrant `[-6, 6]` plane. Ask either "perimeter" or "area"
/// (50/50). Side lengths are integers in [2, 6] so the answer is always
/// a clean integer.
GeneratedQuestion polygonOnCoordinatePlane(Random rand) {
  // Bottom-left corner (lx, ly) ∈ [-5, 5]; width w, height h ∈ [2, 6]
  // with the rectangle fitting inside [-6, 6]².
  final w = rand.nextInt(5) + 2;
  final h = rand.nextInt(5) + 2;
  final lx = rand.nextInt(13 - w) - 6; // [-6, 6-w]
  final ly = rand.nextInt(13 - h) - 6; // [-6, 6-h]
  final vertices = [
    CoordinatePlanePoint(x: lx, y: ly, label: 'A'),
    CoordinatePlanePoint(x: lx + w, y: ly, label: 'B'),
    CoordinatePlanePoint(x: lx + w, y: ly + h, label: 'C'),
    CoordinatePlanePoint(x: lx, y: ly + h, label: 'D'),
  ];

  final askArea = rand.nextBool();
  final perimeter = 2 * (w + h);
  final area = w * h;
  final correct = askArea ? area : perimeter;
  final prompt = askArea
      ? 'What is the area of rectangle ABCD?'
      : 'What is the perimeter of rectangle ABCD?';

  // Misconception distractors:
  //   - the OTHER quantity (kid computed area vs perimeter mix-up)
  //   - w + h (forgot to double for perimeter; or used as area)
  //   - 2*w*h
  final candidates = <String>[
    '${askArea ? perimeter : area}',
    '${w + h}',
    '${2 * w * h}',
    '${w * h + (w + h)}',
  ];

  return GeneratedQuestion(
    conceptId: 'polygon_on_coordinate_plane',
    prompt: prompt,
    diagram: CoordinatePlaneSpec(
      minX: -6,
      maxX: 6,
      minY: -6,
      maxY: 6,
      points: vertices,
      polygons: [
        CoordinatePlanePolygon(
          vertices: vertices,
        ),
      ],
    ),
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: askArea
        ? [
            'Width = $w (from A to B); height = $h (from B to C).',
            'Area = w × h = $w × $h = $area.',
          ]
        : [
            'Width = $w (from A to B); height = $h (from B to C).',
            'Perimeter = 2(w + h) = 2($w + $h) = $perimeter.',
          ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// transformations_translation (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// Show a preimage triangle (solid) + its translation (dashed) on a
/// `[-8, 8]` plane. Ask for the image coordinates of one labelled
/// vertex (A or B or C).
GeneratedQuestion transformationsTranslation(Random rand) {
  // Preimage: 3 vertices on a small triangle inside [-5, 5]² so the
  // translated image fits in [-8, 8]² even for the largest translations.
  late List<List<int>> pre;
  for (var attempt = 0; attempt < 30; attempt++) {
    pre = [
      [rand.nextInt(11) - 5, rand.nextInt(11) - 5],
      [rand.nextInt(11) - 5, rand.nextInt(11) - 5],
      [rand.nextInt(11) - 5, rand.nextInt(11) - 5],
    ];
    // Reject degenerate (collinear / duplicate) cases.
    if (_isNonDegenerateTriangle(pre)) break;
  }

  // Translation vector — non-zero, each component in [-3, 3].
  late int dx;
  late int dy;
  do {
    dx = rand.nextInt(7) - 3;
    dy = rand.nextInt(7) - 3;
  } while (dx == 0 && dy == 0);

  final image = [
    for (final v in pre) [v[0] + dx, v[1] + dy],
  ];

  // Pick which labelled vertex to ask about (A/B/C).
  final askIdx = rand.nextInt(3);
  const labels = ['A', 'B', 'C'];
  final askedLabel = labels[askIdx];
  final correct = _coord(image[askIdx][0], image[askIdx][1]);

  // Misconception distractors:
  //   - applied translation in WRONG direction (subtracted Δ)
  //   - swapped Δx and Δy
  //   - asked-vertex coords with only one component shifted
  final pv = pre[askIdx];
  final candidates = <String>[
    _coord(pv[0] - dx, pv[1] - dy),
    _coord(pv[0] + dy, pv[1] + dx),
    _coord(pv[0] + dx, pv[1]),
    _coord(pv[0], pv[1] + dy),
    _coord(pv[0], pv[1]), // forgot to translate at all
  ];

  final ruleStr = '(x, y) → (x ${_pmComponent(dx)}, y ${_pmComponent(dy)})';

  // Labelled preimage points (A/B/C) so the kid can identify which
  // vertex is which on the diagram.
  final preLabelled = [
    for (var i = 0; i < 3; i++)
      CoordinatePlanePoint(x: pre[i][0], y: pre[i][1], label: labels[i]),
  ];

  return GeneratedQuestion(
    conceptId: 'transformations_translation',
    prompt: 'Translate the triangle by the rule $ruleStr. '
        "What are the coordinates of $askedLabel'?",
    diagram: CoordinatePlaneSpec(
      minX: -8,
      maxX: 8,
      minY: -8,
      maxY: 8,
      points: preLabelled,
      polygons: [
        CoordinatePlanePolygon(
          vertices: preLabelled,
        ),
        CoordinatePlanePolygon(
          vertices: [
            for (var i = 0; i < 3; i++)
              CoordinatePlanePoint(x: image[i][0], y: image[i][1]),
          ],
          style: CoordinatePlanePolygonStyle.dashed,
        ),
      ],
    ),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, candidates),
    explanation: [
      'Translating: add $dx to x, add $dy to y.',
      '${_coord(pv[0], pv[1])} → ${_coord(pv[0] + dx, pv[1] + dy)}.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

/// Format a signed delta for inline use: "+ 3", "− 3", or "+ 0".
String _pmComponent(int d) {
  if (d >= 0) return '+ $d';
  return '$_minus ${-d}';
}

bool _isNonDegenerateTriangle(List<List<int>> pts) {
  // Distinct vertices.
  final keys = pts.map((p) => '${p[0]},${p[1]}').toSet();
  if (keys.length < 3) return false;
  // Non-collinear: cross product of (b-a) and (c-a) must be non-zero.
  final ax = pts[0][0];
  final ay = pts[0][1];
  final bx = pts[1][0];
  final by = pts[1][1];
  final cx = pts[2][0];
  final cy = pts[2][1];
  final cross = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
  return cross != 0;
}

// ─────────────────────────────────────────────────────────────────────────
// transformations_reflection (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// Show a preimage triangle + its reflection across the x-axis OR the
/// y-axis (50/50). Ask for the image coordinates of one labelled vertex.
GeneratedQuestion transformationsReflection(Random rand) {
  // Choose axis. Constrain preimage to one side of that axis so the
  // reflection is visibly distinct (avoids the "point is on the axis,
  // doesn't move" degenerate case for the asked vertex).
  final acrossX = rand.nextBool(); // true → reflect across x-axis
  // For reflection across x-axis: keep y > 0 so the image visibly jumps
  // to the other side. For y-axis: keep x > 0. Force the OTHER axis to
  // also be non-zero so the "negate both coords" misconception distractor
  // ((-x, -y)) never collides with the correct reflection ((x, -y) or
  // (-x, y)): collision requires the non-reflected coord to be 0.
  int pickNonZero() {
    final n = rand.nextInt(11) - 5; // -5..5
    return n == 0 ? (rand.nextBool() ? 1 : -1) : n;
  }

  int sampleX() => acrossX ? pickNonZero() : rand.nextInt(5) + 1;
  int sampleY() => acrossX ? rand.nextInt(5) + 1 : pickNonZero();
  late List<List<int>> pre;
  for (var attempt = 0; attempt < 30; attempt++) {
    pre = [
      [sampleX(), sampleY()],
      [sampleX(), sampleY()],
      [sampleX(), sampleY()],
    ];
    if (_isNonDegenerateTriangle(pre)) break;
  }

  final image = [
    for (final v in pre)
      acrossX ? [v[0], -v[1]] : [-v[0], v[1]],
  ];

  final askIdx = rand.nextInt(3);
  const labels = ['A', 'B', 'C'];
  final askedLabel = labels[askIdx];
  final pv = pre[askIdx];
  final iv = image[askIdx];
  final correct = _coord(iv[0], iv[1]);

  // Misconception distractors:
  //   - reflected across the OTHER axis
  //   - negated both coords (rotated 180° instead)
  //   - swapped coords (reflected across y = x — a different axis)
  //   - unchanged (forgot to reflect)
  final candidates = <String>[
    if (acrossX) _coord(-pv[0], pv[1]) else _coord(pv[0], -pv[1]),
    _coord(-pv[0], -pv[1]),
    _coord(pv[1], pv[0]),
    _coord(pv[0], pv[1]),
  ];

  final preLabelled = [
    for (var i = 0; i < 3; i++)
      CoordinatePlanePoint(x: pre[i][0], y: pre[i][1], label: labels[i]),
  ];
  final axisName = acrossX ? 'x-axis' : 'y-axis';

  return GeneratedQuestion(
    conceptId: 'transformations_reflection',
    prompt: 'Reflect the triangle across the $axisName. '
        "What are the coordinates of $askedLabel'?",
    diagram: CoordinatePlaneSpec(
      minX: -6,
      maxX: 6,
      minY: -6,
      maxY: 6,
      points: preLabelled,
      polygons: [
        CoordinatePlanePolygon(vertices: preLabelled),
        CoordinatePlanePolygon(
          vertices: [
            for (var i = 0; i < 3; i++)
              CoordinatePlanePoint(x: image[i][0], y: image[i][1]),
          ],
          style: CoordinatePlanePolygonStyle.dashed,
        ),
      ],
    ),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, candidates),
    explanation: [
      if (acrossX)
        'Reflecting across the x-axis flips the SIGN of y; x stays.'
      else
        'Reflecting across the y-axis flips the SIGN of x; y stays.',
      '${_coord(pv[0], pv[1])} → ${_coord(iv[0], iv[1])}.',
    ],
    answerFormat: AnswerFormat.string,
  );
}
