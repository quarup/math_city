import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/construction_sites.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/domain/city/beat_registry.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/category.dart';
import 'package:math_city/domain/city/chapter_one.dart';
import 'package:math_city/domain/city/citizen.dart';
import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/domain/city/land_blocks.dart';
import 'package:math_city/domain/city/placement_rules.dart';
import 'package:math_city/domain/city/road_network.dart';
import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/domain/city/upgrade_ladders.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/game/city/city_board_component.dart';
import 'package:math_city/game/city/iso_city_game.dart';
import 'package:math_city/game/city/iso_grid.dart';
import 'package:math_city/game/city/land_window.dart';
import 'package:math_city/presentation/city/celebration_overlay.dart';
import 'package:math_city/presentation/city/letter_overlay.dart';
import 'package:math_city/presentation/city/spin_overlay.dart';
import 'package:math_city/presentation/city/times_overlay.dart';
import 'package:math_city/presentation/navigation/route_observer.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_city/presentation/question/question_screen.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/widgets/coach_hand.dart';
import 'package:math_city/presentation/widgets/coin_icon.dart';
import 'package:math_city/presentation/widgets/site_progress_bar.dart';
import 'package:math_city/state/city_provider.dart';
import 'package:math_city/state/game_session_provider.dart';
import 'package:math_city/state/player_provider.dart';
import 'package:math_city/state/tts_provider.dart';

/// Category → placeholder building color (presentation concern, not domain).
const _categoryColors = <BuildingCategory, Color>{
  BuildingCategory.civicHousing: Color(0xFFBCAAA4), // warm stone
  BuildingCategory.services: Color(0xFF64B5F6), // blue
  BuildingCategory.commercial: Color(0xFFFFB74D), // amber
  BuildingCategory.entertainment: Color(0xFF81C784), // green
};

Color _colorFor(BuildingType b) =>
    _categoryColors[b.category] ?? const Color(0xFF90A4AE);

/// "My City" — the per-player hub. Players reach it by tapping their chip on
/// the home screen. Placing a catalog building starts a *construction site*
/// (city_builder.md §8): no coins change hands, and the wheel is reached by
/// tapping a site's *Build!* — every coin a block earns pays that site down
/// until it opens. There is no coin balance anywhere on this screen.
class CityScreen extends ConsumerStatefulWidget {
  const CityScreen({super.key});

  /// Route name so the spin→question→result loop can return here rather than
  /// all the way to the home screen.
  static const routeName = 'city';

  @override
  ConsumerState<CityScreen> createState() => _CityScreenState();
}

/// What the city screen is doing (city_builder.md §8.7): browsing the
/// board, zoomed onto a site with the wheel above it, or zoomed onto a
/// just-opened building for its celebration. Back from a zoomed state zooms
/// out; it never pops.
enum _CityMode { browsing, siteZoomed, celebrating }

class _CityScreenState extends ConsumerState<CityScreen> with RouteAware {
  IsoCityGame? _game;

  _CityMode _mode = _CityMode.browsing;

  /// The site the camera is on while [_mode] is `siteZoomed`.
  CitySite? _zoomedSite;

  /// Whether the wheel overlay is faded in. Off while the camera tweens and
  /// while a question route sits on top.
  bool _wheelVisible = false;

  /// Bumped for every fresh wheel so the overlay rebuilds its game.
  int _wheelGeneration = 0;

  /// The site that just opened, while its celebration is up.
  ConstructionSite? _celebratingSite;

  /// The celebration card and the board, measured to frame the finished
  /// building in the map area the card leaves free.
  final GlobalKey _celebrationCardKey = GlobalKey();
  final GlobalKey _boardKey = GlobalKey();

  /// The bottom bar, measured after each layout: it is drawn *over* the
  /// game rather than beside it, so the game widget never resizes (and the
  /// camera never jumps) when a bar of a different height comes up. Its
  /// height is handed to the game as [IsoCityGame.bottomInset].
  final GlobalKey _barKey = GlobalKey();
  double _barHeight = 0;

  /// The block the current wheel follows, shown as a recap card above it;
  /// null for the first wheel after *Build!*.
  QuestionBlock? _recapBlock;

  /// The world-tile window the board currently renders (owned land + pale
  /// frontier bounding box). Drives the world↔local translation; grows
  /// monotonically as land is bought. Null until the first build with data.
  LandWindow? _window;

  /// Catalog building type chosen for *new* placement. While set, the bottom
  /// bar asks for a location; a tap on free land then proposes a spot
  /// ([_pendingSpot]) for the player to confirm.
  BuildingType? _selected;

  /// Where [_selected] would go, awaiting *Place here*. The board shows it
  /// as a highlighted ghost; tapping another free tile moves it. Cleared on
  /// confirm, on X, and whenever another mode takes over.
  GridFootprint? _pendingSpot;

  /// The letter on screen (a beat id), or null. Set when a fired letter
  /// interrupts the city at rest, or when the player re-opens one from its
  /// badged catalog card; cleared by *Later* / *Build it!*.
  String? _letterId;

  /// The letter last announced (marked shown + spoken), so a rebuild while
  /// it is up doesn't speak it twice.
  String? _announcedLetterId;

  /// Fulfilled beats whose retirement has been dispatched, so each is
  /// retired once per completion.
  final Set<String> _retiring = <String>{};

  /// Bubble beats already handed to a walker, so each fire bubbles once.
  final Set<String> _bubbled = <String>{};

  /// Grow mode (city_builder.md §10.6): the rung being grown into, the
  /// buildings it could grow out of (oldest first) and which is picked.
  /// The picked one is tinted on the map; ◀ ▶ on the grow bar or a tap on
  /// another candidate changes the pick.
  BuildingType? _growTarget;
  List<BuildingPlacement> _growCandidates = const [];
  int _growIndex = 0;

  /// The building an upgrade site will replace, carried from *Yes, grow
  /// it* into *Place here*.
  BuildingPlacement? _growSource;

  /// The folder open in the bar's third zone (city_builder.md §10.5), or
  /// null for the four folder cards.
  BuildingCategory? _openFolder;

  /// Catalog cards seen so far this session; a card that arrives later
  /// sparkles until its folder is opened. Null until the first catalog.
  Set<String>? _seenCardIds;

  /// Clears the red "no room" footprint after its moment.
  Timer? _rejectedTimer;

  /// A letter waits [kLetterDelay] after the city comes to rest before it
  /// interrupts, so the kid gets a moment with the city first. The timer
  /// arms [_letterArmed] for the beat it was started for.
  Timer? _letterDelay;
  String? _letterPending;
  String? _letterArmed;

  /// The idle nudge (city_builder.md §10.4): with no site open and a letter
  /// waiting on its card, the card bounces every few seconds of inactivity.
  Timer? _nudgeTimer;
  bool _nudge = false;

  /// Whether chapter one is still running for the active player: no
  /// folders, no info cards, no land purchases, no moves.
  bool get _chapterOne =>
      (ref.read(activePlayerProvider).asData?.value.guideStep ??
          kChapterOneDone) <
      kChapterOneDone;

  /// The placed building currently picked up for repositioning (yellow tint +
  /// footprint outline), or null when nothing is selected. Set by tapping a
  /// building, or automatically right after one is bought + placed so the
  /// player can nudge it into place on a small screen.
  int? _movingId;

  /// The frontier block currently selected to start a land site on (yellow
  /// highlight + confirm bar at the bottom), or null.
  (int, int)? _buyingBlock;

  /// The construction site currently selected (yellow fence, site bar at the
  /// bottom with its `paid / price` and *Build!*), or null. A tap on the map
  /// while a site is selected just deselects it; its bar's move button
  /// enters [_movingSiteId].
  int? _selectedSiteId;

  /// The placed building whose info card is open at the bottom (name, what
  /// it does, *Move*, X), or null. A tap on the map deselects it; *Move*
  /// hands it to [_movingId].
  int? _selectedBuildingId;

  /// The building site picked up for repositioning (from its bar's move
  /// button): the next free-tile tap moves it, its coins along with it.
  int? _movingSiteId;

  /// Where the picked-up building or site stood when it was picked up, so
  /// the move bar's X can put it back. Null once dropped.
  (int, int)? _moveOrigin;

  /// One tap on the board. The board reports a **window-local** tile; we map it
  /// back to world coords via the current window, then dispatch in order:
  /// a tap on the pale buyable frontier selects that block for purchase
  /// (confirmed via the bottom bar, movable by tapping elsewhere on the
  /// frontier); a tap on a placed building picks it up (or drops the held one);
  /// a tap on free owned land repositions the held building or places the
  /// catalog pick (auto-fitting the footprint to cover the tapped tile). A tap
  /// on bare background (neither owned nor buyable) does nothing.
  void _onTileTapped(int localCol, int localRow) {
    // While the wheel is up, the only tappable map is the sharp strip
    // below it: a tap there leaves the loop — hide the wheel and zoom back
    // out to the city — rather than nudging the site. During the
    // celebration the card owns the exit, so taps on the map do nothing.
    if (_mode == _CityMode.siteZoomed) {
      if (_wheelVisible) _zoomOut();
      return;
    }
    if (_mode == _CityMode.celebrating) return;
    final window = _window;
    final ownedBlocks = ref.read(ownedBlocksProvider).asData?.value;
    if (window == null || ownedBlocks == null) return;
    final col = localCol + window.minCol;
    final row = localRow + window.minRow;
    final sites = ref.read(sitesProvider).asData?.value ?? const <CitySite>[];

    final ownedTiles = ownedTilesOf(ownedBlocks);
    if (!ownedTiles.contains((col, row))) {
      // Off owned land: a block with a land site selects that site; a pale
      // frontier block is selected to start a land site on, and a second
      // tap on the *same* block confirms — mirroring how re-tapping a
      // picked-up building drops it there. Either replaces any picked-up
      // building, since the bottom bar shows one mode at a time.
      final block = blockOfTile(col, row);
      final landSite = sites
          .where(
            (s) =>
                s.goal is LandBlockGoal &&
                (s.goal as LandBlockGoal).block == block,
          )
          .firstOrNull;
      if (landSite != null) {
        _selectSite(landSite.id);
        return;
      }
      if (!purchasableBlocks(ownedBlocks).contains(block)) return;
      if (_chapterOne) return; // land comes after the guide
      if (_atSiteCap(sites)) return;
      if (block == _buyingBlock) {
        _startSelectedLandSite();
        return;
      }
      setState(() {
        _buyingBlock = block;
        _movingId = null;
        _movingSiteId = null;
        _moveOrigin = null;
        _selectedSiteId = null;
        _selectedBuildingId = null;
        _pendingSpot = null;
      });
      return;
    }

    // A tap back on owned land while picking land just cancels the
    // selection — it shouldn't also place or pick up a building.
    if (_buyingBlock != null) {
      setState(() => _buyingBlock = null);
      return;
    }

    final placements = ref.read(placementsProvider).asData?.value ?? const [];
    final siteHere = _siteAt(sites, col, row);
    if (siteHere != null) {
      // Tap a site to select it (its bar shows paid / price and Build!);
      // tap the selected one again to drop it.
      _selectSite(siteHere.id == _selectedSiteId ? null : siteHere.id);
      return;
    }
    final occupant = _buildingAt(placements, col, row);
    // In grow mode a tap on another candidate picks it.
    if (_growTarget != null) {
      final i = occupant == null
          ? -1
          : _growCandidates.indexWhere((c) => c.id == occupant.id);
      if (i >= 0) setState(() => _growIndex = i);
      return;
    }
    if (occupant != null) {
      // Tapping the building being moved drops it where it is. Any other
      // building opens its info card (tap the open one again to close it).
      if (occupant.id == _movingId) {
        _dropMoved();
        return;
      }
      setState(() {
        _selectedBuildingId = occupant.id == _selectedBuildingId
            ? null
            : occupant.id;
        _movingId = null;
        _movingSiteId = null;
        _moveOrigin = null;
        _selectedSiteId = null;
        _pendingSpot = null;
      });
      return;
    }

    // A free owned tile: reposition whatever is picked up; else close an
    // open info card; else place the catalog pick (which starts a site).
    if (_movingSiteId != null) {
      _tryMoveSite(_movingSiteId!, col, row, placements, sites, ownedTiles);
      return;
    }
    if (_movingId != null) {
      _tryMove(_movingId!, col, row, placements, sites, ownedTiles);
      return;
    }
    if (_selectedSiteId != null || _selectedBuildingId != null) {
      setState(() {
        _selectedSiteId = null;
        _selectedBuildingId = null;
      });
      return;
    }
    // A tap on bare grass or road with nothing picked is just a tap.
    final selected = _selected;
    if (selected == null) return;
    _tryPlace(selected, col, row, placements, sites, ownedTiles);
  }

