import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:math_city/game/spin_wheel/concept_icons.dart';

/// One segment of the spin wheel.
class WheelSegment {
  const WheelSegment({
    required this.conceptId,
    required this.label,
    required this.categoryId,
    required this.tier,
    required this.color,
    this.isNew = false,
  });

  final String conceptId;

  /// Friendly name revealed when the wheel lands on this segment.
  final String label;

  /// Picks the icon ladder ([paintConceptIcon]).
  final String categoryId;

  /// Rung on the ladder: 0 (K–2), 1 (3–5), 2 (6–8).
  final int tier;

  /// Category tint for the icon accent and the landing reveal. Wedges
  /// themselves take their colour from [SpinWheelComponent.wedgePalette]
  /// by position, so neighbours always contrast.
  final Color color;

  /// The player has never answered a question on this concept — the wedge
  /// carries a curved "NEW!" so a fresh unlock is visible on the wheel.
  final bool isNew;
}

/// Spinning carnival wheel.
///
/// The wheel is drawn once into an image (wedges, icons, NEW tags) and that
/// image is rotated each frame, so a spin costs one image draw — plus a few
/// faint ghost copies trailing the rotation, which is what makes it blur at
/// speed. A fixed striped rim with bulbs, the hub and the pointer are drawn
/// live on top.
///
/// Interaction is driven by the enclosing game:
///   - [rotateBy] applies a drag delta while the user's finger is down.
///   - [startSpinWithVelocity] launches the free spin on release.
class SpinWheelComponent extends PositionComponent {
  SpinWheelComponent({
    required this.segments,
    required this.onLanded,
    required this.wheelCenter,
    required this.radius,
  }) : super(priority: 1);

  final List<WheelSegment> segments;
  final void Function(String conceptId) onLanded;

  /// Wheel centre and wedge radius in game coordinates. Everything else is
  /// sized relative to [radius] (the mocks were drawn at radius 148).
  final Vector2 wheelCenter;
  final double radius;

  static const ink = Color(0xFF1E2A32);
  static const _stripeRed = Color(0xFFE25A5A);
  static const _stripeCream = Color(0xFFFFF4E0);
  static const _bulbBright = Color(0xFFFFF3B0);
  static const _bulbWarm = Color(0xFFFFD54F);
  static const _bulbRim = Color(0xFF7A4A12);
  static const _woodDark = Color(0xFF5A3A12);
  static const _coinGold = Color(0xFFF0CC30);
  static const _newOrange = Color(0xFFF2A33A);
  static const _litAmber = Color(0xFFFFD54F);

  /// Wedge colours by position: brand tints ordered warm/cool so any two
  /// neighbours (including the wrap from last to first) contrast.
  static const wedgePalette = [
    Color(0xFFF2A33A), // orange
    Color(0xFF2EB5A0), // teal
    Color(0xFFE25A5A), // red
    Color(0xFF5DB7E8), // sky
    Color(0xFFF0CC30), // yellow
    Color(0xFFA56BC2), // purple
    Color(0xFFF07A4A), // coral
    Color(0xFF7CC36A), // green
  ];

  /// Icons sit at this fraction of the radius, clear of the wedge edges.
  static const iconRadiusFraction = 0.74;
  static const _newArcFraction = 0.44;
  static const _newFontSize = 15.0;
  static const _ghostCount = 4;
  static const _maxVelocity = 28.0;

  double _rotation = 0;
  double _angularVelocity = 0;
  bool _isSpinning = false;
  bool _hasReported = false;
  bool _willSelect = false;
  int? _landedIndex;

  ui.Image? _wheelImage;
  double _imageScale = 1;
  int? _imageLandedIndex;
  bool _imageDirty = true;

  bool get isSpinning => _isSpinning;
  bool get willSelect => _willSelect;
  int get currentSelectedIndex => _selectedSegmentIndex;

  /// Current angular speed as a fraction of a full throw, for the backdrop.
  double get speedFraction => (_angularVelocity.abs() / _maxVelocity).clamp(
    0.0,
    1.0,
  );

  double get _scale => radius / 148;
  double get _sweep => 2 * math.pi / segments.length;

  /// Outer edge of the striped rim.
  double get rimRadius => radius + 22 * _scale;

