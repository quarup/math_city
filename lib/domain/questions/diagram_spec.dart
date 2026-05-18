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

/// A two-way frequency table with a header row + header column + body
/// cells. `counts[r][c]` is the count for row `r` and column `c`. Row
/// and column totals are computed on the fly when [showTotals] is true.
///
/// Used by `two_way_table_construct`, `two_way_relative_frequency`.
class TwoWayTableSpec extends DiagramSpec {
  const TwoWayTableSpec({
    required this.title,
    required this.rowLabels,
    required this.colLabels,
    required this.counts,
    this.showTotals = true,
  }) : assert(rowLabels.length >= 2, 'need ≥ 2 rows'),
       assert(colLabels.length >= 2, 'need ≥ 2 cols');

  final String title;
  final List<String> rowLabels;
  final List<String> colLabels;
  final List<List<int>> counts;
  final bool showTotals;
}

/// One stage of a compound experiment in a [TreeDiagramSpec]: a stage
/// name (e.g. "Coin" or "Spinner") plus the possible outcome labels at
/// that stage (e.g. `["H", "T"]`).
class TreeDiagramStage {
  const TreeDiagramStage({
    required this.label,
    required this.outcomes,
  }) : assert(outcomes.length >= 2, 'each stage needs ≥ 2 outcomes');

  final String label;
  final List<String> outcomes;
}

/// A probability tree diagram for a compound experiment of
/// `stages.length` stages. Branching factor at stage i is
/// `stages[i].outcomes.length`; total leaves = product of branching
/// factors.
///
/// Used by `tree_diagram` and `compound_event_probability`.
class TreeDiagramSpec extends DiagramSpec {
  const TreeDiagramSpec({required this.stages})
    : assert(stages.length >= 2, 'need ≥ 2 stages for a tree');

  final List<TreeDiagramStage> stages;

  /// Total number of leaves (= number of distinct outcome sequences).
  int get leafCount {
    var n = 1;
    for (final s in stages) {
      n *= s.outcomes.length;
    }
    return n;
  }
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

/// A semicircular protractor with one ray fixed along the 0°-180° base
/// line and a second ray at [angleDeg] (measured CCW from the 0° mark
/// on the right). The renderer draws the half-circle, tick labels at
/// every 10°, the two rays, and an arc inside the angle.
///
/// Used by `measure_angle_protractor`, `draw_angle_protractor`.
class ProtractorSpec extends DiagramSpec {
  const ProtractorSpec({
    required this.angleDeg,
    this.showAngleLabel = false,
  }) : assert(angleDeg >= 0 && angleDeg <= 180, 'angleDeg in 0..180');

  /// Angle between the two rays, in degrees (0..180).
  final int angleDeg;

  /// If true, render `${angleDeg}°` inside the wedge — used as a hint
  /// for the "draw angle" task (the kid is shown the target angle).
  final bool showAngleLabel;
}

/// A horizontal ruler showing a marked object measuring some fraction
/// of the ruler's length. Lengths are tracked in units of
/// `1/subdivisions` so a 3.5-inch object on a half-inch ruler is
/// `markedLength = 7` with `subdivisions = 2`. The renderer draws major
/// ticks at every whole unit (labelled) and minor ticks at every
/// subdivision (unlabelled).
///
/// Used by `measure_with_ruler_inches`, `measure_with_ruler_cm`,
/// `measure_to_half_quarter_inch`.
class RulerSpec extends DiagramSpec {
  const RulerSpec({
    required this.totalLength,
    required this.markedLength,
    required this.unitLabel,
    this.subdivisions = 1,
  }) : assert(totalLength > 0, 'totalLength must be > 0'),
       assert(subdivisions >= 1, 'subdivisions must be >= 1'),
       assert(markedLength >= 1, 'markedLength must be >= 1'),
       assert(
         markedLength <= totalLength * subdivisions,
         'markedLength must fit within the ruler',
       );

