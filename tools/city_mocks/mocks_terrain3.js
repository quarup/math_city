// Round three of the ground-and-sky mocks (ground_round3.html). Needs mocks_common.js.
'use strict';
const DENSITY3 = (rg) => rg <= 2 ? 0.06 : rg === 3 ? 0.2 : 0.55;
// Inside and outside are the same meadow; decor (trees, rocks, flowers) grows on free owned tiles too.
function base3(st, o = {}) {
  base(st, { zoom: o.zoom ?? 0.65, density: DENSITY3 }); st.decor = makeDecor(st.sc, { density: o.density || DENSITY3, inside: true, insideRing: o.insideRing ?? 2 });
  st.extra = []; st.edge = o.edge || null; st.coins = o.coins;
}
const ground3 = (ctx, sc, st) => { drawWorldGround(ctx, sc, { style: 'density', inside: 'meadow', view: vw(st), frontierWash: st.frontierWash }); drawPadsRoads(ctx, sc); if (st.edge) drawEdge(ctx, sc, st.edge); };
function takenNow(st) { const t = st.sc.takenTiles(); for (const s of st.sc.sites) for (let c = s.col; c < s.col + s.w; c++) for (let r = s.row; r < s.row + s.h; r++) t.add(c + ',' + r); return t; }
const ents3 = (st) => { const taken = takenNow(st); return decorEntities([...st.decor, ...st.extra], st.sc, vw(st), { taken }); };
const haze3 = (k = 0.42) => (ctx, st, W, H) => drawHaze(ctx, st, W, H, k);
const edgeMock = (id, title, tier, notes, o) => MOCKS.push({
  id, section: 'Where the town ends', title, art: 'I draw it', effort: o.effort || 'S', perf: 'Free', tier, notes,
  scene: new WorldScene(CITY()), view: V(), hourStart: 11, setup: (st) => { base3(st, o); o.setup?.(st); }, terrain: ground3, entities: ents3, hud: haze3(),
});

// ============ X. WHERE THE TOWN ENDS =======================================
edgeMock('x1', 'No indication: the town is just where the buildings are', 'Decide',
  `R1 as asked for: the same meadow, trees, rocks and shades of green inside the town as on the ring just outside it. Decor grows on any free owned tile and hides under a placed building. The edge exists only in placement and move mode (B1 + B4, locked). This is the baseline the other nine add one thing to.`, {});
edgeMock('x2', 'A line: a worn footpath around the town', 'Nice',
  `The simplest honest line: a pale, slightly sunken path along the boundary, the kind that forms where people walk the edge of a field. Reads as a town limit without any built object. Cheapest of the ten and it never fights the buildings.`, { edge: 'line' });
edgeMock('x3', 'A white picket fence', 'Nice',
  `Posts every quarter tile with two rails, in the off-white of the sprites' trims. The most "town" of the fences and the most kid-legible; from the overview it becomes a fine white line. It moves outward when a block is bought, which doubles as the purchase's visible result.`, { edge: 'picket' });
edgeMock('x4', 'A low stone wall', 'Nice',
  `A dry-stone wall with a lit cap and a shaded face on the two viewer-facing sides, so it has a little height. Heavier than the fences; suits the civic buildings but reads a touch defensive for a six-year-old's town.`, { edge: 'stone' });
edgeMock('x5', 'A split-rail fence', 'Recommend',
  `Brown posts and two rails: the farm fence. Quieter than the picket, matches the farmhouse and the wooden survey stakes already in the game, and it sits well against both the meadow and the forest options below. My pick among the built edges.`, { edge: 'rail' });
edgeMock('x6', 'A hedge', 'Nice',
  `Round-one F4's hedge without the gates: a soft dark-green line of shrubs along the boundary. Nature rather than carpentry, and it makes the town feel enclosed and cosy. Slightly bulky where it runs in front of a building's base.`, { edge: 'hedge' });
edgeMock('x7', 'A planted border: a flower bed all the way round', 'Nice',
  `A low green bed with blooms along the boundary, as if the town council planted it. Reads as cared-for rather than fenced-off, and it picks up the flower specks already in the meadow so nothing new is introduced.`, { edge: 'flowerline' });
