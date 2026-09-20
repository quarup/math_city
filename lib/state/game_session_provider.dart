import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/construction_sites.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/state/city_provider.dart';

// ---------------------------------------------------------------------------
// The active construction site — where this session's coins go.
//
// There is no wallet (city_builder.md §8.3): every coin a block earns is paid
// into the site the player is zoomed into. The city screen sets this when the
// player taps a site's "Build!"; the proficiency notifier pays into it on each
// correct answer; the spin / question / summary screens show its `paid / price`
// bar in place of the old coin counter. Session-only state — the site rows
// themselves persist.
// ---------------------------------------------------------------------------

class ActiveSiteIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  int? get selected => state;
  set selected(int? siteId) => state = siteId;
}

final activeSiteIdProvider = NotifierProvider<ActiveSiteIdNotifier, int?>(
  ActiveSiteIdNotifier.new,
);

/// The active site with its current paid-in state, or null when none is
/// selected or it has opened (its row is gone).
final activeSiteProvider = FutureProvider<CitySite?>((ref) async {
  final id = ref.watch(activeSiteIdProvider);
  if (id == null) return null;
  final sites = await ref.watch(sitesProvider.future);
  return sites.where((s) => s.id == id).firstOrNull;
});

// ---------------------------------------------------------------------------
// How the last block ended — handed from the question route chain back to
// the city screen underneath it.
//
// The chain (question → red screen → … → summary) replaces its own route, so
// the city can't await a single push result. Instead the chain publishes the
// finished block here right before popping to the city, and the city (a
// `RouteAware`) reads it when the route above it goes away: re-show the
// wheel (*Spin again*), celebrate an opened site, or zoom back out.
// ---------------------------------------------------------------------------

class BlockResult {
  const BlockResult({required this.block, required this.spinAgain});

  final QuestionBlock block;

  /// True for *Spin again*; false for *Back to city* and for a block that
  /// opened its site (the celebration takes over).
  final bool spinAgain;
}

class LastBlockResultNotifier extends Notifier<BlockResult?> {
  @override
  BlockResult? build() => null;

  BlockResult? get pending => state;
  set pending(BlockResult? result) => state = result;

  /// Returns the pending result (if any) and clears it.
  BlockResult? take() {
    final r = state;
    state = null;
    return r;
  }
}

final lastBlockResultProvider =
    NotifierProvider<LastBlockResultNotifier, BlockResult?>(
      LastBlockResultNotifier.new,
    );
