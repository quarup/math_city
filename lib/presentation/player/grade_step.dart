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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            StepTitle(
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
              ),
            ),
            const SizedBox(height: 12),
            for (final row in kGradeRows)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _GradeTile(
                  row: row,
                  selected: _grade == row.grade,
                  onTap: () => setState(() => _grade = row.grade),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Not sure? Ask a grown-up.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      footer: PrimaryButton(
        label: _grade == null ? 'Pick your grade' : widget.nextLabel,
        onPressed: _grade == null ? null : () => widget.onNext(_grade!),
      ),
    );
  }
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
    final palette = theme.extension<AppPalette>()!;
    return Semantics(
      button: true,
      selected: selected,
      label: '${row.name}, ages ${row.ages}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primaryContainer : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              width: 3,
              color: selected
                  ? palette.brandTealDeep
                  : theme.colorScheme.surfaceContainerHigh,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.brandTealDeep,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  row.badge,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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
