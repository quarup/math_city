import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_city/presentation/player/player_creation_screen.dart';
import 'package:math_city/presentation/spin/spin_screen.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/state/player_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allPlayersProvider);
    final activeId = ref.watch(activePlayerIdProvider);
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;

    return allAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (players) {
        // Auto-select the first player when none is active yet.
        if (players.isNotEmpty && activeId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(activePlayerIdProvider.notifier).selected =
                players.first.id;
          });
        }

        return Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.skyGradientStart, palette.skyGradientEnd],
              ),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/images/math_city_bottom.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/images/math_city_logo.png',
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ---- Player chip row ----
                        Text(
                          "Who's playing?",
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (players.isEmpty)
                          SizedBox(
                            height: 130,
                            child: _EmptyPlayerPrompt(
                              onAdd: () => _openCreation(context),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final p in players)
                                _PlayerChip(
                                  player: p,
                                  isSelected: p.id == activeId,
                                  onTap: () => ref
                                      .read(activePlayerIdProvider.notifier)
                                      .selected = p.id,
                                  onEdit: () => _openEdit(context, p),
                                ),
                              _AddChip(onTap: () => _openCreation(context)),
                            ],
                          ),

                        const SizedBox(height: 24),

                        // ---- Spin button ----
                        FilledButton.icon(
                          onPressed: activeId == null
                              ? null
                              : () => unawaited(
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const SpinScreen(),
                                      ),
                                    ),
                                  ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Spin!'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            textStyle: theme.textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCreation(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PlayerCreationScreen(),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, Player player) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlayerCreationScreen(initialPlayer: player),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Player chip
// ---------------------------------------------------------------------------

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.player,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
  });

  final Player player;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 96,
        height: 120,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AdventurerAvatarWidget(config: player.avatar, size: 52),
                  const SizedBox(height: 4),
                  Text(
                    player.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: palette.coinGold,
                        size: 13,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${player.currentStars}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Edit icon pinned to top-right
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 13,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add-player chip
// ---------------------------------------------------------------------------

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_rounded,
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 6),
            Text(
              'Add',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state prompt (no players yet)
// ---------------------------------------------------------------------------

class _EmptyPlayerPrompt extends StatelessWidget {
  const _EmptyPlayerPrompt({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: OutlinedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Create Player'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: theme.textTheme.titleMedium,
        ),
      ),
    );
  }
}
