import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Icon ladders for the spin wheel: one object per curriculum category,
/// drawn three ways so it grows more sophisticated with the concept's grade
/// band (K–2, 3–5, 6–8). Every icon is painted into a 100×100 box in the
/// flat, dark-outlined style of the logo; the caller scales and positions.
///
/// Kept as plain `Canvas` drawing (no widgets) so both the Flame wheel and
/// any future Flutter badge can share it.

/// Grade band → ladder tier. K–2 → 0, 3–5 → 1, 6–8 → 2.
int tierForGrade(int primaryGrade) {
  if (primaryGrade <= 2) return 0;
  if (primaryGrade <= 5) return 1;
  return 2;
}

/// Paints the icon for [categoryId] at [tier] into the 100×100 box at the
/// canvas origin. [accent] is the category tint; [ink] and [paper] are the
/// outline and the white fill.
void paintConceptIcon(
  Canvas canvas,
  String categoryId,
  int tier, {
  required Color accent,
  Color ink = const Color(0xFF1E2A32),
  Color paper = Colors.white,
}) {
  final p = _Pen(canvas, ink: ink, paper: paper, accent: accent);
  final ladder = _ladders[categoryId];
  if (ladder == null) {
    _fallback(p);
    return;
  }
  ladder[tier.clamp(0, 2)](p);
}

const _ladders = <String, List<void Function(_Pen)>>{
  'counting': [_counting0, _counting1, _counting2],
  'place_value': [_placeValue0, _placeValue1, _placeValue2],
  'add_sub': [_addSub0, _addSub1, _addSub2],
  'mult_div': [_multDiv0, _multDiv1, _multDiv2],
  'fractions': [_fractions0, _fractions1, _fractions2],
  'decimals_percent': [_decimals0, _decimals1, _decimals2],
  'ratios': [_ratios0, _ratios1, _ratios2],
  'measurement': [_measurement0, _measurement1, _measurement2],
  'geometry': [_geometry0, _geometry1, _geometry2],
  'rationals': [_rationals0, _rationals1, _rationals2],
  'prealgebra': [_prealgebra0, _prealgebra1, _prealgebra2],
  'stats': [_stats0, _stats1, _stats2],
};

// ---------------------------------------------------------------------------
// Drawing helpers
// ---------------------------------------------------------------------------

enum _Anchor { start, center, end }

class _Pen {
  _Pen(this.c, {required this.ink, required this.paper, required this.accent});

  final Canvas c;
  final Color ink;
  final Color paper;
  final Color accent;

  /// Base stroke width in the 100-box.
  static const double sw = 5;

  Paint stroke([double w = sw, Color? color]) => Paint()
    ..color = color ?? ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint fill(Color color) => Paint()..color = color;

  /// Fill then outline, like `fill="…" stroke="ink"` in the mock SVGs.
  void shape(Path path, Color fillColor, [double w = sw]) {
    c
      ..drawPath(path, fill(fillColor))
      ..drawPath(path, stroke(w));
  }

  void circle(
    double cx,
    double cy,
    double r,
    Color fillColor, [
    double w = sw,
  ]) {
    c
      ..drawCircle(Offset(cx, cy), r, fill(fillColor))
      ..drawCircle(Offset(cx, cy), r, stroke(w));
  }

