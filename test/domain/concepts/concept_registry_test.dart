import 'package:flutter_test/flutter_test.dart';
import 'package:math_dash/domain/concepts/concept_registry.dart';

void main() {
  group('ConceptRegistry', () {
    test('allConcepts contains both Phase 1 concepts', () {
      final ids = allConcepts.map((c) => c.id).toList();
      expect(ids, containsAll(['add_1digit', 'sub_1digit']));
      expect(allConcepts, hasLength(2));
    });

    test('findConceptById returns the correct concept', () {
      expect(findConceptById('add_1digit'), same(add1Digit));
      expect(findConceptById('sub_1digit'), same(sub1Digit));
    });

    test('findConceptById returns null for unknown id', () {
      expect(findConceptById('unknown'), isNull);
      expect(findConceptById(''), isNull);
    });
  });
}
