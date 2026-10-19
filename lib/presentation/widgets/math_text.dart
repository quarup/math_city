import 'package:flutter/material.dart';

/// Drop-in replacement for [Text] that renders radical notation the way
/// textbooks draw it: the radical sign with a vinculum (the horizontal
/// bar) extending over the radicand, and a small index 3 tucked into the
/// hook for cube roots.
///
/// The domain layer emits plain strings (`√16`, `∛27`, `√(l² + w² + h²)`);
/// this widget parses those spans out and paints each radical with a
/// [CustomPainter], because no Unicode composition produces a bar that
/// actually joins the radical's hook (and the precomposed ∛ glyph gives
/// no control over the index at all). An answer blank (`___`) is drawn
/// as an empty box, and a blank numerator (`___/6`) as a stacked fraction
/// with the box on top — see [parseMathSegments]. Everything else —
/// including Unicode superscript exponents, which are ordinary
/// characters — renders as plain text.
class MathText extends StatelessWidget {
  const MathText(
    this.text, {
    this.style,
    this.textAlign,
    this.highlight,
    this.highlightColor,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// A run of [text] to paint on [highlightColor]: the word being read
  /// aloud. A blank or fraction it touches is filled; a radical is not
  /// highlighted.
  final TextRange? highlight;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final segments = parseMathSegments(text);
    if (segments.every((s) => s is PlainSegment)) {
      final range = highlight;
      if (range == null || !range.isValid || range.isCollapsed) {
        return Text(text, style: style, textAlign: textAlign);
      }
      final end = range.end.clamp(0, text.length);
      final start = range.start.clamp(0, end);
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text.substring(0, start)),
            TextSpan(
              text: text.substring(start, end),
              style: TextStyle(backgroundColor: highlightColor),
            ),
            TextSpan(text: text.substring(end)),
          ],
        ),
        style: style,
        textAlign: textAlign,
      );
    }
    // The painters need the resolved text style (font size, color) that
    // plain spans inherit implicitly from DefaultTextStyle.
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final range = highlight;
    final lit = range != null && range.isValid && !range.isCollapsed
        ? range
        : null;
    bool isLit(MathSegment s) =>
        lit != null && s.start < lit.end && lit.start < s.end;
    return Text.rich(
      TextSpan(
        children: [
          for (final segment in segments)
            switch (segment) {
              PlainSegment() => _plainSpan(segment, lit),
              RadicalSegment() => WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: _Radical(segment: segment, style: effective),
              ),
              BlankSegment() => WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _AnswerBox(
                  style: effective,
                  fill: isLit(segment) ? highlightColor : null,
                ),
              ),
              FractionSegment() => WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _StackedFraction(
                  segment: segment,
                  style: effective,
                  fill: isLit(segment) ? highlightColor : null,
                ),
              ),
            },
        ],
      ),
      style: style,
      textAlign: textAlign,
    );
  }

  /// [segment] as text, with the part of it inside [lit] highlighted.
  TextSpan _plainSpan(PlainSegment segment, TextRange? lit) {
    if (lit == null || lit.end <= segment.start || segment.end <= lit.start) {
      return TextSpan(text: segment.text);
    }
    final from = (lit.start - segment.start).clamp(0, segment.text.length);
    final to = (lit.end - segment.start).clamp(from, segment.text.length);
    return TextSpan(
      children: [
        TextSpan(text: segment.text.substring(0, from)),
        TextSpan(
          text: segment.text.substring(from, to),
          style: TextStyle(backgroundColor: highlightColor),
        ),
        TextSpan(text: segment.text.substring(to)),
      ],
    );
  }
}

/// A parsed run of question text: plain characters, one radical, one
/// answer blank or one stacked fraction. [start] and [end] are its offsets
/// in the source text, so the word being read aloud can be found in it.
sealed class MathSegment {
  const MathSegment(this.start, this.end);

  final int start;
  final int end;
}

final class PlainSegment extends MathSegment {
  PlainSegment(this.text, {int start = 0}) : super(start, start + text.length);

  final String text;
}

/// `___`, drawn as an empty box for the answer to go in.
final class BlankSegment extends MathSegment {
  const BlankSegment(super.start, super.end);
}

