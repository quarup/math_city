import 'package:flutter_test/flutter_test.dart';
import 'package:math_dash/main.dart';

void main() {
  testWidgets('app launches and shows title', (tester) async {
    await tester.pumpWidget(const MathDashApp());
    expect(find.text('Math Dash'), findsOneWidget);
  });
}