  @override
  void initState() {
    super.initState();
    // A city always has its mayor's office (seeded at creation since
    // 2026-09-29; repaired here for older cities), and the first letter is
    // due the moment the office stands.
    unawaited(
      Future<void>.microtask(() async {
        final actions = ref.read(cityActionsProvider);
        await actions.ensureMayorsOffice();
        await actions.fireBeats();
      }),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    _letterDelay?.cancel();
    _rejectedTimer?.cancel();
    _nudgeTimer?.cancel();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Keeps the idle-nudge timer running exactly while [wanted]: every 8 s
  /// of inactivity the first requested card bounces once.
  void _scheduleNudge({required bool wanted}) {
    if (!wanted) {
      _nudgeTimer?.cancel();
      _nudgeTimer = null;
      return;
    }
    _nudgeTimer ??= Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      setState(() => _nudge = true);
      Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _nudge = false);
      });
    });
  }

  /// Starts an event site at [venue] and zooms straight onto it: a party
  /// needs no placement (city_builder.md §10.7).
  Future<void> _startEvent(String eventId, BuildingPlacement venue) async {
    final venueType = findBuildingTypeById(venue.buildingTypeId);
    if (venueType == null) return;
    final result = await ref
        .read(cityActionsProvider)
        .startSite(
          EventGoal(
            eventId: eventId,
            venuePlacementId: venue.id,
            venueType: venueType,
            col: venue.gridX,
            row: venue.gridY,
          ),
        );
    if (!mounted) return;
    if (result.rejection case final rejection?) {
      _toast(_rejectionMessage(rejection, result.openSites));
      return;
    }
    final siteId = result.siteId;
    if (siteId == null) return;
    final sites = await ref.read(sitesProvider.future);
    final site = sites.where((s) => s.id == siteId).firstOrNull;
    if (site != null && mounted) _buildSite(site);
  }

  void _cancelLetterDelay() {
    _letterDelay?.cancel();
    _letterDelay = null;
    _letterPending = null;
    _letterArmed = null;
  }

  /// Paints [type]'s footprint in red at the tapped tile for a moment, so
  /// the player can see how much space it needs.
  void _flashRejected(BuildingType type, int col, int row) {
    final window = _window;
    if (window == null) return;
    final (w, h) = type.footprint;
    final tiles = <(int, int)>{
      for (var c = col; c < col + w; c++)
        for (var r = row; r < row + h; r++)
          (c - window.minCol, r - window.minRow),
    };
    _game?.setRejectedTiles(tiles);
    _rejectedTimer?.cancel();
    _rejectedTimer = Timer(const Duration(milliseconds: 1600), () {
      _game?.setRejectedTiles(const {});
    });
  }

  /// Enters grow mode for [target] with [candidates] to pick from.
  void _enterGrow(BuildingType target, List<BuildingPlacement> candidates) {
    unawaited(ref.read(ttsServiceProvider).stop());
    setState(() {
      _growTarget = target;
      _growCandidates = candidates;
      _growIndex = 0;
      _growSource = null;
      _letterId = null;
      _selected = null;
      _pendingSpot = null;
      _selectedBuildingId = null;
      _selectedSiteId = null;
      _movingId = null;
      _movingSiteId = null;
      _moveOrigin = null;
    });
  }

  void _cancelGrow() => setState(() {
    _growTarget = null;
    _growCandidates = const [];
    _growSource = null;
  });

  /// *Yes, grow it*: proposes the grown footprint over the old tiles when
  /// it fits (the source's own tiles count as free), else on the nearest
  /// spot with room around it; then the usual *Place here* confirms.
  void _confirmGrow(
    List<BuildingPlacement> placements,
    List<CitySite> sites,
    Set<(int, int)> ownedTiles,
  ) {
    final target = _growTarget;
    if (target == null || _growCandidates.isEmpty) return;
    final source = _growCandidates[_growIndex];
    final existing = _footprintsOf(placements, sites, exclude: source.id);
    final over = GridFootprint(
      col: source.gridX,
      row: source.gridY,
      width: target.footprint.$1,
      height: target.footprint.$2,
    );
    final fits = checkPlacement(
      ownedTiles: ownedTiles,
      existing: existing,
      candidate: over,
    ).isLegal;
    final spot = fits
        ? over
        : proposePlacement(
            ownedTiles: ownedTiles,
            existing: existing,
            width: target.footprint.$1,
            height: target.footprint.$2,
            anchor: (source.gridX, source.gridY),
          );
    setState(() {
      _growSource = source;
      _growTarget = null;
      _growCandidates = const [];
      _selected = target;
      _pendingSpot = spot;
    });
  }

  /// Where a letter's *Build it!* proposes [type]: the legal footprint
  /// nearest the mayor's office with room for a road around it.
  GridFootprint? _proposeFor(
    BuildingType type,
    List<BuildingPlacement> placements,
    List<CitySite> sites,
    Set<(int, int)> ownedTiles,
  ) {
    final office = placements
        .where((p) => p.buildingTypeId == 'mayors_office')
        .firstOrNull;
    return proposePlacement(
      ownedTiles: ownedTiles,
      existing: _footprintsOf(placements, sites),
      width: type.footprint.$1,
      height: type.footprint.$2,
      anchor: office == null
          ? AppDatabase.kMayorsOfficeTile
          : (office.gridX, office.gridY),
    );
  }

  /// The question route chain above us went away: read how the block ended
  /// and continue the loop — re-show the wheel, celebrate an opened site,
  /// or zoom back out. A chain that was backed out of publishes nothing, so
  /// a zoomed site simply gets its wheel back.
  @override
  void didPopNext() {
    if (!mounted) return;
    final result = ref.read(lastBlockResultProvider.notifier).take();
    if (_mode != _CityMode.siteZoomed) return;
    if (result != null && result.block.siteOpened) {
      final site = result.block.siteAfter;
      if (site == null) {
        _zoomOut();
      } else {
        _celebrate(site);
      }
    } else if (result == null || result.spinAgain) {
      _recapBlock = result?.block;
      _showWheel();
    } else {
      _zoomOut();
    }
  }

  // ---- The construction loop: zoom onto a site, wheel above it ----------

  /// *Build!* on a site: make it the session's active site — every coin the
  /// coming blocks earn pays it down — tween the camera so the site sits at
  /// the bottom of the screen, then fade the wheel in above it.
  void _buildSite(CitySite site) {
    ref.read(activeSiteIdProvider.notifier).selected = site.id;
    setState(() {
      _mode = _CityMode.siteZoomed;
      _zoomedSite = site;
      _wheelVisible = false;
      _recapBlock = null;
      _movingId = null;
      _movingSiteId = null;
      _moveOrigin = null;
      _selectedBuildingId = null;
      _buyingBlock = null;
    });
    // The bottom bar swaps this frame; focus after layout so the viewport
    // the framing uses is the one the wheel will share.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _game == null) return;
      final (col, row, w, h) = _footprintOf(site.goal);
      _game!.focusOnFootprint(
        col: col - _window!.minCol,
        row: row - _window!.minRow,
        width: w,
        height: h,
        anchorY: 0.82,
        widthFraction: 0.42,
        onDone: () {
          if (mounted && _mode == _CityMode.siteZoomed) _showWheel();
        },
      );
    });
  }

  /// World anchor + tile size of a goal: a building's footprint, or a land
  /// block's 4×4.
  (int, int, int, int) _footprintOf(SiteGoal goal) => switch (goal) {
    BuildingGoal(:final col, :final row, :final type) => (
      col,
      row,
      type.footprint.$1,
      type.footprint.$2,
    ),
    LandBlockGoal(:final blockX, :final blockY) => (
      blockX * kBlockSize,
      blockY * kBlockSize,
      kBlockSize,
      kBlockSize,
    ),
    EventGoal(:final footprint) => (
      footprint.col,
      footprint.row,
      footprint.width,
      footprint.height,
    ),
  };

  void _showWheel() => setState(() {
    _wheelGeneration++;
    _wheelVisible = true;
  });

  /// The wheel landed: hide it and push the question route over the zoomed
  /// city. The chain's exit comes back through [didPopNext].
  void _startBlock(
    String conceptId,
    ProficiencyBand band,
    QuestionBlock block,
  ) {
    setState(() => _wheelVisible = false);
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              QuestionScreen(conceptId: conceptId, band: band, block: block),
        ),
      ),
    );
  }

  /// Back from a zoomed state: hide whatever is over the city and tween
  /// the camera back to where it was.
  void _zoomOut() {
    ref.read(activeSiteIdProvider.notifier).selected = null;
    setState(() {
      _wheelVisible = false;
      _celebratingSite = null;
    });
    _game?.releaseFocus(
      onDone: () {
        if (!mounted) return;
        setState(() {
          _mode = _CityMode.browsing;
          _zoomedSite = null;
        });
      },
    );
  }

  /// A site just opened (a block filled it, or credit did): card and
  /// confetti go up at once, and the camera glides onto the finished
  /// building underneath them, framed in the map area the card leaves free.
  /// *Done* zooms back out. Works from the zoomed loop and from browsing.
  void _celebrate(ConstructionSite site) {
    ref.read(activeSiteIdProvider.notifier).selected = null;
    setState(() {
      _mode = _CityMode.celebrating;
      _wheelVisible = false;
      _selectedSiteId = null;
      _celebratingSite = site;
    });
    // Measure the card after it has laid out, then frame around it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _game == null) return;
      final (col, row, w, h) = _footprintOf(site.goal);
      _game!.focusOnFootprint(
        col: col - _window!.minCol,
        row: row - _window!.minRow,
        width: w,
        height: h,
        anchorY: _celebrationAnchorY(),
        widthFraction: 0.7,
      );
    });
  }

  /// Viewport fraction that centres a footprint in the map area below the
  /// celebration card: halfway between the card's bottom edge and the
  /// bottom of the board, nudged down a little because a building's body
  /// rises above the ground point the camera targets.
  double _celebrationAnchorY() {
    final card =
        _celebrationCardKey.currentContext?.findRenderObject() as RenderBox?;
    final board = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (card == null || board == null || !card.hasSize || !board.hasSize) {
      return 0.6;
    }
    final boardTop = board.localToGlobal(Offset.zero).dy;
    final cardBottom =
        card.localToGlobal(Offset(0, card.size.height)).dy - boardTop;
    // Fractions of the height above the bottom bar, which is what the
    // game's framing treats as the screen.
    final visible = board.size.height - _barHeight;
    final free = (cardBottom / visible).clamp(0.0, 0.8);
    return (free + (1 - free) / 2 + 0.05).clamp(0.5, 0.9);
  }

  String _celebrationTitle(ConstructionSite site) => switch (site.goal) {
    BuildingGoal(:final type) => '${type.name} is finished!',
    LandBlockGoal() => 'The new land is yours!',
    EventGoal() => 'The block party is on!',
  };

  /// True (after toasting which sites are open) when no new site can start
  /// — checked at the moment of picking, so the player never chooses a
  /// location for something that would be refused on *Place here*.
  bool _atSiteCap(List<CitySite> sites) {
    if (sites.length < kMaxOpenSites) return false;
    _toast(_rejectionMessage(SiteStartRejection.tooManyOpenSites, sites));
    return true;
  }

  /// Cancel on the site bar. A site nobody has paid into just goes; one
  /// with coins in it asks first, then refunds every coin as credit.
  Future<void> _cancelSite(CitySite site) async {
    final paid = site.site.paidCoins;
    if (paid > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final palette = Theme.of(ctx).extension<AppPalette>()!;
          return AlertDialog(
            title: Text('Cancel ${site.name}?'),
            content: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Get '),
                  coinSpan(),
                  TextSpan(text: ' $paid back to use anywhere else.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep building'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.errorRedDeep,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancel site'),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !mounted) return;
    }
    final refund = await ref.read(cityActionsProvider).cancelSite(site.id);
    if (!mounted || refund == null) return;
    setState(() => _selectedSiteId = null);
    _toast(
      refund > 0
          ? '${site.name} cancelled — $refund coins back as credit'
          : '${site.name} cancelled',
    );
  }

  /// Use credit on the site bar: pays what the site still needs (or all
  /// the credit, if that's less). Filling the bar opens the site and
  /// celebrates like a block would.
  Future<void> _useCredit(CitySite site) async {
    final result = await ref.read(cityActionsProvider).applyCredit(site.id);
    if (!mounted || result == null) return;
    if (result.opened) _celebrate(result.site);
  }

  /// *Place here* on the move bar (or a tap on the moved building itself):
  /// every tile tap already moved it, so this just ends the mode.
  void _dropMoved() {
    // A building that ended up somewhere else counts as moved (chapter
    // one's move step listens for the home).
    final id = _movingId;
    final origin = _moveOrigin;
    if (id != null && origin != null) {
      final moved = ref
          .read(placementsProvider)
          .asData
          ?.value
          .where((p) => p.id == id)
          .firstOrNull;
      if (moved != null && (moved.gridX, moved.gridY) != origin) {
        unawaited(ref.read(cityActionsProvider).noteBuildingMoved(id));
      }
    }
    setState(() {
      _movingId = null;
      _movingSiteId = null;
      _moveOrigin = null;
    });
  }

  /// X on the move bar: put the building or site back where it was picked
  /// up, then end the mode.
  void _cancelMove() {
    final origin = _moveOrigin;
    final actions = ref.read(cityActionsProvider);
    if (origin != null) {
      if (_movingId case final id?) {
        unawaited(actions.moveBuilding(id, origin.$1, origin.$2));
      } else if (_movingSiteId case final id?) {
        unawaited(actions.moveSite(id, origin.$1, origin.$2));
      }
    }
    _dropMoved();
  }

  void _selectSite(int? siteId) => setState(() {
    _selectedSiteId = siteId;
    _selectedBuildingId = null;
    _movingId = null;
    _movingSiteId = null;
    _moveOrigin = null;
    _buyingBlock = null;
    _pendingSpot = null;
  });

  /// The building site whose footprint covers tile `(col, row)`, or null.
  CitySite? _siteAt(List<CitySite> sites, int col, int row) {
    for (final s in sites) {
      switch (s.goal) {
        case BuildingGoal(:final footprint) || EventGoal(:final footprint):
          if (footprint.tiles().contains((col, row))) return s;
        case LandBlockGoal():
          break;
      }
    }
    return null;
  }

  /// The placement whose footprint covers tile `(col, row)`, or null if that
  /// tile is free. Walks the real footprint (not just the anchor tile) so a tap
  /// anywhere on a multi-tile building selects it.
  BuildingPlacement? _buildingAt(
    List<BuildingPlacement> placements,
    int col,
    int row,
  ) {
    for (final p in placements) {
      final t = findBuildingTypeById(p.buildingTypeId);
      if (t == null) continue;
      final (w, h) = t.footprint;
      if (col >= p.gridX &&
          col < p.gridX + w &&
          row >= p.gridY &&
          row < p.gridY + h) {
        return p;
      }
    }
    return null;
  }

  /// Repositions the picked-up placement so its footprint covers `(col, row)`,
  /// auto-sliding the anchor as needed. Free (no coins). Stays selected so the
  /// player can keep nudging it.
  void _tryMove(
    int placementId,
    int col,
    int row,
    List<BuildingPlacement> placements,
    List<CitySite> sites,
    Set<(int, int)> ownedTiles,
  ) {
    final picked = placements.where((p) => p.id == placementId).firstOrNull;
    final type = picked == null
        ? null
        : findBuildingTypeById(picked.buildingTypeId);
    if (picked == null || type == null) {
      setState(() => _movingId = null);
      return;
    }
    final spot = _resolve(
      type,
      col,
      row,
      placements,
      sites,
      ownedTiles,
      exclude: picked.id,
    );
    if (spot == null) {
      _toast('No room for ${type.name} there');
      return;
    }
    unawaited(
      ref.read(cityActionsProvider).moveBuilding(picked.id, spot.col, spot.row),
    );
  }

  /// Repositions the picked-up building site so its footprint covers
  /// `(col, row)`. Its paid-in coins come along; it stays picked up.
  void _tryMoveSite(
    int siteId,
    int col,
    int row,
    List<BuildingPlacement> placements,
    List<CitySite> sites,
    Set<(int, int)> ownedTiles,
  ) {
    final picked = sites.where((s) => s.id == siteId).firstOrNull;
    if (picked == null || picked.goal is! BuildingGoal) {
      setState(() => _movingSiteId = null);
      return;
    }
    final type = (picked.goal as BuildingGoal).type;
    final spot = _resolve(
      type,
      col,
      row,
      placements,
      sites,
      ownedTiles,
      excludeSite: siteId,
    );
    if (spot == null) {
      _toast('No room for ${type.name} there');
      return;
    }
    unawaited(
      ref.read(cityActionsProvider).moveSite(siteId, spot.col, spot.row),
    );
  }

  /// Proposes a spot for [type] so its footprint covers `(col, row)`
  /// (auto-sliding the anchor): the board shows the building there, yellow
  /// like a picked-up one, with the roads it would get, and the bar offers
  /// *Place here* — [_confirmPlacement] then starts the site. For unique
  /// types that already exist, moves the existing instance instead.
  void _tryPlace(
    BuildingType type,
    int col,
    int row,
    List<BuildingPlacement> placements,
    List<CitySite> sites,
    Set<(int, int)> ownedTiles,
  ) {
    // Unique types (mayor's office): relocate the existing instance rather than
    // stacking a duplicate.
    if (type.unique) {
      final existing = placements
          .where((p) => p.buildingTypeId == type.id)
          .firstOrNull;
      if (existing != null) {
        setState(() => _movingId = existing.id);
        _tryMove(existing.id, col, row, placements, sites, ownedTiles);
        return;
      }
    }

    final spot = _resolve(type, col, row, placements, sites, ownedTiles);
    if (spot == null) {
      _toast('No room for ${type.name} there');
      _flashRejected(type, col, row);
      return;
    }
    setState(() {
      _pendingSpot = spot;
      _movingId = null;
      _movingSiteId = null;
      _moveOrigin = null;
      _selectedSiteId = null;
      _selectedBuildingId = null;
    });
  }

  /// *Place here*: starts a construction site at the proposed spot — no
  /// coins change hands; a free type (the mayor's office) opens on the spot.
  /// On success the new site (or placed building) is left selected so the
  /// player can still nudge it and, for a site, tap *Build!*.
  void _confirmPlacement() {
    final spot = _pendingSpot;
    final type = _selected;
    if (spot == null || type == null) return;
    final source = _growSource;
    final sourceType = source == null
        ? null
        : findBuildingTypeById(source.buildingTypeId);
    setState(() {
      _pendingSpot = null;
      _selected = null;
      _growSource = null;
    });
    unawaited(
      ref.read(cityActionsProvider).markHintSeen(GuideHint.placeHere),
    );
    unawaited(
      _startSite(
        BuildingGoal(
          type: type,
          col: spot.col,
          row: spot.row,
          upgrade: source == null || sourceType == null
              ? null
              : UpgradeLink(
                  sourcePlacementId: source.id,
                  sourceType: sourceType,
                ),
        ),
      ),
    );
  }

  /// Starts a site for [goal] via the city actions and reflects the outcome:
  /// selects the new site (or opens the placed building's card, for a free
  /// goal), or
  /// toasts why it was refused — a fourth site names the three open ones.
  Future<void> _startSite(SiteGoal goal) async {
    final result = await ref.read(cityActionsProvider).startSite(goal);
    if (!mounted) return;
    if (result.rejection case final rejection?) {
      _toast(_rejectionMessage(rejection, result.openSites));
      return;
    }
    setState(() {
      _buyingBlock = null;
      _selectedBuildingId = result.placementId;
      _selectedSiteId = result.siteId;
    });
    // Chapter one: placing it zooms and opens the wheel without a further
    // tap (city_builder.md §10.4).
    final siteId = result.siteId;
    if (siteId != null && _chapterOne) {
      final sites = await ref.read(sitesProvider.future);
      final site = sites.where((s) => s.id == siteId).firstOrNull;
      if (site != null && mounted) _buildSite(site);
    }
  }

  String _rejectionMessage(SiteStartRejection rejection, List<CitySite> open) =>
      switch (rejection) {
        SiteStartRejection.tooManyOpenSites =>
          'Finish one of your $kMaxOpenSites sites first: '
              '${open.map((s) => s.name).join(', ')}',
        SiteStartRejection.sourceAlreadyUpgrading =>
          'That building is already being upgraded',
        SiteStartRejection.notAnUpgradeStep => 'That upgrade is not available',
        SiteStartRejection.blockNotPurchasable =>
          'New land has to touch land you own',
        SiteStartRejection.blockAlreadyStarted =>
          'You are already building on that land',
        SiteStartRejection.eventAlreadyOpen => 'One party at a time!',
        SiteStartRejection.venueNotPublic => 'A party needs a park or a plaza',
      };

  /// Maps placements *and building sites* to grid footprints — a site
  /// occupies its tiles from the moment it is placed. Pass [exclude] /
  /// [excludeSite] to drop the one being moved, so its old tiles don't count
  /// as occupied.
  List<GridFootprint> _footprintsOf(
    List<BuildingPlacement> placements,
    List<CitySite> sites, {
    int? exclude,
    int? excludeSite,
  }) {
    final out = <GridFootprint>[];
    for (final p in placements) {
      if (p.id == exclude) continue;
      final t = findBuildingTypeById(p.buildingTypeId);
      if (t == null) continue;
      out.add(
        GridFootprint(
          col: p.gridX,
          row: p.gridY,
          width: t.footprint.$1,
          height: t.footprint.$2,
        ),
      );
    }
    for (final s in sites) {
      if (s.id == excludeSite) continue;
      if (s.goal case BuildingGoal(:final footprint)) out.add(footprint);
    }
    return out;
  }

  /// Auto-fits [type]'s footprint to cover the tapped `(col, row)`, sliding the
  /// anchor as needed (see `resolvePlacement`). Returns null when the tapped
  /// tile is taken or there's no legal spot. Pass [exclude] when moving so the
  /// moved building's own tiles don't count as occupied.
  GridFootprint? _resolve(
    BuildingType type,
    int col,
    int row,
    List<BuildingPlacement> placements,
    List<CitySite> sites,
    Set<(int, int)> ownedTiles, {
    int? exclude,
    int? excludeSite,
  }) {
    return resolvePlacement(
      ownedTiles: ownedTiles,
      existing: _footprintsOf(
        placements,
        sites,
        exclude: exclude,
        excludeSite: excludeSite,
      ),
      width: type.footprint.$1,
      height: type.footprint.$2,
      tapCol: col,
      tapRow: row,
    );
  }

  /// The auto-generated road tiles for the current placements, confined to
  /// [ownedTiles] (see `road_network.dart`). A proposed placement counts
  /// too, so the player sees the roads it would get before confirming.
  Set<(int, int)> _roadTilesFor(
    List<BuildingPlacement> placements,
    List<CitySite> sites,
    Set<(int, int)> ownedTiles,
  ) => generateRoads(
    ownedTiles: ownedTiles,
    buildings: [
      ..._footprintsOf(placements, sites),
      ?_pendingSpot,
    ],
  );

  /// Recomputes the render window over owned land + its pale frontier and feeds
  /// it to the game. On first call constructs the game; afterwards grows the
  /// window in place, compensating the camera so a land purchase doesn't jump
  /// the view (see `IsoCityGame.updateLand`). Sets [_window].
  void _syncLand(Set<(int, int)> ownedBlocks, Set<(int, int)> ownedTiles) {
    final buyableTiles = ownedTilesOf(purchasableBlocks(ownedBlocks));
    final window = computeLandWindow({...ownedTiles, ...buyableTiles}, _window);
    final grid = IsoGrid(cols: window.cols, rows: window.rows);
    final ownedLocal = _localTilesIn(ownedTiles, window);
    final buyableLocal = _localTilesIn(buyableTiles, window);

    if (_game == null) {
      _game = IsoCityGame(grid: grid, onTileTapped: _onTileTapped)
        // The catalog bar is up for the first fit, before it has been
        // measured: seed its height so the fit centres above it.
        ..bottomInset = _barHeight > 0
            ? _barHeight
            : _kCatalogBarHeight + MediaQuery.paddingOf(context).bottom;
      _game!.updateLand(
        newGrid: grid,
        ownedLocalTiles: ownedLocal,
        buyableLocalTiles: buyableLocal,
        cameraOffsetDeltaPx: Vector2.zero(),
      );
    } else {
      final delta = window.sameAs(_window!)
          ? Vector2.zero()
          : _cameraDelta(_game!.grid, _window!, grid, window);
      _game!.updateLand(
        newGrid: grid,
        ownedLocalTiles: ownedLocal,
        buyableLocalTiles: buyableLocal,
        cameraOffsetDeltaPx: delta,
      );
    }
    _window = window;
  }

  /// Screen-space shift of a fixed world tile between the old and new windows,
  /// to add to the viewfinder so content stays put when the window grows. World
  /// tile (0,0) is always owned, so it's present in both windows.
  Vector2 _cameraDelta(
    IsoGrid oldGrid,
    LandWindow oldWindow,
    IsoGrid newGrid,
    LandWindow newWindow,
  ) {
    final (ox, oy) = oldGrid.centerOf(-oldWindow.minCol, -oldWindow.minRow);
    final (nx, ny) = newGrid.centerOf(-newWindow.minCol, -newWindow.minRow);
    return Vector2(nx - ox, ny - oy);
  }

  /// World tiles → current window-local tiles (subtract the window origin).
  Set<(int, int)> _localTiles(Set<(int, int)> world) =>
      _localTilesIn(world, _window!);

  Set<(int, int)> _localTilesIn(Set<(int, int)> world, LandWindow window) => {
    for (final (c, r) in world) (c - window.minCol, r - window.minRow),
  };

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  void _openDebugSheet() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        // Cap the height so a scrim band stays tappable above the sheet (and
        // the drag handle keeps working to dismiss) — a scroll-controlled
        // sheet otherwise grows to ~full height with no way back to the city.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        builder: (_) => _CityDebugSheet(
          siteId: _selectedSiteId,
          onReset: () => setState(() {
            _selected = null;
            _pendingSpot = null;
            _movingId = null;
            _movingSiteId = null;
            _moveOrigin = null;
            _selectedSiteId = null;
            _selectedBuildingId = null;
          }),
        ),
      ),
    );
  }

  /// Confirms the pending land selection: starts a land site on that block
  /// (paid down by playing, like any site). Reached from the bar's Start
  /// button and from a second tap on the selected block.
  void _startSelectedLandSite() {
    final block = _buyingBlock;
    if (block == null) return;
    unawaited(_startSite(LandBlockGoal(blockX: block.$1, blockY: block.$2)));
  }

  List<PlacedBuildingView> _viewsFor(
    List<BuildingPlacement> placements,
    List<CitySite> sites,
    LandWindow window,
  ) {
    // Round-robin variant assignment: order each building type's placements by
    // id (insertion order) and cycle through its sprite variants, so adjacent
    // buildings of the same type don't repeat. Keyed by id (not tile), so a
    // moved building keeps its variant and a new one advances the cycle.
    final idsByType = <String, List<int>>{};
    for (final p in placements) {
      (idsByType[p.buildingTypeId] ??= <int>[]).add(p.id);
    }
    final slotById = <int, int>{};
    for (final ids in idsByType.values) {
      ids.sort();
      for (var i = 0; i < ids.length; i++) {
        slotById[ids[i]] = i;
      }
    }

    final out = <PlacedBuildingView>[];
    for (final p in placements) {
      final type = findBuildingTypeById(p.buildingTypeId);
      if (type == null) continue;
      out.add(
        PlacedBuildingView(
          col: p.gridX - window.minCol,
          row: p.gridY - window.minRow,
          emoji: type.emoji,
          color: _colorFor(type),
          footprint: type.footprint,
          assetPath: _assetPathFor(type, slotById[p.id] ?? 0),
          selected:
              p.id == _movingId ||
              p.id == _selectedBuildingId ||
              (_growTarget != null &&
                  _growCandidates.isNotEmpty &&
                  p.id == _growCandidates[_growIndex].id),
        ),
      );
    }
    // Building sites render on the same layer, at their construction stage.
    // A site's ghost (stage 2) shows the type's first sprite variant.
    for (final s in sites) {
      if (s.goal case EventGoal(:final venueType, :final col, :final row)) {
        out.add(
          PlacedBuildingView(
            col: col - window.minCol,
            row: row - window.minRow,
            emoji: '🎈',
            color: _colorFor(venueType),
            footprint: venueType.footprint,
            selected: s.id == _selectedSiteId,
            party: true,
          ),
        );
      }
      if (s.goal case BuildingGoal(:final type, :final col, :final row)) {
        out.add(
          PlacedBuildingView(
            col: col - window.minCol,
            row: row - window.minRow,
            emoji: type.emoji,
            color: _colorFor(type),
            footprint: type.footprint,
            assetPath: _assetPathFor(type, 0),
            selected: s.id == _selectedSiteId || s.id == _movingSiteId,
            stage: s.site.stage,
          ),
        );
      }
    }
    // The proposed spot for the catalog pick: the building itself, yellow
    // like a picked-up one, until *Place here* turns it into a site.
    if (_pendingSpot case final spot?) {
      if (_selected case final type?) {
        out.add(
          PlacedBuildingView(
            col: spot.col - window.minCol,
            row: spot.row - window.minRow,
            emoji: type.emoji,
            color: _colorFor(type),
            footprint: type.footprint,
            assetPath: _assetPathFor(type, 0),
            selected: true,
          ),
        );
      }
    }
    return out;
  }

  /// Window-local tiles of every land site, and of the selected one.
  (Set<(int, int)>, Set<(int, int)>) _landSiteTiles(List<CitySite> sites) {
    final all = <(int, int)>{};
    final selected = <(int, int)>{};
    for (final s in sites) {
      if (s.goal case LandBlockGoal(:final blockX, :final blockY)) {
        final tiles = _localTiles(tilesOfBlock(blockX, blockY).toSet());
        all.addAll(tiles);
        if (s.id == _selectedSiteId) selected.addAll(tiles);
      }
    }
    return (all, selected);
  }

  /// `<id>_v<n>.png` for the round-robin [slot] (a building's 0-based index
  /// among placements of its type), or null if the type has no sprite art yet
  /// (renders the Phase-7 box placeholder). Cycling by placement order keeps
  /// adjacent same-type buildings varied, until `BuildingPlacement
  /// .assetVariantIndex` makes the choice explicit (see plan.md Phase 9).
  String? _assetPathFor(BuildingType type, int slot) {
    if (type.numVariants <= 0) return null;
    final variant = slot % type.numVariants + 1;
    return '${type.id}_v$variant.png';
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(activePlayerProvider);
    final cityAsync = ref.watch(activeCityProvider);
    final placementsAsync = ref.watch(placementsProvider);
    final ownedBlocksAsync = ref.watch(ownedBlocksProvider);
    final catalogAsync = ref.watch(cityCatalogProvider);
    // .value so a per-answer refresh keeps the last known sites on the board
    // instead of blinking them out for a frame.
    final sites = ref.watch(sitesProvider).value ?? const <CitySite>[];

    final player = playerAsync.asData?.value;

    // Build the game once the owned land is known, then keep its render model
    // in sync. Buying land grows the window in place (no rebuild) so the camera
    // survives a purchase — see `_syncLand`.
    final city = cityAsync.asData?.value;
    final ownedBlocks = ownedBlocksAsync.asData?.value;
    final ownedTiles = ownedBlocks == null
        ? const <(int, int)>{}
        : ownedTilesOf(ownedBlocks);
    if (ownedBlocks != null) _syncLand(ownedBlocks, ownedTiles);

    // Drop a stale land selection (already bought, or gone after a reset), then
    // feed the highlight tiles to the board.
    final buyingBlock = _buyingBlock;
    if (buyingBlock != null &&
        ownedBlocks != null &&
        !purchasableBlocks(ownedBlocks).contains(buyingBlock)) {
      _buyingBlock = null;
    }
    if (_game != null) {
      final selected = _buyingBlock;
      _game!.setBuyingTiles(
        selected == null
            ? const {}
            : _localTiles(tilesOfBlock(selected.$1, selected.$2).toSet()),
      );
    }

    final placements = placementsAsync.asData?.value;
    // Drop a stale selection (e.g. the building was removed by a reset) so the
    // Done bar doesn't linger over nothing.
    if (placements != null) {
      if (_movingId != null && !placements.any((p) => p.id == _movingId)) {
        _movingId = null;
      }
      if (_selectedBuildingId != null &&
          !placements.any((p) => p.id == _selectedBuildingId)) {
        _selectedBuildingId = null;
      }
    }
    // Drop a stale site selection (it opened, or a reset cleared it).
    if (_selectedSiteId != null && !sites.any((s) => s.id == _selectedSiteId)) {
      _selectedSiteId = null;
    }
    if (_movingSiteId != null && !sites.any((s) => s.id == _movingSiteId)) {
      _movingSiteId = null;
    }
    if (_game != null && placements != null) {
      _game!.setBuildings(_viewsFor(placements, sites, _window!));
      _game!.setRoads(
        _localTiles(_roadTilesFor(placements, sites, ownedTiles)),
      );
      _game!.setStreetLife(
        population: city?.population ?? 0,
        buildingIds: [for (final p in placements) p.buildingTypeId],
      );
      final (allSiteTiles, selectedSiteTiles) = _landSiteTiles(sites);
      _game!.setLandSiteTiles(all: allSiteTiles, selected: selectedSiteTiles);
    }
    final selectedSite = _selectedSiteId == null
        ? null
        : sites.where((s) => s.id == _selectedSiteId).firstOrNull;
    final movingSite = _movingSiteId == null
        ? null
        : sites.where((s) => s.id == _movingSiteId).firstOrNull;
    // The building currently picked up for repositioning, if any — drives the
    // move bar's label.
    final moving = _movingId == null
        ? null
        : placements?.where((p) => p.id == _movingId).firstOrNull;
    final movingType = moving == null
        ? null
        : findBuildingTypeById(moving.buildingTypeId);
    // The building whose info card is open, if any.
    final selectedBuilding = _selectedBuildingId == null
        ? null
        : placements?.where((p) => p.id == _selectedBuildingId).firstOrNull;
    final selectedBuildingType = selectedBuilding == null
        ? null
        : findBuildingTypeById(selectedBuilding.buildingTypeId);

    // .value (not asData?.value) so a refresh — which the catalog does on
    // every placement — keeps the *previous* catalog instead of momentarily
    // dropping to null. Otherwise the bottom bar collapses for a frame, which
    // resizes the Flame viewport and makes the camera jump (see bottomNavBar).
    final catalog = catalogAsync.value;
    // Cards that arrived since the bar was last looked at sparkle.
    if (catalog != null) {
      _seenCardIds ??= catalog.map((b) => b.id).toSet();
    }
    final newCardIds = <String>{
      if (catalog != null && _seenCardIds != null)
        for (final b in catalog)
          if (!_seenCardIds!.contains(b.id)) b.id,
    };

    final zoomed = _mode != _CityMode.browsing;
    // The zoomed site as it stands now (its bar keeps filling between
    // blocks), falling back to the snapshot taken at Build!.
    final liveZoomed = _zoomedSite == null
        ? null
        : sites.where((s) => s.id == _zoomedSite!.id).firstOrNull ??
              _zoomedSite;
    final celebratingSite = _celebratingSite;
    final credit = player?.creditBalance ?? 0;
    // A selected site that has since opened (or was cancelled) is no
    // selection: drop the stale id so the city counts as at rest.
    if (_selectedSiteId != null && selectedSite == null) _selectedSiteId = null;

    // Letters (city_builder.md §10.2). A fired beat whose letter hasn't been
    // shown interrupts when the city is at rest; a shown one stays open on
    // its badged catalog card, from which it can be re-opened. Fulfilled
    // beats retire quietly (their thank-you reply is step 4).
    final openBeats =
        ref.watch(openBeatsProvider).asData?.value ?? const <OpenBeat>[];
    _retiring.removeWhere(
      (id) => !openBeats.any((b) => b.completed && b.beat.id == id),
    );
    for (final b in openBeats) {
      if (b.completed && _retiring.add(b.beat.id)) {
        unawaited(ref.read(cityActionsProvider).retireCompletedBeat(b.beat.id));
      }
    }
    // Ambient praise rides on a walker near the building it is about, then
    // the beat retires at once — nothing to dismiss (city_builder.md §10.2).
    _bubbled.removeWhere((id) => !openBeats.any((b) => b.beat.id == id));
    for (final b in openBeats) {
      if (b.delivery != BeatDelivery.bubble || b.completed) continue;
      if (!_bubbled.add(b.beat.id)) continue;
      final target = beatTargetBuilding(b.beat);
      final at = target == null
          ? null
          : placements?.where((p) => p.buildingTypeId == target.id).firstOrNull;
      final window = _window;
      if (at != null && window != null) {
        _game?.showBubble(
          localCol: at.gridX - window.minCol,
          localRow: at.gridY - window.minRow,
          text: '${b.beat.emoji} ${b.beat.shortLabel}',
        );
      }
      unawaited(ref.read(cityActionsProvider).retireCompletedBeat(b.beat.id));
    }
    final requested = <String, OpenBeat>{};
    final eventAsks = <OpenBeat>[];
    for (final b in openBeats) {
      if (b.completed || b.beat.kind != BeatKind.demand) continue;
      // Asks that are not "build X" — a party, or chapter one's "move
      // your house" — get a card of their own rather than a building's.
      if (b.beat.event != null || b.beat.scripted) {
        eventAsks.add(b);
        continue;
      }
      final target = beatTargetBuilding(b.beat);
      if (target != null) requested.putIfAbsent(target.id, () => b);
    }
    final atRest =
        !zoomed &&
        _selected == null &&
        _movingId == null &&
        _movingSiteId == null &&
        _selectedSiteId == null &&
        _selectedBuildingId == null &&
        _growTarget == null &&
        _buyingBlock == null;
    if (_letterId == null && atRest) {
      final next = openBeats
          .where(
            (b) =>
                !b.shown && !b.completed && b.delivery != BeatDelivery.bubble,
          )
          .firstOrNull;
      if (next == null) {
        _cancelLetterDelay();
      } else if (_letterArmed == next.beat.id) {
        _letterId = next.beat.id;
        _letterArmed = null;
      } else if (_letterPending != next.beat.id) {
        _cancelLetterDelay();
        _letterPending = next.beat.id;
        _letterDelay = Timer(kLetterDelay, () {
          if (!mounted) return;
          setState(() {
            _letterArmed = _letterPending;
            _letterDelay = null;
          });
        });
      }
    } else {
      _cancelLetterDelay();
    }
    final letterBeat = _letterId == null ? null : findBeatById(_letterId!);
    final letterIsTimes = letterBeat?.staticDelivery == BeatDelivery.times;

    // The thank-you reply for the building that just opened rides on the
    // celebration card itself rather than interrupting afterwards.
    final celebrationReply = celebratingSite == null
        ? null
        : openBeats.where((b) {
            if (b.shown || b.completed) return false;
            if (b.beat.kind != BeatKind.praise) return false;
            if (b.delivery != BeatDelivery.letter) return false;
            return switch (celebratingSite.goal) {
              BuildingGoal(:final type) =>
                beatTargetBuilding(b.beat)?.id == type.id,
              EventGoal(:final eventId) => b.beat.event == eventId,
              LandBlockGoal() => false,
            };
          }).firstOrNull;
    if (celebrationReply != null &&
        _announcedLetterId != celebrationReply.beat.id) {
      _announcedLetterId = celebrationReply.beat.id;
      final spoken =
          'Dear Mayor ${player?.name ?? ''}, ${celebrationReply.beat.longText}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(speakIfEnabled(ref, spoken));
      });
    }
    final letterTarget = letterBeat == null
        ? null
        : beatTargetBuilding(letterBeat);
    // A letter for a rung above a root grows an existing building
    // (city_builder.md §10.6): the oldest eligible one is named first.
    final letterGrowSources = letterTarget == null
        ? const <BuildingPlacement>[]
        : upgradeSourcesFor(letterTarget.id, placements ?? const [], sites);
    // An event letter starts its site at the town's public space.
    final letterVenue = letterBeat?.event == null
        ? null
        : partyVenueFor(placements ?? const []);
    final letterCanBuild =
        letterBeat?.kind == BeatKind.demand &&
        !(letterBeat!.scripted && letterBeat.event == null) &&
        ((letterBeat.event != null && letterVenue != null) ||
            (letterTarget != null &&
                (letterGrowSources.isNotEmpty ||
                    (catalog?.any((b) => b.id == letterTarget.id) ?? false))));
    final guideStep = player?.guideStep ?? kChapterOneDone;
    final chapterOne = guideStep < kChapterOneDone;
    final hints = player?.guideHints;
    final showPlaceHint = hints != null && !GuideHint.placeHere.seenIn(hints);
    _scheduleNudge(
      wanted:
          atRest &&
          letterBeat == null &&
          sites.isEmpty &&
          (requested.isNotEmpty || eventAsks.isNotEmpty),
    );
    if (letterBeat != null && _announcedLetterId != letterBeat.id) {
      _announcedLetterId = letterBeat.id;
      final spoken = letterIsTimes
          ? '${letterBeat.shortLabel}. ${letterBeat.longText}'
          : 'Dear Mayor ${player?.name ?? ''}, ${letterBeat.longText}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(ref.read(cityActionsProvider).markBeatRead(letterBeat.id));
        unawaited(speakIfEnabled(ref, spoken));
      });
    }

    // While zoomed the bar is pinned to the site; otherwise: land selected
    // → start-a-site bar; site selected → its bar; something picked up →
    // move bar; building tapped → its info card; catalog pick → choose /
    // confirm a location; else the catalog.
    final bar = zoomed
        ? _ZoomedBar(
            name: celebratingSite != null
                ? _celebrationTitle(celebratingSite)
                : liveZoomed?.name ?? '',
            paid: celebratingSite?.paidCoins ?? liveZoomed?.site.paidCoins,
            price: celebratingSite?.price ?? liveZoomed?.site.price,
            onBack: _mode == _CityMode.celebrating ? null : _zoomOut,
          )
        : _buyingBlock != null
        ? _StartLandSiteBar(
            cost: blockCost(_buyingBlock!.$1, _buyingBlock!.$2),
            onStart: _startSelectedLandSite,
            onCancel: () => setState(() => _buyingBlock = null),
          )
        : selectedSite != null
        ? _SiteBar(
            site: selectedSite,
            credit: credit,
            onBuild: () => _buildSite(selectedSite),
            onCancel: () => unawaited(_cancelSite(selectedSite)),
            onUseCredit: () => unawaited(_useCredit(selectedSite)),
            onMove: selectedSite.goal is BuildingGoal
                ? () => setState(() {
                    final goal = selectedSite.goal as BuildingGoal;
                    _movingSiteId = selectedSite.id;
                    _moveOrigin = (goal.col, goal.row);
                    _selectedSiteId = null;
                  })
                : null,
            onDeselect: () => setState(() => _selectedSiteId = null),
          )
        : movingSite != null
        ? _MoveModeBar(
            name: movingSite.name,
            onPlace: _dropMoved,
            onCancel: _cancelMove,
          )
        : _movingId != null
        ? _MoveModeBar(
            name: movingType?.name,
            onPlace: _dropMoved,
            onCancel: _cancelMove,
          )
        : _growTarget != null && _growCandidates.isNotEmpty
        ? _GrowBar(
            target: _growTarget!,
            source: findBuildingTypeById(
              _growCandidates[_growIndex].buildingTypeId,
            )!,
            index: _growIndex,
            count: _growCandidates.length,
            onPrev: () => setState(
              () => _growIndex =
                  (_growIndex - 1 + _growCandidates.length) %
                  _growCandidates.length,
            ),
            onNext: () => setState(
              () => _growIndex = (_growIndex + 1) % _growCandidates.length,
            ),
            onCancel: _cancelGrow,
            onGrow: () =>
                _confirmGrow(placements ?? const [], sites, ownedTiles),
          )
        : selectedBuildingType != null
        ? _BuildingBar(
            type: selectedBuildingType,
            showMoveHint:
                guideStep == kMoveStep &&
                selectedBuildingType.id == 'single_home',
            // No upgrades until the guide is over: the letters carry it.
            growInto: chapterOne ? null : nextRung(selectedBuildingType.id),
            onGrow: () {
              final next = nextRung(selectedBuildingType.id);
              if (next == null) return;
              final sources = upgradeSourcesFor(
                next.id,
                placements ?? const [],
                sites,
              ).where((p) => p.id == selectedBuilding!.id).toList();
              if (sources.isEmpty) {
                _toast('That building is already being upgraded');
                return;
              }
              if (_atSiteCap(sites)) return;
              _enterGrow(next, sources);
            },
            onMove: () => setState(() {
              _movingId = _selectedBuildingId;
              _moveOrigin = (selectedBuilding!.gridX, selectedBuilding.gridY);
              _selectedBuildingId = null;
            }),
            onDeselect: () => setState(() => _selectedBuildingId = null),
          )
        // Render from the retained catalog so a per-placement refresh never
        // blanks the bar for a frame. Only the very first load — before
        // any data — is empty.
        : catalog == null
        ? const SizedBox.shrink()
        // A catalog pick walks through two bars: choose a location, then
        // confirm the proposed spot. X backs out to the catalog.
        : _selected != null && _pendingSpot != null
        ? _PlaceHereBar(
            type: _selected!,
            showHint: showPlaceHint,
            onPlace: _confirmPlacement,
            onCancel: () => setState(() {
              _pendingSpot = null;
              _selected = null;
            }),
          )
        : _selected != null
        ? _ChooseLocationBar(
            type: _selected!,
            onCancel: () => setState(() => _selected = null),
          )
        : _BuildBar(
            catalog: catalog,
            sites: sites,
            requested: requested,
            eventAsks: eventAsks,
            chapterOne: chapterOne,
            nudge: _nudge,
            openFolder: _openFolder,
            newCardIds: newCardIds,
            onOpenFolder: (c) => setState(() {
              _openFolder = c;
              if (c != null) {
                _seenCardIds?.addAll(
                  catalog.where((b) => b.category == c).map((b) => b.id),
                );
              }
            }),
            onSelectSite: (site) => setState(() => _selectedSiteId = site.id),
            onOpenLetter: (b) => setState(() {
              _letterId = b.beat.id;
              // Re-opened on purpose: read it out again.
              _announcedLetterId = null;
            }),
            onSelect: (b) {
              if (_atSiteCap(sites)) return;
              // A spot is proposed at once, like a letter's Build it!; a
              // tap on the map moves it.
              final spot = _proposeFor(
                b,
                placements ?? const [],
                sites,
                ownedTiles,
              );
              setState(() {
                _selected = b;
                _pendingSpot = spot;
              });
            },
          );

    // Measure the bar once it has laid out; a height change re-renders the
    // overlays that sit above it and tells the game how much it covers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _barKey.currentContext?.findRenderObject() as RenderBox?;
      final h = box != null && box.hasSize ? box.size.height : 0.0;
      if ((h - _barHeight).abs() < 0.5) return;
      _game?.bottomInset = h;
      setState(() => _barHeight = h);
    });

    return PopScope(
      // Back from a zoomed state zooms out; it never leaves the city.
      canPop: !zoomed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_game!.isTweening) _zoomOut();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdventurerAvatarWidget(
                config: player?.avatar ?? const AdventurerConfig(),
                size: 32,
              ),
              const SizedBox(width: 8),
              Text('${player?.name ?? ''}’s city'),
            ],
          ),
          // Credit from cancelled sites, only while there is any; the
          // parent-facing guide skip only while chapter one runs.
          actions: [
            if (credit > 0)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _CreditChip(amount: credit),
              ),
            if (chapterOne)
              PopupMenuButton<String>(
                onSelected: (_) =>
                    unawaited(ref.read(cityActionsProvider).skipGuide()),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'skip',
                    child: Text('Skip the guide (for grown-ups)'),
                  ),
                ],
              ),
          ],
        ),
        body: _game == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        key: _boardKey,
                        color: const Color(0xFF9CCC65),
                        child: _PinchZoomWrapper(
                          game: _game!,
                          child: GameWidget(game: _game!),
                        ),
                      ),
                    ),
                    // Population counter, top-left over the city.
                    if (!zoomed)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: SafeArea(
                          child: _PopulationChip(
                            population: city?.population ?? 0,
                          ),
                        ),
                      ),
                    // The front page on screen.
                    if (!zoomed && letterBeat != null && letterIsTimes)
                      Positioned.fill(
                        child: TimesOverlay(
                          beat: letterBeat,
                          cityName: '${player?.name ?? ''}’s city',
                          onClose: () {
                            unawaited(ref.read(ttsServiceProvider).stop());
                            setState(() => _letterId = null);
                          },
                        ),
                      ),
                    // The letter on screen, over everything but the wheel.
                    if (!zoomed && letterBeat != null && !letterIsTimes)
                      Positioned.fill(
                        child: LetterOverlay(
                          beat: letterBeat,
                          citizen: citizenForBeat(letterBeat),
                          playerName: player?.name ?? '',
                          target: letterTarget,
                          onBuild: letterCanBuild
                              ? () {
                                  if (_atSiteCap(sites)) return;
                                  if (letterBeat.event != null &&
                                      letterVenue != null) {
                                    unawaited(
                                      ref.read(ttsServiceProvider).stop(),
                                    );
                                    setState(() => _letterId = null);
                                    unawaited(
                                      _startEvent(
                                        letterBeat.event!,
                                        letterVenue,
                                      ),
                                    );
                                    return;
                                  }
                                  if (letterTarget == null) return;
                                  if (letterGrowSources.isNotEmpty) {
                                    _enterGrow(letterTarget, letterGrowSources);
                                    return;
                                  }
                                  unawaited(
                                    ref.read(ttsServiceProvider).stop(),
                                  );
                                  final spot = _proposeFor(
                                    letterTarget,
                                    placements ?? const [],
                                    sites,
                                    ownedTiles,
                                  );
                                  setState(() {
                                    _letterId = null;
                                    _selected = letterTarget;
                                    _pendingSpot = spot;
                                  });
                                }
                              : null,
                          onClose: () {
                            unawaited(ref.read(ttsServiceProvider).stop());
                            setState(() => _letterId = null);
                          },
                        ),
                      ),
                    // The wheel over the blurred city, above the site pinned at
                    // the bottom (of the area the bar leaves visible). Fades in
                    // once the camera has landed; stays in the tree (faded
                    // out) while a question route is on top.
                    if (_mode == _CityMode.siteZoomed)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height:
                            (constraints.maxHeight - _barHeight) *
                            (1 - kSpinOverlayBottomFraction),
                        child: IgnorePointer(
                          ignoring: !_wheelVisible,
                          child: AnimatedOpacity(
                            opacity: _wheelVisible ? 1 : 0,
                            duration: const Duration(milliseconds: 450),
                            child: _wheelVisible
                                ? SpinOverlay(
                                    key: ValueKey(_wheelGeneration),
                                    onBlockStart: _startBlock,
                                    recap: _recapBlock,
                                  )
                                : const SizedBox.expand(),
                          ),
                        ),
                      ),
                    if (celebratingSite != null)
                      Positioned.fill(
                        child: CelebrationOverlay(
                          title: _celebrationTitle(celebratingSite),
                          reply: celebrationReply?.beat,
                          replyFrom: celebrationReply == null
                              ? null
                              : citizenForBeat(celebrationReply.beat),
                          playerName: player?.name ?? '',
                          onDone: () {
                            unawaited(ref.read(ttsServiceProvider).stop());
                            if (celebrationReply != null) {
                              unawaited(
                                ref
                                    .read(cityActionsProvider)
                                    .markBeatRead(celebrationReply.beat.id),
                              );
                            }
                            _zoomOut();
                          },
                          cardKey: _celebrationCardKey,
                        ),
                      ),
                    // The wheel is reached through a site's Build! — there is
                    // no free-floating "play" entry (city_builder.md §8.3).
                    // Parked above the tallest bar so no bar ever covers it.
                    if (kDebugMode && !zoomed && letterBeat == null)
                      Positioned(
                        right: 16,
                        bottom: _kDebugFabBottom,
                        child: FloatingActionButton.small(
                          heroTag: 'cityDebugFab',
                          onPressed: _openDebugSheet,
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          child: const Icon(Icons.bug_report_rounded),
                        ),
                      ),
                    // The bottom bar, over the game rather than beside it.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SizedBox(key: _barKey, child: bar),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// How long a letter waits after the city comes to rest before it
