"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { GameEngine, type GameEvent, type Monster } from "@/lib/game/engine";
import { render, renderMinimap } from "@/lib/game/renderer";
import {
  ABILITIES,
  COMBAT,
  DEFAULT_LOOT_FILTER,
  EQUIP_SLOTS,
  FERRY,
  ITEMS,
  NPCS,
  NPC_FERRY_COST,
  NPC_HEAL_COST,
  NPC_STOCK,
  RARITY_STYLES,
  SKILLS,
  SKILL_ORDER,
  VOCATIONS,
  VOCATION_ORDER,
  computeLoadout,
  stepMsFor,
  xpForLevel,
  type EquipSlot,
  type NpcDef,
} from "@/lib/game/content";
import { CRYPT_NAME, MAP_W, regionAt } from "@/lib/game/world";
import Joystick from "./Joystick";

type Toast = { id: number; text: string; tone: "good" | "bad" | "info" };
type InvRow = { itemKey: string; qty: number; name: string; glyph: string };
type Sheet = "none" | "bag" | "gear" | "filter" | "path" | "skills" | "npc";

const haptic = (pattern: number | number[]) => {
  if (typeof navigator !== "undefined" && "vibrate" in navigator) {
    try {
      navigator.vibrate(pattern);
    } catch {
      /* unsupported */
    }
  }
};

