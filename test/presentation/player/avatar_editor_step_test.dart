import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/presentation/player/avatar_editor_step.dart';
import 'package:math_city/presentation/theme/app_theme.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: child));
    await tester.pumpAndSettle();
  }

  testWidgets('Next walks the tabs; Done on the last one returns the face', (
    tester,
  ) async {
    AdventurerConfig? done;
    await pump(
      tester,
      AvatarEditorStep(
        initial: const AdventurerConfig(hairIndex: 2),
        onDone: (c) => done = c,
      ),
    );
    expect(find.text('Tone'), findsOneWidget);
    for (final label in ['Color', 'Glasses']) {
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget, reason: 'after Next: $label');
    }
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Done'), findsOneWidget);
    expect(done, isNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    expect(done, const AdventurerConfig(hairIndex: 2));
  });

  testWidgets('blush and freckles are one choice', (tester) async {
    AdventurerConfig? done;
    await pump(
      tester,
      AvatarEditorStep(
        initial: const AdventurerConfig(blush: true),
        onDone: (c) => done = c,
      ),
    );
    await tester.tap(find.bySemanticsLabel('Freckles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ears'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    expect(done!.freckles, isTrue);
    expect(done!.blush, isFalse);
  });

  testWidgets('long hair replaces the earring grid with a note', (
    tester,
  ) async {
    await pump(
      tester,
      AvatarEditorStep(
        // long01: hangs over the ears.
        initial: const AdventurerConfig(hairIndex: 4),
        onDone: (_) {},
      ),
    );
    await tester.tap(find.text('Ears'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Earrings 1'), findsNothing);
    expect(find.text('Pick a shorter style'), findsOneWidget);
    await tester.tap(find.text('Pick a shorter style'));
    await tester.pumpAndSettle();
    expect(find.text('Color'), findsOneWidget);
  });
}
