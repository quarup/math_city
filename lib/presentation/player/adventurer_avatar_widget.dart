import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:math_dash/domain/avatar/adventurer_composer.dart';
import 'package:math_dash/domain/avatar/adventurer_config.dart';

class AdventurerAvatarWidget extends StatelessWidget {
  const AdventurerAvatarWidget({
    required this.config,
    super.key,
    this.size = 96,
  });

  final AdventurerConfig config;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      composeAdventurer(config),
      width: size,
      height: size,
    );
  }
}
