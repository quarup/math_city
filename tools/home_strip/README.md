# Home screen city strip

`math_city_bottom.xcf` is the GIMP source of
`assets/images/math_city_bottom.png`, the painted city along the bottom of
the home screen (and the wheel's painted backdrop, when that is drawn).

It lives here, not under `assets/`, because `pubspec.yaml` bundles every
file in `assets/images/` into the app.

Export: File → Export As → PNG, 8 bpc RGBA, compression 9, no colour
profile / thumbnail / metadata. Keep the height at 420 px; the width is
free — the app draws the strip into a fixed-height band (92 dp on a phone
on its side, 150 dp upright) and reads the image's own aspect, so a wider
painting shows more buildings rather than growing taller. The top edge
must stay transparent: the sky gradient shows through above the hills.