  /// Total ruler length in *whole* units (e.g. 6 = a 6-inch ruler).
  final int totalLength;

  /// Length of the object shown above the ruler, in units of
  /// `1/subdivisions`. Display value is `markedLength / subdivisions`.
  final int markedLength;

  /// Unit label shown on the ruler, e.g. "in", "cm".
  final String unitLabel;

  /// `1` for whole-unit ticks only. `2` adds half ticks; `4` adds
  /// quarter ticks.
  final int subdivisions;
}

/// A single coin or bill denomination shown in a [MoneySpec]. Values
/// are in cents to keep arithmetic in integers (e.g. `quarter = 25`,
/// `oneDollar = 100`, `fiveDollar = 500`).
enum MoneyDenom {
  penny(1, '1¢', isCoin: true),
  nickel(5, '5¢', isCoin: true),
  dime(10, '10¢', isCoin: true),
  quarter(25, '25¢', isCoin: true),
  oneDollar(100, r'$1', isCoin: false),
  fiveDollar(500, r'$5', isCoin: false),
  tenDollar(1000, r'$10', isCoin: false),
  twentyDollar(2000, r'$20', isCoin: false);

  const MoneyDenom(this.cents, this.label, {required this.isCoin});

  /// Face value in cents.
  final int cents;

  /// Short kid-facing label. Coins are shown in `Nc` form, bills in
  /// `$N` form.
  final String label;

  /// True for coins (rendered as circles), false for paper bills
  /// (rendered as rounded rectangles).
  final bool isCoin;
}

/// A small money figure showing a sequence of coins and/or bills. The
/// renderer arranges them left-to-right (coins first, then bills) so
/// the visual stays consistent across generator instances.
///
/// Used by `coins_id_value`, `count_coins`, `count_bills_coins`,
/// `change_from_purchase`.
class MoneySpec extends DiagramSpec {
  const MoneySpec({required this.items})
    : assert(items.length >= 1, 'need at least one coin or bill');

  final List<MoneyDenom> items;
}

/// A picture graph (a.k.a. pictograph): one row per category, with a
/// horizontal row of icon glyphs whose count visualises that category's
/// value. The optional [scale] makes one icon represent multiple units
/// (so `bananas = 6` with `scale = 2` is drawn as 3 icons + a "Each
/// 🍌 = 2" key).
///
/// Used by `classify_count_categories`, `three_category_data`,
/// `picture_graph_read`, `scaled_picture_graph`.
class PictureGraphSpec extends DiagramSpec {
  const PictureGraphSpec({
    required this.title,
    required this.rowLabels,
    required this.values,
    required this.icon,
    this.scale = 1,
  }) : assert(rowLabels.length == values.length, 'rows and values align'),
       assert(rowLabels.length >= 2, 'need at least 2 rows'),
       assert(scale > 0, 'scale must be > 0');

  /// Header above the graph, e.g. "Favourite fruit".
  final String title;

  /// Row labels shown to the left of each icon row.
  final List<String> rowLabels;

  /// Per-row category counts (in real units, not icons). Each value must
  /// be a non-negative multiple of [scale]; the renderer draws
  /// `value ~/ scale` icons in that row.
  final List<int> values;

  /// Single character / short glyph repeated across each row. Typically
  /// a Unicode emoji.
  final String icon;

  /// "1 icon = $scale units". 1 for unscaled picture graphs (the K-G2
  /// case); >1 for scaled (G3 — `scaled_picture_graph`).
  final int scale;
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

/// A closed polygon drawn on the coordinate plane. Vertices are
/// connected in order and the polygon is auto-closed (last → first).
/// Used by `polygon_on_coordinate_plane` and the `transformations_*`
/// family (preimage = solid; image = dashed).
class CoordinatePlanePolygon {
  const CoordinatePlanePolygon({
    required this.vertices,
    this.style = CoordinatePlanePolygonStyle.solid,
  }) : assert(vertices.length >= 3, 'polygon needs ≥ 3 vertices');

