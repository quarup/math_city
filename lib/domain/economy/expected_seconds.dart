/// Expected seconds of work per concept — the unit the coin economy is
/// denominated in (1 coin ≈ 1 expected second of study; see prd.md
/// *Cosmetics System*).
///
/// These are **hand estimates of how long an average student at the
/// concept's grade needs for one question**, not measurements. The draft
/// started from a grade-band formula (K–1 ≈ 5 s, G2–3 ≈ 10 s, G4–5 ≈ 20 s,
/// G6–8 ≈ 35 s) and every concept was then walked individually: quick
/// recall (facts, naming, reading a numeral) sits under its band; multi-digit
/// algorithms, long division, systems of equations and multi-step word
/// problems run 2–3× over it. Tune freely — nothing else in the codebase
/// hardcodes these numbers, and rewards must *never* be based on the actual
/// time a player took (that would reward idling).
///
/// Every concept in the registry has exactly one entry (enforced by
/// `test/domain/economy/expected_seconds_test.dart`), so the map is also the
/// canonical "how big is this question" signal for block sizing.
library;

/// Seconds an average student at grade level is expected to need for one
/// question of [conceptId]. Throws on an unknown id — the coverage test
/// guarantees every registered concept is present.
int expectedSecondsFor(String conceptId) {
  final s = expectedSecondsByConcept[conceptId];
  if (s == null) {
    throw ArgumentError.value(conceptId, 'conceptId', 'no expectedSeconds');
  }
  return s;
}

