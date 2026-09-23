import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show VoidCallback;

import 'package:flame/cache.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:math_city/domain/city/road_sprites.dart';
import 'package:math_city/game/city/camera_focus.dart';
import 'package:math_city/game/city/city_board_component.dart';
import 'package:math_city/game/city/iso_grid.dart';

/// Hosts the isometric [CityBoardComponent] inside Flame's camera/world so the
/// board can be panned and pinch-zoomed. Tap-to-place is handled by the board
/// itself (it receives world-space taps through the camera).
///
/// Single-finger drag pans via [DragCallbacks]. Pinch-zoom is driven from
/// outside via [setZoom] / [pinchActive] — wired up by a Flutter `Listener`
/// in `city_screen.dart` that tracks raw pointer events for two-finger
/// gestures. We used to use `ScaleCallbacks` for both, but it never produced
/// update callbacks for single-pointer drags here (Flutter arena fight with
/// the child board's `TapCallbacks`).
class IsoCityGame extends FlameGame with DragCallbacks {
  IsoCityGame({required this.grid, required this.onTileTapped});

  /// The current window's geometry. Reassigned in place by [updateLand] when
  /// land is bought and the window grows — the game is never rebuilt for a land
  /// change, so the camera/zoom survive a purchase.
  IsoGrid grid;
  final void Function(int col, int row) onTileTapped;

  late final CityBoardComponent board;

  static const double minZoom = 0.4;
  static const double maxZoom = 3;

  /// The initial camera starts zoomed in to ~1/3 of the fit-the-whole-board
  /// distance, i.e. [_fitCamera] multiplies the whole-board fit zoom by this.
  static const double initialZoomInFactor = 3;

  bool _fitted = false;

  /// While true, single-pointer drag pan is suppressed. The Listener flips
  /// this on as soon as a second pointer goes down so the two parallel
  /// per-finger pans don't jitter the camera during a pinch.
  bool pinchActive = false;

  // ---- Focus (camera tween onto one footprint) --------------------------
  //
  // The construction loop zooms the camera onto a site (wheel above it) or a
  // just-opened building (celebration) and back out again — never a screen
  // swap (city_builder.md §8.7). While focused, pan / pinch are ignored and
  // the board clamp is lifted (the anchored framing may put the camera
  // centre past the board edge).

  late Vector2 _tweenFromPos;
  double _tweenFromZoom = 1;
  Vector2? _tweenToPos;
  double _tweenToZoom = 1;
  double _tweenElapsed = 0;
  double _tweenDuration = 0;
  VoidCallback? _tweenDone;

  /// Camera as it stood before the first focus, restored by [releaseFocus].
  Vector2? _restorePos;
  double _restoreZoom = 1;

  bool get isFocused => _restorePos != null;
  bool get isTweening => _tweenToPos != null;

  /// World-space centre of a footprint's ground diamond, in board coords.
  Vector2 footprintCenter({
    required int col,
    required int row,
    required int width,
    required int height,
  }) {
    final (nx, ny) = grid.centerOf(col, row);
    final (sx, sy) = grid.centerOf(col + width - 1, row + height - 1);
    final (ex, _) = grid.centerOf(col + width - 1, row);
    final (wx, _) = grid.centerOf(col, row + height - 1);
    return Vector2((wx + ex) / 2, (ny + sy) / 2);
  }

  /// Viewport pixels covered by the bottom bar the screen draws over the
  /// game. The game widget keeps one size whatever the bar does (so the
  /// camera never jumps when the bar changes height); framing and the
  /// scroll clamp treat the area above the bar as the screen.
  double bottomInset = 0;

