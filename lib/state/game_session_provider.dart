import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/construction_sites.dart';
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
