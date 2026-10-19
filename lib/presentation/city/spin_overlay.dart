import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/city/chapter_one.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/economy/coin_economy.dart';
import 'package:math_city/domain/economy/expected_seconds.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/game/spin_wheel/concept_icons.dart';
import 'package:math_city/game/spin_wheel/spin_wheel_component.dart';
import 'package:math_city/game/spin_wheel/spin_wheel_game.dart';
import 'package:math_city/presentation/block/block_recap.dart';
import 'package:math_city/presentation/spin/new_concept_celebration.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/theme/category_colors.dart';
import 'package:math_city/presentation/widgets/coach_hand.dart';
import 'package:math_city/state/city_provider.dart';
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
/// When the wheel follows a finished block, [recap] is that block: its
/// [BlockRecapCard] sits above the wheel until the next throw.
///
/// Give each fresh wheel a new [key] — the widget builds its game once.
class SpinOverlay extends ConsumerStatefulWidget {
  const SpinOverlay({
    required this.onBlockStart,
    this.recap,
    this.onLeave,
    this.side = false,
    this.bottomClear = 0,
    super.key,
  });

  /// A tap beside the wheel (on its canvas, off the disc): the player
  /// wants out. Taps on the city itself reach the city and leave too.
  final VoidCallback? onLeave;

  final void Function(
    String conceptId,
    ProficiencyBand band,
    QuestionBlock block,
  )
  onBlockStart;

  final QuestionBlock? recap;

  /// A phone on its side: the overlay covers the whole screen, the site
  /// stays sharp in the left column, the wheel takes the right, and the
  /// recap card sits in the top-left corner.
  final bool side;

  /// On a side, the height the site's card takes at the bottom left: the
  /// recap column stops above it.
  final double bottomClear;

  @override
  ConsumerState<SpinOverlay> createState() => _SpinOverlayState();
}

class _SpinOverlayState extends ConsumerState<SpinOverlay> {
  SpinWheelGame? _game;

  /// Concept whose first-landing celebration is on screen, if any.
  String? _celebrating;

  /// The recap card fades once the player throws.
  bool _recapVisible = true;

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
    final correctCounts =
        ref.read(correctAnswerCountsProvider).asData?.value ?? {};

    // One spin = one block of questions on the landed concept, sized so the
    // block adds up to ~25 s of expected work.
    final block = QuestionBlock(
      conceptId: conceptId,
      band: band,
      size: blockSizeFor(expectedSecondsFor(conceptId)),
      usesKeypad: keypadUnlocked(
        band: band,
        correctAnswers: correctCounts[conceptId] ?? 0,
        roundsPlayed:
            ref.read(activePlayerProvider).asData?.value.roundsPlayed ?? 0,
      ),
    );
    widget.onBlockStart(conceptId, band, block);
  }

  @override
  Widget build(BuildContext context) {
    final wheelAsync = ref.watch(wheelConceptsProvider);
    // Kept loaded so `_startBlock` can read it synchronously.
    ref.watch(correctAnswerCountsProvider);
    final theme = Theme.of(context);
    // The animated hand shows the fling once, until the first real throw.
    final hints = ref.watch(activePlayerProvider).asData?.value.guideHints;
    final showFlingHint = hints != null && !GuideHint.fling.seenIn(hints);

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
        onTapOutside: widget.onLeave,
        onThrow: () {
          if (mounted && _recapVisible) setState(() => _recapVisible = false);
          // The first real fling retires the hand for good.
          unawaited(
            ref.read(cityActionsProvider).markHintSeen(GuideHint.fling),
          );
        },
      );
      final shown = concepts.map((c) => c.id).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(lastWheelProvider.notifier).record(shown);
      });
    }
    final celebrating = _celebrating == null
        ? null
        : findConceptById(_celebrating!);

    // The blur + dim over the city is feathered along its lower edge so the
    // sharp site below reads as emerging from under the wheel rather than
    // cut off by a line. Only that layer is feathered: the wheel, its reveal
    // pill and the recap card sit above it at full opacity (the pill lands
    // in the feather band and used to fade with it).
    final recap = widget.recap == null
        ? null
        : IgnorePointer(
            child: AnimatedOpacity(
              opacity: _recapVisible ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: widget.side
                    ? const EdgeInsets.fromLTRB(12, 12, 12, 0)
                    : const EdgeInsets.fromLTRB(16, 10, 16, 2),
                child: BlockRecapCard(block: widget.recap!),
              ),
            ),
          );
    return Stack(
      fit: StackFit.expand,
      children: [
        _FeatheredSpinBlur(
          intensity: _game?.spinIntensity,
          axis: widget.side ? Axis.horizontal : Axis.vertical,
        ),
        if (_game != null && widget.side) ...[
          // The wheel in the right half; the recap in the left column,
          // above the site's card.
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: _wheelColumnFraction * (_viewport(context).width),
            child: Stack(
              fit: StackFit.expand,
              children: [
                GameWidget(game: _game!),
                // The fling hand sweeps across the upper part of the
                // wheel, well clear of the hub (the wheel's centre sits
                // at 46 % of the column's height).
                if (showFlingHint && celebrating == null)
                  const Align(
                    alignment: Alignment(0, -0.62),
                    child: CoachHand(mode: CoachHandMode.fling, size: 60),
                  ),
              ],
            ),
          ),
          if (recap != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: widget.bottomClear,
              width: (1 - _wheelColumnFraction) * _viewport(context).width,
              child: Align(alignment: Alignment.topLeft, child: recap),
            ),
        ] else if (_game != null)
          Column(
            children: [
              ?recap,
              Expanded(child: GameWidget(game: _game!)),
            ],
          ),
        if (_game != null &&
            !widget.side &&
            showFlingHint &&
            celebrating == null)
          const Align(
            alignment: Alignment(0, -0.45),
            child: CoachHand(mode: CoachHandMode.fling, size: 60),
          ),
        if (_game != null && celebrating != null)
          NewConceptCelebration(
            key: ValueKey(celebrating.id),
            concept: celebrating,
            onDone: () => _startBlock(celebrating.id),
          ),
      ],
    );
  }
}