  void rect(
    double x,
    double y,
    double w,
    double h,
    double rx,
    Color fillColor, [
    double sw = _Pen.sw,
  ]) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      Radius.circular(rx),
    );
    c
      ..drawRRect(rr, fill(fillColor))
      ..drawRRect(rr, stroke(sw));
  }

  void line(double x1, double y1, double x2, double y2, [Paint? paint]) =>
      c.drawLine(Offset(x1, y1), Offset(x2, y2), paint ?? stroke());

  void dashed(
    double x1,
    double y1,
    double x2,
    double y2, {
    double dash = 4,
    double gap = 3,
    Paint? paint,
  }) {
    final total = (Offset(x2, y2) - Offset(x1, y1)).distance;
    final dir = (Offset(x2, y2) - Offset(x1, y1)) / total;
    var t = 0.0;
    final pt = paint ?? stroke();
    while (t < total) {
      final end = math.min(t + dash, total);
      c.drawLine(
        Offset(x1, y1) + dir * t,
        Offset(x1, y1) + dir * end,
        pt,
      );
      t += dash + gap;
    }
  }

  void dots(List<Offset> pts, double r, [Color? fillColor]) {
    for (final o in pts) {
      circle(o.dx, o.dy, r, fillColor ?? accent);
    }
  }

  /// Text in the 100-box. [central] centres vertically on [y]; otherwise
  /// [y] is the alphabetic baseline (matching the SVG mocks).
  void text(
    double x,
    double y,
    String s, {
    double size = 22,
    Color? color,
    _Anchor anchor = _Anchor.center,
    bool central = true,
    Color? outline,
    double outlineWidth = 0,
  }) {
    TextPainter make(Paint? fg) => TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: fg == null ? (color ?? ink) : null,
          foreground: fg,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tp = make(null);
    final dx = switch (anchor) {
      _Anchor.start => x,
      _Anchor.center => x - tp.width / 2,
      _Anchor.end => x - tp.width,
    };
    final baseline = tp.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final dy = central ? y - tp.height / 2 : y - baseline;
    if (outline != null && outlineWidth > 0) {
      make(
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = outlineWidth
          ..strokeJoin = StrokeJoin.round
          ..color = outline,
      ).paint(c, Offset(dx, dy));
    }
    tp.paint(c, Offset(dx, dy));
  }
}

Offset _pol(double cx, double cy, double r, double a) =>
    Offset(cx + r * math.cos(a), cy + r * math.sin(a));

/// Gear outline with [n] teeth, as in the logo.
Path _gearPath(double cx, double cy, double r, int n, {double ratio = 0.72}) {
  final ro = r;
  final ri = r * ratio;
  final path = Path();
  for (var i = 0; i < n; i++) {
    final a = i * 2 * math.pi / n;
    final w = math.pi / n * 0.42;
    final p1 = _pol(cx, cy, ri, a - w * 1.15);
    final p2 = _pol(cx, cy, ro, a - w * 0.6);
    final p3 = _pol(cx, cy, ro, a + w * 0.6);
    final p4 = _pol(cx, cy, ri, a + w * 1.15);
    if (i == 0) {
      path.moveTo(p1.dx, p1.dy);
    } else {
      path.lineTo(p1.dx, p1.dy);
    }
    path
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy);
    final nx = _pol(cx, cy, ri, a + 2 * math.pi / n - w * 1.15);
    path.arcToPoint(nx, radius: Radius.circular(ri));
  }
  return path..close();
}

void _gear(_Pen p, double cx, double cy, double r, int n, Color fill) {
  p.shape(_gearPath(cx, cy, r, n), fill);
  p.c.drawCircle(Offset(cx, cy), r * 0.28, p.stroke());
}

void _axes(_Pen p) {
  p
    ..line(12, 82, 92, 82)
    ..line(20, 90, 20, 12);
  final thin = p.stroke(_Pen.sw * .3);
  for (var i = 1; i < 6; i++) {
    p
      ..line(20 + i * 13, 12, 20 + i * 13, 82, thin)
      ..line(20, 82 - i * 13, 92, 82 - i * 13, thin);
  }
}

void _fallback(_Pen p) {
  p
    ..circle(50, 50, 30, p.accent)
    ..text(50, 50, '?', size: 34, color: p.paper);
}

// ---------------------------------------------------------------------------
// Counting: dots → ten-frame → number line with hops
// ---------------------------------------------------------------------------

void _counting0(_Pen p) {
  p
    ..circle(22, 50, 14, p.accent)
    ..circle(50, 50, 14, p.accent)
    ..circle(78, 50, 14, p.accent);
}

