import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [BaseTenBlocksSpec] as a row of Diene's-style base-ten
/// blocks: hundreds-flats on the left, tens-rods in the middle,
/// ones-cubes on the right. Each block is drawn outline-only with a
/// light fill and an internal grid so the kid sees 1/10/100 scale.
class BaseTenBlocks extends StatelessWidget {
  const BaseTenBlocks({
    required this.spec,
    this.cellSize = 8,
    super.key,
  });

  final BaseTenBlocksSpec spec;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final edge = theme.colorScheme.onSurface;
    final fill = theme.colorScheme.primary.withValues(alpha: 0.18);
    final children = <Widget>[
      for (var i = 0; i < spec.hundreds; i++)
        _Flat(cellSize: cellSize, edge: edge, fill: fill),
      for (var i = 0; i < spec.tens; i++)
        _Rod(cellSize: cellSize, edge: edge, fill: fill),
      for (var i = 0; i < spec.ones; i++)
        _Unit(cellSize: cellSize, edge: edge, fill: fill),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }
}

class _Flat extends StatelessWidget {
  const _Flat({
    required this.cellSize,
    required this.edge,
    required this.fill,
  });

  final double cellSize;
  final Color edge;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cellSize * 10,
      height: cellSize * 10,
      child: CustomPaint(
        painter: _GridPainter(
          cols: 10,
          rows: 10,
          cellSize: cellSize,
          edge: edge,
          fill: fill,
        ),
      ),
    );
  }
}

class _Rod extends StatelessWidget {
  const _Rod({
    required this.cellSize,
    required this.edge,
    required this.fill,
  });

  final double cellSize;
  final Color edge;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cellSize,
      height: cellSize * 10,
      child: CustomPaint(
        painter: _GridPainter(
          cols: 1,
          rows: 10,
          cellSize: cellSize,
          edge: edge,
          fill: fill,
        ),
      ),
    );
  }
}

class _Unit extends StatelessWidget {
  const _Unit({
    required this.cellSize,
    required this.edge,
    required this.fill,
  });

  final double cellSize;
  final Color edge;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: CustomPaint(
        painter: _GridPainter(
          cols: 1,
          rows: 1,
          cellSize: cellSize,
          edge: edge,
          fill: fill,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.cols,
    required this.rows,
    required this.cellSize,
    required this.edge,
    required this.fill,
  });

  final int cols;
  final int rows;
  final double cellSize;
  final Color edge;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = fill;
    final strokePaint = Paint()
      ..color = edge
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas
      ..drawRect(rect, fillPaint)
      ..drawRect(rect, strokePaint);

    // Interior gridlines — only if the block has more than one cell.
    if (cols > 1 || rows > 1) {
      for (var c = 1; c < cols; c++) {
        final x = c * cellSize;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), strokePaint);
      }
      for (var r = 1; r < rows; r++) {
        final y = r * cellSize;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.cols != cols ||
      old.rows != rows ||
      old.cellSize != cellSize ||
      old.edge != edge ||
      old.fill != fill;
}
