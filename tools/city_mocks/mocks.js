'use strict';
const MOCKS = [];
const MAIN = () => ({
  cols: 13, rows: 12,
  roads: [...range(1, 10).map((c) => [c, 3]), ...range(1, 10).map((c) => [c, 8]), ...range(4, 7).map((r) => [1, r]), ...range(4, 7).map((r) => [10, r]), ...range(4, 7).map((r) => [6, r])],
  buildings: [
    { id: 'apartment_v1', col: 1, row: 1 }, { id: 'duplex_v1', col: 3, row: 1 }, { id: 'coffee_shop_v1', col: 3, row: 2 },
    { id: 'bakery_v1', col: 5, row: 1 }, { id: 'high_rise_v1', col: 7, row: 0 }, { id: 'park_v1', col: 2, row: 4 },
    { id: 'playground_v1', col: 4, row: 4 }, { id: 'fountain_plaza_v1', col: 2, row: 6 }, { id: 'fire_station_v1', col: 4, row: 6 },
    { id: 'hospital_v1', col: 7, row: 4 }, { id: 'duplex_v1', col: 7, row: 7 }, { id: 'power_plant_v1', col: 2, row: 9 },
    { id: 'farmhouse_v1', col: 5, row: 9 }, { id: 'police_station_v1', col: 8, row: 9 }, { id: 'observation_tower_v1', col: 11, row: 5 },
  ],
});
function range(a, b) { const o = []; for (let i = a; i <= b; i++) o.push(i); return o; }
const ROAD_TILES = (sc) => [...sc.roads].map((k) => k.split(',').map(Number));
function addCars(st, n, style, o = {}) {
  st.cars = []; const tiles = ROAD_TILES(st.sc);
  for (let i = 0; i < n; i++) {
    const [c, r] = tiles[Math.floor(Math.random() * tiles.length)]; const dirs = st.sc.roadNeighbours(c, r);
    const m = new Mover(st.sc, c, r, pick(dirs), 0.55 + Math.random() * 0.25, 6.5); m.color = pick(PALETTE_CARS); m.style = style; m.t = Math.random(); st.cars.push(m);
  }
  st.carEntities = () => st.cars.map((m) => { const [x, y] = m.pos(); return { depth: m.depth() + 0.4, draw: (ctx) => drawCar(ctx, x, y, m.dir, m.color, m.style, { lights: o.lights && st.tod.night > 0.2, beacon: m.beacon ? st.t : undefined, ...(m.size || {}) }) }; });
}
function stepCars(st, dt, o = {}) {
  for (const m of st.cars) {
    if (o.yield) { // hold if a car is just ahead in my lane
      const [x, y] = m.pos(); const u = UNIT[m.dir]; let blocked = false;
      for (const k of st.cars) { if (k === m) continue; const [kx, ky] = k.pos(); const dx = kx - x, dy = ky - y; const ahead = dx * u[0] + dy * u[1]; const side = Math.abs(dx * u[1] - dy * u[0]); if (ahead > 4 && ahead < 26 && side < 8) blocked = true; }
      if (blocked) continue;
      if (o.lights) { // red for my axis at the junction ahead → stop before entering it
        const nc = m.c + DIRD[m.dir][0], nr = m.r + DIRD[m.dir][1];
        if (st.sc.roadNeighbours(nc, nr).length >= 3 && m.t > 0.55 && m.t < 0.62) { const phase = Math.floor(st.t / 4) % 2; if ((m.dir % 2) !== phase) continue; }
      }
    }
    m.step(dt);
  }
}
function addWalkers(st, n, style) {
  st.walkers = []; const tiles = ROAD_TILES(st.sc);
  for (let i = 0; i < n; i++) {
    const [c, r] = tiles[Math.floor(Math.random() * tiles.length)];
    const m = new Mover(st.sc, c, r, pick(st.sc.roadNeighbours(c, r)), 0.16 + Math.random() * 0.08, 23); m.t = Math.random(); m.look = citizen(); m.style = style; m.ph = Math.random() * 6; st.walkers.push(m);
  }
  st.walkerEntities = () => st.walkers.map((m) => { const [x, y] = m.pos(); return { depth: m.depth() + 0.7, draw: (ctx) => drawWalker(ctx, x, y, m.dir, m.ph, m.look, m.style, { idle: m.wait > 0, wave: m.wave }) }; });
}
function stepWalkers(st, dt) { for (const m of st.walkers) { if (m.wait <= 0 && Math.random() < dt * 0.05) m.wait = 1.5 + Math.random() * 2; m.step(dt); if (m.wait <= 0) m.ph += dt * 9; } }

