import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:math_city/domain/questions/spoken_text.dart';

/// One thing to say, named so the screen can show which of its parts is
/// being spoken (the prompt, the second answer, a diagram label).
class SpeechItem {
  /// Question text: prepared for the voice by [spokenFormOf].
  SpeechItem(this.id, String display) : text = spokenFormOf(display);

  /// Prose (a story beat, a letter) said exactly as written.
  SpeechItem.plain(this.id, String text)
    : text = SpokenText(text, text, [
        SpokenToken(
          display: text,
          displayStart: 0,
          spoken: text,
          spokenStart: 0,
        ),
      ]);

  final String id;

  /// The spoken form, with the map back to the screen text.
  final SpokenText text;
}

/// What the engine is saying right now.
@immutable
class SpeechProgress {
  const SpeechProgress({
    required this.owner,
    required this.item,
    this.wordStart,
    this.wordEnd,
  });

  final Object owner;
  final SpeechItem item;

  /// Offsets into [SpeechItem.text]'s spoken string of the word being
  /// spoken, once the engine reports progress; null until it does.
  final int? wordStart;
  final int? wordEnd;

  /// The screen token being spoken, if the engine has said where it is.
  SpokenToken? get token =>
      wordStart == null ? null : item.text.tokenAt(wordStart!);
}

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

  /// Who is speaking and which word they are on; null while silent.
  /// Widgets listen to this to ring the part being read and light up the
  /// word, and to turn a speaker button into a stop button.
  final ValueNotifier<SpeechProgress?> progress = ValueNotifier(null);

  /// Who started the current utterance, if they said. A screen that is
  /// replaced by the next one is disposed only after the route transition
  /// finishes — by which time the new screen is already speaking — so a
  /// screen's "stop on dispose" must not silence someone else's speech.
  Object? _owner;

  /// The rest of the current sequence, spoken one after another as the
  /// engine reports each utterance complete.
  List<SpeechItem> _queue = const [];

  /// Bumped on every speak/stop so a late completion callback from an
  /// earlier utterance can't advance a newer queue.
  int _generation = 0;

  Future<void> _ensureInitialised() async {
    if (_initialised) return;
    await _tts.setLanguage('en-US');
    // Slightly slower than the platform default — kid voices land better
    // around ~0.45 on iOS / ~0.5 on Android. flutter_tts normalises to a
    // 0..1 range so the same number works cross-platform.
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1);
    // No cancel handler: the only cancels are our own stop() calls, which
    // clear the state themselves — and the engine reports the cancel of
    // the old utterance *after* the next one has started, so acting on it
    // would silence the wrong one.
    _tts
      ..setProgressHandler(_onProgress)
      ..setCompletionHandler(_onComplete)
      ..setErrorHandler((_) => _onSilent());
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
  Future<void> speak(String text, {Object? owner}) =>
      speakAll([SpeechItem.plain('text', text)], owner: owner);

  /// Speaks [items] one after another (a prompt, then each answer),
  /// interrupting anything in flight. [progress] names the item under way.
  Future<void> speakAll(List<SpeechItem> items, {Object? owner}) async {
    final generation = ++_generation;
    _owner = owner;
    _queue = items.where((i) => i.text.text.trim().isNotEmpty).toList();
    progress.value = null;
    if (_queue.isEmpty) return;
    try {
      await _ensureInitialised();
      await _tts.stop();
      if (generation != _generation) return;
      await _speakNext();
    } on Exception {
      // Intentional swallow — see doc above.
      _onSilent();
    }
  }

  Future<void> _speakNext() async {
    if (_queue.isEmpty) {
      progress.value = null;
      return;
    }
    final item = _queue.first;
    _queue = _queue.sublist(1);
    progress.value = SpeechProgress(owner: _owner ?? this, item: item);
    await _tts.speak(item.text.text);
  }

  void _onProgress(String text, int start, int end, String word) {
    final current = progress.value;
    // A late word from the utterance just interrupted is not ours.
    if (current == null || text != current.item.text.text) return;
    progress.value = SpeechProgress(
      owner: current.owner,
      item: current.item,
      wordStart: start,
      wordEnd: end,
    );
  }

  void _onComplete() {
    final generation = _generation;
    // The engine's completion lands on the platform thread's schedule; a
    // stop() in between must win.
    unawaited(
      Future<void>.microtask(() async {
        if (generation != _generation) return;
        try {
          await _speakNext();
        } on Exception {
          _onSilent();
        }
      }),
    );
  }

  void _onSilent() {
    _queue = const [];
    progress.value = null;
  }

  /// Whether [owner]'s item [itemId] is the one being spoken right now.
  bool isSpeaking(Object owner, String itemId) {
    final p = progress.value;
    return p != null && identical(p.owner, owner) && p.item.id == itemId;
  }

  /// Stops any in-flight utterance. Safe to call before initialisation.
  /// With [owner], stops only if [owner] started the current utterance.
  Future<void> stop({Object? owner}) async {
    if (owner != null && !identical(owner, _owner)) return;
    _generation++;
    _onSilent();
    if (!_initialised) return;
    try {
      await _tts.stop();
    } on Exception {
      // ignore
    }
  }
}
