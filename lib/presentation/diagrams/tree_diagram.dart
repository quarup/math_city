import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [TreeDiagramSpec] as a vertical tree growing top-to-bottom.
/// Stage 0 appears at the top under the root label; each subsequent
/// stage adds another row of branches. Leaves at the bottom carry the
/// compound outcome label (e.g. "H, R").
///
/// Layout assumes small experiments — typically 2–3 stages with 2–3
/// branches each (≤ 9 leaves). Larger trees get crowded on phone
/// screens; generators self-limit to keep visuals readable.
class TreeDiagram extends StatelessWidget {
  const TreeDiagram({
    required this.spec,
    this.leafSlot = 56,
    this.rowHeight = 56,
    super.key,
  });

  final TreeDiagramSpec spec;
  final double leafSlot;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leaves = spec.leafCount;
    // +1 for the leaf-label row at the bottom.
    final rows = spec.stages.length + 1;
    const topGutter = 12.0;
    const bottomGutter = 12.0;
    const leftGutter = 12.0;
    const rightGutter = 12.0;
    final naturalWidth = leaves * leafSlot;

    return LayoutBuilder(
      builder: (context, constraints) {
        var slot = leafSlot;
        if (constraints.maxWidth.isFinite) {
          final avail = constraints.maxWidth - leftGutter - rightGutter;
          if (avail > 0 && naturalWidth > avail) {
            slot = avail / leaves;
          }
        }
        final plotWidth = leaves * slot;
        final plotHeight = rows * rowHeight;
        return SizedBox(
          width: plotWidth + leftGutter + rightGutter,
          height: plotHeight + topGutter + bottomGutter,
          child: CustomPaint(
            painter: _TreeDiagramPainter(
              spec: spec,
              leafSlot: slot,
              rowHeight: rowHeight,
              leftGutter: leftGutter,
              topGutter: topGutter,
              edgeColor: theme.colorScheme.onSurface,
              nodeColor: theme.colorScheme.primary,
              labelStyle:
                  theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11),
              leafStyle:
                  (theme.textTheme.labelMedium ??
                          const TextStyle(fontSize: 12))
                      .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

class _TreeDiagramPainter extends CustomPainter {
  _TreeDiagramPainter({
    required this.spec,
    required this.leafSlot,
    required this.rowHeight,
    required this.leftGutter,
    required this.topGutter,
    required this.edgeColor,
    required this.nodeColor,
    required this.labelStyle,
    required this.leafStyle,
  });

  final TreeDiagramSpec spec;
  final double leafSlot;
  final double rowHeight;
  final double leftGutter;
  final double topGutter;
  final Color edgeColor;
  final Color nodeColor;
  final TextStyle labelStyle;
  final TextStyle leafStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = edgeColor
      ..strokeWidth = 1.2;
    final nodePaint = Paint()..color = nodeColor;

    final leaves = spec.leafCount;
    // For each stage k, compute the number of nodes at that level and the
    // span (number of leaves) each one covers.
    final levelCounts = <int>[1]; // root
    for (var k = 0; k < spec.stages.length; k++) {
      levelCounts.add(levelCounts.last * spec.stages[k].outcomes.length);
    }
    // X position of node `i` at level `k`: centre of the leaf range it
    // covers. A node at level k covers `leaves / levelCounts[k]` leaves.
    double xForNode(int level, int i) {
      final span = leaves / levelCounts[level];
      return leftGutter + (i + 0.5) * span * leafSlot;
    }

    double yForLevel(int level) => topGutter + level * rowHeight;

    // Draw the root node.
    canvas.drawCircle(
      Offset(xForNode(0, 0), yForLevel(0)),
      4,
      nodePaint,
    );

    // For each stage k (1-indexed level), draw edges from parents at
    // level k-1 down to children at level k, with the stage's outcome
    // label on the midpoint of the edge.
    for (var k = 0; k < spec.stages.length; k++) {
      final parentLevel = k;
      final childLevel = k + 1;
      final parentCount = levelCounts[parentLevel];
      final outs = spec.stages[k].outcomes;

      for (var p = 0; p < parentCount; p++) {
        final px = xForNode(parentLevel, p);
        final py = yForLevel(parentLevel);
        for (var c = 0; c < outs.length; c++) {
          final childIdx = p * outs.length + c;
          final cx = xForNode(childLevel, childIdx);
          final cy = yForLevel(childLevel);
          canvas
            ..drawLine(Offset(px, py), Offset(cx, cy), edgePaint)
            ..drawCircle(Offset(cx, cy), 4, nodePaint);
          // Edge label: outcome name at the midpoint, just to the side
          // so it doesn't overlap the line.
          _drawText(
            canvas,
            outs[c],
            Offset((px + cx) / 2 + 8, (py + cy) / 2 - 6),
            labelStyle,
            alignLeft: true,
          );
        }
      }
    }

    // Leaf labels: compound outcomes "a, b, c" at the bottom row.
    for (var i = 0; i < leaves; i++) {
      final compound = _compoundLabelForLeaf(i);
      _drawText(
        canvas,
        compound,
        Offset(
          xForNode(spec.stages.length, i),
          yForLevel(spec.stages.length) + 18,
        ),
        leafStyle,
      );
    }
  }

  /// Build "H, R" / "T, B" / etc. for leaf index `i` by decomposing it
  /// into the per-stage outcome indices.
  String _compoundLabelForLeaf(int leafIdx) {
    final parts = <String>[];
    var idx = leafIdx;
    final divisors = <int>[];
    var prod = 1;
    for (var k = spec.stages.length - 1; k >= 0; k--) {
      divisors.add(prod);
      prod *= spec.stages[k].outcomes.length;
    }
    final orderedDivisors = divisors.reversed.toList();
    for (var k = 0; k < spec.stages.length; k++) {
      final d = orderedDivisors[k];
      final pos = idx ~/ d;
      idx = idx % d;
      parts.add(spec.stages[k].outcomes[pos]);
    }
    return parts.join(', ');
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style, {
    bool alignLeft = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(leafSlot * 2, 64));
    final dx = alignLeft ? anchor.dx : anchor.dx - tp.width / 2;
    final dy = anchor.dy - tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_TreeDiagramPainter old) =>
      old.spec != spec ||
      old.leafSlot != leafSlot ||
      old.rowHeight != rowHeight ||
      old.edgeColor != edgeColor ||
      old.nodeColor != nodeColor;
}
