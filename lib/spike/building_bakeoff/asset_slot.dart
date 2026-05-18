// Options A (Kenney bundles) and C (GenAI sprites) — both load a PNG from disk
// for each building. Until the user populates the slots, this widget paints a
// clearly-labelled placeholder occupying the correct iso footprint so the
// comparison layout is still meaningful.

import 'package:flutter/material.dart';

import 'package:math_city/spike/building_bakeoff/building_specs.dart';
import 'package:math_city/spike/building_bakeoff/iso.dart';

enum BakeoffApproach { kenney, genai }

/// Paints a placeholder for one building slot at iso `origin`. Footprint is
/// outlined, the building id and approach name are stencilled inside. Replace
/// with `paintImageBuilding` once real PNGs land in `assets/spike/<approach>/`.
void paintAssetPlaceholder(
  Canvas canvas,
  BuildingSpec spec,
  Iso iso,
  Offset origin,
  BakeoffApproach approach,
) {
  final fp = spec.footprint;

  // Diamond ground footprint.
  final corners = <Offset>[
    iso.grid(origin, 0, 0),
    iso.grid(origin, fp.x.toDouble(), 0),
    iso.grid(origin, fp.x.toDouble(), fp.y.toDouble()),
    iso.grid(origin, 0, fp.y.toDouble()),
  ];
  final path = Path()..moveTo(corners.first.dx, corners.first.dy);
  for (var i = 1; i < corners.length; i++) {
    path.lineTo(corners[i].dx, corners[i].dy);
  }
  path.close();
  canvas
    ..drawPath(
      path,
      Paint()..color = const Color(0x22000000),
    )
    ..drawPath(
      path,
      Paint()
        ..color = const Color(0xFF888888)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

  // Diagonal hatch fill inside the footprint diamond so each "empty slot" is
  // clearly an empty slot. Approach is communicated by hatch colour: Kenney
  // = blue, GenAI = magenta.
  final hatchColor = switch (approach) {
    BakeoffApproach.kenney => const Color(0x553B6FAE),
    BakeoffApproach.genai => const Color(0x55B33B8E),
  };
  final hatchPaint = Paint()
    ..color = hatchColor
    ..strokeWidth = 1;
  canvas
    ..save()
    ..clipPath(path);
  // 45-degree lines spaced 6px apart.
  final bounds = path.getBounds();
  for (
    var x = bounds.left - bounds.height;
    x < bounds.right + bounds.height;
    x += 6
  ) {
    canvas.drawLine(
      Offset(x, bounds.top),
      Offset(x + bounds.height, bounds.bottom),
      hatchPaint,
    );
  }
  canvas.restore();
}
