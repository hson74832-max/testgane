import type { Metadata } from "next";
import Link from "next/link";
import { db } from "@/db";
import { characters, deathLog, marketTrades, remnants, telemetry } from "@/db/schema";
import { desc, eq, sql } from "drizzle-orm";
import { ITEMS } from "@/lib/game/content";

export const metadata: Metadata = { title: "Remnants — World State" };
export const dynamic = "force-dynamic";

function ago(d: Date) {
  const s = Math.floor((Date.now() - new Date(d).getTime()) / 1000);
  if (s < 60) return `${s}s ago`;
  if (s < 3600) return `${Math.floor(s / 60)}m ago`;
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
  return `${Math.floor(s / 86400)}d ago`;
}

export default async function WorldPage() {
  const [deaths, board, open, trades, hotspots, events] = await Promise.all([
    db.select().from(deathLog).orderBy(desc(deathLog.createdAt)).limit(20),
    db.select().from(characters).orderBy(desc(characters.xp)).limit(10),
    db.select().from(remnants).where(eq(remnants.looted, false)).orderBy(desc(remnants.createdAt)).limit(12),
    db.select().from(marketTrades).orderBy(desc(marketTrades.createdAt)).limit(10),
    db
      .select({
        region: deathLog.region,
        n: sql<number>`count(*)::int`,
        avgLevel: sql<number>`coalesce(round(avg(${deathLog.level}))::int, 0)`,
      })
      .from(deathLog)
      .groupBy(deathLog.region)
      .orderBy(desc(sql`count(*)`)),
    db
      .select({ event: telemetry.event, n: sql<number>`count(*)::int` })
      .from(telemetry)
      .groupBy(telemetry.event)
      .orderBy(desc(sql`count(*)`))
      .limit(8),
  ]);

  const maxHot = Math.max(1, ...hotspots.map((h) => h.n));

  return (
    <main className="mx-auto max-w-6xl px-4 py-8 pb-24">
      <p className="text-[11px] font-black uppercase tracking-[0.4em] text-amber-400">Live telemetry</p>
      <h1 className="mt-1 text-3xl font-black text-slate-50 sm:text-4xl">World state</h1>
      <p className="mt-2 max-w-2xl text-sm text-slate-400">
        Persistence is not a feature you describe, it is a feature you can query. Everything below is
        read straight out of the production database — written by real sessions of the vertical slice.
      </p>

      <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {[
          ["Characters", board.length],
          ["Recorded deaths", deaths.length],
          ["Unclaimed remnants", open.length],
          ["Trades logged", trades.length],
        ].map(([k, v]) => (
          <div key={k as string} className="rounded-2xl border border-white/10 bg-white/[0.04] p-4">
            <p className="text-3xl font-black text-amber-300">{v as number}</p>
            <p className="text-[10px] font-bold uppercase tracking-widest text-slate-500">{k as string}</p>
          </div>
        ))}
      </div>

      <div className="mt-8 grid gap-6 lg:grid-cols-2">
        <section className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
          <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">
            💀 The obituary
          </h2>
          <p className="mt-1 text-[11px] text-slate-500">
            Public by design. A death that nobody sees costs nothing socially.
          </p>
          <div className="mt-3 space-y-1.5">
            {deaths.length === 0 && (
              <p className="text-xs text-slate-500">
                Nobody has died yet.{" "}
                <Link href="/play" className="text-amber-300 underline">
                  Fix that
                </Link>
                .
              </p>
            )}
            {deaths.map((d) => (
              <div key={d.id} className="rounded-xl bg-black/30 px-3 py-2 text-[11px]">
                <p className="text-slate-300">
                  <strong className="text-rose-300">{d.characterName}</strong>{" "}
                  <span className="text-slate-500">(lv {d.level})</span> was slain by{" "}
                  <strong className="text-slate-100">{d.killedBy}</strong> in {d.region}
                </p>
                <p className="mt-0.5 text-slate-500">
                  −{d.xpLost} xp · dropped {d.goldDropped}g at ({d.tileX}, {d.tileY}) · {ago(d.createdAt)}
                </p>
              </div>
            ))}
          </div>
        </section>

        <div className="space-y-6">
          <section className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
            <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">
              🏆 Highest experience
            </h2>
            <div className="mt-3 space-y-1.5">
              {board.length === 0 && <p className="text-xs text-slate-500">No characters yet.</p>}
              {board.map((c, i) => (
                <div key={c.id} className="flex items-center gap-3 rounded-xl bg-black/30 px-3 py-2">
                  <span className="w-5 text-center text-xs font-black text-amber-400/60">{i + 1}</span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-xs font-black text-slate-100">{c.name}</p>
                    <p className="text-[10px] text-slate-500">
                      {c.region} · {c.kills} kills · {c.deaths} deaths
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-xs font-black text-lime-300">lv {c.level}</p>
                    <p className="text-[10px] text-slate-500">{c.xp} xp</p>
                  </div>
                </div>
              ))}
            </div>
          </section>

          <section className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
            <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">
              🩸 Death heatmap by region
            </h2>
            <p className="mt-1 text-[11px] text-slate-500">
              The tuning dashboard: if a low-band region outranks a high-band one, the risk gradient is broken.
            </p>
            <div className="mt-3 space-y-2">
              {hotspots.length === 0 && <p className="text-xs text-slate-500">No data yet.</p>}
              {hotspots.map((h) => (
                <div key={h.region}>
                  <div className="flex justify-between text-[11px]">
                    <span className="font-bold text-slate-300">{h.region}</span>
                    <span className="text-slate-500">
                      {h.n} deaths · avg lv {h.avgLevel}
                    </span>
                  </div>
                  <div className="mt-1 h-2 overflow-hidden rounded-full bg-black/50">
                    <div
                      className="h-full rounded-full bg-gradient-to-r from-rose-600 to-amber-400"
                      style={{ width: `${(h.n / maxHot) * 100}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </section>
        </div>
      </div>

      <div className="mt-6 grid gap-6 lg:grid-cols-3">
        <section className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
          <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">
            ✦ Unclaimed remnants
          </h2>
          <div className="mt-3 space-y-1.5">
            {open.length === 0 && <p className="text-xs text-slate-500">The world is clean.</p>}
            {open.map((r) => (
              <div key={r.id} className="flex items-center gap-2 rounded-xl bg-black/30 px-3 py-2 text-[11px]">
                <span>✦</span>
                <span className="font-bold text-slate-300">{r.ownerName}</span>
                <span className="text-slate-500">
                  ({r.tileX}, {r.tileY})
                </span>
                <span className="ml-auto font-black text-amber-300">{r.gold}g</span>
              </div>
            ))}
          </div>
        </section>

        <section className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
          <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">
            ⚖️ Recent trades
          </h2>
          <div className="mt-3 space-y-1.5">
            {trades.length === 0 && <p className="text-xs text-slate-500">Market is quiet.</p>}
            {trades.map((t) => (
              <div key={t.id} className="flex items-center gap-2 text-[11px]">
                <span className="text-base">{ITEMS[t.itemKey]?.glyph ?? "❔"}</span>
                <span className="truncate font-bold text-slate-300">
                  {ITEMS[t.itemKey]?.name ?? t.itemKey} ×{t.qty}
                </span>
                <span className="ml-auto font-black text-amber-300">{t.pricePerUnit}g</span>
              </div>
            ))}
          </div>
        </section>

        <section className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
          <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">
            📊 Playtest telemetry
          </h2>
          <p className="mt-1 text-[11px] text-slate-500">Raw event counts from live sessions.</p>
          <div className="mt-3 space-y-1.5">
            {events.length === 0 && <p className="text-xs text-slate-500">No events recorded.</p>}
            {events.map((e) => (
              <div key={e.event} className="flex justify-between text-[11px]">
                <span className="font-bold text-slate-300">{e.event}</span>
                <span className="font-black text-sky-300">{e.n}</span>
              </div>
            ))}
          </div>
        </section>
      </div>
    </main>
  );
}
