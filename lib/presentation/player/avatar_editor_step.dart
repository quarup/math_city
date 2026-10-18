import 'dart:math';

import 'package:flutter/material.dart';
import 'package:math_city/domain/avatar/adventurer_catalog.dart';
import 'package:math_city/domain/avatar/adventurer_composer.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/presentation/player/avatar_thumb.dart';
import 'package:math_city/presentation/player/creation_chrome.dart';
import 'package:math_city/presentation/theme/app_palette.dart';

/// The face editor: a big preview, five tabs (Skin, Hair, Eyes, Mouth,
/// Ears) and, per tab, rows of thumbnails that each show the option on
/// the current face. *Next* walks the tabs; the last tab's button is
/// *Done*.
///
/// Blush and freckles are one choice (plain, blush or freckles): the two
/// marks never combine, even though the config stores them separately.
/// The thumbnails take whatever size lets the tab's rows fit without
/// scrolling, on a phone upright or on its side.
class AvatarEditorStep extends StatefulWidget {
  const AvatarEditorStep({
    required this.initial,
    required this.onDone,
    this.onBack,
    this.step = 1,
    this.doneLabel = 'Done',
    super.key,
  });

  final AdventurerConfig initial;
  final ValueChanged<AdventurerConfig> onDone;
  final VoidCallback? onBack;

  /// Dot position, or null when editing an existing player.
  final int? step;
  final String doneLabel;

  @override
  State<AvatarEditorStep> createState() => _AvatarEditorStepState();
}

enum _Tab { skin, hair, eyes, mouth, ears }

const _tabLabels = <_Tab, String>{
  _Tab.skin: 'Skin',
  _Tab.hair: 'Hair',
  _Tab.eyes: 'Eyes',
  _Tab.mouth: 'Mouth',
  _Tab.ears: 'Ears',
};

class _AvatarEditorStepState extends State<AvatarEditorStep> {
  late AdventurerConfig _config = widget.initial;
  _Tab _tab = _Tab.skin;

  bool get _isLast => _tab == _Tab.ears;

  void _set(AdventurerConfig next) => setState(() => _config = next);

