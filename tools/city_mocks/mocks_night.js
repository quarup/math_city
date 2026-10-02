// Night-lights round (night_lights.html): windows by the hour, headlights, street lamps.
// Needs sprites.js (with the vehicle + lit bundles), engine.js, terrain.js, mocks_common.js.
'use strict';

// ---- Scene: a few streets, homes, two shops, a hospital, a park -----------------
const NIGHT_TOWN = () => ({
  cols: 9, rows: 8,
  roads: [...ROW(2, 0, 8), ...ROW(6, 0, 8), ...COL(1, 2, 6), ...COL(5, 2, 6)],
  buildings: [
    B('apartment_v1', 2, 0), B('duplex_v1', 6, 1), B('bakery_v1', 8, 0),
    B('single_home_v1', 2, 3), B('single_home_v1', 3, 3), B('coffee_shop_v1', 4, 3),
    B('park_v1', 2, 4), B('single_home_v1', 4, 4), B('single_home_v1', 4, 5),
    B('hospital_v1', 6, 3),
    B('single_home_v1', 2, 7), B('duplex_v1', 3, 7), B('single_home_v1', 6, 7), B('coffee_shop_v1', 7, 7),
  ],
});
const nightGround = (ctx, sc) => {
  const g = sc.grid;
  for (let c = 0; c < g.cols; c++) for (let r = 0; r < g.rows; r++) { const [cx, cy] = g.center(c, r); diamond(ctx, cx, cy); ctx.fillStyle = MEADOW[Math.floor(hash2(c, r) * 3)]; ctx.fill(); }
  drawPadsRoads(ctx, sc);
};
// Ground point of fractional tile offsets from a tile centre (east, south), lifted z px.
const gp = (sc, c, r, de = 0, ds = 0, z = 0) => { const [x, y] = sc.grid.center(c, r); return [x + DIRV[0][0] * de + DIRV[1][0] * ds, y + DIRV[0][1] * de + DIRV[1][1] * ds - z]; };

// ---- Window schedules (port of lib/domain/city/window_lights.dart) --------------
function drawHash(seed, index, salt) {
  let h = (Math.imul(seed, 0x9E3779B1) ^ Math.imul(index, 0x85EBCA6B) ^ Math.imul(salt, 0xC2B2AE35)) >>> 0;
  h = Math.imul(h ^ (h >>> 15), 0x2C1B3C6D) >>> 0; h = Math.imul(h ^ (h >>> 12), 0x297A2D39) >>> 0; h ^= h >>> 15;
  return (h >>> 0) / 4294967296;
}
const PROFILE = { single_home_v1: 'home', duplex_v1: 'home', apartment_v1: 'home', coffee_shop_v1: 'shop', bakery_v1: 'shop', hospital_v1: 'civic', park_v1: 'venue' };
function windowHours(seed, index, profile, glow) {
  const r = (s) => drawHash(seed, index, s), b = (s) => drawHash(seed, -1, s);
  if (glow) { const close = { home: 22 + b(1), shop: 21 + b(1) * 1.5, office: 20.5 + b(1) * 1.5, civic: 23 + b(1) * 0.75, venue: 22.75 + b(1) }[profile]; return { on: 16.9 + b(2) * 0.3 + r(3) * 0.1, off: close }; }
  if (profile === 'home') { if (r(1) < 0.12) return null; const early = r(2) < 0.35; return { on: 17.25 + r(3) * 2.75, off: 21 + r(4) * 2.5, mOn: early ? 5.6 + r(5) * 0.9 : null, mOff: early ? 7 + r(6) * 0.8 : null }; }
  if (profile === 'shop') return { on: 16.9 + b(3) * 0.4 + r(3) * 0.15, off: 20.5 + b(4) * 1.5 + r(4) * 0.2 };
  if (profile === 'civic') { const early = r(2) < 0.5; return { on: 16.9 + r(3), off: 22.5 + r(4) * 1.25, mOn: early ? 5.6 + r(5) * 0.6 : null, mOff: early ? 7.2 + r(6) * 0.6 : null }; }
  return { on: 16.9 + b(3) * 0.3 + r(3) * 0.4, off: 22.5 + b(4) * 0.75 + r(4) * 0.5 };
}
const FADE_H = 0.05;
const spell = (h, on, off) => (off <= on || h <= on || h >= off) ? 0 : Math.min(1, (h - on) / FADE_H, (off - h) / FADE_H);
function windowLight(hour, hrs) { if (!hrs || hour < 5.5) return 0; let v = spell(hour, hrs.on, hrs.off); if (hrs.mOn != null) v = Math.max(v, spell(hour, hrs.mOn, hrs.mOff)); return v; }

