import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/presentation/spin/spin_screen.dart';
import 'package:math_dash/state/game_session_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stars = ref.watch(totalStarsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Math Dash',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _StarCounter(stars: stars),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SpinScreen(),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Spin!'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarCounter extends StatelessWidget {
  const _StarCounter({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
        const SizedBox(width: 6),
        Text(
          '$stars',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'stars',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
