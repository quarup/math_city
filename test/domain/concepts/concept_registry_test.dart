import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_category.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

void main() {
  group('Concept catalog invariants', () {
    test('all concept IDs are unique', () {
      final ids = allConcepts.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every prereq references a concept in the catalog', () {
      final ids = allConcepts.map((c) => c.id).toSet();
      for (final c in allConcepts) {
        for (final p in c.prereqIds) {
          expect(
            ids,
            contains(p),
            reason:
                'concept "${c.id}" lists missing prereq "$p" — drop the '
                'prereq or seed the prereq concept into the catalog',
          );
        }
      }
    });

    test('every prereq has a smaller (or equal) grade than its dependent', () {
      final byId = {for (final c in allConcepts) c.id: c};
      for (final c in allConcepts) {
        for (final pId in c.prereqIds) {
          final p = byId[pId]!;
          expect(
            p.primaryGrade,
            lessThanOrEqualTo(c.primaryGrade),
            reason:
                'prereq "${p.id}" (grade ${p.primaryGrade}) is harder than '
                'dependent "${c.id}" (grade ${c.primaryGrade})',
          );
        }
      }
    });

    test('every concept belongs to a known category', () {
      final categoryIds = allCategories.map((c) => c.id).toSet();
      for (final c in allConcepts) {
        expect(
          categoryIds,
          contains(c.categoryId),
          reason: 'concept "${c.id}" → unknown category "${c.categoryId}"',
        );
      }
    });

    test('every concept has a non-negative grade', () {
      for (final c in allConcepts) {
        expect(c.primaryGrade, greaterThanOrEqualTo(0));
      }
    });

    test('findConceptById returns null for unknown id', () {
      expect(findConceptById('does_not_exist'), isNull);
      expect(findConceptById(''), isNull);
    });

    test('findConceptById returns the catalog instance', () {
      for (final c in allConcepts) {
        expect(findConceptById(c.id), same(c));
      }
    });

    test('every category referenced by a concept resolves', () {
      for (final c in allConcepts) {
        expect(findCategoryById(c.categoryId), isNotNull);
      }
    });
  });

  group('compareConceptDifficulty', () {
    test('lower grade compares before higher grade', () {
      final a = _testConcept(grade: 1, row: 99);
      final b = _testConcept(grade: 2, row: 0);
      expect(compareConceptDifficulty(a, b), lessThan(0));
    });

    test('within the same grade, lower row order wins', () {
      final a = _testConcept(grade: 2, row: 1);
      final b = _testConcept(grade: 2, row: 5);
      expect(compareConceptDifficulty(a, b), lessThan(0));
    });

    test('equal concepts compare equal', () {
      final a = _testConcept(grade: 2, row: 1);
      final b = _testConcept(grade: 2, row: 1);
      expect(compareConceptDifficulty(a, b), 0);
    });
  });

  group('Generator registry coverage', () {
    test('every implemented concept has an entry in the catalog', () {
      final registry = GeneratorRegistry.defaultRegistry();
      final catalogIds = allConcepts.map((c) => c.id).toSet();
      for (final id in registry.implementedConceptIds) {
        expect(
          catalogIds,
          contains(id),
          reason:
              'registry has generator for "$id" but catalog has no row '
              'for it — drift between Phase 5 generator list and concept '
              'catalog',
        );
      }
    });
  });
}

Concept _testConcept({required int grade, required int row}) => Concept(
  id: 'test_grade${grade}_row$row',
  name: 'test',
  shortLabel: 'test',
  categoryId: 'add_sub',
  primaryGrade: grade,
  prereqIds: const [],
  source: ConceptSource.algorithmic,
  diagramRequirement: const DiagramNone(),
  categoryRowOrder: row,
);
