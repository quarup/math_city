import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/presentation/player/grade_step.dart';
import 'package:math_city/presentation/theme/app_theme.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: child));
    await tester.pumpAndSettle();
  }

  testWidgets('a new player has no grade picked and cannot go on', (
    tester,
  ) async {
    int? chosen;
    await pump(
      tester,
      GradeStep(
        avatar: const AdventurerConfig(),
        onNext: (g) => chosen = g,
      ),
    );
    final button = find.widgetWithText(FilledButton, 'Pick your grade');
    expect(button, findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.tap(find.text('2nd grade'));
    await tester.pumpAndSettle();
    final next = find.widgetWithText(FilledButton, 'Next');
    expect(next, findsOneWidget);
    await tester.tap(next);
    expect(chosen, 2);
  });

  testWidgets('editing starts on the current grade', (tester) async {
    await pump(
      tester,
      GradeStep(
        avatar: const AdventurerConfig(),
        initial: 4,
        step: null,
        nextLabel: 'Save',
        onNext: (_) {},
      ),
    );
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
