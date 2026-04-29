import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/game/spin_wheel/spin_wheel_game.dart';
import 'package:math_dash/presentation/question/question_screen.dart';
import 'package:math_dash/state/game_session_provider.dart';

class SpinScreen extends ConsumerStatefulWidget {
  const SpinScreen({this.pulseStars = false, super.key});

  final bool pulseStars;

  @override
  ConsumerState<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends ConsumerState<SpinScreen>
    with TickerProviderStateMixin {
  late final SpinWheelGame _game;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _game = SpinWheelGame(onConceptSelected: _onConceptSelected);
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.6), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.6, end: 1), weight: 65),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    if (widget.pulseStars) {
      // Delay so the pulse coincides with the flying star arriving.
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
    // Defer navigation to avoid touching the widget tree mid-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => QuestionScreen(conceptId: conceptId),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final stars = ref.watch(totalStarsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Spin the Wheel'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ScaleTransition(
              scale: _pulseScale,
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
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
        child: GameWidget(game: _game),
      ),
    );
  }
}
