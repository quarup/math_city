import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/presentation/player/avatar_editor_step.dart';
import 'package:math_city/presentation/player/avatar_thumb.dart';
import 'package:math_city/presentation/player/grade_step.dart';
import 'package:math_city/presentation/player/name_step.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';
import 'package:math_city/state/player_provider.dart';
import 'package:math_city/state/proficiency_provider.dart';

/// Editing an existing player: three doors, one per thing to change,
/// each opening the same screen the creation flow uses. The grade door
/// asks first, because changing grade restarts the lessons (see GitHub
/// issue #132 for keeping mastery across a change).
class PlayerEditHub extends ConsumerStatefulWidget {
  const PlayerEditHub({required this.player, super.key});

  final Player player;

  @override
  ConsumerState<PlayerEditHub> createState() => _PlayerEditHubState();
}

class _PlayerEditHubState extends ConsumerState<PlayerEditHub> {
  late Player _player = widget.player;

  AppDatabase get _db => ref.read(appDatabaseProvider);

  Future<void> _reload() async {
    final fresh = await _db.getPlayerById(_player.id);
    ref
      ..invalidate(allPlayersProvider)
      ..invalidate(activePlayerProvider);
    if (mounted) setState(() => _player = fresh);
  }

  Future<void> _push(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  Future<void> _editLook() async {
    await _push(
      AvatarEditorStep(
        initial: _player.avatar,
        step: null,
        doneLabel: 'Save',
        onBack: () => Navigator.of(context).pop(),
        onDone: (config) async {
          await _db.updatePlayer(
            _player.id,
            avatarConfigJson: config.toJsonString(),
          );
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
    await _reload();
  }

  Future<void> _editName() async {
    Future<void> save(String name) async {
      await _db.updatePlayer(_player.id, name: name);
      if (mounted) Navigator.of(context).pop();
    }

    await _push(
      _NameEditor(
        avatar: _player.avatar,
        initial: _player.name,
        onSave: save,
      ),
    );
    await _reload();
  }

  Future<void> _editGrade() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changing grade starts your lessons over'),
        content: const Text(
          'Your city, coins and buildings stay. Only the questions reset '
          'to the new grade. Ask a grown-up first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Keep ${_gradeName(_player.gradeLevel)}'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).extension<AppPalette>()!.brandTealDeep,
            ),
            child: const Text('Change it'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    await _push(
      GradeStep(
        avatar: _player.avatar,
        initial: _player.gradeLevel,
        step: null,
        nextLabel: 'Save',
        onBack: () => Navigator.of(context).pop(),
        onNext: (grade) async {
          if (grade != _player.gradeLevel) {
            await _db.updatePlayer(_player.id, gradeLevel: grade);
            // Per PRD: changing grade is a "recalibrate" action — wipe skill
            // state so the wheel re-bootstraps a starter pack at the new
            // grade. Coins and the city carry over.
            await _db.resetSkillsForPlayer(_player.id);
            ref
              ..invalidate(proficiencyProvider)
              ..invalidate(introducedConceptsProvider);
          }
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
    await _reload();
  }

  static String _gradeName(int grade) =>
      kGradeRows.firstWhere((r) => r.grade == grade).name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        title: Text('Mayor ${_player.name}'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: theme.colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: AvatarThumb(config: _player.avatar, size: 150),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Door(
                    title: 'Change my look',
                    subtitle: 'Hair, eyes, glasses and more',
                    onTap: _editLook,
                  ),
                  const SizedBox(height: 10),
                  _Door(
                    title: 'Change my name',
                    subtitle: 'The town will use the new one',
                    onTap: _editName,
                  ),
                  const SizedBox(height: 10),
                  _Door(
                    title: 'Change my grade',
                    subtitle:
                        '${_gradeName(_player.gradeLevel)} · '
                        'restarts your lessons',
                    onTap: _editGrade,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SizedBox(
                height: 56,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    foregroundColor: palette.brandTealDeep,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The name screen and its typing screen, as one route that swaps
/// between them, so *Cancel* on the keyboard screen returns to the list.
class _NameEditor extends StatefulWidget {
  const _NameEditor({
    required this.avatar,
    required this.initial,
    required this.onSave,
  });

  final AdventurerConfig avatar;
  final String initial;
  final ValueChanged<String> onSave;

  @override
  State<_NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<_NameEditor> {
  bool _typing = false;

  @override
  Widget build(BuildContext context) {
    String save(String _) => 'Save';
    if (_typing) {
      return TypeNameStep(
        avatar: widget.avatar,
        initial: widget.initial,
        step: null,
        doneLabel: save,
        onCancel: () => setState(() => _typing = false),
        onNext: widget.onSave,
      );
    }
    return NameStep(
      avatar: widget.avatar,
      step: null,
      doneLabel: save,
      onBack: () => Navigator.of(context).pop(),
      onType: () => setState(() => _typing = true),
      onNext: widget.onSave,
    );
  }
}

class _Door extends StatelessWidget {
  const _Door({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.surfaceContainerHigh,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
