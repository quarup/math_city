import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:math_city/domain/city/day_clock.dart';

/// Where the ground dissolves into sky (city_builder.md §11, T4 + K1):
/// the top [kHazeBandFraction] of the viewport fades to the hour's horizon
/// colour. Nothing lives in the band — no sun, moon, clouds or stars.
const double kHazeBandFraction = 0.42;

/// The ground's base green, for the gradient the board floats on.
const Color kMeadowBase = Color(0xFF9CC466);

Color _hazeColor(double hour) => Color(0xFF000000 | hazeColorAt(hour));

/// Viewport-fixed sky behind the world (S1): a gradient from the hour's
/// horizon colour at the top to a meadow tone at the bottom, so the board's
/// edges fade into ground rather than black. Lives in `camera.backdrop`.
class SkyBackdrop extends Component {
  SkyBackdrop({required this.hour, required this.viewportSize});

  /// The clock's hour, read each frame.
  final double Function() hour;
  final Vector2 Function() viewportSize;

  @override
  void render(Canvas canvas) {
    final size = viewportSize();
    final top = _hazeColor(hour());
    final bottom = Color.lerp(top, kMeadowBase, 0.7)!;
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, size.y),
          [top, bottom],
        ),
    );
  }
}

/// Screen-space pass over the world (drawn in `camera.viewport`): the
/// night's multiply tint and the dusk's warm wash (D2), then the haze band
/// from the horizon table — white by day, black at night, never purple.
class SkyHaze extends Component {
  SkyHaze({required this.hour, required this.viewportSize});

  final double Function() hour;
  final Vector2 Function() viewportSize;

  @override
  void render(Canvas canvas) {
    final size = viewportSize();
    final h = hour();
    final full = Rect.fromLTWH(0, 0, size.x, size.y);
    final night = nightStrengthAt(h);
    final dusk = duskWarmthAt(h);
    if (dusk > 0.02) {
      canvas.drawRect(
        full,
        Paint()
          ..color = const Color(0xFFFFAA5A).withValues(alpha: dusk * 0.35)
          ..blendMode = BlendMode.multiply,
      );
    }
    if (night > 0.02) {
      canvas.drawRect(
        full,
        Paint()
          ..color = Color.fromARGB(
            255,
            (255 - 175 * night).round(),
            (255 - 160 * night).round(),
            (255 - 95 * night).round(),
          )
          ..blendMode = BlendMode.multiply,
      );
    }
    final bandHeight = size.y * kHazeBandFraction;
    final haze = _hazeColor(h);
    const steps = 8;
    final colors = <Color>[
      for (var i = 0; i <= steps; i++)
        haze.withValues(alpha: math.pow(1 - i / steps, 1.6).toDouble()),
    ];
    final stops = <double>[for (var i = 0; i <= steps; i++) i / steps];
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, bandHeight),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, bandHeight),
          colors,
          stops,
        ),
    );
  }
}
