import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/state/tts_provider.dart';

/// Small floating action button that toggles app-wide text-to-speech.
/// Drop into any Scaffold's `floatingActionButton:` slot — appears as a
/// volume icon (filled when on, muted when off).
///
/// Tapping flips [ttsEnabledProvider] (persisted via Drift) and stops any
/// in-flight utterance on the off transition.
class SpeechToggleButton extends ConsumerWidget {
  const SpeechToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEnabled = ref.watch(ttsEnabledProvider);
    final enabled = asyncEnabled.value ?? true;
    final theme = Theme.of(context);

    return FloatingActionButton.small(
      heroTag: 'speech_toggle',
      tooltip: enabled ? 'Mute speech' : 'Unmute speech',
      backgroundColor: enabled
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest,
      foregroundColor: enabled
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurfaceVariant,
      onPressed: asyncEnabled.isLoading
          ? null
          : () => ref.read(ttsEnabledProvider.notifier).toggle(),
      child: Icon(enabled ? Icons.volume_up : Icons.volume_off),
    );
  }
}

/// Compact icon-button variant of [SpeechToggleButton]. Use this inside
/// AppBars and small cards (e.g. beat bubbles) where a FAB would
/// dominate the layout.
class SpeechToggleIconButton extends ConsumerWidget {
  const SpeechToggleIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEnabled = ref.watch(ttsEnabledProvider);
    final enabled = asyncEnabled.value ?? true;
    return IconButton(
      tooltip: enabled ? 'Mute speech' : 'Unmute speech',
      onPressed: asyncEnabled.isLoading
          ? null
          : () => ref.read(ttsEnabledProvider.notifier).toggle(),
      icon: Icon(enabled ? Icons.volume_up : Icons.volume_off),
    );
  }
}
