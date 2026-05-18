// Option B: procedural CustomPainter buildings.
//
// One renderer draws all building types from a [BuildingSpec], so the visual
// language is automatically coherent. Each building is an extruded box (walls +
// top), with type-specific additions painted on top:
//
// - Pitched roof (triangular prism) for house & school
// - Window grid on walls for apartment / school / hospital
// - Accent-coloured sign on the front face for school
// - Red cross on the front face for hospital
// - Chimney (smaller box extruded above the main box) for power plant
// - Road tile is just the diamond at z=0 with a yellow centre line
//
// All faces derive from the same base wall colour via luminance multipliers
// (top brightest, front mid, right side darkest), so style coherence is
// automatic across the catalog.

import 'package:flutter/material.dart';

import 'package:math_city/spike/building_bakeoff/building_specs.dart';
import 'package:math_city/spike/building_bakeoff/iso.dart';

/// Paints a single building on `canvas` at the given `origin` — the screen
/// point of grid cell (0, 0)'s NORTH corner (the diamond top). The caller is
/// responsible for paint order (back-to-front sort for occlusion).
void paintProceduralBuilding(
  Canvas canvas,
  BuildingSpec spec,
  Iso iso,
  Offset origin,
) {
  if (spec.id == 'road') {
    _paintRoad(canvas, spec, iso, origin);
    return;
  }
  _paintGroundShadow(canvas, spec, iso, origin);
  _paintBoxAndRoof(canvas, spec, iso, origin);
  _paintWallDetail(canvas, spec, iso, origin);
}

/// Single-building widget (used by the per-building strip view).
class ProceduralBuilding extends StatelessWidget {
  const ProceduralBuilding({
    required this.spec,
    required this.iso,
    super.key,
  });

  final BuildingSpec spec;
  final Iso iso;

  @override
  Widget build(BuildContext context) {
    final w = (spec.footprint.x + spec.footprint.y) * iso.halfW + 16;
    final h =
        (spec.footprint.x + spec.footprint.y) * iso.halfH +
        spec.heightTiles * iso.tileH +
        (spec.id == 'power_plant' ? 1.6 * iso.tileH : 0) +
        24;
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: _SingleBuildingPainter(spec: spec, iso: iso),
      ),
    );
  }
}

class _SingleBuildingPainter extends CustomPainter {
  _SingleBuildingPainter({required this.spec, required this.iso});

  final BuildingSpec spec;
  final Iso iso;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(
      size.width / 2 - (spec.footprint.x - spec.footprint.y) * iso.halfW / 2,
      24 +
          spec.heightTiles * iso.tileH +
          (spec.id == 'power_plant' ? 1.6 * iso.tileH : 0),
    );
    paintProceduralBuilding(canvas, spec, iso, origin);
  }

  @override
  bool shouldRepaint(covariant _SingleBuildingPainter old) =>
      old.spec != spec || old.iso != iso;
}

// -----------------------------------------------------------------------------
// Internals
// -----------------------------------------------------------------------------

Color _shade(int rgb, double luminance) {
  final c = Color(rgb);
  return Color.fromARGB(
    255,
    (c.r * 255 * luminance).round().clamp(0, 255),
    (c.g * 255 * luminance).round().clamp(0, 255),
    (c.b * 255 * luminance).round().clamp(0, 255),
  );
}

Path _polyPath(List<Offset> pts) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    p.lineTo(pts[i].dx, pts[i].dy);
  }
  return p..close();
}

