import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/database.dart';

// ---------------------------------------------------------------------------
// Database provider — overridden in main() with the real AppDatabase instance.
// ---------------------------------------------------------------------------

final appDatabaseProvider = Provider<AppDatabase>(
  (_) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

// ---------------------------------------------------------------------------
// Active player — the player currently in the session.
// null = no player selected (shows launcher / profile picker).
// ---------------------------------------------------------------------------

class ActivePlayerIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  int? get selected => state;
  set selected(int? id) => state = id;
}

final activePlayerIdProvider = NotifierProvider<ActivePlayerIdNotifier, int?>(
  ActivePlayerIdNotifier.new,
);

// ---------------------------------------------------------------------------
// All players — queried once; invalidate after create/delete.
// ---------------------------------------------------------------------------

final allPlayersProvider = FutureProvider<List<Player>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.getAllPlayers();
});

// ---------------------------------------------------------------------------
// Active player data — rebuilds when activePlayerIdProvider changes.
// Throws (→ AsyncError) when no player is selected; only read in game screens.
// ---------------------------------------------------------------------------

final activePlayerProvider = FutureProvider<Player>((ref) async {
  final id = ref.watch(activePlayerIdProvider);
  if (id == null) throw StateError('No active player');
  final db = ref.read(appDatabaseProvider);
  return db.getPlayerById(id);
});
