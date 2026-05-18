import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// G1-G2 money generators sharing the new Money widget:
/// coins_id_value, count_coins, count_bills_coins, change_from_purchase.

/// Format `n` cents as a kid-friendly dollar-or-cents string.
/// `45` → `"45¢"`; `100` → `"\$1"`; `155` → `"\$1.55"`.
String _formatCents(int cents) {
  if (cents < 100) return '$cents¢';
  if (cents % 100 == 0) return '\$${cents ~/ 100}';
  final dollars = cents ~/ 100;
  final rest = cents % 100;
  return '\$$dollars.${rest.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────
// coins_id_value (G1) — "What is this coin worth?"
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion coinsIdValue(Random rand) {
  const coins = [
    MoneyDenom.penny,
    MoneyDenom.nickel,
    MoneyDenom.dime,
    MoneyDenom.quarter,
  ];
  final d = coins[rand.nextInt(coins.length)];
  // Hide the cents label inside the figure by using a "?"-style prompt and
  // a single-coin spec — but the renderer's labelled-circle design always
  // shows the value, so this question is really "read the value from the
  // labelled coin", which is the K-G1 lesson: connect the name to the
  // value.
  //
  // The prompt names the coin; the diagram shows one coin marked with its
  // value; the kid types the cent value.
  return GeneratedQuestion(
    conceptId: 'coins_id_value',
    prompt: 'What is the value of this coin (in cents)?',
    diagram: MoneySpec(items: [d]),
    correctAnswer: '${d.cents}',
    distractors: integerDistractorsWith(
      d.cents,
      rand,
      // Misconception: gave the value of a neighbouring coin.
      misconception: _neighbourCoin(d).cents,
    ),
    explanation: ['A ${_coinName(d)} is worth ${d.cents} cents.'],
  );
}

String _coinName(MoneyDenom d) => switch (d) {
  MoneyDenom.penny => 'penny',
  MoneyDenom.nickel => 'nickel',
  MoneyDenom.dime => 'dime',
  MoneyDenom.quarter => 'quarter',
  _ => throw ArgumentError('not a coin: $d'),
};

MoneyDenom _neighbourCoin(MoneyDenom d) => switch (d) {
  MoneyDenom.penny => MoneyDenom.nickel,
  MoneyDenom.nickel => MoneyDenom.dime,
  MoneyDenom.dime => MoneyDenom.quarter,
  MoneyDenom.quarter => MoneyDenom.dime,
  _ => MoneyDenom.penny,
};

// ─────────────────────────────────────────────────────────────────────────
// count_coins (G2) — sum a small collection of coins
// ─────────────────────────────────────────────────────────────────────────

/// Draw a small collection of 3..6 coins (pennies/nickels/dimes/quarters)
/// and ask the total in cents. Total bounded ≤ 99¢ so it fits the
/// `count_coins` lesson (cents-only).
GeneratedQuestion countCoins(Random rand) {
  const coinPool = [
    MoneyDenom.penny,
    MoneyDenom.nickel,
    MoneyDenom.dime,
    MoneyDenom.quarter,
  ];
  late List<MoneyDenom> chosen;
  late int total;
  // Re-roll until total is in [10, 99] for a meaningful question.
  var attempts = 0;
  do {
    final n = rand.nextInt(4) + 3; // 3..6 coins
    chosen = List.generate(n, (_) => coinPool[rand.nextInt(coinPool.length)]);
    total = chosen.fold(0, (acc, d) => acc + d.cents);
    attempts++;
  } while ((total < 10 || total > 99) && attempts < 20);
  if (total < 10 || total > 99) {
    // Fall back to a deterministic clean case.
    chosen = const [MoneyDenom.dime, MoneyDenom.nickel, MoneyDenom.penny];
    total = 16;
  }
  // Sort coins by value descending for a tidy display.
  chosen.sort((a, b) => b.cents.compareTo(a.cents));
  // Misconception: counted coins (ignored value) — gave the coin count.
  return GeneratedQuestion(
    conceptId: 'count_coins',
    prompt: 'What is the total value of these coins (in cents)?',
    diagram: MoneySpec(items: chosen),
    correctAnswer: '$total',
    distractors: integerDistractorsWith(
      total,
      rand,
      misconception: chosen.length,
    ),
    explanation: [
      'Add: ${chosen.map((c) => '${c.cents}').join(' + ')} = $total.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// count_bills_coins (G2) — sum bills and coins
// ─────────────────────────────────────────────────────────────────────────

/// 2..3 bills + 2..4 coins; answer is the total in cents (e.g. "245" for
/// $2.45). Prompt asks for the dollars-and-cents string so the kid sees
/// the canonical "$$X.YY" form they'd use in real life.
GeneratedQuestion countBillsCoins(Random rand) {
  const bills = [
    MoneyDenom.oneDollar,
    MoneyDenom.fiveDollar,
    MoneyDenom.tenDollar,
  ];
  const coins = [
    MoneyDenom.penny,
    MoneyDenom.nickel,
    MoneyDenom.dime,
    MoneyDenom.quarter,
  ];
  // 1..2 bills, 2..4 coins.
  late List<MoneyDenom> items;
  late int total;
  var attempts = 0;
  do {
    final billCount = rand.nextInt(2) + 1; // 1..2
    final coinCount = rand.nextInt(3) + 2; // 2..4
    final picked = <MoneyDenom>[
      ...List.generate(billCount, (_) => bills[rand.nextInt(bills.length)]),
      ...List.generate(coinCount, (_) => coins[rand.nextInt(coins.length)]),
    ];
    final t = picked.fold<int>(0, (acc, d) => acc + d.cents);
    items = picked;
    total = t;
    attempts++;
    // Keep cents portion non-trivial (avoid all-pennies for the bills
    // case) and total in a kid-friendly range.
  } while ((total > 2599 || total % 100 == 0) && attempts < 20);
  if (total > 2599 || total % 100 == 0) {
    items = const [
      MoneyDenom.oneDollar,
      MoneyDenom.quarter,
      MoneyDenom.dime,
      MoneyDenom.nickel,
    ];
    total = 140;
  }
  items.sort((a, b) => b.cents.compareTo(a.cents));
  final correct = _formatCents(total);
  // Misconception: forgot to convert dollars to cents — added bill face
  // dollars + coin cents directly (e.g. $$1 + 25¢ + 10¢ = "1 + 35 = 36").
  final misconceptionVal =
      items.where((d) => d.isCoin).fold<int>(0, (a, d) => a + d.cents) +
      items.where((d) => !d.isCoin).fold<int>(0, (a, d) => a + d.cents ~/ 100);
  return GeneratedQuestion(
    conceptId: 'count_bills_coins',
    prompt: 'What is the total amount of money shown?',
    diagram: MoneySpec(items: items),
    correctAnswer: correct,
    distractors: _distinctStringDistractors(correct, [
      _formatCents(misconceptionVal),
      _formatCents(total + 5),
      _formatCents(total > 5 ? total - 5 : total + 10),
      _formatCents(total + 100),
      if (total > 100) _formatCents(total - 100),
    ]),
    explanation: [
      'Add the bills and coins together → ${_formatCents(total)}.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

List<String> _distinctStringDistractors(
  String correct,
  List<String> candidates,
) {
  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  if (out.length < 3) {
    throw StateError(
      'distractor pool exhausted; need 3 distinct vs "$correct"',
    );
  }
  return out.take(3).toList();
}

// ─────────────────────────────────────────────────────────────────────────
// change_from_purchase (G2) — "Pay with $X, item costs $Y, change?"
// ─────────────────────────────────────────────────────────────────────────

/// "You pay with a $5 bill for a book that costs $3.40. How much change
/// do you get back?" → $1.60. Pay = 1, 5, 10, or 20 dollars; cost = 100
/// to (pay - 100) cents in 5-cent steps so the answer falls cleanly on a
/// nickel boundary.
GeneratedQuestion changeFromPurchase(Random rand) {
  const payBills = [
    MoneyDenom.oneDollar,
    MoneyDenom.fiveDollar,
    MoneyDenom.tenDollar,
    MoneyDenom.twentyDollar,
  ];
  final payBill = payBills[rand.nextInt(payBills.length)];
  final pay = payBill.cents;
  // Cost in 5-cent steps, in [25, pay - 5].
  final maxCost = pay - 5;
  final steps = (maxCost - 25) ~/ 5;
  final cost = 25 + 5 * rand.nextInt(steps + 1);
  final change = pay - cost;
  final correct = _formatCents(change);
  return GeneratedQuestion(
    conceptId: 'change_from_purchase',
    prompt:
        'You pay with ${payBill.label} for an item that costs '
        '${_formatCents(cost)}. How much change do you get back?',
    diagram: MoneySpec(items: [payBill]),
    correctAnswer: correct,
    distractors: _distinctStringDistractors(correct, [
      // Misconception: added pay + cost.
      _formatCents(pay + cost),
      // Misconception: gave the cost.
      _formatCents(cost),
      // Off by a dime / a nickel.
      _formatCents(change + 10),
      if (change > 10) _formatCents(change - 10),
      _formatCents(change + 5),
      if (change > 5) _formatCents(change - 5),
    ]),
    explanation: [
      '${_formatCents(pay)} − ${_formatCents(cost)} = $correct.',
    ],
    answerFormat: AnswerFormat.string,
  );
}
