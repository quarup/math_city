import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/domain/questions/question.dart';
import 'package:math_dash/presentation/spin/spin_screen.dart';
import 'package:math_dash/state/game_session_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    required this.question,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.starsEarned,
    super.key,
  });

  final Question question;
  final String selectedAnswer;
  final bool isCorrect;
  final int starsEarned;

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
    final isCorrect = widget.isCorrect;

    return Scaffold(
      backgroundColor: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
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
                color: isCorrect ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                isCorrect ? 'Correct!' : 'Not quite…',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCorrect
                      ? Colors.green.shade800
                      : Colors.red.shade800,
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
                child: const Text('Next Round'),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
        const SizedBox(width: 8),
        Text(
          '+$stars',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade800,
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
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You answered: $selectedAnswer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              explanation,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
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
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${widget.starsEarned}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
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
