// Round two of the ground-and-sky mocks (ground_round2.html). Needs mocks_common.js.
'use strict';
const DENSITY = (rg) => rg <= 2 ? 0.06 : rg === 3 ? 0.2 : 0.55;
const ground2 = (inside) => (ctx, sc, st) => { drawWorldGround(ctx, sc, { style: 'density', inside, view: vw(st), frontierWash: st.frontierWash }); if (st.preview) drawPreview(ctx, st); drawPadsRoads(ctx, sc); };
function base2(st, o = {}) { base(st, { zoom: o.zoom ?? 0.65, density: DENSITY }); st.street = o.street ? makeStreetDecor(st.sc) : []; st.coins = o.coins; }
const ents2 = (st) => [...decorEnts(st), ...st.street.map((d) => ({ depth: d.c + d.r + 0.5, draw: (ctx) => d.kind === 'bed' ? drawBed(ctx, d) : drawDecor(ctx, d) }))];
const hazeOnly = (k = 0.42) => (ctx, st, W, H) => drawHaze(ctx, st, W, H, k);
const PARK_SPOTS = [[-3, 1], [6, 2], [7, 6], [3, -4]]; // valid, valid, straddles the edge, on the playground
function cycleGhost(st, spots, period = 1.6) { const k = Math.floor(st.t / period) % spots.length; const [c, r] = spots[k]; st.ghost = [gc(st, c), gc(st, r)]; st.ghostOk = st.sc.fits(st.ghost[0], st.ghost[1], 2, 2); }
function drawGhost(ctx, st, id = 'park_v1') { if (!st.ghost) return; drawGhostFootprint(ctx, st.sc, st.ghost[0], st.ghost[1], 2, 2, st.ghostOk); drawGhostSprite(ctx, st.sc, id, st.ghost[0], st.ghost[1], st.ghostOk ? 0.7 : 0.45); }
// Preview a selected block as tended ground (E4), wiping in.
function drawPreview(ctx, st) {
  const p = st.preview, sc = st.sc, c0 = p.bx * BLOCK + sc.off, r0 = p.by * BLOCK + sc.off;
  for (let c = c0; c < c0 + BLOCK; c++) for (let r = r0; r < r0 + BLOCK; r++) { if (((c - c0) + (r - r0)) / 6 > p.p) continue; const [cx, cy] = sc.grid.center(c, r); diamond(ctx, cx, cy); ctx.fillStyle = TENDED[Math.floor(hash2(c, r) * 3)]; ctx.fill(); }
}
// Expand-mode plumbing: bottom bar with an "Expand city" button; frontier only visible while on.
function expandBar(ctx, st, W, H) { st.barRects = drawActionBar(ctx, W, H, [{ emoji: '🏠' }, { emoji: '🏥' }, { emoji: '🛍️' }, { emoji: '🎡' }, { emoji: '⤢', label: 'Expand city', on: st.expand, key: 'expand' }]); }
function tapExpand(st, wx, wy, e) {
  if (e && st.barRects && e.offsetY > st.H - 52) { const hit = st.barRects.find((r) => e.offsetX >= r.x && e.offsetX <= r.x + r.w); if (hit && hit.item.key === 'expand') setExpand(st, !st.expand); return; }
  if (st.barBtn && e && e.offsetX >= st.barBtn.x && e.offsetX <= st.barBtn.x + st.barBtn.w && e.offsetY >= st.barBtn.y && e.offsetY <= st.barBtn.y + st.barBtn.h) { buySelected(st); st.preview = null; return; }
  if (st.expand) { const before = st.sel; frontierTap(st, wx, wy); if (st.sel !== before) st.preview = st.sel ? { bx: st.sel[0], by: st.sel[1], p: 0 } : null; }
}
// Stakes and string around every purchasable block (F3), the selected one amber.
function drawFrontierStakes(ctx, st, o = {}) {
  for (const [bx, by] of st.sc.frontier()) {
    const selected = st.sel && st.sel[0] === bx && st.sel[1] === by; const pop = popOf(st, bx + ',' + by);
    if (selected) drawSurvey(ctx, st.sc, bx, by, { wash: 'rgba(255,235,59,.35)', t: st.t });
    else { const breathe = o.breathe ? 0.5 + 0.5 * Math.sin(st.t * 2.2 + bx * 0.9 + by * 1.3) : 1; drawSurvey(ctx, st.sc, bx, by, { color: `rgba(255,255,255,${0.55 + 0.35 * breathe * pop})`, width: 1.5, wash: `rgba(255,255,255,${(o.breathe ? 0.03 + 0.09 * breathe : 0.1) * pop})`, t: o.breathe ? st.t : 0 }); }
    const [x, y] = st.sc.blockCenter(bx, by); const price = BLOCK_COST * ring(bx, by);
    if (o.pill && (o.pill === 'always' || selected)) drawPill(ctx, x, y - 6, st.view.zoom, '🪙 ' + price, { gold: st.coins === undefined || st.coins >= price, pop });
    if (o.plus && !selected) drawPlus(ctx, x, y - 4, st.view.zoom, { pop });
  }
}

