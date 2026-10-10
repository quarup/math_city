import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/category.dart';
import 'package:math_city/domain/city/population_model.dart';
import 'package:math_city/domain/city/story_beat.dart';

/// What a balance warning (city_builder.md §4.3) would have the player
/// build, and the sentence that says why in numbers. The two warnings —
/// "no homes!" and "stuck" — have no single building behind them the way a
/// demand does: any home fixes the first, and the second is fixed by
/// whichever gating service is the thinnest. This resolves them to one
/// concrete, buildable thing so the front page can offer *Build it!* like
/// an ask, and the story can say "9 shops and only 2 homes" instead of
/// "check your power, water, clinics, and trash".
class WarningFix {
  const WarningFix({required this.building, required this.story});

  /// The cheapest building in the player's catalog that moves the number.
  final BuildingType building;

  /// Kid-facing headline with the numbers, replacing the beat's static text.
  final String story;
}

/// Kid-facing name of a gating service, for "the … is full".
String gatingServiceName(String serviceId) => switch (serviceId) {
  'power' => 'power',
  'clinic' => 'clinic',
  'waste' => 'trash pickup',
  'water' => 'water',
  _ => serviceId,
};

/// The fix for [beat] given the city as it stands, or null when the beat is
/// not a balance warning, the city isn't out of balance that way, or
/// nothing in [catalog] can fix it yet. A warning with no fix must not be
/// shown at all — a page the player can't act on is worse than none.
///
/// [placed] is one [BuildingType] per placement; [catalog] is what the
/// player can start right now (unlocked, not upgrade-only, not a placed
/// unique).
WarningFix? warningFixFor(
  StoryBeat beat, {
  required List<BuildingType> placed,
  required int population,
  required List<BuildingType> catalog,
}) {
  final rule = beat.triggerRule;
  if (!rule.requiresLopsided && !rule.requiresGrowthStalled) return null;
  final balance = cityBalance(placed, population);
  if (rule.requiresLopsided) {
    return balance.lopsided ? _lopsidedFix(placed, catalog) : null;
  }
  if (!balance.growthStalled) return null;
  return _stalledFix(placed, population, catalog);
}

BuildingType? _cheapest(Iterable<BuildingType> options) {
  BuildingType? best;
  for (final b in options) {
    if (best == null || b.coinCost < best.coinCost) best = b;
  }
  return best;
}

bool _isHome(BuildingType b) => b.populationContribution > 0;

bool _isAmenity(BuildingType b) =>
    b.category == BuildingCategory.commercial ||
    b.category == BuildingCategory.entertainment;

String _plural(int n, String one, String many) => n == 1 ? one : many;

/// Shops and attractions outnumber homes past the ratio: the cheapest home
/// in the catalog, and how many of them close the gap.
WarningFix? _lopsidedFix(
  List<BuildingType> placed,
  List<BuildingType> catalog,
) {
  final home = _cheapest(catalog.where(_isHome));
  if (home == null) return null;
  final homes = placed.where(_isHome).length;
  final amenities = placed.where(_isAmenity).length;
  // Balanced again once amenities ≤ ratio × homes.
  final homesWanted =
      (amenities + lopsidedAmenityToHousingRatio - 1) ~/
      lopsidedAmenityToHousingRatio;
  final more = (homesWanted - homes).clamp(1, 99);
  final story =
      '$amenities shops and attractions and only $homes '
      '${_plural(homes, 'home', 'homes')} — folks love to visit, but nobody '
      'can stay! $more more ${_plural(more, 'home', 'homes')} would even '
      'things out.';
  return WarningFix(building: home, story: story);
}

/// Population has hit a ceiling a gating service holds down: the thinnest
/// service, how full it is, and the cheapest building that provides it.
WarningFix? _stalledFix(
  List<BuildingType> placed,
  int population,
  List<BuildingType> catalog,
) {
  final totals = <String, int>{};
  var housing = 0;
  for (final b in placed) {
    housing += b.populationContribution;
    b.serviceProvision.forEach((id, cap) {
      totals[id] = (totals[id] ?? 0) + cap;
    });
  }
  String? thinnest;
  var thinnestCap = housing;
  for (final id in gatingServiceIds) {
    final cap = serviceFreeAllowance + (totals[id] ?? 0);
    if (cap < thinnestCap) {
      thinnest = id;
      thinnestCap = cap;
    }
  }
  // No service below the homes' own ceiling: the lopsidedness penalty is
  // what's holding growth down, so a home is the fix after all.
  if (thinnest == null) return _lopsidedFix(placed, catalog);
  final service = thinnest;
  final provider = _cheapest(
    catalog.where((b) => (b.serviceProvision[service] ?? 0) > 0),
  );
  if (provider == null) return null;
  final name = gatingServiceName(service);
  final story =
      '${_capitalise(name)} is maxed out: $population people and room for '
      '$thinnestCap. ${_withArticle(provider.name)} would make room for more.';
  return WarningFix(building: provider, story: story);
}

String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _withArticle(String noun) {
  final lower = noun.toLowerCase();
  final article = 'aeiou'.contains(lower[0]) ? 'An' : 'A';
  return '$article $lower';
}
