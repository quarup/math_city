import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/state/player_provider.dart';

// ---------------------------------------------------------------------------
// Total 🧱 bricks for the active player.
//
// build() mirrors the persisted balance off activePlayerProvider, so the count
// resets whenever a different player is selected and re-syncs whenever the
// player row is refetched (earning here, spending in the city).  add() bumps
// in-memory state for instant feedback, persists, then invalidates the player
// providers so the city screen — which reads brickBalance straight off
// activePlayerProvider — sees the bricks the math loop just paid out.
// ---------------------------------------------------------------------------

class TotalBricksNotifier extends Notifier<int> {
  @override
  int build() {
    // `.value` (not `asData`) so a refetch in flight keeps showing the last
    // known balance — AsyncLoading carries it over — instead of blinking to 0.
    return ref.watch(activePlayerProvider).value?.brickBalance ?? 0;
  }

  void add(int bricks) {
    state += bricks;
    final playerId = ref.read(activePlayerIdProvider);
    if (playerId != null) {
      final db = ref.read(appDatabaseProvider);
      // Increment against the persisted row rather than writing an absolute
      // total computed from a possibly-stale cached player — that's what let
      // lifetimeBricksEarned (which gates building unlocks) drift.
      unawaited(
        db.incrementPlayerBricks(playerId, bricks).then((_) {
          // Refresh the active player (city screen 🧱 balance, unlock catalog)
          // and the player list (HomeScreen chips).
          ref
            ..invalidate(activePlayerProvider)
            ..invalidate(allPlayersProvider);
        }),
      );
    }
  }
}

final NotifierProvider<TotalBricksNotifier, int> totalBricksProvider =
    NotifierProvider<TotalBricksNotifier, int>(TotalBricksNotifier.new);
