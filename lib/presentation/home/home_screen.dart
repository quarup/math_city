import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_city/presentation/player/player_creation_screen.dart';
import 'package:math_city/presentation/spin/spin_screen.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/state/player_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.playIntro = false});

  /// When true, the non-logo content fades in after the logo's hero flight
  /// from the splash screen settles. Default false for back-navigations.
  final bool playIntro;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Must match the splash-route transitionDuration so the fade waits for the
  // hero to land.
  static const _heroDuration = Duration(milliseconds: 700);
  static const _fadeDuration = Duration(milliseconds: 450);

  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: _fadeDuration,
      value: widget.playIntro ? 0 : 1,
    );
    if (widget.playIntro) {
      unawaited(
        Future<void>.delayed(_heroDuration, () {
          if (mounted) unawaited(_intro.forward());
        }),
      );
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allPlayersProvider);
    final activeId = ref.watch(activePlayerIdProvider);
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;

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
                      child: Hero(
                        tag: 'math-city-logo',
                        child: Image.asset(
                          'assets/images/math_city_logo.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _intro,
                          curve: Curves.easeOut,
                        ),
                        child: allAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e')),
                          data: (players) =>
                              _buildPlayersAndSpin(theme, players, activeId),
                        ),
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
  }

  Widget _buildPlayersAndSpin(
    ThemeData theme,
    List<Player> players,
    int? activeId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select player:',
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
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final p in players)
                _PlayerChip(
                  player: p,
                  isSelected: p.id == activeId,
                  onTap: () => _selectAndPlay(p),
                  onEdit: () => _openEdit(context, p),
                ),
              _AddChip(onTap: () => _openCreation(context)),
            ],
          ),
      ],
    );
  }

  void _selectAndPlay(Player player) {
    ref.read(activePlayerIdProvider.notifier).selected = player.id;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SpinScreen(),
        ),
      ),
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
