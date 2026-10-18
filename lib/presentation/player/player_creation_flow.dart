import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/presentation/city/city_screen.dart';
import 'package:math_city/presentation/player/avatar_editor_step.dart';
import 'package:math_city/presentation/player/avatar_lineup_step.dart';
import 'package:math_city/presentation/player/grade_step.dart';
import 'package:math_city/presentation/player/name_step.dart';
import 'package:math_city/state/player_provider.dart';

enum _Step { lineup, look, grade, name, typeName }

/// Creating a new player, one question per screen: pick a face from a
/// lineup and tune it, say your school grade, choose a name. The avatar
/// is first because it is the fun part and needs no typing; the grade
/// sits in the middle, on its own, where it cannot be skimmed past; the
/// name comes last so the flow ends on "Meet Mayor Euler!" and walks
/// straight into the city.
class PlayerCreationFlow extends ConsumerStatefulWidget {
  const PlayerCreationFlow({super.key});

  @override
  ConsumerState<PlayerCreationFlow> createState() => _PlayerCreationFlowState();
}

class _PlayerCreationFlowState extends ConsumerState<PlayerCreationFlow> {
  static const _lineupSize = 6;

  _Step _step = _Step.lineup;
  List<AdventurerConfig> _faces = _newFaces();
  AdventurerConfig _config = const AdventurerConfig();
  int? _grade;
  bool _saving = false;

  static List<AdventurerConfig> _newFaces() => [
    for (var i = 0; i < _lineupSize; i++) AdventurerConfig.random(),
  ];

  void _go(_Step step) => setState(() => _step = step);

  /// System back: one step back, until the lineup, which pops the route.
  void _back() {
    switch (_step) {
      case _Step.lineup:
        Navigator.of(context).pop();
      case _Step.look:
        _go(_Step.lineup);
      case _Step.grade:
        _go(_Step.look);
      case _Step.name:
        _go(_Step.grade);
      case _Step.typeName:
        _go(_Step.name);
    }
  }

  Future<void> _create(String name) async {
    if (_saving) return;
    setState(() => _saving = true);
    final db = ref.read(appDatabaseProvider);
    final player = await db.createPlayer(
      name: name,
      gradeLevel: _grade!,
      avatarConfigJson: _config.toJsonString(),
    );
    ref.read(activePlayerIdProvider.notifier).selected = player.id;
    ref.invalidate(allPlayersProvider);
    if (!mounted) return;
    // pushReplacement so back from the city lands on home, not here.
    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: CityScreen.routeName),
          builder: (_) => const CityScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = switch (_step) {
      _Step.lineup => AvatarLineupStep(
        key: const ValueKey('lineup'),
        faces: _faces,
        onBack: _back,
        onMore: () => setState(() => _faces = _newFaces()),
        onPick: (face) {
          _config = face;
          _go(_Step.look);
        },
      ),
      _Step.look => AvatarEditorStep(
        key: const ValueKey('look'),
        initial: _config,
        onBack: _back,
        onDone: (config) {
          _config = config;
          _go(_Step.grade);
        },
      ),
      _Step.grade => GradeStep(
        key: const ValueKey('grade'),
        avatar: _config,
        initial: _grade,
        onBack: _back,
        onNext: (grade) {
          _grade = grade;
          _go(_Step.name);
        },
      ),
      _Step.name => NameStep(
        key: const ValueKey('name'),
        avatar: _config,
        onBack: _back,
        onType: () => _go(_Step.typeName),
        onNext: _create,
      ),
      _Step.typeName => TypeNameStep(
        key: const ValueKey('typeName'),
        avatar: _config,
        onCancel: _back,
        onNext: _create,
      ),
    };
    return PopScope(
      canPop: _step == _Step.lineup,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: screen,
      ),
    );
  }
}
