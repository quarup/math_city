import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/presentation/player/avatar_editor_step.dart';
import 'package:math_city/presentation/player/avatar_lineup_step.dart';
import 'package:math_city/presentation/player/grade_step.dart';
import 'package:math_city/presentation/player/name_step.dart';
import 'package:math_city/presentation/player/player_edit_hub.dart';
import 'package:math_city/presentation/theme/app_theme.dart';

/// Every creation screen must fit without scrolling on each of these
/// (logical pixels left after the system bars): a small Android phone,
/// an iPhone, a Pixel 7 upright and on its side, an iPad both ways.
const _sizes = <String, Size>{
  'small phone': Size(360, 616),
  'iPhone': Size(390, 763),
  'Pixel 7': Size(411, 866),
  'Pixel 7 on its side': Size(915, 363),
  'iPhone on its side': Size(844, 342),
  'iPad': Size(820, 1100),
  'iPad on its side': Size(1180, 740),
};

void main() {
  Future<void> pump(WidgetTester tester, Size size, Widget child) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  final faces = [
    for (var i = 0; i < 6; i++)
      AdventurerConfig(hairIndex: i, eyesIndex: i % 5),
  ];

  for (final MapEntry(key: label, value: size) in _sizes.entries) {
    group(label, () {
      testWidgets('lineup fits', (tester) async {
        await pump(
          tester,
          size,
          AvatarLineupStep(faces: faces, onPick: (_) {}, onMore: () {}),
        );
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel('Mayor 6'), findsOneWidget);
      });

      testWidgets('every editor tab fits', (tester) async {
        await pump(
          tester,
          size,
          AvatarEditorStep(initial: const AdventurerConfig(), onDone: (_) {}),
        );
        for (final tab in ['Skin', 'Hair', 'Eyes', 'Mouth', 'Ears']) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: tab);
        }
        // The last option of the widest tab is on screen, not clipped.
        await tester.tap(find.text('Eyes'));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Glasses 5'), findsOneWidget);
      });

      testWidgets('grade fits', (tester) async {
        await pump(
          tester,
          size,
          GradeStep(avatar: const AdventurerConfig(), onNext: (_) {}),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('8th grade'), findsOneWidget);
      });

      testWidgets('name and typing fit', (tester) async {
        await pump(
          tester,
          size,
          NameStep(avatar: const AdventurerConfig(), onNext: (_) {}),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Type my own name'), findsOneWidget);
        await pump(
          tester,
          size,
          TypeNameStep(
            avatar: const AdventurerConfig(),
            onNext: (_) {},
            onCancel: () {},
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('edit hub fits', (tester) async {
        await pump(
          tester,
          size,
          PlayerEditHub(
            player: Player(
              id: 1,
              name: 'Zed',
              gradeLevel: 2,
              lifetimeCoinsEarned: 0,
              creditBalance: 0,
              streakCount: 0,
              roundsPlayed: 0,
              guideStep: 0,
              guideHints: 0,
              avatarConfig: const AdventurerConfig().toJsonString(),
              createdAt: DateTime(2026),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Change my grade'), findsOneWidget);
      });
    });
  }
}