void _counting1(_Pen p) {
  p.rect(8, 30, 84, 40, 4, p.paper);
  for (var i = 1; i < 5; i++) {
    p.line(8 + i * 16.8, 30, 8 + i * 16.8, 70);
  }
  p.line(8, 50, 92, 50);
  final pts = <Offset>[];
  for (var k = 0; k < 7; k++) {
    pts.add(Offset(16.4 + (k % 5) * 16.8, 40 + (k >= 5 ? 20 : 0)));
  }
  p.dots(pts, 5.5);
}

void _counting2(_Pen p) {
  p.line(6, 66, 94, 66);
  for (var i = 0; i < 6; i++) {
    p.line(12 + i * 14.0, 60, 12 + i * 14.0, 72);
  }
  final hop = p.stroke(_Pen.sw, p.accent);
  for (final x in [12.0, 40.0, 68.0]) {
    p.c.drawPath(
      Path()
        ..moveTo(x, 58)
        ..quadraticBezierTo(x + 14, 30, x + 28, 58),
      hop,
    );
  }
  p
    ..text(12, 86, '0', size: 16)
    ..text(96, 86, '6', size: 16);
}

// ---------------------------------------------------------------------------
// Place value: unit cube → rod + units → flat + rod + units
// ---------------------------------------------------------------------------

void _placeValue0(_Pen p) {
  p.shape(
    Path()
      ..moveTo(30, 38)
      ..relativeLineTo(14, -12)
      ..relativeLineTo(30, 0)
      ..relativeLineTo(0, 34)
      ..relativeLineTo(-14, 12)
      ..relativeLineTo(-30, 0)
      ..close(),
    p.accent,
  );
  p.c.drawPath(
    Path()
      ..moveTo(30, 38)
      ..relativeLineTo(30, 0)
      ..relativeLineTo(0, 34)
      ..moveTo(60, 38)
      ..relativeLineTo(14, -12),
    p.stroke(),
  );
}

void _placeValue1(_Pen p) {
  p.rect(22, 12, 16, 76, 0, p.accent);
  final thin = p.stroke(_Pen.sw * .6);
  for (var i = 1; i < 10; i++) {
    p.line(22, 12 + i * 7.6, 38, 12 + i * 7.6, thin);
  }
  p
    ..rect(52, 56, 16, 16, 0, p.paper)
    ..rect(52, 30, 16, 16, 0, p.paper);
}

void _placeValue2(_Pen p) {
  p.rect(8, 14, 52, 52, 0, p.accent);
  final thin = p.stroke(_Pen.sw * .5);
  for (var i = 1; i < 5; i++) {
    p
      ..line(8 + i * 10.4, 14, 8 + i * 10.4, 66, thin)
      ..line(8, 14 + i * 10.4, 60, 14 + i * 10.4, thin);
  }
  p
    ..rect(68, 14, 12, 52, 0, p.paper)
    ..rect(68, 74, 12, 12, 0, p.paper)
    ..rect(8, 74, 52, 12, 0, p.paper);
}

// ---------------------------------------------------------------------------
// Add & subtract: plus → mixed sum → column addition with a carry
// ---------------------------------------------------------------------------

Path _plus(double x, double y, double arm, double t) => Path()
  ..moveTo(x - t / 2, y - arm)
  ..relativeLineTo(t, 0)
  ..relativeLineTo(0, arm - t / 2)
  ..relativeLineTo(arm - t / 2, 0)
  ..relativeLineTo(0, t)
  ..relativeLineTo(-(arm - t / 2), 0)
  ..relativeLineTo(0, arm - t / 2)
  ..relativeLineTo(-t, 0)
  ..relativeLineTo(0, -(arm - t / 2))
  ..relativeLineTo(-(arm - t / 2), 0)
  ..relativeLineTo(0, -t)
  ..relativeLineTo(arm - t / 2, 0)
  ..close();

void _addSub0(_Pen p) => p.shape(_plus(50, 50, 38, 14), p.accent);

