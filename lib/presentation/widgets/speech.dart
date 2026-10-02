import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/widgets/math_text.dart';
import 'package:math_city/services/tts_service.dart';

/// The voice a screen's speakers talk through, and the screen they belong
/// to. Speaker chips, lit-up words and dotted diagram labels find it here,
/// so a diagram widget needs no plumbing of its own to be read aloud; with
/// no scope above them they draw as plain text.
class SpeechScope extends InheritedWidget {
  const SpeechScope({
    required this.service,
    required this.owner,
    required super.child,
    super.key,
  });

  final TtsService service;

  /// Passed as the owner of every utterance started from this scope, so
  /// the screen's dispose stops its own speech and nobody else's.
  final Object owner;

  static SpeechScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SpeechScope>();

  /// Speaks [items] now, whatever the auto-read preference says: a tap is
  /// a request.
  void speak(List<SpeechItem> items) =>
      unawaited(service.speakAll(items, owner: owner));

  void stop() => unawaited(service.stop(owner: owner));

  @override
  bool updateShouldNotify(SpeechScope old) =>
      old.service != service || old.owner != owner;
}

/// Rebuilds with the current [SpeechProgress] of the scope's voice; null
/// when silent or when no scope is above.
class _OnProgress extends StatelessWidget {
  const _OnProgress({required this.builder});

  final Widget Function(BuildContext, SpeechScope?, SpeechProgress?) builder;

  @override
  Widget build(BuildContext context) {
    final scope = SpeechScope.maybeOf(context);
    if (scope == null) return builder(context, null, null);
    return ValueListenableBuilder<SpeechProgress?>(
      valueListenable: scope.service.progress,
      builder: (context, p, _) => builder(
        context,
        scope,
        p != null && identical(p.owner, scope.owner) ? p : null,
      ),
    );
  }
}

/// The round speaker button. Tapping it reads [items]; while one of them
/// is being read it shows moving bars and tapping it stops the voice.
///
/// [solid] is the deep-teal button for a card; otherwise the quieter
/// tinted one that sits inside an answer button.
class SpeakerChip extends StatelessWidget {
  const SpeakerChip({
    required this.items,
    required this.tooltip,
    this.solid = false,
    super.key,
  });

  final List<SpeechItem> items;
  final String tooltip;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final size = solid ? 40.0 : 36.0;
    final fill = solid
        ? palette.brandTealDeep
        : theme.colorScheme.primaryContainer;
    final ink = solid ? theme.colorScheme.onPrimary : palette.brandTealDeep;
    return _OnProgress(
      builder: (context, scope, progress) {
        final ids = items.map((i) => i.id).toSet();
        final speaking = progress != null && ids.contains(progress.item.id);
        return Material(
          color: fill,
          shape: const CircleBorder(),
          elevation: solid ? 2 : 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: scope == null
                ? null
                : () => speaking ? scope.stop() : scope.speak(items),
            child: Tooltip(
              message: speaking ? 'Stop' : tooltip,
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: speaking
                      ? _SoundBars(color: ink, height: solid ? 16 : 14)
                      : Icon(Icons.volume_up_rounded, color: ink, size: 22),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Three bars bobbing while the voice talks.
class _SoundBars extends StatefulWidget {
  const _SoundBars({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  State<_SoundBars> createState() => _SoundBarsState();
}

class _SoundBarsState extends State<_SoundBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Container(
              width: 3,
              // Each bar runs a little behind the one before it.
              height: widget.height * (0.35 + 0.65 * _bob(i)),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _bob(int i) =>
      0.5 - 0.5 * math.cos((_ctrl.value - i * 0.15) * 2 * math.pi);
}

/// Question text that lights up the word being read aloud. [itemId] names
/// the [SpeechItem] whose progress it follows.
class SpokenWords extends StatelessWidget {
  const SpokenWords(
    this.text, {
    required this.itemId,
    this.style,
    this.textAlign,
    super.key,
  });

  final String text;
  final String itemId;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return _OnProgress(
      builder: (context, _, progress) {
        final token = progress != null && progress.item.id == itemId
            ? progress.token
            : null;
        return MathText(
          text,
          style: style,
          textAlign: textAlign,
          highlight: token == null
              ? null
              : TextRange(start: token.displayStart, end: token.displayEnd),
          highlightColor: palette.speechHighlight,
        );
      },
    );
  }
}

/// Draws a ring around [child] while [itemId] is being read, so the child
/// (a prompt card, an answer button, an explanation line) is seen to be
/// the one talking.
class SpeakingRing extends StatelessWidget {
  const SpeakingRing({
    required this.itemId,
    required this.borderRadius,
    required this.child,
    super.key,
  });

  final String itemId;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return _OnProgress(
      builder: (context, _, progress) {
        final on = progress != null && progress.item.id == itemId;
        // Painted over the child, so a transparent button shows a ring
        // and not a filled orange pill.
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: on
                ? Border.all(color: palette.streakOrange, width: 3)
                : null,
          ),
          child: child,
        );
      },
    );
  }
}

/// A word in a diagram ("rope A", "Snowy", "28 feet") the child can tap to
/// hear. Dotted underneath so it reads as tappable; lit while spoken.
/// Outside a [SpeechScope] it is an ordinary [Text].
class SpokenLabel extends StatelessWidget {
  const SpokenLabel(this.text, {this.style, this.textAlign, super.key});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// How many more questions show the "tap a dotted word" hint this
  /// launch. Tapping any label ends it; the question screen counts it
  /// down.
  static int hintsLeft = 3;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final id = 'label:$text';
    return _OnProgress(
      builder: (context, scope, progress) {
        if (scope == null) {
          return Text(text, style: style, textAlign: textAlign);
        }
        final on = progress != null && progress.item.id == id;
        final base = style ?? DefaultTextStyle.of(context).style;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            hintsLeft = 0;
            scope.speak([SpeechItem(id, text)]);
          },
          child: Text(
            text,
            textAlign: textAlign,
            style: base.copyWith(
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: palette.brandTealDeep,
              decorationThickness: 2,
              backgroundColor: on ? palette.speechHighlight : null,
            ),
          ),
        );
      },
    );
  }
}

/// The one-time nudge beside a diagram with dotted words.
class DottedWordHint extends StatelessWidget {
  const DottedWordHint({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.tileInk,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Text(
          'Tap a dotted word to hear it',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
