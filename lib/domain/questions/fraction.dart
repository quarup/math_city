/// Pure-Dart fraction value type used by fraction generators and the
/// answer-equivalence checker.
///
/// Supports three text shapes:
///   * `"a/b"`        — proper or improper (e.g. `"3/4"`, `"7/4"`)
///   * `"a b/c"`      — mixed (e.g. `"1 3/4"`)
///   * `"n"`          — whole integer (e.g. `"3"` → 3/1)
///
/// Comparison is by value (`1/2 == 2/4 == 4/8`). Reduction yields a
/// canonical (lowest-terms) form with the sign on the numerator and a
/// positive denominator.
class Fraction {
  /// Constructs `numerator / denominator` and normalises the sign so the
  /// denominator is always positive. Does NOT reduce — call [reduce] for
  /// that.
  Fraction(int numerator, int denominator)
    : assert(denominator != 0, 'denominator must not be 0'),
      numerator = denominator < 0 ? -numerator : numerator,
      denominator = denominator < 0 ? -denominator : denominator;

  /// Parses a fraction-shaped string. Returns null if [s] is not
  /// recognisable as one of the supported shapes (whole / proper / improper
  /// / mixed).
  static Fraction? tryParse(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return null;

    // Mixed: "a b/c"  (one or more spaces between whole and fraction).
    final mixed = RegExp(r'^(-?\d+)\s+(\d+)/(\d+)$').firstMatch(trimmed);
    if (mixed != null) {
      final whole = int.parse(mixed.group(1)!);
      final n = int.parse(mixed.group(2)!);
      final d = int.parse(mixed.group(3)!);
      if (d == 0) return null;
      final sign = whole < 0 ? -1 : 1;
      return Fraction(sign * (whole.abs() * d + n), d);
    }

    // Plain fraction "a/b".
    final plain = RegExp(r'^(-?\d+)/(-?\d+)$').firstMatch(trimmed);
    if (plain != null) {
      final n = int.parse(plain.group(1)!);
      final d = int.parse(plain.group(2)!);
      if (d == 0) return null;
      return Fraction(n, d);
    }

    // Bare integer.
    final whole = int.tryParse(trimmed);
    if (whole != null) return Fraction(whole, 1);

    return null;
  }

  final int numerator;
  final int denominator;

  /// True iff |numerator| >= denominator.
  bool get isImproper => numerator.abs() >= denominator;

  /// True iff this fraction represents an integer (denominator divides
  /// numerator after reduction).
  bool get isWhole => numerator % denominator == 0;

  /// Returns the reduced (lowest-terms) form. Sign rides on the
  /// numerator; denominator is always positive (already true post-ctor).
  Fraction reduce() {
    if (numerator == 0) return Fraction(0, 1);
    final g = _gcd(numerator.abs(), denominator);
    return Fraction(numerator ~/ g, denominator ~/ g);
  }

  /// Returns the (whole, properNumerator, denominator) decomposition of
  /// this fraction's reduced form. For values < 1 the whole part is 0.
  /// Sign rides on the whole part if any whole part exists, else on the
  /// numerator. Examples (post-reduce): `7/4 → (1, 3, 4)`; `3/4 → (0, 3,
  /// 4)`; `-7/4 → (-1, 3, 4)`.
  ({int whole, int numerator, int denominator}) mixedParts() {
    final r = reduce();
    final sign = r.numerator < 0 ? -1 : 1;
    final n = r.numerator.abs();
    final whole = n ~/ r.denominator;
    final rem = n % r.denominator;
    return (
      whole: sign * whole,
      numerator: rem,
      denominator: r.denominator,
    );
  }

  /// Equality by mathematical value (not by representation). `1/2 == 2/4`.
  bool equalsByValue(Fraction other) =>
      numerator * other.denominator == other.numerator * denominator;

  /// Canonical kid-textbook string form of the *reduced* fraction:
  ///   * whole → "3"
  ///   * proper → "3/4"
  ///   * improper (kept improper, not auto-converted to mixed) → "7/4"
  /// Negative values prefix the whole part with `-` (e.g. `-3/4`).
  String toCanonical() {
    final r = reduce();
    if (r.denominator == 1) return '${r.numerator}';
    return '${r.numerator}/${r.denominator}';
  }

  /// Mixed-number string form of the *reduced* fraction:
  ///   * whole → "3"
  ///   * proper → "3/4"
  ///   * improper → "1 3/4"
  String toMixed() {
    final r = reduce();
    if (r.denominator == 1) return '${r.numerator}';
    if (r.numerator.abs() < r.denominator) {
      return '${r.numerator}/${r.denominator}';
    }
    final parts = r.mixedParts();
    if (parts.numerator == 0) return '${parts.whole}';
    return '${parts.whole} ${parts.numerator}/${parts.denominator}';
  }

  Fraction operator +(Fraction other) =>
      Fraction(
        numerator * other.denominator + other.numerator * denominator,
        denominator * other.denominator,
      );

  Fraction operator -(Fraction other) =>
      Fraction(
        numerator * other.denominator - other.numerator * denominator,
        denominator * other.denominator,
      );

  Fraction operator *(Fraction other) =>
      Fraction(numerator * other.numerator, denominator * other.denominator);

  Fraction operator /(Fraction other) {
    assert(other.numerator != 0, 'cannot divide by 0/anything');
    return Fraction(
      numerator * other.denominator,
      denominator * other.numerator,
    );
  }

  @override
  String toString() => toCanonical();
}

int _gcd(int a, int b) {
  var x = a;
  var y = b;
  while (y != 0) {
    final t = y;
    y = x % y;
    x = t;
  }
  return x;
}

/// Least common multiple of two positive ints.
int lcm(int a, int b) => (a ~/ _gcd(a, b)) * b;