/// interrupts (city_builder.md §10.3): a moment to take the city in.
const kLetterDelay = Duration(milliseconds: 2500);

/// Height of the catalog bar's content (its cards), used to seed the
/// game's bottom inset before the bar has been measured.
const double _kCatalogBarHeight = 120;

/// Where the debug FAB sits: clear of the tallest bottom bar.
const double _kDebugFabBottom = 176;

/// Share of the screen height, from the bottom, left clear for the zoomed
/// site under the wheel overlay. The camera anchors the site into it.
const double kSpinOverlayBottomFraction = 0.3;

/// Bottom strip while zoomed onto a site or a finished building: the site's
/// name and `paid / price`, plus a way back out.
class _ZoomedBar extends StatelessWidget {
  const _ZoomedBar({
    required this.name,
    required this.paid,
    required this.price,
    required this.onBack,
  });

  final String name;
  final int? paid;
  final int? price;

  /// Null while the celebration owns the exit (its Done button).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.construction_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: paid != null && price != null
                    ? SiteProgressBar(paid: paid!, price: price!, name: name)
                    : Text(name, style: theme.textTheme.titleSmall),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: onBack,
                icon: const Icon(Icons.zoom_out_map_rounded),
                label: const Text('City'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// kDebugMode-only control panel, shown in a bottom sheet from the city
/// screen's debug FAB. Lets a developer exercise the city mechanics
/// (placement, growth, beats) without grinding math for currency: pay coins
/// into a site, set the population directly, force-fire any beat, and reset
/// the city to a brand-new-player baseline.
/// Operates on the *real* active player so persistence is exercised too.
class _CityDebugSheet extends ConsumerStatefulWidget {
  const _CityDebugSheet({required this.onReset, this.siteId});

  /// Called after a successful reset so the parent screen can clear its
  /// pending building selection (which may no longer be available).
  final VoidCallback onReset;

  /// The site selected on the city screen, if any — the pay buttons target
  /// it (else the oldest open site).
  final int? siteId;

  @override
  ConsumerState<_CityDebugSheet> createState() => _CityDebugSheetState();
}

class _CityDebugSheetState extends ConsumerState<_CityDebugSheet> {
  // Local slider position; null until the user drags it, so we fall back to
  // the city's persisted population for the initial value.
  double? _pop;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
      );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset city?'),
        content: const Text(
          'Wipes all placements, sites, beats, and population, and zeroes '
          'lifetime coins and the streak. Cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    await ref.read(cityActionsProvider).debugResetCity();
    widget.onReset();
    if (mounted) {
      setState(() => _pop = 0);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'Debug sheet reached in a non-debug build');
    final theme = Theme.of(context);
    final actions = ref.read(cityActionsProvider);
    final player = ref.watch(activePlayerProvider).asData?.value;
    final city = ref.watch(activeCityProvider).asData?.value;
    final pop = (_pop ?? (city?.population ?? 0).toDouble()).clamp(0.0, 500.0);

    // Scrollable: the force-fire chip list grows with the beat registry
    // (48 chips and counting), far taller than any screen.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report_rounded),
                const SizedBox(width: 8),
                Text('City debug', style: theme.textTheme.titleMedium),
                const Spacer(),
                if (player != null)
                  Text(
                    'lifetime ${player.lifetimeCoinsEarned}',
                    style: theme.textTheme.labelMedium,
                  ),
              ],
            ),
            const Divider(height: 24),
            Text(
              widget.siteId == null
                  ? 'Pay into the oldest open site'
                  : 'Pay into the selected site',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (amount, label) in const [
                  (20, '+20'),
                  (60, '+60 (1 min)'),
                  (600, '+600 (10 min)'),
                  (3600, '+3600 (1 h)'),
                ])
                  FilledButton.tonal(
                    onPressed: () => unawaited(
                      actions.debugPayCoins(amount, siteId: widget.siteId),
                    ),
                    child: Text(label),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Population: ${pop.round()}',
              style: theme.textTheme.labelLarge,
            ),
            Slider(
              value: pop,
              max: 500,
              divisions: 100,
              label: pop.round().toString(),
              onChanged: (v) => setState(() => _pop = v),
              onChangeEnd: (v) =>
                  unawaited(actions.debugSetPopulation(v.round())),
            ),
            const SizedBox(height: 8),
            Text(
              'Round clock: ${player?.roundsPlayed ?? 0} '
              '(building age = clock − placed-at; new letters '
              '$kNewBeatSpacingRounds rounds apart)',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () {
                    unawaited(actions.debugAdvanceRounds(1));
                    _snack('+1 round');
                  },
                  child: const Text('+1 round'),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    unawaited(actions.debugAdvanceRounds(10));
                    _snack('+10 rounds');
                  },
                  child: const Text('+10 rounds'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Unlock all buildings'),
              subtitle: const Text(
                'Whole catalog, ignoring unlock rules. This session only.',
              ),
              value: ref.watch(debugUnlockAllProvider),
              onChanged: (v) {
                ref.read(debugUnlockAllProvider.notifier).set(on: v);
                _snack(v ? 'All buildings unlocked' : 'Unlock rules back on');
              },
            ),
            const SizedBox(height: 8),
            Text('Force-fire beat', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final beat in beatRegistry)
                  ActionChip(
                    avatar: Text(beat.emoji),
                    label: Text(beat.shortLabel),
                    onPressed: () {
                      unawaited(actions.debugFireBeat(beat.id));
                      _snack('Fired “${beat.shortLabel}”');
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                onPressed: () => unawaited(_confirmReset()),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset city (zero everything)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Current population, shown as a shaded chip over the top-left of the city.
/// The value is stepped by the growth model as the player builds and plays.
class _PopulationChip extends StatelessWidget {
  const _PopulationChip({required this.population});

  final int population;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👥', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 5),
          Text(
            '$population',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom strip for a tapped building — its info card: emoji, name, what it
/// does for the city, *Move* (picks it up; see [_MoveModeBar]) and X. The
/// place for upgrade options later (house → bigger house, park → zoo).
class _BuildingBar extends StatelessWidget {
  const _BuildingBar({
    required this.type,
    required this.onMove,
    required this.onDeselect,
    this.growInto,
    this.onGrow,
    this.showMoveHint = false,
  });

  final BuildingType type;
  final VoidCallback onMove;
  final VoidCallback onDeselect;

  /// The animated hand over *Move* during chapter one's move step.
  final bool showMoveHint;

  /// The rung this building can grow into, if any: shown as *Grow into …*
  /// at the delta price (city_builder.md §10.6).
  final BuildingType? growInto;
  final VoidCallback? onGrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pop = type.populationContribution;
    final growPrice = growInto == null
        ? 0
        : upgradeDeltaPrice(source: type, target: growInto!);
    final detail = pop > 0
        ? 'Room for $pop ${pop == 1 ? 'person' : 'people'}'
        : type.category.displayName;
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (growInto != null && onGrow != null) ...[
                      const SizedBox(height: 6),
                      FilledButton.tonalIcon(
                        onPressed: onGrow,
                        icon: const Icon(Icons.trending_up_rounded),
                        label: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Upgrade to a ${growInto!.name} · ',
                              ),
                              coinSpan(),
                              TextSpan(text: ' $growPrice'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onMove,
                    icon: const Icon(Icons.open_with_rounded),
                    label: const Text('Move'),
                  ),
                  if (showMoveHint)
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: -62,
                      child: Center(child: CoachHand(mode: CoachHandMode.tap)),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              _CloseButton(onPressed: onDeselect, tooltip: 'Close'),
            ],
          ),
        ),
      ),
    );
  }
}

