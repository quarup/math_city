import 'package:flutter/material.dart';

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
