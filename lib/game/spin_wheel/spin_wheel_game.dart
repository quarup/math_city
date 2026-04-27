import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:math_dash/domain/concepts/concept_registry.dart';
import 'package:math_dash/game/spin_wheel/spin_wheel_component.dart';

/// Minimal FlameGame that hosts the [SpinWheelComponent].
///
/// Drag gesture physics:
///   - While dragging, the wheel rotates with the finger (using the
///     cross-product formula to convert linear delta → angular delta).
///   - On release, [DragEndEvent.velocity] (px/s) is converted to an
///     angular velocity (rad/s). Throws below [_minAngularVelocity] are
///     ignored — the wheel just stops where it is.
///   - Throws above [_maxAngularVelocity] are clamped.
class SpinWheelGame extends FlameGame with DragCallbacks {
  SpinWheelGame({required this.onConceptSelected});

  final void Function(String conceptId) onConceptSelected;
  late SpinWheelComponent _wheel;

  /// Position of the last drag event, in canvas coordinates.
  Vector2 _lastDragPos = Vector2.zero();

  /// Minimum throw speed (rad/s). Below this the spin is not counted.
  /// ∫₀^∞ ω·exp(−1.5t) dt = ω/1.5 → min 10 rad/s ≈ 1 full rotation.
  static const _minAngularVelocity = 10.0;
  static const _maxAngularVelocity = 30.0;

  // 4 segments: each concept appears twice so the wheel looks full.
  static final _segments = [
    WheelSegment(
      conceptId: add1Digit.id,
      label: add1Digit.shortLabel,
      color: Colors.orange.shade600,
    ),
    WheelSegment(
      conceptId: sub1Digit.id,
      label: sub1Digit.shortLabel,
      color: Colors.blue.shade600,
    ),
    WheelSegment(
      conceptId: add1Digit.id,
      label: add1Digit.shortLabel,
      color: Colors.orange.shade400,
    ),
    WheelSegment(
      conceptId: sub1Digit.id,
      label: sub1Digit.shortLabel,
      color: Colors.blue.shade400,
    ),
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _wheel =
        SpinWheelComponent(segments: _segments, onLanded: onConceptSelected)
          ..size = size
          ..position = Vector2.zero();
    add(_wheel);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_wheel.isSpinning) return;
    _lastDragPos = event.canvasPosition;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_wheel.isSpinning) return;

    // Convert linear drag delta to angular delta using cross-product formula:
    //   dθ = (r × delta) / |r|²
    // where r is the vector from wheel centre to the touch point.
    final center = size / 2;
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
    if (_wheel.isSpinning) return;

    final center = size / 2;
    final r = _lastDragPos - center;
    final rLen2 = r.x * r.x + r.y * r.y;
    if (rLen2 == 0) return;

    // Angular velocity from throw: ω = (r × v) / |r|²
    final v = event.velocity; // px/s
    final omega = (r.x * v.y - r.y * v.x) / rLen2;

    if (omega.abs() >= _minAngularVelocity) {
      _wheel.startSpinWithVelocity(
        omega.clamp(-_maxAngularVelocity, _maxAngularVelocity),
      );
    }
    // Below minimum: wheel stays wherever the drag left it; user retries.
  }

  // onDragCancel: default super implementation is sufficient.
  // Wheel stays wherever the drag left it; no spin is triggered.
}
