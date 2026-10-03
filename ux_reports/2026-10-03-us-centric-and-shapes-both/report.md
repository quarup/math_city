# UX sweep — 2026-10-03-us-centric-and-shapes-both

- Input mode: **both**
- Concepts probed: **12** (12 reviewed)
- ✅ 10 clean · 🎨 2 could improve · 🐞 0 bug

Each question screenshot is the exact screen the player sees. The wrong-answer screenshot is that same question, replayed from its seed and answered with a distractor.

**One wrong-answer screenshot covers both input modes.** The band never reaches the result screen — it renders from the question, the submitted answer and the outcome, and in debug mode bricks are always 0 and the unlock event null. Same seed → same question → same distractor → same red screen. _keypad → MC_ in the keypad column means the question forced multiple choice (`multipleChoiceOnly`, or a text-shaped answer format), so that screen is the MC one.

The green "Correct!" screen is verified programmatically and not captured — it is identical for every concept.

<!-- OBSERVATIONS: hand-written, preserved across rebuilds -->
## Observations

_Nothing yet. Type notes between the two `OBSERVATIONS` HTML comments and
they survive every rebuild — everything outside them is regenerated._
<!-- END OBSERVATIONS -->

## Findings

| | Concept | Finding |
|---|---|---|
| 🎨 | [Integers on number line](#integers_on_number_line) `integers_on_number_line` | Works as intended (only 0 and 25 labelled, point at −75, counted not read). The number-line tick labels are small (~11 px) for a whole-screen diagram; a larger label font would help — pre-existing to the NumberLine widget. |
| 🎨 | [Sales tax and tip](#sales_tax_tip) `sales_tax_tip` | Question now says "service charge"; the concept name in the title bar still reads "Sales tax and tip". Fixed in the same session: renamed "Tax and service charge". |

## 3.6 Decimals & Percentages (`decimals_percent`)

| | Concept | Question (MC) | Question (keypad) | Wrong answer | Notes |
|---|---|---|---|---|---|
| ✅ | **Round decimals**<br>`round_decimals`<br>G5 · dataset | <a id="round_decimals"></a><img src="shots/round_decimals__mc.png" width="180"> | <img src="shots/round_decimals__keypad.png" width="180"> | <img src="shots/round_decimals__wrong.png" width="180"> | Generator sample; the 200 dataset items now read "to the nearest tenth/hundredth/thousandth" too (checked in the JSON, not on screen). |
| 🎨 | **Sales tax and tip**<br>`sales_tax_tip`<br>G7 | <a id="sales_tax_tip"></a><img src="shots/sales_tax_tip__mc.png" width="180"> | <img src="shots/sales_tax_tip__keypad.png" width="180"> | <img src="shots/sales_tax_tip__wrong.png" width="180"> | Question now says "service charge"; the concept name in the title bar still reads "Sales tax and tip". Fixed in the same session: renamed "Tax and service charge". |

## 3.7 Ratios & Proportions (`ratios`)

| | Concept | Question (MC) | Question (keypad) | Wrong answer | Notes |
|---|---|---|---|---|---|
| ✅ | **Ratio tables**<br>`ratio_table`<br>G6 · TapeDiagramSpec | <a id="ratio_table"></a><img src="shots/ratio_table__mc.png" width="180"> | <img src="shots/ratio_table__keypad.png" width="180"> | <img src="shots/ratio_table__wrong.png" width="180"> |  |
| ✅ | **Scale drawings**<br>`scale_drawing`<br>G7 | <a id="scale_drawing"></a><img src="shots/scale_drawing__mc.png" width="180"> | <img src="shots/scale_drawing__keypad.png" width="180"> | <img src="shots/scale_drawing__wrong.png" width="180"> |  |

## 3.8 Measurement, Time & Money (`measurement`)

| | Concept | Question (MC) | Question (keypad) | Wrong answer | Notes |
|---|---|---|---|---|---|
| ✅ | **Estimate length**<br>`estimate_length`<br>G2 | <a id="estimate_length"></a><img src="shots/estimate_length__mc.png" width="180"> | _keypad → MC_ | <img src="shots/estimate_length__wrong.png" width="180"> |  |
| ✅ | **Measure to ½ cm**<br>`measure_to_half_cm`<br>G3 · RulerSpec | <a id="measure_to_half_cm"></a><img src="shots/measure_to_half_cm__mc.png" width="180"> | <img src="shots/measure_to_half_cm__keypad.png" width="180"> | <img src="shots/measure_to_half_cm__wrong.png" width="180"> |  |
| ✅ | **Convert units (one system)**<br>`convert_units_within_system`<br>G4 | <a id="convert_units_within_system"></a><img src="shots/convert_units_within_system__mc.png" width="180"> | <img src="shots/convert_units_within_system__keypad.png" width="180"> | <img src="shots/convert_units_within_system__wrong.png" width="180"> |  |

## 3.9 Geometry & Shapes (`geometry`)

| | Concept | Question (MC) | Question (keypad) | Wrong answer | Notes |
|---|---|---|---|---|---|
| ✅ | **Build shapes from shapes**<br>`compose_shapes`<br>G1 · ShapeSpec | <a id="compose_shapes"></a><img src="shots/compose_shapes__mc.png" width="180"> | _keypad → MC_ | <img src="shots/compose_shapes__wrong.png" width="180"> |  |

## 3.10 Integers & Rational Numbers (`rationals`)

| | Concept | Question (MC) | Question (keypad) | Wrong answer | Notes |
|---|---|---|---|---|---|
| 🎨 | **Integers on number line**<br>`integers_on_number_line`<br>G6 · NumberLineSpec | <a id="integers_on_number_line"></a><img src="shots/integers_on_number_line__mc.png" width="180"> | <img src="shots/integers_on_number_line__keypad.png" width="180"> | <img src="shots/integers_on_number_line__wrong.png" width="180"> | Works as intended (only 0 and 25 labelled, point at −75, counted not read). The number-line tick labels are small (~11 px) for a whole-screen diagram; a larger label font would help — pre-existing to the NumberLine widget. |

## 3.12 Data, Statistics & Probability (`stats`)

| | Concept | Question (MC) | Question (keypad) | Wrong answer | Notes |
|---|---|---|---|---|---|
| ✅ | **Line plot (½, ¼, ⅛)**<br>`line_plot_fractional`<br>G4 · DotPlotSpec | <a id="line_plot_fractional"></a><img src="shots/line_plot_fractional__mc.png" width="180"> | <img src="shots/line_plot_fractional__keypad.png" width="180"> | <img src="shots/line_plot_fractional__wrong.png" width="180"> |  |
| ✅ | **Histogram**<br>`histogram`<br>G6 · HistogramSpec | <a id="histogram"></a><img src="shots/histogram__mc.png" width="180"> | <img src="shots/histogram__keypad.png" width="180"> | <img src="shots/histogram__wrong.png" width="180"> |  |
| ✅ | **Box plot**<br>`box_plot`<br>G6 · BoxPlotSpec | <a id="box_plot"></a><img src="shots/box_plot__mc.png" width="180"> | <img src="shots/box_plot__keypad.png" width="180"> | <img src="shots/box_plot__wrong.png" width="180"> |  |

