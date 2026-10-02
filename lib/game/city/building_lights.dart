import 'dart:convert';
import 'dart:ui';

/// What a light region is.
enum LightKind {
  /// A window: relit warm, on a room's hours, dark in the small hours.
  window,

  /// A sign, a screen, a lit shape: keeps its own colour, on from dusk
  /// until dawn.
  glow,

  /// A point of light — a porch lamp, a garden light: a bright core with a
  /// round halo, on from dusk until dawn.
  lamp,
}

/// One light on a building sprite, as a path in the sprite's own pixels
/// (192 px per tile).
class LightRegion {
  LightRegion({required this.path, required this.kind})
    : centre = path.getBounds().center,
      radius = (path.getBounds().width + path.getBounds().height) / 4;

  final Path path;
  final LightKind kind;

  /// Where a [LightKind.lamp] shines from, and the size of its core.
  final Offset centre;
  final double radius;

  /// A sign or a lamp rather than a window: on all night.
  bool get glow => kind != LightKind.window;
}

/// The lights of one building sprite (city_builder.md §12): the regions a
/// person approved in the night-lights review page. The lit pixels
/// themselves are the sprite-sized image `assets/buildings/lit/<sprite>.png`.
class SpriteLights {
  const SpriteLights({required this.size, required this.regions});

  final Size size;
  final List<LightRegion> regions;
}

/// Parses `assets/buildings/lights.json` (written by
/// `tools/night_lights/build.py`): `{sprite: {s: [w, h], r: [{k, p}]}}`
/// with `p` a flat `[x0, y0, x1, y1, …]` polygon and `k` `w` (window),
/// `g` (glow) or `l` (lamp).
Map<String, SpriteLights> parseBuildingLights(String source) {
  final data = jsonDecode(source) as Map<String, dynamic>;
  final out = <String, SpriteLights>{};
  for (final entry in data.entries) {
    final sprite = entry.value as Map<String, dynamic>;
    final size = (sprite['s'] as List).cast<num>();
    final regions = <LightRegion>[];
    for (final raw in (sprite['r'] as List).cast<Map<String, dynamic>>()) {
      final points = (raw['p'] as List).cast<num>();
      if (points.length < 6) continue;
      final path = Path()..moveTo(points[0].toDouble(), points[1].toDouble());
      for (var i = 2; i + 1 < points.length; i += 2) {
        path.lineTo(points[i].toDouble(), points[i + 1].toDouble());
      }
      path.close();
      regions.add(
        LightRegion(
          path: path,
          kind: switch (raw['k']) {
            'g' => LightKind.glow,
            'l' => LightKind.lamp,
            _ => LightKind.window,
          },
        ),
      );
    }
    out[entry.key] = SpriteLights(
      size: Size(size[0].toDouble(), size[1].toDouble()),
      regions: regions,
    );
  }
  return out;
}

/// A sprite's lights together with its loaded lit image.
typedef LitSprite = ({SpriteLights lights, Image lit});
