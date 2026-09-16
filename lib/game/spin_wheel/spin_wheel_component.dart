import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// One segment of the spin wheel.
class WheelSegment {
  const WheelSegment({
    required this.conceptId,
    required this.label,
    required this.color,
    this.isNew = false,
    this.isReview = false,
  });

  final String conceptId;
  final String label;
  final Color color;

  /// The player has never answered a question on this concept — drawn with
  /// a "NEW" sticker so a fresh unlock is visible on the wheel itself.
  final bool isNew;

  /// A mastered concept back on the wheel as a review slot — drawn with a
  /// small check sticker so the kid knows it's one they already own.
  final bool isReview;
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
  bool _willSelect = false;
  int? _landedIndex;

  bool get isSpinning => _isSpinning;
  bool get willSelect => _willSelect;
  int get currentSelectedIndex => _selectedSegmentIndex;

  /// Cancel a non-selecting free spin so the player can try again.
  void cancelSpin() {
    _isSpinning = false;
    _angularVelocity = 0;
    _hasReported = true;
  }

  int? get landedIndex => _landedIndex;
  set landedIndex(int index) => _landedIndex = index;

  /// Returns the canvas position of the label for [index] (game coordinates).
  Vector2 labelPositionFor(int index) {
    final sweep = 2 * math.pi / segments.length;
    final midAngle = _rotation + (index + 0.5) * sweep;
    final radius = math.min(size.x, size.y) / 2 - 8;
    final labelR = radius * 0.62;
    return Vector2(
      size.x / 2 + math.cos(midAngle) * labelR,
      size.y / 2 + math.sin(midAngle) * labelR,
    );
  }

  /// Apply an incremental rotation during a drag gesture.
  void rotateBy(double delta) => _rotation += delta;

  /// Begin free-spin deceleration at [angularVelocity] (radians/second).
  /// Positive = clockwise; negative = counter-clockwise.
  /// Begin free-spin deceleration. When [selects] is false the wheel spins
  /// freely but does not fire [onLanded] — used for low-force throws.
  void startSpinWithVelocity(double angularVelocity, {bool selects = true}) {
    _isSpinning = true;
    _hasReported = false;
    _willSelect = selects;
    _landedIndex = null;
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
      if (_willSelect) onLanded(segments[_selectedSegmentIndex].conceptId);
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
      final isSelected = _landedIndex == i;
      final dimmed = _landedIndex != null && !isSelected;
      final segColor = dimmed
          ? segments[i].color.withValues(alpha: 0.2)
          : segments[i].color;
      canvas
        ..drawArc(rect, start, sweep, true, Paint()..color = segColor)
        ..drawArc(
          rect,
          start,
          sweep,
          true,
          Paint()
            ..color = isSelected
                ? Colors.amber.withValues(alpha: 0.9)
                : Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 5 : 2,
        );
    }

    // Text labels, plus a "NEW" sticker further out on unplayed segments.
    for (var i = 0; i < segments.length; i++) {
      final midAngle = _rotation + (i + 0.5) * sweep;
      final labelR = radius * 0.62;
      final dimmed = _landedIndex != null && _landedIndex != i;
      _drawLabel(
        canvas,
        segments[i].label,
        Offset(
          center.dx + math.cos(midAngle) * labelR,
          center.dy + math.sin(midAngle) * labelR,
        ),
        dimmed: dimmed,
      );
      if (segments[i].isNew || segments[i].isReview) {
        final stickerR = radius * 0.86;
        final at = Offset(
          center.dx + math.cos(midAngle) * stickerR,
          center.dy + math.sin(midAngle) * stickerR,
        );
        if (segments[i].isNew) {
          _drawSticker(
            canvas,
            at,
            text: 'NEW',
            fill: Colors.amber,
            ink: const Color(0xFF3E2723),
            dimmed: dimmed,
          );
        } else {
          _drawSticker(
            canvas,
            at,
            text: '✓',
            fill: const Color(0xFFB2DFDB),
            ink: const Color(0xFF004D40),
            dimmed: dimmed,
          );
        }
      }
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

  /// Small pill sticker reading [text], centred on [center].
  void _drawSticker(
    Canvas canvas,
    Offset center, {
    required String text,
    required Color fill,
    required Color ink,
    bool dimmed = false,
  }) {
    final alpha = dimmed ? 0.3 : 1.0;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: ink.withValues(alpha: alpha),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromCenter(
      center: center,
      width: tp.width + 10,
      height: tp.height + 4,
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = fill.withValues(alpha: alpha),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset center, {
    bool dimmed = false,
  }) {
    final color = dimmed ? Colors.white.withValues(alpha: 0.3) : Colors.white;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: dimmed
              ? null
              : const [Shadow(color: Color(0x99000000), blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}
