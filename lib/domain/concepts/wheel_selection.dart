import 'dart:math';

import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';

/// Wheel composition (agreed 2026-09-16 — see plan.md "Wheel composition").
///
/// The wheel always shows [kWheelSegments] concepts when the player has that
/// many playable. Up to [kReviewSlots] of them are *review* slots drawn from
/// concepts the player has already mastered (and not outgrown); the rest are
/// *frontier* concepts — introduced and still in the challenging or
/// comfortable band. The drip-feed keeps roughly [kActivePoolTarget] frontier
/// concepts active so there is enough headroom to rotate at least
/// [kMinRotation] segments between one spin and the next.

/// Segments on the wheel whenever the pool allows.
const int kWheelSegments = 8;

/// Segments reserved for mastered-but-not-retired concepts, when any exist.
const int kReviewSlots = 2;

/// Frontier concepts (introduced ∩ challenging-or-comfortable ∩ not retired)
/// the drip-feed tops the active pool up to after every correct answer.
const int kActivePoolTarget = 12;

/// Minimum segments that must differ from the previous spin, pool permitting.
const int kMinRotation = 3;

/// Which part of the wheel a playable concept belongs on.
enum WheelTier {
  /// Introduced and still being learned — challenging or comfortable band.
  frontier,

  /// Mastered and not outgrown — eligible for a review slot.
  review,

  /// Not on the wheel: not yet, or retired as outgrown.
  off,
}

WheelTier wheelTierFor({
  required ProficiencyBand band,
  required bool retired,
}) {
  if (retired) return WheelTier.off;
  return switch (band) {
    ProficiencyBand.challenging ||
    ProficiencyBand.comfortable => WheelTier.frontier,
    ProficiencyBand.mastered => WheelTier.review,
    ProficiencyBand.notYet => WheelTier.off,
  };
}

/// Picks the concepts for one wheel.
///
/// [frontier] and [review] are the playable concepts in each tier;
/// [previous] is the set of concept IDs the player last saw on the wheel
/// (empty for the first spin). Returns up to [kWheelSegments] concepts sorted
/// by difficulty so the layout stays readable.
///
/// Slot rules:
///   - review gets `min(kReviewSlots, review.length)` slots, frontier the
///     rest; if frontier can't fill its share, review fills the remainder
///     (and vice versa), so the wheel is only short when both tiers are;
///   - at least [kMinRotation] of the chosen concepts were not on the
///     previous wheel, as long as that many unseen candidates exist. Frontier
///     absorbs the rotation quota first; review takes whatever is left of it.
List<Concept> selectWheelConcepts({
  required List<Concept> frontier,
  required List<Concept> review,
  required Set<String> previous,
  required Random random,
}) {
  var reviewCount = min(kReviewSlots, review.length);
  final frontierCount = min(kWheelSegments - reviewCount, frontier.length);
  if (frontierCount + reviewCount < kWheelSegments) {
    reviewCount = min(kWheelSegments - frontierCount, review.length);
  }

  final frontierPick = _pickTier(
    frontier,
    count: frontierCount,
    freshQuota: kMinRotation,
    previous: previous,
    random: random,
  );
  final reviewPick = _pickTier(
    review,
    count: reviewCount,
    freshQuota: kMinRotation - frontierPick.freshTaken,
    previous: previous,
    random: random,
  );

  return [...frontierPick.picks, ...reviewPick.picks]
    ..sort(compareConceptDifficulty);
}

class _TierPick {
  const _TierPick(this.picks, this.freshTaken);

  final List<Concept> picks;

  /// How many of [picks] were not on the previous wheel.
  final int freshTaken;
}

/// Chooses [count] concepts from [candidates]: first up to [freshQuota] that
/// were not in [previous], then random fill from whatever remains.
_TierPick _pickTier(
  List<Concept> candidates, {
  required int count,
  required int freshQuota,
  required Set<String> previous,
  required Random random,
}) {
  if (count <= 0) return const _TierPick([], 0);

  final fresh = candidates.where((c) => !previous.contains(c.id)).toList()
    ..shuffle(random);
  final stale = candidates.where((c) => previous.contains(c.id)).toList()
    ..shuffle(random);

  final quota = min(min(freshQuota, count), fresh.length).clamp(0, count);
  final picks = fresh.take(quota).toList();
  final rest = [...fresh.skip(quota), ...stale]..shuffle(random);
  picks.addAll(rest.take(count - picks.length));

  final freshTaken = picks.where((c) => !previous.contains(c.id)).length;
  return _TierPick(picks, freshTaken);
}
