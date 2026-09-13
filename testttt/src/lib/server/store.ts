import { db } from "@/db";
import { characters, equipment, inventoryItems, marketListings } from "@/db/schema";
import {
  DEFAULT_LOOT_FILTER,
  ITEMS,
  computeLoadout,
  type EquipSlot,
} from "@/lib/game/content";
import { and, eq, sql } from "drizzle-orm";

export async function getEquipment(characterId: number) {
  const rows = await db.select().from(equipment).where(eq(equipment.characterId, characterId));
  const map: Partial<Record<EquipSlot, string>> = {};
  for (const r of rows) map[r.slot as EquipSlot] = r.itemKey;
  return { equipped: map, loadout: computeLoadout(map) };
}

export async function getOrCreateCharacter(rawName: string) {
  const name = rawName.trim().slice(0, 18) || "Wanderer";
  const existing = await db.select().from(characters).where(eq(characters.name, name)).limit(1);
  if (existing.length) return existing[0];
  const inserted = await db
    .insert(characters)
    .values({ name, lootFilter: DEFAULT_LOOT_FILTER })
    .returning();
  await db.insert(inventoryItems).values([
    { characterId: inserted[0].id, itemKey: "salve", qty: 3 },
    { characterId: inserted[0].id, itemKey: "mana_draught", qty: 2 },
  ]);
  // Every Warden starts dressed. Naked characters make the armour maths unreadable.
  await db.insert(equipment).values([
    { characterId: inserted[0].id, slot: "weapon", itemKey: "bone_knife" },
    { characterId: inserted[0].id, slot: "armor", itemKey: "leather_vest" },
  ]);
  return inserted[0];
}

export async function getInventory(characterId: number) {
  const rows = await db
    .select()
    .from(inventoryItems)
    .where(eq(inventoryItems.characterId, characterId));
  return rows
    .filter((r) => r.qty > 0)
    .map((r) => ({
      id: r.id,
      itemKey: r.itemKey,
      qty: r.qty,
      name: ITEMS[r.itemKey]?.name ?? r.itemKey,
      glyph: ITEMS[r.itemKey]?.glyph ?? "❔",
      rarity: ITEMS[r.itemKey]?.rarity ?? "common",
      basePrice: ITEMS[r.itemKey]?.basePrice ?? 1,
    }));
}

export async function addItem(characterId: number, itemKey: string, qty: number) {
  if (!ITEMS[itemKey] || qty <= 0) return;
  const found = await db
    .select()
    .from(inventoryItems)
    .where(and(eq(inventoryItems.characterId, characterId), eq(inventoryItems.itemKey, itemKey)))
    .limit(1);
  if (found.length) {
    await db
      .update(inventoryItems)
      .set({ qty: found[0].qty + qty })
      .where(eq(inventoryItems.id, found[0].id));
  } else {
    await db.insert(inventoryItems).values({ characterId, itemKey, qty });
  }
}

export async function removeItem(characterId: number, itemKey: string, qty: number) {
  const found = await db
    .select()
    .from(inventoryItems)
    .where(and(eq(inventoryItems.characterId, characterId), eq(inventoryItems.itemKey, itemKey)))
    .limit(1);
  if (!found.length || found[0].qty < qty) return false;
  const left = found[0].qty - qty;
  if (left <= 0) await db.delete(inventoryItems).where(eq(inventoryItems.id, found[0].id));
  else await db.update(inventoryItems).set({ qty: left }).where(eq(inventoryItems.id, found[0].id));
  return true;
}

/** Seeds baseline broker listings so the market is never a dead screen. */
/**
 * Backfills a broker listing for any item that currently has zero active supply.
 * This is demo scaffolding, not a design position: it keeps the price board
 * readable before there is a real player population. It never competes with an
 * existing player listing, because it only fires when supply for that item is 0.
 */
export async function ensureMarketSeed() {
  const active = await db
    .select({ itemKey: marketListings.itemKey })
    .from(marketListings)
    .where(eq(marketListings.active, true));
  const have = new Set(active.map((r) => r.itemKey));

  const brokers = ["Vell the Broker", "Marrow Guild", "Sable Caravan", "Ashfall Co-op"];
  // Gold is currency, never merchandise.
  const missing = Object.values(ITEMS).filter((it) => it.key !== "gold" && !have.has(it.key));
  if (missing.length === 0) return;

  const rows = missing.flatMap((item, i) => {
    const n = item.rarity === "epic" ? 1 : item.rarity === "rare" ? 2 : 3;
    return Array.from({ length: n }, (_, j) => ({
      sellerName: brokers[(i + j) % brokers.length],
      itemKey: item.key,
      qty: item.kind === "material" ? 3 + ((i + j) % 8) : 1 + ((i + j) % 3),
      pricePerUnit: Math.max(
        1,
        Math.round(item.basePrice * (0.82 + ((i * 7 + j * 13) % 45) / 100)),
      ),
    }));
  });
  await db.insert(marketListings).values(rows);
}
