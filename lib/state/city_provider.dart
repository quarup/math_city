import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/dag_engine.dart';
import 'package:math_city/domain/city/unlock_rule.dart';
import 'package:math_city/state/player_provider.dart';

/// The active player's beginner-map `City` row. Auto-created at player
/// creation, so it resolves for any real player.
final activeCityProvider = FutureProvider<City>((ref) async {
  final playerId = ref.watch(activePlayerIdProvider);
  if (playerId == null) throw StateError('No active player');
  final db = ref.read(appDatabaseProvider);
  return db.cityForPlayer(playerId);
});

/// Every building currently placed in the active city.
final placementsProvider = FutureProvider<List<BuildingPlacement>>((ref) async {
  final city = await ref.watch(activeCityProvider.future);
  final db = ref.read(appDatabaseProvider);
  return db.placementsForCity(city.id);
});

/// One row in the build-mode catalog. Researched entries are placeable;
/// unresearched ones are *available to research* (their unlock rule passes
/// against the current city state) and render as locked cards the player can
/// spend 🔬 to unlock.
class CatalogEntry {
  const CatalogEntry({required this.building, required this.researched});

  final BuildingType building;
  final bool researched;
}

/// The build-mode catalog: every researched building plus every building
/// that's currently available to research, in registry order (stable display;
/// a card flips from locked to placeable in place when researched). Drives the
/// bottom catalog bar on the city screen.
final cityCatalogProvider = FutureProvider<List<CatalogEntry>>((ref) async {
  final playerId = ref.watch(activePlayerIdProvider);
  if (playerId == null) throw StateError('No active player');
  final db = ref.read(appDatabaseProvider);
  final player = await ref.watch(activePlayerProvider.future);
  final city = await ref.watch(activeCityProvider.future);
  final placements = await ref.watch(placementsProvider.future);
  final researchedIds = await db.researchedBuildingTypeIds(playerId);

  // Population growth (Chunk 5) and beat firing (Chunk 6) aren't modelled yet,
  // so those gate inputs are stubbed; v1 unlock rules only gate on placed
  // buildings.
  final ctx = UnlockContext(
    lifetimeBricksEarned: player.lifetimeBricksEarned,
    population: city.population,
    placedBuildingTypeIds: placements.map((p) => p.buildingTypeId).toSet(),
    firedBeatIds: const <String>{},
  );
  const engine = BuildingDagEngine();
  final availableIds = engine.availableToResearch(ctx).map((b) => b.id).toSet();

  final entries = <CatalogEntry>[];
  for (final b in buildingRegistry) {
    if (researchedIds.contains(b.id)) {
      entries.add(CatalogEntry(building: b, researched: true));
    } else if (availableIds.contains(b.id)) {
      entries.add(CatalogEntry(building: b, researched: false));
    }
  }
  return entries;
});

/// Side-effecting city operations. Kept off the widget so the placement
/// orchestration (spend 🧱 → insert row → invalidate) lives in one place.
final cityActionsProvider = Provider<CityActions>(CityActions.new);

class CityActions {
  CityActions(this._ref);

  final Ref _ref;

  /// Spends the building's `brickCost` and records the placement at
  /// `(col, row)`. No-op if there's no active player. Invalidates the
  /// placement, player, and player-list providers so every screen refreshes.
  Future<void> placeBuilding(BuildingType type, int col, int row) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final city = await _ref.read(activeCityProvider.future);
    await db.placeBuilding(
      cityId: city.id,
      playerId: playerId,
      buildingTypeId: type.id,
      gridX: col,
      gridY: row,
      brickCost: type.brickCost,
    );
    _ref
      ..invalidate(placementsProvider)
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider);
  }

  /// Spends [type]'s `researchCost` 🔬 and adds it to the player's catalog.
  /// Invalidates the catalog (so the card flips from locked to placeable) and
  /// the player (so the 🔬 balance updates). No-op if there's no active player.
  /// The caller must have verified affordability.
  Future<void> researchBuilding(BuildingType type) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    await db.researchBuilding(
      playerId: playerId,
      buildingTypeId: type.id,
      researchCost: type.researchCost,
    );
    _ref
      ..invalidate(cityCatalogProvider)
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider);
  }

  /// Moves an existing placement to `(col, row)`. Used for `unique`
  /// building types so a second "place" relocates the first instance
  /// instead of stacking a duplicate.
  Future<void> moveBuilding(int placementId, int col, int row) async {
    final db = _ref.read(appDatabaseProvider);
    await db.moveBuildingPlacement(
      placementId: placementId,
      gridX: col,
      gridY: row,
    );
    _ref.invalidate(placementsProvider);
  }
}
