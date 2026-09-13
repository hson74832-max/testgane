import { NextResponse } from "next/server";
import { db } from "@/db";
import { characters, marketListings, marketTrades } from "@/db/schema";
import { addItem, getInventory, getOrCreateCharacter } from "@/lib/server/store";
import { eq } from "drizzle-orm";

export const dynamic = "force-dynamic";

export async function POST(req: Request) {
  try {
    const body = (await req.json()) as { name: string; listingId: number; qty?: number };
    const buyer = await getOrCreateCharacter(body.name);
    const [listing] = await db
      .select()
      .from(marketListings)
      .where(eq(marketListings.id, body.listingId))
      .limit(1);

    if (!listing || !listing.active)
      return NextResponse.json({ error: "Listing is gone — someone beat you to it." }, { status: 400 });
    if (listing.sellerId === buyer.id)
      return NextResponse.json({ error: "You cannot buy your own listing." }, { status: 400 });

    const qty = Math.max(1, Math.min(listing.qty, Math.floor(body.qty ?? listing.qty)));
    const total = qty * listing.pricePerUnit;
    if (buyer.gold < total)
      return NextResponse.json({ error: `Not enough gold (need ${total}).` }, { status: 400 });

    await db
      .update(characters)
      .set({ gold: buyer.gold - total })
      .where(eq(characters.id, buyer.id));

    if (listing.sellerId) {
      const [seller] = await db
        .select()
        .from(characters)
        .where(eq(characters.id, listing.sellerId))
        .limit(1);
      if (seller) {
        // 5% listing tax is burned — the economy's only real gold sink.
        const net = Math.floor(total * 0.95);
        await db
          .update(characters)
          .set({ gold: seller.gold + net })
          .where(eq(characters.id, seller.id));
      }
    }

    const left = listing.qty - qty;
    if (left <= 0) await db.update(marketListings).set({ active: false, qty: 0 }).where(eq(marketListings.id, listing.id));
    else await db.update(marketListings).set({ qty: left }).where(eq(marketListings.id, listing.id));

    await addItem(buyer.id, listing.itemKey, qty);
    await db.insert(marketTrades).values({
      itemKey: listing.itemKey,
      qty,
      pricePerUnit: listing.pricePerUnit,
      buyerName: buyer.name,
      sellerName: listing.sellerName,
    });

    const [fresh] = await db.select().from(characters).where(eq(characters.id, buyer.id));
    return NextResponse.json({
      ok: true,
      spent: total,
      character: fresh,
      inventory: await getInventory(buyer.id),
    });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}
