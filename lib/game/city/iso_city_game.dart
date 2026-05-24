import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
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

  @override
  Future<void> onLoad() async {
    board = CityBoardComponent(grid: grid, onTileTapped: onTileTapped);
    if (_pendingBuildings != null) board.buildings = _pendingBuildings!;
    await world.add(board);
    camera.viewfinder.position = _boardCenter;
  }

  Vector2 get _boardCenter =>
      Vector2(grid.boardWidth / 2, grid.boardHeight / 2);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_fitted && size.x > 0 && size.y > 0) {
      _fitToBoard(size);
      _fitted = true;
    }
  }

  void _fitToBoard(Vector2 viewport) {
    final zx = viewport.x / (grid.boardWidth + grid.tileWidth);
    final zy = viewport.y / (grid.boardHeight + grid.tileWidth);
    camera.viewfinder
      ..zoom = math.min(zx, zy).clamp(minZoom, maxZoom)
      ..position = _boardCenter;
  }

  /// Absolute zoom setter, clamped. Called from the pinch-zoom Listener.
  void setZoom(double zoom) {
    camera.viewfinder.zoom = zoom.clamp(minZoom, maxZoom);
  }

  /// Pushes the latest placement set into the rendered board. Buffered if
  /// called before [onLoad] finishes — see [_pendingBuildings].
  void setBuildings(List<PlacedBuildingView> buildings) {
    if (isLoaded) {
      board.buildings = buildings;
    } else {
      _pendingBuildings = buildings;
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
