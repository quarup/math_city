import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/presentation/widgets/site_progress_bar.dart';

void main() {
  testWidgets('the compact bar fits in an AppBar action next to a title', (
    tester,
  ) async {
    // AppBar actions get unbounded width; the bar must size itself to its
    // text (a bare LinearProgressIndicator would throw and blank the bar).
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Add within 5'),
            actions: const [
              SiteProgressBar(paid: 18, price: 60, compact: true),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Add within 5'), findsOneWidget);
    expect(find.text('18 / 60'), findsOneWidget);
    final size = tester.getSize(find.byType(SiteProgressBar));
    expect(size.width, lessThan(200));
  });

  testWidgets('the full bar shows the name and paid / price', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SiteProgressBar(paid: 0, price: 120, name: 'Apartment'),
        ),
      ),
    );
    expect(find.text('Apartment'), findsOneWidget);
    expect(find.text('0 / 120'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