// ---- The light layer: lights over the tinted scene, hidden by what stands in front
let LAYER = null;
function nightPass(ctx, st, lights) {
  const cv = ctx.canvas; if (!LAYER) LAYER = document.createElement('canvas');
  if (LAYER.width !== cv.width || LAYER.height !== cv.height) { LAYER.width = cv.width; LAYER.height = cv.height; }
  const l = LAYER.getContext('2d'); l.setTransform(1, 0, 0, 1, 0, 0); l.clearRect(0, 0, cv.width, cv.height); l.setTransform(ctx.getTransform());
  const k = Math.min(1, Math.max(0, (Math.max(st.tod.night, st.tod.dusk * 0.45) - 0.08) / 0.22));
  if (k <= 0.02) return;
  const sc = st.sc, items = [...lights];
  sc.buildings.forEach((b, i) => items.push({ depth: sc.depthOf(b), draw: (c) => {
    const bb = sc.spriteBox(b);
    c.globalCompositeOperation = 'destination-out'; c.drawImage(IMG[b.id], bb.x, bb.y, bb.W, bb.H); c.globalCompositeOperation = 'source-over';
    const L = NIGHT_LIGHTS[b.id], lit = IMG['lit_' + b.id]; if (!L || !lit || st.noWindows) return;
    L.r.forEach((reg, j) => {
      const a = (st.allWindows ? 1 : windowLight(st.hour, windowHours(i + 1, j, PROFILE[b.id] || 'home', reg.k === 'g'))) * k; if (a <= 0.01) return;
      c.save(); c.beginPath(); const p = reg.p; c.moveTo(bb.x + p[0] * SCALE, bb.y + p[1] * SCALE); for (let q = 2; q < p.length; q += 2) c.lineTo(bb.x + p[q] * SCALE, bb.y + p[q + 1] * SCALE); c.closePath();
      c.globalAlpha = a; c.shadowColor = 'rgba(255,216,144,.9)'; c.shadowBlur = 5 * st.view.zoom; c.fillStyle = 'rgba(255,216,144,.4)'; c.fill(); c.shadowBlur = 0; c.shadowColor = 'transparent';
      c.clip(); c.drawImage(lit, bb.x, bb.y, bb.W, bb.H); c.restore();
    });
  } }));
  items.sort((a, b) => a.depth - b.depth); for (const it of items) { l.save(); l.globalAlpha = k; it.draw(l); l.restore(); }
  ctx.save(); ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.drawImage(LAYER, 0, 0); ctx.restore();
}

