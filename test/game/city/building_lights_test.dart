import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/game/city/building_lights.dart';

void main() {
  group('parseBuildingLights', () {
    const source = '''
{"home": {"s": [384, 320], "r": [
  {"k": "w", "p": [10, 10, 20, 15, 20, 30, 10, 25]},
  {"k": "g", "p": [40, 40, 60, 40, 60, 50, 40, 50]},
  {"k": "l", "p": [102, 50, 101, 51.7, 99, 51.7, 98, 50, 99, 48.3, 101, 48.3]},
  {"k": "w", "p": [1, 2, 3, 4]}
]}}''';

    test('reads the size and the three kinds, dropping a degenerate shape', () {
      final home = parseBuildingLights(source)['home']!;
      expect(home.size, const Size(384, 320));
      expect(home.regions.map((r) => r.kind), [
        LightKind.window,
        LightKind.glow,
        LightKind.lamp,
      ]);
    });

    test('a window keeps room hours; a glow and a lamp are on all night', () {
      final regions = parseBuildingLights(source)['home']!.regions;
      expect(regions.map((r) => r.glow), [false, true, true]);
    });

    test('a lamp shines from the middle of its little hexagon', () {
      final lamp = parseBuildingLights(source)['home']!.regions[2];
      expect(lamp.centre.dx, closeTo(100, 0.01));
      expect(lamp.centre.dy, closeTo(50, 0.01));
      // Half the mean of its width (4) and height (3.4).
      expect(lamp.radius, closeTo(1.85, 0.01));
    });
  });
}
