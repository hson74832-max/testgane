import { NextResponse } from "next/server";
import { db } from "@/db";
import { characters } from "@/db/schema";
import { ALL_ITEM_KEYS } from "@/lib/game/content";
import { getOrCreateCharacter } from "@/lib/server/store";
import { eq } from "drizzle-orm";

export const dynamic = "force-dynamic";

/** Loot filter + automation toggles follow the account, not the device. */
export async function POST(req: Request) {
  try {
    const body = (await req.json()) as {
      name: string;
      autoPickup?: boolean;
      autoAttack?: boolean;
      lootFilter?: string[];
    };
    const character = await getOrCreateCharacter(body.name);
    const filter = body.lootFilter?.filter((k) => ALL_ITEM_KEYS.includes(k));

    const [updated] = await db
      .update(characters)
      .set({
        ...(body.autoPickup === undefined ? {} : { autoPickup: body.autoPickup }),
        ...(body.autoAttack === undefined ? {} : { autoAttack: body.autoAttack }),
        ...(filter === undefined ? {} : { lootFilter: filter }),
      })
      .where(eq(characters.id, character.id))
      .returning();

    return NextResponse.json({
      ok: true,
      autoPickup: updated.autoPickup,
      autoAttack: updated.autoAttack,
      lootFilter: updated.lootFilter,
    });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}
