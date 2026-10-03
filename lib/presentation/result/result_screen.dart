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
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/widgets/math_text.dart';
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
    super.key,
  }) : assert(debugMode || block != null, 'real play always runs in a block');

  final GeneratedQuestion question;
  final String selectedAnswer;

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
    return Scaffold(
      backgroundColor: isCorrect
          ? palette.successGreenSoft
          : palette.errorRedSoft,
      body: SpeechScope(
        service: _tts,
        owner: this,
        child: SafeArea(
          child: Stack(
            children: [
              // Stop answering: pops the chain back to the wheel over the
              // site (a debug question just returns to the concept list).
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Stop',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              if (!isCorrect)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: SpeechToggleIconButton(),
                ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 80,
                      color: isCorrect
                          ? palette.successGreenDeep
                          : palette.errorRedDeep,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isCorrect ? 'Correct!' : 'Not quite…',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCorrect
                            ? palette.successGreenDeep
                            : palette.errorRedDeep,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isEquivalentNonCanonical) ...[
                      const SizedBox(height: 16),
                      EquivalentNudgeCard(
                        playerAnswer: widget.selectedAnswer,
                        canonical: widget.question.correctAnswer,
                      ),
                    ],
                    if (!isCorrect) ...[
                      const SizedBox(height: 24),
                      _ExplanationCard(
                        selectedAnswer: widget.selectedAnswer,
                        explanation: widget.question.explanation,
                        diagram: widget.question.explanationDiagram,
                        speechItems: _speechItems,
                      ),
                    ],
                    const Spacer(),
                    FilledButton(
                      onPressed: _onNext,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle: theme.textTheme.titleLarge,
                      ),
                      child: Text(_buttonLabel),
                    ),
                    const SizedBox(height: 12),
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
