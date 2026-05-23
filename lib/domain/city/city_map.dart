/// Thematic map definition — static catalog. Each `CityMap` is a tile-grid
/// + a brick unlock cost (0 for the beginner map). Players can have multiple
/// `City` instances over time (one per `CityMap` they've unlocked).
enum CityMapTheme { beginner, countryside, bigCity, futuristic }

class CityMap {
  const CityMap({
    required this.id,
    required this.name,
    required this.theme,
    required this.baseGridWidth,
    required this.baseGridHeight,
    required this.brickUnlockCost,
    required this.terrainSeed,
  });

  final String id;
  final String name;
  final CityMapTheme theme;
  final int baseGridWidth;
  final int baseGridHeight;

  /// 🧱 to unlock this map. 0 for the beginner map (every player starts
  /// with it; the row in `Cities` is auto-created on player creation).
  final int brickUnlockCost;

  /// Deterministic seed driving the procedural terrain layout.
  final int terrainSeed;
}