// ============ A. STREETS ==================================================
MOCKS.push({
  id: 'a1', section: 'Streets', title: 'Cars on the auto-roads, flat style',
  art: 'I draw it', effort: 'M', perf: 'Light', tier: 'Ship first',
  notes: `Cars follow the existing road tiles as a graph: at each tile centre a car picks a road neighbour (straight preferred, no U-turn unless a dead end), drives on the right, and turns at curves. No pathfinding, no state to save. Drawn here as an outlined iso box in the flat style of the wheel icons, so all four headings come from one bit of geometry.<br><br><b>In Flutter:</b> a <code>TrafficSystem</code> in <code>lib/game/city/</code> owning a list of movers, stepped in <code>update(dt)</code>, painted into the board's depth-sorted building pass so cars pass behind buildings correctly. Roads change when a building is placed, so movers re-validate their tile on <code>setRoads</code>.`,
  scene: MAIN(), setup: (st) => addCars(st, 7, 'flat'), update: (st, dt) => stepCars(st, dt), entities: (st) => st.carEntities(),
});
MOCKS.push({
  id: 'a2', section: 'Streets', title: 'Cars on the auto-roads, painterly sprites',
  art: 'NB sheet', effort: 'M', perf: 'Light', tier: 'Ship first',
  spec: '4 headings × 6 vehicles (hatchback, sedan, van, pickup, bus, taxi) on the 192 px tile canvas, solid green backdrop, same lighting as the buildings. Ask for each heading as its own image; NB does not keep a consistent sheet.',
  notes: `Same movement as A1; the art is a stand-in drawn with gradients, wheels and a specular streak to show how much closer shaded cars sit to the building renders. The real version is a small Nano Banana set you generate; I extend <code>process.py</code> to crop and anchor each heading to the tile centre. The 2:1 diamond gives four unique headings (mirroring does not produce the other two for a lit object, shadows would flip), so it is 4 images per vehicle.`,
  scene: MAIN(), setup: (st) => addCars(st, 7, 'paint'), update: (st, dt) => stepCars(st, dt), entities: (st) => st.carEntities(),
});
MOCKS.push({
  id: 'a3', section: 'Streets', title: 'Fire truck call-outs and a city bus',
  art: 'I draw it (or NB)', effort: 'M', perf: 'Free', tier: 'Nice',
  notes: `Ordinary traffic is ambient; this is event traffic. Every so often the fire station dispatches a red truck with a flashing light bar that does a lap and comes home; a bus trundles a fixed loop and pauses at the same corners. Vehicles come from the buildings the player actually built, so a new fire station visibly changes the streets.<br><br>Anchors needed: the road tile nearest each service building's door (derived, not hand-placed). The truck itself is one more heading set in the A2 sheet, or the flat box with a beacon as here.`,
  scene: MAIN(), setup: (st) => { addCars(st, 3, 'flat'); st.next = 3; const bus = new Mover(st.sc, 1, 8, 0, 0.42, 6.5); bus.color = '#f2b134'; bus.style = 'flat'; bus.size = { L: 30, W: 11, H: 10, R: 3 }; bus.isBus = true; st.cars.push(bus); },
  update: (st, dt) => {
    stepCars(st, dt, { yield: true }); st.next -= dt;
    if (st.next < 0 && !st.truck) { const m = new Mover(st.sc, 5, 8, 0, 0.9, 6.5); m.color = '#e0312a'; m.style = 'flat'; m.beacon = true; m.size = { L: 26, W: 11, H: 9, R: 3 }; m.life = 14; st.truck = m; st.cars.push(m); st.next = 22; }
    if (st.truck) { st.truck.life -= dt; if (st.truck.life < 0) { st.cars = st.cars.filter((c) => c !== st.truck); st.truck = null; } }
    for (const c of st.cars) if (c.isBus && c.wait <= 0 && c.t < 0.02 && st.sc.roadNeighbours(c.c, c.r).length >= 3 && Math.random() < 0.5) c.wait = 2.2;
  },
  entities: (st) => st.carEntities(),
});
MOCKS.push({
  id: 'a4', section: 'Streets', title: 'Traffic lights and queueing at junctions',
  art: 'I draw it', effort: 'M', perf: 'Light', tier: 'Nice',
  notes: `Each cross or tee tile gets a light that alternates axes every four seconds; cars hold before a red and queue behind the car ahead instead of driving through each other. Small thing, but it is what makes traffic read as traffic rather than sliding tokens. The poles are code-drawn at a fixed offset from the tile centre so they sit on the sidewalk corner of every road sprite.<br><br>Cost is a neighbour scan per car per frame, trivial at the ten to twenty cars a city would ever hold.`,
  scene: MAIN(), setup: (st) => addCars(st, 12, 'flat'), update: (st, dt) => stepCars(st, dt, { yield: true, lights: true }), entities: (st) => st.carEntities(),
  overlay: (ctx, st) => {
    const phase = Math.floor(st.t / 4) % 2;
    for (const [c, r] of ROAD_TILES(st.sc)) if (st.sc.roadNeighbours(c, r).length >= 3) {
      const [cx, cy] = st.sc.grid.center(c, r); const px = cx + 20, py = cy - 10;
      ctx.strokeStyle = '#333'; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.moveTo(px, py); ctx.lineTo(px, py - 16); ctx.stroke();
      ctx.fillStyle = '#222'; roundRect(ctx, px - 3, py - 24, 6, 9, 1.5); ctx.fill();
      ctx.fillStyle = phase === 0 ? '#3ddc5a' : '#ff3b3b'; ctx.beginPath(); ctx.arc(px, py - 21, 1.6, 0, 7); ctx.fill();
      ctx.fillStyle = phase === 1 ? '#3ddc5a' : '#ff3b3b'; ctx.beginPath(); ctx.arc(px, py - 17, 1.6, 0, 7); ctx.fill();
    }
  },
});
MOCKS.push({
  id: 'a5', section: 'Streets', title: 'Night driving: headlights and tail lights',
  art: 'I draw it', effort: 'S', perf: 'Light', tier: 'Nice',
  notes: `Once there is a night (see D), cars get a pair of headlight cones drawn additively on the asphalt and red tail lamps. Two radial gradients per car; the road sprites' dark asphalt makes the cones read strongly. Depends on A1/A2 and any of the D mocks.`,
  scene: MAIN(), hourStart: 21.5, setup: (st) => addCars(st, 8, 'paint', { lights: true }), update: (st, dt) => stepCars(st, dt, { yield: true }), entities: (st) => st.carEntities(),
  sky: (ctx, st, W, H) => drawStars(ctx, W, H, st.t, 1),
});

