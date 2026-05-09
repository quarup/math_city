# Math City — Curriculum Reference

> Canonical reference for the K–8 math content in Math City.
> Anchored on the US **Common Core State Standards (CCSS) for Mathematics, K–8**.
> Companion to: [prd.md](prd.md) (product scope) and [plan.md](plan.md) (execution).

---

## Status

- **Last updated:** 2026-05-09
- **Curriculum standard:** US Common Core State Standards (CCSS) for Mathematics, K–8
- **Categories:** 12
- **Sub-concepts:** ~361
- **Coverage strategy:** mostly algorithmic generation (~90% of K–8 reachable) backed by procedural diagram widgets, with a small bundled dataset filling in rich word problems and edge cases.
- **What this document is:** the canonical taxonomy of *what* the app teaches and *where* the questions for each sub-concept come from. The sub-concept IDs here are the source of truth — `lib/domain/concepts/` mirrors them.
- **What this document is not:** an implementation plan. See [plan.md](plan.md) for phase ordering, schemas, and exit criteria.

---

## 1. Design principles

These are locked-in decisions that shape everything else in this document.

1. **K–8 only.** Anchored on CCSS K–8; intentionally excludes high school (Algebra I/II, Geometry-as-course, Pre-calc, Calculus). Product targets ages 6–14.
2. **Per-sub-concept proficiency.** The wheel surfaces sub-concepts (atomic, like `add_2digit_carry`); proficiency is tracked at the sub-concept level. Categories are display-only rollups for the progress screen.
3. **Grade tags initialize, the DAG progresses.** A player's stated grade seeds initial proficiency for sub-concepts at and below that grade. After initialization, **no cross-domain gating** — a kid advanced in arithmetic but behind in geometry sees both branches advance independently. The "introduce next" logic walks the prerequisite DAG: when a sub-concept reaches the `mastered` band, its DAG children become eligible to surface on the wheel (subject to grade-band thresholds for initial value).
4. **Algorithmic generation is preferred.** Where a parameterized Dart generator can produce infinite, correct, age-appropriate questions with deterministic answers and templated step-by-step explanations, we generate. Generators store compactly and feel limitless.
5. **Procedural diagrams over bundled images.** Geometry, fractions, clocks, coordinate planes, etc. are rendered by parameterized Flutter widgets (using `flutter_svg` or `CustomPainter`). A small set of high-leverage widgets (§6) unlocks most non-arithmetic content. Where rendering is prohibitive (e.g., complex 3D nets), fall back to text-only or defer.
6. **Bundled datasets, not runtime LLM calls.** Open-licensed datasets (MIT / Apache 2.0 / CC-BY) are ingested at build time into the bundled question catalog. The PRD's "no cloud LLM calls at runtime" constraint is absolute. **Offline LLM batch generation is also deferred for v1** — first see how far datasets + generators get us.
7. **License hygiene.** Every datum or asset shipped is permissively licensed (MIT / Apache 2.0 / CC-BY / CC0). CC-BY-NC and CC-BY-NC-SA content is treated as red-flagged for app-store distribution; we don't bundle it in v1. Attribution accumulates in `LICENSES_THIRD_PARTY.md` as we go.
8. **Difficulty ordering is within-category only.** Each `### 3.x` table is sorted by within-grade difficulty (after `Grade`); the row order within a category is the curated difficulty signal that the drip-feed engine uses as a tiebreaker. **No global cross-category difficulty order exists or is needed** — `Grade` is the coarse cross-category signal, the DAG handles cross-category prereqs, and the drip-feed uses a cheap policy ("introduce into the category the player has the fewest active concepts in") for cross-category tiebreaks. Adding or rearranging concepts within one category never requires touching another.

---

## 2. Top-level categories

These are the rollup buckets shown on the player progress screen. Each sub-concept in §3 belongs to exactly one category.

| ID | Display | Sub-concepts | Grades |
|---|---|---|---|
| `counting` | Counting & Number Sense | 20 | K–2 |
| `place_value` | Place Value & Number Properties | 28 | 1–8 |
| `add_sub` | Addition & Subtraction | 30 | K–4 |
| `mult_div` | Multiplication & Division | 34 | 2–5 |
| `fractions` | Fractions | 31 | 1–6 |
| `decimals_percent` | Decimals & Percentages | 28 | 4–7 |
| `ratios` | Ratios & Proportions | 16 | 6–7 |
| `measurement` | Measurement, Time & Money | 37 | K–6 |
| `geometry` | Geometry & Shapes | 45 | K–8 |
| `rationals` | Integers & Rational Numbers | 17 | 6–8 |
| `prealgebra` | Pre-Algebra (Expressions, Equations, Functions) | 36 | 6–8 |
| `stats` | Data, Statistics & Probability | 39 | K–8 |

**Total:** ~361 sub-concepts. Implementation will phase these in — initial Phase 6 catalog targets a useful K–3 subset; full coverage rolls out across multiple phases.

---

## 3. Sub-concept catalog

The columns:

- **ID** — `snake_case`. Mirrored exactly in `lib/domain/concepts/`.
- **Display** — kid-friendly name shown on the wheel.
- **Grade** — primary grade (K=0, 1–8). Used **only for initialization**; not for runtime gating.
- **Prereqs** — DAG predecessor IDs. Empty `[]` = root node. Drives the "introduce next" logic.
- **Source** — question source strategy:
  - `algorithmic` — pure parameterized generator
  - `algorithmic_with_diagram` — generator + procedural diagram widget
  - `dataset` — bundled curated questions (with optional templating)
  - `algorithmic+dataset` — mostly generator, dataset for edge cases
  - `deferred` — out of v1; kept in catalog for later phases
- **Diagram** — `none` / `optional` / `required:<kind>` (see §6 for widget catalog).

**Row order within each table is meaningful.** Per design principle 8, rows are sorted by `Grade` ascending and then by within-grade difficulty (curated). The drip-feed engine uses this row order as the within-category tiebreaker when introducing the next concept. When adding or editing a concept, place it at the row position that reflects its difficulty relative to siblings *in this category only* — no need to consider other categories.

### 3.1 Counting & Number Sense (`counting`)

| ID | Display | Grade | Prereqs | Source | Diagram |
|---|---|---|---|---|---|
| `count_to_10` | Count to 10 | 0 | [] | algorithmic | optional |
| `count_to_20` | Count to 20 | 0 | [count_to_10] | algorithmic | optional |
| `count_to_100_by_1` | Count to 100 | 0 | [count_to_20] | algorithmic | none |
| `count_to_100_by_10` | Count by tens | 0 | [count_to_20] | algorithmic | none |
| `count_to_120` | Count to 120 | 1 | [count_to_100_by_1] | algorithmic | none |
| `count_forward_from_n` | Count up from any number | 0 | [count_to_20] | algorithmic | none |
| `read_numerals_0_20` | Read numbers 0–20 | 0 | [count_to_20] | algorithmic | none |
| `write_numerals_0_20` | Write numbers 0–20 | 0 | [read_numerals_0_20] | algorithmic | optional |
| `count_objects_to_10` | Count objects (10) | 0 | [] | algorithmic_with_diagram | required:array_grid |
| `count_objects_to_20` | Count objects (20) | 0 | [count_objects_to_10] | algorithmic_with_diagram | required:array_grid |
| `compare_groups_by_count` | Which group has more? | 0 | [count_objects_to_10] | algorithmic_with_diagram | required:array_grid |
| `compare_numerals_1_10` | Compare two numbers (1–10) | 0 | [read_numerals_0_20] | algorithmic | none |
| `one_more_one_less_within_20` | One more / one less | 0 | [count_to_20] | algorithmic | none |
| `ten_more_ten_less` | Ten more / ten less | 1 | [count_to_100_by_10] | algorithmic | none |
| `skip_count_2` | Skip count by 2s | 1 | [count_to_100_by_1] | algorithmic | none |
| `skip_count_5` | Skip count by 5s | 2 | [skip_count_2] | algorithmic | none |
| `skip_count_10` | Skip count by 10s | 1 | [count_to_100_by_10] | algorithmic | none |
| `skip_count_100` | Skip count by 100s | 2 | [skip_count_10] | algorithmic | none |
| `count_within_1000` | Count within 1000 | 2 | [count_to_120] | algorithmic | none |
| `even_odd` | Even or odd? | 2 | [skip_count_2] | algorithmic | none |

### 3.2 Place Value & Number Properties (`place_value`)

| ID | Display | Grade | Prereqs | Source | Diagram |
|---|---|---|---|---|---|
| `teen_numbers_as_ten_plus` | Teens as ten + ones | 0 | [count_to_20] | algorithmic_with_diagram | required:base_ten_blocks |
| `place_value_2digit` | Tens and ones | 1 | [teen_numbers_as_ten_plus] | algorithmic | optional |
| `compare_2digit` | Compare 2-digit numbers | 1 | [place_value_2digit] | algorithmic | none |
| `place_value_3digit` | Hundreds, tens, ones | 2 | [place_value_2digit] | algorithmic | optional |
| `read_write_3digit` | Read/write to 1000 | 2 | [place_value_3digit] | algorithmic | none |
| `expanded_form_3digit` | Expanded form (3-digit) | 2 | [place_value_3digit] | algorithmic | none |
| `compare_3digit` | Compare 3-digit numbers | 2 | [place_value_3digit, compare_2digit] | algorithmic | none |
| `round_to_10` | Round to nearest 10 | 3 | [compare_2digit] | algorithmic | optional |
| `round_to_100` | Round to nearest 100 | 3 | [compare_3digit] | algorithmic | optional |
| `place_value_multidigit` | Multi-digit place value | 4 | [place_value_3digit] | algorithmic | none |
| `read_write_multidigit` | Read/write big numbers | 4 | [place_value_multidigit] | algorithmic | none |
| `compare_multidigit` | Compare big numbers | 4 | [read_write_multidigit] | algorithmic | none |
| `round_multidigit_any_place` | Round to any place | 4 | [round_to_100, place_value_multidigit] | algorithmic | none |
| `place_value_relationship_10x` | Each place is 10× the next | 5 | [place_value_multidigit] | algorithmic | none |
| `factors_of_n` | Find factors | 4 | [mult_facts_within_100] | algorithmic | none |
| `multiples_of_n` | Find multiples | 4 | [skip_count_2] | algorithmic | none |
| `prime_or_composite` | Prime or composite? | 4 | [factors_of_n] | algorithmic | none |
| `gcf_two_numbers` | Greatest common factor | 6 | [factors_of_n] | algorithmic | none |
| `lcm_two_numbers` | Least common multiple | 6 | [multiples_of_n] | algorithmic | none |
| `distributive_with_gcf` | Factor out the GCF | 6 | [gcf_two_numbers] | algorithmic | none |
| `powers_of_10` | Powers of 10 | 5 | [place_value_relationship_10x] | algorithmic | none |
| `exponents_whole_number` | Whole-number exponents | 6 | [powers_of_10] | algorithmic | none |
| `integer_exponent_props` | Properties of exponents | 8 | [exponents_whole_number, integers_multiply_divide] | algorithmic | none |
| `sqrt_perfect_squares` | Square roots (perfect) | 8 | [exponents_whole_number] | algorithmic | none |
| `cbrt_perfect_cubes` | Cube roots (perfect) | 8 | [exponents_whole_number] | algorithmic | none |
| `scientific_notation_read` | Read scientific notation | 8 | [powers_of_10] | algorithmic | none |
| `scientific_notation_write` | Write scientific notation | 8 | [scientific_notation_read] | algorithmic | none |
| `scientific_notation_ops` | Operate in scientific notation | 8 | [scientific_notation_write, mult_decimals] | algorithmic | none |