  final List<CoordinatePlanePoint> vertices;
  final CoordinatePlanePolygonStyle style;
}

/// Visual style for a [CoordinatePlanePolygon].
enum CoordinatePlanePolygonStyle {
  /// Solid translucent fill + crisp outline in the primary colour.
  /// Use for the preimage / current shape.
  solid,

  /// Dashed outline in a secondary colour, no fill. Use for the image
  /// of a transformation so the eye reads it as "the result".
  dashed,
}

/// One labelled wedge in an [AngleSpec]: the arc lives between rays
/// `rayIndex` and `rayIndex + 1` (mod `rayAnglesDeg.length`), and shows
/// [label] inside the arc.
class AngleWedgeLabel {
  const AngleWedgeLabel({required this.rayIndex, required this.label})
    : assert(rayIndex >= 0, 'rayIndex must be >= 0');

  final int rayIndex;
  final String label;
}

/// A figure made of rays emerging from a single vertex, with optional
/// labels inside the wedges between consecutive rays. Covers most basic
/// angle questions: single labelled angle (rays at 2 directions), two
/// adjacent angles (3 rays), and two intersecting lines (4 rays).
///
/// Ray directions are in degrees, with 0° pointing east and CCW positive
/// (so 90° points north). Rays are drawn in `rayAnglesDeg` order; wedge i
/// is the arc from ray i to ray i+1 (no wrap-around wedge unless one is
/// explicitly emitted by repeating the first ray index in [wedgeLabels]).
class AngleSpec extends DiagramSpec {
  const AngleSpec({
    required this.rayAnglesDeg,
    this.wedgeLabels = const [],
  }) : assert(rayAnglesDeg.length >= 2, 'need at least 2 rays');

  final List<int> rayAnglesDeg;
  final List<AngleWedgeLabel> wedgeLabels;
}

/// A triangle with three vertices and a label placed inside the angle at
/// each vertex (e.g. "35°", "?", or "x°"). Vertex positions are computed
/// by the renderer; the spec only constrains the *appearance* of the
/// triangle (size class) so kids see a triangle that's visibly scalene
/// vs. isoceles when the angle measures warrant it.
///
/// Used by `triangle_angle_sum` and `exterior_angle_triangle`. For
/// exterior-angle questions, the third angle's label is `"?"` and the
/// generator pairs the diagram with a prompt about the exterior angle.
class TriangleAnglesSpec extends DiagramSpec {
  const TriangleAnglesSpec({
    required this.angleDegA,
    required this.angleDegB,
    required this.angleDegC,
    required this.labelA,
    required this.labelB,
    required this.labelC,
    this.showExteriorAtC = false,
  }) : assert(
         angleDegA > 0 && angleDegB > 0 && angleDegC > 0,
         'all three interior angles must be positive',
       ),
       assert(
         angleDegA + angleDegB + angleDegC == 180,
         'interior angles must sum to 180°',
       );

  /// Interior angle at vertex A, B, C (in degrees). Sum must be 180°.
  /// Drives the *shape* of the rendered triangle.
  final int angleDegA;
  final int angleDegB;
  final int angleDegC;

  /// Labels shown inside each vertex's interior angle. Typically the
  /// numeric measure with a degree sign, or `"?"` for the unknown.
  final String labelA;
  final String labelB;
  final String labelC;

