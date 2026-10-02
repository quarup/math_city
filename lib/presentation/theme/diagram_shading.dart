import 'package:flutter/material.dart';

/// Fill for a "shaded" part of a diagram (fraction bar segments, percent-grid
/// cells, the area-model product). Near-black, so shaded vs not reads at a
/// glance — the theme's green was too close to the empty fill.
const Color kDiagramShadedFill = Color(0xFF212121);

/// Fill for an unshaded part of the same diagrams.
const Color kDiagramEmptyFill = Color(0xFFEEEEEE);
