import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/domain/avatar/mathematician_names.dart';
import 'package:math_city/presentation/player/creation_chrome.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/services/tts_service.dart';
import 'package:math_city/state/tts_provider.dart';

/// Longest name the town will print on a letter.
const kPlayerNameMaxLength = 20;

/// What the finished button says once a name is chosen.
typedef NameDoneLabel = String Function(String name);

/// Creating a player: the button walks straight into the city, so it
/// says where it goes rather than greeting the mayor.
String buildMyCityLabel(String name) => 'Build my city!';

/// Step 3: five famous mathematicians to borrow a surname from, a speaker
/// to hear each one, *More names* for another hand, and *Type my own
/// name*, which opens the keyboard screen and comes back here with the
/// typed name chosen: the button itself then shows the name, ringed like
/// a chosen tile, until a mathematician is tapped instead. The gold badge
/// under the face appears once a name is chosen.
class NameStep extends ConsumerStatefulWidget {
  const NameStep({
    required this.avatar,
    required this.onNext,
    this.initialName,
    this.onBack,
    this.step = 3,
    this.doneLabel = buildMyCityLabel,
    super.key,
  });

  final AdventurerConfig avatar;

  /// The player's current name when editing; shown on the own-name
  /// button, already chosen.
  final String? initialName;
  final ValueChanged<String> onNext;
  final VoidCallback? onBack;
  final int? step;
  final NameDoneLabel doneLabel;

  @override
  ConsumerState<NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<NameStep> {
  static const _handSize = 5;
  static const _gap = 8.0;
  static const _buttonH = 46.0;

  final _deck = NameDeck();
  late List<MathematicianName> _hand = _deck.next(_handSize);

  /// The name the kid typed, if any; kept to prefill the keyboard.
  late String? _typed = widget.initialName;

  /// The chosen name: a tile from the hand, or [_typed].
  late String? _chosen = widget.initialName;

  // Read once: `ref` is off limits in dispose.
  late final TtsService _tts;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
  }

  @override
  void dispose() {
    unawaited(_tts.stop(owner: this));
    super.dispose();
  }

  void _more() => setState(() {
    _hand = _deck.next(_handSize);
    // A chosen mathematician leaves with the hand; a typed name stays.
    if (_chosen != _typed) _chosen = null;
  });

  void _hear(String name) {
    // A tapped speaker bypasses the auto-read preference, like the
    // speaker buttons on the question screen. Just the name: saying
    // "Mayor" too confused kids, since it is not what the button shows.
    unawaited(_tts.speak(name, owner: this));
  }

  /// Opens the keyboard screen; Enter (or its button) comes back here
  /// with the typed name chosen, Cancel comes back unchanged.
  Future<void> _type() async {
    final typed = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => TypeNameStep(
          avatar: widget.avatar,
          initial: _typed,
          step: widget.step,
          onNext: (name) => Navigator.of(context).pop(name),
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (typed == null || !mounted) return;
    setState(() {
      _typed = typed;
      _chosen = typed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chosen = _chosen;
    final typed = _typed;
    return StepScaffold(
      step: widget.step,
      onBack: widget.onBack,
      title: 'Your name',
      hero: HeroLead(
        config: widget.avatar,
        portraitSize: 88,
        badge: chosen == null ? null : MayorBadge(name: chosen),
        reserveBadge: true,
      ),
      content: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > c.maxHeight;
            final rows = _hand.length;
            // The two buttons sit under the list: side by side on a wide
            // panel, stacked on a narrow one.
            final buttonsH = wide ? _buttonH : _buttonH * 2 + _gap;
            final gap = wide ? 6.0 : _gap;
            final rowH = ((c.maxHeight - buttonsH - gap * rows - 6) / rows)
                .clamp(
                  34.0,
                  60.0,
                );
            final more = RowButton(
              label: 'More names',
              icon: Icons.shuffle_rounded,
              onPressed: _more,
            );
            final ownChosen = typed != null && chosen == typed;
            final type = ownChosen
                ? _ChosenOwnName(name: typed, onPressed: _type)
                : RowButton(
                    label: 'Type my own name',
                    icon: Icons.keyboard_alt_outlined,
                    onPressed: _type,
                  );
            return Column(
              children: [
                for (final (i, n) in _hand.indexed) ...[
                  if (i > 0) SizedBox(height: gap),
                  SizedBox(
                    height: rowH,
                    child: _NameRow(
                      name: n,
                      selected: chosen == n.name,
                      showFact: rowH >= 44,
                      onTap: () => setState(() => _chosen = n.name),
                      onHear: () => _hear(n.name),
                    ),
                  ),
                ],
                SizedBox(height: gap),
                if (wide)
                  Row(
                    children: [
                      Expanded(child: more),
                      const SizedBox(width: _gap),
                      Expanded(child: type),
                    ],
                  )
                else ...[
                  more,
                  const SizedBox(height: _gap),
                  type,
                ],
              ],
            );
          },
        ),
      ),
      footer: PrimaryButton(
        label: chosen == null ? 'Choose a name' : widget.doneLabel(chosen),
        onPressed: chosen == null ? null : () => widget.onNext(chosen),
      ),
    );
  }
}

