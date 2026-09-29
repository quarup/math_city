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
    this.cooldownAfterAckCoins = 600,
    this.citizen,
    this.scripted = false,
  });

  final String id;
  final BeatKind kind;
  final BeatTone tone;
  final String emoji;

  /// One- or two-word label: the "wants a …" line of the letter header and
  /// the text of a pedestrian bubble.
  final String shortLabel;

  /// Full sentence: the body of the letter, spoken aloud when it opens.
  final String longText;

  final TriggerRule triggerRule;

  /// After the player dismisses the bubble, this many coins (≈ seconds of
  /// study) must be earned before the beat can re-fire. Prevents the same
  /// praise beat repeating immediately on the next answered question.
  final int cooldownAfterAckCoins;

  /// Who signs this beat's letter — a `castRegistry` id (city_builder.md
  /// §10.8), or null to let `citizenForBeat` pick the citizen who owns the
  /// building the beat is about.
  final String? citizen;

  /// A beat the engine never fires on its own — the chapter-one script
  /// (city_builder.md §10.4) fires it at the right moment.
  final bool scripted;
}
