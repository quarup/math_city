// The terrain / sky / frontier / first-minutes mock round (terrain_sky.html). Needs mocks_common.js.
'use strict';
// ============ T. TERRAIN ==================================================
MOCKS.push({
  id: 't1', section: 'Terrain', title: 'Today: a lawn square, a pale cross, flat green to the edge',
  art: 'Baseline', effort: '—', perf: '—', tier: 'Baseline',
  notes: `What ships now, for comparison: two-tone lawn on the nine starting blocks, the twelve purchasable blocks washed translucent green (the cross), and the flat <code>#9CCC65</code> Container colour behind the <code>GameWidget</code> everywhere else. Three greens, three meanings, and the cross is visible from the first second even though the first block costs twenty minutes of maths.`,
  scene: new WorldScene(CITY()), view: V(), setup: (st) => { base(st); st.frontierWash = true; },
  terrain: (ctx, sc, st) => { drawWorldGround(ctx, sc, { style: 'today', view: vw(st), frontierWash: true }); drawPadsRoads(ctx, sc); },
});
MOCKS.push({
  id: 't2', section: 'Terrain', title: 'A clearing in the countryside: lawn inside, meadow outside',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `The unowned plane is drawn as the same iso diamonds in a warmer, noisier meadow green with grass tufts, wildflowers, bushes, rocks and a few trees, all procedural from a per-tile hash so nothing is stored. Owned land keeps the checkerboard lawn. The city edge is now "mown vs wild", which the eye accepts as landscape rather than as a UI state, and the frontier is not drawn at all. Trees are depth-sorted with the buildings so they overlap the edge correctly.<br><br><b>In Flutter:</b> one extra branch in <code>CityBoardComponent._drawTile</code> and a small <code>drawDecor</code> painter; the window just needs to render a margin of unowned tiles around the owned bbox (<code>LandWindow</code> plus ~6 tiles).`,
  scene: new WorldScene(CITY()), view: V(), setup: (st) => base(st), terrain: meadowTerrain('meadow'), entities: decorEnts,
});
MOCKS.push({
  id: 't3', section: 'Terrain', title: 'Density as distance: meadow, scrub, then forest',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `Same idea, with the palette and the tree density keyed to the block ring: meadow on rings 2–3 (what you can buy soon), scrub on ring 3, forest beyond. The land the kid will own next always looks like the easy bit, and the dearer rings look wilder, so the price gradient reads as terrain without a single number on screen. Costs nothing over T2.`,
  scene: new WorldScene(CITY()), view: V(), setup: (st) => base(st, { density: (rg) => rg <= 2 ? 0.06 : rg === 3 ? 0.2 : 0.55 }), terrain: meadowTerrain('density'), entities: decorEnts,
});
MOCKS.push({
  id: 't4', section: 'Terrain', title: 'The ground dissolves into sky at the top of the screen',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `The camera looks down at a fixed angle, so there is no horizon to draw. Instead the ground fades into a sky gradient over the top ~40 % of the viewport, distance-fog style, and sun, moon, stars and clouds live in that band. Township and SimCity BuildIt both do this; nobody notices where the ground ends. The band is screen-space and never pans. Try the three band heights.<br><br><b>In Flutter:</b> a gradient <code>Container</code> behind the <code>GameWidget</code> for the sky, and a viewport-space gradient component drawn after the board for the haze.`,
  scene: new WorldScene(CITY()), view: V(), setup: (st) => { base(st); st.k = 0.42; }, terrain: meadowTerrain('meadow'), entities: decorEnts,
  controls: [{ label: 'Band 30 %', run: (st) => st.k = 0.3 }, { label: 'Band 42 %', run: (st) => st.k = 0.42 }, { label: 'Band 55 %', run: (st) => st.k = 0.55 }],
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H, { k: st.k }); label(ctx, `Haze band ${Math.round(st.k * 100)} % of the viewport`, 10, 10); },
});
MOCKS.push({
  id: 't5', section: 'Terrain', title: 'An island: the city sits on a plateau above the water',
  art: 'I draw it', effort: 'M', perf: 'Light', tier: 'Reject',
  notes: `Owned blocks are a raised slab with cliff faces on the two viewer-facing sides, water everywhere else, and purchasable blocks as sandbanks. Buying raises a new block out of the sea. Charming for a minute, but orthogonal growth makes the coastline a Tetris outline, every raised edge has to be drawn for every configuration, and the water fights the sunny board that placement depends on. Recorded so it is not re-derived; I would not build it.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 13, setup: (st) => { base(st); st.lift = 12; st.sc.grid.originY -= st.lift; overview(st); st.rise = null; st.decor = []; },
  controls: [{ label: 'Buy the east block', run: (st) => { if (!st.rise && !st.sc.ownsBlock(2, 0)) st.rise = { bx: 2, by: 0, p: 0 }; } }, { label: 'Reset', run: (st) => { st.sc.owned = new Set(startBlocks().map((b) => b.join(','))); st.rise = null; } }],
  update: (st, dt) => { if (st.rise) { st.rise.p = Math.min(1, st.rise.p + dt); if (st.rise.p >= 1) { st.sc.buy(st.rise.bx, st.rise.by); st.rise = null; } } },
  terrain: (ctx, sc, st) => {
    const g = sc.grid, L = st.lift, vis = visibleTiles(sc, vw(st)), fr = new Set(sc.frontier().map((b) => b.join(',')));
    const rising = st.rise ? st.rise.bx + ',' + st.rise.by : null;
    for (let c = 0; c < g.cols; c++) for (let r = 0; r < g.rows; r++) {
      if (!vis(c, r) || sc.isOwnedTile(c, r)) continue; const [cx, cy0] = g.center(c, r), cy = cy0 + L; const key = sc.blockOf(c, r).join(',');
      diamond(ctx, cx, cy); const h = hash2(c, r);
      ctx.fillStyle = key === rising ? '#E6D8A6' : fr.has(key) ? '#7CC4E8' : ['#4FA3D8', '#4A9DD2', '#55A9DC'][Math.floor(h * 3)]; ctx.fill();
      if (h > 0.6 && key !== rising) { const s = Math.sin(st.t * 1.5 + h * 20); ctx.strokeStyle = `rgba(255,255,255,${0.15 + 0.25 * (s + 1) / 2})`; ctx.lineWidth = 1.2; ctx.beginPath(); ctx.moveTo(cx - 8 + s * 3, cy + (h - 0.5) * 8); ctx.lineTo(cx + 6 + s * 3, cy + (h - 0.5) * 8); ctx.stroke(); }
      if (fr.has(key) && key !== rising) { ctx.setLineDash([3, 4]); ctx.strokeStyle = 'rgba(255,255,255,.5)'; ctx.stroke(); ctx.setLineDash([]); }
    }
    const tiles = []; for (let c = 0; c < g.cols; c++) for (let r = 0; r < g.rows; r++) { const key = sc.blockOf(c, r).join(','); if (vis(c, r) && (sc.isOwnedTile(c, r) || key === rising)) tiles.push([c, r, key === rising]); }
    tiles.sort((a, b) => (a[0] + a[1]) - (b[0] + b[1]));
    for (const [c, r, isRising] of tiles) {
      const lift = isRising ? L * st.rise.p : L; const [cx, cy0] = g.center(c, r); const cy = cy0 + (L - lift);
      const Wp = [cx - HALF_W, cy], S = [cx, cy + HALF_H], E = [cx + HALF_W, cy];
      const owned = (cc, rr) => sc.isOwnedTile(cc, rr) || sc.blockOf(cc, rr).join(',') === rising;
      const face = (a, b, col) => { ctx.beginPath(); ctx.moveTo(...a); ctx.lineTo(...b); ctx.lineTo(b[0], b[1] + lift); ctx.lineTo(a[0], a[1] + lift); ctx.closePath(); ctx.fillStyle = col; ctx.fill(); };
      if (!owned(c, r + 1)) face(Wp, S, '#8D6E63'); if (!owned(c + 1, r)) face(S, E, '#A1887F');
      diamond(ctx, cx, cy); ctx.fillStyle = isRising ? mix('#E6D8A6', LAWN[(c + r) % 2], st.rise.p) : LAWN[(c + r) % 2]; ctx.fill(); ctx.strokeStyle = 'rgba(0,0,0,.2)'; ctx.lineWidth = 1; ctx.stroke();
    }
    drawPadsRoads(ctx, sc);
  },
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H, { k: 0.3 }); },
});
MOCKS.push({
  id: 't6', section: 'Terrain', title: 'Cloud shadows crossing the meadow and the town',
  art: 'I draw it', effort: 'S', perf: 'Light', tier: 'Nice',
  notes: `The clouds in the sky band are the same ones whose shadows slide across the ground below, so the two layers agree. Shadows are three multiply-blend blobs on a shared wind; they cross lawn, meadow and roads alike, which makes the whole plane feel like one outdoors rather than a board on a backdrop. Only after T2 and T4 are in; it competes with placement legibility, so keep it faint.`,
  scene: new WorldScene(CITY()), view: V(), setup: (st) => { base(st); st.shadows = [0, 1, 2].map((i) => ({ x: i * 420 - 300, y: i * 160 - 120, r: 150 + i * 30 })); },
  update: (st, dt) => { for (const c of st.shadows) { c.x += 18 * dt; c.y += 5 * dt; if (c.x > st.home[0] + 900) { c.x = st.home[0] - 900; } } },
  terrain: meadowTerrain('meadow'), entities: decorEnts,
  ground: (ctx, st) => { ctx.save(); ctx.globalCompositeOperation = 'multiply'; for (const c of st.shadows) { const g = ctx.createRadialGradient(c.x, c.y, 0, c.x, c.y, c.r); g.addColorStop(0, 'rgba(60,70,110,.4)'); g.addColorStop(0.6, 'rgba(60,70,110,.25)'); g.addColorStop(1, 'rgba(60,70,110,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.ellipse(c.x, c.y, c.r, c.r * 0.55, 0, 0, 7); ctx.fill(); } ctx.restore(); },
  hud: (ctx, st, W, H) => skyHud(ctx, st, W, H),
});

// ============ S. SKY ======================================================
MOCKS.push({
  id: 's1', section: 'Sky', title: 'The sky never pans: fixed backdrop while the camera roams',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `The camera drifts around the city on its own here. With the sky fixed to the viewport, the clouds and sun stay put while the ground slides under them, which is what "far away" looks like. Toggle to the alternative, where the sky is glued to the world and pans with it, and it turns back into wallpaper.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 15, setup: (st) => { base(st); st.mode = 'fixed'; },
  controls: [{ label: 'Sky fixed to the viewport', run: (st) => st.mode = 'fixed' }, { label: 'Sky pans with the world', run: (st) => st.mode = 'world' }],
  update: (st) => { st.view.cx = st.home[0] + Math.sin(st.t * 0.5) * 260; st.view.cy = st.home[1] + Math.cos(st.t * 0.35) * 70; },
  terrain: meadowTerrain('meadow'), entities: decorEnts,
  hud: (ctx, st, W, H) => { const px = st.mode === 'world' ? (st.view.cx - st.home[0]) * st.view.zoom : 0; drawHaze(ctx, st, W, H); drawSunMoonHazed(ctx, st, W, H); ctx.save(); if (st.mode === 'world') ctx.translate(0, -(st.view.cy - st.home[1]) * st.view.zoom * 0.5); drawClouds(ctx, st, W, H, 0.42, { parallax: px }); ctx.restore(); label(ctx, st.mode === 'fixed' ? 'Sky fixed to the viewport' : 'Sky glued to the world', 10, 10); },
});
MOCKS.push({
  id: 's2', section: 'Sky', title: 'The eight-minute day: sun, moon and stars on an arc',
  art: 'I draw it', effort: 'M', perf: 'Light', tier: 'Recommend',
  notes: `A whole day every eight minutes, compressed to forty seconds here. The sun rides the arc across the sky band, sets into the haze, the stars come out, the moon takes over; the board takes the dusk and night tints and the windows light up (the existing D4 mask). Scrub the slider to see any hour. The kid gets a clock they can read without numbers.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 8, setup: (st) => { base(st); st.play = true; },
  controls: [{ label: 'Play / pause', run: (st) => st.play = !st.play }, { range: [0, 23.9, 0.1], label: 'Hour', get: (st) => st.hour, set: (st, v) => { st.hour = v % 24; st.play = false; } }],
  update: (st, dt) => { if (st.play) st.hour = (st.hour + dt * 24 / 40) % 24; },
  terrain: meadowTerrain('meadow'), entities: decorEnts,
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H); label(ctx, `${fmtHour(st.hour)} · minute ${(st.hour / 3).toFixed(1)} of 8`, 10, 10); },
});
MOCKS.push({
  id: 's3', section: 'Sky', title: 'City glow: the night sky warms as the city grows',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `At night a warm halo hangs over the city and tints the haze band, and its strength scales with how many buildings there are. A village barely glows; a skyline lights up its own sky. The sky itself becomes a growth reward with no new UI. Two radial gradients in additive blend. Add buildings to see it climb.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 21.5, setup: (st) => { base(st); st.n0 = st.sc.buildings.length; },
  controls: [{ label: '+4 buildings', run: (st) => { for (let i = 0; i < 4; i++) addBuilding(st.sc, pick(EXTRA_IDS)); } }, { label: 'Reset', run: (st) => { st.sc.buildings.length = st.n0; } }],
  terrain: meadowTerrain('meadow'), entities: decorEnts,
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H); drawCityGlow(ctx, st, W, H, st.sc.buildings.length); label(ctx, `${st.sc.buildings.length} buildings · glow ${Math.round(Math.min(1, st.sc.buildings.length / 24) * 100)} %`, 10, 10); },
});
MOCKS.push({
  id: 's4', section: 'Sky', title: 'Clock policy: frozen at morning until the hand-over, then 5 + 3',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `Chapter one runs at a fixed 9:30 so the board is at its most readable while the kid learns to place. The hand-over letter starts the clock: five minutes of day, three of night, looping (compressed to 25 s + 15 s here). Questions cover the city, so the clock pauses under them. The timeline shows where in the loop you are.`,
  scene: new WorldScene(CHAPTER()), view: V(), hourStart: 9.5, setup: (st) => { base(st, { zoom: 0.8 }); st.running = false; st.loopT = 0; st.sc.buildings.push({ id: 'single_home_v1', col: gc(st, 2), row: gc(st, 0), w: 1, h: 1 }); },
  controls: [{ label: 'Hand-over letter (start the clock)', run: (st) => { st.running = true; st.loopT = 0; } }, { label: 'Back to chapter one', run: (st) => { st.running = false; st.hour = 9.5; } }],
  update: (st, dt) => { if (!st.running) return; st.loopT = (st.loopT + dt) % 40; st.hour = st.loopT < 25 ? 7 + (st.loopT / 25) * 12 : (19 + ((st.loopT - 25) / 15) * 12) % 24; },
  terrain: meadowTerrain('meadow'), entities: decorEnts,
  hud: (ctx, st, W, H) => {
    skyHud(ctx, st, W, H, { k: 0.36 });
    const x = 12, y = H - 30, w = W - 24; ctx.fillStyle = 'rgba(16,25,23,.72)'; roundRect(ctx, x, y - 8, w, 26, 13); ctx.fill();
    ctx.fillStyle = '#F2B134'; roundRect(ctx, x + 10, y + 2, (w - 20) * 25 / 40, 6, 3); ctx.fill(); ctx.fillStyle = '#5c6bc0'; roundRect(ctx, x + 10 + (w - 20) * 25 / 40, y + 2, (w - 20) * 15 / 40, 6, 3); ctx.fill();
    const px = st.running ? x + 10 + (w - 20) * st.loopT / 40 : x + 10 + (w - 20) * (2.5 / 25); ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(px, y + 5, 6, 0, 7); ctx.fill();
    label(ctx, st.running ? `Clock running · ${fmtHour(st.hour)} · ${st.loopT < 25 ? 'day (5 min)' : 'night (3 min)'}` : 'Chapter one · clock frozen at 9:30 am', 10, 10);
  },
});
MOCKS.push({
  id: 's5', section: 'Sky', title: 'Parallax: clouds shift at a tenth of the pan',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Decide',
  notes: `Between S1's fixed sky and a sky glued to the world: the clouds move at about a tenth of the camera's speed, the sun and stars stay fixed. It adds depth when the kid pans, at the cost of one multiply per frame. A taste call, hence "decide"; both are the same code with a constant changed.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 16, setup: (st) => { base(st); st.px = 0.12; },
  controls: [{ range: [0, 0.5, 0.02], label: 'Parallax', get: (st) => st.px, set: (st, v) => st.px = v }],
  update: (st) => { st.view.cx = st.home[0] + Math.sin(st.t * 0.5) * 260; st.view.cy = st.home[1] + Math.cos(st.t * 0.35) * 70; },
  terrain: meadowTerrain('meadow'), entities: decorEnts,
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H, { parallax: (st.view.cx - st.home[0]) * st.view.zoom * st.px }); label(ctx, `Parallax ${st.px.toFixed(2)}×`, 10, 10); },
});

// ============ F. FRONTIER =================================================
MOCKS.push({
  id: 'f1', section: 'Frontier', title: 'Nothing until it matters: the frontier appears with the land beat',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `Before the land beat fires there is no frontier to see or tap; the lawn meets the meadow and that is all. Tap the meadow: nothing happens. Fire the beat and the purchasable blocks announce themselves with a sign each, popping in one after another. The affordance is added to the world at the moment it becomes true, not painted from the start.`,
  scene: new WorldScene(CITY()), view: V(), setup: (st) => { base(st); st.unlocked = false; st.msg = ''; },
  controls: [{ label: 'Fire the land beat', run: (st) => { st.unlocked = true; st.signT = {}; st.sc.frontier().forEach(([bx, by], i) => st.signT[bx + ',' + by] = st.t + i * 0.08); } }, { label: 'Reset', run: (st) => { st.unlocked = false; st.sel = null; } }],
  tap: (st, wx, wy, e) => { if (!st.unlocked) { st.msg = 'Tap on the meadow: nothing happens yet'; st.msgT = st.t; return; } tapWithBar(st, wx, wy, e); },
  terrain: meadowTerrain('meadow'), entities: decorEnts,
  overlay: (ctx, st) => { if (st.unlocked) { drawFrontierSigns(ctx, st); drawSelection(ctx, st); } },
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H); if (st.unlocked) buyBar(ctx, st, W, H); label(ctx, st.unlocked ? 'Land beat fired · signs on 12 blocks' : (st.msg && st.t - st.msgT < 2 ? st.msg : 'Before the land beat · tap the meadow'), 10, 10); },
});
MOCKS.push({
  id: 'f2', section: 'Frontier', title: 'Signposts, not washes: a for-sale sign per block',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `A small wooden sign at the centre of each purchasable block, drawn at constant screen size so it is legible at any zoom. Tapping anywhere in the block selects it: survey stakes and string appear around it with the game's yellow wash, and the existing buy bar comes up. Buy, and the lawn spreads across the block tile by tile, the wild things vanish, and new signs pop on the next ring. The signs replace the pale cross entirely.`,
  scene: new WorldScene(CITY()), view: V(), setup: (st) => base(st), tap: tapWithBar,
  controls: [{ label: 'Buy selected block', run: buySelected }],
  terrain: meadowTerrain('meadow'), entities: decorEnts, overlay: (ctx, st) => { drawFrontierSigns(ctx, st); drawSelection(ctx, st); },
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H); buyBar(ctx, st, W, H); if (!st.sel) label(ctx, 'Tap a sign to select its block', 10, 10); },
});
MOCKS.push({
  id: 'f3', section: 'Frontier', title: 'Survey stakes only: string around each block, meadow inside',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `No sign, no wash: each purchasable block is outlined by four stakes and a dashed string, in the same style as the construction-site fence, so the kid has already seen the language. The interior stays meadow. Quieter than F2 but less obviously tappable, and from far out the dashes read as a grid again; better as the selected state than as the resting state.`,
  scene: new WorldScene(CITY()), view: V(), setup: (st) => base(st), tap: tapWithBar,
  controls: [{ label: 'Buy selected block', run: buySelected }],
  terrain: meadowTerrain('meadow'), entities: decorEnts,
  overlay: (ctx, st) => { for (const [bx, by] of st.sc.frontier()) if (!(st.sel && st.sel[0] === bx && st.sel[1] === by)) drawSurvey(ctx, st.sc, bx, by, { color: 'rgba(255,255,255,.75)', width: 1.5 }); drawSelection(ctx, st); },
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H); buyBar(ctx, st, W, H); },
});
MOCKS.push({
  id: 'f4', section: 'Frontier', title: 'A hedge around the town, with gates where land is for sale',
  art: 'I draw it', effort: 'M', perf: 'Free', tier: 'Nice',
  notes: `A low hedge follows the owned/unowned boundary, and where a purchasable block touches the town the hedge opens into a two-tile gate with posts. The edge reads as a town limit, not a UI, and the gate is the tap target. Costs an edge pass over boundary tiles every land change. Combines well with F2 (a sign beside each gate) and it is the one option that also makes the city feel enclosed and cosy for the youngest players.`,
  scene: new WorldScene(CITY()), view: V(), setup: (st) => { base(st); st.hedge = true; }, tap: tapWithBar,
  controls: [{ label: 'Buy selected block', run: buySelected }, { label: 'Toggle signs beside gates', run: (st) => st.signs = !st.signs }],
  terrain: meadowTerrain('meadow'), entities: decorEnts,
  overlay: (ctx, st) => { if (st.signs) drawFrontierSigns(ctx, st); drawSelection(ctx, st); },
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H); buyBar(ctx, st, W, H); },
});
MOCKS.push({
  id: 'f5', section: 'Frontier', title: 'One sign, next to the site that did not fit',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `The city is full and the kid has picked a park: the ghost is red wherever it goes. Instead of twelve signs, one appears on the block beside the failed spot, with the park drawn faintly inside it so the message is "this one would fit your park". The full frontier only shows after the first purchase. Decision load for a first-timer: one thing to tap.`,
  scene: new WorldScene(CROWDED()), view: V(), setup: (st) => { base(st); st.ghost = [gc(st, 3), gc(st, 1)]; },
  update: (st) => { const k = Math.floor(st.t / 1.6) % 3; st.ghost = [[gc(st, 3), gc(st, 1)], [gc(st, -2), gc(st, 0)], [gc(st, 4), gc(st, 5)]][k]; },
  terrain: meadowTerrain('meadow'), entities: decorEnts,
  ground: (ctx, st) => { drawGhostFootprint(ctx, st.sc, st.ghost[0], st.ghost[1], 2, 2, false); if (!st.sc.ownsBlock(2, 0)) drawGhostFootprint(ctx, st.sc, gc(st, 9), gc(st, 1), 2, 2, true); },
  overlay: (ctx, st) => { if (!st.sc.ownsBlock(2, 0)) { drawFrontierSigns(ctx, st, { only: [[2, 0]] }); const [x, y] = st.sc.blockCenter(2, 0); ctx.save(); ctx.translate(x, y + 18); ctx.scale(1 / st.view.zoom, 1 / st.view.zoom); label(ctx, 'fits your park', -38, 0); ctx.restore(); } drawSelection(ctx, st); },
  tap: tapWithBar, controls: [{ label: 'Buy it', run: (st) => { st.sel = [2, 0]; buySelected(st); } }, { label: 'Reset', run: (st) => { st.sc.owned = new Set(startBlocks().map((b) => b.join(','))); st.signT = {}; } }],
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H); buyBar(ctx, st, W, H); if (!st.sel) label(ctx, 'No room for the park · one sign', 10, 10); },
});
MOCKS.push({
  id: 'f6', section: 'Frontier', title: 'Affordability on the sign: gold and a glint when you can pay',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `Signs carry the price. A sign the kid can afford turns gold and glints; the others stay plain wood. One extra block is owned here so ring-3 blocks (🪙 1800) sit beside ring-2 ones (🪙 1200). Earn coins and watch signs turn. Shows what to save for without a single disabled button, and never tempts a tap that ends in "you can't".`,
  scene: new WorldScene({ ...CITY(), owned: [...startBlocks(), [2, 0]] }), view: V(), setup: (st) => { base(st); st.coins = 700; },
  controls: [{ label: '+ 🪙 600 (ten minutes of maths)', run: (st) => st.coins += 600 }, { label: 'Reset coins', run: (st) => st.coins = 700 }, { label: 'Buy selected block', run: buySelected }],
  tap: tapWithBar, terrain: meadowTerrain('meadow'), entities: decorEnts,
  overlay: (ctx, st) => { drawFrontierSigns(ctx, st, { price: true }); drawSelection(ctx, st); },
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H); buyBar(ctx, st, W, H); drawCoins(ctx, W, st.coins); },
});
MOCKS.push({
  id: 'f7', section: 'Frontier', title: 'Buy-land mode: the frontier lights up only inside a Land folder',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Decide',
  notes: `How Township and SimCity BuildIt do it: a Land folder in the bottom bar. Open it and the purchasable blocks wash pale (the current look, but only now) and take taps; close it and the meadow is plain again. Clean, and it fits the four-folder bar from §10.5. Against it: one more folder for a six-year-old, and the mode has to be discovered. I would use it later as the home of the price list, with F2's signs as the always-on affordance.`,
  scene: new WorldScene(CITY()), view: V(), setup: (st) => { base(st); st.land = false; },
  controls: [{ label: 'Toggle the Land folder', run: (st) => { st.land = !st.land; st.frontierWash = st.land; st.sel = null; } }],
  tap: (st, wx, wy, e) => { if (e && e.offsetY > st.H - 52) { st.land = !st.land; st.frontierWash = st.land; st.sel = null; return; } if (st.land) tapWithBar(st, wx, wy, e); },
  terrain: meadowTerrain('meadow'), entities: decorEnts, overlay: (ctx, st) => { if (st.land) drawSelection(ctx, st); },
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H); if (st.land) buyBar(ctx, st, W, H); drawFolderBar(ctx, W, H, [{ emoji: '🏠' }, { emoji: '🏥' }, { emoji: '🛍️' }, { emoji: '🎡' }, { emoji: '🏞️', on: st.land }]); label(ctx, st.land ? 'Land folder open · frontier washed' : 'Land folder closed · plain meadow', 10, 10); },
});

