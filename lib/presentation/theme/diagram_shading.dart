import 'package:flutter/material.dart';

/// Fill for a "shaded" part of a diagram whose question asks the kid to read
/// the shading ("What fraction is shaded?" fraction bars, the percent grid).
/// Near-black, so shaded vs not reads at a glance — the theme's green was
/// too close to the empty fill. Diagrams that only use shading as
/// decoration (arrays, area models, fraction division) keep the theme
/// colors.
const Color kDiagramShadedFill = Color(0xFF212121);

/// Fill for an unshaded part of the same diagrams.
const Color kDiagramEmptyFill = Color(0xFFEEEEEE);
