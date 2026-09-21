/// Camera framing maths for zooming the city onto one footprint (the
/// construction loop's "zoom, never swap" — city_builder.md §8.7). Pure
/// Dart so the framing can be unit-tested without Flame.
library;

/// Zoom at which [contentWidth] world units span [fraction] of
/// [viewportWidth] pixels, clamped to `[minZoom, maxZoom]`.
double zoomToFit({
  required double contentWidth,
  required double viewportWidth,
  required double fraction,
  required double minZoom,
  required double maxZoom,
}) {
  final zoom = fraction * viewportWidth / contentWidth;
  return zoom.clamp(minZoom, maxZoom);
}

/// The world point the camera must centre on so that world point
/// `(targetX, targetY)` lands at viewport fraction `(anchorX, anchorY)`
/// — `(0.5, 0.5)` is dead centre, `(0.5, 0.8)` the lower part of the screen
/// with room for the wheel above. Screen offsets divide by [zoom] because
/// the viewfinder position is in world units.
///
/// [bottomInset] is how many viewport pixels a bar drawn over the bottom
/// edge covers: [anchorY] is then a fraction of the *visible* height above
/// it, so an anchor of 1.0 sits on the bar's top edge, not under it.
(double, double) cameraCenterFor({
  required double targetX,
  required double targetY,
  required double zoom,
  required double viewportWidth,
  required double viewportHeight,
  required double anchorX,
  required double anchorY,
  double bottomInset = 0,
}) => (
  targetX - (anchorX - 0.5) * viewportWidth / zoom,
  targetY -
      (anchorY * (viewportHeight - bottomInset) - viewportHeight / 2) / zoom,
);

/// Ease-in-out for the camera tween, `t` in `[0, 1]`.
double easeInOut(double t) => t < 0.5 ? 2 * t * t : 1 - 2 * (1 - t) * (1 - t);
