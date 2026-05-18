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

/// One five-number summary (min / Q1 / median / Q3 / max) for one box
/// plot. Multiple summaries are stacked vertically inside a single
/// [BoxPlotSpec] to support compare-two-distributions tasks.
class BoxPlotSummary {
  const BoxPlotSummary({
    required this.label,
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
  }) : assert(
         min <= q1 && q1 <= median && median <= q3 && q3 <= max,
         'five-number summary must be in non-decreasing order',
       );

  /// Short row label shown to the left of the box (e.g. "A", "B", or
  /// "Class A"). For single-distribution plots, callers usually pass
  /// the empty string.
  final String label;
  final int min;
  final int q1;
  final int median;
  final int q3;
  final int max;
}

/// A box plot (a.k.a. box-and-whisker plot) along a horizontal axis
/// spanning [minX] to [maxX] (display units). One row per [BoxPlotSummary].
///
/// Used by `box_plot`, `compare_two_distributions`.
class BoxPlotSpec extends DiagramSpec {
  const BoxPlotSpec({
    required this.title,
    required this.axisLabel,
    required this.summaries,
    required this.minX,
    required this.maxX,
    this.tickStep = 5,
  }) : assert(summaries.length >= 1, 'need at least one summary'),
       assert(maxX > minX, 'maxX must be > minX'),
       assert(tickStep > 0, 'tickStep must be > 0');

  final String title;
  final String axisLabel;

  /// One or more five-number summaries, drawn top-to-bottom.
  final List<BoxPlotSummary> summaries;

  final int minX;
  final int maxX;

  /// Major-tick spacing on the x-axis. Tick labels are drawn at every
  /// multiple of [tickStep] inside `[minX, maxX]`.
  final int tickStep;
}

/// A histogram with `counts.length` adjacent bins, each of width [binWidth]
/// starting at [binStart]. The y-axis is scaled by [scale] (1 for unscaled
/// — every gridline is one unit). Bin i covers `[binStart + i·binWidth,
/// binStart + (i+1)·binWidth)`.
///
/// Used by `histogram`, `describe_distribution`.
class HistogramSpec extends DiagramSpec {
  const HistogramSpec({
    required this.title,
    required this.axisLabel,
    required this.counts,
    required this.binStart,
    required this.binWidth,
    required this.scale,
    required this.maxY,
  }) : assert(counts.length >= 2, 'need at least 2 bins'),
       assert(binWidth > 0, 'binWidth must be > 0'),
       assert(scale > 0, 'scale must be > 0'),
       assert(maxY > 0, 'maxY must be > 0'),
       assert(maxY % scale == 0, 'maxY must be a multiple of scale');

  /// Header above the plot, e.g. "Math test scores".
  final String title;

  /// Caption under the x-axis identifying the unit, e.g. "Score".
  final String axisLabel;

  /// Bin counts left-to-right. `counts[i]` is the frequency in
  /// `[binStart + i·binWidth, binStart + (i+1)·binWidth)`.
  final List<int> counts;

  final int binStart;
  final int binWidth;

  /// y-axis gridline spacing. Same role as [BarChartSpec.scale].
  final int scale;

  /// Top of the y-axis, a multiple of [scale].
  final int maxY;
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
    this.denominator = 1,
  }) : assert(maxX > minX, 'maxX must be > minX'),
       assert(values.length > 0, 'need at least one value'),
       assert(denominator > 0, 'denominator must be > 0'),
       assert(
         minX % denominator == 0 && maxX % denominator == 0,
         'minX and maxX must be whole-number multiples of denominator',
       );

  /// Header above the plot, e.g. "Plant heights" or "Books read".
  final String title;

  /// Short caption under the axis identifying the unit, e.g. "Inches".
  final String axisLabel;

  /// The data points. Duplicates are stacked vertically above the
  /// corresponding axis tick. Every value satisfies `minX <= v <= maxX`
  /// and represents `v / denominator` display units.
  final List<int> values;

  /// Internal axis range in units of `1/denominator`. Both endpoints
  /// must be whole-number multiples of [denominator] so the major ticks
  /// land on integer display values.
  final int minX;
  final int maxX;

  /// `1` for an integer dot plot (default). `2` / `4` / `8` for a line
  /// plot at half / quarter / eighth precision: internal units divide by
  /// this to give the display value. Used by `line_plot_fractional`,
  /// `line_plot_fraction_word`, `line_plot_5th_grade_ops`.
  final int denominator;
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

/// An infinite line on the coordinate plane, defined by two distinct
/// points. The renderer extrapolates to the visible plot rect.
class CoordinatePlaneLine {
  const CoordinatePlaneLine({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.style = CoordinatePlaneLineStyle.solid,
  }) : assert(
         x1 != x2 || y1 != y2,
         'a line needs two distinct points',
       );

  final num x1;
  final num y1;
  final num x2;
  final num y2;
  final CoordinatePlaneLineStyle style;
}

/// Visual style for a [CoordinatePlaneLine].
enum CoordinatePlaneLineStyle {
  /// Bold solid stroke in the primary colour. Default — used for
  /// graphed equations.
  solid,

  /// Dashed stroke in a secondary colour. Used for "best-fit" overlays
  /// on scatter plots so the line reads as suggested rather than canonical.
  dashed,
}

/// A 2-D coordinate plane spanning `[minX, maxX] × [minY, maxY]` (inclusive
/// integer ranges), with a grid at every integer step, labelled axes, and
/// zero or more marked points or lines. Covers both first-quadrant
/// (`minX = minY = 0`) and four-quadrant (`minX, minY < 0`) flavours.
class CoordinatePlaneSpec extends DiagramSpec {
  const CoordinatePlaneSpec({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    this.points = const [],
    this.lines = const [],
  }) : assert(maxX > minX, 'maxX must be > minX'),
       assert(maxY > minY, 'maxY must be > minY');

  final int minX;
  final int maxX;
  final int minY;
  final int maxY;
  final List<CoordinatePlanePoint> points;

  /// Optional list of lines drawn on top of the grid. Each line is
  /// extrapolated to the visible plot rect.
  final List<CoordinatePlaneLine> lines;
}
