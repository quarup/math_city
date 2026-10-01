import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The 3×3 patch of land the launch intro grows around the app icon's house.
///
/// Geometry mirrors `tools/app_icon/build_icon.py`, which draws the tiles:
/// every tile is an SVG in a 108-unit box, half a tile wide is [tileW] units
/// and half a tile tall is [tileH]. The widget lays the nine boxes out in
/// those units scaled by [unit] (dp per unit), with the centre tile's box in
/// the middle of the widget — so scaling the widget about its centre keeps
/// the icon's house where the OS launch screen drew it.
class TilePatch extends StatelessWidget {
  const TilePatch({
    required this.unit,
    required this.pop,
    this.centreClipRadius,
    super.key,
  });

  /// Density-independent pixels per icon unit.
  final double unit;

  /// 0 shows the centre tile alone; 1 has every neighbour popped in, back
  /// row first.
  final Animation<double> pop;

  /// Radius in dp of a circle, centred on the centre tile's box, that clips
  /// that tile. The OS launch screen masks its icon to a circle, so the
  /// first frame clips the same way; growing the radius past the box lets
  /// the tile's corners appear as the neighbours arrive.
  final Animation<double>? centreClipRadius;

  /// Tile art keyed by `assets/images/tiles/<kind>.svg`, `[row][col]`.
  /// Rows run from the back of the patch to the front; the icon's house is
  /// in the middle.
  static const kinds = [
    ['park', 'house_teal', 'grass'],
    ['school', 'house', 'park'],
    ['road', 'road', 'road'],
  ];

  static const double box = 108;
  static const double tileW = 42 * 0.85;
  static const double tileH = tileW / 2;

  /// Widget extent in units: the centre box plus two tile steps each way.
  static const double widthUnits = 2 * (2 * tileW + box / 2);
  static const double heightUnits = 2 * (2 * tileH + box / 2);

  /// How far the patch's lowest point (the front road's soil) sits below the
  /// centre box's middle, in units. Lets the home screen park the patch by
  /// its bottom edge.
  static const double bottomUnits =
      2 * tileH + (61.225 - 54) + tileH + 0.25 * 36 * 0.85;

  /// The ground centre of a tile inside its box, as a scale alignment.
  static const _groundAlignment = Alignment(0, (61.225 - 54) / 54);

  static const int _neighbourCount = 8;

  /// Neighbour boxes back to front: `(row, col, popIndex)`.
  static List<(int, int, int)> get _order {
    final cells =
        <(int, int)>[
          for (var r = 0; r < 3; r++)
            for (var c = 0; c < 3; c++)
              if (!(r == 1 && c == 1)) (r, c),
        ]..sort((a, b) {
          final d = (a.$1 + a.$2).compareTo(b.$1 + b.$2);
          return d != 0 ? d : a.$1.compareTo(b.$1);
        });
    return [
      for (var i = 0; i < cells.length; i++) (cells[i].$1, cells[i].$2, i),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final width = widthUnits * unit;
    final height = heightUnits * unit;
    final side = box * unit;

    Widget tile(int row, int col, {int? popIndex}) {
      final dx = ((row - 1) - (col - 1)) * tileW * unit;
      final dy = ((row - 1) + (col - 1)) * tileH * unit;
      Widget art = SvgPicture.asset(
        'assets/images/tiles/${kinds[row][col]}.svg',
        width: side,
        height: side,
      );
      final clip = centreClipRadius;
      if (popIndex == null && clip != null) {
        art = AnimatedBuilder(
          animation: clip,
          builder: (context, child) =>
              ClipPath(clipper: _CircleClipper(clip.value), child: child),
          child: art,
        );
      }
      if (popIndex != null) {
        // Each neighbour takes half the pop window; starts are staggered so
        // the last one begins as the first half is done.
        final start = popIndex / _neighbourCount * 0.5;
        art = ScaleTransition(
          scale: CurvedAnimation(
            parent: pop,
            curve: Interval(start, start + 0.5, curve: Curves.easeOutBack),
          ),
          alignment: _groundAlignment,
          child: art,
        );
      }
      return Positioned(
        left: width / 2 + dx - side / 2,
        top: height / 2 + dy - side / 2,
        width: side,
        height: side,
        child: art,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (row, col, index) in _order)
            if (row + col < 2) tile(row, col, popIndex: index),
          tile(1, 1),
          for (final (row, col, index) in _order)
            if (row + col >= 2) tile(row, col, popIndex: index),
        ],
      ),
    );
  }
}

class _CircleClipper extends CustomClipper<Path> {
  const _CircleClipper(this.radius);

  final double radius;

  @override
  Path getClip(Size size) => Path()
    ..addOval(
      Rect.fromCircle(center: size.center(Offset.zero), radius: radius),
    );

  @override
  bool shouldReclip(_CircleClipper oldClipper) => oldClipper.radius != radius;
}
