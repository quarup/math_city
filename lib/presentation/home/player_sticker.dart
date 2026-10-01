import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';
import 'package:math_city/presentation/theme/app_palette.dart';

/// A player on the home screen: their face as a round sticker (white edge,
/// tile-art ink outline) straight on the sky, the name underneath, and a
/// pencil badge on the ring's lower-right edge for editing. The chosen
/// player gets an orange ring outside the sticker edge.
class PlayerSticker extends StatelessWidget {
  const PlayerSticker({
    required this.player,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    super.key,
  });

  final Player player;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  /// Diameter of the ink-outlined disc. The white sticker edge and the
  /// selection ring sit outside it.
  static const double ringSize = 88;
  static const double _edge = 3;
  static const double _selectRing = 3;
  static const double _badge = 26;

  /// Width of one sticker in the wrap, including room for the badge.
  static const double slotWidth = 96;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return SizedBox(
      width: slotWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: ringSize + 2 * (_edge + _selectRing),
            height: ringSize + 2 * (_edge + _selectRing),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: _StickerDisc(
                    size: ringSize,
                    edge: _edge,
                    ring: isSelected ? _selectRing : 0,
                    ringColor: palette.streakOrange,
                    fill: Colors.white,
                    outline: palette.tileInk,
                    child: AdventurerAvatarWidget(
                      config: player.avatar,
                      size: ringSize - 12,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Semantics(
                    button: true,
                    label: 'Edit ${player.name}',
                    child: GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        width: _badge,
                        height: _badge,
                        decoration: BoxDecoration(
                          color: palette.brandTealDeep,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            player.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.tileInk,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// The empty slot at the end of the row: a dashed ring with a plus.
class AddPlayerSticker extends StatelessWidget {
  const AddPlayerSticker({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    const pad = PlayerSticker._edge + PlayerSticker._selectRing;
    return SizedBox(
      width: PlayerSticker.slotWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(pad),
            child: GestureDetector(
              onTap: onTap,
              child: CustomPaint(
                painter: _DashedRingPainter(color: palette.brandTealDeep),
                child: Container(
                  width: PlayerSticker.ringSize,
                  height: PlayerSticker.ringSize,
                  decoration: const BoxDecoration(
                    color: Color(0x8CFFFFFF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 40,
                    color: palette.brandTealDeep,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.brandTealDeep,
            ),
          ),
        ],
      ),
    );
  }
}

/// White sticker edge, ink outline, optional outer selection ring.
class _StickerDisc extends StatelessWidget {
  const _StickerDisc({
    required this.size,
    required this.edge,
    required this.ring,
    required this.ringColor,
    required this.fill,
    required this.outline,
    required this.child,
  });

  final double size;
  final double edge;
  final double ring;
  final Color ringColor;
  final Color fill;
  final Color outline;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget disc = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: outline, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: child),
    );
    disc = Container(
      padding: EdgeInsets.all(edge),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: disc,
    );
    if (ring > 0) {
      disc = Container(
        padding: EdgeInsets.all(ring),
        decoration: BoxDecoration(color: ringColor, shape: BoxShape.circle),
        child: disc,
      );
    }
    return disc;
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final r = size.width / 2 - 1.5;
    final c = size.center(Offset.zero);
    const dashes = 18;
    const gap = 0.45;
    for (var i = 0; i < dashes; i++) {
      final start = i * 2 * math.pi / dashes;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        2 * math.pi / dashes * (1 - gap),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter oldDelegate) =>
      oldDelegate.color != color;
}
