import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/services/tts_service.dart';
import 'package:math_city/state/player_provider.dart';

/// Singleton TTS service. The service itself is stateless w.r.t. the
/// enabled flag — callers gate on [ttsEnabledProvider] before invoking
/// `speak`.
final ttsServiceProvider = Provider<TtsService>((_) => TtsService());

/// App-wide text-to-speech preference, persisted via Drift. Defaults to
/// `true` (on by default — kids who can't yet read benefit immediately;
/// we revisit if quality is poor).
class TtsEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final db = ref.watch(appDatabaseProvider);
    return db.getTtsEnabled();
  }

  Future<void> toggle() async {
    final current = state.value ?? true;
    final next = !current;
    state = AsyncData(next);
    final db = ref.read(appDatabaseProvider);
    await db.setTtsEnabled(next);
    // If we just turned TTS off, silence anything still being spoken.
    if (!next) {
      await ref.read(ttsServiceProvider).stop();
    }
  }
}

final ttsEnabledProvider = AsyncNotifierProvider<TtsEnabledNotifier, bool>(
  TtsEnabledNotifier.new,
);

/// Convenience: speaks [text] if (and only if) TTS is currently enabled.
/// No-op while the preference is still loading (first build of the
/// notifier) so the very first frame after launch can't trigger an
/// out-of-order utterance.
Future<void> speakIfEnabled(WidgetRef ref, String text) async {
  final enabled = ref.read(ttsEnabledProvider).value ?? false;
  if (!enabled) return;
  await ref.read(ttsServiceProvider).speak(text);
}