edgeMock('x8', 'A line of trees just inside the edge', 'Nice',
  `No object on the boundary at all: a tree every couple of tiles just inside it, like a windbreak. The town reads as a tended place framed by its own trees; up close the gaps between trunks make the edge soft and natural.`, { setup: (st) => { st.extra = makeEdgeTrees(st.sc, 1).map((d) => ({ ...d, s: d.s + 0.3 })); st.decor = st.decor.filter((d) => d.kind !== 'tree' || !st.sc.isOwnedTile(d.c, d.r)); } });
edgeMock('x9', 'Forest right outside: dense trees two tiles deep around the town', 'Recommend',
  `The land you own is a clearing. Immediately beyond the boundary the trees close in for two tiles, then thin back to the ring-2 meadow. The edge is unmistakable and entirely natural, and buying a block visibly clears a bite out of the forest. Works with or without a fence; the forest ring is what I would pair with X5.`,
  { setup: (st) => { st.extra = makeForestRing(st.sc, 2, 0.8); } });
edgeMock('x10', 'Wilder beyond: sparse inside, thick trees everywhere outside', 'Nice',
  `Instead of a two-tile ring, the whole countryside is wooded and the town is the only open ground: few trees inside, many outside, no hard line. The gentlest contrast of the ten, and the one that makes a bought block change the least.`,
  { density: (rg) => rg === 0 ? 0.04 : 0.32, insideRing: 0 });
edgeMock('x11', 'Rail fence and wilder beyond: keeping the wild out', 'Recommend',
  `X5 and X10 together: the whole countryside is wooded and the town is the one open ground, with the farm fence on the line to say so. The fence reads as what keeps the wild animals out rather than as a border. The main street now runs off the map east and west and the high street south, and the fence opens where a road crosses it, so there are three ways in and out of town and the roads no longer stop at the edge. Buying a block moves the fence out and clears that bite of woodland.`,
  { edge: 'rail', density: (rg) => rg === 0 ? 0.04 : 0.32, insideRing: 0 });

