/// Pure-Dart decimal value type used by decimal generators and the
/// answer-equivalence checker.
///
/// Internally stored as `(scaled, scale)` where `scaled` is a signed
/// integer and `scale` is the power of 10. So `1.25` is `(125, 2)` and
/// `-3.0` is `(-3, 0)`. The constructor canonicalises by stripping
/// trailing zeros from the fractional part, so `(150, 2)` becomes
/// `(15, 1)` — `1.5`, not `1.50`. This means two `Decimal`s with the
/// same value are always `==`-equal as field-tuples after construction.
///
/// Supports parsing of "N", "N.D", ".D", and optional leading '-' or
/// Unicode minus sign U+2212.
///
/// `==` is NOT overridden (matches the `Fraction` pattern); use
/// [equalsByValue] for value comparisons. Construction is already
/// canonicalising, so two value-equal `Decimal`s have identical field
/// tuples and `equalsByValue` reduces to a tuple compare.
class Decimal {
  /// Constructs from a signed scaled integer and a non-negative scale,
  /// then canonicalises (strips trailing zeros).
  factory Decimal(int scaled, int scale) {
    assert(scale >= 0, 'scale must be >= 0');
    var s = scaled;
    var p = scale;
    while (p > 0 && s % 10 == 0) {
      s ~/= 10;
      p--;
    }
    return Decimal._(s, p);
  }

  const Decimal._(this.scaled, this.scale);

  /// Parses a decimal-shaped string. Returns null if [input] is not
  /// recognisable. Accepts both ASCII '-' and Unicode minus '−'.
  static Decimal? tryParse(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('−')) s = '-${s.substring(1)}';
    final m = RegExp(r'^(-?)(\d*)(?:\.(\d+))?$').firstMatch(s);
    if (m == null) return null;
    final signStr = m.group(1)!;
    final whole = m.group(2) ?? '';
    final frac = m.group(3) ?? '';
    // Reject pure "-", pure "-.", pure ".".
    if (whole.isEmpty && frac.isEmpty) return null;
    final digits = '${whole.isEmpty ? '0' : whole}$frac';
    final magnitude = int.parse(digits);
    final sign = signStr.isEmpty ? 1 : -1;
    return Decimal(sign * magnitude, frac.length);
  }

  /// Canonical (trailing-zeros-stripped) scaled integer.
  final int scaled;

  /// Canonical (minimal) scale, i.e. number of fractional digits.
  final int scale;

  /// Value equality. Always equivalent to field-tuple equality post-
  /// canonicalisation, but provided as an explicit name for clarity at
  /// call sites.
  bool equalsByValue(Decimal other) =>
      scaled == other.scaled && scale == other.scale;

  /// `< 0`, `== 0`, `> 0` per the usual contract.
  int compareTo(Decimal other) {
    final maxScale = scale > other.scale ? scale : other.scale;
    return _scaleTo(maxScale).compareTo(other._scaleTo(maxScale));
  }

  int _scaleTo(int targetScale) => scaled * _pow10(targetScale - scale);

  Decimal operator +(Decimal other) {
    final maxScale = scale > other.scale ? scale : other.scale;
    return Decimal(_scaleTo(maxScale) + other._scaleTo(maxScale), maxScale);
  }

  Decimal operator -(Decimal other) {
    final maxScale = scale > other.scale ? scale : other.scale;
    return Decimal(_scaleTo(maxScale) - other._scaleTo(maxScale), maxScale);
  }

  Decimal operator *(Decimal other) =>
      Decimal(scaled * other.scaled, scale + other.scale);

  /// Canonical kid-textbook string form. Leading "0" for |v| < 1
  /// ("0.5" not ".5"); trailing zeros stripped ("1.5" not "1.50");
  /// whole values rendered without a point ("3" not "3.0").
  String toCanonical() {
    if (scale == 0) return '$scaled';
    final negative = scaled < 0;
    final mag = scaled.abs();
    final divisor = _pow10(scale);
    final whole = mag ~/ divisor;
    final frac = mag % divisor;
    final fracStr = frac.toString().padLeft(scale, '0');
    return '${negative ? '-' : ''}$whole.$fracStr';
  }

  @override
  String toString() => toCanonical();
}

int _pow10(int n) {
  var v = 1;
  for (var i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}