### 3.3 Addition & Subtraction (`add_sub`)

| ID | Display | Grade | Prereqs | Source | Diagram |
|---|---|---|---|---|---|
| `add_within_5` | Add within 5 | 0 | [] | algorithmic | optional |
| `sub_within_5` | Subtract within 5 | 0 | [add_within_5] | algorithmic | optional |
| `add_within_10` | Add within 10 | 0 | [add_within_5] | algorithmic | optional |
| `sub_within_10` | Subtract within 10 | 0 | [sub_within_5, add_within_10] | algorithmic | optional |
| `make_10_pair` | Pairs that make 10 | 0 | [add_within_10] | algorithmic | optional |
| `decompose_10` | Decompose 10 (or less) | 0 | [add_within_10] | algorithmic | optional |
| `add_3_addends_within_20` | Add three numbers | 1 | [add_within_10] | algorithmic | none |
| `add_within_20` | Add within 20 | 1 | [add_within_10, make_10_pair] | algorithmic | none |
| `sub_within_20` | Subtract within 20 | 1 | [sub_within_10, decompose_10] | algorithmic | none |
| `add_sub_unknown_position` | Find the missing number | 1 | [add_within_20, sub_within_20] | algorithmic | none |
| `equal_sign_meaning` | Is the equation true? | 1 | [add_within_10] | algorithmic | none |
| `commutative_add` | a + b = b + a | 1 | [add_within_20] | algorithmic | none |
| `associative_add` | (a+b)+c = a+(b+c) | 1 | [add_3_addends_within_20] | algorithmic | none |
| `add_2digit_1digit` | 2-digit + 1-digit | 1 | [add_within_20, place_value_2digit] | algorithmic | none |
| `add_2digit_multiple_of_10` | 2-digit + multiple of 10 | 1 | [skip_count_10, add_within_20] | algorithmic | none |
| `sub_multiples_of_10` | Subtract multiples of 10 | 1 | [skip_count_10] | algorithmic | none |
| `add_within_100` | Add within 100 | 2 | [add_2digit_1digit, place_value_2digit] | algorithmic | none |
| `sub_within_100` | Subtract within 100 | 2 | [sub_within_20, place_value_2digit] | algorithmic | none |
| `add_2digit_carry` | 2-digit + with regrouping | 2 | [add_within_100] | algorithmic | none |
| `sub_2digit_borrow` | 2-digit − with regrouping | 2 | [sub_within_100] | algorithmic | none |
| `add_up_to_4_2digit` | Add up to four 2-digit numbers | 2 | [add_within_100] | algorithmic | none |
| `add_within_1000` | Add within 1000 | 2 | [add_2digit_carry, place_value_3digit] | algorithmic | none |
| `sub_within_1000` | Subtract within 1000 | 2 | [sub_2digit_borrow, place_value_3digit] | algorithmic | none |
| `mental_add_10_or_100` | Mental ±10 / ±100 | 2 | [ten_more_ten_less, place_value_3digit] | algorithmic | none |
| `add_word_problems_within_100` | +/− word problems (100) | 2 | [add_within_100, sub_within_100] | dataset | optional |
| `add_sub_2step_word_problems` | Two-step word problems | 2 | [add_word_problems_within_100] | dataset | optional |
| `add_multidigit_standard_alg` | Multi-digit + (algorithm) | 4 | [add_within_1000, place_value_multidigit] | algorithmic | none |
| `sub_multidigit_standard_alg` | Multi-digit − (algorithm) | 4 | [sub_within_1000, place_value_multidigit] | algorithmic | none |
| `add_sub_fluency_within_20` | +/− facts within 20 (memory) | 2 | [add_within_20, sub_within_20] | algorithmic | none |
| `number_line_add_sub` | +/− on number line | 2 | [add_within_100] | algorithmic_with_diagram | required:number_line |

### 3.4 Multiplication & Division (`mult_div`)

| ID | Display | Grade | Prereqs | Source | Diagram |
|---|---|---|---|---|---|
| `equal_groups_intro` | Equal groups (rows × cols) | 2 | [skip_count_5, add_within_100] | algorithmic_with_diagram | required:array_grid |
| `array_repeated_addition` | Arrays as repeated + | 2 | [equal_groups_intro] | algorithmic_with_diagram | required:array_grid |
| `mult_meaning_groups` | What does 5 × 7 mean? | 3 | [equal_groups_intro] | algorithmic_with_diagram | required:array_grid |
| `mult_facts_within_100` | × facts to 100 | 3 | [mult_meaning_groups, skip_count_2, skip_count_5, skip_count_10] | algorithmic | none |
| `mult_facts_2` | ×2 facts | 3 | [skip_count_2] | algorithmic | none |
| `mult_facts_5` | ×5 facts | 3 | [skip_count_5] | algorithmic | none |
| `mult_facts_10` | ×10 facts | 3 | [skip_count_10] | algorithmic | none |
| `mult_facts_3` | ×3 facts | 3 | [mult_meaning_groups] | algorithmic | none |
| `mult_facts_4` | ×4 facts | 3 | [mult_facts_2] | algorithmic | none |
| `mult_facts_6` | ×6 facts | 3 | [mult_facts_3] | algorithmic | none |
| `mult_facts_7` | ×7 facts | 3 | [mult_facts_5, mult_facts_2] | algorithmic | none |
| `mult_facts_8` | ×8 facts | 3 | [mult_facts_4] | algorithmic | none |
| `mult_facts_9` | ×9 facts | 3 | [mult_facts_3, mult_facts_10] | algorithmic | none |
| `div_meaning_share` | Sharing equally | 3 | [mult_facts_within_100] | algorithmic_with_diagram | required:array_grid |
| `div_meaning_grouping` | How many groups? | 3 | [mult_facts_within_100] | algorithmic_with_diagram | required:array_grid |
| `div_facts_within_100` | ÷ facts to 100 | 3 | [mult_facts_within_100, div_meaning_share] | algorithmic | none |
| `div_as_unknown_factor` | ÷ as missing factor | 3 | [mult_facts_within_100] | algorithmic | none |
| `commutative_mult` | a × b = b × a | 3 | [mult_facts_within_100] | algorithmic | none |
| `associative_mult` | (a·b)·c = a·(b·c) | 3 | [mult_facts_within_100] | algorithmic | none |
| `distributive_mult_over_add` | Distributive property | 3 | [mult_facts_within_100] | algorithmic_with_diagram | required:array_grid |
| `mult_1digit_by_multiple_of_10` | 1-digit × multiple of 10 | 3 | [mult_facts_within_100, skip_count_10] | algorithmic | none |
| `div_with_remainder` | ÷ with remainder | 4 | [div_facts_within_100] | algorithmic | none |
| `interpret_remainder_word` | Interpret remainder in story | 4 | [div_with_remainder] | dataset | optional |
| `mult_compare_word` | Multiplicative comparison | 4 | [mult_facts_within_100] | dataset | optional |
| `mult_4digit_by_1digit` | 4-digit × 1-digit | 4 | [mult_facts_within_100, place_value_multidigit] | algorithmic | none |
| `mult_2digit_by_2digit` | 2-digit × 2-digit | 4 | [mult_4digit_by_1digit] | algorithmic | none |
| `div_4digit_by_1digit` | 4-digit ÷ 1-digit | 4 | [div_with_remainder, place_value_multidigit] | algorithmic | none |
| `mult_multidigit_standard_alg` | Multi-digit × (algorithm) | 5 | [mult_2digit_by_2digit] | algorithmic | none |
| `div_4digit_by_2digit` | 4-digit ÷ 2-digit | 5 | [div_4digit_by_1digit] | algorithmic | none |
| `mult_div_word_2step` | Multi-step word problems | 4 | [mult_compare_word, add_sub_2step_word_problems] | dataset | optional |
| `arithmetic_patterns_in_tables` | Patterns in × and + tables | 3 | [mult_facts_within_100] | algorithmic | none |
| `order_of_operations_no_exp` | Order of operations | 5 | [mult_facts_within_100, add_within_1000] | algorithmic | none |
| `order_of_operations_with_exp` | Order with exponents | 6 | [order_of_operations_no_exp, exponents_whole_number] | algorithmic | none |
| `nested_grouping` | Brackets and braces | 5 | [order_of_operations_no_exp] | algorithmic | none |

### 3.5 Fractions (`fractions`)

