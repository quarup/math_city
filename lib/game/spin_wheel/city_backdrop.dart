import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

/// Sky gradient and the home-screen city strip behind the wheel. While the
/// wheel turns the city smears sideways in proportion to wheel speed
/// ([intensity]: 0 = at rest, 1 = full throw, set by the game every frame);
/// the streaks over it are `SpinStreaks`.
class CityBackdrop extends PositionComponent {
  CityBackdrop({required this.skyTop, required this.skyBottom})
    : super(priority: 0);

  final Color skyTop;
  final Color skyBottom;

  /// `assets/images/math_city_bottom.png` is 2170×420.
  static const double stripAspect = 2170 / 420;

  /// The strip is drawn wider than the screen so it can crop at the sides
  /// without ever cropping at the bottom (and so the blur has real city to
  /// sample beyond the edge).
  static const double stripOverhang = 0.19;

  ui.Image? _strip;
  double intensity = 0;

  /// Wheel radius, set by the game once laid out: the blur scales with it.
  double wheelRadius = 100;

  /// Top edge of the strip in game coordinates, for laying out the wheel.
  double get stripTop => size.y - stripHeight;
  double get stripWidth => size.x * (1 + 2 * stripOverhang);
  double get stripHeight => stripWidth / stripAspect;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _strip = await Flame.images.load('math_city_bottom.png');
  }

  @override
  void render(Canvas canvas) {
    final k = intensity.clamp(0.0, 1.0);
    final full = Rect.fromLTWH(0, 0, size.x, size.y);
    final blur = k * 10 * (wheelRadius / 148);
    final blurred = blur > 0.3;

    if (blurred) {
      canvas.saveLayer(
        full,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: blur,
            tileMode: TileMode.clamp,
          ),
      );
    }

    // Sky, painted past both edges so a horizontal blur never pulls in
    // transparent pixels (the bezel showed through in the first mock).
    final sky = Rect.fromLTWH(-80, -20, size.x + 160, size.y + 40);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.y),
          [skyTop, skyBottom],
        ),
    );

    final strip = _strip;
    if (strip != null) {
      final w = stripWidth;
      final h = stripHeight;
      canvas.drawImageRect(
        strip,
        Rect.fromLTWH(0, 0, strip.width.toDouble(), strip.height.toDouble()),
        Rect.fromLTWH((size.x - w) / 2, size.y - h, w, h),
        Paint()..filterQuality = FilterQuality.medium,
      );
    }

    if (blurred) canvas.restore();
  }
}
