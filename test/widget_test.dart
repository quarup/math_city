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
    await tester.pump(); // let FutureProvider resolve

    // HomeScreen always shows the title.
    expect(find.text('Math City'), findsOneWidget);
    // With no players, the empty-state prompt is shown.
    expect(find.text('Create Player'), findsOneWidget);
  });
}
