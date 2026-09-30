// Terrain, sky and land-frontier helpers for terrain_sky.html. Builds on
// engine.js: a WorldScene is a Scene whose tiles carry signed world block
// coordinates (land_blocks.dart), so owned land is a set of 4×4 blocks in
// the middle of a large grid and everything else is countryside.
'use strict';
const BLOCK = 4, BLOCK_COST = 600;
const LAWN = ['#7CB342', '#689F38'];
const MEADOW = ['#9CC466', '#93BB5E', '#A3C96B'];
const SCRUB = ['#84AB50', '#7CA24A', '#8DB257'];
const FOREST = ['#5F8C3B', '#578235', '#66943F'];
const TODAY_OUTSIDE = '#9CCC65', TODAY_FRONTIER = 'rgba(102,163,107,.33)';

function hash2(c, r) { let h = (c * 73856093) ^ (r * 19349663); h = Math.imul(h ^ (h >>> 13), 0x5bd1e995); h ^= h >>> 15; return (h >>> 0) / 4294967296; }
function startBlocks() { const o = []; for (let x = -1; x <= 1; x++) for (let y = -1; y <= 1; y++) o.push([x, y]); return o; }
const ring = (bx, by) => Math.max(Math.abs(bx), Math.abs(by));

class WorldScene extends Scene {
  constructor({ blocksAcross = 15, owned, roads = [], buildings = [], sites = [] }) {
    const n = blocksAcross * BLOCK, off = Math.floor(blocksAcross / 2) * BLOCK;
    super({ cols: n, rows: n, roads: roads.map(([c, r]) => [c + off, r + off]), buildings: buildings.map((b) => ({ ...b, col: b.col + off, row: b.row + off })), sites: sites.map((s) => ({ ...s, col: s.col + off, row: s.row + off })) });
    this.off = off; this.owned = new Set((owned || startBlocks()).map(([x, y]) => x + ',' + y));
  }
  blockOf(gc, gr) { return [Math.floor((gc - this.off) / BLOCK), Math.floor((gr - this.off) / BLOCK)]; }
  ownsBlock(bx, by) { return this.owned.has(bx + ',' + by); }
  isOwnedTile(gc, gr) { const [bx, by] = this.blockOf(gc, gr); return this.ownsBlock(bx, by); }
  buy(bx, by) { this.owned.add(bx + ',' + by); }
  frontier() {
    const out = new Map();
    for (const k of this.owned) { const [bx, by] = k.split(',').map(Number); for (const [dx, dy] of DIRD) { const n = [bx + dx, by + dy]; if (!this.ownsBlock(...n)) out.set(n.join(','), n); } }
    return [...out.values()];
  }
  tileRing(gc, gr) { return ring(...this.blockOf(gc, gr)); }
  // Screen centre of a block, and its four diamond corners (N,E,S,W).
  blockCenter(bx, by) { return this.grid.center(bx * BLOCK + this.off + 1.5, by * BLOCK + this.off + 1.5); }
  blockCorners(bx, by) {
    const c0 = bx * BLOCK + this.off, r0 = by * BLOCK + this.off, g = this.grid;
    const [nx, ny] = g.center(c0, r0), [ex, ey] = g.center(c0 + 3, r0), [sx, sy] = g.center(c0 + 3, r0 + 3), [wx, wy] = g.center(c0, r0 + 3);
    return [[nx, ny - HALF_H], [ex + HALF_W, ey], [sx, sy + HALF_H], [wx - HALF_W, wy]];
  }
  blockAt(wx, wy) { const t = this.grid.tileAt(wx, wy); return t ? this.blockOf(...t) : null; }
  // World-px bounding box of owned land (for camera clamps).
  ownedBox(pad = 0) {
    let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
    for (const k of this.owned) { for (const p of this.blockCorners(...k.split(',').map(Number))) { x0 = Math.min(x0, p[0]); y0 = Math.min(y0, p[1]); x1 = Math.max(x1, p[0]); y1 = Math.max(y1, p[1]); } }
    return { x0: x0 - pad, y0: y0 - pad, x1: x1 + pad, y1: y1 + pad };
  }
  // Free owned tile for a w×h footprint, or null.
  freeSpot(w, h) {
    const taken = new Set(); for (const b of this.buildings) for (let c = b.col; c < b.col + b.w; c++) for (let r = b.row; r < b.row + b.h; r++) taken.add(c + ',' + r);
    for (const k of this.roads) taken.add(k);
    const g = this.grid; const cands = [];
    for (let c = 0; c < g.cols - w; c++) for (let r = 0; r < g.rows - h; r++) {
      let ok = true; for (let dc = 0; dc < w && ok; dc++) for (let dr = 0; dr < h && ok; dr++) if (!this.isOwnedTile(c + dc, r + dr) || taken.has((c + dc) + ',' + (r + dr))) ok = false;
      if (ok) cands.push([c, r]);
    }
    return cands.length ? pick(cands) : null;
  }
}

