import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/data/database.dart';
import 'package:math_dash/domain/avatar/adventurer_config.dart';
import 'package:math_dash/domain/concepts/concept.dart';
import 'package:math_dash/game/spin_wheel/spin_wheel_component.dart';
import 'package:math_dash/game/spin_wheel/spin_wheel_game.dart';
import 'package:math_dash/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_dash/presentation/question/question_screen.dart';
import 'package:math_dash/state/game_session_provider.dart';
import 'package:math_dash/state/player_provider.dart';
import 'package:math_dash/state/proficiency_provider.dart';

// ---------------------------------------------------------------------------
// Concept → wheel colour (presentation concern; not in domain layer).
// ---------------------------------------------------------------------------

Color _colorForConcept(String conceptId) => switch (conceptId) {
  'add_1digit' => Colors.orange.shade600,
  'sub_1digit' => Colors.blue.shade600,
  'add_2digit' => Colors.green.shade600,
  'sub_2digit' => Colors.purple.shade600,
  'mul_1digit' => Colors.red.shade600,
  'div_1digit' => Colors.teal.shade600,
  _ => Colors.grey.shade600,
};

List<WheelSegment> _buildSegments(List<Concept> concepts) => concepts
    .map(
      (c) => WheelSegment(
        conceptId: c.id,
        label: c.shortLabel,
        color: _colorForConcept(c.id),
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
      final playerGrade =
          ref.read(activePlayerProvider).asData?.value.gradeLevel ?? 2;
      final band = bandForConcept(conceptId, profMap, playerGrade);

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
