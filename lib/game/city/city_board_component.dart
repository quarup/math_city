import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';
import 'package:math_city/domain/city/day_clock.dart';
import 'package:math_city/domain/city/land_blocks.dart';
import 'package:math_city/domain/city/mover_depth.dart';
import 'package:math_city/domain/city/pedestrian_walk.dart';
import 'package:math_city/domain/city/road_sprites.dart';
import 'package:math_city/domain/city/street_life.dart';
import 'package:math_city/domain/city/terrain.dart';
import 'package:math_city/domain/city/traffic.dart';
import 'package:math_city/domain/city/window_lights.dart';
import 'package:math_city/game/city/building_lights.dart';
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
    this.lightSeed = 0,
    this.lightProfile = LightProfile.home,
  });

  /// A stable id of the placed building (its placement row), so each
  /// building's windows keep their own hours (city_builder.md §12).
  final int lightSeed;

  /// Whose windows these are — a home's, a shop's — which sets the hours.
  final LightProfile lightProfile;

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

/// An open land site (city_builder.md §11, E7): its tiles (window-local,
/// one block or a connected group) staked and strung, amber when selected.
class LandSiteView {
  const LandSiteView({required this.tiles, required this.selected});

  final Set<(int, int)> tiles;
  final bool selected;
}

/// A purchasable block while Expand city is on (city_builder.md §11, E1):
/// survey stakes and string round its 4×4, a faint wash, and a price pill
/// at its centre; the string turns amber when it is the selected one.
class FrontierBlockView {
  const FrontierBlockView({
    required this.col,
    required this.row,
    required this.price,
    required this.selected,
  });

  /// Window-local tile of the block's north corner.
  final int col;
  final int row;
  final int price;
  final bool selected;
}

/// Renders the isometric terrain grid plus placeholder extruded-box buildings,
/// and reports tile taps back to the presentation layer. Phase 7 placeholder
/// art per plan.md — colored diamonds + emoji, no PNGs.
class CityBoardComponent extends PositionComponent with TapCallbacks {
  CityBoardComponent({
    required IsoGrid grid,
    required this.onTileTapped,
    required this.spriteFor,
    required this.vehicleSpriteFor,
    required this.lightsFor,
  }) : _grid = grid;

  /// Resolves a building sprite file to its lights and lit pixels, or null
  /// if it has none (or they are not loaded yet).
  final LitSprite? Function(String assetPath) lightsFor;

  /// The town clock's exact hour, set by the host game every frame: the
  /// night tint and the lights follow it.
  double clockHour = kChapterOneHour;

  /// The board's tile↔screen geometry for the current window. Reassigned by the
  /// host game when land is bought and the window grows (see
  /// `IsoCityGame.updateLand`); the render loop reads it live each frame.
  IsoGrid get grid => _grid;
  set grid(IsoGrid value) {
    _grid = value;
    _groundRange = null;
    _decorDirty = true;
  }