/// A fraction drawn stacked, numerator over denominator. A null
/// [numerator] is a blank (`___/6`), drawn as a box.
final class FractionSegment extends MathSegment {
  const FractionSegment(
    this.numerator,
    this.denominator,
    super.start,
    super.end,
  );

  final String? numerator;
  final String denominator;
}

final class RadicalSegment extends MathSegment {
  const RadicalSegment(
    this.radicand, {
    this.index,
    int start = 0,
    int end = 0,
  }) : super(start, end);

  /// Text under the vinculum. For a parenthesized radicand the outer
  /// parens are dropped — the bar itself shows where the radicand ends.
  final String radicand;

  /// Small numeral tucked into the hook (`'3'` for cube roots).
  final String? index;
}

/// Splits [text] into plain runs, radical spans, answer blanks and
/// stacked fractions.
///
/// A radical is `√` or `∛` immediately followed by a number (`√16`,
/// `√2.25`) or a balanced parenthesized group (`√(l² + w² + h²)`). A bare
/// `√` with neither stays literal text.
///
/// A blank is two or more underscores. A blank numerator (`___/6`) is
/// drawn as a stacked fraction with a box on top, and then every other
/// fraction in the text is stacked too, so `2/3 = ___/6` reads as one
/// equation. Text without a blank numerator keeps its fractions inline.
List<MathSegment> parseMathSegments(String text) {
  final stackFractions = _blankFraction.hasMatch(text);
  final segments = <MathSegment>[];
  final buf = StringBuffer();
  var bufStart = 0;
  void flush(int at) {
    if (buf.isNotEmpty) {
      segments.add(PlainSegment(buf.toString(), start: bufStart));
      buf.clear();
    }
    bufStart = at;
  }

  var i = 0;
  while (i < text.length) {
    final c = text[i];
    if (c == '√' || c == '∛') {
      final (radicand, end) = _radicandAfter(text, i + 1);
      if (radicand != null) {
        flush(i);
        segments.add(
          RadicalSegment(
            radicand,
            index: c == '∛' ? '3' : null,
            start: i,
            end: end,
          ),
        );
        i = end;
        bufStart = end;
        continue;
      }
    }
    if (c == '_') {
      final m = _blankFraction.matchAsPrefix(text, i);
      final blank = m ?? _blank.matchAsPrefix(text, i);
      if (blank != null) {
        flush(i);
        segments.add(
          m != null
              ? FractionSegment(null, m.group(1)!, i, m.end)
              : BlankSegment(i, blank.end),
        );
        i = blank.end;
        bufStart = i;
        continue;
      }
    }
    if (stackFractions &&
        _isDigit(c) &&
        (i == 0 || !_isNumberChar(text[i - 1]))) {
      final m = _fraction.matchAsPrefix(text, i);
      if (m != null) {
        flush(i);
        segments.add(FractionSegment(m.group(1), m.group(2)!, i, m.end));
        i = m.end;
        bufStart = i;
        continue;
      }
    }
    buf.write(c);
    i++;
  }
  flush(text.length);
  return segments;
}

final _blank = RegExp('_{2,}');
final _blankFraction = RegExp(r'_{2,}/(\d+)(?![\d.])');
final _fraction = RegExp(r'(\d+)/(\d+)(?![\d.])');

bool _isDigit(String c) => c.compareTo('0') >= 0 && c.compareTo('9') <= 0;
bool _isNumberChar(String c) => _isDigit(c) || c == '.' || c == '/';

/// Radicand starting at [start]: `(content, index after it)`, or
/// `(null, start)` if none is found.
(String?, int) _radicandAfter(String text, int start) {
  if (start >= text.length) return (null, start);
  if (text[start] == '(') {
    var depth = 0;
    for (var j = start; j < text.length; j++) {
      if (text[j] == '(') depth++;
      if (text[j] == ')') {
        depth--;
        if (depth == 0) return (text.substring(start + 1, j), j + 1);
      }
    }
    return (null, start); // unbalanced — leave literal
  }
  final m = RegExp(r'\d+(\.\d+)?').matchAsPrefix(text, start);
  if (m == null) return (null, start);
  return (m.group(0), m.end);
}

class _Radical extends StatelessWidget {
  const _Radical({required this.segment, required this.style});

