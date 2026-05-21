import 'package:math_city/domain/questions/generated_question.dart';

/// One bundled question sourced from a third-party math dataset (DeepMind,
/// GSM8K, etc.). Persisted to the Drift `dataset_questions` table at app
/// first-run; consumed at runtime by `QuestionSource` to mix with output
/// from algorithmic generators.
///
/// Pure value type — no Flutter, Drift, or platform imports. The Drift
/// adapter lives in `lib/data/database.dart`.
class DatasetQuestion {
  const DatasetQuestion({
    required this.id,
    required this.conceptId,
    required this.prompt,
    required this.correctAnswer,
    required this.distractors,
    required this.explanation,
    required this.source,
    required this.sourceModule,
    required this.license,
    this.answerFormat = AnswerFormat.integer,
  });

  factory DatasetQuestion.fromJson(Map<String, dynamic> j) => DatasetQuestion(
    id: j['id'] as String,
    conceptId: j['concept_id'] as String,
    prompt: j['prompt'] as String,
    correctAnswer: j['correct_answer'] as String,
    distractors: (j['distractors'] as List<dynamic>).cast<String>(),
    explanation:
        (j['explanation'] as List<dynamic>?)?.cast<String>() ?? const [],
    source: j['source'] as String,
    sourceModule: (j['source_module'] as String?) ?? '',
    license: j['license'] as String,
    answerFormat: _parseAnswerFormat(j['answer_format'] as String?),
  );

  final String id;
  final String conceptId;
  final String prompt;
  final String correctAnswer;
  final List<String> distractors;
  final List<String> explanation;
  final String source;
  final String sourceModule;
  final String license;

  /// How the runtime should compare the player's input against
  /// [correctAnswer]. Most dataset items are plain integer answers so
  /// `AnswerFormat.integer` is the default; ingesters override per-item
  /// when DeepMind / GSM8K / etc. supply a different shape (e.g.
  /// `commaList` for `comparison.sort`).
  final AnswerFormat answerFormat;
}

AnswerFormat _parseAnswerFormat(String? raw) {
  switch (raw) {
    case null:
    case '':
    case 'integer':
      return AnswerFormat.integer;
    case 'fraction':
      return AnswerFormat.fraction;
    case 'mixedNumber':
    case 'mixed_number':
      return AnswerFormat.mixedNumber;
    case 'decimal':
      return AnswerFormat.decimal;
    case 'commaList':
    case 'comma_list':
      return AnswerFormat.commaList;
    case 'string':
      return AnswerFormat.string;
    default:
      throw ArgumentError('Unknown answer_format: "$raw"');
  }
}

/// Inverse of [_parseAnswerFormat]. Used by the Drift adapter to persist
/// the format alongside the prompt / answer.
String answerFormatToString(AnswerFormat f) {
  switch (f) {
    case AnswerFormat.integer:
      return 'integer';
    case AnswerFormat.fraction:
      return 'fraction';
    case AnswerFormat.mixedNumber:
      return 'mixedNumber';
    case AnswerFormat.decimal:
      return 'decimal';
    case AnswerFormat.commaList:
      return 'commaList';
    case AnswerFormat.string:
      return 'string';
  }
}

AnswerFormat answerFormatFromString(String s) => _parseAnswerFormat(s);
