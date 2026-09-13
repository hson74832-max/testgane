"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { ITEMS, RARITY_STYLES, type ItemDef } from "@/lib/game/content";

type Listing = {
  id: number;
  sellerName: string;
  itemKey: string;
  qty: number;
  pricePerUnit: number;
  item: ItemDef | null;
};
type Trade = {
  id: number;
  itemKey: string;
  qty: number;
  pricePerUnit: number;
  buyerName: string;
  sellerName: string;
};
type Stat = { itemKey: string; floor: number; supply: number; listings: number };
type Inv = { itemKey: string; qty: number; name: string; glyph: string; basePrice: number };
type Character = { id: number; name: string; gold: number; level: number };

export default function MarketClient() {
  const [name, setName] = useState("");
  const [character, setCharacter] = useState<Character | null>(null);
  const [inventory, setInventory] = useState<Inv[]>([]);
  const [listings, setListings] = useState<Listing[]>([]);
  const [trades, setTrades] = useState<Trade[]>([]);
  const [stats, setStats] = useState<Stat[]>([]);
  const [filter, setFilter] = useState<string>("all");
  const [msg, setMsg] = useState<{ text: string; ok: boolean } | null>(null);
  const [sellKey, setSellKey] = useState<string>("");
  const [sellQty, setSellQty] = useState(1);
  const [sellPrice, setSellPrice] = useState(10);
  const [busy, setBusy] = useState(false);

  const flash = (text: string, ok: boolean) => {
    setMsg({ text, ok });
    setTimeout(() => setMsg(null), 3200);
  };

  const loadMarket = useCallback(async () => {
    const res = await fetch("/api/market", { cache: "no-store" });
    const data = await res.json();
    setListings(data.listings ?? []);
    setTrades(data.trades ?? []);
    setStats(data.stats ?? []);
  }, []);

  const loadCharacter = useCallback(async (n: string) => {
    const res = await fetch("/api/character", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: n }),
    });
    const data = await res.json();
    setCharacter(data.character);
    setInventory(data.inventory ?? []);
  }, []);

  useEffect(() => {
    const stored = window.localStorage.getItem("remnants.name") ?? "Wanderer";
    setName(stored);
    loadMarket();
    loadCharacter(stored);
  }, [loadMarket, loadCharacter]);

  useEffect(() => {
    if (!sellKey && inventory.length) {
      setSellKey(inventory[0].itemKey);
      setSellPrice(inventory[0].basePrice);
    }
  }, [inventory, sellKey]);

  const buy = async (id: number) => {
    setBusy(true);
    try {
      const res = await fetch("/api/market/buy", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, listingId: id }),
      });
      const data = await res.json();
      if (!res.ok) flash(data.error ?? "Trade failed", false);
      else {
        setCharacter(data.character);
        setInventory(data.inventory);
        flash(`Bought for ${data.spent}g`, true);
      }
      await loadMarket();
    } finally {
      setBusy(false);
    }
  };

  const sell = async () => {
    if (!sellKey) return;
    setBusy(true);
    try {
      const res = await fetch("/api/market", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, itemKey: sellKey, qty: sellQty, pricePerUnit: sellPrice }),
      });
      const data = await res.json();
      if (!res.ok) flash(data.error ?? "Listing failed", false);
      else {
        setInventory(data.inventory);
        if (data.character) setCharacter(data.character);
        flash(`Listed ${sellQty}× at ${sellPrice}g`, true);
      }
      await loadMarket();
    } finally {
      setBusy(false);
    }
  };

  const cancel = async (id: number) => {
    setBusy(true);
    try {
      const res = await fetch(`/api/market?id=${id}&name=${encodeURIComponent(name)}`, {
        method: "DELETE",
      });
      const data = await res.json();
      if (!res.ok) flash(data.error ?? "Could not cancel", false);
      else {
        setInventory(data.inventory);
        flash("Listing withdrawn", true);
      }
      await loadMarket();
    } finally {
      setBusy(false);
    }
  };

  const filtered = filter === "all" ? listings : listings.filter((l) => l.item?.kind === filter);
  const kinds = ["all", "material", "consumable", "gear", "relic"];
  const statFor = (k: string) => stats.find((s) => s.itemKey === k);

  return (
    <main className="mx-auto max-w-6xl px-4 py-8 pb-24">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-[11px] font-black uppercase tracking-[0.4em] text-amber-400">
            The Sanctuary Exchange
          </p>
          <h1 className="mt-1 text-3xl font-black text-slate-50 sm:text-4xl">Player-driven market</h1>
          <p className="mt-2 max-w-xl text-sm text-slate-400">
            Every listing here came off a corpse. No NPC generates supply. A 5% tax on each sale is
            burned — the world&apos;s primary gold sink.
          </p>
        </div>
        <div className="rounded-2xl border border-white/10 bg-white/[0.04] px-4 py-3">
          <p className="text-[10px] font-bold uppercase tracking-widest text-slate-500">Trading as</p>
          <p className="text-lg font-black text-slate-100">{character?.name ?? name}</p>
          <p className="text-sm font-black text-amber-300">{character?.gold ?? 0} gold</p>
        </div>
      </div>

      {msg && (
        <div
          className={`mt-4 rounded-xl border px-4 py-2.5 text-sm font-bold ${
            msg.ok
              ? "border-emerald-500/40 bg-emerald-950/50 text-emerald-200"
              : "border-rose-500/40 bg-rose-950/50 text-rose-200"
          }`}
        >
          {msg.text}
        </div>
      )}

      {/* price board */}
      <section className="mt-8">
        <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">Price board</h2>
        <div className="mt-3 grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
          {Object.values(ITEMS)
            .filter((it) => it.key !== "gold")
            .map((it) => {
            const s = statFor(it.key);
            const r = RARITY_STYLES[it.rarity];
            const delta = s ? Math.round(((s.floor - it.basePrice) / it.basePrice) * 100) : 0;
            return (
              <div key={it.key} className={`rounded-2xl border border-white/10 p-3 ${r.bg}`}>
                <div className="flex items-center gap-2">
                  <span className="text-xl">{it.glyph}</span>
                  <div className="min-w-0">
                    <p className={`truncate text-xs font-black ${r.text}`}>{it.name}</p>
                    <p className="text-[10px] uppercase tracking-wider text-slate-500">{it.rarity}</p>
                  </div>
                  <div className="ml-auto text-right">
                    <p className="text-sm font-black text-amber-300">{s?.floor ?? "—"}g</p>
                    <p
                      className={`text-[10px] font-bold ${
                        delta > 0 ? "text-rose-300" : delta < 0 ? "text-emerald-300" : "text-slate-500"
                      }`}
                    >
                      {s ? `${delta > 0 ? "+" : ""}${delta}% vs base` : "no supply"}
                    </p>
                  </div>
                </div>
                <p className="mt-2 text-[10px] text-slate-500">
                  supply {s?.supply ?? 0} · {s?.listings ?? 0} listings
                </p>
              </div>
            );
            })}
        </div>
      </section>

      <div className="mt-8 grid gap-6 lg:grid-cols-[1.4fr_1fr]">
        {/* listings */}
        <section>
          <div className="flex flex-wrap items-center gap-2">
            <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">
              Open listings
            </h2>
            <div className="ml-auto flex gap-1">
              {kinds.map((k) => (
                <button
                  key={k}
                  onClick={() => setFilter(k)}
                  className={`rounded-lg px-2.5 py-1 text-[10px] font-black uppercase tracking-wider ${
                    filter === k ? "bg-amber-500 text-black" : "bg-white/5 text-slate-400"
                  }`}
                >
                  {k}
                </button>
              ))}
            </div>
          </div>
          <div className="mt-3 space-y-2">
            {filtered.length === 0 && (
              <p className="rounded-2xl border border-white/10 bg-white/[0.03] p-6 text-center text-sm text-slate-500">
                Nothing for sale. Go kill something.
              </p>
            )}
            {filtered.map((l) => {
              const r = RARITY_STYLES[l.item?.rarity ?? "common"];
              const mine = l.sellerName === (character?.name ?? name);
              return (
                <div
                  key={l.id}
                  className="flex items-center gap-3 rounded-2xl border border-white/10 bg-white/[0.04] p-3"
                >
                  <span className={`grid h-11 w-11 shrink-0 place-items-center rounded-xl text-xl ring-2 ${r.ring} ${r.bg}`}>
                    {l.item?.glyph ?? "❔"}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className={`truncate text-sm font-black ${r.text}`}>
                      {l.item?.name ?? l.itemKey} <span className="text-slate-500">×{l.qty}</span>
                    </p>
                    <p className="truncate text-[11px] text-slate-500">
                      {mine ? "your listing" : l.sellerName}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-black text-amber-300">{l.pricePerUnit}g</p>
                    <p className="text-[10px] text-slate-500">{l.pricePerUnit * l.qty}g total</p>
                  </div>
                  {mine ? (
                    <button
                      disabled={busy}
                      onClick={() => cancel(l.id)}
                      className="rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-[11px] font-black uppercase text-slate-300 disabled:opacity-40"
                    >
                      Pull
                    </button>
                  ) : (
                    <button
                      disabled={busy || (character?.gold ?? 0) < l.pricePerUnit * l.qty}
                      onClick={() => buy(l.id)}
                      className="rounded-xl border-b-4 border-amber-700 bg-amber-500 px-3 py-2 text-[11px] font-black uppercase text-black active:translate-y-0.5 active:border-b-2 disabled:border-slate-700 disabled:bg-slate-700 disabled:text-slate-400"
                    >
                      Buy
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        </section>

        {/* sell + tape */}
        <div className="space-y-6">
          <section className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
            <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">
              List an item
            </h2>
            {inventory.length === 0 ? (
              <p className="mt-3 text-xs text-slate-500">
                Your satchel is empty.{" "}
                <Link href="/play" className="text-amber-300 underline">
                  Go earn something
                </Link>
                .
              </p>
            ) : (
              <div className="mt-3 space-y-3">
                <select
                  value={sellKey}
                  onChange={(e) => {
                    setSellKey(e.target.value);
                    const it = inventory.find((i) => i.itemKey === e.target.value);
                    if (it) setSellPrice(it.basePrice);
                    setSellQty(1);
                  }}
                  className="w-full rounded-xl border border-white/15 bg-black/40 px-3 py-2.5 text-sm font-bold text-slate-100"
                >
                  {inventory.map((i) => (
                    <option key={i.itemKey} value={i.itemKey}>
                      {i.glyph} {i.name} (×{i.qty})
                    </option>
                  ))}
                </select>
                <div className="grid grid-cols-2 gap-2">
                  <label className="block">
                    <span className="text-[10px] font-bold uppercase tracking-widest text-slate-500">
                      Quantity
                    </span>
                    <input
                      type="number"
                      min={1}
                      max={inventory.find((i) => i.itemKey === sellKey)?.qty ?? 1}
                      value={sellQty}
                      onChange={(e) => setSellQty(Math.max(1, Number(e.target.value)))}
                      className="mt-1 w-full rounded-xl border border-white/15 bg-black/40 px-3 py-2 text-sm font-bold"
                    />
                  </label>
                  <label className="block">
                    <span className="text-[10px] font-bold uppercase tracking-widest text-slate-500">
                      Price / unit
                    </span>
                    <input
                      type="number"
                      min={1}
                      value={sellPrice}
                      onChange={(e) => setSellPrice(Math.max(1, Number(e.target.value)))}
                      className="mt-1 w-full rounded-xl border border-white/15 bg-black/40 px-3 py-2 text-sm font-bold"
                    />
                  </label>
                </div>
                <p className="text-[11px] text-slate-500">
                  Gross {sellQty * sellPrice}g · you receive{" "}
                  <span className="font-bold text-emerald-300">
                    {Math.floor(sellQty * sellPrice * 0.95)}g
                  </span>{" "}
                  after the 5% burn.
                </p>
                <button
                  disabled={busy}
                  onClick={sell}
                  className="w-full rounded-xl border-b-4 border-emerald-800 bg-emerald-500 py-2.5 text-xs font-black uppercase tracking-widest text-black active:translate-y-0.5 active:border-b-2 disabled:opacity-50"
                >
                  Post listing
                </button>
              </div>
            )}
          </section>

          <section className="rounded-3xl border border-white/10 bg-white/[0.04] p-5">
            <h2 className="text-sm font-black uppercase tracking-widest text-slate-300">
              The tape
            </h2>
            <div className="mt-3 space-y-1.5">
              {trades.length === 0 && <p className="text-xs text-slate-500">No trades yet today.</p>}
              {trades.map((t) => (
                <div key={t.id} className="flex items-center gap-2 text-[11px]">
                  <span className="text-base">{ITEMS[t.itemKey]?.glyph ?? "❔"}</span>
                  <span className="font-bold text-slate-300">
                    {ITEMS[t.itemKey]?.name ?? t.itemKey} ×{t.qty}
                  </span>
                  <span className="ml-auto font-black text-amber-300">{t.pricePerUnit}g</span>
                  <span className="w-24 truncate text-right text-slate-500">{t.buyerName}</span>
                </div>
              ))}
            </div>
          </section>
        </div>
      </div>
    </main>
  );
}