// ---- Cars: the shipped sprites, with lights -------------------------------------
const CAR_DIM = { hatchback: [0.42, 0.22], sedan: [0.46, 0.24], taxi: [0.46, 0.24], pickup: [0.5, 0.24], bus: [0.9, 0.28], police_car: [0.46, 0.24] };
function addNightCars(st, kinds) {
  const tiles = [...st.sc.roads].map((s) => s.split(',').map(Number)); st.cars = [];
  kinds.forEach((kind, i) => { const [c, r] = tiles[(i * 7 + 3) % tiles.length]; const dirs = st.sc.roadNeighbours(c, r); const m = new Mover(st.sc, c, r, dirs[i % dirs.length], 0.5 + (i % 3) * 0.08, 5.5); m.kind = kind; m.t = (i * 0.37) % 1; m.held = 0; st.cars.push(m); });
}
function stepNightCars(st, dt) {
  for (const m of st.cars) {
    const [x, y] = m.pos(); const u = UNIT[m.dir]; let blocked = false;
    for (const o of st.cars) { if (o === m) continue; const [ox, oy] = o.pos(); const dx = ox - x, dy = oy - y; const ahead = dx * u[0] + dy * u[1], side = Math.abs(dx * u[1] - dy * u[0]); if (ahead > 3 && ahead < 24 && side < 7) blocked = true; }
    if (blocked && m.held < 2.5) { m.held += dt; continue; } m.held = blocked ? m.held : 0; m.step(dt);
  }
}
// A point on the car: a tiles forward, b tiles to its right, z px up.
function carPoint(m, a, b, z = 0) { const [x, y] = m.pos(); const A = DIRV[m.dir], Bv = DIRV[(m.dir + 1) % 4]; return [x + A[0] * a + Bv[0] * b, y + A[1] * a + Bv[1] * b - z]; }
function carEntities(st) {
  return st.cars.map((m) => ({ depth: m.depth() + 0.4, draw: (ctx) => { const im = IMG[`veh_${m.kind}_h${m.dir * 2}`]; const [x, y] = m.pos(); const W = im.width * SCALE, H = im.height * SCALE; ctx.drawImage(im, x - W / 2, y - H / 2, W, H); } }));
}
const WARM_BEAM = [255, 240, 196];
function dot(c, p, r, core, halo, haloR) { const g = c.createRadialGradient(p[0], p[1], 0, p[0], p[1], haloR); g.addColorStop(0, halo); g.addColorStop(1, halo.replace(/[\d.]+\)$/, '0)')); c.fillStyle = g; c.beginPath(); c.arc(p[0], p[1], haloR, 0, 7); c.fill(); c.fillStyle = core; c.beginPath(); c.arc(p[0], p[1], r, 0, 7); c.fill(); }
// A beam lying on the road: a quad in the car's tile space, fading along its length, soft-edged.
function beam(c, m, a0, a1, b0, w0, b1, w1, alpha, zoom) {
  const p = [carPoint(m, a0, b0 - w0), carPoint(m, a0, b0 + w0), carPoint(m, a1, b1 + w1), carPoint(m, a1, b1 - w1)];
  const s = carPoint(m, a0, b0), e = carPoint(m, a1, b1); const g = c.createLinearGradient(s[0], s[1], e[0], e[1]);
  const col = WARM_BEAM.join(','); g.addColorStop(0, `rgba(${col},${alpha})`); g.addColorStop(0.55, `rgba(${col},${alpha * 0.42})`); g.addColorStop(1, `rgba(${col},0)`);
  c.save(); c.filter = `blur(${1.4 * zoom}px)`; c.fillStyle = g; c.beginPath(); c.moveTo(...p[0]); for (const q of p.slice(1)) c.lineTo(...q); c.closePath(); c.fill(); c.restore();
}
// style: 'fog' | 'dots' | 'beam' | 'twin' | 'low' | 'full'
function carLights(st, style, o = {}) {
  const out = [];
  for (const m of st.cars) {
    const [L, Wd] = CAR_DIM[m.kind]; const A = DIRV[m.dir]; const facing = A[1] > 0; // the nose points down-screen: we see its lamps
    const fl = [carPoint(m, L / 2 - 0.02, -Wd * 0.32, 3.2), carPoint(m, L / 2 - 0.02, Wd * 0.32, 3.2)];
    const tl = [carPoint(m, -L / 2 + 0.02, -Wd * 0.34, 3.4), carPoint(m, -L / 2 + 0.02, Wd * 0.34, 3.4)];
    const z = st.view.zoom, braking = m.held > 0;
    if (style === 'fog') {
      out.push({ depth: m.depth() + 0.5, draw: (c) => { c.globalCompositeOperation = 'lighter'; const u = UNIT[m.dir]; for (const p of fl) { const g = c.createRadialGradient(p[0], p[1], 0, p[0] + u[0] * 14, p[1] + u[1] * 14, 22); g.addColorStop(0, 'rgba(255,240,180,.55)'); g.addColorStop(1, 'rgba(255,240,180,0)'); c.fillStyle = g; c.beginPath(); c.arc(p[0] + u[0] * 12, p[1] + u[1] * 12, 22, 0, 7); c.fill(); c.fillStyle = '#fff6c8'; c.beginPath(); c.arc(p[0], p[1], 1.6, 0, 7); c.fill(); } for (const p of tl) { c.fillStyle = '#ff4a3a'; c.beginPath(); c.arc(p[0], p[1], 1.4, 0, 7); c.fill(); } } });
      continue;
    }
    // Ground light first (it lies under the car), lamps after (they sit on it).
    if (style === 'beam' || style === 'full') out.push({ depth: m.depth() + 0.1, draw: (c) => beam(c, m, L / 2, L / 2 + (o.reach ?? 0.95), 0, Wd * 0.42, 0, 0.36, o.alpha ?? 0.5, z) });
    if (style === 'twin') out.push({ depth: m.depth() + 0.1, draw: (c) => { for (const s of [-1, 1]) beam(c, m, L / 2, L / 2 + 1.0, s * Wd * 0.32, 0.03, s * Wd * 0.62, 0.12, 0.6, z); } });
    if (style === 'low') out.push({ depth: m.depth() + 0.1, draw: (c) => beam(c, m, L / 2, L / 2 + 0.5, 0, Wd * 0.45, 0, 0.3, 0.55, z) });
    if (style === 'full' && braking) out.push({ depth: m.depth() + 0.1, draw: (c) => { const p = [carPoint(m, -L / 2, -Wd * 0.45), carPoint(m, -L / 2, Wd * 0.45), carPoint(m, -L / 2 - 0.28, Wd * 0.6), carPoint(m, -L / 2 - 0.28, -Wd * 0.6)]; const s = carPoint(m, -L / 2, 0), e = carPoint(m, -L / 2 - 0.28, 0); const g = c.createLinearGradient(s[0], s[1], e[0], e[1]); g.addColorStop(0, 'rgba(255,40,30,.5)'); g.addColorStop(1, 'rgba(255,40,30,0)'); c.save(); c.filter = `blur(${1.2 * z}px)`; c.fillStyle = g; c.beginPath(); c.moveTo(...p[0]); for (const q of p.slice(1)) c.lineTo(...q); c.closePath(); c.fill(); c.restore(); } });
    out.push({ depth: m.depth() + 0.5, draw: (c) => {
      if (facing) for (const p of fl) dot(c, p, 1.25, '#fffbe6', 'rgba(255,244,200,.85)', style === 'dots' ? 5 : 3.6);
      else for (const p of tl) dot(c, p, braking && style === 'full' ? 1.5 : 1.1, braking && style === 'full' ? '#ff5a4a' : '#e0241c', `rgba(255,50,40,${braking && style === 'full' ? 0.9 : 0.6})`, braking && style === 'full' ? 5 : 3);
      if (style === 'full' && m.kind === 'police_car') { const on = Math.floor(st.t * 5) % 2 === 0; const p = carPoint(m, -0.02, 0, 10.5); dot(c, p, 1.5, on ? '#ff4b4b' : '#4b86ff', on ? 'rgba(255,60,60,.8)' : 'rgba(70,130,255,.8)', 8); }
    } });
  }
  return out;
}

