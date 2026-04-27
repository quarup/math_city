import 'dart:async';

import 'package:flutter/material.dart';
import 'package:math_dash/domain/concepts/concept_registry.dart';
import 'package:math_dash/domain/questions/arithmetic_generator.dart';
import 'package:math_dash/domain/questions/question.dart';
import 'package:math_dash/presentation/result/result_screen.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({required this.conceptId, super.key});

  final String conceptId;

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  late final Question _question;
  late final List<String> _shuffledChoices;

  @override
  void initState() {
    super.initState();
    _question = ArithmeticGenerator().generateForConcept(widget.conceptId);
    _shuffledChoices = List.of(_question.allChoices)..shuffle();
  }

  void _onChoiceTapped(String choice) {
    final isCorrect = choice == _question.correctAnswer;
    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            question: _question,
            selectedAnswer: choice,
            isCorrect: isCorrect,
            starsEarned: isCorrect ? 5 : 0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conceptName =
        findConceptById(widget.conceptId)?.name ?? widget.conceptId;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(conceptName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              _PromptCard(prompt: _question.prompt),
              const Spacer(),
              ..._shuffledChoices.map(
                (choice) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _ChoiceButton(
                    label: choice,
                    onTap: () => _onChoiceTapped(choice),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Text(
          prompt,
          style: theme.textTheme.displayMedium?.copyWith(
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
