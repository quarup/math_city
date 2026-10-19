import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/questions/answer_check.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/presentation/block/block_recap.dart';
import 'package:math_city/presentation/diagrams/diagram_renderer.dart';
import 'package:math_city/presentation/question/question_screen.dart';
import 'package:math_city/presentation/question/scratch_pad.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/widgets/math_text.dart';
import 'package:math_city/presentation/widgets/on_side.dart';
import 'package:math_city/presentation/widgets/speech.dart';
import 'package:math_city/presentation/widgets/speech_toggle_button.dart';
import 'package:math_city/services/debug_harness.dart';
import 'package:math_city/services/tts_service.dart';
import 'package:math_city/state/tts_provider.dart';

/// The wrong-answer explanation screen — the teaching moment, kept as a full
/// screen on purpose. In real play it appears only for a wrong answer inside
/// a [QuestionBlock] (a correct answer plays a coin animation and moves
/// straight on); in debug mode (`ConceptDebugScreen`, the UX-sweep harness)
/// it still renders the green "Correct!" state too, so a generator can be
/// checked end-to-end without a block.
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    required this.question,
    required this.selectedAnswer,
    required this.outcome,
    this.block,
    this.debugMode = false,
    this.ink,
    super.key,
  }) : assert(debugMode || block != null, 'real play always runs in a block');

  final GeneratedQuestion question;
  final String selectedAnswer;

  /// What the player wrote on the scratch pad, shown beside the
  /// explanation on the red screen so they can find where it went wrong.
  /// Null when the question had no pad or nothing was written.
  final ScratchInk? ink;

  /// Three-way classification of [selectedAnswer] vs the question's
  /// canonical answer (see `answer_check.dart`). `canonical` and
  /// `equivalentNonCanonical` both render the success state; the latter
  /// also surfaces a friendly nudge with the canonical form.
  final AnswerOutcome outcome;

  /// The block this question belonged to (already updated with this
  /// answer's reward). Drives the button: next question, or the summary.
  final QuestionBlock? block;

  /// When true, "Try another" pops back to the debug picker instead of
  /// continuing a block.
  final bool debugMode;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  /// Cached in `initState`: `ref` is unsafe once the widget has been
  /// deactivated, so `dispose` cannot look the service up itself.
  late final TtsService _tts;

  /// The block's next question, drawn up front so the button can say
  /// "See results" when the concept has run out of new ones (the draw then
  /// shortens the block).
  GeneratedQuestion? _next;

  /// What the red screen reads: the player's answer, then each step of
  /// the explanation. Empty on a correct answer, which shows no
  /// explanation.
  List<SpeechItem> get _speechItems => widget.outcome != AnswerOutcome.wrong
      ? const []
      : [
          SpeechItem('answered', 'You answered: ${widget.selectedAnswer}'),
          for (var i = 0; i < widget.question.explanation.length; i++)
            SpeechItem('step:$i', widget.question.explanation[i]),
        ];

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
    final block = widget.block;
    if (block != null && !block.isOver) _next = drawNextQuestion(ref, block);
    DebugHarness.instance.attachResult(outcome: widget.outcome);
    final items = _speechItems;
    if (items.isNotEmpty) {
      // Defer so the provider read happens after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(speakAllIfEnabled(ref, items, owner: this));
      });
    }
  }

  @override
  void dispose() {
    unawaited(_tts.stop(owner: this));
    super.dispose();
  }

  void _onNext() {
    if (widget.debugMode) {
      Navigator.of(context).pop();
      return;
    }
    final block = widget.block!;
    final next = _next;
    if (block.isOver || next == null) {
      finishBlock(context, ref, block);
      return;
    }
    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => QuestionScreen(
            conceptId: block.conceptId,
            band: block.band,
            block: block,
            question: next,
          ),
        ),
      ),
    );
  }

  String get _buttonLabel {
    if (widget.debugMode) return 'Try another';
    return widget.block!.isComplete ? 'See results' : 'Next question';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final isCorrect = widget.outcome != AnswerOutcome.wrong;
    final isEquivalentNonCanonical =
        widget.outcome == AnswerOutcome.equivalentNonCanonical;
    final ink = isCorrect ? palette.successGreenDeep : palette.errorRedDeep;

    // The verdict is a title row, not a billboard: a 30 dp icon and the
    // words between the stop button and the read-aloud toggle. The colour
    // of the whole screen already says it.
    final titleRow = SizedBox(
      height: 52,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Stop',
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 30,
                  color: ink,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isCorrect ? 'Correct!' : 'Not quite…',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Keeps the title centred on the green screen too.
          if (isCorrect)
            const SizedBox(width: 48)
          else
            const SpeechToggleIconButton(),
        ],
      ),
    );

    final button = FilledButton(
      onPressed: _onNext,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        textStyle: theme.textTheme.titleLarge,
      ),
      child: Text(_buttonLabel),
    );

    return Scaffold(
      backgroundColor: isCorrect
          ? palette.successGreenSoft
          : palette.errorRedSoft,
      body: SpeechScope(
        service: _tts,
        owner: this,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final side = isOnSide(c);
              final Widget body;
              if (!isCorrect) {
                body = side ? _wrongOnSide(button) : _wrongUpright(button);
              } else {
                body = _correct(
                  theme,
                  ink,
                  button,
                  side: side,
                  nudge: isEquivalentNonCanonical,
                );
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: titleRow,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        side ? 24 : 20,
                        4,
                        side ? 24 : 20,
                        side ? 14 : 16,
                      ),
                      child: body,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The explanation, scrolling. The speaker on its corner pokes above it,
  /// so the scroll view keeps a little headroom and does not clip.
  Widget get _explanation => SingleChildScrollView(
    clipBehavior: Clip.none,
    padding: const EdgeInsets.only(top: 14, right: 10),
    child: _ExplanationCard(
      selectedAnswer: widget.selectedAnswer,
      explanation: widget.question.explanation,
      diagram: widget.question.explanationDiagram,
      speechItems: _speechItems,
    ),
  );

  Widget get _answerTile => _AnswerTile(answer: widget.question.correctAnswer);

  Widget? get _work => widget.ink == null ? null : _WorkCard(ink: widget.ink!);

  /// On a side: the explanation on the left, the answer at the top of the
  /// right pane and Next at its bottom — with the player's work filling the
  /// right pane between them when there is any.
  Widget _wrongOnSide(Widget button) {
    final work = _work;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: _explanation),
        const SizedBox(width: 24),
        Expanded(
          flex: work == null ? 1 : 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _answerTile,
              ),
              if (work == null)
                const Spacer()
              else ...[
                const SizedBox(height: 10),
                Expanded(child: work),
                const SizedBox(height: 12),
              ],
              button,
            ],
          ),
        ),
      ],
    );
  }

  /// Upright: the answer under the title, the explanation scrolling in
  /// the middle, Next pinned at the bottom. With the player's work, the
  /// explanation takes what it needs (up to half) and the work the rest.
  Widget _wrongUpright(Widget button) {
    final work = _work;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _answerTile,
        if (work == null)
          Expanded(child: _explanation)
        else ...[
          Flexible(child: _explanation),
          const SizedBox(height: 10),
          Expanded(child: work),
        ],
        const SizedBox(height: 12),
        button,
      ],
    );
  }

  /// The green screen (debug mode only in real play): the equivalence
  /// nudge if there is one, Next at the bottom right on a side and across
  /// the bottom upright.
  Widget _correct(
    ThemeData theme,
    Color ink,
    Widget button, {
    required bool side,
    required bool nudge,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: Center(
          child: nudge
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: EquivalentNudgeCard(
                    playerAnswer: widget.selectedAnswer,
                    canonical: widget.question.correctAnswer,
                  ),
                )
              : Icon(Icons.check_circle_rounded, size: 96, color: ink),
        ),
      ),
      const SizedBox(height: 12),
      if (side)
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(width: 280, child: button),
        )
      else
        button,
    ],
  );
}

