import { NextResponse } from "next/server";
import { db } from "@/db";
import { characters, deathLog, remnants, telemetry } from "@/db/schema";
import { addItem, getInventory, getOrCreateCharacter } from "@/lib/server/store";
import { eq } from "drizzle-orm";

export const dynamic = "force-dynamic";

type SyncBody = {
  name: string;
  state: {
    level: number;
    xp: number;
    hp: number;
    maxHp: number;
    mana: number;
    maxMana: number;
    gold: number;
    tileX: number;
    tileY: number;
    region: string;
    kills: number;
    deaths: number;
  };
  loot?: { itemKey: string; qty: number }[];
  death?: {
    killedBy: string;
    xpLost: number;
    goldDropped: number;
    tileX: number;
    tileY: number;
    region: string;
    level: number;
  };
  events?: { event: string; payload?: Record<string, unknown> }[];
};

export async function POST(req: Request) {
  try {
    const body = (await req.json()) as SyncBody;
    const character = await getOrCreateCharacter(body.name);

    await db
      .update(characters)
      .set({
        level: body.state.level,
        xp: body.state.xp,
        hp: body.state.hp,
        maxHp: body.state.maxHp,
        mana: body.state.mana,
        maxMana: body.state.maxMana,
        gold: body.state.gold,
        tileX: body.state.tileX,
        tileY: body.state.tileY,
        region: body.state.region,
        kills: body.state.kills,
        deaths: body.state.deaths,
        lastSeen: new Date(),
      })
      .where(eq(characters.id, character.id));

    for (const l of body.loot ?? []) await addItem(character.id, l.itemKey, l.qty);

    if (body.death) {
      await db.insert(deathLog).values({
        characterId: character.id,
        characterName: character.name,
        level: body.death.level,
        killedBy: body.death.killedBy,
        region: body.death.region,
        xpLost: body.death.xpLost,
        goldDropped: body.death.goldDropped,
        tileX: body.death.tileX,
        tileY: body.death.tileY,
      });
      await db.insert(remnants).values({
        ownerName: character.name,
        tileX: body.death.tileX,
        tileY: body.death.tileY,
        gold: body.death.goldDropped,
        contents: [],
      });
    }

    if (body.events?.length) {
      await db.insert(telemetry).values(
        body.events.slice(0, 20).map((e) => ({
          characterName: character.name,
          event: e.event,
          payload: e.payload ?? {},
        })),
      );
    }

    const inventory = await getInventory(character.id);
    return NextResponse.json({ ok: true, inventory, gold: body.state.gold });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}