  final RadicalSegment segment;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 14.0;
    final color = style.color ?? Theme.of(context).colorScheme.onSurface;
    // Extra room on the left when an index digit sits beside the hook.
    final indexInset = segment.index == null ? 0.0 : fontSize * 0.26;
    final hookWidth = fontSize * 0.6;
    return CustomPaint(
      painter: _RadicalPainter(
        color: color,
        strokeWidth: fontSize * 0.07,
        hookStart: indexInset,
        hookWidth: hookWidth,
        index: segment.index,
        indexFontSize: fontSize * 0.5,
        fontFamily: style.fontFamily,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: indexInset + hookWidth + fontSize * 0.10,
          top: fontSize * 0.22,
          right: fontSize * 0.08,
        ),
        child: Text(segment.radicand, style: style),
      ),
    );
  }
}

class _RadicalPainter extends CustomPainter {
  const _RadicalPainter({
    required this.color,
    required this.strokeWidth,
    required this.hookStart,
    required this.hookWidth,
    required this.index,
    required this.indexFontSize,
    required this.fontFamily,
  });

  final Color color;
  final double strokeWidth;
  final double hookStart;
  final double hookWidth;
  final String? index;
  final double indexFontSize;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final h = size.height;
    final topY = strokeWidth / 2;
    // Leading tick, down-stroke to the bottom vertex, up-stroke to the
    // top, then the vinculum across the full radicand width.
    final path = Path()
      ..moveTo(hookStart, h * 0.55)
      ..lineTo(hookStart + hookWidth * 0.30, h * 0.48)
      ..lineTo(hookStart + hookWidth * 0.58, h - strokeWidth)
      ..lineTo(hookStart + hookWidth, topY)
      ..lineTo(size.width - strokeWidth / 2, topY);
    canvas.drawPath(path, paint);

    if (index != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: index,
          style: TextStyle(
            fontSize: indexFontSize,
            color: color,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, h * 0.42 - tp.height));
    }
  }

  @override
  bool shouldRepaint(_RadicalPainter old) =>
      color != old.color ||
      strokeWidth != old.strokeWidth ||
      hookStart != old.hookStart ||
      hookWidth != old.hookWidth ||
      index != old.index ||
      indexFontSize != old.indexFontSize ||
      fontFamily != old.fontFamily;
}

/// The empty box an answer goes in. It is sized to two digits so it reads
/// as a place to write, not a letter.
class _AnswerBox extends StatelessWidget {
  const _AnswerBox({required this.style, this.fill});

  final TextStyle style;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 14.0;
    final color = style.color ?? Theme.of(context).colorScheme.onSurface;
    return Container(
      width: fontSize * 1.5,
      height: fontSize * 1.15,
      margin: EdgeInsets.symmetric(horizontal: fontSize * 0.08),
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: color, width: fontSize * 0.07),
        borderRadius: BorderRadius.circular(fontSize * 0.2),
      ),
    );
  }
}

/// A fraction drawn the textbook way, numerator over a bar over the
/// denominator; a blank numerator is an [_AnswerBox].
class _StackedFraction extends StatelessWidget {
  const _StackedFraction({
    required this.segment,
    required this.style,
    this.fill,
  });

  final FractionSegment segment;
  final TextStyle style;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 14.0;
    final color = style.color ?? Theme.of(context).colorScheme.onSurface;
    // Smaller than the line's text, as in print, so the stack stays
    // close to two lines tall.
    final part = style.copyWith(fontSize: fontSize * 0.8, height: 1.1);
    final numerator = segment.numerator;
    return Container(
      color: numerator == null ? null : fill,
      // Room above and below, so the box doesn't crowd the line over it
      // ("is shaded?" sitting right on top of it). Equal above and below,
      // so the bar stays level with an "=" beside it.
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.1,
        vertical: fontSize * 0.45,
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: numerator == null
                  ? Padding(
                      padding: EdgeInsets.only(bottom: fontSize * 0.08),
                      child: _AnswerBox(style: part, fill: fill),
                    )
                  : Text(numerator, style: part),
            ),
            Container(
              height: fontSize * 0.07,
              margin: EdgeInsets.symmetric(horizontal: fontSize * 0.04),
              color: color,
            ),
            Center(child: Text(segment.denominator, style: part)),
          ],
        ),
      ),
    );
  }
}
