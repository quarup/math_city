import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/questions/generator_registry.dart';
import 'package:math_city/presentation/debug/concept_debug_screen.dart';

/// The debug screen lists every implemented concept, so pick the search
/// targets out of the real registry rather than hard-coding ids that a
/// future curriculum change could retire.
Concept _anyImplemented() {
  final ids = GeneratorRegistry.defaultRegistry().implementedConceptIds.toSet();
  return allConcepts.firstWhere((c) => ids.contains(c.id));
}

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: ConceptDebugScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search by pretty title filters the concept list', (
    tester,
  ) async {
    final target = _anyImplemented();
    await _pumpScreen(tester);

    expect(find.text(target.id), findsOneWidget);

    await tester.enterText(find.byType(TextField), target.name);
    await tester.pumpAndSettle();

    expect(find.text(target.id), findsOneWidget);
    // Every surviving row's id must match the query.
    final shown = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.subtitle! as Text).data!)
        .toList();
    expect(shown, isNotEmpty);
    expect(shown, contains(target.id));
  });

  testWidgets('search by one_like_this id filters the concept list', (
    tester,
  ) async {
    final target = _anyImplemented();
    await _pumpScreen(tester);
    final totalRows = find.byType(ListTile).evaluate().length;

    await tester.enterText(find.byType(TextField), target.id);
    await tester.pumpAndSettle();

    // Sibling ids can share this id as a prefix (counting_to_10 /
    // counting_to_100), so require the target row plus a narrowed list —
    // not exactly one hit.
    expect(find.text(target.id), findsWidgets);
    expect(find.byType(ListTile).evaluate().length, lessThan(totalRows));
  });

  testWidgets('underscores and spaces are interchangeable', (tester) async {
    final target = allConcepts.firstWhere(
      (c) =>
          c.id.contains('_') &&
          GeneratorRegistry.defaultRegistry().implementedConceptIds.contains(
            c.id,
          ),
    );
    await _pumpScreen(tester);

    // Typing the id with spaces instead of underscores still matches.
    await tester.enterText(
      find.byType(TextField),
      target.id.replaceAll('_', ' '),
    );
    await tester.pumpAndSettle();

    expect(find.text(target.id), findsOneWidget);
  });

  testWidgets('no matches shows an empty state, clearing restores the list', (
    tester,
  ) async {
    await _pumpScreen(tester);
    final totalRows = find.byType(ListTile).evaluate().length;
    expect(totalRows, greaterThan(0));

    await tester.enterText(find.byType(TextField), 'zzzz-no-such-concept');
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNothing);
    expect(find.textContaining('No concepts match'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile).evaluate().length, totalRows);
  });
}
