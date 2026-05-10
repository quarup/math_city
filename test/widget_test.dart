import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/app.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/state/player_provider.dart';

void main() {
  testWidgets('app launches and shows home screen', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MathCityApp(),
      ),
    );
    // Splash holds for 1500ms then runs a 700ms transition to HomeScreen.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // With no players, the empty-state Create Player button is shown.
    expect(find.text('Create Player'), findsOneWidget);
  });
}