void _addSub1(_Pen p) {
  p
    ..shape(_plus(33, 51, 15, 10), p.accent)
    ..rect(60, 41, 30, 10, 2, p.accent)
    ..rect(18, 70, 64, 14, 4, p.paper)
    ..text(50, 77, '7 + 5 − 3', size: 14);
}

void _addSub2(_Pen p) {
  p
    ..text(82, 38, '248', size: 20, anchor: _Anchor.end, central: false)
    ..text(82, 60, '+ 175', size: 20, anchor: _Anchor.end, central: false)
    ..line(28, 66, 86, 66)
    ..text(
      82,
      86,
      '423',
      size: 20,
      anchor: _Anchor.end,
      central: false,
      color: p.accent,
      outline: p.ink,
      outlineWidth: 1.2,
    )
    ..text(
      54,
      20,
      '1',
      size: 12,
      anchor: _Anchor.start,
      central: false,
      color: p.accent,
      outline: p.ink,
      outlineWidth: 0.9,
    );
}

// ---------------------------------------------------------------------------
// Multiply & divide: times sign → array → long division
// ---------------------------------------------------------------------------

void _multDiv0(_Pen p) {
  final thick = p.stroke(_Pen.sw * 3.2);
  final core = p.stroke(_Pen.sw * 1.6, p.accent);
  p
    ..line(26, 26, 74, 74, thick)
    ..line(74, 26, 26, 74, thick)
    ..line(26, 26, 74, 74, core)
    ..line(74, 26, 26, 74, core);
}

void _multDiv1(_Pen p) {
  p.rect(10, 12, 80, 56, 6, p.paper);
  final pts = <Offset>[];
  for (var r = 0; r < 3; r++) {
    for (var c = 0; c < 4; c++) {
      pts.add(Offset(23 + c * 18.0, 26 + r * 18.0));
    }
  }
  p
    ..dots(pts, 6)
    ..text(50, 86, '3 × 4', size: 16);
}

void _multDiv2(_Pen p) {
  p.c.drawPath(
    Path()
      ..moveTo(30, 34)
      ..lineTo(30, 80)
      ..moveTo(30, 34)
      ..quadraticBezierTo(36, 32, 90, 34),
    p.stroke(),
  );
  p
    ..text(
      60,
      26,
      '31',
      size: 18,
      central: false,
      color: p.accent,
      outline: p.ink,
      outlineWidth: 1.2,
    )
    ..text(16, 60, '7', size: 16, central: false)
    ..text(60, 58, '217', size: 18, central: false)
    ..line(42, 66, 70, 66)
    ..text(60, 82, '–21', size: 16, central: false);
}

// ---------------------------------------------------------------------------
// Fractions: half → three quarters → unlike denominators
// ---------------------------------------------------------------------------

Path _sector(double cx, double cy, double r, double a0, double a1) => Path()
  ..moveTo(cx, cy)
  ..lineTo(cx + r * math.cos(a0), cy + r * math.sin(a0))
  ..arcTo(
    Rect.fromCircle(center: Offset(cx, cy), radius: r),
    a0,
    a1 - a0,
    false,
  )
  ..close();

void _spokes(_Pen p, double cx, double cy, double r, int n) {
  for (var i = 0; i < n; i++) {
    final a = -math.pi / 2 + i * 2 * math.pi / n;
    p.line(cx, cy, cx + r * math.cos(a), cy + r * math.sin(a));
  }
}

void _fractions0(_Pen p) {
  p
    ..circle(50, 50, 34, p.paper)
    ..shape(_sector(50, 50, 34, -math.pi / 2, math.pi / 2), p.accent);
}

void _fractions1(_Pen p) {
  p
    ..circle(50, 42, 30, p.paper)
    ..shape(_sector(50, 42, 30, -math.pi / 2, math.pi), p.accent);
  _spokes(p, 50, 42, 30, 4);
  p.text(50, 88, '¾');
}

