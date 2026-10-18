import 'dart:math';

/// A famous mathematician a new player can borrow a name from.
///
/// Surnames only (one-word names for the ancients), so "Mayor Euler" reads
/// the way a real mayor is addressed and no name leans one way by gender.
/// The fact is a child-sized hook of a few words, not a biography.
class MathematicianName {
  const MathematicianName(this.name, this.fact);

  final String name;
  final String fact;
}

const kMathematicianNames = <MathematicianName>[
  MathematicianName('Euler', 'Loved puzzles about bridges'),
  MathematicianName('Gauss', 'Added 1 to 100 in seconds'),
  MathematicianName('Newton', 'Worked out how gravity pulls'),
  MathematicianName('Fibonacci', 'Found the rabbit number pattern'),
  MathematicianName('Euclid', 'Wrote the first geometry book'),
  MathematicianName('Hypatia', 'Taught math in ancient Egypt'),
  MathematicianName('Lovelace', 'Wrote the first computer program'),
  MathematicianName('Noether', 'Found symmetry in everything'),
  MathematicianName('Turing', 'Built a code-breaking machine'),
  MathematicianName('Hopper', 'Found the first computer bug'),
  MathematicianName('Germain', 'Studied math in secret'),
  MathematicianName('Ramanujan', 'Self-taught from a single book'),
  MathematicianName('Pythagoras', 'Triangles! a² + b² = c²'),
  MathematicianName('Archimedes', 'Shouted Eureka in the bath'),
  MathematicianName('Descartes', 'Invented the x–y grid'),
  MathematicianName('Mirzakhani', 'Won the biggest prize in math'),
  MathematicianName('Möbius', 'Made a strip with only one side'),
  MathematicianName('Venn', 'Drew the overlapping circles'),
  MathematicianName('Mandelbrot', 'Found math in clouds and coastlines'),
  MathematicianName('Pascal', 'Built a triangle out of numbers'),
  MathematicianName('Banneker', 'Predicted eclipses with no teacher'),
  MathematicianName('Kepler', 'Mapped how the planets move'),
  MathematicianName('Erdős', 'Did math with 500 friends'),
  MathematicianName('Sierpinski', 'Triangles inside triangles inside…'),
  MathematicianName('Khayyam', 'Solved cubes with circles'),
  MathematicianName('Bhaskara', 'Explained zero and infinity'),
  MathematicianName('Agnesi', 'Wrote a famous calculus book'),
  MathematicianName('Galois', 'Invented a whole field at 20'),
  MathematicianName('Shannon', 'Juggled, unicycled, invented bits'),
  MathematicianName('Boole', 'Turned logic into algebra'),
];

/// Deals hands of names for the name screen: every name in the pool comes
/// up once before any repeats, and two hands dealt one after the other
/// never share a name, even across the reshuffle.
class NameDeck {
  NameDeck({Random? random, List<MathematicianName> pool = kMathematicianNames})
    : _random = random ?? Random(),
      _pool = List.unmodifiable(pool) {
    _order = List.of(_pool)..shuffle(_random);
  }

  final Random _random;
  final List<MathematicianName> _pool;
  late List<MathematicianName> _order;
  int _cursor = 0;
  List<MathematicianName> _last = const [];

  /// The next [count] names. [count] must not exceed half the pool, or the
  /// no-overlap promise between consecutive hands cannot be kept.
  List<MathematicianName> next(int count) {
    assert(count * 2 <= _pool.length, 'hand too large for the pool');
    if (_cursor + count > _order.length) {
      // Reshuffle so that the names just shown land at the back: the next
      // hand is drawn from the others, so no name repeats across the seam.
      final shown = _last.toSet();
      final fresh = _pool.where((n) => !shown.contains(n)).toList()
        ..shuffle(_random);
      final tail = _pool.where(shown.contains).toList()..shuffle(_random);
      _order = [...fresh, ...tail];
      _cursor = 0;
    }
    final hand = _order.sublist(_cursor, _cursor + count);
    _cursor += count;
    _last = hand;
    return hand;
  }
}
