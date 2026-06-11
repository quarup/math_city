import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:math_city/domain/city/road_sprites.dart';
import 'package:math_city/game/city/iso_grid.dart';

/// Sprites are authored at this many pixels per tile (see
/// `tools/sprite_pipeline/process.py` `TILE_W`). The renderer scales them down
/// to `grid.tileWidth`, so they stay sharp up to the camera's max zoom.
const double kSpriteAuthoringTilePx = 192;

/// Lightweight render model for one placed building. Built by the
/// presentation layer from a `BuildingPlacement` + the building registry, so
/// this component stays ignorant of domain types.
class PlacedBuildingView {
  const PlacedBuildingView({
    required this.col,
    required this.row,
    required this.emoji,
    required this.color,
    this.footprint = const (1, 1),
    this.assetPath,
  });

  final int col;
  final int row;
  final String emoji;
  final Color color;

  /// `(widthTiles, heightTiles)`. Drives the sprite's on-screen size + the
  /// south-corner anchor; the box-placeholder fallback ignores it (all
  /// non-sprite Phase-7 buildings are 1×1).
  final (int, int) footprint;

  /// `assets/buildings/<id>_v<n>.png` filename to render, or null to fall back
  /// to the colored-box + emoji placeholder. Resolved to a loaded [Sprite] by
  /// the host game's cache; null until that load completes.
  final String? assetPath;
}

/// Renders the isometric terrain grid plus placeholder extruded-box buildings,
/// and reports tile taps back to the presentation layer. Phase 7 placeholder
/// art per plan.md — colored diamonds + emoji, no PNGs.
class CityBoardComponent extends PositionComponent with TapCallbacks {
  CityBoardComponent({
    required this.grid,
    required this.onTileTapped,
    required this.spriteFor,
  });

  final IsoGrid grid;
  final void Function(int col, int row) onTileTapped;

  /// Resolves a `<id>_v<n>.png` filename to a loaded sprite, or null if it
  /// isn't loaded yet (the host game loads them asynchronously and caches).
  final Sprite? Function(String assetPath) spriteFor;

  /// Current placement render set. Reassigned (cheaply) by the host game
  /// whenever placements change.
  List<PlacedBuildingView> buildings = const [];

  /// Tiles painted as road (auto-generated; see `road_network.dart`). Drawn in
  /// the terrain pass, so buildings always sit on top. Reassigned by the host
  /// game whenever placements change.
  Set<(int, int)> roads = const {};

  /// Tile of the building currently "picked up" in move mode, outlined so the
  /// player can see what they're relocating. Null when nothing is picked up.
  (int, int)? highlightTile;

