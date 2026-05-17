// Build the Dart-const concept catalog from `curriculum.md` §3.x tables.
//
// Run from the repo root:
//
//   dart tools/curriculum/build_catalog.dart
//
// Reads `curriculum.md`, parses each `### 3.x ... (`category_id`)` table,
// and rewrites `lib/domain/concepts/concept_registry.dart`.
//
// Why Dart const (not JSON-loaded-by-Drift): at ~361 rows the binary-size
// delta is negligible and the const form keeps prereq validation at compile
// time. Re-running this script is the only way to author catalog rows.
//
// ── How to use ──
//
// 1. Edit `curriculum.md` §3.x — that's the single source of truth for
//    catalog rows (id, display, grade, prereqs, source, diagram).
// 2. Run this script. It will overwrite `concept_registry.dart`.
// 3. `flutter test` the catalog invariants and the dag_engine tests.
// 4. Commit `curriculum.md` and the regenerated registry together.
//
// ── Two override maps lower in the file ──
//
//  * `_shortLabelOverrides` — Display name → kid-facing wheel label.
//    Default is the Display column verbatim, but long Display names overflow
//    the wheel segment. Add an override here when a generator lands.
//
//  * `_prereqOverrides` — temporary simplification of the curriculum.md DAG.
//    Exists only to keep the drip-feed alive while Phase 6 fills in missing
//    generators for transitively-required prereqs (e.g. `mult_facts_within_100`
//    in curriculum lists `[mult_meaning_groups, skip_count_*]`, none of which
//    have generators yet — so we override to `[add_within_100]` for now).
//    REMOVE the override the moment the missing generator lands.

import 'dart:io';

void main(List<String> args) {
  final repoRoot = _detectRepoRoot();
  final inputPath = '$repoRoot/curriculum.md';
  final outputPath = '$repoRoot/lib/domain/concepts/concept_registry.dart';

  final content = File(inputPath).readAsStringSync();
  final concepts = _parse(content);

  _validate(concepts);

  final dart = _emit(concepts);
  File(outputPath).writeAsStringSync(dart);

  stdout.writeln(
    'Wrote ${concepts.length} concepts across '
    '${concepts.map((c) => c.categoryId).toSet().length} categories '
    '→ $outputPath',
  );
}

