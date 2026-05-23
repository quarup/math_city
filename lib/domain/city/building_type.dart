import 'package:math_city/domain/city/category.dart';
import 'package:math_city/domain/city/unlock_rule.dart';

/// Pure-Dart description of a building type. Static catalog — see
/// `buildingRegistry` for the v1 set of ~10 types.
class BuildingType {
  const BuildingType({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.brickCost,
    required this.researchCost,
    required this.unlockRule,
    this.populationContribution = 0,
    this.serviceProvision = const <String, int>{},
    this.varietyContribution = false,
    this.footprint = const (1, 1),
    this.assetRef,
  });

  final String id;
  final String name;

  /// One-glyph stand-in for the building until Phase 9 ships real art. Drawn
  /// onto the placeholder tile by the Phase 7 CustomPainter.
  final String emoji;

  final BuildingCategory category;
  final int brickCost;
  final int researchCost;
  final UnlockRule unlockRule;

  /// Residents this building houses. Non-housing buildings are 0.
  final int populationContribution;

  /// Map of `serviceId -> capacity` (e.g. `{'clinic': 50}` = serves 50
  /// residents). Empty for non-service buildings.
  final Map<String, int> serviceProvision;

  /// Whether this type counts toward its category's variety multiplier.
  /// Civic-core/housing types typically don't (since their variety isn't
  /// celebrated); commercial / entertainment / services typically do.
  final bool varietyContribution;

  /// `(widthTiles, heightTiles)` on the city grid. Default 1×1.
  final (int, int) footprint;

  /// Opaque per-tier asset reference. Phase 7 resolves this string to a
  /// `CustomPainter` placeholder; Phase 9 swaps the resolver to PNG-loading
  /// without any domain-layer change.
  final String? assetRef;
}