| ID | Display | Grade | Prereqs | Source | Diagram |
|---|---|---|---|---|---|
| `partition_halves_fourths` | Halves and fourths | 1 | [] | algorithmic_with_diagram | required:fraction_bar |
| `partition_thirds` | Thirds | 2 | [partition_halves_fourths] | algorithmic_with_diagram | required:fraction_bar |
| `unit_fraction_intro` | What is 1/b? | 3 | [partition_thirds] | algorithmic_with_diagram | required:fraction_bar |
| `fraction_a_over_b` | What is a/b? | 3 | [unit_fraction_intro] | algorithmic_with_diagram | required:fraction_bar |
| `fraction_on_number_line` | Fractions on a number line | 3 | [fraction_a_over_b] | algorithmic_with_diagram | required:number_line |
| `equivalent_fractions_visual` | Equal fractions (with picture) | 3 | [fraction_a_over_b] | algorithmic_with_diagram | required:fraction_bar |
| `equivalent_fractions_compute` | Find equivalent fraction | 4 | [equivalent_fractions_visual, mult_facts_within_100] | algorithmic | none |
| `compare_fractions_same_denom` | Compare (same bottom) | 3 | [fraction_a_over_b] | algorithmic | optional |
| `compare_fractions_same_num` | Compare (same top) | 3 | [fraction_a_over_b] | algorithmic | optional |
| `compare_fractions_unlike` | Compare unlike fractions | 4 | [equivalent_fractions_compute] | algorithmic | none |
| `whole_number_as_fraction` | Whole numbers as fractions | 3 | [fraction_a_over_b] | algorithmic | none |
| `simplify_fraction` | Simplify fractions | 4 | [equivalent_fractions_compute, gcf_two_numbers] | algorithmic | none |
| `improper_to_mixed` | Improper → mixed number | 4 | [fraction_a_over_b] | algorithmic | optional |
| `mixed_to_improper` | Mixed number → improper | 4 | [improper_to_mixed] | algorithmic | optional |
| `add_fractions_like_denom` | Add fractions (same bottom) | 4 | [fraction_a_over_b, add_within_20] | algorithmic | optional |
| `sub_fractions_like_denom` | Subtract fractions (same bottom) | 4 | [add_fractions_like_denom] | algorithmic | optional |
| `add_mixed_like_denom` | Add mixed numbers (like) | 4 | [add_fractions_like_denom, mixed_to_improper] | algorithmic | optional |
| `sub_mixed_like_denom` | Subtract mixed numbers (like) | 4 | [sub_fractions_like_denom, mixed_to_improper] | algorithmic | optional |
| `mult_fraction_by_whole` | Fraction × whole number | 4 | [fraction_a_over_b, mult_facts_within_100] | algorithmic | optional |
| `add_fractions_unlike_denom` | Add fractions (unlike) | 5 | [add_fractions_like_denom, equivalent_fractions_compute, lcm_two_numbers] | algorithmic | none |
| `sub_fractions_unlike_denom` | Subtract fractions (unlike) | 5 | [add_fractions_unlike_denom] | algorithmic | none |
| `add_mixed_unlike_denom` | Add mixed (unlike) | 5 | [add_fractions_unlike_denom] | algorithmic | none |
| `sub_mixed_unlike_denom` | Subtract mixed (unlike) | 5 | [sub_fractions_unlike_denom] | algorithmic | none |
| `fraction_as_division` | Fraction as a ÷ b | 5 | [div_facts_within_100, fraction_a_over_b] | algorithmic | none |
| `mult_fractions_proper` | Fraction × fraction | 5 | [mult_fraction_by_whole] | algorithmic_with_diagram | required:area_grid |
| `mult_mixed_numbers` | × with mixed numbers | 5 | [mult_fractions_proper, mixed_to_improper] | algorithmic | none |
| `mult_as_scaling` | Multiplication as scaling | 5 | [mult_fractions_proper] | algorithmic | none |
| `div_unit_fraction_by_whole` | Unit fraction ÷ whole | 5 | [fraction_a_over_b, div_facts_within_100] | algorithmic_with_diagram | required:fraction_bar |
| `div_whole_by_unit_fraction` | Whole ÷ unit fraction | 5 | [div_unit_fraction_by_whole] | algorithmic_with_diagram | required:fraction_bar |
| `div_fraction_by_fraction` | Fraction ÷ fraction | 6 | [div_unit_fraction_by_whole, div_whole_by_unit_fraction, mult_fractions_proper] | algorithmic | none |
| `fraction_word_problems` | Fraction word problems | 5 | [add_fractions_unlike_denom, mult_fraction_by_whole] | dataset | optional |

### 3.6 Decimals & Percentages (`decimals_percent`)

| ID | Display | Grade | Prereqs | Source | Diagram |
|---|---|---|---|---|---|
| `fraction_denom_10_100` | Tenths and hundredths | 4 | [fraction_a_over_b] | algorithmic_with_diagram | required:fraction_bar |
| `decimal_notation_tenths` | Decimal: tenths | 4 | [fraction_denom_10_100] | algorithmic | optional |
| `decimal_notation_hundredths` | Decimal: hundredths | 4 | [decimal_notation_tenths] | algorithmic | optional |
| `decimal_on_number_line` | Decimals on number line | 4 | [decimal_notation_hundredths] | algorithmic_with_diagram | required:number_line |
| `compare_decimals_hundredths` | Compare decimals to 0.01 | 4 | [decimal_notation_hundredths] | algorithmic | none |
| `decimal_to_thousandths_read` | Read decimals to 0.001 | 5 | [compare_decimals_hundredths] | algorithmic | none |
| `compare_decimals_thousandths` | Compare decimals to 0.001 | 5 | [decimal_to_thousandths_read] | algorithmic | none |
| `round_decimals` | Round decimals | 5 | [decimal_to_thousandths_read, round_to_100] | algorithmic | none |
| `add_decimals` | Add decimals (to 0.01) | 5 | [decimal_notation_hundredths, add_multidigit_standard_alg] | algorithmic | none |
| `sub_decimals` | Subtract decimals (to 0.01) | 5 | [add_decimals] | algorithmic | none |
| `mult_decimal_by_whole` | Decimal × whole | 5 | [mult_multidigit_standard_alg, decimal_notation_hundredths] | algorithmic | none |
| `mult_decimals` | Decimal × decimal | 5 | [mult_decimal_by_whole] | algorithmic | none |
| `div_decimal_by_whole` | Decimal ÷ whole | 5 | [div_4digit_by_1digit, decimal_notation_hundredths] | algorithmic | none |
| `div_by_decimal` | ÷ by a decimal | 6 | [mult_decimals, div_decimal_by_whole] | algorithmic | none |
| `decimals_fluent_4ops` | Fluent +,−,×,÷ decimals | 6 | [add_decimals, sub_decimals, mult_decimals, div_by_decimal] | algorithmic | none |
| `decimal_to_fraction` | Decimal → fraction | 5 | [decimal_notation_hundredths] | algorithmic | none |
| `fraction_to_decimal` | Fraction → decimal | 6 | [div_facts_within_100, decimal_notation_hundredths] | algorithmic | none |
| `repeating_decimal_recognize` | Repeating decimal? | 8 | [fraction_to_decimal] | algorithmic | none |
| `repeating_decimal_to_fraction` | Repeating decimal → fraction | 8 | [repeating_decimal_recognize] | algorithmic | none |
| `percent_intro` | What is a percent? | 6 | [fraction_denom_10_100] | algorithmic_with_diagram | required:area_grid |
| `percent_of_quantity` | Percent of a number | 6 | [percent_intro, mult_decimals] | algorithmic | none |
| `find_whole_from_part_percent` | Find whole from a percent | 6 | [percent_of_quantity] | algorithmic | none |
| `percent_change` | Percent increase/decrease | 7 | [percent_of_quantity] | algorithmic | none |
| `markup_markdown` | Markup and markdown | 7 | [percent_change] | dataset | optional |
| `sales_tax_tip` | Sales tax and tip | 7 | [percent_of_quantity] | dataset | optional |
| `simple_interest` | Simple interest | 7 | [percent_of_quantity] | algorithmic | none |
| `commission` | Commission | 7 | [percent_of_quantity] | algorithmic | none |
| `convert_fraction_decimal_percent` | Convert F/D/% | 6 | [decimal_to_fraction, percent_intro] | algorithmic | none |

### 3.7 Ratios & Proportions (`ratios`)

| ID | Display | Grade | Prereqs | Source | Diagram |
|---|---|---|---|---|---|
| `ratio_intro` | What is a ratio? | 6 | [mult_facts_within_100] | algorithmic_with_diagram | required:tape_diagram |
| `ratio_language` | Ratio language (a:b, a to b) | 6 | [ratio_intro] | algorithmic | none |
| `equivalent_ratios` | Equivalent ratios | 6 | [ratio_intro, mult_facts_within_100] | algorithmic | none |
| `ratio_table` | Ratio tables | 6 | [equivalent_ratios] | algorithmic_with_diagram | required:tape_diagram |
| `unit_rate` | Unit rate | 6 | [ratio_intro, div_facts_within_100] | algorithmic | none |
| `unit_pricing` | Unit pricing | 6 | [unit_rate] | dataset | optional |
| `constant_speed` | Constant-speed problems | 6 | [unit_rate] | algorithmic | none |
| `convert_units_using_ratio` | Convert units (ratio) | 6 | [unit_rate] | algorithmic | none |
| `double_number_line` | Double number line | 6 | [equivalent_ratios] | algorithmic_with_diagram | required:double_number_line |
| `ratio_to_coordinate_pairs` | Plot ratios as ordered pairs | 6 | [equivalent_ratios, plot_first_quadrant] | algorithmic_with_diagram | required:coordinate_plane_q1 |
| `unit_rate_with_fractions` | Unit rate (fractions) | 7 | [unit_rate, div_fraction_by_fraction] | algorithmic | none |
| `proportional_relationship` | Is it proportional? | 7 | [equivalent_ratios] | algorithmic_with_diagram | required:coordinate_plane_q1 |
| `constant_of_proportionality` | Constant k in y=kx | 7 | [proportional_relationship] | algorithmic | none |
| `proportional_equation` | Write y = kx | 7 | [constant_of_proportionality] | algorithmic | none |
| `multistep_ratio_word` | Multi-step ratio problems | 7 | [unit_rate, percent_of_quantity] | dataset | optional |
| `scale_drawing` | Scale drawings | 7 | [proportional_equation] | algorithmic_with_diagram | required:shape |

### 3.8 Measurement, Time & Money (`measurement`)

