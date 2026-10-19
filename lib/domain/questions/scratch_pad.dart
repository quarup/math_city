import 'package:math_city/domain/economy/expected_seconds.dart';

/// Which questions come with the scratch pad: a sheet of squared paper the
/// player writes on with a finger, under the question and above the
/// answer (prd.md *Scratch pad*, decided 2026-10-19).
///
/// The pad is for questions that take minutes of written work — long
/// multiplication and division, multi-step word problems, two-step
/// equations, fraction and decimal arithmetic, mean/median/MAD. A kid
/// doing those without paper has to hold partial products in their head or
/// guess, and guessing is the thing the game must not reward. Quick
/// questions do not get one: a pad under "7 × 8 = ?" is clutter.
///
/// The signal is the concept's expected seconds
/// ([expectedSecondsByConcept], the same estimate that prices the coins):
/// at [kScratchPadFromSeconds] or more a question is paper work. The
/// estimates are hand-tuned and a few sit oddly, so two lists adjust the
/// threshold by eye: [scratchPadAlways] for arithmetic rated just under it
/// that is written out column by column all the same, and
/// [scratchPadNever] for slow questions that are read off a figure rather
/// than worked out.
///
/// Keep the lists short and keep the reasons next to the ids.
const int kScratchPadFromSeconds = 40;

/// Rated under the threshold but set out on paper by every kid who does
/// them: unlike-denominator fractions (find the common denominator, scale,
/// add), decimal multiplication and division (long × or ÷ with a point to
/// place), the median (sort the list first), order of operations (rewrite
/// line by line).
const Set<String> scratchPadAlways = {
  'add_fractions_unlike_denom', // 35 s
  'sub_fractions_unlike_denom', // 35 s
  'mult_decimals', // 35 s
  'div_decimal_by_whole', // 35 s
  'mult_decimal_by_whole', // 30 s
  'median', // 30 s
  'order_of_operations_no_exp', // 30 s
  'nested_grouping', // 30 s
};

/// Rated at or over the threshold but answered by reading a figure, not by
/// working: which point is missing from the scatter plot, the slope of a
/// line already drawn, what a box plot says. Paper adds nothing.
const Set<String> scratchPadNever = {
  'scatter_plot_construct', // 40 s
  'informal_line_of_fit', // 40 s
  'interpret_slope_intercept_data', // 40 s
  'box_plot', // 45 s
};

/// Whether [conceptId]'s questions show the scratch pad.
bool usesScratchPad(String conceptId) {
  if (scratchPadNever.contains(conceptId)) return false;
  if (scratchPadAlways.contains(conceptId)) return true;
  final secs = expectedSecondsByConcept[conceptId];
  return secs != null && secs >= kScratchPadFromSeconds;
}
