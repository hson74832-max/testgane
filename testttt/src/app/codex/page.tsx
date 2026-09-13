import type { Metadata } from "next";
import {
  ABILITIES,
  COMBAT,
  EQUIP_SLOTS,
  ITEMS,
  MONSTERS,
  RARITY_STYLES,
  statsForLevel,
  stepMsFor,
  xpForLevel,
} from "@/lib/game/content";

export const metadata: Metadata = { title: "Remnants — Systems Codex" };
export const dynamic = "force-static";

export default function CodexPage() {
  const levels = Array.from({ length: 12 }, (_, i) => i + 1);
  const maxXp = xpForLevel(levels[levels.length - 1]);

  return (
    <main className="mx-auto max-w-6xl px-4 py-8 pb-24">
      <p className="text-[11px] font-black uppercase tracking-[0.4em] text-amber-400">Reference</p>
      <h1 className="mt-1 text-3xl font-black text-slate-50 sm:text-4xl">Systems codex</h1>
      <p className="mt-2 max-w-2xl text-sm text-slate-400">
        The live numbers powering the vertical slice. Everything on this page is imported from the
        same content tables the game engine reads at runtime — the doc cannot drift from the build.
      </p>

      {/* progression */}
      <section className="mt-10">
        <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">
          Progression curve
        </h2>
        <p className="mt-1 max-w-2xl text-xs text-slate-500">
          <code className="rounded bg-black/50 px-1.5 py-0.5 text-amber-300">xp(n) = 60 · n^1.85</code>{" "}
          — deliberately steep from level 8, so the 10% death penalty in the Barrow costs a real
          evening rather than a real month.
        </p>
        <div className="mt-4 overflow-x-auto rounded-3xl border border-white/10 bg-white/[0.04] p-5">
          <div className="flex min-w-[560px] items-end gap-2" style={{ height: 180 }}>
            {levels.map((l) => {
              const xp = xpForLevel(l);
              const s = statsForLevel(l);
              return (
                <div key={l} className="group flex flex-1 flex-col items-center gap-1">
                  <span className="text-[9px] font-bold text-slate-500 opacity-0 group-hover:opacity-100">
                    {xp}
                  </span>
                  <div
                    className="w-full rounded-t-lg bg-gradient-to-t from-amber-600 to-amber-300"
                    style={{ height: `${(xp / maxXp) * 140}px` }}
                  />
                  <span className="text-[10px] font-black text-slate-400">{l}</span>
                  <span className="text-[8px] text-slate-600">{s.maxHp}hp</span>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* formulas */}
      <section className="mt-10 grid gap-4 md:grid-cols-3 lg:grid-cols-3">
        {[
          {
            t: "Auto-attack tick",
            f: "every 2000ms · dmg = 6 + floor(lv · 0.9) + weapon",
            n: "Melee reach only. Any manual ability resets the tick, so active play is always faster.",
          },
          {
            t: "Damage & mitigation",
            f: "dmg = max(1, (base + floor(lv · 1.6) + weapon) − armour)",
            n: "Flat mitigation, never percentages. Crit is a flat 14% for ×1.85 so the maths stays head-doable.",
          },
          {
            t: "Encumbrance",
            f: "step = 205 + min(90, heavy · 5) ms",
            n: "The counterweight to armour. Full plate costs 40ms per tile, which is a real telegraph tax.",
          },
          {
            t: "Death penalty",
            f: "xp -= xp · 0.10  ·  gold -= carried · 0.50",
            n: "Applied instantly. A Remnant cache spawns on the exact tile and is written to the world feed.",
          },
          {
            t: "Regeneration",
            f: "+1 + floor(lv/3) hp  ·  +2 + floor(lv/2) mp  per 1.4s",
            n: "Slow on purpose. Downtime is where the market for salves and draughts comes from.",
          },
        ].map((x) => (
          <div key={x.t} className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
            <h3 className="text-sm font-black uppercase tracking-widest text-slate-300">{x.t}</h3>
            <code className="mt-2 block rounded-xl bg-black/50 p-3 text-[11px] text-emerald-300">
              {x.f}
            </code>
            <p className="mt-2 text-[11px] leading-relaxed text-slate-500">{x.n}</p>
          </div>
        ))}
      </section>

      {/* bestiary table */}
      <section className="mt-10">
        <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">Bestiary</h2>
        <div className="mt-3 overflow-x-auto rounded-3xl border border-white/10 bg-white/[0.04]">
          <table className="w-full min-w-[720px] text-left text-xs">
            <thead className="border-b border-white/10 text-[10px] uppercase tracking-widest text-slate-500">
              <tr>
                {["Monster", "HP", "Dmg", "XP", "Tell (ms)", "Cadence", "Range", "Aggro", "Loot"].map((h) => (
                  <th key={h} className="px-4 py-3 font-black">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {Object.values(MONSTERS).map((m) => (
                <tr key={m.key}>
                  <td className="px-4 py-3">
                    <span className="mr-2">{m.glyph}</span>
                    <span className="font-black text-slate-100">{m.name}</span>
                  </td>
                  <td className="px-4 py-3 text-rose-300">{m.hp}</td>
                  <td className="px-4 py-3 text-orange-300">{m.damage}</td>
                  <td className="px-4 py-3 text-lime-300">{m.xp}</td>
                  <td className="px-4 py-3 font-black text-amber-300">{m.windup}</td>
                  <td className="px-4 py-3 text-slate-400">{m.cadence}ms</td>
                  <td className="px-4 py-3 text-slate-400">{m.attackRange}t</td>
                  <td className="px-4 py-3 text-slate-400">{m.aggroRange}t</td>
                  <td className="px-4 py-3 text-slate-400">
                    {m.loot
                      .map((l) => `${ITEMS[l.itemKey]?.name ?? l.itemKey} ${Math.round(l.chance * 100)}%`)
                      .join(", ")}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {/* abilities */}
      <section className="mt-10">
        <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">Ability table</h2>
        <div className="mt-3 overflow-x-auto rounded-3xl border border-white/10 bg-white/[0.04]">
          <table className="w-full min-w-[640px] text-left text-xs">
            <thead className="border-b border-white/10 text-[10px] uppercase tracking-widest text-slate-500">
              <tr>
                {["Ability", "Mana", "CD", "Wind-up", "Dmg", "Range", "Shape"].map((h) => (
                  <th key={h} className="px-4 py-3 font-black">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {ABILITIES.map((a) => (
                <tr key={a.key}>
                  <td className="px-4 py-3">
                    <span className="mr-2">{a.glyph}</span>
                    <span className="font-black text-slate-100">{a.name}</span>
                  </td>
                  <td className="px-4 py-3 text-sky-300">{a.manaCost}</td>
                  <td className="px-4 py-3 text-slate-400">{(a.cooldown / 1000).toFixed(2)}s</td>
                  <td className="px-4 py-3 text-amber-300">{a.windup}ms</td>
                  <td className="px-4 py-3 text-orange-300">{a.damage || "—"}</td>
                  <td className="px-4 py-3 text-slate-400">{a.range || "self"}</td>
                  <td className="px-4 py-3 text-slate-400">{a.shape}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {/* gear */}
      <section className="mt-10">
        <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">
          Gear slots & armour values
        </h2>
        <p className="mt-1 max-w-2xl text-xs text-slate-500">
          Armour rating is the plain sum of equipped pieces. Encumbrance is the plain sum too. Both
          numbers are shown on the character sheet at all times because both are decisions.
        </p>
        <div className="mt-3 overflow-x-auto rounded-3xl border border-white/10 bg-white/[0.04]">
          <table className="w-full min-w-[680px] text-left text-xs">
            <thead className="border-b border-white/10 text-[10px] uppercase tracking-widest text-slate-500">
              <tr>
                {["Piece", "Slot", "Armour", "Weapon dmg", "Encumbrance", "Step cost", "Base price"].map(
                  (h) => (
                    <th key={h} className="px-4 py-3 font-black">
                      {h}
                    </th>
                  ),
                )}
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {Object.values(ITEMS)
                .filter((i) => i.slot)
                .sort((a, b) => (a.slot ?? "").localeCompare(b.slot ?? ""))
                .map((it) => (
                  <tr key={it.key}>
                    <td className="px-4 py-3">
                      <span className="mr-2">{it.glyph}</span>
                      <span className={`font-black ${RARITY_STYLES[it.rarity].text}`}>{it.name}</span>
                    </td>
                    <td className="px-4 py-3 uppercase text-slate-500">
                      {EQUIP_SLOTS.find((s) => s.key === it.slot)?.label}
                    </td>
                    <td className="px-4 py-3 font-black text-sky-300">{it.armor ?? "—"}</td>
                    <td className="px-4 py-3 text-orange-300">{it.damage ? `+${it.damage}` : "—"}</td>
                    <td className="px-4 py-3 text-slate-400">{it.heavy ?? 0}</td>
                    <td className="px-4 py-3 text-lime-300">+{(it.heavy ?? 0) * COMBAT.MS_PER_HEAVY}ms</td>
                    <td className="px-4 py-3 text-amber-300">{it.basePrice}g</td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
        <div className="mt-3 grid gap-3 sm:grid-cols-3">
          {[
            {
              t: "Naked",
              armor: 0,
              heavy: 0,
              note: "Ember Husk hits for the full 17. Fastest possible footwork.",
            },
            {
              t: "Starter kit",
              armor: 4,
              heavy: 3,
              note: "Bone Knife + Leather Vest + Buckler. The default new-character loadout.",
            },
            {
              t: "Full Barrow plate",
              armor: 27,
              heavy: 18,
              note: "Everything equipped. Nothing in the game hits you for more than 1 — but you step at 295ms.",
            },
          ].map((b) => (
            <div key={b.t} className="rounded-2xl border border-white/10 bg-white/[0.04] p-4">
              <p className="text-xs font-black uppercase tracking-widest text-slate-200">{b.t}</p>
              <div className="mt-2 flex gap-3 text-[11px]">
                <span className="font-black text-sky-300">🛡 {b.armor}</span>
                <span className="font-black text-orange-300">
                  Husk → {Math.max(1, 17 - b.armor)} dmg
                </span>
                <span className="font-black text-lime-300">{stepMsFor(b.heavy)}ms</span>
              </div>
              <p className="mt-2 text-[11px] text-slate-500">{b.note}</p>
            </div>
          ))}
        </div>
      </section>

      {/* loot rules */}
      <section className="mt-10">
        <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">Loot rules</h2>
        <div className="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {[
            {
              t: "1 sqm spread",
              v: "3×3",
              c: "text-amber-300",
              n: "Drops distribute across the walkable tiles around the corpse, corpse tile first. Nine items never stack into one unreadable 44px pile.",
            },
            {
              t: "Claim window",
              v: `${COMBAT.LOOT_PROTECT_MS / 1000}s`,
              c: "text-rose-300",
              n: "The top damage dealer holds exclusive rights. A lock icon plus a depleting red arc renders on every protected stack.",
            },
            {
              t: "Ground decay",
              v: `${COMBAT.GROUND_DECAY_MS / 60000}min`,
              c: "text-slate-300",
              n: "After that the stack is deleted. Unclaimed wealth leaves the economy — a passive gold sink.",
            },
            {
              t: "Filter",
              v: "hide",
              c: "text-sky-300",
              n: "Excluded items are not rendered, not tappable, and skipped by auto pick-up. Purely a clarity tool, never a drop-rate modifier.",
            },
          ].map((x) => (
            <div key={x.t} className="rounded-2xl border border-white/10 bg-white/[0.04] p-4">
              <p className={`text-2xl font-black ${x.c}`}>{x.v}</p>
              <p className="text-[10px] font-black uppercase tracking-widest text-slate-300">{x.t}</p>
              <p className="mt-2 text-[11px] leading-relaxed text-slate-500">{x.n}</p>
            </div>
          ))}
        </div>
      </section>

      {/* items */}
      <section className="mt-10">
        <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">Item registry</h2>
        <div className="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {Object.values(ITEMS).map((it) => {
            const r = RARITY_STYLES[it.rarity];
            return (
              <div key={it.key} className={`rounded-2xl border border-white/10 p-4 ${r.bg}`}>
                <div className="flex items-center gap-2">
                  <span className={`grid h-11 w-11 place-items-center rounded-xl text-2xl ring-2 ${r.ring}`}>
                    {it.glyph}
                  </span>
                  <div className="min-w-0">
                    <p className={`truncate text-sm font-black ${r.text}`}>{it.name}</p>
                    <p className="text-[10px] uppercase tracking-widest text-slate-500">
                      {it.rarity} · {it.kind}
                    </p>
                  </div>
                </div>
                <p className="mt-3 text-[11px] leading-relaxed text-slate-400">{it.blurb}</p>
                <p className="mt-2 text-[11px] font-black text-amber-300">base {it.basePrice}g</p>
              </div>
            );
          })}
        </div>
      </section>

      {/* control map */}
      <section className="mt-10 grid gap-4 md:grid-cols-2">
        <div className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
          <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">Touch controls</h2>
          <ul className="mt-3 space-y-2 text-xs text-slate-400">
            <li><strong className="text-slate-200">Left stick</strong> — 8-way grid stepping, 205ms + encumbrance</li>
            <li><strong className="text-slate-200">Tap a creature</strong> — Mark it; starts the 2s auto-attack tick</li>
            <li><strong className="text-slate-200">Drag a creature → release</strong> — shove it 1 tile, cancelling its wind-up</li>
            <li><strong className="text-slate-200">Tap a loot stack</strong> — take it if adjacent and unlocked</li>
            <li><strong className="text-slate-200">Mark pad</strong> — cycle nearest hostiles within 6 tiles</li>
            <li><strong className="text-slate-200">Loot pad</strong> — sweep all claimable filtered loot within 1 tile</li>
            <li><strong className="text-slate-200">4 action pads</strong> — Strike / Cleave / Ash Bolt / Ward</li>
            <li><strong className="text-slate-200">Walk onto a stack</strong> — auto pick-up, if enabled</li>
          </ul>
        </div>
        <div className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
          <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">Desktop parity</h2>
          <ul className="mt-3 space-y-2 text-xs text-slate-400">
            <li><strong className="text-slate-200">WASD / arrows</strong> — movement</li>
            <li><strong className="text-slate-200">1 · 2 · 3 · 4</strong> — abilities (Space = Strike)</li>
            <li><strong className="text-slate-200">Tab</strong> — cycle Mark</li>
            <li><strong className="text-slate-200">Click</strong> — Mark / loot, identical to tap</li>
            <li>
              <strong className="text-slate-200">Hold left-click on a creature, drag, release</strong>{" "}
              — shove. Same gesture, same code path as touch.
            </li>
            <li><strong className="text-slate-200">G</strong> — loot everything nearby</li>
            <li><strong className="text-slate-200">I · C · F</strong> — satchel · character · loot filter</li>
          </ul>
          <p className="mt-3 text-[11px] text-slate-500">
            Desktop never receives extra information or extra actions. Any advantage there would
            fracture a shared persistent world.
          </p>
        </div>
      </section>
    </main>
  );
}
