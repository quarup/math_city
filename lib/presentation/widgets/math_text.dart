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
/// no control over the index at all). Everything else — including Unicode
/// superscript exponents, which are ordinary characters — renders as
/// plain text.
class MathText extends StatelessWidget {
  const MathText(this.text, {this.style, this.textAlign, super.key});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final segments = parseMathSegments(text);
    if (segments.whereType<RadicalSegment>().isEmpty) {
      return Text(text, style: style, textAlign: textAlign);
    }
    // The painter needs the resolved text style (font size, color) that
    // plain spans inherit implicitly from DefaultTextStyle.
    final effective = DefaultTextStyle.of(context).style.merge(style);
    return Text.rich(
      TextSpan(
        children: [
          for (final segment in segments)
            switch (segment) {
              PlainSegment(:final text) => TextSpan(text: text),
              RadicalSegment() => WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: _Radical(segment: segment, style: effective),
              ),
            },
        ],
      ),
      style: style,
      textAlign: textAlign,
    );
  }
}

/// A parsed run of question text: plain characters or one radical.
sealed class MathSegment {
  const MathSegment();
}

final class PlainSegment extends MathSegment {
  const PlainSegment(this.text);

  final String text;
}

final class RadicalSegment extends MathSegment {
  const RadicalSegment(this.radicand, {this.index});

  /// Text under the vinculum. For a parenthesized radicand the outer
  /// parens are dropped — the bar itself shows where the radicand ends.
  final String radicand;

  /// Small numeral tucked into the hook (`'3'` for cube roots).
  final String? index;
}

/// Splits [text] into plain runs and radical spans. A radical is `√` or
/// `∛` immediately followed by a number (`√16`, `√2.25`) or a balanced
/// parenthesized group (`√(l² + w² + h²)`). A bare `√` with neither stays
/// literal text.
List<MathSegment> parseMathSegments(String text) {
  final segments = <MathSegment>[];
  final buf = StringBuffer();
  var i = 0;
  while (i < text.length) {
    final c = text[i];
    if (c == '√' || c == '∛') {
      final (radicand, end) = _radicandAfter(text, i + 1);
      if (radicand != null) {
        if (buf.isNotEmpty) {
          segments.add(PlainSegment(buf.toString()));
          buf.clear();
        }
        segments.add(RadicalSegment(radicand, index: c == '∛' ? '3' : null));
        i = end;
        continue;
      }
    }
    buf.write(c);
    i++;
  }
  if (buf.isNotEmpty) segments.add(PlainSegment(buf.toString()));
  return segments;
}

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