// ---- Ground styles ---------------------------------------------------------
// style: 'today' | 'meadow' | 'density' ; o.frontierWash draws the pale cross.
function drawWorldGround(ctx, sc, o = {}) {
  const g = sc.grid, style = o.style || 'meadow', fr = o.frontierWash ? new Set(sc.frontier().map((b) => b.join(','))) : null;
  if (style === 'today') { ctx.fillStyle = TODAY_OUTSIDE; ctx.fillRect(-4000, -4000, 8000 + g.boardW, 8000 + g.boardH); }
  const vis = o.view ? visibleTiles(sc, o.view) : null;
  for (let c = 0; c < g.cols; c++) for (let r = 0; r < g.rows; r++) {
    if (vis && !vis(c, r)) continue;
    const [cx, cy] = g.center(c, r); const owned = sc.isOwnedTile(c, r);
    if (!owned && style === 'today') { if (fr && fr.has(sc.blockOf(c, r).join(','))) { diamond(ctx, cx, cy); ctx.fillStyle = TODAY_FRONTIER; ctx.fill(); ctx.strokeStyle = 'rgba(0,0,0,.2)'; ctx.lineWidth = 1; ctx.stroke(); } continue; }
    diamond(ctx, cx, cy);
    if (owned) { ctx.fillStyle = LAWN[(c + r) % 2]; ctx.fill(); ctx.strokeStyle = 'rgba(0,0,0,.2)'; ctx.lineWidth = 1; ctx.stroke(); }
    else {
      const rg = sc.tileRing(c, r); const h = hash2(c, r);
      const pal = style === 'density' ? (rg <= 2 ? MEADOW : rg === 3 ? SCRUB : FOREST) : MEADOW;
      ctx.fillStyle = pal[Math.floor(h * pal.length)]; ctx.fill();
      if (fr && fr.has(sc.blockOf(c, r).join(','))) { ctx.fillStyle = 'rgba(255,255,255,.18)'; ctx.fill(); }
      // grass tufts
      if (h > 0.55) { ctx.strokeStyle = 'rgba(40,80,20,.35)'; ctx.lineWidth = 1; const tx = cx + (h - 0.5) * 30, ty = cy + (hash2(r, c) - 0.5) * 12; ctx.beginPath(); ctx.moveTo(tx, ty); ctx.lineTo(tx - 1.5, ty - 4); ctx.moveTo(tx + 2, ty); ctx.lineTo(tx + 3, ty - 4); ctx.stroke(); }
    }
  }
}
function visibleTiles(sc, view) {
  const g = sc.grid, hw = view.W / view.zoom / 2 + TILE_W, hh = view.H / view.zoom / 2 + 120;
  return (c, r) => { const [x, y] = g.center(c, r); return Math.abs(x - view.cx) < hw && Math.abs(y - view.cy) < hh; };
}

