'use strict';
// Parameterised pedestrian renderer. Feet at (x, y); y grows downward; sizes in
// world px at zoom 1 (64 px tile). Every knob lives in the style object S.
const INK = '#2b2b3a';
function darker(c, f = 0.7) { return shade(c, f); }

function drawPed(ctx, x, y, dir, ph, look, S, o = {}) {
  const u = UNIT[dir]; const fx = u[0] >= 0 ? 1 : -1; // screen-x facing
  const front = u[1] > 0; // walking toward the viewer: face visible
  const H = S.h * (o.scale || 1);
  const headR = H * S.head, legL = H * S.leg, bodyW = H * S.bodyW;
  const bodyH = Math.max(2, H - legL - 2 * headR - (S.neck || 0) * H);
  const moving = !o.idle;
  const walk = S.walk || 'pendulum';
  let sw = moving ? Math.sin(ph) : 0, bob = 0, lean = 0;
  if (walk === 'stride') { const s = Math.sin(ph); sw = Math.tanh(s * 4) ; bob = moving ? (Math.abs(Math.cos(ph)) > 0.9 ? 0 : 0.6) : 0; }
  else if (walk === 'hop') { sw = 0; bob = moving ? Math.max(0, Math.sin(ph)) * H * 0.18 : 0; }
  else if (walk === 'glide') { sw = 0; lean = moving ? fx * 0.16 : 0; bob = moving ? Math.abs(Math.sin(ph * 0.5)) * 0.8 : 0; }
  else if (walk === 'shuffle') { sw = moving ? Math.sin(ph * 1.8) * 0.45 : 0; bob = moving ? Math.abs(Math.cos(ph * 1.8)) * 0.4 : 0; }
  else { bob = moving ? Math.abs(Math.cos(ph)) * (S.bob ?? 0.06) * H : 0; }
  const stride = H * (S.stride ?? 0.22);
  const hipY = y - legL - bob, shY = hipY - bodyH, headCY = shY - headR - (S.neck || 0) * H;
  const outline = S.outline || 0; const oc = outline === 2 ? darker(look.shirt, 0.55) : INK; const lw = S.lw || 1;
  const stroke = (col) => { if (!outline) return; ctx.strokeStyle = col || oc; ctx.lineWidth = lw; ctx.stroke(); };
  const fillShade = (col, path) => { ctx.fillStyle = col; ctx.fill(); if (S.shade === 'side') { ctx.save(); ctx.clip(); ctx.fillStyle = 'rgba(0,0,0,.2)'; ctx.fillRect(x, y - H - 10, H, H + 12); ctx.restore(); } };

  // shadow
  ctx.fillStyle = `rgba(0,0,0,${S.shadow ?? 0.25})`; ctx.beginPath(); ctx.ellipse(x, y + 0.5, bodyW * 0.75, bodyW * 0.32, 0, 0, 7); ctx.fill();

  ctx.save(); if (lean) { ctx.translate(x, y); ctx.rotate(lean); ctx.translate(-x, -y); }

  // Which screen side (-1 left, +1 right) is nearer the camera: the figure's
  // right-hand side is world vector sv; it sits at screen-x sign(sv.x) and is
  // near when sv.y > 0. Far limbs draw before the torso, near ones after.
  const shirt = look.shirt; const B = S.body || 'capsule';
  const sv = UNIT[(dir + 1) % 4]; const nearSide = (sv[0] * sv[1] > 0) ? 1 : -1; const farSide = -nearSide;
  // The far arm goes down first of all, behind the legs as well as the torso.
  drawArm(farSide);
  // ---- legs ----
  const legCol = look.pants || '#3a3f5c'; const hipX = (i) => x + i * bodyW * 0.22; const fs = S.feetScale ?? 1;
  if (S.legs !== 'none' && S.body !== 'pill' && S.body !== 'meeple') {
    for (const i of [farSide, nearSide]) {
      const s = sw * i; const footX = hipX(i) + s * stride * fx; let footY = y;
      let lift = 0; if (walk === 'full' && moving) lift = Math.max(0, Math.cos(ph) * i) * H * 0.1; footY = y - lift;
      if (S.legs === 'sticks') { ctx.strokeStyle = S.legCol || legCol; ctx.lineWidth = S.legW || 2; ctx.lineCap = 'round'; ctx.beginPath(); ctx.moveTo(hipX(i), hipY); ctx.lineTo(footX, footY); ctx.stroke(); }
      else if (S.legs === 'doll' || walk === 'full') {
        const kneeX = (hipX(i) + footX) / 2 + fx * (lift * 0.9 + 0.6), kneeY = (hipY + footY) / 2;
        ctx.strokeStyle = legCol; ctx.lineWidth = S.legW || bodyW * 0.28; ctx.lineCap = 'round'; ctx.lineJoin = 'round'; ctx.beginPath(); ctx.moveTo(hipX(i), hipY); ctx.lineTo(kneeX, kneeY); ctx.lineTo(footX, footY); ctx.stroke();
        if (outline) { ctx.strokeStyle = oc; ctx.lineWidth = (S.legW || bodyW * 0.28) + lw * 1.4; ctx.globalCompositeOperation = 'destination-over'; ctx.stroke(); ctx.globalCompositeOperation = 'source-over'; }
        if (S.feet) { ctx.fillStyle = S.feetCol || INK; ctx.beginPath(); ctx.ellipse(footX + fx * 1.2 * fs, footY, 2.4 * fs, 1.2 * fs, 0, 0, 7); ctx.fill(); }
      }
      else if (S.legs === 'tapered') { const w0 = bodyW * 0.3, w1 = bodyW * 0.16; ctx.beginPath(); ctx.moveTo(hipX(i) - w0 / 2, hipY); ctx.lineTo(hipX(i) + w0 / 2, hipY); ctx.lineTo(footX + w1 / 2, footY); ctx.lineTo(footX - w1 / 2, footY); ctx.closePath(); ctx.fillStyle = legCol; ctx.fill(); stroke(); if (S.feet) { ctx.fillStyle = S.feetCol || INK; ctx.beginPath(); ctx.ellipse(footX + fx * 1 * fs, footY, 2.2 * fs, 1.1 * fs, 0, 0, 7); ctx.fill(); } }
      else { // pants: rounded bars
        const w = bodyW * 0.3; ctx.strokeStyle = legCol; ctx.lineWidth = w; ctx.lineCap = 'round'; ctx.beginPath(); ctx.moveTo(hipX(i), hipY); ctx.lineTo(footX, footY); ctx.stroke();
        if (outline) { ctx.globalCompositeOperation = 'destination-over'; ctx.strokeStyle = oc; ctx.lineWidth = w + lw * 1.6; ctx.stroke(); ctx.globalCompositeOperation = 'source-over'; }
        if (S.feet) { ctx.fillStyle = S.feetCol || INK; ctx.beginPath(); ctx.ellipse(footX + fx * 1 * fs, footY, 2.2 * fs, 1.1 * fs, 0, 0, 7); ctx.fill(); }
      }
    }
  }

  // ---- torso ----
  if (B === 'capsule') { roundRect(ctx, x - bodyW / 2, shY, bodyW, bodyH + (S.legs === 'none' ? 0 : bodyW * 0.15), bodyW * 0.45); fillShade(shirt); stroke(); }
  else if (B === 'trapezoid') { const wt = bodyW, wb = bodyW * 0.72; ctx.beginPath(); ctx.moveTo(x - wt / 2, shY + wt * 0.25); ctx.quadraticCurveTo(x - wt / 2, shY, x - wt / 2 + wt * 0.25, shY); ctx.lineTo(x + wt / 2 - wt * 0.25, shY); ctx.quadraticCurveTo(x + wt / 2, shY, x + wt / 2, shY + wt * 0.25); ctx.lineTo(x + wb / 2, hipY + 1); ctx.lineTo(x - wb / 2, hipY + 1); ctx.closePath(); fillShade(shirt); stroke(); }
  else if (B === 'aline') { const wt = bodyW * 0.7, wb = bodyW * 1.35; const hem = hipY + legL * 0.45; ctx.beginPath(); ctx.moveTo(x - wt / 2, shY + 1); ctx.quadraticCurveTo(x, shY - 1, x + wt / 2, shY + 1); ctx.lineTo(x + wb / 2, hem); ctx.lineTo(x - wb / 2, hem); ctx.closePath(); fillShade(shirt); stroke(); }
  else if (B === 'bean') { ctx.beginPath(); ctx.ellipse(x, shY + bodyH * 0.55, bodyW * 0.62, bodyH * 0.62, 0, 0, 7); fillShade(shirt); stroke(); }
  else if (B === 'pill') { roundRect(ctx, x - bodyW / 2, y - H, bodyW, H, bodyW / 2); fillShade(shirt); stroke(); }
  else if (B === 'block') {
    const d = bodyW * 0.55; const s = UNIT[(dir + 1) % 4]; const P = (a, b, z) => [x + u[0] * a + s[0] * b, y + u[1] * a + s[1] * b - z];
    const face = (pts, col) => { ctx.beginPath(); ctx.moveTo(...pts[0]); pts.slice(1).forEach((p) => ctx.lineTo(...p)); ctx.closePath(); ctx.fillStyle = col; ctx.fill(); stroke(); };
    const rightLower = s[1] > 0, frontLower = u[1] > 0; const z0 = legL + bob, z1 = z0 + bodyH;
    const side = rightLower ? [P(-d / 2, d / 2, z0), P(d / 2, d / 2, z0), P(d / 2, d / 2, z1), P(-d / 2, d / 2, z1)] : [P(-d / 2, -d / 2, z0), P(d / 2, -d / 2, z0), P(d / 2, -d / 2, z1), P(-d / 2, -d / 2, z1)];
    const end = frontLower ? [P(d / 2, -d / 2, z0), P(d / 2, d / 2, z0), P(d / 2, d / 2, z1), P(d / 2, -d / 2, z1)] : [P(-d / 2, -d / 2, z0), P(-d / 2, d / 2, z0), P(-d / 2, d / 2, z1), P(-d / 2, -d / 2, z1)];
    face(side, darker(shirt, 0.72)); face(end, darker(shirt, 0.86)); face([P(-d / 2, -d / 2, z1), P(d / 2, -d / 2, z1), P(d / 2, d / 2, z1), P(-d / 2, d / 2, z1)], shirt);
    const hd = headR * 1.6, hz = z1 + (S.neck || 0) * H; const hs = [P(-hd / 2, -hd / 2, hz), P(hd / 2, -hd / 2, hz), P(hd / 2, hd / 2, hz), P(-hd / 2, hd / 2, hz)];
    const hside = rightLower ? [hs[3], hs[2], P(hd / 2, hd / 2, hz + hd), P(-hd / 2, hd / 2, hz + hd)] : [hs[0], hs[1], P(hd / 2, -hd / 2, hz + hd), P(-hd / 2, -hd / 2, hz + hd)];
    const hend = frontLower ? [hs[1], hs[2], P(hd / 2, hd / 2, hz + hd), P(hd / 2, -hd / 2, hz + hd)] : [hs[0], hs[3], P(-hd / 2, hd / 2, hz + hd), P(-hd / 2, -hd / 2, hz + hd)];
    face(hside, darker(look.skin, 0.8)); face(hend, front ? look.skin : darker(look.hair, 0.9)); face(hs.map((p) => [p[0], p[1] - hd]), look.hair);
    if (front) { const e = frontLower ? P(hd / 2 + 0.1, 0, hz + hd * 0.55) : null; if (e) { ctx.fillStyle = INK; ctx.fillRect(e[0] - 1.6, e[1], 1.1, 1.1); ctx.fillRect(e[0] + 0.6, e[1] + 0.5, 1.1, 1.1); } }
    ctx.restore(); return;
  }
  else if (B === 'silhouette') {
    const col = look.shirt; ctx.beginPath(); ctx.arc(x, headCY, headR, 0, 7); ctx.moveTo(x - bodyW / 2, shY); ctx.lineTo(x + bodyW / 2, shY); ctx.lineTo(x + bodyW * 0.36, hipY); ctx.lineTo(x - bodyW * 0.36, hipY); ctx.closePath(); ctx.fillStyle = col; ctx.fill();
    for (const i of [-1, 1]) { const s = sw * i; ctx.beginPath(); ctx.moveTo(x + i * bodyW * 0.3, hipY - 1); ctx.lineTo(x + i * bodyW * 0.05, hipY - 1); ctx.lineTo(x + i * bodyW * 0.1 + s * stride * fx, y); ctx.lineTo(x + i * bodyW * 0.3 + s * stride * fx, y); ctx.closePath(); ctx.fillStyle = col; ctx.fill(); }
    for (const i of [-1, 1]) { const s = -sw * i; ctx.strokeStyle = col; ctx.lineWidth = bodyW * 0.2; ctx.lineCap = 'round'; ctx.beginPath(); ctx.moveTo(x + i * bodyW * 0.5, shY + 1); ctx.lineTo(x + i * bodyW * 0.55 + s * stride * 0.6 * fx, shY + bodyH * 0.75); ctx.stroke(); }
    ctx.restore(); return;
  }
  else if (B === 'meeple') {
    const w = bodyW * 1.5; ctx.beginPath(); ctx.arc(x, headCY, headR, Math.PI * 0.85, Math.PI * 2.15); ctx.lineTo(x + w * 0.62, shY + bodyH * 0.25); ctx.quadraticCurveTo(x + w * 0.7, shY + bodyH * 0.45, x + w * 0.3, shY + bodyH * 0.5); ctx.lineTo(x + w * 0.42, y); ctx.lineTo(x + w * 0.05, y); ctx.lineTo(x, y - legL * 0.6); ctx.lineTo(x - w * 0.05, y); ctx.lineTo(x - w * 0.42, y); ctx.lineTo(x - w * 0.3, shY + bodyH * 0.5); ctx.quadraticCurveTo(x - w * 0.7, shY + bodyH * 0.45, x - w * 0.62, shY + bodyH * 0.25); ctx.closePath(); fillShade(shirt); stroke();
    ctx.restore(); return;
  }
  else if (B === 'stick') { ctx.strokeStyle = shirt; ctx.lineWidth = bodyW * 0.55; ctx.lineCap = 'round'; ctx.beginPath(); ctx.moveTo(x, shY + 1); ctx.lineTo(x, hipY); ctx.stroke(); if (outline) { ctx.globalCompositeOperation = 'destination-over'; ctx.strokeStyle = oc; ctx.lineWidth = bodyW * 0.55 + lw * 1.6; ctx.stroke(); ctx.globalCompositeOperation = 'source-over'; } }
  if (S.shade === 'gradient' && B !== 'silhouette') { ctx.save(); const g = ctx.createLinearGradient(x - bodyW / 2, 0, x + bodyW / 2, 0); g.addColorStop(0, 'rgba(255,255,255,.22)'); g.addColorStop(0.55, 'rgba(0,0,0,0)'); g.addColorStop(1, 'rgba(0,0,0,.28)'); ctx.fillStyle = g; ctx.fill(); ctx.restore(); }

  // ---- arms (near side; the far arm was drawn before the torso) ----
  drawArm(nearSide);
  function drawArm(i) {
    if (S.arms === 'none' || B === 'pill' || B === 'bean') return;
    const aw = S.armW || bodyW * 0.24; const armL = bodyH * (S.armL ?? 0.9);
    {
      const s = moving && S.arms !== 'stiff' ? -sw * i : 0; const ax0 = x + i * bodyW * 0.5, ay0 = shY + bodyW * 0.2;
      const ax1 = ax0 + s * stride * 0.7 * fx + i * 0.6, ay1 = ay0 + armL;
      if (o.wave && i === fx) { ctx.strokeStyle = shirt; ctx.lineWidth = aw; ctx.lineCap = 'round'; ctx.beginPath(); ctx.moveTo(ax0, ay0); ctx.lineTo(ax0 + i * armL * 0.7, ay0 - armL * 0.9 - Math.sin(ph * 3) * 1.5); ctx.stroke(); return; }
      if (S.legs === 'doll' || S.arms === 'doll') { const ex = (ax0 + ax1) / 2 - fx * 0.8 * (s > 0 ? 1 : 0.3), ey = (ay0 + ay1) / 2; ctx.strokeStyle = shirt; ctx.lineWidth = aw; ctx.lineCap = 'round'; ctx.lineJoin = 'round'; ctx.beginPath(); ctx.moveTo(ax0, ay0); ctx.lineTo(ex, ey); ctx.lineTo(ax1, ay1); ctx.stroke(); if (outline) { ctx.globalCompositeOperation = 'destination-over'; ctx.strokeStyle = oc; ctx.lineWidth = aw + lw * 1.6; ctx.stroke(); ctx.globalCompositeOperation = 'source-over'; } ctx.fillStyle = look.skin; ctx.beginPath(); ctx.arc(ax1, ay1, aw * 0.55, 0, 7); ctx.fill(); }
      else { ctx.strokeStyle = shirt; ctx.lineWidth = aw; ctx.lineCap = 'round'; ctx.beginPath(); ctx.moveTo(ax0, ay0); ctx.lineTo(ax1, ay1); ctx.stroke(); if (outline) { ctx.globalCompositeOperation = 'destination-over'; ctx.strokeStyle = oc; ctx.lineWidth = aw + lw * 1.6; ctx.stroke(); ctx.globalCompositeOperation = 'source-over'; } if (S.hands) { ctx.fillStyle = look.skin; ctx.beginPath(); ctx.arc(ax1, ay1, aw * 0.5, 0, 7); ctx.fill(); } }
    }
  }
  // ---- head ----
  if (B !== 'pill') {
    ctx.beginPath(); ctx.arc(x, headCY, headR, 0, 7); ctx.fillStyle = look.skin; ctx.fill(); if (S.shade === 'side') { ctx.save(); ctx.clip(); ctx.fillStyle = 'rgba(0,0,0,.18)'; ctx.fillRect(x, headCY - headR, headR, headR * 2); ctx.restore(); } stroke();
    // hair: cap from the front, full dome from behind
    ctx.fillStyle = look.hair; ctx.beginPath();
    if (front) ctx.arc(x, headCY, headR + (outline ? 0 : 0.2), Math.PI * 1.05, Math.PI * 1.95); else { ctx.arc(x, headCY, headR + 0.1, Math.PI * 0.95, Math.PI * 2.05); ctx.lineTo(x + headR, headCY + headR * 0.35); ctx.lineTo(x - headR, headCY + headR * 0.35); }
    ctx.closePath(); ctx.fill();
    if (front && S.face) { ctx.fillStyle = INK; const ey = headCY + headR * 0.1; ctx.beginPath(); ctx.arc(x - headR * 0.35 + fx * headR * 0.15, ey, headR * 0.12, 0, 7); ctx.arc(x + headR * 0.35 + fx * headR * 0.15, ey, headR * 0.12, 0, 7); ctx.fill(); if (S.face === 'smile') { ctx.strokeStyle = INK; ctx.lineWidth = 0.6; ctx.beginPath(); ctx.arc(x + fx * headR * 0.15, headCY + headR * 0.3, headR * 0.3, 0.2, Math.PI - 0.2); ctx.stroke(); } }
  } else { // pill: hair cap + eyes
    ctx.fillStyle = look.hair; ctx.beginPath(); if (front) ctx.arc(x, y - H + bodyW / 2, bodyW / 2, Math.PI * 1.05, Math.PI * 1.95); else { ctx.arc(x, y - H + bodyW / 2, bodyW / 2, Math.PI, 2 * Math.PI); ctx.lineTo(x + bodyW / 2, y - H + bodyW * 0.8); ctx.lineTo(x - bodyW / 2, y - H + bodyW * 0.8); } ctx.closePath(); ctx.fill();
    ctx.fillStyle = look.skin; ctx.beginPath(); ctx.arc(x, y - H + bodyW / 2 + 0.5, bodyW * 0.42, Math.PI * 0.05, Math.PI * 0.95); ctx.fill();
    if (front && S.face) { ctx.fillStyle = INK; ctx.fillRect(x - bodyW * 0.22 + fx * 0.5, y - H + bodyW * 0.55, 0.9, 1.2); ctx.fillRect(x + bodyW * 0.12 + fx * 0.5, y - H + bodyW * 0.55, 0.9, 1.2); }
  }
  // ---- accessories ----
  const acc = o.acc || look.acc;
  if (acc === 'hat') { ctx.fillStyle = look.hat || '#c62828'; ctx.fillRect(x - headR * 1.25, headCY - headR * 0.75, headR * 2.5, 1.2); roundRect(ctx, x - headR * 0.8, headCY - headR * 1.55, headR * 1.6, headR * 0.9, 1); ctx.fill(); stroke(); }
  if (acc === 'cap') { ctx.fillStyle = look.hat || '#3a7bd5'; ctx.beginPath(); ctx.arc(x, headCY - headR * 0.1, headR * 1.02, Math.PI, 2 * Math.PI); ctx.fill(); ctx.fillRect(x + (fx > 0 ? 0 : -headR * 1.5), headCY - headR * 0.15, headR * 1.5, 1); }
  if (acc === 'hardhat') { ctx.fillStyle = '#f2b134'; ctx.beginPath(); ctx.arc(x, headCY - headR * 0.05, headR * 1.08, Math.PI, 2 * Math.PI); ctx.fill(); ctx.fillRect(x - headR * 1.25, headCY - headR * 0.1, headR * 2.5, 1); }
  if (acc === 'bag') { ctx.fillStyle = look.bag || '#8d5a3a'; roundRect(ctx, x - fx * (bodyW * 0.5 + 3) - 1.5, hipY - bodyH * 0.35, 3.6, 4.2, 0.8); ctx.fill(); stroke(); ctx.strokeStyle = look.bag || '#8d5a3a'; ctx.lineWidth = 0.8; ctx.beginPath(); ctx.moveTo(x + fx * bodyW * 0.3, shY); ctx.lineTo(x - fx * (bodyW * 0.5 + 1.5), hipY - bodyH * 0.3); ctx.stroke(); }
  if (acc === 'balloon') { const bx = x + fx * 4 + Math.sin(ph * 0.7) * 1.5, by = headCY - headR - H * 0.55; ctx.strokeStyle = 'rgba(40,40,60,.6)'; ctx.lineWidth = 0.5; ctx.beginPath(); ctx.moveTo(x + fx * bodyW * 0.5, shY + bodyH * 0.6); ctx.lineTo(bx, by + 4); ctx.stroke(); ctx.fillStyle = look.balloon || '#e0523f'; ctx.beginPath(); ctx.ellipse(bx, by, 3.2, 4, 0, 0, 7); ctx.fill(); stroke(); }
  if (acc === 'umbrella') { const ux = x + fx * 1, uy = headCY - headR - 3; ctx.strokeStyle = INK; ctx.lineWidth = 0.6; ctx.beginPath(); ctx.moveTo(x + fx * bodyW * 0.55, shY + bodyH * 0.5); ctx.lineTo(ux, uy); ctx.stroke(); ctx.fillStyle = look.umbrella || '#3a7bd5'; ctx.beginPath(); ctx.arc(ux, uy + 0.5, headR * 2.3, Math.PI, 2 * Math.PI); ctx.closePath(); ctx.fill(); stroke(); }
  if (acc === 'cane') { ctx.strokeStyle = '#5a3a1a'; ctx.lineWidth = 0.9; ctx.beginPath(); ctx.moveTo(x + fx * (bodyW * 0.6 + 2), hipY - bodyH * 0.3); ctx.lineTo(x + fx * (bodyW * 0.6 + 2 + Math.sin(ph) * 1.5), y); ctx.stroke(); }
  if (acc === 'phone') { ctx.fillStyle = '#222'; ctx.fillRect(x + fx * bodyW * 0.45, shY + bodyH * 0.15, 1.6, 2.6); }
  ctx.restore();
}

