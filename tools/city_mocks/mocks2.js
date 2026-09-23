'use strict';
function label(ctx, text, x, y) { ctx.font = '600 12px "Nunito", system-ui, sans-serif'; const w = ctx.measureText(text).width + 16; ctx.fillStyle = 'rgba(16,25,23,.72)'; roundRect(ctx, x, y, w, 22, 11); ctx.fill(); ctx.fillStyle = '#fff'; ctx.textBaseline = 'middle'; ctx.textAlign = 'left'; ctx.fillText(text, x + 8, y + 11); }
function fmtHour(h) { const hh = Math.floor(h) % 24, mm = Math.floor((h % 1) * 60); const ap = hh >= 12 ? 'pm' : 'am'; return `${((hh + 11) % 12) + 1}:${String(mm).padStart(2, '0')} ${ap}`; }
function tweenHour(st, dt) { if (st.target === undefined) return; let d = st.target - st.hour; if (d > 12) d -= 24; if (d < -12) d += 24; if (Math.abs(d) < 0.01) { st.hour = st.target; return; } st.hour = (st.hour + Math.sign(d) * Math.min(Math.abs(d), dt * 6) + 24) % 24; }
const skyPass = (ctx, st, W, H) => { drawStars(ctx, W, H, st.t, st.tod ? st.tod.night : 0); drawSunMoon(ctx, st.hour, W, H); };

