import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/land_blocks.dart';
import 'package:math_city/domain/city/terrain.dart';

void main() {
  group('tileHash', () {
    test('is deterministic and in [0, 1)', () {
      for (var c = -40; c < 40; c += 7) {
        for (var r = -40; r < 40; r += 5) {
          final h = tileHash(c, r);
          expect(h, inInclusiveRange(0, 1));
          expect(h, lessThan(1));
          expect(tileHash(c, r), h);
        }
      }
    });

    test('differs between neighbouring tiles', () {
      final seen = <double>{
        for (var c = 0; c < 10; c++)
          for (var r = 0; r < 10; r++) tileHash(c, r),
      };
      expect(seen.length, greaterThan(90));
    });
  });

  group('terrainBandOf', () {
    test('meadow near town, scrub on ring 3, forest beyond', () {
      expect(terrainBandOf(0), TerrainBand.meadow);
      expect(terrainBandOf(2), TerrainBand.meadow);
      expect(terrainBandOf(3), TerrainBand.scrub);
      expect(terrainBandOf(4), TerrainBand.forest);
      expect(terrainBandOf(9), TerrainBand.forest);
    });

    test("terrainBandAt reads the tile's block ring", () {
      expect(terrainBandAt(0, 0), TerrainBand.meadow);
      expect(terrainBandAt(12, 0), TerrainBand.scrub);
      expect(terrainBandAt(-12, 0), TerrainBand.scrub);
      expect(terrainBandAt(-13, 0), TerrainBand.forest);
      expect(terrainBandAt(0, 16), TerrainBand.forest);
    });
  });

  group('decorAt', () {
    test('the countryside is wooded, the town sparse', () {
      var townTrees = 0;
      var wildTrees = 0;
      var townItems = 0;
      const n = 60 * 60;
      for (var c = -30; c < 30; c++) {
        for (var r = -30; r < 30; r++) {
          final ring = blockRing(c ~/ kBlockSize, r ~/ kBlockSize);
          final town = decorAt(c, r, owned: true, ring: ring);
          final wild = decorAt(c, r, owned: false, ring: ring);
          if (town?.kind == DecorKind.tree) townTrees++;
          if (wild?.kind == DecorKind.tree) wildTrees++;
          if (town != null) townItems++;
        }
      }
      expect(townTrees / n, closeTo(kTownTreeDensity, 0.02));
      expect(wildTrees / n, closeTo(kWildTreeDensity, 0.03));
      // Bushes, flowers and rocks fill the town in: it is not bare.
      expect(townItems / n, greaterThan(0.15));
    });

    test('no flowers on the forest floor', () {
      for (var c = -40; c < 40; c++) {
        for (var r = -40; r < 40; r++) {
          final item = decorAt(c, r, owned: false, ring: 5);
          expect(item?.kind, isNot(DecorKind.flowers));
        }
      }
    });

    test('items stay on their tile', () {
      final item = decorAt(3, 4, owned: false, ring: 2);
      if (item != null) {
        expect(item.col, 3);
        expect(item.row, 4);
        expect(item.dx.abs(), lessThan(0.5));
        expect(item.dy.abs(), lessThan(0.5));
      }
    });
  });

  group('edgeSegments', () {
    test('a lone tile has all four sides', () {
      final segs = edgeSegments(owned: {(0, 0)});
      expect(segs.map((s) => s.side).toSet(), TileSide.values.toSet());
      expect(segs.length, 4);
    });

    test('inner edges are not segments', () {
      final segs = edgeSegments(owned: {(0, 0), (1, 0)});
      expect(segs.length, 6);
      expect(segs, isNot(contains((col: 0, row: 0, side: TileSide.east))));
      expect(segs, isNot(contains((col: 1, row: 0, side: TileSide.west))));
    });

    test('a road crossing the line opens the fence', () {
      final owned = {for (var c = 0; c < 4; c++) (c, 0)};
      final segs = edgeSegments(owned: owned, roads: {(3, 0), (4, 0), (5, 0)});
      expect(segs, isNot(contains((col: 3, row: 0, side: TileSide.east))));
      // A road that stops at the edge does not open it.
      final closed = edgeSegments(owned: owned, roads: {(3, 0)});
      expect(closed, contains((col: 3, row: 0, side: TileSide.east)));
    });

    test('is ordered by column, row, side', () {
      final segs = edgeSegments(owned: {(1, 1), (0, 0)});
      expect(segs.first.col, 0);
      expect(segs.last.col, 1);
    });
  });

  group('highwayTiles', () {
    test('main street spans the window; high street runs south', () {
      final tiles = highwayTiles(
        minCol: -6,
        maxCol: 17,
        minRow: -6,
        maxRow: 17,
      );
      for (var c = -6; c <= 17; c++) {
        expect(tiles, contains((c, kMainStreetRow)));
      }
      for (var r = kMainStreetRow; r <= 17; r++) {
        expect(tiles, contains((kHighStreetCol, r)));
      }
      expect(tiles, isNot(contains((kHighStreetCol, -1))));
      expect(tiles.length, 24 + 17);
    });

    test('isHighwayTile agrees with the tile set', () {
      final tiles = highwayTiles(minCol: -9, maxCol: 9, minRow: -9, maxRow: 9);
      for (var c = -9; c <= 9; c++) {
        for (var r = -9; r <= 9; r++) {
          expect(isHighwayTile(c, r), tiles.contains((c, r)), reason: '$c,$r');
        }
      }
    });

    test('is clipped to the window', () {
      final tiles = highwayTiles(minCol: 5, maxCol: 8, minRow: 1, maxRow: 3);
      expect(tiles, isEmpty);
    });
  });
}
