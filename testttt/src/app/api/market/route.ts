import { NextResponse } from "next/server";
import { db } from "@/db";
import { characters, marketListings, marketTrades } from "@/db/schema";
import { ITEMS } from "@/lib/game/content";
import { ensureMarketSeed, getInventory, getOrCreateCharacter, removeItem } from "@/lib/server/store";
import { and, desc, eq, sql } from "drizzle-orm";

export const dynamic = "force-dynamic";

export async function GET() {
  await ensureMarketSeed();
  const listings = await db
    .select()
    .from(marketListings)
    .where(eq(marketListings.active, true))
    .orderBy(desc(marketListings.createdAt))
    .limit(120);

  const trades = await db
    .select()
    .from(marketTrades)
    .orderBy(desc(marketTrades.createdAt))
    .limit(25);

  const stats = await db
    .select({
      itemKey: marketListings.itemKey,
      floor: sql<number>`min(${marketListings.pricePerUnit})::int`,
      supply: sql<number>`sum(${marketListings.qty})::int`,
      listings: sql<number>`count(*)::int`,
    })
    .from(marketListings)
    .where(eq(marketListings.active, true))
    .groupBy(marketListings.itemKey);

  return NextResponse.json({
    listings: listings.map((l) => ({ ...l, item: ITEMS[l.itemKey] ?? null })),
    trades,
    stats: stats.map((s) => ({ ...s, item: ITEMS[s.itemKey] ?? null })),
  });
}

export async function POST(req: Request) {
  try {
    const body = (await req.json()) as {
      name: string;
      itemKey: string;
      qty: number;
      pricePerUnit: number;
    };
    if (!ITEMS[body.itemKey]) return NextResponse.json({ error: "Unknown item" }, { status: 400 });
    const qty = Math.max(1, Math.floor(body.qty));
    const price = Math.max(1, Math.floor(body.pricePerUnit));
    const character = await getOrCreateCharacter(body.name);
    const ok = await removeItem(character.id, body.itemKey, qty);
    if (!ok) return NextResponse.json({ error: "You do not own that many." }, { status: 400 });

    await db.insert(marketListings).values({
      sellerId: character.id,
      sellerName: character.name,
      itemKey: body.itemKey,
      qty,
      pricePerUnit: price,
    });

    const inventory = await getInventory(character.id);
    const [fresh] = await db.select().from(characters).where(eq(characters.id, character.id));
    return NextResponse.json({ ok: true, inventory, character: fresh });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}

export async function DELETE(req: Request) {
  const { searchParams } = new URL(req.url);
  const id = Number(searchParams.get("id"));
  const name = searchParams.get("name") ?? "";
  if (!id) return NextResponse.json({ error: "id required" }, { status: 400 });
  const [listing] = await db
    .select()
    .from(marketListings)
    .where(and(eq(marketListings.id, id), eq(marketListings.sellerName, name)))
    .limit(1);
  if (!listing) return NextResponse.json({ error: "Not your listing" }, { status: 403 });
  await db.update(marketListings).set({ active: false }).where(eq(marketListings.id, id));
  const character = await getOrCreateCharacter(name);
  const { addItem } = await import("@/lib/server/store");
  await addItem(character.id, listing.itemKey, listing.qty);
  return NextResponse.json({ ok: true, inventory: await getInventory(character.id) });
}
