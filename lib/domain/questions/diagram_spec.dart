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

/// A 10×10 grid with the first [shadedCount] cells shaded in row-major
/// order (left-to-right, top-to-bottom). Visualises "N out of 100",
/// the canonical way to introduce a percent.
class PercentGridSpec extends DiagramSpec {
  const PercentGridSpec({required this.shadedCount})
    : assert(
        shadedCount >= 0 && shadedCount <= 100,
        'shadedCount must be 0..100',
      );

  final int shadedCount;
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

/// A single labelled point on a coordinate plane.
class CoordinatePlanePoint {
  const CoordinatePlanePoint({
    required this.x,
    required this.y,
    this.label,
  });

  final int x;
  final int y;

  /// Short label (typically a single letter A/B/C/D) drawn next to the
  /// point. `null` means draw the dot with no label.
  final String? label;
}

/// A dot plot (a.k.a. line plot) — a horizontal axis from [minX] to [maxX]
/// with one tick per integer, and a vertical stack of dots above each tick
/// representing the count of that value in [values].
///
/// Used by `line_plot_whole`, `dot_plot`. Fractional-position support is
/// a separate spec / widget extension when needed (see curriculum.md
/// `line_plot_fractional`).
class DotPlotSpec extends DiagramSpec {
  const DotPlotSpec({
    required this.title,
    required this.axisLabel,
    required this.values,
    required this.minX,
    required this.maxX,
  }) : assert(maxX > minX, 'maxX must be > minX'),
       assert(values.length > 0, 'need at least one value');

  /// Header above the plot, e.g. "Plant heights" or "Books read".
  final String title;

  /// Short caption under the axis identifying the unit, e.g. "Inches".
  final String axisLabel;

  /// The data points. Duplicates are stacked vertically above the
  /// corresponding axis tick. Every value must satisfy
  /// `minX <= v <= maxX`.
  final List<int> values;

  final int minX;
  final int maxX;
}

/// A vertical bar chart with one bar per category. `labels` and `values`
/// are parallel lists. The y-axis runs from 0 to [maxY] with a gridline
/// every [scale] units (so `maxY / scale` horizontal gridlines).
///
/// Used by `bar_graph_read`, `bar_graph_compare`, and
/// `scaled_bar_graph_read`. For unscaled charts pass `scale: 1`; every
/// value must be a non-negative multiple of [scale] (the widget assumes
/// bars land exactly on gridlines).
class BarChartSpec extends DiagramSpec {
  const BarChartSpec({
    required this.title,
    required this.labels,
    required this.values,
    required this.scale,
    required this.maxY,
  }) : assert(labels.length == values.length, 'labels & values must align'),
       assert(labels.length >= 2, 'need at least 2 bars'),
       assert(scale > 0, 'scale must be > 0'),
       assert(maxY > 0, 'maxY must be > 0'),
       assert(maxY % scale == 0, 'maxY must be a multiple of scale');

  /// Header above the chart, e.g. "Favorite fruit" or "Materials at the site".
  final String title;

  /// Category labels shown under each bar.
  final List<String> labels;

  /// Bar heights (same length as [labels]). Must be non-negative multiples
  /// of [scale]; must not exceed [maxY].
  final List<int> values;

  /// y-axis gridline spacing. `1` for an unscaled chart; otherwise the
  /// scale factor (2, 5, 10, …) that turns gridline counts into values.
  final int scale;

  /// Top of the y-axis; a multiple of [scale]. Should be just above
  /// `values.reduce(max)` so the chart isn't dominated by empty space.
  final int maxY;
}

/// A 2-D coordinate plane spanning `[minX, maxX] × [minY, maxY]` (inclusive
/// integer ranges), with a grid at every integer step, labelled axes, and
/// zero or more marked points. Covers both first-quadrant (`minX = minY =
/// 0`) and four-quadrant (`minX, minY < 0`) flavours.
class CoordinatePlaneSpec extends DiagramSpec {
  const CoordinatePlaneSpec({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    this.points = const [],
  }) : assert(maxX > minX, 'maxX must be > minX'),
       assert(maxY > minY, 'maxY must be > minY');

  final int minX;
  final int maxX;
  final int minY;
  final int maxY;
  final List<CoordinatePlanePoint> points;
}