  void _next() {
    if (_isLast) {
      widget.onDone(_config);
      return;
    }
    setState(() => _tab = _Tab.values[_tab.index + 1]);
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: widget.step,
      onBack: widget.onBack,
      title: 'Make your mayor',
      hero: HeroLead(config: _config),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          _TabRow(current: _tab, onSelect: (t) => setState(() => _tab = t)),
          const SizedBox(height: 12),
          Expanded(child: _panel()),
        ],
      ),
      footer: PrimaryButton(
        label: _isLast ? widget.doneLabel : 'Next',
        onPressed: _next,
      ),
    );
  }

  Widget _panel() {
    final c = _config;
    switch (_tab) {
      case _Tab.skin:
        final plain = c.copyWith(blush: false, freckles: false);
        return _Sections(
          sections: [
            _Section('Tone', [
              for (var i = 0; i < kSkinColors.length; i++)
                _Option(
                  config: c.copyWith(skinColorIndex: i),
                  crop: AvatarCrop.face,
                  selected: c.skinColorIndex == i,
                  label: kSkinColorLabels[i],
                  onTap: () => _set(c.copyWith(skinColorIndex: i)),
                ),
            ]),
            _Section('Cheeks', [
              _Option(
                config: plain,
                crop: AvatarCrop.face,
                selected: !c.blush && !c.freckles,
                label: 'No cheek marks',
                onTap: () => _set(plain),
              ),
              _Option(
                config: plain.copyWith(blush: true),
                crop: AvatarCrop.face,
                selected: c.blush,
                label: 'Blush',
                onTap: () => _set(plain.copyWith(blush: true)),
              ),
              _Option(
                config: plain.copyWith(freckles: true),
                crop: AvatarCrop.face,
                selected: c.freckles,
                label: 'Freckles',
                onTap: () => _set(plain.copyWith(freckles: true)),
              ),
            ]),
          ],
        );
      case _Tab.hair:
        return _Sections(
          sections: [
            _Section(null, [
              for (var i = 0; i < kHairStyles.length; i++)
                _Option(
                  config: c.copyWith(hairIndex: i),
                  crop: AvatarCrop.head,
                  selected: c.hairIndex == i,
                  label: kHairStyleLabels[i],
                  onTap: () => _set(c.copyWith(hairIndex: i)),
                ),
            ]),
          ],
          trailer: _SwatchRow(
            label: 'Color',
            count: kHairColors.length,
            swatch: hairColorSwatch,
            labels: kHairColorLabels,
            selectedIndex: c.hairColorIndex,
            onSelect: (i) => _set(c.copyWith(hairColorIndex: i)),
          ),
        );
      case _Tab.eyes:
        return _Sections(
          sections: [
            _Section('Eyes', [
              for (var i = 0; i < kEyeVariants.length; i++)
                _Option(
                  config: c.copyWith(eyesIndex: i),
                  crop: AvatarCrop.face,
                  selected: c.eyesIndex == i,
                  label: 'Eyes ${i + 1}',
                  onTap: () => _set(c.copyWith(eyesIndex: i)),
                ),
            ]),
            _Section('Glasses', [
              for (var i = 0; i < kGlassesOptions.length; i++)
                _Option(
                  config: c.copyWith(glassesIndex: i),
                  crop: AvatarCrop.eyes,
                  selected: c.glassesIndex == i,
                  label: i == 0 ? 'No glasses' : 'Glasses $i',
                  onTap: () => _set(c.copyWith(glassesIndex: i)),
                ),
            ]),
          ],
        );
      case _Tab.mouth:
        return _Sections(
          sections: [
            _Section(null, [
              for (var i = 0; i < kMouthVariants.length; i++)
                _Option(
                  config: c.copyWith(mouthIndex: i),
                  crop: AvatarCrop.face,
                  selected: c.mouthIndex == i,
                  label: 'Mouth ${i + 1}',
                  onTap: () => _set(c.copyWith(mouthIndex: i)),
                ),
            ]),
          ],
        );
      case _Tab.ears:
        if (hairCoversEars(c.hairIndex)) {
          return _CoveredEarsNote(
            onChangeHair: () => setState(() => _tab = _Tab.hair),
          );
        }
        return _Sections(
          sections: [
            _Section(null, [
              for (var i = 0; i < kEarringsOptions.length; i++)
                _Option(
                  config: c.copyWith(earringsIndex: i),
                  crop: AvatarCrop.ear,
                  selected: c.earringsIndex == i,
                  label: i == 0 ? 'No earrings' : 'Earrings $i',
                  onTap: () => _set(c.copyWith(earringsIndex: i)),
                ),
            ]),
          ],
        );
    }
  }
}

/// Shown on the Ears tab when the hair hides the ears.
class _CoveredEarsNote extends StatelessWidget {
  const _CoveredEarsNote({required this.onChangeHair});

