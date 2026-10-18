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
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return StepScaffold(
      step: widget.step,
      onBack: widget.onBack,
      trailing: IconButton(
        onPressed: () => _set(AdventurerConfig.random()),
        tooltip: 'Surprise me',
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          foregroundColor: palette.brandTealDeep,
        ),
        icon: const Icon(Icons.casino_outlined),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: theme.colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Center(
              child: AvatarThumb(config: _config, size: 196),
            ),
          ),
          const SizedBox(height: 14),
          const StepTitle(title: 'Make your mayor'),
          const SizedBox(height: 10),
          _TabRow(
            current: _tab,
            onSelect: (t) => setState(() => _tab = t),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _panel(),
              ),
            ),
          ),
        ],
      ),
      footer: PrimaryButton(
        label: _isLast ? widget.doneLabel : 'Next',
        onPressed: _next,
      ),
    );
  }

  List<Widget> _panel() {
    final c = _config;
    switch (_tab) {
      case _Tab.skin:
        final plain = c.copyWith(blush: false, freckles: false);
        return [
          _OptionRow(
            label: 'Tone',
            options: [
              for (var i = 0; i < kSkinColors.length; i++)
                _Option(
                  config: c.copyWith(skinColorIndex: i),
                  crop: AvatarCrop.face,
                  selected: c.skinColorIndex == i,
                  label: kSkinColorLabels[i],
                  onTap: () => _set(c.copyWith(skinColorIndex: i)),
                ),
            ],
          ),
          _OptionRow(
            label: 'Cheeks',
            options: [
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
            ],
          ),
        ];
      case _Tab.hair:
        return [
          _OptionRow(
            options: [
              for (var i = 0; i < kHairStyles.length; i++)
                _Option(
                  config: c.copyWith(hairIndex: i),
                  crop: AvatarCrop.head,
                  selected: c.hairIndex == i,
                  label: kHairStyleLabels[i],
                  onTap: () => _set(c.copyWith(hairIndex: i)),
                ),
            ],
          ),
          _SwatchRow(
            label: 'Color',
            count: kHairColors.length,
            swatch: hairColorSwatch,
            labels: kHairColorLabels,
            selectedIndex: c.hairColorIndex,
            onSelect: (i) => _set(c.copyWith(hairColorIndex: i)),
          ),
        ];
      case _Tab.eyes:
        return [
          _OptionRow(
            label: 'Eyes',
            options: [
              for (var i = 0; i < kEyeVariants.length; i++)
                _Option(
                  config: c.copyWith(eyesIndex: i),
                  crop: AvatarCrop.face,
                  selected: c.eyesIndex == i,
                  label: 'Eyes ${i + 1}',
                  onTap: () => _set(c.copyWith(eyesIndex: i)),
                ),
            ],
          ),
          _OptionRow(
            label: 'Glasses',
            options: [
              for (var i = 0; i < kGlassesOptions.length; i++)
                _Option(
                  config: c.copyWith(glassesIndex: i),
                  crop: AvatarCrop.eyes,
                  selected: c.glassesIndex == i,
                  label: i == 0 ? 'No glasses' : 'Glasses $i',
                  onTap: () => _set(c.copyWith(glassesIndex: i)),
                ),
            ],
          ),
        ];
      case _Tab.mouth:
        return [
          _OptionRow(
            options: [
              for (var i = 0; i < kMouthVariants.length; i++)
                _Option(
                  config: c.copyWith(mouthIndex: i),
                  crop: AvatarCrop.face,
                  selected: c.mouthIndex == i,
                  label: 'Mouth ${i + 1}',
                  onTap: () => _set(c.copyWith(mouthIndex: i)),
                ),
            ],
          ),
        ];
      case _Tab.ears:
        if (hairCoversEars(c.hairIndex)) {
          return [
            _CoveredEarsNote(
              onChangeHair: () => setState(() => _tab = _Tab.hair),
            ),
          ];
        }
        return [
          _OptionRow(
            options: [
              for (var i = 0; i < kEarringsOptions.length; i++)
                _Option(
                  config: c.copyWith(earringsIndex: i),
                  crop: AvatarCrop.ear,
                  selected: c.earringsIndex == i,
                  label: i == 0 ? 'No earrings' : 'Earrings $i',
                  onTap: () => _set(c.copyWith(earringsIndex: i)),
                ),
            ],
          ),
        ];
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
                  height: 48,
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

/// A labelled row of thumbnail cells, five across, wrapping as needed.
class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.options, this.label});

  final List<_Option> options;
  final String? label;

  static const _columns = 5;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                label!,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cell =
                  (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
              return Wrap(
                spacing: _gap,
                runSpacing: _gap,
                children: [
                  for (final o in options)
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
              );
            },
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
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
                    width: 40,
                    height: 40,
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
      ),
    );
  }
}
