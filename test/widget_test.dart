import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_dash/app.dart';

void main() {
  testWidgets('app launches and shows title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MathDashApp()),
    );
    expect(find.text('Math Dash'), findsOneWidget);
  });
}
