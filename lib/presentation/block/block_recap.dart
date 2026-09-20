import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/presentation/city/city_screen.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/widgets/coin_icon.dart';
import 'package:math_city/presentation/widgets/concept_icon_badge.dart';
import 'package:math_city/presentation/widgets/streak_flame.dart';
import 'package:math_city/state/game_session_provider.dart';

/// Ends a block from wherever its last question finished. There is no
/// summary screen: the chain pops straight back to the zoomed city, which
/// re-shows the wheel with a [BlockRecapCard] above it — or, when the block
/// opened its site, celebrates over the finished building instead.
void finishBlock(BuildContext context, WidgetRef ref, QuestionBlock block) {
  exitBlock(context, ref, block, spinAgain: !block.siteOpened);
}

/// Publishes how the block ended and pops back to the city screen, which
/// reads the result as the route above it goes away (re-shows the wheel,
/// celebrates, or zooms out).
void exitBlock(
  BuildContext context,
  WidgetRef ref,
  QuestionBlock block, {
  required bool spinAgain,
}) {
  ref.read(lastBlockResultProvider.notifier).pending = BlockResult(
    block: block,
    spinAgain: spinAgain,
  );
  Navigator.of(context).popUntil(
    (route) => route.settings.name == CityScreen.routeName || route.isFirst,
  );
}

/// What the block just earned, in one card that sits above the wheel while
/// the player winds up the next spin: headline, coins, score, streak, any
/// band-crossing bonus, and the drip-feed unlocks that fired mid-block (the
/// wheel carries their NEW! tags; this names them). The site's own bar is
/// pinned at the bottom of the screen already, so it isn't repeated here.
class BlockRecapCard extends StatelessWidget {
  const BlockRecapCard({required this.block, super.key});

  final QuestionBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final conceptName =
        findConceptById(block.conceptId)?.name ?? block.conceptId;
    final streak = block.streakCount ?? 0;
    final allRight = block.correctCount == block.size;
    final headline = block.coinsEarned == 0
        ? 'Keep going!'
        : allRight
        ? 'Perfect block!'
        : 'Nice work!';
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  headline,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.successGreenDeep,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    conceptName,
                    style: muted,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CoinAmount(
                  amount: block.coinsEarned,
                  prefix: '+',
                  iconSize: 24,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.coinGoldDeep,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '${block.correctCount} of ${block.size} correct',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (streak > 0) StreakBadge(count: streak),
              ],
            ),
            for (final bonus in block.bandBonuses) ...[
              const SizedBox(height: 8),
              _BandBonusRow(bonus: bonus),
            ],
            if (block.unlocks.isNotEmpty) ...[
              const SizedBox(height: 8),
              _NewTopicsRows(
                concepts: [for (final u in block.unlocks) u.newConcept],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "You genuinely learned something new" — one line per band the block
/// crossed for the first time.
class _BandBonusRow extends StatelessWidget {
  const _BandBonusRow({required this.bonus});

  final BandCrossingBonus bonus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final name = findConceptById(bonus.conceptId)?.name ?? bonus.conceptId;
    return Row(
      children: [
        Icon(Icons.stars_rounded, color: palette.coinGold, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${bandBonusHeadline(bonus.band)} ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.coinGoldDeep,
                  ),
                ),
                TextSpan(text: name),
              ],
            ),
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        CoinAmount(
          amount: bonus.coins,
          prefix: '+',
          iconSize: 18,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: palette.coinGoldDeep,
          ),
        ),
      ],
    );
  }
}

/// Kid-facing headline for a band crossing.
String bandBonusHeadline(ProficiencyBand band) => switch (band) {
  ProficiencyBand.mastered => 'Mastered!',
  ProficiencyBand.comfortable => 'Getting comfortable!',
  _ => 'Level up!',
};

/// "N new topics are on the wheel!" followed by each unlocked concept,
/// named next to the same badge the wheel carries it under.
class _NewTopicsRows extends StatelessWidget {
  const _NewTopicsRows({required this.concepts});

  final List<Concept> concepts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: palette.brandTealDeep,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                newTopicsHeadline(concepts.length),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.brandTealDeep,
                ),
              ),
            ),
          ],
        ),
        for (final c in concepts)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 34),
            child: Row(
              children: [
                ConceptIconBadge(concept: c),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    c.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Kid-facing teaser for [count] newly unlocked concepts.
String newTopicsHeadline(int count) => count == 1
    ? 'A new topic is on the wheel!'
    : '$count new topics are on the wheel!';
