import 'package:flutter/material.dart';
import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/presentation/city/city_screen.dart';
import 'package:math_city/presentation/spin/spin_screen.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/widgets/coin_icon.dart';
import 'package:math_city/presentation/widgets/concept_icon_badge.dart';
import 'package:math_city/presentation/widgets/site_progress_bar.dart';
import 'package:math_city/presentation/widgets/streak_flame.dart';

/// End-of-block celebration: the site's bar before → after, coins earned,
/// streak state, any band-crossing bonuses, and a one-line teaser for
/// drip-feed unlocks that fired mid-block (the wheel itself carries the
/// "NEW" stickers and the first-landing celebration). "Spin again" returns
/// to the wheel; once the site has opened there is nothing left to pay into,
/// so the primary action becomes "Back to city".
class BlockSummaryScreen extends StatelessWidget {
  const BlockSummaryScreen({required this.block, super.key});

  final QuestionBlock block;

  void _backToCity(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.settings.name == CityScreen.routeName || route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final conceptName =
        findConceptById(block.conceptId)?.name ?? block.conceptId;
    final streak = block.streakCount ?? 0;
    final allRight = block.correctCount == block.size;
    final site = block.siteAfter;
    final opened = block.siteOpened;
    final headline = opened
        ? 'It’s open!'
        : block.coinsEarned == 0
        ? 'Keep going!'
        : allRight
        ? 'Perfect block!'
        : 'Nice work!';

    return Scaffold(
      backgroundColor: palette.successGreenSoft,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                conceptName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                headline,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.successGreenDeep,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    if (site != null) ...[
                      _SiteCard(
                        site: site,
                        paidBefore: block.sitePaidBefore,
                        opened: opened,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _CoinsCard(
                      block: block,
                      theme: theme,
                      palette: palette,
                    ),
                    const SizedBox(height: 12),
                    _StreakCard(count: streak, theme: theme),
                    for (final bonus in block.bandBonuses) ...[
                      const SizedBox(height: 12),
                      _BandBonusCard(bonus: bonus),
                    ],
                    if (block.unlocks.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _NewTopicsCard(
                        concepts: [
                          for (final u in block.unlocks) u.newConcept,
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (opened)
                FilledButton(
                  onPressed: () => _backToCity(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: theme.textTheme.titleLarge,
                  ),
                  child: const Text('Back to city'),
                )
              else ...[
                FilledButton(
                  onPressed: () => SpinScreen.pushFresh(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: theme.textTheme.titleLarge,
                  ),
                  child: const Text('Spin again'),
                ),
                TextButton(
                  onPressed: () => _backToCity(context),
                  child: const Text('Back to city'),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// The construction site this block paid into: name, the bar as it stands
/// now, and how far it moved. When the block finished the job, says so.
class _SiteCard extends StatelessWidget {
  const _SiteCard({
    required this.site,
    required this.paidBefore,
    required this.opened,
  });

  final ConstructionSite site;
  final int paidBefore;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final name = switch (site.goal) {
      BuildingGoal(:final type) => type.name,
      LandBlockGoal() => 'New land',
    };
    return Card(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: opened ? palette.successGreenDeep : palette.coinGold,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  opened
                      ? Icons.celebration_rounded
                      : Icons.construction_rounded,
                  color: opened
                      ? palette.successGreenDeep
                      : palette.coinGoldDeep,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    opened ? '$name is finished!' : 'Building $name',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SiteProgressBar(paid: site.paidCoins, price: site.price),
            if (!opened) ...[
              const SizedBox(height: 6),
              Text(
                'was $paidBefore before this block',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CoinsCard extends StatelessWidget {
  const _CoinsCard({
    required this.block,
    required this.theme,
    required this.palette,
  });

  final QuestionBlock block;
  final ThemeData theme;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            CoinAmount(
              amount: block.coinsEarned,
              prefix: '+',
              iconSize: 44,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.coinGoldDeep,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${block.correctCount} of ${block.size} correct',
              style: theme.textTheme.titleMedium,
            ),
            if (block.bonusCoins > 0) ...[
              const SizedBox(height: 4),
              Text(
                'includes ${block.bonusCoins} bonus coins',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The streak as one flame whose heat tracks the count, plus "N in a row!".
/// A fresh miss shows the cold flame and an invitation rather than "0 in a
/// row". Pay tops out at five in a row but the count keeps climbing so the
/// player can see how far they've gone.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.count, required this.theme});

  final int count;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            StreakFlame(count: count, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                streakHeadline(count),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: count == 0
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "You genuinely learned something new" — shown for each band the block
/// crossed for the first time, worth more than the routine practice pay.
class _BandBonusCard extends StatelessWidget {
  const _BandBonusCard({required this.bonus});

  final BandCrossingBonus bonus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final name = findConceptById(bonus.conceptId)?.name ?? bonus.conceptId;
    return Card(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.coinGold, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.stars_rounded, color: palette.coinGold, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bandBonusHeadline(bonus.band),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: palette.coinGoldDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CoinAmount(
              amount: bonus.coins,
              prefix: '+',
              iconSize: 22,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.coinGoldDeep,
              ),
            ),
          ],
        ),
      ),
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
class _NewTopicsCard extends StatelessWidget {
  const _NewTopicsCard({required this.concepts});

  final List<Concept> concepts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Card(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.brandTealDeep, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: palette.brandTealDeep,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    newTopicsHeadline(concepts.length),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: palette.brandTealDeep,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final c in concepts)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    ConceptIconBadge(concept: c),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kid-facing teaser for [count] newly unlocked concepts.
String newTopicsHeadline(int count) => count == 1
    ? 'A new topic is on the wheel!'
    : '$count new topics are on the wheel!';