  IsoGrid _grid;
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
    _lightStates.clear();
  }

  List<PlacedBuildingView> _buildings = const [];

  /// World tile of the window's local origin `(0, 0)`: the terrain is a
  /// function of *world* tiles, so the same tree stands on the same tile
  /// however the window has grown. Reassigned with [grid] by `updateLand`.
  (int, int) get origin => _origin;
  set origin((int, int) value) {
    _origin = value;
    _groundRange = null;
    _decorDirty = true;
  }

  (int, int) _origin = (0, 0);

  /// The part of the board the camera can see, in board coordinates, set
  /// by the host game every frame. The ground and the decor are culled to
  /// it; null draws everything.
  Rect? visibleWorldRect;

  /// Seconds since the board was added; drives the moving dashes.
  double time = 0;

  /// The ground (and the decor beyond the window) recorded once for the
  /// visible tile range, in chunks of [_kGroundChunk] tiles, and replayed
  /// until the camera leaves the range or the window changes. The plane
  /// is infinite: tiles past the window are painted too, so a zoomed-out
  /// camera never sees the backdrop.
  ui.Picture? _groundPicture;
  (int, int, int, int)? _groundRange;
  static const int _kGroundChunk = 8;

  /// True while a building is being placed or moved (city_builder.md §11,
  /// B1 + B4): the countryside dims, a thin tile grid lies over the owned
  /// land and the town's boundary runs round it as a moving dashed line.
  /// Nothing of this is drawn at rest.
  bool placementEdges = false;

  /// Expand-city mode (E1 + E6): the purchasable blocks to stake, and
  /// whether the mode is on at all (the land beyond the ring dims).
  bool expandMode = false;
  List<FrontierBlockView> frontierBlocks = const [];

  /// E9: the block set a building that did not fit needs, staked as one
  /// plot (window-local tiles) with its group label, while Expand city
  /// proposes it. Empty when no proposal is up.
  Set<(int, int)> proposedPlot = const {};
  String? proposedLabel;

  /// The camera's zoom, set by the host game every frame, so labels can be
  /// drawn at a constant screen size.
  double cameraZoom = 1;

  /// The town's outline for the placement edges — every owned-tile edge
  /// facing unowned land, road crossings included (the fence skips them).
  List<EdgeSegment> _boundary = const [];
  bool _boundaryDirty = true;

  /// Tiles painted as road (auto-generated; see `road_network.dart`). Drawn in
  /// the terrain pass, so buildings always sit on top. Reassigned by the host
  /// game whenever placements change; the pedestrians follow the new network.
  Set<(int, int)> get roads => _roads;
  set roads(Set<(int, int)> value) {
    _roads = value;
    _hiddenDirty = true;
    _fenceDirty = true;
    // The highway past the window joins the roads at its edge.
    _groundRange = null;
    _syncMoverRoads();
    _replanStreetLife();
  }

  /// How far past the window the roads out of town carry the through
  /// traffic before it turns into a fresh car: well past any zoom.
  static const int kHighwayReach = 40;

  /// Whether local tile `(col, row)` lies outside the window on one of the
  /// roads that leave town — road there with nothing else on it.
  bool _isHighwayBeyond(int col, int row) {
    if (col >= 0 && col < grid.cols && row >= 0 && row < grid.rows) {
      return false;
    }
    final (oc, or) = origin;
    return isHighwayTile(col + oc, row + or);
  }

  /// Whether every exit can be reached from the first over [tiles].
  bool _linksAll(Set<(int, int)> tiles, List<HighwayExit> exits) {
    if (exits.isEmpty) return true;
    final start = (exits.first.col, exits.first.row);
    final seen = <(int, int)>{start};
    final stack = <(int, int)>[start];
    while (stack.isNotEmpty) {
      final (c, r) = stack.removeLast();
      for (final (dc, dr) in const [(1, 0), (0, 1), (-1, 0), (0, -1)]) {
        final n = (c + dc, r + dr);
        if (tiles.contains(n) && seen.add(n)) stack.add(n);
      }
    }
    return exits.every((e) => seen.contains((e.col, e.row)));
  }

  /// Hands the movers their road graphs: walkers and town-only vehicles
  /// keep to the roads inside the fence; the through traffic also gets the
  /// highway on to [kHighwayReach] tiles past the window, ending at the
  /// three exits.
  void _syncMoverRoads() {
    final town = {
      for (final t in _roads)
        if (_ownedTiles.contains(t)) t,
    };
    final (oc, or) = origin;
    final mainRow = kMainStreetRow - or;
    final highCol = kHighStreetCol - oc;
    // The through traffic keeps to the two roads that leave town, so the
    // inter-town roads stay busy instead of the cars getting lost in the
    // side streets.
    final beyond = <(int, int)>{};
    final exits = <HighwayExit>[];
    if (mainRow >= 0 && mainRow < grid.rows) {
      for (var c = -kHighwayReach; c < 0; c++) {
        beyond.add((c, mainRow));
      }
      for (var c = grid.cols; c < grid.cols + kHighwayReach; c++) {
        beyond.add((c, mainRow));
      }
      exits
        ..add(HighwayExit(col: -kHighwayReach, row: mainRow, inbound: 0))
        ..add(
          HighwayExit(
            col: grid.cols + kHighwayReach - 1,
            row: mainRow,
            inbound: 2,
          ),
        );
    }
    if (highCol >= 0 && highCol < grid.cols) {
      for (var r = grid.rows; r < grid.rows + kHighwayReach; r++) {
        beyond.add((highCol, r));
      }
      exits.add(
        HighwayExit(
          col: highCol,
          row: grid.rows + kHighwayReach - 1,
          inbound: 3,
        ),
      );
    }
    var through = <(int, int)>{
      ...beyond,
      for (final (c, r) in _roads)
        if (isHighwayTile(c + oc, r + or)) (c, r),
    };
    // The player may set a building down on one of them: if the highway
    // alone no longer links the exits, the through traffic uses the
    // town's streets to get across.
    if (!_linksAll(through, exits)) through = {...beyond, ..._roads};
    pedestrians.setRoads(town);
    traffic.setRoads(
      _roads,
      townRoads: town,
      throughRoads: through,
      exits: exits,
    );
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

  /// The town clock's hour, in quarter-hour steps: the street life follows
  /// it (walkers by day, the school bus in school hours, a thin night
  /// traffic). Set by the host game every frame; replans on a new step.
  double _hour = kChapterOneHour;
  int? _hourStep;

  void setHour(double hour) {
    final step = (hour * 4).floor();
    if (step == _hourStep) return;
    _hourStep = step;
    _hour = hour;
    _replanStreetLife();
  }

  void _replanStreetLife() {
    // The roads that run on past the fence are not streets: the budget
    // counts the town's own.
    final plan = planStreetLife(
      population: _population,
      roadTiles: _roads.where(_ownedTiles.contains).length,
      buildingIds: _buildingIds,
      hour: _hour,
    );
    traffic
      ..setFleet(plan, buildingIds: _buildingIds, population: _population)
      ..setCommutersPerExit(commutersPerExitAt(_hour));
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
    _fenceDirty = true;
    _boundaryDirty = true;
    _groundRange = null;
    _syncMoverRoads();
  }

  Set<(int, int)> _ownedTiles = const {};

  /// The fence line: every owned-tile edge facing the countryside, minus
  /// the road crossings (X11). Recomputed when the land or the roads change.
  List<EdgeSegment> _fence = const [];
  bool _fenceDirty = true;

  /// The open land sites: staked and strung plots on the countryside.
  /// Reassigned by the host game whenever sites change.
  List<LandSiteView> get landSites => _landSites;
  set landSites(List<LandSiteView> value) {
    _landSites = value;
    _hiddenDirty = true;
  }

  List<LandSiteView> _landSites = const [];

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

  /// The split-rail fence (X5): brown posts, two paler rails.
  final _railPaint = Paint()
    ..color = const Color(0xFFA1887F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  final _postPaint = Paint()..color = const Color(0xFF8D6E63);
  final _postShadowPaint = Paint()..color = const Color(0x2E000000);

  /// Placement-mode edges (B1): the dim over the countryside, the tile
  /// grid over owned land, the dashed boundary.
  final _dimPaint = Paint()..color = const Color(0x33141E3C);
  final _gridPaint = Paint()
    ..color = const Color(0x33FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final _boundaryPaint = Paint()
    ..color = const Color(0xE6FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  /// Survey stakes and string (E1): white string on a resting block, amber
  /// marching dashes on the selected one.
  static const _amber = Color(0xFFF9A825);
  final _stringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final _stakePaint = Paint()..color = const Color(0xFF6D4C2B);
  final _capPaint = Paint();
  final _washPaint = Paint();
  final Map<String, TextPainter> _pillText = {};

  static const _rejectedFill = Color(0x80E53935);
  final _rejectedStroke = Paint()
    ..color = const Color(0xFFB71C1C)
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
        for (final v in traffic.allCars)
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
    // Roads draw after all terrain: the sprites carry a small overscan rim
    // (seam cover), which a later-drawn neighbouring grass diamond would
    // otherwise clip.
    for (final (col, row) in roads) {
      _drawRoadTile(canvas, col, row);
    }
    _drawFence(canvas);
    for (final site in _landSites) {
      _drawStakedPlot(canvas, site.tiles, selected: site.selected);
    }
    if (expandMode && proposedPlot.isNotEmpty) {
      _drawStakedPlot(canvas, proposedPlot, selected: true);
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
    // The night: how dark it is, and how much the lights show. Each item
    // carries, next to its draw, what it does in the light pass — a
    // building cuts itself out of the lights behind it and adds its own
    // windows; a tree only cuts itself out.
    final night = nightStrengthAt(clockHour);
    final dusk = duskWarmthAt(clockHour);
    final darkness = night > dusk * 0.45 ? night : dusk * 0.45;
    final lightLevel = ((darkness - 0.08) / 0.22).clamp(0.0, 1.0);
    final items = <(double, void Function(), void Function()?)>[
      for (final b in buildings)
        (
          (b.col + b.row).toDouble(),
          () => _drawBuilding(canvas, b),
          b.stage == null && !b.party
              ? () => _drawBuildingLights(canvas, b, lightLevel)
              : null,
        ),
      for (final d in _decorItems())
        if (!hidden.contains((d.col, d.row)) &&
            (vis == null || _inView(vis, d.col, d.row)))
          (
            d.col + d.row + 0.5,
            () => _drawDecor(canvas, d),
            d.kind == DecorKind.tree
                ? () => _drawDecor(canvas, d, silhouette: _erasePaint)
                : null,
          ),
      for (final v in pedestrians.views(grid))
        (
          moverDepth(v.col, v.row, footprints),
          () => _fading(
            canvas,
            v.feet,
            v.opacity,
            () => v.paint(canvas, citizenScale),
          ),
          null,
        ),
      for (final v in traffic.views(grid))
        (
          moverDepth(v.col, v.row, footprints),
          () => _fading(
            canvas,
            v.centre,
            v.opacity,
            () => v.paint(canvas, spriteScale, vehicleSpriteFor),
          ),
          null,
        ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, draw, _) in items) {
      draw();
    }
    _drawNightTint(canvas, night, dusk);
    if (lightLevel > 0.02) {
      // The lights go on their own layer over the tinted town, in the same
      // back-to-front order, so a building in front hides the windows
      // behind it.
      canvas.saveLayer(vis?.inflate(grid.tileWidth * 2), Paint());
      for (final (_, _, light) in items) {
        light?.call();
      }
      canvas.restore();
    }
    if (placementEdges) _drawPlacementEdges(canvas);
    if (expandMode) _drawExpandMode(canvas);
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

  /// Paints a mover at [at] through [opacity] (a walker or a car joining or
  /// leaving the street as the hour changes); a plain paint at full opacity.
  void _fading(
    Canvas canvas,
    Offset at,
    double opacity,
    void Function() paint,
  ) {
    if (opacity >= 1) {
      paint();
      return;
    }
    final r = grid.tileWidth;
    canvas.saveLayer(
      Rect.fromLTRB(at.dx - r, at.dy - 1.5 * r, at.dx + r, at.dy + 0.75 * r),
      Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
    );
    paint();
    canvas.restore();
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

  /// The local tile range (minCol, maxCol, minRow, maxRow) whose diamonds
  /// can touch [rect], a tile beyond on every side.
  (int, int, int, int) _tileRangeOf(Rect rect) {
    var minC = double.infinity;
    var minR = double.infinity;
    var maxC = double.negativeInfinity;
    var maxR = double.negativeInfinity;
    for (final p in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      final (c, r) = grid.fractionalTileAt(p.dx, p.dy);
      if (c < minC) minC = c;
      if (r < minR) minR = r;
      if (c > maxC) maxC = c;
      if (r > maxR) maxR = r;
    }
    return (
      minC.floor() - 1,
      maxC.ceil() + 1,
      minR.floor() - 1,
      maxR.ceil() + 1,
    );
  }

  /// The meadow, inside and outside the fence alike — and on past the
  /// window: every tile the camera can see is painted in its band's greens
  /// with a tuft of grass here and there. The band comes from the tile's
  /// *world* block ring, so the countryside darkens with distance from the
  /// town (T3) and nothing shifts when the window grows. Recorded once per
  /// visible chunk range and replayed.
  void _drawGround(Canvas canvas) {
    final vis = visibleWorldRect;
    final (c0, c1, r0, r1) = vis == null
        ? (0, grid.cols - 1, 0, grid.rows - 1)
        : _tileRangeOf(vis);
    int down(int v) => (v / _kGroundChunk).floor() * _kGroundChunk;
    int up(int v) => (v / _kGroundChunk).ceil() * _kGroundChunk;
    final range = (down(c0), up(c1), down(r0), up(r1));
    final roadSpriteArrived =
        !_groundHadRoadSprite &&
        spriteFor(RoadSpriteShape.straight.fileName) != null;
    if (_groundPicture == null || _groundRange != range || roadSpriteArrived) {
      _groundPicture?.dispose();
      _groundPicture = _recordGround(range);
      _groundRange = range;
    }
    canvas.drawPicture(_groundPicture!);
  }

  /// Whether the straight road sprite was loaded when the ground was last
  /// recorded; the highway beyond the window is baked into the picture,
  /// so it re-records once the sprite arrives.
  bool _groundHadRoadSprite = false;

  ui.Picture _recordGround((int, int, int, int) range) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final k = grid.tileWidth / 64;
    final (oc, or) = origin;
    final (c0, c1, r0, r1) = range;
    final outside = <DecorItem>[];
    final ownedBlocks = <(int, int)>{
      for (final (c, r) in _ownedTiles) blockOfTile(c + oc, r + or),
    };
    final distance = <(int, int), int>{};
    _groundHadRoadSprite = spriteFor(RoadSpriteShape.straight.fileName) != null;
    for (var c = c0; c <= c1; c++) {
      for (var r = r0; r <= r1; r++) {
        final (cx, cy) = grid.centerOf(c, r);
        final wc = c + oc;
        final wr = r + or;
        final block = blockOfTile(wc, wr);
        final d = distance.putIfAbsent(
          block,
          () => blockDistanceToOwned(block.$1, block.$2, ownedBlocks),
        );
        final palette = switch (terrainBandForDistance(d)) {
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
        // Beyond the window nothing is ever built, so its decor needs no
        // depth sort against buildings and can live in the picture — and
        // the roads out of town run on to the edge of whatever is seen.
        if (c < 0 || c >= grid.cols || r < 0 || r >= grid.rows) {
          if (isHighwayTile(wc, wr)) {
            _drawRoadTile(canvas, c, r);
            continue;
          }
          final item = decorAt(wc, wr, owned: false, ring: d + 2);
          if (item != null) outside.add(item);
        }
      }
    }
    outside.sort((a, b) => (a.col + a.row).compareTo(b.col + b.row));
    for (final d in outside) {
      final (cx, cy) = grid.centerOf(d.col - oc, d.row - or);
      paintDecor(canvas, d, Offset(cx, cy), grid.tileWidth);
    }
    return recorder.endRecording();
  }

  /// The two ground corners of a tile's [side], in painter order.
  (Offset, Offset) _sideCorners(int col, int row, TileSide side) {
    final (cx, cy) = grid.centerOf(col, row);
    final n = Offset(cx, cy - _halfH);
    final e = Offset(cx + _halfW, cy);
    final s = Offset(cx, cy + _halfH);
    final w = Offset(cx - _halfW, cy);
    return switch (side) {
      TileSide.east => (e, s),
      TileSide.south => (s, w),
      TileSide.west => (w, n),
      TileSide.north => (n, e),
    };
  }

  /// The rail fence along the town's edge (city_builder.md §11, X11): two
  /// rails and three posts per tile edge, opening where a road crosses.
  /// Drawn in the terrain pass so buildings stand in front of it.
  void _drawFence(Canvas canvas) {
    if (_fenceDirty) {
      _fence = edgeSegments(owned: _ownedTiles, roads: _roads);
      _fenceDirty = false;
    }
    final vis = visibleWorldRect;
    final k = grid.tileWidth / 64;
    final rails = Path();
    for (final seg in _fence) {
      if (vis != null && !_inView(vis, seg.col, seg.row)) continue;
      final (a, b) = _sideCorners(seg.col, seg.row, seg.side);
      for (final z in const [2.5, 6.0]) {
        rails
          ..moveTo(a.dx, a.dy - z * k)
          ..lineTo(b.dx, b.dy - z * k);
      }
    }
    canvas.drawPath(rails, _railPaint..strokeWidth = 1.6 * k);
    for (final seg in _fence) {
      if (vis != null && !_inView(vis, seg.col, seg.row)) continue;
      final (a, b) = _sideCorners(seg.col, seg.row, seg.side);
      for (var i = 0; i <= 2; i++) {
        final p = Offset.lerp(a, b, i / 2)!;
        canvas
          ..drawRect(
            Rect.fromLTWH(p.dx - 1.2 * k, p.dy - 0.5 * k, 2.4 * k, 1.5 * k),
            _postShadowPaint,
          )
          ..drawRect(
            Rect.fromLTWH(p.dx - 1.1 * k, p.dy - 8 * k, 2.2 * k, 8 * k),
            _postPaint,
          );
      }
    }
  }

  /// B1 + B4: while something is in the hand, dim the land beyond the town,
  /// lay a tile grid over the owned land and run the boundary round it as
  /// a moving dashed line, so a refused spot explains itself.
  void _drawPlacementEdges(Canvas canvas) {
    final vis = visibleWorldRect;
    for (var c = 0; c < grid.cols; c++) {
      for (var r = 0; r < grid.rows; r++) {
        if (vis != null && !_inView(vis, c, r)) continue;
        final (cx, cy) = grid.centerOf(c, r);
        final path = _diamond(cx, cy, 0);
        canvas.drawPath(
          path,
          _ownedTiles.contains((c, r)) ? _gridPaint : _dimPaint,
        );
      }
    }
    if (_boundaryDirty) {
      _boundary = edgeSegments(owned: _ownedTiles);
      _boundaryDirty = false;
    }
    final k = grid.tileWidth / 64;
    final outline = Path();
    for (final seg in _boundary) {
      if (vis != null && !_inView(vis, seg.col, seg.row)) continue;
      final (a, b) = _sideCorners(seg.col, seg.row, seg.side);
      outline
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }
    canvas.drawPath(
      dashedPath(outline, dash: 8 * k, gap: 6 * k, phase: time * 14 * k),
      _boundaryPaint..strokeWidth = 2 * k,
    );
  }

  /// Corner points of a `w × h` tile region at local `(col, row)`: north,
  /// east, south, west.
  (Offset, Offset, Offset, Offset) _regionCorners(
    int col,
    int row,
    int w,
    int h,
  ) {
    final (ncx, ncy) = grid.centerOf(col, row);
    final (ecx, ecy) = grid.centerOf(col + w - 1, row);
    final (scx, scy) = grid.centerOf(col + w - 1, row + h - 1);
    final (wcx, wcy) = grid.centerOf(col, row + h - 1);
    return (
      Offset(ncx, ncy - _halfH),
      Offset(ecx + _halfW, ecy),
      Offset(scx, scy + _halfH),
      Offset(wcx - _halfW, wcy),
    );
  }

  /// A staked plot of any shape (a land site, or the group a big footprint
  /// needs): a yellow wash over its tiles, string along its outline and a
  /// stake at every corner. [selected] makes the string march.
  void _drawStakedPlot(
    Canvas canvas,
    Set<(int, int)> tiles, {
    required bool selected,
  }) {
    final k = grid.tileWidth / 64;
    _washPaint.color = selected
        ? const Color(0x59FFEB3B)
        : const Color(0x2EFFEB3B);
    for (final (c, r) in tiles) {
      final (cx, cy) = grid.centerOf(c, r);
      canvas.drawPath(_diamond(cx, cy, 0), _washPaint);
    }
    final outline = Path();
    final corners = <Offset>{};
    for (final seg in edgeSegments(owned: tiles)) {
      final (a, b) = _sideCorners(seg.col, seg.row, seg.side);
      outline
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
      corners
        ..add(Offset(a.dx.roundToDouble(), a.dy.roundToDouble()))
        ..add(Offset(b.dx.roundToDouble(), b.dy.roundToDouble()));
    }
    _stringPaint
      ..color = _amber
      ..strokeWidth = 2 * k;
    canvas.drawPath(
      dashedPath(
        outline,
        dash: 6 * k,
        gap: 5 * k,
        phase: selected ? time * 12 * k : 0,
      ),
      _stringPaint,
    );
    _capPaint.color = _amber;
    for (final p in corners) {
      canvas
        ..drawRect(
          Rect.fromLTWH(p.dx - 1.5 * k, p.dy - 10 * k, 3 * k, 11 * k),
          _stakePaint,
        )
        ..drawRect(
          Rect.fromLTWH(p.dx - 3 * k, p.dy - 12 * k, 6 * k, 4 * k),
          _capPaint,
        );
    }
  }

  /// Survey stakes at the corners of a region and string between them,
  /// over an optional wash. [selected] makes the string amber and marching.
  void _drawSurvey(
    Canvas canvas,
    (Offset, Offset, Offset, Offset) corners, {
    required bool selected,
    Color? wash,
  }) {
    final k = grid.tileWidth / 64;
    final (n, e, s, w) = corners;
    final outline = Path()
      ..moveTo(n.dx, n.dy)
      ..lineTo(e.dx, e.dy)
      ..lineTo(s.dx, s.dy)
      ..lineTo(w.dx, w.dy)
      ..close();
    if (wash != null) canvas.drawPath(outline, _washPaint..color = wash);
    _stringPaint
      ..color = selected ? _amber : const Color(0xE6FFFFFF)
      ..strokeWidth = (selected ? 2 : 1.5) * k;
    canvas.drawPath(
      dashedPath(
        outline,
        dash: 6 * k,
        gap: 5 * k,
        phase: selected ? time * 12 * k : 0,
      ),
      _stringPaint,
    );
    _capPaint.color = selected ? _amber : const Color(0xFFF5F2E8);
    for (final p in [n, e, s, w]) {
      canvas
        ..drawRect(
          Rect.fromLTWH(p.dx - 1.5 * k, p.dy - 10 * k, 3 * k, 11 * k),
          _stakePaint,
        )
        ..drawRect(
          Rect.fromLTWH(p.dx - 3 * k, p.dy - 12 * k, 6 * k, 4 * k),
          _capPaint,
        );
    }
  }

  /// A label at a world point drawn at a constant screen size whatever the
  /// zoom: the app's dark pill.
  void _drawPill(Canvas canvas, Offset at, String text) {
    final tp = _pillText.putIfAbsent(
      text,
      () => TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFFFFF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
    final w = tp.width + 18;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: 22),
      const Radius.circular(11),
    );
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..scale(1 / cameraZoom)
      ..drawRRect(rect, Paint()..color = const Color(0xC7101917));
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2 + 0.5));
    canvas.restore();
  }

  /// E1 + E6: beyond the purchasable ring the land dims; each purchasable
  /// block gets stakes, string, a faint wash and its price pill; the
  /// selected block is amber with a yellow wash.
  void _drawExpandMode(Canvas canvas) {
    final vis = visibleWorldRect;
    final ringTiles = <(int, int)>{
      ...proposedPlot,
      for (final b in frontierBlocks)
        for (var c = b.col; c < b.col + kBlockSize; c++)
          for (var r = b.row; r < b.row + kBlockSize; r++) (c, r),
    };
    for (var c = 0; c < grid.cols; c++) {
      for (var r = 0; r < grid.rows; r++) {
        if (_ownedTiles.contains((c, r)) || ringTiles.contains((c, r))) {
          continue;
        }
        if (vis != null && !_inView(vis, c, r)) continue;
        final (cx, cy) = grid.centerOf(c, r);
        canvas.drawPath(_diamond(cx, cy, 0), _dimPaint);
      }
    }
    for (final b in frontierBlocks) {
      _drawSurvey(
        canvas,
        _regionCorners(b.col, b.row, kBlockSize, kBlockSize),
        selected: b.selected,
        wash: b.selected ? const Color(0x59FFEB3B) : const Color(0x1AFFFFFF),
      );
    }
    for (final b in frontierBlocks) {
      final (cx, cy) = grid.pointAt(b.col + 1.5, b.row + 1.5);
      _drawPill(
        canvas,
        Offset(cx, cy - 6 * grid.tileWidth / 64),
        '🪙 ${b.price}',
      );
    }
    if (proposedPlot.isNotEmpty && proposedLabel != null) {
      var sx = 0.0;
      var sy = 0.0;
      for (final (c, r) in proposedPlot) {
        final (cx, cy) = grid.centerOf(c, r);
        sx += cx;
        sy += cy;
      }
      final n = proposedPlot.length;
      _drawPill(
        canvas,
        Offset(sx / n, sy / n + grid.tileWidth * 0.6),
        proposedLabel!,
      );
    }
  }

  /// The decor for the current window, rebuilt when the owned land or the
  /// window changes. Items are in window-local tiles, grown from world
  /// tiles so a tree never moves when the window grows.
  List<DecorItem> _decorItems() {
    if (!_decorDirty) return _decor;
    final (oc, or) = origin;
    final out = <DecorItem>[];
    final ownedBlocks = <(int, int)>{
      for (final (c, r) in _ownedTiles) blockOfTile(c + oc, r + or),
    };
    for (var c = 0; c < grid.cols; c++) {
      for (var r = 0; r < grid.rows; r++) {
        final (bx, by) = blockOfTile(c + oc, r + or);
        final world = decorAt(
          c + oc,
          r + or,
          owned: _ownedTiles.contains((c, r)),
          ring: blockDistanceToOwned(bx, by, ownedBlocks) + 2,
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
    final out = <(int, int)>{
      ..._roads,
      for (final site in _landSites) ...site.tiles,
    };
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

  void _drawDecor(Canvas canvas, DecorItem d, {Paint? silhouette}) {
    final (cx, cy) = grid.centerOf(d.col, d.row);
    paintDecor(
      canvas,
      d,
      Offset(cx, cy),
      grid.tileWidth,
      silhouette: silhouette,
    );
  }

  // ---- Night: tint and lights (city_builder.md §12) ----------------------

  /// Cuts a shape out of the light layer: whatever stands in front of a
  /// lit window hides it.
  final _erasePaint = Paint()..blendMode = BlendMode.dstOut;
  final _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final _litPaint = Paint()..filterQuality = FilterQuality.low;
  static const _windowGlow = Color(0xFFFFD890);

  /// The time of day over the whole scene: a warm wash at dawn and dusk,
  /// a dark multiply at night. Drawn over the town and under its lights
  /// and its overlays.
  void _drawNightTint(Canvas canvas, double night, double dusk) {
    if (night <= 0.02 && dusk <= 0.02) return;
    final rect =
        (visibleWorldRect ??
                Rect.fromLTWH(0, 0, grid.boardWidth, grid.boardHeight))
            .inflate(grid.tileWidth * 2);
    if (dusk > 0.02) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFFFFAA5A).withValues(alpha: dusk * 0.35)
          ..blendMode = BlendMode.multiply,
      );
    }
    if (night > 0.02) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = Color.fromARGB(
            255,
            (255 - 175 * night).round(),
            (255 - 160 * night).round(),
            (255 - 95 * night).round(),
          )
          ..blendMode = BlendMode.multiply,
      );
    }
  }

  /// Which of a building's windows are on this game minute: the fully lit
  /// ones as one path, the ones mid-fade each with its level.
  final Map<String, _LightState> _lightStates = {};

  _LightState _lightStateFor(PlacedBuildingView b, SpriteLights lights) {
    final minute = (clockHour * 60).floor();
    final key = '${b.assetPath}#${b.lightSeed}';
    final cached = _lightStates[key];
    if (cached != null && cached.minute == minute) return cached;
    Path? full;
    final fading = <(Path, double)>[];
    for (var i = 0; i < lights.regions.length; i++) {
      final region = lights.regions[i];
      final level = windowLightAt(
        clockHour,
        windowHoursFor(
          seed: b.lightSeed,
          index: i,
          profile: b.lightProfile,
          glow: region.glow,
        ),
      );
      if (level <= 0.01) continue;
      if (level >= 0.99) {
        (full ??= Path()).addPath(region.path, Offset.zero);
      } else {
        fading.add((region.path, level));
      }
    }
    return _lightStates[key] = _LightState(minute, full, fading);
  }

  /// A building in the light pass: it hides the lights behind it, then
  /// shows its own lit windows — the sprite's lit pixels through the
  /// regions that are on, over a soft glow.
  void _drawBuildingLights(Canvas canvas, PlacedBuildingView b, double level) {
    final path = b.assetPath;
    final sprite = path == null ? null : spriteFor(path);
    if (path == null || sprite == null) return;
    _drawSprite(canvas, b, sprite, overridePaint: _erasePaint);
    final lit = lightsFor(path);
    if (lit == null) return;
    final state = _lightStateFor(b, lit.lights);
    if (state.full == null && state.fading.isEmpty) return;
    // Sprite pixels → board space, anchored like `_drawSprite`.
    final (w, hTiles) = b.footprint;
    final (mcx, mcy) = grid.centerOf(b.col + w - 1, b.row + hTiles - 1);
    final scale = grid.tileWidth / kSpriteAuthoringTilePx;
    final size = sprite.srcSize * scale;
    canvas
      ..save()
      ..translate(mcx - size.x * w / (w + hTiles), mcy + _halfH - size.y)
      ..scale(scale);
    void shine(Path region, double alpha) {
      canvas
        ..drawPath(
          region,
          _glowPaint..color = _windowGlow.withValues(alpha: 0.4 * alpha),
        )
        ..save()
        ..clipPath(region)
        ..drawImage(
          lit.lit,
          Offset.zero,
          _litPaint..color = Color.fromRGBO(255, 255, 255, alpha),
        )
        ..restore();
    }

    if (state.full case final full?) shine(full, level);
    for (final (region, alpha) in state.fading) {
      shine(region, alpha * level);
    }
    canvas.restore();
  }

  /// Draws one auto-road tile: resolves the connection mask to a canonical
  /// sprite + screen flips (see `road_sprites.dart`), falling back to the
  /// flat grey diamond until the sprite's async load lands.
  void _drawRoadTile(Canvas canvas, int col, int row) {
    final (cx, cy) = grid.centerOf(col, row);
    final spec = roadSpriteAt(
      isRoad: (c, r) => roads.contains((c, r)) || _isHighwayBeyond(c, r),
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

/// [path] cut into dashes of [dash] length separated by [gap], starting
/// [phase] along each contour so an increasing phase makes them march.
Path dashedPath(
  Path path, {
  required double dash,
  required double gap,
  double phase = 0,
}) {
  final out = Path();
  final period = dash + gap;
  for (final metric in path.computeMetrics()) {
    var d = -(phase % period);
    while (d < metric.length) {
      final start = d < 0 ? 0.0 : d;
      final end = d + dash;
      if (end > 0) {
        out.addPath(
          metric.extractPath(start, end > metric.length ? metric.length : end),
          Offset.zero,
        );
      }
      d += period;
    }
  }
  return out;
}

/// A building's lit windows at one game minute.
class _LightState {
  const _LightState(this.minute, this.full, this.fading);

  final int minute;

  /// Every fully lit region as one path, or null if none is.
  final Path? full;

  /// Regions coming on or going off, each with its level `0..1`.
  final List<(Path, double)> fading;
}
