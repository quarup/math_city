import 'dart:ui';

import 'package:flame/components.dart';
import 'package:math_city/domain/city/day_clock.dart';

/// The ground's base green, for the backdrop behind the world (only ever
/// seen for a frame before the ground picture covers it).
const Color kMeadowBase = Color(0xFF9CC466);

/// Viewport-fixed backdrop behind the world: a flat meadow tone.
class SkyBackdrop extends Component {
  SkyBackdrop({required this.viewportSize});

  final Vector2 Function() viewportSize;

  @override
  void render(Canvas canvas) {
    final size = viewportSize();
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = kMeadowBase,
    );
  }
}

/// The time of day over the whole scene (city_builder.md §11, D2; revised
/// 2026-10-01 — no haze band): a warm wash at dawn and dusk and a dark
/// multiply at night, both across the entire viewport. Drawn in
/// `camera.viewport`, over the world.
class SkyTint extends Component {
  SkyTint({required this.hour, required this.viewportSize});

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
  }
}