const Map<String, int> expectedSecondsByConcept = <String, int>{
  // -- Counting & cardinality ------------------------------------------------
  'count_to_10': 4, // K · Count to 10
  'count_to_20': 4, // K · Count to 20
  'count_to_100_by_1': 4, // K · Count to 100
  'count_to_100_by_10': 4, // K · Count by tens
  'count_to_120': 5, // G1 · Count to 120
  'count_forward_from_n': 5, // K · Count up from any number
  'read_numerals_0_20': 4, // K · Read numbers 0–20
  'write_numerals_0_20': 5, // K · Write numbers 0–20
  'count_objects_to_10': 6, // K · Count objects (10)
  'count_objects_to_20': 8, // K · Count objects (20)
  'compare_groups_by_count': 6, // K · Which group has more?
  'compare_numerals_1_10': 5, // K · Compare two numbers (1–10)
  'one_more_one_less_within_20': 5, // K · One more / one less
  'ten_more_ten_less': 6, // G1 · Ten more / ten less
  'skip_count_2': 6, // G1 · Skip count by 2s
  'skip_count_5': 7, // G2 · Skip count by 5s
  'skip_count_10': 6, // G1 · Skip count by 10s
  'skip_count_100': 7, // G2 · Skip count by 100s
  'count_within_1000': 8, // G2 · Count within 1000
  'even_odd': 5, // G2 · Even or odd?
  // -- Place value & number theory -------------------------------------------
  'teen_numbers_as_ten_plus': 6, // K · Teens as ten + ones
  'place_value_2digit': 7, // G1 · Tens and ones
  'compare_2digit': 6, // G1 · Compare 2-digit numbers
  'place_value_3digit': 9, // G2 · Hundreds, tens, ones
  'read_write_3digit': 8, // G2 · Read/write to 1000
  'expanded_form_3digit': 10, // G2 · Expanded form (3-digit)
  'compare_3digit': 8, // G2 · Compare 3-digit numbers
  'round_to_10': 9, // G3 · Round to nearest 10
  'round_to_100': 10, // G3 · Round to nearest 100
  'place_value_multidigit': 15, // G4 · Multi-digit place value
  'read_write_multidigit': 15, // G4 · Read/write big numbers
  'compare_multidigit': 12, // G4 · Compare big numbers
  'round_multidigit_any_place': 18, // G4 · Round to any place
  'place_value_relationship_10x': 15, // G5 · Each place is 10× the next
  'factors_of_n': 25, // G4 · Find factors
  'multiples_of_n': 14, // G4 · Find multiples
  'prime_or_composite': 15, // G4 · Prime or composite?
  'gcf_two_numbers': 40, // G6 · Greatest common factor
  'lcm_two_numbers': 40, // G6 · Least common multiple
  'distributive_with_gcf': 40, // G6 · Factor out the GCF
  'powers_of_10': 14, // G5 · Powers of 10
  'exponents_whole_number': 18, // G6 · Whole-number exponents
  'integer_exponent_props': 28, // G8 · Properties of exponents
  'sqrt_perfect_squares': 12, // G8 · Square roots (perfect)
  'cbrt_perfect_cubes': 14, // G8 · Cube roots (perfect)
  'scientific_notation_read': 18, // G8 · Read scientific notation
  'scientific_notation_write': 25, // G8 · Write scientific notation
  'scientific_notation_ops': 50, // G8 · Operate in scientific notation
  // -- Addition & subtraction ------------------------------------------------
  'add_within_5': 4, // K · Add within 5
  'sub_within_5': 4, // K · Subtract within 5
  'add_within_10': 5, // K · Add within 10
  'sub_within_10': 5, // K · Subtract within 10
  'make_10_pair': 5, // K · Pairs that make 10
  'decompose_10': 6, // K · Decompose 10 (or less)
  'add_3_addends_within_20': 10, // G1 · Add three numbers
  'add_within_20': 6, // G1 · Add within 20
  'sub_within_20': 6, // G1 · Subtract within 20
  'add_sub_unknown_position': 10, // G1 · Find the missing number
  'equal_sign_meaning': 7, // G1 · Is the equation true?
  'commutative_add': 6, // G1 · Add in any order
  'associative_add': 8, // G1 · Group addends any way
  'add_2digit_1digit': 8, // G1 · 2-digit + 1-digit
  'add_2digit_multiple_of_10': 7, // G1 · 2-digit + multiple of 10
  'sub_multiples_of_10': 7, // G1 · Subtract multiples of 10
  'add_within_100': 12, // G2 · Add within 100
  'sub_within_100': 12, // G2 · Subtract within 100
  'add_2digit_carry': 14, // G2 · 2-digit + with regrouping
  'sub_2digit_borrow': 15, // G2 · 2-digit − with regrouping
  'add_up_to_4_2digit': 25, // G2 · Add up to four 2-digit numbers
  'add_within_1000': 20, // G2 · Add within 1000
  'sub_within_1000': 22, // G2 · Subtract within 1000
  'mental_add_10_or_100': 7, // G2 · Mental ±10 / ±100
  'add_word_problems_within_100': 20, // G2 · +/− word problems (100)
  'add_sub_2step_word_problems': 28, // G2 · Two-step word problems
  'add_multidigit_standard_alg': 40, // G4 · Multi-digit + (algorithm)
  'sub_multidigit_standard_alg': 45, // G4 · Multi-digit − (algorithm)
  'add_sub_fluency_within_20': 5, // G2 · +/− facts within 20 (memory)
  'number_line_add_sub': 10, // G2 · +/− on number line
  // -- Multiplication & division ---------------------------------------------
  'equal_groups_intro': 10, // G2 · Equal groups (rows × cols)
  'array_repeated_addition': 12, // G2 · Arrays as repeated +
  'mult_meaning_groups': 10, // G3 · What multiplication means
  'mult_facts_within_100': 8, // G3 · × facts to 100
  'mult_facts_2': 6, // G3 · ×2 facts
  'mult_facts_5': 6, // G3 · ×5 facts
  'mult_facts_10': 5, // G3 · ×10 facts
  'mult_facts_3': 6, // G3 · ×3 facts
  'mult_facts_4': 7, // G3 · ×4 facts
  'mult_facts_6': 7, // G3 · ×6 facts
  'mult_facts_7': 8, // G3 · ×7 facts
  'mult_facts_8': 8, // G3 · ×8 facts
  'mult_facts_9': 8, // G3 · ×9 facts
  'div_meaning_share': 12, // G3 · Sharing equally
  'div_meaning_grouping': 12, // G3 · How many groups?
  'div_facts_within_100': 9, // G3 · ÷ facts to 100
  'div_as_unknown_factor': 9, // G3 · ÷ as missing factor
  'commutative_mult': 8, // G3 · Multiply in any order
  'associative_mult': 12, // G3 · Group factors any way
  'distributive_mult_over_add': 18, // G3 · Distributive property
  'mult_1digit_by_multiple_of_10': 10, // G3 · 1-digit × multiple of 10
  'div_with_remainder': 25, // G4 · ÷ with remainder
  'interpret_remainder_word': 35, // G4 · Interpret remainder in story
  'mult_compare_word': 25, // G4 · Multiplicative comparison
  'mult_4digit_by_1digit': 40, // G4 · 4-digit × 1-digit
  'mult_2digit_by_2digit': 45, // G4 · 2-digit × 2-digit
  'div_4digit_by_1digit': 50, // G4 · 4-digit ÷ 1-digit
  'mult_multidigit_standard_alg': 55, // G5 · Multi-digit × (algorithm)
  'div_4digit_by_2digit': 70, // G5 · 4-digit ÷ 2-digit
  'mult_div_word_2step': 50, // G4 · Multi-step word problems
  'arithmetic_patterns_in_tables': 15, // G3 · Patterns in × and + tables
  'order_of_operations_no_exp': 30, // G5 · Order of operations
  'order_of_operations_with_exp': 40, // G6 · Order with exponents
  'nested_grouping': 30, // G5 · Parentheses first
  // -- Fractions -------------------------------------------------------------
  'partition_halves_fourths': 6, // G1 · Halves and fourths
  'partition_thirds': 7, // G2 · Thirds
  'unit_fraction_intro': 8, // G3 · What is 1/b?
  'fraction_a_over_b': 9, // G3 · What is a/b?
  'fraction_on_number_line': 14, // G3 · Fractions on a number line
  'equivalent_fractions_visual': 14, // G3 · Equal fractions (with picture)
  'equivalent_fractions_compute': 15, // G4 · Find equivalent fraction
  'compare_fractions_same_denom': 8, // G3 · Compare (same bottom)
  'compare_fractions_same_num': 10, // G3 · Compare (same top)
  'compare_fractions_unlike': 22, // G4 · Compare unlike fractions
  'whole_number_as_fraction': 8, // G3 · Whole numbers as fractions
  'simplify_fraction': 18, // G4 · Simplify fractions
  'improper_to_mixed': 18, // G4 · Improper → mixed number
  'mixed_to_improper': 18, // G4 · Mixed number → improper
  'add_fractions_like_denom': 15, // G4 · Add fractions (same bottom)
  'sub_fractions_like_denom': 15, // G4 · Subtract fractions (same bottom)
  'add_mixed_like_denom': 25, // G4 · Add mixed numbers (like)
  'sub_mixed_like_denom': 28, // G4 · Subtract mixed numbers (like)
  'mult_fraction_by_whole': 18, // G4 · Fraction × whole number
  'add_fractions_unlike_denom': 35, // G5 · Add fractions (unlike)
  'sub_fractions_unlike_denom': 35, // G5 · Subtract fractions (unlike)
  'add_mixed_unlike_denom': 45, // G5 · Add mixed (unlike)
  'sub_mixed_unlike_denom': 50, // G5 · Subtract mixed (unlike)
  'fraction_as_division': 12, // G5 · Fraction as a ÷ b
  'mult_fractions_proper': 25, // G5 · Fraction × fraction
  'mult_mixed_numbers': 40, // G5 · × with mixed numbers
  'mult_as_scaling': 15, // G5 · Multiplication as scaling
  'div_unit_fraction_by_whole': 30, // G5 · Unit fraction ÷ whole
  'div_whole_by_unit_fraction': 30, // G5 · Whole ÷ unit fraction
  'div_fraction_by_fraction': 40, // G6 · Fraction ÷ fraction
  'fraction_word_problems': 40, // G5 · Fraction word problems
  // -- Decimals & percent ----------------------------------------------------
  'fraction_denom_10_100': 14, // G4 · Tenths and hundredths
  'decimal_notation_tenths': 12, // G4 · Decimal: tenths
  'decimal_notation_hundredths': 14, // G4 · Decimal: hundredths
  'decimal_on_number_line': 20, // G4 · Decimals on number line
  'compare_decimals_hundredths': 14, // G4 · Compare decimals to 0.01
  'decimal_to_thousandths_read': 14, // G5 · Read decimals to 0.001
  'compare_decimals_thousandths': 15, // G5 · Compare decimals to 0.001
  'round_decimals': 15, // G5 · Round decimals
  'add_decimals': 25, // G5 · Add decimals (to 0.01)
  'sub_decimals': 25, // G5 · Subtract decimals (to 0.01)
  'mult_decimal_by_whole': 30, // G5 · Decimal × whole
  'mult_decimals': 35, // G5 · Decimal × decimal
  'div_decimal_by_whole': 35, // G5 · Decimal ÷ whole
  'div_by_decimal': 50, // G6 · ÷ by a decimal
  'decimals_fluent_4ops': 50, // G6 · Fluent +,−,×,÷ decimals
  'decimal_to_fraction': 15, // G5 · Decimal → fraction
  'fraction_to_decimal': 30, // G6 · Fraction → decimal
  'repeating_decimal_recognize': 18, // G8 · Repeating decimal?
  'repeating_decimal_to_fraction': 60, // G8 · Repeating decimal → fraction
  'percent_intro': 18, // G6 · What is a percent?
  'percent_of_quantity': 30, // G6 · Percent of a number
  'find_whole_from_part_percent': 45, // G6 · Find whole from a percent
  'percent_change': 45, // G7 · Percent increase/decrease
  'markup_markdown': 50, // G7 · Markup and markdown
  'sales_tax_tip': 50, // G7 · Sales tax and tip
  'simple_interest': 45, // G7 · Simple interest
  'commission': 45, // G7 · Commission
  'convert_fraction_decimal_percent': 25, // G6 · Convert F/D/%
  // -- Ratios & proportions --------------------------------------------------
  'ratio_intro': 18, // G6 · What is a ratio?
  'ratio_language': 16, // G6 · Ratio language (a:b, a to b)
  'equivalent_ratios': 22, // G6 · Equivalent ratios
  'ratio_table': 28, // G6 · Ratio tables
  'unit_rate': 28, // G6 · Unit rate
  'unit_pricing': 40, // G6 · Unit pricing
  'constant_speed': 45, // G6 · Constant-speed problems
  'convert_units_using_ratio': 40, // G6 · Convert units (ratio)
  'double_number_line': 28, // G6 · Double number line
  'ratio_to_coordinate_pairs': 30, // G6 · Plot ratios as ordered pairs
  'unit_rate_with_fractions': 45, // G7 · Unit rate (fractions)
  'proportional_relationship': 28, // G7 · Is it proportional?
  'constant_of_proportionality': 28, // G7 · Constant k in y=kx
  'proportional_equation': 28, // G7 · Write y = kx
  'multistep_ratio_word': 70, // G7 · Multi-step ratio problems
  'scale_drawing': 45, // G7 · Scale drawings
  // -- Measurement -----------------------------------------------------------
  'describe_attribute': 5, // K · Describe length/weight
  'compare_two_objects': 5, // K · Compare objects directly
  'order_three_objects_length': 7, // G1 · Order three by length
  'measure_length_units': 8, // G1 · Measure with same-size units
  'measure_with_ruler_cm': 9, // G2 · Measure with ruler (cm)
  'estimate_length': 8, // G2 · Estimate length
  'length_word_problems': 18, // G2 · Length word problems
  'length_diff_units': 12, // G2 · How much longer?
  'measure_to_half_cm': 10, // G3 · Measure to ½ cm
  'time_to_hour_half': 6, // G1 · Time to hour and half-hour
  'time_to_5_min': 9, // G2 · Time to 5 minutes
  'time_to_minute': 12, // G3 · Time to the minute
  'am_pm': 7, // G2 · a.m. vs. p.m.
  'elapsed_time': 25, // G3 · Elapsed time
  'liquid_volume_mass': 18, // G3 · Liquid volume / mass
  'convert_units_within_system': 25, // G4 · Convert units (one system)
  'convert_units_multistep': 45, // G5 · Convert in word problems
  'area_rectangle_count_squares': 12, // G3 · Area by counting squares
  'area_rectangle_formula': 15, // G3 · Area = l × w
  'perimeter_polygon': 18, // G3 · Perimeter of polygon
  'perimeter_unknown_side': 20, // G3 · Find missing side (perimeter)
  'area_perimeter_word': 40, // G4 · Area/perimeter word problems
  'volume_unit_cubes': 18, // G5 · Volume by counting cubes
  'volume_rect_prism_formula': 25, // G5 · Volume = l × w × h
  'volume_composite': 45, // G5 · Volume of composite figures
  'volume_prism_fractional_edges': 45, // G6 · Prism volume (fractional edges)
  'surface_area_from_net': 60, // G6 · Surface area from net
  'volume_cylinder': 45, // G8 · Volume of a cylinder
  'volume_cone': 50, // G8 · Volume of a cone
  'volume_sphere': 45, // G8 · Volume of a sphere
  // -- Geometry --------------------------------------------------------------
  'identify_shape_2d': 4, // K · Name 2D shapes
  'identify_shape_3d': 5, // K · Name 3D shapes
  'positional_words': 5, // K · Above, below, beside
  'shape_attributes_basic': 6, // G1 · Sides and corners
  'compose_shapes': 8, // G1 · Build shapes from shapes
  'partition_circle_rect_halves': 6, // G1 · Halves of circle/rectangle
  'identify_polygons': 7, // G2 · Triangles, quads, pentagons, hexagons
  'partition_into_rows_columns': 9, // G2 · Rows × columns of squares
  'classify_quadrilaterals': 12, // G3 · Classify quadrilaterals
  'identify_lines_rays_segments': 10, // G4 · Lines, rays, segments
  'right_acute_obtuse_angle': 10, // G4 · Right / acute / obtuse
  'parallel_perpendicular_lines': 10, // G4 · Parallel and perpendicular
  'classify_2d_by_lines_angles': 15, // G4 · Classify by lines/angles
  'line_of_symmetry': 14, // G4 · Lines of symmetry
  'measure_angle_protractor': 25, // G4 · Measure angle with protractor
  'draw_angle_protractor': 25, // G4 · Draw angle with protractor
  'angle_addition': 25, // G4 · Add angle measures
  'classify_2d_hierarchy': 18, // G5 · Shape hierarchy
  'plot_first_quadrant': 15, // G5 · Plot in 1st quadrant
  'read_first_quadrant': 14, // G5 · Read coordinates Q1
  'area_triangle': 30, // G6 · Area of a triangle
  'area_parallelogram': 30, // G6 · Area of a parallelogram
  'area_trapezoid': 40, // G6 · Area of a trapezoid
  'area_polygon_decompose': 50, // G6 · Area by decomposing
  'polygon_on_coordinate_plane': 40, // G6 · Polygon on coord plane
  'construct_triangle_given': 40, // G7 · Construct a triangle
  'triangle_inequality_recognize': 25, // G7 · Possible triangle?
  'cross_section_3d': 25, // G7 · Cross-sections of 3D solids
  'circle_circumference': 40, // G7 · Circumference of a circle
  'area_circle': 40, // G7 · Area of a circle
  'supplementary_angles': 22, // G7 · Supplementary angles
  'complementary_angles': 22, // G7 · Complementary angles
  'vertical_angles': 20, // G7 · Vertical angles
  'adjacent_angles': 22, // G7 · Adjacent angles
  'transformations_translation': 28, // G8 · Translations
  'transformations_reflection': 28, // G8 · Reflections
  'transformations_rotation': 30, // G8 · Rotations
  'transformations_dilation': 30, // G8 · Dilations
  'congruence_via_transformations': 28, // G8 · Congruent figures
  'similarity_via_transformations': 28, // G8 · Similar figures
  'triangle_angle_sum': 28, // G8 · Triangle angles sum to 180°
  'exterior_angle_triangle': 30, // G8 · Exterior angle theorem
  'parallel_lines_transversal': 30, // G8 · Parallel lines and a transversal
  'pythagorean_apply_2d': 45, // G8 · Pythagorean theorem (2D)
  'pythagorean_apply_3d': 60, // G8 · Pythagorean theorem (3D)
  'pythagorean_distance_coords': 50, // G8 · Distance between two points
  // -- Rational numbers ------------------------------------------------------
  'signed_quantities_context': 18, // G6 · Negative numbers in context
  'integers_on_number_line': 14, // G6 · Integers on number line
  'opposites_and_zero': 12, // G6 · Opposites; opposite of opposite
  'absolute_value': 12, // G6 · Absolute value
  'compare_order_rationals': 22, // G6 · Order rational numbers
  'closest_to_target': 22, // G6 · Closest to a target
  'kth_value_in_list': 22, // G6 · Kth biggest / smallest in a list
  'sort_rationals': 25, // G6 · Sort values
  'plot_four_quadrants': 20, // G6 · Plot in all 4 quadrants
  'coord_distance_same_line': 22, // G6 · Distance: same x or same y
  'integers_add': 22, // G7 · Add integers
  'integers_subtract': 25, // G7 · Subtract integers
  'integers_multiply_divide': 22, // G7 · × and ÷ integers (sign rules)
  'rationals_add_sub': 40, // G7 · Add/subtract rational numbers
  'rationals_multiply_divide': 40, // G7 · × and ÷ rational numbers
  'rationals_four_op_word': 60, // G7 · Word problems with rationals
  'rational_to_decimal_terminating': 25, // G7 · Rational → terminating decimal
  'rational_to_decimal_repeating': 40, // G8 · Rational → repeating decimal
  'irrational_recognize': 18, // G8 · Rational vs. irrational
  'approximate_irrational': 25, // G8 · Approximate √2, π
  // -- Pre-algebra -----------------------------------------------------------
  'missing_addend_within_20': 7, // G1 · Find missing addend
  'missing_factor': 10, // G3 · Find missing factor
  'numerical_pattern_rule': 15, // G4 · Pattern rule
  'two_pattern_relationships': 25, // G5 · Compare two patterns
  'write_expression_from_words': 25, // G6 · Write expression from words
  'evaluate_expression': 25, // G6 · Evaluate expression at a value
  'identify_parts_expression': 18, // G6 · Term, factor, coefficient
  'equivalent_expressions_props': 30, // G6 · Equivalent expressions
  'substitute_to_check': 25, // G6 · Substitute to check
  'solve_one_step_eq_addition': 18, // G6 · Solve x + p = q
  'solve_one_step_eq_mult': 18, // G6 · Solve px = q
  'inequality_one_var_intro': 22, // G6 · Inequalities x > c, x < c
  'dependent_independent_vars': 18, // G6 · Independent vs. dependent variable
  'add_subtract_linear_expressions': 40, // G7 · Combine like terms (linear)
  'factor_linear_expression': 40, // G7 · Factor a linear expression
  'expand_linear_expression': 30, // G7 · Expand: a(b+c)
  'solve_two_step_eq': 45, // G7 · Solve px + q = r
  'solve_two_step_eq_distributive': 50, // G7 · Solve p(x+q) = r
  'solve_two_step_inequality': 50, // G7 · Solve px + q > r
  'word_problem_two_step_eq': 60, // G7 · Two-step equation word problem
  'solve_linear_eq_one_solution': 45, // G8 · Linear eq: one solution
  'solve_linear_eq_no_or_inf': 30, // G8 · No solution or infinite
  'solve_linear_eq_with_distrib_collect': 60, // G8 · Distrib + combine + solve
  'graph_proportional_slope': 30, // G8 · Graph proportional, find slope
  'derive_y_eq_mx_b': 45, // G8 · Derive y = mx + b
  'slope_from_two_points': 40, // G8 · Slope from two points
  'linear_function_construct': 50, // G8 · Construct a linear function
  'function_evaluate_at_point': 30, // G8 · Evaluate f(x) at a value
  'graph_linear_equation': 45, // G8 · Graph y = mx + b
  'identify_linear_vs_nonlinear': 22, // G8 · Linear or nonlinear?
  'function_definition_check': 22, // G8 · Is it a function?
  'compare_functions_representations': 50, // G8 · Compare functions across reps
  'qualitative_graph_features': 25, // G8 · Read a graph qualitatively
  'solve_system_by_graphing': 60, // G8 · System: graph and find intersect
  'solve_system_substitution': 70, // G8 · System: substitution
  'solve_system_elimination': 70, // G8 · System: elimination
  'inspect_system_no_solution': 30, // G8 · How many solutions?
  'system_word_problem': 90, // G8 · Word problem → system
  // -- Statistics & probability ----------------------------------------------
  'classify_count_categories': 6, // K · Sort and count
  'three_category_data': 8, // G1 · Picture/bar (3 categories)
  'picture_graph_read': 9, // G2 · Read a picture graph
  'bar_graph_read': 9, // G2 · Read a bar graph
  'bar_graph_compare': 14, // G2 · Bar graph: compare problems
  'line_plot_whole': 9, // G2 · Line plot (whole units)
  'scaled_bar_graph_read': 12, // G3 · Scaled bar graph
  'scaled_picture_graph': 12, // G3 · Scaled picture graph
  'line_plot_fractional': 25, // G4 · Line plot (½, ¼, ⅛)
  'line_plot_fraction_word': 30, // G4 · Line plot fraction problems
  'line_plot_5th_grade_ops': 40, // G5 · Line plot with fraction ops
  'statistical_question': 18, // G6 · Is it a statistical question?
  'dot_plot': 25, // G6 · Dot plot
  'histogram': 28, // G6 · Histogram
  'box_plot': 45, // G6 · Box plot
  'mean': 45, // G6 · Mean (average)
  'median': 30, // G6 · Median
  'mode': 20, // G6 · Mode
  'range_data': 20, // G6 · Range
  'iqr': 50, // G6 · Interquartile range
  'mad': 60, // G6 · Mean absolute deviation
  'describe_distribution': 28, // G6 · Describe shape/center/spread
  'compare_two_distributions': 30, // G7 · Compare distributions
  'sampling_representativeness': 25, // G7 · Is the sample fair?
  'inference_from_sample': 30, // G7 · Make inferences from a sample
  'probability_zero_to_one': 18, // G7 · Probability: 0 to 1 scale
  'probability_simple_event': 22, // G7 · P(simple event)
  'experimental_probability': 28, // G7 · Probability from data
  'theoretical_vs_experimental': 28, // G7 · Theoretical vs. experimental
  'sample_space_list': 30, // G7 · List sample space
  'compound_event_probability': 45, // G7 · P(compound event)
  'tree_diagram': 45, // G7 · Tree diagram
  'simulate_compound': 40, // G7 · Simulate to estimate P
  'scatter_plot_construct': 40, // G8 · Make a scatter plot
  'scatter_plot_describe': 25, // G8 · Describe scatter pattern
  'informal_line_of_fit': 40, // G8 · Fit a line to data
  'interpret_slope_intercept_data': 40, // G8 · Interpret slope/intercept (data)
  'two_way_table_construct': 40, // G8 · Two-way table
  'two_way_relative_frequency': 45, // G8 · Relative frequency in 2-way table
};
