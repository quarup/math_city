import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/avatar/mathematician_names.dart';

void main() {
  group('kMathematicianNames', () {
    test('names are unique, one word, and facts are short', () {
      final names = kMathematicianNames.map((n) => n.name).toList();
      expect(names.toSet().length, names.length);
      for (final n in kMathematicianNames) {
        expect(n.name.contains(' '), isFalse, reason: n.name);
        expect(n.name.length, lessThanOrEqualTo(20));
        expect(n.fact.split(' ').length, lessThanOrEqualTo(7), reason: n.fact);
      }
    });
  });

  group('NameDeck', () {
    test('deals the requested number of distinct names', () {
      final hand = NameDeck(random: Random(1)).next(5);
      expect(hand.length, 5);
      expect(hand.map((n) => n.name).toSet().length, 5);
    });

    test('every name comes up once before any repeats', () {
      final deck = NameDeck(random: Random(2));
      final seen = <String>[];
      for (var i = 0; i < 6; i++) {
        seen.addAll(deck.next(5).map((n) => n.name));
      }
      expect(seen.toSet().length, kMathematicianNames.length);
    });

    test('consecutive hands never share a name, across many reshuffles', () {
      for (var seed = 0; seed < 50; seed++) {
        final deck = NameDeck(random: Random(seed));
        var previous = deck.next(5).map((n) => n.name).toSet();
        for (var i = 0; i < 40; i++) {
          final hand = deck.next(5).map((n) => n.name).toSet();
          expect(hand.intersection(previous), isEmpty, reason: 'seed $seed');
          previous = hand;
        }
      }
    });

    test('seeded deck is deterministic', () {
      final a = NameDeck(random: Random(9)).next(5).map((n) => n.name);
      final b = NameDeck(random: Random(9)).next(5).map((n) => n.name);
      expect(a, b);
    });
  });
}