  int? get landedIndex => _landedIndex;
  set landedIndex(int index) {
    _landedIndex = index;
    _imageDirty = true;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Park the wheel a little off-centre so the pointer visibly isn't on a
    // segment yet.
    _rotation = -_sweep / 2 + 0.28;
  }

  @override
  void onRemove() {
    _wheelImage?.dispose();
    _wheelImage = null;
    super.onRemove();
  }

  /// Cancel a non-selecting free spin so the player can try again.
  void cancelSpin() {
    _isSpinning = false;
    _angularVelocity = 0;
    _hasReported = true;
  }

  /// Canvas position of the icon for [index] (game coordinates).
  Vector2 labelPositionFor(int index) {
    final midAngle = _rotation + (index + 0.5) * _sweep;
    final r = radius * iconRadiusFraction;
    return Vector2(
      wheelCenter.x + math.cos(midAngle) * r,
      wheelCenter.y + math.sin(midAngle) * r,
    );
  }

  /// Apply an incremental rotation during a drag gesture.
  void rotateBy(double delta) => _rotation += delta;

  /// Begin free-spin deceleration at [angularVelocity] (radians/second).
  /// Positive = clockwise; negative = counter-clockwise. When [selects] is
  /// false the wheel spins freely but does not fire [onLanded] — used for
  /// low-force throws.
  void startSpinWithVelocity(double angularVelocity, {bool selects = true}) {
    _isSpinning = true;
    _hasReported = false;
    _willSelect = selects;
    _landedIndex = null;
    _imageDirty = true;
    _angularVelocity = angularVelocity;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isSpinning) return;

    // Frame-rate-independent exponential decay.
    final effectiveDt = dt.clamp(0.0, 0.1);
    _rotation += _angularVelocity * effectiveDt;
    _angularVelocity *= math.exp(-1.5 * effectiveDt);

