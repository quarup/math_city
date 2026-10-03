import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/presentation/widgets/coin_icon.dart';

/// How long one coin takes to travel.
const Duration _kFlightDuration = Duration(milliseconds: 700);

/// Delay between one coin leaving and the next.
const Duration _kStagger = Duration(milliseconds: 70);

/// Flies a short stream of coins from [from] to wherever [to] points, as an
/// overlay above everything. Used to show a refund landing in the credit
/// pill, so a kid sees where the coins went.
///
/// [to] is looked up on every frame: the target may not exist yet when the
/// flight starts (the credit pill appears once credit is above zero) or
/// may move. While it returns null the coins head for the top-right corner.
/// Completes when the last coin lands.
Future<void> flyCoins(
  BuildContext context, {
  required Rect from,
  required Rect? Function() to,
  int count = 6,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return Future.value();
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: _CoinFlight(
        from: from,
        to: to,
        count: count,
        onDone: () {
          entry.remove();
          done.complete();
        },
      ),
    ),
  );
  overlay.insert(entry);
  return done.future;
}

/// Screen rect of the widget [key] is attached to, or null when it isn't
/// laid out.
Rect? globalRectOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

class _CoinFlight extends StatefulWidget {
  const _CoinFlight({
    required this.from,
    required this.to,
    required this.count,
    required this.onDone,
  });

  final Rect from;
  final Rect? Function() to;
  final int count;
  final VoidCallback onDone;

  @override
  State<_CoinFlight> createState() => _CoinFlightState();
}

class _CoinFlightState extends State<_CoinFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final total = _kFlightDuration + _kStagger * (widget.count - 1);
    _ctrl = AnimationController(vsync: this, duration: total)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      });
    unawaited(_ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const coinSize = 26.0;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final screen = MediaQuery.sizeOf(context);
        final target =
            widget.to()?.center ?? Offset(screen.width - 40, kToolbarHeight);
        final totalMs = _ctrl.duration!.inMilliseconds;
        final nowMs = _ctrl.value * totalMs;
        final coins = <Widget>[];
        for (var i = 0; i < widget.count; i++) {
          final t =
              ((nowMs - i * _kStagger.inMilliseconds) /
                      _kFlightDuration.inMilliseconds)
                  .clamp(0.0, 1.0);
          if (t <= 0 || t >= 1) continue;
          final e = Curves.easeInOutCubic.transform(t);
          // Each coin starts at a slightly different spot on the button and
          // arcs out sideways a little, so the stream reads as several coins.
          final spread = (i - (widget.count - 1) / 2) * 6.0;
          final start = widget.from.center.translate(spread, 0);
          final control = Offset(
            start.dx + (target.dx - start.dx) * 0.2 - 60 + spread * 3,
            math.min(start.dy, target.dy) - 40,
          );
          final p = _bezier(start, control, target, e);
          // Grows a little mid-flight, shrinks into the pill.
          final scale = 1 + 0.35 * math.sin(math.pi * e) - 0.3 * e;
          coins.add(
            Positioned(
              left: p.dx - coinSize / 2,
              top: p.dy - coinSize / 2,
              child: Transform.scale(
                scale: scale,
                child: const CoinIcon(size: coinSize),
              ),
            ),
          );
        }
        return Stack(children: coins);
      },
    );
  }

  static Offset _bezier(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return a * (u * u) + c * (2 * u * t) + b * (t * t);
  }
}