void _fractions2(_Pen p) {
  p
    ..circle(26, 46, 20, p.paper)
    ..shape(_sector(26, 46, 20, -math.pi / 2, -math.pi / 6), p.accent);
  _spokes(p, 26, 46, 20, 6);
  p
    ..line(50, 40, 50, 52)
    ..line(44, 46, 56, 46)
    ..circle(74, 46, 20, p.paper)
    ..shape(_sector(74, 46, 20, -math.pi / 2, 0), p.accent);
  _spokes(p, 74, 46, 20, 4);
  p.text(50, 84, '⅙ + ¼', size: 15);
}

// ---------------------------------------------------------------------------
// Decimals & percent: decimal point → percent sign → price tag conversion
// ---------------------------------------------------------------------------

void _decimals0(_Pen p) {
  p
    ..rect(10, 30, 26, 40, 4, p.paper)
    ..rect(64, 30, 26, 40, 4, p.paper)
    ..circle(50, 66, 7, p.accent)
    ..text(23, 50, '0')
    ..text(77, 50, '5');
}

void _decimals1(_Pen p) {
  p
    ..circle(30, 30, 13, p.accent)
    ..circle(70, 70, 13, p.accent)
    ..line(22, 80, 78, 20, p.stroke(_Pen.sw * 1.8));
}

void _decimals2(_Pen p) {
  p
    ..shape(
    Path()
      ..moveTo(14, 22)
      ..relativeLineTo(44, 0)
      ..relativeLineTo(24, 28)
      ..relativeLineTo(-24, 28)
      ..relativeLineTo(-44, 0)
      ..close(),
    p.accent,
  )
    ..circle(26, 50, 5, p.paper)
    ..text(50, 50, '25%', size: 17, color: p.paper)
    ..line(50, 88, 80, 88)
    ..line(74, 82, 80, 88)
    ..line(80, 88, 74, 94)
    ..text(80, 12, '0.25 = ¼', size: 12, anchor: _Anchor.end, central: false);
}

// ---------------------------------------------------------------------------
// Ratios: balance → bars → gears
// ---------------------------------------------------------------------------

void _ratios0(_Pen p) {
  p
    ..line(50, 20, 50, 78)
    ..line(22, 84, 78, 84)
    ..line(50, 28, 20, 48)
    ..line(50, 28, 80, 48)
    ..shape(
      Path()
        ..moveTo(8, 50)
        ..relativeLineTo(24, 0)
        ..relativeLineTo(-12, -10)
        ..close(),
      p.paper,
    )
    ..shape(
      Path()
        ..moveTo(68, 50)
        ..relativeLineTo(24, 0)
        ..relativeLineTo(-12, -10)
        ..close(),
      p.paper,
    )
    ..dots([const Offset(20, 36)], 4)
    ..dots([const Offset(75, 34), const Offset(85, 36)], 4);
}

void _ratios1(_Pen p) {
  for (final x in [10.0, 36.0, 62.0]) {
    p.rect(x, 26, 24, 16, 3, p.accent);
  }
  for (final x in [10.0, 36.0]) {
    p.rect(x, 56, 24, 16, 3, p.paper);
  }
  p.text(50, 90, '3 : 2', size: 16);
}

void _ratios2(_Pen p) {
  _gear(p, 34, 44, 22, 8, p.accent);
  _gear(p, 72, 58, 14, 6, p.paper);
}

// ---------------------------------------------------------------------------
// Measurement: ruler → ruler + clock → protractor
// ---------------------------------------------------------------------------

void _measurement0(_Pen p) {
  p.rect(8, 36, 84, 28, 4, p.accent);
  for (var i = 1; i < 7; i++) {
    p.line(8 + i * 12.0, 36, 8 + i * 12.0, i % 3 == 0 ? 54 : 46);
  }
}