  static const _grassFill = Color(0xFF7CB342);
  static const _grassFillAlt = Color(0xFF689F38);
  static const _roadFill = Color(0xFF9E9E9E);
  final _tileStroke = Paint()
    ..color = const Color(0x33000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final _highlightStroke = Paint()
    ..color = const Color(0xFFFFEB3B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  late final TextPaint _emojiPaint = TextPaint(
    style: TextStyle(fontSize: grid.tileWidth * 0.42),
  );

  @override
  Future<void> onLoad() async {
    size = Vector2(grid.boardWidth, grid.boardHeight);
  }

  @override
  void render(Canvas canvas) {
    for (var row = 0; row < grid.rows; row++) {
      for (var col = 0; col < grid.cols; col++) {
        _drawTile(canvas, col, row);
      }
    }
    // Roads draw after all terrain: the sprites carry a small overscan rim
    // (seam cover), which a later-drawn neighbouring grass diamond would
    // otherwise clip.
    for (final (col, row) in roads) {
      _drawRoadTile(canvas, col, row);
    }
    // Painter's order: tiles further back (smaller col+row) draw first so
    // nearer buildings overlap them correctly.
    final sorted = [...buildings]
      ..sort((a, b) => (a.col + a.row).compareTo(b.col + b.row));
    for (final b in sorted) {
      _drawBuilding(canvas, b);
    }
    // Move-mode highlight: ring the top face of the picked-up building.
    final hl = highlightTile;
    if (hl != null) {
      final (cx, cy) = grid.centerOf(hl.$1, hl.$2);
      canvas.drawPath(_diamond(cx, cy, grid.tileWidth * 0.5), _highlightStroke);
    }
  }

  void _drawTile(Canvas canvas, int col, int row) {
    final (cx, cy) = grid.centerOf(col, row);
    final path = _diamond(cx, cy, 0);
    final fill = (col + row).isEven ? _grassFill : _grassFillAlt;
    canvas
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(path, _tileStroke);
  }

  /// Draws one auto-road tile: resolves the connection mask to a canonical
  /// sprite + screen flips (see `road_sprites.dart`), falling back to the
  /// flat grey diamond until the sprite's async load lands.
  void _drawRoadTile(Canvas canvas, int col, int row) {
    final (cx, cy) = grid.centerOf(col, row);
    final spec = roadSpriteFor(
      east: roads.contains((col + 1, row)),
      south: roads.contains((col, row + 1)),
      west: roads.contains((col - 1, row)),
      north: roads.contains((col, row - 1)),
    );
    final sprite = spriteFor(spec.shape.fileName);
    if (sprite == null) {
      canvas.drawPath(_diamond(cx, cy, 0), Paint()..color = _roadFill);
      return;
    }
    final size = sprite.srcSize * (grid.tileWidth / kSpriteAuthoringTilePx);
    if (spec.flipH || spec.flipV) {
      canvas
        ..save()
        ..translate(cx, cy)
        ..scale(spec.flipH ? -1 : 1, spec.flipV ? -1 : 1);
      sprite.render(
        canvas,
        position: Vector2.zero(),
        size: size,
        anchor: Anchor.center,
      );
      canvas.restore();
    } else {
      sprite.render(
        canvas,
        position: Vector2(cx, cy),
        size: size,
        anchor: Anchor.center,
      );
    }
  }

  void _drawBuilding(Canvas canvas, PlacedBuildingView b) {
    final path = b.assetPath;
    if (path != null) {
      final sprite = spriteFor(path);
      if (sprite != null) {
        _drawSprite(canvas, b, sprite);
        return;
      }
      // Sprite not loaded yet — fall through to the box so the building still
      // shows this frame; it swaps to the sprite once the async load lands.
    }
    _drawBox(canvas, b);
  }

  /// Draws the building sprite anchored at the south corner of its footprint,
  /// scaled from authoring resolution down to the live tile size.
  void _drawSprite(Canvas canvas, PlacedBuildingView b, Sprite sprite) {
    final (w, hTiles) = b.footprint;
    // The footprint's lowest on-screen point is the south corner of its
    // furthest (max col+row) tile.
    final (mcx, mcy) = grid.centerOf(b.col + w - 1, b.row + hTiles - 1);
    final south = Vector2(mcx, mcy + _halfH);
    final scale = grid.tileWidth / kSpriteAuthoringTilePx;
    sprite.render(
      canvas,
      position: south,
      size: sprite.srcSize * scale,
      anchor: Anchor.bottomCenter,
    );
  }

  void _drawBox(Canvas canvas, PlacedBuildingView b) {
    final (cx, cy) = grid.centerOf(b.col, b.row);
    final h = grid.tileWidth * 0.5;

    final left = Path()
      ..moveTo(cx - _halfW, cy - h)
      ..lineTo(cx, cy + _halfH - h)
      ..lineTo(cx, cy + _halfH)
      ..lineTo(cx - _halfW, cy)
      ..close();
    final right = Path()
      ..moveTo(cx + _halfW, cy - h)
      ..lineTo(cx, cy + _halfH - h)
      ..lineTo(cx, cy + _halfH)
      ..lineTo(cx + _halfW, cy)
      ..close();

    canvas
      ..drawPath(left, Paint()..color = _shade(b.color, 0.7))
      ..drawPath(right, Paint()..color = _shade(b.color, 0.55))
      ..drawPath(_diamond(cx, cy, h), Paint()..color = b.color);

    _emojiPaint.render(
      canvas,
      b.emoji,
      Vector2(cx, cy - h),
      anchor: Anchor.center,
    );
  }

  double get _halfW => grid.tileWidth / 2;
  double get _halfH => grid.tileWidth / 4;

  /// Diamond for a tile center `(cx, cy)`, raised by [lift] (0 = on the
  /// ground, used for the terrain tile and a building's top face).
  Path _diamond(double cx, double cy, double lift) => Path()
    ..moveTo(cx, cy - _halfH - lift)
    ..lineTo(cx + _halfW, cy - lift)
    ..lineTo(cx, cy + _halfH - lift)
    ..lineTo(cx - _halfW, cy - lift)
    ..close();

  Color _shade(Color c, double f) =>
      Color.from(alpha: c.a, red: c.r * f, green: c.g * f, blue: c.b * f);

  @override
  void onTapUp(TapUpEvent event) {
    final tile = grid.tileAt(event.localPosition.x, event.localPosition.y);
    if (tile != null) onTileTapped(tile.$1, tile.$2);
  }
}
