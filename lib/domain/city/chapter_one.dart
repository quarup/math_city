/// Chapter one — the scripted first ten minutes (city_builder.md §10.4).
///
/// Four letters in a fixed order — a home, then Mrs. Pomeroy asking for
/// it to be moved (the kid learns Move), then the school, then a park —
/// each fired the moment the previous step is done, then a hand-over
/// letter from the whole town; the beat engine and the folder bar stay
/// out of the way until it is done. The player's `guideStep` persists
/// where they are.
///
/// Pure Dart: no Flutter / Flame / Drift imports.
library;

/// The letter for each step, in order.
const chapterOneLetters = <String>[
  'demand_first_home',
  'tutorial_move_home',
  'demand_school',
  'demand_more_parks',
];

/// The building each step waits for before moving on; null for the move
/// step, which the state layer advances when the home is actually moved.
const chapterOneBuildings = <String?>['single_home', null, 'school', 'park'];

/// The step that waits for the home to be moved.
const kMoveStep = 1;

/// Mrs. Pomeroy's thank-you once the home has moved; the school letter
/// waits until this has been shown.
const kMovedThanksBeatId = 'tutorial_moved_thanks';

/// The letter signed by everyone once the park opens.
const kHandoverBeatId = 'letter_handover';

/// The step the hand-over letter is due at.
const kHandoverStep = 4;

/// `guideStep` value once the hand-over letter has been sent: free play.
const kChapterOneDone = 5;

/// Advances [step] past every chapter-one building already standing in
/// [placedTypeIds]; stops at the move step, which only an actual move
/// advances. Never moves past [kHandoverStep]; the hand-over itself is
/// sent by the state layer, which then marks the chapter done.
int chapterOneStepFor(int step, Set<String> placedTypeIds) {
  var s = step;
  while (s < kHandoverStep) {
    final building = chapterOneBuildings[s];
    if (building == null || !placedTypeIds.contains(building)) break;
    s++;
  }
  return s;
}

/// One-time gesture hints, stored as bits in `Players.guideHints`. (Bit 4
/// was a hand over the first answer, dropped 2026-09-29: a hand over one
/// choice read as the answer.)
enum GuideHint {
  placeHere(1),
  fling(2)
  ;

  const GuideHint(this.bit);

  final int bit;

  bool seenIn(int hints) => hints & bit != 0;
}
