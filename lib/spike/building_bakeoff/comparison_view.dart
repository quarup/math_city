// 3-panel comparison view: same building diorama rendered three ways.
//
// Each panel shows the same 5 buildings + a road network in iso projection.
// Paint order is back-to-front so taller buildings near the viewer occlude the
// ones behind. The shared [DioramaLayout] makes A/B/C strictly comparable.

import 'package:flutter/material.dart';

import 'package:math_city/spike/building_bakeoff/asset_slot.dart';
import 'package:math_city/spike/building_bakeoff/building_specs.dart';
import 'package:math_city/spike/building_bakeoff/iso.dart';
import 'package:math_city/spike/building_bakeoff/procedural_building.dart';

/// A single building placement on the diorama grid.
class Placement {
  const Placement({required this.gx, required this.gy, required this.specId});
  final int gx;
  final int gy;
  final String specId;
}

/// Shared 5x5 layout used by all three panels. Roads form a horizontal main
/// road at gy=2, with the 5 building types placed adjacent to it.
const dioramaLayout = <Placement>[
  Placement(gx: 0, gy: 2, specId: 'road'),
  Placement(gx: 1, gy: 2, specId: 'road'),
  Placement(gx: 2, gy: 2, specId: 'road'),
  Placement(gx: 3, gy: 2, specId: 'road'),
  Placement(gx: 4, gy: 2, specId: 'road'),
  Placement(gx: 0, gy: 0, specId: 'house'),
  Placement(gx: 2, gy: 0, specId: 'apartment'),
  Placement(gx: 4, gy: 0, specId: 'power_plant'),
  Placement(gx: 0, gy: 4, specId: 'school'), // 2x1
  Placement(gx: 3, gy: 4, specId: 'hospital'), // 2x1
];

const dioramaGridW = 5;
const dioramaGridH = 5;

/// Three-panel comparison: Kenney slots / Procedural / GenAI slots.
class BakeoffComparisonView extends StatelessWidget {
  const BakeoffComparisonView({this.tileW = 56, super.key});

  final double tileW;

  @override
  Widget build(BuildContext context) {
    final iso = Iso(tileW: tileW, tileH: tileW);
    final panelW = (dioramaGridW + dioramaGridH) * iso.halfW + 40;
    final panelH =
        (dioramaGridW + dioramaGridH) * iso.halfH +
        2.5 * iso.tileH + // headroom for tallest building + chimney
        72; // header + footer chrome

    Widget panel(Color headerColor, _DioramaMode mode) {
      return Container(
        width: panelW,
        height: panelH,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFE9D9),
          border: Border.all(color: const Color(0xFF888888)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header band — coloured to identify the approach (blue=A, green=B,
            // magenta=C) since text rendering in widget tests is unreliable.
            Container(height: 18, color: headerColor),
            const SizedBox(height: 4),
            Expanded(
              child: CustomPaint(
                painter: _DioramaPainter(iso: iso, mode: mode),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFFAF7EE),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          panel(const Color(0xFF3B6FAE), _DioramaMode.kenneyPlaceholder),
          panel(const Color(0xFF4FA86A), _DioramaMode.procedural),
          panel(const Color(0xFFB33B8E), _DioramaMode.genaiPlaceholder),
        ],
      ),
    );
  }
}

enum _DioramaMode { procedural, kenneyPlaceholder, genaiPlaceholder }

class _DioramaPainter extends CustomPainter {
  _DioramaPainter({required this.iso, required this.mode});

  final Iso iso;
  final _DioramaMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    // Grid origin: top-centre of the (0, 0) diamond.
    final origin = Offset(
      size.width / 2 - (dioramaGridW - dioramaGridH) * iso.halfW / 2,
      24,
    );

    // Paint the empty grid first (faint terrain diamonds) so cells that aren't
    // covered by a placement still show the layout.
    for (var gx = 0; gx < dioramaGridW; gx++) {
      for (var gy = 0; gy < dioramaGridH; gy++) {
        final corners = [
          iso.grid(origin, gx.toDouble(), gy.toDouble()),
          iso.grid(origin, gx + 1, gy.toDouble()),
          iso.grid(origin, gx + 1, gy + 1),
          iso.grid(origin, gx.toDouble(), gy + 1),
        ];
        final p = Path()..moveTo(corners.first.dx, corners.first.dy);
        for (var i = 1; i < corners.length; i++) {
          p.lineTo(corners[i].dx, corners[i].dy);
        }
        p.close();
        canvas
          ..drawPath(p, Paint()..color = const Color(0xFFDDD3B6))
          ..drawPath(
            p,
            Paint()
              ..color = const Color(0x22000000)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5,
          );
      }
    }

    // Back-to-front sort: smaller (gx + gy) is further away; paint first.
    final sorted = [...dioramaLayout]
      ..sort((a, b) => (a.gx + a.gy).compareTo(b.gx + b.gy));

    for (final p in sorted) {
      final spec = specById(p.specId);
      final placementOrigin = iso.grid(
        origin,
        p.gx.toDouble(),
        p.gy.toDouble(),
      );
      switch (mode) {
        case _DioramaMode.procedural:
          paintProceduralBuilding(canvas, spec, iso, placementOrigin);
        case _DioramaMode.kenneyPlaceholder:
          if (spec.id == 'road') {
            // Roads still render procedurally for placeholder panels so the
            // city has visible road structure — the user is evaluating the
            // BUILDINGS, not the roads.
            paintProceduralBuilding(canvas, spec, iso, placementOrigin);
          } else {
            paintAssetPlaceholder(
              canvas,
              spec,
              iso,
              placementOrigin,
              BakeoffApproach.kenney,
            );
          }
        case _DioramaMode.genaiPlaceholder:
          if (spec.id == 'road') {
            paintProceduralBuilding(canvas, spec, iso, placementOrigin);
          } else {
            paintAssetPlaceholder(
              canvas,
              spec,
              iso,
              placementOrigin,
              BakeoffApproach.genai,
            );
          }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DioramaPainter old) =>
      old.iso != iso || old.mode != mode;
}
