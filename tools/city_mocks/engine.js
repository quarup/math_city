// Mini isometric engine mirroring lib/game/city (IsoGrid, CityBoardComponent,
// road_sprites.dart). World units = screen px at zoom 1, tileWidth = 64.
'use strict';
const TILE_W = 64, HALF_W = 32, HALF_H = 16, AUTH_PX = 192, SCALE = TILE_W / AUTH_PX;
const FOOT = {
  apartment_v1: [2, 2], park_v1: [2, 2], coffee_shop_v1: [1, 1], high_rise_v1: [3, 3],
  amusement_park_v1: [6, 6], fountain_plaza_v1: [2, 2], power_plant_v1: [2, 2],
  fire_station_v1: [2, 2], observation_tower_v1: [2, 2], duplex_v1: [2, 1],
  playground_v1: [1, 2], hospital_v1: [3, 3], bakery_v1: [1, 2], farmhouse_v1: [2, 2],
  police_station_v1: [2, 2],
};
// Grid direction -> screen vector (E = col+1 exits lower-right, S = row+1 lower-left).
const DIRV = [[HALF_W, HALF_H], [-HALF_W, HALF_H], [-HALF_W, -HALF_H], [HALF_W, -HALF_H]];
const DIRD = [[1, 0], [0, 1], [-1, 0], [0, -1]];
const UNIT = DIRV.map(([x, y]) => { const l = Math.hypot(x, y); return [x / l, y / l]; });

const IMG = {}; // name -> HTMLImageElement
const LIT = {}; // name -> offscreen canvas holding only the warm-bright (window) pixels
function loadSprites(done) {
  const names = Object.keys(SPRITES); let left = names.length;
  names.forEach((n) => {
    const im = new Image();
    im.onload = () => { IMG[n] = im; if (!n.startsWith('road')) LIT[n] = emissiveMask(im); if (--left === 0) done(); };
    im.src = SPRITES[n];
  });
}
// Offline this would be a process.py step emitting <id>_v<n>_lit.png.
function emissiveMask(im) {
  const c = document.createElement('canvas'); c.width = im.width; c.height = im.height;
  const x = c.getContext('2d'); x.drawImage(im, 0, 0);
  const d = x.getImageData(0, 0, c.width, c.height), p = d.data;
  for (let i = 0; i < p.length; i += 4) {
    const r = p[i], g = p[i + 1], b = p[i + 2];
    const warm = r > 205 && g > 150 && b < 175 && r - b > 55 && p[i + 3] > 200;
    if (!warm) p[i + 3] = 0;
  }
  x.putImageData(d, 0, 0); return c;
}

class Grid {
  constructor(cols, rows) { this.cols = cols; this.rows = rows; this.originX = rows * HALF_W; this.originY = HALF_H; }
  get boardW() { return (this.cols + this.rows) * HALF_W; }
  get boardH() { return (this.cols + this.rows) * HALF_H; }
  center(c, r) { return [this.originX + (c - r) * HALF_W, this.originY + (c + r) * HALF_H]; }
  tileAt(x, y) {
    const a = (x - this.originX) / HALF_W, b = (y - this.originY) / HALF_H;
    const c = Math.round((a + b) / 2), r = Math.round((b - a) / 2);
    return (c < 0 || c >= this.cols || r < 0 || r >= this.rows) ? null : [c, r];
  }
}

// Port of roadSpriteFor (road_sprites.dart).
function roadSprite(e, s, w, n) {
  const cnt = e + s + w + n;
  if (cnt === 4 || cnt === 0) return ['road_cross', 0, 0];
  if (cnt === 3) { if (!n) return ['road_tee', 0, 0]; if (!w) return ['road_tee', 1, 0]; if (!e) return ['road_tee', 0, 1]; return ['road_tee', 1, 1]; }
  if (cnt === 2) {
    if (e && w) return ['road_straight', 0, 0]; if (n && s) return ['road_straight', 1, 0];
    if (e && s) return ['road_curve_ud', 0, 0]; if (w && n) return ['road_curve_ud', 0, 1];
    if (e && n) return ['road_curve_lr', 0, 0]; return ['road_curve_lr', 1, 0];
  }
  if (e) return ['road_deadend', 0, 0]; if (s) return ['road_deadend', 1, 0]; if (n) return ['road_deadend', 0, 1]; return ['road_deadend', 1, 1];
}

