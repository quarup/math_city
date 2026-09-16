import 'package:flutter/material.dart';
import 'package:math_city/domain/concepts/concept.dart';

// Concept category → colour (presentation concern; not in the domain layer).
//
// Per-category palette — the same category always wins the same colour
// family, so a kid quickly associates "orange = addition" / "purple =
// fractions" regardless of which sub-concept the wheel currently surfaces.
// Shared by the wheel segments and the block summary's new-topic badges.

const _categoryColors = <String, Color>{
  'counting': Color(0xFFFFA000), // amber
  'place_value': Color(0xFFEF6C00), // orange-deep
  'add_sub': Color(0xFFFB8C00), // orange
  'mult_div': Color(0xFFE53935), // red
  'fractions': Color(0xFF8E24AA), // purple
  'decimals_percent': Color(0xFF6A1B9A), // deep purple
  'ratios': Color(0xFF1565C0), // blue-deep
  'measurement': Color(0xFF1E88E5), // blue
  'geometry': Color(0xFF00897B), // teal
  'rationals': Color(0xFF2E7D32), // green-deep
  'prealgebra': Color(0xFF43A047), // green
  'stats': Color(0xFF6D4C41), // brown
};

Color categoryColorFor(Concept c) =>
    _categoryColors[c.categoryId] ?? Colors.grey.shade600;
