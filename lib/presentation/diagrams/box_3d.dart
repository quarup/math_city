import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [Box3DSpec] as an isometric outline of a rectangular
/// prism. Three faces are visible (front, top, right). With
/// [Box3DSpec.showUnitGrid] true, each face is divided into a grid of
/// unit cells so the kid sees unit cubes. With
/// [Box3DSpec.showDimensionLabels] true, three edges are labelled
/// with their integer values.
class Box3D extends StatelessWidget {
  const Box3D({
    required this.spec,
    this.size = 200,
    super.key,
  });

  final Box3DSpec spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Box3DPainter(
          spec: spec,
          edge: theme.colorScheme.onSurface,
          fill: theme.colorScheme.primary.withValues(alpha: 0.12),
          gridColor: theme.colorScheme.outline.withValues(alpha: 0.6),
          labelStyle:
              theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _Box3DPainter extends CustomPainter {
  _Box3DPainter({
    required this.spec,
    required this.edge,
    required this.fill,
    required this.gridColor,
    required this.labelStyle,
  });

  final Box3DSpec spec;
  final Color edge;
  final Color fill;
  final Color gridColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    // Scale unit-cell size so the box fits in the canvas with a small
    // margin. The visible footprint (after isometric projection) is
    // (length + depthOffsetX) wide and (height + depthOffsetY) tall.
    const isoDepth = 0.45;
    final maxW = spec.length + spec.width * isoDepth;
    final maxH = spec.height + spec.width * isoDepth;
    final cell =
        (0.85 *
                (size.width / maxW < size.height / maxH
                    ? size.width / maxW
                    : size.height / maxH))
            .clamp(8.0, 64.0);
    final boxW = cell * spec.length;
    final boxH = cell * spec.height;
    final depthDx = cell * spec.width * isoDepth;
    final depthDy = -cell * spec.width * isoDepth;
    final originX = (size.width - (boxW + depthDx)) / 2;
    final originY = (size.height - (boxH - depthDy)) / 2 + boxH;

    // Front-face corners (anchored at origin, going up and right).
    final fbl = Offset(originX, originY);
    final fbr = Offset(originX + boxW, originY);
    final ftl = Offset(originX, originY - boxH);
    final ftr = Offset(originX + boxW, originY - boxH);
    // Back face = front + depth offset.
    final back = Offset(depthDx, depthDy);
    final bbr = fbr + back;
    final btl = ftl + back;
    final btr = ftr + back;

    final stroke = Paint()
      ..color = edge
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()..color = fill;
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8;

    // Front face fill + outline.
    final front = Path()
      ..moveTo(fbl.dx, fbl.dy)
      ..lineTo(fbr.dx, fbr.dy)
      ..lineTo(ftr.dx, ftr.dy)
      ..lineTo(ftl.dx, ftl.dy)
      ..close();
    canvas
      ..drawPath(front, fillPaint)
      ..drawPath(front, stroke);

    // Top face.
    final top = Path()
      ..moveTo(ftl.dx, ftl.dy)
      ..lineTo(ftr.dx, ftr.dy)
      ..lineTo(btr.dx, btr.dy)
      ..lineTo(btl.dx, btl.dy)
      ..close();
    canvas
      ..drawPath(top, fillPaint)
      ..drawPath(top, stroke);

    // Right face.
    final right = Path()
      ..moveTo(fbr.dx, fbr.dy)
      ..lineTo(ftr.dx, ftr.dy)
      ..lineTo(btr.dx, btr.dy)
      ..lineTo(bbr.dx, bbr.dy)
      ..close();
    canvas
      ..drawPath(right, fillPaint)
      ..drawPath(right, stroke);

    if (spec.showUnitGrid) {
      // Front face gridlines.
      for (var i = 1; i < spec.length; i++) {
        final x = originX + i * cell;
        canvas.drawLine(Offset(x, fbl.dy), Offset(x, ftl.dy), grid);
      }
      for (var j = 1; j < spec.height; j++) {
        final y = originY - j * cell;
        canvas.drawLine(Offset(fbl.dx, y), Offset(fbr.dx, y), grid);
      }
      // Top face gridlines (along length and depth).
      for (var i = 1; i < spec.length; i++) {
        final p1 = ftl + Offset(i * cell, 0);
        final p2 = p1 + back;
        canvas.drawLine(p1, p2, grid);
      }
      for (var j = 1; j < spec.width; j++) {
        final t = j / spec.width;
        final p1 = Offset(ftl.dx + t * depthDx, ftl.dy + t * depthDy);
        final p2 = Offset(ftr.dx + t * depthDx, ftr.dy + t * depthDy);
        canvas.drawLine(p1, p2, grid);
      }
      // Right face gridlines.
      for (var j = 1; j < spec.height; j++) {
        final y = j * cell;
        final p1 = Offset(fbr.dx, fbr.dy - y);
        final p2 = p1 + back;
        canvas.drawLine(p1, p2, grid);
      }
      for (var j = 1; j < spec.width; j++) {
        final t = j / spec.width;
        final p1 = Offset(fbr.dx + t * depthDx, fbr.dy + t * depthDy);
        final p2 = Offset(ftr.dx + t * depthDx, ftr.dy + t * depthDy);
        canvas.drawLine(p1, p2, grid);
      }
    }

    if (spec.showDimensionLabels) {
      // Bottom-front edge label = length.
      _drawText(
        canvas,
        '${spec.length}',
        Offset((fbl.dx + fbr.dx) / 2, fbl.dy + 10),
      );
      // Front-right vertical edge = height.
      _drawText(
        canvas,
        '${spec.height}',
        Offset(fbr.dx + 10, (fbr.dy + ftr.dy) / 2),
        alignLeft: true,
      );
      // Top-back depth label = width.
      _drawText(
        canvas,
        '${spec.width}',
        Offset((ftr.dx + btr.dx) / 2 + 6, (ftr.dy + btr.dy) / 2 - 4),
        alignLeft: true,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos, {
    bool alignLeft = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignLeft ? pos.dx : pos.dx - tp.width / 2;
    tp.paint(canvas, Offset(dx, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_Box3DPainter old) =>
      old.spec != spec ||
      old.edge != edge ||
      old.fill != fill ||
      old.gridColor != gridColor;
}