// Decorations (trees, bushes, flowers, rocks) outside owned land, as depth-sorted entities.
function makeDecor(sc, o = {}) {
  const out = []; const g = sc.grid; const dens = o.density || ((rg) => rg <= 2 ? 0.10 : 0.10);
  for (let c = 0; c < g.cols; c++) for (let r = 0; r < g.rows; r++) {
    if (sc.isOwnedTile(c, r)) continue;
    const rg = sc.tileRing(c, r); const h = hash2(c * 3 + 1, r * 7 + 2), h2 = hash2(r * 5 + 3, c * 11 + 4);
    const [cx, cy] = g.center(c, r); const jx = (h2 - 0.5) * 22, jy = (hash2(c + 9, r + 9) - 0.5) * 10;
    const pTree = dens(rg);
    if (h < pTree) out.push({ kind: 'tree', c, r, x: cx + jx, y: cy + jy, s: 0.8 + h2 * 0.6, v: Math.floor(h2 * 3) });
    else if (h < pTree + 0.06) out.push({ kind: 'bush', c, r, x: cx + jx, y: cy + jy, s: 0.7 + h2 * 0.5 });
    else if (h < pTree + 0.16 && rg <= 3) out.push({ kind: 'flowers', c, r, x: cx + jx, y: cy + jy, v: Math.floor(h2 * 3) });
    else if (h < pTree + 0.19) out.push({ kind: 'rock', c, r, x: cx + jx, y: cy + jy, s: 0.6 + h2 * 0.6 });
  }
  return out;
}
function decorEntities(decor, sc, view, o = {}) {
  const vis = view ? visibleTiles(sc, view) : () => true; const hide = o.hideBlock;
  return decor.filter((d) => vis(d.c, d.r) && !(hide && hide(...sc.blockOf(d.c, d.r)))).map((d) => ({ depth: d.c + d.r + 0.5, draw: (ctx) => drawDecor(ctx, d, o) }));
}
function drawDecor(ctx, d, o = {}) {
  const { x, y } = d; const dim = o.night || 0;
  if (d.kind === 'tree') {
    const s = d.s; const greens = [['#4E8A2E', '#6BAF3F'], ['#3F7A2A', '#5A9E38'], ['#5B9432', '#7BBE48']][d.v];
    ctx.fillStyle = 'rgba(0,0,0,.18)'; ctx.beginPath(); ctx.ellipse(x + 2, y + 1, 9 * s, 4 * s, 0, 0, 7); ctx.fill();
    ctx.fillStyle = '#6D4C2B'; ctx.fillRect(x - 1.5 * s, y - 10 * s, 3 * s, 10 * s);
    ctx.fillStyle = greens[0]; ctx.beginPath(); ctx.arc(x, y - 15 * s, 9 * s, 0, 7); ctx.fill();
    ctx.fillStyle = greens[1]; ctx.beginPath(); ctx.arc(x - 3 * s, y - 18 * s, 6.5 * s, 0, 7); ctx.arc(x + 4 * s, y - 13 * s, 5.5 * s, 0, 7); ctx.fill();
  } else if (d.kind === 'bush') {
    const s = d.s; ctx.fillStyle = '#5E9A34'; ctx.beginPath(); ctx.ellipse(x, y - 3 * s, 8 * s, 5 * s, 0, 0, 7); ctx.fill();
    ctx.fillStyle = '#74B444'; ctx.beginPath(); ctx.ellipse(x - 2 * s, y - 5 * s, 4 * s, 3 * s, 0, 0, 7); ctx.fill();
  } else if (d.kind === 'flowers') {
    const cols = [['#F48FB1', '#FFF176'], ['#FFFFFF', '#FFD54F'], ['#CE93D8', '#FFF176']][d.v];
    for (let i = 0; i < 4; i++) { ctx.fillStyle = cols[i % 2]; ctx.beginPath(); ctx.arc(x + (i - 1.5) * 5, y - 2 + ((i * 7) % 3) - 1, 1.6, 0, 7); ctx.fill(); }
  } else if (d.kind === 'rock') {
    const s = d.s; ctx.fillStyle = '#9E9E9E'; ctx.beginPath(); ctx.ellipse(x, y - 2 * s, 6 * s, 4 * s, 0, 0, 7); ctx.fill();
    ctx.fillStyle = '#BDBDBD'; ctx.beginPath(); ctx.ellipse(x - 1.5 * s, y - 3.5 * s, 3 * s, 1.8 * s, 0, 0, 7); ctx.fill();
  }
}