void _fillStroke(
  Canvas canvas,
  Path path,
  Color fill, {
  double strokeWidth = 0.8,
}) {
  canvas
    ..drawPath(path, Paint()..color = fill)
    ..drawPath(
      path,
      Paint()
        ..color = const Color(0x44000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
}

void _paintGroundShadow(
  Canvas canvas,
  BuildingSpec spec,
  Iso iso,
  Offset origin,
) {
  final fp = spec.footprint;
  final corners = <Offset>[
    iso.grid(origin, 0, 0),
    iso.grid(origin, fp.x.toDouble(), 0),
    iso.grid(origin, fp.x.toDouble(), fp.y.toDouble()),
    iso.grid(origin, 0, fp.y.toDouble()),
  ];
  canvas.drawPath(
    _polyPath(corners),
    Paint()..color = const Color(0x22000000),
  );
}

void _paintRoad(Canvas canvas, BuildingSpec spec, Iso iso, Offset origin) {
  final fp = spec.footprint;
  final corners = <Offset>[
    iso.grid(origin, 0, 0),
    iso.grid(origin, fp.x.toDouble(), 0),
    iso.grid(origin, fp.x.toDouble(), fp.y.toDouble()),
    iso.grid(origin, 0, fp.y.toDouble()),
  ];
  _fillStroke(canvas, _polyPath(corners), Color(spec.palette.wall));

  final dashPaint = Paint()
    ..color = Color(spec.palette.accent)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  canvas
    ..drawLine(
      iso.grid(origin, 0.2, 0.5),
      iso.grid(origin, 0.4, 0.5),
      dashPaint,
    )
    ..drawLine(
      iso.grid(origin, 0.6, 0.5),
      iso.grid(origin, 0.8, 0.5),
      dashPaint,
    )
    ..drawLine(
      iso.grid(origin, 0.5, 0.2),
      iso.grid(origin, 0.5, 0.4),
      dashPaint,
    )
    ..drawLine(
      iso.grid(origin, 0.5, 0.6),
      iso.grid(origin, 0.5, 0.8),
      dashPaint,
    );
}

void _paintBoxAndRoof(
  Canvas canvas,
  BuildingSpec spec,
  Iso iso,
  Offset origin,
) {
  final fp = spec.footprint;
  final h = spec.heightTiles;
  final wallTopColor = _shade(spec.palette.wall, 1);
  final wallFrontColor = _shade(spec.palette.wall, 0.78);
  final wallRightColor = _shade(spec.palette.wall, 0.55);

  final topNW = iso.grid(origin, 0, 0, z: h);
  final topNE = iso.grid(origin, fp.x.toDouble(), 0, z: h);
  final topSE = iso.grid(origin, fp.x.toDouble(), fp.y.toDouble(), z: h);
  final topSW = iso.grid(origin, 0, fp.y.toDouble(), z: h);

  final gNE = iso.grid(origin, fp.x.toDouble(), 0);
  final gSE = iso.grid(origin, fp.x.toDouble(), fp.y.toDouble());
  final gSW = iso.grid(origin, 0, fp.y.toDouble());

  _fillStroke(canvas, _polyPath([topNE, topSE, gSE, gNE]), wallRightColor);
  _fillStroke(canvas, _polyPath([topSE, topSW, gSW, gSE]), wallFrontColor);

  final usePitchedRoof = spec.id == 'house' || spec.id == 'school';
  if (usePitchedRoof) {
    _paintPitchedRoof(canvas, spec, iso, origin, h);
  } else {
    _fillStroke(canvas, _polyPath([topNW, topNE, topSE, topSW]), wallTopColor);
  }
}

void _paintPitchedRoof(
  Canvas canvas,
  BuildingSpec spec,
  Iso iso,
  Offset origin,
  double wallH,
) {
  final fp = spec.footprint;
  final roofColor = Color(spec.palette.roof);
  final roofDark = _shade(spec.palette.roof, 0.7);
  final ridgeAlongX = fp.x >= fp.y;
  final ridgeZ = wallH + 0.55;

  final topNE = iso.grid(origin, fp.x.toDouble(), 0, z: wallH);
  final topSE = iso.grid(origin, fp.x.toDouble(), fp.y.toDouble(), z: wallH);
  final topSW = iso.grid(origin, 0, fp.y.toDouble(), z: wallH);

  if (ridgeAlongX) {
    final ridgeW = iso.grid(origin, 0, fp.y / 2, z: ridgeZ);
    final ridgeE = iso.grid(origin, fp.x.toDouble(), fp.y / 2, z: ridgeZ);
    _fillStroke(canvas, _polyPath([ridgeW, ridgeE, topSE, topSW]), roofColor);
    _fillStroke(canvas, _polyPath([ridgeE, topNE, topSE]), roofDark);
  } else {
    final ridgeN = iso.grid(origin, fp.x / 2, 0, z: ridgeZ);
    final ridgeS = iso.grid(origin, fp.x / 2, fp.y.toDouble(), z: ridgeZ);
    _fillStroke(canvas, _polyPath([ridgeN, topNE, topSE, ridgeS]), roofColor);
    _fillStroke(canvas, _polyPath([ridgeS, topSW, topSE]), roofDark);
  }
}

void _paintWallDetail(
  Canvas canvas,
  BuildingSpec spec,
  Iso iso,
  Offset origin,
) {
  switch (spec.id) {
    case 'apartment':
      _paintWindowGrid(canvas, spec, iso, origin, rows: 4, cols: 2);
    case 'house':
      _paintSingleWindow(canvas, spec, iso, origin);
    case 'school':
      _paintSign(canvas, spec, iso, origin, label: 'SCHOOL');
      _paintWindowGrid(canvas, spec, iso, origin, rows: 2, cols: 3);
    case 'hospital':
      _paintWindowGrid(canvas, spec, iso, origin, rows: 2, cols: 3);
      _paintHospitalCross(canvas, spec, iso, origin);
    case 'power_plant':
      _paintChimney(canvas, spec, iso, origin);
    default:
      break;
  }
}

Offset _frontWallPt(
  Iso iso,
  Offset origin,
  ({int x, int y}) fp,
  double u,
  double v,
) {
  // Point on the FRONT wall (gy = fp.y), with u along gx, v along z.
  return iso.grid(origin, u, fp.y.toDouble(), z: v);
}

Offset _rightWallPt(
  Iso iso,
  Offset origin,
  ({int x, int y}) fp,
  double u,
  double v,
) {
  // Point on the RIGHT wall (gx = fp.x), with u along gy, v along z.
  return iso.grid(origin, fp.x.toDouble(), u, z: v);
}

void _paintWindowGrid(
  Canvas canvas,
  BuildingSpec spec,
  Iso iso,
  Offset origin, {
  required int rows,
  required int cols,
}) {
  final fp = spec.footprint;
  final wallH = spec.heightTiles;
  final accent = Color(spec.palette.accent);
  const dark = Color(0xCC2A3A4A);
  const marginU = 0.18;
  const marginV = 0.22;
  final usableU = fp.x - 2 * marginU;
  final usableV = wallH - 2 * marginV;
  final winW = usableU / (cols * 1.8);
  final winH = usableV / (rows * 1.8);

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final cu = marginU + (c + 0.5) * usableU / cols;
      final cv = marginV + (r + 0.5) * usableV / rows;
      final pts = [
        _frontWallPt(iso, origin, fp, cu - winW / 2, cv - winH / 2),
        _frontWallPt(iso, origin, fp, cu + winW / 2, cv - winH / 2),
        _frontWallPt(iso, origin, fp, cu + winW / 2, cv + winH / 2),
        _frontWallPt(iso, origin, fp, cu - winW / 2, cv + winH / 2),
      ];
      _fillStroke(canvas, _polyPath(pts), dark);
    }
  }

  // Right-wall column.
  final usableU2 = fp.y - 2 * marginU;
  final winW2 = usableU2 / (cols * 1.8);
  for (var r = 0; r < rows; r++) {
    final cv = marginV + (r + 0.5) * usableV / rows;
    final cu = fp.y / 2;
    final pts = [
      _rightWallPt(iso, origin, fp, cu - winW2 / 2, cv - winH / 2),
      _rightWallPt(iso, origin, fp, cu + winW2 / 2, cv - winH / 2),
      _rightWallPt(iso, origin, fp, cu + winW2 / 2, cv + winH / 2),
      _rightWallPt(iso, origin, fp, cu - winW2 / 2, cv + winH / 2),
    ];
    _fillStroke(canvas, _polyPath(pts), dark);
  }

  // One accent-lit window so the building has a focal point.
  final accentCu = marginU + 0.5 * usableU / cols;
  final accentCv = marginV + 0.5 * usableV / rows;
  final winSize = winH * 0.55;
  final accPts = [
    _frontWallPt(
      iso,
      origin,
      fp,
      accentCu - winSize / 2,
      accentCv - winSize / 2,
    ),
    _frontWallPt(
      iso,
      origin,
      fp,
      accentCu + winSize / 2,
      accentCv - winSize / 2,
    ),
    _frontWallPt(
      iso,
      origin,
      fp,
      accentCu + winSize / 2,
      accentCv + winSize / 2,
    ),
    _frontWallPt(
      iso,
      origin,
      fp,
      accentCu - winSize / 2,
      accentCv + winSize / 2,
    ),
  ];
  canvas.drawPath(_polyPath(accPts), Paint()..color = accent);
}

