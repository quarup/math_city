import 'dart:convert';
import 'dart:ui';

/// One light on a building sprite: a window, or a sign / lamp ([glow]),
/// as a path in the sprite's own pixels (192 px per tile).
class LightRegion {
  const LightRegion({required this.path, required this.glow});

  final Path path;

  /// A sign, a lamp, a screen: follows the building's closing time rather
  /// than a room's hours.
  final bool glow;
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
/// with `p` a flat `[x0, y0, x1, y1, …]` polygon and `k` `w` (window) or
/// `g` (glow).
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
      regions.add(LightRegion(path: path, glow: raw['k'] == 'g'));
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
