import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/state/tts_provider.dart';

/// A front page of the Math City Times (city_builder.md §10.2): how
/// milestones and the two balance warnings reach the player. Masthead,
/// kicker, headline, one spoken line, one button. Rare by design.
class TimesOverlay extends ConsumerWidget {
  const TimesOverlay({
    required this.beat,
    required this.cityName,
    required this.onClose,
    super.key,
  });

  final StoryBeat beat;

  /// "Sam's city" — printed as the dateline.
  final String cityName;
  final VoidCallback onClose;

  /// What the voice reads: the kicker, then the story.
  String get spokenText => '${beat.shortLabel}. ${beat.longText}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const paper = Color(0xFFF7F1E3);
    const ink = Color(0xFF1F1B16);
    final isWarning = beat.kind == BeatKind.warning;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Material(
                color: paper,
                elevation: 12,
                borderRadius: BorderRadius.circular(6),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'THE MATH CITY TIMES',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Divider(color: ink, thickness: 2, height: 2),
                      const Divider(color: ink, thickness: 0.8, height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cityName.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: ink,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              isWarning ? 'CITY DESK' : 'FRONT PAGE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: ink,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: ink, thickness: 0.8, height: 8),
                      const SizedBox(height: 10),
                      Text(
                        '${beat.emoji}  ${beat.shortLabel.toUpperCase()}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isWarning
                              ? const Color(0xFFB3261E)
                              : const Color(0xFF2F6FA8),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        beat.longText,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Read it again',
                            onPressed: () =>
                                unawaited(speakIfEnabled(ref, spokenText)),
                            icon: const Icon(Icons.volume_up_rounded),
                            color: ink,
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: onClose,
                            style: FilledButton.styleFrom(
                              backgroundColor: ink,
                              foregroundColor: paper,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              textStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Text(isWarning ? 'On it' : 'Hooray!'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
