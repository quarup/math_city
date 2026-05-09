import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/avatar/adventurer_catalog.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';

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

  group('AdventurerConfig.random', () {
    test('every slot index stays within its catalog range', () {
      final r = Random(7);
      for (var i = 0; i < 200; i++) {
        final c = AdventurerConfig.random(random: r);
        expect(c.hairIndex, inInclusiveRange(0, kHairStyles.length - 1));
        expect(c.hairColorIndex, inInclusiveRange(0, kHairColors.length - 1));
        expect(c.skinColorIndex, inInclusiveRange(0, kSkinColors.length - 1));
        expect(c.eyesIndex, inInclusiveRange(0, kEyeVariants.length - 1));
        expect(c.mouthIndex, inInclusiveRange(0, kMouthVariants.length - 1));
        expect(
          c.glassesIndex,
          inInclusiveRange(0, kGlassesOptions.length - 1),
        );
        expect(
          c.earringsIndex,
          inInclusiveRange(0, kEarringsOptions.length - 1),
        );
      }
    });

    test('seeded random is deterministic', () {
      final a = AdventurerConfig.random(random: Random(42));
      final b = AdventurerConfig.random(random: Random(42));
      expect(a, equals(b));
    });

    test('produces variety across calls (not stuck on default)', () {
      final r = Random(1);
      final samples = {
        for (var i = 0; i < 50; i++) AdventurerConfig.random(random: r),
      };
      // 50 uniformly-random configs should yield far more than 1 distinct
      // value — collisions on all 9 slots are astronomically unlikely.
      expect(
        samples.length,
        greaterThan(20),
        reason: 'random factory should not collapse to a single config',
      );
      // None of them should match the all-zero default.
      const defaultConfig = AdventurerConfig();
      expect(
        samples.where((c) => c == defaultConfig).length,
        lessThan(2),
      );
    });

    test('round-trips through JSON', () {
      final c = AdventurerConfig.random(random: Random(99));
      expect(AdventurerConfig.fromJsonString(c.toJsonString()), equals(c));
    });
  });
}
