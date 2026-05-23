import 'package:math_city/domain/city/beat_registry.dart';
import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/domain/city/trigger_rule.dart';

/// Pure-Dart engine that picks which story beats are eligible to be on the
/// player's screen given a snapshot of the player + city state.
///
/// Caller responsibilities NOT handled here:
/// - Capping on-screen bubbles at ~5 (UI layer decides which subset of the
///   eligible set to surface).
/// - Persisting bubble state (`StoryBeatState` writes happen on dismissal /
///   re-fire in the data layer).
class BeatEngine {
  const BeatEngine();

  /// Returns every beat whose [TriggerRule] is satisfied by the current
  /// state. The caller passes per-beat context via [contextFor]; this lets
  /// the engine handle beat-specific spacing (`bricksEarnedSinceBeatLastFired`)
  /// without needing the full beat-state map here.
  List<StoryBeat> eligibleBeats({
    required TriggerContext Function(StoryBeat beat) contextFor,
  }) {
    return beatRegistry
        .where((b) => b.triggerRule.evaluate(contextFor(b)))
        .toList();
  }
}
