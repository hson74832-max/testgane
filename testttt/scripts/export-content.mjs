/**
 * Export web single-source-of-truth -> shared JSON for Godot.
 * Run: node scripts/export-content.mjs
 * Reads TS directly via Node type-stripping (Node >=22.6, we have v25).
 */
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, "..");

const content = await import(pathToFileURL(join(root, "src/lib/game/content.ts")).href);
const world = await import(pathToFileURL(join(root, "src/lib/game/world.ts")).href);

const data = {
  version: 2,
  exportedAt: new Date().toISOString(),
  balance: {
    COMBAT: content.COMBAT,
    xpForLevelSamples: Object.fromEntries(
      [1, 2, 3, 5, 8, 10, 12].map((l) => [l, content.xpForLevel(l)])
    ),
  },
  items: content.ITEMS,
  itemList: content.ITEM_LIST.map((i) => i.key),
  monsters: content.MONSTERS,
  abilities: content.ABILITIES,
  equipSlots: content.EQUIP_SLOTS,
  defaultLootFilter: content.DEFAULT_LOOT_FILTER,
  allItemKeys: content.ALL_ITEM_KEYS,
  rivals: content.RIVALS,
  npcs: content.NPCS,
  npcStock: content.NPC_STOCK,
  ferry: content.FERRY,
  npcTalkRange: content.NPC_TALK_RANGE,
  npcHealCost: content.NPC_HEAL_COST,
  npcFerryCost: content.NPC_FERRY_COST,
  npcSellPct: content.NPC_SELL_PCT,
  vocationOrder: content.VOCATION_ORDER,
  vocations: content.VOCATIONS,
  skillOrder: content.SKILL_ORDER,
  skills: content.SKILLS,
  world: {
    MAP_W: world.MAP_W,
    MAP_H: world.MAP_H,
    TILE: world.TILE,
    TEMPLE: world.TEMPLE,
    REGIONS: world.REGIONS,
    TILE_DEFS: world.TILE_DEFS,
    CRYPT: world.CRYPT,
  },
};

const outWeb = join(root, "shared", "content.json");
mkdirSync(dirname(outWeb), { recursive: true });
writeFileSync(outWeb, JSON.stringify(data, null, 2));
console.log(`wrote ${outWeb} (${JSON.stringify(data).length} bytes)`);

// Also mirror into Godot project so Godot never imports TS directly.
const outGodot = join(dirname(root), "remnants-godot", "data", "content.json");
mkdirSync(dirname(outGodot), { recursive: true });
writeFileSync(outGodot, JSON.stringify(data, null, 2));
console.log(`wrote ${outGodot}`);