// ============ N. FIRST MINUTES =============================================
MOCKS.push({
  id: 'n1', section: 'First minutes', title: 'First sight: zoomed in on the mayor\'s office, no edge anywhere',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `What the kid sees when the city is created: the mayor's office, a road, lawn in every direction. The starting land is 12×12 and the camera starts at three times the fit-the-board zoom, so the edge is off screen; with T2's meadow beyond it there is nothing to find by pinching out either. Nothing on this screen says "limit".`,
  scene: new WorldScene(CHAPTER()), view: V(), hourStart: 9.5, setup: (st) => { base(st, { zoom: 1.45 }); st.zoomed = true; },
  controls: [{ label: 'Pinch out (what they would find)', run: (st) => { st.zoomed = !st.zoomed; } }],
  update: (st, dt) => { const z = st.zoomed ? 1.45 : 0.55; st.view.zoom += (z - st.view.zoom) * Math.min(1, dt * 4); },
  terrain: meadowTerrain('meadow'), entities: decorEnts,
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H, { k: 0.3 }); label(ctx, st.zoomed ? 'Start zoom · no edge in sight' : 'Pinched out · still no frontier', 10, 10); },
});
MOCKS.push({
  id: 'n2', section: 'First minutes', title: 'A tighter pan clamp until the land beat',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Nice',
  notes: `The camera here keeps trying to drift east. With the frontier hidden the clamp stops at the owned land plus a tile, so the kid cannot wander off into empty meadow and wonder what it is for. When land unlocks, the clamp loosens to include the ring of purchasable blocks. The dashed box is the pannable extent.`,
  scene: new WorldScene(CITY()), view: V(), hourStart: 11, setup: (st) => { base(st, { zoom: 0.8 }); st.unlocked = false; },
  controls: [{ label: 'Toggle land unlocked', run: (st) => { st.unlocked = !st.unlocked; st.signT = {}; } }],
  update: (st) => { st.view.cx = st.home[0] + Math.sin(st.t * 0.45) * 700; st.view.cy = st.home[1] + Math.cos(st.t * 0.3) * 260; st.box = st.sc.ownedBox(st.unlocked ? 4 * TILE_W : TILE_W); clampView(st, st.box); },
  terrain: meadowTerrain('meadow'), entities: decorEnts,
  overlay: (ctx, st) => { const b = st.box; ctx.save(); ctx.setLineDash([8, 6]); ctx.strokeStyle = 'rgba(255,255,255,.8)'; ctx.lineWidth = 2; ctx.strokeRect(b.x0, b.y0, b.x1 - b.x0, b.y1 - b.y0); ctx.restore(); if (st.unlocked) drawFrontierSigns(ctx, st); },
  hud: (ctx, st, W, H) => { skyHud(ctx, st, W, H); label(ctx, st.unlocked ? 'Clamp: owned land + frontier ring' : 'Clamp: owned land + one tile', 10, 10); },
});
const N3_STEPS = [2.5, 5.5, 8.5, 11, 15.5];
function n3Reset(st) { st.t0 = st.t; st.sc.owned = new Set(startBlocks().map((b) => b.join(','))); if (st.park) { st.sc.buildings.splice(st.sc.buildings.indexOf(st.park), 1); st.park = null; } st.signT = {}; st.wiping = null; st.bought = false; overview(st, 0.62); }
function n3Update(st, dt, o) {
  const e = st.t - st.t0; let ph = 0; while (ph < N3_STEPS.length && e >= N3_STEPS[ph]) ph++; st.phase = ph;
  if (ph >= N3_STEPS.length) { n3Reset(st); return; }
  glide(st, (ph >= 2 && ph <= 3) ? st.sc.blockCenter(2, 0) : st.home, dt);
  if (ph === 4 && !st.bought) { st.bought = true; st.wiping = { bx: 2, by: 0, p: 0 }; if (o.gift) sparkle(st, 2, 0); }
  stepWipe(st, dt);
  if (st.bought && !st.wiping && !st.park) { st.park = { id: 'park_v1', col: gc(st, 9), row: gc(st, 1), w: 2, h: 2 }; st.sc.buildings.push(st.park); }
}
function n3Hud(ctx, st, W, H, o) {
  skyHud(ctx, st, W, H, { k: 0.3 }); const ph = st.phase; const [sx, sy] = worldToScreen(st, ...st.sc.blockCenter(2, 0), W, H);
  if (ph === 0) drawBar(ctx, W, H, 'No room for a park anywhere', { button: 'Cancel' });
  if (ph === 1) drawLetter(ctx, W, H, o.gift ? { from: 'Mrs. Pomeroy & the neighbours', emoji: '🎁', text: 'The town is getting cosy! We chipped in and bought you the field next door.', button: 'Open the gate' } : { from: 'Mrs. Pomeroy', text: 'The town is getting cosy! There is a field for sale next to my farm.', button: 'Show me' });
  if (ph === 2) { drawHand(ctx, sx + 6, sy - 10, st.t); label(ctx, o.gift ? 'Tap the gate' : 'Tap the sign', 10, 10); }
  if (ph === 3) { const btn = drawBar(ctx, W, H, o.gift ? 'Open the gate to the new field?' : 'Buy this land for 🪙 1200?', { button: o.gift ? 'Open' : 'Buy' }); if (btn) drawHand(ctx, btn.x + btn.w / 2, btn.y + 8, st.t); }
  if (ph === 4) label(ctx, st.park ? (o.gift ? 'The field is yours · park built' : 'Bought · park built') : 'Lawn spreading…', 10, 10);
  if (o.coins !== undefined) drawCoins(ctx, W, o.coins);
}
const n3Overlay = (ctx, st, o) => { drawWipe(ctx, st); if (st.phase >= 2 && st.phase <= 3 && !st.sc.ownsBlock(2, 0)) { if (o.gift) drawSurvey(ctx, st.sc, 2, 0, { color: '#FFD54F', wash: st.phase === 3 ? 'rgba(255,235,59,.35)' : undefined, t: st.t }); else { drawFrontierSigns(ctx, st, { only: [[2, 0]] }); if (st.phase === 3) drawSurvey(ctx, st.sc, 2, 0, { wash: 'rgba(255,235,59,.35)', t: st.t }); } } drawParts(ctx, st); };
MOCKS.push({
  id: 'n3', section: 'First minutes', title: 'The land letter: refused fit → letter → Show me → sign → buy',
  art: 'I draw it', effort: 'M', perf: 'Free', tier: 'Recommend',
  notes: `The full beat, auto-playing on a loop. The city is full and the park will not fit anywhere; the engine notices and Mrs. Pomeroy writes. <em>Show me</em> pans the camera to the one block beside her farm, a sign pops, the animated hand taps it once, the buy bar comes up, the hand taps Buy, the lawn spreads and the park goes in. One new thing per letter, and the mechanic is learned by doing it, not by reading about it. This is §10.4 item 6 made concrete.`,
  scene: new WorldScene(CROWDED()), view: V(), hourStart: 10, setup: (st) => { base(st); st.park = null; n3Reset(st); },
  controls: [{ label: 'Replay', run: n3Reset }],
  update: (st, dt) => n3Update(st, dt, {}), terrain: meadowTerrain('meadow'), entities: decorEnts,
  ground: (ctx, st) => { if (st.phase === 0) drawGhostFootprint(ctx, st.sc, gc(st, 3), gc(st, 1), 2, 2, false); },
  overlay: (ctx, st) => n3Overlay(ctx, st, {}), hud: (ctx, st, W, H) => n3Hud(ctx, st, W, H, {}),
});
MOCKS.push({
  id: 'n4', section: 'First minutes', title: 'The first deed is a gift: no price, just open the gate',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Decide',
  notes: `Same beat, but the neighbours have already paid. Ring 2 costs 🪙 1200, about twenty minutes of maths, and a first-timer who has just been told the town is full should not have to save up before seeing what expansion is. The letter carries the deed; the kid opens the gate and the field is theirs. The second block costs the usual price. An economy call, so "decide"; the code difference is one flag on the beat.`,
  scene: new WorldScene(CROWDED()), view: V(), hourStart: 10, setup: (st) => { base(st); st.park = null; n3Reset(st); },
  controls: [{ label: 'Replay', run: n3Reset }],
  update: (st, dt) => n3Update(st, dt, { gift: true }), terrain: meadowTerrain('meadow'), entities: decorEnts,
  ground: (ctx, st) => { if (st.phase === 0) drawGhostFootprint(ctx, st.sc, gc(st, 3), gc(st, 1), 2, 2, false); },
  overlay: (ctx, st) => n3Overlay(ctx, st, { gift: true }), hud: (ctx, st, W, H) => n3Hud(ctx, st, W, H, { gift: true, coins: 340 }),
});
const N5 = [
  { name: '1 · Chapter one', hour: 9.5, zoom: 1.1, keep: 4, bar: false, signs: 'none', clamp: 1, notes: ['clock frozen at 9:30', 'no folder bar', 'no frontier', 'tight pan clamp', 'no prices anywhere'] },
  { name: '2 · Hand-over letter', hour: 14, zoom: 0.8, keep: 99, bar: true, signs: 'none', clamp: 1, notes: ['clock running (5 + 3)', 'folder bar in', 'still no frontier', 'tight pan clamp'] },
  { name: '3 · Land beat', hour: 16, zoom: 0.62, keep: 99, bar: true, signs: 'one', clamp: 4, notes: ['one sign, beside the failed site', 'letter + Show me', 'clamp loosened', 'no price yet'] },
  { name: '4 · First purchase', hour: 17.5, zoom: 0.55, keep: 99, bar: true, land: true, signs: 'all', clamp: 4, notes: ['all signs, with prices', 'gold when affordable', 'Land folder appears', 'coins shown'] },
];
MOCKS.push({
  id: 'n5', section: 'First minutes', title: 'The disclosure schedule: what is on screen at each stage',
  art: 'I draw it', effort: 'S', perf: 'Free', tier: 'Recommend',
  notes: `All of the above in one place, as a stepper. Stage 1 is chapter one: four buildings, morning light, no bar, no edge. Stage 2, after the hand-over letter, adds the folder bar and starts the clock. Stage 3 is the land beat with its single sign. Stage 4, after the first purchase, is the full game: every sign, prices, the Land folder and the coin count. The checklist at the top left is the spec; each line is one flag on the player row.`,
  scene: new WorldScene({ ...CITY(), buildings: [B('mayors_office_v1', -1, 0), B('single_home_v1', 2, 0), B('school_v1', -3, 5), B('park_v1', 2, 5), B('single_home_v1', 3, 0), B('single_home_v1', 2, 1), B('duplex_v1', -4, 0), B('apartment_v1', -4, -3), B('bakery_v1', -1, -3), B('coffee_shop_v1', 2, -2), B('playground_v1', 4, -3), B('fountain_plaza_v1', 5, 0), B('police_station_v1', 5, 5), B('farmhouse_v1', -1, 5)] }), view: V(), hourStart: 9.5,
  setup: (st) => { base(st); st.all = st.sc.buildings.slice(); st.stage = 0; st.coins = 1400; st.sc.owned.add('2,0'); st.owned4 = new Set(st.sc.owned); st.sc.owned = new Set(startBlocks().map((b) => b.join(','))); st.decor = makeDecor(st.sc); },
  controls: N5.map((s, i) => ({ label: s.name, run: (st) => { st.stage = i; st.signT = {}; st.sel = null; st.sc.owned = i === 3 ? new Set(st.owned4) : new Set(startBlocks().map((b) => b.join(','))); } })),
  update: (st, dt) => { const s = N5[st.stage]; st.hour += (s.hour - st.hour) * Math.min(1, dt * 2); st.view.zoom += (s.zoom - st.view.zoom) * Math.min(1, dt * 3); st.sc.buildings = st.all.slice(0, s.keep); st.view.cx = st.home[0] + Math.sin(st.t * 0.4) * 500; st.view.cy = st.home[1] + Math.cos(st.t * 0.3) * 200; clampView(st, st.sc.ownedBox(s.clamp * TILE_W)); },
  terrain: meadowTerrain('meadow'), entities: decorEnts,
  overlay: (ctx, st) => { const s = N5[st.stage]; if (s.signs === 'one') drawFrontierSigns(ctx, st, { only: [[2, 0]] }); if (s.signs === 'all') drawFrontierSigns(ctx, st, { price: true }); },
  hud: (ctx, st, W, H) => {
    const s = N5[st.stage]; skyHud(ctx, st, W, H, { k: 0.34 });
    if (s.bar) drawFolderBar(ctx, W, H, [{ emoji: '🏠' }, { emoji: '🏥' }, { emoji: '🛍️' }, { emoji: '🎡' }, ...(s.land ? [{ emoji: '🏞️' }] : [])]);
    if (s.signs === 'all') drawCoins(ctx, W, st.coins);
    let y = 10; label(ctx, `${s.name} · ${fmtHour(st.hour)}`, 10, y); y += 26; for (const n of s.notes) { label(ctx, '✓ ' + n, 10, y); y += 24; }
  },
});