/// The grow bar (city_builder.md §10.6): which building grows into the
/// rung a letter asked for. ◀ ▶ step through the candidates (the picked one
/// is tinted on the map; a tap on another candidate picks it too); *Yes,
/// grow it* proposes the bigger footprint.
class _GrowBar extends StatelessWidget {
  const _GrowBar({
    required this.target,
    required this.source,
    required this.index,
    required this.count,
    required this.onPrev,
    required this.onNext,
    required this.onCancel,
    required this.onGrow,
  });

  final BuildingType target;
  final BuildingType source;
  final int index;
  final int count;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onCancel;
  final VoidCallback onGrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = upgradeDeltaPrice(source: source, target: target);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: count > 1 ? onPrev : null,
                    tooltip: 'Previous',
                    icon: const Icon(Icons.chevron_left_rounded, size: 32),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade this one?',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${source.emoji} ${source.name}'),
                              TextSpan(text: ' · ${index + 1} of $count · '),
                              coinSpan(),
                              TextSpan(text: ' $price to a ${target.name}'),
                            ],
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: count > 1 ? onNext : null,
                    tooltip: 'Next',
                    icon: const Icon(Icons.chevron_right_rounded, size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Not now'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: onGrow,
                    child: const Text('Yes, upgrade it'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom strip shown while a building (or site) is picked up for
/// repositioning. Each tile tap moves it there at once; *Place here* keeps
/// it where it stands and X snaps it back to where it was picked up. The
/// layout mirrors the placement bar so the two flows read the same.
class _MoveModeBar extends StatelessWidget {
  const _MoveModeBar({
    required this.onPlace,
    required this.onCancel,
    this.name,
  });

  /// Name of the picked-up building.
  final String? name;
  final VoidCallback onPlace;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.open_with_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Moving ${name ?? 'building'}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _CloseButton(onPressed: onCancel, tooltip: 'Put it back'),
              const SizedBox(width: 4),
              FilledButton(onPressed: onPlace, child: const Text('Place here')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small round X used by the bottom bars to back out of a mode.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed, required this.tooltip});

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: const Icon(Icons.close_rounded),
  );
}

