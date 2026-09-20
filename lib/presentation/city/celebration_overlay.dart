import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/presentation/theme/app_palette.dart';

/// The building-opened celebration drawn over the zoomed-in city
/// (city_builder.md §8.2 step 6): confetti rains over the finished
/// building, a card congratulates and names it, and *Done* hands control
/// back so the camera can zoom out. Empty regions don't absorb touches;
/// only the card does. The block's coins and streak are not repeated here
/// — the site bar's full `price / price` already says the job is paid, a
/// "+N" next to the headline read as a bonus, and the streak is beside the
/// point at this moment.
///
/// [cardKey] lets the host measure the card so it can frame the building
/// in the space the card leaves free.
class CelebrationOverlay extends StatelessWidget {
  const CelebrationOverlay({
    required this.title,
    required this.onDone,
    this.cardKey,
    super.key,
  });

  /// e.g. "Single home is finished!"
  final String title;
  final VoidCallback onDone;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Stack(
      children: [
        const Positioned.fill(child: IgnorePointer(child: ConfettiRain())),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Material(
              key: cardKey,
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Congratulations!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: palette.successGreenDeep,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: onDone,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.successGreenDeep,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 14,
                        ),
                        textStyle: theme.textTheme.titleMedium,
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Confetti falling from the top of the screen: coloured paper flakes with
/// a little sway and tumble, looping so the shower lasts as long as the
/// celebration is up. Pure `CustomPainter`, no assets, no dependencies.
class ConfettiRain extends StatefulWidget {
  const ConfettiRain({this.count = 90, super.key});

  final int count;

  @override
  State<ConfettiRain> createState() => _ConfettiRainState();
}

class _ConfettiRainState extends State<ConfettiRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();
  late final List<_Flake> _flakes = _seed(widget.count);

  static const _colors = [
    Color(0xFFF9D648),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
    Color(0xFFFFA726),
  ];

  List<_Flake> _seed(int n) {
    final rnd = math.Random(7);
    return [
      for (var i = 0; i < n; i++)
        _Flake(
          x: rnd.nextDouble(),
          delay: rnd.nextDouble(),
          speed: 0.55 + rnd.nextDouble() * 0.5,
          sway: 0.02 + rnd.nextDouble() * 0.04,
          swayFreq: 2 + rnd.nextDouble() * 3,
          spin: (rnd.nextDouble() - 0.5) * 12,
          size: 7 + rnd.nextDouble() * 7,
          color: _colors[rnd.nextInt(_colors.length)],
        ),
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, _) => CustomPaint(
      painter: _ConfettiPainter(flakes: _flakes, t: _ctrl.value),
      size: Size.infinite,
    ),
  );
}

class _Flake {
  const _Flake({
    required this.x,
    required this.delay,
    required this.speed,
    required this.sway,
    required this.swayFreq,
    required this.spin,
    required this.size,
    required this.color,
  });

  final double x;
  final double delay;
  final double speed;
  final double sway;
  final double swayFreq;
  final double spin;
  final double size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.flakes, required this.t});

  final List<_Flake> flakes;

  /// Loop phase in `[0, 1)`.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final f in flakes) {
      // Each flake runs its own loop offset by its delay; it falls the
      // screen height in 1 / speed of the loop and waits out the rest.
      final phase = (t + f.delay) % 1.0;
      final fall = phase * f.speed * 1.35;
      if (fall > 1.15) continue;
      final y = fall * size.height - f.size;
      final x =
          f.x * size.width +
          math.sin(phase * f.swayFreq * math.pi * 2) * f.sway * size.width;
      final angle = phase * f.spin;
      // Fade out over the last stretch so the loop restart is seamless.
      final alpha = fall > 0.95 ? ((1.15 - fall) / 0.2).clamp(0.0, 1.0) : 1.0;
      paint.color = f.color.withValues(alpha: alpha);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(angle)
        // A tumbling flake foreshortens: scale x by the spin phase.
        ..scale(0.4 + 0.6 * math.cos(angle * 1.7).abs(), 1)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: f.size,
              height: f.size * 0.6,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
