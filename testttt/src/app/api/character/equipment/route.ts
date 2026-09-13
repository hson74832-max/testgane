import { NextResponse } from "next/server";
import { db } from "@/db";
import { equipment } from "@/db/schema";
import { ITEMS, type EquipSlot } from "@/lib/game/content";
import {
  addItem,
  getEquipment,
  getInventory,
  getOrCreateCharacter,
  removeItem,
} from "@/lib/server/store";
import { and, eq } from "drizzle-orm";

export const dynamic = "force-dynamic";

type Body = { name: string; action: "equip" | "unequip"; itemKey?: string; slot?: EquipSlot };

export async function POST(req: Request) {
  try {
    const body = (await req.json()) as Body;
    const character = await getOrCreateCharacter(body.name);

    if (body.action === "equip") {
      const def = body.itemKey ? ITEMS[body.itemKey] : undefined;
      if (!def?.slot)
        return NextResponse.json({ error: "That item has no gear slot." }, { status: 400 });

      const took = await removeItem(character.id, def.key, 1);
      if (!took) return NextResponse.json({ error: "You do not own that." }, { status: 400 });

      // Swap out whatever occupies the slot, back into the satchel.
      const [existing] = await db
        .select()
        .from(equipment)
        .where(and(eq(equipment.characterId, character.id), eq(equipment.slot, def.slot)))
        .limit(1);
      if (existing) {
        await addItem(character.id, existing.itemKey, 1);
        await db
          .update(equipment)
          .set({ itemKey: def.key })
          .where(eq(equipment.id, existing.id));
      } else {
        await db
          .insert(equipment)
          .values({ characterId: character.id, slot: def.slot, itemKey: def.key });
      }
    } else {
      if (!body.slot) return NextResponse.json({ error: "slot required" }, { status: 400 });
      const [existing] = await db
        .select()
        .from(equipment)
        .where(and(eq(equipment.characterId, character.id), eq(equipment.slot, body.slot)))
        .limit(1);
      if (!existing) return NextResponse.json({ error: "Slot is empty." }, { status: 400 });
      await addItem(character.id, existing.itemKey, 1);
      await db.delete(equipment).where(eq(equipment.id, existing.id));
    }

    const gear = await getEquipment(character.id);
    return NextResponse.json({
      ok: true,
      ...gear,
      inventory: await getInventory(character.id),
    });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}