  /// If true, the renderer draws a dashed extension of one side past
  /// vertex C and marks the exterior wedge — used by
  /// `exterior_angle_triangle`.
  final bool showExteriorAtC;
}

/// A 2-D coordinate plane spanning `[minX, maxX] × [minY, maxY]` (inclusive
/// integer ranges), with a grid at every integer step, labelled axes, and
/// zero or more marked points or lines. Covers both first-quadrant
/// (`minX = minY = 0`) and four-quadrant (`minX, minY < 0`) flavours.
/// What kind of figure a [ShapeSpec] renders. Splits 2D polygons by name
/// (so a triangle is its own kind) and gives 3D solids schematic
/// outlines. The renderer is expected to draw each kind at a single
/// canonical orientation so kids can tell two squares from a square +
/// rectangle (e.g. rectangle is always wider than tall).
enum ShapeKind {
  // 2D — closed curves
  circle,
  // 2D — triangles by shape
  triangleRight,
  triangleEquilateral,
  triangleIsosceles,
  triangleScalene,
  // 2D — quadrilaterals
  square,
  rectangle,
  parallelogram,
  rhombus,
  trapezoid,
  // 2D — regular polygons (≥ 5 sides)
  pentagon,
  hexagon,
  octagon,
  // 3D — schematic outlines
  cube,
  sphere,
  cylinder,
  cone;

  /// Number of straight sides (0 for circle / sphere). Triangles = 3,
  /// quads = 4, etc. For 3D solids, returns the number of *visible*
  /// straight edges so the value can be used as a "how many sides /
  /// faces" answer — but most generators only ask about the 2D kinds.
  int get sideCount {
    switch (this) {
      case ShapeKind.circle:
      case ShapeKind.sphere:
        return 0;
      case ShapeKind.triangleRight:
      case ShapeKind.triangleEquilateral:
      case ShapeKind.triangleIsosceles:
      case ShapeKind.triangleScalene:
        return 3;
      case ShapeKind.square:
      case ShapeKind.rectangle:
      case ShapeKind.parallelogram:
      case ShapeKind.rhombus:
      case ShapeKind.trapezoid:
        return 4;
      case ShapeKind.pentagon:
        return 5;
      case ShapeKind.hexagon:
        return 6;
      case ShapeKind.octagon:
        return 8;
      case ShapeKind.cube:
      case ShapeKind.cylinder:
      case ShapeKind.cone:
        // Not meaningful as a side count — leave to specific generators.
        return -1;
    }
  }

  /// Kid-friendly display name. Triangles collapse to "triangle" so
  /// `identify_shape_2d` keeps a small answer pool; specialised
  /// generators (e.g. `triangleRight`) can override the prompt as
  /// needed.
  String get displayName {
    switch (this) {
      case ShapeKind.circle:
        return 'circle';
      case ShapeKind.triangleRight:
      case ShapeKind.triangleEquilateral:
      case ShapeKind.triangleIsosceles:
      case ShapeKind.triangleScalene:
        return 'triangle';
      case ShapeKind.square:
        return 'square';
      case ShapeKind.rectangle:
        return 'rectangle';
      case ShapeKind.parallelogram:
        return 'parallelogram';
      case ShapeKind.rhombus:
        return 'rhombus';
      case ShapeKind.trapezoid:
        return 'trapezoid';
      case ShapeKind.pentagon:
        return 'pentagon';
      case ShapeKind.hexagon:
        return 'hexagon';
      case ShapeKind.octagon:
        return 'octagon';
      case ShapeKind.cube:
        return 'cube';
      case ShapeKind.sphere:
        return 'sphere';
      case ShapeKind.cylinder:
        return 'cylinder';
      case ShapeKind.cone:
        return 'cone';
    }
  }

  /// True for the 3D solids (cube/sphere/cylinder/cone). 2D shapes
  /// return false.
  bool get is3D {
    switch (this) {
      case ShapeKind.cube:
      case ShapeKind.sphere:
      case ShapeKind.cylinder:
      case ShapeKind.cone:
        return true;
      case ShapeKind.circle:
      case ShapeKind.triangleRight:
      case ShapeKind.triangleEquilateral:
      case ShapeKind.triangleIsosceles:
      case ShapeKind.triangleScalene:
      case ShapeKind.square:
      case ShapeKind.rectangle:
      case ShapeKind.parallelogram:
      case ShapeKind.rhombus:
      case ShapeKind.trapezoid:
      case ShapeKind.pentagon:
      case ShapeKind.hexagon:
      case ShapeKind.octagon:
        return false;
    }
  }
}

/// A spinner divided into equal sectors. Each entry in [sectors]
/// represents one sector and carries the color label that appears
/// on the wedge. Sectors with the same color name are filled with
/// the same paint. Used by probability generators.
class SpinnerSpec extends DiagramSpec {
  const SpinnerSpec({required this.sectors})
      : assert(sectors.length >= 2, 'spinner needs at least 2 sectors');

