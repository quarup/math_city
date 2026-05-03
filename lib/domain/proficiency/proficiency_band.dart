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
/// [conceptGrade]: the grade at which the concept is introduced.
/// [playerGrade]: the player's stated grade level.
double initialProficiency(int conceptGrade, int playerGrade) =>
    conceptGrade <= (playerGrade < 1 ? 1 : playerGrade) ? 0.4 : 0.05;
