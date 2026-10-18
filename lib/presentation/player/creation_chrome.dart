import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_city/presentation/theme/app_palette.dart';

/// The frame every player-creation step shares: a top bar with a back
/// button, the three step dots (hidden when [step] is null, i.e. editing
/// an existing player) and an optional trailing widget; the step's body;
/// and a footer pinned above the safe area, usually a [PrimaryButton].
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    required this.body,
    this.step,
    this.onBack,
    this.trailing,
    this.footer,
    super.key,
  });

  final Widget body;
  final int? step;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
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
        title: step == null ? null : StepDots(step: step!),
        actions: [
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(width: 44, height: 44, child: trailing),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: body),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Three dots: the current step is a wide pill, done steps are filled.
class StepDots extends StatelessWidget {
  const StepDots({required this.step, super.key});

  final int step;

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
            if (i > 1) const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == step ? 28 : 10,
              height: 10,
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
      height: 56,
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
      height: 50,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
