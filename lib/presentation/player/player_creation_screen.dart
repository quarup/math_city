import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/avatar/adventurer_catalog.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';
import 'package:math_city/state/player_provider.dart';
import 'package:math_city/state/proficiency_provider.dart';

/// Pass [initialPlayer] to edit an existing player; null = create a new one.
class PlayerCreationScreen extends ConsumerStatefulWidget {
  const PlayerCreationScreen({this.initialPlayer, super.key});

  final Player? initialPlayer;

  bool get isEdit => initialPlayer != null;

  @override
  ConsumerState<PlayerCreationScreen> createState() =>
      _PlayerCreationScreenState();
}

class _PlayerCreationScreenState extends ConsumerState<PlayerCreationScreen> {
  late final TextEditingController _nameController;
  late AdventurerConfig _config;
  late int _grade;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPlayer;
    _nameController = TextEditingController(text: p?.name ?? '');
    _grade = p?.gradeLevel ?? 2;
    // New players get a randomly-rolled avatar; the editor below lets them
    // tweak it.
    _config = p?.avatar ?? AdventurerConfig.random();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);

    final db = ref.read(appDatabaseProvider);

    if (widget.isEdit) {
      final gradeChanged = widget.initialPlayer!.gradeLevel != _grade;
      await db.updatePlayer(
        widget.initialPlayer!.id,
        name: name,
        gradeLevel: _grade,
        avatarConfigJson: _config.toJsonString(),
      );
      if (gradeChanged) {
        // Per PRD: changing grade is a "recalibrate" action — wipe skill
        // state so the wheel re-bootstraps a starter pack at the new
        // grade. Stars carry over.
        await db.resetSkillsForPlayer(widget.initialPlayer!.id);
      }
      ref
        ..invalidate(allPlayersProvider)
        ..invalidate(activePlayerProvider);
      if (gradeChanged) {
        ref
          ..invalidate(proficiencyProvider)
          ..invalidate(introducedConceptsProvider);
      }
    } else {
      final player = await db.createPlayer(
        name: name,
        gradeLevel: _grade,
        avatarConfigJson: _config.toJsonString(),
      );
      ref.read(activePlayerIdProvider.notifier).selected = player.id;
      ref.invalidate(allPlayersProvider);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameOk = _nameController.text.trim().isNotEmpty;
    final isEdit = widget.isEdit;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Player' : 'New Player'),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // ---- Sticky avatar preview ----
              Container(
                color: theme.colorScheme.surfaceContainerLowest,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: AdventurerAvatarWidget(config: _config, size: 120),
                ),
              ),
              const Divider(height: 1),

              // ---- Scrollable form ----
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name
                      TextField(
                        controller: _nameController,
                        autofocus: !isEdit,
                        textCapitalization: TextCapitalization.words,
                        maxLength: 20,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // Grade
                      Text('Grade', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('K'),
                            selected: _grade == 0,
                            onSelected: (_) => setState(() => _grade = 0),
                          ),
                          ...List.generate(8, (i) {
                            final g = i + 1;
                            return ChoiceChip(
                              label: Text('$g'),
                              selected: _grade == g,
                              onSelected: (_) => setState(() => _grade = g),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Skin color
                      _sectionLabel('Skin', theme),
                      _colorSwatches(
                        count: kSkinColors.length,
                        swatch: skinColorSwatch,
                        selectedIndex: _config.skinColorIndex,
                        onSelect: (i) => setState(
                          () => _config = _config.copyWith(skinColorIndex: i),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Hair style
                      _sectionLabel('Hair Style', theme),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: List.generate(kHairStyles.length, (i) {
                          return ChoiceChip(
                            label: Text(kHairStyleLabels[i]),
                            selected: _config.hairIndex == i,
                            onSelected: (_) => setState(
                              () => _config = _config.copyWith(hairIndex: i),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),

                      // Hair color
                      _sectionLabel('Hair Color', theme),
                      _colorSwatches(
                        count: kHairColors.length,
                        swatch: hairColorSwatch,
                        selectedIndex: _config.hairColorIndex,
                        onSelect: (i) => setState(
                          () => _config = _config.copyWith(hairColorIndex: i),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Eyes
                      _sectionLabel('Eyes', theme),
                      Wrap(
                        spacing: 8,
                        children: List.generate(kEyeVariants.length, (i) {
                          return ChoiceChip(
                            label: Text('${i + 1}'),
                            selected: _config.eyesIndex == i,
                            onSelected: (_) => setState(
                              () => _config = _config.copyWith(eyesIndex: i),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Mouth
                      _sectionLabel('Mouth', theme),
                      Wrap(
                        spacing: 8,
                        children: List.generate(kMouthVariants.length, (i) {
                          return ChoiceChip(
                            label: Text('${i + 1}'),
                            selected: _config.mouthIndex == i,
                            onSelected: (_) => setState(
                              () => _config = _config.copyWith(mouthIndex: i),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Glasses
                      _sectionLabel('Glasses', theme),
                      Wrap(
                        spacing: 8,
                        children: List.generate(kGlassesOptions.length, (i) {
                          return ChoiceChip(
                            label: Text(i == 0 ? 'None' : '$i'),
                            selected: _config.glassesIndex == i,
                            onSelected: (_) => setState(
                              () => _config = _config.copyWith(glassesIndex: i),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Earrings
                      _sectionLabel('Earrings', theme),
                      Wrap(
                        spacing: 8,
                        children: List.generate(kEarringsOptions.length, (i) {
                          return ChoiceChip(
                            label: Text(i == 0 ? 'None' : '$i'),
                            selected: _config.earringsIndex == i,
                            onSelected: (_) => setState(
                              () =>
                                  _config = _config.copyWith(earringsIndex: i),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),

                      // Blush + Freckles
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Blush'),
                        value: _config.blush,
                        onChanged: (v) => setState(
                          () => _config = _config.copyWith(blush: v),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Freckles'),
                        value: _config.freckles,
                        onChanged: (v) => setState(
                          () => _config = _config.copyWith(freckles: v),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ---- Save button at end of form ----
                      FilledButton(
                        onPressed: nameOk && !_saving ? _save : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          textStyle: theme.textTheme.titleLarge,
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isEdit ? 'Save' : 'Create!'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _sectionLabel(String label, ThemeData theme) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: theme.textTheme.labelLarge),
  );
}

Widget _colorSwatches({
  required int count,
  required Color Function(int) swatch,
  required int selectedIndex,
  required ValueChanged<int> onSelect,
}) {
  return Wrap(
    spacing: 8,
    children: List.generate(count, (i) {
      final selected = i == selectedIndex;
      return GestureDetector(
        onTap: () => onSelect(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: swatch(i),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.white : Colors.black12,
              width: selected ? 3 : 1,
            ),
            boxShadow: selected
                ? [const BoxShadow(color: Color(0x55000000), blurRadius: 6)]
                : null,
          ),
        ),
      );
    }),
  );
}
