import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Whether a box is wider than tall: a phone or tablet on its side. Every
/// screen with a side-by-side layout reads this one rule, with no height
/// threshold and no orientation API, so a window that is merely wide (an
/// iPad on its side, a desktop window) gets the same layout as a phone.
bool isOnSide(BoxConstraints c) => c.maxWidth > c.maxHeight;

/// [isOnSide] for a size.
bool sizeIsOnSide(Size size) => size.width > size.height;

/// Height of an app bar on a phone on its side: the standard 64 dp is a
/// sixth of the screen there.
const double kSideToolbarHeight = 44;

/// Hides the system status bar while a *phone* is on its side (a 412 dp
/// screen cannot spare 24 of them) and shows it again upright. Tablets keep
/// their bar both ways. Sits under the app's navigator so one widget covers
/// every screen.
class SystemBarsForOrientation extends StatefulWidget {
  const SystemBarsForOrientation({required this.child, super.key});

  final Widget child;

  /// Below this shortest side the device counts as a phone.
  static const double tabletShortestSide = 600;

  @override
  State<SystemBarsForOrientation> createState() =>
      _SystemBarsForOrientationState();
}

class _SystemBarsForOrientationState extends State<SystemBarsForOrientation> {
  bool? _hidden;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hide =
        sizeIsOnSide(size) &&
        size.shortestSide < SystemBarsForOrientation.tabletShortestSide;
    if (hide != _hidden) {
      _hidden = hide;
      // After the frame: a platform call during build is harmless but the
      // frame that follows is the one that should already match.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (hide) {
          unawaited(
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
          );
        } else {
          unawaited(
            SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.manual,
              overlays: SystemUiOverlay.values,
            ),
          );
        }
      });
    }
    return widget.child;
  }
}
