import type { GameEngine } from "./engine";
import { COMBAT, ITEMS, NPCS } from "./content";
import { TEMPLE, TILE_DEFS, regionAt } from "./world";

export type Viewport = { w: number; h: number; tile: number; dpr: number };

function rr(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

export function render(
  ctx: CanvasRenderingContext2D,
  g: GameEngine,
  vp: Viewport,
  now: number,
) {
  const T = vp.tile;
  const cx = vp.w / 2;
  const cy = vp.h / 2;
  const offX = cx - g.camX * T - T / 2;
  const offY = cy - g.camY * T - T / 2;
  const sx = (tx: number) => offX + tx * T;
  const sy = (ty: number) => offY + ty * T;

  // Bounds come from the current floor: 40x40 surface, 12x12 crypt.
  const tiles = g.map.tiles;
  const mw = tiles[0].length;
  const mh = tiles.length;
  const pz = g.player.z;

  const minTx = Math.max(0, Math.floor(-offX / T) - 1);
  const maxTx = Math.min(mw - 1, Math.ceil((vp.w - offX) / T) + 1);
  const minTy = Math.max(0, Math.floor(-offY / T) - 1);
  const maxTy = Math.min(mh - 1, Math.ceil((vp.h - offY) / T) + 1);

  ctx.clearRect(0, 0, vp.w, vp.h);
  ctx.fillStyle = "#11131a";
  ctx.fillRect(0, 0, vp.w, vp.h);

  // ---- floor
  for (let ty = minTy; ty <= maxTy; ty++) {
    for (let tx = minTx; tx <= maxTx; tx++) {
      const def = TILE_DEFS[tiles[ty][tx]];
      const X = sx(tx);
      const Y = sy(ty);
      if (def.kind === "wall") continue;
      ctx.fillStyle = def.side;
      rr(ctx, X + 1, Y + 3, T - 2, T - 3, 7);
      ctx.fill();
      ctx.fillStyle = def.top;
      rr(ctx, X + 1, Y + 1, T - 2, T - 5, 7);
      ctx.fill();
      if (def.detail) {
        const h = (tx * 73856093) ^ (ty * 19349663);
        if ((h & 7) === 0) {
          ctx.fillStyle = def.detail;
          ctx.globalAlpha = 0.85;
          rr(ctx, X + T * 0.28, Y + T * 0.3, T * 0.22, T * 0.18, 4);
          ctx.fill();
          ctx.globalAlpha = 1;
        }
      }
      if (def.kind === "water") {
        ctx.fillStyle = "rgba(255,255,255,0.14)";
        const wob = Math.sin(now / 500 + tx + ty) * 2;
        rr(ctx, X + 6, Y + T * 0.4 + wob, T - 12, 4, 2);
        ctx.fill();
      }
      if (def.kind === "gate") {
        // Rift pulse (Godot parity: violet ring + white heart).
        const pulse = 0.6 + 0.4 * Math.sin(now / 400);
        ctx.strokeStyle = "rgba(217,153,255,0.9)";
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.arc(X + T / 2, Y + T / 2, T * 0.3 * pulse, 0, Math.PI * 2);
        ctx.stroke();
        ctx.fillStyle = "rgba(255,255,255,0.9)";
        ctx.beginPath();
        ctx.arc(X + T / 2, Y + T / 2, T * 0.08, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }

  // ---- safe-zone plaza glow (surface only)
  if (pz === 0) {
    const X = sx(TEMPLE.x - 3);
    const Y = sy(TEMPLE.y - 3);
    ctx.strokeStyle = "rgba(255, 224, 130, 0.5)";
    ctx.lineWidth = 3;
    ctx.setLineDash([10, 8]);
    rr(ctx, X, Y, T * 7, T * 7, 14);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.fillStyle = "rgba(255, 224, 130, 0.07)";
    ctx.fill();
    ctx.font = `700 ${Math.round(T * 0.3)}px ui-sans-serif, system-ui`;
    ctx.fillStyle = "rgba(255,235,180,0.8)";
    ctx.textAlign = "center";
    ctx.fillText("SANCTUARY · PROTECTED ZONE", sx(TEMPLE.x) + T / 2, Y - 8);
  }

  // ---- telegraphs (drawn under actors: readability first)
  for (const t of g.telegraphs) {
    if (t.z !== pz) continue;
    const total = Math.max(1, t.resolveAt - t.startAt);
    const p = Math.min(1, (now - t.startAt) / total);
    const done = now >= t.resolveAt;
    const flash = done ? Math.max(0, 1 - (now - t.resolveAt) / 220) : 0;
    for (const tile of t.tiles) {
      if (tile.x < 0 || tile.y < 0 || tile.x >= mw || tile.y >= mh) continue;
      const X = sx(tile.x);
      const Y = sy(tile.y);
      ctx.globalAlpha = done ? flash * 0.85 : 0.22 + p * 0.42;
      ctx.fillStyle = t.color;
      rr(ctx, X + 2, Y + 2, T - 4, T - 6, 8);
      ctx.fill();
      ctx.globalAlpha = done ? flash : 0.55 + p * 0.45;
      ctx.strokeStyle = t.color;
      ctx.lineWidth = 3;
      rr(ctx, X + 2, Y + 2, T - 4, T - 6, 8);
      ctx.stroke();
      // fill-up wipe = time remaining, readable at a glance
      if (!done) {
        ctx.globalAlpha = 0.5;
        ctx.fillStyle = "rgba(255,255,255,0.65)";
        rr(ctx, X + 3, Y + T - 8 - (T - 12) * p, T - 6, (T - 12) * p, 5);
        ctx.fill();
      }
      ctx.globalAlpha = 1;
    }
  }

  // ---- ground loot (filtered items are simply not drawn)
  ctx.textAlign = "center";
  for (const it of g.visibleGround()) {
    const X = sx(it.x + it.jx);
    const Y = sy(it.y + it.jy);
    const def = ITEMS[it.itemKey];
    const bob = Math.sin(now / 320 + it.id) * 2;
    const locked = !g.canLoot(it);

    ctx.globalAlpha = 0.3;
    ctx.fillStyle = "#000";
    ctx.beginPath();
    ctx.ellipse(X + T / 2, Y + T * 0.74, T * 0.2, T * 0.09, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;

    // rarity plinth
    const tint =
      def?.rarity === "epic"
        ? "#c026d3"
        : def?.rarity === "rare"
          ? "#0ea5e9"
          : def?.rarity === "uncommon"
            ? "#10b981"
            : "#94a3b8";
    ctx.globalAlpha = locked ? 0.35 : 0.9;
    ctx.fillStyle = "rgba(0,0,0,0.6)";
    rr(ctx, X + T * 0.24, Y + T * 0.26 + bob, T * 0.52, T * 0.44, 8);
    ctx.fill();
    ctx.strokeStyle = tint;
    ctx.lineWidth = 2.5;
    rr(ctx, X + T * 0.24, Y + T * 0.26 + bob, T * 0.52, T * 0.44, 8);
    ctx.stroke();
    ctx.globalAlpha = locked ? 0.45 : 1;
    ctx.font = `${Math.round(T * 0.3)}px serif`;
    ctx.textBaseline = "middle";
    ctx.fillStyle = "#fff";
    ctx.fillText(def?.glyph ?? "❔", X + T / 2, Y + T * 0.49 + bob);
    ctx.textBaseline = "alphabetic";

    if (it.qty > 1) {
      ctx.font = `900 ${Math.round(T * 0.19)}px ui-sans-serif, system-ui`;
      ctx.lineWidth = 3;
      ctx.strokeStyle = "rgba(0,0,0,0.9)";
      ctx.strokeText(`${it.qty}`, X + T * 0.74, Y + T * 0.74 + bob);
      ctx.fillStyle = "#fde047";
      ctx.fillText(`${it.qty}`, X + T * 0.74, Y + T * 0.74 + bob);
    }

    // 60s loot-protection lock + countdown arc
    if (locked) {
      const left = Math.max(0, it.protectedUntil - now);
      const pct = left / COMBAT.LOOT_PROTECT_MS;
      ctx.globalAlpha = 1;
      ctx.strokeStyle = "#f87171";
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(X + T / 2, Y + T * 0.48 + bob, T * 0.33, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * pct);
      ctx.stroke();
      ctx.font = `${Math.round(T * 0.22)}px serif`;
      ctx.fillText("🔒", X + T / 2, Y + T * 0.16 + bob);
    }
    ctx.globalAlpha = 1;
  }

  // ---- Sanctuary fixtures (robed NPCs, Godot parity)
  if (pz === 0) {
    for (const n of NPCS) {
      const [nx, ny, nz] = n.pos;
      if (nz !== 0) continue;
      const X = sx(nx);
      const Y = sy(ny);
      ctx.globalAlpha = 0.35;
      ctx.fillStyle = "#000";
      ctx.beginPath();
      ctx.ellipse(X + T / 2, Y + T * 0.8, T * 0.3, T * 0.12, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.globalAlpha = 1;
      const bw = T * 0.6;
      const bh = T * 0.68;
      const bx = X + (T - bw) / 2;
      const by = Y + T * 0.12;
      ctx.fillStyle = "rgba(0,0,0,0.85)";
      rr(ctx, bx - 3, by - 3, bw + 6, bh + 6, 10);
      ctx.fill();
      ctx.fillStyle = "#ebe6d6";
      rr(ctx, bx, by, bw, bh, 9);
      ctx.fill();
      ctx.fillStyle = n.color;
      rr(ctx, bx, by + bh * 0.55, bw, bh * 0.45, 8);
      ctx.fill();
      // attention pip + name
      ctx.fillStyle = "#ffd166";
      ctx.beginPath();
      ctx.arc(X + T / 2, Y + T * 0.02, T * 0.09, 0, Math.PI * 2);
      ctx.fill();
      ctx.font = `900 ${Math.round(T * 0.2)}px ui-sans-serif, system-ui`;
      ctx.textAlign = "center";
      ctx.fillStyle = "rgba(255,255,255,0.9)";
      ctx.fillText(n.name, X + T / 2, Y - T * 0.08);
    }
  }

  // ---- walls (drawn after floor so they overlap the tile above)
  for (let ty = minTy; ty <= maxTy; ty++) {
    for (let tx = minTx; tx <= maxTx; tx++) {
      if (tiles[ty][tx] !== "wall") continue;
      const X = sx(tx);
      const Y = sy(ty);
      const def = TILE_DEFS.wall;
      ctx.fillStyle = def.side;
      rr(ctx, X, Y - T * 0.18, T, T * 1.18, 8);
      ctx.fill();
      ctx.fillStyle = def.top;
      rr(ctx, X + 2, Y - T * 0.2, T - 4, T * 0.72, 8);
      ctx.fill();
      ctx.fillStyle = "rgba(0,0,0,0.18)";
      rr(ctx, X + 5, Y + T * 0.16, T - 10, T * 0.16, 4);
      ctx.fill();
    }
  }

  // ---- projectiles
  for (const pr of g.projectiles) {
    if (pr.z !== pz) continue;
    const p = Math.min(1, (now - pr.born) / pr.duration);
    const X = sx(pr.fx + (pr.tx - pr.fx) * p) + T / 2;
    const Y = sy(pr.fy + (pr.ty - pr.fy) * p) + T / 2;
    ctx.fillStyle = pr.color;
    ctx.shadowColor = pr.color;
    ctx.shadowBlur = 14;
    ctx.beginPath();
    ctx.arc(X, Y, T * 0.16, 0, Math.PI * 2);
    ctx.fill();
    ctx.shadowBlur = 0;
  }

  // ---- monsters (current floor only — other floors are frozen)
  const sorted = [...g.monsters]
    .filter((m) => m.z === pz)
    .sort((a, b) => a.ry - b.ry);
  for (const m of sorted) {
    const X = sx(m.rx);
    const Y = sy(m.ry);
    const dying = m.dying ? Math.min(1, (now - m.dying) / 320) : 0;
    ctx.save();
    if (dying) {
      ctx.globalAlpha = 1 - dying;
      ctx.translate(X + T / 2, Y + T / 2);
      ctx.scale(1 + dying * 0.5, 1 - dying * 0.4);
      ctx.translate(-(X + T / 2), -(Y + T / 2));
    }
    // shadow
    ctx.globalAlpha *= 0.35;
    ctx.fillStyle = "#000";
    ctx.beginPath();
    ctx.ellipse(X + T / 2, Y + T * 0.78, T * 0.3, T * 0.13, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = dying ? 1 - dying : 1;

    const bob = Math.sin(now / 300 + m.id * 1.7) * T * 0.03;
    const winding = now < m.windupUntil;
    const scale = winding ? 1 + Math.sin((now / m.def.windup) * Math.PI) * 0.12 : 1;
    const bw = T * 0.62 * scale;
    const bh = T * 0.62 * scale;
    const bx = X + (T - bw) / 2;
    const by = Y + T * 0.16 + bob;

    // chunky outline body
    ctx.fillStyle = "rgba(0,0,0,0.85)";
    rr(ctx, bx - 3, by - 3, bw + 6, bh + 6, 12);
    ctx.fill();
    ctx.fillStyle = now < m.hitFlash ? "#ffffff" : m.def.color;
    rr(ctx, bx, by, bw, bh, 10);
    ctx.fill();
    // top highlight
    ctx.fillStyle = "rgba(255,255,255,0.22)";
    rr(ctx, bx + 4, by + 4, bw - 8, bh * 0.3, 6);
    ctx.fill();

    ctx.font = `${Math.round(bh * 0.62)}px serif`;
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText(m.def.glyph, bx + bw / 2, by + bh / 2 + 1);
    ctx.textBaseline = "alphabetic";

    // hp bar
    if (m.hp < m.maxHp || g.targetId === m.id) {
      const bwid = T * 0.66;
      const bxx = X + (T - bwid) / 2;
      const byy = by - 10;
      ctx.fillStyle = "rgba(0,0,0,0.7)";
      rr(ctx, bxx - 1.5, byy - 1.5, bwid + 3, 7, 3.5);
      ctx.fill();
      ctx.fillStyle = "#ff5a6e";
      rr(ctx, bxx, byy, bwid * Math.max(0, m.hp / m.maxHp), 4, 2);
      ctx.fill();
    }
    ctx.restore();

    // MARK reticle + 2s auto-attack tick arc
    if (g.targetId === m.id && !m.dying) {
      const r = T * 0.5;
      ctx.save();
      ctx.translate(X + T / 2, Y + T / 2);
      ctx.rotate(now / 900);
      ctx.strokeStyle = "#ffd166";
      ctx.lineWidth = 3;
      ctx.setLineDash([r * 0.5, r * 0.55]);
      ctx.beginPath();
      ctx.arc(0, 0, r, 0, Math.PI * 2);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.restore();

      // Solid arc filling over COMBAT.AUTO_ATTACK_MS — the tick you can read.
      const pct = g.autoTickPct();
      ctx.save();
      ctx.translate(X + T / 2, Y + T / 2);
      ctx.strokeStyle = pct >= 1 ? "#ffffff" : "#ff8a3d";
      ctx.lineWidth = 4;
      ctx.lineCap = "round";
      ctx.beginPath();
      ctx.arc(0, 0, r * 0.78, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * pct);
      ctx.stroke();
      ctx.restore();
    }
  }

  // ---- player
  {
    const p = g.player;
    const X = sx(p.rx);
    const Y = sy(p.ry);
    ctx.globalAlpha = p.dead ? 0.35 : 1;
    ctx.save();
    ctx.globalAlpha = (p.dead ? 0.25 : 0.4);
    ctx.fillStyle = "#000";
    ctx.beginPath();
    ctx.ellipse(X + T / 2, Y + T * 0.8, T * 0.32, T * 0.14, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
    ctx.globalAlpha = p.dead ? 0.4 : 1;

    const bob = Math.sin(now / 260) * T * 0.03;
    const bw = T * 0.66;
    const bh = T * 0.7;
    const bx = X + (T - bw) / 2;
    const by = Y + T * 0.1 + bob;

    if (p.wardHp > 0) {
      ctx.strokeStyle = "#06d6a0";
      ctx.lineWidth = 3;
      ctx.globalAlpha = 0.75;
      ctx.beginPath();
      ctx.arc(X + T / 2, Y + T * 0.45, T * 0.52, 0, Math.PI * 2);
      ctx.stroke();
      ctx.fillStyle = "rgba(6,214,160,0.14)";
      ctx.fill();
      ctx.globalAlpha = 1;
    }

    ctx.fillStyle = "rgba(0,0,0,0.85)";
    rr(ctx, bx - 3.5, by - 3.5, bw + 7, bh + 7, 13);
    ctx.fill();
    ctx.fillStyle = now < p.hitFlash ? "#ffffff" : p.dead ? "#5b6270" : "#e8eaf0";
    rr(ctx, bx, by, bw, bh, 11);
    ctx.fill();
    // cloak
    ctx.fillStyle = p.dead ? "#3a3f4b" : "#c0392b";
    rr(ctx, bx, by + bh * 0.45, bw, bh * 0.55, 10);
    ctx.fill();
    // visor
    ctx.fillStyle = "#1a1d26";
    rr(ctx, bx + bw * 0.18, by + bh * 0.2, bw * 0.64, bh * 0.16, 4);
    ctx.fill();
    // facing pip
    ctx.fillStyle = "#ffd166";
    ctx.beginPath();
    ctx.arc(
      X + T / 2 + p.facing.x * T * 0.36,
      Y + T * 0.45 + p.facing.y * T * 0.36,
      T * 0.07,
      0,
      Math.PI * 2,
    );
    ctx.fill();

    // cast ring
    if (p.castKey && now < p.castUntil) {
      ctx.strokeStyle = "#ffd166";
      ctx.lineWidth = 4;
      ctx.beginPath();
      ctx.arc(X + T / 2, Y + T * 0.45, T * 0.45, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * 0.7);
      ctx.stroke();
    }

    // status pips
    const pips = p.statuses.filter((s) => s.key !== "ward");
    pips.forEach((s, i) => {
      const c = s.key === "poison" ? "#84cc16" : s.key === "burn" ? "#f97316" : "#38bdf8";
      ctx.fillStyle = c;
      ctx.beginPath();
      ctx.arc(bx + 6 + i * 11, by - 9, 4.5, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = "rgba(0,0,0,0.8)";
      ctx.lineWidth = 1.5;
      ctx.stroke();
    });
    ctx.globalAlpha = 1;
  }

  // ---- shove preview (drag gesture)
  if (g.pushPreview) {
    const { from, to, valid } = g.pushPreview;
    const col = valid ? "#4cc9f0" : "#ef4444";
    const FX = sx(from.x) + T / 2;
    const FY = sy(from.y) + T / 2;
    const TX = sx(to.x) + T / 2;
    const TY = sy(to.y) + T / 2;

    ctx.globalAlpha = 0.3;
    ctx.fillStyle = col;
    rr(ctx, sx(to.x) + 2, sy(to.y) + 2, T - 4, T - 6, 8);
    ctx.fill();
    ctx.globalAlpha = 0.95;
    ctx.strokeStyle = col;
    ctx.lineWidth = 3.5;
    ctx.setLineDash([7, 6]);
    rr(ctx, sx(to.x) + 2, sy(to.y) + 2, T - 4, T - 6, 8);
    ctx.stroke();
    ctx.setLineDash([]);

    // arrow shaft + head
    ctx.beginPath();
    ctx.moveTo(FX, FY);
    ctx.lineTo(TX, TY);
    ctx.lineWidth = 5;
    ctx.stroke();
    const ang = Math.atan2(TY - FY, TX - FX);
    ctx.beginPath();
    ctx.moveTo(TX, TY);
    ctx.lineTo(TX - Math.cos(ang - 0.5) * T * 0.28, TY - Math.sin(ang - 0.5) * T * 0.28);
    ctx.lineTo(TX - Math.cos(ang + 0.5) * T * 0.28, TY - Math.sin(ang + 0.5) * T * 0.28);
    ctx.closePath();
    ctx.fillStyle = col;
    ctx.fill();

    if (!valid) {
      ctx.font = `900 ${Math.round(T * 0.3)}px ui-sans-serif, system-ui`;
      ctx.textAlign = "center";
      ctx.fillStyle = "#fff";
      ctx.fillText("✕", TX, TY + T * 0.1);
    }
    ctx.globalAlpha = 1;
  }

  // ---- floating combat text
  ctx.textAlign = "center";
  for (const f of g.floats) {
    const age = (now - f.born) / 1100;
    const X = sx(f.x) + T / 2;
    const Y = sy(f.y) + T * 0.4 - age * T * 0.9;
    ctx.globalAlpha = Math.max(0, 1 - age * age);
    const size = Math.round(T * (f.crit ? 0.4 : 0.3));
    ctx.font = `900 ${size}px ui-sans-serif, system-ui, sans-serif`;
    ctx.lineWidth = 4;
    ctx.strokeStyle = "rgba(0,0,0,0.85)";
    ctx.strokeText(f.text, X, Y);
    ctx.fillStyle = f.color;
    ctx.fillText(f.text, X, Y);
    ctx.globalAlpha = 1;
  }

  // ---- region banner tint at edges (soft vignette)
  const grad = ctx.createRadialGradient(cx, cy, Math.min(vp.w, vp.h) * 0.32, cx, cy, Math.max(vp.w, vp.h) * 0.75);
  const tint = pz !== 0 ? "#2b3a4a" : regionAt(g.player.x, g.player.y).tint;
  grad.addColorStop(0, "rgba(0,0,0,0)");
  grad.addColorStop(1, tint + "aa");
  ctx.globalCompositeOperation = "multiply";
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, vp.w, vp.h);
  ctx.globalCompositeOperation = "source-over";
}

export function renderMinimap(
  ctx: CanvasRenderingContext2D,
  g: GameEngine,
  size: number,
) {
  const tiles = g.map.tiles;
  const mw = tiles[0].length;
  const mh = tiles.length;
  const pz = g.player.z;
  const s = size / mw;
  ctx.clearRect(0, 0, size, size);
  ctx.fillStyle = "#0b0d12";
  ctx.fillRect(0, 0, size, size);
  for (let y = 0; y < mh; y++) {
    for (let x = 0; x < mw; x++) {
      const k = tiles[y][x];
      const d = TILE_DEFS[k];
      ctx.fillStyle = k === "wall" ? "#2a2d36" : k === "gate" ? "#8a6ac0" : d.top;
      ctx.fillRect(x * s, y * s, s, s);
    }
  }
  if (pz === 0) {
    ctx.fillStyle = "#ffd166";
    ctx.fillRect((TEMPLE.x - 1) * s, (TEMPLE.y - 1) * s, s * 3, s * 3);
  }
  for (const m of g.monsters) {
    if (m.dying || m.z !== pz) continue;
    ctx.fillStyle = m.aggro ? "#ff5a6e" : "rgba(255,255,255,0.35)";
    ctx.fillRect(m.x * s, m.y * s, s, s);
  }
  for (const it of g.visibleGround()) {
    ctx.fillStyle = g.canLoot(it) ? "#fde047" : "#f87171";
    ctx.fillRect(it.x * s, it.y * s, s, s);
  }
  ctx.fillStyle = "#4cc9f0";
  ctx.fillRect(g.player.x * s - s * 0.5, g.player.y * s - s * 0.5, s * 2, s * 2);
}
