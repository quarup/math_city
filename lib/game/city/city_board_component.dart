import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:math_city/game/city/iso_grid.dart';

/// Lightweight render model for one placed building. Built by the
/// presentation layer from a `BuildingPlacement` + the building registry, so
/// this component stays ignorant of domain types.
class PlacedBuildingView {
  const PlacedBuildingView({
    required this.col,
    required this.row,
    required this.emoji,
    required this.color,
  });

  final int col;
  final int row;
  final String emoji;
  final Color color;
}

/// Renders the isometric terrain grid plus placeholder extruded-box buildings,
/// and reports tile taps back to the presentation layer. Phase 7 placeholder
/// art per plan.md — colored diamonds + emoji, no PNGs.
class CityBoardComponent extends PositionComponent with TapCallbacks {
  CityBoardComponent({required this.grid, required this.onTileTapped});

  final IsoGrid grid;
  final void Function(int col, int row) onTileTapped;

  /// Current placement render set. Reassigned (cheaply) by the host game
  /// whenever placements change.
  List<PlacedBuildingView> buildings = const [];

  static const _grassFill = Color(0xFF7CB342);
  static const _grassFillAlt = Color(0xFF689F38);
  final _tileStroke = Paint()
    ..color = const Color(0x33000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

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
    // Painter's order: tiles further back (smaller col+row) draw first so
    // nearer buildings overlap them correctly.
    final sorted = [...buildings]
      ..sort((a, b) => (a.col + a.row).compareTo(b.col + b.row));
    for (final b in sorted) {
      _drawBuilding(canvas, b);
    }
  }

  void _drawTile(Canvas canvas, int col, int row) {
    final (cx, cy) = grid.centerOf(col, row);
    final path = _diamond(cx, cy, 0);
    canvas
      ..drawPath(
        path,
        Paint()..color = (col + row).isEven ? _grassFill : _grassFillAlt,
      )
      ..drawPath(path, _tileStroke);
  }

  void _drawBuilding(Canvas canvas, PlacedBuildingView b) {
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
