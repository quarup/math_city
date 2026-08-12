/// Unicode superscript notation for exponents.
///
/// Kids meet exponents as a raised, smaller digit (10⁵, 3²) — never as the
/// programmer caret (10^5), which a child may read as a literal character.
/// All question-facing text (prompts, choices, explanations) renders
/// exponents through [sup] so the whole app uses the textbook notation.
library;

const _superscripts = <String, String>{
  '0': '⁰',
  '1': '¹',
  '2': '²',
  '3': '³',
  '4': '⁴',
  '5': '⁵',
  '6': '⁶',
  '7': '⁷',
  '8': '⁸',
  '9': '⁹',
  '-': '⁻',
  '−': '⁻',
  '+': '⁺',
  'm': 'ᵐ',
  'n': 'ⁿ',
};

/// Renders [exponent] as Unicode superscript characters: `sup(23)` → `²³`,
/// `sup(-4)` → `⁻⁴`, `sup('m+n')` → `ᵐ⁺ⁿ`. Supports digits, signs, and the
/// symbolic letters m/n used by the exponent-rule explanations.
String sup(Object exponent) =>
    '$exponent'.split('').map((c) => _superscripts[c]!).join();
