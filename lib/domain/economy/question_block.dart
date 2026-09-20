import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/domain/concepts/dag_engine.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';

/// One-time coin bonus paid when a concept's proficiency first crossed a
/// band boundary (see `band_crossings.dart`).
class BandCrossingBonus {
  const BandCrossingBonus({
    required this.conceptId,
    required this.band,
    required this.coins,
  });

  final String conceptId;

  /// The band the concept just entered.
  final ProficiencyBand band;
  final int coins;
}

/// Everything one answered question paid out, as computed and persisted by
/// the proficiency notifier. Pure value; the UI animates from it.
class AnswerReward {
  const AnswerReward({
    required this.correct,
    required this.coins,
    required this.streakCount,
    this.bandBonuses = const <BandCrossingBonus>[],
    this.unlocks = const <UnlockEvent>[],
    this.sitePayIn,
  });

  final bool correct;

  /// Coins from the answer itself (0 on a wrong answer).
  final int coins;

  /// The player's consecutive-correct count *after* this answer (uncapped;
  /// pay tops out at `kStreakCap`).
  final int streakCount;

  /// Band-crossing bonuses this answer triggered (normally 0 or 1).
  final List<BandCrossingBonus> bandBonuses;

  /// Drip-feed concepts this answer introduced (the top-up after a mastery
  /// or a retirement can add several at once; usually empty).
  final List<UnlockEvent> unlocks;

  /// Where [totalCoins] went: the construction site the player is building
  /// (city_builder.md §8 — a coin only exists inside a site). Null when no
  /// site was active, or on a wrong answer (nothing to pay).
  final PayInResult? sitePayIn;

  int get bonusCoins => bandBonuses.fold(0, (sum, b) => sum + b.coins);

  /// Answer coins plus any band bonus.
  int get totalCoins => coins + bonusCoins;
}

/// A wheel spin's worth of questions on one concept, accumulating the
/// rewards as the player works through it. Mutable on purpose: the same
/// instance threads through the question → (red screen) → question → summary
/// chain, and the summary screen renders from it.
class QuestionBlock {
  QuestionBlock({
    required this.conceptId,
    required this.band,
    required this.size,
  }) : assert(size >= 1, 'a block has at least one question');

  final String conceptId;

  /// The band at spin time — chooses MC vs keypad for every question in the
  /// block (it isn't re-evaluated mid-block, so the input mode is stable).
  final ProficiencyBand band;

  /// Total questions in the block.
  final int size;

  final List<AnswerReward> rewards = <AnswerReward>[];

  int get answered => rewards.length;
  int get remaining => size - answered;
  bool get isComplete => answered >= size;

  /// 1-based index of the question currently on screen (or about to be).
  int get currentIndex => answered + 1;

  int get correctCount => rewards.where((r) => r.correct).length;

  /// Coins from answers alone (no bonuses).
  int get answerCoins => rewards.fold(0, (sum, r) => sum + r.coins);

  int get bonusCoins => rewards.fold(0, (sum, r) => sum + r.bonusCoins);

  /// Everything the block paid out.
  int get coinsEarned => answerCoins + bonusCoins;

  List<BandCrossingBonus> get bandBonuses => [
    for (final r in rewards) ...r.bandBonuses,
  ];

  List<UnlockEvent> get unlocks => [
    for (final r in rewards) ...r.unlocks,
  ];

  /// Streak count after the last answered question, or null if nothing has
  /// been answered yet.
  int? get streakCount => rewards.isEmpty ? null : rewards.last.streakCount;

  /// Every site payment this block made, in order.
  List<PayInResult> get sitePayIns => [
    for (final r in rewards) ?r.sitePayIn,
  ];

  /// The site as it stood after the block's last payment, or null if no
  /// coins reached a site (no active site, or nothing earned).
  ConstructionSite? get siteAfter =>
      sitePayIns.isEmpty ? null : sitePayIns.last.site;

  /// Coins the block put into the site (never more than the site could
  /// take — the bar stops at the price).
  int get siteCoins => sitePayIns.fold(0, (sum, p) => sum + p.accepted);

  /// The site's paid-in coins before this block started.
  int get sitePaidBefore => (siteAfter?.paidCoins ?? 0) - siteCoins;

  /// The block's payments took the site from short to full — it opened.
  bool get siteOpened => sitePayIns.any((p) => p.opened);

  void record(AnswerReward reward) {
    assert(!isComplete, 'block already complete');
    rewards.add(reward);
  }
}
