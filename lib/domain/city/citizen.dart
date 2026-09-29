/// The cast of Math City — the named citizens whose letters carry the story
/// (city_builder.md §10.8). Ten people, each with a face composed from an
/// `AdventurerConfig` (the same avatar system the player uses, so a cast
/// costs a config each and no art), each tied to an arc of the building
/// catalog. Every story beat resolves to exactly one of them: an explicit
/// `StoryBeat.citizen` first, else the citizen who "owns" the building the
/// beat is about, else the town clerk.
///
/// Pure Dart: no Flutter / Flame / Drift imports.
library;

import 'dart:math';

import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/story_beat.dart';

class Citizen {
  const Citizen({
    required this.id,
    required this.name,
    required this.role,
    required this.face,
  });

  final String id;

  /// How the letter header names them ("Mrs. Pomeroy").
  final String name;

  /// One-line flavour under the name in the letter header.
  final String role;

  final AdventurerConfig face;
}

/// A seeded random face: the same config on every launch, so a citizen
/// always looks like themselves without hand-picking catalog indices.
AdventurerConfig _face(int seed) =>
    AdventurerConfig.random(random: Random(seed));

/// The letter "from everyone" (the chapter-one hand-over, §10.4) is signed
/// by this pseudo-citizen; the letter card draws the whole cast instead of
/// one face when it sees this id.
const kTownCitizenId = 'town';

/// Everyone in Math City, as one signer. Not in [castRegistry] (nothing is
/// "owned" by the town); resolved by [findCitizenById].
final townCitizen = Citizen(
  id: kTownCitizenId,
  name: 'The whole town',
  role: 'everyone in Math City',
  face: _face(0),
);

final castRegistry = <Citizen>[
  Citizen(
    id: 'pomeroy',
    name: 'Mrs. Pomeroy',
    role: 'and her cat, Biscuit',
    face: _face(1),
  ),
  Citizen(
    id: 'alvarez',
    name: 'Mr. Alvarez',
    role: 'grows avocados',
    face: _face(2),
  ),
  Citizen(
    id: 'okafor',
    name: 'Dr. Okafor',
    role: 'the town doctor',
    face: _face(3),
  ),
  Citizen(
    id: 'diaz',
    name: 'Coach Diaz',
    role: 'never stops running',
    face: _face(4),
  ),
  Citizen(
    id: 'lin',
    name: 'Ms. Lin',
    role: 'the librarian',
    face: _face(5),
  ),
  Citizen(
    id: 'maya',
    name: 'Maya',
    role: 'age 7, expert climber',
    face: _face(6),
  ),
  Citizen(
    id: 'bo',
    name: 'Farmer Bo',
    role: 'chickens, mostly',
    face: _face(7),
  ),
  Citizen(
    id: 'hattie',
    name: 'Clerk Hattie',
    role: 'runs the town hall',
    face: _face(8),
  ),
  Citizen(
    id: 'pip',
    name: 'Pip',
    role: 'plans the parties',
    face: _face(9),
  ),
  Citizen(
    id: 'grumbold',
    name: 'Mr. Grumbold',
    role: 'has concerns',
    face: _face(10),
  ),
];

Citizen? findCitizenById(String id) {
  if (id == kTownCitizenId) return townCitizen;
  for (final c in castRegistry) {
    if (c.id == id) return c;
  }
  return null;
}

/// Which citizen speaks for which building. Anything not listed falls to the
/// town clerk.
const _citizenByBuilding = <String, String>{
  // Homes — Mrs. Pomeroy.
  'single_home': 'pomeroy',
  'duplex': 'pomeroy',
  'townhouse_row': 'pomeroy',
  'apartment': 'pomeroy',
  'mid_rise_apartment': 'pomeroy',
  'high_rise': 'pomeroy',
  'luxury_condo': 'alvarez',
  'farmhouse': 'bo',
  // Shops — Mr. Alvarez, food and market things Farmer Bo.
  'market_stall': 'bo',
  'grocery': 'alvarez',
  'supermarket': 'alvarez',
  'bakery': 'alvarez',
  'coffee_shop': 'alvarez',
  'restaurant': 'alvarez',
  'farmers_market': 'bo',
  'toy_store': 'maya',
  'clothing_store': 'alvarez',
  'shopping_mall': 'alvarez',
  'bookshop': 'lin',
  'office_building': 'hattie',
  'business_tower': 'hattie',
  // Health.
  'clinic': 'okafor',
  'hospital': 'okafor',
  // Learning and culture — Ms. Lin, the school is Maya's.
  'school': 'maya',
  'high_school': 'lin',
  'library': 'lin',
  'museum': 'lin',
  'aquarium': 'lin',
  // Sport and play.
  'sports_field': 'diaz',
  'swimming_pool': 'diaz',
  'gym': 'diaz',
  'stadium': 'diaz',
  'playground': 'maya',
  'park': 'maya',
  'amusement_park': 'maya',
  'zoo': 'maya',
  // Green things.
  'community_garden': 'bo',
  'botanical_garden': 'bo',
  'solar_farm': 'bo',
  'recycling_center': 'bo',
  // Civic — Clerk Hattie.
  'town_hall': 'hattie',
  'city_hall': 'hattie',
  'post_office': 'hattie',
  'fire_station': 'hattie',
  'police_station': 'hattie',
  'bus_depot': 'hattie',
  'fountain_plaza': 'hattie',
  'observation_tower': 'hattie',
  'movie_theater': 'pip',
  // Utilities — Mr. Grumbold notices when they're missing.
  'power_plant': 'grumbold',
  'power_station': 'grumbold',
  'water_tower': 'grumbold',
  'water_treatment': 'grumbold',
  'waste_management': 'grumbold',
};

/// The building a beat is about: for a demand, the building whose unlock
/// rule names this beat (the discovery gate), falling back to the single
/// building the trigger wants absent; for praise, the single building the
/// trigger wants present. Null for beats about the town as a whole
/// (milestones, ratio warnings).
BuildingType? beatTargetBuilding(StoryBeat beat) {
  if (beat.kind == BeatKind.demand) {
    for (final b in buildingRegistry) {
      if (b.unlockRule.requiredBeatsRead.contains(beat.id)) return b;
    }
    final absent = beat.triggerRule.buildingsAbsent;
    if (absent.length == 1) return findBuildingTypeById(absent.first);
    // A recurring demand (more parks) wants nothing absent; the building it
    // asks for is the one whose card it reveals — handled above — so only
    // the multi-absent first-home beat lands here: it asks for a home.
    if (absent.isNotEmpty) return findBuildingTypeById(absent.first);
    return null;
  }
  if (beat.kind == BeatKind.praise) {
    final present = beat.triggerRule.buildingsPresent;
    if (present.length == 1) return findBuildingTypeById(present.first);
  }
  return null;
}

/// The citizen who signs [beat]'s letter. Explicit `StoryBeat.citizen`
/// first; else the owner of the building the beat is about; warnings go to
/// Mr. Grumbold; anything else to the town clerk.
Citizen citizenForBeat(StoryBeat beat) {
  final explicit = beat.citizen;
  if (explicit != null) {
    final c = findCitizenById(explicit);
    if (c != null) return c;
  }
  if (beat.kind == BeatKind.warning) return findCitizenById('grumbold')!;
  final target = beatTargetBuilding(beat);
  final owner = target == null ? null : _citizenByBuilding[target.id];
  return findCitizenById(owner ?? 'hattie')!;
}
