import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [TapeDiagramSpec] as two horizontal bars stacked
/// vertically. Each bar is divided into unit cells of the same width,
/// so the relative bar lengths visually reproduce the a:b ratio.
class TapeDiagram extends StatelessWidget {
  const TapeDiagram({
    required this.spec,
    this.unitSize = 28,
    this.height = 32,
    super.key,
  });

  final TapeDiagramSpec spec;
  final double unitSize;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxUnits = spec.topUnits > spec.bottomUnits
        ? spec.topUnits
        : spec.bottomUnits;
    final width = maxUnits * unitSize;
    final topFill = theme.colorScheme.primary.withValues(alpha: 0.20);
    final bottomFill = theme.colorScheme.secondary.withValues(alpha: 0.20);
    final edge = theme.colorScheme.onSurface;
    final labelStyle =
        theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (spec.topLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(spec.topLabel!, style: labelStyle),
          ),
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _TapeRowPainter(
              units: spec.topUnits,
              unitSize: unitSize,
              edge: edge,
              fill: topFill,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _TapeRowPainter(
              units: spec.bottomUnits,
              unitSize: unitSize,
              edge: edge,
              fill: bottomFill,
            ),
          ),
        ),
        if (spec.bottomLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(spec.bottomLabel!, style: labelStyle),
          ),
      ],
    );
  }
}

class _TapeRowPainter extends CustomPainter {
  _TapeRowPainter({
    required this.units,
    required this.unitSize,
    required this.edge,
    required this.fill,
  });

  final int units;
  final double unitSize;
  final Color edge;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = fill;
    final stroke = Paint()
      ..color = edge
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(0, 0, units * unitSize, size.height);
    canvas
      ..drawRect(rect, fillPaint)
      ..drawRect(rect, stroke);
    for (var i = 1; i < units; i++) {
      final x = i * unitSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), stroke);
    }
  }

  @override
  bool shouldRepaint(_TapeRowPainter old) =>
      old.units != units ||
      old.unitSize != unitSize ||
      old.edge != edge ||
      old.fill != fill;
}
