import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/dataset_question.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';
import 'package:math_city/domain/questions/question_source.dart';

void main() {
  GeneratedQuestion stubGenerated(String conceptId) => GeneratedQuestion(
    conceptId: conceptId,
    prompt: 'GEN $conceptId',
    correctAnswer: 'GEN',
    distractors: const ['a', 'b', 'c'],
    explanation: const ['from generator'],
  );

  DatasetQuestion stubDataset(String conceptId, int n) => DatasetQuestion(
    id: '${conceptId}_$n',
    conceptId: conceptId,
    prompt: 'DS $conceptId #$n',
    correctAnswer: 'DS',
    distractors: const ['x', 'y', 'z'],
    explanation: const ['from dataset'],
    source: 'test',
    sourceModule: 'unit_test',
    license: 'MIT',
  );

  GeneratorRegistry registryFor(Iterable<String> ids) =>
      GeneratorRegistry.fromMap({
        for (final id in ids) id: (_) => stubGenerated(id),
      });

  group('isImplemented / implementedConceptIds', () {
    test('union of registry + dataset keys', () {
      final source = QuestionSource(
        registry: registryFor(const ['gen_only', 'both']),
        datasetByConcept: {
          'both': [stubDataset('both', 0)],
          'ds_only': [stubDataset('ds_only', 0)],
        },
      );
      expect(source.isImplemented('gen_only'), isTrue);
      expect(source.isImplemented('both'), isTrue);
      expect(source.isImplemented('ds_only'), isTrue);
      expect(source.isImplemented('nope'), isFalse);
      expect(
        source.implementedConceptIds.toSet(),
        {'gen_only', 'both', 'ds_only'},
      );
    });
  });

  group('generate — only one side available', () {
    test('generator-only concept always uses the generator', () {
      final source = QuestionSource(
        registry: registryFor(const ['gen_only']),
        datasetByConcept: const {},
      );
      for (var i = 0; i < 50; i++) {
        final q = source.generate('gen_only', random: Random(i));
        expect(q.prompt, 'GEN gen_only');
      }
    });

    test('dataset-only concept always uses the dataset', () {
      final pool = [
        stubDataset('ds_only', 0),
        stubDataset('ds_only', 1),
        stubDataset('ds_only', 2),
      ];
      final source = QuestionSource(
        registry: registryFor(const []),
        datasetByConcept: {'ds_only': pool},
      );
      for (var i = 0; i < 50; i++) {
        final q = source.generate('ds_only', random: Random(i));
        expect(q.prompt, startsWith('DS ds_only'));
      }
    });

    test(
      'empty dataset pool with a registered generator falls back to generator',
      () {
        final source = QuestionSource(
          registry: registryFor(const ['gen_only']),
          datasetByConcept: const {'gen_only': []},
        );
        final q = source.generate('gen_only', random: Random(0));
        expect(q.prompt, 'GEN gen_only');
      },
    );

    test('unknown concept throws (matches GeneratorRegistry contract)', () {
      final source = QuestionSource(
        registry: registryFor(const []),
        datasetByConcept: const {},
      );
      expect(() => source.generate('mystery'), throwsArgumentError);
    });
  });

  group('generate — weighted mix policy', () {
    // Empirically count dataset hits over many seeds for a given pool size.
    double observedDatasetShare(int poolSize, {int trials = 4000}) {
      final pool = List.generate(poolSize, (i) => stubDataset('both', i));
      final source = QuestionSource(
        registry: registryFor(const ['both']),
        datasetByConcept: {'both': pool},
      );
      var datasetHits = 0;
      for (var i = 0; i < trials; i++) {
        final q = source.generate('both', random: Random(i));
        if (q.prompt.startsWith('DS ')) datasetHits++;
      }
      return datasetHits / trials;
    }

    test('pool at saturation hits ~50% dataset', () {
      final share = observedDatasetShare(QuestionSource.poolSaturationSize);
      expect(share, closeTo(0.5, 0.05));
    });

    test('pool above saturation still caps at ~50%', () {
      final share = observedDatasetShare(100);
      expect(share, closeTo(0.5, 0.05));
    });

    test('small pool yields proportionally smaller dataset share', () {
      // pool=5, saturation=50 → expected dataset share 0.5 * 5/50 = 0.05
      final share = observedDatasetShare(5);
      expect(share, closeTo(0.05, 0.02));
    });

    test('singleton pool yields a thin dataset share', () {
      // pool=1, saturation=50 → expected 0.5 * 1/50 = 0.01
      final share = observedDatasetShare(1);
      expect(share, closeTo(0.01, 0.01));
    });
  });

  group('dataset → GeneratedQuestion conversion', () {
    test('carries through prompt / answer / distractors / explanation', () {
      final source = QuestionSource(
        registry: registryFor(const []),
        datasetByConcept: {
          'ds_only': [stubDataset('ds_only', 0)],
        },
      );
      final q = source.generate('ds_only', random: Random(0));
      expect(q.conceptId, 'ds_only');
      expect(q.prompt, 'DS ds_only #0');
      expect(q.correctAnswer, 'DS');
      expect(q.distractors, const ['x', 'y', 'z']);
      expect(q.explanation, const ['from dataset']);
    });

    test('falls back to one-liner when explanation is empty', () {
      const empty = DatasetQuestion(
        id: 'empty',
        conceptId: 'ds_only',
        prompt: 'P',
        correctAnswer: '42',
        distractors: ['1', '2', '3'],
        explanation: [],
        source: 'test',
        sourceModule: 'unit_test',
        license: 'MIT',
      );
      final source = QuestionSource(
        registry: registryFor(const []),
        datasetByConcept: const {
          'ds_only': [empty],
        },
      );
      final q = source.generate('ds_only', random: Random(0));
      expect(q.explanation, ['The correct answer is 42.']);
    });
  });
}
