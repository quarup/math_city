import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/state/player_provider.dart';

// ---------------------------------------------------------------------------
// Total 🧱 bricks for the active player.
//
// build() watches activePlayerProvider so the count resets whenever a
// different player is selected.  add() increments in-memory state and
// persists asynchronously using the active player's ID.
// ---------------------------------------------------------------------------

class TotalBricksNotifier extends Notifier<int> {
  @override
  int build() {
    final playerAsync = ref.watch(activePlayerProvider);
    return playerAsync.asData?.value.brickBalance ?? 0;
  }

  void add(int bricks) {
    state += bricks;
    final playerId = ref.read(activePlayerIdProvider);
    if (playerId != null) {
      final db = ref.read(appDatabaseProvider);
      final player = ref.read(activePlayerProvider).asData?.value;
      final lifetime = (player?.lifetimeBricksEarned ?? 0) + bricks;
      unawaited(
        db
            .updatePlayerBricks(
              playerId,
              brickBalance: state,
              lifetimeBricksEarned: lifetime,
            )
            .then((_) {
              // Invalidate so HomeScreen player chips show the new total.
              ref.invalidate(allPlayersProvider);
            }),
      );
    }
  }
}

final NotifierProvider<TotalBricksNotifier, int> totalBricksProvider =
    NotifierProvider<TotalBricksNotifier, int>(TotalBricksNotifier.new);
