import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The game's coin, painted rather than drawn from an emoji or a photo: a
/// gold disc with a rim and a stamped star. Deliberately *un*-currency-like:
/// it is no country's money, so word problems can price things in coins.
class CoinIcon extends StatelessWidget {
  const CoinIcon({this.size = 20, super.key});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _CoinPainter());
}

/// Coin icon followed by an amount, for balances and payouts.
class CoinAmount extends StatelessWidget {
  const CoinAmount({
    required this.amount,
    this.iconSize = 20,
    this.style,
    this.prefix = '',
    super.key,
  });

  final int amount;
  final double iconSize;
  final TextStyle? style;

  /// Text before the number, e.g. `'+'` for a payout.
  final String prefix;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CoinIcon(size: iconSize),
      SizedBox(width: iconSize * 0.25),
      Text('$prefix$amount', style: style),
    ],
  );
}

/// A coin glyph for use inside running text (`Text.rich`), sized to the
/// surrounding font.
InlineSpan coinSpan({double size = 16}) => WidgetSpan(
  alignment: PlaceholderAlignment.middle,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 1),
    child: CoinIcon(size: size),
  ),
);

class _CoinPainter extends CustomPainter {
  const _CoinPainter();

  static const _face = Color(0xFFF9D648);
  static const _faceEdge = Color(0xFFE2A81C);
  static const _rim = Color(0xFFB8860B);
  static const _stamp = Color(0xFFC98E14);
  static const _stampLight = Color(0xFFFFF1B3);
  static const _faceGradient = RadialGradient(
    center: Alignment(-0.35, -0.4),
    colors: [_face, _faceEdge],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final faceR = r * 0.84;
    final star = _starPath(c, faceR * 0.62, faceR * 0.26);

    canvas
      // Soft drop shadow so the coin lifts off light surfaces and dark
      // AppBars alike, then the darker gold rim.
      ..drawCircle(
        c.translate(0, r * 0.06),
        r,
        Paint()..color = Colors.black.withValues(alpha: 0.18),
      )
      ..drawCircle(c, r, Paint()..color = _rim)
      // Face: radial gradient, lighter in the upper-left.
      ..drawCircle(
        c,
        faceR,
        Paint()
          ..shader = _faceGradient.createShader(
            Rect.fromCircle(center: c, radius: faceR),
          ),
      )
      // Thin inner ring so the face reads as a struck coin, not a dot.
      ..drawCircle(
        c,
        faceR * 0.86,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, r * 0.06)
          ..color = _rim.withValues(alpha: 0.55),
      )
      // Stamped star: a light offset copy under the dark star fakes an
      // embossed edge.
      ..drawPath(
        star.shift(Offset(-r * 0.04, -r * 0.04)),
        Paint()..color = _stampLight,
      )
      ..drawPath(star, Paint()..color = _stamp)
      // Glint.
      ..drawOval(
        Rect.fromCenter(
          center: c.translate(-faceR * 0.42, -faceR * 0.5),
          width: faceR * 0.5,
          height: faceR * 0.22,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.45),
      );
  }

  Path _starPath(Offset center, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_CoinPainter oldDelegate) => false;
}