  /// The color label for each sector. e.g. `['red', 'red', 'blue']`
  /// means 3 equal sectors, 2 red and 1 blue.
  final List<String> sectors;
}

/// A circle drawn at a fixed canonical size with optional radius
/// and diameter markings + numeric labels. Used by
/// `circle_circumference` and `area_circle`.
class CircleSpec extends DiagramSpec {
  const CircleSpec({
    required this.radius,
    this.showRadius = true,
    this.showDiameter = false,
  })  : assert(radius >= 1, 'radius must be >= 1');

  /// The numeric radius value to label on the diagram. Visual size of
  /// the circle is normalized by the widget — the label is what the
  /// kid uses for arithmetic.
  final int radius;

  /// If true, draw a radius line from the centre to the boundary and
  /// label it with the value.
  final bool showRadius;

  /// If true, draw a diameter line through the centre and label it
  /// with 2·radius.
  final bool showDiameter;
}

/// A 3D rectangular prism (length × width × height) drawn in
/// isometric outline. Used by `volume_unit_cubes`,
/// `pythagorean_apply_3d`, and other generators that benefit from
/// seeing labelled dimensions on a 3D figure.
class Box3DSpec extends DiagramSpec {
  const Box3DSpec({
    required this.length,
    required this.width,
    required this.height,
    this.showUnitGrid = false,
    this.showDimensionLabels = true,
  })  : assert(length >= 1, 'length must be >= 1'),
        assert(width >= 1, 'width must be >= 1'),
        assert(height >= 1, 'height must be >= 1');

  final int length;
  final int width;
  final int height;

  /// If true, draws gridlines on each visible face so unit cubes are
  /// visible — used by `volume_unit_cubes`.
  final bool showUnitGrid;

  /// If true, labels the three visible edges with their integer
  /// values (l, w, h).
  final bool showDimensionLabels;
}

/// An unfolded cube net: 6 connected square faces in the canonical
/// "plus / cross" layout. Used by `surface_area_from_net`.
class Net3DSpec extends DiagramSpec {
  const Net3DSpec({required this.edgeLength})
      : assert(edgeLength >= 1, 'edgeLength must be >= 1');

  /// Edge length of the cube. Each of the 6 net squares is this size
  /// (label is shown on one of them so the kid sees the scale).
  final int edgeLength;
}

/// What kind of one-dimensional figure to draw in a [LineFigureSpec].
/// `line` extends infinitely both ways (arrows on each end); `ray`
/// extends one way (arrow on one end, endpoint dot on the other);
/// `segment` is bounded (endpoint dots on both ends).
enum LineFigureKind {
  line,
  ray,
  segment,
  parallelLines,
  perpendicularLines,
  intersectingLines;

  String get displayName {
    switch (this) {
      case LineFigureKind.line:
        return 'line';
      case LineFigureKind.ray:
        return 'ray';
      case LineFigureKind.segment:
        return 'line segment';
      case LineFigureKind.parallelLines:
        return 'parallel';
      case LineFigureKind.perpendicularLines:
        return 'perpendicular';
      case LineFigureKind.intersectingLines:
        return 'intersecting';
    }
  }
}

/// A schematic figure showing a line / ray / segment, or a pair of
/// two lines in one of three relationships (parallel / perpendicular
/// / intersecting). Used by `identify_lines_rays_segments` and
/// `parallel_perpendicular_lines`.
class LineFigureSpec extends DiagramSpec {
  const LineFigureSpec({required this.kind});

