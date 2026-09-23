import 'dart:async';

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
import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/domain/city/land_blocks.dart';
import 'package:math_city/domain/city/placement_rules.dart';
import 'package:math_city/domain/city/road_network.dart';
import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/game/city/city_board_component.dart';
import 'package:math_city/game/city/iso_city_game.dart';
import 'package:math_city/game/city/iso_grid.dart';
import 'package:math_city/game/city/land_window.dart';
import 'package:math_city/presentation/city/celebration_overlay.dart';
import 'package:math_city/presentation/city/spin_overlay.dart';
import 'package:math_city/presentation/navigation/route_observer.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_city/presentation/question/question_screen.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/widgets/coin_icon.dart';
import 'package:math_city/presentation/widgets/site_progress_bar.dart';
import 'package:math_city/presentation/widgets/speech_toggle_button.dart';
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

  /// The only catalog entry is picked for the starter player automatically,
  /// once — after they back out of it with X, the catalog shows instead.
  bool _autoPicked = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
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
  void _dropMoved() => setState(() {
    _movingId = null;
    _movingSiteId = null;
    _moveOrigin = null;
  });

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
      if (s.goal case BuildingGoal(:final footprint)) {
        if (footprint.tiles().contains((col, row))) return s;
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
    setState(() => _pendingSpot = null);
    unawaited(
      _startSite(BuildingGoal(type: type, col: spot.col, row: spot.row)),
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
          selected: p.id == _movingId || p.id == _selectedBuildingId,
        ),
      );
    }
    // Building sites render on the same layer, at their construction stage.
    // A site's ghost (stage 2) shows the type's first sprite variant.
    for (final s in sites) {
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

    // Auto-select the only buildable building so the starter player doesn't
    // have to click the mayor's office before placing it. Once the catalog
    // grows, the player makes an explicit pick.
    // .value (not asData?.value) so a refresh — which the catalog does on
    // every placement — keeps the *previous* catalog instead of momentarily
    // dropping to null. Otherwise the bottom bar collapses for a frame, which
    // resizes the Flame viewport and makes the camera jump (see bottomNavBar).
    final catalog = catalogAsync.value;
    if (_selected == null &&
        !_autoPicked &&
        catalog != null &&
        catalog.length == 1 &&
        sites.length < kMaxOpenSites) {
      _selected = catalog.first;
      _autoPicked = true;
    }

    final zoomed = _mode != _CityMode.browsing;
    // The zoomed site as it stands now (its bar keeps filling between
    // blocks), falling back to the snapshot taken at Build!.
    final liveZoomed = _zoomedSite == null
        ? null
        : sites.where((s) => s.id == _zoomedSite!.id).firstOrNull ??
              _zoomedSite;
    final celebratingSite = _celebratingSite;
    final credit = player?.creditBalance ?? 0;

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
        : selectedBuildingType != null
        ? _BuildingBar(
            type: selectedBuildingType,
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
        : _BuildCatalogBar(
            catalog: catalog,
            selected: _selected,
            onSelect: (b) {
              if (_atSiteCap(sites)) return;
              setState(() {
                _selected = b;
                _pendingSpot = null;
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
          // Credit from cancelled sites, only while there is any.
          actions: [
            if (credit > 0)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _CreditChip(amount: credit),
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
                    // Floating citizen bubbles (and their tap-to-expand cards).
                    if (!zoomed)
                      const Positioned.fill(child: _CitizenBubbleOverlay()),
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
                          onDone: _zoomOut,
                          cardKey: _celebrationCardKey,
                        ),
                      ),
                    // The wheel is reached through a site's Build! — there is
                    // no free-floating "play" entry (city_builder.md §8.3).
                    // Parked above the tallest bar so no bar ever covers it.
                    if (kDebugMode && !zoomed)
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
              '(building age = clock − placed-at; bubbles rotate off after '
              '$kBubbleRotationRounds)',
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
  });

  final BuildingType type;
  final VoidCallback onMove;
  final VoidCallback onDeselect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pop = type.populationContribution;
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: onMove,
                icon: const Icon(Icons.open_with_rounded),
                label: const Text('Move'),
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
  });

  final BuildingType type;
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
                    Text.rich(
                      TextSpan(
                        children: type.coinCost == 0
                            ? const [TextSpan(text: 'Free — place it here?')]
                            : [
                                coinSpan(),
                                TextSpan(
                                  text: ' ${type.coinCost} — place it here?',
                                ),
                              ],
                      ),
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
              FilledButton(onPressed: onPlace, child: const Text('Place here')),
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

/// Color accent for a beat by its kind — demands nudge (amber), praise
/// celebrates (green), warnings alert (red).
Color _beatColor(BeatKind kind) => switch (kind) {
  BeatKind.demand => const Color(0xFFFFA726),
  BeatKind.praise => const Color(0xFF66BB6A),
  BeatKind.warning => const Color(0xFFEF5350),
};

/// The ✓ flash sequence for a fulfilled demand: a quick attention-grabbing pop
/// (scale 1.0 → [_kPopMaxScale] → 1.0), then a hold, then a fade-out. Total
/// wall-clock duration is [_kCompletedFlashDuration]; the overlay's retire
/// timer matches it so the bubble's state row only flips to 'acked' once the
/// fade has finished. Wall-clock and not rounds — completion happens on
/// placement, and the round clock only ticks on answered math questions.
const _kCompletedPopUp = Duration(milliseconds: 200);
const _kCompletedPopDown = Duration(milliseconds: 200);
const _kCompletedHold = Duration(seconds: 5);
const _kCompletedFade = Duration(seconds: 3);
const _kPopMaxScale = 1.5;
const _kCompletedFlashDuration = Duration(
  milliseconds: 200 + 200 + 5000 + 3000, // == pop-up + pop-down + hold + fade
);

/// Floating citizen-bubble layer drawn over the city. Shows up to 5 of the
/// beats currently in the `onScreen` state (from [onScreenBeatsProvider]) as
/// emoji stickers along the top; tapping one marks it read and expands it into
/// a card with the full sentence and a "Got it" button. Opening a demand
/// bubble is what unlocks the building it asks for; the sticker itself lingers
/// a few rounds before retiring (see [kReadHideRounds]). "Got it" just closes
/// the card.
///
/// Demand/warning bubbles whose request has been fulfilled (e.g. the player
/// built the house the demand asked for) come back from the provider in their
/// `completed` form: praise-green ring + ✓ badge. They auto-retire after
/// [_kCompletedFlashDuration]; tapping them retires immediately.
///
/// Empty regions don't absorb touches, so the city stays pannable; while a
/// card is open a scrim catches outside taps to collapse it.
class _CitizenBubbleOverlay extends ConsumerStatefulWidget {
  const _CitizenBubbleOverlay();

  @override
  ConsumerState<_CitizenBubbleOverlay> createState() =>
      _CitizenBubbleOverlayState();
}

class _CitizenBubbleOverlayState extends ConsumerState<_CitizenBubbleOverlay> {
  String? _expandedId;

  /// Auto-retire timers for each currently-displayed `completed` bubble, keyed
  /// by beat id. Cancelled on disposal so the dispatched retire-action doesn't
  /// fire after the screen is gone.
  final Map<String, Timer> _completedTimers = {};

  void _scheduleRetire(String beatId) {
    if (_completedTimers.containsKey(beatId)) return;
    _completedTimers[beatId] = Timer(_kCompletedFlashDuration, () {
      _completedTimers.remove(beatId);
      if (!mounted) return;
      unawaited(ref.read(cityActionsProvider).retireCompletedBeat(beatId));
    });
  }

  void _retireNow(String beatId) {
    _completedTimers.remove(beatId)?.cancel();
    unawaited(ref.read(cityActionsProvider).retireCompletedBeat(beatId));
  }

  @override
  void dispose() {
    for (final t in _completedTimers.values) {
      t.cancel();
    }
    _completedTimers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Repeat the currently-open bubble's long text when the user flips
    // speech off→on. Only a real user toggle counts — initial
    // loading→AsyncData(true) is suppressed so we don't speak on every
    // mount of the city screen.
    ref.listen<AsyncValue<bool>>(ttsEnabledProvider, (prev, next) {
      final wasExplicitlyOff = prev is AsyncData<bool> && !prev.value;
      final isOn = next is AsyncData<bool> && next.value;
      if (!wasExplicitlyOff || !isOn) return;
      final id = _expandedId;
      if (id == null) return;
      final current = ref
          .read(onScreenBeatsProvider)
          .asData
          ?.value
          .where((b) => b.beat.id == id && !b.completed)
          .firstOrNull;
      if (current == null) return;
      unawaited(ref.read(ttsServiceProvider).speak(current.beat.longText));
    });

    final beats =
        ref.watch(onScreenBeatsProvider).asData?.value ??
        const <OnScreenBeat>[];
    final shown = beats.take(5).toList();

    // Maintain timers in sync with what's currently in the completed state.
    // Schedule a retire for each new completed bubble, and drop timers for any
    // that have already left the list (e.g. the provider raced ahead of us).
    final liveCompletedIds = <String>{
      for (final b in shown)
        if (b.completed) b.beat.id,
    }..forEach(_scheduleRetire);
    _completedTimers.removeWhere((id, t) {
      if (liveCompletedIds.contains(id)) return false;
      t.cancel();
      return true;
    });

    if (shown.isEmpty) {
      _expandedId = null;
      return const SizedBox.shrink();
    }

    // Completed bubbles aren't expandable — they auto-retire. If the user
    // somehow has one expanded when it completes, close the card.
    final expanded = _expandedId == null
        ? null
        : shown
              .where((b) => b.beat.id == _expandedId && !b.completed)
              .firstOrNull
              ?.beat;

    return Stack(
      children: [
        // Sticker row, top-right so it clears the population chip.
        Positioned(
          top: 8,
          right: 8,
          left: 64,
          child: SafeArea(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                for (final b in shown)
                  _BubbleSticker(
                    key: ValueKey('beat-${b.beat.id}'),
                    beat: b.beat,
                    completed: b.completed,
                    // Completed bubbles auto-retire on tap; for live bubbles,
                    // opening one marks it read — which both starts its linger
                    // timer and unlocks the building a demand asks for.
                    onTap: b.completed
                        ? () => _retireNow(b.beat.id)
                        : () {
                            unawaited(
                              ref
                                  .read(cityActionsProvider)
                                  .markBeatRead(b.beat.id),
                            );
                            unawaited(
                              speakIfEnabled(ref, b.beat.longText),
                            );
                            setState(() => _expandedId = b.beat.id);
                          },
                  ),
              ],
            ),
          ),
        ),
        if (expanded != null) ...[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                unawaited(ref.read(ttsServiceProvider).stop());
                setState(() => _expandedId = null);
              },
            ),
          ),
          Positioned(
            top: 64,
            left: 16,
            right: 16,
            child: SafeArea(
              child: _ExpandedBeatCard(
                beat: expanded,
                // Already marked read on open; "Got it" just closes the card.
                onDismiss: () {
                  unawaited(ref.read(ttsServiceProvider).stop());
                  setState(() => _expandedId = null);
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Collapsed bubble: a round emoji sticker ringed in its beat's accent color.
/// When [completed] is true (a demand/warning whose request has been fulfilled)
/// the ring flips to praise-green and a ✓ badge overlays the emoji. The
/// sticker also runs the four-stage flash animation in that state:
///   1. pop up to [_kPopMaxScale] over [_kCompletedPopUp]
///   2. pop back to 1.0 over [_kCompletedPopDown]
///   3. hold at full opacity for [_kCompletedHold]
///   4. fade to invisible over [_kCompletedFade]
/// The overlay's retire timer is sized to [_kCompletedFlashDuration] so the
/// state row only flips to 'acked' once the fade has run.
class _BubbleSticker extends StatefulWidget {
  const _BubbleSticker({
    required this.beat,
    required this.onTap,
    super.key,
    this.completed = false,
  });

  final StoryBeat beat;
  final VoidCallback onTap;
  final bool completed;

  @override
  State<_BubbleSticker> createState() => _BubbleStickerState();
}

class _BubbleStickerState extends State<_BubbleSticker>
    with SingleTickerProviderStateMixin {
  static const _completedAccent = Color(0xFF66BB6A);

  /// Drives scale + opacity for the completed flash. Null while the bubble
  /// is in its normal (non-completed) state.
  AnimationController? _flash;

  @override
  void initState() {
    super.initState();
    if (widget.completed) _startFlash();
  }

  @override
  void didUpdateWidget(_BubbleSticker old) {
    super.didUpdateWidget(old);
    // Bubble transitions into completion (e.g. user placed the building):
    // start the pop/hold/fade. Going back out of completed is unusual but
    // harmless — drop the controller so the bubble snaps to its idle look.
    if (widget.completed && !old.completed) {
      _startFlash();
    } else if (!widget.completed && old.completed) {
      _flash?.dispose();
      _flash = null;
    }
  }

  void _startFlash() {
    _flash?.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: _kCompletedFlashDuration,
    );
    _flash = controller;
    unawaited(controller.forward().orCancel.catchError((Object _) {}));
  }

  @override
  void dispose() {
    _flash?.dispose();
    super.dispose();
  }

  double _scaleFor(double tMs) {
    final popUp = _kCompletedPopUp.inMilliseconds.toDouble();
    final popDownEnd = popUp + _kCompletedPopDown.inMilliseconds;
    if (tMs <= popUp) {
      final p = (tMs / popUp).clamp(0.0, 1.0);
      return 1.0 + (_kPopMaxScale - 1.0) * Curves.easeOut.transform(p);
    }
    if (tMs <= popDownEnd) {
      final p = ((tMs - popUp) / _kCompletedPopDown.inMilliseconds).clamp(
        0.0,
        1.0,
      );
      return _kPopMaxScale - (_kPopMaxScale - 1) * Curves.easeIn.transform(p);
    }
    return 1;
  }

  double _opacityFor(double tMs) {
    final fadeStart = (_kCompletedPopUp + _kCompletedPopDown + _kCompletedHold)
        .inMilliseconds
        .toDouble();
    final fadeMs = _kCompletedFade.inMilliseconds.toDouble();
    if (tMs <= fadeStart) return 1;
    if (tMs >= fadeStart + fadeMs) return 0;
    return 1 - (tMs - fadeStart) / fadeMs;
  }

  @override
  Widget build(BuildContext context) {
    final sticker = _Sticker(
      beat: widget.beat,
      accent: widget.completed
          ? _completedAccent
          : _beatColor(widget.beat.kind),
      showCheck: widget.completed,
      checkColor: _completedAccent,
    );
    final flash = _flash;
    final child = (widget.completed && flash != null)
        ? AnimatedBuilder(
            animation: flash,
            builder: (context, cachedChild) {
              final tMs = flash.value * _kCompletedFlashDuration.inMilliseconds;
              return Opacity(
                opacity: _opacityFor(tMs),
                child: Transform.scale(
                  scale: _scaleFor(tMs),
                  child: cachedChild,
                ),
              );
            },
            child: sticker,
          )
        : sticker;
    return GestureDetector(onTap: widget.onTap, child: child);
  }
}

/// The pure visual: the emoji disc + optional ✓ badge. Pulled out of
/// [_BubbleSticker] so the [AnimatedBuilder] can keep it as a const-ish child
/// while the wrapper rebuilds on every tick.
class _Sticker extends StatelessWidget {
  const _Sticker({
    required this.beat,
    required this.accent,
    required this.showCheck,
    required this.checkColor,
  });

  final StoryBeat beat;
  final Color accent;
  final bool showCheck;
  final Color checkColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(beat.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          if (showCheck)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: checkColor,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Expanded bubble: the full sentence with a "Got it" dismiss button.
class _ExpandedBeatCard extends StatelessWidget {
  const _ExpandedBeatCard({required this.beat, required this.onDismiss});

  final StoryBeat beat;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _beatColor(beat.kind);
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(beat.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    beat.shortLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(beat.longText, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                const SpeechToggleIconButton(),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: onDismiss,
                  child: const Text('Got it'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal catalog of buildings whose unlock rule has passed. Every card
/// is tap-to-select; placing it starts a site at the shown price, so nothing
/// is ever unaffordable.
class _BuildCatalogBar extends StatelessWidget {
  const _BuildCatalogBar({
    required this.catalog,
    required this.selected,
    required this.onSelect,
  });

  final List<BuildingType> catalog;
  final BuildingType? selected;
  final void Function(BuildingType) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _kCatalogBarHeight,
          child: catalog.isEmpty
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
                  itemCount: catalog.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final b = catalog[i];
                    return _CatalogCard(
                      building: b,
                      isSelected: b.id == selected?.id,
                      color: _colorFor(b),
                      onTap: () => onSelect(b),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.building,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final BuildingType building;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = building;
    final costStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 88,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
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

    return GestureDetector(onTap: onTap, child: card);
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