// ============ B. PEOPLE ===================================================
MOCKS.push({
  id: 'b1', section: 'People', title: 'Pedestrians on the sidewalks, flat style',
  art: 'I draw it', effort: 'M', perf: 'Light', tier: 'Ship first',
  notes: `The road sprites already carry a beige sidewalk band at the edge, so walkers use the same road graph as cars with a wider lane offset. Each citizen is a head, a torso and two swinging legs, about 13 px tall at zoom 1, with a random shirt, skin and hair, and a little bob. They pause now and then. Reuses the car mover, so it is mostly drawing.<br><br>With the emoji-and-box placeholder style already in the codebase, this is the version I can ship without any asset from you.`,
  scene: MAIN(), setup: (st) => addWalkers(st, 14, 'flat'), update: (st, dt) => stepWalkers(st, dt), entities: (st) => st.walkerEntities(),
});
MOCKS.push({
  id: 'b2', section: 'People', title: 'Pedestrians, painterly stand-in',
  art: 'NB sheet (risky)', effort: 'L', perf: 'Light', tier: 'Later',
  spec: '6 citizens × 4 headings, one still frame each, at the building lighting; the walk is a code bob plus leg swing over the still. Do not ask NB for walk-cycle frames: consistency across frames is where it fails.',
  notes: `Shaded stand-in with pants colour and a shadow side on the torso. Honest read: at 13 px tall and zoomed out, a painted person and a flat one are hard to tell apart, and people sprites are the hardest thing to get consistent out of Nano Banana. I would ship B1, and revisit only if the flat cars in A1 look wrong next to the buildings and you go with A2 sprites.`,
  scene: MAIN(), setup: (st) => addWalkers(st, 14, 'paint'), update: (st, dt) => stepWalkers(st, dt), entities: (st) => st.walkerEntities(),
});
MOCKS.push({
  id: 'b3', section: 'People', title: 'Park life: benches, swings, a runaway balloon',
  art: 'I draw it + anchors', effort: 'M', perf: 'Free', tier: 'Nice',
  notes: `Parks and playgrounds are where kids expect to see other kids. Citizens wander inside the park's footprint diamond instead of the sidewalk, a swing rocks on the playground, and now and then a balloon slips away and floats off. The wander area is derived from the footprint; only the swing is a hand-placed anchor (one point per playground variant, three variants).`,
  scene: { cols: 7, rows: 6, roads: range(0, 6).map((c) => [c, 4]), buildings: [{ id: 'park_v1', col: 1, row: 1 }, { id: 'playground_v1', col: 4, row: 1 }] },
  view: { zoom: 2.1, cx: 205, cy: 70 },
  setup: (st) => {
    st.people = []; const b = st.sc.buildings[0]; const [ox, oy] = st.sc.grid.center(b.col, b.row);
    const inside = () => { const a = Math.random() * 1.6 - 0.3, bb = Math.random() * 1.6 - 0.3; return [ox + (a - bb) * HALF_W, oy + (a + bb) * HALF_H]; };
    for (let i = 0; i < 5; i++) { const p = { x: 0, y: 0, tx: 0, ty: 0, look: citizen(), ph: Math.random() * 6, rest: 0 }; [p.x, p.y] = inside(); [p.tx, p.ty] = inside(); p.inside = inside; st.people.push(p); }
    st.balloonNext = 4;
  },
  update: (st, dt) => {
    for (const p of st.people) { if (p.rest > 0) { p.rest -= dt; continue; } const dx = p.tx - p.x, dy = p.ty - p.y, d = Math.hypot(dx, dy); if (d < 1.5) { p.rest = 1 + Math.random() * 3; [p.tx, p.ty] = p.inside(); } else { p.x += dx / d * 9 * dt; p.y += dy / d * 9 * dt; p.ph += dt * 8; p.dir = dx > 0 ? (dy > 0 ? 0 : 3) : (dy > 0 ? 1 : 2); } }
    st.balloonNext -= dt; if (st.balloonNext < 0) { const [x, y] = st.sc.anchor(st.sc.buildings[1], 200, 250); st.parts.spawn({ x, y, vx: 6, vy: -14, ttl: 6, color: pick(['#e0523f', '#3a7bd5', '#f2b134']), balloon: true }); st.balloonNext = 7 + Math.random() * 5; }
  },
  entities: (st) => st.people.map((p) => ({ depth: st.sc.grid.tileAt(p.x, p.y) ? p.x / HALF_W * 0 + (p.y - HALF_H) / HALF_H : 0, draw: (ctx) => drawWalker(ctx, p.x, p.y, p.dir ?? 0, p.ph, p.look, 'flat', { idle: p.rest > 0 }) })).map((e) => ({ ...e, depth: e.depth + 0.5 })),
  overlay: (ctx, st) => {
    const [sx, sy] = st.sc.anchor(st.sc.buildings[1], 75, 300); const a = Math.sin(st.t * 2.2) * 0.5;
    ctx.strokeStyle = '#6d5a4a'; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(sx, sy - 16); ctx.lineTo(sx + Math.sin(a) * 12, sy - 16 + Math.cos(a) * 12); ctx.stroke();
    ctx.fillStyle = '#f2b134'; ctx.fillRect(sx + Math.sin(a) * 12 - 3, sy - 16 + Math.cos(a) * 12 - 1, 6, 2);
    drawWalker(ctx, sx + Math.sin(a) * 12, sy - 12 + Math.cos(a) * 12, 0, 0, { shirt: '#3a7bd5', skin: '#d9a276', hair: '#2b1d12' }, 'flat', { idle: true, h: 9 });
    st.parts.draw(ctx, (c, p) => { c.strokeStyle = 'rgba(40,40,60,.5)'; c.beginPath(); c.moveTo(p.x, p.y); c.lineTo(p.x, p.y + 9); c.stroke(); c.fillStyle = p.color; c.beginPath(); c.ellipse(p.x + Math.sin(st.t * 3) * 1.5, p.y - 4, 4, 5, 0, 0, 7); c.fill(); });
  },
});
MOCKS.push({
  id: 'b4', section: 'People', title: 'Citizen bubbles over houses',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Ship first',
  notes: `A tiny thought bubble drifts up from a random building every few seconds: a coffee from the cafe, music from the apartment, zzz from a house at night. It is the cheapest "someone lives here" signal there is, needs no art beyond the emoji the codebase already uses for placeholders, and lines up with the citizen-request beats in city_builder.md, so the same bubble can later carry a real request. Tap one and it pops (see G1).`,
  scene: MAIN(), setup: (st) => { st.next = 1; st.bubbles = []; },
  update: (st, dt) => { st.next -= dt; if (st.next < 0) { const b = pick(st.sc.buildings); const bb = st.sc.spriteBox(b); st.bubbles.push({ x: bb.x + bb.W / 2, y: bb.y + bb.H * 0.25, life: 0, e: pick(['☕', '🎵', '💤', '❤️', '🍞', '📚', '⚽', '🎈']) }); st.next = 1.6 + Math.random() * 2; } for (const b of st.bubbles) b.life += dt; st.bubbles = st.bubbles.filter((b) => b.life < 3.2); },
  overlay: (ctx, st) => { for (const b of st.bubbles) { const k = Math.min(1, b.life * 3), fade = b.life > 2.4 ? (3.2 - b.life) / 0.8 : 1; const y = b.y - b.life * 9; ctx.save(); ctx.globalAlpha = fade; ctx.translate(b.x, y); ctx.scale(k, k); ctx.fillStyle = '#fff'; ctx.strokeStyle = 'rgba(0,0,0,.25)'; ctx.beginPath(); ctx.arc(0, 0, 11, 0, 7); ctx.fill(); ctx.stroke(); ctx.beginPath(); ctx.arc(-6, 10, 3, 0, 7); ctx.fill(); ctx.stroke(); ctx.font = '13px system-ui'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(b.e, 0, 1); ctx.restore(); } },
  tap: (st, wx, wy) => { st.bubbles = st.bubbles.filter((b) => Math.hypot(b.x - wx, b.y - b.life * 9 - wy) > 14); },
});

