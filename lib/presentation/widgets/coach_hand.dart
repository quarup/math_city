import 'package:flutter/material.dart';

/// How the hand moves: a tap bobs in place; a fling slides across and
/// fades, over and over.
enum CoachHandMode { tap, fling }

/// The one-time gesture hint of city_builder.md §10.4: an animated hand
/// that shows the kid what to do — tap here, fling this — instead of a
/// tutorial screen. Ignores pointers so it never gets in the way of the
/// gesture it is teaching.
class CoachHand extends StatefulWidget {
  const CoachHand({required this.mode, this.size = 44, super.key});

  final CoachHandMode mode;
  final double size;

  @override
  State<CoachHand> createState() => _CoachHandState();
}

class _CoachHandState extends State<CoachHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.mode == CoachHandMode.tap
        ? const Duration(milliseconds: 900)
        : const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hand = Text(
      '👆',
      style: TextStyle(
        fontSize: widget.size,
        shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
      ),
    );
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          if (widget.mode == CoachHandMode.tap) {
            // Press down and lift: a dip with a small squash at the bottom.
            final dip = Curves.easeInOut.transform(
              t < 0.5 ? t * 2 : (1 - t) * 2,
            );
            return Transform.translate(
              offset: Offset(0, -10 + 14 * dip),
              child: Transform.scale(scale: 1 - 0.12 * dip, child: child),
            );
          }
          // Sweep left to right, fading out at the end of each pass.
          final x = Curves.easeInOut.transform(t) * 2 - 1;
          final fade = t < 0.15
              ? t / 0.15
              : t > 0.8
              ? (1 - t) / 0.2
              : 1.0;
          return Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(x * widget.size * 1.6, 0),
              child: child,
            ),
          );
        },
        child: hand,
      ),
    );
  }
}
