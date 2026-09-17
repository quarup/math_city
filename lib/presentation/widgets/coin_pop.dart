import 'dart:async';

import 'package:flutter/material.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/widgets/coin_icon.dart';

/// A coin (with its `+N`) that pops at [at] (global coordinates): it blows
/// up fast, settles back to its natural size, then fades — it never travels
/// across the screen. Insert in an [Overlay]; remove the entry after
/// [duration].
///
/// [peakFraction] is where the pop is biggest; the caller times the
/// counter's own pulse to it so the balance changes while the coin is large.
class CoinPop extends StatefulWidget {
  const CoinPop({
    required this.at,
    required this.amount,
    this.duration = kCoinPopDuration,
    super.key,
  });

  final Offset at;
  final int amount;
  final Duration duration;

  static const double peakFraction = 0.3;

  @override
  State<CoinPop> createState() => _CoinPopState();
}

/// Total on-screen time of a [CoinPop].
const Duration kCoinPopDuration = Duration(milliseconds: 600);

class _CoinPopState extends State<CoinPop> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: widget.duration, vsync: this);
    // Blow up past natural size, spring back to 1.0, hold while fading.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: 1.6).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: CoinPop.peakFraction * 100,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.6, end: 1).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 35,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 35),
    ]).animate(_ctrl);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 70),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 30),
    ]).animate(_ctrl);
    unawaited(_ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Positioned(
      left: widget.at.dx,
      top: widget.at.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: IgnorePointer(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: CoinAmount(
                amount: widget.amount,
                prefix: '+',
                iconSize: 36,
                style: TextStyle(
                  color: palette.coinGoldDeep,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  // Overlay entries sit outside the Scaffold's
                  // DefaultTextStyle, which would otherwise underline.
                  decoration: TextDecoration.none,
                  shadows: const [
                    Shadow(color: Color(0x66000000), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
