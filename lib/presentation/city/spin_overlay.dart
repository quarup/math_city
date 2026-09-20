import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/economy/coin_economy.dart';
import 'package:math_city/domain/economy/expected_seconds.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/game/spin_wheel/concept_icons.dart';
import 'package:math_city/game/spin_wheel/spin_wheel_component.dart';
import 'package:math_city/game/spin_wheel/spin_wheel_game.dart';
import 'package:math_city/presentation/spin/new_concept_celebration.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/theme/category_colors.dart';
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

/// The spin wheel floating over the zoomed-in city (city_builder.md §8.7):
/// the city behind it is blurred and dimmed, the PR #112 wheel art renders
/// on a transparent canvas above the construction site pinned at the
/// bottom of the screen. Landing on a concept builds the block and hands it
/// to [onBlockStart]; the host pushes the question route.
///
/// Give each fresh wheel a new [key] — the widget builds its game once.
class SpinOverlay extends ConsumerStatefulWidget {
  const SpinOverlay({required this.onBlockStart, super.key});

  final void Function(
    String conceptId,
    ProficiencyBand band,
    QuestionBlock block,
  )
  onBlockStart;

  @override
  ConsumerState<SpinOverlay> createState() => _SpinOverlayState();
}

class _SpinOverlayState extends ConsumerState<SpinOverlay> {
  SpinWheelGame? _game;

  /// Concept whose first-landing celebration is on screen, if any.
  String? _celebrating;

  void _onConceptSelected(String conceptId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profMap = ref.read(proficiencyProvider).asData?.value ?? {};
      if (_neverPlayed(conceptId, profMap)) {
        setState(() => _celebrating = conceptId);
        return;
      }
      _startBlock(conceptId);
    });
  }

  void _startBlock(String conceptId) {
    if (!mounted) return;
    final profMap = ref.read(proficiencyProvider).asData?.value ?? {};
    final statedGrade =
        ref.read(activePlayerProvider).asData?.value.gradeLevel ?? 2;
    final engine = ref.read(dagEngineProvider);
    final effectiveGrade = engine.effectiveGradeFor(statedGrade);
    final band = bandForConcept(conceptId, profMap, effectiveGrade);

    // One spin = one block of questions on the landed concept, sized so the
    // block adds up to ~25 s of expected work.
    final block = QuestionBlock(
      conceptId: conceptId,
      band: band,
      size: blockSizeFor(expectedSecondsFor(conceptId)),
    );
    widget.onBlockStart(conceptId, band, block);
  }

  @override
  Widget build(BuildContext context) {
    final wheelAsync = ref.watch(wheelConceptsProvider);
    final theme = Theme.of(context);

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
        showBackdrop: false,
      );
      final shown = concepts.map((c) => c.id).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(lastWheelProvider.notifier).record(shown);
      });
    }
    final celebrating = _celebrating == null
        ? null
        : findConceptById(_celebrating!);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.28),
          child: _game == null
              ? const SizedBox.expand()
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
      ),
    );
  }
}

/// Runs [action] after the wheel's reveal has had its beat, without holding
/// a `BuildContext` across the gap.
Future<void> afterBeat(VoidCallback action) =>
    Future<void>.delayed(const Duration(milliseconds: 250), action);
