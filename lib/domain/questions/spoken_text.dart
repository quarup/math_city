/// Screen text, prepared for the voice.
///
/// Prompts, answers and diagram labels are written for the eye: `8, 9, ___`,
/// `3/4 × 3/4 = ?`, `(3, −1)`, `$20.15`. Handed to a speech engine as-is
/// they come out as "underscore underscore", "three slash four" or a date.
/// [spokenFormOf] rewrites them token by token into what a teacher would
/// say, and remembers which run of screen text each spoken run came from,
/// so the word being spoken can be lit up on screen.
library;

/// Whether [text] has anything worth reading on its own: a word of two or
/// more letters. Bare sums (`31 − 14 = ?`) and digit strings don't, and so
/// are never read automatically — but they can still be spoken on request.
bool hasReadableWords(String text) => _word.hasMatch(text);

final RegExp _word = RegExp('[A-Za-z]{2,}');

/// One whitespace-delimited run of screen text and how it is spoken. A
/// token whose [spoken] form is empty (a bullet, a brace) is silent.
class SpokenToken {
  const SpokenToken({
    required this.display,
    required this.displayStart,
    required this.spoken,
    required this.spokenStart,
  });

  final String display;

  /// Offset of [display] in the screen text.
  final int displayStart;
  int get displayEnd => displayStart + display.length;

  final String spoken;

  /// Offset of [spoken] in [SpokenText.text]; meaningless when silent.
  final int spokenStart;
  int get spokenEnd => spokenStart + spoken.length;
}

/// The spoken form of one piece of screen text, with the token map.
class SpokenText {
  const SpokenText(this.display, this.text, this.tokens);

  /// The screen text this was made from.
  final String display;

  /// What the voice says.
  final String text;

  final List<SpokenToken> tokens;

  /// The token being spoken when the engine reports it has reached
  /// [spokenOffset] in [text], or null if the offset lands between tokens.
  SpokenToken? tokenAt(int spokenOffset) {
    for (final t in tokens) {
      if (t.spoken.isEmpty) continue;
      if (spokenOffset >= t.spokenStart && spokenOffset < t.spokenEnd) {
        return t;
      }
    }
    return null;
  }
}

/// What the voice should say for [display]. See the library doc.
String spokenForm(String display) => spokenFormOf(display).text;

SpokenText spokenFormOf(String display) {
  final tokens = <SpokenToken>[];
  final out = StringBuffer();
  String? previous;
  for (final m in RegExp(r'\S+').allMatches(display)) {
    final raw = m.group(0)!;
    final spoken = _spokenToken(raw, previous: previous);
    if (spoken.isNotEmpty && out.isNotEmpty) out.write(' ');
    tokens.add(
      SpokenToken(
        display: raw,
        displayStart: m.start,
        spoken: spoken,
        spokenStart: out.length,
      ),
    );
    out.write(spoken);
    previous = raw;
  }
  return SpokenText(display, out.toString(), tokens);
}

const _symbols = <String, String>{
  '×': 'times',
  '÷': 'divided by',
  '=': 'equals',
  '+': 'plus',
  '−': 'minus',
  '-': 'minus',
  '?': 'what',
  '≈': 'is about',
  '<': 'is less than',
  '>': 'is greater than',
  '≤': 'is less than or equal to',
  '≥': 'is greater than or equal to',
  '→': 'to',
};

const _superscripts = <String, String>{
  '⁰': '0',
  '¹': '1',
  '²': '2',
  '³': '3',
  '⁴': '4',
  '⁵': '5',
  '⁶': '6',
  '⁷': '7',
  '⁸': '8',
  '⁹': '9',
};

const _denominators = <int, (String, String)>{
  2: ('half', 'halves'),
  3: ('third', 'thirds'),
  4: ('quarter', 'quarters'),
  5: ('fifth', 'fifths'),
  6: ('sixth', 'sixths'),
  7: ('seventh', 'sevenths'),
  8: ('eighth', 'eighths'),
  9: ('ninth', 'ninths'),
  10: ('tenth', 'tenths'),
  12: ('twelfth', 'twelfths'),
  100: ('hundredth', 'hundredths'),
};