/// Bottom strip after a catalog pick: names the building and asks for a
/// tile. X drops the pick and brings the catalog back.
class _ChooseLocationBar extends StatelessWidget {
  const _ChooseLocationBar({required this.type, required this.onCancel});

  final BuildingType type;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Choose a location — tap a tile to place it',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CloseButton(onPressed: onCancel, tooltip: 'Cancel'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom strip while a spot is proposed for the catalog pick: the price
/// it will take to build there, *Place here* to start the site, X to drop
/// the pick. Tapping another free tile moves the proposal instead.
class _PlaceHereBar extends StatelessWidget {
  const _PlaceHereBar({
    required this.type,
    required this.onPlace,
    required this.onCancel,
    this.showHint = false,
  });

  final BuildingType type;
  final VoidCallback onPlace;
  final VoidCallback onCancel;

  /// The one-time animated hand over *Place here* (city_builder.md §10.4).
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and price on one line, the hint alone on the
                    // next so it never wraps mid-sentence.
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: type.name),
                          if (type.coinCost > 0) ...[
                            const TextSpan(text: '  '),
                            coinSpan(),
                            TextSpan(
                              text: ' ${type.coinCost}',
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tap the map to move it',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CloseButton(onPressed: onCancel, tooltip: 'Cancel'),
              const SizedBox(width: 4),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FilledButton(
                    onPressed: onPlace,
                    child: const Text('Place here'),
                  ),
                  if (showHint)
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: -62,
                      child: Center(child: CoachHand(mode: CoachHandMode.tap)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom strip shown while a frontier block is selected. Not a dialog on
/// purpose: the city stays visible and tappable, so the player can still
/// move the selection to a different spot before confirming. Starting the
/// land site costs nothing up front — the price is what the site is paid
/// down to by playing.
class _StartLandSiteBar extends StatelessWidget {
  const _StartLandSiteBar({
    required this.cost,
    required this.onStart,
    required this.onCancel,
  });

  final int cost;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.landscape_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Build out this land for '),
                      coinSpan(),
                      TextSpan(text: ' $cost?'),
                    ],
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
              const SizedBox(width: 4),
              FilledButton(onPressed: onStart, child: const Text('Start')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom strip for the selected construction site. Top row: its
/// `paid / price` bar and an X to deselect. Bottom row: red *Cancel*,
/// *Move* (building sites only),
/// (refunds every paid coin as credit), green *Use N* while the player
/// holds credit the site can take, and *Build!*, which makes it the active
/// site and opens the wheel. A building site can be nudged by tapping a
/// tile while it is selected.
class _SiteBar extends StatelessWidget {
  const _SiteBar({
    required this.site,
    required this.credit,
    required this.onBuild,
    required this.onCancel,
    required this.onUseCredit,
    required this.onMove,
    required this.onDeselect,
  });

  final CitySite site;
  final int credit;
  final VoidCallback onBuild;
  final VoidCallback onCancel;
  final VoidCallback onUseCredit;

  /// Null for a land site, which can't move.
  final VoidCallback? onMove;
  final VoidCallback onDeselect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final usable = credit < site.site.remaining ? credit : site.site.remaining;
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.construction_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SiteProgressBar(
                      paid: site.site.paidCoins,
                      price: site.site.price,
                      name: site.name,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CloseButton(onPressed: onDeselect, tooltip: 'Deselect'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  FilledButton(
                    onPressed: onCancel,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.errorRedDeep,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel'),
                  ),
                  if (onMove != null) ...[
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: onMove,
                      icon: const Icon(Icons.open_with_rounded),
                      label: const Text('Move'),
                    ),
                  ],
                  if (usable > 0) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onUseCredit,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.successGreenDeep,
                        foregroundColor: Colors.white,
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            coinSpan(),
                            TextSpan(text: ' Use $usable'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  FilledButton(onPressed: onBuild, child: const Text('Build!')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AppBar pill showing credit from cancelled sites — coins with no site
/// yet. Only shown while the balance is above zero.
class _CreditChip extends StatelessWidget {
  const _CreditChip({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Tooltip(
      message: 'Credit — use it on any site',
      child: Material(
        color: Colors.white,
        shape: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: CoinAmount(
            amount: amount,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: palette.successGreenDeep,
            ),
          ),
        ),
      ),
    );
  }
}

/// Kid-facing folder names for the four categories (city_builder.md §10.5).
const _folderNames = <BuildingCategory, String>{
  BuildingCategory.civicHousing: 'Homes',
  BuildingCategory.services: 'Services',
  BuildingCategory.commercial: 'Shops',
  BuildingCategory.entertainment: 'Fun',
};

const _folderEmoji = <BuildingCategory, String>{
  BuildingCategory.civicHousing: '🏠',
  BuildingCategory.services: '🚒',
  BuildingCategory.commercial: '🛒',
  BuildingCategory.entertainment: '🎡',
};

/// The bottom bar at rest, in three zones (city_builder.md §10.5): open
/// construction sites with a progress ring, then buildings a letter has
/// asked for (envelope badge, tap re-opens the letter), then four folders —
/// or, with one open, its cards behind a back chevron. Never a third level.
class _BuildBar extends StatelessWidget {
  const _BuildBar({
    required this.catalog,
    required this.sites,
    required this.requested,
    required this.eventAsks,
    required this.chapterOne,
    required this.nudge,
    required this.openFolder,
    required this.newCardIds,
    required this.onOpenFolder,
    required this.onSelectSite,
    required this.onOpenLetter,
    required this.onSelect,
  });

  final List<BuildingType> catalog;
  final List<CitySite> sites;

  /// Buildings a citizen's letter has asked for, by building id.
  final Map<String, OpenBeat> requested;

  /// Open event letters (the block party): a card each in the requested
  /// zone, since an event has no building card to come back from.
  final List<OpenBeat> eventAsks;

  /// While chapter one runs there is no third zone: the letters carry the
  /// flow and the folders arrive with the hand-over (city_builder.md §10.4).
  final bool chapterOne;

  /// A one-shot bounce of the first requested card (the idle nudge).
  final bool nudge;
  final BuildingCategory? openFolder;

  /// Cards that arrived since the bar was last looked at.
  final Set<String> newCardIds;
  final void Function(BuildingCategory?) onOpenFolder;
  final void Function(CitySite) onSelectSite;
  final void Function(OpenBeat) onOpenLetter;
  final void Function(BuildingType) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asked = catalog.where((b) => requested.containsKey(b.id)).toList();
    final rest = catalog.where((b) => !requested.containsKey(b.id)).toList();
    final folder = openFolder;

    final cards = <Widget>[
      for (final site in sites)
        _SiteCard(site: site, onTap: () => onSelectSite(site)),
      if (sites.isNotEmpty &&
          (asked.isNotEmpty || eventAsks.isNotEmpty || rest.isNotEmpty))
        const _ZoneDivider(),
      for (final (i, b) in asked.indexed)
        _Nudge(
          active: nudge && i == 0,
          child: _CatalogCard(
            building: b,
            color: _colorFor(b),
            requestedBy: citizenForBeat(requested[b.id]!.beat),
            onTap: () => onOpenLetter(requested[b.id]!),
          ),
        ),
      for (final (i, b) in eventAsks.indexed)
        _Nudge(
          active: nudge && asked.isEmpty && i == 0,
          child: _EventCard(
            beat: b.beat,
            requestedBy: citizenForBeat(b.beat),
            onTap: () => onOpenLetter(b),
          ),
        ),
      if (chapterOne)
        const SizedBox.shrink()
      else if ((asked.isNotEmpty || eventAsks.isNotEmpty) && rest.isNotEmpty)
        const _ZoneDivider(),
      if (chapterOne)
        const SizedBox.shrink()
      else if (folder == null) ...[
        // Only folders with something in them; an empty one is noise.
        for (final c in BuildingCategory.values)
          if (rest.any((b) => b.category == c))
            _FolderCard(
              category: c,
              count: rest.where((b) => b.category == c).length,
              hasNew: rest.any(
                (b) => b.category == c && newCardIds.contains(b.id),
              ),
              onTap: () => onOpenFolder(c),
            ),
      ] else ...[
        _BackCard(category: folder, onTap: () => onOpenFolder(null)),
        for (final b in rest.where((b) => b.category == folder))
          _CatalogCard(
            building: b,
            color: _colorFor(b),
            isNew: newCardIds.contains(b.id),
            onTap: () => onSelect(b),
          ),
      ],
    ];

    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _kCatalogBarHeight,
          child: cards.isEmpty
              ? Center(
                  child: Text(
                    'No buildings yet — keep playing math!',
                    style: theme.textTheme.bodySmall,
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: cards.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => cards[i],
                ),
        ),
      ),
    );
  }
}

/// Plays one scale bounce each time [active] flips to true.
class _Nudge extends StatefulWidget {
  const _Nudge({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Nudge> createState() => _NudgeState();
}

class _NudgeState extends State<_Nudge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.18), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.96), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.08), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.08, end: 1), weight: 1),
  ]).animate(_controller);

  @override
  void didUpdateWidget(_Nudge old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      unawaited(_controller.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// A thin vertical rule between the bar's zones.
class _ZoneDivider extends StatelessWidget {
  const _ZoneDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
    child: VerticalDivider(
      width: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
  );
}

/// The shared card frame: fixed width, tinted, optional selected border.
class _BarCard extends StatelessWidget {
  const _BarCard({
    required this.color,
    required this.onTap,
    required this.child,
    this.dashed = false,
  });

  final Color color;
  final VoidCallback onTap;
  final Widget child;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: dashed ? 0.10 : 0.25),
          borderRadius: BorderRadius.circular(12),
          border: dashed
              ? Border.all(color: theme.colorScheme.outlineVariant, width: 1.5)
              : null,
        ),
        child: child,
      ),
    );
  }
}