export default function GamePlay({ initialName }: { initialName: string }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const miniRef = useRef<HTMLCanvasElement>(null);
  const engineRef = useRef<GameEngine | null>(null);
  const [engine, setEngine] = useState<GameEngine | null>(null);
  const [name, setName] = useState(initialName);
  const nameFieldRef = useRef<HTMLInputElement>(null);
  const [started, setStarted] = useState(false);
  const [, force] = useState(0);
  const [toasts, setToasts] = useState<Toast[]>([]);
  const [inventory, setInventory] = useState<InvRow[]>([]);
  const [equipped, setEquipped] = useState<Partial<Record<EquipSlot, string>>>({});
  const [lootFilter, setLootFilter] = useState<string[]>(DEFAULT_LOOT_FILTER);
  const [autoPickup, setAutoPickup] = useState(true);
  const [autoAttack, setAutoAttack] = useState(true);
  const [sheet, setSheet] = useState<Sheet>("none");
  /** NPC sheet render source (state) + loop-guard mirror (ref). */
  const [npcOpen, setNpcOpen] = useState<NpcDef | null>(null);
  const npcRef = useRef<NpcDef | null>(null);
  const [banner, setBanner] = useState<string | null>(null);
  const [dim, setDim] = useState(false);
  const [deathCard, setDeathCard] = useState<{ killedBy: string; xpLost: number; gold: number } | null>(
    null,
  );
  const lastInputRef = useRef(0);
  const lootQueue = useRef<{ itemKey: string; qty: number }[]>([]);
  const deathQueue = useRef<GameEvent | null>(null);
  const teleQueue = useRef<{ event: string; payload?: Record<string, unknown> }[]>([]);
  /** Drag-to-shove gesture bookkeeping. */
  const dragRef = useRef<{
    monster: Monster | null;
    startTile: { x: number; y: number };
    startPx: { x: number; y: number };
    moved: boolean;
  } | null>(null);

  const loadout = computeLoadout(equipped);

  const toast = useCallback((text: string, tone: Toast["tone"] = "info") => {
    const id = Math.random();
    setToasts((t) => [...t.slice(-4), { id, text, tone }]);
    setTimeout(() => setToasts((t) => t.filter((x) => x.id !== id)), 2600);
  }, []);

  const markInput = useCallback(() => {
    lastInputRef.current = Date.now();
    setDim(false);
  }, []);

  // Restore the last character name straight into the uncontrolled field. Doing
  // this via DOM avoids a synchronous setState-in-effect cascade on mount.
  useEffect(() => {
    const stored = window.localStorage.getItem("remnants.name");
    if (stored && nameFieldRef.current) nameFieldRef.current.value = stored;
  }, []);

  // ------------------------------------------------------------ boot session
  const boot = useCallback(async () => {
    const clean = (nameFieldRef.current?.value ?? "").trim().slice(0, 18) || "Wanderer";
    setName(clean);
    let saved: Record<string, number> | undefined;
    let gear: Partial<Record<EquipSlot, string>> = {};
    let filter = DEFAULT_LOOT_FILTER;
    let pickup = true;
    let auto = true;
    try {
      const res = await fetch("/api/character", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: clean }),
      });
      const data = await res.json();
      if (data.character) {
        saved = {
          level: data.character.level,
          xp: data.character.xp,
          hp: data.character.hp,
          mana: data.character.mana,
          gold: data.character.gold,
          x: data.character.tileX,
          y: data.character.tileY,
          kills: data.character.kills,
          deaths: data.character.deaths,
        };
        setInventory(data.inventory ?? []);
        gear = data.equipped ?? {};
        setEquipped(gear);
        filter = data.settings?.lootFilter?.length ? data.settings.lootFilter : DEFAULT_LOOT_FILTER;
        pickup = data.settings?.autoPickup ?? true;
        auto = data.settings?.autoAttack ?? true;
        setLootFilter(filter);
        setAutoPickup(pickup);
        setAutoAttack(auto);
      }
      window.localStorage.setItem("remnants.name", clean);
    } catch {
      toast("Offline mode — progress will not persist.", "bad");
    }
    const created = new GameEngine(clean, 1337, saved, computeLoadout(gear), {
      autoPickup: pickup,
      autoAttack: auto,
      lootFilter: filter,
    });
    engineRef.current = created;
    setEngine(created);
    setStarted(true);
    haptic(24);
  }, [toast]);

  // ---------------------------------------------- push engine config changes
  useEffect(() => {
    engineRef.current?.setLoadout(computeLoadout(equipped));
  }, [equipped]);
  useEffect(() => {
    engineRef.current?.setLootFilter(lootFilter);
  }, [lootFilter]);
  useEffect(() => {
    engineRef.current?.setAutoPickup(autoPickup);
  }, [autoPickup]);
  useEffect(() => {
    engineRef.current?.setAutoAttackEnabled(autoAttack);
  }, [autoAttack]);

  // ------------------------------------------------------------- game loop
  useEffect(() => {
    if (!started) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    let raf = 0;
    let last = performance.now();
    let vp = { w: 0, h: 0, tile: 48, dpr: 1 };

    const resize = () => {
      const dpr = Math.min(2, window.devicePixelRatio || 1);
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      canvas.width = Math.floor(w * dpr);
      canvas.height = Math.floor(h * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      vp = { w, h, tile: Math.max(38, Math.min(76, Math.min(w, h) / 8.5)), dpr };
    };
    resize();
    window.addEventListener("resize", resize);

    const mini = miniRef.current;
    const mctx = mini?.getContext("2d") ?? null;
    let miniAcc = 0;
    let uiAcc = 0;

    const handleEvent = (e: GameEvent) => {
      switch (e.type) {
        case "kill":
          haptic([12, 30, 18]);
          teleQueue.current.push({ event: "kill", payload: { monster: e.monster } });
          break;
        case "loot":
          if (e.items.length) {
            for (const it of e.items) lootQueue.current.push(it);
            toast(
              e.items
                .map((i) => `${ITEMS[i.itemKey]?.glyph ?? ""} ${ITEMS[i.itemKey]?.name ?? i.itemKey} x${i.qty}`)
                .join(", "),
              "good",
            );
            haptic(18);
          }
          break;
        case "levelup":
          haptic([0, 40, 60, 80]);
          setBanner(`LEVEL ${e.level}`);
          setTimeout(() => setBanner(null), 2200);
          teleQueue.current.push({ event: "levelup", payload: { level: e.level } });
          break;
        case "damaged":
          haptic(e.amount > 15 ? [0, 45] : 14);
          break;
        case "death":
          haptic([0, 90, 60, 140]);
          deathQueue.current = e;
          setDeathCard({ killedBy: e.killedBy, xpLost: e.xpLost, gold: e.goldDropped });
          setTimeout(() => setDeathCard(null), 5200);
          break;
        case "push":
          haptic(e.ok ? [0, 26, 20, 12] : 6);
          if (e.ok) teleQueue.current.push({ event: "shove", payload: {} });
          else if (e.reason) toast(e.reason, "bad");
          break;
        case "denied":
          haptic(6);
          toast(e.reason, "bad");
          break;
        case "region":
          setBanner(e.name);
          setTimeout(() => setBanner((b) => (b === e.name ? null : b)), 1900);
          break;
        case "rift":
          haptic([0, 30, 30, 30]);
          toast(`Rift carries you to ${e.name}`, "info");
          break;
        case "vocation":
          toast(`Path of the ${e.name} — ${e.blurb}`, "good");
          break;
        case "nomana":
          haptic(8);
          break;
        default:
          break;
      }
    };

    const loop = (t: number) => {
      const dt = Math.min(64, t - last);
      last = t;
      const g = engineRef.current;
      if (g) {
        g.update(dt, t);
        render(ctx, g, vp, t);
        miniAcc += dt;
        if (mctx && miniAcc > 220) {
          miniAcc = 0;
          renderMinimap(mctx, g, mini!.width);
        }
        uiAcc += dt;
        if (uiAcc > 90) {
          uiAcc = 0;
          force((n) => n + 1);
        }
        for (const e of g.drainEvents()) handleEvent(e);
        // Walking away from an NPC counter closes the deal (Godot hud parity).
        if (npcRef.current && !g.canTalkNpc(npcRef.current)) {
          npcRef.current = null;
          setNpcOpen(null);
          setSheet((cur) => (cur === "npc" ? "none" : cur));
          toast("Deal closed — too far from the counter.", "info");
        }
        if (Date.now() - lastInputRef.current > 3800) setDim(true);
      }
      raf = requestAnimationFrame(loop);
    };

    raf = requestAnimationFrame(loop);
    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", resize);
    };
  }, [started, toast]);

  // ------------------------------------------------------------- persistence
  useEffect(() => {
    if (!started) return;
    const iv = setInterval(async () => {
      const g = engineRef.current;
      if (!g) return;
      const p = g.player;
      const loot = lootQueue.current.splice(0, lootQueue.current.length);
      const deathEv = deathQueue.current;
      deathQueue.current = null;
      const events = teleQueue.current.splice(0, teleQueue.current.length);
      try {
        const res = await fetch("/api/character/sync", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            name: p.name,
            state: {
              level: p.level,
              xp: p.xp,
              hp: Math.max(1, Math.round(p.hp)),
              maxHp: p.maxHp,
              mana: Math.round(p.mana),
              maxMana: p.maxMana,
              gold: p.gold,
              tileX: p.x,
              tileY: p.y,
              region: regionAt(p.x, p.y).name,
              kills: p.kills,
              deaths: p.deaths,
            },
            loot,
            events,
            death:
              deathEv && deathEv.type === "death"
                ? {
                    killedBy: deathEv.killedBy,
                    xpLost: deathEv.xpLost,
                    goldDropped: deathEv.goldDropped,
                    tileX: deathEv.x,
                    tileY: deathEv.y,
                    region: regionAt(deathEv.x, deathEv.y).name,
                    level: p.level,
                  }
                : undefined,
          }),
        });
        const data = await res.json();
        if (data.inventory) setInventory(data.inventory);
      } catch {
        /* keep playing offline */
      }
    }, 5000);
    return () => clearInterval(iv);
  }, [started]);

  const saveSettings = useCallback(
    async (patch: { autoPickup?: boolean; autoAttack?: boolean; lootFilter?: string[] }) => {
      try {
        await fetch("/api/character/settings", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name, ...patch }),
        });
      } catch {
        /* non-critical */
      }
    },
    [name],
  );

  // --------------------------------------------------------------- targeting
  const cycleTarget = useCallback(() => {
    const g = engineRef.current;
    if (!g) return;
    const near = g.monsters
      .filter((m) => !m.dying && m.z === g.player.z)
      .map((m) => ({ m, d: Math.max(Math.abs(m.x - g.player.x), Math.abs(m.y - g.player.y)) }))
      .filter((o) => o.d <= 6)
      .sort((a, b) => a.d - b.d);
    if (!near.length) return;
    const idx = near.findIndex((o) => o.m.id === g.targetId);
    g.setTarget(near[(idx + 1) % near.length].m.id);
    haptic(10);
  }, []);

  const drinkItem = useCallback(
    async (itemKey: string) => {
      markInput();
      try {
        const res = await fetch("/api/character/use", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name, itemKey }),
        });
        const data = await res.json();
        if (!res.ok) return toast(data.error ?? "Cannot use that", "bad");
        engineRef.current?.consume(data.effect.hp ?? 0, data.effect.mana ?? 0);
        setInventory(data.inventory);
        toast(data.effect.label, "good");
        haptic([0, 20, 40, 20]);
      } catch {
        toast("Server unreachable", "bad");
      }
    },
    [name, markInput, toast],
  );

  const changeGear = useCallback(
    async (action: "equip" | "unequip", payload: { itemKey?: string; slot?: EquipSlot }) => {
      markInput();
      try {
        const res = await fetch("/api/character/equipment", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name, action, ...payload }),
        });
        const data = await res.json();
        if (!res.ok) return toast(data.error ?? "Could not change gear", "bad");
        setEquipped(data.equipped ?? {});
        setInventory(data.inventory ?? []);
        haptic(16);
      } catch {
        toast("Server unreachable", "bad");
      }
    },
    [name, markInput, toast],
  );

  const toggleFilter = useCallback(
    (key: string) => {
      setLootFilter((prev) => {
        const next = prev.includes(key) ? prev.filter((k) => k !== key) : [...prev, key];
        saveSettings({ lootFilter: next });
        return next;
      });
      haptic(8);
    },
    [saveSettings],
  );

  // -------------------------------------------------- canvas pointer: tap/drag
  const tileFromPointer = useCallback((clientX: number, clientY: number) => {
    const g = engineRef.current;
    const canvas = canvasRef.current;
    if (!g || !canvas) return null;
    const rect = canvas.getBoundingClientRect();
    const tile = Math.max(38, Math.min(76, Math.min(rect.width, rect.height) / 8.5));
    const offX = rect.width / 2 - g.camX * tile - tile / 2;
    const offY = rect.height / 2 - g.camY * tile - tile / 2;
    return {
      x: Math.floor((clientX - rect.left - offX) / tile),
      y: Math.floor((clientY - rect.top - offY) / tile),
      tile,
    };
  }, []);

  const onPointerDown = useCallback(
    (e: React.PointerEvent<HTMLCanvasElement>) => {
      markInput();
      const g = engineRef.current;
      const t = tileFromPointer(e.clientX, e.clientY);
      if (!g || !t) return;
      (e.target as HTMLElement).setPointerCapture(e.pointerId);
      dragRef.current = {
        monster: g.monsterAt(t.x, t.y),
        startTile: { x: t.x, y: t.y },
        startPx: { x: e.clientX, y: e.clientY },
        moved: false,
      };
    },
    [markInput, tileFromPointer],
  );

  const onPointerMove = useCallback(
    (e: React.PointerEvent<HTMLCanvasElement>) => {
      const d = dragRef.current;
      const g = engineRef.current;
      if (!d || !g) return;
      const dist = Math.hypot(e.clientX - d.startPx.x, e.clientY - d.startPx.y);
      const t = tileFromPointer(e.clientX, e.clientY);
      if (!t) return;
      if (dist > 14) d.moved = true;
      if (d.monster && d.moved && (t.x !== d.startTile.x || t.y !== d.startTile.y)) {
        g.previewPush(d.monster, t.x, t.y);
      } else {
        g.clearPushPreview();
      }
    },
    [tileFromPointer],
  );

  const onPointerUp = useCallback(
    (e: React.PointerEvent<HTMLCanvasElement>) => {
      const d = dragRef.current;
      const g = engineRef.current;
      dragRef.current = null;
      if (!d || !g) return;
      g.clearPushPreview();
      const t = tileFromPointer(e.clientX, e.clientY);
      if (!t) return;

      const sameTile = t.x === d.startTile.x && t.y === d.startTile.y;
      if (d.monster && d.moved && !sameTile) {
        // Hold-and-release on a creature = shove one tile toward the release point.
        g.push(d.monster, t.x, t.y);
        return;
      }
      // NPCs first (their tile may hold loot underneath), then mark/loot.
      const npc = g.npcAt(d.startTile.x, d.startTile.y, g.player.z);
      if (npc) {
        if (g.canTalkNpc(npc)) {
          npcRef.current = npc;
          setNpcOpen(npc);
          setSheet("npc");
        } else {
          toast("Come closer.", "info");
        }
        haptic(10);
        return;
      }
      // Plain tap: mark a creature or loot a tile.
      g.tapTile(d.startTile.x, d.startTile.y);
      haptic(8);
    },
    [tileFromPointer, toast],
  );

  // ------------------------------------------------------------- keyboard
  useEffect(() => {
    if (!started) return;
    const held = new Set<string>();
    const dirFor = () => {
      let x = 0;
      let y = 0;
      if (held.has("a") || held.has("arrowleft")) x -= 1;
      if (held.has("d") || held.has("arrowright")) x += 1;
      if (held.has("w") || held.has("arrowup")) y -= 1;
      if (held.has("s") || held.has("arrowdown")) y += 1;
      return x || y ? { x, y } : null;
    };
    const down = (e: KeyboardEvent) => {
      const k = e.key.toLowerCase();
      markInput();
      if (["1", "2", "3", "4"].includes(k)) return engineRef.current?.ability(Number(k) - 1);
      if (k === " ") {
        e.preventDefault();
        return engineRef.current?.ability(0);
      }
      if (k === "tab") {
        e.preventDefault();
        return cycleTarget();
      }
      if (k === "g") return engineRef.current?.lootAllNearby();
      if (k === "i") return setSheet((s) => (s === "bag" ? "none" : "bag"));
      if (k === "c") return setSheet((s) => (s === "gear" ? "none" : "gear"));
      if (k === "f") return setSheet((s) => (s === "filter" ? "none" : "filter"));
      if (k === "p") return setSheet((s) => (s === "path" ? "none" : "path"));
      if (k === "k") return setSheet((s) => (s === "skills" ? "none" : "skills"));
      held.add(k);
      engineRef.current?.setHeld(dirFor());
    };
    const up = (e: KeyboardEvent) => {
      held.delete(e.key.toLowerCase());
      engineRef.current?.setHeld(dirFor());
    };
    window.addEventListener("keydown", down);
    window.addEventListener("keyup", up);
    return () => {
      window.removeEventListener("keydown", down);
      window.removeEventListener("keyup", up);
    };
  }, [started, markInput, cycleTarget]);

  // The engine is a long-lived mutable object; it lives in state (not a ref) so
  // render may read it. Re-renders are driven by the rAF loop's `force` tick.
  const g = engine;
  const p = g?.player;

  // ------------------------------------------------------------------ gate
  if (!started) {
    return (
      <div className="relative flex min-h-dvh flex-col items-center justify-center overflow-hidden bg-[#0b0d12] px-6 text-slate-100">
        <div className="pointer-events-none absolute inset-0 opacity-40 [background:radial-gradient(circle_at_30%_20%,#1e3a5f,transparent_55%),radial-gradient(circle_at_75%_75%,#4a2b3d,transparent_55%)]" />
        <div className="relative w-full max-w-sm rounded-3xl border border-white/10 bg-black/50 p-6 backdrop-blur-xl">
          <p className="text-xs font-black uppercase tracking-[0.35em] text-amber-400">Remnants</p>
          <h1 className="mt-2 text-3xl font-black leading-tight">Enter the Hollow</h1>
          <p className="mt-2 text-sm text-slate-400">
            Mark a creature and it is struck every 2 seconds. Drag a creature to shove it one tile.
            Death costs 10% XP and half your carried gold.
          </p>
          <label className="mt-6 block text-[11px] font-bold uppercase tracking-widest text-slate-400">
            Character name
          </label>
          <input
            ref={nameFieldRef}
            defaultValue={initialName}
            onKeyDown={(e) => e.key === "Enter" && boot()}
            maxLength={18}
            placeholder="Wanderer"
            className="mt-2 w-full rounded-xl border border-white/15 bg-white/5 px-4 py-3 text-lg font-bold outline-none focus:border-amber-400"
          />
          <button
            onClick={boot}
            className="mt-4 w-full rounded-xl border-b-4 border-amber-700 bg-amber-500 px-4 py-3.5 text-base font-black uppercase tracking-wide text-black active:translate-y-0.5 active:border-b-2"
          >
            Descend
          </button>
          <div className="mt-4 grid grid-cols-2 gap-2 text-[11px] text-slate-500">
            <p>📱 Tap to mark · drag creature to shove · tap a robed NPC to talk</p>
            <p>⌨️ WASD · 1-4 · Tab · G loot · P path · K skills</p>
          </div>
          <Link href="/" className="mt-4 block text-center text-xs text-slate-500 underline">
            Back to the design bible
          </Link>
        </div>
      </div>
    );
  }

  const hpPct = p ? Math.max(0, p.hp / p.maxHp) : 1;
  const mpPct = p ? Math.max(0, p.mana / p.maxMana) : 1;
  const xpPct = g ? g.xpProgress() : 0;
  const inCrypt = (p?.z ?? 0) !== 0;
  const regionName = p ? (inCrypt ? CRYPT_NAME : regionAt(p.x, p.y).name) : null;
  const regionBand = p
    ? inCrypt
      ? "The deep below · no shrine"
      : regionAt(p.x, p.y).levelBand
    : null;
  const tgt = g?.target() ?? null;
  const fade = dim ? 0.32 : 1;
  const inPz = g?.inProtectedZone ?? false;
  const pushPct = g?.pushCooldownPct() ?? 0;
  const autoPct = g?.autoTickPct() ?? 0;
  const nearbyLoot = g
    ? g
        .visibleGround()
        .filter((it) => Math.max(Math.abs(it.x - g.player.x), Math.abs(it.y - g.player.y)) <= 1)
    : [];
  const equippable = inventory.filter((i) => ITEMS[i.itemKey]?.slot);

  return (
    <div className="relative h-dvh w-full select-none overflow-hidden bg-[#0b0d12] text-slate-100">
      <canvas
        ref={canvasRef}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={() => {
          dragRef.current = null;
          engineRef.current?.clearPushPreview();
        }}
        className="absolute inset-0 h-full w-full touch-none"
      />

      {/* ---------- vitals ---------- */}
      <div
        className="pointer-events-none absolute left-3 top-3 w-56 max-w-[52vw]"
        style={{ opacity: fade, transition: "opacity .5s ease" }}
      >
        <div className="rounded-2xl border border-white/10 bg-black/55 p-2.5 backdrop-blur-md">
          <div className="flex items-center gap-2">
            <div className="grid h-9 w-9 shrink-0 place-items-center rounded-xl border-2 border-black/60 bg-gradient-to-b from-amber-300 to-amber-600 text-sm font-black text-black">
              {p?.level ?? 1}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-xs font-black uppercase tracking-wide">{name}</p>
              <div className="mt-1 h-2.5 w-full overflow-hidden rounded-full bg-black/60">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-rose-600 to-rose-400 transition-[width] duration-150"
                  style={{ width: `${hpPct * 100}%` }}
                />
              </div>
              <div className="mt-1 h-2 w-full overflow-hidden rounded-full bg-black/60">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-sky-600 to-sky-400 transition-[width] duration-150"
                  style={{ width: `${mpPct * 100}%` }}
                />
              </div>
            </div>
          </div>
          <div className="mt-1.5 h-1 w-full overflow-hidden rounded-full bg-black/60">
            <div className="h-full rounded-full bg-lime-400" style={{ width: `${xpPct * 100}%` }} />
          </div>
          <div className="mt-1.5 flex items-center justify-between text-[10px] font-bold text-slate-400">
            <span>
              {Math.max(0, Math.round(p?.hp ?? 0))}/{p?.maxHp}
            </span>
            <span className="text-amber-300">{p?.gold ?? 0}g</span>
            <span className="text-slate-300">🛡 {loadout.armor}</span>
            <span>{p ? Math.max(0, xpForLevel(p.level) - p.xp) : 0} xp→</span>
          </div>
        </div>
        <div className="mt-1.5 flex flex-wrap gap-1.5">
          <span className="rounded-lg bg-sky-500/25 px-2 py-0.5 text-[10px] font-black uppercase text-sky-200">
            {p ? (VOCATIONS[p.vocation]?.name ?? "Warrior") : ""}
          </span>
          {inPz && (
            <span className="rounded-lg bg-amber-500/25 px-2 py-0.5 text-[10px] font-black uppercase text-amber-200">
              🕊 protected zone
            </span>
          )}
          {loadout.heavy > 0 && (
            <span className="rounded-lg bg-slate-500/25 px-2 py-0.5 text-[10px] font-black uppercase text-slate-300">
              ⚓ {stepMsFor(loadout.heavy)}ms step
            </span>
          )}
          {p?.statuses.map((s) => (
            <span
              key={s.key}
              className={`rounded-lg px-2 py-0.5 text-[10px] font-black uppercase ${
                s.key === "poison"
                  ? "bg-lime-500/25 text-lime-300"
                  : s.key === "burn"
                    ? "bg-orange-500/25 text-orange-300"
                    : s.key === "ward"
                      ? "bg-emerald-500/25 text-emerald-300"
                      : "bg-sky-500/25 text-sky-300"
              }`}
            >
              {s.key}
            </span>
          ))}
        </div>
      </div>

      {/* ---------- minimap + buttons ---------- */}
      <div
        className="absolute right-3 top-3 flex flex-col items-end gap-2"
        style={{ opacity: fade, transition: "opacity .5s ease" }}
      >
        <div className="rounded-2xl border border-white/10 bg-black/55 p-1.5 backdrop-blur-md">
          <canvas ref={miniRef} width={MAP_W * 3} height={MAP_W * 3} className="h-[104px] w-[104px] rounded-xl" />
        </div>
        <div className="rounded-xl border border-white/10 bg-black/55 px-2.5 py-1 text-right backdrop-blur-md">
          <p className="text-[10px] font-black uppercase tracking-wider text-amber-300">{regionName}</p>
          <p className="text-[9px] text-slate-400">{regionBand}</p>
        </div>
        <div className="pointer-events-auto flex gap-1.5">
          {(
            [
              ["bag", "🎒"],
              ["gear", "🧰"],
              ["filter", "🔎"],
              ["path", "🧭"],
              ["skills", "✨"],
            ] as [Sheet, string][]
          ).map(([s, glyph]) => (
            <button
              key={s}
              onClick={() => {
                markInput();
                setSheet((cur) => (cur === s ? "none" : s));
              }}
              className={`relative rounded-xl border px-2.5 py-1.5 text-xs font-bold backdrop-blur-md active:scale-95 ${
                sheet === s ? "border-amber-400 bg-amber-500/25" : "border-white/15 bg-black/55"
              }`}
            >
              {glyph}
              {s === "skills" && (p?.skillPoints ?? 0) > 0 && (
                <span className="absolute -right-1 -top-1 grid h-4 w-4 place-items-center rounded-full bg-lime-400 text-[9px] font-black text-black">
                  {p?.skillPoints}
                </span>
              )}
            </button>
          ))}
          <Link
            href="/"
            className="rounded-xl border border-white/15 bg-black/55 px-2.5 py-1.5 text-xs font-bold backdrop-blur-md active:scale-95"
          >
            ✕
          </Link>
        </div>
      </div>

      {/* ---------- marked target plate ---------- */}
      {tgt && (
        <div className="pointer-events-none absolute left-1/2 top-3 w-56 -translate-x-1/2">
          <div className="rounded-2xl border border-rose-500/40 bg-black/65 px-3 py-2 backdrop-blur-md">
            <div className="flex items-center justify-between text-[11px] font-black uppercase">
              <span>
                {tgt.def.glyph} {tgt.def.name}
              </span>
              <span className="text-rose-300">{Math.max(0, tgt.hp)}</span>
            </div>
            <div className="mt-1 h-2 overflow-hidden rounded-full bg-black/60">
              <div
                className="h-full bg-gradient-to-r from-rose-600 to-rose-400"
                style={{ width: `${Math.max(0, (tgt.hp / tgt.maxHp) * 100)}%` }}
              />
            </div>
            {/* 2-second auto-attack tick */}
            <div className="mt-1.5 flex items-center gap-1.5">
              <span className="text-[9px] font-black uppercase tracking-wider text-slate-400">
                {autoAttack ? "tick" : "auto off"}
              </span>
              <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-black/60">
                <div
                  className="h-full rounded-full bg-orange-400"
                  style={{ width: `${autoPct * 100}%` }}
                />
              </div>
              <span className="text-[9px] font-black text-orange-300">
                {(COMBAT.AUTO_ATTACK_MS / 1000).toFixed(0)}s
              </span>
            </div>
            {g && g.now < tgt.windupUntil && (
              <p className="mt-1 animate-pulse text-[10px] font-black uppercase tracking-widest text-amber-300">
                ⚠ winding up — move or shove
              </p>
            )}
          </div>
        </div>
      )}

      {banner && (
        <div className="pointer-events-none absolute left-1/2 top-1/3 -translate-x-1/2 text-center">
          <p className="animate-pulse text-3xl font-black uppercase tracking-[0.2em] text-amber-300 drop-shadow-[0_4px_0_rgba(0,0,0,0.8)]">
            {banner}
          </p>
        </div>
      )}

      <div className="pointer-events-none absolute left-3 top-44 flex w-56 flex-col gap-1.5">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={`rounded-xl border px-2.5 py-1.5 text-[11px] font-bold backdrop-blur-md ${
              t.tone === "good"
                ? "border-lime-500/40 bg-lime-950/70 text-lime-200"
                : t.tone === "bad"
                  ? "border-rose-500/40 bg-rose-950/70 text-rose-200"
                  : "border-white/15 bg-black/60 text-slate-200"
            }`}
          >
            {t.text}
          </div>
        ))}
      </div>

      {deathCard && (
        <div className="pointer-events-none absolute inset-0 grid place-items-center bg-rose-950/35 backdrop-blur-[2px]">
          <div className="w-72 rounded-3xl border-2 border-rose-600/60 bg-black/85 p-5 text-center">
            <p className="text-4xl">💀</p>
            <p className="mt-1 text-2xl font-black uppercase tracking-widest text-rose-400">You died</p>
            <p className="mt-1 text-xs text-slate-400">Slain by {deathCard.killedBy}</p>
            <div className="mt-4 grid grid-cols-2 gap-2 text-xs">
              <div className="rounded-xl bg-white/5 p-2">
                <p className="font-black text-rose-300">-{deathCard.xpLost}</p>
                <p className="text-[10px] uppercase text-slate-500">experience</p>
              </div>
              <div className="rounded-xl bg-white/5 p-2">
                <p className="font-black text-amber-300">-{deathCard.gold}g</p>
                <p className="text-[10px] uppercase text-slate-500">dropped</p>
              </div>
            </div>
            <p className="mt-3 text-[11px] leading-relaxed text-slate-500">
              Your gold is on the floor, locked to you for 60 seconds. After that anyone may take it.
            </p>
          </div>
        </div>
      )}

      {/* ---------- sheets ---------- */}
      {sheet !== "none" && (
        <div className="absolute inset-x-0 bottom-0 z-20 max-h-[62dvh] overflow-y-auto rounded-t-3xl border-t border-white/15 bg-[#12141c]/96 p-4 backdrop-blur-xl">
          <div className="mb-3 flex items-center justify-between">
            <h2 className="text-sm font-black uppercase tracking-widest">
              {sheet === "bag"
                ? "Satchel"
                : sheet === "gear"
                  ? "Equipment"
                  : sheet === "filter"
                    ? "Loot filter"
                    : sheet === "path"
                      ? "Choose your path"
                      : sheet === "skills"
                        ? "Skill tree"
                        : "Sanctuary"}
            </h2>
            <button
              onClick={() => setSheet("none")}
              className="rounded-lg bg-white/10 px-3 py-1 text-xs font-bold"
            >
              Close
            </button>
          </div>

          {sheet === "bag" && (
            <>
              {inventory.length === 0 ? (
                <p className="text-xs text-slate-500">
                  Empty. Kill something — loot scatters over the 3×3 around the corpse.
                </p>
              ) : (
                <div className="grid grid-cols-4 gap-2 sm:grid-cols-6">
                  {inventory.map((it) => {
                    const def = ITEMS[it.itemKey];
                    const usable = Boolean(def?.effect);
                    const wearable = Boolean(def?.slot);
                    return (
                      <button
                        key={it.itemKey}
                        disabled={!usable && !wearable}
                        onClick={() =>
                          usable ? drinkItem(it.itemKey) : changeGear("equip", { itemKey: it.itemKey })
                        }
                        className={`rounded-xl border p-2 text-center ${
                          usable
                            ? "border-emerald-500/40 bg-emerald-500/10 active:scale-95"
                            : wearable
                              ? "border-sky-500/40 bg-sky-500/10 active:scale-95"
                              : "border-white/10 bg-white/5"
                        }`}
                      >
                        <p className="text-xl">{it.glyph}</p>
                        <p className="mt-0.5 truncate text-[10px] font-bold">{it.name}</p>
                        <p className="text-[10px] text-amber-300">x{it.qty}</p>
                        {usable && <p className="text-[9px] font-black uppercase text-emerald-300">use</p>}
                        {wearable && <p className="text-[9px] font-black uppercase text-sky-300">equip</p>}
                      </button>
                    );
                  })}
                </div>
              )}
              <Link
                href="/market"
                className="mt-3 block rounded-xl border-b-4 border-amber-700 bg-amber-500 py-2.5 text-center text-xs font-black uppercase text-black"
              >
                Take it to the market
              </Link>
            </>
          )}

          {sheet === "gear" && (
            <>
              <div className="mb-3 grid grid-cols-3 gap-2">
                {[
                  ["Armor", `${loadout.armor}`, "flat physical reduction", "text-sky-300"],
                  ["Weapon", `+${loadout.weaponDamage}`, "added to every tick", "text-orange-300"],
                  ["Step", `${stepMsFor(loadout.heavy)}ms`, `${loadout.heavy} encumbrance`, "text-lime-300"],
                ].map(([k, v, sub, c]) => (
                  <div key={k} className="rounded-2xl border border-white/10 bg-white/5 p-3 text-center">
                    <p className={`text-xl font-black ${c}`}>{v}</p>
                    <p className="text-[10px] font-black uppercase tracking-wider text-slate-300">{k}</p>
                    <p className="text-[9px] text-slate-500">{sub}</p>
                  </div>
                ))}
              </div>
              <div className="grid grid-cols-4 gap-2">
                {EQUIP_SLOTS.map((s) => {
                  const key = equipped[s.key];
                  const def = key ? ITEMS[key] : null;
                  return (
                    <button
                      key={s.key}
                      onClick={() => def && changeGear("unequip", { slot: s.key })}
                      className={`rounded-xl border p-2 text-center ${
                        def
                          ? "border-amber-400/50 bg-amber-500/10 active:scale-95"
                          : "border-dashed border-white/15 bg-white/[0.03]"
                      }`}
                    >
                      <p className="text-xl">{def?.glyph ?? s.glyph}</p>
                      <p className="mt-0.5 truncate text-[10px] font-bold">{def?.name ?? s.label}</p>
                      <p className="text-[9px] text-slate-500">
                        {def ? `🛡${def.armor ?? 0} ⚓${def.heavy ?? 0}` : "empty"}
                      </p>
                    </button>
                  );
                })}
              </div>
              <p className="mt-3 text-[11px] text-slate-500">
                Armour is <strong className="text-slate-300">flat</strong>: a 17-damage Ember Husk hits
                for {Math.max(1, 17 - loadout.armor)} against your current {loadout.armor} armour. Tap a
                slot to unequip.
              </p>
              {equippable.length > 0 && (
                <>
                  <p className="mt-4 text-[10px] font-black uppercase tracking-widest text-slate-400">
                    In satchel
                  </p>
                  <div className="mt-2 grid grid-cols-4 gap-2 sm:grid-cols-6">
                    {equippable.map((it) => (
                      <button
                        key={it.itemKey}
                        onClick={() => changeGear("equip", { itemKey: it.itemKey })}
                        className="rounded-xl border border-sky-500/40 bg-sky-500/10 p-2 text-center active:scale-95"
                      >
                        <p className="text-xl">{it.glyph}</p>
                        <p className="mt-0.5 truncate text-[10px] font-bold">{it.name}</p>
                        <p className="text-[9px] text-slate-500">
                          🛡{ITEMS[it.itemKey]?.armor ?? 0} ⚓{ITEMS[it.itemKey]?.heavy ?? 0}
                        </p>
                      </button>
                    ))}
                  </div>
                </>
              )}
            </>
          )}

          {sheet === "filter" && (
            <>
              <div className="mb-3 grid grid-cols-2 gap-2">
                <button
                  onClick={() => {
                    const v = !autoPickup;
                    setAutoPickup(v);
                    saveSettings({ autoPickup: v });
                    haptic(12);
                  }}
                  className={`rounded-2xl border p-3 text-left ${
                    autoPickup ? "border-emerald-500/50 bg-emerald-500/15" : "border-white/15 bg-white/5"
                  }`}
                >
                  <p className="text-xs font-black uppercase tracking-wider">
                    Auto pick-up {autoPickup ? "ON" : "OFF"}
                  </p>
                  <p className="mt-0.5 text-[10px] text-slate-400">
                    Walk over a tile to take filtered loot you own.
                  </p>
                </button>
                <button
                  onClick={() => {
                    const v = !autoAttack;
                    setAutoAttack(v);
                    saveSettings({ autoAttack: v });
                    haptic(12);
                  }}
                  className={`rounded-2xl border p-3 text-left ${
                    autoAttack ? "border-orange-500/50 bg-orange-500/15" : "border-white/15 bg-white/5"
                  }`}
                >
                  <p className="text-xs font-black uppercase tracking-wider">
                    Auto attack {autoAttack ? "ON" : "OFF"}
                  </p>
                  <p className="mt-0.5 text-[10px] text-slate-400">
                    Marked creatures are struck every 2s.
                  </p>
                </button>
              </div>
              <div className="mb-2 flex gap-2">
                <button
                  onClick={() => {
                    const all = Object.keys(ITEMS);
                    setLootFilter(all);
                    saveSettings({ lootFilter: all });
                  }}
                  className="rounded-lg bg-white/10 px-3 py-1 text-[10px] font-black uppercase"
                >
                  All
                </button>
                <button
                  onClick={() => {
                    setLootFilter(["gold"]);
                    saveSettings({ lootFilter: ["gold"] });
                  }}
                  className="rounded-lg bg-white/10 px-3 py-1 text-[10px] font-black uppercase"
                >
                  Gold only
                </button>
                <button
                  onClick={() => {
                    setLootFilter(DEFAULT_LOOT_FILTER);
                    saveSettings({ lootFilter: DEFAULT_LOOT_FILTER });
                  }}
                  className="rounded-lg bg-white/10 px-3 py-1 text-[10px] font-black uppercase"
                >
                  Recommended
                </button>
              </div>
              <p className="mb-2 text-[11px] text-slate-500">
                Unchecked items are <strong className="text-slate-300">invisible on the floor</strong> —
                they are not drawn, not tappable and skipped by auto pick-up. This is the single biggest
                readability lever on a phone screen.
              </p>
              <div className="grid grid-cols-2 gap-1.5 sm:grid-cols-3">
                {Object.values(ITEMS).map((it) => {
                  const on = lootFilter.includes(it.key);
                  const r = RARITY_STYLES[it.rarity];
                  return (
                    <button
                      key={it.key}
                      onClick={() => toggleFilter(it.key)}
                      className={`flex items-center gap-2 rounded-xl border px-2.5 py-2 text-left ${
                        on ? `border-white/20 ${r.bg}` : "border-white/10 bg-black/40 opacity-45"
                      }`}
                    >
                      <span className="text-lg">{it.glyph}</span>
                      <span className={`min-w-0 flex-1 truncate text-[11px] font-bold ${r.text}`}>
                        {it.name}
                      </span>
                      <span
                        className={`grid h-4 w-4 shrink-0 place-items-center rounded border text-[9px] font-black ${
                          on ? "border-emerald-400 bg-emerald-400 text-black" : "border-slate-600 text-transparent"
                        }`}
                      >
                        ✓
                      </span>
                    </button>
                  );
                })}
              </div>
            </>
          )}

          {sheet === "path" && (
            <div className="grid gap-2">
              {VOCATION_ORDER.map((key) => {
                const v = VOCATIONS[key];
                const cur = p?.vocation === key;
                return (
                  <button
                    key={key}
                    onClick={() => {
                      engineRef.current?.setVocation(key);
                      haptic(16);
                    }}
                    className={`rounded-2xl border p-3 text-left ${
                      cur ? "border-amber-400/70 bg-amber-500/15" : "border-white/15 bg-white/5"
                    }`}
                  >
                    <p className="flex items-center justify-between text-xs font-black uppercase tracking-wider">
                      <span className={cur ? "text-amber-300" : "text-slate-200"}>
                        {cur ? "◆ " : ""}
                        {v.name}
                      </span>
                      <span className="text-[10px] font-bold text-slate-400">
                        tick {v.tickRange} tile{v.tickRange > 1 ? "s" : ""}
                      </span>
                    </p>
                    <p className="mt-0.5 text-[11px] text-slate-400">{v.blurb}</p>
                    <p className="mt-1 text-[10px] font-bold text-slate-500">
                      HP ×{v.hpMult} · mana ×{v.manaMult} · steel ×{v.meleeMult} · spells ×{v.spellMult}
                      {v.tickShot ? " · ranged tick" : ""}
                    </p>
                  </button>
                );
              })}
              <p className="text-[11px] text-slate-500">
                Your path bends the shared 4-button kit. Changing it re-applies growth — current
                health and mana are kept.
              </p>
            </div>
          )}

          {sheet === "skills" && (
            <>
              <p className="mb-3 text-xs font-bold text-slate-300">
                Points available:{" "}
                <span className="text-lime-300">{p?.skillPoints ?? 0}</span>{" "}
                <span className="font-normal text-slate-500">— one per level.</span>
              </p>
              <div className="grid gap-2">
                {SKILL_ORDER.map((key) => {
                  const def = SKILLS[key];
                  const rank = p?.skills[key] ?? 0;
                  const maxed = rank >= def.max;
                  const canSpend = (p?.skillPoints ?? 0) > 0 && !maxed;
                  return (
                    <div
                      key={key}
                      className="flex items-center gap-3 rounded-2xl border border-white/10 bg-white/5 p-3"
                    >
                      <div className="min-w-0 flex-1">
                        <p className="text-xs font-black uppercase tracking-wider text-slate-200">
                          {def.name}{" "}
                          <span className="text-slate-500">
                            {rank}/{def.max}
                          </span>
                        </p>
                        <p className="mt-0.5 text-[11px] text-slate-400">{def.desc}</p>
                      </div>
                      <button
                        disabled={!canSpend}
                        onClick={() => {
                          engineRef.current?.spendSkill(key);
                          haptic(12);
                        }}
                        className={`grid h-9 w-9 shrink-0 place-items-center rounded-xl text-lg font-black ${
                          canSpend
                            ? "border-b-4 border-lime-700 bg-lime-500 text-black active:translate-y-0.5"
                            : "bg-white/5 text-slate-600"
                        }`}
                      >
                        +
                      </button>
                    </div>
                  );
                })}
              </div>
            </>
          )}

          {sheet === "npc" && npcOpen && (
            <>
              <p className="mb-3 text-[11px] text-slate-400">{npcOpen.blurb}</p>
              {npcOpen.role === "trader" && (
                <>
                  <p className="mb-2 text-[10px] font-black uppercase tracking-widest text-amber-300">
                    Buy — {p?.gold ?? 0}g in purse
                  </p>
                  <div className="grid grid-cols-2 gap-2">
                    {NPC_STOCK.map((key) => {
                      const def = ITEMS[key];
                      const cost = def?.basePrice ?? 1;
                      const poor = (p?.gold ?? 0) < cost;
                      return (
                        <button
                          key={key}
                          onClick={() => {
                            const r = engineRef.current?.npcBuy(key);
                            if (r && !r.ok && r.reason) toast(r.reason, "bad");
                            else haptic(16);
                          }}
                          className={`rounded-2xl border p-3 text-left ${
                            poor ? "border-white/10 bg-white/5 opacity-50" : "border-emerald-500/40 bg-emerald-500/10"
                          }`}
                        >
                          <p className="text-lg">{def?.glyph ?? "❔"}</p>
                          <p className="mt-0.5 truncate text-[11px] font-bold">{def?.name ?? key}</p>
                          <p className="text-[10px] font-black text-amber-300">{cost}g</p>
                        </button>
                      );
                    })}
                  </div>
                  <p className="mt-3 text-[11px] text-slate-500">
                    Selling loot to the Guild needs a server hand-off (an inventory-decrement
                    endpoint) — until then, the market is your counter.
                  </p>
                  <Link
                    href="/market"
                    className="mt-2 block rounded-xl border-b-4 border-amber-700 bg-amber-500 py-2.5 text-center text-xs font-black uppercase text-black"
                  >
                    Take it to the market
                  </Link>
                </>
              )}
              {npcOpen.role === "healer" && (
                <button
                  onClick={() => {
                    const r = engineRef.current?.npcHeal();
                    if (r && !r.ok && r.reason) toast(r.reason, "bad");
                    else {
                      haptic(20);
                      toast(`Mended for ${NPC_HEAL_COST}g`, "good");
                    }
                  }}
                  className="w-full rounded-2xl border-b-4 border-emerald-800 bg-emerald-600 py-3.5 text-sm font-black uppercase tracking-wide text-black active:translate-y-0.5"
                >
                  Be mended — {NPC_HEAL_COST}g
                </button>
              )}
              {npcOpen.role === "ferry" && (
                <div className="grid gap-2">
                  {FERRY.map((d) => (
                    <button
                      key={d.key}
                      onClick={() => {
                        const r = engineRef.current?.npcTravel(d.key);
                        if (r && !r.ok && r.reason) toast(r.reason, "bad");
                        else {
                          haptic(25);
                          setSheet("none");
                          npcRef.current = null;
                          setNpcOpen(null);
                        }
                      }}
                      className="rounded-2xl border border-sky-500/40 bg-sky-500/10 py-3 text-xs font-black uppercase tracking-wider text-sky-200 active:scale-95"
                    >
                      Sail: {d.name} — {NPC_FERRY_COST}g
                    </button>
                  ))}
                </div>
              )}
            </>
          )}
        </div>
      )}

      {/* ---------- thumb controls ---------- */}
      <div className="pointer-events-none absolute inset-x-0 bottom-0 flex items-end justify-between p-4 pb-[max(1rem,env(safe-area-inset-bottom))]">
        <div onPointerDown={markInput}>
          <Joystick
            onDir={(d) => {
              engineRef.current?.setHeld(d);
              if (d) markInput();
            }}
            dim={dim}
          />
        </div>

        <div
          className="pointer-events-auto grid grid-cols-2 gap-2.5"
          style={{ opacity: dim ? 0.55 : 1, transition: "opacity .45s ease" }}
        >
          <div className="col-span-2 flex gap-2">
            <button
              onPointerDown={(e) => {
                e.preventDefault();
                markInput();
                cycleTarget();
              }}
              className="h-11 flex-1 rounded-2xl border-2 border-black/50 bg-slate-700/80 text-[11px] font-black uppercase tracking-widest text-slate-100 backdrop-blur-sm active:scale-95"
            >
              🎯 Mark
            </button>
            <button
              onPointerDown={(e) => {
                e.preventDefault();
                markInput();
                engineRef.current?.lootAllNearby();
                haptic(12);
              }}
              className={`relative h-11 flex-1 overflow-hidden rounded-2xl border-2 border-black/50 text-[11px] font-black uppercase tracking-widest backdrop-blur-sm active:scale-95 ${
                nearbyLoot.length
                  ? "bg-amber-500/85 text-black"
                  : "bg-slate-700/80 text-slate-300"
              }`}
            >
              ✦ Loot{nearbyLoot.length ? ` ${nearbyLoot.length}` : ""}
            </button>
          </div>
          {ABILITIES.map((a, i) => {
            const cd = g?.cooldownPct(a.key) ?? 0;
            const noMana = (p?.mana ?? 0) < a.manaCost;
            return (
              <button
                key={a.key}
                onPointerDown={(e) => {
                  e.preventDefault();
                  markInput();
                  engineRef.current?.ability(i);
                  haptic(cd > 0 || noMana ? 6 : 16);
                }}
                className={`relative grid h-[68px] w-[68px] place-items-center overflow-hidden rounded-2xl border-2 border-black/60 text-2xl active:translate-y-1 ${
                  noMana ? "bg-slate-700/70" : "bg-gradient-to-b from-slate-200 to-slate-400"
                }`}
                style={{ boxShadow: `0 5px 0 rgba(0,0,0,.5), inset 0 0 0 3px ${a.color}55` }}
              >
                <span className={noMana ? "opacity-40" : ""}>{a.glyph}</span>
                <span className="absolute bottom-0.5 right-1 text-[9px] font-black text-sky-900">
                  {a.manaCost > 0 ? a.manaCost : ""}
                </span>
                <span className="absolute left-1 top-0.5 text-[9px] font-black text-black/50">{i + 1}</span>
                {cd > 0 && (
                  <span
                    className="pointer-events-none absolute inset-x-0 bottom-0 bg-black/65"
                    style={{ height: `${cd * 100}%` }}
                  />
                )}
              </button>
            );
          })}
          {/* Shove readiness indicator — the gesture lives on the canvas, not a button */}
          <div className="col-span-2 rounded-xl border border-white/10 bg-black/55 px-2 py-1 backdrop-blur-md">
            <div className="flex items-center gap-1.5">
              <span className="text-[9px] font-black uppercase tracking-wider text-slate-400">
                ✋ shove
              </span>
              <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-black/60">
                <div
                  className="h-full rounded-full bg-cyan-400"
                  style={{ width: `${(1 - pushPct) * 100}%` }}
                />
              </div>
            </div>
            <p className="mt-0.5 text-center text-[8px] uppercase tracking-wider text-slate-500">
              drag a creature 1 tile
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