// ---- Street lamps ----------------------------------------------------------------
// Where lamps stand: {c, r, e, s} tile + east/south offsets on the sidewalk, and the along-road axis.
function lampSpots(sc, mode) {
  const out = [];
  for (const key of sc.roads) {
    const [c, r] = key.split(',').map(Number); const n = sc.roadNeighbours(c, r);
    const ew = n.includes(0) && n.includes(2) && n.length === 2, ns = n.includes(1) && n.includes(3) && n.length === 2;
    if (mode === 'corners') { if (n.length >= 3) for (const [e, s] of [[-0.41, -0.41], [0.41, -0.41], [0.41, 0.41], [-0.41, 0.41]]) { if (!sc.isRoad(c + Math.sign(e), r) || !sc.isRoad(c, r + Math.sign(s))) out.push({ c, r, e, s, axis: 0 }); } continue; }
    if (!ew && !ns) continue;
    const idx = ew ? c : r, side = (idx >> 1) % 2 ? 1 : -1;
    if (mode === 'dense') { for (const a of [-0.25, 0.25]) for (const sd of [-1, 1]) out.push(ew ? { c, r, e: a, s: 0.41 * sd, axis: 0 } : { c, r, e: 0.41 * sd, s: a, axis: 1 }); continue; }
    if (idx % 2) continue;
    const sides = mode === 'both' ? [-1, 1] : [side];
    for (const sd of sides) out.push(ew ? { c, r, e: 0, s: 0.41 * sd, axis: 0 } : { c, r, e: 0.41 * sd, s: 0, axis: 1 });
  }
  return out;
}
const lampOn = (st, sp) => { const h = st.hour, onAt = 17.55 + hash2(sp.c * 3 + 1, sp.r * 5 + 2) * 0.8, offAt = 6.3 + hash2(sp.r, sp.c) * 0.4; if (h >= onAt) return Math.min(1, (h - onAt) / 0.04); return h < offAt ? 1 : 0; };
// A pool of light lying on the ground: an ellipse of rE × rS tiles, drawn in tile space so it sits flat.
function groundPool(c, sc, sp, de, ds, rE, rS, rgb, alpha) {
  const [x, y] = gp(sc, sp.c, sp.r, de, ds);
  c.save(); c.transform(DIRV[0][0], DIRV[0][1], DIRV[1][0], DIRV[1][1], x, y); c.scale(rE, rS);
  const g = c.createRadialGradient(0, 0, 0, 0, 0, 1); g.addColorStop(0, `rgba(${rgb},${alpha})`); g.addColorStop(0.45, `rgba(${rgb},${alpha * 0.5})`); g.addColorStop(1, `rgba(${rgb},0)`);
  c.fillStyle = g; c.beginPath(); c.arc(0, 0, 1, 0, 7); c.fill(); c.restore();
}
const WARM = '255,214,150', AMBER = '255,190,110', COOL = '222,236,255';
const POST = '#2d3338';
function drawPost(ctx, p, style, on, sp, sc) {
  const [x, y] = p; ctx.lineCap = 'round';
  const glass = on > 0.5 ? '#fff3c4' : '#aab2b9';
  if (style === 'pole') { ctx.strokeStyle = '#2f3436'; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x, y - 22); ctx.stroke(); ctx.fillStyle = on > 0.5 ? '#fff1b8' : '#8a8f94'; ctx.beginPath(); ctx.arc(x, y - 23, 2.2, 0, 7); ctx.fill(); return [x, y - 23]; }
  if (style === 'globe') { ctx.fillStyle = POST; ctx.fillRect(x - 1.6, y - 2.5, 3.2, 2.5); ctx.strokeStyle = POST; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x, y - 17); ctx.stroke(); ctx.fillStyle = POST; ctx.fillRect(x - 1.8, y - 18.2, 3.6, 1.4); ctx.fillStyle = glass; ctx.beginPath(); ctx.arc(x, y - 20.8, 2.9, 0, 7); ctx.fill(); ctx.strokeStyle = 'rgba(30,36,40,.55)'; ctx.lineWidth = 0.6; ctx.stroke(); return [x, y - 20.8]; }
  if (style === 'lantern') { ctx.fillStyle = POST; ctx.fillRect(x - 1.7, y - 3, 3.4, 3); ctx.strokeStyle = POST; ctx.lineWidth = 1.4; ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x, y - 16.5); ctx.stroke(); ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(x - 2.6, y - 14.6); ctx.lineTo(x + 2.6, y - 14.6); ctx.stroke();
    ctx.fillStyle = glass; ctx.beginPath(); ctx.moveTo(x - 1.6, y - 16.5); ctx.lineTo(x + 1.6, y - 16.5); ctx.lineTo(x + 2.5, y - 21.4); ctx.lineTo(x - 2.5, y - 21.4); ctx.closePath(); ctx.fill(); ctx.strokeStyle = POST; ctx.lineWidth = 0.7; ctx.stroke();
    ctx.fillStyle = POST; ctx.beginPath(); ctx.moveTo(x - 3.1, y - 21.4); ctx.lineTo(x + 3.1, y - 21.4); ctx.lineTo(x, y - 24.4); ctx.closePath(); ctx.fill(); ctx.fillRect(x - 0.5, y - 25.6, 1, 1.4); return [x, y - 19]; }
  if (style === 'cobra') { // tall post, an arm reaching over the road
    const [rx, ry] = gp(sc, sp.c, sp.r, sp.e * 0.3, sp.s * 0.3, 27);
    ctx.strokeStyle = '#3a4046'; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x, y - 24); ctx.quadraticCurveTo(x, y - 28.5, (x + rx) / 2, (y - 27.5 + ry) / 2 - 1); ctx.lineTo(rx, ry); ctx.stroke();
    ctx.fillStyle = on > 0.5 ? '#eef6ff' : '#8f979e'; ctx.beginPath(); ctx.ellipse(rx, ry + 0.6, 2.6, 1.2, 0, 0, 7); ctx.fill(); return [rx, ry + 0.8]; }
  if (style === 'bollard') { ctx.fillStyle = '#3a4046'; ctx.fillRect(x - 1.3, y - 6, 2.6, 6); ctx.fillStyle = glass; ctx.fillRect(x - 1.3, y - 5.4, 2.6, 1.8); return [x, y - 4.5]; }
  return [x, y - 20];
}
function headHalo(c, h, rgb, r, alpha) { const g = c.createRadialGradient(h[0], h[1], 0, h[0], h[1], r); g.addColorStop(0, `rgba(${rgb},${alpha})`); g.addColorStop(0.35, `rgba(${rgb},${alpha * 0.35})`); g.addColorStop(1, `rgba(${rgb},0)`); c.fillStyle = g; c.beginPath(); c.arc(h[0], h[1], r, 0, 7); c.fill(); }
// One lamp design → {entities, lights}. o: {post, mode, rgb, pool:[rAlong, rAcross], poolAt (0..1 towards the road), alpha, halo, cone, legacy}
function lampSet(st, o) {
  const sc = st.sc; st.lampSpots = st.lampSpots || lampSpots(sc, o.mode || 'alternate'); const ents = [], lights = [];
  for (const sp of st.lampSpots) {
    const on = lampOn(st, sp); const depth = sp.c + sp.r + sp.e + sp.s; const base = gp(sc, sp.c, sp.r, sp.e, sp.s); let head = [base[0], base[1] - 20];
    if (o.post) ents.push({ depth: depth + 0.45, draw: (ctx) => { head = drawPost(ctx, base, o.post, on, sp, sc); } });
    if (on <= 0) continue;
    const flick = on < 1 ? 0.5 + 0.5 * Math.sin(st.t * 40 + sp.c) : 1, a = (o.alpha ?? 0.5) * on * flick;
    const k = o.poolAt ?? 0.8; const [rA, rX] = o.pool || [0.42, 0.34]; const rE = sp.axis === 0 ? rA : rX, rS = sp.axis === 0 ? rX : rA;
    if (o.legacy) { lights.push({ depth: depth + 0.5, draw: (c) => { c.globalCompositeOperation = 'lighter'; const g = c.createRadialGradient(base[0], base[1] + 2, 0, base[0], base[1] + 2, 30); g.addColorStop(0, 'rgba(255,220,140,.5)'); g.addColorStop(1, 'rgba(255,220,140,0)'); c.fillStyle = g; c.beginPath(); c.ellipse(base[0], base[1] + 2, 30, 16, 0, 0, 7); c.fill(); } }); continue; }
    lights.push({ depth: depth - 0.35, draw: (c) => groundPool(c, sc, sp, sp.e * k, sp.s * k, rE, rS, o.rgb || WARM, a) });
    if (o.cone) lights.push({ depth: depth + 0.46, draw: (c) => { const [gx, gy] = gp(sc, sp.c, sp.r, sp.e * k, sp.s * k); const hw = rE * 26; const g = c.createLinearGradient(head[0], head[1], gx, gy); g.addColorStop(0, `rgba(${o.rgb || WARM},${0.26 * on})`); g.addColorStop(1, `rgba(${o.rgb || WARM},0)`); c.fillStyle = g; c.beginPath(); c.moveTo(head[0] - 1.5, head[1]); c.lineTo(head[0] + 1.5, head[1]); c.lineTo(gx + hw, gy); c.lineTo(gx - hw, gy); c.closePath(); c.fill(); } });
    if (o.post && o.halo !== 0) lights.push({ depth: depth + 0.5, draw: (c) => { headHalo(c, head, o.rgb || WARM, o.halo || 7, 0.95 * on * flick); c.fillStyle = `rgba(255,252,236,${on})`; c.beginPath(); c.arc(head[0], head[1], o.post === 'bollard' ? 0.9 : 1.5, 0, 7); c.fill(); } });
  }
  return { ents, lights };
}

