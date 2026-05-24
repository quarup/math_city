import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/domain/city/trigger_rule.dart';

/// Phase 7 hand-written beat set (~the "simple DAG proof" sampler). Covers the
/// shapes the engine needs to exercise: pre-unlock service demands, a recurring
/// demand, an anti-prereq warning, post-placement commercial praise, and an
/// age + prior-beat gated milestone. The rich hundreds-of-beats catalog is
/// Phase 8 / 9. Text is kid-friendly with a deliberate silly/civic/cozy mix.
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
];

StoryBeat? findBeatById(String id) {
  for (final b in beatRegistry) {
    if (b.id == id) return b;
  }
  return null;
}
