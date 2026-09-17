import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/domain/questions/answer_check.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/is_word_problem.dart';
import 'package:math_city/presentation/block/block_summary_screen.dart';
import 'package:math_city/presentation/diagrams/diagram_renderer.dart';
import 'package:math_city/presentation/question/number_pad_widget.dart';
import 'package:math_city/presentation/result/result_screen.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/widgets/coin_icon.dart';
import 'package:math_city/presentation/widgets/coin_pop.dart';
import 'package:math_city/presentation/widgets/math_text.dart';
import 'package:math_city/presentation/widgets/speech_toggle_button.dart';
import 'package:math_city/presentation/widgets/streak_flame.dart';
import 'package:math_city/services/debug_harness.dart';
import 'package:math_city/services/tts_service.dart';
import 'package:math_city/state/game_session_provider.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';
import 'package:math_city/state/player_provider.dart';
import 'package:math_city/state/proficiency_provider.dart';
import 'package:math_city/state/tts_provider.dart';

/// One question. In real play it's one step of a [QuestionBlock]: a correct
/// answer plays a coin animation into the AppBar counter and moves straight
/// on to the next question (or the block summary) — no green screen; a wrong
/// answer goes to the red explanation screen, which then continues the
/// block. In debug mode (no block) it keeps the original single-question
/// semantics — answer → [ResultScreen] → pop — which is what the UX-sweep
/// harness drives.
class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({
    required this.conceptId,
    required this.band,
    this.block,
    this.debugMode = false,
    this.seed,
    super.key,
  }) : assert(debugMode || block != null, 'real play always runs in a block');

  final String conceptId;

  /// The proficiency band at the time the wheel landed. Determines input
  /// mode (MC vs number pad), which in turn sets the pay rate.
  final ProficiencyBand band;

  /// The block this question belongs to (null in debug mode).
  final QuestionBlock? block;

  /// When true (kDebugMode-only entry from `ConceptDebugScreen` and the
  /// UX-sweep harness): proficiency tracking is skipped, no coins are paid,
  /// and the result screen pops back to the picker instead of continuing a
  /// block. Player profile state stays untouched.
  final bool debugMode;

  /// When set, the question and its choice order are drawn from
  /// `Random(seed)` instead of an unseeded one, so the same seed replays
  /// the identical question. Used by the kDebugMode UX-sweep harness to
  /// show the same question twice — once answered right, once wrong.
  final int? seed;

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen>
    with SingleTickerProviderStateMixin {
  GeneratedQuestion? _question;
  List<String> _shuffledChoices = const [];
  bool _useNumberPad = false;
  bool _answered = false;

  /// Cached in `initState`: `ref` is unsafe once the widget has been
  /// deactivated, so `dispose` cannot look the service up itself.
  late final TtsService _tts;

  /// Where the last touch landed — the coin takes off from there, so it
  /// visibly leaves the choice (or keypad) the player just pressed.
  Offset? _lastPointerDown;

  /// While a payout is popping the counter shows this instead of the live
  /// balance (which the notifier has already persisted), so the number only
  /// jumps at the pop's peak.
  int? _frozenCoins;

  /// 1-based position of this question in its block, fixed at build time so
  /// the header doesn't tick over while the coin is still popping.
  late final int _questionNumber = widget.block?.currentIndex ?? 1;

  /// Counter reaction when the balance changes: a quick grow-and-settle
  /// plus a bright flash that fades over the same beat.
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseFlash;
  final List<OverlayEntry> _liveOverlays = <OverlayEntry>[];

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.5), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1), weight: 65),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
    _pulseFlash = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.75), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 0), weight: 80),
    ]).animate(_pulseCtrl);
    unawaited(_loadQuestion());
  }

  Future<void> _loadQuestion() async {
    final source = await ref.read(questionSourceProvider.future);
    if (!mounted) return;
    // One Random drives both the generator and the choice shuffle, so a
    // given seed reproduces the screen exactly.
    final seed = widget.seed;
    final rand = seed == null ? null : Random(seed);
    final q = source.generate(widget.conceptId, random: rand);
    setState(() {
      _question = q;
      _shuffledChoices = List.of(q.allChoices)..shuffle(rand);
      _useNumberPad = _keypadEligible(q);
    });
    DebugHarness.instance.attachQuestion(
      question: q,
      displayedChoices: _shuffledChoices,
      usesKeypad: _useNumberPad,
      submit: (answer) => unawaited(_onAnswerSubmitted(answer)),
    );
    // Auto-read word problems only — bare equations like "3 + 4 = ?"
    // sound robotic when synthesised and don't help readers.
    if (isWordProblem(q.prompt)) {
      unawaited(speakIfEnabled(ref, q.prompt));
    }
  }

  @override
  void dispose() {
    // Silence anything still in flight when the player leaves the screen.
    unawaited(_tts.stop());
    for (final e in _liveOverlays) {
      e.remove();
    }
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// Keypad eligibility is gated by band, answer format, AND the question's
  /// own opt-out. The keypad can only enter numeric values (digits + a small
  /// extra-chars row); answer formats whose surface form is text-shaped
  /// (string, commaList) force MC even at the comfortable band. Questions
  /// that read against a list of choices ("Which of these is a factor of
  /// 24?") set `multipleChoiceOnly` — their answer is numeric, but more than
  /// one number is right and only the stored one is accepted.
  bool _keypadEligible(GeneratedQuestion q) =>
      widget.band == ProficiencyBand.comfortable &&
      !q.multipleChoiceOnly &&
      formatSupportsKeypad(q.answerFormat);

  Future<void> _onAnswerSubmitted(String answer) async {
    if (_answered) return;
    final question = _question;
    if (question == null) return;
    _answered = true;

    final outcome = checkAnswer(question, answer);
    final isCorrect = outcome != AnswerOutcome.wrong;

    // Debug mode: skip every persisted side-effect (proficiency, drip-feed,
    // coins) so testing a generator doesn't pollute player state, and keep
    // the single-question flow the harness expects.
    if (widget.debugMode) {
      unawaited(
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ResultScreen(
              question: question,
              selectedAnswer: answer,
              outcome: outcome,
              debugMode: true,
            ),
          ),
        ),
      );
      return;
    }

    final block = widget.block!;
    // Hold the counter at the pre-answer balance until the coin lands.
    final balanceBefore = ref.read(totalCoinsProvider);
    setState(() => _frozenCoins = balanceBefore);

    final reward = await ref
        .read(proficiencyProvider.notifier)
        .recordAnswer(
          widget.conceptId,
          correct: isCorrect,
          usesKeypad: _useNumberPad,
        );
    if (!mounted) return;
    block.record(reward);

    if (!isCorrect) {
      // The red screen is the teaching moment: it stays, and it counts as
      // one of the block's questions.
      unawaited(
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ResultScreen(
              question: question,
              selectedAnswer: answer,
              outcome: outcome,
              block: block,
            ),
          ),
        ),
      );
      return;
    }

    await _celebrate(reward, outcome, answer, balanceBefore);
    if (!mounted) return;
    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => block.isComplete
              ? BlockSummaryScreen(block: block)
              : QuestionScreen(
                  conceptId: widget.conceptId,
                  band: widget.band,
                  block: block,
                ),
        ),
      ),
    );
  }

  /// Correct-answer feedback, in place of the old green screen: the coin
  /// pops in place over the tapped answer while the counter flashes and
  /// pulses to the new balance, a nudge shows if the answer was equivalent
  /// but not canonical, and a band crossing gets its own bigger card plus a
  /// second coin pop for the bonus.
  Future<void> _celebrate(
    AnswerReward reward,
    AnswerOutcome outcome,
    String answer,
    int balanceBefore,
  ) async {
    final size = MediaQuery.of(context).size;
    final from = _lastPointerDown ?? Offset(size.width / 2, size.height * 0.75);

    await _popCoins(
      at: from,
      amount: reward.coins,
      // At the peak: reveal the answer pay (but hold back any bonus until
      // its card) and let the counter react.
      onPeak: () {
        setState(
          () => _frozenCoins = reward.bandBonuses.isEmpty
              ? null
              : balanceBefore + reward.coins,
        );
        unawaited(_pulseCtrl.forward(from: 0));
      },
    );
    if (!mounted) return;

    if (outcome == AnswerOutcome.equivalentNonCanonical) {
      await _showCard(
        EquivalentNudgeCard(
          playerAnswer: answer,
          canonical: _question!.correctAnswer,
        ),
        const Duration(milliseconds: 1800),
      );
      if (!mounted) return;
    }

    for (final bonus in reward.bandBonuses) {
      await _showCard(
        _BandBonusBurst(bonus: bonus),
        const Duration(milliseconds: 1600),
      );
      if (!mounted) return;
      await _popCoins(
        at: Offset(size.width / 2, size.height / 2),
        amount: bonus.coins,
        onPeak: () {
          setState(() => _frozenCoins = null);
          unawaited(_pulseCtrl.forward(from: 0));
        },
      );
      if (!mounted) return;
    }
    if (_frozenCoins != null) setState(() => _frozenCoins = null);
  }

  /// Shows a [CoinPop] at [at] and calls [onPeak] when it is biggest, so
  /// the counter changes while the coin is large.
  Future<void> _popCoins({
    required Offset at,
    required int amount,
    VoidCallback? onPeak,
  }) async {
    final entry = OverlayEntry(
      builder: (_) => CoinPop(at: at, amount: amount),
    );
    Overlay.of(context).insert(entry);
    _liveOverlays.add(entry);
    final peak = kCoinPopDuration * CoinPop.peakFraction;
    await Future<void>.delayed(peak);
    if (mounted) onPeak?.call();
    await Future<void>.delayed(kCoinPopDuration - peak);
    if (_liveOverlays.remove(entry)) entry.remove();
  }

  Future<void> _showCard(Widget card, Duration hold) async {
    final entry = OverlayEntry(
      builder: (_) => _CenteredCard(child: card),
    );
    await _hold(entry, hold);
  }

  Future<void> _hold(OverlayEntry entry, Duration duration) async {
    Overlay.of(context).insert(entry);
    _liveOverlays.add(entry);
    await Future<void>.delayed(duration);
    if (_liveOverlays.remove(entry)) entry.remove();
  }

  @override
  Widget build(BuildContext context) {
    // Re-read the prompt when the user flips the speech toggle off→on, so
    // they can hear what's currently on screen. We only react to a true
    // user transition (AsyncData(false) → AsyncData(true)) — the initial
    // loading→AsyncData(true) emission is suppressed so the load path
    // (which already calls `speakIfEnabled` once) doesn't double-speak.
    ref.listen<AsyncValue<bool>>(ttsEnabledProvider, (prev, next) {
      final wasExplicitlyOff = prev is AsyncData<bool> && !prev.value;
      final isOn = next is AsyncData<bool> && next.value;
      if (!wasExplicitlyOff || !isOn) return;
      final q = _question;
      if (q == null) return;
      if (!isWordProblem(q.prompt)) return;
      unawaited(ref.read(ttsServiceProvider).speak(q.prompt));
    });

    final theme = Theme.of(context);
    final conceptName =
        findConceptById(widget.conceptId)?.name ?? widget.conceptId;
    final question = _question;
    final block = widget.block;

    final title = block == null || block.size == 1
        ? Text(conceptName, overflow: TextOverflow.ellipsis)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conceptName,
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Question $_questionNumber of ${block.size}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          );

    final actions = <Widget>[
      if (question != null && isWordProblem(question.prompt))
        const SpeechToggleIconButton(),
      if (block != null) ...[
        StreakBadge(count: _streakCount(block)),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            // A warm-white wash over icon and digits, strongest right as
            // the number changes, gone by the end of the pulse.
            builder: (_, child) => ColorFiltered(
              colorFilter: ColorFilter.mode(
                const Color(0xFFFFF3B0).withValues(alpha: _pulseFlash.value),
                BlendMode.srcATop,
              ),
              child: ScaleTransition(scale: _pulseScale, child: child),
            ),
            child: CoinAmount(
              amount: _frozenCoins ?? ref.watch(totalCoinsProvider),
              iconSize: 22,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ];

    if (question == null) {
      return Scaffold(
        appBar: AppBar(
          title: title,
          automaticallyImplyLeading: false,
          actions: actions,
        ),
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: title,
        automaticallyImplyLeading: false,
        actions: actions,
      ),
      body: SafeArea(
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) => _lastPointerDown = e.position,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // With a diagram: the diagram is measured FIRST at its
                // natural size (capped at 45% of the space, so a long
                // prompt can never crush it into a speck), and the prompt
                // card gets the true remainder — a short diagram (ruler,
                // number line) hands its unused space to the card instead
                // of reserving a fixed slot that left the card clipped
                // mid-glyph while empty space sat above it. The card
                // scrolls only when the prompt genuinely exceeds what's
                // left.
                //
                // Without one: the card scrolls if a long word problem
                // exceeds the space above the keypad (an unflexed card
                // overflowed there by design of the diagram path).
                Expanded(
                  child: question.diagram == null
                      ? Center(
                          child: SingleChildScrollView(
                            child: _PromptCard(prompt: question.prompt),
                          ),
                        )
                      : CustomMultiChildLayout(
                          delegate: _DiagramThenCardLayout(),
                          children: [
                            LayoutId(
                              id: _QuestionSlot.diagram,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) => FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: ConstrainedBox(
                                      // Bound the width so self-sizing
                                      // diagram widgets lay out at phone
                                      // width; FittedBox then scales the
                                      // result down if the 45% cap binds.
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth,
                                      ),
                                      child: DiagramRenderer(
                                        spec: question.diagram!,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            LayoutId(
                              id: _QuestionSlot.card,
                              child: SingleChildScrollView(
                                child: _PromptCard(
                                  prompt: question.prompt,
                                  compact: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                if (_useNumberPad)
                  NumberPadWidget(
                    onSubmit: _onAnswerSubmitted,
                    extraChars: _extraCharsFor(question),
                  )
                else
                  ..._shuffledChoices.map(
                    (choice) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _ChoiceButton(
                        label: choice,
                        onTap: () => _onAnswerSubmitted(choice),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Streak to show in the AppBar: the count after the block's last answer,
  /// else the persisted count the player walked in with.
  int _streakCount(QuestionBlock block) =>
      block.streakCount ??
      (ref.watch(activePlayerProvider).value?.streakCount ?? 0);
}

/// Whether the on-screen number pad can produce a valid answer for this
/// format. `string` and `commaList` are text-shaped (English words,
/// comma-separated mixed-form lists) and don't fit the pad's digit + few
/// extra-chars model — those force MC even at the comfortable band.
///
/// Exposed (rather than file-private) so the keypad/MC gate has a
/// unit-test contract that doesn't require pumping a widget.
bool formatSupportsKeypad(AnswerFormat fmt) {
  switch (fmt) {
    case AnswerFormat.integer:
    case AnswerFormat.fraction:
    case AnswerFormat.mixedNumber:
    case AnswerFormat.decimal:
      return true;
    case AnswerFormat.string:
    case AnswerFormat.commaList:
      return false;
  }
}

/// Symbol keys the pad shows above the digits, derived from the union of
/// ALL four choices — never from the correct answer alone, which leaked
/// it: a − key appeared iff the answer was negative (fatal in a concept
/// about sign rules) and the / key vanished iff a fraction sum happened
/// to simplify to a whole number.
///
/// Distractors are crafted to cover the plausible answer shapes (sign
/// flips, un-reduced fractions), so their union is exactly "what this
/// question type may need" without saying which shape is right. Only
/// known pad symbols are surfaced (dataset distractors can carry commas
/// and other untypeable notation), and the ASCII hyphen is folded into
/// the typeset − the parsers accept.
///
/// Exposed for unit tests.
List<String> extraKeypadCharsFor(GeneratedQuestion q) {
  const order = ['−', '+', '.', '/', ' ', ':', 'R'];
  final present = <String>{};
  for (final choice in q.allChoices) {
    for (final raw in choice.split('')) {
      final c = raw == '-' ? '−' : raw;
      if (order.contains(c)) present.add(c);
    }
  }
  return [
    for (final c in order)
      if (present.contains(c)) c,
  ];
}

List<String> _extraCharsFor(GeneratedQuestion q) => extraKeypadCharsFor(q);

// ---------------------------------------------------------------------------
// Celebration overlays
// ---------------------------------------------------------------------------

/// Centres a card over the question with a dim scrim and a springy scale-in.
class _CenteredCard extends StatelessWidget {
  const _CenteredCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.25),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Material(
                  color: Colors.transparent,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The band-crossing celebration — bigger than a routine payout: a star
/// badge, the "you learned something new" headline, and the bonus amount.
class _BandBonusBurst extends StatelessWidget {
  const _BandBonusBurst({required this.bonus});

  final BandCrossingBonus bonus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final name = findConceptById(bonus.conceptId)?.name ?? bonus.conceptId;
    return Card(
      color: theme.colorScheme.surfaceContainerLowest,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: palette.coinGold, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stars_rounded, color: palette.coinGold, size: 64),
            const SizedBox(height: 8),
            Text(
              bandBonusHeadline(bonus.band),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.coinGoldDeep,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            CoinAmount(
              amount: bonus.coins,
              prefix: '+',
              iconSize: 34,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.coinGoldDeep,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'bonus coins',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Diagram + prompt-card layout
// ---------------------------------------------------------------------------

enum _QuestionSlot { diagram, card }

/// Sequential two-slot layout: the diagram is measured first at its
/// natural size (its max height capped at 45% of the available space so
/// a long prompt can never crush it), then the prompt card receives
/// everything that remains. A fixed reserved slot either crushed the
/// card under a short diagram or wasted the space a big diagram never
/// claimed; measuring in order gives each question the split it needs.
/// The pair is vertically centred when both fit with room to spare.
class _DiagramThenCardLayout extends MultiChildLayoutDelegate {
  static const _gap = 16.0;

  @override
  void performLayout(Size size) {
    final diagramSize = layoutChild(
      _QuestionSlot.diagram,
      BoxConstraints(
        maxWidth: size.width,
        maxHeight: size.height * 0.45,
      ),
    );
    final cardSize = layoutChild(
      _QuestionSlot.card,
      BoxConstraints(
        // The card stretches to the full width (matching the old
        // stretched Column) and scrolls when the prompt exceeds the
        // remaining height.
        minWidth: size.width,
        maxWidth: size.width,
        maxHeight: (size.height - diagramSize.height - _gap).clamp(
          0.0,
          size.height,
        ),
      ),
    );
    final used = diagramSize.height + _gap + cardSize.height;
    final top = ((size.height - used) / 2).clamp(0.0, size.height);
    positionChild(
      _QuestionSlot.diagram,
      Offset((size.width - diagramSize.width) / 2, top),
    );
    positionChild(
      _QuestionSlot.card,
      Offset(0, top + diagramSize.height + _gap),
    );
  }

  @override
  bool shouldRelayout(_DiagramThenCardLayout oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt, this.compact = false});

  final String prompt;

  /// True when a diagram shares the screen with the card: the card has
  /// less height to work with, so the step-down to the smaller text
  /// size kicks in earlier (a ~110-char prompt at headline size clipped
  /// behind the keypad next to a tall diagram).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Long word problems step down a text size so four-line prompts fit
    // above the keypad instead of scrolling out of view mid-word.
    final style = prompt.length > (compact ? 90 : 120)
        ? theme.textTheme.titleLarge
        : theme.textTheme.headlineMedium;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: MathText(
          prompt,
          style: style?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        textStyle: theme.textTheme.headlineSmall,
      ),
      child: MathText(label),
    );
  }
}