final _integer = RegExp(r'^\d+$');
final _fraction = RegExp(r'^(\d+)/(\d+)$');
final _ratio = RegExp(r'^(\d+):(\d+)$');
final _time = RegExp(r'^(\d{1,2}):(\d{2})$');
final _remainder = RegExp(r'^(\d+)R(\d+)$');
final _money = RegExp(r'^\$(\d[\d,]*)(?:\.(\d{2}))?$');
final _cents = RegExp(r'^(\d+)¢$');
final _percent = RegExp(r'^([\d.,]+)%$');
final _degrees = RegExp(r'^([\d.,]+)°$');
final _absolute = RegExp(r'^\|(.+)\|$');
final _negative = RegExp(r'^[−-](?=[\d(])');
final _blank = RegExp(r'^_{2,}$');
final _leadingPunct = RegExp(r'^[(\[{"“•]+');
final _trailingPunct = RegExp(r'[)\]}.,;:!"”]+$');

String _spokenToken(String raw, {String? previous}) {
  // "= ?" is "equals what"; "9 apples?" keeps its noun and drops the mark.
  if (raw == '?') return 'what';
  final body = raw.endsWith('?') ? raw.substring(0, raw.length - 1) : raw;
  // A trailing comma or full stop stays: the voice pauses on it.
  final tail = _trailingPunct.firstMatch(body)?.group(0) ?? '';
  final pause = RegExp('[.,;:!]').firstMatch(tail)?.group(0) ?? '';
  final core = body
      .replaceFirst(_leadingPunct, '')
      .replaceFirst(_trailingPunct, '');
  // A token that is only punctuation says nothing: "•", "{", "}".
  if (core.isEmpty) return '';
  final symbol = _symbols[core];
  if (symbol != null) return symbol;
  return '${_spokenCore(core, previous: previous)}$pause';
}

String _spokenCore(String core, {String? previous}) {
  if (_blank.hasMatch(core)) return 'blank';
  if (core == '%') return 'percent';
  if (core == '°') return 'degrees';
  final abs = _absolute.firstMatch(core);
  if (abs != null) {
    return 'the absolute value of ${_spokenCore(abs.group(1)!)}';
  }
  if (_negative.hasMatch(core)) {
    return 'negative ${_spokenCore(core.substring(1))}';
  }
  final money = _money.firstMatch(core);
  if (money != null) {
    final dollars = money.group(1)!;
    final cents = money.group(2);
    final d = dollars == '1' ? '1 dollar' : '$dollars dollars';
    if (cents == null || cents == '00') return d;
    final c = int.parse(cents);
    final cc = c == 1 ? '1 cent' : '$c cents';
    return dollars == '0' ? cc : '$d and $cc';
  }
  final cents = _cents.firstMatch(core);
  if (cents != null) {
    final c = cents.group(1)!;
    return c == '1' ? '1 cent' : '$c cents';
  }
  final percent = _percent.firstMatch(core);
  if (percent != null) return '${percent.group(1)} percent';
  final degrees = _degrees.firstMatch(core);
  if (degrees != null) return '${degrees.group(1)} degrees';
  final fraction = _fraction.firstMatch(core);
  if (fraction != null) {
    final n = int.parse(fraction.group(1)!);
    final d = int.parse(fraction.group(2)!);
    final names = _denominators[d];
    final spoken = names == null
        ? '$n over $d'
        : n == 1
        ? '1 ${names.$1}'
        : '$n ${names.$2}';
    // "2 3/4" is "2 and 3 quarters".
    final mixed = previous != null && _integer.hasMatch(previous);
    return mixed ? 'and $spoken' : spoken;
  }
  if (_time.hasMatch(core)) return core; // engines read clock times well
  final ratio = _ratio.firstMatch(core);
  if (ratio != null) return '${ratio.group(1)} to ${ratio.group(2)}';
  final remainder = _remainder.firstMatch(core);
  if (remainder != null) {
    return '${remainder.group(1)} remainder ${remainder.group(2)}';
  }
  if (core.startsWith('√')) return 'the square root of ${core.substring(1)}';
  if (core.startsWith('∛')) return 'the cube root of ${core.substring(1)}';
  return _spokenPowers(core);
}

/// `5²` is "5 squared", `x³` "x cubed", `8⁶` "8 to the power of 6".
String _spokenPowers(String core) {
  if (!core.split('').any(_superscripts.containsKey)) return core;
  final out = StringBuffer();
  var i = 0;
  while (i < core.length) {
    final c = core[i];
    if (!_superscripts.containsKey(c)) {
      out.write(c);
      i++;
      continue;
    }
    final digits = StringBuffer();
    while (i < core.length && _superscripts.containsKey(core[i])) {
      digits.write(_superscripts[core[i]]);
      i++;
    }
    final power = digits.toString();
    out.write(switch (power) {
      '2' => ' squared',
      '3' => ' cubed',
      _ => ' to the power of $power',
    });
  }
  // "(8⁶)²": the brackets only group for the eye.
  return out.toString().replaceAll(RegExp('[()]'), '');
}
