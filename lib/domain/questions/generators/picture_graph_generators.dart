import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// K-G3 picture-graph generators sharing the new PictureGraph widget.
/// `classify_count_categories` (K), `three_category_data` (G1),
/// `picture_graph_read` (G2), `scaled_picture_graph` (G3).

/// Themed contexts: each context is a title + a list of (label, icon)
/// rows. The picture-graph generators all rotate through this pool so
/// kids see varied scenarios.
class _PictureContext {
  const _PictureContext({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<(String label, String icon)> rows;
}

const _contexts = <_PictureContext>[
  _PictureContext(
    title: 'Favourite fruit',
    rows: [
      ('Apple', '🍎'),
      ('Banana', '🍌'),
      ('Grape', '🍇'),
      ('Orange', '🍊'),
    ],
  ),
  _PictureContext(
    title: 'Pets at home',
    rows: [
      ('Dog', '🐶'),
      ('Cat', '🐱'),
      ('Fish', '🐟'),
      ('Bird', '🐦'),
    ],
  ),
  _PictureContext(
    title: 'Cars on the street',
    rows: [
      ('Red', '🚗'),
      ('Blue', '🚙'),
      ('Black', '🚕'),
      ('White', '🚐'),
    ],
  ),
  _PictureContext(
    title: "Today's weather log",
    rows: [
      ('Sunny', '☀️'),
      ('Cloudy', '☁️'),
      ('Rainy', '🌧️'),
      ('Snowy', '❄️'),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────
// classify_count_categories (K) — "How many of <one category>?"
// ─────────────────────────────────────────────────────────────────────────

/// Show 2 categories with small counts (1..5 each, distinct); ask for
/// the count of one. CCSS K.MD.B.3.
GeneratedQuestion classifyCountCategories(Random rand) {
  final ctx = _contexts[rand.nextInt(_contexts.length)];
  // Use the first two rows of the context.
  final labels = [ctx.rows[0].$1, ctx.rows[1].$1];
  final icon = ctx.rows[0].$2; // single icon used across rows
  // Counts in [1, 5], pairwise distinct so the wrong-row distractor is
  // unambiguous.
  late int a;
  late int b;
  do {
    a = rand.nextInt(5) + 1;
    b = rand.nextInt(5) + 1;
  } while (a == b);
  final values = [a, b];
  final askIdx = rand.nextInt(2);
  final correct = values[askIdx];
  return GeneratedQuestion(
    conceptId: 'classify_count_categories',
    prompt: 'How many ${labels[askIdx].toLowerCase()}s are there?',
    diagram: PictureGraphSpec(
      title: ctx.title,
      rowLabels: labels,
      values: values,
      icon: icon,
    ),
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: values[1 - askIdx], // read the wrong row
    ),
    explanation: ['Count the icons in the ${labels[askIdx]} row → $correct.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// three_category_data (G1)
// ─────────────────────────────────────────────────────────────────────────

/// Same shape as `classify_count_categories` but with 3 categories and
/// asks one of "how many of a row" or "how many in all". Counts in
/// `[1, 6]`, pairwise distinct. CCSS 1.MD.C.4.
GeneratedQuestion threeCategoryData(Random rand) {
  final ctx = _contexts[rand.nextInt(_contexts.length)];
  final labels = [ctx.rows[0].$1, ctx.rows[1].$1, ctx.rows[2].$1];
  final icon = ctx.rows[0].$2;
  final values = <int>[];
  while (values.length < 3) {
    final v = rand.nextInt(6) + 1;
    if (!values.contains(v)) values.add(v);
  }
  // 50% asks one row, 50% asks the total.
  final askTotal = rand.nextBool();
  if (askTotal) {
    final total = values.reduce((a, b) => a + b);
    return GeneratedQuestion(
      conceptId: 'three_category_data',
      prompt: 'How many in all?',
      diagram: PictureGraphSpec(
        title: ctx.title,
        rowLabels: labels,
        values: values,
        icon: icon,
      ),
      correctAnswer: '$total',
      distractors: integerDistractorsWith(
        total,
        rand,
        // Misconception: gave one row's count.
        misconception: values[rand.nextInt(3)],
      ),
      explanation: ['${values.join(' + ')} = $total.'],
    );
  } else {
    final askIdx = rand.nextInt(3);
    final correct = values[askIdx];
    return GeneratedQuestion(
      conceptId: 'three_category_data',
      prompt: 'How many ${labels[askIdx].toLowerCase()}s are there?',
      diagram: PictureGraphSpec(
        title: ctx.title,
        rowLabels: labels,
        values: values,
        icon: icon,
      ),
      correctAnswer: '$correct',
      distractors: integerDistractorsWith(
        correct,
        rand,
        misconception: values[(askIdx + 1) % 3], // read wrong row
      ),
      explanation: [
        'Count the icons in the ${labels[askIdx]} row → $correct.',
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// picture_graph_read (G2)
// ─────────────────────────────────────────────────────────────────────────

/// 4 categories, scale = 1, counts in [2, 9]. Ask "How many X?" or
/// "How many more X than Y?". CCSS 2.MD.D.10.
GeneratedQuestion pictureGraphRead(Random rand) {
  final ctx = _contexts[rand.nextInt(_contexts.length)];
  final labels = ctx.rows.map((r) => r.$1).toList();
  final icon = ctx.rows[0].$2;
  final values = <int>[];
  while (values.length < 4) {
    final v = rand.nextInt(8) + 2; // 2..9
    if (!values.contains(v)) values.add(v);
  }
  // 50% "how many X", 50% "how many more X than Y" (X > Y).
  final isCompare = rand.nextBool();
  if (!isCompare) {
    final askIdx = rand.nextInt(4);
    final correct = values[askIdx];
    return GeneratedQuestion(
      conceptId: 'picture_graph_read',
      prompt: 'How many ${labels[askIdx].toLowerCase()}s are there?',
      diagram: PictureGraphSpec(
        title: ctx.title,
        rowLabels: labels,
        values: values,
        icon: icon,
      ),
      correctAnswer: '$correct',
      distractors: integerDistractorsWith(
        correct,
        rand,
        misconception: values[(askIdx + 1) % 4],
      ),
      explanation: [
        'Count the icons in the ${labels[askIdx]} row → $correct.',
      ],
    );
  } else {
    // Find a pair (i, j) with values[i] > values[j].
    final pairs = <(int, int)>[];
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        if (i != j && values[i] > values[j]) pairs.add((i, j));
      }
    }
    final (i, j) = pairs[rand.nextInt(pairs.length)];
    final correct = values[i] - values[j];
    return GeneratedQuestion(
      conceptId: 'picture_graph_read',
      prompt:
          'How many more ${labels[i].toLowerCase()}s than '
          '${labels[j].toLowerCase()}s are there?',
      diagram: PictureGraphSpec(
        title: ctx.title,
        rowLabels: labels,
        values: values,
        icon: icon,
      ),
      correctAnswer: '$correct',
      distractors: integerDistractorsWith(
        correct,
        rand,
        // Misconception: gave the sum instead of the difference.
        misconception: values[i] + values[j],
      ),
      explanation: [
        '${values[i]} − ${values[j]} = $correct.',
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// scaled_picture_graph (G3) — "Each 🍎 = 2"
// ─────────────────────────────────────────────────────────────────────────

/// 4 categories, scale ∈ {2, 5, 10}, drawn-icon count in [1, 7],
/// real-value = drawnIcons × scale. CCSS 3.MD.B.3.
GeneratedQuestion scaledPictureGraph(Random rand) {
  final ctx = _contexts[rand.nextInt(_contexts.length)];
  final labels = ctx.rows.map((r) => r.$1).toList();
  final icon = ctx.rows[0].$2;
  final scale = [2, 5, 10][rand.nextInt(3)];
  final iconCounts = <int>[];
  while (iconCounts.length < 4) {
    final v = rand.nextInt(7) + 1; // 1..7 icons drawn per row
    if (!iconCounts.contains(v)) iconCounts.add(v);
  }
  final values = iconCounts.map((n) => n * scale).toList();
  final askIdx = rand.nextInt(4);
  final correct = values[askIdx];
  return GeneratedQuestion(
    conceptId: 'scaled_picture_graph',
    prompt: 'How many ${labels[askIdx].toLowerCase()}s are there?',
    diagram: PictureGraphSpec(
      title: ctx.title,
      rowLabels: labels,
      values: values,
      icon: icon,
      scale: scale,
    ),
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      // Misconception: gave the icon count without multiplying by scale.
      misconception: iconCounts[askIdx],
    ),
    explanation: [
      '${iconCounts[askIdx]} icons × $scale = $correct.',
    ],
  );
}
