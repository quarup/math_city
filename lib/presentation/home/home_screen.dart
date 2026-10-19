import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/presentation/city/city_screen.dart';
import 'package:math_city/presentation/debug/concept_debug_screen.dart';
import 'package:math_city/presentation/home/player_sticker.dart';
import 'package:math_city/presentation/home/tile_patch.dart';
import 'package:math_city/presentation/player/player_creation_flow.dart';
import 'package:math_city/presentation/player/player_edit_hub.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/widgets/on_side.dart';
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
  static const _introDuration = Duration(milliseconds: 2700);

  /// The Android 12+ launch screen draws the icon on a 288 dp canvas; the
  /// iOS storyboard does the same. The icon's own canvas is 108 units.
  static const double _launchIconDp = 288;
  static const double _unit = _launchIconDp / TilePatch.box;

  /// Scale the patch shrinks towards while it glides down and fades out.
  static const _endScale = 0.45;

  /// Flat sky behind the OS launch icon; the top of the sky gradient.
  static const _launchSky = Color(0xFF5DB7E8);

  /// Height of the painted city band along the bottom edge. On a side the
  /// band is low and the painting shows end to end; upright it is taller
  /// and the painting's middle fills it.
  static const double kSideStripHeight = 92;
  static const double kUprightStripHeight = 150;

  late final AnimationController _intro;

  // Timeline, in seconds of [_introDuration] (2.7 s):
  //   0.25–1.15  neighbours pop in
  //   0.60–1.00  flat sky fades to the gradient
  //   1.15–1.50  the full patch holds, centred
  //   1.50–2.60  patch glides down and shrinks, fading over its last part
  //   1.50–2.10  city strip fades in behind it
  //   1.90–2.40  lockup drops in
  //   2.20–2.70  player cards fade in
  late final Animation<double> _pop = _phase(0.25, 1.15);
  late final Animation<double> _gradient = _phase(0.6, 1);
  late final Animation<double> _move = _phase(1.5, 2.6, Curves.easeInOutCubic);
  late final Animation<double> _strip = _phase(1.5, 2.1);
  late final Animation<double> _lockup = _phase(1.9, 2.4, Curves.easeOutCubic);
  late final Animation<double> _cards = _phase(2.2, 2.7);

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
    // iOS reports the display in its native portrait orientation even when
    // the app is in landscape, so the side running the window's height is
    // whichever one matches the window's orientation.
    final display = View.of(context).display;
    final displaySize = display.size / display.devicePixelRatio;
    final windowSize = MediaQuery.sizeOf(context);
    final displayHeight =
        (displaySize.width > displaySize.height) ==
            (windowSize.width > windowSize.height)
        ? displaySize.height
        : displaySize.width;

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
            final onSide = isOnSide(constraints);
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
                // The painted city is a fixed-height band — low on a
                // phone on its side, taller upright — and the image fills
                // it from its bottom edge, so a wider painting shows more
                // buildings rather than growing taller.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: onSide ? kSideStripHeight : kUprightStripHeight,
                  child: FadeTransition(
                    opacity: _strip,
                    child: Image.asset(
                      'assets/images/math_city_bottom.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
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
                        opacity: 1 - Curves.easeIn.transform(t),
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
                    padding: EdgeInsets.fromLTRB(
                      24,
                      onSide ? 16 : 24,
                      24,
                      onSide ? kSideStripHeight + 8 : 24,
                    ),
                    child: onSide
                        ? _onSide(theme, allAsync, activeId)
                        : _upright(theme, allAsync, activeId),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _lockupIn() => SlideTransition(
    position: Tween(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(_lockup),
    child: FadeTransition(opacity: _lockup, child: const _Lockup()),
  );

  /// The player block, faded in after the lockup, scaled down rather than
  /// overflowing when the space is short: no scrolling, no stripes.
  Widget _cardsIn(
    ThemeData theme,
    AsyncValue<List<Player>> allAsync,
    int? activeId, {
    required bool onSide,
  }) => AnimatedBuilder(
    animation: _cards,
    builder: (context, child) => IgnorePointer(
      ignoring: _cards.value < 1,
      child: Opacity(opacity: _cards.value, child: child),
    ),
    child: allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (players) => LayoutBuilder(
        builder: (context, c) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: onSide ? Alignment.center : Alignment.topCenter,
          child: SizedBox(
            width: c.maxWidth,
            child: _buildPlayersAndSpin(
              theme,
              players,
              activeId,
              onSide: onSide,
            ),
          ),
        ),
      ),
    ),
  );

  /// Upright: the lockup, then the title and the stickers under it.
  Widget _upright(
    ThemeData theme,
    AsyncValue<List<Player>> allAsync,
    int? activeId,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _lockupIn(),
      const SizedBox(height: 20),
      Expanded(child: _cardsIn(theme, allAsync, activeId, onSide: false)),
    ],
  );

  /// On a side: the lockup and the title in a narrow left column, the
  /// stickers wrapping in the rest.
  Widget _onSide(
    ThemeData theme,
    AsyncValue<List<Player>> allAsync,
    int? activeId,
  ) {
    final palette = theme.extension<AppPalette>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 230,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lockupIn(),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _cards,
                child: Text(
                  'Who is playing?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.tileInk,
                  ),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _cards,
                  child: _DebugButton(onPressed: () => _openDebug(context)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(child: _cardsIn(theme, allAsync, activeId, onSide: true)),
      ],
    );
  }

  Widget _buildPlayersAndSpin(
    ThemeData theme,
    List<Player> players,
    int? activeId, {
    required bool onSide,
  }) {
    final palette = theme.extension<AppPalette>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!onSide) ...[
          Text(
            'Who is playing?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.tileInk,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (players.isEmpty)
          SizedBox(
            height: 130,
            child: _EmptyPlayerPrompt(
              onAdd: () => _openCreation(context),
              onDebug: kDebugMode && !onSide ? () => _openDebug(context) : null,
            ),
          )
        else ...[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 16,
            children: [
              for (final p in players)
                PlayerSticker(
                  player: p,
                  isSelected: p.id == activeId,
                  onTap: () => _selectAndOpenCity(p),
                  onEdit: () => _openEdit(context, p),
                ),
              AddPlayerSticker(onTap: () => _openCreation(context)),
            ],
          ),
          if (kDebugMode && !onSide) ...[
            const SizedBox(height: 10),
            Center(child: _DebugButton(onPressed: () => _openDebug(context))),
          ],
        ],
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
        MaterialPageRoute<void>(builder: (_) => const PlayerCreationFlow()),
      ),
    );
  }

  void _openEdit(BuildContext context, Player player) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PlayerEditHub(player: player)),
      ),
    );
  }

  void _openDebug(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ConceptDebugScreen()),
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

class _DebugButton extends StatelessWidget {
  const _DebugButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.bug_report_rounded, size: 16),
    label: const Text('Debug'),
    style: TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      visualDensity: VisualDensity.compact,
    ),
  );
}

class _Lockup extends StatelessWidget {
  const _Lockup();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
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
          Image.asset(
            'assets/images/math_city_wordmark.png',
            height: 58,
            fit: BoxFit.contain,
          ),
        ],
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
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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
