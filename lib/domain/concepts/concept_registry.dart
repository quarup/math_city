import 'package:math_dash/domain/concepts/concept.dart';

const add1Digit = Concept(
  id: 'add_1digit',
  name: 'Single-digit addition',
  shortLabel: 'Addition',
  gradeLevel: 1,
  description: 'Adding two single-digit numbers (0–9)',
);

const sub1Digit = Concept(
  id: 'sub_1digit',
  name: 'Single-digit subtraction',
  shortLabel: 'Subtraction',
  gradeLevel: 1,
  description: 'Subtracting a single-digit number, no negatives',
);

const List<Concept> allConcepts = [add1Digit, sub1Digit];

Concept? findConceptById(String id) =>
    allConcepts.where((c) => c.id == id).firstOrNull;
