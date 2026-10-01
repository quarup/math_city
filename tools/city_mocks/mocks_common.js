// Scenes and plumbing shared by the ground-and-sky mock pages (terrain_sky.html, ground_round2.html).
'use strict';
const MOCKS = [];
function range(a, b) { const o = []; for (let i = a; i <= b; i++) o.push(i); return o; }
const ROW = (r, c0, c1) => range(c0, c1).map((c) => [c, r]);
const COL = (c, r0, r1) => range(r0, r1).map((r) => [c, r]);
const B = (id, col, row) => ({ id, col, row });
// Scenes in signed world tiles: the starting 3×3 blocks cover −4..7.
const CITY = () => ({
  roads: [...ROW(-1, -4, 7), ...ROW(4, -4, 7), ...COL(1, -4, 7)],
  buildings: [B('mayors_office_v1', -1, 0), B('single_home_v1', 2, 0), B('single_home_v1', 3, 0), B('single_home_v1', 2, 1), B('duplex_v1', -4, 0), B('school_v1', -3, 5), B('park_v1', 2, 5), B('apartment_v1', -4, -3), B('bakery_v1', -1, -3), B('coffee_shop_v1', 2, -2), B('playground_v1', 4, -3), B('fountain_plaza_v1', 5, 0), B('police_station_v1', 5, 5), B('farmhouse_v1', -1, 5)],
});
const CROWDED = () => { const c = CITY(); c.buildings.push(B('high_rise_v1', -4, 1), B('apartment_v1', 5, -4), B('fire_station_v1', 2, -4), B('power_plant_v1', 5, 2), B('observation_tower_v1', -1, 2), B('duplex_v1', 2, 2), B('single_home_v1', 2, 3), B('single_home_v1', 3, 3), B('duplex_v1', 2, 7), B('duplex_v1', 5, 7), B('duplex_v1', -1, 7), B('single_home_v1', -1, -4), B('single_home_v1', 0, -4), B('single_home_v1', -4, -4), B('single_home_v1', -3, -4), B('single_home_v1', -2, -4)); return c; };
const CHAPTER = () => ({ roads: [...ROW(-1, -4, 7), ...COL(1, -4, 7)], buildings: [B('mayors_office_v1', -1, 0)] });
const EXTRA_IDS = ['apartment_v1', 'duplex_v1', 'coffee_shop_v1', 'bakery_v1', 'single_home_v1', 'high_rise_v1', 'single_home_v1', 'duplex_v1'];
const V = () => ({ zoom: 0.55, cx: 0, cy: 0 });
const OVERVIEW_ZOOM = 0.55;

