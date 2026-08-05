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

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Lowercase, with `_`/`-` collapsed to spaces so "place value" matches
  /// `place_value` and vice versa.
  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp('[_-]+'), ' ');

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'Debug screen reached in a non-debug build');

    final registry = ref.watch(generatorRegistryProvider);
    final implementedIds = registry.implementedConceptIds.toSet();
    final query = _normalize(_query.trim());

    // Group implemented concepts by category, preserving curriculum.md
    // category order and within-category row order.
    final byCategory = <String, List<Concept>>{};
    for (final c in allConcepts) {
      if (!implementedIds.contains(c.id)) continue;
      if (query.isNotEmpty &&
          !_normalize(c.name).contains(query) &&
          !_normalize(c.id).contains(query)) {
        continue;
      }
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              autocorrect: false,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search by name or id…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        tooltip: 'Clear',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: byCategory.isEmpty
                ? Center(
                    child: Text(
                      'No concepts match "${_query.trim()}"',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView(
                    children: [
                      for (final cat in orderedCategories)
                        if (byCategory[cat.id]?.isNotEmpty ?? false)
                          _CategoryGroup(
                            // Re-key on the query so a category the user
                            // collapsed earlier springs back open for a new
                            // search instead of hiding its matches.
                            key: ValueKey('${cat.id}|$query'),
                            category: cat,
                            concepts: byCategory[cat.id]!,
                            filtering: query.isNotEmpty,
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
    required this.filtering,
    required this.onTap,
    super.key,
  });

  final ConceptCategory category;
  final List<Concept> concepts;
  final bool filtering;
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
      subtitle: Text(
        filtering
            ? '${concepts.length} matching'
            : '${concepts.length} implemented',
      ),
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
