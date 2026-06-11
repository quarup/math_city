/// Road autotiling resolver — maps a road tile's orthogonal-neighbour
/// connection mask to one of the canonical road sprites plus the screen-space
/// flips that orient it (city_builder.md §5.5).
///
/// The 2:1 dimetric diamond survives horizontal/vertical mirroring but not
/// 90° rotation, so the 16 connection masks collapse onto 6 sprites under the
/// flip group {identity, H, V, HV}. Grid directions map to screen directions
/// as: east (col+1) exits the lower-right diamond edge, south (row+1) the
/// lower-left, west the upper-left, north the upper-right. A horizontal flip
/// therefore swaps east↔south and west↔north; a vertical flip swaps
/// east↔north and south↔west.
library;

/// The six authored road sprites (canonical orientations — see
/// `tools/sprite_pipeline/compose_roads.py`).
enum RoadSpriteShape {
  /// 4-way junction (also used for an isolated road tile).
  cross('road_cross.png'),

  /// 3-way junction; canonical = connected east + south + west.
  tee('road_tee.png'),

  /// 2 opposite connections; canonical = east + west.
  straight('road_straight.png'),

  /// 2 adjacent connections opening up/down; canonical = east + south.
  curveUd('road_curve_ud.png'),

  /// 2 adjacent connections opening left/right; canonical = east + north.
  curveLr('road_curve_lr.png'),

  /// 1 connection; canonical = east.
  deadend('road_deadend.png');

  const RoadSpriteShape(this.fileName);

  /// Asset filename under `assets/buildings/`.
  final String fileName;
}

/// A resolved sprite + transform for one road tile: mirror across the
/// screen-vertical axis ([RoadTileSprite].flipH) and/or the screen-horizontal
/// axis (.flipV) when drawing.
typedef RoadTileSprite = ({RoadSpriteShape shape, bool flipH, bool flipV});

RoadTileSprite _spec(
  RoadSpriteShape shape, {
  bool flipH = false,
  bool flipV = false,
}) => (shape: shape, flipH: flipH, flipV: flipV);

/// Resolves the sprite + flips for a road tile whose orthogonal neighbours'
/// road-ness is given by [east] (col+1), [south] (row+1), [west] (col-1) and
/// [north] (row-1).
RoadTileSprite roadSpriteFor({
  required bool east,
  required bool south,
  required bool west,
  required bool north,
}) {
  final count =
      (east ? 1 : 0) + (south ? 1 : 0) + (west ? 1 : 0) + (north ? 1 : 0);
  switch (count) {
    case 4:
    case 0:
      // Isolated tiles reuse the cross per §5.5 (the generator never emits
      // them, but the renderer shouldn't have a hole if one ever appears).
      return _spec(RoadSpriteShape.cross);
    case 3:
      // Identified by the missing direction; canonical tee misses north.
      if (!north) return _spec(RoadSpriteShape.tee);
      if (!west) return _spec(RoadSpriteShape.tee, flipH: true);
      if (!east) return _spec(RoadSpriteShape.tee, flipV: true);
      return _spec(RoadSpriteShape.tee, flipH: true, flipV: true);
    case 2:
      if (east && west) return _spec(RoadSpriteShape.straight);
      if (north && south) return _spec(RoadSpriteShape.straight, flipH: true);
      if (east && south) return _spec(RoadSpriteShape.curveUd);
      if (west && north) return _spec(RoadSpriteShape.curveUd, flipV: true);
      if (east && north) return _spec(RoadSpriteShape.curveLr);
      return _spec(RoadSpriteShape.curveLr, flipH: true); // south && west
    default: // 1
      if (east) return _spec(RoadSpriteShape.deadend);
      if (south) return _spec(RoadSpriteShape.deadend, flipH: true);
      if (north) return _spec(RoadSpriteShape.deadend, flipV: true);
      return _spec(RoadSpriteShape.deadend, flipH: true, flipV: true);
  }
}
