import 'package:flutter/material.dart';
import 'package:math_dash/domain/avatar/avatar_config.dart';

/// Renders a simple character from an [AvatarConfig].
/// No external assets needed — everything is drawn with CustomPainter.
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({required this.config, this.size = 80, super.key});

  final AvatarConfig config;

  /// Height of the widget; width is 75% of this so the figure is portrait.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.75,
      height: size,
      child: CustomPaint(painter: _AvatarPainter(config)),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter(this.config);

  final AvatarConfig config;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Long hair: side strands drawn first so head and body overlap them.
    if (config.hairStyleIndex == 1) {
      final hairPaint = Paint()..color = config.hairColor;
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.27, h * 0.10, w * 0.10, h * 0.32),
            Radius.circular(w * 0.04),
          ),
          hairPaint,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.63, h * 0.10, w * 0.10, h * 0.32),
            Radius.circular(w * 0.04),
          ),
          hairPaint,
        );
    }

    // Hair cap (behind head) then head.
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.10),
          width: w * 0.38,
          height: h * 0.20,
        ),
        Paint()..color = config.hairColor,
      )
      ..drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.16),
          width: w * 0.34,
          height: h * 0.28,
        ),
        Paint()..color = config.skinTone,
      );

    // Eyes: white sclera, coloured iris, dark pupil.
    for (final cx in [w * 0.42, w * 0.58]) {
      final eyeCenter = Offset(cx, h * 0.155);
      canvas
        ..drawOval(
          Rect.fromCenter(
            center: eyeCenter,
            width: w * 0.11,
            height: h * 0.090,
          ),
          Paint()..color = Colors.white,
        )
        ..drawOval(
          Rect.fromCenter(
            center: eyeCenter,
            width: w * 0.08,
            height: h * 0.068,
          ),
          Paint()..color = config.eyeColor,
        )
        ..drawOval(
          Rect.fromCenter(
            center: eyeCenter,
            width: w * 0.04,
            height: h * 0.038,
          ),
          Paint()..color = const Color(0xFF1A1A1A),
        );
    }

    // Neck, arms (angled outward, drawn before torso so torso overlaps
    // shoulder), torso, legs.
    // Flutter canvas: positive rotation = clockwise, so +angle swings LEFT,
    // -angle swings RIGHT for a downward-pointing arm.
    canvas
      ..drawRect(
        Rect.fromLTWH(w * 0.44, h * 0.285, w * 0.12, h * 0.038),
        Paint()..color = config.skinTone,
      )
      ..save()
      ..translate(w * 0.315, h * 0.315)
      ..rotate(0.55)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * 0.05, 0, w * 0.10, h * 0.27),
          Radius.circular(w * 0.04),
        ),
        Paint()..color = config.topColor,
      )
      ..restore()
      ..save()
      ..translate(w * 0.685, h * 0.315)
      ..rotate(-0.55)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * 0.05, 0, w * 0.10, h * 0.27),
          Radius.circular(w * 0.04),
        ),
        Paint()..color = config.topColor,
      )
      ..restore()
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.315, h * 0.312, w * 0.37, h * 0.318),
          Radius.circular(w * 0.05),
        ),
        Paint()..color = config.topColor,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.315, h * 0.622, w * 0.16, h * 0.378),
          Radius.circular(w * 0.05),
        ),
        Paint()..color = config.bottomColor,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.525, h * 0.622, w * 0.16, h * 0.378),
          Radius.circular(w * 0.05),
        ),
        Paint()..color = config.bottomColor,
      );
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => config != old.config;
}
