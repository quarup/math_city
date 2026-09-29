import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/presentation/city/city_screen.dart';
import 'package:math_city/state/player_provider.dart';

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets('My City mounts and the first letter arrives', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final player = await db.createPlayer(
      name: 'Robin',
      gradeLevel: 2,
      avatarConfigJson: '{}',
    );

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.read(activePlayerIdProvider.notifier).selected = player.id;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CityScreen()),
      ),
    );
    // GameWidget runs a continuous loop, so pump fixed frames rather than
    // pumpAndSettle (which would never settle).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Robin’s city'), findsOneWidget);
    // The mayor's office is seeded on the board, so it has no catalog card.
    expect(find.text("Mayor's office"), findsNothing);
    // The wheel is reached through a site, never a free-floating button.
    expect(find.text('Play math'), findsNothing);

    // The office being there is enough for Mrs. Pomeroy to write: her
    // letter interrupts the city at rest with the kid's name and Build it!.
    for (var i = 0; i < 10 && find.text('Build it!').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Mrs. Pomeroy'), findsOneWidget);
    expect(find.text('Dear Mayor Robin,'), findsOneWidget);
    expect(find.text('Build it!'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
  });
}
