import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/domain/city/trigger_rule.dart';

/// Phase 7 sample beats — just enough to exercise the BeatEngine in tests.
/// The full hand-written ~5–10 set lands in a follow-up Phase 7 chunk; the
/// rich hundreds-of-beats catalog is Phase 8 / 9.
const beatRegistry = <StoryBeat>[
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
];

StoryBeat? findBeatById(String id) {
  for (final b in beatRegistry) {
    if (b.id == id) return b;
  }
  return null;
}
