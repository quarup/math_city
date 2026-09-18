import 'package:flutter/material.dart';
import 'package:math_city/domain/concepts/concept.dart';

// Concept category → colour (presentation concern; not in the domain layer).
//
// Per-category palette — the same category always wins the same colour
// family, so a kid quickly associates "coral = addition" / "purple =
// fractions" regardless of which sub-concept the wheel currently surfaces.
// Tints are aligned to the logo (teal, orange, yellow) rather than Material's
// saturated defaults so the wheel sits with the rest of the art. Shared by
// the wheel wedges and the block summary's new-topic badges.

const _categoryColors = <String, Color>{
  'counting': Color(0xFFF0CC30), // logo yellow
  'place_value': Color(0xFFF2A33A), // logo orange
  'add_sub': Color(0xFFF07A4A), // coral
  'mult_div': Color(0xFFE25A5A), // red
  'fractions': Color(0xFFA56BC2), // purple
  'decimals_percent': Color(0xFF7A5FB0), // violet
  'ratios': Color(0xFF4A8BDA), // blue
  'measurement': Color(0xFF5DB7E8), // sky
  'geometry': Color(0xFF2EB5A0), // logo teal
  'rationals': Color(0xFF3E9C6A), // green-deep
  'prealgebra': Color(0xFF7CC36A), // green
  'stats': Color(0xFFB98457), // brown
};

Color categoryColorFor(Concept c) =>
    _categoryColors[c.categoryId] ?? Colors.grey.shade600;
