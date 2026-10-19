import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/game/spin_wheel/spin_wheel_component.dart';
import 'package:math_city/game/spin_wheel/spin_wheel_game.dart';

void main() {
  Future<SpinWheelGame> game({VoidCallback? onTapOutside}) async {
    final g = SpinWheelGame(
      onConceptSelected: (_) {},
      segments: [
        for (var i = 0; i < 8; i++)
          WheelSegment(
            conceptId: 'c$i',
            label: 'Concept $i',
            categoryId: 'arithmetic',
            tier: 0,
            color: Colors.orange,
          ),
      ],
      skyTop: Colors.blue,
      skyBottom: Colors.lightBlue,
      showBackdrop: false,
      onTapOutside: onTapOutside,
    );
    // The right-hand column of a Pixel 7 on its side.
    await (g..onGameResize(Vector2(476, 412))).onLoad();
    return g;
  }

  TapUpEvent tapAt(SpinWheelGame g, Offset p) => TapUpEvent(
    1,
    g,
    TapUpDetails(
      kind: PointerDeviceKind.touch,
      globalPosition: p,
      localPosition: p,
    ),
  );

  test('the disc and the pointer above it count as the wheel', () async {
    final g = await game();
    // The wheel is centred at (238, 190) with a radius of about 142.
    expect(g.isOnWheel(Vector2(238, 190)), isTrue);
    expect(g.isOnWheel(Vector2(238, 60)), isTrue);
    expect(g.isOnWheel(Vector2(20, 20)), isFalse);
    expect(g.isOnWheel(Vector2(460, 400)), isFalse);
  });

  test('a tap beside the wheel leaves; a tap on it does not', () async {
    var left = 0;
    final g = await game(onTapOutside: () => left++);
    g.onTapUp(tapAt(g, const Offset(238, 190)));
    expect(left, 0);
    g.onTapUp(tapAt(g, const Offset(20, 20)));
    expect(left, 1);
  });
}
