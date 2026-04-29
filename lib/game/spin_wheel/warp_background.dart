import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Animated warp-space overlay shown while the wheel is spinning.
///
/// Call [activate] when a spin starts and [deactivate] on landing.
/// Opacity transitions smoothly in both directions.
class WarpBackground extends PositionComponent {
  // Rendered behind the wheel (priority 0).
  WarpBackground() : super(priority: 0);

  double _time = 0;
  double _overlayOpacity = 0;
  bool _active = false;

  // 60 speed lines with fixed geometry (seeded for repeatability).
  static final List<(double, double, double)> _lineData = _buildLineData();

  static List<(double, double, double)> _buildLineData() {
    final rng = math.Random(42);
    return List<(double, double, double)>.generate(
      60,
      (_) => (
        rng.nextDouble() * 2 * math.pi,
        rng.nextDouble() * 0.3 + 0.2,
        rng.nextDouble(),
      ),
    );
  }

  /// Immediately flash bright, then the update loop settles to the
  /// steady level.
  void activate() {
    _active = true;
    _overlayOpacity = 1.0;
  }

  void deactivate() => _active = false;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_active) {
      // Decay the initial flash burst down to the steady spinning level (0.65).
      if (_overlayOpacity > 0.65) {
        _overlayOpacity = (_overlayOpacity - dt * 3.0).clamp(0.65, 1.0);
      } else {
        _overlayOpacity = (_overlayOpacity + dt * 2.5).clamp(0.0, 0.65);
      }
    } else {
      _overlayOpacity = (_overlayOpacity - dt * 2.0).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_overlayOpacity < 0.01) return;

    final cx = size.x / 2;
    final cy = size.y / 2;
    // Reach all the way to canvas corners.
    final maxR = math.sqrt(cx * cx + cy * cy);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Color.fromRGBO(0, 0, 30, _overlayOpacity * 0.6),
    );

    // 5 expanding rings cycling outward.
    for (var i = 0; i < 5; i++) {
      final progress = (_time * 0.4 + i / 5.0) % 1.0;
      final ringR = progress * maxR;
      final opacity = (1.0 - progress) * _overlayOpacity;
      canvas.drawCircle(
        Offset(cx, cy),
        ringR,
        Paint()
          ..color = Color.fromRGBO(70, 130, 255, opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 + (1.0 - progress) * 6,
      );
    }

    // 60 radial speed lines streaming outward.
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    for (var i = 0; i < 60; i++) {
      final (angle, speed, startOffset) = _lineData[i];
      final t = (_time * speed + startOffset) % 1.0;
      final startR = t * maxR;
      final endR = (t + 0.15).clamp(0.0, 1.0) * maxR;
      final opacity = (1.0 - t) * _overlayOpacity;
      linePaint.color = Color.fromRGBO(180, 210, 255, opacity);
      canvas.drawLine(
        Offset(cx + math.cos(angle) * startR, cy + math.sin(angle) * startR),
        Offset(cx + math.cos(angle) * endR, cy + math.sin(angle) * endR),
        linePaint,
      );
    }
  }
}
