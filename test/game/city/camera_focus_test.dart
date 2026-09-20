import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/game/city/camera_focus.dart';

void main() {
  group('zoomToFit', () {
    test('makes the content span the requested fraction', () {
      // 200 world units should fill 40% of a 1000 px viewport → zoom 2.
      expect(
        zoomToFit(
          contentWidth: 200,
          viewportWidth: 1000,
          fraction: 0.4,
          minZoom: 0.4,
          maxZoom: 3,
        ),
        2,
      );
    });

    test('clamps to the camera limits', () {
      expect(
        zoomToFit(
          contentWidth: 10,
          viewportWidth: 1000,
          fraction: 0.5,
          minZoom: 0.4,
          maxZoom: 3,
        ),
        3,
      );
      expect(
        zoomToFit(
          contentWidth: 10000,
          viewportWidth: 1000,
          fraction: 0.5,
          minZoom: 0.4,
          maxZoom: 3,
        ),
        0.4,
      );
    });
  });

  group('cameraCenterFor', () {
    test('dead-centre anchor centres on the target', () {
      expect(
        cameraCenterFor(
          targetX: 300,
          targetY: 400,
          zoom: 2,
          viewportWidth: 1000,
          viewportHeight: 2000,
          anchorX: 0.5,
          anchorY: 0.5,
        ),
        (300, 400),
      );
    });

    test('a low anchor puts the camera above the target', () {
      // Target at 80% down a 2000 px viewport at zoom 2: the camera centre
      // sits (0.8 − 0.5) × 2000 / 2 = 300 world units above the target.
      final (cx, cy) = cameraCenterFor(
        targetX: 300,
        targetY: 400,
        zoom: 2,
        viewportWidth: 1000,
        viewportHeight: 2000,
        anchorX: 0.5,
        anchorY: 0.8,
      );
      expect(cx, 300);
      expect(cy, closeTo(100, 1e-9));
    });
  });

  test('easeInOut is monotonic and hits both ends', () {
    expect(easeInOut(0), 0);
    expect(easeInOut(1), 1);
    expect(easeInOut(0.5), 0.5);
    var prev = 0.0;
    for (var i = 1; i <= 20; i++) {
      final v = easeInOut(i / 20);
      expect(v, greaterThanOrEqualTo(prev));
      prev = v;
    }
  });
}
