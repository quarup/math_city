import 'dart:ui';

import 'package:flame/components.dart';

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
