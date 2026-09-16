/// Mastery bands that drive wheel inclusion and input mode.
enum ProficiencyBand { notYet, challenging, comfortable, mastered }

/// Maps a proficiency value [p] ∈ [0, 1] to a band.
///
/// Thresholds (from plan.md Domain Specs):
///   p < 0.20              → notYet     (off wheel)
///   0.20 ≤ p < 0.50       → challenging (multiple choice)
///   0.50 ≤ p < 0.85       → comfortable (number pad)
///   p ≥ 0.85              → mastered    (off wheel)
ProficiencyBand bandForProficiency(double p) {
  if (p < 0.20) return ProficiencyBand.notYet;
  if (p < 0.50) return ProficiencyBand.challenging;
  if (p < 0.85) return ProficiencyBand.comfortable;
  return ProficiencyBand.mastered;
}

/// A concept this many grades (or more) below the player's grade retires from
/// the wheel once it reaches the comfortable band — mastered baby-steps
/// disappear, while shaky old material still resurfaces.
const int kWheelRetirementGradeGap = 2;

/// Whether a concept should be kept off the wheel as "outgrown": it sits at
/// least [kWheelRetirementGradeGap] grades below [playerGrade] AND the player
/// is already comfortable (or better) with it. Below-comfortable old material
/// stays on the wheel so gaps still get practised.
bool isRetiredFromWheel({
  required int conceptGrade,
  required int playerGrade,
  required ProficiencyBand band,
}) =>
    playerGrade - conceptGrade >= kWheelRetirementGradeGap &&
    (band == ProficiencyBand.comfortable || band == ProficiencyBand.mastered);

/// EMA proficiency update: p_new = clamp(p + α·(target − p), 0, 1)
///
/// α = 0.1 (learning rate from plan.md).
/// target = 1.0 on correct, 0.0 on wrong.
double updateProficiency(double p, {required bool correct}) {
  const alpha = 0.1;
  final target = correct ? 1.0 : 0.0;
  return (p + alpha * (target - p)).clamp(0.0, 1.0);
}

/// Starting proficiency when a player first encounters a concept.
///
/// Graded by how far below the player's stated grade the concept sits, so
/// a higher-grade player isn't forced to grind through years of content
/// they already know. Buckets:
///
///   offset ≥ 2  → 0.95  mastered    (off wheel; satisfies prereqs)
///   offset = 1  → 0.70  comfortable (number-pad; fluency check)
///   offset = 0  → 0.40  challenging (multiple-choice; the frontier)
///   offset < 0  → 0.05  notYet      (off wheel until a prereq path opens)
///
/// where `offset = playerGrade − conceptGrade`.
double initialProficiency(int conceptGrade, int playerGrade) {
  final offset = playerGrade - conceptGrade;
  if (offset >= 2) return 0.95;
  if (offset == 1) return 0.70;
  if (offset == 0) return 0.40;
  return 0.05;
}

/// Challenging-band floor an *introduced* concept starts at when its
/// grade-based [initialProficiency] would put it in `notYet`.
const double kIntroducedFloorProficiency = 0.40;

/// Proficiency to assume for a concept the player has never answered.
///
/// Same as [initialProficiency], except that a concept the drip-feed has
/// *introduced* never starts in the `notYet` band: the drip-feed only
/// introduces a concept once its prereqs are mastered, so an above-grade
/// concept it hands the player starts at the challenging floor
/// ([kIntroducedFloorProficiency]) and goes straight onto the wheel. Without
/// this, a player who mastered everything at their grade would have the next
/// grade introduced at p = 0.05 — off the wheel with no way to ever raise it.
double startingProficiency({
  required int conceptGrade,
  required int playerGrade,
  required bool introduced,
}) {
  final p = initialProficiency(conceptGrade, playerGrade);
  if (introduced && bandForProficiency(p) == ProficiencyBand.notYet) {
    return kIntroducedFloorProficiency;
  }
  return p;
}