class Scene {
  constructor({ cols, rows, roads = [], buildings = [], sites = [] }) {
    this.grid = new Grid(cols, rows);
    this.roads = new Set(roads.map(([c, r]) => c + ',' + r));
    this.buildings = buildings.map((b) => ({ ...b, w: FOOT[b.id][0], h: FOOT[b.id][1] }));
    this.sites = sites; // {col,row,w,h,stage}
  }
  isRoad(c, r) { return this.roads.has(c + ',' + r); }
  roadNeighbours(c, r) { return DIRD.map(([dc, dr], d) => this.isRoad(c + dc, r + dr) ? d : -1).filter((d) => d >= 0); }
  // Screen point of the footprint's south corner and the sprite's top-left/size.
  spriteBox(b) {
    const [mx, my] = this.grid.center(b.col + b.w - 1, b.row + b.h - 1);
    const im = IMG[b.id]; const W = im.width * SCALE, H = im.height * SCALE;
    const ax = b.w / (b.w + b.h);
    return { x: mx - ax * W, y: my + HALF_H - H, W, H };
  }
  // World point of an authoring-pixel anchor on a building sprite.
  anchor(b, ax, ay) { const bb = this.spriteBox(b); return [bb.x + ax * SCALE, bb.y + ay * SCALE]; }
  depthOf(b) { return b.col + b.row + (b.w + b.h) / 2 - 1; }
}

// ---- Drawing -------------------------------------------------------------
function diamond(ctx, cx, cy, lift = 0) {
  ctx.beginPath(); ctx.moveTo(cx, cy - HALF_H - lift); ctx.lineTo(cx + HALF_W, cy - lift);
  ctx.lineTo(cx, cy + HALF_H - lift); ctx.lineTo(cx - HALF_W, cy - lift); ctx.closePath();
}
function drawTerrain(ctx, sc, opts = {}) {
  const g = sc.grid;
  for (let c = 0; c < g.cols; c++) for (let r = 0; r < g.rows; r++) {
    const [cx, cy] = g.center(c, r); diamond(ctx, cx, cy);
    ctx.fillStyle = (c + r) % 2 === 0 ? '#7CB342' : '#689F38'; ctx.fill();
    ctx.strokeStyle = 'rgba(0,0,0,.2)'; ctx.lineWidth = 1; ctx.stroke();
  }
  for (const s of sc.sites) for (let c = s.col; c < s.col + s.w; c++) for (let r = s.row; r < s.row + s.h; r++) {
    const [cx, cy] = g.center(c, r); diamond(ctx, cx, cy);
    ctx.fillStyle = (c + r) % 2 === 0 ? '#A1887F' : '#8D6E63'; ctx.fill(); ctx.strokeStyle = 'rgba(0,0,0,.2)'; ctx.stroke();
  }
  for (const key of sc.roads) {
    const [c, r] = key.split(',').map(Number); const [cx, cy] = g.center(c, r);
    const [name, fh, fv] = roadSprite(+sc.isRoad(c + 1, r), +sc.isRoad(c, r + 1), +sc.isRoad(c - 1, r), +sc.isRoad(c, r - 1));
    const im = IMG[name]; const W = im.width * SCALE, H = im.height * SCALE;
    ctx.save(); ctx.translate(cx, cy); ctx.scale(fh ? -1 : 1, fv ? -1 : 1); ctx.drawImage(im, -W / 2, -H / 2, W, H); ctx.restore();
  }
}
function drawSite(ctx, sc, s) {
  const g = sc.grid;
  const [ncx, ncy] = g.center(s.col, s.row), [ecx, ecy] = g.center(s.col + s.w - 1, s.row), [scx, scy] = g.center(s.col + s.w - 1, s.row + s.h - 1), [wcx, wcy] = g.center(s.col, s.row + s.h - 1);
  const N = [ncx, ncy - HALF_H], E = [ecx + HALF_W, ecy], S = [scx, scy + HALF_H], Wp = [wcx - HALF_W, wcy];
  if (s.stage >= 1) {
    const l = TILE_W * 0.06; ctx.beginPath(); ctx.moveTo(N[0], N[1] - l); ctx.lineTo(E[0], E[1] - l); ctx.lineTo(S[0], S[1] - l); ctx.lineTo(Wp[0], Wp[1] - l); ctx.closePath();
    ctx.fillStyle = '#B0BEC5'; ctx.fill(); ctx.strokeStyle = 'rgba(0,0,0,.2)'; ctx.stroke();
  }
  ctx.beginPath(); ctx.moveTo(...N); ctx.lineTo(...E); ctx.lineTo(...S); ctx.lineTo(...Wp); ctx.closePath();
  ctx.strokeStyle = '#5D4037'; ctx.lineWidth = 3; ctx.stroke(); ctx.lineWidth = 1;
  return { N, E, S, W: Wp };
}
function drawBuilding(ctx, sc, b, night = 0, flicker = 1) {
  const bb = sc.spriteBox(b); const im = IMG[b.id];
  ctx.drawImage(im, bb.x, bb.y, bb.W, bb.H);
  if (night > 0.05 && LIT[b.id] && !b.dark) {
    // Windows stay lit through the night tint: drawn again later in the light pass.
    sc._lit = sc._lit || []; sc._lit.push({ b, bb, a: Math.min(1, night * 1.4) * flicker });
  }
}

