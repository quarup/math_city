/// Camera framing maths for zooming the city onto one footprint (the
/// construction loop's "zoom, never swap" — city_builder.md §8.7). Pure
/// Dart so the framing can be unit-tested without Flame.
library;

import 'dart:math' as math;

/// Where the town's centre sits on screen in the default framing — city
/// creation, the Expand-city pull-back — as a fraction of the visible
/// height: below the centre, so the haze band over the top of the viewport
/// reads as sky above the town (city_builder.md §11.5).
const double kTownAnchorY = 0.58;

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

/// How many tile-widths the view spans, at most, when the camera glides
/// onto a suggested spot: close enough that the spot is easy to find,
/// far enough that the town around it still shows, for a player who
/// meant to build somewhere else. About the opening framing's distance.
const double kModerateViewTiles = 10;

/// Zoom for gliding onto a suggestion whose framed content is
/// [contentWidth] world units wide: zooms in to at least the
/// [kModerateViewTiles]-wide view, keeps a closer [current] zoom as it is,
/// but backs off so the content still spans no more than [fraction] of the
/// viewport. Clamped to `[minZoom, maxZoom]`.
double suggestionZoom({
  required double current,
  required double contentWidth,
  required double viewportWidth,
  required double tileWidth,
  required double minZoom,
  required double maxZoom,
  double fraction = 0.9,
}) {
  final moderate = viewportWidth / (kModerateViewTiles * tileWidth);
  final fit = fraction * viewportWidth / contentWidth;
  return math.min(math.max(current, moderate), fit).clamp(minZoom, maxZoom);
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
