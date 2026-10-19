import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/presentation/player/avatar_thumb.dart';
import 'package:math_city/presentation/theme/app_palette.dart';

/// The frame every player-creation step shares, laid out so that nothing
/// ever needs scrolling, on a phone upright or on its side.
///
/// Upright: the bar shows the step dots (or [title] when there are no
/// dots), then [hero], the title and [hint], [content] in the room that is
/// left, the secondary [actions] and the primary [footer] button.
///
/// On its side: the bar carries the title with small dots at its right
/// end; the content takes the left, and a right pane holds [trailing],
/// the hint, the hero, the actions and the footer. Content widgets size
/// their choices from the constraints they receive.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    required this.title,
    required this.content,
    this.hint,
    this.hero,
    this.step,
    this.onBack,
    this.trailing,
    this.actions = const [],
    this.footer,
    this.resizeForKeyboard = true,
    super.key,
  });

  final String title;
  final Widget content;
  final Widget? hint;

  /// A [HeroLead]: the avatar on its band.
  final Widget? hero;

  /// Dot position, or null when editing an existing player (the title
  /// then goes in the bar upright too).
  final int? step;
  final VoidCallback? onBack;
  final Widget? trailing;
  final List<Widget> actions;
  final Widget? footer;

  /// False lets the keyboard cover the bottom instead of squeezing the
  /// layout; a screen whose text box sits at the top can afford that.
  final bool resizeForKeyboard;

  /// A screen wider than tall gets the side-by-side layout.
  static bool isWide(BoxConstraints c) => c.maxWidth > c.maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final wide = size.width > size.height;
    final titleText = Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      resizeToAvoidBottomInset: resizeForKeyboard,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: !wide && step != null,
        titleSpacing: onBack == null ? 20 : 4,
        automaticallyImplyLeading: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemStatusBarContrastEnforced: false,
        ),
        leading: onBack == null
            ? null
            : IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
        title: !wide && step != null ? StepDots(step: step!) : titleText,
        actions: [
          if (wide && step != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: StepDots(step: step!, small: true),
            ),
          if (!wide && trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(width: 44, height: 44, child: trailing),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, c) {
            if (!isWide(c)) return _upright(c);
            return _onSide(c);
          },
        ),
      ),
    );
  }

  Widget _upright(BoxConstraints c) {
    // A short upright screen puts the secondary actions side by side so
    // the choices keep their room.
    final short = c.maxHeight < 700 && actions.length > 1;
    final tail = short
        ? [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (final (i, a) in actions.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: a),
                  ],
                ],
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: footer,
              ),
          ]
        : _tail();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?hero,
        if (step != null)
          Padding(
            padding: EdgeInsets.only(top: hero == null ? 4 : 14, bottom: 10),
            child: StepTitle(title: title, hint: hint),
          )
        else if (hint != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: hint,
          ),
        Expanded(child: content),
        ...tail,
      ],
    );
  }

  Widget _onSide(BoxConstraints c) {
    final paneWidth = (c.maxWidth * 0.38).clamp(300.0, 460.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: content,
          ),
        ),
        SizedBox(
          width: paneWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 16, 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(width: 44, height: 44, child: trailing),
                  ),
                ),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    child: hint!,
                  ),
                ),
              if (hero != null) Expanded(child: hero!),
              // No hero: the actions follow the hint, the button stays at
              // the bottom.
              for (final a in actions)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: a,
                ),
              if (hero == null) const Spacer(),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: footer,
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _tail() => [
    for (final a in actions)
      Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: a),
    if (footer != null)
      Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), child: footer),
  ];
}

/// The avatar on its soft band, with an optional badge under it. Upright
/// it draws at [portraitSize]; in a bounded pane (the side layout) it
/// fills what it is given, so the pane always fits.
class HeroLead extends StatelessWidget {
  const HeroLead({
    required this.config,
    this.portraitSize = 196,
    this.badge,
    this.reserveBadge = false,
    super.key,
  });

  final AdventurerConfig config;
  final double portraitSize;
  final Widget? badge;

