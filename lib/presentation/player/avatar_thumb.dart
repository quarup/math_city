import 'package:flutter/material.dart';
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/presentation/player/adventurer_avatar_widget.dart';

/// Which part of the face a thumbnail shows.
enum AvatarCrop {
  /// The whole avatar, as the game draws it.
  full,

  /// Hair and head, for the hair styles.
  head,

  /// Eyes to chin, so eyes, mouths and cheek marks read at thumbnail size.
  face,

  /// The eye line with room either side, so glasses frames fit.
  eyes,

  /// The right ear and what hangs from it.
  ear,
}

/// A round avatar at [size], optionally zoomed onto part of the face.
///
/// The crop windows are in the SVG's 762-unit view box: left, top and
/// side of a square. The full avatar is drawn at the scale that fits the
/// window into [size] and shifted so the window's corner sits at the top
/// left; the disc clips the rest.
class AvatarThumb extends StatelessWidget {
  const AvatarThumb({
    required this.config,
    required this.size,
    this.crop = AvatarCrop.full,
    this.background = Colors.white,
    super.key,
  });

  final AdventurerConfig config;
  final double size;
  final AvatarCrop crop;
  final Color background;

  static const double _viewBox = 762;
  static const _windows = <AvatarCrop, (double, double, double)>{
    AvatarCrop.full: (0, 0, 762),
    AvatarCrop.head: (60, 40, 650),
    AvatarCrop.face: (170, 230, 430),
    AvatarCrop.eyes: (110, 240, 430),
    AvatarCrop.ear: (490, 345, 240),
  };

  @override
  Widget build(BuildContext context) {
    final (left, top, side) = _windows[crop]!;
    final drawn = size * _viewBox / side;
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: background,
        child: Stack(
          children: [
            Positioned(
              left: -left / _viewBox * drawn,
              top: -top / _viewBox * drawn,
              width: drawn,
              height: drawn,
              child: AdventurerAvatarWidget(config: config, size: drawn),
            ),
          ],
        ),
      ),
    );
  }
}
