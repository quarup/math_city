import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_category.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/presentation/question/question_screen.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';

/// kDebugMode-only screen: pick any implemented concept and play one
/// question against it, bypassing the wheel and the DAG drip-feed.
///
/// Proficiency, stars, and unlock events are NOT written when entered via
/// this screen — the player profile stays clean across as many debug
/// rounds as you want to play.
class ConceptDebugScreen extends ConsumerStatefulWidget {
  const ConceptDebugScreen({super.key});

  @override
  ConsumerState<ConceptDebugScreen> createState() => _ConceptDebugScreenState();
}

class _ConceptDebugScreenState extends ConsumerState<ConceptDebugScreen> {
  // Default to multiple choice so distractors are exercised.
  ProficiencyBand _band = ProficiencyBand.challenging;

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'Debug screen reached in a non-debug build');

    final registry = ref.watch(generatorRegistryProvider);
    final implementedIds = registry.implementedConceptIds.toSet();

    // Group implemented concepts by category, preserving curriculum.md
    // category order and within-category row order.
    final byCategory = <String, List<Concept>>{};
    for (final c in allConcepts) {
      if (!implementedIds.contains(c.id)) continue;
      byCategory.putIfAbsent(c.categoryId, () => []).add(c);
    }
    for (final list in byCategory.values) {
      list.sort((a, b) => a.categoryRowOrder.compareTo(b.categoryRowOrder));
    }
    final orderedCategories = allCategories.toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug — Generator preview'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text('Answer mode:  '),
                Expanded(
                  child: SegmentedButton<ProficiencyBand>(
                    segments: const [
                      ButtonSegment(
                        value: ProficiencyBand.challenging,
                        label: Text('Multiple choice'),
                        icon: Icon(Icons.list_alt_rounded),
                      ),
                      ButtonSegment(
                        value: ProficiencyBand.comfortable,
                        label: Text('Keypad'),
                        icon: Icon(Icons.dialpad_rounded),
                      ),
                    ],
                    selected: {_band},
                    onSelectionChanged: (s) => setState(() => _band = s.first),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                for (final cat in orderedCategories)
                  if (byCategory[cat.id]?.isNotEmpty ?? false)
                    _CategoryGroup(
                      category: cat,
                      concepts: byCategory[cat.id]!,
                      onTap: _openQuestion,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openQuestion(Concept concept) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuestionScreen(
            conceptId: concept.id,
            band: _band,
            debugMode: true,
          ),
        ),
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({
    required this.category,
    required this.concepts,
    required this.onTap,
  });

  final ConceptCategory category;
  final List<Concept> concepts;
  final ValueChanged<Concept> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(
        category.displayName,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text('${concepts.length} implemented'),
      initiallyExpanded: true,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final c in concepts)
          ListTile(
            dense: true,
            title: Text(c.name),
            subtitle: Text(c.id, style: theme.textTheme.bodySmall),
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                'G${c.primaryGrade}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => onTap(c),
          ),
      ],
    );
  }
}