  /// Keep the badge's room when [badge] is null, so nothing jumps when
  /// it appears.
  final bool reserveBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final band = theme.colorScheme.surfaceContainerLow;
    final hasBadge = badge != null || reserveBadge;
    Widget stacked(double size) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarThumb(config: config, size: size),
        if (hasBadge) ...[
          const SizedBox(height: 8),
          SizedBox(height: 36, child: Center(child: badge)),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (!c.hasBoundedHeight) {
          // Upright: a short screen gets a smaller avatar.
          final screenH = MediaQuery.sizeOf(context).height;
          final size = screenH < 700 ? portraitSize * 0.7 : portraitSize;
          return Container(
            color: band,
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Center(child: stacked(size)),
          );
        }
        // Side layout: the avatar takes what the pane's width and height
        // allow; when too short to stack, the badge sits beside the face.
        return Container(
          color: band,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: LayoutBuilder(
            builder: (context, b) {
              final reserve = hasBadge ? 48.0 : 0.0;
              final fit = min(b.maxWidth - 40, b.maxHeight - 16 - reserve);
              if (fit >= 56 || !hasBadge) {
                return Center(child: stacked(fit.clamp(40.0, 260.0)));
              }
              final side = (b.maxHeight - 16).clamp(0.0, 80.0);
              return Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (side >= 40) ...[
                      AvatarThumb(config: config, size: side),
                      const SizedBox(width: 12),
                    ],
                    SizedBox(height: 36, child: Center(child: badge)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Three dots: the current step is a wide pill, done steps are filled.
class StepDots extends StatelessWidget {
  const StepDots({required this.step, this.small = false, super.key});

  final int step;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Semantics(
      label: 'Step $step of 3',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 3; i++) ...[
            if (i > 1) SizedBox(width: small ? 5 : 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == step ? (small ? 20 : 28) : (small ? 7 : 10),
              height: small ? 7 : 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: i == step
                    ? palette.brandTealDeep
                    : i < step
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHigh,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The step's one big action. With [onPressed] null it stays visible but
/// greyed, so the kid can read what is still needed ("Pick your grade").
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: palette.brandTealDeep,
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHigh,
          disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        child: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// A full-width secondary action with an icon ("Show me more").
class RowButton extends StatelessWidget {
  const RowButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.brandTealDeep,
          side: BorderSide(
            color: theme.colorScheme.surfaceContainerHigh,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// A square option cell with a selection ring, for avatar parts.
class OptionCell extends StatelessWidget {
  const OptionCell({
    required this.selected,
    required this.onTap,
    required this.child,
    required this.semanticLabel,
    this.size = 62,
    super.key,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        // The size is set outright: tweening it would make cells wrap
        // into extra rows for a few frames whenever a tab changes.
        child: SizedBox(
          width: size,
          height: size,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size < 56 ? 12 : 16),
              border: Border.all(
                width: 3,
                color: selected
                    ? palette.brandTealDeep
                    : theme.colorScheme.surfaceContainerHigh,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Big heading, optional one-line hint under it.
class StepTitle extends StatelessWidget {
  const StepTitle({required this.title, this.hint, super.key});

  final String title;
  final Widget? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: DefaultTextStyle(
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                child: hint!,
              ),
            ),
        ],
      ),
    );
  }
}

/// The biggest square cell for [count] items that fits [width] × [height]
/// at some column count in [minCols]..[maxCols], with [gap] between
/// cells. Returns (columns, cell side).
(int, double) fitSquareGrid({
  required int count,
  required double width,
  required double height,
  required double gap,
  int minCols = 2,
  int maxCols = 8,
  double maxCell = double.infinity,
}) {
  var bestCols = minCols;
  var best = 0.0;
  for (var cols = minCols; cols <= min(maxCols, count); cols++) {
    final rows = (count / cols).ceil();
    final byWidth = (width - gap * (cols - 1)) / cols;
    final byHeight = (height - gap * (rows - 1)) / rows;
    final cell = min(byWidth, byHeight);
    if (cell > best) {
      best = cell;
      bestCols = cols;
    }
  }
  return (bestCols, min(best, maxCell).clamp(0.0, double.infinity));
}
