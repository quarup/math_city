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

/// Subset of [wordProblemItems] that one can plausibly *eat*. Used by
/// the `eats` subtraction context to avoid sentences like "Maria eats 5
/// of the bricks."
const List<String> edibleWordProblemItems = [
  'apples',
  'oranges',
  'grapes',
  'cookies',
  'cupcakes',
  'candies',
];

// ─────────────────────────────────────────────────────────────────────────
// Contexts — the verb shape that drives the math. Each context is one
// templated sentence inserted between the setup and the question.
//
// Templates use placeholders {Name}, {b}, {items}.
// ─────────────────────────────────────────────────────────────────────────

enum WordProblemOp { add, sub, mult }

class WordProblemContext {
  const WordProblemContext({
    required this.id,
    required this.op,
    required this.action,
    this.requiresEdibleItems = false,
  });

  final String id;
  final WordProblemOp op;

  /// Action sentence. For [WordProblemOp.add] and [WordProblemOp.sub],
  /// the sentence is inserted between the setup ("{name} has {a}
  /// {items}.") and the closing question — placeholders supported are
  /// {Name}, {b}, {items}. For [WordProblemOp.mult] the sentence is
  /// the entire setup — placeholders are {Name}, {a}, {b}, {items}.
  final String action;

  /// When true, the generator must pick an item from
  /// [edibleWordProblemItems] (used by the `eats` and `bakes`
  /// contexts).
  final bool requiresEdibleItems;
}

const List<WordProblemContext> addSubContextsV1 = [
  // Addition
  WordProblemContext(
    id: 'collects',
    op: WordProblemOp.add,
    action: '{Name} finds {b} more {items}.',
  ),
  WordProblemContext(
    id: 'is_given',
    op: WordProblemOp.add,
    action: 'A friend gives {Name} {b} more {items}.',
  ),
  WordProblemContext(
    id: 'buys',
    op: WordProblemOp.add,
    action: '{Name} buys {b} more {items} at the store.',
  ),
  // Subtraction
  WordProblemContext(
    id: 'gives_away',
    op: WordProblemOp.sub,
    action: '{Name} gives {b} of the {items} to a friend.',
  ),
  WordProblemContext(
    id: 'eats',
    op: WordProblemOp.sub,
    action: '{Name} eats {b} of the {items}.',
    requiresEdibleItems: true,
  ),
  WordProblemContext(
    id: 'loses',
    op: WordProblemOp.sub,
    action: '{Name} loses {b} of the {items}.',
  ),
];

/// Multiplication contexts: full setup sentence that produces `a × b`
/// items. Each context names a natural "per unit / for N units" frame
/// (per day, per batch, per week). Used standalone for single-step
/// mult word problems, or chained with an add/sub context to make a
/// two-step problem (e.g. `mult_div_word_2step`).
const List<WordProblemContext> multContextsV1 = [
  WordProblemContext(
    id: 'builds',
    op: WordProblemOp.mult,
    action: '{Name} builds {a} {items} each day, for {b} days.',
  ),
  WordProblemContext(
    id: 'bakes',
    op: WordProblemOp.mult,
    action:
        '{Name} bakes {a} {items} in each batch, '
        'and makes {b} batches.',
    requiresEdibleItems: true,
  ),
  WordProblemContext(
    id: 'saves',
    op: WordProblemOp.mult,
    action: '{Name} saves {a} {items} each week, for {b} weeks.',
  ),
];

/// Comparison-framing templates for `mult_compare_word`. Each template
/// uses placeholders {Name1}, {Name2}, {k}, {n}, {items}. Picked at
/// random per question so kids see varied phrasing of the same
/// multiplicative-comparison concept.
const List<String> multCompareTemplatesV1 = [
  // ignore: no_adjacent_strings_in_list — single template wrapped for length
  '{Name1} has {k} times as many {items} as {Name2}. '
      '{Name2} has {n} {items}. How many {items} does {Name1} have?',
  // ignore: no_adjacent_strings_in_list — single template wrapped for length
  'For every {items} {Name2} owns, {Name1} owns {k}. '
      '{Name2} has {n} {items}. How many {items} does {Name1} have?',
  // ignore: no_adjacent_strings_in_list — single template wrapped for length
  '{Name1} collected {k} times the {items} that {Name2} did. '
      '{Name2} collected {n} {items}. How many {items} did {Name1} collect?',
];

// ─────────────────────────────────────────────────────────────────────────
// Composer
// ─────────────────────────────────────────────────────────────────────────

/// Composes the prompt for a 1-step word problem.
///
/// Structure (addition):
///   "{name} has {a} {items}. {action} How many {items} does {name} have
///    now?"
///
/// Structure (subtraction):
///   "{name} has {a} {items}. {action} How many {items} does {name} have
///    left?"
String composeWordProblem({
  required String name,
  required String items,
  required int a,
  required int b,
  required WordProblemContext context,
}) {
  final action = context.action
      .replaceAll('{Name}', name)
      .replaceAll('{b}', '$b')
      .replaceAll('{items}', items);
  final closing = context.op == WordProblemOp.add ? 'have now' : 'have left';
  return '$name has $a $items. $action '
      'How many $items does $name $closing?';
}

/// Composes the setup sentence for a 1-step multiplication word
/// problem. Returns just the action sentence (no closing question) so
/// callers can either append `"How many {items} in all?"` for a 1-step
/// shape or chain with another action for a 2-step shape.
///
/// Structure:
///   "{name} builds {a} {items} each day, for {b} days."
String composeMultActionSentence({
  required String name,
  required String items,
  required int a,
  required int b,
  required WordProblemContext context,
}) {
  assert(
    context.op == WordProblemOp.mult,
    'composeMultActionSentence requires a WordProblemOp.mult context',
  );
  return context.action
      .replaceAll('{Name}', name)
      .replaceAll('{a}', '$a')
      .replaceAll('{b}', '$b')
      .replaceAll('{items}', items);
}

/// Composes a 1-step multiplication word problem prompt — setup
/// sentence + "How many {items} in all?" closing question.
String composeMultWordProblem({
  required String name,
  required String items,
  required int a,
  required int b,
  required WordProblemContext context,
}) {
  final action = composeMultActionSentence(
    name: name,
    items: items,
    a: a,
    b: b,
    context: context,
  );
  return '$action How many $items in all?';
}

/// Picks a context-compatible item from the pool. Filters to edibles when
/// the context requires it.
String pickWordProblemItem(WordProblemContext context, Random rand) =>
    context.requiresEdibleItems
    ? pickRandom(edibleWordProblemItems, rand)
    : pickRandom(wordProblemItems, rand);

/// Picks a uniformly-random element from [list] using [rand].
T pickRandom<T>(List<T> list, Random rand) => list[rand.nextInt(list.length)];
