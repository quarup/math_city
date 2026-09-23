import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/pedestrian_walk.dart';
import 'package:math_city/game/city/citizen_painter.dart';

void main() {
  const look = CitizenLook(
    shirt: 0xFFE0523F,
    pants: 0xFF3A3F5C,
    skin: 0xFFF1C9A5,
    hair: 0xFF2B1D12,
  );

  test('paints every heading, walking and idle, into a picture', () {
    for (var dir = 0; dir < 4; dir++) {
      for (final idle in [false, true]) {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        paintCitizen(
          canvas,
          feet: const Offset(32, 32),
          dir: dir,
          phase: 1.3,
          look: look,
          idle: idle,
          scale: 2,
        );
        final picture = recorder.endRecording();
        expect(picture.approximateBytesUsed, greaterThan(0));
        picture.dispose();
      }
    }
  });

  test('a kid look scales down without breaking the torso', () {
    const kid = CitizenLook(
      shirt: 0xFF3A7BD5,
      pants: 0xFF4A4A4A,
      skin: 0xFFD9A276,
      hair: 0xFF6B3E1E,
      scale: 0.62,
      headScale: 1.35,
    );
    final recorder = PictureRecorder();
    paintCitizen(
      Canvas(recorder),
      feet: Offset.zero,
      dir: 1,
      phase: 0,
      look: kid,
    );
    expect(recorder.endRecording().approximateBytesUsed, greaterThan(0));
  });
}
