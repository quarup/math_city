import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/category.dart';
import 'package:math_city/domain/city/unlock_rule.dart';

/// Phase 7 building catalog — the 10-building "simple DAG proof" set.
/// Costs are placeholders (10 🧱 / 1 🔬 with a few overrides) chosen to
/// exercise the mechanics; real numbers are tuned in Phase 8 / 9 from play.
///
/// Mayor's office is free and ungated so every player can place it on turn
/// one. Single home costs 5 🧱 to place and 1 🔬 to research, so the very
/// first 🔬 award (band-crossing on a starter concept) unlocks the research
/// card and a handful of correct answers afterward earns the bricks to
/// place the first house.
const buildingRegistry = <BuildingType>[
  // -- Civic & housing ---------------------------------------------------
  BuildingType(
    id: 'mayors_office',
    name: "Mayor's office",
    emoji: '🏛️',
    category: BuildingCategory.civicHousing,
    brickCost: 0,
    researchCost: 0,
    unlockRule: UnlockRule.open,
    unique: true,
  ),
  BuildingType(
    id: 'single_home',
    name: 'Single home',
    emoji: '🏠',
    category: BuildingCategory.civicHousing,
    brickCost: 5,
    researchCost: 1,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'mayors_office'},
      requiredBeatsRead: <String>{'demand_first_home'},
    ),
    populationContribution: 4,
  ),
  BuildingType(
    id: 'apartment',
    name: 'Apartment',
    emoji: '🏢',
    category: BuildingCategory.civicHousing,
    brickCost: 10,
    researchCost: 1,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'mayors_office'},
      requiredBeatsRead: <String>{'demand_apartment'},
    ),
    populationContribution: 16,
  ),
  BuildingType(
    id: 'school',
    name: 'School',
    emoji: '🏫',
    category: BuildingCategory.civicHousing,
    brickCost: 10,
    researchCost: 1,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'mayors_office'},
      requiredBeatsRead: <String>{'demand_school'},
    ),
    serviceProvision: <String, int>{'school': 60},
  ),
  // -- Services ----------------------------------------------------------
  BuildingType(
    id: 'clinic',
    name: 'Clinic',
    emoji: '🏥',
    category: BuildingCategory.services,
    brickCost: 10,
    researchCost: 1,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'mayors_office'},
      requiredBeatsRead: <String>{'demand_clinic'},
    ),
    serviceProvision: <String, int>{'clinic': 50},
    varietyContribution: true,
  ),
  BuildingType(
    id: 'power_plant',
    name: 'Power plant',
    emoji: '⚡',
    category: BuildingCategory.services,
    brickCost: 10,
    researchCost: 1,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'mayors_office'},
      requiredBeatsRead: <String>{'demand_power'},
    ),
    serviceProvision: <String, int>{'power': 200},
    varietyContribution: true,
  ),
  BuildingType(
    id: 'waste_management',
    name: 'Waste management',
    emoji: '🚮',
    category: BuildingCategory.services,
    brickCost: 10,
    researchCost: 1,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'mayors_office'},
      requiredBeatsRead: <String>{'demand_waste'},
    ),
    serviceProvision: <String, int>{'waste': 150},
    varietyContribution: true,
  ),
  // -- Commercial -------------------------------------------------------
  BuildingType(
    id: 'grocery',
    name: 'Grocery',
    emoji: '🛒',
    category: BuildingCategory.commercial,
    brickCost: 10,
    researchCost: 1,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'mayors_office'},
      requiredBeatsRead: <String>{'demand_grocery'},
    ),
    varietyContribution: true,
  ),
  BuildingType(
    id: 'coffee_shop',
    name: 'Coffee shop',
    emoji: '☕',
    category: BuildingCategory.commercial,
    brickCost: 10,
    researchCost: 1,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'mayors_office'},
      requiredBeatsRead: <String>{'demand_coffee_shop'},
    ),
    varietyContribution: true,
  ),
  // -- Entertainment ----------------------------------------------------
  BuildingType(
    id: 'park',
    name: 'Park',
    emoji: '🌳',
    category: BuildingCategory.entertainment,
    brickCost: 10,
    researchCost: 1,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'mayors_office'},
      requiredBeatsRead: <String>{'demand_more_parks'},
    ),
    varietyContribution: true,
  ),
];

BuildingType? findBuildingTypeById(String id) {
  for (final b in buildingRegistry) {
    if (b.id == id) return b;
  }
  return null;
}

/// Building types that should be pre-researched at city creation: any with
/// `researchCost == 0` whose `unlockRule` is trivially satisfied by an empty
/// starting state. In v1 this is just the mayor's office.
Iterable<BuildingType> get preResearchedBuildings => buildingRegistry.where(
  (b) =>
      b.researchCost == 0 &&
      b.unlockRule.evaluate(
        const UnlockContext(
          lifetimeBricksEarned: 0,
          population: 0,
          placedBuildingTypeIds: <String>{},
          readBeatIds: <String>{},
        ),
      ),
);