/// Zone 1: an open construction site with its progress ring. Tap selects
/// the site so its bar (paid / price, Build!) comes up.
class _SiteCard extends StatelessWidget {
  const _SiteCard({required this.site, required this.onTap});

  final CitySite site;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = site.goal;
    final emoji = switch (goal) {
      BuildingGoal(:final type) => type.emoji,
      LandBlockGoal() => '🟫',
      EventGoal() => '🎈',
    };
    final color = switch (goal) {
      BuildingGoal(:final type) => _colorFor(type),
      LandBlockGoal() => const Color(0xFF8D6E63),
      EventGoal() => const Color(0xFFEF5350),
    };
    final fraction = site.site.price == 0
        ? 1.0
        : (site.site.paidCoins / site.site.price).clamp(0.0, 1.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _BarCard(
          color: color,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  site.name,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '🚧 ${site.site.paidCoins} / ${site.site.price}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: _ProgressRing(fraction: fraction),
        ),
      ],
    );
  }
}

/// A small ring showing how much of a site is paid.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: scheme.surface, shape: BoxShape.circle),
      padding: const EdgeInsets.all(3),
      child: CustomPaint(
        painter: _RingPainter(
          fraction: fraction,
          color: const Color(0xFF2F6FA8),
          track: scheme.outlineVariant,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    Paint stroke(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = c;
    canvas
      ..drawArc(rect, 0, 2 * math.pi, false, stroke(track))
      ..drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        stroke(color),
      );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}

/// Zone 3 closed: one of the four folders.
class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.category,
    required this.count,
    required this.hasNew,
    required this.onTap,
  });

  final BuildingCategory category;
  final int count;
  final bool hasNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _categoryColors[category] ?? const Color(0xFF90A4AE);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _BarCard(
          color: color,
          dashed: true,
          onTap: onTap,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _folderEmoji[category]!,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  _folderNames[category]!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('$count', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ),
        if (hasNew)
          const Positioned(
            top: -4,
            right: -4,
            child: Text('✨', style: TextStyle(fontSize: 16)),
          ),
      ],
    );
  }
}