| ID | Display | Grade | Prereqs | Source | Diagram |
|---|---|---|---|---|---|
| `describe_attribute` | Describe length/weight | 0 | [] | algorithmic_with_diagram | required:shape |
| `compare_two_objects` | Compare objects directly | 0 | [describe_attribute] | algorithmic_with_diagram | required:shape |
| `order_three_objects_length` | Order three by length | 1 | [compare_two_objects] | algorithmic_with_diagram | required:shape |
| `measure_length_units` | Measure with same-size units | 1 | [order_three_objects_length] | algorithmic_with_diagram | required:ruler |
| `measure_with_ruler_inches` | Measure with ruler (in.) | 2 | [measure_length_units] | algorithmic_with_diagram | required:ruler |
| `measure_with_ruler_cm` | Measure with ruler (cm) | 2 | [measure_length_units] | algorithmic_with_diagram | required:ruler |
| `estimate_length` | Estimate length | 2 | [measure_with_ruler_inches, measure_with_ruler_cm] | algorithmic_with_diagram | required:shape |
| `length_word_problems` | Length word problems | 2 | [measure_with_ruler_inches, add_within_100] | dataset | optional |
| `length_diff_units` | How much longer? | 2 | [measure_with_ruler_inches, sub_within_100] | algorithmic | none |
| `measure_to_half_quarter_inch` | Measure to ½ or ¼ inch | 3 | [measure_with_ruler_inches, partition_halves_fourths] | algorithmic_with_diagram | required:ruler |
| `time_to_hour_half` | Time to hour and half-hour | 1 | [] | algorithmic_with_diagram | required:clock_analog |
| `time_to_5_min` | Time to 5 minutes | 2 | [time_to_hour_half, skip_count_5] | algorithmic_with_diagram | required:clock_analog |
| `time_to_minute` | Time to the minute | 3 | [time_to_5_min] | algorithmic_with_diagram | required:clock_analog |
| `am_pm` | a.m. vs. p.m. | 2 | [time_to_5_min] | algorithmic | none |
| `elapsed_time` | Elapsed time | 3 | [time_to_minute, add_within_100] | algorithmic_with_diagram | required:clock_analog |
| `coins_id_value` | Coin values | 1 | [] | algorithmic_with_diagram | required:money |
| `count_coins` | Count coins | 2 | [coins_id_value, skip_count_5, skip_count_10] | algorithmic_with_diagram | required:money |
| `count_bills_coins` | Bills and coins | 2 | [count_coins] | algorithmic_with_diagram | required:money |
| `money_word_problems` | Money word problems | 2 | [count_bills_coins, add_within_100] | dataset | optional |
| `change_from_purchase` | Make change | 2 | [money_word_problems, sub_within_100] | algorithmic_with_diagram | required:money |
| `liquid_volume_mass` | Liquid volume / mass | 3 | [add_within_1000] | dataset | optional |
| `convert_units_within_system` | Convert units (one system) | 4 | [mult_facts_within_100] | algorithmic | none |
| `convert_units_multistep` | Convert in word problems | 5 | [convert_units_within_system, mult_decimals] | dataset | optional |
| `area_rectangle_count_squares` | Area by counting squares | 3 | [skip_count_5] | algorithmic_with_diagram | required:area_grid |
| `area_rectangle_formula` | Area = l × w | 3 | [area_rectangle_count_squares, mult_facts_within_100] | algorithmic_with_diagram | required:shape |
| `perimeter_polygon` | Perimeter of polygon | 3 | [add_within_100] | algorithmic_with_diagram | required:shape |
| `perimeter_unknown_side` | Find missing side (perimeter) | 3 | [perimeter_polygon] | algorithmic_with_diagram | required:shape |
| `area_perimeter_word` | Area/perimeter word problems | 4 | [area_rectangle_formula, perimeter_polygon] | dataset | optional |
| `volume_unit_cubes` | Volume by counting cubes | 5 | [area_rectangle_count_squares] | algorithmic_with_diagram | required:net_3d |
| `volume_rect_prism_formula` | Volume = l × w × h | 5 | [volume_unit_cubes, mult_facts_within_100] | algorithmic_with_diagram | required:shape |
| `volume_composite` | Volume of composite figures | 5 | [volume_rect_prism_formula] | algorithmic_with_diagram | required:shape |
| `volume_prism_fractional_edges` | Prism volume (fractional edges) | 6 | [volume_rect_prism_formula, mult_fractions_proper] | algorithmic | none |
| `surface_area_from_net` | Surface area from net | 6 | [area_rectangle_formula] | algorithmic_with_diagram | required:net_3d |
| `volume_cylinder` | Volume of a cylinder | 8 | [area_circle, volume_rect_prism_formula] | algorithmic_with_diagram | required:shape |
| `volume_cone` | Volume of a cone | 8 | [volume_cylinder] | algorithmic_with_diagram | required:shape |
| `volume_sphere` | Volume of a sphere | 8 | [volume_cylinder] | algorithmic_with_diagram | required:shape |

### 3.9 Geometry & Shapes (`geometry`)

| ID | Display | Grade | Prereqs | Source | Diagram |
|---|---|---|---|---|---|
| `identify_shape_2d` | Name 2D shapes | 0 | [] | algorithmic_with_diagram | required:shape |
| `identify_shape_3d` | Name 3D shapes | 0 | [identify_shape_2d] | algorithmic_with_diagram | required:shape |
| `positional_words` | Above, below, beside | 0 | [] | algorithmic_with_diagram | required:shape |
| `shape_attributes_basic` | Sides and corners | 1 | [identify_shape_2d] | algorithmic_with_diagram | required:shape |
| `compose_shapes` | Build shapes from shapes | 1 | [identify_shape_2d] | algorithmic_with_diagram | required:shape |
| `partition_circle_rect_halves` | Halves of circle/rectangle | 1 | [partition_halves_fourths] | algorithmic_with_diagram | required:shape |
| `identify_polygons` | Triangles, quads, pentagons, hexagons | 2 | [shape_attributes_basic] | algorithmic_with_diagram | required:shape |
| `partition_into_rows_columns` | Rows × columns of squares | 2 | [identify_shape_2d] | algorithmic_with_diagram | required:array_grid |
| `classify_quadrilaterals` | Classify quadrilaterals | 3 | [identify_polygons] | algorithmic_with_diagram | required:shape |
| `identify_lines_rays_segments` | Lines, rays, segments | 4 | [] | algorithmic_with_diagram | required:shape |
| `right_acute_obtuse_angle` | Right / acute / obtuse | 4 | [identify_lines_rays_segments] | algorithmic_with_diagram | required:angle_diagram |
| `parallel_perpendicular_lines` | Parallel and perpendicular | 4 | [identify_lines_rays_segments] | algorithmic_with_diagram | required:shape |
| `classify_2d_by_lines_angles` | Classify by lines/angles | 4 | [parallel_perpendicular_lines, right_acute_obtuse_angle] | algorithmic_with_diagram | required:shape |
| `line_of_symmetry` | Lines of symmetry | 4 | [identify_polygons] | algorithmic_with_diagram | required:shape |
| `measure_angle_protractor` | Measure angle with protractor | 4 | [right_acute_obtuse_angle] | algorithmic_with_diagram | required:protractor |
| `draw_angle_protractor` | Draw angle with protractor | 4 | [measure_angle_protractor] | algorithmic_with_diagram | required:protractor |
| `angle_addition` | Add angle measures | 4 | [measure_angle_protractor] | algorithmic_with_diagram | required:angle_diagram |
| `classify_2d_hierarchy` | Shape hierarchy | 5 | [classify_quadrilaterals, classify_2d_by_lines_angles] | algorithmic_with_diagram | required:shape |
| `plot_first_quadrant` | Plot in 1st quadrant | 5 | [number_line_add_sub] | algorithmic_with_diagram | required:coordinate_plane_q1 |
| `read_first_quadrant` | Read coordinates Q1 | 5 | [plot_first_quadrant] | algorithmic_with_diagram | required:coordinate_plane_q1 |
| `area_triangle` | Area of a triangle | 6 | [area_rectangle_formula] | algorithmic_with_diagram | required:shape |
| `area_parallelogram` | Area of a parallelogram | 6 | [area_rectangle_formula] | algorithmic_with_diagram | required:shape |
| `area_trapezoid` | Area of a trapezoid | 6 | [area_parallelogram] | algorithmic_with_diagram | required:shape |
| `area_polygon_decompose` | Area by decomposing | 6 | [area_triangle, area_parallelogram] | algorithmic_with_diagram | required:shape |
| `polygon_on_coordinate_plane` | Polygon on coord plane | 6 | [plot_first_quadrant, plot_four_quadrants] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `construct_triangle_given` | Construct a triangle | 7 | [measure_angle_protractor] | deferred | required:angle_diagram |
| `triangle_inequality_recognize` | Possible triangle? | 7 | [shape_attributes_basic] | algorithmic | none |
| `cross_section_3d` | Cross-sections of 3D solids | 7 | [identify_shape_3d] | algorithmic_with_diagram | required:shape |
| `circle_circumference` | Circumference of a circle | 7 | [mult_decimals] | algorithmic_with_diagram | required:circle |
| `area_circle` | Area of a circle | 7 | [circle_circumference] | algorithmic_with_diagram | required:circle |
| `supplementary_angles` | Supplementary angles | 7 | [right_acute_obtuse_angle] | algorithmic_with_diagram | required:angle_diagram |
| `complementary_angles` | Complementary angles | 7 | [right_acute_obtuse_angle] | algorithmic_with_diagram | required:angle_diagram |
| `vertical_angles` | Vertical angles | 7 | [supplementary_angles] | algorithmic_with_diagram | required:angle_diagram |
| `adjacent_angles` | Adjacent angles | 7 | [supplementary_angles] | algorithmic_with_diagram | required:angle_diagram |
| `transformations_translation` | Translations | 8 | [polygon_on_coordinate_plane] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `transformations_reflection` | Reflections | 8 | [transformations_translation] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `transformations_rotation` | Rotations | 8 | [transformations_translation] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `transformations_dilation` | Dilations | 8 | [transformations_translation] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `congruence_via_transformations` | Congruent figures | 8 | [transformations_translation, transformations_reflection, transformations_rotation] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `similarity_via_transformations` | Similar figures | 8 | [transformations_dilation, congruence_via_transformations] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `triangle_angle_sum` | Triangle angles sum to 180° | 8 | [supplementary_angles] | algorithmic_with_diagram | required:angle_diagram |
| `exterior_angle_triangle` | Exterior angle theorem | 8 | [triangle_angle_sum] | algorithmic_with_diagram | required:angle_diagram |
| `parallel_lines_transversal` | Parallel lines and a transversal | 8 | [supplementary_angles, vertical_angles] | algorithmic_with_diagram | required:angle_diagram |
| `pythagorean_apply_2d` | Pythagorean theorem (2D) | 8 | [sqrt_perfect_squares, area_rectangle_formula] | algorithmic_with_diagram | required:shape |
| `pythagorean_apply_3d` | Pythagorean theorem (3D) | 8 | [pythagorean_apply_2d] | algorithmic_with_diagram | required:shape |
| `pythagorean_distance_coords` | Distance between two points | 8 | [pythagorean_apply_2d, polygon_on_coordinate_plane] | algorithmic_with_diagram | required:coordinate_plane_q4 |

### 3.10 Integers & Rational Numbers (`rationals`)

| ID | Display | Grade | Prereqs | Source | Diagram |
|---|---|---|---|---|---|
| `signed_quantities_context` | Negative numbers in context | 6 | [add_within_1000] | algorithmic | none |
| `integers_on_number_line` | Integers on number line | 6 | [number_line_add_sub] | algorithmic_with_diagram | required:number_line |
| `opposites_and_zero` | Opposites; opposite of opposite | 6 | [integers_on_number_line] | algorithmic_with_diagram | required:number_line |
| `absolute_value` | Absolute value | 6 | [integers_on_number_line] | algorithmic | none |
| `compare_order_rationals` | Order rational numbers | 6 | [integers_on_number_line, compare_decimals_thousandths] | algorithmic | none |
| `plot_four_quadrants` | Plot in all 4 quadrants | 6 | [plot_first_quadrant, integers_on_number_line] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `coord_distance_same_line` | Distance: same x or same y | 6 | [plot_four_quadrants, absolute_value] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `integers_add` | Add integers | 7 | [opposites_and_zero] | algorithmic_with_diagram | required:number_line |
| `integers_subtract` | Subtract integers | 7 | [integers_add] | algorithmic_with_diagram | required:number_line |
| `integers_multiply_divide` | × and ÷ integers (sign rules) | 7 | [integers_subtract, mult_facts_within_100] | algorithmic | none |
| `rationals_add_sub` | Add/subtract rational numbers | 7 | [integers_add, add_fractions_unlike_denom, add_decimals] | algorithmic | none |
| `rationals_multiply_divide` | × and ÷ rational numbers | 7 | [integers_multiply_divide, mult_fractions_proper, mult_decimals] | algorithmic | none |
| `rationals_four_op_word` | Word problems with rationals | 7 | [rationals_add_sub, rationals_multiply_divide] | dataset | optional |
| `rational_to_decimal_terminating` | Rational → terminating decimal | 7 | [fraction_to_decimal] | algorithmic | none |
| `rational_to_decimal_repeating` | Rational → repeating decimal | 8 | [fraction_to_decimal, repeating_decimal_recognize] | algorithmic | none |
| `irrational_recognize` | Rational vs. irrational | 8 | [rational_to_decimal_repeating] | algorithmic | none |
| `approximate_irrational` | Approximate √2, π | 8 | [irrational_recognize, sqrt_perfect_squares] | algorithmic_with_diagram | required:number_line |

