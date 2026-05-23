import 'package:math_city/domain/city/trigger_rule.dart';

/// Narrative tone of a beat. Tunable later (Phase 8) when the full catalog
/// is authored; v1 ships three.
enum BeatTone { silly, civic, cozy }

enum BeatKind { demand, praise, warning }

/// Pure-Dart description of a story beat. Static catalog — see
/// `beatRegistry` for the v1 set of sample beats.
class StoryBeat {
  const StoryBeat({
    required this.id,
    required this.kind,
    required this.tone,
    required this.emoji,
    required this.shortLabel,
    required this.longText,
    required this.triggerRule,
    this.cooldownAfterAckBricks = 100,
  });

  final String id;
  final BeatKind kind;
  final BeatTone tone;
  final String emoji;

  /// One- or two-word sticker label drawn next to the emoji in the bubble.
  final String shortLabel;

  /// Full sentence shown when the bubble is tapped.
  final String longText;

  final TriggerRule triggerRule;

  /// After the player dismisses the bubble, this many bricks must be earned
  /// before the beat can re-fire. Prevents the same praise beat repeating
  /// immediately on the next answered question.
  final int cooldownAfterAckBricks;
}