/// Zone 3 open: the back chevron that closes the folder.
class _BackCard extends StatelessWidget {
  const _BackCard({required this.category, required this.onTap});

  final BuildingCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chevron_left_rounded, size: 28),
            Text(
              _folderNames[category]!,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// A building card: emoji, name, price. Wears an envelope badge with the
/// requesting citizen's face when a letter asked for it, or a sparkle when
/// it arrived since the bar was last looked at.
class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.building,
    required this.color,
    required this.onTap,
    this.requestedBy,
    this.isNew = false,
  });

  final BuildingType building;
  final Color color;
  final VoidCallback onTap;

  /// The citizen whose open letter asks for this building, if any.
  final Citizen? requestedBy;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = building;
    final costStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final card = _BarCard(
      color: color,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(b.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              b.name,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          if (b.coinCost == 0)
            Text('Free', style: costStyle)
          else
            CoinAmount(amount: b.coinCost, iconSize: 12, style: costStyle),
        ],
      ),
    );
    final badge = requestedBy;
    if (badge == null && !isNew) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -6,
          right: -6,
          child: badge != null
              ? _EnvelopeBadge(citizen: badge)
              : const Text('✨', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}

/// Zone 2 for an event letter: the party the organiser asked for, with the
/// envelope badge; tap re-opens the letter.
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.beat,
    required this.requestedBy,
    required this.onTap,
  });

  final StoryBeat beat;
  final Citizen requestedBy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEvent = beat.event != null;
    final card = _BarCard(
      color: isEvent ? const Color(0xFFEF5350) : const Color(0xFFFFA726),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(beat.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              isEvent ? 'Block party' : beat.shortLabel,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isEvent) ...[
            const SizedBox(height: 2),
            CoinAmount(
              amount: kBlockPartyPrice,
              iconSize: 12,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -6,
          right: -6,
          child: _EnvelopeBadge(citizen: requestedBy),
        ),
      ],
    );
  }
}

