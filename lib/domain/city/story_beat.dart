import 'package:math_city/domain/city/trigger_rule.dart';

/// Narrative tone of a beat. Tunable later (Phase 8) when the full catalog
/// is authored; v1 ships three.
enum BeatTone { silly, civic, cozy }

enum BeatKind { demand, praise, warning }

/// How a beat reaches the player (city_builder.md §10.2): a letter that
/// interrupts, a speech bubble over a passing pedestrian, or a front page
/// of the Math City Times. Demands are letters; warnings and milestones
/// are front pages; praise is a *reply* letter when it answers the
/// building that just opened and a bubble when the engine fires it later.
enum BeatDelivery { letter, bubble, times }

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
    this.delivery,
    this.oneShot = false,
    this.event,
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

  /// Explicit delivery for the static part of the decision (a milestone
  /// praise beat that belongs on a front page; a capacity demand — water,
  /// trash, hospital — that reads as news). Null = by kind: demands and
  /// praise as letters, warnings as the Times. A demand on a front page
  /// keeps a demand's behaviour: Build it! / Later, a badged card, and it
  /// clears when the building is placed.
  final BeatDelivery? delivery;

  /// Fires at most once per player, ever (milestones): the engine skips it
  /// once it has fired, whatever its trigger says afterwards.
  final bool oneShot;

  /// The event this beat asks for (a demand) or celebrates (its reply),
  /// e.g. `kBlockPartyId`. Build it! starts the event site at the town's
  /// public space instead of placing a building.
  final String? event;

  /// The static delivery: [delivery] if set, else warnings go to the Times
  /// and everything else is a letter. The engine turns a praise letter
  /// into a bubble at fire time (see `openBeatsProvider`).
  BeatDelivery get staticDelivery =>
      delivery ??
      (kind == BeatKind.warning ? BeatDelivery.times : BeatDelivery.letter);
}
