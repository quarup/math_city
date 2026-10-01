import 'dart:ui';

import 'package:math_city/domain/city/terrain.dart';

/// Paints one piece of countryside decor (city_builder.md §11, the X11
/// ground) at a tile centre. Everything is drawn in code at the mocks'
/// 64 px tile and scaled to the live tile width, so no sprite sheet is
/// needed for trees, bushes, flowers and rocks.
void paintDecor(
  Canvas canvas,
  DecorItem item,
  Offset tileCenter,
  double tileWidth,
) {
  final k = tileWidth / 64;
  final x = tileCenter.dx + item.dx * tileWidth;
  final y = tileCenter.dy + item.dy * tileWidth;
  final s = item.scale * k;
  final fill = Paint();
  switch (item.kind) {
    case DecorKind.tree:
      final greens = _treeGreens[item.variant];
      fill.color = const Color(0x2E000000);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + 2 * k, y + 1 * k),
          width: 18 * s,
          height: 8 * s,
        ),
        fill,
      );
      fill.color = const Color(0xFF6D4C2B);
      canvas.drawRect(
        Rect.fromLTWH(x - 1.5 * s, y - 10 * s, 3 * s, 10 * s),
        fill,
      );
      fill.color = greens.$1;
      canvas.drawCircle(Offset(x, y - 15 * s), 9 * s, fill);
      fill.color = greens.$2;
      canvas
        ..drawCircle(Offset(x - 3 * s, y - 18 * s), 6.5 * s, fill)
        ..drawCircle(Offset(x + 4 * s, y - 13 * s), 5.5 * s, fill);
    case DecorKind.bush:
      fill.color = const Color(0xFF5E9A34);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y - 3 * s),
          width: 16 * s,
          height: 10 * s,
        ),
        fill,
      );
      fill.color = const Color(0xFF74B444);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - 2 * s, y - 5 * s),
          width: 8 * s,
          height: 6 * s,
        ),
        fill,
      );
    case DecorKind.flowers:
      final colors = _bloomColors[item.variant];
      for (var i = 0; i < 4; i++) {
        fill.color = colors[i % 2];
        canvas.drawCircle(
          Offset(x + (i - 1.5) * 5 * k, y + (-2 + (i * 7) % 3 - 1) * k),
          1.6 * k,
          fill,
        );
      }
    case DecorKind.rock:
      fill.color = const Color(0xFF9E9E9E);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y - 2 * s),
          width: 12 * s,
          height: 8 * s,
        ),
        fill,
      );
      fill.color = const Color(0xFFBDBDBD);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - 1.5 * s, y - 3.5 * s),
          width: 6 * s,
          height: 3.6 * s,
        ),
        fill,
      );
  }
}

const _treeGreens = <(Color, Color)>[
  (Color(0xFF4E8A2E), Color(0xFF6BAF3F)),
  (Color(0xFF3F7A2A), Color(0xFF5A9E38)),
  (Color(0xFF5B9432), Color(0xFF7BBE48)),
];

const _bloomColors = <List<Color>>[
  [Color(0xFFF48FB1), Color(0xFFFFF176)],
  [Color(0xFFFFFFFF), Color(0xFFFFD54F)],
  [Color(0xFFCE93D8), Color(0xFFFFF176)],
];