// ---- Time of day -----------------------------------------------------------
// hour in [0,24). Returns sky gradient stops, night strength, dusk warmth.
function timeOfDay(hour) {
  const key = [
    [0, ['#0a1230', '#182a5c'], 1, 0], [5, ['#1c2a5e', '#5a4e7a'], 0.85, 0.2], [6.5, ['#6d7fb8', '#f4a86a'], 0.35, 0.8],
    [8, ['#5DB7E8', '#A4DDC9'], 0, 0.15], [16, ['#5DB7E8', '#A4DDC9'], 0, 0.05], [18.5, ['#4a6fb3', '#f6a05a'], 0.25, 0.9],
    [20, ['#141d4d', '#3a3468'], 0.8, 0.35], [21.5, ['#0a1230', '#182a5c'], 1, 0], [24, ['#0a1230', '#182a5c'], 1, 0],
  ];
  let i = 0; while (key[i + 1][0] <= hour) i++;
  const [h0, c0, n0, d0] = key[i], [h1, c1, n1, d1] = key[i + 1]; const t = (hour - h0) / (h1 - h0);
  return { sky: [mix(c0[0], c1[0], t), mix(c0[1], c1[1], t)], night: n0 + (n1 - n0) * t, dusk: d0 + (d1 - d0) * t };
}
function mix(a, b, t) {
  const pa = hex(a), pb = hex(b); return 'rgb(' + pa.map((v, i) => Math.round(v + (pb[i] - v) * t)).join(',') + ')';
}
function hex(h) { return [1, 3, 5].map((i) => parseInt(h.substr(i, 2), 16)); }

// ---- Entities: cars & walkers on the road graph ----------------------------
function pickDir(sc, c, r, dir) {
  const opts = sc.roadNeighbours(c, r).filter((d) => d !== (dir + 2) % 4);
  if (opts.length === 0) return (dir + 2) % 4;
  if (opts.includes(dir) && Math.random() < 0.6) return dir;
  return opts[Math.floor(Math.random() * opts.length)];
}
class Mover {
  constructor(sc, c, r, dir, speed, lane) { this.sc = sc; this.c = c; this.r = r; this.dir = dir; this.t = 0; this.speed = speed; this.lane = lane; this.wait = 0; }
  step(dt) {
    if (this.wait > 0) { this.wait -= dt; return; }
    this.t += dt * this.speed;
    while (this.t >= 1) { this.t -= 1; this.c += DIRD[this.dir][0]; this.r += DIRD[this.dir][1]; this.dir = pickDir(this.sc, this.c, this.r, this.dir); }
  }
  pos() {
    const [x0, y0] = this.sc.grid.center(this.c, this.r); const v = DIRV[this.dir]; const s = UNIT[(this.dir + 1) % 4];
    return [x0 + v[0] * this.t + s[0] * this.lane, y0 + v[1] * this.t + s[1] * this.lane];
  }
  depth() { return this.c + this.r + (DIRD[this.dir][0] + DIRD[this.dir][1]) * this.t; }
}