/// The "a citizen asked for this" badge: their face in a ring, with a small
/// envelope so it reads as mail even at a glance.
class _EnvelopeBadge extends StatelessWidget {
  const _EnvelopeBadge({required this.citizen});

  final Citizen citizen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFA726), width: 2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AdventurerAvatarWidget(config: citizen.face, size: 26),
          const Positioned(
            right: -6,
            bottom: -4,
            child: Text('✉️', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// Tracks raw pointer events to detect two-finger pinch and drive
/// [IsoCityGame.setZoom]. Sits below Flutter's gesture arena via
/// [Listener], so Flame's `DragCallbacks` still receives single-finger
/// drags untouched. While 2+ pointers are down, [IsoCityGame.pinchActive]
/// suppresses the per-finger pan so the camera doesn't jitter.
class _PinchZoomWrapper extends StatefulWidget {
  const _PinchZoomWrapper({required this.game, required this.child});

  final IsoCityGame game;
  final Widget child;

  @override
  State<_PinchZoomWrapper> createState() => _PinchZoomWrapperState();
}

class _PinchZoomWrapperState extends State<_PinchZoomWrapper> {
  final _pointers = <int, Offset>{};
  double? _initialDistance;
  double? _initialZoom;

  void _onDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length >= 2) {
      _initialDistance = _twoPointerDistance();
      _initialZoom = widget.game.camera.viewfinder.zoom;
      widget.game.pinchActive = true;
    }
  }

  void _onMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    if (_pointers.length >= 2 &&
        _initialDistance != null &&
        _initialDistance! > 0) {
      final scale = _twoPointerDistance() / _initialDistance!;
      widget.game.setZoom(_initialZoom! * scale);
    }
  }

  void _onUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2) {
      _initialDistance = null;
      _initialZoom = null;
      widget.game.pinchActive = false;
    }
  }

  /// Distance between the first two tracked pointers (iteration order is
  /// insertion order on `Map`, which is good enough — we only need a stable
  /// reference pair for the duration of one pinch).
  double _twoPointerDistance() {
    final it = _pointers.values.iterator..moveNext();
    final a = it.current;
    it.moveNext();
    final b = it.current;
    return (a - b).distance;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: widget.child,
    );
  }
}
