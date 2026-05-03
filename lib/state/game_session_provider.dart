import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/state/player_provider.dart';

// ---------------------------------------------------------------------------
// Total stars for the active player.
//
// build() watches activePlayerProvider so the count resets whenever a
// different player is selected.  add() increments in-memory state and
// persists asynchronously using the active player's ID.
// ---------------------------------------------------------------------------

class TotalStarsNotifier extends Notifier<int> {
  @override
  int build() {
    final playerAsync = ref.watch(activePlayerProvider);
    return playerAsync.asData?.value.totalStars ?? 0;
  }

  void add(int stars) {
    state += stars;
    final playerId = ref.read(activePlayerIdProvider);
    if (playerId != null) {
      final db = ref.read(appDatabaseProvider);
      unawaited(
        db.updatePlayerStars(playerId, state).then((_) {
          // Invalidate so the player chips on HomeScreen show the new total.
          ref.invalidate(allPlayersProvider);
        }),
      );
    }
  }
}

final NotifierProvider<TotalStarsNotifier, int> totalStarsProvider =
    NotifierProvider<TotalStarsNotifier, int>(TotalStarsNotifier.new);
