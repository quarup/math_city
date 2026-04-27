import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:math_dash/domain/concepts/concept_registry.dart';
import 'package:math_dash/game/spin_wheel/spin_wheel_component.dart';

/// Minimal FlameGame that hosts the [SpinWheelComponent].
///
/// Taps anywhere on the canvas start the spin. When the wheel stops,
/// [onConceptSelected] is invoked with the winning concept ID.
class SpinWheelGame extends FlameGame with TapCallbacks {
  SpinWheelGame({required this.onConceptSelected});

  final void Function(String conceptId) onConceptSelected;
  late SpinWheelComponent _wheel;

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
        SpinWheelComponent(
            segments: _segments,
            onLanded: onConceptSelected,
          )
          ..size = size
          ..position = Vector2.zero();
    add(_wheel);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    _wheel.startSpin();
    return true;
  }
}
