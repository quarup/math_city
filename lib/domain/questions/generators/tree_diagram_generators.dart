import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Tree-diagram generators (Grade 7, `stats` category).
///
/// `tree_diagram` shows a 2-stage compound experiment and asks "How
/// many outcomes are in the sample space?" — answer is the product of
/// branching factors. `compound_event_probability` shows the same kind
/// of tree and asks for P(specific compound outcome) — answer is a
/// unit fraction `1/leafCount`.
///
/// All experiments self-limit to ≤ 9 leaves so the rendered tree stays
/// readable on phone screens.

final _experiments = <List<TreeDiagramStage>>[
  [
    TreeDiagramStage(label: 'Coin', outcomes: ['H', 'T']),
    TreeDiagramStage(label: 'Coin', outcomes: ['H', 'T']),
  ],
  [
    TreeDiagramStage(label: 'Coin', outcomes: ['H', 'T']),
    TreeDiagramStage(label: 'Spinner', outcomes: ['R', 'G', 'B']),
  ],
  [
    TreeDiagramStage(label: 'Spinner', outcomes: ['1', '2', '3']),
    TreeDiagramStage(label: 'Coin', outcomes: ['H', 'T']),
  ],
  [
    TreeDiagramStage(label: 'Spinner', outcomes: ['R', 'G', 'B']),
    TreeDiagramStage(label: 'Spinner', outcomes: ['1', '2', '3']),
  ],
];

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
      if (v < 1) continue; // counts must be ≥ 1
      final s = '$v';
      if (seen.add(s)) out.add(s);
      if (out.length >= 3) break;
    }
  }
  return out.take(3).toList();
}

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

String _phraseFor(List<TreeDiagramStage> stages) {
  if (stages.length == 2) {
    return 'You ${_verbFor(stages[0])} and then ${_verbFor(stages[1])}.';
  }
  return 'You perform ${stages.length} stages.';
}

String _verbFor(TreeDiagramStage s) {
  switch (s.label) {
    case 'Coin':
      return 'flip a coin';
    case 'Spinner':
      return 'spin a ${s.outcomes.length}-section spinner';
    case 'Die':
      return 'roll a die';
  }
  return 'perform ${s.label}';
}

// ─────────────────────────────────────────────────────────────────────────
// tree_diagram (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "How many possible outcomes are there?" Answer = product of stage
/// branching factors. Distractors include sum (added instead of
/// multiplied), individual stage counts, and off-by-one product.
GeneratedQuestion treeDiagram(Random rand) {
  final stages = _experiments[rand.nextInt(_experiments.length)];
  final spec = TreeDiagramSpec(stages: stages);
  final correct = spec.leafCount;
  final n1 = stages[0].outcomes.length;
  final n2 = stages[1].outcomes.length;

  final candidates = <String>[
    '${n1 + n2}', // sum instead of product
    '$n1',
    '$n2',
    '${correct + 1}',
    '${correct - 1}',
  ];

  return GeneratedQuestion(
    conceptId: 'tree_diagram',
    prompt: '${_phraseFor(stages)} '
        'How many possible outcomes are there in total?',
    diagram: spec,
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: [
      'Stage 1 has $n1 outcomes; stage 2 has $n2 outcomes.',
      'Total outcomes = $n1 × $n2 = $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// compound_event_probability (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "What is P(asked compound outcome)?" Each leaf is equally likely
/// (uniform), so the answer is `1 / leafCount`. Distractors are common
/// confusions: `1 / n1`, `1 / n2`, `1 / (n1 + n2)`, `n1 / n2`.
GeneratedQuestion compoundEventProbability(Random rand) {
  final stages = _experiments[rand.nextInt(_experiments.length)];
  final spec = TreeDiagramSpec(stages: stages);
  final leaves = spec.leafCount;
  final n1 = stages[0].outcomes.length;
  final n2 = stages[1].outcomes.length;

  // Pick a specific compound outcome to ask about.
  final i = rand.nextInt(n1);
  final j = rand.nextInt(n2);
  final outcomeStr = '${stages[0].outcomes[i]} and ${stages[1].outcomes[j]}';

  final correct = Fraction(1, leaves).toCanonical();
  // Misconception distractors. Use 1/(leaves ± 1) as off-by-one fallbacks
  // since the natural misconceptions (1/n1, 1/n2, 1/(n1+n2)) collapse
  // to the same fraction for small symmetric experiments like 2 × 2 = 4.
  final candidates = <String>[
    Fraction(1, n1).toCanonical(),
    Fraction(1, n2).toCanonical(),
    Fraction(2, leaves).toCanonical(),
    Fraction(1, leaves + 1).toCanonical(),
    Fraction(1, leaves - 1).toCanonical(),
  ];

  return GeneratedQuestion(
    conceptId: 'compound_event_probability',
    prompt: '${_phraseFor(stages)} '
        'What is the probability of getting $outcomeStr?',
    diagram: spec,
    correctAnswer: correct,
    distractors: _distinctStrings(correct, candidates),
    explanation: [
      'Each leaf of the tree is equally likely.',
      'There are $leaves leaves and 1 matches "$outcomeStr".',
      'So P = 1/$leaves = $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}