// ============ R. INSIDE ==================================================
const R_NOTE = (what) => `${what} Outside is T3's density-as-distance in every mock on this page: meadow on the rings you can buy soon, scrub, then forest, with the haze band and nothing floating in it.`;
MOCKS.push({
  id: 'r1', section: 'Inside', title: 'One meadow: the town sits on the same ground as the countryside',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Decide',
  notes: R_NOTE(`No checkerboard, no distinction at all: owned tiles use the same noisy meadow palette and grass tufts as the land beyond, and only roads and buildings say where the town is. The most beautiful and the least legible; B1–B4 below are how placement gets its edges back.`),
  scene: new WorldScene(CITY()), view: V(), hourStart: 11, setup: (st) => base2(st), terrain: ground2('meadow'), entities: ents2, hud: hazeOnly(),
});
MOCKS.push({
  id: 'r2', section: 'Inside', title: 'Tended ground: the same grain, a shade greener, nothing wild',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: R_NOTE(`Owned land keeps the meadow's per-tile noise but shifts one step greener and quieter: no flowers, rocks or trees, rarer tufts. It reads as mown without a pattern, and the edge is visible if you look for it and invisible if you don't. My pick for the resting look.`),
  scene: new WorldScene(CITY()), view: V(), hourStart: 11, setup: (st) => base2(st), terrain: ground2('tended'), entities: ents2, hud: hazeOnly(),
});
MOCKS.push({
  id: 'r3', section: 'Inside', title: 'Mown stripes at low contrast',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: R_NOTE(`Two greens a few percent apart in diagonal stripes, the way a mower leaves a lawn. Keeps a hint of the old rhythm for counting tiles while placing, without the checkerboard's dark squares.`),
  scene: new WorldScene(CITY()), view: V(), hourStart: 11, setup: (st) => base2(st), terrain: ground2('stripes'), entities: ents2, hud: hazeOnly(),
});
MOCKS.push({
  id: 'r4', section: 'Inside', title: 'A faint checker, two percent apart',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: R_NOTE(`The current checkerboard with its contrast turned almost all the way down and the tile stroke removed. Tiles are still countable up close; from the overview it is a plain green.`),
  scene: new WorldScene(CITY()), view: V(), hourStart: 11, setup: (st) => base2(st), terrain: ground2('faint'), entities: ents2, hud: hazeOnly(),
});
MOCKS.push({
  id: 'r5', section: 'Inside', title: 'Tended ground with street trees and flower beds along the roads',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: R_NOTE(`R2 plus a little civic care: on free owned tiles that touch a road, a small street tree or a flower bed sits at the kerb, seeded from the tile hash so nothing is stored and nothing blocks a footprint (they hide under a placed building). The town looks tended rather than mown, which is the difference the user noticed between inside and outside.`),
  scene: new WorldScene(CITY()), view: V(), hourStart: 11, setup: (st) => base2(st, { street: true }), terrain: ground2('tended'), entities: ents2, hud: hazeOnly(),
});

