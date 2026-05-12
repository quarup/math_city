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
class NumberPadWidget extends StatefulWidget {
  const NumberPadWidget({
    required this.onSubmit,
    this.extraChars = const [],
    super.key,
  });

  final void Function(String value) onSubmit;
  final List<String> extraChars;

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
  const _InputDisplay({required this.input, required this.theme});

  final String input;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Text(
        input.isEmpty ? '?' : input,
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
  const _DigitButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 60,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          textStyle: theme.textTheme.headlineSmall,
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
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
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