// Iso box car; heading dir 0..3. style: 'flat' | 'paint'.
function drawCar(ctx, x, y, dir, color, style = 'flat', o = {}) {
  const u = UNIT[dir], s = UNIT[(dir + 1) % 4]; const L = o.L || 20, Wd = o.W || 10, H = o.H || 7, R = o.R || 4;
  const P = (a, b, z) => [x + u[0] * a + s[0] * b, y + u[1] * a + s[1] * b - z];
  // shadow
  ctx.fillStyle = 'rgba(0,0,0,.28)'; ctx.beginPath(); ctx.ellipse(x + 1, y + 2, L * 0.55, L * 0.3, 0, 0, 7); ctx.fill();
  const face = (pts, fill) => { ctx.beginPath(); ctx.moveTo(...pts[0]); pts.slice(1).forEach((p) => ctx.lineTo(...p)); ctx.closePath(); ctx.fillStyle = fill; ctx.fill(); if (style === 'flat') { ctx.strokeStyle = 'rgba(20,20,40,.55)'; ctx.lineWidth = 1; ctx.stroke(); } };
  const dark = shade(color, 0.62), mid = shade(color, 0.8), roof = style === 'paint' ? shade(color, 1.12) : color;
  // Determine which side faces the viewer: screen-lower faces (positive y of u / s).
  const frontIsLower = u[1] > 0, rightIsLower = s[1] > 0;
  const sideA = [P(-L / 2, Wd / 2, 0), P(L / 2, Wd / 2, 0), P(L / 2, Wd / 2, H), P(-L / 2, Wd / 2, H)];
  const sideB = [P(-L / 2, -Wd / 2, 0), P(L / 2, -Wd / 2, 0), P(L / 2, -Wd / 2, H), P(-L / 2, -Wd / 2, H)];
  const endF = [P(L / 2, -Wd / 2, 0), P(L / 2, Wd / 2, 0), P(L / 2, Wd / 2, H), P(L / 2, -Wd / 2, H)];
  const endB = [P(-L / 2, -Wd / 2, 0), P(-L / 2, Wd / 2, 0), P(-L / 2, Wd / 2, H), P(-L / 2, -Wd / 2, H)];
  face(rightIsLower ? sideA : sideB, dark); face(frontIsLower ? endF : endB, mid);
  face([P(-L / 2, -Wd / 2, H), P(L / 2, -Wd / 2, H), P(L / 2, Wd / 2, H), P(-L / 2, Wd / 2, H)], roof);
  // cabin (raised, shorter)
  const cab = [P(-L * 0.28, -Wd / 2 + 1, H), P(L * 0.18, -Wd / 2 + 1, H), P(L * 0.18, Wd / 2 - 1, H), P(-L * 0.28, Wd / 2 - 1, H)];
  face(rightIsLower ? [P(-L * 0.28, Wd / 2 - 1, H), P(L * 0.18, Wd / 2 - 1, H), P(L * 0.18, Wd / 2 - 1, H + R), P(-L * 0.28, Wd / 2 - 1, H + R)] : [P(-L * 0.28, -Wd / 2 + 1, H), P(L * 0.18, -Wd / 2 + 1, H), P(L * 0.18, -Wd / 2 + 1, H + R), P(-L * 0.28, -Wd / 2 + 1, H + R)], '#8fb6d6');
  face(frontIsLower ? [P(L * 0.18, -Wd / 2 + 1, H), P(L * 0.18, Wd / 2 - 1, H), P(L * 0.18, Wd / 2 - 1, H + R), P(L * 0.18, -Wd / 2 + 1, H + R)] : [P(-L * 0.28, -Wd / 2 + 1, H), P(-L * 0.28, Wd / 2 - 1, H), P(-L * 0.28, Wd / 2 - 1, H + R), P(-L * 0.28, -Wd / 2 + 1, H + R)], '#a9cfe9');
  face(cab.map((p) => [p[0], p[1] - R]), roof);
  if (style === 'paint') { // specular streak + wheels
    ctx.strokeStyle = 'rgba(255,255,255,.45)'; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.moveTo(...P(-L * 0.4, -Wd * 0.2, H + 0.5)); ctx.lineTo(...P(L * 0.35, -Wd * 0.2, H + 0.5)); ctx.stroke();
    ctx.fillStyle = '#1e1e24'; for (const a of [-L * 0.32, L * 0.32]) { const b = rightIsLower ? Wd / 2 : -Wd / 2; const p = P(a, b, 1.5); ctx.beginPath(); ctx.ellipse(p[0], p[1], 2.6, 2, 0, 0, 7); ctx.fill(); }
  }
  if (o.lights) { // headlights + tail lights (screen-space glow)
    const hl = [P(L / 2, -Wd / 2 + 2, 3), P(L / 2, Wd / 2 - 2, 3)], tl = [P(-L / 2, -Wd / 2 + 2, 3), P(-L / 2, Wd / 2 - 2, 3)];
    ctx.save(); ctx.globalCompositeOperation = 'lighter';
    for (const p of hl) { const g = ctx.createRadialGradient(p[0], p[1], 0, p[0] + u[0] * 14, p[1] + u[1] * 14, 22); g.addColorStop(0, 'rgba(255,240,180,.55)'); g.addColorStop(1, 'rgba(255,240,180,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.arc(p[0] + u[0] * 12, p[1] + u[1] * 12, 22, 0, 7); ctx.fill(); ctx.fillStyle = '#fff6c8'; ctx.beginPath(); ctx.arc(p[0], p[1], 1.6, 0, 7); ctx.fill(); }
    for (const p of tl) { ctx.fillStyle = '#ff4a3a'; ctx.beginPath(); ctx.arc(p[0], p[1], 1.4, 0, 7); ctx.fill(); }
    ctx.restore();
  }
  if (o.beacon !== undefined) { // emergency light bar
    const on = Math.floor(o.beacon * 6) % 2 === 0; const p = P(-L * 0.08, 0, H + R + 1);
    ctx.fillStyle = on ? '#ff3b3b' : '#3b7bff'; ctx.beginPath(); ctx.arc(p[0], p[1], 2.2, 0, 7); ctx.fill();
    ctx.save(); ctx.globalCompositeOperation = 'lighter'; const g = ctx.createRadialGradient(p[0], p[1], 0, p[0], p[1], 16); g.addColorStop(0, on ? 'rgba(255,60,60,.6)' : 'rgba(60,120,255,.6)'); g.addColorStop(1, 'rgba(0,0,0,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.arc(p[0], p[1], 16, 0, 7); ctx.fill(); ctx.restore();
  }
}
function shade(c, f) { const [r, g, b] = hex(c); return `rgb(${Math.min(255, r * f) | 0},${Math.min(255, g * f) | 0},${Math.min(255, b * f) | 0})`; }

// Little walking citizen. phase: walk cycle radians. style 'flat' | 'paint'.
function drawWalker(ctx, x, y, dir, ph, colors, style = 'flat', o = {}) {
  const u = UNIT[dir]; const bob = Math.abs(Math.sin(ph)) * 1.2; const h = o.h || 13;
  ctx.fillStyle = 'rgba(0,0,0,.25)'; ctx.beginPath(); ctx.ellipse(x, y + 1, 4, 2, 0, 0, 7); ctx.fill();
  const swing = Math.sin(ph) * 3.2 * (o.idle ? 0 : 1);
  ctx.strokeStyle = style === 'flat' ? '#2b2b3a' : colors.pants || '#3a3f5c'; ctx.lineWidth = style === 'flat' ? 2 : 2.4; ctx.lineCap = 'round';
  ctx.beginPath(); ctx.moveTo(x, y - h * 0.45 - bob); ctx.lineTo(x + u[0] * swing, y - bob + 0.5); ctx.moveTo(x, y - h * 0.45 - bob); ctx.lineTo(x - u[0] * swing, y - bob + 0.5); ctx.stroke();
  // torso
  ctx.fillStyle = colors.shirt; roundRect(ctx, x - 3, y - h * 0.85 - bob, 6, h * 0.45, 2.5); ctx.fill();
  if (style === 'flat') { ctx.strokeStyle = '#2b2b3a'; ctx.lineWidth = 1; ctx.stroke(); }
  else { ctx.fillStyle = 'rgba(0,0,0,.18)'; roundRect(ctx, x, y - h * 0.85 - bob, 3, h * 0.45, 2.5); ctx.fill(); }
  // arms
  ctx.strokeStyle = colors.shirt; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(x - 3, y - h * 0.8 - bob); ctx.lineTo(x - 4 - u[0] * swing * 0.5, y - h * 0.55 - bob); ctx.moveTo(x + 3, y - h * 0.8 - bob); ctx.lineTo(x + 4 + u[0] * swing * 0.5, y - h * 0.55 - bob); ctx.stroke();
  // head
  ctx.fillStyle = colors.skin; ctx.beginPath(); ctx.arc(x, y - h - bob + 1, 3.2, 0, 7); ctx.fill();
  if (style === 'flat') { ctx.strokeStyle = '#2b2b3a'; ctx.lineWidth = 1; ctx.stroke(); }
  ctx.fillStyle = colors.hair; ctx.beginPath(); ctx.arc(x, y - h - bob + 0.2, 3.2, Math.PI, 2 * Math.PI); ctx.fill();
  if (o.wave) { ctx.strokeStyle = colors.shirt; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(x + 3, y - h * 0.8 - bob); ctx.lineTo(x + 6, y - h - 4 - Math.sin(ph * 3) * 2); ctx.stroke(); }
}
function roundRect(ctx, x, y, w, h, r) { ctx.beginPath(); ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r); ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath(); }

const PALETTE_CARS = ['#e0523f', '#3a7bd5', '#f2b134', '#3DA85F', '#f4f4f4', '#8e5bd1', '#2f3e46', '#ff8c42'];
const SKINS = ['#f1c9a5', '#d9a276', '#b07a4f', '#8d5a3a', '#f7dcc2'];
const HAIRS = ['#2b1d12', '#6b3e1e', '#d8b26a', '#1a1a1a', '#9c3d1f', '#c8c8c8'];
const SHIRTS = ['#e0523f', '#3a7bd5', '#f2b134', '#3DA85F', '#8e5bd1', '#ff8c42', '#0E6E62', '#f06292'];
const pick = (a) => a[Math.floor(Math.random() * a.length)];
function citizen() { return { shirt: pick(SHIRTS), skin: pick(SKINS), hair: pick(HAIRS), pants: pick(['#3a3f5c', '#4a4a4a', '#6b4b3a', '#2f5d8a']) }; }

// ---- Particles -------------------------------------------------------------
class Particles {
  constructor() { this.list = []; }
  spawn(p) { this.list.push({ life: 1, ...p }); }
  step(dt) { for (const p of this.list) { p.x += (p.vx || 0) * dt; p.y += (p.vy || 0) * dt; p.vy = (p.vy || 0) + (p.g || 0) * dt; p.life -= dt / (p.ttl || 1); } this.list = this.list.filter((p) => p.life > 0); }
  draw(ctx, fn) { for (const p of this.list) fn(ctx, p); }
}

// ---- Mock runner -----------------------------------------------------------
// A mock is {scene, view:{zoom, cx, cy}, setup(st), update(st, dt), ground(ctx, st), entities(st) -> [{depth, draw(ctx)}],
//            overlay(ctx, st), sky(ctx, st, w, h), tap(st, wx, wy), controls:[{label, run(st)}], hour(st) }
const RUNNING = new Set();
function mountMock(mock, canvas) {
  const W = canvas.clientWidth, H = canvas.clientHeight, dpr = Math.min(2, window.devicePixelRatio || 1);
  canvas.width = W * dpr; canvas.height = H * dpr;
  const ctx = canvas.getContext('2d');
  const sc = new Scene(mock.scene); const st = { sc, t: 0, hour: mock.hourStart ?? 12, parts: new Particles(), W, H, reduce: matchMedia('(prefers-reduced-motion: reduce)').matches };
  const view = mock.view || fitView(sc, W, H);
  st.view = view; mock.setup?.(st);
  const toWorld = (px, py) => [(px - W / 2) / view.zoom + view.cx, (py - H / 2) / view.zoom + view.cy];
  canvas.addEventListener('pointerdown', (e) => { const r = canvas.getBoundingClientRect(); const [wx, wy] = toWorld(e.clientX - r.left, e.clientY - r.top); mock.tap?.(st, wx, wy, e); });
  let last = performance.now();
  function frame(now) {
    const dt = Math.min(0.05, (now - last) / 1000); last = now;
    if (!st.reduce || st.t === 0) { st.t += dt; mock.update?.(st, dt); st.parts.step(dt); }
    const tod = timeOfDay(mock.hour ? mock.hour(st) : st.hour); st.tod = tod;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    // sky
    const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, tod.sky[0]); g.addColorStop(1, tod.sky[1]); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
    mock.sky?.(ctx, st, W, H);
    ctx.translate(W / 2, H / 2); ctx.scale(view.zoom, view.zoom); ctx.translate(-view.cx, -view.cy);
    sc._lit = [];
    drawTerrain(ctx, sc); mock.ground?.(ctx, st);
    const items = sc.buildings.map((b) => ({ depth: sc.depthOf(b), draw: (c) => drawBuilding(c, sc, b, tod.night, b.flicker ?? 1) }));
    for (const s of sc.sites) items.push({ depth: s.col + s.row + (s.w + s.h) / 2 - 1, draw: (c) => { const k = drawSite(c, sc, s); s.corners = k; s.drawInside?.(c, st, k); } });
    for (const e of (mock.entities?.(st) || [])) items.push(e);
    items.sort((a, b) => a.depth - b.depth); for (const it of items) it.draw(ctx);
    // night tint + emissive pass
    if (tod.night > 0.02 || tod.dusk > 0.02) {
      ctx.save(); ctx.globalCompositeOperation = 'multiply';
      if (tod.dusk > 0.02) { ctx.fillStyle = `rgba(255,170,90,${tod.dusk * 0.35})`; ctx.fillRect(view.cx - W / view.zoom, view.cy - H / view.zoom, 2 * W / view.zoom, 2 * H / view.zoom); }
      if (tod.night > 0.02) { const k = tod.night; ctx.fillStyle = `rgba(${Math.round(255 - 175 * k)},${Math.round(255 - 160 * k)},${Math.round(255 - 95 * k)},1)`; ctx.fillRect(view.cx - W / view.zoom, view.cy - H / view.zoom, 2 * W / view.zoom, 2 * H / view.zoom); }
      ctx.restore();
      if (!mock.noWindows) { ctx.save(); for (const l of sc._lit) { ctx.globalAlpha = l.a; ctx.drawImage(LIT[l.b.id], l.bb.x, l.bb.y, l.bb.W, l.bb.H); } ctx.restore(); }
    }
    mock.overlay?.(ctx, st);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0); mock.hud?.(ctx, st, W, H);
    if (RUNNING.has(canvas)) requestAnimationFrame(frame);
  }
  const io = new IntersectionObserver((es) => { for (const e of es) { if (e.isIntersecting) { if (!RUNNING.has(canvas)) { RUNNING.add(canvas); last = performance.now(); requestAnimationFrame(frame); } } else RUNNING.delete(canvas); } }, { rootMargin: '120px' });
  io.observe(canvas);
  return st;
}
function fitView(sc, W, H) {
  const bw = sc.grid.boardW, bh = sc.grid.boardH; const zoom = Math.min((W - 8) / bw, (H - 8) / (bh + 84));
  return { zoom, cx: bw / 2, cy: bh / 2 - 34 };
}
// Tint helper for the sky pass: sun / moon disc at hour.
function drawSunMoon(ctx, hour, W, H) {
  const dayT = (hour - 6) / 12; // 0 at 6h, 1 at 18h
  if (dayT > -0.05 && dayT < 1.05) { const x = W * (0.1 + 0.8 * dayT), y = H * 0.55 - Math.sin(dayT * Math.PI) * H * 0.5; const g = ctx.createRadialGradient(x, y, 0, x, y, 40); g.addColorStop(0, 'rgba(255,245,200,.95)'); g.addColorStop(0.3, 'rgba(255,230,150,.6)'); g.addColorStop(1, 'rgba(255,220,120,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, 40, 0, 7); ctx.fill(); }
  const nightT = ((hour + 6) % 24) / 12; // 0 at 18h, 1 at 6h
  if (nightT > 0 && nightT < 1) { const x = W * (0.1 + 0.8 * nightT), y = H * 0.55 - Math.sin(nightT * Math.PI) * H * 0.5; ctx.fillStyle = '#f4f1e0'; ctx.beginPath(); ctx.arc(x, y, 11, 0, 7); ctx.fill(); ctx.fillStyle = 'rgba(200,205,225,.5)'; ctx.beginPath(); ctx.arc(x - 4, y - 2, 3, 0, 7); ctx.arc(x + 3, y + 4, 2, 0, 7); ctx.fill(); }
}
function drawStars(ctx, W, H, t, k) {
  if (k <= 0.05) return; ctx.save(); ctx.globalAlpha = k;
  for (let i = 0; i < 60; i++) { const x = ((i * 137.5) % W), y = ((i * 71.3) % (H * 0.6)); const tw = 0.5 + 0.5 * Math.sin(t * (1 + i % 5) + i); ctx.fillStyle = `rgba(255,255,255,${0.35 + 0.6 * tw})`; ctx.fillRect(x, y, 1.6, 1.6); }
  ctx.restore();
}