// ============ B. BOUNDARY ON DEMAND ========================================
const placingHud = (what) => (ctx, st, W, H) => { drawHaze(ctx, st, W, H); if (st.placing) drawBar(ctx, W, H, `${what} · tap a tile to place it`, { button: 'Cancel' }); else label(ctx, 'Not placing · no edge drawn', 10, 10); };
MOCKS.push({
  id: 'b1', section: 'Boundary on demand', title: 'Placement mode: boundary, tile grid and a dimmed outside',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `At rest the town is R5: no edge. The moment a building is picked from a folder, three things appear together: the land beyond the town dims, a thin tile grid lies over the owned land, and the boundary runs around it as a moving dashed line. The ghost park cycles through four spots here: two valid, one straddling the edge, one on the playground. The red footprint plus the visible edge explain each refusal without a word. Cancel, and it all goes.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 11, setup: (st) => { base2(st, { street: true }); st.placing = true; },
  controls: [{ label: 'Toggle placement mode', run: (st) => st.placing = !st.placing }],
  update: (st) => cycleGhost(st, PARK_SPOTS), terrain: ground2('tended'), entities: ents2,
  overlay: (ctx, st) => { if (!st.placing) return; dimOutside(ctx, st.sc, vw(st), 0.2); drawOwnedGrid(ctx, st.sc, vw(st), { alpha: 0.2 }); drawBoundary(ctx, st.sc, { dash: [8, 6], t: st.t }); drawGhost(ctx, st); },
  hud: placingHud('Park'),
});
MOCKS.push({
  id: 'b2', section: 'Boundary on demand', title: 'Placement mode: just the boundary line',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `The quietest version: no grid, a lighter dim, and one solid white line with a dark underline around the owned land. The footprint wash alone shows which tiles the ghost covers. Enough for older kids; the six-year-old may want B1's grid to count with.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 11, setup: (st) => { base2(st, { street: true }); st.placing = true; },
  controls: [{ label: 'Toggle placement mode', run: (st) => st.placing = !st.placing }],
  update: (st) => cycleGhost(st, PARK_SPOTS), terrain: ground2('tended'), entities: ents2,
  overlay: (ctx, st) => { if (!st.placing) return; dimOutside(ctx, st.sc, vw(st), 0.12); drawBoundary(ctx, st.sc, { color: 'rgba(0,0,0,.35)', width: 4 }); drawBoundary(ctx, st.sc, { color: 'rgba(255,255,255,.95)', width: 2 }); drawGhost(ctx, st); },
  hud: placingHud('Park'),
});
MOCKS.push({
  id: 'b3', section: 'Boundary on demand', title: 'Placement mode: a grid halo that follows the ghost',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `The tile grid only exists around the ghost, fading out a few tiles away, so the whole town is not covered in lines while the kid drags. The boundary stays faint everywhere and brightens where the halo touches it. The most "designed" of the three; also the most code.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 11, setup: (st) => { base2(st, { street: true }); st.placing = true; },
  controls: [{ label: 'Toggle placement mode', run: (st) => st.placing = !st.placing }],
  update: (st) => cycleGhost(st, PARK_SPOTS), terrain: ground2('tended'), entities: ents2,
  overlay: (ctx, st) => { if (!st.placing) return; dimOutside(ctx, st.sc, vw(st), 0.14); const [gx, gy] = st.sc.grid.center(st.ghost[0] + 0.5, st.ghost[1] + 0.5); drawOwnedGrid(ctx, st.sc, vw(st), { alpha: 0.45, near: [gx, gy, 230] }); drawBoundary(ctx, st.sc, { color: 'rgba(255,255,255,.45)', width: 1.5 }); drawGhost(ctx, st); },
  hud: placingHud('Park'),
});
MOCKS.push({
  id: 'b4', section: 'Boundary on demand', title: 'Move mode: lifting a building shows the same edges',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `The police station has been picked up with <em>Move</em>. Same treatment as B1: the edge and the grid appear for as long as something is in the hand, and the lifted building shows as a translucent ghost over its candidate spot, red when the spot crosses the edge. Drop it or cancel and the town is plain again. One code path for both modes.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 11, setup: (st) => { base2(st, { street: true }); st.placing = true; st.sc.buildings = st.sc.buildings.filter((b) => b.id !== 'police_station_v1'); st.street = makeStreetDecor(st.sc); },
  controls: [{ label: 'Toggle move mode', run: (st) => st.placing = !st.placing }],
  update: (st) => cycleGhost(st, [[5, 5], [-3, 1], [7, 6]], 1.8), terrain: ground2('tended'), entities: ents2,
  overlay: (ctx, st) => { if (!st.placing) return; dimOutside(ctx, st.sc, vw(st), 0.2); drawOwnedGrid(ctx, st.sc, vw(st), { alpha: 0.2 }); drawBoundary(ctx, st.sc, { dash: [8, 6], t: st.t }); drawGhost(ctx, st, 'police_station_v1'); },
  hud: (ctx, st, W, H) => { drawHaze(ctx, st, W, H); if (st.placing) drawBar(ctx, W, H, 'Police station · tap where to move it', { button: 'Cancel' }); else label(ctx, 'Not moving · no edge drawn', 10, 10); },
});

