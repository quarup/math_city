import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/road_sprites.dart';

/// The canonical connection set each sprite was authored with
/// (compose_roads.py header).
const Map<RoadSpriteShape, Set<String>> canonicalConnections = {
  RoadSpriteShape.cross: {'e', 's', 'w', 'n'},
  RoadSpriteShape.tee: {'e', 's', 'w'},
  RoadSpriteShape.straight: {'e', 'w'},
  RoadSpriteShape.curveUd: {'e', 's'},
  RoadSpriteShape.curveLr: {'e', 'n'},
  RoadSpriteShape.deadend: {'e'},
};

/// Screen-space horizontal mirror in grid terms: east↔south, west↔north.
String flipH(String d) => const {'e': 's', 's': 'e', 'w': 'n', 'n': 'w'}[d]!;

/// Screen-space vertical mirror in grid terms: east↔north, south↔west.
String flipV(String d) => const {'e': 'n', 'n': 'e', 's': 'w', 'w': 's'}[d]!;

void main() {
  group('roadSpriteFor', () {
    test(
      'every mask resolves to a sprite whose flipped canonical connections '
      'reproduce the mask',
      () {
        for (var bits = 0; bits < 16; bits++) {
          final east = bits & 1 != 0;
          final south = bits & 2 != 0;
          final west = bits & 4 != 0;
          final north = bits & 8 != 0;
          final mask = <String>{
            if (east) 'e',
            if (south) 's',
            if (west) 'w',
            if (north) 'n',
          };

          final result = roadSpriteFor(
            east: east,
            south: south,
            west: west,
            north: north,
          );

          var connections = canonicalConnections[result.shape]!;
          if (result.flipH) connections = connections.map(flipH).toSet();
          if (result.flipV) connections = connections.map(flipV).toSet();

          // Empty mask is the §5.5 isolated tile, drawn as a cross.
          final expected = mask.isEmpty ? {'e', 's', 'w', 'n'} : mask;
          expect(
            connections,
            expected,
            reason: 'mask $mask resolved to $result',
          );
        }
      },
    );

    test('spot checks', () {
      expect(
        roadSpriteFor(east: true, south: false, west: true, north: false),
        (shape: RoadSpriteShape.straight, flipH: false, flipV: false),
      );
      expect(
        roadSpriteFor(east: false, south: true, west: false, north: true),
        (shape: RoadSpriteShape.straight, flipH: true, flipV: false),
      );
      expect(
        roadSpriteFor(east: true, south: true, west: true, north: true),
        (shape: RoadSpriteShape.cross, flipH: false, flipV: false),
      );
      expect(
        roadSpriteFor(east: true, south: true, west: true, north: false),
        (shape: RoadSpriteShape.tee, flipH: false, flipV: false),
      );
      expect(
        roadSpriteFor(east: true, south: true, west: false, north: false),
        (shape: RoadSpriteShape.curveUd, flipH: false, flipV: false),
      );
      expect(
        roadSpriteFor(east: false, south: false, west: false, north: true),
        (shape: RoadSpriteShape.deadend, flipH: false, flipV: true),
      );
    });

    test('each of the 6 sprite files is reachable', () {
      final seen = <String>{};
      for (var bits = 0; bits < 16; bits++) {
        seen.add(
          roadSpriteFor(
            east: bits & 1 != 0,
            south: bits & 2 != 0,
            west: bits & 4 != 0,
            north: bits & 8 != 0,
          ).shape.fileName,
        );
      }
      expect(seen, hasLength(RoadSpriteShape.values.length));
    });
  });
}