  final LineFigureKind kind;
}

/// Two horizontal "tape" bars stacked vertically: the top bar is
/// split into [topUnits] equal-width unit boxes, the bottom bar into
/// [bottomUnits], both using the same unit size so the kid sees the
/// a:b ratio as the relative bar lengths.
///
/// Used by `ratio_table` and (optionally) by other proportional-
/// reasoning generators.
class TapeDiagramSpec extends DiagramSpec {
  const TapeDiagramSpec({
    required this.topUnits,
    required this.bottomUnits,
    this.topLabel,
    this.bottomLabel,
  })  : assert(topUnits >= 1, 'topUnits must be >= 1'),
        assert(bottomUnits >= 1, 'bottomUnits must be >= 1');

  final int topUnits;
  final int bottomUnits;
  final String? topLabel;
  final String? bottomLabel;
}

/// Two parallel number lines stacked vertically with corresponding
/// tick positions: position `i` on the top line corresponds to
/// position `i` on the bottom line. Used to visualise a proportional
/// relationship between two quantities (e.g. "for every 2 cups of
/// flour, you need 5 cups of sugar").
///
/// Used by `double_number_line` and (optionally) other ratio /
/// proportional-reasoning generators.
class DoubleNumberLineSpec extends DiagramSpec {
  const DoubleNumberLineSpec({
    required this.topValues,
    required this.bottomValues,
    this.topLabel,
    this.bottomLabel,
  });

  /// Tick values along the top line (left-to-right, including 0 at
  /// position 0 by convention).
  final List<int> topValues;

  /// Tick values along the bottom line, same length as [topValues].
  final List<int> bottomValues;

  final String? topLabel;
  final String? bottomLabel;
}

/// Base-ten place-value blocks: a count of hundreds (10×10 flat),
/// tens (1×10 rod), and ones (1×1 unit cube). The renderer draws each
/// in canonical Diene's-blocks form so kids see place value as
/// physical magnitude.
///
/// Used by `teen_numbers_as_ten_plus` and (optionally) by 2- and
/// 3-digit place-value generators when they want a concrete picture.
class BaseTenBlocksSpec extends DiagramSpec {
  const BaseTenBlocksSpec({
    this.hundreds = 0,
    this.tens = 0,
    this.ones = 0,
  })  : assert(hundreds >= 0, 'hundreds must be >= 0'),
        assert(tens >= 0, 'tens must be >= 0'),
        assert(ones >= 0, 'ones must be >= 0');

  final int hundreds;
  final int tens;
  final int ones;
}

/// A schematic 2D or 3D figure used by shape-recognition, polygon-
/// classification, and basic geometry generators. Drawn outline-only at
/// a canonical orientation so kids can tell shape kinds apart at a
/// glance (e.g. rectangle is wider than tall; trapezoid is shown with
/// the longer base on the bottom).
///
/// Used by `identify_shape_2d`, `identify_shape_3d`,
/// `shape_attributes_basic`, `identify_polygons`.
class ShapeSpec extends DiagramSpec {
  const ShapeSpec({
    required this.kind,
    this.label,
    this.showRightAngleMark = false,
  });

  final ShapeKind kind;

  /// Optional text label drawn near the figure (e.g. "A" for a labelled
  /// triangle, or a measurement like "5 cm"). Not used by the first
  /// shape generators but available for later geometry questions.
  final String? label;

  /// If true on a right triangle, draws the small square symbol at the
  /// right-angle vertex.
  final bool showRightAngleMark;
}

class CoordinatePlaneSpec extends DiagramSpec {
  const CoordinatePlaneSpec({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    this.points = const [],
    this.lines = const [],
    this.polygons = const [],
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

  /// Optional list of closed polygons. Drawn beneath points and lines
  /// so labelled vertices remain visible.
  final List<CoordinatePlanePolygon> polygons;
}
