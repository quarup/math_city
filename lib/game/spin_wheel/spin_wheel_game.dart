import 'dart:async';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:math_city/game/spin_wheel/burst_component.dart';
import 'package:math_city/game/spin_wheel/spin_wheel_component.dart';
import 'package:math_city/game/spin_wheel/warp_background.dart';

/// Minimal FlameGame that hosts the [SpinWheelComponent].
///
/// Drag gesture physics:
///   - While dragging, the wheel rotates with the finger.
///   - On release, velocity is converted to angular velocity (rad/s).
///   - Strong throws (≥ [_minSelectVelocity]): wheel spins, warp activates,
///     concept is selected on landing.
///   - Weak throws (< [_minSelectVelocity]): wheel still spins (boosted to
///     [_minBoostVelocity]) but no concept is selected — prevents "cheating"
///     by nudging the wheel to a desired segment.
///   - Throws above [_maxAngularVelocity] are clamped.
class SpinWheelGame extends FlameGame with DragCallbacks {
  SpinWheelGame({
    required this.onConceptSelected,
    required List<WheelSegment> segments,
  }) : _segments = segments;

  final void Function(String conceptId) onConceptSelected;
  final List<WheelSegment> _segments;
  late SpinWheelComponent _wheel;
  late WarpBackground _warp;

  /// Position of the last drag event, in canvas coordinates.
  Vector2 _lastDragPos = Vector2.zero();

  /// Minimum throw speed (rad/s) required to select a concept.
  static const double _minSelectVelocity = 10;

  /// Floor velocity applied to weak throws so the wheel always spins.
  static const double _minBoostVelocity = 3;
  static const double _maxAngularVelocity = 30;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _warp = WarpBackground()
      ..size = size
      ..position = Vector2.zero();
    add(_warp);
    _wheel =
        SpinWheelComponent(
            segments: _segments,
            onLanded: _onWheelLanded,
          )
          ..size = size
          ..position = Vector2.zero()
          ..priority = 1;
    add(_wheel);
  }

  Future<void> _onWheelLanded(String conceptId) async {
    _warp.deactivate();
    final index = _wheel.currentSelectedIndex;
    _wheel.landedIndex = index;
    final burst = BurstComponent(
      burstPosition: _wheel.labelPositionFor(index),
    );
    await add(burst);
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
    if (_spinLocked) return;

    final center = size / 2;
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
      // Strong throw: spin, activate warp, and select a concept on landing.
      _wheel.startSpinWithVelocity(
        rawOmega.clamp(-_maxAngularVelocity, _maxAngularVelocity),
      );
      _warp.activate();
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