void _measurement1(_Pen p) {
  p.rect(6, 62, 60, 22, 4, p.accent);
  for (var i = 1; i < 6; i++) {
    p.line(6 + i * 10.0, 62, 6 + i * 10.0, i.isEven ? 76 : 70);
  }
  p
    ..circle(66, 34, 24, p.paper)
    ..line(66, 34, 66, 19)
    ..line(66, 34, 76, 40);
  p.c.drawCircle(const Offset(66, 34), 2.5, p.fill(p.ink));
}

void _measurement2(_Pen p) {
  p
    ..shape(
    Path()
      ..moveTo(10, 72)
      ..arcToPoint(const Offset(90, 72), radius: const Radius.circular(40))
      ..close(),
    p.paper,
  )
    ..line(50, 72, 82, 50, p.stroke(_Pen.sw * 1.4, p.accent));
  p.c.drawPath(
    Path()
      ..moveTo(62, 72)
      ..arcToPoint(
        const Offset(60, 65),
        radius: const Radius.circular(12),
        clockwise: false,
      ),
    p.stroke(),
  );
  final thin = p.stroke(_Pen.sw * .6);
  p.c
    ..drawPath(
      Path()
        ..moveTo(50, 72)
        ..arcToPoint(const Offset(22, 56), radius: const Radius.circular(32)),
      thin,
    )
    ..drawPath(
      Path()
        ..moveTo(50, 72)
        ..arcToPoint(
          const Offset(78, 56),
          radius: const Radius.circular(32),
          clockwise: false,
        ),
      thin,
    );
  p.text(50, 90, '35°', size: 14);
}

// ---------------------------------------------------------------------------
// Geometry: basic shapes → cube → triangle on a grid
// ---------------------------------------------------------------------------

void _geometry0(_Pen p) {
  p
    ..shape(
      Path()
        ..moveTo(30, 20)
        ..lineTo(52, 58)
        ..lineTo(8, 58)
        ..close(),
      p.accent,
    )
    ..circle(72, 30, 16, p.paper)
    ..rect(52, 54, 32, 32, 3, p.paper);
}

void _geometry1(_Pen p) {
  p.shape(
    Path()
      ..moveTo(24, 36)
      ..relativeLineTo(18, -14)
      ..relativeLineTo(36, 0)
      ..relativeLineTo(0, 36)
      ..relativeLineTo(-18, 14)
      ..relativeLineTo(-36, 0)
      ..close(),
    p.paper,
  );
  p.c.drawPath(
    Path()
      ..moveTo(24, 36)
      ..relativeLineTo(36, 0)
      ..relativeLineTo(0, 36)
      ..moveTo(60, 36)
      ..relativeLineTo(18, -14),
    p.stroke(),
  );
  p.rect(24, 36, 36, 36, 0, p.accent);
}

void _geometry2(_Pen p) {
  _axes(p);
  p
    ..shape(
    Path()
      ..moveTo(33, 69)
      ..lineTo(72, 69)
      ..lineTo(59, 30)
      ..close(),
    p.accent,
  )
    ..dots(
    const [Offset(33, 69), Offset(72, 69), Offset(59, 30)],
    3.5,
    p.paper,
  );
}

// ---------------------------------------------------------------------------
// Negative numbers: number line → zero pairs → four quadrants
// ---------------------------------------------------------------------------

void _rationals0(_Pen p) {
  p.line(6, 56, 94, 56);
  for (var i = 0; i < 7; i++) {
    p.line(11 + i * 13.0, 50, 11 + i * 13.0, 62);
  }
  p
    ..rect(14, 20, 30, 20, 4, p.accent)
    ..text(29, 30, '−3', size: 15)
    ..text(50, 80, '0', size: 16)
    ..circle(50, 56, 4, p.paper)
    ..circle(11, 56, 4, p.accent);
}