// ---- Mock plumbing ----------------------------------------------------------------
const NV = (zoom, c, r) => { const g = new Grid(9, 8); const [cx, cy] = g.center(c, r); return { zoom, cx, cy }; };
const HOUR_CTRL = { range: [16.5, 23.9, 0.05], label: 'Hour', get: (st) => st.hour, set: (st, v) => { st.hour = v; st.play = false; } };
const nightHud = (ctx, st) => label(ctx, fmtHour(st.hour), 10, 10);
function nightMock(m) {
  MOCKS.push({ art: 'I draw it', perf: 'Light', effort: 'S', noWindows: true, terrain: nightGround, hud: nightHud, scene: NIGHT_TOWN(), ...m,
    lightPass: (ctx, st) => nightPass(ctx, st, m.lights ? m.lights(st) : []) });
}

// ============ W. WINDOWS BY THE HOUR ===============================================
nightMock({
  id: 'w1', section: 'Windows by the hour', title: 'An evening and a morning, every window on its own clock', tier: 'Recommend', effort: 'M',
  notes: `This is the schedule now in the app, running fast: 4 pm round to 8 am. Homes come home over two and a half hours and go to bed one window at a time, so a street fills in and empties out instead of flipping. The two shops switch on as one at dusk and close as one. The hospital stays up late. <strong>Nothing is lit between midnight and 5:30</strong>; before dawn a third of the homes show a light for the early risers. Each window draws its hours from a hash of its building and its own index, so two identical houses never switch together. The regions are the ones the detector proposed; you correct them in the review page.`,
  view: NV(1.62, 4, 3.6), hourStart: 16.5,
  setup: (st) => { st.play = true; addNightCars(st, ['hatchback', 'sedan', 'taxi']); },
  controls: [{ label: 'Play / pause', run: (st) => st.play = !st.play }, { range: [0, 23.9, 0.05], label: 'Hour', get: (st) => st.hour, set: (st, v) => { st.hour = v; st.play = false; } }, { label: '2 am', run: (st) => { st.hour = 2; st.play = false; } }, { label: '7:30 pm', run: (st) => { st.hour = 19.5; st.play = false; } }],
  update: (st, dt) => { if (st.play) { st.hour += dt * 0.5; if (st.hour >= 24) st.hour -= 24; if (st.hour > 8 && st.hour < 16) st.hour = 16; } stepNightCars(st, dt); },
  entities: (st) => carEntities(st), lights: (st) => carLights(st, 'full'),
});

