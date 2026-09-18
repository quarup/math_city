import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/game/spin_wheel/concept_icons.dart';

void main() {
  test('tierForGrade maps K–2, 3–5, 6–8 to the three ladder rungs', () {
    expect([0, 1, 2].map(tierForGrade), everyElement(0));
    expect([3, 4, 5].map(tierForGrade), everyElement(1));
    expect([6, 7, 8].map(tierForGrade), everyElement(2));
  });

  test('every registered category has a ladder that paints at every tier', () {
    final categories = allConcepts.map((c) => c.categoryId).toSet();
    expect(categories, isNotEmpty);
    for (final cat in categories) {
      for (var tier = 0; tier < 3; tier++) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        paintConceptIcon(canvas, cat, tier, accent: Colors.orange);
        recorder.endRecording().dispose();
      }
    }
  });

  test('unknown categories fall back rather than throw', () {
    final recorder = ui.PictureRecorder();
    paintConceptIcon(Canvas(recorder), 'nope', 1, accent: Colors.orange);
    recorder.endRecording().dispose();
  });
}
