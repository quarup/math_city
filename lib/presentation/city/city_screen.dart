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
    final occupied = placements.any((p) => p.gridX == col && p.gridY == row);
    if (occupied) {
      _toast('That spot is taken');
      return;
    }
    final bricks = ref.read(activePlayerProvider).asData?.value.brickBalance;
    if (bricks == null || selected.brickCost > bricks) {
      _toast('Not enough 🧱 for ${selected.name}');
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
    final theme = Theme.of(context);
    final playerAsync = ref.watch(activePlayerProvider);
    final cityAsync = ref.watch(activeCityProvider);
    final placementsAsync = ref.watch(placementsProvider);
    final catalogAsync = ref.watch(researchedBuildingsProvider);

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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  '🧱 ${player.brickBalance}   🔬 ${player.researchBalance}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
        ],
      ),
      body: _game == null
          ? const Center(child: CircularProgressIndicator())
          : ColoredBox(
              color: const Color(0xFF9CCC65),
              child: GameWidget(game: _game!),
            ),
      bottomNavigationBar: catalogAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (catalog) => _BuildCatalogBar(
          catalog: catalog,
          selected: _selected,
          brickBalance: player?.brickBalance ?? 0,
          onSelect: (b) => setState(() => _selected = b),
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

/// Horizontal catalog of researched buildings. Tap to select for placement;
/// unaffordable types are greyed and unselectable.
class _BuildCatalogBar extends StatelessWidget {
  const _BuildCatalogBar({
    required this.catalog,
    required this.selected,
    required this.brickBalance,
    required this.onSelect,
  });

  final List<BuildingType> catalog;
  final BuildingType? selected;
  final int brickBalance;
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
                    final b = catalog[i];
                    return _CatalogCard(
                      building: b,
                      isSelected: b.id == selected?.id,
                      affordable: b.brickCost <= brickBalance,
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
    required this.affordable,
    required this.color,
    required this.onTap,
  });

  final BuildingType building;
  final bool isSelected;
  final bool affordable;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: affordable ? 1 : 0.4,
      child: GestureDetector(
        onTap: affordable ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 88,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(building.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  building.name,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                building.brickCost == 0 ? 'Free' : '🧱 ${building.brickCost}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
