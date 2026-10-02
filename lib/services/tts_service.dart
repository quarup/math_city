import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around `flutter_tts` for reading question prompts and
/// story beats aloud. Uses the OS-native engine on each platform
/// (AVSpeechSynthesizer on iOS, TextToSpeech on Android) so we ship no
/// voice data.
///
/// The service is a Riverpod singleton (see `tts_provider.dart`). The
/// caller decides *when* to speak; the enabled/disabled toggle is
/// enforced upstream by checking `ttsEnabledProvider` before invoking
/// [speak]. This keeps the service stateless w.r.t. the player
/// preference.
class TtsService {
  TtsService();

  final FlutterTts _tts = FlutterTts();
  bool _initialised = false;

  /// Who started the current utterance, if they said. A screen that is
  /// replaced by the next one is disposed only after the route transition
  /// finishes — by which time the new screen is already speaking — so a
  /// screen's "stop on dispose" must not silence someone else's speech.
  Object? _owner;

  Future<void> _ensureInitialised() async {
    if (_initialised) return;
    await _tts.setLanguage('en-US');
    // Slightly slower than the platform default — kid voices land better
    // around ~0.45 on iOS / ~0.5 on Android. flutter_tts normalises to a
    // 0..1 range so the same number works cross-platform.
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1);
    _initialised = true;
  }

  /// Speaks [text], interrupting anything currently in flight. No-op for
  /// empty input. Failures (e.g. missing TTS engine on Android emulators
  /// without Google TTS installed) are swallowed — TTS is an accessibility
  /// affordance, not a correctness boundary, so we'd rather degrade
  /// silently than crash the question flow.
  ///
  /// Pass [owner] (typically the calling `State`) to let that owner later
  /// stop only its own utterance — see [stop].
  Future<void> speak(String text, {Object? owner}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _owner = owner;
    try {
      await _ensureInitialised();
      await _tts.stop();
      await _tts.speak(trimmed);
    } on Exception {
      // Intentional swallow — see doc above.
    }
  }

  /// Stops any in-flight utterance. Safe to call before initialisation.
  /// With [owner], stops only if [owner] started the current utterance.
  Future<void> stop({Object? owner}) async {
    if (!_initialised) return;
    if (owner != null && !identical(owner, _owner)) return;
    try {
      await _tts.stop();
    } on Exception {
      // ignore
    }
  }
}
