# City animation mocks

Browser mock pages for the animated-city work (design record in
[city_builder.md §9](../../city_builder.md)). They run a small JS port of
the Flame board — `IsoGrid` geometry, `road_sprites.dart` autotiling and
the `_drawSprite` south-corner anchoring — on the real PNGs from
`assets/buildings/`, so what you see is at the game's own 64 px tile.

```sh
python3 tools/city_mocks/build_sprites.py   # once: writes sprites.js (gitignored, ~1.6 MB)
open tools/city_mocks/city_alive.html       # 29 animation ideas with feasibility notes
open tools/city_mocks/walkers.html          # 31 pedestrian styles
open tools/city_mocks/p02_walk.html         # the chosen citizen: walk + shoe comparison
```

- `engine.js` — grid, scene, terrain/road/building drawing, day/night tint,
  emissive-window mask, `Mover` (road-graph walker), cars, particles.
- `mocks.js`, `mocks2.js` — the 29 idea mocks (A streets, B people, C sky,
  D time & light, E landmarks, F construction, G touch & idle).
- `ped.js` — `drawPed(...)`, the parameterised citizen renderer of record,
  plus the 31 style presets. The Dart `CitizenPainter` is a translation of
  this file.

To add a mock, push an object onto `MOCKS` (see the shape at the top of
`engine.js` → `mountMock`). Pages need no server; a `file://` URL works.
