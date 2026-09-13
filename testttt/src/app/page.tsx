import Link from "next/link";
import Image from "next/image";
import { COMBAT_LOOP, OPEN_ISSUES, PILLARS, RISKS, ROADMAP, SYSTEMS, UX_SPECS } from "@/lib/design";
import { MONSTERS, ABILITIES } from "@/lib/game/content";
import { REGIONS } from "@/lib/game/world";

export const dynamic = "force-static";

function Section({
  id,
  eyebrow,
  title,
  children,
}: {
  id?: string;
  eyebrow: string;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section id={id} className="mx-auto w-full max-w-6xl px-4 py-14 sm:py-20">
      <p className="text-[11px] font-black uppercase tracking-[0.4em] text-amber-400">{eyebrow}</p>
      <h2 className="mt-2 text-3xl font-black leading-tight text-slate-50 sm:text-4xl">{title}</h2>
      <div className="mt-8">{children}</div>
    </section>
  );
}

export default function Home() {
  return (
    <main className="pb-24">
      {/* ---------------------------------------------------------- hero */}
      <div className="relative overflow-hidden border-b border-white/10">
        <Image
          src="/images/keyart.jpg"
          alt="Remnants key art"
          fill
          priority
          className="object-cover opacity-45"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-[#0b0d12]/60 via-[#0b0d12]/80 to-[#0b0d12]" />
        <div className="relative mx-auto max-w-6xl px-4 py-20 sm:py-28">
          <span className="inline-block rounded-full border border-amber-500/40 bg-amber-500/10 px-3 py-1 text-[10px] font-black uppercase tracking-[0.3em] text-amber-300">
            Design Bible · v0.9 · Vertical Slice
          </span>
          <h1 className="mt-5 max-w-3xl text-5xl font-black leading-[0.95] text-white sm:text-7xl">
            REMNANTS
          </h1>
          <p className="mt-4 max-w-2xl text-lg font-medium text-slate-300 sm:text-xl">
            A tile-based, persistent-world MMORPG for phones. The grid-locked, high-stakes
            permanence of <span className="text-amber-300">Tibia</span>, wearing the readable,
            thumb-native skin of <span className="text-sky-300">Brawl Stars</span>.
          </p>
          <div className="mt-7 flex flex-wrap gap-3">
            <Link
              href="/play"
              className="rounded-2xl border-b-4 border-amber-700 bg-amber-500 px-6 py-3.5 text-sm font-black uppercase tracking-widest text-black active:translate-y-0.5 active:border-b-2"
            >
              ▶ Play the slice
            </Link>
            <Link
              href="#pillars"
              className="rounded-2xl border border-white/20 bg-white/5 px-6 py-3.5 text-sm font-black uppercase tracking-widest text-slate-200 backdrop-blur"
            >
              Read the pillars
            </Link>
          </div>
          <dl className="mt-10 grid max-w-3xl grid-cols-2 gap-3 sm:grid-cols-4">
            {[
              ["Platform", "iOS · Android · Web"],
              ["Perspective", "Top-down 40×40 grid"],
              ["Combat", "2s tick + manual"],
              ["Economy", "100% player-driven"],
            ].map(([k, v]) => (
              <div key={k} className="rounded-2xl border border-white/10 bg-black/40 p-3 backdrop-blur">
                <dt className="text-[10px] font-bold uppercase tracking-widest text-slate-500">{k}</dt>
                <dd className="mt-1 text-sm font-black text-slate-100">{v}</dd>
              </div>
            ))}
          </dl>
        </div>
      </div>

      {/* ------------------------------------------------------- pillars */}
      <Section id="pillars" eyebrow="Section 01" title="The four pillars">
        <div className="grid gap-4 md:grid-cols-2">
          {PILLARS.map((p) => (
            <article
              key={p.id}
              className="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-b from-white/[0.06] to-transparent p-6"
            >
              <div className={`absolute inset-x-0 top-0 h-1 bg-gradient-to-r ${p.accent}`} />
              <div className="flex items-start gap-3">
                <span className="text-3xl">{p.icon}</span>
                <div>
                  <h3 className="text-xl font-black text-slate-50">{p.title}</h3>
                  <p className="text-xs font-bold uppercase tracking-widest text-amber-400/80">{p.tag}</p>
                </div>
              </div>
              <p className="mt-4 text-sm leading-relaxed text-slate-400">{p.body}</p>
              <ul className="mt-4 space-y-1.5">
                {p.rules.map((r) => (
                  <li key={r} className="flex gap-2 text-xs text-slate-300">
                    <span className="text-amber-400">▸</span>
                    {r}
                  </li>
                ))}
              </ul>
            </article>
          ))}
        </div>
      </Section>

      {/* -------------------------------------------------- combat loop */}
      <Section eyebrow="Section 02" title="The core combat loop">
        <p className="-mt-4 mb-8 max-w-2xl text-sm text-slate-400">
          Six beats, repeated forever. Exactly one of them is automated — the tick — and everything
          else is a decision the player has to make with their hands.
        </p>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-6">
          {COMBAT_LOOP.map((c) => (
            <div key={c.step} className="rounded-2xl border border-white/10 bg-white/[0.04] p-4">
              <div className="flex items-baseline justify-between">
                <span className="text-2xl font-black text-amber-400/40">{c.step}</span>
                <span className="rounded-md bg-black/40 px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wider text-sky-300">
                  {c.ms}
                </span>
              </div>
              <h3 className="mt-1 text-base font-black text-slate-100">{c.name}</h3>
              <p className="mt-2 text-xs leading-relaxed text-slate-400">{c.text}</p>
            </div>
          ))}
        </div>

        <div className="mt-8 grid gap-4 md:grid-cols-2">
          <div className="rounded-3xl border border-white/10 bg-white/[0.04] p-6">
            <h3 className="text-sm font-black uppercase tracking-widest text-slate-300">
              Why the tick is 2 seconds
            </h3>
            <p className="mt-3 text-sm leading-relaxed text-slate-400">
              An earlier draft of this document banned automation outright. Playtesting killed it:
              on a 6-inch screen, a thumb parked on an attack pad is a thumb that cannot also read
              the floor, and the player ends up watching their own hands instead of the telegraph.
            </p>
            <p className="mt-3 text-sm leading-relaxed text-slate-400">
              So baseline damage moved onto a metronome — and the metronome was made deliberately
              slow. Two seconds is roughly one wind-up window, which means there is always room to
              act <em>between</em> ticks. The skill ceiling is preserved because any manual ability
              resets the tick: pressing buttons is always strictly faster than not pressing them.
              Automation sets the floor. It never touches the ceiling.
            </p>
          </div>
          <div className="rounded-3xl border border-white/10 bg-white/[0.04] p-6">
            <h3 className="text-sm font-black uppercase tracking-widest text-slate-300">
              The death contract
            </h3>
            <ul className="mt-3 space-y-2 text-sm text-slate-400">
              <li>
                <strong className="text-rose-300">−10% experience.</strong> Enough to erase an
                evening. Never enough to erase a character.
              </li>
              <li>
                <strong className="text-amber-300">−50% carried gold.</strong> Banked gold at the
                Sanctuary is safe. Deciding when to walk home <em>is</em> the risk system.
              </li>
              <li>
                <strong className="text-sky-300">A Remnant spawns.</strong> Your dropped gold lands
                on the floor, locked to you for 60 seconds. Get back inside that window and it is
                yours. Miss it and it belongs to whoever is standing there.
              </li>
              <li>
                <strong className="text-emerald-300">Equipped gear is safe</strong> outside
                Emberfield and the Grey Barrow, which are labelled at the border.
              </li>
            </ul>
          </div>
        </div>
      </Section>

      {/* ------------------------------------------------- systems addendum */}
      <Section id="systems" eyebrow="Section 02b" title="Systems addendum — build 0.9">
        <p className="-mt-4 mb-8 max-w-2xl text-sm text-slate-400">
          Five systems added after the first slice review. Each one exists because a specific
          playtest problem could not be solved with tuning alone.
        </p>
        <div className="space-y-4">
          {SYSTEMS.map((s) => (
            <article key={s.id} className={`rounded-3xl border ${s.accent} bg-white/[0.04] p-6`}>
              <div className="flex flex-wrap items-start gap-3">
                <span className="text-3xl">{s.icon}</span>
                <div className="min-w-[200px] flex-1">
                  <h3 className="text-xl font-black text-slate-50">{s.title}</h3>
                  <p className="mt-1 text-sm font-medium text-amber-300/90">{s.summary}</p>
                </div>
              </div>
              <div className="mt-4 grid gap-5 md:grid-cols-2">
                <p className="text-sm leading-relaxed text-slate-400">{s.detail}</p>
                <ul className="space-y-1.5">
                  {s.rules.map((r) => (
                    <li key={r} className="flex gap-2 text-xs text-slate-300">
                      <span className="text-amber-400">▸</span>
                      {r}
                    </li>
                  ))}
                </ul>
              </div>
            </article>
          ))}
        </div>

        <div className="mt-6 rounded-3xl border border-rose-500/30 bg-rose-500/5 p-6">
          <h3 className="text-sm font-black uppercase tracking-widest text-rose-300">
            Known open issues these rules create
          </h3>
          <p className="mt-1 text-xs text-slate-500">
            A design bible that only lists wins is a sales deck. These are live and unresolved.
          </p>
          <div className="mt-4 grid gap-4 md:grid-cols-3">
            {OPEN_ISSUES.map((o) => (
              <div key={o.title} className="rounded-2xl bg-black/40 p-4">
                <h4 className="text-xs font-black text-slate-100">{o.title}</h4>
                <p className="mt-2 text-[11px] leading-relaxed text-slate-400">{o.body}</p>
              </div>
            ))}
          </div>
        </div>
      </Section>

      {/* ------------------------------------------------------ mobile UX */}
      <Section eyebrow="Section 03" title="Mobile-first UX specification">
        <div className="grid gap-4 lg:grid-cols-[1.1fr_0.9fr]">
          {/* phone diagram */}
          <div className="rounded-3xl border border-white/10 bg-white/[0.04] p-6">
            <div className="mx-auto aspect-[9/17] w-full max-w-[280px] overflow-hidden rounded-[2rem] border-4 border-black/70 bg-[#12141c] p-2">
              <div className="relative h-full w-full rounded-[1.4rem] bg-gradient-to-b from-[#2b4a33] to-[#1a2a3a]">
                <div className="absolute inset-x-2 top-2 flex justify-between">
                  <div className="rounded-lg border border-sky-400/40 bg-sky-400/10 px-2 py-3 text-[8px] font-black uppercase text-sky-200">
                    Vitals
                  </div>
                  <div className="rounded-lg border border-sky-400/40 bg-sky-400/10 px-2 py-3 text-[8px] font-black uppercase text-sky-200">
                    Map
                  </div>
                </div>
                <div className="absolute inset-x-6 top-[38%] rounded-lg border border-dashed border-white/25 py-3 text-center text-[8px] font-bold uppercase tracking-widest text-white/50">
                  World · never occluded
                </div>
                <div className="absolute inset-x-0 bottom-0 h-[38%] border-t border-dashed border-amber-400/40 bg-amber-400/[0.06]">
                  <p className="pt-1 text-center text-[8px] font-black uppercase tracking-widest text-amber-300/80">
                    Thumb zone · 38%
                  </p>
                  <div className="mt-1 flex items-end justify-between px-3 pb-3">
                    <div className="h-16 w-16 rounded-full border-2 border-white/30 bg-white/10" />
                    <div className="grid grid-cols-2 gap-1.5">
                      {["⚔️", "🌀", "✨", "🛡️"].map((a) => (
                        <div
                          key={a}
                          className="grid h-7 w-7 place-items-center rounded-lg border border-white/30 bg-white/10 text-[11px]"
                        >
                          {a}
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <p className="mt-4 text-center text-xs text-slate-500">
              Reachability model: everything interactive lives inside a 62mm arc of the resting
              thumb. Informational UI lives above the world and fades out of the way.
            </p>
          </div>

          <div className="space-y-4">
            <div className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
              <h3 className="text-sm font-black uppercase tracking-widest text-slate-300">
                Hard numbers
              </h3>
              <dl className="mt-3 divide-y divide-white/5">
                {UX_SPECS.map((s) => (
                  <div key={s.k} className="flex items-baseline justify-between gap-4 py-2">
                    <dt className="text-xs text-slate-500">{s.k}</dt>
                    <dd className="text-right text-xs font-bold text-slate-200">{s.v}</dd>
                  </div>
                ))}
              </dl>
            </div>
            <div className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
              <h3 className="text-sm font-black uppercase tracking-widest text-slate-300">
                Haptic language
              </h3>
              <ul className="mt-3 space-y-2 text-xs text-slate-400">
                <li><strong className="text-slate-200">8ms tick</strong> — target acquired, ability on cooldown (rejection)</li>
                <li><strong className="text-slate-200">14ms tap</strong> — you land a hit</li>
                <li><strong className="text-slate-200">45ms thud</strong> — you take &gt;15 damage</li>
                <li><strong className="text-slate-200">12/30/18 triple</strong> — kill confirmed</li>
                <li><strong className="text-slate-200">26/20/12 decay</strong> — shove connects</li>
                <li><strong className="text-slate-200">90/60/140 double-thud</strong> — death</li>
              </ul>
              <p className="mt-3 text-[11px] text-slate-500">
                Haptics are never decorative. If it buzzes, world state changed.
              </p>
            </div>
          </div>
        </div>
      </Section>

      {/* --------------------------------------------------- telegraphing */}
      <Section eyebrow="Section 04" title="Telegraphing & the bestiary">
        <p className="-mt-4 mb-8 max-w-2xl text-sm text-slate-400">
          Every enemy is defined first by its tell, second by its numbers. If a designer cannot
          describe the tell in one sentence, the monster does not ship.
        </p>
        <div className="grid gap-3 sm:grid-cols-2">
          {Object.values(MONSTERS).map((m) => (
            <div key={m.key} className="rounded-2xl border border-white/10 bg-white/[0.04] p-5">
              <div className="flex items-center gap-3">
                <span
                  className="grid h-12 w-12 place-items-center rounded-2xl border-2 border-black/60 text-2xl"
                  style={{ background: m.color }}
                >
                  {m.glyph}
                </span>
                <div>
                  <h3 className="text-base font-black text-slate-100">{m.name}</h3>
                  <p className="text-[10px] font-bold uppercase tracking-widest text-slate-500">
                    {m.hp} hp · {m.damage} dmg · {m.xp} xp
                  </p>
                </div>
                <span className="ml-auto rounded-lg bg-black/50 px-2 py-1 text-[10px] font-black text-amber-300">
                  {m.windup}ms tell
                </span>
              </div>
              <p className="mt-3 text-xs leading-relaxed text-slate-300">
                <strong className="text-amber-400">Tell —</strong> {m.tell}
              </p>
              <p className="mt-2 text-xs leading-relaxed text-slate-500">{m.behaviour}</p>
            </div>
          ))}
        </div>

        <h3 className="mt-10 text-sm font-black uppercase tracking-widest text-slate-300">
          Player kit — four buttons, four decisions
        </h3>
        <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {ABILITIES.map((a) => (
            <div key={a.key} className="rounded-2xl border border-white/10 bg-white/[0.04] p-4">
              <div className="flex items-center gap-2">
                <span
                  className="grid h-10 w-10 place-items-center rounded-xl border-2 border-black/60 bg-slate-200 text-xl"
                  style={{ boxShadow: `inset 0 0 0 3px ${a.color}` }}
                >
                  {a.glyph}
                </span>
                <div>
                  <p className="text-sm font-black text-slate-100">{a.name}</p>
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500">
                    {a.manaCost} mana · {(a.cooldown / 1000).toFixed(1)}s cd
                  </p>
                </div>
              </div>
              <p className="mt-3 text-xs text-slate-400">{a.description}</p>
              <p className="mt-2 border-l-2 border-amber-500/50 pl-2 text-[11px] italic leading-relaxed text-slate-500">
                {a.designNote}
              </p>
            </div>
          ))}
        </div>
      </Section>

      {/* -------------------------------------------------------- regions */}
      <Section eyebrow="Section 05" title="World structure & risk gradient">
        <p className="-mt-4 mb-8 max-w-2xl text-sm text-slate-400">
          One contiguous 40×40 grid, no loading screens, no instances. Risk rises as you walk north.
          The single Sanctuary sits at the southern tip, which means every trip home is a decision.
        </p>
        <div className="space-y-3">
          {[...REGIONS].reverse().map((r, i) => (
            <div
              key={r.key}
              className="flex flex-col gap-3 rounded-2xl border border-white/10 bg-white/[0.04] p-5 sm:flex-row sm:items-center"
            >
              <div
                className="h-14 w-14 shrink-0 rounded-2xl border-2 border-black/60"
                style={{ background: r.tint }}
              />
              <div className="min-w-0 flex-1">
                <h3 className="text-base font-black text-slate-100">{r.name}</h3>
                <p className="text-[11px] font-bold uppercase tracking-widest text-amber-400/80">
                  {r.levelBand}
                </p>
                <p className="mt-1 text-xs text-slate-500">
                  Spawns: {r.spawns.map((s) => MONSTERS[s.key]?.name ?? s.key).join(", ")} · tiles{" "}
                  {r.w}×{r.h}
                </p>
              </div>
              <div className="flex shrink-0 items-center gap-1">
                {Array.from({ length: 4 }).map((_, k) => (
                  <span
                    key={k}
                    className={`h-2 w-8 rounded-full ${k <= i ? "bg-rose-500" : "bg-white/10"}`}
                  />
                ))}
                <span className="ml-2 text-[10px] font-black uppercase text-rose-400">risk</span>
              </div>
            </div>
          ))}
        </div>
      </Section>

      {/* -------------------------------------------------------- economy */}
      <Section eyebrow="Section 06" title="Economy design">
        <div className="grid gap-4 md:grid-cols-3">
          {[
            {
              t: "Faucets",
              c: "text-emerald-300",
              items: [
                "Monster gold drops (1–90 per kill, region-scaled)",
                "Material drops with hard rarity gates",
                "Unclaimed Remnants decaying back into the world",
              ],
            },
            {
              t: "Sinks",
              c: "text-rose-300",
              items: [
                "5% market transaction tax (burned)",
                "50% carried gold destroyed on death",
                "Consumables: salves and draughts are never refundable",
              ],
            },
            {
              t: "Levers we will pull",
              c: "text-sky-300",
              items: [
                "Region respawn density (supply)",
                "Rarity table weights (scarcity)",
                "Tax rate, 3%–8% band (velocity)",
                "Barrow seasonal reset (shock absorber)",
              ],
            },
          ].map((col) => (
            <div key={col.t} className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
              <h3 className={`text-sm font-black uppercase tracking-widest ${col.c}`}>{col.t}</h3>
              <ul className="mt-3 space-y-2 text-xs text-slate-400">
                {col.items.map((i) => (
                  <li key={i} className="flex gap-2">
                    <span className="text-slate-600">—</span>
                    {i}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
        <div className="mt-4 rounded-3xl border border-amber-500/30 bg-amber-500/5 p-6">
          <h3 className="text-sm font-black uppercase tracking-widest text-amber-300">
            The one rule
          </h3>
          <p className="mt-2 text-sm leading-relaxed text-slate-300">
            No item enters the world except through a player killing something and physically
            carrying it home. Monetisation touches cosmetics only — the moment gold or gear can be
            bought, the risk system that makes the walk home meaningful becomes optional, and the
            entire design collapses.
          </p>
          <Link
            href="/market"
            className="mt-4 inline-block rounded-xl border-b-4 border-amber-700 bg-amber-500 px-5 py-2.5 text-xs font-black uppercase tracking-widest text-black"
          >
            Open the live market →
          </Link>
        </div>
      </Section>

      {/* ------------------------------------------------------ risks/roadmap */}
      <Section eyebrow="Section 07" title="Risk register & roadmap">
        <div className="grid gap-4 lg:grid-cols-2">
          <div className="space-y-3">
            {RISKS.map((r) => (
              <div key={r.risk} className="rounded-2xl border border-white/10 bg-white/[0.04] p-5">
                <div className="flex items-start gap-3">
                  <span
                    className={`mt-0.5 shrink-0 rounded-md px-2 py-0.5 text-[9px] font-black uppercase tracking-wider ${
                      r.severity === "High"
                        ? "bg-rose-500/20 text-rose-300"
                        : r.severity === "Resolved"
                          ? "bg-emerald-500/20 text-emerald-300"
                          : "bg-amber-500/20 text-amber-300"
                    }`}
                  >
                    {r.severity}
                  </span>
                  <h3 className="text-sm font-black text-slate-100">{r.risk}</h3>
                </div>
                <p className="mt-2 text-xs leading-relaxed text-slate-400">{r.mitigation}</p>
              </div>
            ))}
          </div>
          <div className="space-y-3">
            {ROADMAP.map((p) => (
              <div key={p.phase} className="rounded-2xl border border-white/10 bg-white/[0.04] p-5">
                <div className="flex items-center gap-2">
                  <h3 className="text-sm font-black uppercase tracking-widest text-slate-100">
                    {p.phase}
                  </h3>
                  <span
                    className={`rounded-md px-2 py-0.5 text-[9px] font-black uppercase ${
                      p.state === "done"
                        ? "bg-emerald-500/20 text-emerald-300"
                        : p.state === "next"
                          ? "bg-sky-500/20 text-sky-300"
                          : "bg-white/10 text-slate-400"
                    }`}
                  >
                    {p.state}
                  </span>
                </div>
                <div className="mt-3 flex flex-wrap gap-1.5">
                  {p.items.map((i) => (
                    <span key={i} className="rounded-lg bg-black/40 px-2 py-1 text-[11px] text-slate-300">
                      {i}
                    </span>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      </Section>

      <div className="mx-auto max-w-6xl px-4">
        <div className="rounded-3xl border border-white/10 bg-gradient-to-br from-amber-500/15 to-rose-500/10 p-8 text-center">
          <h2 className="text-2xl font-black text-slate-50 sm:text-3xl">
            Documents lie. Prototypes don&apos;t.
          </h2>
          <p className="mx-auto mt-2 max-w-xl text-sm text-slate-400">
            The slice below runs the real telegraph timings, the real death penalty, and writes to
            the real persistent database. Play it on your phone.
          </p>
          <Link
            href="/play"
            className="mt-6 inline-block rounded-2xl border-b-4 border-amber-700 bg-amber-500 px-8 py-4 text-sm font-black uppercase tracking-widest text-black active:translate-y-0.5 active:border-b-2"
          >
            ▶ Enter the Hollow
          </Link>
        </div>
      </div>
    </main>
  );
}