// A small dog on a leash, trotting beside its walker.
function drawDog(ctx, x, y, dir, ph, col) {
  const u = UNIT[dir]; const fx = u[0] >= 0 ? 1 : -1; const b = Math.abs(Math.sin(ph * 1.6)) * 0.6;
  ctx.fillStyle = 'rgba(0,0,0,.2)'; ctx.beginPath(); ctx.ellipse(x, y + 0.4, 4, 1.4, 0, 0, 7); ctx.fill();
  ctx.strokeStyle = col; ctx.lineWidth = 1.1; ctx.lineCap = 'round'; for (const i of [-1, 1]) { ctx.beginPath(); ctx.moveTo(x + i * 2, y - 2.5); ctx.lineTo(x + i * 2 + Math.sin(ph * 1.6) * i * 1.2, y); ctx.stroke(); }
  ctx.fillStyle = col; roundRect(ctx, x - 3.5, y - 4.4 - b, 7, 2.8, 1.3); ctx.fill(); ctx.beginPath(); ctx.arc(x + fx * 3.6, y - 4.8 - b, 1.7, 0, 7); ctx.fill();
  ctx.strokeStyle = col; ctx.lineWidth = 0.9; ctx.beginPath(); ctx.moveTo(x - fx * 3.5, y - 3.8 - b); ctx.lineTo(x - fx * 5, y - 5.5 - b + Math.sin(ph * 4) * 0.6); ctx.stroke();
  ctx.fillStyle = INK; ctx.fillRect(x + fx * 4.3, y - 5.3 - b, 0.7, 0.7);
}