// ============ H. HAZE ONLY =================================================
MOCKS.push({
  id: 'h1', section: 'Haze only', title: 'Haze alone, daytime',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `T4 with the sun and clouds removed: the ground simply dissolves into the sky colour over the top of the viewport. Three band heights to compare. This is the whole sky treatment; nothing floats, nothing animates in the band.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 11, setup: (st) => { base2(st, { street: true, zoom: 0.55 }); st.k = 0.42; }, terrain: ground2('tended'), entities: ents2,
  controls: [{ label: 'Band 30 %', run: (st) => st.k = 0.3 }, { label: 'Band 42 %', run: (st) => st.k = 0.42 }, { label: 'Band 55 %', run: (st) => st.k = 0.55 }],
  hud: (ctx, st, W, H) => { drawHaze(ctx, st, W, H, st.k); label(ctx, `Haze band ${Math.round(st.k * 100)} %`, 10, 10); },
});
MOCKS.push({
  id: 'h2', section: 'Haze only', title: 'Haze alone through the eight-minute day',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `The band takes the sky colour of the hour, so dawn is a warm haze, noon a pale blue one, dusk orange and night a deep blue, while the board takes the tints and the windows light. No sun, moon, stars or clouds: the time of day is carried entirely by colour. Scrub the slider.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 8, setup: (st) => { base2(st, { street: true, zoom: 0.55 }); st.play = true; }, terrain: ground2('tended'), entities: ents2,
  controls: [{ label: 'Play / pause', run: (st) => st.play = !st.play }, { range: [0, 23.9, 0.1], label: 'Hour', get: (st) => st.hour, set: (st, v) => { st.hour = v % 24; st.play = false; } }],
  update: (st, dt) => { if (st.play) st.hour = (st.hour + dt * 24 / 40) % 24; },
  hud: (ctx, st, W, H) => { drawHaze(ctx, st, W, H); label(ctx, fmtHour(st.hour), 10, 10); },
});
MOCKS.push({
  id: 'h3', section: 'Haze only', title: 'Haze, with stars in the band at night only',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Decide',
  notes: `H2 plus one concession: a scatter of twinkling stars fades into the haze band after dusk and out again at dawn. By day the band is empty. Stars are static points, not a floating object, so they may pass where the sun and clouds did not. Your call.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 21.5, setup: (st) => { base2(st, { street: true, zoom: 0.55 }); st.play = true; }, terrain: ground2('tended'), entities: ents2,
  controls: [{ label: 'Play / pause', run: (st) => st.play = !st.play }, { range: [0, 23.9, 0.1], label: 'Hour', get: (st) => st.hour, set: (st, v) => { st.hour = v % 24; st.play = false; } }],
  update: (st, dt) => { if (st.play) st.hour = (st.hour + dt * 24 / 40) % 24; },
  hud: (ctx, st, W, H) => { drawHaze(ctx, st, W, H); drawStarsHazed(ctx, st, W, H); label(ctx, fmtHour(st.hour), 10, 10); },
});

// ============ E. EXPAND CITY ==============================================
const E_SCENE = () => new WorldScene({ ...CITY(), owned: [...startBlocks(), [2, 0]] });
const expandHud = (label0) => (ctx, st, W, H) => { drawHaze(ctx, st, W, H); if (st.expand) buyBar(ctx, st, W, H); else st.barBtn = null; expandBar(ctx, st, W, H); if (st.coins !== undefined) drawCoins(ctx, W, st.coins); if (!st.expand) label(ctx, label0, 10, 10); };
MOCKS.push({
  id: 'e1', section: 'Expand city', title: 'Expand city: stakes and string, a price pill on each block',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `An <em>Expand city</em> button sits at the right of the folder bar. At rest, nothing marks the frontier. Press it and the land beyond the purchasable ring dims, each purchasable block gets F3's stakes and string with a faint wash, and a small price pill in the app's own label style sits at its centre: gold when the kid can afford it, dark otherwise. Tap a block for the amber selection and the buy bar; Buy, and the ground turns tended. One extra block is owned so ring-3 prices show beside ring-2. No signs, no wood.`,
  scene: E_SCENE(), view: V(), hourStart: 11, setup: (st) => { base2(st, { street: true, zoom: 0.5, coins: 1400 }); setExpand(st, true); },
  controls: [{ label: 'Toggle Expand city', run: (st) => setExpand(st, !st.expand) }, { label: '+ 🪙 600', run: (st) => st.coins += 600 }, { label: 'Buy selected', run: (st) => { buySelected(st); st.preview = null; } }],
  tap: tapExpand, terrain: ground2('tended'), entities: ents2,
  overlay: (ctx, st) => { if (!st.expand) return; dimOutside(ctx, st.sc, vw(st), 0.2, { spareFrontier: true }); drawFrontierStakes(ctx, st, { pill: 'always' }); },
  hud: expandHud('At rest · press Expand city'),
});
MOCKS.push({
  id: 'e2', section: 'Expand city', title: 'Expand city: a plus marker, the price only once selected',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `Same mode, quieter blocks: stakes and string plus a white "+" disc at each centre, the universal add-here mark. The price appears as a pill only on the selected block and in the buy bar, so the overview is not a field of numbers. Better for the youngest; F6's affordability colour is lost at a glance.`,
  scene: E_SCENE(), view: V(), hourStart: 11, setup: (st) => { base2(st, { street: true, zoom: 0.5, coins: 1400 }); setExpand(st, true); },
  controls: [{ label: 'Toggle Expand city', run: (st) => setExpand(st, !st.expand) }, { label: 'Buy selected', run: (st) => { buySelected(st); st.preview = null; } }],
  tap: tapExpand, terrain: ground2('tended'), entities: ents2,
  overlay: (ctx, st) => { if (!st.expand) return; dimOutside(ctx, st.sc, vw(st), 0.2, { spareFrontier: true }); drawFrontierStakes(ctx, st, { plus: true, pill: 'selected' }); },
  hud: expandHud('At rest · press Expand city'),
});
MOCKS.push({
  id: 'e3', section: 'Expand city', title: 'Expand city: breathing string, no marker at all',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `Nothing at the block centres. The string itself animates (the dashes crawl and the wash breathes, out of phase per block), which is what says "these are live" instead of a marker. The price is in the bar once a block is tapped. The cleanest picture; the least discoverable without the dimmed outside to frame it.`,
  scene: E_SCENE(), view: V(), hourStart: 11, setup: (st) => { base2(st, { street: true, zoom: 0.5, coins: 1400 }); setExpand(st, true); },
  controls: [{ label: 'Toggle Expand city', run: (st) => setExpand(st, !st.expand) }, { label: 'Buy selected', run: (st) => { buySelected(st); st.preview = null; } }],
  tap: tapExpand, terrain: ground2('tended'), entities: ents2,
  overlay: (ctx, st) => { if (!st.expand) return; dimOutside(ctx, st.sc, vw(st), 0.2, { spareFrontier: true }); drawFrontierStakes(ctx, st, { breathe: true }); },
  hud: expandHud('At rest · press Expand city'),
});
MOCKS.push({
  id: 'e4', section: 'Expand city', title: 'Expand city: selecting a block previews it as tended ground',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `E1's mode, and when a block is tapped its meadow wipes into the tended green before anything is paid: the kid sees what they would own. Deselect and the wild ground returns. A small extra on top of any of E1–E3; it makes the purchase feel like a change to the world rather than a number going down.`,
  scene: E_SCENE(), view: V(), hourStart: 11, setup: (st) => { base2(st, { street: true, zoom: 0.5, coins: 1400 }); setExpand(st, true); st.sel = [3, 0]; st.preview = { bx: 3, by: 0, p: 0 }; },
  controls: [{ label: 'Toggle Expand city', run: (st) => setExpand(st, !st.expand) }, { label: 'Buy selected', run: (st) => { buySelected(st); st.preview = null; } }],
  update: (st, dt) => { if (st.preview) st.preview.p = Math.min(1.01, st.preview.p + dt * 1.4); },
  tap: tapExpand, terrain: ground2('tended'), entities: (st) => decorEntities(st.decor, st.sc, vw(st), { hideBlock: (bx, by) => st.sc.ownsBlock(bx, by) || (st.preview && st.preview.bx === bx && st.preview.by === by) }).concat(st.street.map((d) => ({ depth: d.c + d.r + 0.5, draw: (ctx) => d.kind === 'bed' ? drawBed(ctx, d) : drawDecor(ctx, d) }))),
  overlay: (ctx, st) => { if (!st.expand) return; dimOutside(ctx, st.sc, vw(st), 0.2, { spareFrontier: true }); drawFrontierStakes(ctx, st, { pill: 'selected' }); },
  hud: expandHud('At rest · press Expand city'),
});
const E5_STEPS = [2.5, 5, 8, 10.5, 15];
function e5Reset(st) { st.t0 = st.t; st.sc.owned = new Set(startBlocks().map((b) => b.join(','))); if (st.park) { st.sc.buildings.splice(st.sc.buildings.indexOf(st.park), 1); st.park = null; } st.expand = false; st.sel = null; st.signT = {}; st.wiping = null; st.bought = false; st.zoomTarget = 0.62; st.view.zoom = 0.62; overview(st, 0.62); }
MOCKS.push({
  id: 'e5', section: 'Expand city', title: 'No room → Expand city: the guided path',
  art: 'I draw it', effort: 'M', perf: 'Free', tier: 'Recommend',
  notes: `Auto-playing. The town is full and the park will not fit; the bar says so and offers <em>Expand city</em> instead of a dead end. The hand taps it, the camera pulls back so the ring fits, the mode opens, and the one block the park would fit on breathes brighter with the park ghosted inside it while the others carry plain stakes. The hand taps that block, the bar asks for the price, Buy, the ground turns tended, the park goes in and the mode closes. This replaces round one's N3 letter and F5 sign with the same flow inside the mode.`,
  scene: new WorldScene(CROWDED()), view: V(), hourStart: 11, setup: (st) => { base2(st, { street: true, coins: 1400 }); st.park = null; e5Reset(st); },
  controls: [{ label: 'Replay', run: e5Reset }],
  update: (st, dt) => {
    const e = st.t - st.t0; let ph = 0; while (ph < E5_STEPS.length && e >= E5_STEPS[ph]) ph++; st.phase = ph;
    if (ph >= E5_STEPS.length) { e5Reset(st); return; }
    if (ph === 1 && !st.expand) { setExpand(st, true); st.zoomTarget = 0.46; }
    if (ph === 2 && !st.sel) st.sel = [2, 0];
    if (ph === 3 && !st.bought) { st.bought = true; st.wiping = { bx: 2, by: 0, p: 0 }; st.sel = null; }
    st.view.zoom += (st.zoomTarget - st.view.zoom) * Math.min(1, dt * 3);
    stepWipe(st, dt);
    if (st.bought && !st.wiping && !st.park) { st.park = { id: 'park_v1', col: gc(st, 9), row: gc(st, 1), w: 2, h: 2 }; st.sc.buildings.push(st.park); st.expand = false; st.zoomTarget = 0.62; }
  },
  terrain: ground2('tended'), entities: ents2,
  ground: (ctx, st) => { if (st.wiping) { const w = st.wiping, sc = st.sc, c0 = w.bx * BLOCK + sc.off, r0 = w.by * BLOCK + sc.off; for (let c = c0; c < c0 + BLOCK; c++) for (let r = r0; r < r0 + BLOCK; r++) { if (((c - c0) + (r - r0)) / 6 > w.p) continue; const [cx, cy] = sc.grid.center(c, r); diamond(ctx, cx, cy); ctx.fillStyle = TENDED[Math.floor(hash2(c, r) * 3)]; ctx.fill(); } } },
  overlay: (ctx, st) => {
    if (st.phase === 0) { drawGhostFootprint(ctx, st.sc, gc(st, 3), gc(st, 1), 2, 2, false); drawGhostSprite(ctx, st.sc, 'park_v1', gc(st, 3), gc(st, 1), 0.5); }
    if (!st.expand) return; dimOutside(ctx, st.sc, vw(st), 0.2, { spareFrontier: true });
    for (const [bx, by] of st.sc.frontier()) {
      const fitsHere = bx === 2 && by === 0; const selected = st.sel && st.sel[0] === bx && st.sel[1] === by; const pop = popOf(st, bx + ',' + by);
      if (selected) drawSurvey(ctx, st.sc, bx, by, { wash: 'rgba(255,235,59,.35)', t: st.t });
      else if (fitsHere) { const b = 0.5 + 0.5 * Math.sin(st.t * 3); drawSurvey(ctx, st.sc, bx, by, { color: `rgba(255,255,255,${0.7 + 0.3 * b})`, width: 2, wash: `rgba(255,255,255,${0.12 + 0.14 * b})`, t: st.t }); }
      else drawSurvey(ctx, st.sc, bx, by, { color: `rgba(255,255,255,${0.6 * pop})`, width: 1.5, wash: `rgba(255,255,255,${0.1 * pop})` });
      if (fitsHere && !st.bought) { drawGhostFootprint(ctx, st.sc, gc(st, 9), gc(st, 1), 2, 2, true); drawGhostSprite(ctx, st.sc, 'park_v1', gc(st, 9), gc(st, 1), 0.55); }
    }
  },
  hud: (ctx, st, W, H) => {
    drawHaze(ctx, st, W, H); const ph = st.phase; let btn = null;
    if (ph === 0) btn = drawBar(ctx, W, H, 'No room for a park', { button: '⤢ Expand city' });
    if (ph === 1) label(ctx, 'Expand city · the block that fits breathes', 10, 10);
    if (ph === 2) btn = drawBar(ctx, W, H, 'Buy this land for 🪙 1200?', { button: 'Buy' });
    if (ph >= 3) label(ctx, st.park ? 'Bought · park built · mode closed' : 'Ground turning tended…', 10, 10);
    if (ph !== 0 && ph !== 2) st.barRects = drawActionBar(ctx, W, H, [{ emoji: '🏠' }, { emoji: '🏥' }, { emoji: '🛍️' }, { emoji: '🎡' }, { emoji: '⤢', label: 'Expand city', on: st.expand }]);
    drawCoins(ctx, W, st.bought ? 200 : 1400);
    if (btn && (ph === 0 || ph === 2)) drawHand(ctx, btn.x + btn.w / 2, btn.y + 8, st.t);
    if (ph === 1) { const [sx, sy] = worldToScreen(st, ...st.sc.blockCenter(2, 0), W, H); drawHand(ctx, sx + 6, sy - 6, st.t); }
  },
});
MOCKS.push({
  id: 'e6', section: 'Expand city', title: 'Expand city: the camera pulls back to frame the ring, and returns',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `Entering the mode zooms out just enough to show the whole purchasable ring around the town, whatever the kid was looking at; leaving it restores the previous framing. The mode then never needs the kid to find the edge by panning. Shown with E1's visuals; it pairs with any of E1–E4.`,
  scene: E_SCENE(), view: V(), hourStart: 11, setup: (st) => { base2(st, { street: true, zoom: 0.9, coins: 1400 }); st.expand = false; st.zoomTarget = 0.9; st.view.cx = st.home[0] + 120; st.view.cy = st.home[1] - 40; st.restore = [st.view.cx, st.view.cy]; },
  controls: [{ label: 'Toggle Expand city', run: (st) => { setExpand(st, !st.expand); st.zoomTarget = st.expand ? 0.46 : 0.9; } }],
  tap: (st, wx, wy, e) => { const was = st.expand; tapExpand(st, wx, wy, e); if (st.expand !== was) st.zoomTarget = st.expand ? 0.46 : 0.9; },
  update: (st, dt) => { st.view.zoom += (st.zoomTarget - st.view.zoom) * Math.min(1, dt * 4); const tgt = st.expand ? st.home : st.restore; st.view.cx += (tgt[0] - st.view.cx) * Math.min(1, dt * 4); st.view.cy += (tgt[1] - st.view.cy) * Math.min(1, dt * 4); },
  terrain: ground2('tended'), entities: ents2,
  overlay: (ctx, st) => { if (!st.expand) return; dimOutside(ctx, st.sc, vw(st), 0.2, { spareFrontier: true }); drawFrontierStakes(ctx, st, { pill: 'always' }); },
  hud: expandHud('At rest, zoomed in on the town centre · press Expand city'),
});
