import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/construction_site.dart';

/// A persisted construction site: its row id plus the pure-domain value the
/// rules operate on. The state layer hands these to the screens.
class CitySite {
  const CitySite({required this.id, required this.site});

  final int id;
  final ConstructionSite site;

  SiteGoal get goal => site.goal;

  /// Kid-facing name of what the site is building.
  String get name => switch (site.goal) {
    BuildingGoal(:final type) => type.name,
    LandBlockGoal() => 'New land',
  };
}

/// Maps a `ConstructionSites` row to the domain value. Upgrade sites need
/// the source placement's type for delta pricing, so pass the city's
/// placements; a site whose building type (or upgrade source) no longer
/// resolves is skipped by [sitesFromRows].
ConstructionSite? siteFromRow(
  ConstructionSiteRow row,
  Iterable<BuildingPlacement> placements,
) {
  final SiteGoal goal;
  if (row.goalKind == 'land') {
    goal = LandBlockGoal(blockX: row.blockX!, blockY: row.blockY!);
  } else {
    final type = findBuildingTypeById(row.buildingTypeId!);
    if (type == null) return null;
    UpgradeLink? upgrade;
    final sourceId = row.upgradesFromPlacementId;
    if (sourceId != null) {
      final source = placements.where((p) => p.id == sourceId).firstOrNull;
      final sourceType = source == null
          ? null
          : findBuildingTypeById(source.buildingTypeId);
      if (sourceType == null) return null;
      upgrade = UpgradeLink(
        sourcePlacementId: sourceId,
        sourceType: sourceType,
      );
    }
    goal = BuildingGoal(
      type: type,
      col: row.gridX!,
      row: row.gridY!,
      upgrade: upgrade,
    );
  }
  return ConstructionSite(
    goal: goal,
    startedAtRound: row.startedAtRound,
    paidCoins: row.paidCoins,
  );
}

List<CitySite> sitesFromRows(
  Iterable<ConstructionSiteRow> rows,
  Iterable<BuildingPlacement> placements,
) => [
  for (final row in rows)
    if (siteFromRow(row, placements) case final site?)
      CitySite(id: row.id, site: site),
];
