import 'dart:math';

/// Word-problem framework — bundled name/item pools and template composer
/// for 1-step word-problem generators.
///
/// Design notes:
///  * Quantities are always ≥ 2 so item nouns can stay in plural form.
///    No singular handling — kids never see "1 apple" in v1.
///  * The subject's name is repeated rather than referred to with a
///    pronoun. Avoids gender encoding and verb-conjugation traps with
///    gender-neutral names. Slightly stilted, but kid-readable.
///  * Pools are tuned for the city-builder theme: 4 of the 20 items are
///    construction-themed (bricks, paint cans, traffic cones, road signs).

// ─────────────────────────────────────────────────────────────────────────
// Name pool — 25 entries, balanced across cultures and gender presentation,
// each chosen for 6-year-old reading friendliness (1–3 syllables, no
// reading-trap clusters).
// ─────────────────────────────────────────────────────────────────────────

const List<String> wordProblemNames = [
  // Latin American
  'Maria', 'Diego', 'Sofia', 'Mateo',
  // East Asian
  'Yuki', 'Kenji', 'Mei', 'Wei',
  // South Asian
  'Priya', 'Arjun', 'Aanya', 'Rohan',
  // Black / African-American
  'Aaliyah', 'Malik', 'Jasmine', 'Marcus',
  // Middle Eastern
  'Layla', 'Omar', 'Fatima', 'Yusuf',
  // Anglo / European
  'Emma', 'Liam', 'Olivia', 'Noah',
  // Gender-neutral
  'Nina',
];

// ─────────────────────────────────────────────────────────────────────────
// Item pool — 20 plural countable nouns. 4 city-builder-themed.
// All stored in plural form; quantities are always ≥ 2 so we never need
// the singular.
// ─────────────────────────────────────────────────────────────────────────

const List<String> wordProblemItems = [
  // Food
  'apples', 'oranges', 'grapes', 'cookies', 'cupcakes', 'candies',
  // School supplies
  'pencils', 'crayons', 'erasers', 'books', 'stickers',
  // Toys / play
  'marbles', 'balloons', 'coins', 'flowers', 'toy cars',
  // City-builder theme
  'bricks', 'paint cans', 'traffic cones', 'road signs',
];

// ─────────────────────────────────────────────────────────────────────────
// Contexts — the verb shape that drives the math. Each context is one
// templated sentence inserted between the setup and the question.
//
// Templates use placeholders {Name}, {b}, {items}.
// ─────────────────────────────────────────────────────────────────────────

class AdditionContext {
  const AdditionContext({required this.id, required this.action});

  final String id;

  /// Action sentence. Inserted between "{Name} has {a} {items}." and
  /// "How many {items} does {Name} have now?". Placeholders: {Name}, {b},
  /// {items}.
  final String action;
}

const List<AdditionContext> additionContextsV1 = [
  AdditionContext(
    id: 'collects',
    action: '{Name} finds {b} more {items}.',
  ),
  AdditionContext(
    id: 'is_given',
    action: 'A friend gives {Name} {b} more {items}.',
  ),
  AdditionContext(
    id: 'buys',
    action: '{Name} buys {b} more {items} at the store.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────
// Composer
// ─────────────────────────────────────────────────────────────────────────

/// Composes the prompt for a 1-step "starts-with-a, adds-b, total?" problem.
///
/// Structure: "{name} has {a} {items}. {action}. How many {items} does
/// {name} have now?"
String composeAdditionWordProblem({
  required String name,
  required String items,
  required int a,
  required int b,
  required AdditionContext context,
}) {
  final action = context.action
      .replaceAll('{Name}', name)
      .replaceAll('{b}', '$b')
      .replaceAll('{items}', items);
  return '$name has $a $items. $action '
      'How many $items does $name have now?';
}

/// Picks a uniformly-random element from [list] using [rand].
T pickRandom<T>(List<T> list, Random rand) => list[rand.nextInt(list.length)];
