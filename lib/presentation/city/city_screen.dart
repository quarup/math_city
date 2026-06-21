import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/domain/city/beat_registry.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/category.dart';
import 'package:math_city/domain/city/city_map_registry.dart';
import 'package:math_city/domain/city/land_expansion.dart';
import 'package:math_city/domain/city/placement_rules.dart';
import 'package:math_city/domain/city/road_network.dart';
import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/game/city/city_board_component.dart';
import 'package:math_city/game/city/iso_city_game.dart';
import 'package:math_city/game/city/iso_grid.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_city/presentation/spin/spin_screen.dart';
import 'package:math_city/presentation/widgets/speech_toggle_button.dart';
import 'package:math_city/state/city_provider.dart';
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
/// the home screen, and jump to the spin wheel from here. Chunk 2 scope:
/// render the empty grid, list the researched build catalog, tap-to-place.
class CityScreen extends ConsumerStatefulWidget {
  const CityScreen({super.key});

  /// Route name so the spin→question→result loop can return here rather than
  /// all the way to the home screen.
  static const routeName = 'city';

  @override
  ConsumerState<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends ConsumerState<CityScreen> {
  IsoCityGame? _game;

  /// Catalog building type chosen for *new* placement. Independent of
  /// [_movingId]: it stays remembered (and re-highlighted in the catalog) after
  /// the player finishes repositioning whatever they just placed/picked up.
  BuildingType? _selected;

  /// The placed building currently picked up for repositioning (yellow tint +
  /// footprint outline), or null when nothing is selected. Set by tapping a
  /// building, or automatically right after one is bought + placed so the
  /// player can nudge it into place on a small screen.
  int? _movingId;

  /// One tap on the board. Tapping a placed building selects it for moving
  /// (tapping the already-selected one drops it); tapping a free tile either
  /// repositions the picked-up building or places the catalog selection, in
  /// both cases auto-fitting the footprint to cover the tapped tile.
  void _onTileTapped(int col, int row) {
    final placements = ref.read(placementsProvider).asData?.value ?? const [];
    final city = ref.read(activeCityProvider).asData?.value;
    if (city == null) return;

    final occupant = _buildingAt(placements, col, row);
    if (occupant != null) {
      // Tap a building to pick it up; tap the held one again to drop it.
      setState(() => _movingId = occupant.id == _movingId ? null : occupant.id);
      return;
    }

    // A free tile: reposition the held building, else place the catalog pick.
    if (_movingId != null) {
      _tryMove(_movingId!, col, row, placements, city);
      return;
    }
    final selected = _selected;
    if (selected == null) {
      _toast('Pick a building below first');
      return;
    }
    _tryPlace(selected, col, row, placements, city);
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
  /// auto-sliding the anchor as needed. Free (no 🧱). Stays selected so the
  /// player can keep nudging it.
  void _tryMove(
    int placementId,
    int col,
    int row,
    List<BuildingPlacement> placements,
    City city,
  ) {
    final picked = placements.where((p) => p.id == placementId).firstOrNull;
    final type = picked == null
        ? null
        : findBuildingTypeById(picked.buildingTypeId);
    if (picked == null || type == null) {
      setState(() => _movingId = null);
      return;
    }
    final spot = _resolve(type, col, row, placements, city, exclude: picked.id);
    if (spot == null) {
      _toast('No room for ${type.name} there');
      return;
    }
    unawaited(
      ref.read(cityActionsProvider).moveBuilding(picked.id, spot.col, spot.row),
    );
  }

  /// Places [type] so its footprint covers `(col, row)` (auto-sliding the
  /// anchor). For unique types that already exist, moves the existing instance
  /// instead. On success the placed/moved building is left selected so the
  /// player can fine-tune its position.
  void _tryPlace(
    BuildingType type,
    int col,
    int row,
    List<BuildingPlacement> placements,
    City city,
  ) {
    // Unique types (mayor's office): relocate the existing instance rather than
    // stacking a duplicate.
    if (type.unique) {
      final existing = placements
          .where((p) => p.buildingTypeId == type.id)
          .firstOrNull;
      if (existing != null) {
        setState(() => _movingId = existing.id);
        _tryMove(existing.id, col, row, placements, city);
        return;
      }
    }

    final spot = _resolve(type, col, row, placements, city);
    if (spot == null) {
      _toast('No room for ${type.name} there');
      return;
    }
    final bricks = ref.read(activePlayerProvider).asData?.value.brickBalance;
    if (bricks == null || type.brickCost > bricks) {
      _toast('Not enough bricks for ${type.name}');
      return;
    }
    unawaited(() async {
      final id = await ref
          .read(cityActionsProvider)
          .placeBuilding(type, spot.col, spot.row);
      if (!mounted) return;
      setState(() {
        // Keep the just-placed building selected so it can be nudged (req. #3),
        // and drop the catalog pick if the player can't afford another.
        _movingId = id;
        if (bricks - type.brickCost < type.brickCost) _selected = null;
      });
    }());
  }

  /// Maps placements to grid footprints via the building registry. Pass
  /// [exclude] to drop one placement (used when moving, so the mover's old
  /// tiles don't count as occupied).
  List<GridFootprint> _footprintsOf(
    List<BuildingPlacement> placements, {
    int? exclude,
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
    City city, {
    int? exclude,
  }) {
    return resolvePlacement(
      gridWidth: city.gridWidth,
      gridHeight: city.gridHeight,
      existing: _footprintsOf(placements, exclude: exclude),
      width: type.footprint.$1,
      height: type.footprint.$2,
      tapCol: col,
      tapRow: row,
    );
  }

  /// The auto-generated road tiles for the current placements (see
  /// `road_network.dart`).
  Set<(int, int)> _roadTilesFor(
    List<BuildingPlacement> placements,
    City city,
  ) => generateRoads(
    gridWidth: city.gridWidth,
    gridHeight: city.gridHeight,
    buildings: _footprintsOf(placements),
  );

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  void _openSpin() {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SpinScreen()),
      ),
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
          onReset: () => setState(() {
            _selected = null;
            _movingId = null;
          }),
        ),
      ),
    );
  }

  /// The next land expansion available for [city], or null at the 24×24 cap.
  LandExpansionOffer? _expansionOffer(City city) {
    final map = findCityMapById(city.cityMapId);
    if (map == null) return null;
    return nextLandExpansion(
      gridWidth: city.gridWidth,
      gridHeight: city.gridHeight,
      baseGridWidth: map.baseGridWidth,
      baseGridHeight: map.baseGridHeight,
    );
  }

  /// Tap on the expand FAB: confirm the size + 🧱 cost, then buy the
  /// expansion. Mirrors the research-confirm flow.
  Future<void> _confirmExpand(LandExpansionOffer offer) async {
    final bricks = ref.read(activePlayerProvider).asData?.value.brickBalance;
    if (bricks == null || offer.brickCost > bricks) {
      _toast('Not enough bricks to expand — keep playing math!');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Expand your land?'),
        content: Text(
          'Spend 🧱 ${offer.brickCost} to grow the map to '
          '${offer.newGridWidth}×${offer.newGridHeight} tiles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Expand'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(cityActionsProvider).expandLand();
    }
  }

  /// Tap on a locked (available-to-research) catalog card: confirm, then spend
  /// 🔬 to unlock the type. On success the newly-researched building is
  /// auto-selected so the player can place it right away.
  Future<void> _confirmResearch(BuildingType b) async {
    final research = ref
        .read(activePlayerProvider)
        .asData
        ?.value
        .researchBalance;
    if (research == null || b.researchCost > research) {
      _toast('Not enough research for ${b.name}');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Research ${b.name}?'),
        content: Text(
          'Spend 🔬 ${b.researchCost} to add ${b.name} to your build menu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Research'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(cityActionsProvider).researchBuilding(b);
      if (mounted) setState(() => _selected = b);
    }
  }

  List<PlacedBuildingView> _viewsFor(List<BuildingPlacement> placements) {
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
          col: p.gridX,
          row: p.gridY,
          emoji: type.emoji,
          color: _colorFor(type),
          footprint: type.footprint,
          assetPath: _assetPathFor(type, slotById[p.id] ?? 0),
          selected: p.id == _movingId,
        ),
      );
    }
    return out;
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
    final catalogAsync = ref.watch(cityCatalogProvider);

    final player = playerAsync.asData?.value;

    // Build the game once the grid size is known, then keep its render model
    // in sync with the latest placements. A land expansion changes the grid
    // size, so the game is rebuilt against the new grid when that happens
    // (the camera re-centers on the bigger board — a nice reveal).
    final city = cityAsync.asData?.value;
    if (city != null &&
        (_game == null ||
            _game!.grid.cols != city.gridWidth ||
            _game!.grid.rows != city.gridHeight)) {
      _game = IsoCityGame(
        grid: IsoGrid(cols: city.gridWidth, rows: city.gridHeight),
        onTileTapped: _onTileTapped,
      );
    }
    final placements = placementsAsync.asData?.value;
    // Drop a stale selection (e.g. the building was removed by a reset) so the
    // Done bar doesn't linger over nothing.
    if (_movingId != null &&
        placements != null &&
        !placements.any((p) => p.id == _movingId)) {
      _movingId = null;
    }
    if (_game != null && placements != null) {
      _game!.setBuildings(_viewsFor(placements));
      if (city != null) _game!.setRoads(_roadTilesFor(placements, city));
    }
    // The building currently picked up for repositioning, if any — drives the
    // Done bar's label.
    final moving = _movingId == null
        ? null
        : placements?.where((p) => p.id == _movingId).firstOrNull;
    final movingType = moving == null
        ? null
        : findBuildingTypeById(moving.buildingTypeId);

    // Auto-select the only researched building so the starter player doesn't
    // have to click the mayor's office before placing it. Once the catalog
    // grows (more researched buildings, or locked ones to research), the
    // player makes an explicit pick.
    // .value (not asData?.value) so a refresh — which the catalog does on
    // every placement — keeps the *previous* catalog instead of momentarily
    // dropping to null. Otherwise the bottom bar collapses for a frame, which
    // resizes the Flame viewport and makes the camera jump (see bottomNavBar).
    final catalog = catalogAsync.value;
    if (_selected == null && catalog != null) {
      final placeable = catalog.where((e) => e.researched).toList();
      if (placeable.length == 1) _selected = placeable.first.building;
    }

    return Scaffold(
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
        actions: [
          if (player != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _CurrencyBar(
                bricks: player.brickBalance,
                research: player.researchBalance,
              ),
            ),
        ],
      ),
      body: _game == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xFF9CCC65),
                    child: _PinchZoomWrapper(
                      game: _game!,
                      child: GameWidget(game: _game!),
                    ),
                  ),
                ),
                // Population counter, top-left over the city.
                Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
                    child: _PopulationChip(population: city?.population ?? 0),
                  ),
                ),
                // Floating citizen bubbles (and their tap-to-expand cards).
                const Positioned.fill(child: _CitizenBubbleOverlay()),
              ],
            ),
      // While a building is picked up, the catalog is swapped for a Done bar
      // (tap the building again, or Done, to drop it).
      bottomNavigationBar: _movingId != null
          ? _MoveModeBar(
              name: movingType?.name,
              onDone: () => setState(() => _movingId = null),
            )
          // Render from the retained catalog so a per-placement refresh never
          // collapses the bar (which would resize the game and jump the
          // camera). Only the very first load — before any data — is empty.
          : catalog == null
          ? const SizedBox.shrink()
          : _BuildCatalogBar(
              catalog: catalog,
              selected: _selected,
              brickBalance: player?.brickBalance ?? 0,
              researchBalance: player?.researchBalance ?? 0,
              onSelect: (b) => setState(() => _selected = b),
              onResearch: _confirmResearch,
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (kDebugMode) ...[
            FloatingActionButton.small(
              heroTag: 'cityDebugFab',
              onPressed: _openDebugSheet,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              child: const Icon(Icons.bug_report_rounded),
            ),
            const SizedBox(height: 12),
          ],
          // Land expansion — hidden while a building is picked up (it shifts
          // every placement) and at the 24×24 cap.
          if (city != null && _movingId == null)
            if (_expansionOffer(city) case final LandExpansionOffer offer) ...[
              FloatingActionButton.small(
                heroTag: 'cityExpandFab',
                tooltip: 'Expand land (🧱 ${offer.brickCost})',
                onPressed: () => unawaited(_confirmExpand(offer)),
                child: const Icon(Icons.zoom_out_map_rounded),
              ),
              const SizedBox(height: 12),
            ],
          FloatingActionButton.extended(
            heroTag: 'citySpinFab',
            onPressed: _openSpin,
            icon: const Icon(Icons.casino_rounded),
            label: const Text('Play math'),
          ),
        ],
      ),
    );
  }
}

