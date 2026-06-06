import 'dart:async';
import 'dart:math' as math;

import 'package:flame/cache.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
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

  final IsoGrid grid;
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

  /// Most-recent placements pushed before [onLoad] ran. Applied to the board
  /// once it exists. Without this, the first `setBuildings` after a fresh
  /// city-screen mount is silently dropped (the board is `late` and not yet
  /// constructed), and the city looks empty until something triggers a
  /// rebuild that re-pushes the same data.
  List<PlacedBuildingView>? _pendingBuildings;

  /// Road tiles pushed before [onLoad] ran — applied once the board exists.
  /// Same buffering rationale as [_pendingBuildings].
  Set<(int, int)>? _pendingRoads;

  /// Move-mode highlight pushed before [onLoad] ran. The flag distinguishes
  /// "clear the highlight" (null) from "never set", same buffering rationale.
  (int, int)? _pendingHighlight;
  bool _hasPendingHighlight = false;

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
    if (_hasPendingHighlight) board.highlightTile = _pendingHighlight;
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
  void _fitCamera(Vector2 viewport) {
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
    camera.viewfinder
      ..zoom = zoom.clamp(minZoom, maxZoom)
      ..position = center;
  }

  /// Absolute zoom setter, clamped. Called from the pinch-zoom Listener.
  void setZoom(double zoom) {
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
    if (isLoaded) {
      board.roads = roads;
    } else {
      _pendingRoads = roads;
    }
  }

  /// Sets (or clears, with null) the move-mode highlight tile. Buffered if
  /// called before [onLoad] finishes — see [_pendingHighlight].
  void setHighlight((int, int)? tile) {
    if (isLoaded) {
      board.highlightTile = tile;
    } else {
      _pendingHighlight = tile;
      _hasPendingHighlight = true;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (pinchActive) return;
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
    camera.viewfinder.position = Vector2(
      p.x.clamp(-margin, grid.boardWidth + margin),
      p.y.clamp(-margin, grid.boardHeight + margin),
    );
  }
}
