import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/presentation/diagrams/diagram_renderer.dart';
import 'package:math_city/presentation/question/number_pad_widget.dart';
import 'package:math_city/presentation/result/result_screen.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';
import 'package:math_city/state/proficiency_provider.dart';

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
  late final GeneratedQuestion _question;
  late final List<String> _shuffledChoices;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    final registry = ref.read(generatorRegistryProvider);
    _question = registry.generate(widget.conceptId);
    _shuffledChoices = List.of(_question.allChoices)..shuffle();
  }

  Future<void> _onAnswerSubmitted(String answer) async {
    if (_answered) return;
    _answered = true;

    final isCorrect = answer == _question.correctAnswer;

    // Debug mode: skip every persisted side-effect (proficiency, drip-feed,
    // stars) so testing a generator doesn't pollute player state.
    final unlock = widget.debugMode
        ? null
        : await ref
              .read(proficiencyProvider.notifier)
              .recordAnswer(widget.conceptId, correct: isCorrect);

    if (!mounted) return;

    final stars = (isCorrect && !widget.debugMode)
        ? starsForBand(widget.band)
        : 0;

    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            question: _question,
            selectedAnswer: answer,
            isCorrect: isCorrect,
            starsEarned: stars,
            unlockEvent: isCorrect ? unlock : null,
            debugMode: widget.debugMode,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conceptName =
        findConceptById(widget.conceptId)?.name ?? widget.conceptId;
    final useNumberPad = widget.band == ProficiencyBand.comfortable;

    return Scaffold(
      appBar: AppBar(
        title: Text(conceptName),
        automaticallyImplyLeading: false,
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
                        if (_question.diagram != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Center(
                              child: DiagramRenderer(spec: _question.diagram!),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        _PromptCard(prompt: _question.prompt),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (useNumberPad)
                NumberPadWidget(
                  onSubmit: _onAnswerSubmitted,
                  extraChars: _extraCharsFor(_question.correctAnswer),
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
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Text(
          prompt,
          style: theme.textTheme.displaySmall?.copyWith(
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