### 3.11 Pre-Algebra (`prealgebra`)

| ID | Display | Grade | Prereqs | Source | Diagram |
|---|---|---|---|---|---|
| `missing_addend_within_20` | Find missing addend | 1 | [add_within_20] | algorithmic | none |
| `missing_factor` | Find missing factor | 3 | [mult_facts_within_100] | algorithmic | none |
| `numerical_pattern_rule` | Pattern rule | 4 | [skip_count_2] | algorithmic | none |
| `two_pattern_relationships` | Compare two patterns | 5 | [numerical_pattern_rule, plot_first_quadrant] | algorithmic_with_diagram | required:coordinate_plane_q1 |
| `write_expression_from_words` | Write expression from words | 6 | [add_within_1000] | algorithmic | none |
| `evaluate_expression` | Evaluate expression at a value | 6 | [order_of_operations_with_exp] | algorithmic | none |
| `identify_parts_expression` | Term, factor, coefficient | 6 | [write_expression_from_words] | algorithmic | none |
| `equivalent_expressions_props` | Equivalent expressions | 6 | [distributive_mult_over_add, write_expression_from_words] | algorithmic | none |
| `substitute_to_check` | Substitute to check | 6 | [evaluate_expression] | algorithmic | none |
| `solve_one_step_eq_addition` | Solve x + p = q | 6 | [missing_addend_within_20, write_expression_from_words] | algorithmic | none |
| `solve_one_step_eq_mult` | Solve px = q | 6 | [missing_factor, write_expression_from_words] | algorithmic | none |
| `inequality_one_var_intro` | Inequalities x > c, x < c | 6 | [compare_order_rationals] | algorithmic_with_diagram | required:number_line |
| `dependent_independent_vars` | Independent vs. dependent variable | 6 | [solve_one_step_eq_mult, plot_first_quadrant] | algorithmic_with_diagram | required:coordinate_plane_q1 |
| `add_subtract_linear_expressions` | Combine like terms (linear) | 7 | [equivalent_expressions_props, integers_subtract] | algorithmic | none |
| `factor_linear_expression` | Factor a linear expression | 7 | [add_subtract_linear_expressions, distributive_with_gcf] | algorithmic | none |
| `expand_linear_expression` | Expand: a(b+c) | 7 | [distributive_mult_over_add] | algorithmic | none |
| `solve_two_step_eq` | Solve px + q = r | 7 | [solve_one_step_eq_mult, solve_one_step_eq_addition, integers_subtract] | algorithmic | none |
| `solve_two_step_eq_distributive` | Solve p(x+q) = r | 7 | [solve_two_step_eq, expand_linear_expression] | algorithmic | none |
| `solve_two_step_inequality` | Solve px + q > r | 7 | [solve_two_step_eq, inequality_one_var_intro] | algorithmic_with_diagram | required:number_line |
| `word_problem_two_step_eq` | Two-step equation word problem | 7 | [solve_two_step_eq] | dataset | optional |
| `solve_linear_eq_one_solution` | Linear eq: one solution | 8 | [solve_two_step_eq] | algorithmic | none |
| `solve_linear_eq_no_or_inf` | No solution or infinite | 8 | [solve_linear_eq_one_solution] | algorithmic | none |
| `solve_linear_eq_with_distrib_collect` | Distrib + combine + solve | 8 | [solve_two_step_eq_distributive, add_subtract_linear_expressions] | algorithmic | none |
| `graph_proportional_slope` | Graph proportional, find slope | 8 | [proportional_relationship, plot_four_quadrants] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `derive_y_eq_mx_b` | Derive y = mx + b | 8 | [graph_proportional_slope, similarity_via_transformations] | deferred | required:coordinate_plane_q4 |
| `slope_from_two_points` | Slope from two points | 8 | [graph_proportional_slope] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `linear_function_construct` | Construct a linear function | 8 | [slope_from_two_points] | algorithmic | none |
| `graph_linear_equation` | Graph y = mx + b | 8 | [linear_function_construct] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `identify_linear_vs_nonlinear` | Linear or nonlinear? | 8 | [graph_linear_equation] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `function_definition_check` | Is it a function? | 8 | [graph_linear_equation] | algorithmic | none |
| `compare_functions_representations` | Compare functions across reps | 8 | [function_definition_check] | algorithmic | none |
| `qualitative_graph_features` | Read a graph qualitatively | 8 | [graph_linear_equation] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `solve_system_by_graphing` | System: graph and find intersect | 8 | [graph_linear_equation] | algorithmic_with_diagram | required:coordinate_plane_q4 |
| `solve_system_substitution` | System: substitution | 8 | [solve_linear_eq_with_distrib_collect] | algorithmic | none |
| `solve_system_elimination` | System: elimination | 8 | [solve_linear_eq_with_distrib_collect] | algorithmic | none |
| `inspect_system_no_solution` | System with no solution | 8 | [solve_system_substitution] | algorithmic | none |
| `system_word_problem` | Word problem → system | 8 | [solve_system_substitution] | dataset | optional |

### 3.12 Data, Statistics & Probability (`stats`)

| ID | Display | Grade | Prereqs | Source | Diagram |
|---|---|---|---|---|---|
| `classify_count_categories` | Sort and count | 0 | [count_objects_to_10] | algorithmic_with_diagram | required:bar_graph |
| `three_category_data` | Picture/bar (3 categories) | 1 | [classify_count_categories] | algorithmic_with_diagram | required:bar_graph |
| `picture_graph_read` | Read a picture graph | 2 | [count_to_100_by_1] | algorithmic_with_diagram | required:bar_graph |
| `bar_graph_read` | Read a bar graph | 2 | [picture_graph_read] | algorithmic_with_diagram | required:bar_graph |
| `bar_graph_compare` | Bar graph: compare problems | 2 | [bar_graph_read, sub_within_100] | algorithmic_with_diagram | required:bar_graph |
| `line_plot_whole` | Line plot (whole units) | 2 | [measure_with_ruler_inches] | algorithmic_with_diagram | required:line_plot |
| `scaled_bar_graph_read` | Scaled bar graph | 3 | [bar_graph_read, mult_facts_within_100] | algorithmic_with_diagram | required:bar_graph |
| `scaled_picture_graph` | Scaled picture graph | 3 | [scaled_bar_graph_read] | algorithmic_with_diagram | required:bar_graph |
| `line_plot_fractional` | Line plot (½, ¼, ⅛) | 4 | [line_plot_whole, partition_halves_fourths] | algorithmic_with_diagram | required:line_plot |
| `line_plot_fraction_word` | Line plot fraction problems | 4 | [line_plot_fractional, add_fractions_like_denom] | algorithmic_with_diagram | required:line_plot |
| `line_plot_5th_grade_ops` | Line plot with fraction ops | 5 | [line_plot_fractional, add_fractions_unlike_denom] | algorithmic_with_diagram | required:line_plot |
| `statistical_question` | Is it a statistical question? | 6 | [] | dataset | optional |
| `dot_plot` | Dot plot | 6 | [line_plot_whole] | algorithmic_with_diagram | required:line_plot |
| `histogram` | Histogram | 6 | [bar_graph_read] | algorithmic_with_diagram | required:histogram |
| `box_plot` | Box plot | 6 | [median] | algorithmic_with_diagram | required:box_plot |
| `mean` | Mean (average) | 6 | [div_4digit_by_1digit] | algorithmic | none |
| `median` | Median | 6 | [compare_order_rationals] | algorithmic | none |
| `mode` | Mode | 6 | [classify_count_categories] | algorithmic | none |
| `range_data` | Range | 6 | [sub_within_1000] | algorithmic | none |
| `iqr` | Interquartile range | 6 | [median] | algorithmic | none |
| `mad` | Mean absolute deviation | 6 | [mean, absolute_value] | algorithmic | none |
| `describe_distribution` | Describe shape/center/spread | 6 | [histogram, box_plot] | algorithmic_with_diagram | required:histogram |
| `compare_two_distributions` | Compare distributions | 7 | [describe_distribution] | algorithmic_with_diagram | required:box_plot |
| `sampling_representativeness` | Is the sample fair? | 7 | [statistical_question] | dataset | optional |
| `inference_from_sample` | Make inferences from a sample | 7 | [sampling_representativeness] | dataset | optional |
| `probability_zero_to_one` | Probability: 0 to 1 scale | 7 | [decimals_fluent_4ops] | algorithmic | none |
| `probability_simple_event` | P(simple event) | 7 | [probability_zero_to_one, fraction_a_over_b] | algorithmic | none |
| `experimental_probability` | Probability from data | 7 | [probability_simple_event] | algorithmic | none |
| `theoretical_vs_experimental` | Theoretical vs. experimental | 7 | [experimental_probability] | algorithmic | none |
| `sample_space_list` | List sample space | 7 | [probability_simple_event] | algorithmic | none |
| `compound_event_probability` | P(compound event) | 7 | [sample_space_list] | algorithmic_with_diagram | required:tree_diagram |
| `tree_diagram` | Tree diagram | 7 | [sample_space_list] | algorithmic_with_diagram | required:tree_diagram |
| `simulate_compound` | Simulate to estimate P | 7 | [compound_event_probability] | dataset | optional |
| `scatter_plot_construct` | Make a scatter plot | 8 | [plot_four_quadrants] | algorithmic_with_diagram | required:scatter_plot |
| `scatter_plot_describe` | Describe scatter pattern | 8 | [scatter_plot_construct] | algorithmic_with_diagram | required:scatter_plot |
| `informal_line_of_fit` | Fit a line to data | 8 | [scatter_plot_describe, graph_linear_equation] | algorithmic_with_diagram | required:scatter_plot |
| `interpret_slope_intercept_data` | Interpret slope/intercept (data) | 8 | [informal_line_of_fit] | algorithmic_with_diagram | required:scatter_plot |
| `two_way_table_construct` | Two-way table | 8 | [classify_count_categories] | algorithmic_with_diagram | required:two_way_table |
| `two_way_relative_frequency` | Relative frequency in 2-way table | 8 | [two_way_table_construct, percent_intro] | algorithmic_with_diagram | required:two_way_table |

