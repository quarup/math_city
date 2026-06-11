import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/category.dart';
import 'package:math_city/domain/city/unlock_rule.dart';

/// Building catalog, authored against `city_builder.md §3` (the §3 row is the
/// source of truth for costs / footprints / unlock rules). Phase 7 shipped the
/// first 10; Phase 9 grows the list building-by-building as sprite art lands.
/// `numVariants: 0` means no art yet — the renderer keeps the Phase-7
/// box+emoji placeholder (a few such rows exist purely as DAG prereqs for
/// art-backed buildings further up their arc).
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
    footprint: (2, 2),
    numVariants: 1,
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
    numVariants: 6,
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
    footprint: (2, 2),
    numVariants: 5,
  ),
  BuildingType(
    id: 'school',
    name: 'School',
    emoji: '🏫',
    // §3.2: education moved from civicHousing to services (2026-05-31
    // city_builder.md decision; the one-field change Phase 9 applies).
    category: BuildingCategory.services,
    brickCost: 10,
    researchCost: 1,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'mayors_office'},
      requiredBeatsRead: <String>{'demand_school'},
    ),
    serviceProvision: <String, int>{'school': 60},
    footprint: (2, 3),
    numVariants: 2,
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
    // §3 said 1×2 pre-art; both NB raws are drawn on a square lot, so the
    // footprint was bumped to 2×2 (§3 updated to match, 2026-06-12).
    footprint: (2, 2),
    numVariants: 2,
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
    footprint: (2, 2),
    numVariants: 2,
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
    footprint: (2, 2),
    numVariants: 2,
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
    numVariants: 4,
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

  // ======================================================================
  // Phase 9 catalog growth (city_builder.md §3) — civic & housing arc
  // ======================================================================
  BuildingType(
    id: 'town_hall',
    name: 'Town hall',
    emoji: '🏤',
    category: BuildingCategory.civicHousing,
    brickCost: 30,
    researchCost: 2,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'mayors_office'},
      minPopulation: 20,
      requiredBeatsRead: <String>{'demand_town_hall'},
    ),
    footprint: (3, 2),
    numVariants: 1,
    unique: true,
  ),
  BuildingType(
    id: 'city_hall',
    name: 'City hall',
    emoji: '🏙️',
    category: BuildingCategory.civicHousing,
    brickCost: 80,
    researchCost: 3,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'town_hall'},
      minPopulation: 80,
      requiredBeatsRead: <String>{'demand_city_hall'},
    ),
    footprint: (3, 3),
    numVariants: 1,
    unique: true,
  ),
  BuildingType(
    id: 'library',
    name: 'Library',
    emoji: '📚',
    category: BuildingCategory.civicHousing,
    brickCost: 20,
    researchCost: 2,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'school'},
      requiredBeatsRead: <String>{'demand_library'},
    ),
    footprint: (2, 2),
    numVariants: 2,
  ),
  BuildingType(
    id: 'post_office',
    name: 'Post office',
    emoji: '📮',
    category: BuildingCategory.civicHousing,
    brickCost: 20,
    researchCost: 2,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'town_hall'},
      requiredBeatsRead: <String>{'demand_post_office'},
    ),
    footprint: (2, 1),
    numVariants: 2,
  ),
  BuildingType(
    id: 'duplex',
    name: 'Duplex',
    emoji: '🏘️',
    category: BuildingCategory.civicHousing,
    brickCost: 10,
    researchCost: 1,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'single_home'},
      requiredBeatsRead: <String>{'demand_duplex'},
    ),
    populationContribution: 8,
    footprint: (2, 1),
    numVariants: 4,
  ),
  BuildingType(
    id: 'townhouse_row',
    name: 'Townhouse row',
    emoji: '🏘️',
    category: BuildingCategory.civicHousing,
    brickCost: 20,
    researchCost: 2,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'duplex'},
      minPopulation: 12,
      requiredBeatsRead: <String>{'demand_townhouse_row'},
    ),
    populationContribution: 12,
    footprint: (1, 3),
    numVariants: 3,
  ),
  BuildingType(
    id: 'mid_rise_apartment',
    name: 'Mid-rise apartment',
    emoji: '🏢',
    category: BuildingCategory.civicHousing,
    brickCost: 30,
    researchCost: 2,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'apartment'},
      minPopulation: 30,
      requiredBeatsRead: <String>{'demand_mid_rise'},
    ),
    populationContribution: 30,
    footprint: (2, 3),
  ),
  BuildingType(
    id: 'high_rise',
    name: 'High-rise',
    emoji: '🌆',
    category: BuildingCategory.civicHousing,
    brickCost: 60,
    researchCost: 3,
    unlockRule: UnlockRule(
      minLifetimeBricks: 300,
      requiredBuildingsPlaced: <String>{'mid_rise_apartment'},
      minPopulation: 60,
      requiredBeatsRead: <String>{'demand_high_rise'},
    ),
    populationContribution: 60,
    footprint: (3, 3),
    numVariants: 3,
  ),
  BuildingType(
    id: 'luxury_condo',
    name: 'Luxury condo',
    emoji: '🏨',
    category: BuildingCategory.civicHousing,
    brickCost: 100,
    researchCost: 3,
    unlockRule: UnlockRule(
      minLifetimeBricks: 500,
      requiredBuildingsPlaced: <String>{'high_rise'},
      requiredBeatsRead: <String>{'demand_luxury_condo'},
    ),
    populationContribution: 50,
    varietyContribution: true,
    footprint: (3, 3),
    numVariants: 2,
  ),
  BuildingType(
    id: 'farmhouse',
    name: 'Farmhouse',
    emoji: '🏡',
    category: BuildingCategory.civicHousing,
    brickCost: 8,
    researchCost: 1,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'single_home'},
      requiredBeatsRead: <String>{'demand_farmhouse'},
    ),
    populationContribution: 3,
    footprint: (2, 2),
    numVariants: 3,
  ),

  // ======================================================================
  // Phase 9 catalog growth — services (power + water arcs)
  // ======================================================================
  BuildingType(
    id: 'power_station',
    name: 'Power station',
    emoji: '🏭',
    category: BuildingCategory.services,
    brickCost: 40,
    researchCost: 3,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'power_plant'},
      minPopulation: 40,
      requiredBeatsRead: <String>{'demand_power_station'},
    ),
    serviceProvision: <String, int>{'power': 500},
    varietyContribution: true,
    footprint: (3, 3),
    numVariants: 1,
  ),
  BuildingType(
    id: 'solar_farm',
    name: 'Solar farm',
    emoji: '☀️',
    category: BuildingCategory.services,
    brickCost: 70,
    researchCost: 3,
    unlockRule: UnlockRule(
      minLifetimeBricks: 400,
      requiredBuildingsPlaced: <String>{'power_station'},
      requiredBeatsRead: <String>{'demand_solar_farm'},
    ),
    serviceProvision: <String, int>{'power': 800},
    varietyContribution: true,
    footprint: (4, 4),
    numVariants: 1,
  ),
  BuildingType(
    id: 'water_tower',
    name: 'Water tower',
    emoji: '🚰',
    category: BuildingCategory.services,
    brickCost: 10,
    researchCost: 1,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'single_home'},
      requiredBeatsRead: <String>{'demand_water'},
    ),
    serviceProvision: <String, int>{'water': 150},
    varietyContribution: true,
    numVariants: 2,
  ),
  BuildingType(
    id: 'water_treatment',
    name: 'Water treatment',
    emoji: '💧',
    category: BuildingCategory.services,
    brickCost: 40,
    researchCost: 3,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'water_tower'},
      minPopulation: 40,
      requiredBeatsRead: <String>{'demand_water_treatment'},
    ),
    serviceProvision: <String, int>{'water': 500},
    varietyContribution: true,
    footprint: (3, 3),
    numVariants: 1,
  ),
  BuildingType(
    id: 'recycling_center',
    name: 'Recycling center',
    emoji: '♻️',
    category: BuildingCategory.services,
    brickCost: 40,
    researchCost: 3,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'waste_management'},
      minPopulation: 40,
      requiredBeatsRead: <String>{'demand_recycling'},
    ),
    serviceProvision: <String, int>{'waste': 400},
    varietyContribution: true,
    footprint: (2, 3),
    numVariants: 1,
  ),
  BuildingType(
    id: 'hospital',
    name: 'Hospital',
    emoji: '🚑',
    category: BuildingCategory.services,
    brickCost: 60,
    researchCost: 3,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'clinic'},
      minPopulation: 60,
      requiredBeatsRead: <String>{'demand_hospital'},
    ),
    serviceProvision: <String, int>{'clinic': 200},
    varietyContribution: true,
    footprint: (3, 3),
    numVariants: 1,
  ),

  // ======================================================================
  // Phase 9 catalog growth — entertainment arc (culture + capstones)
  // ======================================================================
  BuildingType(
    id: 'sports_field',
    name: 'Sports field',
    emoji: '⚽',
    category: BuildingCategory.entertainment,
    brickCost: 25,
    researchCost: 2,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'school'},
      requiredBeatsRead: <String>{'demand_sports_field'},
    ),
    varietyContribution: true,
    footprint: (3, 2),
  ),
  BuildingType(
    id: 'museum',
    name: 'Museum',
    emoji: '🏛️',
    category: BuildingCategory.entertainment,
    brickCost: 50,
    researchCost: 3,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'library'},
      requiredBeatsRead: <String>{'demand_museum'},
    ),
    varietyContribution: true,
    footprint: (3, 3),
  ),
  BuildingType(
    id: 'stadium',
    name: 'Stadium',
    emoji: '🏟️',
    category: BuildingCategory.entertainment,
    brickCost: 90,
    researchCost: 3,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'sports_field'},
      minPopulation: 80,
      requiredBeatsRead: <String>{'demand_stadium'},
    ),
    varietyContribution: true,
    footprint: (4, 4),
  ),
  BuildingType(
    id: 'aquarium',
    name: 'Aquarium',
    emoji: '🐠',
    category: BuildingCategory.entertainment,
    brickCost: 120,
    researchCost: 5,
    unlockRule: UnlockRule(
      requiredBuildingsPlaced: <String>{'museum'},
      minPopulation: 100,
      requiredBeatsRead: <String>{'demand_aquarium'},
    ),
    varietyContribution: true,
    footprint: (4, 3),
    numVariants: 1,
  ),
  BuildingType(
    id: 'amusement_park',
    name: 'Amusement park',
    emoji: '🎢',
    category: BuildingCategory.entertainment,
    brickCost: 200,
    researchCost: 5,
    unlockRule: UnlockRule(
      minLifetimeBricks: 800,
      requiredBuildingsPlaced: <String>{'stadium'},
      minPopulation: 120,
      requiredBeatsRead: <String>{'demand_amusement_park'},
    ),
    varietyContribution: true,
    footprint: (6, 6),
    numVariants: 2,
  ),
  BuildingType(
    id: 'observation_tower',
    name: 'Observation tower',
    emoji: '🗼',
    category: BuildingCategory.entertainment,
    brickCost: 250,
    researchCost: 5,
    unlockRule: UnlockRule(
      minLifetimeBricks: 1000,
      requiredBuildingsPlaced: <String>{'city_hall'},
      requiredBeatsRead: <String>{'demand_observation_tower'},
    ),
    varietyContribution: true,
    footprint: (2, 2),
    numVariants: 1,
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
