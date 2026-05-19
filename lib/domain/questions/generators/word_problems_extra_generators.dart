import 'dart:math';

import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/word_problems/word_problem_framework.dart';

/// Additional dataset/optional word-problem generators that template
/// cleanly: length, money, liquid-volume, multi-step mult/div, area-
/// perimeter, multi-step unit conversion, and the two judgment-item
/// stats concepts (`statistical_question`, `sampling_representativeness`).

// ─────────────────────────────────────────────────────────────────────────
// length_word_problems (G2)
// ─────────────────────────────────────────────────────────────────────────

const _lengthItems = [
  ('rope', 'cm'),
  ('ribbon', 'cm'),
  ('string', 'cm'),
  ('plank', 'in'),
  ('hose', 'ft'),
];

/// "Maria has a rope that is 25 cm long. She buys 15 cm more. How long
/// is the rope now?" → 40. Single-step length word problem, balanced
/// 50/50 between + and −.
GeneratedQuestion lengthWordProblems(Random rand) {
  final item = _lengthItems[rand.nextInt(_lengthItems.length)];
  final isAdd = rand.nextBool();
  final name = pickRandom(wordProblemNames, rand);
  late int a;
  late int b;
  late int correct;
  late String prompt;
  if (isAdd) {
    a = rand.nextInt(60) + 10; // 10..69
    b = rand.nextInt(30) + 5; // 5..34
    correct = a + b;
    prompt =
        '$name has a ${item.$1} that is $a ${item.$2} long. '
        '$name attaches $b ${item.$2} more. '
        'How long is the ${item.$1} now, in ${item.$2}?';
  } else {
    a = rand.nextInt(60) + 30; // 30..89
    b = rand.nextInt(a - 5) + 3; // 3..(a-3)
    if (b > 30) b = 30;
    correct = a - b;
    prompt =
        '$name has a ${item.$1} that is $a ${item.$2} long. '
        '$name cuts off $b ${item.$2}. '
        'How long is the ${item.$1} now, in ${item.$2}?';
  }
  return GeneratedQuestion(
    conceptId: 'length_word_problems',
    prompt: prompt,
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: isAdd ? (a - b).abs() : a + b,
    ),
    explanation: [
      '$a ${isAdd ? "+" : "−"} $b = $correct ${item.$2}.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// money_word_problems (G2)
// ─────────────────────────────────────────────────────────────────────────

/// "Maria has 3 dimes and 2 nickels. How much money does she have in
/// cents?" — uses standard US coin values. 50/50 between coin-count and
/// straightforward $ word problem.
GeneratedQuestion moneyWordProblems(Random rand) {
  final flavor = rand.nextInt(2);
  final name = pickRandom(wordProblemNames, rand);
  if (flavor == 0) {
    // Coins: pick two distinct coin types.
    const coins = [
      ('pennies', 1),
      ('nickels', 5),
      ('dimes', 10),
      ('quarters', 25),
    ];
    final i = rand.nextInt(coins.length);
    var j = rand.nextInt(coins.length);
    while (j == i) {
      j = rand.nextInt(coins.length);
    }
    final n1 = rand.nextInt(5) + 2; // 2..6
    final n2 = rand.nextInt(5) + 2;
    final correct = n1 * coins[i].$2 + n2 * coins[j].$2;
    return GeneratedQuestion(
      conceptId: 'money_word_problems',
      prompt:
          '$name has $n1 ${coins[i].$1} and $n2 ${coins[j].$1}. '
          'How much money does $name have, in cents?',
      correctAnswer: '$correct',
      distractors: integerDistractorsWith(
        correct,
        rand,
        misconception: n1 + n2, // counted coins, ignored value
      ),
      explanation: [
        '$n1 × ${coins[i].$2}¢ + $n2 × ${coins[j].$2}¢ = $correct¢.',
      ],
    );
  } else {
    // Dollars: simple +/− word problem.
    final start = rand.nextInt(40) + 20; // 20..59
    final spend = rand.nextInt(start - 5) + 2; // 2..(start-3)
    final correct = start - spend;
    return GeneratedQuestion(
      conceptId: 'money_word_problems',
      prompt:
          '$name has \$$start. $name spends \$$spend at the store. '
          'How much money does $name have left, in dollars?',
      correctAnswer: '$correct',
      distractors: integerDistractorsWith(
        correct,
        rand,
        misconception: start + spend,
      ),
      explanation: ['$start − $spend = $correct dollars.'],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// liquid_volume_mass (G3)
// ─────────────────────────────────────────────────────────────────────────

/// "A pitcher holds 1500 mL of juice. Maria pours out 400 mL. How much
/// is left?" — single-step subtraction word problem with liquid volume
/// or mass. CCSS 3.MD.A.2.
GeneratedQuestion liquidVolumeMass(Random rand) {
  const scenarios = [
    ('pitcher', 'pours out', 'mL', 'of juice'),
    ('bottle', 'drinks', 'mL', 'of water'),
    ('tank', 'drains', 'L', 'of water'),
    ('bag', 'spills', 'g', 'of flour'),
    ('jar', 'removes', 'g', 'of sugar'),
  ];
  final s = scenarios[rand.nextInt(scenarios.length)];
  final name = pickRandom(wordProblemNames, rand);
  final start = rand.nextInt(900) + 100; // 100..999
  final removed = rand.nextInt(start - 50) + 25; // 25..(start-25)
  final correct = start - removed;
  return GeneratedQuestion(
    conceptId: 'liquid_volume_mass',
    prompt:
        'A ${s.$1} has $start ${s.$3} ${s.$4}. $name ${s.$2} $removed ${s.$3}. '
        'How much is left, in ${s.$3}?',
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: start + removed,
    ),
    explanation: ['$start − $removed = $correct ${s.$3}.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// mult_div_word_2step (G4)
// ─────────────────────────────────────────────────────────────────────────

/// Two-step word problem. Flavor 0: mult-then-sub (a × b − c) using
/// a multiplication context from [multContextsV1] to set up the
/// product, then a subtraction context from [addSubContextsV1] to
/// take away c. Flavor 1: add-then-divide ((a + b) ÷ c). CCSS 4.OA.A.3.
GeneratedQuestion multDivWord2step(Random rand) {
  final name = pickRandom(wordProblemNames, rand);
  final flavor = rand.nextInt(2);
  if (flavor == 0) {
    // a × b − c, framed via a mult context + a sub context.
    final a = rand.nextInt(7) + 3; // 3..9
    final b = rand.nextInt(8) + 4; // 4..11
    final c = rand.nextInt(a * b - 5) + 3; // 3..(a*b-3)
    final correct = a * b - c;

    // Pick a mult context first; the sub context must use the same
    // item pool (subset of edibles if the mult context demands it).
    final multCtx = pickRandom(multContextsV1, rand);
    final subCtxPool = addSubContextsV1
        .where((c) => c.op == WordProblemOp.sub)
        .where((c) => !multCtx.requiresEdibleItems || c.requiresEdibleItems
            // sub `eats` requires edibles; only block when the mult
            // context is bakes (edibles) and the sub context would
            // otherwise pick a non-edible verb.
            || !c.requiresEdibleItems)
        .toList();
    final subCtx = pickRandom(subCtxPool, rand);
    final items = (multCtx.requiresEdibleItems || subCtx.requiresEdibleItems)
        ? pickRandom(edibleWordProblemItems, rand)
        : pickRandom(wordProblemItems, rand);

    final setup = composeMultActionSentence(
      name: name,
      items: items,
      a: a,
      b: b,
      context: multCtx,
    );
    final subAction = subCtx.action
        .replaceAll('{Name}', name)
        .replaceAll('{b}', '$c')
        .replaceAll('{items}', items);
    final prompt = '$setup Then $subAction '
        'How many $items does $name have left?';

    return GeneratedQuestion(
      conceptId: 'mult_div_word_2step',
      prompt: prompt,
      correctAnswer: '$correct',
      distractors: integerDistractorsWith(
        correct,
        rand,
        misconception: a * b + c, // wrong sign on the second step
      ),
      explanation: [
        '$a × $b = ${a * b}',
        '${a * b} − $c = $correct',
      ],
    );
  } else {
    // (a + b) ÷ c — re-rolls until exactly divisible.
    late int a;
    late int b;
    late int c;
    do {
      a = rand.nextInt(40) + 10; // 10..49
      b = rand.nextInt(40) + 10;
      c = rand.nextInt(5) + 2; // 2..6
    } while ((a + b) % c != 0);
    final correct = (a + b) ~/ c;
    return GeneratedQuestion(
      conceptId: 'mult_div_word_2step',
      prompt:
          '$name picks $a apples on Monday and $b apples on Tuesday. '
          '$name puts them equally into $c baskets. '
          'How many apples per basket?',
      correctAnswer: '$correct',
      distractors: integerDistractorsWith(
        correct,
        rand,
        misconception: (a + b) - c,
      ),
      explanation: [
        '$a + $b = ${a + b}',
        '${a + b} ÷ $c = $correct',
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// area_perimeter_word (G4)
// ─────────────────────────────────────────────────────────────────────────

/// "A garden is 7 m long and 5 m wide. What is the area?" → 35. Or
/// "...What is the perimeter?" → 24. Square/rectangular gardens with
/// integer sides.
GeneratedQuestion areaPerimeterWord(Random rand) {
  final length = rand.nextInt(11) + 4; // 4..14
  final width = rand.nextInt(11) + 4;
  final askArea = rand.nextBool();
  final correct = askArea ? length * width : 2 * (length + width);
  final ask = askArea ? 'area, in square meters' : 'perimeter, in meters';
  return GeneratedQuestion(
    conceptId: 'area_perimeter_word',
    prompt:
        'A garden is $length m long and $width m wide. '
        'What is its $ask?',
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      // Misconception: gave the other measure.
      misconception: askArea ? 2 * (length + width) : length * width,
    ),
    explanation: [
      if (askArea)
        'Area = length × width = $length × $width = $correct m².'
      else
        'Perimeter = 2(l + w) = 2($length + $width) = $correct m.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// convert_units_multistep (G5)
// ─────────────────────────────────────────────────────────────────────────

/// "A rope is 3 m 25 cm long. How long is it in cm?" → 325. Two-step
/// unit conversion within a system; tests CCSS 5.MD.A.1.
GeneratedQuestion convertUnitsMultistep(Random rand) {
  const conversions = [
    ('m', 'cm', 100, 'rope'),
    ('km', 'm', 1000, 'road'),
    ('hr', 'min', 60, 'movie'),
    ('min', 's', 60, 'song'),
    ('kg', 'g', 1000, 'bag'),
  ];
  final c = conversions[rand.nextInt(conversions.length)];
  final big = rand.nextInt(8) + 2; // 2..9
  final small = rand.nextInt(c.$3 - 50) + 25; // ensure < big-unit threshold
  final correct = big * c.$3 + small;
  return GeneratedQuestion(
    conceptId: 'convert_units_multistep',
    prompt:
        'A ${c.$4} is $big ${c.$1} $small ${c.$2} long. '
        'How long is it in ${c.$2}?',
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: big + small, // forgot to convert
    ),
    explanation: [
      '$big ${c.$1} = $big × ${c.$3} = ${big * c.$3} ${c.$2}.',
      '${big * c.$3} + $small = $correct ${c.$2}.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// statistical_question (G6)
// ─────────────────────────────────────────────────────────────────────────

const _statisticalQuestions = [
  // (statistical, non-statistical-counterpart) pairs.
  (
    'How tall are the students in this class?',
    'How tall is Maria?',
  ),
  (
    'How many minutes did students in 5th grade spend on homework last night?',
    'How many minutes did Mateo spend on homework last night?',
  ),
  (
    'What were the high temperatures in town last week?',
    'What was the high temperature in town yesterday?',
  ),
  (
    'How many books did the students in the school read this year?',
    'How many books did Aaliyah read this year?',
  ),
  (
    'How long do batteries last in this brand of remote?',
    'How long did this one battery last?',
  ),
];

/// "Which is a statistical question?" → MC, exactly one stat among
/// four candidates. CCSS 6.SP.A.1.
GeneratedQuestion statisticalQuestion(Random rand) {
  // Pick one pair as the "stat" answer, then take 3 non-stat from the
  // remaining pairs as distractors.
  final idx = rand.nextInt(_statisticalQuestions.length);
  final stat = _statisticalQuestions[idx].$1;
  // 3 non-stat distractors from other pairs.
  final others = List<int>.generate(_statisticalQuestions.length, (k) => k)
    ..removeAt(idx)
    ..shuffle(rand);
  final distractors = others
      .take(3)
      .map((k) => _statisticalQuestions[k].$2)
      .toList();
  return GeneratedQuestion(
    conceptId: 'statistical_question',
    prompt:
        'Which of these is a statistical question (one that anticipates '
        'variability)?',
    correctAnswer: stat,
    distractors: distractors,
    explanation: [
      'A statistical question anticipates variability in the data.',
      '"$stat" asks about a group whose answers naturally vary.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// sampling_representativeness (G7)
// ─────────────────────────────────────────────────────────────────────────

const _samplingScenarios = [
  // (scenario, isBiased)
  (
    'A school surveys only members of its track team to find the favorite '
        'sport of students.',
    true,
  ),
  (
    'A grocery store surveys only customers buying coffee to find what '
        'drink shoppers prefer.',
    true,
  ),
  (
    'A teacher surveys every fifth student on a random roster to find the '
        'favorite school lunch.',
    false,
  ),
  (
    'A town surveys only people leaving a fast-food restaurant to ask '
        'what people eat for dinner.',
    true,
  ),
  (
    'A scientist randomly selects 100 of the 1000 fish in a pond to '
        'estimate the average length.',
    false,
  ),
];

/// "Is this sample fair?" — Yes/No. Hard-coded scenario list mixing
/// biased and unbiased examples. CCSS 7.SP.A.1.
GeneratedQuestion samplingRepresentativeness(Random rand) {
  final s = _samplingScenarios[rand.nextInt(_samplingScenarios.length)];
  final isBiased = s.$2;
  return GeneratedQuestion(
    conceptId: 'sampling_representativeness',
    prompt: '${s.$1} Is this a fair (representative) sample?',
    correctAnswer: isBiased ? 'No' : 'Yes',
    distractors: [
      if (isBiased) 'Yes' else 'No',
      'Only if the sample is bigger',
      'Cannot tell from this description',
    ],
    explanation: [
      if (isBiased)
        'The sample is drawn from a group already biased toward one answer.'
      else
        'The sample is drawn fairly across the population.',
    ],
  );
}
