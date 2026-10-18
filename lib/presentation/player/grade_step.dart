import 'package:flutter/material.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/presentation/player/avatar_thumb.dart';
import 'package:math_city/presentation/player/creation_chrome.dart';
import 'package:math_city/presentation/theme/app_palette.dart';

/// One row of the grade list. Grade 0 is kindergarten.
class GradeRow {
  const GradeRow(this.grade, this.badge, this.name, this.ages);

  final int grade;
  final String badge;
  final String name;
  final String ages;
}

const kGradeRows = <GradeRow>[
  GradeRow(0, 'K', 'Kindergarten', '5–6'),
  GradeRow(1, '1', '1st grade', '6–7'),
  GradeRow(2, '2', '2nd grade', '7–8'),
  GradeRow(3, '3', '3rd grade', '8–9'),
  GradeRow(4, '4', '4th grade', '9–10'),
  GradeRow(5, '5', '5th grade', '10–11'),
  GradeRow(6, '6', '6th grade', '11–12'),
  GradeRow(7, '7', '7th grade', '12–13'),
  GradeRow(8, '8', '8th grade', '13–14'),
];

/// Step 2: the player's school grade, as a plain list with age ranges.
///
/// Deliberately no default for a new player: the wrong grade is the
/// costliest mistake in the whole flow, and a preselected chip is the one
/// kids skim past. The button stays grey until a row is tapped.
///
/// The nine rows shrink to fit the height; when even short rows would
/// not fit (a phone on its side) they become a three-by-three grid.
class GradeStep extends StatefulWidget {
  const GradeStep({
    required this.avatar,
    required this.onNext,
    this.initial,
    this.onBack,
    this.step = 2,
    this.nextLabel = 'Next',
    super.key,
  });

  final AdventurerConfig avatar;
  final int? initial;
  final ValueChanged<int> onNext;
  final VoidCallback? onBack;
  final int? step;
  final String nextLabel;

  @override
  State<GradeStep> createState() => _GradeStepState();
}

class _GradeStepState extends State<GradeStep> {
  late int? _grade = widget.initial;

  static const _gap = 8.0;
  static const _minRow = 42.0;
  static const _maxRow = 54.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StepScaffold(
      step: widget.step,
      onBack: widget.onBack,
      trailing: Center(
        child: AvatarThumb(
          config: widget.avatar,
          size: 40,
          background: theme.colorScheme.surfaceContainerLow,
        ),
      ),
      title: 'Your school grade',
      hint: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'This one is about '),
            TextSpan(
              text: 'you',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const TextSpan(text: ', not your mayor.'),
          ],
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: LayoutBuilder(
          builder: (context, c) {
            // Rows share the height evenly, each capped at a comfortable
            // size; a short screen (a phone on its side) gets a grid.
            const hint = 40.0;
            final n = kGradeRows.length;
            final rowH = (c.maxHeight - hint - _gap * (n - 1)) / n;
            if (rowH >= _minRow) {
              return Column(
                children: [
                  for (final (i, row) in kGradeRows.indexed) ...[
                    if (i > 0) const SizedBox(height: _gap),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: _maxRow),
                        child: _GradeTile(
                          row: row,
                          selected: _grade == row.grade,
                          onTap: () => setState(() => _grade = row.grade),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(height: hint - 8, child: _GrownUpHint()),
                ],
              );
            }
            // Two across while five rows stay tall enough, else three.
            double rowHeightFor(int cols) {
              final rows = (n / cols).ceil();
              return (c.maxHeight - hint - _gap * (rows - 1)) / rows;
            }

            final cols = c.maxWidth >= 600 || rowHeightFor(2) < 44 ? 3 : 2;
            final cellW = (c.maxWidth - _gap * (cols - 1)) / cols;
            final cellH = rowHeightFor(cols).clamp(36.0, 96.0);
            return Column(
              children: [
                Wrap(
                  spacing: _gap,
                  runSpacing: _gap,
                  children: [
                    for (final row in kGradeRows)
                      _GradeCard(
                        row: row,
                        width: cellW,
                        height: cellH,
                        selected: _grade == row.grade,
                        onTap: () => setState(() => _grade = row.grade),
                      ),
                  ],
                ),
                const Spacer(),
                SizedBox(height: hint - 8, child: _GrownUpHint()),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
      footer: PrimaryButton(
        label: _grade == null ? 'Pick your grade' : widget.nextLabel,
        onPressed: _grade == null ? null : () => widget.onNext(_grade!),
      ),
    );
  }
}

class _GrownUpHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Not sure? Ask a grown-up.',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

BoxDecoration _tileDecoration(ThemeData theme, {required bool selected}) {
  final palette = theme.extension<AppPalette>()!;
  return BoxDecoration(
    color: selected ? theme.colorScheme.primaryContainer : Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      width: 3,
      color: selected
          ? palette.brandTealDeep
          : theme.colorScheme.surfaceContainerHigh,
    ),
  );
}

Widget _badge(ThemeData theme, String text, double size) {
  final palette = theme.extension<AppPalette>()!;
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: palette.brandTealDeep,
      shape: BoxShape.circle,
    ),
    child: Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _GradeTile extends StatelessWidget {
  const _GradeTile({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  final GradeRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${row.name}, ages ${row.ages}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _tileDecoration(theme, selected: selected),
          child: Row(
            children: [
              _badge(theme, row.badge, 32),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  row.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'ages ${row.ages}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.row,
    required this.width,
    required this.height,
    required this.selected,
    required this.onTap,
  });

  final GradeRow row;
  final double width;
  final double height;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${row.name}, ages ${row.ages}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: _tileDecoration(theme, selected: selected),
          child: Row(
            children: [
              _badge(theme, row.badge, 30),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    // A very short card keeps only the name.
                    if (height >= 48)
                      Text(
                        'ages ${row.ages}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
