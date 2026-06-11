import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/domain/city/trigger_rule.dart';

/// Phase 7 hand-written beat set (~the "simple DAG proof" sampler). Covers the
/// shapes the engine needs to exercise: pre-unlock service demands, a recurring
/// demand, an anti-prereq warning, post-placement commercial praise, and an
/// age + prior-beat gated milestone. The rich hundreds-of-beats catalog is
/// Phase 8 / 9. Text is kid-friendly with a deliberate silly/civic/cozy mix.
///
/// Each "demand" beat doubles as the unlock gate for the building it asks for:
/// a building's `requiredBeatsRead` lists its demand beat, so the building's
/// research card only appears once the player has opened (read) that ask. See
/// `building_registry.dart`.
const beatRegistry = <StoryBeat>[
  // -- Housing --------------------------------------------------------------
  StoryBeat(
    id: 'demand_first_home',
    kind: BeatKind.demand,
    tone: BeatTone.cozy,
    emoji: '🏠',
    shortLabel: 'a home!',
    longText:
        "We've got a mayor's office but nowhere to live yet — could we get "
        'a house, please?',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'mayors_office'},
      buildingsAbsent: <String>{'single_home', 'apartment'},
    ),
  ),
  StoryBeat(
    id: 'praise_first_home',
    kind: BeatKind.praise,
    tone: BeatTone.silly,
    emoji: '🎉',
    shortLabel: 'home sweet home',
    longText:
        'The new home is cozy! Mrs. Pomeroy moved her cat in already — '
        'she sends thanks.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
    ),
  ),
  StoryBeat(
    id: 'demand_school',
    kind: BeatKind.demand,
    tone: BeatTone.civic,
    emoji: '🏫',
    shortLabel: 'a school?',
    longText:
        'The neighborhood kids have nowhere to practice their math — could we '
        'build a school?',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
      buildingsAbsent: <String>{'school'},
    ),
  ),
  StoryBeat(
    id: 'demand_apartment',
    kind: BeatKind.demand,
    tone: BeatTone.cozy,
    emoji: '🏢',
    shortLabel: 'more homes!',
    longText:
        'More families want to move in but every house is full — an apartment '
        'block would give them somewhere to live.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
      buildingsAbsent: <String>{'apartment'},
      minPopulation: 8,
    ),
  ),

  // -- Service demands (fire once there are residents but the service is
  //    missing — these nudge the player to research + build it) -------------
  StoryBeat(
    id: 'demand_clinic',
    kind: BeatKind.demand,
    tone: BeatTone.civic,
    emoji: '🏥',
    shortLabel: 'a clinic?',
    longText:
        "Someone tripped chasing the ice-cream truck and there's nowhere to "
        'get a bandage — could we build a clinic?',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
      buildingsAbsent: <String>{'clinic'},
    ),
  ),
  StoryBeat(
    id: 'demand_power',
    kind: BeatKind.demand,
    tone: BeatTone.civic,
    emoji: '⚡',
    shortLabel: 'power!',
    longText:
        'The lights keep flickering and the fridges are getting warm — the '
        'town really needs a power plant.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
      buildingsAbsent: <String>{'power_plant'},
    ),
  ),
  StoryBeat(
    id: 'demand_waste',
    kind: BeatKind.warning,
    tone: BeatTone.civic,
    emoji: '🚮',
    shortLabel: 'trash!',
    longText:
        'The neighborhood is tired of stepping over garbage — we need a Waste '
        'Management facility before it gets any worse!',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
      buildingsAbsent: <String>{'waste_management'},
      minPopulation: 12,
    ),
  ),

  // -- Commercial demands (pre-placement asks that gate the shops) ----------
  StoryBeat(
    id: 'demand_grocery',
    kind: BeatKind.demand,
    tone: BeatTone.cozy,
    emoji: '🛒',
    shortLabel: 'groceries?',
    longText:
        'Folks are tired of driving far for milk and bread — a grocery store '
        'would be so handy.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
      buildingsAbsent: <String>{'grocery'},
    ),
  ),
  StoryBeat(
    id: 'demand_coffee_shop',
    kind: BeatKind.demand,
    tone: BeatTone.cozy,
    emoji: '☕',
    shortLabel: 'coffee?',
    longText:
        'A cozy coffee shop would give everyone a warm place to meet up — '
        'what do you think?',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
      buildingsAbsent: <String>{'coffee_shop'},
    ),
  ),

  // -- Recurring demand (re-fires with brick spacing, even after a park
  //    exists — see prd.md: beats can recur post-build) ----------------------
  StoryBeat(
    id: 'demand_more_parks',
    kind: BeatKind.demand,
    tone: BeatTone.cozy,
    emoji: '🌳',
    shortLabel: 'a park?',
    longText:
        "The town's feeling a little grey — a new park would brighten "
        "everyone's day.",
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
      minBricksEarnedSinceLastBeat: 150,
    ),
  ),

  // -- Commercial praise (post-placement) -----------------------------------
  StoryBeat(
    id: 'praise_grocery',
    kind: BeatKind.praise,
    tone: BeatTone.silly,
    emoji: '🛒',
    shortLabel: 'yum!',
    longText:
        'The new grocery is a hit — Mr. Alvarez bought twelve avocados and '
        "won't say why.",
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'grocery'},
    ),
  ),
  StoryBeat(
    id: 'praise_coffee_shop',
    kind: BeatKind.praise,
    tone: BeatTone.cozy,
    emoji: '☕',
    shortLabel: 'cozy!',
    longText:
        'The coffee shop smells amazing — half the town is in there swapping '
        'stories.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'coffee_shop'},
    ),
  ),

  // -- Milestone (age + prior-beat gated) -----------------------------------
  StoryBeat(
    id: 'praise_established_town',
    kind: BeatKind.praise,
    tone: BeatTone.civic,
    emoji: '🏙️',
    shortLabel: 'looking good!',
    longText:
        "The town's really taking shape — folks are proud to call it home. "
        'Nice work, Mayor!',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
      minBuildingAgeForId: (buildingTypeId: 'mayors_office', minRounds: 10),
      requiredBeatsFired: <String>{'praise_first_home'},
    ),
  ),

  // ==========================================================================
  // Phase 9 catalog growth (city_builder.md §4) — housing-arc demands
  // ==========================================================================
  StoryBeat(
    id: 'demand_duplex',
    kind: BeatKind.demand,
    tone: BeatTone.cozy,
    emoji: '🏘️',
    shortLabel: 'share a yard',
    longText:
        'Two families want to share a yard — a duplex would fit them both '
        'nicely.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
      buildingsAbsent: <String>{'duplex'},
    ),
  ),
  StoryBeat(
    id: 'demand_townhouse_row',
    kind: BeatKind.demand,
    tone: BeatTone.cozy,
    emoji: '🏘️',
    shortLabel: 'row houses',
    longText:
        'Lots of folks want to live close together — how about a row of '
        'townhouses?',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'duplex'},
      buildingsAbsent: <String>{'townhouse_row'},
      minPopulation: 12,
    ),
  ),
  StoryBeat(
    id: 'demand_mid_rise',
    kind: BeatKind.demand,
    tone: BeatTone.cozy,
    emoji: '🏢',
    shortLabel: 'go taller',
    longText:
        'The apartment filled up in a flash — a taller mid-rise would house '
        'even more.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'apartment'},
      buildingsAbsent: <String>{'mid_rise_apartment'},
      minPopulation: 30,
    ),
  ),
  StoryBeat(
    id: 'demand_high_rise',
    kind: BeatKind.demand,
    tone: BeatTone.civic,
    emoji: '🌆',
    shortLabel: 'to the sky',
    longText:
        'People are lining up to move in — a high-rise tower would reach for '
        'the sky!',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'mid_rise_apartment'},
      buildingsAbsent: <String>{'high_rise'},
      minPopulation: 60,
    ),
  ),
  StoryBeat(
    id: 'demand_luxury_condo',
    kind: BeatKind.demand,
    tone: BeatTone.silly,
    emoji: '🏨',
    shortLabel: 'fancy!',
    longText:
        'Mr. Alvarez sold his avocados for a fortune and wants a fancy condo.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'high_rise'},
      buildingsAbsent: <String>{'luxury_condo'},
    ),
  ),
  StoryBeat(
    id: 'demand_farmhouse',
    kind: BeatKind.demand,
    tone: BeatTone.cozy,
    emoji: '🏡',
    shortLabel: 'chickens?',
    longText:
        'Someone wants chickens and a big garden — a farmhouse on the edge '
        'of town?',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
      buildingsAbsent: <String>{'farmhouse'},
    ),
  ),

  // -- Civic-core demands ----------------------------------------------------
  StoryBeat(
    id: 'demand_town_hall',
    kind: BeatKind.demand,
    tone: BeatTone.civic,
    emoji: '🏤',
    shortLabel: 'town hall',
    longText:
        "The mayor's office is bursting at the seams — a proper town hall "
        'would give the town a real heart.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
      buildingsAbsent: <String>{'town_hall'},
      minPopulation: 20,
    ),
  ),
  StoryBeat(
    id: 'demand_city_hall',
    kind: BeatKind.demand,
    tone: BeatTone.civic,
    emoji: '🏙️',
    shortLabel: 'a city!',
    longText:
        "The town's grown into a city — time for a grand city hall to run "
        'it all.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'town_hall'},
      buildingsAbsent: <String>{'city_hall'},
      minPopulation: 80,
    ),
  ),
  StoryBeat(
    id: 'demand_library',
    kind: BeatKind.demand,
    tone: BeatTone.cozy,
    emoji: '📚',
    shortLabel: 'books!',
    longText:
        'The kids have read every book in the school twice — can we build a '
        'library?',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'school'},
      buildingsAbsent: <String>{'library'},
    ),
  ),
  StoryBeat(
    id: 'demand_post_office',
    kind: BeatKind.demand,
    tone: BeatTone.civic,
    emoji: '📮',
    shortLabel: 'mail!',
    longText:
        'Letters are piling up at the town hall — a post office would sort '
        'things out.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'town_hall'},
      buildingsAbsent: <String>{'post_office'},
    ),
  ),

  // -- Service demands (water arc is new; ⚠ rows are warning-kind capacity
  //    asks, matching Phase 7's demand_waste) --------------------------------
  StoryBeat(
    id: 'demand_water',
    kind: BeatKind.warning,
    tone: BeatTone.civic,
    emoji: '🚰',
    shortLabel: 'water!',
    longText:
        'The taps are sputtering and the gardens are going brown — the town '
        'needs a water tower.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'single_home'},
      buildingsAbsent: <String>{'water_tower'},
    ),
  ),
  StoryBeat(
    id: 'demand_power_station',
    kind: BeatKind.warning,
    tone: BeatTone.civic,
    emoji: '🏭',
    shortLabel: 'brownouts',
    longText:
        "The power plant's maxed out and brownouts are spreading — a bigger "
        'power station would keep the lights on.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'power_plant'},
      buildingsAbsent: <String>{'power_station'},
      minPopulation: 40,
    ),
  ),
  StoryBeat(
    id: 'demand_solar_farm',
    kind: BeatKind.demand,
    tone: BeatTone.cozy,
    emoji: '☀️',
    shortLabel: 'go green',
    longText:
        'Why not go green? A solar farm would power the whole city from '
        'sunshine.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'power_station'},
      buildingsAbsent: <String>{'solar_farm'},
    ),
  ),
  StoryBeat(
    id: 'demand_water_treatment',
    kind: BeatKind.warning,
    tone: BeatTone.civic,
    emoji: '💧',
    shortLabel: 'clean water',
    longText:
        'More homes means more water — a treatment plant would keep it '
        'flowing and clean.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'water_tower'},
      buildingsAbsent: <String>{'water_treatment'},
      minPopulation: 40,
    ),
  ),
  StoryBeat(
    id: 'demand_recycling',
    kind: BeatKind.demand,
    tone: BeatTone.cozy,
    emoji: '♻️',
    shortLabel: 'recycle',
    longText:
        "We're throwing away things we could reuse — a recycling center "
        'would help the town go green.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'waste_management'},
      buildingsAbsent: <String>{'recycling_center'},
      minPopulation: 40,
    ),
  ),
  StoryBeat(
    id: 'demand_hospital',
    kind: BeatKind.warning,
    tone: BeatTone.civic,
    emoji: '🚑',
    shortLabel: 'hospital',
    longText:
        "The clinic can't keep up with everyone — the city really needs a "
        'proper hospital.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'clinic'},
      buildingsAbsent: <String>{'hospital'},
      minPopulation: 60,
    ),
  ),

  // -- Entertainment-arc demands ----------------------------------------------
  StoryBeat(
    id: 'demand_sports_field',
    kind: BeatKind.demand,
    tone: BeatTone.civic,
    emoji: '⚽',
    shortLabel: "let's play",
    longText:
        'The school kids need somewhere to run and play — a sports field!',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'school'},
      buildingsAbsent: <String>{'sports_field'},
    ),
  ),
  StoryBeat(
    id: 'demand_museum',
    kind: BeatKind.demand,
    tone: BeatTone.civic,
    emoji: '🏛️',
    shortLabel: 'our story',
    longText: "The town's got stories to tell — a museum would show them off.",
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'library'},
      buildingsAbsent: <String>{'museum'},
    ),
  ),
  StoryBeat(
    id: 'demand_stadium',
    kind: BeatKind.demand,
    tone: BeatTone.civic,
    emoji: '🏟️',
    shortLabel: 'go team!',
    longText:
        "The team's outgrown the field — a stadium would pack in the crowds!",
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'sports_field'},
      buildingsAbsent: <String>{'stadium'},
      minPopulation: 80,
    ),
  ),
  StoryBeat(
    id: 'demand_aquarium',
    kind: BeatKind.demand,
    tone: BeatTone.silly,
    emoji: '🐠',
    shortLabel: 'fishy',
    longText:
        "The museum's little fish tank started a craze — let's build a whole "
        'aquarium.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'museum'},
      buildingsAbsent: <String>{'aquarium'},
      minPopulation: 100,
    ),
  ),
  StoryBeat(
    id: 'demand_amusement_park',
    kind: BeatKind.demand,
    tone: BeatTone.silly,
    emoji: '🎢',
    shortLabel: 'coaster!',
    longText:
        'The whole city is chanting for a roller coaster — an amusement '
        'park!',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'stadium'},
      buildingsAbsent: <String>{'amusement_park'},
      minPopulation: 120,
    ),
  ),
  StoryBeat(
    id: 'demand_observation_tower',
    kind: BeatKind.demand,
    tone: BeatTone.civic,
    emoji: '🗼',
    shortLabel: 'the view',
    longText:
        "The city's so beautiful now — a tower to see it all from the very "
        'top.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'city_hall'},
      buildingsAbsent: <String>{'observation_tower'},
    ),
  ),

  // -- Phase 9 praise beats --------------------------------------------------
  StoryBeat(
    id: 'praise_school',
    kind: BeatKind.praise,
    tone: BeatTone.civic,
    emoji: '🔔',
    shortLabel: 'first bell',
    longText:
        'The school bell rang for the first time — the kids '
        "can't wait for math class!",
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'school'},
    ),
  ),
  StoryBeat(
    id: 'praise_town_hall',
    kind: BeatKind.praise,
    tone: BeatTone.civic,
    emoji: '🎀',
    shortLabel: 'ribbon cut',
    longText:
        'Ribbon cut! The new town hall already feels like the heart of the '
        'town.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'town_hall'},
    ),
  ),
  StoryBeat(
    id: 'praise_library',
    kind: BeatKind.praise,
    tone: BeatTone.cozy,
    emoji: '📚',
    shortLabel: 'storytime',
    longText:
        'Storytime at the library is packed — kids are reading more than '
        'ever.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'library'},
    ),
  ),
  StoryBeat(
    id: 'praise_hospital',
    kind: BeatKind.praise,
    tone: BeatTone.civic,
    emoji: '🚑',
    shortLabel: 'thank you',
    longText:
        'The new hospital is open and the doctors send their heartfelt '
        'thanks, Mayor.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'hospital'},
    ),
  ),
  StoryBeat(
    id: 'praise_recycling',
    kind: BeatKind.praise,
    tone: BeatTone.cozy,
    emoji: '♻️',
    shortLabel: 'green day',
    longText:
        "Recycling day is the neighborhood's new favorite — green and "
        'clean!',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'recycling_center'},
    ),
  ),
  StoryBeat(
    id: 'praise_solar_farm',
    kind: BeatKind.praise,
    tone: BeatTone.cozy,
    emoji: '☀️',
    shortLabel: 'sunshine',
    longText:
        'The solar farm gleams in the sun — the whole city runs on sunshine '
        'now.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'solar_farm'},
    ),
  ),
  StoryBeat(
    id: 'praise_high_rise',
    kind: BeatKind.praise,
    tone: BeatTone.silly,
    emoji: '🌆',
    shortLabel: 'what a view',
    longText:
        'Whoa — you can see the whole town from the top floor! Residents are '
        'thrilled.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'high_rise'},
    ),
  ),
  StoryBeat(
    id: 'praise_museum',
    kind: BeatKind.praise,
    tone: BeatTone.civic,
    emoji: '🏛️',
    shortLabel: 'grand opening',
    longText:
        "The museum's grand opening drew a line all the way around the "
        'block.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'museum'},
    ),
  ),
  StoryBeat(
    id: 'praise_stadium',
    kind: BeatKind.praise,
    tone: BeatTone.silly,
    emoji: '🏟️',
    shortLabel: 'the wave',
    longText:
        'The first game sold out — the crowd did the wave for ten whole '
        'minutes!',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'stadium'},
    ),
  ),
  StoryBeat(
    id: 'praise_amusement_park',
    kind: BeatKind.praise,
    tone: BeatTone.silly,
    emoji: '🎢',
    shortLabel: 'wheee!',
    longText:
        "The roller coaster's first riders are still grinning — what a day!",
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'amusement_park'},
    ),
  ),
  StoryBeat(
    id: 'praise_observation_tower',
    kind: BeatKind.praise,
    tone: BeatTone.cozy,
    emoji: '🗼',
    shortLabel: 'magical',
    longText:
        'From the tower the city looks magical at night. You built this, '
        'Mayor.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'observation_tower'},
    ),
  ),

  // -- Phase 9 milestone -----------------------------------------------------
  StoryBeat(
    id: 'milestone_big_city',
    kind: BeatKind.praise,
    tone: BeatTone.civic,
    emoji: '🌇',
    shortLabel: 'big city',
    longText:
        'From a single office to a whole skyline — what an incredible '
        'journey, Mayor.',
    triggerRule: TriggerRule(
      buildingsPresent: <String>{'high_rise'},
      minBuildingAgeForId: (buildingTypeId: 'mayors_office', minRounds: 40),
      requiredBeatsFired: <String>{'praise_established_town'},
    ),
  ),
];

StoryBeat? findBeatById(String id) {
  for (final b in beatRegistry) {
    if (b.id == id) return b;
  }
  return null;
}
