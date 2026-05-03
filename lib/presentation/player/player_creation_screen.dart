import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/data/database.dart';
import 'package:math_dash/domain/avatar/avatar_config.dart';
import 'package:math_dash/presentation/player/avatar_widget.dart';
import 'package:math_dash/state/player_provider.dart';

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
  late AvatarConfig _config;
  late int _grade;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPlayer;
    _nameController = TextEditingController(text: p?.name ?? '');
    _grade = p?.gradeLevel ?? 2;
    _config = p?.avatar ?? const AvatarConfig();
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
      await db.updatePlayer(
        widget.initialPlayer!.id,
        name: name,
        gradeLevel: _grade,
        avatarConfigJson: _config.toJsonString(),
      );
      ref
        ..invalidate(allPlayersProvider)
        ..invalidate(activePlayerProvider);
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
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Player' : 'New Player'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ---- Sticky avatar preview ----
            Container(
              color: theme.colorScheme.surfaceContainerLowest,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: AvatarWidget(config: _config, size: 120)),
            ),
            const Divider(height: 1),

            // ---- Scrollable form fields ----
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
                        ...List.generate(12, (i) {
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

                    // Colour pickers
                    _colorRow(
                      'Skin',
                      kSkinTones,
                      _config.skinToneIndex,
                      (i) => setState(
                        () => _config = _config.copyWith(skinToneIndex: i),
                      ),
                    ),
                    _colorRow(
                      'Hair',
                      kHairColors,
                      _config.hairColorIndex,
                      (i) => setState(
                        () => _config = _config.copyWith(hairColorIndex: i),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 46,
                            child: Text(
                              'Style',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Short'),
                            selected: _config.hairStyleIndex == 0,
                            onSelected: (_) => setState(
                              () => _config =
                                  _config.copyWith(hairStyleIndex: 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Long'),
                            selected: _config.hairStyleIndex == 1,
                            onSelected: (_) => setState(
                              () => _config =
                                  _config.copyWith(hairStyleIndex: 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _colorRow(
                      'Eyes',
                      kEyeColors,
                      _config.eyeColorIndex,
                      (i) => setState(
                        () => _config = _config.copyWith(eyeColorIndex: i),
                      ),
                    ),
                    _colorRow(
                      'Top',
                      kTopColors,
                      _config.topColorIndex,
                      (i) => setState(
                        () => _config = _config.copyWith(topColorIndex: i),
                      ),
                    ),
                    _colorRow(
                      'Pants',
                      kBottomColors,
                      _config.bottomColorIndex,
                      (i) => setState(
                        () => _config = _config.copyWith(bottomColorIndex: i),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ---- Sticky save button at bottom ----
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: FilledButton(
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
            ),
          ],
        ),
      ),
    );
  }
}

Widget _colorRow(
  String label,
  List<Color> colors,
  int selectedIndex,
  ValueChanged<int> onSelect,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 46,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        ...List.generate(colors.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.black12,
                  width: selected ? 3 : 1,
                ),
                boxShadow: selected
                    ? [
                        const BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ],
    ),
  );
}
