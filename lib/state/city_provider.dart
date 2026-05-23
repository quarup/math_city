import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
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

/// Building types the player has unlocked, in registry order (stable catalog
/// display). Drives the build-mode catalog.
final researchedBuildingsProvider = FutureProvider<List<BuildingType>>((
  ref,
) async {
  final playerId = ref.watch(activePlayerIdProvider);
  if (playerId == null) throw StateError('No active player');
  final db = ref.read(appDatabaseProvider);
  final ids = await db.researchedBuildingTypeIds(playerId);
  return buildingRegistry.where((b) => ids.contains(b.id)).toList();
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
}