// ============ H. HEADLIGHTS ========================================================
const carMock = (id, title, tier, notes, style, extra = {}) => nightMock({
  id, section: 'Headlights', title, tier, notes, view: NV(2.1, 3, 5), hourStart: 21.2,
  setup: (st) => addNightCars(st, ['hatchback', 'sedan', 'taxi', 'pickup', 'police_car', 'bus']),
  update: (st, dt) => stepNightCars(st, dt), entities: (st) => carEntities(st), lights: (st) => carLights(st, style, extra), controls: [HOUR_CTRL],
});
carMock('h1', 'The early mock: two blobs of fog', 'Baseline',
  `What you remembered. Each headlight was a 22 px radial gradient floating in front of the lamp and added to the scene. It has no direction and no ground: it lights the air, so it reads as fog, and it spills over buildings and kerbs alike. Kept here only to compare against.`, 'fog');
carMock('h2', 'Lamps only: two points of light, nothing on the road', 'Nice',
  `The quietest answer. Two small warm lamps at the nose with a tight halo, seen only when the car faces you; two red tail lamps when it drives away. No beam at all. At the game's zoom this is most of what an eye picks up from a real car at night, and it can never smear.`, 'dots');
carMock('h3', 'One soft beam lying on the road', 'Nice',
  `The light is a shape <em>on the ground</em>: a quad in the car's own lane space, as wide as the bumper at the nose and fanning to about a third of a tile nearly a tile ahead, brightest at the car and gone at the far end. Because it is drawn in road space it foreshortens with the projection and turns with the car, and because it sits in the light layer the building in front of it hides it. The lamps themselves are the small points from H2.`, 'beam');
