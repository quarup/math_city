import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:math_dash/game/spin_wheel/spin_wheel_game.dart';
import 'package:math_dash/presentation/question/question_screen.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> {
  late final SpinWheelGame _game;

  @override
  void initState() {
    super.initState();
    _game = SpinWheelGame(onConceptSelected: _onConceptSelected);
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Spin the Wheel'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GameWidget(game: _game),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Swipe the wheel to spin!',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
