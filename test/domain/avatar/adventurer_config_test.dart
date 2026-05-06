import 'package:flutter_test/flutter_test.dart';
import 'package:math_dash/domain/avatar/adventurer_config.dart';

void main() {
  group('AdventurerConfig serialization', () {
    test('round-trips default config', () {
      const config = AdventurerConfig();
      final json = config.toJsonString();
      expect(AdventurerConfig.fromJsonString(json), equals(config));
    });

    test('round-trips non-default config', () {
      const config = AdventurerConfig(
        hairIndex: 3,
        hairColorIndex: 2,
        skinColorIndex: 1,
        eyesIndex: 4,
        mouthIndex: 2,
        glassesIndex: 1,
        earringsIndex: 3,
        blush: true,
        freckles: true,
      );
      final json = config.toJsonString();
      expect(AdventurerConfig.fromJsonString(json), equals(config));
    });

    test('fromJsonString with empty object uses defaults', () {
      final config = AdventurerConfig.fromJsonString('{}');
      expect(config, equals(const AdventurerConfig()));
    });

    test('copyWith preserves unchanged fields', () {
      const base = AdventurerConfig(hairIndex: 2, blush: true);
      final copy = base.copyWith(skinColorIndex: 3);
      expect(copy.hairIndex, 2);
      expect(copy.blush, true);
      expect(copy.skinColorIndex, 3);
    });
  });
}
