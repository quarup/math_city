import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/presentation/city/letter_overlay.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_city/state/tts_provider.dart';

/// A front page of the Math City Times (city_builder.md §10.2): how
/// milestones, the two balance warnings and the capacity asks (water,
/// trash, hospital, …) reach the player. Masthead, kicker, headline, a
/// black-and-white photo, one spoken line, and the buttons: *Hooray!* /
/// *On it* for news, *Later* / *Build it!* for an ask. Rare by design.
///
/// The photo is the story's: the building asked for (its sprite, as an
/// artist's impression) when [target] is set, else the [photo] of the
/// city taken as the page came out, with the mayor's face inset when
/// [mayor] is set. No photo at all when neither is available.
class TimesOverlay extends ConsumerWidget {
  const TimesOverlay({
    required this.beat,
    required this.cityName,
    required this.onClose,
    this.target,
    this.onBuild,
    this.photo,
    this.mayor,
    super.key,
  });

  final StoryBeat beat;

  /// "Sam's city" — printed as the dateline.
  final String cityName;

  /// *Hooray!* / *On it* on a news page; *Later* on an ask. The page is
  /// gone either way; the caller decides whether the beat retires.
  final VoidCallback onClose;

  /// The building an ask is about; its sprite is the page's photo.
  final BuildingType? target;

  /// *Build it!* on an ask. Null when the building can't be started right
  /// now (not in the catalog yet), in which case only *Later* shows.
  final VoidCallback? onBuild;

  /// Snapshot of the city for a news page. The caller owns the image.
  final ui.Image? photo;

  /// The mayor, inset on a milestone's photo.
  final AdventurerConfig? mayor;

  /// What the voice reads: the kicker, then the story.
  String get spokenText => '${beat.shortLabel}. ${beat.longText}';

  bool get _isAsk => beat.kind == BeatKind.demand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const paper = Color(0xFFF7F1E3);
    const ink = Color(0xFF1F1B16);
    // Bad news and asks run on the city desk in red; milestones are the
    // front page in blue.
    final badNews = beat.kind == BeatKind.warning || _isAsk;

    final photoPanel = _NewsPhoto(
      target: target,
      photo: photo,
      mayor: mayor,
      cityName: cityName,
      ink: ink,
      paper: paper,
    );

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
                              badNews ? 'CITY DESK' : 'FRONT PAGE',
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
                          color: badNews
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
                      if (photoPanel.hasPhoto) ...[
                        const SizedBox(height: 12),
                        photoPanel,
                      ],
                      const SizedBox(height: 14),
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
                          if (_isAsk) ...[
                            TextButton(
                              onPressed: onClose,
                              style: TextButton.styleFrom(
                                foregroundColor: ink,
                                textStyle: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              child: const Text('Later'),
                            ),
                            if (onBuild != null) ...[
                              const SizedBox(width: 8),
                              _InkButton(
                                ink: ink,
                                paper: paper,
                                onPressed: onBuild!,
                                child: const Text('Build it!'),
                              ),
                            ],
                          ] else
                            _InkButton(
                              ink: ink,
                              paper: paper,
                              onPressed: onClose,
                              child: Text(badNews ? 'On it' : 'Hooray!'),
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

class _InkButton extends StatelessWidget {
  const _InkButton({
    required this.ink,
    required this.paper,
    required this.onPressed,
    required this.child,
  });

  final Color ink;
  final Color paper;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: ink,
      foregroundColor: paper,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    ),
    child: child,
  );
}

/// Newsprint: greyscale with a touch of the paper's warmth, so the photo
/// reads as printed on the page rather than pasted on.
const ColorFilter kNewsprintFilter = ColorFilter.matrix(<double>[
  0.299 * 1.00, 0.587 * 1.00, 0.114 * 1.00, 0, 0, //
  0.299 * 0.96, 0.587 * 0.96, 0.114 * 0.96, 0, 0, //
  0.299 * 0.88, 0.587 * 0.88, 0.114 * 0.88, 0, 0, //
  0, 0, 0, 1, 0,
]);

/// The page's photo in an ink frame with an italic caption: the building
/// an ask is about, or the city with the mayor inset.
class _NewsPhoto extends StatelessWidget {
  const _NewsPhoto({
    required this.target,
    required this.photo,
    required this.mayor,
    required this.cityName,
    required this.ink,
    required this.paper,
  });

  final BuildingType? target;
  final ui.Image? photo;
  final AdventurerConfig? mayor;
  final String cityName;
  final Color ink;
  final Color paper;

  bool get hasPhoto => target != null || photo != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = target;
    final Widget picture;
    final String caption;
    if (t != null) {
      picture = ColoredBox(
        color: const Color(0xFFE9E2D2),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: TrimmedSprite(
            asset: 'assets/buildings/${t.id}_v1.png',
            fallback: Text(t.emoji, style: const TextStyle(fontSize: 56)),
          ),
        ),
      );
      caption = "Artist's impression: the ${t.name.toLowerCase()}.";
    } else {
      picture = RawImage(image: photo, fit: BoxFit.cover);
      caption = mayor != null
          ? '$cityName from the air. Inset: the Mayor.'
          : '$cityName from the air, this morning.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: t != null ? 16 / 9 : 16 / 10,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: ink, width: 1.5),
              color: paper,
            ),
            padding: const EdgeInsets.all(3),
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(colorFilter: kNewsprintFilter, child: picture),
                  if (mayor != null)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: paper,
                          border: Border.all(color: ink, width: 1.5),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ColorFiltered(
                          colorFilter: kNewsprintFilter,
                          child: AdventurerAvatarWidget(
                            config: mayor!,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: theme.textTheme.bodySmall?.copyWith(
            color: ink,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