// ============ K. HAZE COLOUR ==============================================
MOCKS.push({
  id: 'k1', section: 'Haze colour', title: 'The sky is white by day, black at night, and never purple',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `The haze now takes its colour from a fixed horizon table instead of the old teal sky gradient: near-black at midnight, dark grey before dawn, a short peach at sunrise, then an almost-white with the faintest blue through the day, warm white in the afternoon, orange at dusk, grey-brown to dark. Interpolation only ever runs between neighbouring keys, so there is no purple between night-blue and dawn. The strip at the bottom is the whole day; scrub the slider or jump to the hours you flagged. No stars.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 10, setup: (st) => { base3(st, { zoom: 0.55, edge: 'rail' }); st.extra = makeForestRing(st.sc, 2, 0.8); st.play = false; },
  controls: [{ label: '5 am', run: (st) => st.hour = 5 }, { label: '6:30 am', run: (st) => st.hour = 6.5 }, { label: '10 am', run: (st) => st.hour = 10 }, { label: 'Noon', run: (st) => st.hour = 12 }, { label: '6:30 pm', run: (st) => st.hour = 18.5 }, { label: 'Midnight', run: (st) => st.hour = 0 }, { label: 'Play / pause', run: (st) => st.play = !st.play }, { range: [0, 23.9, 0.1], label: 'Hour', get: (st) => st.hour, set: (st, v) => { st.hour = v % 24; st.play = false; } }],
  update: (st, dt) => { if (st.play) st.hour = (st.hour + dt * 24 / 40) % 24; },
  terrain: ground3, entities: ents3,
  hud: (ctx, st, W, H) => {
    drawHaze(ctx, st, W, H); label(ctx, fmtHour(st.hour), 10, 10);
    const x0 = 14, y0 = H - 26, w = W - 28, h = 12; for (let i = 0; i < 96; i++) { ctx.fillStyle = hazeColorAt(i / 4); ctx.fillRect(x0 + (w * i) / 96, y0, w / 96 + 0.5, h); }
    ctx.strokeStyle = 'rgba(0,0,0,.4)'; ctx.lineWidth = 1; ctx.strokeRect(x0, y0, w, h); const mx = x0 + (w * st.hour) / 24; ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.moveTo(mx, y0 - 2); ctx.lineTo(mx - 5, y0 - 9); ctx.lineTo(mx + 5, y0 - 9); ctx.closePath(); ctx.fill();
  },
});

// ============ E. EXPAND WITH A BUILDING IN MIND ============================
const CROWDED_E = () => new WorldScene(CROWDED());
function eReset(st) { st.t0 = st.t; st.sc.owned = new Set(startBlocks().map((b) => b.join(','))); st.sc.buildings = st.sc.buildings.filter((b) => b !== st.park); st.park = null; st.sc.sites = []; st.expand = false; st.sel = null; st.signT = {}; st.paid = 0; st.zoomTarget = 0.62; st.view.zoom = 0.62; overview(st, 0.62); st.extra = makeForestRing(st.sc, 2, 0.8); }
function phaseOf(st, steps) { const e = st.t - st.t0; let ph = 0; while (ph < steps.length && e >= steps[ph]) ph++; return [ph, e]; }
function drawFrontierPlain(ctx, st, except) {
  for (const [bx, by] of st.sc.frontier()) { if (except && except(bx, by)) continue; const pop = popOf(st, bx + ',' + by); drawSurvey(ctx, st.sc, bx, by, { color: `rgba(255,255,255,${0.6 * pop})`, width: 1.5, wash: `rgba(255,255,255,${0.1 * pop})` }); }
}
const parkGhost = (ctx, st, ok) => { drawGhostFootprint(ctx, st.sc, gc(st, 9), gc(st, 1), 2, 2, ok); drawGhostSprite(ctx, st.sc, 'park_v1', gc(st, 9), gc(st, 1), 0.55); };
const E7_STEPS = [2.5, 5, 7.5, 13, 15.5, 19.5, 22];
MOCKS.push({
  id: 'e7', section: 'Expand with a building in mind', title: 'Two sites in a row, and the app remembers the park',
  art: 'I draw it', effort: 'M', perf: 'Free', tier: 'Recommend',
  notes: `Answer to problem 1, option A. Land stops being an instant coin purchase and becomes a <em>construction site like any other</em>: the block is staked (the stakes and string already are the site look) and paid off through the normal question loop. The thing the kid wanted is remembered as a one-slot <em>next</em> on the player row, shown as a chip while the land site runs. When the land opens, the app auto-proposes the park on the new block with the usual <em>Place here</em> bar, and that becomes the second site. Two bars, two celebrations, nothing to re-find. If the kid changes their mind the chip is just dismissed.`,
  scene: CROWDED_E(), view: V(), hourStart: 11, setup: (st) => { base3(st, { edge: 'rail' }); st.park = null; eReset(st); },
  controls: [{ label: 'Replay', run: eReset }],
  update: (st, dt) => {
    const [ph, e] = phaseOf(st, E7_STEPS); st.phase = ph; if (ph >= E7_STEPS.length) { eReset(st); return; }
    if (ph === 1 && !st.expand) { setExpand(st, true); st.zoomTarget = 0.46; }
    if (ph === 2) st.sel = [2, 0];
    if (ph === 3) { st.expand = false; st.sel = null; st.zoomTarget = 0.62; st.paid = Math.min(1200, 1200 * (e - 7.5) / 5); }
    if (ph === 4 && !st.sc.ownsBlock(2, 0)) { st.sc.buy(2, 0); st.paid = 0; }
    if (ph === 5) { if (!st.sc.sites.length) st.sc.sites = [{ col: gc(st, 9), row: gc(st, 1), w: 2, h: 2, stage: 0 }]; st.paid = Math.min(300, 300 * (e - 15.5) / 3.5); if (st.paid >= 300 && !st.park) { st.sc.sites = []; st.park = { id: 'park_v1', col: gc(st, 9), row: gc(st, 1), w: 2, h: 2 }; st.sc.buildings.push(st.park); } }
    st.view.zoom += (st.zoomTarget - st.view.zoom) * Math.min(1, dt * 3);
  },
  terrain: ground3, entities: ents3,
  overlay: (ctx, st) => {
    const ph = st.phase;
    if (ph === 0) { drawGhostFootprint(ctx, st.sc, gc(st, 3), gc(st, 1), 2, 2, false); drawGhostSprite(ctx, st.sc, 'park_v1', gc(st, 3), gc(st, 1), 0.5); }
    if (st.expand) { dimOutside(ctx, st.sc, vw(st), 0.2, { spareFrontier: true }); drawFrontierPlain(ctx, st, (bx, by) => bx === 2 && by === 0); const b = 0.5 + 0.5 * Math.sin(st.t * 3); if (st.sel) drawSurvey(ctx, st.sc, 2, 0, { wash: 'rgba(255,235,59,.35)', t: st.t }); else drawSurvey(ctx, st.sc, 2, 0, { color: `rgba(255,255,255,${0.7 + 0.3 * b})`, width: 2, wash: `rgba(255,255,255,${0.12 + 0.14 * b})`, t: st.t }); parkGhost(ctx, st, true); }
    if (ph === 3) { drawSurvey(ctx, st.sc, 2, 0, { wash: 'rgba(255,235,59,.18)', t: st.t }); const [x, y] = st.sc.blockCenter(2, 0); drawProgressPill(ctx, x, y - 4, st.view.zoom, st.paid, 1200); }
    if (ph === 4) parkGhost(ctx, st, true);
    if (ph === 5 && !st.park) { const [x, y] = st.sc.grid.center(gc(st, 9) + 0.5, gc(st, 1) + 0.5); drawProgressPill(ctx, x, y - 6, st.view.zoom, st.paid, 300); }
  },
  hud: (ctx, st, W, H) => {
    drawHaze(ctx, st, W, H); const ph = st.phase; let btn = null;
    if (ph === 0) btn = drawBar(ctx, W, H, 'No room for a park', { button: '⤢ Expand city' });
    if (ph === 1) label(ctx, 'Expand city · the block that fits breathes', 10, 10);
    if (ph === 2) btn = drawBar(ctx, W, H, 'Stake this land for 🪙 1200? Your park comes next', { button: 'Stake it' });
    if (ph === 3) { label(ctx, 'Land site · paid off by answering questions', 10, 10); label(ctx, 'Next: 🎡 Park (remembered)', 10, 36); }
    if (ph === 4) btn = drawBar(ctx, W, H, 'Your land is ready! Park · place here?', { button: 'Build it!' });
    if (ph === 5) label(ctx, st.park ? 'Park built' : 'Park site · paying off', 10, 10);
    if (ph === 6) label(ctx, 'Done: land, then park, two sites', 10, 10);
    if (ph !== 0 && ph !== 2 && ph !== 4) st.barRects = drawActionBar(ctx, W, H, [{ emoji: '🏠' }, { emoji: '🏥' }, { emoji: '🛍️' }, { emoji: '🎡' }, { emoji: '⤢', label: 'Expand city', on: st.expand }]);
    if (btn) drawHand(ctx, btn.x + btn.w / 2, btn.y + 8, st.t);
    if (ph === 1) { const [sx, sy] = worldToScreen(st, ...st.sc.blockCenter(2, 0), W, H); drawHand(ctx, sx + 6, sy - 6, st.t); }
  },
});
const E8_STEPS = [2.5, 5, 7.5, 15, 18.5];
function drawTwoStagePill(ctx, x, y, zoom, paid, a, b) {
  ctx.save(); ctx.translate(x, y); ctx.scale(1 / zoom, 1 / zoom); const w = 150, h = 22; ctx.fillStyle = 'rgba(16,25,23,.78)'; roundRect(ctx, -w / 2, -h / 2, w, h, 11); ctx.fill();
  const iw = w - 6, aw = iw * a / (a + b); ctx.fillStyle = '#F2B134'; roundRect(ctx, -w / 2 + 3, -h / 2 + 3, aw * Math.min(1, paid / a), h - 6, 8); ctx.fill();
  if (paid > a) { ctx.fillStyle = '#66BB6A'; roundRect(ctx, -w / 2 + 3 + aw, -h / 2 + 3, (iw - aw) * Math.min(1, (paid - a) / b), h - 6, 8); ctx.fill(); }
  ctx.fillStyle = 'rgba(255,255,255,.5)'; ctx.fillRect(-w / 2 + 3 + aw - 0.5, -h / 2 + 3, 1, h - 6);
  ctx.fillStyle = '#fff'; ctx.font = '700 10px "Nunito", system-ui, sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(`🪙 ${Math.round(paid)} / ${a + b} · land then park`, 0, 0.5); ctx.restore();
}
MOCKS.push({
  id: 'e8', section: 'Expand with a building in mind', title: 'One bundled site: land and park paid off together',
  art: 'I draw it', effort: 'M', perf: 'Free', tier: 'Decide',
  notes: `Answer to problem 1, option B. The bar offers one thing, <em>Park on new land</em>, at one price (🪙 1200 land + 🪙 300 park), and it becomes a single site with a two-stage bar. The land stage fills first; when it completes the fence moves out and the park's pad appears on the new ground, and the park stage fills on. One decision, one bar, one celebration, nothing to remember. Against it: the kid commits to a 🪙 1500 goal in one go, and cancelling half-way needs a rule (I would refund the park part and keep the land if the land stage is complete).`,
  scene: CROWDED_E(), view: V(), hourStart: 11, setup: (st) => { base3(st, { edge: 'rail' }); st.park = null; eReset(st); },
  controls: [{ label: 'Replay', run: eReset }],
  update: (st, dt) => {
    const [ph, e] = phaseOf(st, E8_STEPS); st.phase = ph; if (ph >= E8_STEPS.length) { eReset(st); return; }
    if (ph === 1 && !st.expand) { setExpand(st, true); st.zoomTarget = 0.46; }
    if (ph === 2) st.sel = [2, 0];
    if (ph === 3) { st.expand = false; st.sel = null; st.zoomTarget = 0.62; st.paid = Math.min(1500, 1500 * (e - 7.5) / 7); if (st.paid >= 1200 && !st.sc.ownsBlock(2, 0)) { st.sc.buy(2, 0); st.sc.sites = [{ col: gc(st, 9), row: gc(st, 1), w: 2, h: 2, stage: 0 }]; } if (st.paid >= 1500 && !st.park) { st.sc.sites = []; st.park = { id: 'park_v1', col: gc(st, 9), row: gc(st, 1), w: 2, h: 2 }; st.sc.buildings.push(st.park); } }
    st.view.zoom += (st.zoomTarget - st.view.zoom) * Math.min(1, dt * 3);
  },
  terrain: ground3, entities: ents3,
  overlay: (ctx, st) => {
    const ph = st.phase;
    if (ph === 0) { drawGhostFootprint(ctx, st.sc, gc(st, 3), gc(st, 1), 2, 2, false); drawGhostSprite(ctx, st.sc, 'park_v1', gc(st, 3), gc(st, 1), 0.5); }
    if (st.expand) { dimOutside(ctx, st.sc, vw(st), 0.2, { spareFrontier: true }); drawFrontierPlain(ctx, st, (bx, by) => bx === 2 && by === 0); const b = 0.5 + 0.5 * Math.sin(st.t * 3); if (st.sel) drawSurvey(ctx, st.sc, 2, 0, { wash: 'rgba(255,235,59,.35)', t: st.t }); else drawSurvey(ctx, st.sc, 2, 0, { color: `rgba(255,255,255,${0.7 + 0.3 * b})`, width: 2, wash: `rgba(255,255,255,${0.12 + 0.14 * b})`, t: st.t }); parkGhost(ctx, st, true); }
    if (ph === 3 && !st.park) { if (!st.sc.ownsBlock(2, 0)) { drawSurvey(ctx, st.sc, 2, 0, { wash: 'rgba(255,235,59,.18)', t: st.t }); parkGhost(ctx, st, true); } const [x, y] = st.sc.blockCenter(2, 0); drawTwoStagePill(ctx, x, y - 30, st.view.zoom, st.paid, 1200, 300); }
  },
  hud: (ctx, st, W, H) => {
    drawHaze(ctx, st, W, H); const ph = st.phase; let btn = null;
    if (ph === 0) btn = drawBar(ctx, W, H, 'No room for a park', { button: '⤢ Expand city' });
    if (ph === 1) label(ctx, 'Expand city · the block that fits breathes', 10, 10);
    if (ph === 2) btn = drawBar(ctx, W, H, 'Park on new land · 🪙 1200 land + 🪙 300 park', { button: 'Build it!' });
    if (ph === 3) label(ctx, st.park ? 'Park built' : st.sc.ownsBlock(2, 0) ? 'Land done · park stage' : 'One site · land stage', 10, 10);
    if (ph === 4) label(ctx, 'Done: one bundled site', 10, 10);
    if (ph !== 0 && ph !== 2) st.barRects = drawActionBar(ctx, W, H, [{ emoji: '🏠' }, { emoji: '🏥' }, { emoji: '🛍️' }, { emoji: '🎡' }, { emoji: '⤢', label: 'Expand city', on: st.expand }]);
    if (btn) drawHand(ctx, btn.x + btn.w / 2, btn.y + 8, st.t);
    if (ph === 1) { const [sx, sy] = worldToScreen(st, ...st.sc.blockCenter(2, 0), W, H); drawHand(ctx, sx + 6, sy - 6, st.t); }
  },
});
const BIG = { amusement_park_v1: { blocks: [[2, 0], [3, 0], [2, 1], [3, 1]], col: 8, row: 0, w: 6, h: 6, region: [8, 0, 8, 8], label: 'Amusement park (6×6) needs 4 blocks' }, hospital_v1: { blocks: [[2, 0]], col: 8, row: 0, w: 3, h: 3, region: [8, 0, 4, 4], label: 'Hospital (3×3) needs 1 block' } };
MOCKS.push({
  id: 'e9', section: 'Expand with a building in mind', title: 'A building bigger than a block: the mode stakes the set it needs',
  art: 'I draw it', effort: 'M', perf: 'Free', tier: 'Recommend',
  notes: `Answer to problem 2. Blocks are 4×4 and the big capstones are up to 6×6, so "the block that fits" becomes "the smallest set of connected blocks that, together with the land you own, fits the footprint". The mode searches that set (cheapest first, nearest to the town on ties), outlines it as one region with the ghost inside, and prices it as a group: here four blocks for the amusement park at 🪙 6000, two of them on ring 3. Buying a group is one site with one bar. Toggle to the hospital to see the same rule pick a single block. Ring-3 blocks are not normally purchasable until their ring-2 neighbour is owned; a group buy is allowed to include them because the whole set is bought together.`,
  scene: CROWDED_E(), view: V(), hourStart: 11, setup: (st) => { base3(st, { edge: 'rail', coins: 6000 }); st.park = null; eReset(st); st.big = 'amusement_park_v1'; setExpand(st, true); st.zoomTarget = 0.4; },
  controls: [{ label: 'Amusement park (6×6)', run: (st) => st.big = 'amusement_park_v1' }, { label: 'Hospital (3×3)', run: (st) => st.big = 'hospital_v1' }],
  update: (st, dt) => { st.view.zoom += (st.zoomTarget - st.view.zoom) * Math.min(1, dt * 3); },
  terrain: ground3, entities: (st) => { const B = BIG[st.big]; const taken = takenNow(st); for (let c = 0; c < B.region[2]; c++) for (let r = 0; r < B.region[3]; r++) taken.add((gc(st, B.region[0]) + c) + ',' + (gc(st, B.region[1]) + r)); return decorEntities([...st.decor, ...st.extra], st.sc, vw(st), { taken }); },
  overlay: (ctx, st) => {
    const B = BIG[st.big]; const inSet = (bx, by) => B.blocks.some(([x, y]) => x === bx && y === by);
    dimOutside(ctx, st.sc, vw(st), 0.2, { spareFrontier: true });
    for (const [bx, by] of B.blocks) if (ring(bx, by) > 2) { const pts = st.sc.blockCorners(bx, by); ctx.save(); ctx.beginPath(); pts.forEach((p, i) => i ? ctx.lineTo(...p) : ctx.moveTo(...p)); ctx.closePath(); ctx.fillStyle = 'rgba(255,255,255,.14)'; ctx.fill(); ctx.restore(); }
    drawFrontierPlain(ctx, st, inSet);
    const [c0, r0, w, h] = B.region; drawSurveyTiles(ctx, st.sc, gc(st, c0), gc(st, r0), w, h, { wash: 'rgba(255,235,59,.25)', t: st.t });
    drawGhostFootprint(ctx, st.sc, gc(st, B.col), gc(st, B.row), B.w, B.h, true); drawGhostSprite(ctx, st.sc, st.big, gc(st, B.col), gc(st, B.row), 0.6);
    const [x, y] = st.sc.grid.center(gc(st, c0) + w / 2 - 0.5, gc(st, r0) + h / 2 - 0.5); const total = B.blocks.reduce((s, [bx, by]) => s + BLOCK_COST * ring(bx, by), 0);
    drawPill(ctx, x, y + HALF_H * h * 0.5 + 10, st.view.zoom, `${B.blocks.length} block${B.blocks.length > 1 ? 's' : ''} · 🪙 ${total}`, { gold: true });
  },
  hud: (ctx, st, W, H) => { drawHaze(ctx, st, W, H); const B = BIG[st.big]; const total = B.blocks.reduce((s, [bx, by]) => s + BLOCK_COST * ring(bx, by), 0); drawBar(ctx, W, H, `${B.label} · 🪙 ${total}`, { button: 'Stake them' }); drawCoins(ctx, W, st.coins); },
});