---

## 4. CCSS K–8 standards reference

This section is the compact CCSS dump that the §3 sub-concepts trace back to. Format: **Domain → Cluster → Standard (code) — 1-line summary**.

### Kindergarten

**Counting & Cardinality (K.CC)**
- A. Number names & count sequence
  - K.CC.A.1 — Count to 100 by ones and by tens.
  - K.CC.A.2 — Count forward starting at any given number.
  - K.CC.A.3 — Read/write numerals 0–20; match numeral to count.
- B. Count to tell number of objects
  - K.CC.B.4 — Counting–cardinality connection (one-to-one, last number = total, +1 = next).
  - K.CC.B.5 — Count up to 20 in a line/array/circle (10 if scattered); produce a set of given size.
- C. Compare numbers
  - K.CC.C.6 — Compare two groups (more/less/equal).
  - K.CC.C.7 — Compare two numerals 1–10.

**Operations & Algebraic Thinking (K.OA)**
- A. Understand +/−
  - K.OA.A.1–5 — Represent +/− with objects/drawings; word problems within 10; decompose ≤10; pairs that make 10; fluently +/− within 5.

**Number & Operations in Base Ten (K.NBT)**
- A. Foundations for place value
  - K.NBT.A.1 — Compose/decompose 11–19 as ten + ones.

**Measurement & Data (K.MD)**
- A. Describe/compare measurable attributes (K.MD.A.1–2).
- B. Classify and count (K.MD.B.3).

**Geometry (K.G)**
- A. Identify/describe shapes (K.G.A.1–3).
- B. Analyze/compare/create/compose shapes (K.G.B.4–6).

### Grade 1

- **1.OA** Add/subtract within 20 (word problems, all unknown positions); commutativity/associativity; +/− as inverse; counting on; making ten; equation truth; missing values.
- **1.NBT** Count to 120; place value (tens + ones); compare 2-digit; add within 100 (no carry-required); ±10 mentally; subtract multiples of 10.
- **1.MD** Length transitivity; iterating shorter units; time to hour and half-hour; data with up to 3 categories.
- **1.G** Defining vs. non-defining attributes; compose 2D/3D; partition into halves and fourths.

### Grade 2

- **2.OA** One- and two-step word problems within 100; fluent +/− within 20 from memory; even/odd; rectangular array totals.
- **2.NBT** Place value to 1000; skip-count by 5/10/100; read/write/compare to 1000; +/− within 100 fluent; +/− within 1000; mental ±10/±100; explain why algorithms work.
- **2.MD** Measure with rulers in standard units; estimate; length word problems within 100; number-line model; time to nearest 5 min, a.m./p.m.; money ($, ¢); line plots; picture/bar graphs.
- **2.G** Identify polygons (triangle, quadrilateral, pentagon, hexagon, cube); partition rectangles into rows and columns of squares; partition into halves/thirds/fourths.

### Grade 3

- **3.OA** ×/÷ within 100 (word problems, equal groups, arrays, missing-factor, properties, fact-family); fluent ×/÷; two-step word problems; arithmetic patterns.
- **3.NBT** Round to nearest 10/100; +/− within 1000; 1-digit × multiples of 10.
- **3.NF** Fractions as numbers (denoms 2,3,4,6,8); on a number line; equivalence and comparison (same num or same denom); whole numbers as fractions.
- **3.MD** Time to the minute; elapsed-time word problems; liquid volume and mass; scaled picture/bar graphs; line plots to ½/¼ inch; area as attribute / area = l×w (rectangles); perimeter; same perimeter ≠ same area.
- **3.G** Categorize quadrilaterals; partition shapes into equal areas (unit fractions).

### Grade 4

- **4.OA** Multiplicative comparisons; multistep word problems with remainders; factors/multiples; prime/composite; pattern rules.
- **4.NBT** Place-value generalization (10×); read/write/compare/round multi-digit; standard +/− algorithm; multiply up to 4-digit × 1-digit and 2-digit × 2-digit; divide up to 4-digit ÷ 1-digit (with remainder).
- **4.NF** Equivalent fractions (a/b = na/nb); compare fractions; +/− with like denominators; mixed numbers; fraction × whole; tenths and hundredths; decimal notation; compare decimals to hundredths.
- **4.MD** Convert larger→smaller within a system; word problems with measurements; area/perimeter formulas; line plot at ½/¼/⅛; angles as turns; protractor measure/sketch; angle additivity.
- **4.G** Lines/segments/rays; parallel/perpendicular; classify 2D by lines and angles; right triangles; lines of symmetry.

### Grade 5

- **5.OA** Numerical expressions with parentheses/brackets/braces; write expressions from descriptions; ordered-pair patterns; graph in Q1.
- **5.NBT** 10×/⅒ place-value relationship; powers of 10 patterns; read/write/compare/round decimals to thousandths; standard algorithm × multi-digit; ÷ 4-digit ÷ 2-digit; +/−/×/÷ decimals to hundredths.
- **5.NF** +/− unlike denominators (incl. mixed); fraction-as-division; fraction × fraction (area model); scaling interpretation; word problems; ÷ unit fraction by whole and whole by unit fraction.
- **5.MD** Convert within a system in multistep problems; line plots in ½/¼/⅛ with fraction ops; volume = l×w×h; volume of composite figures by adding.
- **5.G** Coordinate plane (Q1); 2D figure hierarchy (square ⊂ rectangle ⊂ parallelogram, etc.).

### Grade 6

- **6.RP** Ratio language; unit rate; ratio reasoning (tables, tape diagrams, double number lines, equations); percent as rate per 100; unit conversions via ratio.
- **6.NS** Fraction ÷ fraction; multi-digit ÷ standard algorithm; +/−/×/÷ multi-digit decimals; GCF (≤100), LCM (≤12); distributive with GCF; signed numbers (intro); rationals on number line and in all four quadrants; absolute value.
- **6.EE** Whole-number exponents; algebraic expressions (term/factor/coefficient); equivalent expressions via properties; substitute to check; one-step equations (x+p=q, px=q); inequalities x>c, x<c on a number line; dependent/independent variables.
- **6.G** Area of triangles/special quads/polygons by decomposition; volume of right rectangular prisms with fractional edges; polygons on the coordinate plane; surface area from nets.
- **6.SP** Statistical question; distribution shape/center/spread; dot plot, histogram, box plot; mean/median/mode/range/IQR/MAD.

### Grade 7

- **7.RP** Unit rate with fractions; proportional relationships (tables, equations y=kx, graphs through origin); multi-step ratio and percent (markup, tax, tip, simple interest, % change).
- **7.NS** Add/subtract rationals; signed-number rules for ×/÷; convert rationals to decimals; word problems with rationals.
- **7.EE** Add/subtract/factor/expand linear expressions with rational coefficients; rewrite expressions to reveal structure; multi-step real-world problems with rationals; word problems → px+q=r and p(x+q)=r; one-step inequalities.
- **7.G** Scale drawings; construct triangles from given measures; cross-sections of right prisms/pyramids; circle circumference and area; angle relationships (supplementary, complementary, vertical, adjacent); area/volume/surface area.
- **7.SP** Sampling/representativeness; informal inference from a sample; compare two populations using center/variability; probability 0–1; experimental and theoretical probability; sample space; compound events (lists, tables, tree diagrams, simulation).

### Grade 8

- **8.NS** Rational vs. irrational; repeating-decimal ↔ fraction; approximate irrationals on the number line.
- **8.EE** Integer-exponent properties; square/cube roots; powers of 10 to estimate magnitudes; scientific notation; graph proportional relationships and identify slope; similar triangles and constant slope; derive y=mx and y=mx+b; solve linear equations (one/no/infinite solutions); systems of two linear equations (graph, substitute, eliminate).
- **8.F** Function = each input → exactly one output; compare functions across representations (eq, graph, table, verbal); identify linear; construct from rate/initial value; qualitatively describe graphs.
- **8.G** Properties of rotations/reflections/translations/dilations on coordinates; congruence and similarity via transformations; angle facts (triangle sum, exterior, transversal, AA); Pythagorean theorem (proof, 2D/3D applications, distance in coord plane); volume of cones/cylinders/spheres.
- **8.SP** Scatter plots; informal line of fit; interpret slope/intercept in context; two-way tables and relative frequency.

---

## 5. Algorithmic generators — priority list

Per design principle (4), generators produce parameterized questions in Dart. Every generator outputs a `GeneratedQuestion`:

```dart
class GeneratedQuestion {
  final String prompt;                  // text with optional placeholders
  final List<DiagramSpec> diagrams;     // tagged-union widget specs
  final Answer correctAnswer;           // numeric | fraction | choice | coord
  final List<Answer> distractors;       // for challenging band
  final List<ExplanationStep> explanation;
  final String conceptId;
  final DifficultyBand band;
}
```

`DiagramSpec` is a sealed family of value types — one per widget in §6. The `domain/` layer constructs them as plain Dart; the presentation layer dispatches to the corresponding widget. This preserves the "no Flutter imports under `lib/domain/`" rule from CLAUDE.md.

### 5.1 Highest-ROI generators (priority-ordered)

Build in this order. Earlier ones cover more sub-concepts × wider age range × lower dev cost.