void _rationals1(_Pen p) {
  const cells = [
    (0, 0, '+'),
    (1, 0, '+'),
    (2, 0, '+'),
    (0, 1, '−'),
    (1, 1, '−'),
    (2, 1, '−'),
    (3, 1, '−'),
    (4, 1, '−'),
  ];
  for (final (c, r, t) in cells) {
    final y = r == 1 ? 54.0 : 24.0;
    p
      ..rect(8 + c * 17.0, y, 15, 18, 3, t == '+' ? p.accent : p.paper)
      ..text(15.5 + c * 17.0, y + 9, t, size: 15);
  }
}

void _rationals2(_Pen p) {
  p
    ..line(8, 50, 92, 50)
    ..line(50, 8, 50, 92);
  final thin = p.stroke(_Pen.sw * .6);
  for (var i = 1; i < 5; i++) {
    p
      ..line(50 + i * 10.0, 47, 50 + i * 10.0, 53, thin)
      ..line(50 - i * 10.0, 47, 50 - i * 10.0, 53, thin)
      ..line(47, 50 + i * 10.0, 53, 50 + i * 10.0, thin)
      ..line(47, 50 - i * 10.0, 53, 50 - i * 10.0, thin);
  }
  p.dots(const [Offset(20, 70), Offset(80, 30), Offset(30, 20)], 5.5);
}

// ---------------------------------------------------------------------------
// Pre-algebra: mystery box → x on a balance → line on a graph
// ---------------------------------------------------------------------------

void _prealgebra0(_Pen p) {
  p
    ..rect(10, 34, 30, 30, 5, p.accent)
    ..text(25, 49, '?', color: p.paper)
    ..text(62, 49, '+ 3', size: 18)
    ..rect(4, 74, 92, 14, 4, p.paper)
    ..text(50, 81, '? + 3 = 8', size: 13);
}

void _prealgebra1(_Pen p) {
  p
    ..line(50, 26, 50, 76)
    ..line(22, 82, 78, 82)
    ..line(18, 40, 82, 40)
    ..rect(14, 24, 20, 14, 3, p.accent)
    ..text(24, 31, 'x', size: 13, color: p.paper)
    ..rect(66, 24, 20, 14, 3, p.paper)
    ..text(76, 31, '5', size: 13)
    ..circle(50, 40, 4, p.accent)
    ..text(50, 94, 'x + 2 = 5', size: 13);
}

void _prealgebra2(_Pen p) {
  _axes(p);
  p
    ..line(20, 74, 88, 22, p.stroke(_Pen.sw * 1.6, p.accent))
    ..dots(const [Offset(33, 64), Offset(59, 44), Offset(85, 24)], 4, p.paper)
    ..text(74, 72, 'y=2x', size: 12);
}

// ---------------------------------------------------------------------------
// Data & stats: two bars → bar chart with mean → scatter with trend
// ---------------------------------------------------------------------------

void _stats0(_Pen p) {
  p
    ..line(10, 82, 90, 82)
    ..rect(22, 44, 22, 38, 3, p.accent)
    ..rect(56, 24, 22, 58, 3, p.paper);
}

void _stats1(_Pen p) {
  p
    ..line(8, 82, 92, 82)
    ..rect(14, 52, 14, 30, 2, p.accent)
    ..rect(34, 30, 14, 52, 2, p.paper)
    ..rect(54, 42, 14, 40, 2, p.accent)
    ..rect(74, 60, 14, 22, 2, p.paper)
    ..dashed(8, 46, 92, 46)
    ..text(50, 18, 'mean', size: 12);
}

void _stats2(_Pen p) {
  p
    ..line(10, 84, 92, 84)
    ..line(14, 88, 14, 12)
    ..dashed(
      18,
      72,
      86,
      26,
      dash: 6,
      gap: 4,
      paint: p.stroke(_Pen.sw * 1.3, p.accent),
    )
    ..dots(
      const [
        Offset(24, 66),
        Offset(34, 58),
        Offset(42, 66),
        Offset(52, 46),
        Offset(60, 52),
        Offset(70, 34),
        Offset(80, 38),
        Offset(86, 24),
      ],
      4.5,
      p.paper,
    );
}
