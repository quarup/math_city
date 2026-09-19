/// Construction sites — the unit of the construction loop (city_builder.md
/// §8). Placing anything with a price starts a *site*, not a purchase; every
/// coin a question earns is paid into the site the player is zoomed into,
/// and the site opens when its bar reaches the price. There is no wallet: a
/// coin only ever exists inside a site (§8.3), so land blocks and parks are
/// sites too — everything with a price is a [SiteGoal].
///
/// Pure Dart: no Flutter / Flame / Drift imports. The data layer persists a
/// site as one `ConstructionSites` row (cityId, goal columns, paidCoins,
/// startedAtRound) and deletes the row when the site opens — v1 has **no
/// cancel** (§8.11: paid coins would have nowhere to go), so a row's only
/// exits are *moved* or *opened*.
library;

import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/land_blocks.dart';
import 'package:math_city/domain/city/placement_rules.dart';
import 'package:math_city/domain/city/upgrade_ladders.dart';
import 'package:math_city/domain/economy/question_block.dart';

/// At most this many sites may be open at once (§8.5): enough to choose
/// where today's work goes, few enough that nothing is forgotten.
const int kMaxOpenSites = 3;

/// Paid-fraction thresholds at which the site's art advances (§8.4, draft
/// 0 / ⅓ / ⅔ / done): stage 0 below the first, stage 1 from ⅓, stage 2 from
/// ⅔. Stage [kSiteOpenStage] is reserved for *full* — the final sprite.
const List<double> kSiteStageThresholds = <double>[1 / 3, 2 / 3];

/// The stage a fully paid site shows: the finished building.
const int kSiteOpenStage = 3;

/// Construction stage for a paid fraction in `[0, 1]`: the number of
/// [kSiteStageThresholds] reached, or [kSiteOpenStage] once full.
int stageForFraction(double paidFraction) {
  if (paidFraction >= 1) return kSiteOpenStage;
  var stage = 0;
  for (final t in kSiteStageThresholds) {
    if (paidFraction >= t) stage++;
  }
  return stage;
}

/// The link from an upgrade site to the building it replaces (§8.6). The
/// source keeps standing — and counting toward population / services —
/// until the site opens, then its placement is removed.
class UpgradeLink {
  const UpgradeLink({
    required this.sourcePlacementId,
    required this.sourceType,
  });

  /// Persistence id of the `BuildingPlacements` row being upgraded (opaque
  /// to the domain; it identifies the source across moves).
  final int sourcePlacementId;

  final BuildingType sourceType;
}

/// What a site is paying for. Sealed so the data layer and the renderer can
/// switch exhaustively.
sealed class SiteGoal {
  const SiteGoal();

  /// Total coins the site is paid down to.
  int get price;
}

/// A building (a new build, or an upgrade of [upgrade]'s source) at a tile
/// anchor. A park is just a building goal with an entertainment type.
final class BuildingGoal extends SiteGoal {
  const BuildingGoal({
    required this.type,
    required this.col,
    required this.row,
    this.upgrade,
  });

  final BuildingType type;

  /// North-corner anchor of the footprint on the world grid.
  final int col;
  final int row;

  /// Set when this site upgrades an existing placement into [type].
  final UpgradeLink? upgrade;

  bool get isUpgrade => upgrade != null;

  GridFootprint get footprint => GridFootprint(
    col: col,
    row: row,
    width: type.footprint.$1,
    height: type.footprint.$2,
  );

  /// Full price for a new build; `target − source` for an upgrade.
  @override
  int get price => switch (upgrade) {
    null => type.coinCost,
    final u => upgradeDeltaPrice(source: u.sourceType, target: type),
  };

  /// Residents the city gains when the site opens: the target's contribution
  /// for a new build, `target − source` for an upgrade (the source counted
  /// all along, so there is no mid-construction dip and no double count).
  int get netPopulationOnOpen =>
      type.populationContribution -
      (upgrade?.sourceType.populationContribution ?? 0);

  BuildingGoal movedTo({required int col, required int row}) =>
      BuildingGoal(type: type, col: col, row: row, upgrade: upgrade);
}

/// A land block (`land_blocks.dart`), priced on the ladder `600 × ring`.
final class LandBlockGoal extends SiteGoal {
  const LandBlockGoal({required this.blockX, required this.blockY});

  final int blockX;
  final int blockY;

  (int, int) get block => (blockX, blockY);

  @override
  int get price => blockCost(blockX, blockY);
}

/// Outcome of paying coins into a site.
class PayInResult {
  const PayInResult({
    required this.site,
    required this.accepted,
    required this.overflow,
    required this.stageBefore,
  });

  /// The site after the payment.
  final ConstructionSite site;

  /// Coins that went into the bar.
  final int accepted;

