import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/beat_registry.dart';
import 'package:math_city/domain/city/chapter_one.dart';
import 'package:math_city/domain/city/citizen.dart';
import 'package:math_city/domain/city/placement_rules.dart';

void main() {
  group('chapterOneStepFor', () {
    test('advances past every scripted building already standing', () {
      expect(chapterOneStepFor(0, const {'mayors_office'}), 0);
      expect(chapterOneStepFor(0, const {'single_home'}), kMoveStep);
      // The move step waits for an actual move, whatever else stands.
      expect(chapterOneStepFor(0, const {'single_home', 'school'}), kMoveStep);
      expect(
        chapterOneStepFor(kMoveStep + 1, const {
          'single_home',
          'school',
          'park',
        }),
        kHandoverStep,
      );
    });

    test('a later building alone does not skip an earlier step', () {
      expect(chapterOneStepFor(0, const {'school', 'park'}), 0);
    });

    test('never runs past the hand-over step', () {
      expect(
        chapterOneStepFor(kHandoverStep, const {
          'single_home',
          'school',
          'park',
        }),
        kHandoverStep,
      );
    });
  });

  test('every scripted letter exists and the hand-over is engine-proof', () {
    for (final id in chapterOneLetters) {
      expect(findBeatById(id), isNotNull, reason: id);
    }
    final handover = findBeatById(kHandoverBeatId)!;
    expect(handover.scripted, isTrue);
    expect(citizenForBeat(handover).id, kTownCitizenId);
  });

  test('guide hint bits are distinct', () {
    final bits = GuideHint.values.map((h) => h.bit).toSet();
    expect(bits.length, GuideHint.values.length);
    expect(GuideHint.fling.seenIn(GuideHint.placeHere.bit), isFalse);
    expect(GuideHint.fling.seenIn(GuideHint.fling.bit), isTrue);
  });

  group('proposePlacement', () {
    // A 6×6 lot with the 2×2 office at (2,2).
    final owned = {
      for (var c = 0; c < 6; c++)
        for (var r = 0; r < 6; r++) (c, r),
    };
    const office = GridFootprint(col: 2, row: 2, width: 2, height: 2);

    test('leaves a road-wide gap from the office and stays close', () {
      final spot = proposePlacement(
        ownedTiles: owned,
        existing: const [office],
        width: 1,
        height: 1,
        anchor: (2, 2),
      )!;
      // Not touching the office (Chebyshev gap ≥ 1): the office covers
      // 2..3, its fringe 1..4, so the spot sits on the lot's edge ring.
      for (final t in spot.tiles()) {
        expect(t.$1 == 0 || t.$1 == 5 || t.$2 == 0 || t.$2 == 5, isTrue);
        expect(owned, contains(t));
      }
    });

    test('falls back to a touching spot when nothing else fits', () {
      // A 4×4 lot: the office fills the middle, only touching tiles remain.
      final tiny = {
        for (var c = 0; c < 4; c++)
          for (var r = 0; r < 4; r++) (c, r),
      };
      const mid = GridFootprint(col: 1, row: 1, width: 2, height: 2);
      final spot = proposePlacement(
        ownedTiles: tiny,
        existing: const [mid],
        width: 1,
        height: 1,
        anchor: (1, 1),
      );
      expect(spot, isNotNull);
    });

    test('null when the lot is full', () {
      final one = {(0, 0)};
      const full = GridFootprint(col: 0, row: 0, width: 1, height: 1);
      expect(
        proposePlacement(
          ownedTiles: one,
          existing: const [full],
          width: 1,
          height: 1,
          anchor: (0, 0),
        ),
        isNull,
      );
    });

    test('is deterministic', () {
      GridFootprint? go() => proposePlacement(
        ownedTiles: owned,
        existing: const [office],
        width: 2,
        height: 2,
        anchor: (2, 2),
      );
      final a = go()!;
      final b = go()!;
      expect((a.col, a.row), (b.col, b.row));
    });
  });
}