  /// Tweens the camera so the footprint at `(col, row)` of `width × height`
  /// tiles spans [widthFraction] of the viewport width and sits at viewport
  /// fraction `(0.5, anchorY)`. The first focus remembers the camera so
  /// [releaseFocus] can put it back.
  void focusOnFootprint({
    required int col,
    required int row,
    required int width,
    required int height,
    required double anchorY,
    required double widthFraction,
    Duration duration = const Duration(milliseconds: 650),
    VoidCallback? onDone,
  }) {
    final viewport = _viewport ?? size;
    if (!isFocused) {
      _restorePos = camera.viewfinder.position.clone();
      _restoreZoom = camera.viewfinder.zoom;
    }
    final target = footprintCenter(
      col: col,
      row: row,
      width: width,
      height: height,
    );
    // A w×h footprint's ground diamond is (w + h) half-tiles wide; buildings
    // rise above it, so frame a little wider than the diamond alone.
    final contentWidth = (width + height) * grid.tileWidth / 2 * 1.3;
    final zoom = zoomToFit(
      contentWidth: contentWidth,
      viewportWidth: viewport.x,
      fraction: widthFraction,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
    final (cx, cy) = cameraCenterFor(
      targetX: target.x,
      targetY: target.y,
      zoom: zoom,
      viewportWidth: viewport.x,
      viewportHeight: viewport.y,
      anchorX: 0.5,
      anchorY: anchorY,
      bottomInset: bottomInset,
    );
    _startTween(Vector2(cx, cy), zoom, duration, onDone);
  }

  /// Tweens the camera back to where it was before [focusOnFootprint].
  /// No-op (calls [onDone] at once) when not focused.
  void releaseFocus({
    Duration duration = const Duration(milliseconds: 650),
    VoidCallback? onDone,
  }) {
    final restore = _restorePos;
    if (restore == null) {
      onDone?.call();
      return;
    }
    final zoom = _restoreZoom;
    _restorePos = null;
    _startTween(restore, zoom, duration, () {
      _clampCamera();
      onDone?.call();
    });
  }

  void _startTween(
    Vector2 toPos,
    double toZoom,
    Duration duration,
    VoidCallback? onDone,
  ) {
    _tweenFromPos = camera.viewfinder.position.clone();
    _tweenFromZoom = camera.viewfinder.zoom;
    _tweenToPos = toPos;
    _tweenToZoom = toZoom;
    _tweenElapsed = 0;
    _tweenDuration = duration.inMicroseconds / 1e6;
    _tweenDone = onDone;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final to = _tweenToPos;
    if (to == null) return;
    _tweenElapsed += dt;
    final t = _tweenDuration <= 0
        ? 1.0
        : (_tweenElapsed / _tweenDuration).clamp(0.0, 1.0);
    final k = easeInOut(t);
    camera.viewfinder
      ..position = _tweenFromPos + (to - _tweenFromPos) * k
      ..zoom = _tweenFromZoom + (_tweenToZoom - _tweenFromZoom) * k;
    if (t >= 1) {
      _tweenToPos = null;
      final done = _tweenDone;
      _tweenDone = null;
      done?.call();
    }
  }

  /// Most-recent placements pushed before [onLoad] ran. Applied to the board
  /// once it exists. Without this, the first `setBuildings` after a fresh
  /// city-screen mount is silently dropped (the board is `late` and not yet
  /// constructed), and the city looks empty until something triggers a
  /// rebuild that re-pushes the same data.
  List<PlacedBuildingView>? _pendingBuildings;

  /// Road tiles pushed before [onLoad] ran — applied once the board exists.
  /// Same buffering rationale as [_pendingBuildings].
  Set<(int, int)>? _pendingRoads;

  /// Owned / buyable land tiles (window-local) pushed before [onLoad] ran —
  /// applied once the board exists. Same buffering rationale as above.
  Set<(int, int)>? _pendingOwned;
  Set<(int, int)>? _pendingBuyable;
  Set<(int, int)>? _pendingBuying;
  Set<(int, int)>? _pendingLandSites;
  Set<(int, int)>? _pendingSelectedLandSite;

  /// Building sprites live under `assets/buildings/`, outside Flame's default
  /// `assets/images/` image cache, so they get their own cache + prefix.
  final Images _buildingImages = Images(prefix: 'assets/buildings/');
  final Map<String, Sprite> _sprites = <String, Sprite>{};
  final Set<String> _loadingSprites = <String>{};

  /// The loaded sprite for `<id>_v<n>.png`, or null if it isn't loaded yet.
  /// Read synchronously by the board during render.
  Sprite? spriteFor(String assetPath) => _sprites[assetPath];

  /// Kicks off async loads for any referenced sprite we don't have cached.
  /// Each completed load lands in [_sprites]; Flame re-renders every frame, so
  /// the building swaps from box placeholder to sprite as soon as it arrives.
  void _ensureSpritesLoaded(Iterable<String> assetPaths) {
    for (final path in assetPaths) {
      if (_sprites.containsKey(path) || !_loadingSprites.add(path)) continue;
      unawaited(
        Sprite.load(path, images: _buildingImages)
            .then((sprite) {
              _sprites[path] = sprite;
              _loadingSprites.remove(path);
            })
            .catchError((Object _) {
              // Missing/corrupt asset: drop the in-flight marker so a later
              // frame can retry, and leave the box placeholder showing.
              _loadingSprites.remove(path);
            }),
      );
    }
  }

  @override
  Future<void> onLoad() async {
    board = CityBoardComponent(
      grid: grid,
      onTileTapped: onTileTapped,
      spriteFor: spriteFor,
    );
    if (_pendingBuildings != null) board.buildings = _pendingBuildings!;
    if (_pendingRoads != null) board.roads = _pendingRoads!;
    if (_pendingOwned != null) board.ownedTiles = _pendingOwned!;
    if (_pendingBuyable != null) board.buyableTiles = _pendingBuyable!;
    if (_pendingBuying != null) board.buyingTiles = _pendingBuying!;
    if (_pendingLandSites != null) board.landSiteTiles = _pendingLandSites!;
    if (_pendingSelectedLandSite != null) {
      board.selectedLandSiteTiles = _pendingSelectedLandSite!;
    }
    await world.add(board);
    camera.viewfinder.position = _boardCenter;
    _maybeFit();
  }

  Vector2 get _boardCenter =>
      Vector2(grid.boardWidth / 2, grid.boardHeight / 2);

  /// Viewport size from the latest [onGameResize]; null until the first
  /// non-zero layout pass. The one-time initial fit needs both this and a
  /// loaded board (with buffered buildings applied), which can arrive in
  /// either order — hence [_maybeFit].
  Vector2? _viewport;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0 && size.y > 0) {
      _viewport = size;
      _maybeFit();
    }
  }

  void _maybeFit() {
    if (_fitted || !isLoaded || _viewport == null) return;
    _fitCamera(_viewport!);
    _fitted = true;
  }

  /// Initial camera framing. We start zoomed in to ~1/3 of the
  /// fit-the-whole-board distance ([initialZoomInFactor]× its zoom), centred on
  /// the placed buildings — close enough to feel inviting rather than a distant
  /// overview. Exception: if the buildings are spread too wide to fit at that
  /// zoom, back off just enough to frame them all (never farther than the
  /// whole-board fit). A fresh, empty city has nothing to frame, so it uses the
  /// board centre at the zoomed-in distance.
  void _fitCamera(Vector2 fullViewport) {
    // Fit into the part of the viewport the bottom bar leaves visible, then
    // shift the centre down so the framing is centred in that part.
    final viewport = Vector2(fullViewport.x, fullViewport.y - bottomInset);
    final boardFitZoom = math.min(
      viewport.x / (grid.boardWidth + grid.tileWidth),
      viewport.y / (grid.boardHeight + grid.tileWidth),
    );
    final closeZoom = boardFitZoom * initialZoomInFactor;

    final buildings = board.buildings;
    double zoom;
    Vector2 center;
    if (buildings.isEmpty) {
      zoom = closeZoom;
      center = _boardCenter;
    } else {
      var minX = double.infinity;
      var minY = double.infinity;
      var maxX = double.negativeInfinity;
      var maxY = double.negativeInfinity;
      for (final b in buildings) {
        final (cx, cy) = grid.centerOf(b.col, b.row);
        minX = math.min(minX, cx);
        minY = math.min(minY, cy);
        maxX = math.max(maxX, cx);
        maxY = math.max(maxY, cy);
      }
      // Pad by a tile so edge buildings aren't clipped against the viewport.
      final pad = grid.tileWidth;
      final contentFitZoom = math.min(
        viewport.x / ((maxX - minX) + 2 * pad),
        viewport.y / ((maxY - minY) + 2 * pad),
      );
      zoom = math.min(closeZoom, contentFitZoom);
      center = Vector2((minX + maxX) / 2, (minY + maxY) / 2);
    }
    final z = zoom.clamp(minZoom, maxZoom);
    camera.viewfinder
      ..zoom = z
      ..position = center + Vector2(0, bottomInset / 2 / z);
  }

  /// Absolute zoom setter, clamped. Called from the pinch-zoom Listener.
  /// Ignored while focused on a footprint.
  void setZoom(double zoom) {
    if (isFocused) return;
    camera.viewfinder.zoom = zoom.clamp(minZoom, maxZoom);
  }

  /// Pushes the latest placement set into the rendered board. Buffered if
  /// called before [onLoad] finishes — see [_pendingBuildings].
  void setBuildings(List<PlacedBuildingView> buildings) {
    _ensureSpritesLoaded(
      buildings.map((b) => b.assetPath).whereType<String>(),
    );
    if (isLoaded) {
      board.buildings = buildings;
    } else {
      _pendingBuildings = buildings;
    }
  }

  /// Pushes the latest auto-generated road tiles into the board. Buffered if
  /// called before [onLoad] finishes — see [_pendingRoads].
  void setRoads(Set<(int, int)> roads) {
    if (roads.isNotEmpty) {
      _ensureSpritesLoaded(RoadSpriteShape.values.map((s) => s.fileName));
    }
    if (isLoaded) {
      board.roads = roads;
    } else {
      _pendingRoads = roads;
    }
  }

  /// Pushes the latest land window into the board: the owned + buyable tile
  /// sets (window-local) and, when the window grew, a larger [newGrid]. Growing
  /// the window moves the local origin, so [cameraOffsetDeltaPx] is the screen
  /// shift of any fixed world tile; adding it to the viewfinder keeps the view
  /// visually put (no jump). Buffered before [onLoad]; the one-time initial fit
  /// frames the start, so the delta is irrelevant then.
  void updateLand({
    required IsoGrid newGrid,
    required Set<(int, int)> ownedLocalTiles,
    required Set<(int, int)> buyableLocalTiles,
    required Vector2 cameraOffsetDeltaPx,
  }) {
    grid = newGrid;
    if (isLoaded) {
      board
        ..grid = newGrid
        ..size = Vector2(newGrid.boardWidth, newGrid.boardHeight)
        ..ownedTiles = ownedLocalTiles
        ..buyableTiles = buyableLocalTiles;
      if (!cameraOffsetDeltaPx.isZero()) {
        camera.viewfinder.position += cameraOffsetDeltaPx;
        _clampCamera();
        // The same shift in tiles keeps the crowd where it was on screen:
        // a local-origin move of (dCol, dRow) shows up on screen as
        // ((dCol - dRow)·halfW, (dCol + dRow)·halfH).
        final hw = newGrid.tileWidth / 2;
        final hh = newGrid.tileWidth / 4;
        final a = cameraOffsetDeltaPx.x / hw;
        final b = cameraOffsetDeltaPx.y / hh;
        board.pedestrians.shift(((a + b) / 2).round(), ((b - a) / 2).round());
      }
    } else {
      _pendingOwned = ownedLocalTiles;
      _pendingBuyable = buyableLocalTiles;
    }
  }

  /// Pushes the tiles (window-local) of the frontier block currently selected
  /// for purchase — empty when none. Buffered before [onLoad] like the rest of
  /// the land sets.
  void setBuyingTiles(Set<(int, int)> tiles) {
    if (isLoaded) {
      board.buyingTiles = tiles;
    } else {
      _pendingBuying = tiles;
    }
  }

  /// Pushes the tiles (window-local) of every land block with an open
  /// construction site, and the subset belonging to the selected site.
  /// Buffered before [onLoad] like the rest of the land sets.
  void setLandSiteTiles({
    required Set<(int, int)> all,
    required Set<(int, int)> selected,
  }) {
    if (isLoaded) {
      board
        ..landSiteTiles = all
        ..selectedLandSiteTiles = selected;
    } else {
      _pendingLandSites = all;
      _pendingSelectedLandSite = selected;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (pinchActive || isFocused) return;
    // localDelta is in screen pixels; divide by zoom to get world units.
    // Pan the camera opposite the finger so content follows the drag.
    final zoom = camera.viewfinder.zoom;
    camera.viewfinder.position =
        camera.viewfinder.position - event.localDelta / zoom;
    _clampCamera();
  }

  void _clampCamera() {
    final p = camera.viewfinder.position;
    final margin = grid.tileWidth;
    // The bar covers the bottom of the viewport, so let the camera go that
    // much further down and the board's bottom edge can still be reached.
    final under = bottomInset / camera.viewfinder.zoom;
    camera.viewfinder.position = Vector2(
      p.x.clamp(-margin, grid.boardWidth + margin),
      p.y.clamp(-margin, grid.boardHeight + margin + under),
    );
  }
}