  final VoidCallback onChangeHair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This hair covers the ears, so earrings would not show.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onChangeHair,
            style: TextButton.styleFrom(
              foregroundColor: palette.brandTealDeep,
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Pick a shorter style'),
          ),
        ],
      ),
    );
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({required this.current, required this.onSelect});

  final _Tab current;
  final ValueChanged<_Tab> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.surfaceContainerHigh,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          for (final t in _Tab.values)
            Expanded(
              child: InkWell(
                onTap: () => onSelect(t),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: t == current
                            ? palette.brandTealDeep
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    _tabLabels[t]!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: t == current
                          ? palette.brandTealDeep
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Option {
  const _Option({
    required this.config,
    required this.crop,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final AdventurerConfig config;
  final AvatarCrop crop;
  final bool selected;
  final String label;
  final VoidCallback onTap;
}

class _Section {
  const _Section(this.label, this.options);

  final String? label;
  final List<_Option> options;
}

/// A tab's rows of thumbnails, sized to fit the space they are given.
///
/// Labels sit above their row when the panel is upright and to its left
/// when the panel is wide, so a side layout spends its height on the
/// thumbnails. One column count serves every section of the tab.
class _Sections extends StatelessWidget {
  const _Sections({required this.sections, this.trailer});

  final List<_Section> sections;

  /// A fixed-height row under the sections (the hair colour swatches).
  final Widget? trailer;

  static const _gap = 10.0;
  static const _labelH = 24.0;
  static const _labelW = 68.0;
  static const _sectionGap = 10.0;
  static const _trailerH = 48.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, c) {
          // Labels beside the rows only when the panel is a wide side
          // pane; an upright phone's panel is wider than tall too.
          final inline = c.maxWidth > 1.6 * c.maxHeight;
          final labelled = sections.where((s) => s.label != null).length;
          final gridWidth = c.maxWidth - (inline ? _labelW : 0);
          final fixed =
              _sectionGap * (sections.length - 1) +
              (inline ? 0 : _labelH * labelled) +
              (trailer == null ? 0 : _trailerH);
          // Biggest cells that fit, capped; once cells are a comfortable
          // size, fewer rows beat bigger cells.
          const maxCell = 80.0;
          const comfortable = 56.0;
          var bestCols = 3;
          var best = 0.0;
          var bestRows = 1 << 20;
          for (var cols = 3; cols <= 8; cols++) {
            var rows = 0;
            for (final s in sections) {
              rows += (s.options.length / cols).ceil();
            }
            final byWidth = (gridWidth - _gap * (cols - 1)) / cols;
            final byHeight =
                (c.maxHeight - fixed - _gap * (rows - sections.length)) / rows;
            final cell = min(min(byWidth, byHeight), maxCell);
            final better = best < comfortable
                ? cell > best
                : cell >= comfortable &&
                      (rows < bestRows || (rows == bestRows && cell > best));
            if (better) {
              best = cell;
              bestCols = cols;
              bestRows = rows;
            }
          }
          final cell = best;
          final gridSpan = bestCols * cell + (bestCols - 1) * _gap;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, s) in sections.indexed) ...[
                if (i > 0) const SizedBox(height: _sectionGap),
                _SectionView(
                  section: s,
                  cell: cell,
                  gridSpan: gridSpan,
                  inline: inline,
                ),
              ],
              if (trailer != null) ...[
                const SizedBox(height: _sectionGap),
                SizedBox(height: _trailerH - _sectionGap, child: trailer),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({
    required this.section,
    required this.cell,
    required this.gridSpan,
    required this.inline,
  });

  final _Section section;
  final double cell;
  final double gridSpan;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = section.label == null
        ? null
        : Text(
            section.label!,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
    final grid = SizedBox(
      width: gridSpan,
      child: Wrap(
        spacing: _Sections._gap,
        runSpacing: _Sections._gap,
        children: [
          for (final o in section.options)
            OptionCell(
              size: cell,
              selected: o.selected,
              semanticLabel: o.label,
              onTap: o.onTap,
              child: AvatarThumb(
                config: o.config,
                size: cell - 12,
                crop: o.crop,
              ),
            ),
        ],
      ),
    );
    if (inline) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _Sections._labelW,
            height: cell,
            child: Align(alignment: Alignment.centerLeft, child: label),
          ),
          grid,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          SizedBox(
            height: _Sections._labelH,
            child: Align(alignment: Alignment.centerLeft, child: label),
          ),
        grid,
      ],
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({
    required this.label,
    required this.count,
    required this.swatch,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String label;
  final int count;
  final Color Function(int) swatch;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Semantics(
              button: true,
              selected: i == selectedIndex,
              label: labels[i],
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: swatch(i),
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 3,
                      color: i == selectedIndex
                          ? palette.brandTealDeep
                          : Colors.white,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
