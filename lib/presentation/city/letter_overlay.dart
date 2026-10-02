import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/citizen.dart';
import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_city/state/tts_provider.dart';

/// A letter from a citizen (city_builder.md §10.2): the unit of story. Drawn
/// over the city as a modal card — face, name and a "wants a …" line; the
/// spoken sentence addressed to the mayor by name; the building it is about;
/// and two big buttons, the primary one always the action. One template for
/// every age: pre-readers get the face, the picture and the voice.
///
/// The caller decides what the buttons do: [onBuild] (null hides *Build
/// it!*) and [onClose] (*Later*, or *Thanks!* on a letter that asks for
/// nothing). Speech on open is the caller's too — this widget only offers
/// the replay button.
class LetterOverlay extends ConsumerWidget {
  const LetterOverlay({
    required this.beat,
    required this.citizen,
    required this.playerName,
    required this.onClose,
    this.target,
    this.onBuild,
    super.key,
  });

  final StoryBeat beat;
  final Citizen citizen;
  final String playerName;

  /// The building the letter is about; drawn in the picture panel.
  final BuildingType? target;

  final VoidCallback? onBuild;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final askLine = '${beat.emoji} ${beat.shortLabel}';
    final isTown = citizen.id == kTownCitizenId;

    return Stack(
      children: [
        // Scrim: a tap outside is *Later*.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Material(
                color: scheme.surface,
                elevation: 12,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (isTown)
                            const _CastRow(size: 40)
                          else
                            AdventurerAvatarWidget(
                              config: citizen.face,
                              size: 52,
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  citizen.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  askLine,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Read it again',
                            onPressed: () =>
                                unawaited(speakIfEnabled(ref, spokenText)),
                            icon: const Icon(Icons.volume_up_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Dear Mayor $playerName,',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(beat.longText, style: theme.textTheme.bodyLarge),
                      if (target != null) ...[
                        const SizedBox(height: 14),
                        _PicturePanel(building: target!, onTap: onBuild),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (onBuild != null) ...[
                            Expanded(
                              flex: 3,
                              child: FilledButton(
                                onPressed: onBuild,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  textStyle: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                child: const Text('Build it!'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: OutlinedButton(
                                onPressed: onClose,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text('Later'),
                              ),
                            ),
                          ] else
                            Expanded(
                              child: FilledButton(
                                onPressed: onClose,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  textStyle: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                child: Text(
                                  beat.kind == BeatKind.praise
                                      ? 'Thanks!'
                                      : 'Got it',
                                ),
                              ),
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

  /// What the voice reads: the salutation, then the sentence.
  String get spokenText => 'Dear Mayor $playerName, ${beat.longText}';
}

/// The building the letter is about: its sprite on a soft panel, the emoji
/// as a fallback while the asset is missing. Tapping it does what *Build
/// it!* does ([onTap]; null when the letter has nothing to build).
class _PicturePanel extends StatelessWidget {
  const _PicturePanel({required this.building, this.onTap});

  final BuildingType building;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: _TrimmedSprite(
          asset: 'assets/buildings/${building.id}_v1.png',
          fallback: Text(building.emoji, style: const TextStyle(fontSize: 48)),
        ),
      ),
    );
  }
}

/// A sprite drawn so its *visible* pixels are centred and fill the box: the
/// building sprites carry transparent headroom above the roof (room for
/// taller variants), which would otherwise sit the building low.
class _TrimmedSprite extends StatefulWidget {
  const _TrimmedSprite({required this.asset, required this.fallback});

  final String asset;
  final Widget fallback;

  @override
  State<_TrimmedSprite> createState() => _TrimmedSpriteState();
}

class _TrimmedSpriteState extends State<_TrimmedSprite> {
  /// Decoded sprites and their opaque bounds, kept across letters.
  static final Map<String, Future<(ui.Image, Rect)?>> _cache = {};

  late Future<(ui.Image, Rect)?> _sprite = _load(widget.asset);

  @override
  void didUpdateWidget(_TrimmedSprite old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset) _sprite = _load(widget.asset);
  }

  static Future<(ui.Image, Rect)?> _load(String asset) =>
      _cache.putIfAbsent(asset, () async {
        try {
          final data = await rootBundle.load(asset);
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final image = (await codec.getNextFrame()).image;
          final bytes = await image.toByteData();
          if (bytes == null) return null;
          final w = image.width;
          final h = image.height;
          var minX = w;
          var minY = h;
          var maxX = -1;
          var maxY = -1;
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              if (bytes.getUint8((y * w + x) * 4 + 3) == 0) continue;
              if (x < minX) minX = x;
              if (x > maxX) maxX = x;
              if (y < minY) minY = y;
              if (y > maxY) maxY = y;
            }
          }
          if (maxX < 0) return null;
          return (
            image,
            Rect.fromLTRB(
              minX.toDouble(),
              minY.toDouble(),
              maxX + 1.0,
              maxY + 1.0,
            ),
          );
        } on Exception {
          return null;
        }
      });

  @override
  Widget build(BuildContext context) => FutureBuilder<(ui.Image, Rect)?>(
    future: _sprite,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const SizedBox.expand();
      }
      final sprite = snap.data;
      if (sprite == null) return Center(child: widget.fallback);
      return CustomPaint(
        size: Size.infinite,
        painter: _TrimmedSpritePainter(sprite.$1, sprite.$2),
      );
    },
  );
}

class _TrimmedSpritePainter extends CustomPainter {
  _TrimmedSpritePainter(this.image, this.bounds);

  final ui.Image image;
  final Rect bounds;

  @override
  void paint(Canvas canvas, Size size) {
    final fitted = applyBoxFit(BoxFit.contain, bounds.size, size);
    final dst = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    canvas.drawImageRect(
      image,
      bounds,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_TrimmedSpritePainter old) =>
      old.image != image || old.bounds != bounds;
}

/// The whole cast in a row, for a letter signed by everyone.
class _CastRow extends StatelessWidget {
  const _CastRow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final faces = castRegistry.take(5).toList();
    return SizedBox(
      width: size + (faces.length - 1) * size * 0.55,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < faces.length; i++)
            Positioned(
              left: i * size * 0.55,
              child: AdventurerAvatarWidget(config: faces[i].face, size: size),
            ),
        ],
      ),
    );
  }
}
