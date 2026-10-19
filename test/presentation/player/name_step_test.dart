import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/domain/avatar/mathematician_names.dart';
import 'package:math_city/presentation/player/name_step.dart';
import 'package:math_city/presentation/theme/app_theme.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  Set<String> shownNames(WidgetTester tester) {
    final all = kMathematicianNames.map((n) => n.name).toSet();
    return {
      for (final t in tester.widgetList<Text>(find.byType(Text)))
        if (t.data != null && all.contains(t.data)) t.data!,
    };
  }

  testWidgets('shows five names, gates the button, and reshuffles', (
    tester,
  ) async {
    String? chosen;
    await pump(
      tester,
      NameStep(avatar: const AdventurerConfig(), onNext: (n) => chosen = n),
    );
    expect(tester.takeException(), isNull);
    final first = shownNames(tester);
    expect(first.length, 5);
    // No badge until a name is chosen.
    expect(find.textContaining('Mayor '), findsNothing);
    final gate = find.widgetWithText(FilledButton, 'Choose a name');
    expect(tester.widget<FilledButton>(gate).onPressed, isNull);

    await tester.tap(find.text(first.first));
    await tester.pumpAndSettle();
    expect(find.text('Mayor ${first.first}'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Build my city!'));
    expect(chosen, first.first);

    await tester.tap(find.text('More names'));
    await tester.pumpAndSettle();
    final second = shownNames(tester);
    expect(second.length, 5);
    expect(second.intersection(first), isEmpty);
    expect(find.textContaining('Mayor '), findsNothing);
  });

  testWidgets('a typed name comes back chosen on the own-name button', (
    tester,
  ) async {
    await pump(
      tester,
      NameStep(avatar: const AdventurerConfig(), onNext: (_) {}),
    );
    await tester.tap(find.text('Type my own name'));
    await tester.pumpAndSettle();
    expect(find.text('Type your name'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Zed');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Use name'));
    await tester.pumpAndSettle();

    // Back on the list: badge filled, button shows the name, no save yet.
    expect(find.text('Your name'), findsOneWidget);
    expect(find.text('Mayor Zed'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Zed'), findsOneWidget);
    expect(find.text('Type my own name'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Build my city!'), findsOneWidget);

    // A mathematician replaces it; the button goes back to its label.
    final names = shownNames(tester);
    await tester.tap(find.text(names.first));
    await tester.pumpAndSettle();
    expect(find.text('Mayor ${names.first}'), findsOneWidget);
    expect(find.text('Type my own name'), findsOneWidget);
  });

  testWidgets('typing screen gates on a non-blank name', (tester) async {
    String? chosen;
    await pump(
      tester,
      TypeNameStep(
        avatar: const AdventurerConfig(),
        onNext: (n) => chosen = n,
        onCancel: () {},
      ),
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Use name'),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), '  Zed ');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Use name'));
    expect(chosen, 'Zed');
  });
}
