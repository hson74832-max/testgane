import { NextResponse } from "next/server";
import { ITEMS } from "@/lib/game/content";
import { getInventory, getOrCreateCharacter, removeItem } from "@/lib/server/store";

export const dynamic = "force-dynamic";

export async function POST(req: Request) {
  try {
    const body = (await req.json()) as { name: string; itemKey: string };
    const def = ITEMS[body.itemKey];
    // Consumable effects live on the item row (content.json items.*.effect) —
    // a new potion is a data edit, no code.
    const effect = def?.effect;
    if (!effect || !def) return NextResponse.json({ error: "That is not consumable." }, { status: 400 });
    const character = await getOrCreateCharacter(body.name);
    const ok = await removeItem(character.id, body.itemKey, 1);
    if (!ok) return NextResponse.json({ error: "You have none left." }, { status: 400 });
    const bits = [
      effect.hp ? `+${effect.hp} HP` : "",
      effect.mana ? `+${effect.mana} mana` : "",
    ].filter(Boolean);
    const label = `${def.name}: ${bits.join(", ") || "a strange tingle"} (rooted)`;
    return NextResponse.json({
      ok: true,
      effect: { ...effect, label },
      inventory: await getInventory(character.id),
    });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}
