import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/domain/questions/question.dart';
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
                _StarAward(stars: widget.starsEarned, theme: theme),
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
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
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
  const _StarAward({required this.stars, required this.theme});

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