| # | Generator family | Sub-concepts unlocked | Diagram widget needed |
|---|---|---|---|
| 1 | **Multi-digit ± with regrouping** (`add_n_digit`, `sub_n_digit`) | `add_within_100`, `sub_within_100`, `add_2digit_carry`, `sub_2digit_borrow`, `add_within_1000`, `sub_within_1000`, `add_multidigit_standard_alg`, `sub_multidigit_standard_alg` | none |
| 2 | **Multi-digit × and ÷** (`mul_multi_digit`, `div_with_remainder`) | `mult_4digit_by_1digit`, `mult_2digit_by_2digit`, `mult_multidigit_standard_alg`, `div_4digit_by_1digit`, `div_4digit_by_2digit` | none |
| 3 | **Fraction generators** (`fraction_compare`, `fraction_equiv`, `fraction_add_like`, `fraction_add_unlike`, `fraction_mul`, `fraction_div`) + `FractionBar` widget | `fraction_a_over_b`, `equivalent_fractions_*`, `compare_fractions_*`, `add_fractions_like_denom`, `add_fractions_unlike_denom`, `mult_fractions_proper`, `div_fraction_by_fraction`, etc. | `FractionBar`, `PieChart` |
| 4 | **Time-telling** + `Clock` widget | `time_to_hour_half`, `time_to_5_min`, `time_to_minute`, `elapsed_time` | `Clock` |
| 5 | **Word-problem framework** with name/item/verb pools | `add_word_problems_within_100`, `add_sub_2step_word_problems`, `mult_compare_word`, `interpret_remainder_word`, `mult_div_word_2step`, `length_word_problems`, `money_word_problems`, `fraction_word_problems`, `multistep_ratio_word`, `rationals_four_op_word`, `word_problem_two_step_eq`, `system_word_problem` | none |
| 6 | **Signed-number arithmetic** | `integers_add`, `integers_subtract`, `integers_multiply_divide`, `rationals_add_sub`, `rationals_multiply_divide` | `NumberLine` (optional) |
| 7 | **Coordinate-plane** + `CoordinatePlane` widget | `plot_first_quadrant`, `read_first_quadrant`, `plot_four_quadrants`, `coord_distance_same_line`, `polygon_on_coordinate_plane`, all `transformations_*`, `graph_proportional_slope`, `slope_from_two_points`, `graph_linear_equation`, `solve_system_by_graphing`, `pythagorean_distance_coords`, `scatter_plot_*`, `informal_line_of_fit` | `CoordinatePlane` |
| 8 | **Order-of-operations / expression evaluation** | `order_of_operations_no_exp`, `order_of_operations_with_exp`, `nested_grouping`, `evaluate_expression`, `equivalent_expressions_props`, `add_subtract_linear_expressions`, `expand_linear_expression`, `factor_linear_expression` | none |
| 9 | **Percent / unit-rate / proportion** | `percent_intro`, `percent_of_quantity`, `find_whole_from_part_percent`, `percent_change`, `simple_interest`, `commission`, `unit_rate`, `equivalent_ratios`, `ratio_table`, `proportional_relationship`, `constant_of_proportionality`, `proportional_equation` | `tape_diagram`, `double_number_line` |
| 10 | **Area/perimeter** + `RectangleArea` widget | `area_rectangle_count_squares`, `area_rectangle_formula`, `perimeter_polygon`, `perimeter_unknown_side`, `area_triangle`, `area_parallelogram`, `area_trapezoid`, `area_polygon_decompose` | `RectangleArea`, `Shape` |
| 11 | **One-/two-step equations** | `solve_one_step_eq_addition`, `solve_one_step_eq_mult`, `solve_two_step_eq`, `solve_two_step_eq_distributive`, `solve_two_step_inequality`, `solve_linear_eq_*`, `solve_system_*` | none |
| 12 | **Angles** + `Angle` / `IntersectingLines` widgets | `right_acute_obtuse_angle`, `measure_angle_protractor`, `draw_angle_protractor`, `angle_addition`, `supplementary_angles`, `complementary_angles`, `vertical_angles`, `adjacent_angles`, `triangle_angle_sum`, `exterior_angle_triangle`, `parallel_lines_transversal` | `Angle`, `IntersectingLines` |
| 13 | **Pythagorean theorem** | `pythagorean_apply_2d`, `pythagorean_apply_3d`, `pythagorean_distance_coords` | `Shape` (optional) |
| 14 | **Probability** + `Spinner` / `Dice` widgets | `probability_zero_to_one`, `probability_simple_event`, `experimental_probability`, `theoretical_vs_experimental`, `sample_space_list`, `compound_event_probability` | `Spinner`, `Dice`, `tree_diagram` |
| 15 | **Round / place-value / scientific notation** | `round_to_10`, `round_to_100`, `round_multidigit_any_place`, `round_decimals`, `place_value_*`, `scientific_notation_*` | none |
| 16 | **Data-display + summary stats** | `bar_graph_*`, `picture_graph_read`, `dot_plot`, `histogram`, `box_plot`, `mean`, `median`, `mode`, `range_data`, `iqr`, `mad` | `BarChart`, `Histogram`, `DotPlot`, `BoxPlot` |

### 5.2 Generator spec template

Each generator's full specification lives in code and tests. The metadata schema:

- **Parameter ranges** with constraints (e.g. `a, b ∈ [10, 99]; tens(a) + tens(b) < 10` to force no-carry)
- **Answer computation** — pure function from params
- **Distractor strategies** — generic (off-by-one, swapped operands, sign error) plus topic-specific (e.g. for fraction addition: "added denominators too" → `(a+b)/(2d)`)
- **Step-by-step explanation template** — produced from the same params, used on wrong answers
- **Diagram requirement** — `DiagramSpec` constructor signature

Detailed specs for each of #1–16 are documented in code and tested against worked examples; the algorithmic-generation feasibility study (in conversation history) contains the per-generator notes.

### 5.3 Distractor strategies (universal)

Every multiple-choice question (challenging band) uses 3 distractors from this menu plus topic-specific ones:

- ±1 off-by-one
- Swapped operands (subtraction, division, exponentiation, ratios)
- Wrong operation (+ for −, × for ÷, etc.)
- Sign error (signed-number content)
- Magnitude error (×10 or ÷10)
- Unsimplified-but-correct (fractions, ratios)
- Common misconception per topic (e.g. fraction +: added denominators; signed +: lost sign of larger; PEMDAS: left-to-right)

The "common misconception" distractor is the most pedagogically valuable — it surfaces the kid's likely actual mistake.

### 5.4 Step-by-step explanation philosophy

Every wrong-answer screen shows a procedural walkthrough. Templates are deterministic from question params, so they don't require LLMs:

- Use kid-friendly verbs ("First add the ones, then add the tens.")
- Show intermediate values, not just the final answer
- Match the conceptual frame (e.g. fraction addition: show common-denominator step)
- ≤ 4 steps; if it needs more, the question is too hard for its band

---

## 6. Diagram widget catalog

A small set of high-leverage widgets unlocks the bulk of non-arithmetic content. Each widget is a parameterized Flutter widget under `presentation/diagrams/`. Generator code emits `DiagramSpec` value types under `domain/diagrams/` (pure Dart, no Flutter imports), which the presentation layer dispatches.

### 6.1 The 8-widget unlock set (build first)

These eight widgets unlock ~70% of all non-arithmetic K–8 content.

| Widget | Complexity | Sub-concepts unlocked |
|---|---|---|
| `FractionBar(numer, denom)` / `PieChart(numer, denom)` | easy | All `fraction_*` introductory + visual operations + percent intro |
| `NumberLine(min, max, divisions, marked, hops?)` | easy | `number_line_add_sub`, `fraction_on_number_line`, `decimal_on_number_line`, `integers_on_number_line`, `inequality_one_var_intro`, signed-number ops |
| `Clock(hour, minute, showDigital?)` | easy | `time_to_hour_half`, `time_to_5_min`, `time_to_minute`, `elapsed_time` |
| `BarChart(labels, values, scale)` / `Histogram` / `DotPlot` / `LinePlot` | easy–medium | `picture_graph_read`, `bar_graph_*`, `scaled_*`, `line_plot_*`, `dot_plot`, `histogram`, `describe_distribution` |
| `RectangleArea(width, height, showGrid)` | easy | `area_rectangle_*`, `partition_into_rows_columns`, distributive-property visual |
| `CoordinatePlane(points, lines, range, quadrants)` | medium | `plot_*_quadrant`, `polygon_on_coordinate_plane`, all `transformations_*`, `graph_*`, `slope_from_two_points`, `pythagorean_distance_coords`, `scatter_plot_*` |
| `Angle(degrees, label)` / `IntersectingLines(theta)` | easy–medium | All angle-classification, angle-addition, parallel-lines-transversal, triangle-angle-sum |
| `Spinner(sectors)` / `Dice(faces)` | easy | All single-event and compound-event probability |

### 6.2 Second-tier widgets (build as content phases require)

| Widget | Complexity | Sub-concepts unlocked |
|---|---|---|
| `BaseTenBlocks(hundreds, tens, ones)` | easy | `teen_numbers_as_ten_plus`, place-value visualizations |
| `Polygon(sides, regular, vertices?)` | easy | shape ID, perimeter, polygon-on-coordinate-plane |
| `Shape(kind: triangle\|square\|...)` | easy | All shape-naming and basic geometry |
| `TapeDiagram(parts)` | medium | Ratios, percent visualizations |
| `DoubleNumberLine(top, bottom)` | medium | Ratio reasoning |
| `Box3D(l, w, h, showGrid?)` | medium | Volume, prism surface area |
| `Circle(radius, showRadius?, showCircumference?)` | easy | Circumference and area |
| `Protractor(angle)` | medium | Angle measurement / drawing |
| `Ruler(length, units)` | medium | Length measurement, ½/¼ inch |
| `Money(coins, bills)` | medium | Money values, change-making (uses simple labeled circles for coins, not photo-realistic art — license-safe) |
| `BoxPlot(min, q1, median, q3, max)` | medium | `box_plot`, `compare_two_distributions` |
| `ScatterPlot(points, lineOfFit?)` | medium | `scatter_plot_*`, `informal_line_of_fit` |
| `TwoWayTable(rows, cols, counts)` | easy | `two_way_table_*` |
| `TreeDiagram(branches)` | medium | `compound_event_probability`, `tree_diagram` |
| `Net3D(shape)` | hard | `surface_area_from_net`, `volume_unit_cubes` |
| `ColumnArithmetic(operands, op, carries?)` | medium–hard | Wrong-answer explanation diagrams for multi-digit ± × |

### 6.3 Deferred / out-of-scope

- Long-division "house" layout — text-only step-by-step is sufficient for v1.
- Compass-and-straightedge constructions (7.G) — `construct_triangle_given` flagged `deferred` in §3.
- Animated transformations — static before/after coordinate planes are sufficient.

---

## 7. Public dataset inventory

Per design principle (6), datasets fill the gaps where algorithmic generation isn't sufficient — primarily rich word problems and conceptual judgment items.

### 7.1 License traffic light

| Color | Meaning |
|---|---|
| **Green** | Permissive (MIT / Apache 2.0 / CC-BY / CC0). Safe to bundle and redistribute with attribution. |
| **Yellow** | CC-BY-SA / ODC-By / mixed sub-licenses — bundlable but with copyleft or attribution edge cases. |
| **Red** | CC-BY-NC family — commercial-distribution restriction. App-store distribution carries non-zero legal risk. **Excluded from v1.** |
| **Black** | Proprietary or unclear provenance. Excluded. |

### 7.2 Top 5 datasets to ingest

In priority order:

