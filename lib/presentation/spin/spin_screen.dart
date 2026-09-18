import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/economy/coin_economy.dart';
import 'package:math_city/domain/economy/expected_seconds.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/game/spin_wheel/concept_icons.dart';
import 'package:math_city/game/spin_wheel/spin_wheel_component.dart';
import 'package:math_city/game/spin_wheel/spin_wheel_game.dart';
import 'package:math_city/presentation/city/city_screen.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_city/presentation/question/question_screen.dart';
import 'package:math_city/presentation/spin/new_concept_celebration.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/theme/category_colors.dart';
import 'package:math_city/presentation/widgets/coin_icon.dart';
import 'package:math_city/state/game_session_provider.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';
import 'package:math_city/state/player_provider.dart';
import 'package:math_city/state/proficiency_provider.dart';

/// A concept with no proficiency row has never been answered — the wheel
/// stickers it "NEW" and the first landing gets a celebration.
bool _neverPlayed(String conceptId, Map<String, double> profMap) =>
    !profMap.containsKey(conceptId);

List<WheelSegment> _buildSegments(
  List<Concept> concepts,
  Map<String, double> profMap,
) => concepts
    .map(
      (c) => WheelSegment(
        conceptId: c.id,
        label: c.name,
        categoryId: c.categoryId,
        tier: tierForGrade(c.primaryGrade),
        color: categoryColorFor(c),
        isNew: _neverPlayed(c.id, profMap),
      ),
    )
    .toList();

// ---------------------------------------------------------------------------
// SpinScreen
// ---------------------------------------------------------------------------

class SpinScreen extends ConsumerStatefulWidget {
  const SpinScreen({super.key});

  /// Collapses the spin → question → summary loop back onto the player's
  /// "My City" hub (or the home screen as a backstop) and pushes a fresh
  /// wheel, so a new spin sits directly above the city and back-navigation
  /// returns there.
  static void pushFresh(BuildContext context) {
    unawaited(
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const SpinScreen()),
        (route) => route.settings.name == CityScreen.routeName || route.isFirst,
      ),
    );
  }

  @override
  ConsumerState<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends ConsumerState<SpinScreen> {
  SpinWheelGame? _game;

  /// Concept whose first-landing celebration is on screen, if any.
  String? _celebrating;

  void _onConceptSelected(String conceptId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profMap = ref.read(proficiencyProvider).asData?.value ?? {};
      if (_neverPlayed(conceptId, profMap)) {
        // First time on this concept: celebrate on the wheel, then start
        // the block when the overlay finishes.
        setState(() => _celebrating = conceptId);
        return;
      }
      _startBlock(conceptId);
    });
  }

  void _startBlock(String conceptId) {
    if (!mounted) return;
    {
      final profMap = ref.read(proficiencyProvider).asData?.value ?? {};
      final statedGrade =
          ref.read(activePlayerProvider).asData?.value.gradeLevel ?? 2;
      final engine = ref.read(dagEngineProvider);
      final effectiveGrade = engine.effectiveGradeFor(statedGrade);
      final band = bandForConcept(conceptId, profMap, effectiveGrade);

      // One spin = one block of questions on the landed concept, sized so
      // the block adds up to ~25 s of expected work (five quick K sums, or
      // a single long-division problem).
      final block = QuestionBlock(
        conceptId: conceptId,
        band: band,
        size: blockSizeFor(expectedSecondsFor(conceptId)),
      );

      unawaited(
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) =>
                QuestionScreen(conceptId: conceptId, band: band, block: block),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(totalCoinsProvider);
    final wheelAsync = ref.watch(wheelConceptsProvider);
    final playerAsync = ref.watch(activePlayerProvider);
    final theme = Theme.of(context);

    final playerName = playerAsync.asData?.value.name ?? '';
    final avatarConfig =
        playerAsync.asData?.value.avatar ?? const AdventurerConfig();

    // Create the game once, the first build where concepts are available,
    // and remember this wheel so the next one rotates against it.
    final concepts = wheelAsync.asData?.value;
    if (_game == null && concepts != null) {
      final profMap = ref.read(proficiencyProvider).asData?.value ?? {};
      final palette = theme.extension<AppPalette>() ?? AppPalette.light;
      _game = SpinWheelGame(
        onConceptSelected: _onConceptSelected,
        segments: _buildSegments(concepts, profMap),
        skyTop: palette.skyGradientStart,
        skyBottom: palette.skyGradientEnd,
      );
      final shown = concepts.map((c) => c.id).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(lastWheelProvider.notifier).record(shown);
      });
    }
    final celebrating = _celebrating == null
        ? null
        : findConceptById(_celebrating!);

    return Scaffold(
      appBar: AppBar(
        // Back arrow returns to the player's "My City" hub.
        leading: IconButton(
          icon: const Icon(Icons.location_city_rounded),
          tooltip: 'My City',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdventurerAvatarWidget(config: avatarConfig, size: 32),
            const SizedBox(width: 8),
            Text(playerName, style: theme.textTheme.titleMedium),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CoinAmount(
              amount: coins,
              iconSize: 22,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _game == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                fit: StackFit.expand,
                children: [
                  GameWidget(game: _game!),
                  if (celebrating != null)
                    NewConceptCelebration(
                      key: ValueKey(celebrating.id),
                      concept: celebrating,
                      onDone: () => _startBlock(celebrating.id),
                    ),
                ],
              ),
      ),
    );
  }
}
