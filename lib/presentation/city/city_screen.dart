import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/category.dart';
import 'package:math_city/game/city/city_board_component.dart';
import 'package:math_city/game/city/iso_city_game.dart';
import 'package:math_city/game/city/iso_grid.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_city/presentation/spin/spin_screen.dart';
import 'package:math_city/state/city_provider.dart';
import 'package:math_city/state/player_provider.dart';

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
  BuildingType? _selected;

  void _onTileTapped(int col, int row) {
    final selected = _selected;
    if (selected == null) {
      _toast('Pick a building below first');
      return;
    }
    final placements = ref.read(placementsProvider).asData?.value ?? const [];
    final occupant = placements
        .where((p) => p.gridX == col && p.gridY == row)
        .firstOrNull;

    // Unique types (mayor's office): a second "place" relocates the
    // existing instance instead of inserting a duplicate.
    if (selected.unique) {
      final existing = placements
          .where((p) => p.buildingTypeId == selected.id)
          .firstOrNull;
      if (existing != null) {
        if (existing.gridX == col && existing.gridY == row) return;
        if (occupant != null) {
          _toast('That spot is taken');
          return;
        }
        unawaited(
          ref.read(cityActionsProvider).moveBuilding(existing.id, col, row),
        );
        return;
      }
    }

    if (occupant != null) {
      _toast('That spot is taken');
      return;
    }
    final bricks = ref.read(activePlayerProvider).asData?.value.brickBalance;
    if (bricks == null || selected.brickCost > bricks) {
      _toast('Not enough bricks for ${selected.name}');
      return;
    }
    unawaited(ref.read(cityActionsProvider).placeBuilding(selected, col, row));
    // Deselect if the player can no longer afford another one.
    if (bricks - selected.brickCost < selected.brickCost) {
      setState(() => _selected = null);
    }
  }

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

  /// Tap on a locked (available-to-research) catalog card: confirm, then spend
  /// 🔬 to unlock the type. On success the newly-researched building is
  /// auto-selected so the player can place it right away.
  Future<void> _confirmResearch(BuildingType b) async {
    final research =
        ref.read(activePlayerProvider).asData?.value.researchBalance;
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
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(activePlayerProvider);
    final cityAsync = ref.watch(activeCityProvider);
    final placementsAsync = ref.watch(placementsProvider);
    final catalogAsync = ref.watch(cityCatalogProvider);

    final player = playerAsync.asData?.value;

    // Build the game once the grid size is known, then keep its render model
    // in sync with the latest placements.
    final city = cityAsync.asData?.value;
    if (_game == null && city != null) {
      _game = IsoCityGame(
        grid: IsoGrid(cols: city.gridWidth, rows: city.gridHeight),
        onTileTapped: _onTileTapped,
      );
    }
    final placements = placementsAsync.asData?.value;
    if (_game != null && placements != null) {
      _game!.setBuildings(_viewsFor(placements));
    }

    // Auto-select the only researched building so the starter player doesn't
    // have to click the mayor's office before placing it. Once the catalog
    // grows (more researched buildings, or locked ones to research), the
    // player makes an explicit pick.
    final catalog = catalogAsync.asData?.value;
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
          : ColoredBox(
              color: const Color(0xFF9CCC65),
              child: _PinchZoomWrapper(
                game: _game!,
                child: GameWidget(game: _game!),
              ),
            ),
      bottomNavigationBar: catalogAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (catalog) => _BuildCatalogBar(
          catalog: catalog,
          selected: _selected,
          brickBalance: player?.brickBalance ?? 0,
          researchBalance: player?.researchBalance ?? 0,
          onSelect: (b) => setState(() => _selected = b),
          onResearch: _confirmResearch,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSpin,
        icon: const Icon(Icons.casino_rounded),
        label: const Text('Play math'),
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
