import 'package:flutter/material.dart';

/// On-screen number pad for numeric answer entry.
///
/// Displays the current input and a submit button. The caller receives the
/// submitted string via [onSubmit]; empty input is ignored.
///
/// [extraChars]: optional non-digit characters the answer may contain
/// (e.g. `/` for fractions, `:` for time). Each is rendered as a button
/// above the digit grid. Pass an empty list (the default) to keep the pad
/// digits-only — important so younger players doing pure arithmetic don't
/// see symbols that don't belong to their question type.
///
/// [fill] is the pad for a phone on its side: it takes the height it is
/// given instead of its natural 4 × 60 dp, and the extra characters stand
/// in a column beside the digits rather than in a row above them, so a
/// 340 dp pane holds the whole pad with keys a thumb can hit.
class NumberPadWidget extends StatefulWidget {
  const NumberPadWidget({
    required this.onSubmit,
    this.extraChars = const [],
    this.fill = false,
    super.key,
  });

  final void Function(String value) onSubmit;
  final List<String> extraChars;
  final bool fill;

  @override
  State<NumberPadWidget> createState() => _NumberPadWidgetState();
}

class _NumberPadWidgetState extends State<NumberPadWidget> {
  String _input = '';

  // 8 covers the worst case in v1: a mixed-number answer with a 2-digit
  // whole part and a 2-digit denominator, e.g. `12 3/12`. (3-digit/3-digit
  // fractions like `100/123` and `12:55` times fit in 7.)
  static const _maxLength = 8;

  void _append(String c) {
    if (_input.length >= _maxLength) return;
    // Mixed-number separator: only one space allowed, and only after a digit.
    // Stops the silent double-press footgun and the "leading space" mistake.
    if (c == ' ' && (_input.isEmpty || _input.endsWith(' '))) return;
    setState(() => _input += c);
  }

  void _backspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _submit() {
    if (_input.isEmpty) return;
    widget.onSubmit(_input);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.fill) return _fillLayout(theme);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InputDisplay(input: _input, theme: theme),
        const SizedBox(height: 12),
        if (widget.extraChars.isNotEmpty) ...[
          _ExtraCharsRow(chars: widget.extraChars, onTap: _append),
          const SizedBox(height: 4),
        ],
        _PadGrid(onDigit: _append, onBackspace: _backspace, onSubmit: _submit),
      ],
    );
  }

  /// The side layout: the display on top, then four rows that share the
  /// rest of the height — digits in three columns, the extra characters
  /// in one more column (two when there are more than four).
  Widget _fillLayout(ThemeData theme) {
    final extras = widget.extraChars;
    final symbolColumns = extras.isEmpty ? 0 : (extras.length > 4 ? 2 : 1);
    final symbolStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    Widget cell(Widget child) => Expanded(
      child: Padding(padding: const EdgeInsets.all(4), child: child),
    );
    Widget symbol(int i) {
      if (i >= extras.length) return const SizedBox.shrink();
      final c = extras[i];
      return _DigitButton(
        label: c == ' ' ? 'and' : c,
        onTap: () => _append(c),
        textStyle: symbolStyle,
        expand: true,
      );
    }

    Widget row(List<Widget> keys, int r) => Expanded(
      child: Row(
        children: [
          for (final k in keys) cell(k),
          for (var c = 0; c < symbolColumns; c++) cell(symbol(r + 4 * c)),
        ],
      ),
    );

    const rows = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
    ];
    return Column(
      children: [
        _InputDisplay(input: _input, theme: theme, height: 52),
        const SizedBox(height: 4),
        for (final (r, digits) in rows.indexed)
          row([
            for (final d in digits)
              _DigitButton(label: d, onTap: () => _append(d), expand: true),
          ], r),
        row([
          _ActionButton(
            icon: Icons.backspace_outlined,
            color: theme.colorScheme.errorContainer,
            iconColor: theme.colorScheme.onErrorContainer,
            onTap: _backspace,
            expand: true,
          ),
          _DigitButton(label: '0', onTap: () => _append('0'), expand: true),
          _ActionButton(
            icon: Icons.check_rounded,
            color: theme.colorScheme.primaryContainer,
            iconColor: theme.colorScheme.onPrimaryContainer,
            onTap: _submit,
            expand: true,
          ),
        ], 3),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Extra-chars row (only shown when needed)
// ---------------------------------------------------------------------------

class _ExtraCharsRow extends StatelessWidget {
  const _ExtraCharsRow({required this.chars, required this.onTap});

  final List<String> chars;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final c in chars)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 80,
              child: _DigitButton(
                // Space is invisible on a button; show "and" so the mixed-
                // number separator key reads clearly to a kid.
                label: c == ' ' ? 'and' : c,
                onTap: () => onTap(c),
                // Symbol glyphs (especially '.') are much smaller than
                // digits at the default size — bump them so the decimal
                // point key doesn't read as an empty pill.
                textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Input display
// ---------------------------------------------------------------------------

class _InputDisplay extends StatelessWidget {
  const _InputDisplay({
    required this.input,
    required this.theme,
    this.height = 64,
  });

  final String input;
  final ThemeData theme;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Text(
        // The mixed-number separator is stored as ' ' so the parser handles
        // it, but rendered as " and " so the player visually matches the
        // prompt's phrasing ("Write 1 and 3/4 as ...").
        input.isEmpty ? '?' : input.replaceAll(' ', ' and '),
        style: theme.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: input.isEmpty
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pad grid  (3 × 4 calculator layout)
// ---------------------------------------------------------------------------
//   7  8  9
//   4  5  6
//   1  2  3
//   ⌫  0  ✓

class _PadGrid extends StatelessWidget {
  const _PadGrid({
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
  });

  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
    ];
    return Column(
      children: [
        for (final row in rows) _buildRow(context, row),
        _buildBottomRow(context),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: digits
          .map(
            (d) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _DigitButton(label: d, onTap: () => onDigit(d)),
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _buildBottomRow(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _ActionButton(
                icon: Icons.backspace_outlined,
                color: theme.colorScheme.errorContainer,
                iconColor: theme.colorScheme.onErrorContainer,
                onTap: onBackspace,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _DigitButton(label: '0', onTap: () => onDigit('0')),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _ActionButton(
                icon: Icons.check_rounded,
                color: theme.colorScheme.primaryContainer,
                iconColor: theme.colorScheme.onPrimaryContainer,
                onTap: onSubmit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitButton extends StatelessWidget {
  const _DigitButton({
    required this.label,
    required this.onTap,
    this.textStyle,
    this.expand = false,
  });

  final String label;
  final VoidCallback onTap;
  final TextStyle? textStyle;

  /// Fill the cell the pad gives it instead of the standard 60 dp.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: expand ? double.infinity : 60,
      width: expand ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          textStyle: textStyle ?? theme.textTheme.headlineSmall,
          padding: EdgeInsets.zero,
        ),
        child: Text(label),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
    this.expand = false,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: expand ? double.infinity : 60,
      width: expand ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}
