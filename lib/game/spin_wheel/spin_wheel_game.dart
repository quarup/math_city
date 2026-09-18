import 'dart:async';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:math_city/game/spin_wheel/burst_component.dart';
import 'package:math_city/game/spin_wheel/city_backdrop.dart';
import 'package:math_city/game/spin_wheel/reveal_pill.dart';
import 'package:math_city/game/spin_wheel/spin_wheel_component.dart';

/// FlameGame that hosts the carnival wheel over the city backdrop.
///
/// Layout: the city strip sits along the bottom edge; the wheel is centred
/// on the sky band above it, sized to fit the width with room for the rim,
/// the pointer above and the name reveal below.
///
/// Drag gesture physics:
///   - While dragging, the wheel rotates with the finger.
///   - On release, velocity is converted to angular velocity (rad/s).
///   - Strong throws (≥ [_minSelectVelocity]): wheel spins, the backdrop
///     blurs and streaks, concept is selected on landing.
///   - Weak throws (< [_minSelectVelocity]): wheel still spins (boosted to
///     [_minBoostVelocity]) but no concept is selected — prevents "cheating"
///     by nudging the wheel to a desired segment.
///   - Throws above [_maxAngularVelocity] are clamped.
class SpinWheelGame extends FlameGame with DragCallbacks {
  SpinWheelGame({
    required this.onConceptSelected,
    required List<WheelSegment> segments,
    required this.skyTop,
    required this.skyBottom,
  }) : _segments = segments;

  final void Function(String conceptId) onConceptSelected;
  final List<WheelSegment> _segments;
  final Color skyTop;
  final Color skyBottom;

  late SpinWheelComponent _wheel;
  late CityBackdrop _backdrop;

  /// Position of the last drag event, in canvas coordinates.
  Vector2 _lastDragPos = Vector2.zero();

  /// Minimum throw speed (rad/s) required to select a concept.
  static const double _minSelectVelocity = 10;

  /// Floor velocity applied to weak throws so the wheel always spins.
  static const double _minBoostVelocity = 3;
  static const double _maxAngularVelocity = 30;

  @override
  Color backgroundColor() => skyTop;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _backdrop = CityBackdrop(skyTop: skyTop, skyBottom: skyBottom)
      ..size = size
      ..position = Vector2.zero();

    // Wheel centred on the sky band. Radius: 41% of the width (the mock
    // proportion), shrunk if needed so the pointer clears the top and the
    // reveal pill clears the strip.
    final cy = _backdrop.stripTop / 2;
    final radius = [
      size.x * 0.41,
      (cy - 30) / 1.55,
    ].reduce((a, b) => a < b ? a : b);
    final center = Vector2(size.x / 2, cy);
    _backdrop
      ..wheelCenter = center
      ..wheelRadius = radius;
    await add(_backdrop);

    _wheel = SpinWheelComponent(
      segments: _segments,
      onLanded: _onWheelLanded,
      wheelCenter: center,
      radius: radius,
    );
    await add(_wheel);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _backdrop.intensity = _wheel.willSelect || _wheel.isSpinning
        ? _wheel.speedFraction
        : 0;
  }

  Future<void> _onWheelLanded(String conceptId) async {
    _backdrop.intensity = 0;
    final index = _wheel.currentSelectedIndex;
    _wheel.landedIndex = index;
    final seg = _wheel.segments[index];
    final s = _wheel.radius / 148;
    await add(BurstComponent(burstPosition: _wheel.labelPositionFor(index)));
    await add(
      RevealPill(
        text: seg.label,
        dotColor: seg.color,
        at: Vector2(
          _wheel.wheelCenter.x,
          _wheel.wheelCenter.y + _wheel.radius + 52 * s,
        ),
        scaleFactor: s,
      ),
    );
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 1500),
        () => onConceptSelected(conceptId),
      ),
    );
  }

  /// True when the current spin is locked (selecting) and can't be interrupted.
  bool get _spinLocked => _wheel.isSpinning && _wheel.willSelect;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_spinLocked) return;
    if (_wheel.isSpinning) _wheel.cancelSpin();
    _lastDragPos = event.canvasPosition;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_spinLocked) return;

    // Convert linear drag delta to angular delta using cross-product formula:
    //   dθ = (r × delta) / |r|²
    // where r is the vector from wheel centre to the touch point.
    final center = _wheel.wheelCenter;
    final r = event.canvasStartPosition - center;
    final rLen2 = r.x * r.x + r.y * r.y;

    // Ignore drags that start within 10 px of centre (degenerate geometry).
    if (rLen2 > 100) {
      final d = event.canvasDelta;
      final dTheta = (r.x * d.y - r.y * d.x) / rLen2;
      _wheel.rotateBy(dTheta);
    }

    _lastDragPos = event.canvasEndPosition;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_spinLocked) return;

    final center = _wheel.wheelCenter;
    final r = _lastDragPos - center;
    final rLen2 = r.x * r.x + r.y * r.y;

    // Degenerate case: tap exactly at centre — idle spin, no selection.
    if (rLen2 == 0) {
      _wheel.startSpinWithVelocity(_minBoostVelocity, selects: false);
      return;
    }

    // Angular velocity from throw: ω = (r × v) / |r|²
    final v = event.velocity; // px/s
    final rawOmega = (r.x * v.y - r.y * v.x) / rLen2;
    final absOmega = rawOmega.abs();

    if (absOmega >= _minSelectVelocity) {
      // Strong throw: spin, blur the city, and select a concept on landing.
      _wheel.startSpinWithVelocity(
        rawOmega.clamp(-_maxAngularVelocity, _maxAngularVelocity),
      );
    } else {
      // Weak throw: spin for feel (with boost) but do not select.
      final sign = rawOmega >= 0 ? 1.0 : -1.0;
      final boosted = absOmega < _minBoostVelocity
          ? _minBoostVelocity * sign
          : rawOmega;
      _wheel.startSpinWithVelocity(boosted, selects: false);
    }
  }

  // onDragCancel: default super implementation is sufficient.
  // Wheel stays wherever the drag left it; no spin is triggered.
}
