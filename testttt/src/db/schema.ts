import {
  pgTable,
  serial,
  text,
  integer,
  timestamp,
  boolean,
  jsonb,
  index,
  uniqueIndex,
} from "drizzle-orm/pg-core";

/**
 * REMNANTS — persistent world tables.
 * Everything here is world-state that survives a client session, matching the
 * "persistent, high-stakes" pillar: characters, their goods, the shared market,
 * and the public record of every death in the realm.
 */

export const characters = pgTable(
  "characters",
  {
    id: serial("id").primaryKey(),
    name: text("name").notNull().unique(),
    vocation: text("vocation").notNull().default("Warden"),
    level: integer("level").notNull().default(1),
    xp: integer("xp").notNull().default(0),
    hp: integer("hp").notNull().default(120),
    maxHp: integer("max_hp").notNull().default(120),
    mana: integer("mana").notNull().default(60),
    maxMana: integer("max_mana").notNull().default(60),
    gold: integer("gold").notNull().default(50),
    tileX: integer("tile_x").notNull().default(12),
    tileY: integer("tile_y").notNull().default(18),
    region: text("region").notNull().default("Ashfall Hollow"),
    deaths: integer("deaths").notNull().default(0),
    kills: integer("kills").notNull().default(0),
    playtimeSeconds: integer("playtime_seconds").notNull().default(0),
    /** Client settings that must survive a device change. */
    autoPickup: boolean("auto_pickup").notNull().default(true),
    autoAttack: boolean("auto_attack").notNull().default(true),
    lootFilter: jsonb("loot_filter").$type<string[]>().notNull().default([]),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    lastSeen: timestamp("last_seen").notNull().defaultNow(),
  },
  (t) => [index("characters_level_idx").on(t.level)],
);

export const inventoryItems = pgTable(
  "inventory_items",
  {
    id: serial("id").primaryKey(),
    characterId: integer("character_id").notNull(),
    itemKey: text("item_key").notNull(),
    qty: integer("qty").notNull().default(1),
  },
  (t) => [index("inventory_character_idx").on(t.characterId)],
);

/** One row per filled gear slot. Slot is unique per character. */
export const equipment = pgTable(
  "equipment",
  {
    id: serial("id").primaryKey(),
    characterId: integer("character_id").notNull(),
    slot: text("slot").notNull(),
    itemKey: text("item_key").notNull(),
  },
  (t) => [
    index("equipment_character_idx").on(t.characterId),
    uniqueIndex("equipment_slot_uq").on(t.characterId, t.slot),
  ],
);

export const marketListings = pgTable(
  "market_listings",
  {
    id: serial("id").primaryKey(),
    sellerId: integer("seller_id"),
    sellerName: text("seller_name").notNull().default("Wandering Broker"),
    itemKey: text("item_key").notNull(),
    qty: integer("qty").notNull().default(1),
    pricePerUnit: integer("price_per_unit").notNull(),
    active: boolean("active").notNull().default(true),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (t) => [index("market_active_idx").on(t.active)],
);

export const marketTrades = pgTable("market_trades", {
  id: serial("id").primaryKey(),
  itemKey: text("item_key").notNull(),
  qty: integer("qty").notNull(),
  pricePerUnit: integer("price_per_unit").notNull(),
  buyerName: text("buyer_name").notNull(),
  sellerName: text("seller_name").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const deathLog = pgTable("death_log", {
  id: serial("id").primaryKey(),
  characterId: integer("character_id"),
  characterName: text("character_name").notNull(),
  level: integer("level").notNull(),
  killedBy: text("killed_by").notNull(),
  region: text("region").notNull(),
  xpLost: integer("xp_lost").notNull().default(0),
  goldDropped: integer("gold_dropped").notNull().default(0),
  tileX: integer("tile_x").notNull().default(0),
  tileY: integer("tile_y").notNull().default(0),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

/** Remnant caches: the loot pile a player leaves behind when they die. */
export const remnants = pgTable("remnants", {
  id: serial("id").primaryKey(),
  ownerName: text("owner_name").notNull(),
  tileX: integer("tile_x").notNull(),
  tileY: integer("tile_y").notNull(),
  gold: integer("gold").notNull().default(0),
  contents: jsonb("contents").$type<{ itemKey: string; qty: number }[]>().notNull().default([]),
  looted: boolean("looted").notNull().default(false),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

/** Design-review artifact: playtest telemetry pushed from the prototype. */
export const telemetry = pgTable("telemetry", {
  id: serial("id").primaryKey(),
  characterName: text("character_name").notNull(),
  event: text("event").notNull(),
  payload: jsonb("payload").$type<Record<string, unknown>>().notNull().default({}),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});
