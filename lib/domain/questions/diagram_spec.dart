/// Sealed family of diagram specifications. The domain layer constructs
/// these as plain Dart values; the presentation layer dispatches on the
/// concrete type to render the corresponding widget.
///
/// Add a new subclass per supported widget kind (see curriculum.md §6).
sealed class DiagramSpec {
  const DiagramSpec();
}

/// A horizontal bar partitioned into [denominator] equal segments, with
/// the first [numerator] segments shaded.
class FractionBarSpec extends DiagramSpec {
  const FractionBarSpec({
    required this.numerator,
    required this.denominator,
  }) : assert(denominator > 0, 'denominator must be > 0'),
       assert(numerator >= 0, 'numerator must be >= 0');

  final int numerator;
  final int denominator;
}

/// A single arc-shaped hop on a number line, optionally labelled.
class NumberLineHop {
  const NumberLineHop({
    required this.from,
    required this.to,
    this.label,
  });

  final num from;
  final num to;
  final String? label;
}

/// A horizontal number line from [min] to [max], with [divisions] equal
/// tick marks. [markedPoints] are highlighted dots; [hops] are arcs.
class NumberLineSpec extends DiagramSpec {
  const NumberLineSpec({
    required this.min,
    required this.max,
    required this.divisions,
    this.markedPoints = const [],
    this.hops = const [],
  }) : assert(divisions > 0, 'divisions must be > 0');

  final num min;
  final num max;
  final int divisions;
  final List<num> markedPoints;
  final List<NumberLineHop> hops;
}

/// A `rows × cols` grid where the top `shadedRows` rows and the left
/// `shadedCols` columns are both shaded. The intersection cells (top-left
/// `shadedRows × shadedCols` rectangle) are highlighted in a stronger
/// color to depict the product of two fractions: a/cols × b/rows visually
/// reads as the deepest-shaded rectangle out of the whole grid.
class AreaGridSpec extends DiagramSpec {
  const AreaGridSpec({
    required this.rows,
    required this.cols,
    required this.shadedRows,
    required this.shadedCols,
  }) : assert(rows > 0 && cols > 0, 'rows and cols must be > 0'),
       assert(
         shadedRows >= 0 && shadedRows <= rows,
         'shadedRows must be in 0..rows',
       ),
       assert(
         shadedCols >= 0 && shadedCols <= cols,
         'shadedCols must be in 0..cols',
       );

  final int rows;
  final int cols;
  final int shadedRows;
  final int shadedCols;
}

/// A round analog clock face showing [hour] (1–12) and [minute] (0–59).
class ClockSpec extends DiagramSpec {
  const ClockSpec({
    required this.hour,
    required this.minute,
  }) : assert(hour >= 1 && hour <= 12, 'hour must be 1–12'),
       assert(minute >= 0 && minute < 60, 'minute must be 0–59');

  final int hour;
  final int minute;
}
