import 'package:flutter/material.dart';
import 'package:math_dash/domain/questions/diagram_spec.dart';
import 'package:math_dash/presentation/diagrams/clock.dart';
import 'package:math_dash/presentation/diagrams/fraction_bar.dart';
import 'package:math_dash/presentation/diagrams/number_line.dart';

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
  };
}
