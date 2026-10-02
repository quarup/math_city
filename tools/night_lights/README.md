# Night lights

Which windows, signs and lamps light up on each building sprite at night.
**Every region is drawn by hand** in a review page; nothing is detected
automatically (design record: [city_builder.md §12](../../city_builder.md)).

```sh
PY=tools/sprite_pipeline/.venv/bin/python     # needs numpy, opencv, Pillow

$PY tools/night_lights/serve.py               # the review page, http://127.0.0.1:8765
$PY tools/night_lights/build.py               # re-bake every sprite's assets
```

## Drawing

`serve.py` opens a page with every building sprite shown at night, each
starting blank. A region is a simple polygon: four corners for a plain
window, never more than six.

- **Box** (B, the default): drag a window shape. Pick which way its top
  edge runs first (╲ ╱ ▭).
- **Draw** (P): click each corner (3 to 6). Click the first corner again,
  double-click or press Enter to finish; Esc cancels.
- **Wand** (W): click inside a window; it grows to the patch of similar
  colour and becomes a polygon. Raise the tolerance if it stops short,
  lower it if it leaks.
- **Lamp** (L): click a point of light: a porch lamp, a garden light, a
  bulb on a string. No shape to draw; the app paints a bright core in a
  round halo there. `[` and `]` resize it.
- **Window / Glow**: in Edit with regions selected, the two buttons show
  their kind and clicking one changes them (as does G); neither is lit
  when the selection is mixed or all lamps. In the drawing tools, or with
  nothing selected, they set what the next region you draw will be. A
  *window* is relit warm and keeps a room's hours (dark from midnight to
  5:30). A *glow* (a sign, a screen, a ride) keeps its own colour. **Glows
  and lamps stay on all night**, from dusk until dawn.
- **Edit** (E): click a region to select it.
  - **Several at once:** Shift-click adds or removes one; drag a box to
    select everything whose centre is inside it (Shift adds to what is
    selected; the box may start on top of a region); ⌘A / Ctrl-A selects
    all.
  - With one region selected: drag a corner to move it; double-click an
    edge to add a corner, up to six; Alt-click a corner to remove it, down
    to three.
  - With any selection: drag inside it to move it; **⌘D / Ctrl-D
    duplicates it** (the copies land a little down and to the right,
    selected, ready to drag: the quick way down a row of like windows);
    Delete removes it; G flips it between *window* and *glow*; `[` and `]`
    shrink and grow each shape about its centre; Esc deselects. Each of
    these is one undo step, however many regions it touched.
  - Delete, G, `[ ]` and ⌘D also work on the region you have just drawn,
    in any tool.
- **Clear** removes every region on the sprite. ⌘Z / Ctrl-Z undo, D day /
  night, O outlines, Z zoom (fit, 2×, 3×, 4×, 6×), ← → previous / next,
  R reviewed and next.

Every change is saved to `regions.json` and baked into
`assets/buildings/lights.json` and `assets/buildings/lit/<sprite>.png` at
once, so `git diff` is the review and the app picks it up on the next run.
Commit all three. A sprite with no regions has no entry and no lit image:
its nights are simply dark.

## Files

| File | What |
|---|---|
| `regions.json` | Every region a person drew, per sprite (`id`, kind `w` / `g` / `l`, polygon), and the reviewed flags. The source of truth. |
| `build.py` | `regions.json` → `assets/buildings/lights.json` and `assets/buildings/lit/`. |
| `serve.py`, `review.html` | The review page. |
| `nl_common.py` | Shared: the lit-pixel bake, the wand's polygon fit, the night preview. |

Never hand-edit `assets/buildings/lit/` or `lights.json`; change the
regions in the review page (or `regions.json`) and re-bake.

After adding or regenerating a building sprite, open it in the review page
and draw its lights.

There was a detector (`detect.py`, shape-based) until 2026-10-02. Its
regions were mostly wrong on this art and cost more to clean up than to
draw, so it was removed; it is in the git history if it is ever wanted.
