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

  // Run `dart format` over the generated file so the lint suite (which
  // enforces 80-column lines) stays clean. Without this step a `prereqIds`
  // list with 3+ entries lands on one line and trips the line-length lint.
  final fmt = Process.runSync('dart', <String>['format', outputPath]);
  if (fmt.exitCode != 0) {
    stderr.writeln(fmt.stderr);
    exit(fmt.exitCode);
  }

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
  'count_to_10': 'count 10',
  'count_to_20': 'count 20',
  'count_to_100_by_1': 'count 100',
  'count_to_100_by_10': 'by 10s',
  'count_to_120': 'count 120',
  'count_forward_from_n': 'count up',
  'one_more_one_less_within_20': '±1',
  'ten_more_ten_less': '±10',
  'compare_numerals_1_10': 'compare',
  'count_within_1000': 'count 1000',
  'even_odd': 'even/odd',
  'compare_2digit': 'compare 2d',
  'make_10_pair': 'pair to 10',
  'add_3_addends_within_20': '3 addends',
  'add_sub_unknown_position': '?+b=r',
  'equal_sign_meaning': 'true?',
  'commutative_add': 'a+b=b+a',
  'add_2digit_1digit': '2d+1d',
  'sub_multiples_of_10': '×10 −',
  'mental_add_10_or_100': '±10/100',
  'skip_count_2': 'skip 2s',
  'skip_count_5': 'skip 5s',
  'skip_count_10': 'skip 10s',
  'skip_count_100': 'skip 100s',
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
  'bar_graph_read': 'bar graph',
  'bar_graph_compare': 'bar diff',
  'scaled_bar_graph_read': 'bar scaled',
  'line_plot_whole': 'line plot',
  'dot_plot': 'dot plot',
  'line_plot_fractional': 'line ½/¼',
  'line_plot_fraction_word': 'line × frac',
  'line_plot_5th_grade_ops': 'line range',
  'histogram': 'histogram',
  'describe_distribution': 'shape?',
  'box_plot': 'box plot',
  'compare_two_distributions': 'A vs B',
  'scatter_plot_construct': 'find pt',
  'scatter_plot_describe': 'scatter?',
  'informal_line_of_fit': 'best fit',
  'graph_linear_equation': 'graph y=mx+b',
  'identify_linear_vs_nonlinear': 'linear?',
  'solve_system_by_graphing': 'lines meet',
  'polygon_on_coordinate_plane': 'polygon coords',
  'transformations_translation': 'translate',
  'transformations_reflection': 'reflect',
  'transformations_rotation': 'rotate',
  'transformations_dilation': 'dilate',
  'congruence_via_transformations': 'congruent?',
  'similarity_via_transformations': 'similar?',
  'tree_diagram': 'tree',
  'compound_event_probability': 'P(A∩B)',
  'two_way_table_construct': '2-way?',
  'two_way_relative_frequency': '2-way %',
  'ratio_to_coordinate_pairs': 'ratio plot',
  'dependent_independent_vars': 'indep var',
  'mult_facts_2': '×2',
  'mult_facts_3': '×3',
  'mult_facts_4': '×4',
  'mult_facts_5': '×5',
  'mult_facts_6': '×6',
  'mult_facts_7': '×7',
  'mult_facts_8': '×8',
  'mult_facts_9': '×9',
  'mult_facts_10': '×10',
  'mult_1digit_by_multiple_of_10': '× ×10',
  'commutative_mult': 'a·b=b·a',
  'associative_mult': '(ab)c',
  'div_as_unknown_factor': 'a·?=c',
  'arithmetic_patterns_in_tables': 'pattern',
  'decompose_10': '10=a+?',
  'associative_add': '(a+b)+c',
  'add_2digit_multiple_of_10': '2d+×10',
  'add_up_to_4_2digit': '+ 4 nums',
  'add_sub_fluency_within_20': '±/20 fluent',
  'read_write_3digit': 'name 3d',
  'compare_3digit': 'compare 3d',
  'read_write_multidigit': 'name multi',
  'compare_multidigit': 'compare md',
  'place_value_relationship_10x': '10× place',
  'powers_of_10': '10^n',
  'am_pm': 'a.m./p.m.',
  'length_diff_units': 'len diff',
  'triangle_inequality_recognize': '△ valid?',
  'adjacent_angles': 'adj ∠',
  'exterior_angle_triangle': 'ext ∠',
  'inspect_system_no_solution': 'sys soln?',
  'unit_rate_with_fractions': 'frac rate',
  'read_numerals_0_20': 'read 0-20',
  'write_numerals_0_20': 'write 0-20',
  'interpret_remainder_word': 'rem story',
  'fraction_word_problems': 'frac word',
  'multistep_ratio_word': 'rate word',
  'rationals_four_op_word': 'rat word',
  'word_problem_two_step_eq': '2-step eq',
  'system_word_problem': 'sys word',
  'missing_addend_within_20': '?+b=r',
  'missing_factor': '?×b=c',
  'numerical_pattern_rule': 'rule?',
  'signed_quantities_context': 'context ±',
  'write_expression_from_words': 'words→expr',
  'identify_parts_expression': 'coef/const',
  'convert_units_within_system': 'unit conv',
  'volume_prism_fractional_edges': 'V frac',
  'length_word_problems': 'len word',
  'money_word_problems': r'$ word',
  'liquid_volume_mass': 'liquid',
  'mult_div_word_2step': '×÷ 2-step',
  'area_perimeter_word': 'area word',
  'convert_units_multistep': 'unit 2-step',
  'statistical_question': 'stat Q?',
  'sampling_representativeness': 'fair?',
  'partition_halves_fourths': '½ ¼',
  'partition_thirds': '⅓',
  'unit_fraction_intro': '1/b',
  'number_line_add_sub': '± line',
  'decimal_on_number_line': 'dec line',
  'integers_on_number_line': '± int line',
  'area_rectangle_count_squares': 'count □',
  'partition_into_rows_columns': 'rows × cols',
  'inference_from_sample': 'estimate',
  'count_objects_to_10': 'count obj 10',
  'count_objects_to_20': 'count obj 20',
  'equal_groups_intro': 'groups',
  'array_repeated_addition': 'array +',
  'mult_meaning_groups': '× meaning',
  'div_meaning_share': 'share',
  'div_meaning_grouping': '÷ groups',
  'distributive_mult_over_add': 'distrib',
  'time_to_minute': 'clock 1m',
  'elapsed_time': 'elapsed',
  'fraction_denom_10_100': 'tenths',
  'approximate_irrational': '√n approx',
  'two_pattern_relationships': '2 patterns',
  'graph_proportional_slope': 'find slope',
  'qualitative_graph_features': 'incr/decr',
  'interpret_slope_intercept_data': 'pred y',
  'simulate_compound': 'P sim',
  'right_acute_obtuse_angle': '∠ kind?',
  'angle_addition': '∠ + ∠',
  'fraction_on_number_line': 'frac line',
  'classify_count_categories': 'sort+count',
  'three_category_data': '3 cats',
  'picture_graph_read': 'pic graph',
  'scaled_picture_graph': 'pic scaled',
  'coins_id_value': 'coin?',
  'count_coins': 'coin sum',
  'count_bills_coins': r'$ + ¢',
  'change_from_purchase': 'change',
  'measure_with_ruler_inches': 'ruler in',
  'measure_with_ruler_cm': 'ruler cm',
  'measure_to_half_quarter_inch': 'ruler ½/¼',
  'measure_angle_protractor': 'measure ∠',
  'draw_angle_protractor': 'draw ∠',
  'identify_shape_2d': 'name 2D',
  'identify_shape_3d': 'name 3D',
  'shape_attributes_basic': 'sides?',
  'identify_polygons': 'polygon?',
  'classify_quadrilaterals': 'name quad',
  'line_of_symmetry': 'symmetry',
  'classify_2d_hierarchy': 'is a __?',
  'pythagorean_apply_3d': 'a²+b²+c²',
  'teen_numbers_as_ten_plus': 'teen = 10+',
  'ratio_table': 'ratio tbl',
  'double_number_line': '2× line',
  'identify_lines_rays_segments': 'line/ray?',
  'parallel_perpendicular_lines': '∥ ⊥ ×?',
  'classify_2d_by_lines_angles': 'right ∠?',
  'describe_attribute': 'measure?',
  'compare_two_objects': 'longer?',
  'order_three_objects_length': 'sort 3',
  'positional_words': 'where?',
  'partition_circle_rect_halves': 'halves?',
  'estimate_length': 'estimate',
  'compose_shapes': 'compose',
  'cross_section_3d': 'cross §',
  'scale_drawing': 'scale dr',
  'volume_unit_cubes': 'count V',
  'surface_area_from_net': 'cube SA',
  'area_polygon_decompose': 'A = a+b',
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
  // add_within_100: add_2digit_1digit now lives (Chunk 44),
  // place_value_2digit lives, so the curriculum prereq is met — no
  // override needed.
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
  // fraction_a_over_b: unit_fraction_intro now lives (Chunk 51), so
  // the curriculum prereq is met — no override needed.
  // time_to_5_min: skip_count_5 now lives (Chunk 42), so the curriculum
  // prereq [time_to_hour_half, skip_count_5] is met — no override needed.
  // place_value_2digit: teen_numbers_as_ten_plus now lives (Chunk 61),
  // so the curriculum prereq is met — no override needed.
  // drop compare_2digit (no generator) — substitute the more direct
  // place-value prereq.
  'round_to_10': ['place_value_2digit'],
  // drop compare_3digit (no generator) — same substitution.
  'round_to_100': ['place_value_3digit'],
  // integers_add: opposites_and_zero now lives, so the curriculum.md
  // prereq is met — no override needed.
  // decimal_notation_tenths / percent_intro: fraction_denom_10_100 now
  // lives (Chunk 52) — curriculum prereqs are met, no overrides needed.
  // evaluate_expression: order_of_operations_with_exp now lives — the
  // curriculum.md prereq is met, no override needed.
  // solve_one_step_eq_addition: missing_addend_within_20 +
  // write_expression_from_words now live (Chunk 49) so the curriculum
  // prereq is met — no override needed.
  // solve_one_step_eq_mult: missing_factor + write_expression_from_words
  // now live — no override needed.
  // drop distributive_mult_over_add (no generator — needs array_grid
  // widget). write_expression_from_words now lives, so substitute that.
  'expand_linear_expression': ['write_expression_from_words'],
  'equivalent_expressions_props': ['write_expression_from_words'],
  // drop compare_order_rationals (no generator) — substitute basic
  // ordering/sort skill via sub_within_1000 which already lives in the DAG.
  'median': ['sub_within_1000'],
  // mode: classify_count_categories now lives (Chunk 55), so the
  // curriculum prereq is met — no override needed.
  // mad: absolute_value now lives, but it doesn't have a generator path
  // visible to the DAG until after the integers branch fills in. Keep
  // the simpler-prereq override so mad reaches kids who haven't done
  // integers yet.
  'mad': ['mean'],
  // factor_linear_expression: distributive_with_gcf now lives — the
  // curriculum.md prereq
  // [add_subtract_linear_expressions, distributive_with_gcf] is met,
  // no override needed.
  // absolute_value / opposites_and_zero: integers_on_number_line now
  // lives (Chunk 51), so the curriculum prereq is met — no override
  // needed.
  // multiples_of_n: skip_count_2 now lives (Chunk 41), so the curriculum
  // prereq is met — no override needed.
  // area_rectangle_formula: area_rectangle_count_squares now lives —
  // curriculum prereq is met, no override needed.
  // drop powers_of_10 (no generator) — substitute mult facts as the
  // basic multiplicative background.
  'exponents_whole_number': ['mult_facts_within_100'],
  // drop powers_of_10 (no generator yet) — substitute mult_facts.
  'scientific_notation_read': ['mult_facts_within_100'],
  // volume_rect_prism_formula: volume_unit_cubes now lives (Chunk 67),
  // so the curriculum prereq is met — no override needed.
  // compare_order_rationals: integers_on_number_line now lives —
  // curriculum prereq is met, no override needed.
  // irrational_recognize: rational_to_decimal_repeating now lives —
  // curriculum.md prereq is met, no override needed.
  // pythagorean_apply_2d: prereqs are sqrt_perfect_squares ✓ and
  // area_rectangle_formula ✓ — no override needed.
  // irrational_recognize: rational_to_decimal_repeating now lives, so
  // the override above can be cleaned up — handled below.
  // drop graph_proportional_slope (no generator yet — needs the
  // CoordinatePlane widget). proportional_relationship is conceptually
  // closest since slope is the constant of proportionality.
  'slope_from_two_points': ['proportional_relationship'],
  // function_definition_check: graph_linear_equation now lives (Chunk 33),
  // so the curriculum.md prereq is met — no override needed.
  // supplementary_angles / complementary_angles: right_acute_obtuse_angle
  // now lives (Chunk 54), so the curriculum prereq is met — no overrides
  // needed.
  // vertical_angles / triangle_angle_sum / parallel_lines_transversal:
  // their curriculum prereqs (supplementary_angles, vertical_angles) now
  // live — no override needed.
  // right_acute_obtuse_angle: identify_lines_rays_segments now lives
  // (Chunk 63), so the curriculum prereq is met — no override needed.
  // angle_addition: measure_angle_protractor now lives (Chunk 58), so
  // the curriculum prereq is met — no override needed.
  // drop measure_length_units (still no generator — needs the iterated-
  // units variant of the Ruler widget). Substitute add_within_20 as basic
  // count-up background; the ruler widget itself carries the visual
  // measure-the-bar skill.
  'measure_with_ruler_inches': ['add_within_20'],
  'measure_with_ruler_cm': ['add_within_20'],
  // plot_first_quadrant: number_line_add_sub now lives — curriculum
  // prereq is met, no override needed.
  // drop integers_on_number_line (no generator yet). Substitute
  // opposites_and_zero, which carries the same "negative integers
  // exist on a number line" intuition needed for Q2/Q3/Q4 plotting.
  'plot_four_quadrants': ['plot_first_quadrant', 'opposites_and_zero'],
  // pythagorean_distance_coords: polygon_on_coordinate_plane now lives
  // (Chunk 35), so the curriculum prereq is met — no override needed.
  // bar_graph_read: picture_graph_read now lives (Chunk 55), so the
  // curriculum prereq is met — no override needed.
  // bar_graph_compare prereqs are [bar_graph_read, sub_within_100] —
  // both implemented, no override needed.
  // scaled_bar_graph_read prereqs are [bar_graph_read,
  // mult_facts_within_100] — both implemented, no override needed.
  // line_plot_whole: measure_with_ruler_inches now lives (Chunk 57), so
  // the curriculum prereq is met — no override needed.
  // dot_plot prereq is [line_plot_whole] — implemented, no override needed.
  // drop partition_halves_fourths (no generator — would need a FractionBar
  // partition exercise). Substitute fraction_a_over_b which carries the
  // "I understand what 1/4 means as a fraction" intuition.
  'line_plot_fractional': ['line_plot_whole', 'fraction_a_over_b'],
  // line_plot_fraction_word prereqs are [line_plot_fractional,
  // add_fractions_like_denom] — both implemented, no override needed.
  // line_plot_5th_grade_ops prereqs are [line_plot_fractional,
  // add_fractions_unlike_denom] — both implemented, no override needed.
  // histogram prereq is [bar_graph_read] — implemented, no override needed.
  // drop box_plot (no generator yet — needs BoxPlot widget). The histogram
  // alone is enough scaffolding for "describe the shape" — kids don't need
  // box-plot fluency to recognise symmetric / skewed / uniform.
  'describe_distribution': ['histogram'],
  // box_plot prereq is [median] — implemented, no override needed.
  // compare_two_distributions prereq is [describe_distribution] —
  // implemented, no override needed.
  // two_way_table_construct: classify_count_categories now lives —
  // curriculum prereq is met, no override needed.
  // compare_numerals_1_10: read_numerals_0_20 now lives (Chunk 48) so
  // the curriculum prereq is met — no override needed.
  // two_way_relative_frequency prereqs are [two_way_table_construct,
  // percent_intro] — both implemented, no override needed.
  // mult_facts_3: mult_meaning_groups now lives (Chunk 52) — curriculum
  // prereq is met, no override needed.
  // length_diff_units: measure_with_ruler_inches now lives (Chunk 57), so
  // the curriculum prereq is met — no override needed.
  // triangle_inequality_recognize: shape_attributes_basic now lives
  // (Chunk 59), so the curriculum prereq is met — no override needed.
  // length_word_problems: measure_with_ruler_inches now lives (Chunk 57),
  // so the curriculum prereq is met — no override needed.
  // money_word_problems: count_bills_coins now lives (Chunk 56), so the
  // curriculum prereq is met — no override needed.
  // partition_into_rows_columns: identify_shape_2d now lives (Chunk 59),
  // so the curriculum prereq is met — no override needed.
  // classify_2d_hierarchy: classify_2d_by_lines_angles now lives
  // (Chunk 63), so the curriculum prereq is met — no override needed.
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

    // Strip backticks and the `✅` implemented-marker that
    // sync_implementation_status.py writes in front of implemented IDs.
    final id = cells[1].trim().replaceAll('`', '').replaceAll('✅', '').trim();
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
  // Use a raw string when '$' is present and there are no chars (like
  // backslash or single quote) that raw strings can't represent — that
  // satisfies the use_raw_strings lint cleanly.
  if (s.contains(r'$') && !s.contains(r'\') && !s.contains("'")) {
    return "r'$s'";
  }
  final escaped = s
      .replaceAll(r'\', r'\\')
      .replaceAll(r'$', r'\$')
      .replaceAll("'", r"\'");
  return "'$escaped'";
}

String _dartList(List<String> items) {
  if (items.isEmpty) return '[]';
  return '[${items.map(_dartString).join(', ')}]';
}