/// Share of the width the wheel takes on a side; the site keeps the rest.
const double _wheelColumnFraction = 0.52;

Size _viewport(BuildContext context) => MediaQuery.sizeOf(context);

/// Runs [action] after the wheel's reveal has had its beat, without holding
/// a `BuildContext` across the gap.
Future<void> afterBeat(VoidCallback action) =>
    Future<void>.delayed(const Duration(milliseconds: 250), action);

/// The blur + dim under the wheel: [_restSigma] both ways at rest, plus up
/// to [_spinSigma] sideways at full speed — while the wheel spins the city
/// smears in proportion to its speed (the PR #112 spin effect; the streaks
/// are drawn by the game).
///
/// The lower [_featherFraction] fades out. Not with a `ShaderMask`: that
/// renders its child into an offscreen layer, and a `BackdropFilter` in
/// there only sees that empty layer, so nothing behind it got blurred at
/// all. Instead the band is [_featherSteps] strips whose blur steps down to
/// nothing, and the dim is a gradient.
class _FeatheredSpinBlur extends StatelessWidget {
  const _FeatheredSpinBlur({required this.intensity, required this.axis});

  final ValueListenable<double>? intensity;

  /// Vertical: the band along the bottom fades out (the site under the
  /// wheel). Horizontal: the left column is clear and the blur fades in
  /// across the middle (the site beside the wheel).
  final Axis axis;

  /// On a side, the share of the width left clear on the left.
  static const double _clearFraction = 0.40;

  static const double _restSigma = 2.5;
  static const double _spinSigma = 10;
  static const double _featherFraction = 0.18;
  static const int _featherSteps = 8;
  static const double _dim = 0.28;

  @override
  Widget build(BuildContext context) {
    final speed = intensity ?? const AlwaysStoppedAnimation<double>(0);
    return Stack(
      fit: StackFit.expand,
      children: [
        ValueListenableBuilder<double>(
          valueListenable: speed,
          builder: (context, k, _) => LayoutBuilder(
            builder: (context, box) {
              Widget blurred(double extent, double scale) => SizedBox(
                height: axis == Axis.vertical ? extent : null,
                width: axis == Axis.horizontal ? extent : null,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: (_restSigma + _spinSigma * k) * scale,
                      sigmaY: _restSigma * scale,
                      tileMode: TileMode.clamp,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
              if (axis == Axis.horizontal) {
                final clear = box.maxWidth * _clearFraction;
                final band = box.maxWidth * _featherFraction;
                final stripW = band / _featherSteps;
                return Row(
                  children: [
                    SizedBox(width: clear),
                    for (var i = 0; i < _featherSteps; i++)
                      blurred(stripW, (i + 1) / (_featherSteps + 1)),
                    blurred(box.maxWidth - clear - band, 1),
                  ],
                );
              }
              final band = box.maxHeight * _featherFraction;
              final stripH = band / _featherSteps;
              return Column(
                children: [
                  blurred(box.maxHeight - band, 1),
                  for (var i = 0; i < _featherSteps; i++)
                    blurred(stripH, 1 - (i + 1) / (_featherSteps + 1)),
                ],
              );
            },
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: axis == Axis.horizontal
                ? LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: _dim),
                      Colors.black.withValues(alpha: _dim),
                    ],
                    stops: const [
                      _clearFraction,
                      _clearFraction + _featherFraction,
                      1,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: _dim),
                      Colors.black.withValues(alpha: _dim),
                      Colors.transparent,
                    ],
                    stops: const [0, 1 - _featherFraction, 1],
                  ),
          ),
        ),
      ],
    );
  }
}
