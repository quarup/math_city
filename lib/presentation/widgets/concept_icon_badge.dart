import 'package:flutter/material.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/game/spin_wheel/concept_icons.dart';
import 'package:math_city/presentation/theme/category_colors.dart';

/// The concept's wheel badge as a Flutter widget: the same white disc with an
/// ink outline and category icon that the spin wheel paints, so a
/// concept looks the same wherever it is named outside the wheel.
class ConceptIconBadge extends StatelessWidget {
  const ConceptIconBadge({required this.concept, this.size = 40, super.key});

  final Concept concept;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _ConceptBadgePainter(
        categoryId: concept.categoryId,
        tier: tierForGrade(concept.primaryGrade),
        accent: categoryColorFor(concept),
      ),
    ),
  );
}

class _ConceptBadgePainter extends CustomPainter {
  const _ConceptBadgePainter({
    required this.categoryId,
    required this.tier,
    required this.accent,
  });

  final String categoryId;
  final int tier;
  final Color accent;

  static const _ink = Color(0xFF1E2A32);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final centre = Offset(size.width / 2, size.height / 2);
    canvas
      ..drawCircle(centre, r - 1, Paint()..color = Colors.white)
      ..drawCircle(
        centre,
        r - 1,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.1,
      );
    // Icon box is 100 units; it fills ~72% of the badge diameter, as on the
    // wheel.
    final iconSize = r * 2 * 0.72;
    canvas
      ..save()
      ..translate(centre.dx - iconSize / 2, centre.dy - iconSize / 2)
      ..scale(iconSize / 100);
    paintConceptIcon(canvas, categoryId, tier, accent: accent);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ConceptBadgePainter old) =>
      old.categoryId != categoryId || old.tier != tier || old.accent != accent;
}