/// The player's own scratch-pad page, scaled to fit, so the working can be
/// compared with the explanation line by line.
class _WorkCard extends StatelessWidget {
  const _WorkCard({required this.ink});

  final ScratchInk ink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerLowest,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: Text(
                'YOUR WORK',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(
                  painter: InkPainter(ink: ink),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The right answer, stated once, big and green, so a child who skims the
/// explanation still leaves with it.
class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.answer});

  final String answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Card(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 2,
          children: [
            Text(
              'THE ANSWER',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            MathText(
              answer,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.successGreenDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The explanation, with one speaker on its corner that reads the whole
/// card again; each line is ringed as the voice reaches it.
class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({
    required this.selectedAnswer,
    required this.explanation,
    required this.speechItems,
    this.diagram,
  });

  final String selectedAnswer;
  final List<String> explanation;
  final List<SpeechItem> speechItems;
  final DiagramSpec? diagram;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final lineRadius = BorderRadius.circular(6);
    return Stack(
      // Passthrough, not the default loose fit: the card must take the
      // width it is given (full width on a tablet), not shrink to its text
      // while the speaker stays pinned to the far edge.
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        Card(
          color: theme.colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SpeakingRing(
                  itemId: 'answered',
                  borderRadius: lineRadius,
                  child: SpokenWords(
                    'You answered: $selectedAnswer',
                    itemId: 'answered',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.errorRedDeep,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (diagram != null) ...[
                  Center(child: DiagramRenderer(spec: diagram!)),
                  const SizedBox(height: 12),
                ],
                for (var i = 0; i < explanation.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SpeakingRing(
                      itemId: 'step:$i',
                      borderRadius: lineRadius,
                      child: SpokenWords(
                        explanation[i],
                        itemId: 'step:$i',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -12,
          right: -8,
          child: SpeakerChip(
            items: speechItems,
            tooltip: 'Hear the explanation',
            solid: true,
          ),
        ),
      ],
    );
  }
}

/// Friendly nudge when the player's answer is mathematically equivalent
/// but not in canonical (lowest-terms / textbook) form. Resolves [GitHub
/// issue #2 option (c)] — we accepted the answer, now teach the
/// simplification. Shown on the debug green screen and, in a block, as a
/// brief overlay while the coin flies (see `QuestionScreen`).
class EquivalentNudgeCard extends StatelessWidget {
  const EquivalentNudgeCard({
    required this.playerAnswer,
    required this.canonical,
    super.key,
  });

  final String playerAnswer;
  final String canonical;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Card(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.successGreenDeep, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: palette.successGreenDeep,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MathText(
                "You said $playerAnswer — that's equal to $canonical!",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
