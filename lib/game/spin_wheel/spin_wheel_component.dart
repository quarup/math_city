import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// One segment of the spin wheel.
class WheelSegment {
  const WheelSegment({
    required this.conceptId,
    required this.label,
    required this.color,
  });

  final String conceptId;
  final String label;
  final Color color;
}

/// Spinning wheel Flame component.
///
/// The wheel fills its [size] area. A fixed pointer triangle sits at the
/// top; whichever segment is under the pointer when the free spin stops is
/// reported via [onLanded].
///
/// Interaction is driven by the enclosing game:
///   - [rotateBy] applies a drag delta while the user's finger is down.
///   - [startSpinWithVelocity] launches the free spin on release.
class SpinWheelComponent extends PositionComponent {
  SpinWheelComponent({
    required this.segments,
    required this.onLanded,
  });

  final List<WheelSegment> segments;
  final void Function(String conceptId) onLanded;

  double _rotation = 0;
  double _angularVelocity = 0;
  bool _isSpinning = false;
  bool _hasReported = false;

  bool get isSpinning => _isSpinning;

  /// Apply an incremental rotation during a drag gesture.
  void rotateBy(double delta) => _rotation += delta;

  /// Begin free-spin deceleration at [angularVelocity] (radians/second).
  /// Positive = clockwise; negative = counter-clockwise.
  void startSpinWithVelocity(double angularVelocity) {
    _isSpinning = true;
    _hasReported = false;
    _angularVelocity = angularVelocity;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isSpinning) return;

    // Frame-rate-independent exponential decay.
    final effectiveDt = dt.clamp(0.0, 0.1);
    _rotation += _angularVelocity * effectiveDt;
    _angularVelocity *= math.exp(-1.5 * effectiveDt);

    if (_angularVelocity.abs() < 0.05 && !_hasReported) {
      _isSpinning = false;
      _hasReported = true;
      onLanded(segments[_selectedSegmentIndex].conceptId);
    }
  }

  /// Index of the segment currently under the top pointer.
  int get _selectedSegmentIndex {
    // Canvas: 0 rad = right (3 o'clock), clockwise. Top = 3π/2.
    const indicator = math.pi * 1.5;
    final sweep = 2 * math.pi / segments.length;
    var relative = (indicator - _rotation) % (2 * math.pi);
    if (relative < 0) relative += 2 * math.pi;
    return (relative / sweep).floor() % segments.length;
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final center = Offset(cx, cy);
    final radius = math.min(size.x, size.y) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi / segments.length;

    for (var i = 0; i < segments.length; i++) {
      final start = _rotation + i * sweep;
      canvas
        ..drawArc(
          rect,
          start,
          sweep,
          true,
          Paint()..color = segments[i].color,
        )
        ..drawArc(
          rect,
          start,
          sweep,
          true,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
    }

    // Text labels
    for (var i = 0; i < segments.length; i++) {
      final midAngle = _rotation + (i + 0.5) * sweep;
      final labelR = radius * 0.62;
      _drawLabel(
        canvas,
        segments[i].label,
        Offset(
          center.dx + math.cos(midAngle) * labelR,
          center.dy + math.sin(midAngle) * labelR,
        ),
      );
    }

    // Outer ring, then centre hub
    canvas
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      )
      ..drawCircle(center, 14, Paint()..color = Colors.white)
      ..drawCircle(
        center,
        14,
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

    // Fixed pointer at top (does not rotate with the wheel)
    final pointerPath = Path()
      ..moveTo(cx, cy - radius + 14) // tip points down into the wheel
      ..lineTo(cx - 10, cy - radius - 10)
      ..lineTo(cx + 10, cy - radius - 10)
      ..close();
    canvas
      ..drawPath(pointerPath, Paint()..color = Colors.red.shade700)
      ..drawPath(
        pointerPath,
        Paint()
          ..color = Colors.red.shade900
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
  }

  void _drawLabel(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0x99000000), blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}