// ---- Style presets -----------------------------------------------------------
const BASE = { h: 17, head: 0.125, leg: 0.45, bodyW: 0.34, body: 'capsule', legs: 'tapered', outline: 1, lw: 0.9, walk: 'pendulum', face: 'dots', feet: true, shadow: 0.25 };
const PEDS = [
  // A — proportions
  { id: 'P01', group: 'Proportions', title: 'Baseline from the first page', S: { h: 13, head: 0.25, leg: 0.35, bodyW: 0.46, body: 'capsule', legs: 'sticks', legW: 2, outline: 1, lw: 1, walk: 'pendulum', bob: 0.09, stride: 0.25 }, notes: 'The version you called chubby with big heads and stick legs, kept here as the reference point. Three heads tall, torso as wide as it is long, legs thinner than the arms.' },
  { id: 'P02', group: 'Proportions', title: 'Toy chibi, two and a half heads', S: { ...BASE, h: 15, head: 0.2, leg: 0.3, bodyW: 0.42, legs: 'pants', stride: 0.2, bob: 0.08 }, notes: 'Leans into the big head on purpose: short legs with real thickness, a small torso, feet. Reads as a toy figure rather than a badly proportioned adult. Works best small.' },
  { id: 'P03', group: 'Proportions', title: 'Four heads tall, real legs', S: { ...BASE }, notes: 'The middle of the road: head an eighth of the height, legs almost half, torso narrower than a head-and-shoulders. Tapered legs and feet give the walk weight. My candidate for the default.' },
  { id: 'P04', group: 'Proportions', title: 'Lanky, six heads', S: { ...BASE, h: 20, head: 0.085, leg: 0.5, bodyW: 0.26, stride: 0.2 }, notes: 'Closer to a real adult. Elegant at close zoom but at city zoom the head becomes a two-pixel dot and the figure turns into a stroke; you lose the face and the hair colour that tell citizens apart.' },
  { id: 'P05', group: 'Proportions', title: 'Bean body, no neck', S: { ...BASE, h: 15, head: 0.17, leg: 0.28, bodyW: 0.5, body: 'bean', legs: 'pants', arms: 'none', stride: 0.18, bob: 0.07 }, notes: 'Head set straight into an egg body, no arms. Very cute and very cheap, and the round silhouette survives any zoom. It is also the least like the realistic building renders.' },
  // B — construction
  { id: 'P06', group: 'Construction', title: 'Pill people', S: { h: 15, head: 0.12, leg: 0, bodyW: 0.36, body: 'pill', legs: 'none', arms: 'none', outline: 0, walk: 'glide', face: 'dots', shadow: 0.22 }, notes: 'One capsule, a hair cap and two eyes, leaning into the direction of travel. No limbs to animate, so nothing can look wrong. The map-marker look; cheerful and unmistakably simplified.' },
  { id: 'P07', group: 'Construction', title: 'Meeples', S: { h: 15, head: 0.16, leg: 0.3, bodyW: 0.34, body: 'meeple', legs: 'none', arms: 'none', outline: 2, lw: 0.8, walk: 'glide', face: 'none', shadow: 0.25 }, notes: 'Board-game tokens sliding along the sidewalk with a slight rock. A single colour each. It tells the kid "these are pieces", which fits a game about building a city block by block.' },
  { id: 'P08', group: 'Construction', title: 'Iso blocks, like the flat cars', S: { h: 16, head: 0.14, leg: 0.4, bodyW: 0.36, body: 'block', legs: 'pants', legW: 2.2, outline: 1, lw: 0.7, walk: 'pendulum', face: 'dots', bob: 0.05, stride: 0.16 }, notes: 'Torso and head as little dimetric boxes, so people and the A1 cars share one visual language and the same three-face shading. Squarer and more "voxel" than the buildings, but consistent with everything else drawn in code.' },
  { id: 'P09', group: 'Construction', title: 'Pictogram silhouettes', S: { h: 17, head: 0.13, leg: 0.45, bodyW: 0.34, body: 'silhouette', outline: 0, walk: 'pendulum', stride: 0.22, shadow: 0.2 }, notes: 'A single filled shape per person, tinted by a per-citizen colour, no skin or hair. Like the figures on road signs. Clean at any size and almost free to draw, but anonymous: no face, no hair, no clothes to spot your favourite.' },
  { id: 'P10', group: 'Construction', title: 'Paper doll, jointed limbs', S: { ...BASE, h: 18, legs: 'doll', arms: 'doll', walk: 'full', legW: 2.4, armW: 1.8, hands: true, stride: 0.24 }, notes: 'Two-segment arms and legs with knees and elbows, a heel lift on the swinging leg, hands. The most convincing walk here and still under a hundred lines. The joints are the thing to look at in the turnaround.' },
  { id: 'P11', group: 'Construction', title: 'Painterly, no outline', S: { ...BASE, h: 17, outline: 0, shade: 'side', legs: 'pants', hands: true, shadow: 0.3 }, notes: 'No ink line; form comes from a shaded right half on body and head, the way the building renders are lit from the upper left. Sits most naturally next to the sprites, at the cost of some crispness at 1×.' },
  { id: 'P12', group: 'Construction', title: 'Thick outline, logo style', S: { ...BASE, h: 17, outline: 1, lw: 1.5, legs: 'pants', legW: 2.6, armW: 2, face: 'smile', shadow: 0.22 }, notes: 'Heavy ink and flat fills, matching the wheel icons and the Math City logo. Pops against the painterly ground and is very readable small. Also the most "cartoon" against the realistic buildings; that contrast is a choice.' },
  { id: 'P13', group: 'Construction', title: 'Coats and dresses', S: { ...BASE, h: 17, body: 'aline', legs: 'sticks', legW: 1.6, legCol: '#d9a276', stride: 0.16 }, notes: 'A-line silhouette with skinny legs poking out below the hem. Mixed with P03 torsos it gives the crowd two silhouettes instead of one, which matters more for variety than any colour palette does.' },
  { id: 'P14', group: 'Construction', title: 'Comic stick figures with a body line', S: { ...BASE, h: 17, head: 0.15, body: 'stick', bodyW: 0.3, legs: 'sticks', legW: 1.4, armW: 1.4, feet: true, feetCol: '#2b2b3a', face: 'smile', stride: 0.26 }, notes: 'A fat body line, round head, big feet. Deliberately doodle-like, like a kid drew the citizens. Charming, but at 1× the body line and the legs blur into a single squiggle.' },
  // C — walk cycles (P03 body)
  { id: 'P15', group: 'Walk cycles', title: 'Pendulum legs and a bob', S: { ...BASE, walk: 'pendulum' }, notes: 'Straight legs swinging from the hip, a bob at each pass, arms counter-swing. The current cycle. Cheap and fine at 1×; up close the straight legs look like scissors.' },
  { id: 'P16', group: 'Walk cycles', title: 'Two-frame stride', S: { ...BASE, walk: 'stride' }, notes: 'Legs snap between two poses like a two-frame sprite sheet, with a hitch at each swap. Retro and cheap; reads as "sprite" even though it is code, which may be the look you want if A2 goes with Nano Banana cars.' },
  { id: 'P17', group: 'Walk cycles', title: 'Knees and heel lift', S: { ...BASE, walk: 'full', legs: 'doll', legW: 2.4, feet: true }, notes: 'The forward-moving leg lifts and bends at the knee; the planted one stays straight. The only cycle here where the feet plausibly leave the ground. Pairs with P10.' },
  { id: 'P18', group: 'Walk cycles', title: 'Hop', S: { ...BASE, walk: 'hop', legs: 'pants' }, notes: 'Legs together, whole figure hops along like a wind-up toy. Silly in a good way, and unmistakably not trying to be realistic. Fits P02 or P05 bodies better than this one.' },
  { id: 'P19', group: 'Walk cycles', title: 'Quick shuffle', S: { ...BASE, walk: 'shuffle', stride: 0.16 }, notes: 'Short fast steps with a light bob, the way people actually walk when seen from a rooftop. Less cartoon energy, more city.' },
  { id: 'P20', group: 'Walk cycles', title: 'Glide and lean', S: { ...BASE, walk: 'glide', legs: 'pants', arms: 'stiff' }, notes: 'No leg motion at all; the figure leans into its direction and slides. Zero animation cost. Feels like a token unless the body is a pill or meeple.' },
  // D — scale (P03 body)
  { id: 'P21', group: 'Scale', title: '11 px, true to the 10 m tile', S: { ...BASE, h: 11, lw: 0.7 }, notes: 'A 1.8 m person on a 10 m tile is eleven pixels at zoom 1. Honest, and invisible at the default camera. Dots with legs.' },
  { id: 'P22', group: 'Scale', title: '15 px', S: { ...BASE, h: 15, lw: 0.8 }, notes: 'Two and a half metres. Still small next to a door, still readable as a person at 1×.' },
  { id: 'P23', group: 'Scale', title: '20 px', S: { ...BASE, h: 20 }, notes: 'Over three metres tall: as tall as the ground floor of the duplex. Reads clearly at every zoom; the cars (20 px long) would need to grow to match.' },
  { id: 'P24', group: 'Scale', title: '26 px, oversized', S: { ...BASE, h: 26, lw: 1.1 }, notes: 'Giants. Good for a hero moment (the celebration crowd) but as street traffic they dwarf the sidewalk and cover doors and windows.' },
  // E — crowd variety
  { id: 'P25', group: 'Crowd', title: 'Kids, adults, elders', S: { ...BASE, walk: 'full', legs: 'doll', legW: 2.3 }, crowd: 'ages', notes: 'Three heights and paces in one crowd: kids at 60 % with bigger heads and a faster step, adults, and elders at 90 % with a cane and a slower shuffle. Variety of gait does more than variety of colour.' },
  { id: 'P26', group: 'Crowd', title: 'Props: hats, bags, balloons, umbrellas', S: { ...BASE, walk: 'full', legs: 'doll', legW: 2.3 }, crowd: 'props', notes: 'One small accessory per citizen, drawn from a list: hat, cap, shoulder bag, balloon, umbrella, phone. Each is a few lines and each makes a citizen recognisable.' },
  { id: 'P27', group: 'Crowd', title: 'Dog walkers and joggers', S: { ...BASE, walk: 'full', legs: 'doll', legW: 2.3 }, crowd: 'dogs', notes: 'A trotting dog on a leash beside its owner, and joggers at double pace in a cap. The dog is the single most-noticed thing in every test with kids I know of.' },
  { id: 'P28', group: 'Crowd', title: 'Pairs, hand in hand', S: { ...BASE, walk: 'full', legs: 'doll', legW: 2.3 }, crowd: 'pairs', notes: 'Parent and child walking together at the child\'s pace, and couples side by side. Groups make a sidewalk look social rather than like a conveyor belt.' },
  // F — palette
  { id: 'P29', group: 'Palette', title: 'Saturated with dark ink', S: { ...BASE, walk: 'full', legs: 'doll', legW: 2.3 }, palette: 'saturated', notes: 'Primary shirts, the ink outline of the logo. Loudest against the ground; citizens are the most visible thing on the board.' },
  { id: 'P30', group: 'Palette', title: 'Muted, no outline', S: { ...BASE, walk: 'full', legs: 'doll', legW: 2.3, outline: 0, shade: 'side' }, palette: 'muted', notes: 'Dusty clothing colours sampled from the sprites themselves (terracotta roofs, sandstone, teal awnings), no ink line. They belong to the city rather than sitting on it.' },
  { id: 'P31', group: 'Palette', title: 'Math City brand colours', S: { ...BASE, walk: 'full', legs: 'doll', legW: 2.3, outline: 2, lw: 0.9 }, palette: 'brand', notes: 'Shirts drawn only from the app palette (teal, coin gold, streak orange, success green, sky) with a darker-of-fill outline instead of black. Ties the citizens to the UI chrome.' },
];
const PAL = {
  saturated: ['#e0523f', '#3a7bd5', '#f2b134', '#3DA85F', '#8e5bd1', '#ff8c42', '#f06292', '#26c6da'],
  muted: ['#b96b4a', '#c9a96b', '#5f8a7a', '#7d8ca3', '#a8746b', '#8fa36a', '#c4b49a', '#6b7d9c'],
  brand: ['#0E6E62', '#F0CC30', '#F2A33A', '#3DA85F', '#5DB7E8', '#5BBF7A', '#B8860B', '#A4DDC9'],
};
function lookFor(preset) { const c = citizen(); if (preset.palette) c.shirt = pick(PAL[preset.palette]); if (preset.S.body === 'silhouette') c.shirt = pick(['#2f3e46', '#37474f', '#4a3a5c', '#3d5a4a', '#5a3d3d']); return c; }
