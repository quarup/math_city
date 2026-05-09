import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/game/spin_wheel/spin_wheel_component.dart';
import 'package:math_city/game/spin_wheel/spin_wheel_game.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_city/presentation/question/question_screen.dart';
import 'package:math_city/state/game_session_provider.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';
import 'package:math_city/state/player_provider.dart';
import 'package:math_city/state/proficiency_provider.dart';

// ---------------------------------------------------------------------------
// Concept → wheel colour (presentation concern; not in domain layer).
//
// Per-category palette — same category always wins the same colour family,
// so a kid quickly associates "orange = addition" / "purple = fractions"
// regardless of which sub-concept the wheel currently surfaces.
// ---------------------------------------------------------------------------

const _categoryColors = <String, Color>{
  'counting': Color(0xFFFFA000), // amber
  'place_value': Color(0xFFEF6C00), // orange-deep
  'add_sub': Color(0xFFFB8C00), // orange
  'mult_div': Color(0xFFE53935), // red
  'fractions': Color(0xFF8E24AA), // purple
  'decimals_percent': Color(0xFF6A1B9A), // deep purple
  'ratios': Color(0xFF1565C0), // blue-deep
  'measurement': Color(0xFF1E88E5), // blue
  'geometry': Color(0xFF00897B), // teal
  'rationals': Color(0xFF2E7D32), // green-deep
  'prealgebra': Color(0xFF43A047), // green
  'stats': Color(0xFF6D4C41), // brown
};

Color _colorForConcept(Concept c) =>
    _categoryColors[c.categoryId] ?? Colors.grey.shade600;

List<WheelSegment> _buildSegments(List<Concept> concepts) => concepts
    .map(
      (c) => WheelSegment(
        conceptId: c.id,
        label: c.shortLabel,
        color: _colorForConcept(c),
      ),
    )
    .toList();

// ---------------------------------------------------------------------------
// SpinScreen
// ---------------------------------------------------------------------------

class SpinScreen extends ConsumerStatefulWidget {
  const SpinScreen({this.pulseStars = false, super.key});

  final bool pulseStars;

  @override
  ConsumerState<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends ConsumerState<SpinScreen>
    with TickerProviderStateMixin {
  SpinWheelGame? _game;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.6), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.6, end: 1), weight: 65),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    if (widget.pulseStars) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 280), () {
            if (mounted) unawaited(_pulseCtrl.forward());
          }),
        );
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onConceptSelected(String conceptId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final profMap = ref.read(proficiencyProvider).asData?.value ?? {};
      final statedGrade =
          ref.read(activePlayerProvider).asData?.value.gradeLevel ?? 2;
      final engine = ref.read(dagEngineProvider);
      final effectiveGrade = engine.effectiveGradeFor(statedGrade);
      final band = bandForConcept(conceptId, profMap, effectiveGrade);

      unawaited(
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => QuestionScreen(conceptId: conceptId, band: band),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final stars = ref.watch(totalStarsProvider);
    final wheelAsync = ref.watch(wheelConceptsProvider);
    final playerAsync = ref.watch(activePlayerProvider);
    final theme = Theme.of(context);

    final playerName = playerAsync.asData?.value.name ?? '';
    final avatarConfig =
        playerAsync.asData?.value.avatar ?? const AdventurerConfig();

    // Create the game once, the first build where concepts are available.
    final concepts = wheelAsync.asData?.value;
    if (_game == null && concepts != null) {
      _game = SpinWheelGame(
        onConceptSelected: _onConceptSelected,
        segments: _buildSegments(concepts),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Tapping the player chip pops back to HomeScreen to switch players.
        title: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdventurerAvatarWidget(config: avatarConfig, size: 32),
              const SizedBox(width: 8),
              Text(playerName, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ScaleTransition(
              scale: _pulseScale,
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$stars',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _game == null
            ? const Center(child: CircularProgressIndicator())
            : GameWidget(game: _game!),
      ),
    );
  }
}
