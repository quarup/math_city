import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/presentation/city/city_screen.dart';
import 'package:math_city/presentation/debug/concept_debug_screen.dart';
import 'package:math_city/presentation/home/tile_patch.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_city/presentation/player/player_creation_screen.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/services/debug_harness.dart';
import 'package:math_city/state/player_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.playIntro = false});

  /// When true, the screen opens on the frame the OS launch screen leaves
  /// behind — flat sky with the app icon's house in the middle — and plays
  /// the launch intro from it: the neighbouring tiles pop in around the
  /// house, the patch settles to the bottom of the screen, the lockup drops
  /// in and the player cards fade up. Default false for back-navigations,
  /// which show the resting layout at once.
  final bool playIntro;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _introDuration = Duration(milliseconds: 1600);

  /// The Android 12+ launch screen draws the icon on a 288 dp canvas; the
  /// iOS storyboard does the same. The icon's own canvas is 108 units.
  static const double _launchIconDp = 288;
  static const double _unit = _launchIconDp / TilePatch.box;

  /// Scale the patch shrinks towards while it glides down and fades out.
  static const _endScale = 0.45;

  /// Flat sky behind the OS launch icon; the top of the sky gradient.
  static const _launchSky = Color(0xFF5DB7E8);

  late final AnimationController _intro;

  // Timeline, in seconds of [_introDuration] (1.6 s):
  //   0.25–0.95  neighbours pop in
  //   0.60–1.00  flat sky fades to the gradient
  //   0.95–1.35  patch glides down, shrinks and fades away
  //   0.95–1.30  city strip fades in behind it
  //   1.05–1.45  lockup drops in
  //   1.25–1.60  player cards fade in
  late final Animation<double> _pop = _phase(0.25, 0.95);
  late final Animation<double> _gradient = _phase(0.6, 1);
  late final Animation<double> _move = _phase(0.95, 1.35, Curves.easeInCubic);
  late final Animation<double> _strip = _phase(0.95, 1.3);
  late final Animation<double> _lockup = _phase(
    1.05,
    1.45,
    Curves.easeOutCubic,
  );
  late final Animation<double> _cards = _phase(1.25, 1.6);

  /// The launch icon's visible circle is 192 dp across; the clip grows well
  /// past the tile box as the neighbours pop in.
  late final Animation<double> _centreClip = Tween<double>(
    begin: 96,
    end: 400,
  ).animate(_pop);

  Animation<double> _phase(
    double fromS,
    double toS, [
    Curve curve = Curves.easeOut,
  ]) {
    final total = _introDuration.inMilliseconds / 1000;
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(fromS / total, toS / total, curve: curve),
    );
  }

  @override
  void initState() {
    super.initState();
    // Tells the UX-sweep harness a question can be pushed now.
    DebugHarness.instance.markHomeReady();
    _intro = AnimationController(
      vsync: this,
      duration: _introDuration,
      value: widget.playIntro ? 0 : 1,
    );
    if (widget.playIntro) unawaited(_startIntro());
  }

  /// The OS launch screen stays up until Flutter's first frame is
  /// rasterised, which on a cold start can take well over a second; the
  /// intro's clock must not run while the launch screen still covers it.
  /// The short hold after that gives the launch screen's dismissal time to
  /// finish on the frame that matches it.
  Future<void> _startIntro() async {
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) await _intro.forward();
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // The OS centres its launch icon on the physical display. Flutter's
    // window can be shorter than that (it stops above the navigation bar
    // unless the app is edge-to-edge), so the display, not the window,
    // gives the launch icon's centre; the window starts at the display's top.
    final display = View.of(context).display;
    final displayHeight = display.size.height / display.devicePixelRatio;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.skyGradientStart, palette.skyGradientEnd],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            // Frame zero: the patch's centre box sits where the OS drew the
            // launch icon, the middle of the screen. It then glides towards
            // the bottom edge, shrinking and fading, and hands the ground
            // over to the painted city strip.
            final launchCentre = Offset(size.width / 2, displayHeight / 2);
            final endCentre = Offset(
              size.width / 2,
              size.height -
                  bottomInset -
                  8 -
                  TilePatch.bottomUnits * _unit * _endScale,
            );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FadeTransition(
                    opacity: _strip,
                    child: Image.asset(
                      'assets/images/math_city_bottom.png',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: FadeTransition(
                      opacity: ReverseAnimation(_gradient),
                      child: const ColoredBox(color: _launchSky),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _move,
                  builder: (context, child) {
                    final t = _move.value;
                    if (t >= 1) return const SizedBox.shrink();
                    final centre = Offset.lerp(launchCentre, endCentre, t)!;
                    final scale = lerpDouble(1, _endScale, t)!;
                    return Positioned(
                      left: centre.dx - TilePatch.widthUnits * _unit / 2,
                      top: centre.dy - TilePatch.heightUnits * _unit / 2,
                      child: Opacity(
                        opacity: 1 - t,
                        child: Transform.scale(scale: scale, child: child),
                      ),
                    );
                  },
                  child: IgnorePointer(
                    child: TilePatch(
                      unit: _unit,
                      pop: _pop,
                      centreClipRadius: _centreClip,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SlideTransition(
                          position: Tween(
                            begin: const Offset(0, -0.6),
                            end: Offset.zero,
                          ).animate(_lockup),
                          child: FadeTransition(
                            opacity: _lockup,
                            child: const _Lockup(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _cards,
                            builder: (context, child) => IgnorePointer(
                              ignoring: _cards.value < 1,
                              child: Opacity(
                                opacity: _cards.value,
                                child: child,
                              ),
                            ),
                            child: allAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) => Center(child: Text('Error: $e')),
                              data: (players) => _buildPlayersAndSpin(
                                theme,
                                players,
                                activeId,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
          'Who is playing?',
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
              onDebug: kDebugMode ? () => _openDebug(context) : null,
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
                  onTap: () => _selectAndOpenCity(p),
                  onEdit: () => _openEdit(context, p),
                ),
              _AddChip(onTap: () => _openCreation(context)),
              if (kDebugMode) _DebugChip(onTap: () => _openDebug(context)),
            ],
          ),
      ],
    );
  }

  void _selectAndOpenCity(Player player) {
    ref.read(activePlayerIdProvider.notifier).selected = player.id;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: CityScreen.routeName),
          builder: (_) => const CityScreen(),
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

  void _openDebug(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ConceptDebugScreen(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lockup: the icon's tile at the head of the wordmark
// ---------------------------------------------------------------------------

class _HouseTile extends StatelessWidget {
  const _HouseTile({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/tiles/house.svg',
      width: size,
      height: size,
    );
  }
}

class _Lockup extends StatelessWidget {
  const _Lockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // The tile's box carries empty margin around the house (it is the
        // icon's canvas); show it through a narrower slot so the house sits
        // close to the wordmark.
        const SizedBox(
          width: 66,
          height: 88,
          child: OverflowBox(
            maxWidth: 88,
            maxHeight: 88,
            child: _HouseTile(size: 88),
          ),
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Image.asset(
            'assets/images/math_city_wordmark.png',
            height: 58,
            fit: BoxFit.contain,
          ),
        ),
      ],
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
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
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
    final palette = theme.extension<AppPalette>()!;
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
            // brandTealDeep, not primary: the logo teal only reaches 2.1:1 on
            // this card fill.
            Icon(
              Icons.person_add_rounded,
              size: 28,
              color: palette.brandTealDeep,
            ),
            const SizedBox(height: 6),
            Text(
              'Add',
              style: theme.textTheme.labelMedium?.copyWith(
                color: palette.brandTealDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Debug chip (kDebugMode only — opens the ConceptDebugScreen)
// ---------------------------------------------------------------------------

class _DebugChip extends StatelessWidget {
  const _DebugChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The logo yellow lands at 1.29:1 on this card fill — all but invisible.
    // A neutral keeps the dev-only chip legible and subordinate to the teal
    // player/add cards; the bug glyph is what distinguishes it, not the hue.
    final accent = theme.colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bug_report_rounded, size: 28, color: accent),
            const SizedBox(height: 6),
            Text(
              'Debug',
              style: theme.textTheme.labelMedium?.copyWith(color: accent),
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
  const _EmptyPlayerPrompt({required this.onAdd, this.onDebug});

  final VoidCallback onAdd;
  final VoidCallback? onDebug;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Solid fill, not an outline: the sky gradient sits behind these, and
          // a transparent button leaves both the label and the border far under
          // WCAG contrast (see AppPalette.brandTealDeep).
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Create Player'),
            style: FilledButton.styleFrom(
              backgroundColor: palette.brandTealDeep,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 16,
              ),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDebug != null) ...[
            const SizedBox(height: 14),
            // Deliberately quieter than the primary action, but still on a
            // solid ground so it doesn't dissolve into the sky.
            FilledButton.icon(
              onPressed: onDebug,
              icon: const Icon(Icons.bug_report_rounded, size: 20),
              label: const Text('Debug'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerLowest,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
