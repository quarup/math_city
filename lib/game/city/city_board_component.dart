import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';
import 'package:math_city/domain/city/land_blocks.dart';
import 'package:math_city/domain/city/mover_depth.dart';
import 'package:math_city/domain/city/pedestrian_walk.dart';
import 'package:math_city/domain/city/road_sprites.dart';
import 'package:math_city/domain/city/street_life.dart';
import 'package:math_city/domain/city/terrain.dart';
import 'package:math_city/domain/city/traffic.dart';
import 'package:math_city/game/city/decor_painter.dart';
import 'package:math_city/game/city/iso_grid.dart';
import 'package:math_city/game/city/pedestrian_system.dart';
import 'package:math_city/game/city/traffic_system.dart';

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
    this.selected = false,
    this.stage,
    this.party = false,
  });

  /// An event site on this footprint (city_builder.md §10.7): drawn as
  /// bunting around the venue instead of a building.

  final int col;
  final int row;
  final String emoji;
  final Color color;

  /// Construction stage for a site under construction (0, 1 or 2 — see
  /// `stageForFraction`), or null for a finished building. Interim generic
  /// overlays (city_builder.md §8.8): dirt pad + fence, then a slab, then
  /// the final sprite as a ghost.
  final int? stage;

  final bool party;

  /// True for the building the player currently has picked up for placement /
  /// moving: it renders with a yellow tint and a yellow footprint outline so
  /// it's obvious which one a tap will reposition.
  final bool selected;

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
    required this.vehicleSpriteFor,
  });

  /// The board's tile↔screen geometry for the current window. Reassigned by the
  /// host game when land is bought and the window grows (see
  /// `IsoCityGame.updateLand`); the render loop reads it live each frame.
  IsoGrid grid;
  final void Function(int col, int row) onTileTapped;

  /// Resolves a `<id>_v<n>.png` filename to a loaded sprite, or null if it
  /// isn't loaded yet (the host game loads them asynchronously and caches).
  final Sprite? Function(String assetPath) spriteFor;

  /// Resolves a `<kind>_h<heading>.png` file under `assets/vehicles/` to a
  /// loaded sprite, or null if it isn't loaded yet.
  final Sprite? Function(String file) vehicleSpriteFor;

  /// Current placement render set. Reassigned (cheaply) by the host game
  /// whenever placements change.
  List<PlacedBuildingView> get buildings => _buildings;
  set buildings(List<PlacedBuildingView> value) {
    _buildings = value;
    _hiddenDirty = true;
  }

  List<PlacedBuildingView> _buildings = const [];

  /// World tile of the window's local origin `(0, 0)`: the terrain is a
  /// function of *world* tiles, so the same tree stands on the same tile
  /// however the window has grown. Reassigned with [grid] by `updateLand`.
  (int, int) origin = (0, 0);

  /// The part of the board the camera can see, in board coordinates, set
  /// by the host game every frame. The ground and the decor are culled to
  /// it; null draws everything.
  Rect? visibleWorldRect;

  /// Seconds since the board was added; drives the moving dashes.
  double time = 0;

  /// Tiles painted as road (auto-generated; see `road_network.dart`). Drawn in
  /// the terrain pass, so buildings always sit on top. Reassigned by the host
  /// game whenever placements change; the pedestrians follow the new network.
  Set<(int, int)> get roads => _roads;
  set roads(Set<(int, int)> value) {
    _roads = value;
    _hiddenDirty = true;
    pedestrians.setRoads(value);
    traffic.setRoads(value);
    _replanStreetLife();
  }

  int _population = 0;
  List<String> _buildingIds = const [];

  /// The inputs of the street-life budget (city_builder.md §9.5): the live
  /// population bounds how many movers are out, and the placed building ids
  /// unlock the gated vehicles. Reassigned by the host game whenever either
  /// changes.
  void setStreetLife({
    required int population,
    required List<String> buildingIds,
  }) {
    _population = population;
    _buildingIds = buildingIds;
    _replanStreetLife();
  }

  void _replanStreetLife() {
    final plan = planStreetLife(
      population: _population,
      roadTiles: _roads.length,
      buildingIds: _buildingIds,
    );
    traffic.setFleet(
      plan,
      buildingIds: _buildingIds,
      population: _population,
    );
    pedestrians.setCrowd(plan.pedestrians);
  }

  Set<(int, int)> _roads = const {};

  /// The walkers on the sidewalks (city_builder.md §9, idea B1). Stepped in
  /// [update] — also under the wheel and the celebration, so the city keeps
  /// living behind them — and painted in the building pass.
  final PedestrianSystem pedestrians = PedestrianSystem();

  /// The cars on the roads (city_builder.md §9, ideas A1/A2). Stepped and
  /// painted alongside the pedestrians.
  final TrafficSystem traffic = TrafficSystem();

  /// Owned (purchased) land tiles in **window-local** coords. Inside the
  /// fence the decor is sparse; beyond it the countryside is wooded
  /// (city_builder.md §11, X11). Reassigned by the host game as land is
  /// bought. The set is what's drawn, so the owned region can be any shape.
  Set<(int, int)> get ownedTiles => _ownedTiles;
  set ownedTiles(Set<(int, int)> value) {
    _ownedTiles = value;
    _decorDirty = true;
  }

  Set<(int, int)> _ownedTiles = const {};

  /// Tiles (window-local) of land blocks with an open construction site —
  /// painted as a cleared dirt pad. Reassigned by the host game whenever
  /// sites change.
  Set<(int, int)> get landSiteTiles => _landSiteTiles;
  set landSiteTiles(Set<(int, int)> value) {
    _landSiteTiles = value;
    _hiddenDirty = true;
  }

  Set<(int, int)> _landSiteTiles = const {};

  /// The subset of [landSiteTiles] belonging to the selected site, drawn
  /// with the yellow selection wash.
  Set<(int, int)> selectedLandSiteTiles = const {};

  /// Trees, bushes, flowers and rocks on every tile of the window, grown
  /// from the tile hash (`decorAt`). Rebuilt when the window or the owned
  /// land changes; hidden per frame under footprints, roads and land sites.
  List<DecorItem> _decor = const [];
  bool _decorDirty = true;

  /// Tiles whose decor is covered: building and site footprints, roads,
  /// staked land. Recomputed lazily when any of those sets changes.
  Set<(int, int)> _hidden = const {};
  bool _hiddenDirty = true;

  /// The footprint a building would have needed where the player just
  /// tried to place it and could not: painted translucent red over
  /// whatever is in the way, for a moment, so the size of the gap to clear
  /// is visible. Window-local tiles.
  Set<(int, int)> rejectedTiles = const {};

  static const _roadFill = Color(0xFF9E9E9E);

  /// The ground's greens by distance from town (city_builder.md §11, T3):
  /// three shades each, picked per tile by its hash so the meadow has grain.
  static const _meadow = [
    Color(0xFF9CC466),
    Color(0xFF93BB5E),
    Color(0xFFA3C96B),
  ];
  static const _scrub = [
    Color(0xFF84AB50),
    Color(0xFF7CA24A),
    Color(0xFF8DB257),
  ];
  static const _forest = [
    Color(0xFF5F8C3B),
    Color(0xFF578235),
    Color(0xFF66943F),
  ];
  final _groundPaint = Paint();
  final _tuftPaint = Paint()
    ..color = const Color(0x59285014)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  /// Yellow wash for the selected land site, drawn over its pad. Matches
  /// the picked-up-building tint so "selected" reads the same everywhere.
  static const _buyingFill = Color(0x66FFEB3B);
  static const _rejectedFill = Color(0x80E53935);
  final _rejectedStroke = Paint()
    ..color = const Color(0xFFB71C1C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final _buyingStroke = Paint()
    ..color = const Color(0xFFF9A825)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final _tileStroke = Paint()
    ..color = const Color(0x33000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  /// Construction-site art: cleared dirt, the hoarding fence around the
  /// footprint, the stage-1 slab and the stage-2 ghost sprite.
  static const _padFill = Color(0xFFA1887F);
  static const _padFillAlt = Color(0xFF8D6E63);
  static const _slabFill = Color(0xFFB0BEC5);
  final _fenceStroke = Paint()
    ..color = const Color(0xFF5D4037)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final _fenceSelectedStroke = Paint()
    ..color = const Color(0xFFF9A825)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final _ghostPaint = Paint()..color = const Color(0x59FFFFFF);

  /// Yellow wash laid over the selected building's sprite (its opaque pixels
  /// only) so it reads as "picked up" without hiding the artwork.
  static const _selectedTint = Color(0xFFFFEB3B);
  final _selectedSpritePaint = Paint()
    ..colorFilter = const ColorFilter.mode(
      Color(0x80FFEB3B),
      BlendMode.srcATop,
    );

  late final TextPaint _emojiPaint = TextPaint(
    style: TextStyle(fontSize: grid.tileWidth * 0.42),
  );

  @override
  Future<void> onLoad() async {
    size = Vector2(grid.boardWidth, grid.boardHeight);
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
    // Walkers wait rather than step into a car; cars yield to walkers
    // already on their asphalt (a side street's mouth). A holding car never
    // holds a walker, so the pair can't deadlock.
    pedestrians.update(
      dt,
      cars: [
        for (final v in traffic.cars)
          if (vehiclePosition(v) case final pos)
            (col: pos.col, row: pos.row, held: v.held > 0),
      ],
    );
    traffic.update(
      dt,
      walkers: [
        for (final p in pedestrians.people)
          if (pedestrianPosition(p) case final pos)
            (col: pos.col, row: pos.row),
      ],
    );
  }

  @override
  void render(Canvas canvas) {
    _drawGround(canvas);
    for (final (col, row) in landSiteTiles) {
      _drawPadTile(canvas, col, row);
      if (selectedLandSiteTiles.contains((col, row))) {
        _drawBuyingTile(canvas, col, row);
      }
    }
    // Roads draw after all terrain: the sprites carry a small overscan rim
    // (seam cover), which a later-drawn neighbouring grass diamond would
    // otherwise clip.
    for (final (col, row) in roads) {
      _drawRoadTile(canvas, col, row);
    }
    // Painter's order: tiles further back (smaller col+row) draw first so
    // nearer buildings overlap them correctly. Movers slot into the same
    // sort by their interpolated col+row, pulled behind any wide building
    // they are north or west of (`moverDepth`), so a walker passes behind a
    // building's facade and in front of its road.
    // Selected (picked-up) buildings render with a yellow tint (see
    // `_drawSprite` / `_drawBox`) — that alone signals what a tap repositions.
    final citizenScale = grid.tileWidth / 64;
    final spriteScale = grid.tileWidth / kSpriteAuthoringTilePx;
    final footprints = <Footprint>[
      for (final b in buildings)
        (col: b.col, row: b.row, w: b.footprint.$1, h: b.footprint.$2),
    ];
    final vis = visibleWorldRect;
    final hidden = _hiddenTiles();
    final items = <(double, void Function())>[
      for (final b in buildings)
        ((b.col + b.row).toDouble(), () => _drawBuilding(canvas, b)),
      for (final d in _decorItems())
        if (!hidden.contains((d.col, d.row)) &&
            (vis == null || _inView(vis, d.col, d.row)))
          (d.col + d.row + 0.5, () => _drawDecor(canvas, d)),
      for (final v in pedestrians.views(grid))
        (
          moverDepth(v.col, v.row, footprints),
          () => v.paint(canvas, citizenScale),
        ),
      for (final v in traffic.views(grid))
        (
          moverDepth(v.col, v.row, footprints),
          () => v.paint(canvas, spriteScale, vehicleSpriteFor),
        ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, draw) in items) {
      draw();
    }
    // The rejected footprint sits over everything in its way.
    for (final (col, row) in rejectedTiles) {
      final (cx, cy) = grid.centerOf(col, row);
      final path = _diamond(cx, cy, 0);
      canvas
        ..drawPath(path, Paint()..color = _rejectedFill)
        ..drawPath(path, _rejectedStroke);
    }
    // Speech bubbles float above everything, over their walker's head.
    if (pedestrians.bubbles.isNotEmpty) {
      final byWalker = {
        for (final v in pedestrians.views(grid)) v.pedestrian: v,
      };
      for (final bubble in pedestrians.bubbles) {
        final v = byWalker[bubble.pedestrian];
        if (v != null) _drawBubble(canvas, bubble, v.feet, citizenScale);
      }
    }
  }

  /// A rounded speech bubble with a little tail, fading in and out at the
  /// ends of its life.
  void _drawBubble(
    Canvas canvas,
    SpeechBubble bubble,
    Offset feet,
    double scale,
  ) {
    final life = bubble.remaining;
    final alpha = life < 0.4 ? life / 0.4 : 1.0;
    final tp = TextPainter(
      text: TextSpan(
        text: bubble.text,
        style: TextStyle(
          fontSize: grid.tileWidth * 0.2,
          color: const Color(0xFF1E2A33).withValues(alpha: alpha),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: grid.tileWidth * 2.2);
    final padX = grid.tileWidth * 0.12;
    final padY = grid.tileWidth * 0.08;
    final w = tp.width + padX * 2;
    final h = tp.height + padY * 2;
    final headY = feet.dy - 58 * scale;
    final rect = Rect.fromLTWH(feet.dx - w / 2, headY - h - 10 * scale, w, h);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(h / 2));
    final fill = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.92 * alpha);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF1E2A33).withValues(alpha: 0.6 * alpha);
    final tail = Path()
      ..moveTo(feet.dx - 6 * scale, rect.bottom - 1)
      ..lineTo(feet.dx, rect.bottom + 8 * scale)
      ..lineTo(feet.dx + 6 * scale, rect.bottom - 1)
      ..close();
    canvas
      ..drawRRect(rrect, fill)
      ..drawPath(tail, fill)
      ..drawRRect(rrect, stroke);
    tp.paint(canvas, Offset(rect.left + padX, rect.top + padY));
  }

  /// Whether tile `(col, row)`'s centre lies within a tile of [vis].
  bool _inView(Rect vis, int col, int row) {
    final (cx, cy) = grid.centerOf(col, row);
    return vis.inflate(grid.tileWidth).contains(Offset(cx, cy));
  }

  /// The meadow, inside and outside the fence alike: every tile of the
  /// window in its band's greens with a tuft of grass here and there. The
  /// band comes from the tile's *world* block ring, so the countryside
  /// darkens with distance from the town (T3) and nothing shifts when the
  /// window grows.
  void _drawGround(Canvas canvas) {
    final vis = visibleWorldRect;
    final k = grid.tileWidth / 64;
    final (oc, or) = origin;
    for (var c = 0; c < grid.cols; c++) {
      for (var r = 0; r < grid.rows; r++) {
        if (vis != null && !_inView(vis, c, r)) continue;
        final (cx, cy) = grid.centerOf(c, r);
        final wc = c + oc;
        final wr = r + or;
        final palette = switch (terrainBandAt(wc, wr)) {
          TerrainBand.meadow => _meadow,
          TerrainBand.scrub => _scrub,
          TerrainBand.forest => _forest,
        };
        final h = tileHash(wc, wr);
        _groundPaint.color = palette[(h * palette.length).floor()];
        canvas.drawPath(_diamond(cx, cy, 0), _groundPaint);
        final tuft = tuftAt(wc, wr);
        if (tuft != null) {
          final tx = cx + tuft.$1 * grid.tileWidth;
          final ty = cy + tuft.$2 * grid.tileWidth;
          canvas
            ..drawLine(
              Offset(tx, ty),
              Offset(tx - 1.5 * k, ty - 4 * k),
              _tuftPaint,
            )
            ..drawLine(
              Offset(tx + 2 * k, ty),
              Offset(tx + 3 * k, ty - 4 * k),
              _tuftPaint,
            );
        }
      }
    }
  }

  /// The decor for the current window, rebuilt when the owned land or the
  /// window changes. Items are in window-local tiles, grown from world
  /// tiles so a tree never moves when the window grows.
  List<DecorItem> _decorItems() {
    if (!_decorDirty) return _decor;
    final (oc, or) = origin;
    final out = <DecorItem>[];
    for (var c = 0; c < grid.cols; c++) {
      for (var r = 0; r < grid.rows; r++) {
        final (bx, by) = blockOfTile(c + oc, r + or);
        final world = decorAt(
          c + oc,
          r + or,
          owned: _ownedTiles.contains((c, r)),
          ring: blockRing(bx, by),
        );
        if (world == null) continue;
        out.add(
          DecorItem(
            kind: world.kind,
            col: c,
            row: r,
            dx: world.dx,
            dy: world.dy,
            scale: world.scale,
            variant: world.variant,
          ),
        );
      }
    }
    _decor = out;
    _decorDirty = false;
    return out;
  }

  /// Tiles whose decor is covered by something built or staked.
  Set<(int, int)> _hiddenTiles() {
    if (!_hiddenDirty) return _hidden;
    final out = <(int, int)>{..._roads, ..._landSiteTiles};
    for (final b in _buildings) {
      final (w, h) = b.footprint;
      for (var c = b.col; c < b.col + w; c++) {
        for (var r = b.row; r < b.row + h; r++) {
          out.add((c, r));
        }
      }
    }
    _hidden = out;
    _hiddenDirty = false;
    return out;
  }

  void _drawDecor(Canvas canvas, DecorItem d) {
    final (cx, cy) = grid.centerOf(d.col, d.row);
    paintDecor(canvas, d, Offset(cx, cy), grid.tileWidth);
  }

  /// A tile of the selected land site: yellow wash + amber stroke over its
  /// pad, so the selection stands out.
  void _drawBuyingTile(Canvas canvas, int col, int row) {
    final (cx, cy) = grid.centerOf(col, row);
    final path = _diamond(cx, cy, 0);
    canvas
      ..drawPath(path, Paint()..color = _buyingFill)
      ..drawPath(path, _buyingStroke);
  }

  /// Draws one auto-road tile: resolves the connection mask to a canonical
  /// sprite + screen flips (see `road_sprites.dart`), falling back to the
  /// flat grey diamond until the sprite's async load lands.
  void _drawRoadTile(Canvas canvas, int col, int row) {
    final (cx, cy) = grid.centerOf(col, row);
    final spec = roadSpriteAt(
      isRoad: (c, r) => roads.contains((c, r)),
      col: col,
      row: row,
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

  /// A cleared dirt tile — the ground of a construction site.
  void _drawPadTile(Canvas canvas, int col, int row) {
    final (cx, cy) = grid.centerOf(col, row);
    final path = _diamond(cx, cy, 0);
    final fill = (col + row).isEven ? _padFill : _padFillAlt;
    canvas
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(path, _tileStroke);
  }

  /// Corner points of a footprint at ground level: north, east, south, west.
  (Offset, Offset, Offset, Offset) _footprintCorners(PlacedBuildingView b) {
    final (w, hTiles) = b.footprint;
    final (ncx, ncy) = grid.centerOf(b.col, b.row);
    final (ecx, ecy) = grid.centerOf(b.col + w - 1, b.row);
    final (scx, scy) = grid.centerOf(b.col + w - 1, b.row + hTiles - 1);
    final (wcx, wcy) = grid.centerOf(b.col, b.row + hTiles - 1);
    return (
      Offset(ncx, ncy - _halfH),
      Offset(ecx + _halfW, ecy),
      Offset(scx, scy + _halfH),
      Offset(wcx - _halfW, wcy),
    );
  }

  /// A site under construction (city_builder.md §8.8, interim generic
  /// overlays): stage 0 is a dirt pad ringed by a fence; stage 1 adds a
  /// foundation slab; stage 2 adds the final sprite as a ~35 % ghost.
  void _drawSite(Canvas canvas, PlacedBuildingView b, int stage) {
    final (w, hTiles) = b.footprint;
    for (var c = b.col; c < b.col + w; c++) {
      for (var r = b.row; r < b.row + hTiles; r++) {
        _drawPadTile(canvas, c, r);
      }
    }
    final (north, east, south, west) = _footprintCorners(b);
    if (stage >= 1) {
      final lift = grid.tileWidth * 0.06;
      final slab = Path()
        ..moveTo(north.dx, north.dy - lift)
        ..lineTo(east.dx, east.dy - lift)
        ..lineTo(south.dx, south.dy - lift)
        ..lineTo(west.dx, west.dy - lift)
        ..close();
      canvas
        ..drawPath(slab, Paint()..color = _slabFill)
        ..drawPath(slab, _tileStroke);
    }
    if (stage >= 2) {
      final path = b.assetPath;
      final sprite = path == null ? null : spriteFor(path);
      if (sprite != null) {
        _drawSprite(canvas, b, sprite, overridePaint: _ghostPaint);
      }
    }
    final fence = Path()
      ..moveTo(north.dx, north.dy)
      ..lineTo(east.dx, east.dy)
      ..lineTo(south.dx, south.dy)
      ..lineTo(west.dx, west.dy)
      ..close();
    canvas.drawPath(fence, b.selected ? _fenceSelectedStroke : _fenceStroke);
  }

  /// Bunting strung around a venue while a party is being prepared: a line
  /// along each footprint edge with little pennants hanging from it.
  void _drawParty(Canvas canvas, PlacedBuildingView b) {
    final (north, east, south, west) = _footprintCorners(b);
    final lift = grid.tileWidth * 0.28;
    final corners = [
      north,
      east,
      south,
      west,
    ].map((c) => Offset(c.dx, c.dy - lift)).toList();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF5D4037);
    const colors = [
      Color(0xFFEF5350),
      Color(0xFFFFCA28),
      Color(0xFF42A5F5),
      Color(0xFF66BB6A),
      Color(0xFFAB47BC),
    ];
    var k = 0;
    for (var i = 0; i < 4; i++) {
      final a = corners[i];
      final c = corners[(i + 1) % 4];
      canvas.drawLine(a, c, line);
      final n = ((a - c).distance / (grid.tileWidth * 0.22)).round().clamp(
        2,
        12,
      );
      for (var j = 1; j < n; j++) {
        final t = j / n;
        final p = Offset.lerp(a, c, t)!;
        final size = grid.tileWidth * 0.09;
        final flag = Path()
          ..moveTo(p.dx - size / 2, p.dy)
          ..lineTo(p.dx + size / 2, p.dy)
          ..lineTo(p.dx, p.dy + size * 1.3)
          ..close();
        canvas.drawPath(flag, Paint()..color = colors[k++ % colors.length]);
      }
    }
    if (b.selected) {
      final outline = Path()
        ..moveTo(north.dx, north.dy)
        ..lineTo(east.dx, east.dy)
        ..lineTo(south.dx, south.dy)
        ..lineTo(west.dx, west.dy)
        ..close();
      canvas.drawPath(outline, _fenceSelectedStroke);
    }
  }

  void _drawBuilding(Canvas canvas, PlacedBuildingView b) {
    if (b.party) {
      _drawParty(canvas, b);
      return;
    }
    final stage = b.stage;
    if (stage != null) {
      _drawSite(canvas, b, stage);
      return;
    }
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
  void _drawSprite(
    Canvas canvas,
    PlacedBuildingView b,
    Sprite sprite, {
    Paint? overridePaint,
  }) {
    final (w, hTiles) = b.footprint;
    // The footprint's lowest on-screen point is the south corner of its
    // furthest (max col+row) tile.
    final (mcx, mcy) = grid.centerOf(b.col + w - 1, b.row + hTiles - 1);
    final south = Vector2(mcx, mcy + _halfH);
    final scale = grid.tileWidth / kSpriteAuthoringTilePx;
    // In the authored canvas the footprint's south corner sits w/(w+h) of the
    // way across (the bottom-center only for square footprints — for a
    // rectangle the iso footprint is a tilted parallelogram, issue #90).
    final anchorX = w / (w + hTiles);
    sprite.render(
      canvas,
      position: south,
      size: sprite.srcSize * scale,
      anchor: Anchor(anchorX, 1),
      overridePaint:
          overridePaint ?? (b.selected ? _selectedSpritePaint : null),
    );
  }

  /// Extruded-box placeholder spanning the full footprint: the top face is
  /// the footprint quad (a parallelogram for rectangular footprints) lifted by
  /// the box height; the two visible walls drop from its south-facing edges.
  void _drawBox(Canvas canvas, PlacedBuildingView b) {
    final (w, hTiles) = b.footprint;
    final h = grid.tileWidth * 0.5;

    // Footprint corner points (ground level), via the corner tiles' centers.
    final (ncx, ncy) = grid.centerOf(b.col, b.row);
    final (ecx, ecy) = grid.centerOf(b.col + w - 1, b.row);
    final (scx, scy) = grid.centerOf(b.col + w - 1, b.row + hTiles - 1);
    final (wcx, wcy) = grid.centerOf(b.col, b.row + hTiles - 1);
    final north = Offset(ncx, ncy - _halfH);
    final east = Offset(ecx + _halfW, ecy);
    final south = Offset(scx, scy + _halfH);
    final west = Offset(wcx - _halfW, wcy);

    final left = Path()
      ..moveTo(west.dx, west.dy - h)
      ..lineTo(south.dx, south.dy - h)
      ..lineTo(south.dx, south.dy)
      ..lineTo(west.dx, west.dy)
      ..close();
    final right = Path()
      ..moveTo(east.dx, east.dy - h)
      ..lineTo(south.dx, south.dy - h)
      ..lineTo(south.dx, south.dy)
      ..lineTo(east.dx, east.dy)
      ..close();
    final top = Path()
      ..moveTo(north.dx, north.dy - h)
      ..lineTo(east.dx, east.dy - h)
      ..lineTo(south.dx, south.dy - h)
      ..lineTo(west.dx, west.dy - h)
      ..close();

    // Selected buildings wash toward yellow so the placeholder also reads as
    // "picked up", matching the sprite tint.
    final base = b.selected
        ? Color.lerp(b.color, _selectedTint, 0.55)!
        : b.color;
    canvas
      ..drawPath(left, Paint()..color = _shade(base, 0.7))
      ..drawPath(right, Paint()..color = _shade(base, 0.55))
      ..drawPath(top, Paint()..color = base);

    final center = Offset(
      (east.dx + west.dx) / 2,
      (north.dy + south.dy) / 2 - h,
    );
    _emojiPaint.render(
      canvas,
      b.emoji,
      Vector2(center.dx, center.dy),
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