String _detectRepoRoot() {
  // Allow running from anywhere by walking up to the dir that contains
  // both `curriculum.md` and `pubspec.yaml`.
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    final hasCurriculum = File('${dir.path}/curriculum.md').existsSync();
    final hasPubspec = File('${dir.path}/pubspec.yaml').existsSync();
    if (hasCurriculum && hasPubspec) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'Could not find repo root (looking for curriculum.md + pubspec.yaml). '
    'Run from the repo root: dart tools/curriculum/build_catalog.dart',
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Override maps
// ─────────────────────────────────────────────────────────────────────────

/// Kid-facing wheel labels. Default is the curriculum.md Display column;
/// override here whenever a generator lands so the wheel segment stays
/// readable at small sizes.
const _shortLabelOverrides = <String, String>{
  'add_within_5': '+ to 5',
  'sub_within_5': '− from 5',
  'add_within_10': '+ to 10',
  'sub_within_10': '− from 10',
  'add_within_20': '+ to 20',
  'sub_within_20': '− from 20',
  'add_within_100': '+ to 100',
  'sub_within_100': '− from 100',
  'add_2digit_carry': '+ 2d carry',
  'sub_2digit_borrow': '− 2d borrow',
  'add_within_1000': '+ to 1000',
  'sub_within_1000': '− from 1000',
  'add_multidigit_standard_alg': '+ multi',
  'sub_multidigit_standard_alg': '− multi',
  'mult_facts_within_100': '× facts',
  'div_facts_within_100': '÷ facts',
  'div_with_remainder': '÷ w/ rem',
  'mult_4digit_by_1digit': '4d × 1d',
  'mult_2digit_by_2digit': '2d × 2d',
  'mult_multidigit_standard_alg': '× multi',
  'div_4digit_by_1digit': '4d ÷ 1d',
  'div_4digit_by_2digit': '4d ÷ 2d',
  'fraction_a_over_b': 'a/b',
  'compare_fractions_same_denom': 'cmp same d',
  'compare_fractions_same_num': 'cmp same n',
  'compare_fractions_unlike': 'cmp unlike',
  'equivalent_fractions_visual': 'equiv visual',
  'equivalent_fractions_compute': 'find equiv',
  'simplify_fraction': 'simplify',
  'improper_to_mixed': '→ mixed',
  'mixed_to_improper': '→ improper',
  'add_fractions_like_denom': '+ frac',
  'sub_fractions_like_denom': '− frac',
  'add_fractions_unlike_denom': '+ unlike',
  'sub_fractions_unlike_denom': '− unlike',
  'mult_fraction_by_whole': 'frac × N',
  'mult_fractions_proper': 'frac × frac',
  'div_unit_fraction_by_whole': '1/n ÷ N',
  'div_whole_by_unit_fraction': 'N ÷ 1/n',
  'div_fraction_by_fraction': 'frac ÷ frac',
  'fraction_as_division': '÷ as frac',
  'whole_number_as_fraction': 'N as frac',
  'add_mixed_like_denom': '+ mixed',
  'sub_mixed_like_denom': '− mixed',
  'add_mixed_unlike_denom': '+ mix unlk',
  'sub_mixed_unlike_denom': '− mix unlk',
  'mult_mixed_numbers': 'mixed ×',
  'mult_as_scaling': 'scaling',
  'time_to_hour_half': 'clock ½h',
  'time_to_5_min': 'clock 5m',
  'add_word_problems_within_100': '+− word',
  'add_sub_2step_word_problems': '+− 2-step',
  'mult_compare_word': '× compare',
  'place_value_2digit': 'place 2d',
  'place_value_3digit': 'place 3d',
  'place_value_multidigit': 'place md',
  'round_to_10': 'round 10',
  'round_to_100': 'round 100',
  'round_multidigit_any_place': 'round md',
  'integers_add': '± int +',
  'integers_subtract': '± int −',
  'integers_multiply_divide': '± int ×÷',
  'absolute_value': '|·|',
  'opposites_and_zero': 'opposite',
  'factors_of_n': 'factors',
  'multiples_of_n': 'multiples',
  'gcf_two_numbers': 'GCF',
  'lcm_two_numbers': 'LCM',
  'rationals_add_sub': '± rat +−',
  'rationals_multiply_divide': '± rat ×÷',
  'decimal_notation_tenths': 'tenths',
  'decimal_notation_hundredths': 'hundredths',
  'compare_decimals_hundredths': 'cmp dec',
  'add_decimals': '+ dec',
  'sub_decimals': '− dec',
  'mult_decimal_by_whole': 'dec × N',
  'mult_decimals': 'dec × dec',
  'decimal_to_thousandths_read': 'thousandths',
  'compare_decimals_thousandths': 'cmp 0.001',
  'round_decimals': 'round dec',
  'div_decimal_by_whole': 'dec ÷ N',
  'div_by_decimal': '÷ by dec',
  'decimal_to_fraction': 'dec → frac',
  'fraction_to_decimal': 'frac → dec',
  'percent_intro': 'percent?',
  'percent_of_quantity': '% of N',
  'find_whole_from_part_percent': 'whole from %',
  'percent_change': '% change',
  'simple_interest': 'interest',
  'commission': 'commission',
  'markup_markdown': 'mark up/dn',
  'sales_tax_tip': 'tax/tip',
  'convert_fraction_decimal_percent': 'F/D/% conv',
  'decimals_fluent_4ops': 'dec ±×÷',
  'ratio_intro': 'ratio?',
  'ratio_language': 'ratio form',
  'equivalent_ratios': 'equiv ratio',
  'unit_rate': 'unit rate',
  'constant_speed': 'd = r·t',
  'unit_pricing': 'unit price',
  'convert_units_using_ratio': 'unit conv',
  'proportional_relationship': 'is prop?',
  'constant_of_proportionality': 'find k',
  'proportional_equation': 'y = kx',
  'order_of_operations_no_exp': 'order ops',
  'nested_grouping': 'parens',
  'evaluate_expression': 'eval ax+b',
  'solve_one_step_eq_addition': 'x ± p = q',
  'solve_one_step_eq_mult': 'px = q',
  'solve_two_step_eq': 'px ± q = r',
  'expand_linear_expression': 'expand',
  'add_subtract_linear_expressions': 'combine',
  'equivalent_expressions_props': 'equiv expr',
  'substitute_to_check': 'sub check',
  'factor_linear_expression': 'factor',
  'solve_two_step_eq_distributive': 'p(x±q)=r',
  'solve_linear_eq_one_solution': 'ax+b=cx+d',
  'mean': 'mean',
  'median': 'median',
  'mode': 'mode',
  'range_data': 'range',
  'iqr': 'IQR',
  'mad': 'MAD',
  'area_rectangle_formula': 'area rect',
  'perimeter_polygon': 'perimeter',
  'perimeter_unknown_side': 'find side',
  'area_triangle': 'area △',
  'area_parallelogram': 'area ▱',
  'area_trapezoid': 'area trap',
  'probability_zero_to_one': 'P scale',
  'probability_simple_event': 'P(event)',
  'experimental_probability': 'P (data)',
  'sample_space_list': 'outcomes',
  'prime_or_composite': 'prime?',
  'exponents_whole_number': 'a^b',
  'order_of_operations_with_exp': 'order +exp',
  'sqrt_perfect_squares': '√',
  'cbrt_perfect_cubes': '∛',
  'scientific_notation_read': 'sci → N',
  'scientific_notation_write': 'N → sci',
  'integer_exponent_props': 'exp rules',
  'repeating_decimal_recognize': 'rep dec?',
  'repeating_decimal_to_fraction': 'rep → frac',
  'scientific_notation_ops': 'sci × sci',
  'pythagorean_apply_2d': 'a²+b²=c²',
  'volume_rect_prism_formula': 'V = lwh',
  'compare_order_rationals': 'order rat',
  'irrational_recognize': 'rat?',
  'expanded_form_3digit': 'expanded',
  'inequality_one_var_intro': 'x > c?',
  'solve_two_step_inequality': 'px+q>r',
  'rational_to_decimal_terminating': 'a/b → dec',
  'rational_to_decimal_repeating': 'a/b → rep',
};

/// Phase-5/6 transitional simplifications of the curriculum.md DAG.
///
/// The curriculum.md prereqs are the source of truth for the long-term DAG.
/// Each entry below TRIMS those prereqs to ones that already have generators
/// registered, so the drip-feed engine can actually reach the implemented
/// concept. Remove the entry once every prereq listed in curriculum.md for
/// that concept has a generator wired up in `GeneratorRegistry`.
// Each entry below names the prereq(s) we drop and why; the curriculum.md
// row stays canonical. Convention: drop a prereq iff it has no registered
// generator yet.
const _prereqOverrides = <String, List<String>>{
  // drop make_10_pair (no generator).
  'add_within_20': ['add_within_10'],
  // drop decompose_10 (no generator).
  'sub_within_20': ['sub_within_10'],
  // drop add_2digit_1digit + place_value_2digit (no generators).
  'add_within_100': ['add_within_20'],
  // drop place_value_2digit (no generator).
  'sub_within_100': ['sub_within_20'],
  // drop place_value_3digit (no generator).
  'add_within_1000': ['add_2digit_carry'],
  // drop place_value_3digit (no generator).
  'sub_within_1000': ['sub_2digit_borrow'],
  // (add_multidigit_standard_alg, sub_multidigit_standard_alg,
  //  mult_4digit_by_1digit, div_4digit_by_1digit) — all four no longer
  // need overrides now that place_value_multidigit has a generator.
  // drop mult_meaning_groups + skip_count_{2,5,10} (no generators).
  'mult_facts_within_100': ['add_within_100'],
  // drop div_meaning_share (no generator).
  'div_facts_within_100': ['mult_facts_within_100'],
  // drop unit_fraction_intro (no generator).
  'fraction_a_over_b': <String>[],
  // drop skip_count_5 (no generator).
  'time_to_5_min': ['time_to_hour_half'],
  // drop teen_numbers_as_ten_plus (no generator) — it's a foundational
  // grade-1 concept, no other prereq stands in.
  'place_value_2digit': <String>[],
  // drop compare_2digit (no generator) — substitute the more direct
  // place-value prereq.
  'round_to_10': ['place_value_2digit'],
  // drop compare_3digit (no generator) — same substitution.
  'round_to_100': ['place_value_3digit'],
  // integers_add: opposites_and_zero now lives, so the curriculum.md
  // prereq is met — no override needed.
  // drop fraction_denom_10_100 (no generator yet) — `decimal_notation_tenths`
  // becomes the entry point into the decimals branch.
  'decimal_notation_tenths': <String>[],
  // drop fraction_denom_10_100 (no generator yet) for the percent root —
  // the percent grid widget visualises "N out of 100" directly.
  'percent_intro': <String>[],
  // evaluate_expression: order_of_operations_with_exp now lives — the
  // curriculum.md prereq is met, no override needed.
  // drop missing_addend_within_20 + write_expression_from_words
  // (no generators) — substitute the basic +/− concept as background.
  'solve_one_step_eq_addition': ['add_within_100'],
  // drop missing_factor + write_expression_from_words (no generators).
  'solve_one_step_eq_mult': ['mult_facts_within_100'],
  // drop distributive_mult_over_add + write_expression_from_words
  // (no generators) — substitute mult facts as basic background.
  'expand_linear_expression': ['mult_facts_within_100'],
  'equivalent_expressions_props': ['mult_facts_within_100'],
  // drop compare_order_rationals (no generator) — substitute basic
  // ordering/sort skill via sub_within_1000 which already lives in the DAG.
  'median': ['sub_within_1000'],
  // drop classify_count_categories (no generator) — substitute a basic
  // arithmetic background; mode is conceptually a "spot the repeat" skill.
  'mode': ['add_within_100'],
  // mad: absolute_value now lives, but it doesn't have a generator path
  // visible to the DAG until after the integers branch fills in. Keep
  // the simpler-prereq override so mad reaches kids who haven't done
  // integers yet.
  'mad': ['mean'],
  // factor_linear_expression: distributive_with_gcf now lives — the
  // curriculum.md prereq
  // [add_subtract_linear_expressions, distributive_with_gcf] is met,
  // no override needed.
  // drop integers_on_number_line (no generator yet — needs NumberLine
  // diagram wiring for decimals support). Use add_within_100 as
  // basic background for both absolute value and opposites.
  'absolute_value': ['add_within_100'],
  'opposites_and_zero': ['add_within_100'],
  // drop skip_count_2 (no generator) — multiples is fundamentally a
  // "did mult facts" skill.
  'multiples_of_n': ['mult_facts_within_100'],
  // drop area_rectangle_count_squares (no generator) — substitute the
  // mult-facts background since area-by-formula IS multiplication.
  'area_rectangle_formula': ['mult_facts_within_100'],
  // drop powers_of_10 (no generator) — substitute mult facts as the
  // basic multiplicative background.
  'exponents_whole_number': ['mult_facts_within_100'],
  // drop powers_of_10 (no generator yet) — substitute mult_facts.
  'scientific_notation_read': ['mult_facts_within_100'],
  // drop volume_unit_cubes (no generator); area_rectangle_count_squares
  // also missing. Substitute mult facts (V = lwh is just multiplication).
  'volume_rect_prism_formula': ['mult_facts_within_100'],
  // drop integers_on_number_line (no generator yet — needs decimal-aware
  // NumberLine spec). compare_decimals_thousandths is already a prereq.
  'compare_order_rationals': ['compare_decimals_thousandths'],
  // irrational_recognize: rational_to_decimal_repeating now lives —
  // curriculum.md prereq is met, no override needed.
  // pythagorean_apply_2d: prereqs are sqrt_perfect_squares ✓ and
  // area_rectangle_formula ✓ — no override needed.
  // irrational_recognize: rational_to_decimal_repeating now lives, so
  // the override above can be cleaned up — handled below.
};

// ─────────────────────────────────────────────────────────────────────────
// Parser
// ─────────────────────────────────────────────────────────────────────────

class _ParsedConcept {
  _ParsedConcept({
    required this.id,
    required this.displayName,
    required this.grade,
    required this.prereqIds,
    required this.source,
    required this.diagram,
    required this.categoryId,
    required this.categoryRowOrder,
  });

  final String id;
  final String displayName;
  final int grade;
  final List<String> prereqIds;
  final String source;
  final String diagram;
  final String categoryId;
  final int categoryRowOrder;
}

final _categoryHeading = RegExp(r'^### 3\.\d+\s.+\(`([a-z_]+)`\)\s*$');
final _separatorRow = RegExp(r'^\|[-|\s]+\|\s*$');

List<_ParsedConcept> _parse(String content) {
  final lines = content.split('\n');
  final result = <_ParsedConcept>[];

  String? category;
  var rowIndex = 0;

  for (final line in lines) {
    // End of §3 — stop parsing once we leave the sub-concept-catalog section.
    if (line.startsWith('## ') && !line.startsWith('## 3')) {
      category = null;
      continue;
    }

    final headingMatch = _categoryHeading.firstMatch(line);
    if (headingMatch != null) {
      category = headingMatch.group(1);
      rowIndex = 0;
      continue;
    }

    if (category == null) continue;
    if (!line.startsWith('|')) continue;

    // Skip the table header (`| ID | Display | Grade | ...`).
    if (line.contains('Display') && line.contains('Grade')) continue;
    // Skip the separator row.
    if (_separatorRow.hasMatch(line)) continue;

    final cells = line.split('|');
    // Expected: ['', ID, Display, Grade, Prereqs, Source, Diagram, '']
    if (cells.length < 8) continue;

    final id = cells[1].trim().replaceAll('`', '');
    if (id.isEmpty) continue;

    final displayName = cells[2].trim();
    final gradeStr = cells[3].trim();
    final prereqsStr = cells[4].trim();
    final sourceStr = cells[5].trim();
    final diagramStr = cells[6].trim();

    final grade = int.tryParse(gradeStr);
    if (grade == null) {
      throw FormatException(
        'Could not parse grade "$gradeStr" for concept "$id"',
      );
    }

    result.add(
      _ParsedConcept(
        id: id,
        displayName: displayName,
        grade: grade,
        prereqIds: _parsePrereqs(prereqsStr, id),
        source: sourceStr,
        diagram: diagramStr,
        categoryId: category,
        categoryRowOrder: rowIndex,
      ),
    );
    rowIndex++;
  }

  return result;
}

List<String> _parsePrereqs(String s, String forConceptId) {
  if (!(s.startsWith('[') && s.endsWith(']'))) {
    throw FormatException(
      'Prereqs for "$forConceptId" not in [a, b] form: "$s"',
    );
  }
  final inner = s.substring(1, s.length - 1).trim();
  if (inner.isEmpty) return const <String>[];
  return inner.split(',').map((e) => e.trim()).toList();
}

void _validate(List<_ParsedConcept> concepts) {
  // Unique IDs.
  final byId = <String, _ParsedConcept>{};
  for (final c in concepts) {
    if (byId.containsKey(c.id)) {
      throw FormatException(
        'Duplicate concept id "${c.id}" — first in category '
        '"${byId[c.id]!.categoryId}", duplicate in "${c.categoryId}"',
      );
    }
    byId[c.id] = c;
  }

  // Override targets must be valid concept IDs.
  for (final id in _shortLabelOverrides.keys) {
    if (!byId.containsKey(id)) {
      throw FormatException(
        'shortLabel override targets unknown concept "$id"',
      );
    }
  }
  for (final entry in _prereqOverrides.entries) {
    if (!byId.containsKey(entry.key)) {
      throw FormatException(
        'prereq override targets unknown concept "${entry.key}"',
      );
    }
    for (final p in entry.value) {
      if (!byId.containsKey(p)) {
        throw FormatException(
          'prereq override for "${entry.key}" references unknown id "$p"',
        );
      }
    }
  }

  // Curriculum-level invariants. These mirror the catalog tests in
  // test/domain/concepts/concept_registry_test.dart so authoring errors
  // surface at build time, not test time.
  for (final c in concepts) {
    final prereqs = _prereqOverrides[c.id] ?? c.prereqIds;
    for (final pId in prereqs) {
      final p = byId[pId];
      if (p == null) {
        throw FormatException(
          'concept "${c.id}" lists missing prereq "$pId"',
        );
      }
      if (p.grade > c.grade) {
        throw FormatException(
          'grade-DAG violation: "${c.id}" (G${c.grade}) lists prereq '
          '"$pId" (G${p.grade}). Either lower the prereq grade, raise '
          'the dependent grade, or drop the prereq.',
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Emitter
// ─────────────────────────────────────────────────────────────────────────

String _emit(List<_ParsedConcept> concepts) {
  final sb = StringBuffer()
    ..writeln('// GENERATED FILE — DO NOT EDIT BY HAND.')
    ..writeln('//')
    ..writeln('// Source: curriculum.md §3.x')
    ..writeln('// Generator: tools/curriculum/build_catalog.dart')
    ..writeln('//')
    ..writeln('// To regenerate after editing curriculum.md:')
    ..writeln('//   dart tools/curriculum/build_catalog.dart')
    ..writeln()
    ..writeln("import 'package:math_city/domain/concepts/concept.dart';")
    ..writeln()
    ..writeln('const List<Concept> allConcepts = [');

  String? lastCategory;
  for (final c in concepts) {
    if (c.categoryId != lastCategory) {
      sb.writeln('  // ── ${c.categoryId} ──');
      lastCategory = c.categoryId;
    }

    final shortLabel = _shortLabelOverrides[c.id] ?? c.displayName;
    final prereqIds = _prereqOverrides[c.id] ?? c.prereqIds;
    final source = _sourceFor(c.source, c.id);
    final diagram = _diagramFor(c.diagram, c.id);

    sb
      ..writeln('  Concept(')
      ..writeln('    id: ${_dartString(c.id)},')
      ..writeln('    name: ${_dartString(c.displayName)},')
      ..writeln('    shortLabel: ${_dartString(shortLabel)},')
      ..writeln('    categoryId: ${_dartString(c.categoryId)},')
      ..writeln('    primaryGrade: ${c.grade},')
      ..writeln('    prereqIds: ${_dartList(prereqIds)},')
      ..writeln('    source: $source,')
      ..writeln('    diagramRequirement: $diagram,')
      ..writeln('    categoryRowOrder: ${c.categoryRowOrder},')
      ..writeln('  ),');
  }

  sb
    ..writeln('];')
    ..writeln()
    ..writeln('/// Lookup helper. O(n); n is small, called rarely.')
    ..writeln('Concept? findConceptById(String id) =>')
    ..writeln('    allConcepts.where((c) => c.id == id).firstOrNull;')
    ..writeln()
    ..writeln(
      '/// Returns the concepts whose primary grade is at or below '
      '[playerGrade].',
    )
    ..writeln('Iterable<Concept> conceptsAtOrBelowGrade(int playerGrade) =>')
    ..writeln('    allConcepts.where((c) => c.primaryGrade <= playerGrade);')
    ..writeln()
    ..writeln(
      '/// Difficulty queue order: ascending grade, then ascending '
      'category row order.',
    )
    ..writeln('int compareConceptDifficulty(Concept a, Concept b) {')
    ..writeln('  final byGrade = a.primaryGrade.compareTo(b.primaryGrade);')
    ..writeln('  if (byGrade != 0) return byGrade;')
    ..writeln('  return a.categoryRowOrder.compareTo(b.categoryRowOrder);')
    ..writeln('}');

  return sb.toString();
}

String _sourceFor(String source, String forId) {
  switch (source) {
    case 'algorithmic':
      return 'ConceptSource.algorithmic';
    case 'algorithmic_with_diagram':
      return 'ConceptSource.algorithmicWithDiagram';
    case 'dataset':
      return 'ConceptSource.dataset';
    case 'algorithmic+dataset':
      return 'ConceptSource.algorithmicPlusDataset';
    case 'deferred':
      return 'ConceptSource.deferred';
  }
  throw FormatException('Unknown Source value "$source" for concept "$forId"');
}

String _diagramFor(String diagram, String forId) {
  if (diagram == 'none') return 'DiagramNone()';
  if (diagram == 'optional') return 'DiagramOptional()';
  if (diagram.startsWith('required:')) {
    final kind = diagram.substring('required:'.length).trim();
    if (kind.isEmpty) {
      throw FormatException(
        'Empty `required:` diagram kind for concept "$forId"',
      );
    }
    return "DiagramRequired('$kind')";
  }
  throw FormatException(
    'Unknown Diagram value "$diagram" for concept "$forId"',
  );
}

String _dartString(String s) {
  final escaped = s.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  return "'$escaped'";
}

String _dartList(List<String> items) {
  if (items.isEmpty) return '[]';
  return '[${items.map(_dartString).join(', ')}]';
}