void _paintSingleWindow(
  Canvas canvas,
  BuildingSpec spec,
  Iso iso,
  Offset origin,
) {
  final fp = spec.footprint;
  final h = spec.heightTiles;
  final accent = Color(spec.palette.accent);
  const dark = Color(0xCC2A3A4A);
  final doorPts = [
    _frontWallPt(iso, origin, fp, 0.55, 0.05),
    _frontWallPt(iso, origin, fp, 0.78, 0.05),
    _frontWallPt(iso, origin, fp, 0.78, 0.55),
    _frontWallPt(iso, origin, fp, 0.55, 0.55),
  ];
  _fillStroke(canvas, _polyPath(doorPts), accent);
  final winPts = [
    _frontWallPt(iso, origin, fp, 0.18, 0.30),
    _frontWallPt(iso, origin, fp, 0.42, 0.30),
    _frontWallPt(iso, origin, fp, 0.42, 0.60),
    _frontWallPt(iso, origin, fp, 0.18, 0.60),
  ];
  _fillStroke(canvas, _polyPath(winPts), dark);
  // Silence unused warning — h is captured for symmetry with siblings.
  assert(h > 0, 'house height should be positive');
}

void _paintSign(
  Canvas canvas,
  BuildingSpec spec,
  Iso iso,
  Offset origin, {
  required String label,
}) {
  final fp = spec.footprint;
  final h = spec.heightTiles;
  final accent = Color(spec.palette.accent);
  final pts = [
    _frontWallPt(iso, origin, fp, 0.1, h * 0.62 / h),
    _frontWallPt(iso, origin, fp, fp.x - 0.1, h * 0.62 / h),
    _frontWallPt(iso, origin, fp, fp.x - 0.1, h * 0.82 / h),
    _frontWallPt(iso, origin, fp, 0.1, h * 0.82 / h),
  ];
  _fillStroke(canvas, _polyPath(pts), accent);

  final tp = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final cx = (pts[0].dx + pts[2].dx) / 2;
  final cy = (pts[0].dy + pts[2].dy) / 2;
  tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
}