// ============ D. TIME & LIGHT ============================================
MOCKS.push({
  id: 'd1', section: 'Time & light', title: 'Day and night from the device clock',
  art: 'I draw it', effort: 'M', perf: 'Light', tier: 'Decide',
  notes: `The city shows the kid's own time of day: a warm dawn, the current sunny board through the afternoon, orange dusk, then a blue night with the windows lit. One multiply-blend tint over the whole board plus a sky gradient behind it (which also fixes the black void beyond the frontier). Nothing new to save, and it makes the app feel like it knows what time it is.<br><br>The catch is in the option description you already read: a kid who plays at 4 pm every day sees the same light every day, and one who plays after dinner never sees the sunny version the sprites were painted for.`,
  scene: MAIN(), hourStart: (new Date().getHours() + new Date().getMinutes() / 60), setup: (st) => { addCars(st, 5, 'flat', { lights: true }); },
  controls: [{ label: 'Now', run: (st) => { st.target = new Date().getHours() + new Date().getMinutes() / 60; } }, { label: '6 am', run: (st) => { st.target = 6; } }, { label: '1 pm', run: (st) => { st.target = 13; } }, { label: '7 pm', run: (st) => { st.target = 19; } }, { label: '11 pm', run: (st) => { st.target = 23; } }],
  update: (st, dt) => { tweenHour(st, dt); stepCars(st, dt); }, entities: (st) => st.carEntities(), sky: skyPass, hud: (ctx, st) => label(ctx, 'Device clock · ' + fmtHour(st.hour), 10, 10),
});
MOCKS.push({
  id: 'd2', section: 'Time & light', title: 'A slow ambient day, every eight minutes',
  art: 'I draw it', effort: 'M', perf: 'Light', tier: 'Decide',
  notes: `Same rendering as D1, driven by a loop instead of the clock: a full day every eight minutes (compressed to forty seconds here). Every session sees a sunrise and a night, and dusk is never far away when the player wants it. Starts at morning on each launch so the board is readable when placing. The sun and moon arc across the sky behind the board.<br><br>Risk: a visible tint change while the kid is choosing a site could feel like the app doing something behind their back. Freezing the clock during the construction zoom removes that.`,
  scene: MAIN(), setup: (st) => addCars(st, 5, 'flat', { lights: true }), hour: (st) => (8 + (st.t * 24) / 40) % 24,
  update: (st, dt) => { st.hour = (8 + (st.t * 24) / 40) % 24; stepCars(st, dt); }, entities: (st) => st.carEntities(), sky: skyPass, hud: (ctx, st) => label(ctx, 'Ambient loop · ' + fmtHour(st.hour), 10, 10),
});
MOCKS.push({
  id: 'd3', section: 'Time & light', title: 'Time advances when you answer',
  art: 'I draw it', effort: 'M', perf: 'Light', tier: 'Decide',
  notes: `The sun only moves when the player earns it: each answered block advances the city an hour or two, so night is a reward for a good session and a returning player picks up at the light they left. This is the one option that ties the animation to the maths loop, and it needs one persisted number (city hour) in the player row. Press the button to answer a block.`,
  scene: MAIN(), hourStart: 9, setup: (st) => { addCars(st, 5, 'flat', { lights: true }); st.target = 9; st.blocks = 0; },
  controls: [{ label: 'Answer a block (+1½ h)', run: (st) => { st.target = (st.target + 1.5) % 24; st.blocks++; } }, { label: 'Reset', run: (st) => { st.target = 9; st.blocks = 0; } }],
  update: (st, dt) => { tweenHour(st, dt); stepCars(st, dt); }, entities: (st) => st.carEntities(), sky: skyPass,
  hud: (ctx, st) => { label(ctx, `Play-driven · ${fmtHour(st.hour)} · ${st.blocks} block${st.blocks === 1 ? '' : 's'}`, 10, 10); },
});
MOCKS.push({
  id: 'd4', section: 'Time & light', title: 'Windows that stay lit at night',
  art: 'Pipeline step (I do it)', effort: 'M', perf: 'Light', tier: 'Ship first',
  notes: `The sprites already have warm lit windows painted in. So: darken the whole building with the night tint, then draw back only its warm-bright pixels on top. That second layer is a mask I can compute offline in <code>process.py</code> and ship as <code>&lt;id&gt;_v&lt;n&gt;_lit.png</code> (small, mostly transparent). Every building in the catalogue gets night windows with zero hand work and no new art. Individual buildings flicker on and off by fading their mask, so the skyline is not uniform.<br><br>The mask you see here was computed in the browser with the same threshold. The office and civic buildings with cool white windows would need a second, cooler threshold, still automatic.`,
  scene: MAIN(), hourStart: 22, setup: (st) => { st.next = 0; for (const b of st.sc.buildings) b.flicker = 1; },
  controls: [{ label: 'Night', run: (st) => { st.target = 22; } }, { label: 'Dusk', run: (st) => { st.target = 18.8; } }, { label: 'Day', run: (st) => { st.target = 13; } }],
  update: (st, dt) => { tweenHour(st, dt); st.next -= dt; if (st.next < 0) { const b = pick(st.sc.buildings); b.flicker = b.flicker > 0.5 ? 0.12 : 1; st.next = 1.2 + Math.random() * 2; } },
  sky: skyPass, hud: (ctx, st) => label(ctx, fmtHour(st.hour), 10, 10),
});
MOCKS.push({
  id: 'd5', section: 'Time & light', title: 'Street lamps switching on at dusk',
  art: 'I draw it', effort: 'S', perf: 'Light', tier: 'Nice',
  notes: `A lamp post on the sidewalk corner of every other road tile, drawn in code at a fixed offset from the tile centre. As dusk comes each lamp flicks on at its own random moment across a minute, and pours a soft pool of light onto the asphalt. Depends on any D option. One additive radial gradient per lamp; a big city might hold sixty, still cheap.`,
  scene: MAIN(), hourStart: 17.5, setup: (st) => addCars(st, 4, 'flat', { lights: true }),
  hour: (st) => 17.5 + ((st.t % 24) / 24) * 5,
  update: (st, dt) => { st.hour = 17.5 + ((st.t % 24) / 24) * 5; stepCars(st, dt); }, entities: (st) => st.carEntities(), sky: skyPass,
  overlay: (ctx, st) => {
    for (const [c, r] of ROAD_TILES(st.sc)) if ((c + r) % 2 === 0) {
      const [cx, cy] = st.sc.grid.center(c, r); const px = cx + 22, py = cy - 3; const onAt = 18.2 + ((c * 31 + r * 17) % 10) / 10; const on = st.hour >= onAt;
      ctx.strokeStyle = '#2f3436'; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.moveTo(px, py); ctx.lineTo(px, py - 22); ctx.stroke(); ctx.fillStyle = on ? '#fff1b8' : '#8a8f94'; ctx.beginPath(); ctx.arc(px, py - 23, 2.2, 0, 7); ctx.fill();
      if (on) { ctx.save(); ctx.globalCompositeOperation = 'lighter'; const g = ctx.createRadialGradient(px, py + 2, 0, px, py + 2, 30); g.addColorStop(0, 'rgba(255,220,140,.5)'); g.addColorStop(1, 'rgba(255,220,140,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.ellipse(px, py + 2, 30, 16, 0, 0, 7); ctx.fill(); ctx.restore(); }
    }
  },
  hud: (ctx, st) => label(ctx, fmtHour(st.hour), 10, 10),
});
MOCKS.push({
  id: 'd6', section: 'Time & light', title: 'Stars, moon and fireflies over the park',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `Night-only dressing: a twinkling star field in the sky band, a moon that tracks the hour, and a few fireflies blinking over parks and gardens (any building tagged green in the registry). Pure particles, and the sort of thing a kid points at.`,
  scene: MAIN(), hourStart: 22.5, setup: (st) => addCars(st, 2, 'flat', { lights: true }),
  update: (st, dt) => { stepCars(st, dt); for (const b of st.sc.buildings) if (b.id === 'park_v1' || b.id === 'fountain_plaza_v1' || b.id === 'farmhouse_v1') if (Math.random() < dt * 1.5) { const bb = st.sc.spriteBox(b); st.parts.spawn({ x: bb.x + 20 + Math.random() * (bb.W - 40), y: bb.y + bb.H - 20 - Math.random() * 30, vx: (Math.random() - 0.5) * 8, vy: -4 - Math.random() * 6, ttl: 2.5 + Math.random() * 2, ph: Math.random() * 6 }); } },
  entities: (st) => st.carEntities(), sky: skyPass,
  overlay: (ctx, st) => { ctx.save(); ctx.globalCompositeOperation = 'lighter'; st.parts.draw(ctx, (c, p) => { const k = Math.max(0, Math.sin(st.t * 5 + p.ph)); c.fillStyle = `rgba(220,255,120,${0.9 * k * Math.min(1, p.life * 3)})`; c.beginPath(); c.arc(p.x, p.y, 1.4 + k, 0, 7); c.fill(); }); ctx.restore(); },
});

// ============ E. LANDMARKS ===============================================
MOCKS.push({
  id: 'e1', section: 'Landmarks', title: 'Amusement park: gondolas turn, the drop tower drops',
  art: 'Anchors on the sprite (I place them)', effort: 'M', perf: 'Free', tier: 'Nice',
  notes: `The painted wheel stays as it is; eight coloured gondolas are drawn over its rim and travel round it, which reads as the wheel turning without touching the sprite. The drop tower's ring climbs, hesitates, and falls. Both are code plus two anchor points per park variant (wheel centre and radius, tower top and bottom), which I place from the sprite once. The capstone building of the whole game deserves this.`,
  scene: { cols: 9, rows: 9, roads: range(0, 8).map((c) => [c, 8]), buildings: [{ id: 'amusement_park_v1', col: 1, row: 1 }] },
  view: { zoom: 1.7, cx: 305, cy: 165 },
  overlay: (ctx, st) => {
    const b = st.sc.buildings[0]; const [wx, wy] = st.sc.anchor(b, 690, 1005); const R = 82 * SCALE;
    for (let i = 0; i < 8; i++) { const a = st.t * 0.45 + (i * Math.PI) / 4; const x = wx + Math.cos(a) * R, y = wy + Math.sin(a) * R * 0.96; ctx.strokeStyle = '#444'; ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x, y + 4); ctx.stroke(); ctx.fillStyle = ['#e0523f', '#3a7bd5', '#f2b134', '#3DA85F', '#8e5bd1', '#ff8c42', '#f06292', '#26c6da'][i]; roundRect(ctx, x - 3.2, y + 4, 6.4, 5, 1.5); ctx.fill(); ctx.strokeStyle = 'rgba(0,0,0,.35)'; ctx.stroke(); }
    const [tx, ty0] = st.sc.anchor(b, 580, 900), [, ty1] = st.sc.anchor(b, 580, 775); const cyc = st.t % 7; let k; if (cyc < 4) k = cyc / 4; else if (cyc < 5) k = 1; else if (cyc < 5.5) k = 1 - ((cyc - 5) / 0.5) ** 2; else k = 0; k = Math.max(0, k);
    const y = ty0 - (ty0 - ty1) * k; ctx.fillStyle = '#e0523f'; roundRect(ctx, tx - 9, y - 3, 18, 5, 2); ctx.fill(); ctx.strokeStyle = 'rgba(0,0,0,.4)'; ctx.stroke();
  },
});
MOCKS.push({
  id: 'e2', section: 'Landmarks', title: 'Fountain plaza: water spray and ripples',
  art: 'Anchors on the sprite (I place them)', effort: 'S', perf: 'Light', tier: 'Nice',
  notes: `A particle jet from the top tier arcs into the basin, with expanding ripple rings where it lands. One anchor for the spout and one ellipse for the basin, both read off the sprite. The park (v1) and the amusement park have fountains too, so the same effect gets reused.`,
  scene: { cols: 5, rows: 5, roads: range(0, 4).map((c) => [c, 4]), buildings: [{ id: 'fountain_plaza_v1', col: 1, row: 1 }] },
  view: { zoom: 2.8, cx: 160, cy: 62 },
  update: (st, dt) => { const b = st.sc.buildings[0]; const [sx, sy] = st.sc.anchor(b, 192, 296); for (let i = 0; i < 4; i++) st.parts.spawn({ x: sx, y: sy, vx: (Math.random() - 0.5) * 34, vy: -32 - Math.random() * 10, g: 85, ttl: 1.15 }); if (Math.random() < dt * 3) st.parts.spawn({ x: sx + (Math.random() - 0.5) * 30, y: sy + 26 + Math.random() * 8, ttl: 1.4, ripple: true }); },
  overlay: (ctx, st) => { st.parts.draw(ctx, (c, p) => { if (p.ripple) { c.strokeStyle = `rgba(255,255,255,${0.5 * p.life})`; c.lineWidth = 0.8; c.beginPath(); c.ellipse(p.x, p.y, (1 - p.life) * 8, (1 - p.life) * 3.5, 0, 0, 7); c.stroke(); } else { c.fillStyle = `rgba(225,245,255,${0.85 * p.life})`; c.beginPath(); c.arc(p.x, p.y, 0.9, 0, 7); c.fill(); } }); },
});
MOCKS.push({
  id: 'e3', section: 'Landmarks', title: 'Power plant: cooling-tower steam and a pulsing core',
  art: 'Anchors on the sprite (I place them)', effort: 'S', perf: 'Light', tier: 'Nice',
  notes: `Puffs rise from the cooling tower, grow, thin out and drift with the wind; the green reactor dome breathes with a slow glow. Two anchors. The same smoke particle serves chimneys on the bakery, the farmhouse in winter and the recycling centre.`,
  scene: { cols: 5, rows: 5, roads: range(0, 4).map((c) => [c, 4]), buildings: [{ id: 'power_plant_v1', col: 1, row: 1 }] },
  view: { zoom: 2.4, cx: 160, cy: 50 },
  update: (st, dt) => { const b = st.sc.buildings[0]; const [sx, sy] = st.sc.anchor(b, 268, 330); if (Math.random() < dt * 5) st.parts.spawn({ x: sx + (Math.random() - 0.5) * 8, y: sy, vx: 5 + Math.random() * 3, vy: -12 - Math.random() * 4, ttl: 4 + Math.random() * 2 }); },
  overlay: (ctx, st) => {
    st.parts.draw(ctx, (c, p) => { const age = 1 - p.life; c.fillStyle = `rgba(240,240,245,${0.45 * p.life})`; c.beginPath(); c.arc(p.x, p.y, 3 + age * 12, 0, 7); c.fill(); });
    const b = st.sc.buildings[0]; const [gx, gy] = st.sc.anchor(b, 200, 292); const k = 0.5 + 0.5 * Math.sin(st.t * 2.2); ctx.save(); ctx.globalCompositeOperation = 'lighter'; const g = ctx.createRadialGradient(gx, gy, 0, gx, gy, 14 + k * 6); g.addColorStop(0, `rgba(80,255,200,${0.35 + 0.35 * k})`); g.addColorStop(1, 'rgba(80,255,200,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.arc(gx, gy, 22, 0, 7); ctx.fill(); ctx.restore();
  },
});
MOCKS.push({
  id: 'e4', section: 'Landmarks', title: 'Coffee shop: steam from the cup, sign glow at night',
  art: 'Anchors on the sprite (I place them)', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `Wisps rise from the cup on the roof; after dusk the sign glows warm. The coffee shop is the first shop most players build (it unlocks from a single home), so it is a good place to spend a small bespoke touch early. One anchor per variant, four variants.`,
  scene: { cols: 5, rows: 4, roads: range(0, 4).map((c) => [c, 3]), buildings: [{ id: 'coffee_shop_v1', col: 1, row: 1 }, { id: 'bakery_v1', col: 3, row: 1 }] },
  view: { zoom: 3.2, cx: 140, cy: 42 }, hourStart: 13,
  controls: [{ label: 'Day', run: (st) => { st.target = 13; } }, { label: 'Night', run: (st) => { st.target = 21; } }],
  update: (st, dt) => { tweenHour(st, dt); const b = st.sc.buildings[0]; const [sx, sy] = st.sc.anchor(b, 100, 84); if (Math.random() < dt * 4) st.parts.spawn({ x: sx + (Math.random() - 0.5) * 4, y: sy, vx: 2, vy: -7, ttl: 2.2, ph: Math.random() * 6 }); },
  sky: skyPass,
  overlay: (ctx, st) => {
    st.parts.draw(ctx, (c, p) => { const age = 1 - p.life; c.fillStyle = `rgba(255,255,255,${0.5 * p.life})`; c.beginPath(); c.arc(p.x + Math.sin(age * 6 + p.ph) * 2, p.y, 1.2 + age * 3, 0, 7); c.fill(); });
    if (st.tod.night > 0.1) { const b = st.sc.buildings[0]; const [gx, gy] = st.sc.anchor(b, 100, 96); ctx.save(); ctx.globalCompositeOperation = 'lighter'; const g = ctx.createRadialGradient(gx, gy, 0, gx, gy, 16); g.addColorStop(0, `rgba(255,190,90,${0.7 * st.tod.night})`); g.addColorStop(1, 'rgba(255,190,90,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.arc(gx, gy, 16, 0, 7); ctx.fill(); ctx.restore(); }
  },
});
MOCKS.push({
  id: 'e5', section: 'Landmarks', title: 'Observation tower: beacon and a sweeping searchlight',
  art: 'Anchors on the sprite (I place them)', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `A red aviation beacon blinks on the dome all day; at night a searchlight beam sweeps slowly round from the deck. Two anchors. As one of the two most expensive buildings in the game, the tower should be visible from anywhere in the city, and a moving beam does that.`,
  scene: { cols: 6, rows: 6, roads: range(0, 5).map((c) => [c, 5]), buildings: [{ id: 'observation_tower_v1', col: 2, row: 2 }, { id: 'duplex_v1', col: 0, row: 3 }, { id: 'coffee_shop_v1', col: 4, row: 1 }] },
  view: { zoom: 1.9, cx: 200, cy: 60 }, hourStart: 22,
  sky: skyPass,
  overlay: (ctx, st) => {
    const b = st.sc.buildings[0]; const [bx, by] = st.sc.anchor(b, 200, 38); const on = Math.floor(st.t * 1.5) % 2 === 0;
    if (on) { ctx.save(); ctx.globalCompositeOperation = 'lighter'; const g = ctx.createRadialGradient(bx, by, 0, bx, by, 9); g.addColorStop(0, 'rgba(255,60,60,.9)'); g.addColorStop(1, 'rgba(255,60,60,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.arc(bx, by, 9, 0, 7); ctx.fill(); ctx.restore(); } ctx.fillStyle = on ? '#ff5a5a' : '#6a2020'; ctx.beginPath(); ctx.arc(bx, by, 1.6, 0, 7); ctx.fill();
    const [dx, dy] = st.sc.anchor(b, 200, 120); const a = st.t * 0.6; ctx.save(); ctx.globalCompositeOperation = 'lighter'; ctx.translate(dx, dy); ctx.scale(1, 0.5); ctx.rotate(a); const g = ctx.createLinearGradient(0, 0, 200, 0); g.addColorStop(0, 'rgba(255,250,210,.55)'); g.addColorStop(1, 'rgba(255,250,210,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(200, -22); ctx.lineTo(200, 22); ctx.closePath(); ctx.fill(); ctx.restore();
  },
});
MOCKS.push({
  id: 'e6', section: 'Landmarks', title: 'A flag waving on civic buildings',
  art: 'Anchors on the sprite (I place them)', effort: 'S', perf: 'Free', tier: 'Later',
  notes: `A cloth strip drawn as a dozen thin slices with a travelling sine wave, hung from the pole the sprite already has. Police station, fire station, city hall and the mayor's office all have poles. Small and charming, but the pole positions are per-sprite anchors and the flag design is a question in itself (a Math City flag?).`,
  scene: { cols: 5, rows: 5, roads: range(0, 4).map((c) => [c, 4]), buildings: [{ id: 'police_station_v1', col: 1, row: 1 }] },
  view: { zoom: 3.4, cx: 150, cy: 68 },
  overlay: (ctx, st) => {
    const b = st.sc.buildings[0]; const [px, py] = st.sc.anchor(b, 163, 226); ctx.strokeStyle = '#d9d9d9'; ctx.lineWidth = 0.8; ctx.beginPath(); ctx.moveTo(px, py); ctx.lineTo(px, py + 20); ctx.stroke();
    const n = 14; for (let i = 0; i < n; i++) { const x0 = px + i * 1.1, x1 = x0 + 1.15; const w0 = Math.sin(st.t * 7 - i * 0.55) * (i / n) * 1.8, w1 = Math.sin(st.t * 7 - (i + 1) * 0.55) * ((i + 1) / n) * 1.8; const shade = 0.75 + 0.25 * Math.cos(st.t * 7 - i * 0.55); ctx.fillStyle = `rgba(${14 * shade | 0},${110 * shade | 0},${98 * shade | 0},1)`; ctx.beginPath(); ctx.moveTo(x0, py + w0); ctx.lineTo(x1, py + w1); ctx.lineTo(x1, py + 7 + w1); ctx.lineTo(x0, py + 7 + w0); ctx.closePath(); ctx.fill(); }
    ctx.fillStyle = '#F0CC30'; ctx.beginPath(); ctx.arc(px + 8, py + 3.5 + Math.sin(st.t * 7 - 7 * 0.55) * 0.9, 1.6, 0, 7); ctx.fill();
  },
});

// ============ F. CONSTRUCTION ============================================
MOCKS.push({
  id: 'f1', section: 'Construction', title: 'A construction site that is actually working',
  art: 'I draw it', effort: 'M', perf: 'Free', tier: 'Ship first',
  notes: `The site is where the player's answers land, and right now it is a still fence. Here a crane swings a load over the pad, two hard-hats pace between the corners, dust puffs up, and each paid stage arrives with a sparkle. All code, on top of the stage overlays that already exist in <code>CityBoardComponent._drawSite</code>. Of everything on this page, this is the one that connects the animation to the maths.`,
  scene: { cols: 7, rows: 6, roads: range(0, 6).map((c) => [c, 5]), buildings: [{ id: 'duplex_v1', col: 4, row: 2 }], sites: [{ col: 1, row: 1, w: 2, h: 2, stage: 0 }] },
  view: { zoom: 2.2, cx: 200, cy: 70 },
  setup: (st) => { const s = st.sc.sites[0]; st.workers = [0, 1].map((i) => ({ k: Math.random(), dir: 1, look: { shirt: '#f2b134', skin: pick(SKINS), hair: '#f2b134' }, ph: 0, lane: i })); s.drawInside = (ctx, st2, k) => { if (s.stage >= 2) { ctx.save(); ctx.globalAlpha = 0.35; const b = { id: 'apartment_v1', col: s.col, row: s.row, w: 2, h: 2 }; const bb = st.sc.spriteBox(b); ctx.drawImage(IMG.apartment_v1, bb.x, bb.y, bb.W, bb.H); ctx.restore(); } }; },
  controls: [{ label: 'Pay a block', run: (st) => { const s = st.sc.sites[0]; if (s.stage < 2) { s.stage++; const [cx, cy] = st.sc.grid.center(s.col, s.row); for (let i = 0; i < 26; i++) st.parts.spawn({ x: cx + 32 + (Math.random() - 0.5) * 60, y: cy + 16 + (Math.random() - 0.5) * 30, vx: (Math.random() - 0.5) * 30, vy: -20 - Math.random() * 30, g: 40, ttl: 1.2, spark: true }); } } }, { label: 'Reset', run: (st) => { st.sc.sites[0].stage = 0; } }],
  update: (st, dt) => { for (const w of st.workers) { w.k += w.dir * dt * 0.12; if (w.k > 1 || w.k < 0) { w.dir *= -1; w.k = Math.max(0, Math.min(1, w.k)); } w.ph += dt * 8; } const s = st.sc.sites[0]; if (Math.random() < dt * 1.2) { const [cx, cy] = st.sc.grid.center(s.col + 1, s.row + 1); st.parts.spawn({ x: cx + (Math.random() - 0.5) * 40, y: cy + (Math.random() - 0.5) * 16, vy: -6, ttl: 1.5, dust: true }); } },
  entities: (st) => st.workers.map((w) => { const s = st.sc.sites[0]; const [ax, ay] = st.sc.grid.center(s.col, s.row + w.lane), [bx, by] = st.sc.grid.center(s.col + 1, s.row + w.lane); const x = ax + (bx - ax) * w.k, y = ay + (by - ay) * w.k; return { depth: s.col + s.row + 3, draw: (ctx) => { drawWalker(ctx, x, y, w.dir > 0 ? 0 : 2, w.ph, w.look, 'flat', { h: 11 }); ctx.fillStyle = '#f2b134'; ctx.beginPath(); ctx.arc(x, y - 12 - Math.abs(Math.sin(w.ph)) * 1.2, 3.6, Math.PI, 2 * Math.PI); ctx.fill(); } }; }),
  overlay: (ctx, st) => {
    const s = st.sc.sites[0]; const [wx, wy] = st.sc.grid.center(s.col, s.row + 1); const bx = wx - 20, by = wy + 4; const mastH = 58;
    ctx.strokeStyle = '#f2b134'; ctx.lineWidth = 2.2; ctx.beginPath(); ctx.moveTo(bx, by); ctx.lineTo(bx, by - mastH); ctx.stroke();
    const a = Math.sin(st.t * 0.35) * 0.9 + 0.4; const jx = bx + Math.cos(a) * 62, jy = by - mastH + Math.sin(a) * 26; ctx.beginPath(); ctx.moveTo(bx - Math.cos(a) * 14, by - mastH - Math.sin(a) * 6); ctx.lineTo(jx, jy); ctx.stroke();
    const hk = 0.5 + 0.5 * Math.sin(st.t * 0.9); const hx = bx + Math.cos(a) * 44, hy = by - mastH + Math.sin(a) * 18; const ly = hy + 18 + hk * 20; ctx.strokeStyle = '#444'; ctx.lineWidth = 0.8; ctx.beginPath(); ctx.moveTo(hx, hy); ctx.lineTo(hx, ly); ctx.stroke(); ctx.fillStyle = '#8d6e63'; ctx.fillRect(hx - 5, ly, 10, 6); ctx.strokeStyle = 'rgba(0,0,0,.4)'; ctx.strokeRect(hx - 5, ly, 10, 6);
    st.parts.draw(ctx, (c, p) => { if (p.dust) { c.fillStyle = `rgba(190,160,130,${0.45 * p.life})`; c.beginPath(); c.arc(p.x, p.y, 3 + (1 - p.life) * 6, 0, 7); c.fill(); } else if (p.spark) { c.fillStyle = `rgba(255,${200 + 55 * p.life | 0},80,${p.life})`; c.beginPath(); c.arc(p.x, p.y, 1.5 + p.life, 0, 7); c.fill(); } });
  },
});
MOCKS.push({
  id: 'f2', section: 'Construction', title: 'Opening day: the building pops in and neighbours gather',
  art: 'I draw it', effort: 'M', perf: 'Free', tier: 'Nice',
  notes: `Extends the existing confetti celebration. The finished sprite bounces up from its ghost, a handful of citizens walk over from the road and cluster at the door, balloons let go, and after a few seconds they wander off. This is a one-off sequence tied to the "It's open!" moment, so it can afford to be a bit theatrical.`,
  scene: { cols: 7, rows: 6, roads: range(0, 6).map((c) => [c, 5]), buildings: [], sites: [] },
  view: { zoom: 2.0, cx: 205, cy: 78 },
  setup: (st) => { st.phase = 'ghost'; st.k = 0; st.people = []; st.b = { id: 'apartment_v1', col: 2, row: 2, w: 2, h: 2 }; },
  controls: [{ label: 'Open it!', run: (st) => { if (st.phase !== 'ghost') return; st.phase = 'open'; st.k = 0; const bb = st.sc.spriteBox(st.b); for (let i = 0; i < 40; i++) st.parts.spawn({ x: bb.x + bb.W / 2, y: bb.y + bb.H * 0.5, vx: (Math.random() - 0.5) * 120, vy: -60 - Math.random() * 80, g: 120, ttl: 2, confetti: pick(['#e0523f', '#3a7bd5', '#f2b134', '#3DA85F', '#8e5bd1']) }); for (let i = 0; i < 5; i++) { const [rx, ry] = st.sc.grid.center(i + 1, 5); st.people.push({ x: rx, y: ry, tx: bb.x + bb.W * (0.45 + i * 0.08), ty: bb.y + bb.H - 6 + (i % 2) * 5, look: citizen(), ph: 0, delay: i * 0.4, done: false }); } } }, { label: 'Reset', run: (st) => { st.phase = 'ghost'; st.k = 0; st.people = []; } }],
  update: (st, dt) => { if (st.phase === 'open') { st.k = Math.min(1, st.k + dt / 0.6); if (st.k >= 1 && st.t % 1 < dt) {} } for (const p of st.people) { p.delay -= dt; if (p.delay > 0) continue; const dx = p.tx - p.x, dy = p.ty - p.y, d = Math.hypot(dx, dy); if (d > 1.2 && !p.done) { p.x += dx / d * 18 * dt; p.y += dy / d * 18 * dt; p.ph += dt * 9; p.dir = dx > 0 ? 3 : 2; } else { p.done = true; p.stay = (p.stay ?? 5) - dt; if (p.stay < 0 && Math.random() < dt * 4) { const [rx, ry] = st.sc.grid.center(6, 5); p.tx = rx; p.ty = ry; p.done = false; p.stay = 99; if (Math.random() < 0.6) st.parts.spawn({ x: p.x, y: p.y - 10, vx: 4, vy: -12, ttl: 6, balloon: pick(['#e0523f', '#3a7bd5', '#f2b134']) }); } } } },
  entities: (st) => { const b = st.b; const bb = st.sc.spriteBox(b); const list = [{ depth: st.sc.depthOf(b), draw: (ctx) => { const e = st.phase === 'ghost' ? 0 : 1 + Math.sin(Math.min(1, st.k) * Math.PI) * 0.12 * (1 - st.k); ctx.save(); if (st.phase === 'ghost') { ctx.globalAlpha = 0.35; ctx.drawImage(IMG[b.id], bb.x, bb.y, bb.W, bb.H); } else { const sx = bb.x + bb.W / 2, sy = bb.y + bb.H; ctx.translate(sx, sy); ctx.scale(e, e * (0.3 + 0.7 * Math.min(1, st.k * 1.4))); ctx.translate(-sx, -sy); ctx.drawImage(IMG[b.id], bb.x, bb.y, bb.W, bb.H); } ctx.restore(); } }]; for (const p of st.people) list.push({ depth: (p.y - HALF_H) / HALF_H + 0.6, draw: (ctx) => drawWalker(ctx, p.x, p.y, p.dir ?? 3, p.ph, p.look, 'flat', { idle: p.done, wave: p.done && p.stay > 0 && p.stay < 99 }) }); return list; },
  overlay: (ctx, st) => { st.parts.draw(ctx, (c, p) => { if (p.confetti) { c.fillStyle = p.confetti; c.fillRect(p.x, p.y, 3, 2); } else if (p.balloon) { c.strokeStyle = 'rgba(40,40,60,.5)'; c.beginPath(); c.moveTo(p.x, p.y); c.lineTo(p.x, p.y + 8); c.stroke(); c.fillStyle = p.balloon; c.beginPath(); c.ellipse(p.x + Math.sin(st.t * 3) * 1.5, p.y - 4, 3.5, 4.5, 0, 0, 7); c.fill(); } }); },
});

// ============ G. TOUCH & IDLE ============================================
MOCKS.push({
  id: 'g1', section: 'Touch & idle', title: 'Tap a car, a citizen, a house, the birds',
  art: 'I draw it', effort: 'M', perf: 'Free', tier: 'Nice',
  notes: `Try it: cars honk and wobble, a citizen waves back, a house blinks its windows and sends up a heart, birds scatter. None of it changes game state, it is pure delight. The gesture question is real: the board's tap already means "place here" or "select this site". The fix is ordering, not new gestures: the board hit-tests moving things first and only when nothing is picked up and no site is selected; otherwise the tap goes to placement as today, so a kid mid-move never loses a tap to a honk.`,
  scene: MAIN(), setup: (st) => { addCars(st, 7, 'flat'); addWalkers(st, 8, 'flat'); flockSetup(st); st.flockNext = 0.5; st.hearts = []; },
  update: (st, dt) => { stepCars(st, dt, { yield: true }); stepWalkers(st, dt); flockStep(st, dt, st.W, st.H); for (const c of st.cars) c.honk = Math.max(0, (c.honk || 0) - dt); for (const w of st.walkers) if (w.wave) { w.wave -= dt; if (w.wave <= 0) w.wave = 0; } for (const b of st.sc.buildings) if (b.blink) b.blink = Math.max(0, b.blink - dt); for (const h of st.hearts) h.life += dt; st.hearts = st.hearts.filter((h) => h.life < 1.6); },
  entities: (st) => [...st.cars.map((m) => { const [x, y] = m.pos(); const wob = m.honk ? Math.sin(m.honk * 40) * 1.5 : 0; return { depth: m.depth() + 0.4, draw: (ctx) => { drawCar(ctx, x + wob, y, m.dir, m.color, 'flat'); if (m.honk) { ctx.strokeStyle = `rgba(255,220,80,${m.honk})`; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(x, y - 8, (0.6 - m.honk) * 40 + 4, 0, 7); ctx.stroke(); ctx.font = 'bold 11px system-ui'; ctx.fillStyle = `rgba(40,40,60,${m.honk * 1.6})`; ctx.fillText('beep!', x + 8, y - 16); } } }; }), ...st.walkerEntities()],
  overlay: (ctx, st) => { for (const b of st.sc.buildings) if (b.blink) { const bb = st.sc.spriteBox(b); ctx.save(); ctx.globalAlpha = Math.abs(Math.sin(b.blink * 12)); ctx.drawImage(LIT[b.id], bb.x, bb.y, bb.W, bb.H); ctx.restore(); } for (const h of st.hearts) { ctx.save(); ctx.globalAlpha = 1 - h.life / 1.6; ctx.font = '16px system-ui'; ctx.textAlign = 'center'; ctx.fillText('❤️', h.x, h.y - h.life * 30); ctx.restore(); } },
  hud: (ctx, st) => { drawFlocks(ctx, st); label(ctx, 'Tap things', 10, 10); },
  tap: (st, wx, wy, e) => {
    for (const c of st.cars) { const [x, y] = c.pos(); if (Math.hypot(x - wx, y - wy) < 16) { c.honk = 0.6; return; } }
    for (const w of st.walkers) { const [x, y] = w.pos(); if (Math.hypot(x - wx, y - wy + 6) < 14) { w.wave = 1.6; w.wait = 1.6; return; } }
    const r = e.target.getBoundingClientRect(); if (e.clientY - r.top < 110 && st.flocks.length) { for (const f of st.flocks) f.scatter = 1.2; return; }
    for (const b of [...st.sc.buildings].reverse()) { const bb = st.sc.spriteBox(b); if (wx > bb.x && wx < bb.x + bb.W && wy > bb.y && wy < bb.y + bb.H) { b.blink = 1.2; st.hearts.push({ x: bb.x + bb.W / 2, y: bb.y + bb.H * 0.3, life: 0 }); return; } }
  },
});
MOCKS.push({
  id: 'g2', section: 'Touch & idle', title: 'The camera drifts when nobody is touching',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `After a few idle seconds the camera starts a slow, wide drift across the city, the way a strategy game's title screen does; the first touch stops it and hands control back. It costs nothing, reuses the tween code in <code>IsoCityGame</code>, and makes the city feel like a place even before a single car exists. It must stay clamped to the board and never run while a site is selected or during the construction zoom.`,
  scene: MAIN(), view: { zoom: 1.35, cx: 400, cy: 160 }, setup: (st) => { addCars(st, 5, 'flat'); st.idle = 3; st.base = { cx: 400, cy: 160 }; },
  update: (st, dt) => { stepCars(st, dt); st.idle += dt; const k = Math.min(1, Math.max(0, (st.idle - 2.5) / 2)); const tx = st.base.cx + Math.sin(st.t * 0.18) * 110 * k, ty = st.base.cy + Math.cos(st.t * 0.13) * 40 * k; st.view.cx += (tx - st.view.cx) * dt * 2; st.view.cy += (ty - st.view.cy) * dt * 2; },
  entities: (st) => st.carEntities(), hud: (ctx, st) => label(ctx, st.idle > 2.5 ? 'Drifting… tap to stop' : `Idle ${(2.5 - st.idle).toFixed(1)} s`, 10, 10),
  tap: (st) => { st.idle = 0; },
});
