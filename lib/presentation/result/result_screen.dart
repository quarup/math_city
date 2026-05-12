import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/concepts/dag_engine.dart';
import 'package:math_city/domain/questions/answer_check.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/presentation/spin/spin_screen.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/state/game_session_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    required this.question,
    required this.selectedAnswer,
    required this.outcome,
    required this.starsEarned,
    this.unlockEvent,
    this.debugMode = false,
    super.key,
  });

  final GeneratedQuestion question;
  final String selectedAnswer;

  /// Three-way classification of [selectedAnswer] vs the question's
  /// canonical answer (see `answer_check.dart`). `canonical` and
  /// `equivalentNonCanonical` both render the success state; the latter
  /// also surfaces a friendly nudge with the canonical form.
  final AnswerOutcome outcome;
  final int starsEarned;

  /// Drip-feed unlock to celebrate. Caller is responsible for ensuring
  /// this is null on wrong answers — the result screen does not double-
  /// check (we trust the caller per plan.md Phase 5).
  final UnlockEvent? unlockEvent;

  /// When true, "Next round" pops back to the debug picker instead of
  /// pushing the spin wheel. Caller is also responsible for passing
  /// `starsEarned: 0` so no stars are written to the player profile.
  final bool debugMode;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  final GlobalKey _starKey = GlobalKey();
  bool _starVisible = true;

  @override
  void initState() {
    super.initState();
    if (widget.starsEarned > 0) {
      // Defer so we're not mutating provider state during a build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(totalStarsProvider.notifier).add(widget.starsEarned);
      });
    }
  }

  Future<void> _onNextRound() async {
    if (widget.debugMode) {
      Navigator.of(context).pop();
      return;
    }

    if (widget.starsEarned <= 0) {
      _pushSpin();
      return;
    }

    final box = _starKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      _pushSpin();
      return;
    }

    final starCenter = box.localToGlobal(
      Offset(box.size.width / 2, box.size.height / 2),
    );
    // Target: the star icon in SpinScreen's AppBar (top-right area).
    final screenWidth = MediaQuery.of(context).size.width;
    final target = Offset(screenWidth - 44, 60);

    // Hide the original so it looks like it's moving, not cloned.
    setState(() => _starVisible = false);

    final overlayState = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayCtx) => _FlyingStarOverlay(
        from: starCenter,
        to: target,
        starsEarned: widget.starsEarned,
      ),
    );
    overlayState.insert(entry);

    // Navigate mid-flight so the star appears to land on the counter.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) {
      entry.remove();
      return;
    }
    _pushSpin(pulse: true);

    await Future<void>.delayed(const Duration(milliseconds: 350));
    entry.remove();
  }

  void _pushSpin({bool pulse = false}) {
    unawaited(
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => SpinScreen(pulseStars: pulse),
        ),
        (route) => route.isFirst,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final isCorrect = widget.outcome != AnswerOutcome.wrong;
    final isEquivalentNonCanonical =
        widget.outcome == AnswerOutcome.equivalentNonCanonical;

    return Scaffold(
      backgroundColor:
          isCorrect ? palette.successGreenSoft : palette.errorRedSoft,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 80,
                color: isCorrect
                    ? palette.successGreenDeep
                    : palette.errorRedDeep,
              ),
              const SizedBox(height: 16),
              Text(
                isCorrect ? 'Correct!' : 'Not quite…',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCorrect
                      ? palette.successGreenDeep
                      : palette.errorRedDeep,
                ),
                textAlign: TextAlign.center,
              ),
              if (isCorrect && widget.starsEarned > 0) ...[
                const SizedBox(height: 16),
                Opacity(
                  opacity: _starVisible ? 1.0 : 0.0,
                  child: _StarAward(
                    key: _starKey,
                    stars: widget.starsEarned,
                    theme: theme,
                  ),
                ),
              ],
              if (isEquivalentNonCanonical) ...[
                const SizedBox(height: 16),
                _EquivalentNudgeCard(
                  playerAnswer: widget.selectedAnswer,
                  canonical: widget.question.correctAnswer,
                ),
              ],
              if (isCorrect && widget.unlockEvent != null) ...[
                const SizedBox(height: 24),
                _UnlockCard(event: widget.unlockEvent!),
              ],
              if (!isCorrect) ...[
                const SizedBox(height: 24),
                _ExplanationCard(
                  selectedAnswer: widget.selectedAnswer,
                  explanation: widget.question.explanation,
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _onNextRound,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: theme.textTheme.titleLarge,
                ),
                child: Text(widget.debugMode ? 'Try another' : 'Next Round'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarAward extends StatelessWidget {
  const _StarAward({required this.stars, required this.theme, super.key});

  final int stars;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final palette = theme.extension<AppPalette>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star_rounded, color: palette.coinGold, size: 40),
        const SizedBox(width: 8),
        Text(
          '+$stars',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: palette.coinGoldDeep,
          ),
        ),
      ],
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({
    required this.selectedAnswer,
    required this.explanation,
  });

  final String selectedAnswer;
  final List<String> explanation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Card(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You answered: $selectedAnswer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.errorRedDeep,
              ),
            ),
            const SizedBox(height: 12),
            for (final step in explanation)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  step,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Friendly nudge when the player's answer is mathematically equivalent
/// but not in canonical (lowest-terms / textbook) form. Resolves [GitHub
/// issue #2 option (c)] — we accepted the answer, now teach the
/// simplification.
class _EquivalentNudgeCard extends StatelessWidget {
  const _EquivalentNudgeCard({
    required this.playerAnswer,
    required this.canonical,
  });

  final String playerAnswer;
  final String canonical;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Card(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.successGreenDeep, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: palette.successGreenDeep,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "You said $playerAnswer — that's equal to $canonical!",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  const _UnlockCard({required this.event});

  final UnlockEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Card(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.coinGold, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.lock_open_rounded,
              color: palette.coinGold,
              size: 36,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New concept unlocked!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: palette.coinGoldDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.newConcept.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
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

class _FlyingStarOverlay extends StatefulWidget {
  const _FlyingStarOverlay({
    required this.from,
    required this.to,
    required this.starsEarned,
  });

  final Offset from;
  final Offset to;
  final int starsEarned;

  @override
  State<_FlyingStarOverlay> createState() => _FlyingStarOverlayState();
}

class _FlyingStarOverlayState extends State<_FlyingStarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    unawaited(_ctrl.forward());
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) {
        final t = _anim.value;
        final linear = Offset.lerp(widget.from, widget.to, t)!;
        // Arc upward at the midpoint.
        final arcY = math.sin(t * math.pi) * -80.0;
        final pos = Offset(linear.dx, linear.dy + arcY);
        final scale = 1.0 - 0.55 * t;
        final opacity = t > 0.75 ? (1.0 - t) / 0.25 : 1.0;

        return Positioned(
          left: pos.dx,
          top: pos.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: palette.coinGold,
                      size: 36,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${widget.starsEarned}',
                      style: TextStyle(
                        color: palette.coinGold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(
                            color: Color(0x99000000),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