void _paintHospitalCross(
  Canvas canvas,
  BuildingSpec spec,
  Iso iso,
  Offset origin,
) {
  final fp = spec.footprint;
  final h = spec.heightTiles;
  final accent = Color(spec.palette.accent);
  final cu = fp.x / 2;
  final cv = h * 0.55;
  const arm = 0.18;
  const thick = 0.07;
  final hArm = [
    _frontWallPt(iso, origin, fp, cu - arm, cv - thick),
    _frontWallPt(iso, origin, fp, cu + arm, cv - thick),
    _frontWallPt(iso, origin, fp, cu + arm, cv + thick),
    _frontWallPt(iso, origin, fp, cu - arm, cv + thick),
  ];
  final vArm = [
    _frontWallPt(iso, origin, fp, cu - thick, cv - arm),
    _frontWallPt(iso, origin, fp, cu + thick, cv - arm),
    _frontWallPt(iso, origin, fp, cu + thick, cv + arm),
    _frontWallPt(iso, origin, fp, cu - thick, cv + arm),
  ];
  canvas
    ..drawPath(_polyPath(hArm), Paint()..color = accent)
    ..drawPath(_polyPath(vArm), Paint()..color = accent);
}

void _paintChimney(
  Canvas canvas,
  BuildingSpec spec,
  Iso iso,
  Offset origin,
) {
  final fp = spec.footprint;
  final wallH = spec.heightTiles;
  final wallTopColor = _shade(spec.palette.roof, 1.05);
  final wallFrontColor = _shade(spec.palette.roof, 0.78);
  final wallRightColor = _shade(spec.palette.roof, 0.55);
  final accent = Color(spec.palette.accent);
  final cx = fp.x / 2;
  final cy = fp.y / 2;
  const s = 0.22;
  const chimneyH = 1.2;
  final baseZ = wallH;

  final tNW = iso.grid(origin, cx - s, cy - s, z: baseZ + chimneyH);
  final tNE = iso.grid(origin, cx + s, cy - s, z: baseZ + chimneyH);
  final tSE = iso.grid(origin, cx + s, cy + s, z: baseZ + chimneyH);
  final tSW = iso.grid(origin, cx - s, cy + s, z: baseZ + chimneyH);
  final bNE = iso.grid(origin, cx + s, cy - s, z: baseZ);
  final bSE = iso.grid(origin, cx + s, cy + s, z: baseZ);
  final bSW = iso.grid(origin, cx - s, cy + s, z: baseZ);

  _fillStroke(canvas, _polyPath([tNE, tSE, bSE, bNE]), wallRightColor);
  _fillStroke(canvas, _polyPath([tSE, tSW, bSW, bSE]), wallFrontColor);
  _fillStroke(canvas, _polyPath([tNW, tNE, tSE, tSW]), wallTopColor);

  const bandH = 0.18;
  final btNE = iso.grid(origin, cx + s, cy - s, z: baseZ + chimneyH - bandH);
  final btSE = iso.grid(origin, cx + s, cy + s, z: baseZ + chimneyH - bandH);
  final btSW = iso.grid(origin, cx - s, cy + s, z: baseZ + chimneyH - bandH);
  canvas
    ..drawPath(
      _polyPath([tNE, tSE, btSE, btNE]),
      Paint()..color = accent.withValues(alpha: 0.9),
    )
    ..drawPath(
      _polyPath([tSE, tSW, btSW, btSE]),
      Paint()..color = accent.withValues(alpha: 0.7),
    );
}