// ---- Sky, haze, clouds, glow (screen space) --------------------------------
// The sky is only ever seen where the ground dissolves: a band at the top.
function hazeAlpha(y, H, k = 0.42) { const t = y / (H * k); return t >= 1 ? 0 : Math.pow(1 - t, 1.6); }
function drawHaze(ctx, st, W, H, k = 0.42, strength = 1) {
  const col = st.tod.sky[1]; const g = ctx.createLinearGradient(0, 0, 0, H * k);
  const [r, gg, b] = rgbOf(col);
  for (let i = 0; i <= 8; i++) { const t = i / 8; g.addColorStop(t, `rgba(${r},${gg},${b},${strength * Math.pow(1 - t, 1.6)})`); }
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H * k);
}
function rgbOf(c) { const m = c.match(/\d+/g); return m ? m.slice(0, 3).map(Number) : hex(c); }
function makeClouds(n = 5, W = 620) { const o = []; for (let i = 0; i < n; i++) o.push({ x: (i / n) * W * 1.3 - 60, y: 8 + ((i * 37) % 50), s: 0.7 + ((i * 13) % 7) / 10, v: 6 + (i % 3) * 3 }); return o; }
function drawClouds(ctx, st, W, H, k = 0.42, o = {}) {
  const px = o.parallax || 0, night = st.tod.night;
  for (const c of st.clouds) {
    const x = ((c.x + st.t * c.v - px) % (W * 1.3) + W * 1.3) % (W * 1.3) - 100, y = c.y; const a = hazeAlpha(y + 10, H, k) * (o.alpha ?? 1);
    if (a <= 0.02) continue; ctx.save(); ctx.globalAlpha = a * (0.9 - night * 0.6);
    ctx.fillStyle = night > 0.5 ? '#6f7aa0' : '#ffffff';
    for (const [dx, dy, r] of [[0, 0, 16], [14, -6, 13], [28, 0, 15], [-14, 2, 11], [42, 3, 10]]) { ctx.beginPath(); ctx.ellipse(x + dx * c.s, y + dy * c.s, r * c.s, r * 0.62 * c.s, 0, 0, 7); ctx.fill(); }
    ctx.restore();
  }
}
function drawSunMoonHazed(ctx, st, W, H, k = 0.42) {
  const hour = st.hour; const arc = (t) => [W * (0.1 + 0.8 * t), H * 0.5 - Math.sin(t * Math.PI) * H * 0.45];
  const dayT = (hour - 6) / 12;
  if (dayT > -0.05 && dayT < 1.05) { const [x, y] = arc(dayT); ctx.save(); ctx.globalAlpha = Math.max(0, Math.min(1, hazeAlpha(y, H, k) * 3)); const g = ctx.createRadialGradient(x, y, 0, x, y, 34); g.addColorStop(0, 'rgba(255,248,210,1)'); g.addColorStop(0.35, 'rgba(255,232,150,.7)'); g.addColorStop(1, 'rgba(255,220,120,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, 34, 0, 7); ctx.fill(); ctx.restore(); }
  const nightT = ((hour + 6) % 24) / 12;
  if (nightT > 0 && nightT < 1) { const [x, y] = arc(nightT); ctx.save(); ctx.globalAlpha = Math.max(0, Math.min(1, hazeAlpha(y, H, k) * 3)) * Math.min(1, st.tod.night * 2); ctx.fillStyle = '#f4f1e0'; ctx.beginPath(); ctx.arc(x, y, 10, 0, 7); ctx.fill(); ctx.fillStyle = 'rgba(200,205,225,.5)'; ctx.beginPath(); ctx.arc(x - 3.5, y - 2, 2.6, 0, 7); ctx.arc(x + 3, y + 3.5, 1.8, 0, 7); ctx.fill(); ctx.restore(); }
}
function drawStarsHazed(ctx, st, W, H, k = 0.42) {
  const n = st.tod.night; if (n <= 0.05) return; ctx.save();
  for (let i = 0; i < 70; i++) { const x = ((i * 137.5) % W), y = ((i * 71.3) % (H * k)); const a = hazeAlpha(y, H, k) * n; if (a < 0.03) continue; const tw = 0.5 + 0.5 * Math.sin(st.t * (1 + i % 5) + i); ctx.fillStyle = `rgba(255,255,255,${a * (0.35 + 0.6 * tw)})`; ctx.fillRect(x, y, 1.6, 1.6); }
  ctx.restore();
}
// Warm halo over the city at night, scaled by how much city there is.
function drawCityGlow(ctx, st, W, H, count) {
  const n = st.tod.night; if (n <= 0.05) return; const k = Math.min(1, count / 24) * n;
  const [sx, sy] = worldToScreen(st, ...st.sc.blockCenter(0, 0), W, H);
  ctx.save(); ctx.globalCompositeOperation = 'lighter';
  let g = ctx.createRadialGradient(sx, sy, 0, sx, sy, W * 0.55); g.addColorStop(0, `rgba(255,170,90,${0.22 * k})`); g.addColorStop(0.5, `rgba(255,140,70,${0.08 * k})`); g.addColorStop(1, 'rgba(255,140,70,0)'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  g = ctx.createLinearGradient(0, 0, 0, H * 0.4); g.addColorStop(0, `rgba(255,150,80,${0.28 * k})`); g.addColorStop(1, 'rgba(255,150,80,0)'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H * 0.4);
  ctx.restore();
}
function worldToScreen(st, wx, wy, W, H) { const v = st.view; return [(wx - v.cx) * v.zoom + W / 2, (wy - v.cy) * v.zoom + H / 2]; }

// ---- Frontier affordances --------------------------------------------------
// A wooden "for sale" sign at a world point, constant screen size regardless of zoom.
function drawSign(ctx, x, y, zoom, o = {}) {
  ctx.save(); ctx.translate(x, y); ctx.scale(1 / zoom, 1 / zoom);
  const pop = o.pop ?? 1; ctx.scale(pop, pop);
  ctx.fillStyle = 'rgba(0,0,0,.22)'; ctx.beginPath(); ctx.ellipse(1, 1, 8, 3.5, 0, 0, 7); ctx.fill();
  ctx.fillStyle = '#8D6E63'; ctx.fillRect(-1.5, -22, 3, 22);
  ctx.font = '700 9px "Nunito", system-ui, sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  const w = o.text ? Math.max(38, ctx.measureText(o.text).width + 18) : 38;
  ctx.fillStyle = o.gold ? '#FFE082' : '#C69C6D'; ctx.strokeStyle = o.gold ? '#B8860B' : '#6D4C2B'; ctx.lineWidth = 1.5;
  roundRect(ctx, -w / 2, -38, w, 18, 3); ctx.fill(); ctx.stroke();
  ctx.fillStyle = o.gold ? '#6B4F00' : '#3E2723';
  ctx.fillText(o.text || 'FOR SALE', 0, -29);
  if (o.glint !== undefined) { const p = (Math.sin(o.glint * 3) + 1) / 2; ctx.fillStyle = `rgba(255,255,255,${0.5 + 0.5 * p})`; star(ctx, w / 2 - 3, -40, 3 + 2 * p); }
  ctx.restore();
}
function star(ctx, x, y, r) { ctx.beginPath(); for (let i = 0; i < 8; i++) { const a = i * Math.PI / 4, rr = i % 2 ? r * 0.35 : r; ctx.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr); } ctx.closePath(); ctx.fill(); }
// Survey stakes and string around a block. wash: optional fill.
function drawSurvey(ctx, sc, bx, by, o = {}) {
  const pts = sc.blockCorners(bx, by);
  ctx.save(); ctx.beginPath(); pts.forEach((p, i) => i ? ctx.lineTo(...p) : ctx.moveTo(...p)); ctx.closePath();
  if (o.wash) { ctx.fillStyle = o.wash; ctx.fill(); }
  ctx.setLineDash([6, 5]); ctx.lineDashOffset = -(o.t || 0) * 12; ctx.strokeStyle = o.color || '#F9A825'; ctx.lineWidth = o.width || 2; ctx.stroke(); ctx.setLineDash([]);
  for (const [x, y] of pts) { ctx.fillStyle = '#6D4C2B'; ctx.fillRect(x - 1.5, y - 10, 3, 11); ctx.fillStyle = o.color || '#F9A825'; ctx.fillRect(x - 3, y - 12, 6, 4); }
  ctx.restore();
}
// Hedge along the owned/unowned boundary, with two-tile gates facing purchasable blocks.
function drawHedge(ctx, sc, o = {}) {
  const g = sc.grid; const fr = new Set(sc.frontier().map((b) => b.join(',')));
  for (let c = 0; c < g.cols; c++) for (let r = 0; r < g.rows; r++) {
    if (!sc.isOwnedTile(c, r)) continue;
    const [cx, cy] = g.center(c, r);
    const corners = { N: [cx, cy - HALF_H], E: [cx + HALF_W, cy], S: [cx, cy + HALF_H], W: [cx - HALF_W, cy] };
    const edges = [[1, 0, 'E', 'S', c % BLOCK], [0, 1, 'S', 'W', r % BLOCK], [-1, 0, 'W', 'N', c % BLOCK], [0, -1, 'N', 'E', r % BLOCK]];
    for (const [dc, dr, a, b, along] of edges) {
      if (sc.isOwnedTile(c + dc, r + dr)) continue;
      // which index along the block edge is this tile (0..3)?
      const idx = (dc !== 0) ? ((r - sc.off) % BLOCK + BLOCK) % BLOCK : ((c - sc.off) % BLOCK + BLOCK) % BLOCK;
      const gate = o.gates && fr.has(sc.blockOf(c + dc, r + dr).join(',')) && (idx === 1 || idx === 2);
      const [x0, y0] = corners[a], [x1, y1] = corners[b];
      if (gate) { // posts at the outer ends of the gap
        const isOuter = idx === 1 ? 0 : 1; const px = isOuter ? x1 : x0, py = isOuter ? y1 : y0;
        ctx.fillStyle = '#8D6E63'; ctx.fillRect(px - 2, py - 12, 4, 13); ctx.fillStyle = '#A1887F'; ctx.fillRect(px - 3, py - 13, 6, 3);
        continue;
      }
      for (let i = 0; i < 3; i++) { const t = (i + 0.5) / 3; const x = x0 + (x1 - x0) * t, y = y0 + (y1 - y0) * t; ctx.fillStyle = '#3E7A2B'; ctx.beginPath(); ctx.ellipse(x, y - 3, 7, 5, 0, 0, 7); ctx.fill(); ctx.fillStyle = '#4F9435'; ctx.beginPath(); ctx.ellipse(x - 1, y - 5, 4, 3, 0, 0, 7); ctx.fill(); }
    }
  }
}
// Rejected footprint (the game's red wash) for a w×h ghost at grid col,row.
function drawGhostFootprint(ctx, sc, col, row, w, h, ok) {
  const g = sc.grid; ctx.save(); ctx.globalAlpha = 0.85;
  for (let c = col; c < col + w; c++) for (let r = row; r < row + h; r++) { const [cx, cy] = g.center(c, r); diamond(ctx, cx, cy); ctx.fillStyle = ok ? 'rgba(255,235,59,.4)' : 'rgba(229,57,53,.5)'; ctx.fill(); ctx.strokeStyle = ok ? '#F9A825' : '#B71C1C'; ctx.lineWidth = 2; ctx.stroke(); }
  ctx.restore();
}

// ---- HUD pieces --------------------------------------------------------------
function drawLetter(ctx, W, H, o) {
  const w = Math.min(W - 24, 420), h = 96, x = (W - w) / 2, y = H - h - 12 - (o.lift || 0);
  ctx.save(); ctx.globalAlpha = o.alpha ?? 1; ctx.fillStyle = 'rgba(0,0,0,.18)'; roundRect(ctx, x + 2, y + 4, w, h, 14); ctx.fill();
  ctx.fillStyle = '#FFFDF6'; roundRect(ctx, x, y, w, h, 14); ctx.fill(); ctx.strokeStyle = '#E8DCC0'; ctx.lineWidth = 1.5; ctx.stroke();
  ctx.fillStyle = o.color || '#F48FB1'; ctx.beginPath(); ctx.arc(x + 34, y + 34, 20, 0, 7); ctx.fill();
  ctx.font = '22px system-ui'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillStyle = '#000'; ctx.fillText(o.emoji || '👩‍🌾', x + 34, y + 35);
  ctx.textAlign = 'left'; ctx.fillStyle = '#16302B'; ctx.font = '700 13px "Nunito", system-ui, sans-serif'; ctx.fillText(o.from, x + 64, y + 22);
  ctx.font = '13px "Nunito", system-ui, sans-serif'; ctx.fillStyle = '#3d4f4a'; wrapText(ctx, o.text, x + 64, y + 42, w - 80, 16);
  if (o.button) { const bw = ctx.measureText(o.button).width + 26; ctx.fillStyle = o.buttonColor || '#0E6E62'; roundRect(ctx, x + w - bw - 14, y + h - 32, bw, 24, 12); ctx.fill(); ctx.fillStyle = '#fff'; ctx.font = '700 12px "Nunito", system-ui, sans-serif'; ctx.fillText(o.button, x + w - bw - 1, y + h - 20); }
  ctx.restore();
}
function wrapText(ctx, text, x, y, maxW, lh) { const words = text.split(' '); let line = ''; for (const w of words) { const t = line ? line + ' ' + w : w; if (ctx.measureText(t).width > maxW && line) { ctx.fillText(line, x, y); y += lh; line = w; } else line = t; } ctx.fillText(line, x, y); }
function drawBar(ctx, W, H, text, o = {}) {
  const w = Math.min(W - 24, 420), h = 44, x = (W - w) / 2, y = H - h - 12;
  ctx.save(); ctx.fillStyle = '#FFFFFF'; roundRect(ctx, x, y, w, h, 12); ctx.fill(); ctx.strokeStyle = '#D3DEDA'; ctx.lineWidth = 1.5; ctx.stroke();
  ctx.fillStyle = '#16302B'; ctx.font = '700 13px "Nunito", system-ui, sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle'; ctx.fillText(text, x + 14, y + h / 2);
  let btn = null;
  if (o.button) { const bw = ctx.measureText(o.button).width + 26; ctx.fillStyle = o.disabled ? '#B0BEC5' : '#0E6E62'; roundRect(ctx, x + w - bw - 8, y + 8, bw, h - 16, 12); ctx.fill(); ctx.fillStyle = '#fff'; ctx.font = '700 12px "Nunito", system-ui, sans-serif'; ctx.fillText(o.button, x + w - bw + 5, y + h / 2); btn = { x: x + w - bw - 8, y: y + 8, w: bw, h: h - 16 }; }
  ctx.restore(); return btn;
}
function drawFolderBar(ctx, W, H, items, o = {}) {
  const h = 52, y = H - h; ctx.save(); ctx.globalAlpha = o.alpha ?? 1; ctx.fillStyle = '#FFFFFF'; ctx.fillRect(0, y, W, h); ctx.fillStyle = '#D3DEDA'; ctx.fillRect(0, y, W, 1.5);
  const n = items.length, cell = Math.min(72, W / n); const x0 = (W - cell * n) / 2;
  items.forEach((it, i) => { const x = x0 + i * cell + cell / 2; ctx.fillStyle = it.on ? '#E0F2F1' : '#F1F5F4'; roundRect(ctx, x - 22, y + 8, 44, 36, 10); ctx.fill(); if (it.on) { ctx.strokeStyle = '#0E6E62'; ctx.lineWidth = 2; ctx.stroke(); } ctx.font = '20px system-ui'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillStyle = '#000'; ctx.fillText(it.emoji, x, y + 27); });
  ctx.restore();
}
function drawHand(ctx, x, y, t) { const b = Math.sin(t * 6) > 0 ? 0 : 4; ctx.save(); ctx.font = '30px system-ui'; ctx.textAlign = 'center'; ctx.textBaseline = 'top'; ctx.shadowColor = 'rgba(0,0,0,.35)'; ctx.shadowBlur = 6; ctx.fillStyle = '#000'; ctx.fillText('👆', x + 4, y + 6 + b); ctx.restore(); }
function label(ctx, text, x, y) { ctx.font = '600 12px "Nunito", system-ui, sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle'; const w = ctx.measureText(text).width + 16; ctx.fillStyle = 'rgba(16,25,23,.72)'; roundRect(ctx, x, y, w, 22, 11); ctx.fill(); ctx.fillStyle = '#fff'; ctx.fillText(text, x + 8, y + 11); return w; }
function fmtHour(h) { const hh = Math.floor(h) % 24, mm = Math.floor((h % 1) * 60); const ap = hh >= 12 ? 'pm' : 'am'; return `${((hh + 11) % 12) + 1}:${String(mm).padStart(2, '0')} ${ap}`; }
function drawCoins(ctx, W, coins) { label(ctx, `🪙 ${coins}`, W - 84, 10); }
function fmtCoins(n) { return '🪙 ' + n; }
