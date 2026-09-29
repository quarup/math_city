/// Chapter one — the scripted first ten minutes (city_builder.md §10.4).
///
/// Three letters in a fixed order, each fired the moment the previous
/// building opens, then a hand-over letter from the whole town; the beat
/// engine and the folder bar stay out of the way until it is done. The
/// player's `guideStep` persists where they are.
///
/// Pure Dart: no Flutter / Flame / Drift imports.
library;

/// The letter for each step, in order: a home, the school, a park.
const chapterOneLetters = <String>[
  'demand_first_home',
  'demand_school',
  'demand_more_parks',
];

/// The building each step waits for before moving on.
const chapterOneBuildings = <String>['single_home', 'school', 'park'];

/// The letter signed by everyone once the park opens.
const kHandoverBeatId = 'letter_handover';

/// `guideStep` value once the hand-over letter has been sent: free play.
const kChapterOneDone = 4;

/// The step the hand-over letter is due at.
const kHandoverStep = 3;

/// Advances [step] past every chapter-one building already standing in
/// [placedTypeIds]: a player at step 0 with a home and a school placed is
/// at step 2 (the park letter). Never moves past [kHandoverStep]; the
/// hand-over itself is sent by the state layer, which then marks the
/// chapter done.
int chapterOneStepFor(int step, Set<String> placedTypeIds) {
  var s = step;
  while (s < kHandoverStep && placedTypeIds.contains(chapterOneBuildings[s])) {
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
