import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/domain/questions/answer_check.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/is_word_problem.dart';
import 'package:math_city/presentation/diagrams/diagram_renderer.dart';
import 'package:math_city/presentation/question/number_pad_widget.dart';
import 'package:math_city/presentation/result/result_screen.dart';
import 'package:math_city/presentation/widgets/speech_toggle_button.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';
import 'package:math_city/state/proficiency_provider.dart';
import 'package:math_city/state/tts_provider.dart';

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({
    required this.conceptId,
    required this.band,
    this.debugMode = false,
    super.key,
  });

  final String conceptId;

  /// The proficiency band at the time the wheel landed.
  /// Determines input mode (MC vs number pad) and stars awarded.
  final ProficiencyBand band;

  /// When true (kDebugMode-only entry from `ConceptDebugScreen`):
  /// proficiency tracking is skipped, no stars are awarded, and the
  /// result screen pops back to the picker instead of returning to the
  /// spin wheel. Player profile state stays untouched.
  final bool debugMode;

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  GeneratedQuestion? _question;
  List<String> _shuffledChoices = const [];
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadQuestion());
  }

  Future<void> _loadQuestion() async {
    final source = await ref.read(questionSourceProvider.future);
    if (!mounted) return;
    final q = source.generate(widget.conceptId);
    setState(() {
      _question = q;
      _shuffledChoices = List.of(q.allChoices)..shuffle();
    });
    // Auto-read word problems only — bare equations like "3 + 4 = ?"
    // sound robotic when synthesised and don't help readers.
    if (isWordProblem(q.prompt)) {
      unawaited(speakIfEnabled(ref, q.prompt));
    }
  }

  @override
  void dispose() {
    // Silence anything still in flight when the player leaves the screen.
    unawaited(ref.read(ttsServiceProvider).stop());
    super.dispose();
  }

  Future<void> _onAnswerSubmitted(String answer) async {
    if (_answered) return;
    final question = _question;
    if (question == null) return;
    _answered = true;

    final outcome = checkAnswer(question, answer);
    final isCorrect = outcome != AnswerOutcome.wrong;

    // Debug mode: skip every persisted side-effect (proficiency, drip-feed,
    // stars) so testing a generator doesn't pollute player state.
    final unlock = widget.debugMode
        ? null
        : await ref
              .read(proficiencyProvider.notifier)
              .recordAnswer(widget.conceptId, correct: isCorrect);

    if (!mounted) return;

    final stars = (isCorrect && !widget.debugMode)
        ? bricksForBand(widget.band)
        : 0;

    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            question: question,
            selectedAnswer: answer,
            outcome: outcome,
            bricksEarned: stars,
            unlockEvent: isCorrect ? unlock : null,
            debugMode: widget.debugMode,
          ),
        ),
      ),
    );
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

    final conceptName =
        findConceptById(widget.conceptId)?.name ?? widget.conceptId;
    final question = _question;

    if (question == null) {
      // Hide the speaker until we know whether the prompt is speakable —
      // we don't yet know if this generator emits a word problem.
      return Scaffold(
        appBar: AppBar(
          title: Text(conceptName),
          automaticallyImplyLeading: false,
        ),
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final speakablePrompt = isWordProblem(question.prompt);

    // Keypad eligibility is gated by BOTH band AND answer format. The
    // keypad can only enter numeric values (digits + a small extra-chars
    // row); answer formats whose surface form is text-shaped (string,
    // commaList) force MC even at the comfortable band.
    final useNumberPad =
        widget.band == ProficiencyBand.comfortable &&
        formatSupportsKeypad(question.answerFormat);

    return Scaffold(
      appBar: AppBar(
        title: Text(conceptName),
        automaticallyImplyLeading: false,
        actions: [
          if (speakablePrompt) const SpeechToggleIconButton(),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (question.diagram != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Center(
                              child: DiagramRenderer(spec: question.diagram!),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        _PromptCard(prompt: question.prompt),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (useNumberPad)
                NumberPadWidget(
                  onSubmit: _onAnswerSubmitted,
                  extraChars: _extraCharsFor(question.correctAnswer),
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
    );
  }
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

/// Returns the non-digit characters present in [answer], in the order
/// they appear, deduplicated. The number pad surfaces these so younger
/// players doing pure arithmetic see only digits, while fraction (`/`)
/// and time (`:`) answers expose the symbols they need.
List<String> _extraCharsFor(String answer) {
  const digits = '0123456789';
  final seen = <String>{};
  final out = <String>[];
  for (final c in answer.split('')) {
    if (digits.contains(c)) continue;
    if (seen.add(c)) out.add(c);
  }
  return out;
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Text(
          prompt,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        textStyle: theme.textTheme.headlineSmall,
      ),
      child: Text(label),
    );
  }
}
