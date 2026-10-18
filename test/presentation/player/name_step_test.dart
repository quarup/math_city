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
    var typed = false;
    await pump(
      tester,
      NameStep(
        avatar: const AdventurerConfig(),
        onNext: (n) => chosen = n,
        onType: () => typed = true,
      ),
    );
    expect(tester.takeException(), isNull);
    final first = shownNames(tester);
    expect(first.length, 5);
    expect(find.text('Mayor ?'), findsOneWidget);
    final gate = find.widgetWithText(FilledButton, 'Choose a name');
    expect(tester.widget<FilledButton>(gate).onPressed, isNull);

    await tester.tap(find.text(first.first));
    await tester.pumpAndSettle();
    expect(find.text('Mayor ${first.first}'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(FilledButton, 'Meet Mayor ${first.first}!'),
    );
    expect(chosen, first.first);

    await tester.tap(find.text('More names'));
    await tester.pumpAndSettle();
    final second = shownNames(tester);
    expect(second.length, 5);
    expect(second.intersection(first), isEmpty);
    expect(find.text('Mayor ?'), findsOneWidget);

    await tester.tap(find.text('Type my own name'));
    expect(typed, isTrue);
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
            find.widgetWithText(FilledButton, 'Type a name'),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), '  Zed ');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Meet Mayor Zed!'));
    expect(chosen, 'Zed');
  });
}