carMock('h4', 'Twin beams: one per lamp', 'Nice',
  `The same idea split in two narrow fans. Crisper and more "headlight", and it shows the gap between the lamps on the big vehicles. On the small cars the two fans mostly merge and it reads busier than H3 for little gain.`, 'twin');
carMock('h5', 'Dipped lights: a short pool just ahead', 'Nice',
  `Town driving: the beam reaches only half a tile. Calmer in a busy street and it keeps the light off the car in front. Loses the sense of speed on the long roads out of town.`, 'low');
carMock('h6', 'Beam, lamps, tail lamps that brighten when braking, and the patrol car', 'Recommend',
  `What I would build: H3's ground beam at a slightly lower strength, lamps at the nose, red tail lamps, and when a car holds behind another its tail lamps flare and throw a short red wash on the road behind it. The patrol car's roof bar alternates red and blue. All of it is geometry from the car's length, width and heading, so the sixteen vehicle kinds need no per-sprite art, only a lamp-height tweak for the bus and the trucks.`, 'full', { alpha: 0.42 });

// ============ L. STREET LAMPS ======================================================
const lampMock = (id, title, tier, notes, o, extra = {}) => nightMock({
  id, section: 'Street lamps', title, tier, notes, view: NV(1.9, 3, 5), hourStart: 21,
  setup: (st) => { addNightCars(st, ['hatchback', 'taxi', 'sedan']); st.allWindows = false; },
  update: (st, dt) => { if (st.play) { st.hour += dt * 0.35; if (st.hour > 23.5) st.hour = 16.8; } stepNightCars(st, dt); st.lamp = lampSet(st, o); },
  entities: (st) => [...carEntities(st), ...(st.lamp ? st.lamp.ents : []), ...(extra.ents ? extra.ents(st) : [])],
  lights: (st) => [...carLights(st, 'full', { alpha: 0.42 }), ...(st.lamp ? st.lamp.lights : []), ...(extra.lights ? extra.lights(st) : [])],
  controls: [HOUR_CTRL, { label: 'Dusk time-lapse', run: (st) => { st.play = !st.play; if (st.play) st.hour = 16.8; } }],
});
lampMock('l1', 'The early mock: a pole and a round glow', 'Baseline',
  `The one that looked meh. A grey line with a dot, and a 30 px glow drawn round its foot. The glow is a circle on the screen and not on the ground, it is the same size as a house, and it has no edge, so the whole street goes milky.`, { post: 'pole', legacy: true });
lampMock('l2', 'Globe lamp: a dark post, a warm globe, a pool on the pavement', 'Recommend',
  `A slim charcoal post with a foot and a round opal globe, on alternating sides of the street every other tile. The light is a pool that <em>lies on the ground</em>, drawn in tile space so it is the right ellipse for the projection: bright under the lamp, gone within four tenths of a tile, mostly on the pavement with a little spilling on the asphalt. A tight halo sits round the globe itself. Each lamp comes on at its own moment across dusk with a brief flicker.`, { post: 'globe', pool: [0.42, 0.34], alpha: 0.5 });
lampMock('l3', 'Victorian lantern: a caged lamp with a cap', 'Recommend',
  `The same pool with a more "old town" fitting: a lantern cage with a crossbar and a pointed cap, a slightly warmer amber. Suits the painted houses and the town hall better than anything modern; the cap gives the post a silhouette by day, which the globe lacks.`, { post: 'lantern', rgb: AMBER, pool: [0.4, 0.32], alpha: 0.55 });
