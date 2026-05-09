import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

String _formatTime(int hour, int minute) {
  final mm = minute.toString().padLeft(2, '0');
  return '$hour:$mm';
}

/// Tell time on the hour or half-hour. Diagram = analog clock.
GeneratedQuestion timeToHourHalf(Random rand) {
  final hour = rand.nextInt(12) + 1; // 1..12
  final minute = rand.nextBool() ? 0 : 30;
  final correct = _formatTime(hour, minute);
  // Pool of plausible alt-times for distractors.
  final pool = <String>[
    _formatTime((hour % 12) + 1, minute), // hour off by 1
    _formatTime(hour == 1 ? 12 : hour - 1, minute), // other hour off
    _formatTime(hour, minute == 0 ? 30 : 0), // swapped half/whole
    _formatTime((hour % 12) + 1, minute == 0 ? 30 : 0),
  ];
  return GeneratedQuestion(
    conceptId: 'time_to_hour_half',
    prompt: 'What time is it?',
    diagram: ClockSpec(hour: hour, minute: minute),
    correctAnswer: correct,
    distractors: stringDistractorsFromPool(correct, pool, rand),
    explanation: [
      if (minute == 0)
        "The minute hand points at 12 — that means o'clock."
      else
        'The minute hand points at 6 — that means half past.',
      'The hour hand is at $hour, so the time is $correct.',
    ],
  );
}

/// Tell time to 5-minute increments.
GeneratedQuestion timeTo5Min(Random rand) {
  final hour = rand.nextInt(12) + 1; // 1..12
  final minute = rand.nextInt(12) * 5; // 0, 5, 10, ..., 55
  final correct = _formatTime(hour, minute);
  final altMinutes = <int>{
    (minute + 5) % 60,
    (minute + 55) % 60,
    (minute + 30) % 60,
    (minute + 10) % 60,
  }..remove(minute);
  final pool = <String>[
    for (final m in altMinutes) _formatTime(hour, m),
    _formatTime((hour % 12) + 1, minute),
    _formatTime(hour == 1 ? 12 : hour - 1, minute),
  ];
  return GeneratedQuestion(
    conceptId: 'time_to_5_min',
    prompt: 'What time is it?',
    diagram: ClockSpec(hour: hour, minute: minute),
    correctAnswer: correct,
    distractors: stringDistractorsFromPool(correct, pool, rand),
    explanation: [
      'Count by 5s around the clock to find the minutes.',
      'The minute hand is at ${minute ~/ 5} ($minute minutes).',
      'The hour hand is past $hour, so the time is $correct.',
    ],
  );
}
