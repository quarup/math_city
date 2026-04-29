import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_dash/state/game_session_provider.dart';

void main() {
  group('TotalStarsNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('starts at zero', () {
      expect(container.read(totalStarsProvider), 0);
    });

    test('add increments the total', () {
      container.read(totalStarsProvider.notifier).add(3);
      expect(container.read(totalStarsProvider), 3);
    });

    test('multiple adds accumulate', () {
      container.read(totalStarsProvider.notifier).add(3);
      container.read(totalStarsProvider.notifier).add(5);
      container.read(totalStarsProvider.notifier).add(1);
      expect(container.read(totalStarsProvider), 9);
    });
  });
}