lampMock('l4', 'Road lamp: a tall arm over the lane, cool white', 'Nice',
  `A tall grey post with an arm reaching over the road and a flat LED head. The pool sits on the asphalt, longer along the road than across it, in a cooler white. Reads as a modern road and would suit the two roads that leave town; in the old centre it is colder than the houses.`, { post: 'cobra', rgb: COOL, pool: [0.6, 0.3], poolAt: 0.3, alpha: 0.42, halo: 5 });
lampMock('l5', 'Lanterns on both sides', 'Nice',
  `L3 on both pavements. Twice the posts: the street becomes a lit corridor and the houses' own windows matter less. Handsome on one main street, too much everywhere.`, { post: 'lantern', mode: 'both', rgb: AMBER, pool: [0.38, 0.3], alpha: 0.5 });
lampMock('l6', 'Corners only: lamps where streets meet', 'Nice',
  `No lamps along the streets, a globe on each free corner of every junction. The fewest posts of any option and the town's shape shows up as points of light at the crossings. Long straights between junctions stay dark.`, { post: 'globe', mode: 'corners', pool: [0.4, 0.4], alpha: 0.5 });
lampMock('l7', 'A visible cone under the lamp', 'Decide',
  `L2 with the light itself drawn: a faint wedge from the globe down to its pool, as on a misty night. More atmosphere, and the nearest thing here to the fog you disliked on the cars, so it is a taste call.`, { post: 'globe', pool: [0.42, 0.34], alpha: 0.5, cone: true });
lampMock('l8', 'Bollards: knee-high lights along the kerb', 'Nice',
  `Short posts with a lit band, two a tile on each side, each with a tiny pool. A dotted line of light down both kerbs and nothing above head height, so the buildings stay the tallest things in view. Many more draws than the others (four a tile).`, { post: 'bollard', mode: 'dense', pool: [0.16, 0.14], poolAt: 0.92, alpha: 0.6, halo: 3 });
lampMock('l9', 'Pools only: no posts at all', 'Nice',
  `Just the light on the ground, where L2's lamps would stand. Nothing to draw by day, nothing to collide with a walker or a building, the cheapest of all. The light has no visible source, which most people never question at this size.`, { post: null, pool: [0.44, 0.36], alpha: 0.5 });
lampMock('l10', 'String lights across the street', 'Decide',
  `For one street only, say the main street: short posts on both sides with a cable between them and a row of small bulbs. Festive rather than civic, and no pool at all, just a warm scatter. Could come with the block party instead of every night.`, { post: null, mode: 'alternate' }, {
    ents: (st) => (st.lampSpots || []).map((sp) => ({ depth: sp.c + sp.r + 0.47, draw: (ctx) => { const a = gp(st.sc, sp.c, sp.r, sp.axis === 0 ? 0 : -0.41, sp.axis === 0 ? -0.41 : 0), b = gp(st.sc, sp.c, sp.r, sp.axis === 0 ? 0 : 0.41, sp.axis === 0 ? 0.41 : 0); ctx.strokeStyle = POST; ctx.lineWidth = 1.3; for (const p of [a, b]) { ctx.beginPath(); ctx.moveTo(p[0], p[1]); ctx.lineTo(p[0], p[1] - 17); ctx.stroke(); } ctx.lineWidth = 0.6; ctx.beginPath(); ctx.moveTo(a[0], a[1] - 17); ctx.quadraticCurveTo((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - 12, b[0], b[1] - 17); ctx.stroke(); } })),
    lights: (st) => (st.lampSpots || []).map((sp) => ({ depth: sp.c + sp.r + 0.5, draw: (c) => { const on = lampOn(st, sp); if (on <= 0) return; const a = gp(st.sc, sp.c, sp.r, sp.axis === 0 ? 0 : -0.41, sp.axis === 0 ? -0.41 : 0), b = gp(st.sc, sp.c, sp.r, sp.axis === 0 ? 0 : 0.41, sp.axis === 0 ? 0.41 : 0); const cols = ['255,214,150', '255,150,130', '170,220,255', '200,255,170']; for (let i = 1; i < 8; i++) { const t = i / 8, mx = (a[0] + b[0]) / 2, my = (a[1] + b[1]) / 2 - 12; const x = (1 - t) * (1 - t) * a[0] + 2 * t * (1 - t) * mx + t * t * b[0], y = (1 - t) * (1 - t) * (a[1] - 17) + 2 * t * (1 - t) * my + t * t * (b[1] - 17); headHalo(c, [x, y + 1], cols[i % 4], 3.2, 0.9 * on); c.fillStyle = `rgba(255,252,236,${on})`; c.beginPath(); c.arc(x, y + 1, 0.8, 0, 7); c.fill(); } } })),
  });