  /// Coins beyond the price. The bar stops at the price; the caller decides
  /// what a full site's spillover means (the player's lifetime total already
  /// counted the whole reward).
  final int overflow;

  final int stageBefore;

  /// The payment took the site from short to full — the building opens.
  bool get opened => stageBefore != kSiteOpenStage && site.isFull;

  /// The site's art advances (including the final swap on [opened]).
  bool get stageAdvanced => site.stage > stageBefore;
}

/// One site: a [goal] and the coins paid into it so far. Immutable — pay-in
/// and moves return new values.
class ConstructionSite {
  const ConstructionSite({
    required this.goal,
    required this.startedAtRound,
    this.paidCoins = 0,
  }) : assert(paidCoins >= 0, 'paidCoins is never negative');

  final SiteGoal goal;

  /// The player's `roundsPlayed` when the site was started.
  final int startedAtRound;

  /// Coins paid in so far, `0 ≤ paidCoins ≤ price`.
  final int paidCoins;

  int get price => goal.price;

  /// Coins still owed.
  int get remaining => price - paidCoins < 0 ? 0 : price - paidCoins;

  /// Bar reaches the price → the building opens. A free goal (the mayor's
  /// office) is full from the start.
  bool get isFull => paidCoins >= price;

  /// `paidCoins / price` in `[0, 1]`; `1` for a free goal.
  double get paidFraction {
    if (price == 0) return 1;
    final f = paidCoins / price;
    return f > 1 ? 1 : f;
  }

  /// Construction stage the art shows (see [stageForFraction]).
  int get stage => stageForFraction(paidFraction);

  ConstructionSite copyWith({SiteGoal? goal, int? paidCoins}) =>
      ConstructionSite(
        goal: goal ?? this.goal,
        startedAtRound: startedAtRound,
        paidCoins: paidCoins ?? this.paidCoins,
      );

  /// Pay [coins] into the site. The bar never exceeds the price; the excess
  /// comes back as [PayInResult.overflow]. Paying into a full site accepts
  /// nothing.
  PayInResult payIn(int coins) {
    assert(coins >= 0, 'a payment is never negative');
    final accepted = coins < remaining ? coins : remaining;
    return PayInResult(
      site: copyWith(paidCoins: paidCoins + accepted),
      accepted: accepted,
      overflow: coins - accepted,
      stageBefore: stage,
    );
  }

  /// Pay everything one answer earned — the answer's coins plus any
  /// band-crossing bonus. A wrong answer pays 0 and changes nothing.
  PayInResult payReward(AnswerReward reward) => payIn(reward.totalCoins);
}

/// Why a site can't be started.
enum SiteStartRejection {
  /// [kMaxOpenSites] sites are already open — the nudge names them.
  tooManyOpenSites,

  /// The building being upgraded already has an open upgrade site.
  sourceAlreadyUpgrading,

  /// The target is not the rung directly above the source on a declared
  /// ladder (`upgrade_ladders.dart`).
  notAnUpgradeStep,

  /// The land block doesn't share an edge with owned land.
  blockNotPurchasable,

  /// A site is already paying for that land block.
  blockAlreadyStarted,
}

/// Whether [goal] may be started alongside [openSites] on a city that owns
/// [ownedBlocks]. Null means go ahead. Tile-level legality of a building goal
/// (bounds, overlap, road access) is `checkPlacement`'s job — for an upgrade
/// placed over its own source, exclude the source's footprint from
/// `existing` there, exactly as for a move.
SiteStartRejection? checkStartSite({
  required SiteGoal goal,
  required Iterable<ConstructionSite> openSites,
  required Set<(int, int)> ownedBlocks,
}) {
  final open = openSites.toList();
  if (open.length >= kMaxOpenSites) {
    return SiteStartRejection.tooManyOpenSites;
  }
  switch (goal) {
    case BuildingGoal(:final upgrade?):
      if (!isUpgradeStep(source: upgrade.sourceType.id, target: goal.type.id)) {
        return SiteStartRejection.notAnUpgradeStep;
      }
      for (final s in open) {
        if (s.goal case BuildingGoal(
          :final upgrade?,
        ) when upgrade.sourcePlacementId == goal.upgrade!.sourcePlacementId) {
          return SiteStartRejection.sourceAlreadyUpgrading;
        }
      }
    case BuildingGoal():
      break;
    case LandBlockGoal():
      if (!purchasableBlocks(ownedBlocks).contains(goal.block)) {
        return SiteStartRejection.blockNotPurchasable;
      }
      for (final s in open) {
        if (s.goal case LandBlockGoal(:final block) when block == goal.block) {
          return SiteStartRejection.blockAlreadyStarted;
        }
      }
  }
  return null;
}
