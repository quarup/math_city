# UX sweep — 2026-10-19-answer-blanks-both

- Input mode: **both**
- Concepts probed: **7** (7 reviewed)
- ✅ 7 clean · 🎨 0 could improve · 🐞 0 bug

Each question screenshot is the exact screen the player sees. The wrong-answer screenshot is that same question, replayed from its seed and answered with a distractor.

**One wrong-answer screenshot covers both input modes.** The band never reaches the result screen — it renders from the question, the submitted answer and the outcome, and in debug mode bricks are always 0 and the unlock event null. Same seed → same question → same distractor → same red screen. _keypad → MC_ in the keypad column means the question forced multiple choice (`multipleChoiceOnly`, or a text-shaped answer format), so that screen is the MC one.

The green "Correct!" screen is verified programmatically and not captured — it is identical for every concept.

<!-- OBSERVATIONS: hand-written, preserved across rebuilds -->
## Observations

_Nothing yet. Type notes between the two `OBSERVATIONS` HTML comments and
they survive every rebuild — everything outside them is regenerated._
<!-- END OBSERVATIONS -->

## 3.1 Counting & Number Sense (`counting`)

| | Concept | Question (MC) | Question (keypad) | Wrong answer | Notes |
|---|---|---|---|---|---|
| ✅ | **Skip count by 2s**<br>`skip_count_2`<br>G1 | <a id="skip_count_2"></a><img src="shots/skip_count_2__mc.png" width="180"> | <img src="shots/skip_count_2__keypad.png" width="180"> | <img src="shots/skip_count_2__wrong.png" width="180"> |  |

## 3.4 Multiplication & Division (`mult_div`)

| | Concept | Question (MC) | Question (keypad) | Wrong answer | Notes |
|---|---|---|---|---|---|
| ✅ | **Multiply in any order**<br>`commutative_mult`<br>G3 | <a id="commutative_mult"></a><img src="shots/commutative_mult__mc.png" width="180"> | <img src="shots/commutative_mult__keypad.png" width="180"> | <img src="shots/commutative_mult__wrong.png" width="180"> |  |
| ✅ | **Group factors any way**<br>`associative_mult`<br>G3 | <a id="associative_mult"></a><img src="shots/associative_mult__mc.png" width="180"> | <img src="shots/associative_mult__keypad.png" width="180"> | <img src="shots/associative_mult__wrong.png" width="180"> |  |

## 3.5 Fractions (`fractions`)

| | Concept | Question (MC) | Question (keypad) | Wrong answer | Notes |
|---|---|---|---|---|---|
| ✅ | **What is a/b?**<br>`fraction_a_over_b`<br>G3 · FractionBarSpec | <a id="fraction_a_over_b"></a><img src="shots/fraction_a_over_b__mc.png" width="180"> | <img src="shots/fraction_a_over_b__keypad.png" width="180"> | <img src="shots/fraction_a_over_b__wrong.png" width="180"> |  |
| ✅ | **Find equivalent fraction**<br>`equivalent_fractions_compute`<br>G4 | <a id="equivalent_fractions_compute"></a><img src="shots/equivalent_fractions_compute__mc.png" width="180"> | <img src="shots/equivalent_fractions_compute__keypad.png" width="180"> | <img src="shots/equivalent_fractions_compute__wrong.png" width="180"> |  |

## 3.6 Decimals & Percentages (`decimals_percent`)

| | Concept | Question (MC) | Question (keypad) | Wrong answer | Notes |
|---|---|---|---|---|---|
| ✅ | **Tenths and hundredths**<br>`fraction_denom_10_100`<br>G4 · FractionBarSpec | <a id="fraction_denom_10_100"></a><img src="shots/fraction_denom_10_100__mc.png" width="180"> | <img src="shots/fraction_denom_10_100__keypad.png" width="180"> | <img src="shots/fraction_denom_10_100__wrong.png" width="180"> |  |

## 3.11 Pre-Algebra (`prealgebra`)

| | Concept | Question (MC) | Question (keypad) | Wrong answer | Notes |
|---|---|---|---|---|---|
| ✅ | **Find missing addend**<br>`missing_addend_within_20`<br>G1 | <a id="missing_addend_within_20"></a><img src="shots/missing_addend_within_20__mc.png" width="180"> | <img src="shots/missing_addend_within_20__keypad.png" width="180"> | <img src="shots/missing_addend_within_20__wrong.png" width="180"> |  |