/// kDebugMode-only control panel, shown in a bottom sheet from the city
/// screen's debug FAB. Lets a developer exercise the city mechanics
/// (placement, research, growth, beats) without grinding math for currency:
/// grant 🧱/🔬, set the population directly, research the whole catalog,
/// force-fire any beat, and reset the city to a brand-new-player baseline.
/// Operates on the *real* active player so persistence is exercised too.
class _CityDebugSheet extends ConsumerStatefulWidget {
  const _CityDebugSheet({required this.onReset});

  /// Called after a successful reset so the parent screen can clear its
  /// pending building selection (which may now be un-researched).
  final VoidCallback onReset;

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
          'Wipes all placements, researched buildings, beats, and population, '
          'and zeroes 🧱 / 🔬 (balances + lifetime). Cannot be undone.',
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
                    '🧱 ${player.brickBalance}   🔬 ${player.researchBalance}',
                    style: theme.textTheme.titleMedium,
                  ),
              ],
            ),
            const Divider(height: 24),
            Text('Currency', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => unawaited(actions.debugGrantBricks(500)),
                  child: const Text('+500 🧱'),
                ),
                FilledButton.tonal(
                  onPressed: () => unawaited(actions.debugGrantResearch(50)),
                  child: const Text('+50 🔬'),
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
            Text('Buildings', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => unawaited(actions.debugResearchAll()),
              child: const Text('Research all buildings'),
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

/// 🧱 / 🔬 balances on a shaded rounded card so both glyphs keep contrast
/// against the city's bright terrain background showing behind the AppBar.
class _CurrencyBar extends StatelessWidget {
  const _CurrencyBar({required this.bricks, required this.research});

  final int bricks;
  final int research;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🧱', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 5),
          Text('$bricks', style: textStyle),
          const SizedBox(width: 12),
          const Text('🔬', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 5),
          Text('$research', style: textStyle),
        ],
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

/// Bottom strip shown while a building is picked up for repositioning: a hint
/// to tap a tile to move it, plus a Done button to drop it and bring the build
/// catalog back.
class _MoveModeBar extends StatelessWidget {
  const _MoveModeBar({required this.onDone, this.name});

  /// Name of the picked-up building, for the hint text.
  final String? name;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final what = name ?? 'building';
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
                  'Moving $what — tap a tile to place it',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: onDone, child: const Text('Done')),
            ],
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

/// Horizontal catalog of buildings. Researched buildings are tap-to-select for
/// placement (🧱 cost); buildings still available to research show a 🔬 cost +
/// a lock badge and tap-to-research. Unaffordable cards are greyed.
class _BuildCatalogBar extends StatelessWidget {
  const _BuildCatalogBar({
    required this.catalog,
    required this.selected,
    required this.brickBalance,
    required this.researchBalance,
    required this.onSelect,
    required this.onResearch,
  });

  final List<CatalogEntry> catalog;
  final BuildingType? selected;
  final int brickBalance;
  final int researchBalance;
  final void Function(BuildingType) onSelect;
  final void Function(BuildingType) onResearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 120,
          child: catalog.isEmpty
              ? Center(
                  child: Text(
                    'No buildings yet — research some by playing math!',
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
                    final entry = catalog[i];
                    final b = entry.building;
                    final affordable = entry.researched
                        ? b.brickCost <= brickBalance
                        : b.researchCost <= researchBalance;
                    return _CatalogCard(
                      entry: entry,
                      isSelected: entry.researched && b.id == selected?.id,
                      affordable: affordable,
                      color: _colorFor(b),
                      // Researched + unaffordable can't be selected; locked
                      // cards are always tappable so the research flow can
                      // explain when the player can't afford the 🔬.
                      onTap: entry.researched
                          ? (affordable ? () => onSelect(b) : null)
                          : () => onResearch(b),
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
    required this.entry,
    required this.isSelected,
    required this.affordable,
    required this.color,
    required this.onTap,
  });

  final CatalogEntry entry;
  final bool isSelected;
  final bool affordable;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = entry.building;
    final locked = !entry.researched;
    final costLabel = locked
        ? '🔬 ${b.researchCost}'
        : (b.brickCost == 0 ? 'Free' : '🧱 ${b.brickCost}');

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
          Text(
            costLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: affordable ? 1 : 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: locked
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  card,
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              )
            : card,
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