// ---- shared plumbing ----------------------------------------------------------
function overview(st, zoom = OVERVIEW_ZOOM, bx = 0, by = 0) { const [cx, cy] = st.sc.blockCenter(bx, by); Object.assign(st.view, { zoom, cx, cy }); st.home = [cx, cy]; }
const vw = (st) => ({ ...st.view, W: st.W, H: st.H });
function base(st, o = {}) { overview(st, o.zoom); st.decor = makeDecor(st.sc, { density: o.density }); st.clouds = makeClouds(5, st.W); st.signT = {}; st.sel = null; }
const meadowTerrain = (style = 'meadow') => (ctx, sc, st) => { drawWorldGround(ctx, sc, { style, view: vw(st), frontierWash: st.frontierWash }); if (st.hedge) drawHedge(ctx, sc, { gates: true }); drawPadsRoads(ctx, sc); };
const decorEnts = (st) => decorEntities(st.decor, st.sc, vw(st), { hideBlock: (bx, by) => st.sc.ownsBlock(bx, by) || (st.wiping && st.wiping.bx === bx && st.wiping.by === by) });
function skyHud(ctx, st, W, H, o = {}) { const k = o.k ?? 0.42; drawHaze(ctx, st, W, H, k); drawStarsHazed(ctx, st, W, H, k); drawSunMoonHazed(ctx, st, W, H, k); if (st.clouds && !o.noClouds) drawClouds(ctx, st, W, H, k, { parallax: o.parallax || 0 }); }
const easeOutBack = (t) => { const c1 = 1.70158, c3 = c1 + 1; return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2); };
function popOf(st, key) { if (st.signT[key] === undefined) st.signT[key] = st.t; const a = Math.min(1, (st.t - st.signT[key]) / 0.35); return easeOutBack(a); }
function drawFrontierSigns(ctx, st, o = {}) {
  const sc = st.sc; for (const [bx, by] of (o.only || sc.frontier())) {
    const key = bx + ',' + by; const [x, y] = sc.blockCenter(bx, by); const price = BLOCK_COST * ring(bx, by); const afford = st.coins === undefined || st.coins >= price;
    drawSign(ctx, x, y, st.view.zoom, { pop: popOf(st, key), text: o.price ? '🪙 ' + price : (o.text || undefined), gold: !!o.price && afford, glint: (o.price && afford) ? st.t + bx : undefined });
  }
}
function frontierTap(st, wx, wy) { const b = st.sc.blockAt(wx, wy); if (!b) { st.sel = null; return; } const hit = st.sc.frontier().some(([x, y]) => x === b[0] && y === b[1]); st.sel = hit && !(st.sel && st.sel[0] === b[0] && st.sel[1] === b[1]) ? b : null; }
function tapWithBar(st, wx, wy, e) { const r = st.barBtn; if (r && e && e.offsetX >= r.x && e.offsetX <= r.x + r.w && e.offsetY >= r.y && e.offsetY <= r.y + r.h) { buySelected(st); return; } frontierTap(st, wx, wy); }
function buySelected(st) { if (!st.sel) return; const price = BLOCK_COST * ring(...st.sel); if (st.coins !== undefined && st.coins < price) return; if (st.coins !== undefined) st.coins -= price; st.sc.buy(...st.sel); st.sel = null; }
function drawSelection(ctx, st) { if (st.sel) drawSurvey(ctx, st.sc, ...st.sel, { wash: 'rgba(255,235,59,.35)', t: st.t }); }
function buyBar(ctx, st, W, H) { st.barBtn = null; if (!st.sel) return; const price = BLOCK_COST * ring(...st.sel); const can = st.coins === undefined || st.coins >= price; st.barBtn = drawBar(ctx, W, H, can ? `Buy this land for 🪙 ${price}?` : `Costs 🪙 ${price} — earn 🪙 ${price - st.coins} more!`, { button: 'Buy', disabled: !can }); }
const gc = (st, c) => c + st.sc.off; // world → grid
function addBuilding(sc, id) { const [w, h] = FOOT[id]; const spot = sc.freeSpot(w, h); if (!spot) return false; sc.buildings.push({ id, col: spot[0], row: spot[1], w, h }); return true; }
function clampView(st, box) { const v = st.view, hw = st.W / v.zoom / 2, hh = st.H / v.zoom / 2; const x0 = box.x0 + hw, x1 = box.x1 - hw, y0 = box.y0 + hh, y1 = box.y1 - hh; v.cx = x0 > x1 ? (box.x0 + box.x1) / 2 : Math.max(x0, Math.min(x1, v.cx)); v.cy = y0 > y1 ? (box.y0 + box.y1) / 2 : Math.max(y0, Math.min(y1, v.cy)); }
function glide(st, target, dt, k = 3) { st.view.cx += (target[0] - st.view.cx) * Math.min(1, dt * k); st.view.cy += (target[1] - st.view.cy) * Math.min(1, dt * k); }
// Lawn wipe over a block being bought (tiles flip meadow → lawn in painter order).
function drawWipe(ctx, st) {
  const w = st.wiping; if (!w) return; const sc = st.sc, c0 = w.bx * BLOCK + sc.off, r0 = w.by * BLOCK + sc.off;
  for (let c = c0; c < c0 + BLOCK; c++) for (let r = r0; r < r0 + BLOCK; r++) { const k = ((c - c0) + (r - r0)) / 6; if (k > w.p) continue; const [cx, cy] = sc.grid.center(c, r); diamond(ctx, cx, cy); ctx.fillStyle = LAWN[(c + r) % 2]; ctx.fill(); ctx.strokeStyle = 'rgba(0,0,0,.2)'; ctx.lineWidth = 1; ctx.stroke(); }
}
function stepWipe(st, dt) { const w = st.wiping; if (!w) return; w.p = Math.min(1.01, w.p + dt * 1.2); if (w.p >= 1) { st.sc.buy(w.bx, w.by); st.wiping = null; } }
function sparkle(st, bx, by) { const [x, y] = st.sc.blockCenter(bx, by); for (let i = 0; i < 26; i++) { const a = Math.random() * 6.28, sp = 40 + Math.random() * 90; st.parts.spawn({ x: x + (Math.random() - 0.5) * 120, y: y + (Math.random() - 0.5) * 60, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp - 60, g: 90, ttl: 1 + Math.random(), col: pick(['#FFD54F', '#FFF176', '#FFFFFF', '#81C784']) }); } }
function drawParts(ctx, st) { st.parts.draw(ctx, (c, p) => { c.globalAlpha = Math.max(0, p.life); c.fillStyle = p.col; star(c, p.x, p.y, 4 + 3 * p.life); c.globalAlpha = 1; }); }
// Expand-city mode toggle (rounds two and three).
function setExpand(st, on) { st.expand = on; st.sel = null; st.preview = null; st.signT = {}; if (on) st.sc.frontier().forEach(([bx, by], i) => st.signT[bx + ',' + by] = st.t + i * 0.05); }
