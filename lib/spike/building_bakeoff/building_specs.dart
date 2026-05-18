// Spike: city-building art bake-off.
// Shared catalog of buildings used by all three approaches (Kenney bundles,
// Procedural CustomPainter, GenAI sprites) — comparison stays apples-to-apples.

/// A single building type in the bake-off catalog.
class BuildingSpec {
  const BuildingSpec({
    required this.id,
    required this.label,
    required this.footprint,
    required this.heightTiles,
    required this.tier,
    required this.palette,
  });

  /// Stable identifier — used as the asset filename stem for Options A and C
  /// (e.g. `id = 'house'` ⇒ `assets/spike/option_a_kenney/house.png`).
  final String id;

  /// Kid-facing label, shown beneath the rendered tile in the comparison view.
  final String label;

  /// Footprint on the isometric grid, in tiles. (1, 1) is one tile; (2, 1) is
  /// two tiles along the x-axis. Roads in v1 are always (1, 1).
  final ({int x, int y}) footprint;

  /// Visual height in tile-heights (used by the procedural painter to extrude
  /// the wall block). Roads have height 0.
  final double heightTiles;

  /// Upgrade tier (1..3). Footprint stays the same across tiers per Phase 8.
  final int tier;

  /// Three colours the procedural painter uses: wall, roof, accent (windows,
  /// signage, etc.). Kept abstract so each approach can interpret it.
  final BuildingPalette palette;
}

class BuildingPalette {
  const BuildingPalette({
    required this.wall,
    required this.roof,
    required this.accent,
  });

  final int wall;
  final int roof;
  final int accent;
}

/// The bake-off catalog. Phase 7 starter set: house, apartment, school,
/// hospital, power plant, plus a road tile so we can see buildings sitting on
/// connecting infrastructure.
///
/// Tiers 1..3 of every building share the same footprint and id family (e.g.
/// `apartment`, `apartment_t2`, `apartment_t3`) — Phase 8 upgrade visuals.
const List<BuildingSpec> bakeoffCatalog = [
  // --- Road -----------------------------------------------------------------
  BuildingSpec(
    id: 'road',
    label: 'Road',
    footprint: (x: 1, y: 1),
    heightTiles: 0,
    tier: 1,
    palette: BuildingPalette(
      wall: 0xFF555555,
      roof: 0xFF6E6E6E,
      accent: 0xFFFFE066,
    ),
  ),

  // --- House (tier 1 base) --------------------------------------------------
  BuildingSpec(
    id: 'house',
    label: 'House',
    footprint: (x: 1, y: 1),
    heightTiles: 0.9,
    tier: 1,
    palette: BuildingPalette(
      wall: 0xFFE0C7A6,
      roof: 0xFFB14A3A,
      accent: 0xFF6FA3C7,
    ),
  ),

  // --- Apartment (tier 1) ---------------------------------------------------
  BuildingSpec(
    id: 'apartment',
    label: 'Apartment',
    footprint: (x: 1, y: 1),
    heightTiles: 2.4,
    tier: 1,
    palette: BuildingPalette(
      wall: 0xFFC8B8A0,
      roof: 0xFF5C4536,
      accent: 0xFF8BC4DE,
    ),
  ),

  // --- School (wider footprint) --------------------------------------------
  BuildingSpec(
    id: 'school',
    label: 'School',
    footprint: (x: 2, y: 1),
    heightTiles: 1.1,
    tier: 1,
    palette: BuildingPalette(
      wall: 0xFFEBE0CC,
      roof: 0xFF8B5A2B,
      accent: 0xFFD3463A,
    ),
  ),

  // --- Hospital ------------------------------------------------------------
  BuildingSpec(
    id: 'hospital',
    label: 'Hospital',
    footprint: (x: 2, y: 1),
    heightTiles: 1.6,
    tier: 1,
    palette: BuildingPalette(
      wall: 0xFFF4F4F4,
      roof: 0xFF93B5D7,
      accent: 0xFFD03A3A,
    ),
  ),

  // --- Power plant ---------------------------------------------------------
  BuildingSpec(
    id: 'power_plant',
    label: 'Power plant',
    footprint: (x: 1, y: 1),
    heightTiles: 2,
    tier: 1,
    palette: BuildingPalette(
      wall: 0xFFB8B5A8,
      roof: 0xFF5C5A50,
      accent: 0xFFFFB347,
    ),
  ),
];

/// Lookup by id.
BuildingSpec specById(String id) =>
    bakeoffCatalog.firstWhere((s) => s.id == id);