    if (_angularVelocity.abs() < 0.05 && !_hasReported) {
      _isSpinning = false;
      _angularVelocity = 0;
      _hasReported = true;
      if (_willSelect) onLanded(segments[_selectedSegmentIndex].conceptId);
    }
  }

  /// Index of the segment currently under the top pointer.
  int get _selectedSegmentIndex {
    // Canvas: 0 rad = right (3 o'clock), clockwise. Top = 3π/2.
    const indicator = math.pi * 1.5;
    var relative = (indicator - _rotation) % (2 * math.pi);
    if (relative < 0) relative += 2 * math.pi;
    return (relative / _sweep).floor() % segments.length;
  }

  // ---------------------------------------------------------------------
  // Rendering
  // ---------------------------------------------------------------------

  @override
  void render(Canvas canvas) {
    _ensureImage();
    final c = Offset(wheelCenter.x, wheelCenter.y);
    final s = _scale;

    _drawRimShadow(canvas, c, s);
    _drawWheelImage(canvas, c);
    _drawRim(canvas, c, s);
    _drawHub(canvas, c, s);
    _drawPointer(canvas, c, s);
  }

  void _drawWheelImage(Canvas canvas, Offset c) {
    final img = _wheelImage;
    if (img == null) return;
    final half = img.width / _imageScale / 2;
    final src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: half * 2,
      height: half * 2,
    );

    void drawAt(double angle, double alpha) {
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..rotate(angle)
        ..drawImageRect(
          img,
          src,
          dst,
          Paint()
            ..filterQuality = FilterQuality.medium
            ..color = Color.fromRGBO(255, 255, 255, alpha),
        )
        ..restore();
    }

    // Ghost copies trail the rotation; their opacity follows speed, so the
    // wheel is crisp at rest and blurred mid-throw.
    final k = speedFraction;
    if (k > 0.02) {
      final sign = _angularVelocity.sign;
      for (var i = 1; i <= _ghostCount; i++) {
        drawAt(_rotation - sign * k * 0.56 * i / _ghostCount * 1.0, k * 0.28);
      }
    }
    drawAt(_rotation, 1);
  }

  void _drawRimShadow(Canvas canvas, Offset c, double s) {
    canvas.drawCircle(
      c + Offset(0, 3 * s),
      rimRadius,
      Paint()
        ..color = const Color(0xFF0B2A30).withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * s),
    );
  }

  void _drawRim(Canvas canvas, Offset c, double s) {
    const stripes = 16;
    final inner = radius + 2 * s;
    final outer = rimRadius;
    final stripeStroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < stripes; i++) {
      final a0 = -math.pi / 2 + i * 2 * math.pi / stripes;
      final a1 = a0 + 2 * math.pi / stripes;
      final path = _annularSector(c, inner, outer, a0, a1);
      canvas
        ..drawPath(path, Paint()..color = i.isOdd ? _stripeRed : _stripeCream)
        ..drawPath(path, stripeStroke);
    }
    // Ring between wedges and rim.
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * s,
    );
    // Bulbs.
    const bulbs = 24;
    final bulbR = radius + 12 * s;
    final bulbStroke = Paint()
      ..color = _bulbRim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * s;
    for (var i = 0; i < bulbs; i++) {
      final a = i * 2 * math.pi / bulbs;
      final o = c + Offset(math.cos(a), math.sin(a)) * bulbR;
      canvas
        ..drawCircle(
          o,
          4.5 * s,
          Paint()..color = i.isOdd ? _bulbBright : _bulbWarm,
        )
        ..drawCircle(o, 4.5 * s, bulbStroke);
    }
  }

  void _drawHub(Canvas canvas, Offset c, double s) {
    canvas
      ..drawCircle(c, 24 * s, Paint()..color = _coinGold)
      ..drawCircle(
        c,
        24 * s,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5 * s,
      );
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final r = (i.isEven ? 13.0 : 5.5) * s;
      final o = c + Offset(math.cos(a), math.sin(a)) * r;
      if (i == 0) {
        star.moveTo(o.dx, o.dy);
      } else {
        star.lineTo(o.dx, o.dy);
      }
    }
    star.close();
    canvas
      ..drawPath(star, Paint()..color = Colors.white)
      ..drawPath(
        star,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * s
          ..strokeJoin = StrokeJoin.round,
      );
  }

  void _drawPointer(Canvas canvas, Offset c, double s) {
    final ty = c.dy - (radius + 20 * s);
    final path = Path()
      ..moveTo(c.dx, ty + 18 * s)
      ..lineTo(c.dx - 12 * s, ty - 16 * s)
      ..lineTo(c.dx + 12 * s, ty - 16 * s)
      ..close();
    canvas
      ..drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(c.dx, ty - 16 * s),
            Offset(c.dx, ty + 18 * s),
            const [Color(0xFFFFE9A3), Color(0xFFE0B14C), Color(0xFF9A6E1E)],
            const [0, 0.5, 1],
          ),
      )
      ..drawPath(
        path,
        Paint()
          ..color = _woodDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * s
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawCircle(
        Offset(c.dx, ty - 10 * s),
        5 * s,
        Paint()..color = _woodDark,
      );
  }

  // ---------------------------------------------------------------------
  // Wheel image (wedges + icons + NEW), rebuilt only when the landed state
  // changes.
  // ---------------------------------------------------------------------

  void _ensureImage() {
    if (!_imageDirty &&
        _wheelImage != null &&
        _imageLandedIndex == _landedIndex) {
      return;
    }
    _wheelImage?.dispose();
    final dpr =
        WidgetsBinding
            .instance
            .platformDispatcher
            .implicitView
            ?.devicePixelRatio ??
        2.0;
    _imageScale = dpr.clamp(1.0, 3.0);
    // Room for the lit-wedge outline that pokes past the radius.
    final pad = radius + 8 * _scale;
    final px = (pad * 2 * _imageScale).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(_imageScale)
      ..translate(pad, pad);
    _paintWheel(canvas);
    final picture = recorder.endRecording();
    _wheelImage = picture.toImageSync(px, px);
    picture.dispose();
    _imageLandedIndex = _landedIndex;
    _imageDirty = false;
  }

  /// Paints the rotating part of the wheel centred on the origin, with
  /// segment i spanning `[i·sweep, (i+1)·sweep]` from 3 o'clock clockwise.
  void _paintWheel(Canvas canvas) {
    final s = _scale;
    const o = Offset.zero;
    final sweep = _sweep;
    final landed = _landedIndex;

    final wedgeStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < segments.length; i++) {
      final dim = landed != null && landed != i;
      final path = _annularSector(o, 0, radius, i * sweep, (i + 1) * sweep);
      final base = wedgePalette[i % wedgePalette.length];
      final color = dim ? Color.lerp(base, Colors.white, 0.72)! : base;
      canvas
        ..drawPath(path, Paint()..color = color)
        ..drawPath(path, wedgeStroke);
    }

    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final dim = landed != null && landed != i;
      final mid = (i + 0.5) * sweep;
      _paintBadge(canvas, seg, mid, dim);
      if (seg.isNew) _paintNewArc(canvas, mid, dim);
    }

    if (landed != null) {
      canvas.drawPath(
        _annularSector(o, 0, radius, landed * sweep, (landed + 1) * sweep),
        Paint()
          ..color = _litAmber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7 * s
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void _paintBadge(Canvas canvas, WheelSegment seg, double mid, bool dim) {
    final s = _scale;
    final r = radius * iconRadiusFraction;
    final badgeR = 28.5 * s;
    canvas
      ..save()
      ..translate(math.cos(mid) * r, math.sin(mid) * r)
      // Radial: the icon's "up" points away from the hub.
      ..rotate(mid + math.pi / 2);
    if (dim) canvas.saveLayer(null, Paint()..color = const Color(0x59FFFFFF));
    canvas
      ..drawCircle(Offset.zero, badgeR, Paint()..color = Colors.white)
      ..drawCircle(
        Offset.zero,
        badgeR,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * s,
      );
    // Icon box is 100 units; it fills ~72% of the badge diameter.
    final iconSize = badgeR * 2 * 0.72;
    canvas
      ..save()
      ..translate(-iconSize / 2, -iconSize / 2)
      ..scale(iconSize / 100);
    paintConceptIcon(canvas, seg.categoryId, seg.tier, accent: seg.color);
    canvas.restore();
    if (dim) canvas.restore();
    canvas.restore();
  }

  /// "NEW!" set along an arc under the icon, reading clockwise, orange with
  /// the ink outline.
  void _paintNewArc(Canvas canvas, double mid, bool dim) {
    final s = _scale;
    final r = radius * _newArcFraction;
    final style = TextStyle(
      fontSize: _newFontSize * s,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2 * s,
      height: 1,
    );
    const text = 'NEW!';
    final glyphs = text.split('').map((ch) {
      return TextPainter(
        text: TextSpan(text: ch, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
    }).toList();
    final total = glyphs.fold<double>(0, (sum, g) => sum + g.width);
    var a = mid - total / 2 / r;
    final alpha = dim ? 0.35 : 1.0;
    for (final g in glyphs) {
      final half = g.width / 2 / r;
      a += half;
      canvas
        ..save()
        ..translate(math.cos(a) * r, math.sin(a) * r)
        ..rotate(a + math.pi / 2);
      final baseline = g.computeDistanceToActualBaseline(
        TextBaseline.alphabetic,
      );
      final at = Offset(-g.width / 2, -baseline);
      TextPainter(
          text: TextSpan(
            text: g.plainText,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3.5 * s
                ..strokeJoin = StrokeJoin.round
                ..color = ink.withValues(alpha: alpha),
            ),
          ),
          textDirection: TextDirection.ltr,
        )
        ..layout()
        ..paint(canvas, at);
      TextPainter(
          text: TextSpan(
            text: g.plainText,
            style: style.copyWith(color: _newOrange.withValues(alpha: alpha)),
          ),
          textDirection: TextDirection.ltr,
        )
        ..layout()
        ..paint(canvas, at);
      canvas.restore();
      a += half;
    }
  }

  static Path _annularSector(
    Offset c,
    double r0,
    double r1,
    double a0,
    double a1,
  ) {
    final outer = Rect.fromCircle(center: c, radius: r1);
    final path = Path();
    if (r0 <= 0) {
      path
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + r1 * math.cos(a0), c.dy + r1 * math.sin(a0))
        ..arcTo(outer, a0, a1 - a0, false)
        ..close();
      return path;
    }
    final inner = Rect.fromCircle(center: c, radius: r0);
    path
      ..moveTo(c.dx + r0 * math.cos(a0), c.dy + r0 * math.sin(a0))
      ..lineTo(c.dx + r1 * math.cos(a0), c.dy + r1 * math.sin(a0))
      ..arcTo(outer, a0, a1 - a0, false)
      ..lineTo(c.dx + r0 * math.cos(a1), c.dy + r0 * math.sin(a1))
      ..arcTo(inner, a1, -(a1 - a0), false)
      ..close();
    return path;
  }
}
