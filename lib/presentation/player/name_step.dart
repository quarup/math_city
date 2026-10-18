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
/// name* for the kid who wants their own.
class NameStep extends ConsumerStatefulWidget {
  const NameStep({
    required this.avatar,
    required this.onNext,
    required this.onType,
    this.initial,
    this.onBack,
    this.step = 3,
    this.doneLabel = buildMyCityLabel,
    super.key,
  });

  final AdventurerConfig avatar;

  /// A name to show as already chosen (editing an existing player).
  final String? initial;
  final ValueChanged<String> onNext;
  final VoidCallback onType;
  final VoidCallback? onBack;
  final int? step;
  final NameDoneLabel doneLabel;

  @override
  ConsumerState<NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<NameStep> {
  static const _handSize = 5;
  static const _gap = 8.0;

  final _deck = NameDeck();
  late List<MathematicianName> _hand = _deck.next(_handSize);
  late String? _picked = widget.initial;

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
    _picked = null;
  });

  void _hear(String name) {
    // A tapped speaker bypasses the auto-read preference, like the
    // speaker buttons on the question screen. Just the name: saying
    // "Mayor" too confused kids, since it is not what the button shows.
    unawaited(_tts.speak(name, owner: this));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final picked = _picked;
    return StepScaffold(
      step: widget.step,
      onBack: widget.onBack,
      title: 'Your name',
      hero: HeroLead(
        config: widget.avatar,
        portraitSize: 88,
        badge: MayorBadge(name: picked),
      ),
      content: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: LayoutBuilder(
          builder: (context, c) {
            final rowH =
                ((c.maxHeight - _gap * (_handSize - 1) - 6) / _handSize).clamp(
                  40.0,
                  60.0,
                );
            return Column(
              children: [
                for (final (i, n) in _hand.indexed) ...[
                  if (i > 0) const SizedBox(height: _gap),
                  SizedBox(
                    height: rowH,
                    child: Row(
                      children: [
                        Expanded(
                          child: _NameTile(
                            name: n,
                            showFact: rowH >= 50,
                            selected: picked == n.name,
                            onTap: () => setState(() => _picked = n.name),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          child: OutlinedButton(
                            onPressed: () => _hear(n.name),
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
                            child: Semantics(
                              label: 'Hear ${n.name}',
                              child: const Icon(
                                Icons.volume_up_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        RowButton(
          label: 'More names',
          icon: Icons.shuffle_rounded,
          onPressed: _more,
        ),
        RowButton(
          label: 'Type my own name',
          icon: Icons.keyboard_alt_outlined,
          onPressed: widget.onType,
        ),
      ],
      footer: PrimaryButton(
        label: picked == null ? 'Choose a name' : widget.doneLabel(picked),
        onPressed: picked == null ? null : () => widget.onNext(picked),
      ),
    );
  }
}

class _NameTile extends StatelessWidget {
  const _NameTile({
    required this.name,
    required this.showFact,
    required this.selected,
    required this.onTap,
  });

  final MathematicianName name;
  final bool showFact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Semantics(
      button: true,
      selected: selected,
      label: name.name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              // Lighter on purpose: a hook for the kid who reads it, easy to
              // skip for the one who doesn't.
              if (showFact)
                Text(
                  name.fact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The gold "Mayor …" badge ("Mayor ?" until a name is chosen).
class MayorBadge extends StatelessWidget {
  const MayorBadge({required this.name, super.key});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final shown = name == null || name!.trim().isEmpty ? '?' : name!.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      decoration: BoxDecoration(
        color: palette.coinGold,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.coinGoldDeep, width: 2),
      ),
      child: Text(
        'Mayor $shown',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: palette.tileInk,
        ),
      ),
    );
  }
}

/// The typing screen behind *Type my own name*: just the badge, one text
/// box and *Cancel*. Kept apart from the name list so the two ways of
/// choosing never share a screen. The keyboard covers the bottom of the
/// screen rather than squeezing it: the box sits at the top of its pane,
/// and the keyboard's own done key submits.
class TypeNameStep extends StatefulWidget {
  const TypeNameStep({
    required this.avatar,
    required this.onNext,
    required this.onCancel,
    this.initial,
    this.step = 3,
    this.doneLabel = buildMyCityLabel,
    super.key,
  });

  final AdventurerConfig avatar;
  final String? initial;
  final ValueChanged<String> onNext;
  final VoidCallback onCancel;
  final int? step;
  final NameDoneLabel doneLabel;

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
        badge: MayorBadge(name: typed),
      ),
      content: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            children: [
              TextField(
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
                    vertical: 16,
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
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: palette.brandTealDeep,
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
      footer: PrimaryButton(
        label: typed.isEmpty ? 'Type a name' : widget.doneLabel(typed),
        onPressed: typed.isEmpty ? null : _submit,
      ),
    );
  }
}
