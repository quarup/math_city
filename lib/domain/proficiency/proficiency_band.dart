/// Mastery bands that drive wheel inclusion and input mode.
enum ProficiencyBand { notYet, challenging, comfortable, mastered }

/// Maps a proficiency value [p] ∈ [0, 1] to a band.
///
/// Thresholds (from plan.md Domain Specs):
///   p < 0.20              → notYet     (off wheel)
///   0.20 ≤ p < 0.50       → challenging (multiple choice, 5 stars)
///   0.50 ≤ p < 0.85       → comfortable (number pad, 3 stars)
///   p ≥ 0.85              → mastered    (off wheel)
ProficiencyBand bandForProficiency(double p) {
  if (p < 0.20) return ProficiencyBand.notYet;
  if (p < 0.50) return ProficiencyBand.challenging;
  if (p < 0.85) return ProficiencyBand.comfortable;
  return ProficiencyBand.mastered;
}

/// Stars awarded for a correct answer in [band].
/// Wrong answers always earn 0.
int starsForBand(ProficiencyBand band) => switch (band) {
  ProficiencyBand.challenging => 5,
  ProficiencyBand.comfortable => 3,
  _ => 0,
};

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
