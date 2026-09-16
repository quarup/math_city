import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/wheel_selection.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';

Concept _c(String id, {int grade = 0, int row = 0}) => Concept(
  id: id,
  name: id,
  shortLabel: id,
  categoryId: 'add_sub',
  primaryGrade: grade,
  prereqIds: const [],
  source: ConceptSource.algorithmic,
  diagramRequirement: const DiagramNone(),
  categoryRowOrder: row,
);

List<Concept> _many(String prefix, int n, {int grade = 0}) => [
  for (var i = 0; i < n; i++) _c('$prefix$i', grade: grade, row: i),
];

Set<String> _ids(Iterable<Concept> cs) => cs.map((c) => c.id).toSet();

void main() {
  group('wheelTierFor', () {
    test('challenging and comfortable are frontier', () {
      expect(
        wheelTierFor(band: ProficiencyBand.challenging, retired: false),
        WheelTier.frontier,
      );
      expect(
        wheelTierFor(band: ProficiencyBand.comfortable, retired: false),
        WheelTier.frontier,
      );
    });

    test('mastered is review unless retired', () {
      expect(
        wheelTierFor(band: ProficiencyBand.mastered, retired: false),
        WheelTier.review,
      );
      expect(
        wheelTierFor(band: ProficiencyBand.mastered, retired: true),
        WheelTier.off,
      );
    });

    test('notYet and anything retired are off', () {
      expect(
        wheelTierFor(band: ProficiencyBand.notYet, retired: false),
        WheelTier.off,
      );
      expect(
        wheelTierFor(band: ProficiencyBand.comfortable, retired: true),
        WheelTier.off,
      );
    });
  });

  group('selectWheelConcepts', () {
    final frontier12 = _many('f', 12);
    final review5 = _many('r', 5, grade: 1);

    test('fills 8 segments with exactly kReviewSlots review concepts', () {
      for (var seed = 0; seed < 20; seed++) {
        final wheel = selectWheelConcepts(
          frontier: frontier12,
          review: review5,
          previous: const {},
          random: Random(seed),
        );
        expect(wheel, hasLength(kWheelSegments));
        expect(
          wheel.where((c) => _ids(review5).contains(c.id)).length,
          kReviewSlots,
        );
      }
    });

    test('with no review concepts the wheel is all frontier', () {
      final wheel = selectWheelConcepts(
        frontier: frontier12,
        review: const [],
        previous: const {},
        random: Random(1),
      );
      expect(wheel, hasLength(kWheelSegments));
      expect(_ids(wheel).difference(_ids(frontier12)), isEmpty);
    });

    test('review fills in when the frontier is short', () {
      final wheel = selectWheelConcepts(
        frontier: _many('f', 3),
        review: _many('r', 10, grade: 1),
        previous: const {},
        random: Random(2),
      );
      expect(wheel, hasLength(kWheelSegments));
      expect(wheel.where((c) => c.id.startsWith('f')).length, 3);
      expect(wheel.where((c) => c.id.startsWith('r')).length, 5);
    });

    test('frontier fills in when review is short', () {
      final wheel = selectWheelConcepts(
        frontier: frontier12,
        review: _many('r', 1, grade: 1),
        previous: const {},
        random: Random(3),
      );
      expect(wheel, hasLength(kWheelSegments));
      expect(wheel.where((c) => c.id.startsWith('r')).length, 1);
    });

    test('returns everything when both tiers together are short', () {
      final wheel = selectWheelConcepts(
        frontier: _many('f', 3),
        review: _many('r', 1, grade: 1),
        previous: const {},
        random: Random(4),
      );
      expect(_ids(wheel), {'f0', 'f1', 'f2', 'r0'});
    });

    test('returns nothing when both tiers are empty', () {
      expect(
        selectWheelConcepts(
          frontier: const [],
          review: const [],
          previous: const {},
          random: Random(5),
        ),
        isEmpty,
      );
    });

    test('at least kMinRotation segments differ from the previous wheel', () {
      var previous = _ids(
        selectWheelConcepts(
          frontier: frontier12,
          review: review5,
          previous: const {},
          random: Random(6),
        ),
      );
      for (var seed = 0; seed < 50; seed++) {
        final next = _ids(
          selectWheelConcepts(
            frontier: frontier12,
            review: review5,
            previous: previous,
            random: Random(seed),
          ),
        );
        expect(next, hasLength(kWheelSegments));
        expect(
          next.difference(previous).length,
          greaterThanOrEqualTo(kMinRotation),
          reason: 'seed $seed rotated too little',
        );
        previous = next;
      }
    });

    test('rotation uses every unseen candidate when fewer than the quota', () {
      // 9 frontier, 8 of them shown last time: the one unseen concept must
      // always come in, and the wheel is still full.
      final frontier9 = _many('f', 9);
      final previous = _ids(frontier9.take(8));
      for (var seed = 0; seed < 20; seed++) {
        final wheel = selectWheelConcepts(
          frontier: frontier9,
          review: const [],
          previous: previous,
          random: Random(seed),
        );
        expect(wheel, hasLength(kWheelSegments));
        expect(_ids(wheel), contains('f8'));
      }
    });

    test('review takes the leftover rotation quota when frontier cannot', () {
      // Frontier has no unseen concepts; review has plenty, so the rotation
      // quota is met from the review tier alone (both slots fresh).
      final frontier6 = _many('f', 6);
      final review10 = _many('r', 10, grade: 1);
      final previous = {..._ids(frontier6), 'r0', 'r1'};
      for (var seed = 0; seed < 20; seed++) {
        final wheel = selectWheelConcepts(
          frontier: frontier6,
          review: review10,
          previous: previous,
          random: Random(seed),
        );
        final reviewPicked = wheel.where((c) => c.id.startsWith('r'));
        expect(reviewPicked, hasLength(kReviewSlots));
        expect(
          reviewPicked.where((c) => !previous.contains(c.id)),
          hasLength(kReviewSlots),
        );
      }
    });

    test('output is sorted by difficulty and deterministic per seed', () {
      final a = selectWheelConcepts(
        frontier: frontier12,
        review: review5,
        previous: const {},
        random: Random(7),
      );
      final b = selectWheelConcepts(
        frontier: frontier12,
        review: review5,
        previous: const {},
        random: Random(7),
      );
      expect(a.map((c) => c.id), b.map((c) => c.id));
      // Frontier concepts are grade 0, review grade 1: every frontier pick
      // precedes every review pick once sorted by difficulty.
      final firstReview = a.indexWhere((c) => c.primaryGrade == 1);
      expect(a.skip(firstReview).every((c) => c.primaryGrade == 1), isTrue);
    });
  });
}
