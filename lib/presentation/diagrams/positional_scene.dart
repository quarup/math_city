import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [PositionalSceneSpec] as two labelled rectangles placed in
/// the named spatial relation, so the K kid sees the scene rather than
/// inferring the position from prepositional phrases in the prompt.
class PositionalScene extends StatelessWidget {
  const PositionalScene({
    required this.spec,
    this.subjectSize = const Size(70, 32),
    this.referenceSize = const Size(120, 48),
    this.gap = 6,
    super.key,
  });

  final PositionalSceneSpec spec;
  final Size subjectSize;
  final Size referenceSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectStyle = theme.colorScheme.primary;
    final referenceStyle = theme.colorScheme.secondary;
    final labelStyle =
        theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    final edge = theme.colorScheme.onSurface;

    final subject = _Box(
      label: spec.subjectLabel,
      size: subjectSize,
      fill: subjectStyle.withValues(alpha: 0.30),
      edge: edge,
      labelStyle: labelStyle,
    );
    final reference = _Box(
      label: spec.referenceLabel,
      size: referenceSize,
      fill: referenceStyle.withValues(alpha: 0.20),
      edge: edge,
      labelStyle: labelStyle,
    );

    switch (spec.relation) {
      case PositionRelation.above:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            subject,
            SizedBox(height: gap),
            reference,
          ],
        );
      case PositionRelation.below:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            reference,
            SizedBox(height: gap),
            subject,
          ],
        );
      case PositionRelation.beside:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            reference,
            SizedBox(width: gap),
            subject,
          ],
        );
      case PositionRelation.inside:
        return SizedBox(
          width: referenceSize.width,
          height: referenceSize.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              reference,
              subject,
            ],
          ),
        );
    }
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.label,
    required this.size,
    required this.fill,
    required this.edge,
    required this.labelStyle,
  });

  final String label;
  final Size size;
  final Color fill;
  final Color edge;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) => Container(
    width: size.width,
    height: size.height,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: fill,
      border: Border.all(color: edge, width: 1.2),
    ),
    child: Text(label, style: labelStyle, textAlign: TextAlign.center),
  );
}