// ============ C. SKY ======================================================
function flockSetup(st) { st.flocks = []; st.flockNext = 1; }
function flockStep(st, dt, W, H) {
  st.flockNext -= dt; if (st.flockNext < 0) { const dir = Math.random() < 0.5 ? 1 : -1; const y = 20 + Math.random() * 60; st.flocks.push({ x: dir > 0 ? -60 : W + 60, y, dir, v: 38 + Math.random() * 20, n: 3 + Math.floor(Math.random() * 5), ph: Math.random() * 6, scatter: 0 }); st.flockNext = 7 + Math.random() * 6; }
  for (const f of st.flocks) { f.x += f.dir * f.v * dt; f.ph += dt * 10; f.scatter = Math.max(0, f.scatter - dt); }
  st.flocks = st.flocks.filter((f) => f.x > -120 && f.x < W + 120);
}
function drawFlocks(ctx, st) {
  for (const f of st.flocks) for (let i = 0; i < f.n; i++) {
    const k = Math.ceil(i / 2) * (i % 2 ? 1 : -1); const sc = 1 + f.scatter * 2.5; const x = f.x - f.dir * Math.abs(k) * 12 * sc, y = f.y + k * 6 * sc + (f.scatter ? Math.sin(i * 7 + st.t * 9) * 6 : 0);
    const flap = Math.sin(f.ph + i) * 3; ctx.strokeStyle = 'rgba(30,30,50,.85)'; ctx.lineWidth = 1.4; ctx.beginPath(); ctx.moveTo(x - 5, y + flap); ctx.quadraticCurveTo(x - 2, y - 1, x, y); ctx.quadraticCurveTo(x + 2, y - 1, x + 5, y + flap); ctx.stroke();
  }
}
MOCKS.push({
  id: 'c1', section: 'Sky', title: 'Birds crossing in a loose V',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Ship first',
  notes: `Three to seven birds as two flapping arcs each, crossing the top of the viewport every ten seconds or so. Drawn in screen space over the board so they are the same size at every zoom and never get depth-sorted with buildings. About forty lines of code and the single highest "alive per line" ratio on this page. Tap the flock to scatter it (G1).`,
  scene: MAIN(), setup: flockSetup, update: (st, dt) => flockStep(st, dt, st.W, st.H), hud: drawFlocks,
  tap: (st, wx, wy, e) => { for (const f of st.flocks) f.scatter = 1.2; },
});
MOCKS.push({
  id: 'c2', section: 'Sky', title: 'A hot-air balloon, and now and then a plane',
  art: 'I draw it (balloon), NB optional (plane)', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `A striped balloon drifts across slowly with a gentle bob; every couple of minutes a small plane crosses fast with a fading contrail. Both are screen-space like the birds. The balloon is easy to code-draw and could carry the Math City colours; a plane looks better as one Nano Banana side-view sprite if you want the painterly look, but the flat one works.`,
  scene: MAIN(), setup: (st) => { st.bx = -60; st.plane = { x: -400, t: 0 }; st.planeNext = 6; },
  update: (st, dt) => { st.bx += 9 * dt; if (st.bx > st.W + 80) st.bx = -80; st.planeNext -= dt; if (st.planeNext < 0) { st.plane.x = -80; st.planeNext = 18; } st.plane.x += 150 * dt; },
  hud: (ctx, st, W, H) => {
    const x = st.bx, y = 70 + Math.sin(st.t * 0.8) * 6;
    ctx.fillStyle = 'rgba(0,0,0,.08)'; ctx.beginPath(); ctx.ellipse(x + 40, 330, 30, 8, 0, 0, 7); ctx.fill();
    ctx.strokeStyle = '#5a4030'; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(x - 8, y + 20); ctx.lineTo(x - 4, y + 34); ctx.moveTo(x + 8, y + 20); ctx.lineTo(x + 4, y + 34); ctx.stroke();
    ctx.fillStyle = '#8d5a3a'; ctx.fillRect(x - 6, y + 33, 12, 7);
    for (let i = 0; i < 6; i++) { ctx.fillStyle = i % 2 ? '#e0523f' : '#f2b134'; ctx.beginPath(); ctx.moveTo(x, y + 22); ctx.bezierCurveTo(x - 24 + i * 8, y + 10, x - 24 + i * 8, y - 26, x, y - 26); ctx.bezierCurveTo(x - 16 + i * 8, y - 26, x - 16 + i * 8, y + 10, x, y + 22); ctx.fill(); }
    ctx.fillStyle = '#e0523f'; ctx.beginPath(); ctx.ellipse(x, y - 2, 20, 24, 0, 0, 7); ctx.fill(); for (let i = -1; i <= 1; i += 2) { ctx.fillStyle = '#f2b134'; ctx.beginPath(); ctx.ellipse(x + i * 8, y - 2, 6, 24, 0, 0, 7); ctx.fill(); } ctx.fillStyle = 'rgba(255,255,255,.25)'; ctx.beginPath(); ctx.ellipse(x - 7, y - 10, 5, 9, 0.3, 0, 7); ctx.fill();
    const p = st.plane; if (p.x > -100 && p.x < W + 100) { const py = 36; ctx.strokeStyle = 'rgba(255,255,255,.55)'; ctx.lineWidth = 3; ctx.lineCap = 'round'; ctx.beginPath(); ctx.moveTo(p.x - 14, py + 1); ctx.lineTo(Math.max(-100, p.x - 130), py + 1); ctx.stroke(); ctx.fillStyle = '#f4f4f4'; ctx.beginPath(); ctx.moveTo(p.x + 14, py); ctx.lineTo(p.x - 12, py - 3); ctx.lineTo(p.x - 14, py + 3); ctx.closePath(); ctx.fill(); ctx.fillStyle = '#3a7bd5'; ctx.beginPath(); ctx.moveTo(p.x - 2, py); ctx.lineTo(p.x - 10, py + 7); ctx.lineTo(p.x - 12, py + 1); ctx.closePath(); ctx.fill(); ctx.beginPath(); ctx.moveTo(p.x - 11, py - 2); ctx.lineTo(p.x - 15, py - 8); ctx.lineTo(p.x - 14, py); ctx.closePath(); ctx.fill(); }
  },
});
MOCKS.push({
  id: 'c3', section: 'Sky', title: 'Cloud shadows drifting over the ground',
  art: 'I draw it', effort: 'S', perf: 'Light', tier: 'Ship first',
  notes: `You never see the clouds, only their soft shadows sliding across grass, roads and rooftops. Three or four blurred blobs in multiply blend, moving with a shared wind vector. This is the effect that makes a static scene feel outdoors, and it costs a few gradient fills per frame. Drawn after buildings so rooftops darken too.`,
  scene: MAIN(), setup: (st) => { st.clouds = [0, 1, 2, 3].map((i) => ({ x: i * 260 - 200, y: 60 + i * 90, r: 110 + i * 25 })); },
  update: (st, dt) => { for (const c of st.clouds) { c.x += 14 * dt; c.y += 4 * dt; if (c.x > st.sc.grid.boardW + 250) { c.x = -250; c.y = Math.random() * st.sc.grid.boardH; } } },
  overlay: (ctx, st) => { ctx.save(); ctx.globalCompositeOperation = 'multiply'; for (const c of st.clouds) { const g = ctx.createRadialGradient(c.x, c.y, 0, c.x, c.y, c.r); g.addColorStop(0, 'rgba(60,70,110,.45)'); g.addColorStop(0.6, 'rgba(60,70,110,.3)'); g.addColorStop(1, 'rgba(60,70,110,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.ellipse(c.x, c.y, c.r, c.r * 0.55, 0, 0, 7); ctx.fill(); } ctx.restore(); },
});
MOCKS.push({
  id: 'c4', section: 'Sky', title: 'A passing rain shower (snow in winter)',
  art: 'I draw it', effort: 'M', perf: 'Light', tier: 'Later',
  notes: `Sky dims, rain streaks fall for a while, puddles glint on the asphalt, then it clears. A snow variant swaps streaks for slow flakes and tints the grass white. Weather is fun but it competes with the readable, sunny board that placement depends on, so I would keep showers short and rare, and never during the construction zoom. Wholly procedural.`,
  scene: MAIN(), setup: (st) => { st.mode = 'rain'; st.k = 0; },
  controls: [{ label: 'Rain', run: (st) => { st.mode = 'rain'; } }, { label: 'Snow', run: (st) => { st.mode = 'snow'; } }, { label: 'Clear', run: (st) => { st.mode = 'clear'; } }],
  update: (st, dt) => { st.k += ((st.mode === 'clear' ? 0 : 1) - st.k) * dt * 1.2; if (st.mode !== 'clear' && Math.random() < 0.9) for (let i = 0; i < (st.mode === 'rain' ? 6 : 2); i++) st.parts.spawn({ x: Math.random() * st.sc.grid.boardW, y: -40 + Math.random() * 40, vx: st.mode === 'rain' ? -30 : 8 * Math.sin(st.t), vy: st.mode === 'rain' ? 340 : 40, ttl: st.mode === 'rain' ? 1.4 : 9, snow: st.mode === 'snow' }); },
  overlay: (ctx, st) => {
    ctx.save(); ctx.globalCompositeOperation = 'multiply'; ctx.fillStyle = `rgba(120,135,170,${st.k * 0.6})`; ctx.fillRect(-500, -500, 3000, 3000); ctx.restore();
    if (st.mode === 'snow' || (st.k > 0 && st.parts.list.some((p) => p.snow))) { ctx.save(); ctx.globalAlpha = st.k * 0.55; ctx.fillStyle = '#fff'; for (let c = 0; c < st.sc.grid.cols; c++) for (let r = 0; r < st.sc.grid.rows; r++) if (!st.sc.isRoad(c, r)) { const [cx, cy] = st.sc.grid.center(c, r); diamond(ctx, cx, cy); ctx.fill(); } ctx.restore(); }
    st.parts.draw(ctx, (c, p) => { if (p.snow) { c.fillStyle = 'rgba(255,255,255,.9)'; c.beginPath(); c.arc(p.x, p.y, 1.6, 0, 7); c.fill(); } else { c.strokeStyle = 'rgba(200,220,255,.55)'; c.lineWidth = 1; c.beginPath(); c.moveTo(p.x, p.y); c.lineTo(p.x - 2, p.y - 10); c.stroke(); } });
    if (st.mode === 'rain') { ctx.save(); ctx.globalAlpha = st.k; for (const [c, r] of ROAD_TILES(st.sc)) if ((c * 7 + r * 13) % 4 === 0) { const [cx, cy] = st.sc.grid.center(c, r); const g = Math.abs(Math.sin(st.t * 2 + c + r)); ctx.fillStyle = `rgba(200,225,255,${0.15 + 0.25 * g})`; ctx.beginPath(); ctx.ellipse(cx + 6, cy + 4, 9, 4, 0, 0, 7); ctx.fill(); } ctx.restore(); }
  },
});
