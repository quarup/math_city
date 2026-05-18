import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/presentation/diagrams/angle.dart';
import 'package:math_city/presentation/diagrams/area_grid.dart';
import 'package:math_city/presentation/diagrams/bar_chart.dart';
import 'package:math_city/presentation/diagrams/base_ten_blocks.dart';
import 'package:math_city/presentation/diagrams/box_3d.dart';
import 'package:math_city/presentation/diagrams/box_plot.dart';
import 'package:math_city/presentation/diagrams/circle.dart';
import 'package:math_city/presentation/diagrams/clock.dart';
import 'package:math_city/presentation/diagrams/coordinate_plane.dart';
import 'package:math_city/presentation/diagrams/dot_plot.dart';
import 'package:math_city/presentation/diagrams/double_number_line.dart';
import 'package:math_city/presentation/diagrams/fraction_bar.dart';
import 'package:math_city/presentation/diagrams/histogram.dart';
import 'package:math_city/presentation/diagrams/line_figure.dart';
import 'package:math_city/presentation/diagrams/money.dart';
import 'package:math_city/presentation/diagrams/net_3d.dart';
import 'package:math_city/presentation/diagrams/number_line.dart';
import 'package:math_city/presentation/diagrams/percent_grid.dart';
import 'package:math_city/presentation/diagrams/picture_graph.dart';
import 'package:math_city/presentation/diagrams/protractor.dart';
import 'package:math_city/presentation/diagrams/ruler.dart';
import 'package:math_city/presentation/diagrams/shape.dart';
import 'package:math_city/presentation/diagrams/tape_diagram.dart';
import 'package:math_city/presentation/diagrams/tree_diagram.dart';
import 'package:math_city/presentation/diagrams/triangle_angles.dart';
import 'package:math_city/presentation/diagrams/two_way_table.dart';

/// Dispatches a [DiagramSpec] (pure-Dart value type) to the corresponding
/// Flutter widget. Used by the question screen so generators in
/// `lib/domain/questions/` never import Flutter.
class DiagramRenderer extends StatelessWidget {
  const DiagramRenderer({required this.spec, super.key});

  final DiagramSpec spec;

  @override
  Widget build(BuildContext context) => switch (spec) {
    final FractionBarSpec s => FractionBar(spec: s),
    final NumberLineSpec s => NumberLine(spec: s),
    final ClockSpec s => Clock(spec: s),
    final AreaGridSpec s => AreaGrid(spec: s),
    final PercentGridSpec s => PercentGrid(spec: s),
    final CoordinatePlaneSpec s => CoordinatePlane(spec: s),
    final BarChartSpec s => BarChart(spec: s),
    final DotPlotSpec s => DotPlot(spec: s),
    final HistogramSpec s => Histogram(spec: s),
    final BoxPlotSpec s => BoxPlot(spec: s),
    final TreeDiagramSpec s => TreeDiagram(spec: s),
    final TwoWayTableSpec s => TwoWayTable(spec: s),
    final AngleSpec s => Angle(spec: s),
    final TriangleAnglesSpec s => TriangleAngles(spec: s),
    final PictureGraphSpec s => PictureGraph(spec: s),
    final MoneySpec s => Money(spec: s),
    final RulerSpec s => Ruler(spec: s),
    final ProtractorSpec s => Protractor(spec: s),
    final ShapeSpec s => Shape(spec: s),
    final BaseTenBlocksSpec s => BaseTenBlocks(spec: s),
    final TapeDiagramSpec s => TapeDiagram(spec: s),
    final DoubleNumberLineSpec s => DoubleNumberLine(spec: s),
    final LineFigureSpec s => LineFigure(spec: s),
    final Box3DSpec s => Box3D(spec: s),
    final Net3DSpec s => Net3D(spec: s),
    final CircleSpec s => Circle(spec: s),
  };
}