/// A name tile with its side button (a speaker, or a pencil for the
/// typed name).
class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.sideIcon,
    required this.sideLabel,
    required this.onSide,
  });

  final String title;
  final Widget? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData sideIcon;
  final String sideLabel;
  final VoidCallback onSide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            selected: selected,
            label: title,
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primaryContainer
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    width: 3,
                    color: selected
                        ? palette.brandTealDeep
                        : theme.colorScheme.surfaceContainerHigh,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    ?subtitle,
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          height: double.infinity,
          child: OutlinedButton(
            onPressed: onSide,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: palette.brandTealDeep,
              side: BorderSide(
                color: theme.colorScheme.surfaceContainerHigh,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Semantics(label: sideLabel, child: Icon(sideIcon, size: 20)),
          ),
        ),
      ],
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({
    required this.name,
    required this.selected,
    required this.showFact,
    required this.onTap,
    required this.onHear,
  });

  final MathematicianName name;
  final bool selected;
  final bool showFact;
  final VoidCallback onTap;
  final VoidCallback onHear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Tile(
      title: name.name,
      // Lighter on purpose: a hook for the kid who reads it, easy to
      // skip for the one who doesn't.
      subtitle: showFact
          ? Text(
              name.fact,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      selected: selected,
      onTap: onTap,
      sideIcon: Icons.volume_up_rounded,
      sideLabel: 'Hear ${name.name}',
      onSide: onHear,
    );
  }
}

/// The *Type my own name* button while the typed name is the chosen
/// one: ringed and tinted like a chosen tile, showing the name. Tapping
/// it reopens the keyboard with the name to change.
class _ChosenOwnName extends StatelessWidget {
  const _ChosenOwnName({required this.name, required this.onPressed});

  final String name;
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
        icon: const Icon(Icons.keyboard_alt_outlined, size: 20),
        label: Text(name, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: palette.brandTealDeep, width: 3),
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

/// The gold "Mayor …" badge.
class MayorBadge extends StatelessWidget {
  const MayorBadge({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      decoration: BoxDecoration(
        color: palette.coinGold,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.coinGoldDeep, width: 2),
      ),
      child: Text(
        'Mayor ${name.trim()}',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: palette.tileInk,
        ),
      ),
    );
  }
}

/// The keyboard screen behind *Type my own name*: the badge, one text
/// box, and *Cancel* / *Use name* right by it, so both stay above the
/// keyboard: under the box upright, beside it on a side, where the
/// keyboard leaves only a strip. It never saves: Enter, or *Use name*,
/// hands the name back to the list, where it is chosen and can still be
/// swapped for a mathematician. The keyboard covers the bottom rather
/// than squeezing the screen.
class TypeNameStep extends StatefulWidget {
  const TypeNameStep({
    required this.avatar,
    required this.onNext,
    required this.onCancel,
    this.initial,
    this.step = 3,
    super.key,
  });

  final AdventurerConfig avatar;
  final String? initial;
  final ValueChanged<String> onNext;
  final VoidCallback onCancel;
  final int? step;

  @override
  State<TypeNameStep> createState() => _TypeNameStepState();
}

class _TypeNameStepState extends State<TypeNameStep> {
  late final _controller = TextEditingController(text: widget.initial ?? '');

  String get _typed => _controller.text.trim();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_typed.isEmpty) return;
    widget.onNext(_typed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final typed = _typed;
    return StepScaffold(
      step: widget.step,
      onBack: widget.onCancel,
      resizeForKeyboard: false,
      title: 'Type your name',
      hint: const Text('A nickname is fine too.'),
      hero: HeroLead(
        config: widget.avatar,
        portraitSize: 110,
        badge: typed.isEmpty ? null : MayorBadge(name: typed),
        reserveBadge: true,
      ),
      content: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > c.maxHeight;
              final field = TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                maxLength: kPlayerNameMaxLength,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                onChanged: (_) => setState(() {}),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'Type here',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: palette.brandTealDeep,
                      width: 3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: palette.brandTealDeep,
                      width: 3,
                    ),
                  ),
                ),
              );
              final cancel = SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.brandTealDeep,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  child: const Text('Cancel'),
                ),
              );
              final use = SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: typed.isEmpty ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.brandTealDeep,
                    disabledBackgroundColor:
                        theme.colorScheme.surfaceContainerHigh,
                    disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Use name'),
                ),
              );
              if (wide) {
                // One row: the keyboard leaves little height on a side.
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: 10),
                    cancel,
                    const SizedBox(width: 10),
                    use,
                  ],
                );
              }
              return Column(
                children: [
                  field,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: cancel),
                      const SizedBox(width: 10),
                      Expanded(child: use),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
