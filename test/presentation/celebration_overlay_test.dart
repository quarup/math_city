import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/presentation/city/celebration_overlay.dart';
import 'package:math_city/presentation/theme/app_theme.dart';

void main() {
  testWidgets('shows the title, the block stats and a Done button', (
    tester,
  ) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CelebrationOverlay(
            title: 'Single home is finished!',
            coins: 48,
            streak: 10,
            onDone: () => done = true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('It’s open!'), findsOneWidget);
    expect(find.text('Single home is finished!'), findsOneWidget);
    expect(find.text('+48'), findsOneWidget);
    expect(find.byType(ConfettiRain), findsOneWidget);

    await tester.tap(find.text('Done'));
    expect(done, isTrue);
    // The confetti loops; advance a few frames without error.
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
