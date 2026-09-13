import { NextResponse } from "next/server";
import { db } from "@/db";
import { characters } from "@/db/schema";
import { getEquipment, getInventory, getOrCreateCharacter } from "@/lib/server/store";
import { DEFAULT_LOOT_FILTER } from "@/lib/game/content";
import { desc } from "drizzle-orm";

export const dynamic = "force-dynamic";

export async function POST(req: Request) {
  try {
    const body = (await req.json()) as { name?: string };
    const character = await getOrCreateCharacter(body.name ?? "Wanderer");
    const [inventory, gear] = await Promise.all([
      getInventory(character.id),
      getEquipment(character.id),
    ]);
    return NextResponse.json({
      character,
      inventory,
      ...gear,
      settings: {
        autoPickup: character.autoPickup,
        autoAttack: character.autoAttack,
        lootFilter: character.lootFilter?.length ? character.lootFilter : DEFAULT_LOOT_FILTER,
      },
    });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}

export async function GET() {
  const rows = await db.select().from(characters).orderBy(desc(characters.lastSeen)).limit(20);
  return NextResponse.json({ characters: rows });
}