1. **DeepMind `mathematics_dataset`** — Apache 2.0. Code-based generator (8 modules, millions of items procedurally generated). Covers arithmetic, algebra, calculus(!), comparison, measurement, numbers, polynomials, probability. We use *only* the modules within K–8 scope. Best for high-volume drill content. https://github.com/google-deepmind/mathematics_dataset
2. **GSM8K** — MIT (Copyright OpenAI 2021). 8,500 grade-school word problems with step-by-step rationales. Best for grades 3–6 word problems (`add_word_problems_within_100`, `add_sub_2step_word_problems`, `mult_compare_word`, `mult_div_word_2step`, `fraction_word_problems`). https://github.com/openai/grade-school-math
3. **MathDataset-ElementarySchool** — MIT (Ramon Kaspar). Pre-aggregated arithmetic + word problems + geometry for ~grade-4 level, with `category/subcategory/source` provenance. Useful "first 1000 items" seed for K–5. https://github.com/RamonKaspar/MathDataset-ElementarySchool
4. **MathQA** — Apache 2.0 (Allen AI). 37K cleaned multiple-choice algebra problems with executable formula annotations (gold for free distractor generation and answer verification). Grades 6–8 (`ratios`, `prealgebra`, `rationals`). https://math-qa.github.io/
5. **SVAMP** — MIT (with provenance audit needed: some items derive from CC-BY-NC ASDiv). 1K curated grades 2–4 arithmetic word problems. Small but high-quality. https://github.com/arkilpatel/SVAMP

### 7.3 Open educational resources (curriculum, not Q&A datasets)

Of the K–8 OER curricula, **only one is safe to bundle**: **Open Up Resources 6–8 Math (1st & 2nd editions)** is CC-BY 4.0. Everything else common (EngageNY/Eureka, OpenStax K–12, Illustrative Mathematics v.360, CK-12, Khan Academy) is CC-BY-NC or CC-BY-NC-SA = excluded from v1.

If we ingest Open Up Resources, it requires PDF→JSON extraction work + per-page attribution. Defer to a later phase.

### 7.4 Other datasets evaluated — not used in v1

| Dataset | License | Why not v1 |
|---|---|---|
| MATH (Hendrycks) | MIT | Competition-level (AMC/AIME); only Prealgebra L1–2 in scope. Also LaTeX/Asymptote heavy. |
| AQuA-RAT | Apache 2.0 | High error rate; MathQA is the cleaned version we prefer. |
| ASDiv | **CC-BY-NC 4.0** | Excluded (NC). |
| TabMWP | **CC-BY-NC-SA 4.0** | Excluded (NC + SA). |
| MAWPS | Unclear | License unclear; SVAMP/MathDataset-ES already pull cleaned subsets. |
| MetaMathQA | MIT (cascaded) | Synthetic GPT-rephrasings; only useful for diversity, not as a primary source. |
| MathInstruct | Mixed | Some sub-sources are NC (Camel-Math); requires strict source filter. |
| Lila | CC-BY 4.0 (per task) | Useful as a *combined index*; ingest only the GREEN partitions. |
| NuminaMath | Apache 2.0 | Out of K–8 scope (competition-level). |
| Orca-Math 200K | MIT | Synthetic; correctness not 100%; author note "not intended for educational systems". Use cautiously if at all. |

### 7.5 Coverage matrix — domain × source

Legend: **A** = primary fit, **B** = secondary fit, blank = not covered.

| CCSS Domain | K | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|---|
| **CC** Counting | gap | | | | | | | | |
| **OA** Operations & Algebraic Thinking | gap | gap | gap+DM(B) | DM(A), MDES(A), GSM(B) | DM(A), MDES(A), SV(A), GSM(A) | DM(A), GSM(A) | | | |
| **NBT** Number & Ops in Base Ten | gap | gap | gap+DM(B) | DM(A), MDES(A) | DM(A), MDES(A), GSM(B) | DM(A), GSM(B) | | | |
| **NF** Fractions | | | | DM(A), MDES(B) | DM(A), GSM(B) | DM(A), GSM(B) | | | |
| **MD** Measurement & Data | gap | gap | gap | DM(B) | DM(B), GSM(B) | DM(B) | gap | gap | |
| **G** Geometry | gap | gap | gap | MDES(B) | MDES(B) | MDES(B) | MQA-geom(B) | MQA-geom(B) | MQA-geom(B) |
| **RP** Ratios & Proportions | | | | | | | MQA(A) | MQA(A) | |
| **NS** The Number System | | | | | | | DM-num(A), MQA(B) | DM-num(A), MQA(B) | DM-num(A), MQA(B) |
| **EE** Expressions & Equations | | | | | | | DM-alg(A), MQA(A) | DM-alg(A), MQA(A) | DM-alg(A), MQA(A) |
| **SP** Statistics & Probability | | | | | | | DM-prob(B) | DM-prob(B) | DM-prob(B) |
| **F** Functions | | | | | | | | | DM-alg(B), gap |

`DM` = DeepMind, `GSM` = GSM8K, `MDES` = MathDataset-ElementarySchool, `MQA` = MathQA, `SV` = SVAMP. **`gap`** = no GREEN dataset coverage; rely on algorithmic generation + small hand-curated seed.

### 7.6 Coverage gaps (rely on algorithmic generation)

Per §7.5, no GREEN dataset substantively covers:

- **K–2 across all domains** — too verbose / too text-heavy in available datasets.
- **Grade 2 word problems** — SVAMP floor is grade 4; GSM8K floor is grade 3.
- **K–5 Geometry with figures** — no open dataset has K–5 geometry with usable images. **Procedural diagram widgets fill this gap.**
- **Measurement & Data 6–8** — TabMWP (the natural fit) is RED.
- **Statistics & Probability 6–8** — DeepMind-probability covers basic combinatorics but not full SP intent.
- **Functions 8** — minimal open Q&A coverage.

The pattern: **the open ML-dataset ecosystem covers grades 3–8 word/symbolic arithmetic well, and covers K–2, geometry, measurement, statistics, and functions poorly.** Hand-curated gap-fills (~1500 items total) round out the catalog.

---

## 8. Coverage analysis

Estimated share of K–8 CCSS content reachable each way:

| Strategy | Estimated coverage | Notes |
|---|---|---|
| Pure algorithmic generation (no diagram) | **~40%** | All arithmetic core, signed numbers, exponents, equations, percent, basic probability. |
| Algorithmic + procedural diagram | **~35%** | Geometry, time/money, area/volume, coordinate plane, data displays, fractions-as-shapes. |
| Algorithmic + static context pool (word problems) | **~10%** | 1- and 2-step word problems with bundled name/item/verb pools. |
| Static curated dataset | **~10%** | Rich multi-step word problems; statistical-question recognition; some grade 7–8 real-world ratio scenarios; gap-fills for K–2. |
| Deferred to v2+ (LLM batch / proofs / constructions) | **~5%** | Geometric proofs, constructions, "explain your thinking" items, qualitative graph interpretation. |

**Net: ~85% of K–8 CCSS content is reachable in v1 with algorithmic generators + the §6 diagram widgets + the §7.2 datasets.** The remaining ~15% is split between deferred conceptual content and v2+ enhancements.

---

## 9. Open questions for human review

These came up during research; flagging here so they're not lost. Resolve as we implement.

1. **Counting vs. Place Value boundary.** Skip-counting (5/10/100) is taxonomically borderline — appears in K.CC and 2.NBT. Currently under `counting`; could move to `place_value`. Alternative: split into chant-version (counting) vs. fact-version (multiplication).
2. **Fluency sub-concepts.** CCSS distinguishes "fluently add within 100" from "add within 100". I treated fluency as a separate ID where it's load-bearing (`add_sub_fluency_within_20`, `mult_facts_within_100`), folded elsewhere. Consider a `fluent` tier per sub-concept rather than separate IDs.
3. **Geometry hierarchy duplication.** Quadrilateral classification appears at grade 3, 4, and 5 with progressively richer attribute reasoning. Fold into one progressive sub-concept with three difficulty levels?
4. **Word problems as a separate axis.** I created `*_word_problems` IDs sparingly; most word-problem framings of basic skills are NOT broken out. Recommend treating word-problem framing as a question-shape variant within a sub-concept (current approach) rather than doubling the catalog.
5. **Decimal arithmetic vs. multidigit arithmetic.** Treated `add_decimals` etc. as separate from `add_multidigit_standard_alg`. CCSS often considers them the same skill applied with different unit understanding. The DAG reflects the dependency, but kids may feel they're "the same thing."
6. **Constructions and proofs.** `construct_triangle_given` (7.G), 8.G proof items, `derive_y_eq_mx_b` are marked `deferred`. They don't fit a procedural-question model in a mobile game; kept as IDs for later content-author work.
7. **Statistical-question recognition (`statistical_question`).** A judgment item ("which of these anticipates variability?") — probably a small curated multiple-choice set, not algorithmic.
8. **Mathematical Practices (MP1–MP8).** CCSS includes 8 cross-cutting practice standards (perseverance, reasoning, structure, etc.). Excluded from this taxonomy as meta-skills, not testable sub-concepts.
9. **Money in Measurement vs. its own category.** Money sub-concepts live in `measurement` (matches CCSS 2.MD.C.8). Reasonable alternative: a separate `money` category, or fold into `add_sub`.
10. **Functions vs. Pre-Algebra.** Merged 8.F into `prealgebra`. Could split into a 13th `functions` category for visual distinction — kids hear "function" and it feels different from "equation."
11. **Probability heaviness.** ~7 sub-concepts in probability alone. Some are interrelated (`theoretical_vs_experimental` and `experimental_probability`). Collapse if catalog feels sprawling in playtesting.
12. **Empty categories at low grades.** Categories like `rationals` (grade 6+) and `prealgebra` (grade 6+) will be empty for younger players — by design (no cross-domain gating), but worth confirming this doesn't feel weird on the progress screen.

---

## 10. References

**Primary curriculum source**
- [Common Core State Standards Initiative – Mathematics](https://www.thecorestandards.org/Math/)
- [CCSS Mathematics PDF](https://corestandards.org/wp-content/uploads/Math_Standards1.pdf)

**Top datasets (GREEN-licensed, in priority order)**
- [DeepMind mathematics_dataset](https://github.com/google-deepmind/mathematics_dataset) (Apache 2.0)
- [GSM8K](https://github.com/openai/grade-school-math) (MIT)
- [MathDataset-ElementarySchool](https://github.com/RamonKaspar/MathDataset-ElementarySchool) (MIT)
- [MathQA](https://math-qa.github.io/) (Apache 2.0)
- [SVAMP](https://github.com/arkilpatel/SVAMP) (MIT)
- [Open Up Resources 6–8 Math (1st/2nd ed)](https://openupresources.org/) (CC-BY 4.0)

**Additional considered (not v1)**
- [MATH (Hendrycks)](https://github.com/hendrycks/math) (MIT) — competition-level
- [Lila](https://huggingface.co/datasets/allenai/lila) (CC-BY per-task; per-task source license still applies)
- [NuminaMath](https://huggingface.co/datasets/AI-MO/NuminaMath-CoT) (Apache 2.0) — out of K–8 scope
- [MetaMathQA](https://huggingface.co/datasets/meta-math/MetaMathQA) (MIT cascaded)
