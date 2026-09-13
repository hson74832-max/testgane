module.exports = [
"[externals]/next/dist/compiled/next-server/app-route-turbo.runtime.dev.js [external] (next/dist/compiled/next-server/app-route-turbo.runtime.dev.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/compiled/next-server/app-route-turbo.runtime.dev.js", () => require("next/dist/compiled/next-server/app-route-turbo.runtime.dev.js"));

module.exports = mod;
}),
"[externals]/next/dist/compiled/@opentelemetry/api [external] (next/dist/compiled/@opentelemetry/api, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/compiled/@opentelemetry/api", () => require("next/dist/compiled/@opentelemetry/api"));

module.exports = mod;
}),
"[externals]/next/dist/compiled/next-server/app-page-turbo.runtime.dev.js [external] (next/dist/compiled/next-server/app-page-turbo.runtime.dev.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/compiled/next-server/app-page-turbo.runtime.dev.js", () => require("next/dist/compiled/next-server/app-page-turbo.runtime.dev.js"));

module.exports = mod;
}),
"[externals]/next/dist/server/app-render/work-unit-async-storage.external.js [external] (next/dist/server/app-render/work-unit-async-storage.external.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/server/app-render/work-unit-async-storage.external.js", () => require("next/dist/server/app-render/work-unit-async-storage.external.js"));

module.exports = mod;
}),
"[externals]/next/dist/server/app-render/work-async-storage.external.js [external] (next/dist/server/app-render/work-async-storage.external.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/server/app-render/work-async-storage.external.js", () => require("next/dist/server/app-render/work-async-storage.external.js"));

module.exports = mod;
}),
"[externals]/next/dist/shared/lib/no-fallback-error.external.js [external] (next/dist/shared/lib/no-fallback-error.external.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/shared/lib/no-fallback-error.external.js", () => require("next/dist/shared/lib/no-fallback-error.external.js"));

module.exports = mod;
}),
"[externals]/next/dist/server/app-render/after-task-async-storage.external.js [external] (next/dist/server/app-render/after-task-async-storage.external.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/server/app-render/after-task-async-storage.external.js", () => require("next/dist/server/app-render/after-task-async-storage.external.js"));

module.exports = mod;
}),
"[project]/src/db/index.ts [app-route] (ecmascript)", ((__turbopack_context__) => {
"use strict";

return __turbopack_context__.a(async (__turbopack_handle_async_dependencies__, __turbopack_async_result__) => { try {

__turbopack_context__.s([
    "db",
    ()=>db,
    "pool",
    ()=>pool
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$node$2d$postgres$2f$driver$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/drizzle-orm/node-postgres/driver.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$externals$5d2f$pg__$5b$external$5d$__$28$pg$2c$__esm_import$2c$__$5b$project$5d2f$node_modules$2f$pg$29$__ = __turbopack_context__.i("[externals]/pg [external] (pg, esm_import, [project]/node_modules/pg)");
var __turbopack_async_dependencies__ = __turbopack_handle_async_dependencies__([
    __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$node$2d$postgres$2f$driver$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__,
    __TURBOPACK__imported__module__$5b$externals$5d2f$pg__$5b$external$5d$__$28$pg$2c$__esm_import$2c$__$5b$project$5d2f$node_modules$2f$pg$29$__
]);
[__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$node$2d$postgres$2f$driver$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__, __TURBOPACK__imported__module__$5b$externals$5d2f$pg__$5b$external$5d$__$28$pg$2c$__esm_import$2c$__$5b$project$5d2f$node_modules$2f$pg$29$__] = __turbopack_async_dependencies__.then ? (await __turbopack_async_dependencies__)() : __turbopack_async_dependencies__;
;
;
const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
    throw new Error("DATABASE_URL is required");
}
const globalForDb = globalThis;
const pool = globalForDb.__arenaNextJsPostgresqlPool ?? new __TURBOPACK__imported__module__$5b$externals$5d2f$pg__$5b$external$5d$__$28$pg$2c$__esm_import$2c$__$5b$project$5d2f$node_modules$2f$pg$29$__["Pool"]({
    connectionString: databaseUrl
});
if ("TURBOPACK compile-time truthy", 1) {
    globalForDb.__arenaNextJsPostgresqlPool = pool;
}
const db = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$node$2d$postgres$2f$driver$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["drizzle"])(pool);
__turbopack_async_result__();
} catch(e) { __turbopack_async_result__(e); } }, false);}),
"[project]/src/db/schema.ts [app-route] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "characters",
    ()=>characters,
    "deathLog",
    ()=>deathLog,
    "equipment",
    ()=>equipment,
    "inventoryItems",
    ()=>inventoryItems,
    "marketListings",
    ()=>marketListings,
    "marketTrades",
    ()=>marketTrades,
    "remnants",
    ()=>remnants,
    "telemetry",
    ()=>telemetry
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$table$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/drizzle-orm/pg-core/table.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$serial$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/drizzle-orm/pg-core/columns/serial.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/drizzle-orm/pg-core/columns/text.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/drizzle-orm/pg-core/columns/integer.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$timestamp$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/drizzle-orm/pg-core/columns/timestamp.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$boolean$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/drizzle-orm/pg-core/columns/boolean.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$jsonb$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/drizzle-orm/pg-core/columns/jsonb.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$indexes$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/drizzle-orm/pg-core/indexes.js [app-route] (ecmascript)");
;
const characters = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$table$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["pgTable"])("characters", {
    id: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$serial$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["serial"])("id").primaryKey(),
    name: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("name").notNull().unique(),
    vocation: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("vocation").notNull().default("Warden"),
    level: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("level").notNull().default(1),
    xp: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("xp").notNull().default(0),
    hp: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("hp").notNull().default(120),
    maxHp: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("max_hp").notNull().default(120),
    mana: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("mana").notNull().default(60),
    maxMana: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("max_mana").notNull().default(60),
    gold: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("gold").notNull().default(50),
    tileX: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("tile_x").notNull().default(12),
    tileY: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("tile_y").notNull().default(18),
    region: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("region").notNull().default("Ashfall Hollow"),
    deaths: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("deaths").notNull().default(0),
    kills: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("kills").notNull().default(0),
    playtimeSeconds: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("playtime_seconds").notNull().default(0),
    /** Client settings that must survive a device change. */ autoPickup: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$boolean$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["boolean"])("auto_pickup").notNull().default(true),
    autoAttack: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$boolean$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["boolean"])("auto_attack").notNull().default(true),
    lootFilter: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$jsonb$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["jsonb"])("loot_filter").$type().notNull().default([]),
    createdAt: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$timestamp$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["timestamp"])("created_at").notNull().defaultNow(),
    lastSeen: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$timestamp$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["timestamp"])("last_seen").notNull().defaultNow()
}, (t)=>[
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$indexes$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["index"])("characters_level_idx").on(t.level)
    ]);
const inventoryItems = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$table$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["pgTable"])("inventory_items", {
    id: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$serial$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["serial"])("id").primaryKey(),
    characterId: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("character_id").notNull(),
    itemKey: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("item_key").notNull(),
    qty: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("qty").notNull().default(1)
}, (t)=>[
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$indexes$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["index"])("inventory_character_idx").on(t.characterId)
    ]);
const equipment = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$table$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["pgTable"])("equipment", {
    id: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$serial$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["serial"])("id").primaryKey(),
    characterId: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("character_id").notNull(),
    slot: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("slot").notNull(),
    itemKey: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("item_key").notNull()
}, (t)=>[
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$indexes$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["index"])("equipment_character_idx").on(t.characterId),
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$indexes$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["uniqueIndex"])("equipment_slot_uq").on(t.characterId, t.slot)
    ]);
const marketListings = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$table$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["pgTable"])("market_listings", {
    id: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$serial$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["serial"])("id").primaryKey(),
    sellerId: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("seller_id"),
    sellerName: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("seller_name").notNull().default("Wandering Broker"),
    itemKey: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("item_key").notNull(),
    qty: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("qty").notNull().default(1),
    pricePerUnit: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("price_per_unit").notNull(),
    active: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$boolean$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["boolean"])("active").notNull().default(true),
    createdAt: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$timestamp$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["timestamp"])("created_at").notNull().defaultNow()
}, (t)=>[
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$indexes$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["index"])("market_active_idx").on(t.active)
    ]);
const marketTrades = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$table$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["pgTable"])("market_trades", {
    id: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$serial$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["serial"])("id").primaryKey(),
    itemKey: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("item_key").notNull(),
    qty: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("qty").notNull(),
    pricePerUnit: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("price_per_unit").notNull(),
    buyerName: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("buyer_name").notNull(),
    sellerName: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("seller_name").notNull(),
    createdAt: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$timestamp$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["timestamp"])("created_at").notNull().defaultNow()
});
const deathLog = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$table$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["pgTable"])("death_log", {
    id: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$serial$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["serial"])("id").primaryKey(),
    characterId: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("character_id"),
    characterName: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("character_name").notNull(),
    level: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("level").notNull(),
    killedBy: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("killed_by").notNull(),
    region: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("region").notNull(),
    xpLost: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("xp_lost").notNull().default(0),
    goldDropped: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("gold_dropped").notNull().default(0),
    tileX: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("tile_x").notNull().default(0),
    tileY: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("tile_y").notNull().default(0),
    createdAt: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$timestamp$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["timestamp"])("created_at").notNull().defaultNow()
});
const remnants = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$table$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["pgTable"])("remnants", {
    id: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$serial$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["serial"])("id").primaryKey(),
    ownerName: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("owner_name").notNull(),
    tileX: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("tile_x").notNull(),
    tileY: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("tile_y").notNull(),
    gold: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$integer$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["integer"])("gold").notNull().default(0),
    contents: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$jsonb$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["jsonb"])("contents").$type().notNull().default([]),
    looted: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$boolean$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["boolean"])("looted").notNull().default(false),
    createdAt: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$timestamp$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["timestamp"])("created_at").notNull().defaultNow()
});
const telemetry = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$table$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["pgTable"])("telemetry", {
    id: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$serial$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["serial"])("id").primaryKey(),
    characterName: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("character_name").notNull(),
    event: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$text$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["text"])("event").notNull(),
    payload: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$jsonb$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["jsonb"])("payload").$type().notNull().default({}),
    createdAt: (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$pg$2d$core$2f$columns$2f$timestamp$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["timestamp"])("created_at").notNull().defaultNow()
});
}),
"[project]/src/lib/game/content.ts [app-route] (ecmascript)", ((__turbopack_context__) => {
"use strict";

/**
 * REMNANTS — content tables.
 * Single source of truth shared by the client prototype, the codex pages and
 * the server-side market/loot routes.
 */ __turbopack_context__.s([
    "ABILITIES",
    ()=>ABILITIES,
    "ALL_ITEM_KEYS",
    ()=>ALL_ITEM_KEYS,
    "COMBAT",
    ()=>COMBAT,
    "DEFAULT_LOOT_FILTER",
    ()=>DEFAULT_LOOT_FILTER,
    "EQUIP_SLOTS",
    ()=>EQUIP_SLOTS,
    "ITEMS",
    ()=>ITEMS,
    "ITEM_LIST",
    ()=>ITEM_LIST,
    "MONSTERS",
    ()=>MONSTERS,
    "RARITY_STYLES",
    ()=>RARITY_STYLES,
    "RIVALS",
    ()=>RIVALS,
    "computeLoadout",
    ()=>computeLoadout,
    "levelFromXp",
    ()=>levelFromXp,
    "mitigate",
    ()=>mitigate,
    "statsForLevel",
    ()=>statsForLevel,
    "stepMsFor",
    ()=>stepMsFor,
    "xpForLevel",
    ()=>xpForLevel
]);
const EQUIP_SLOTS = [
    {
        key: "helmet",
        label: "Head",
        glyph: "🪖"
    },
    {
        key: "amulet",
        label: "Neck",
        glyph: "📿"
    },
    {
        key: "armor",
        label: "Chest",
        glyph: "🎽"
    },
    {
        key: "weapon",
        label: "Weapon",
        glyph: "🗡️"
    },
    {
        key: "shield",
        label: "Off-hand",
        glyph: "🛡️"
    },
    {
        key: "legs",
        label: "Legs",
        glyph: "👖"
    },
    {
        key: "boots",
        label: "Feet",
        glyph: "🥾"
    },
    {
        key: "ring",
        label: "Ring",
        glyph: "💍"
    }
];
const ITEMS = {
    rat_pelt: {
        key: "rat_pelt",
        name: "Sewer Pelt",
        glyph: "🐀",
        rarity: "common",
        basePrice: 6,
        kind: "material",
        blurb: "Matted, cheap, endless. The copper standard of the Hollow economy."
    },
    chitin_plate: {
        key: "chitin_plate",
        name: "Chitin Plate",
        glyph: "🕷️",
        rarity: "uncommon",
        basePrice: 24,
        kind: "material",
        blurb: "Crafters buy these in stacks of twenty. Stacks of twenty are hard to carry home."
    },
    ember_core: {
        key: "ember_core",
        name: "Ember Core",
        glyph: "🔥",
        rarity: "rare",
        basePrice: 90,
        kind: "material",
        blurb: "Still warm. Fuels the only known method of re-forging a broken ward."
    },
    grave_silk: {
        key: "grave_silk",
        name: "Grave Silk",
        glyph: "🕸️",
        rarity: "rare",
        basePrice: 120,
        kind: "material",
        blurb: "Harvested from wraiths. The single most volatile commodity on the board."
    },
    salve: {
        key: "salve",
        name: "Field Salve",
        glyph: "🧪",
        rarity: "common",
        basePrice: 18,
        kind: "consumable",
        blurb: "Restores 55 HP over a 3s channel. You cannot move while drinking. That is the point."
    },
    mana_draught: {
        key: "mana_draught",
        name: "Blue Draught",
        glyph: "🫙",
        rarity: "common",
        basePrice: 22,
        kind: "consumable",
        blurb: "Restores 40 mana. Mana is the real currency of survival."
    },
    gold: {
        key: "gold",
        name: "Gold",
        glyph: "🪙",
        rarity: "common",
        basePrice: 1,
        kind: "material",
        blurb: "Carried gold is at risk. Banked gold is not. That is the whole risk system in one line."
    },
    // ---------------------------------------------------------------- weapons
    bone_knife: {
        key: "bone_knife",
        name: "Bone Knife",
        glyph: "🔪",
        rarity: "common",
        basePrice: 35,
        kind: "gear",
        slot: "weapon",
        damage: 3,
        heavy: 0,
        blurb: "Starter steel. Weightless, so your step cadence stays at a clean 205ms."
    },
    ember_axe: {
        key: "ember_axe",
        name: "Ember Axe",
        glyph: "🪓",
        rarity: "rare",
        basePrice: 320,
        kind: "gear",
        slot: "weapon",
        damage: 7,
        heavy: 3,
        blurb: "Heavy enough that you feel it in your feet. The classic damage-versus-footwork trade."
    },
    hollow_blade: {
        key: "hollow_blade",
        name: "Hollow Blade",
        glyph: "🗡️",
        rarity: "epic",
        basePrice: 850,
        kind: "gear",
        slot: "weapon",
        damage: 9,
        heavy: 1,
        blurb: "+9 damage, near weightless. Drops 1-in-400 from wraiths. A server event when it lands."
    },
    // ----------------------------------------------------------------- armour
    rusted_helm: {
        key: "rusted_helm",
        name: "Rusted Helm",
        glyph: "🪖",
        rarity: "common",
        basePrice: 40,
        kind: "gear",
        slot: "helmet",
        armor: 1,
        heavy: 1,
        blurb: "One flat point off every physical hit. Against a Hollow Rat that is 17% of its damage."
    },
    chitin_helm: {
        key: "chitin_helm",
        name: "Chitin Helm",
        glyph: "⛑️",
        rarity: "uncommon",
        basePrice: 140,
        kind: "gear",
        slot: "helmet",
        armor: 3,
        heavy: 2,
        blurb: "Crafted from six plates. The first meaningful spider-farming milestone."
    },
    leather_vest: {
        key: "leather_vest",
        name: "Leather Vest",
        glyph: "🎽",
        rarity: "common",
        basePrice: 70,
        kind: "gear",
        slot: "armor",
        armor: 3,
        heavy: 2,
        blurb: "The default chest piece. Cheap enough that losing it in the Barrow is survivable."
    },
    chitin_mail: {
        key: "chitin_mail",
        name: "Chitin Mail",
        glyph: "🦺",
        rarity: "rare",
        basePrice: 380,
        kind: "gear",
        slot: "armor",
        armor: 7,
        heavy: 4,
        blurb: "Turns an Ember Husk from a 17-damage threat into a 10-damage nuisance."
    },
    ember_plate: {
        key: "ember_plate",
        name: "Ember Plate",
        glyph: "🛡️",
        rarity: "epic",
        basePrice: 1100,
        kind: "gear",
        slot: "armor",
        armor: 12,
        heavy: 8,
        blurb: "Best-in-slot mitigation, worst-in-slot mobility. +40ms per step is a real telegraph tax."
    },
    wooden_buckler: {
        key: "wooden_buckler",
        name: "Wooden Buckler",
        glyph: "🪵",
        rarity: "common",
        basePrice: 45,
        kind: "gear",
        slot: "shield",
        armor: 2,
        heavy: 1,
        blurb: "Off-hand mitigation with almost no encumbrance cost."
    },
    barrow_shield: {
        key: "barrow_shield",
        name: "Barrow Shield",
        glyph: "🔰",
        rarity: "rare",
        basePrice: 420,
        kind: "gear",
        slot: "shield",
        armor: 5,
        heavy: 3,
        blurb: "Pulled off the dead of the Grey Barrow. Still cold."
    },
    ash_greaves: {
        key: "ash_greaves",
        name: "Ash Greaves",
        glyph: "👖",
        rarity: "uncommon",
        basePrice: 130,
        kind: "gear",
        slot: "legs",
        armor: 3,
        heavy: 2,
        blurb: "Emberfield standard issue. Leg armour is the cheapest armour-per-gold in the game."
    },
    travel_boots: {
        key: "travel_boots",
        name: "Travel Boots",
        glyph: "🥾",
        rarity: "common",
        basePrice: 55,
        kind: "gear",
        slot: "boots",
        armor: 1,
        heavy: 0,
        blurb: "Weightless. Every serious Barrow runner wears these and nothing heavier below the waist."
    },
    silk_amulet: {
        key: "silk_amulet",
        name: "Grave Silk Amulet",
        glyph: "📿",
        rarity: "rare",
        basePrice: 300,
        kind: "gear",
        slot: "amulet",
        armor: 2,
        heavy: 0,
        blurb: "Woven from wraith silk. Two flat points, zero weight — the arbitrage everyone wants."
    },
    ember_ring: {
        key: "ember_ring",
        name: "Ember Ring",
        glyph: "💍",
        rarity: "uncommon",
        basePrice: 180,
        kind: "gear",
        slot: "ring",
        armor: 1,
        heavy: 0,
        blurb: "A warm band. One point of mitigation and a small social signal that you farm Emberfield."
    },
    soul_token: {
        key: "soul_token",
        name: "Soul Token",
        glyph: "💠",
        rarity: "epic",
        basePrice: 400,
        kind: "relic",
        blurb: "Consumed on death to protect your XP. The whole economy prices itself against this."
    }
};
const ITEM_LIST = Object.values(ITEMS);
const MONSTERS = {
    rat: {
        key: "rat",
        name: "Hollow Rat",
        glyph: "🐀",
        hp: 26,
        damage: 6,
        xp: 12,
        gold: [
            1,
            6
        ],
        windup: 520,
        cadence: 1500,
        aggroRange: 4,
        attackRange: 1,
        moveMs: 420,
        color: "#a98467",
        tell: "Rears up on hind legs — one tile of orange floor.",
        loot: [
            {
                itemKey: "rat_pelt",
                chance: 0.7,
                qty: [
                    1,
                    2
                ]
            },
            {
                itemKey: "bone_knife",
                chance: 0.05,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "rusted_helm",
                chance: 0.04,
                qty: [
                    1,
                    1
                ]
            }
        ],
        behaviour: "Swarms. Individually trivial, lethal in fours because each one resets your step timer."
    },
    spider: {
        key: "spider",
        name: "Cave Spider",
        glyph: "🕷️",
        hp: 54,
        damage: 11,
        xp: 34,
        gold: [
            4,
            14
        ],
        windup: 700,
        cadence: 2000,
        aggroRange: 5,
        attackRange: 1,
        moveMs: 340,
        color: "#6b5b95",
        tell: "Fangs flare violet — applies POISON, a 3-tick DOT shown as green pips.",
        loot: [
            {
                itemKey: "chitin_plate",
                chance: 0.5,
                qty: [
                    1,
                    2
                ]
            },
            {
                itemKey: "salve",
                chance: 0.15,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "leather_vest",
                chance: 0.07,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "wooden_buckler",
                chance: 0.06,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "chitin_helm",
                chance: 0.04,
                qty: [
                    1,
                    1
                ]
            }
        ],
        behaviour: "Fast mover, slow attacker. Punishes players who stand still to heal."
    },
    ember: {
        key: "ember",
        name: "Ember Husk",
        glyph: "🔥",
        hp: 88,
        damage: 17,
        xp: 70,
        gold: [
            12,
            30
        ],
        windup: 950,
        cadence: 2600,
        aggroRange: 6,
        attackRange: 3,
        moveMs: 620,
        color: "#e07a3f",
        tell: "Telegraphs a 3-tile line of glowing floor. Sidestep, do not outrun.",
        loot: [
            {
                itemKey: "ember_core",
                chance: 0.35,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "mana_draught",
                chance: 0.2,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "ash_greaves",
                chance: 0.08,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "travel_boots",
                chance: 0.07,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "ember_ring",
                chance: 0.05,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "ember_axe",
                chance: 0.03,
                qty: [
                    1,
                    1
                ]
            }
        ],
        behaviour: "Ranged zoner. Teaches the core lesson: read the floor, not the monster."
    },
    wraith: {
        key: "wraith",
        name: "Grave Wraith",
        glyph: "👻",
        hp: 150,
        damage: 26,
        xp: 165,
        gold: [
            40,
            90
        ],
        windup: 1150,
        cadence: 3000,
        aggroRange: 7,
        attackRange: 2,
        moveMs: 520,
        color: "#4cc9f0",
        tell: "Screams and paints a 3x3 cyan bloom. Full 1.15s to leave the zone.",
        loot: [
            {
                itemKey: "grave_silk",
                chance: 0.4,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "barrow_shield",
                chance: 0.09,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "silk_amulet",
                chance: 0.07,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "chitin_mail",
                chance: 0.05,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "soul_token",
                chance: 0.04,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "ember_plate",
                chance: 0.012,
                qty: [
                    1,
                    1
                ]
            },
            {
                itemKey: "hollow_blade",
                chance: 0.0025,
                qty: [
                    1,
                    1
                ]
            }
        ],
        behaviour: "Territory boss of the Barrow. Solo-able at level 8 with perfect footwork, never before."
    }
};
const ABILITIES = [
    {
        key: "strike",
        name: "Strike",
        glyph: "⚔️",
        manaCost: 0,
        cooldown: 850,
        windup: 260,
        damage: 14,
        range: 1,
        shape: "adjacent",
        color: "#ffd166",
        description: "Manual melee swing on the targeted adjacent tile.",
        designNote: "There is no auto-attack in Remnants. Every point of damage you deal is a tap you chose to make. This single decision is what makes a 30-second rat fight tense instead of idle."
    },
    {
        key: "cleave",
        name: "Cleave",
        glyph: "🌀",
        manaCost: 14,
        cooldown: 4200,
        windup: 420,
        damage: 19,
        range: 1,
        shape: "adjacent",
        color: "#ef476f",
        description: "Hits every enemy in the 8 tiles around you after a 0.42s wind-up.",
        designNote: "Your own wind-up is telegraphed to other players too. Committing to Cleave is a readable, punishable choice — symmetry with monster tells."
    },
    {
        key: "bolt",
        name: "Ash Bolt",
        glyph: "✨",
        manaCost: 20,
        cooldown: 2600,
        windup: 340,
        damage: 26,
        range: 5,
        shape: "line",
        color: "#4cc9f0",
        description: "Straight-line projectile, 5 tiles, stops on the first target.",
        designNote: "The only reliable way to open on an Ember Husk before it zones you. Mana-gated so it can never become the default attack."
    },
    {
        key: "ward",
        name: "Ward",
        glyph: "🛡️",
        manaCost: 26,
        cooldown: 9000,
        windup: 0,
        damage: 0,
        range: 0,
        shape: "self",
        color: "#06d6a0",
        description: "Absorbs the next 45 damage for 6 seconds. Consumes a full thumb-press.",
        designNote: "Defensive cooldowns are held, not spammed. Long CD + visible bubble = other players can count your Ward down out loud."
    }
];
const RARITY_STYLES = {
    common: {
        text: "text-slate-300",
        ring: "ring-slate-600",
        bg: "bg-slate-800/60"
    },
    uncommon: {
        text: "text-emerald-300",
        ring: "ring-emerald-600/60",
        bg: "bg-emerald-950/40"
    },
    rare: {
        text: "text-sky-300",
        ring: "ring-sky-500/60",
        bg: "bg-sky-950/40"
    },
    epic: {
        text: "text-fuchsia-300",
        ring: "ring-fuchsia-500/60",
        bg: "bg-fuchsia-950/40"
    }
};
function xpForLevel(level) {
    // Deliberately steep after 8 — the mid-game is where death should hurt most.
    return Math.floor(60 * Math.pow(level, 1.85));
}
function levelFromXp(xp) {
    let lvl = 1;
    while(lvl < 60 && xp >= xpForLevel(lvl))lvl += 1;
    return lvl;
}
function statsForLevel(level) {
    return {
        maxHp: 100 + level * 20,
        maxMana: 45 + level * 15,
        damageBonus: Math.floor(level * 1.6)
    };
}
const COMBAT = {
    /** Auto-attack tick while a creature is Marked. */ AUTO_ATTACK_MS: 2000,
    /** Base grid step cadence before encumbrance. */ BASE_STEP_MS: 205,
    /** Each encumbrance point adds this many ms to a step. */ MS_PER_HEAVY: 5,
    /** Hard ceiling so full plate can never be unplayable. */ MAX_STEP_PENALTY_MS: 90,
    /** Flat mitigation floor — armour can never fully negate a hit. */ MIN_DAMAGE: 1,
    /** Shove cooldown. */ PUSH_CD_MS: 2500,
    /** How long the top-damage dealer holds an exclusive claim on a drop. */ LOOT_PROTECT_MS: 60_000,
    /** Ground items despawn after this. */ GROUND_DECAY_MS: 180_000
};
function computeLoadout(equipped) {
    let armor = 0;
    let heavy = 0;
    let weaponDamage = 0;
    for (const key of Object.values(equipped)){
        if (!key) continue;
        const it = ITEMS[key];
        if (!it) continue;
        armor += it.armor ?? 0;
        heavy += it.heavy ?? 0;
        if (it.slot === "weapon") weaponDamage += it.damage ?? 0;
    }
    return {
        armor,
        heavy,
        weaponDamage
    };
}
function stepMsFor(heavy) {
    return COMBAT.BASE_STEP_MS + Math.min(COMBAT.MAX_STEP_PENALTY_MS, heavy * COMBAT.MS_PER_HEAVY);
}
function mitigate(raw, armor) {
    return Math.max(COMBAT.MIN_DAMAGE, raw - armor);
}
const DEFAULT_LOOT_FILTER = Object.values(ITEMS).filter((i)=>i.rarity !== "common" || i.kind !== "material" || i.key === "gold").map((i)=>i.key);
const ALL_ITEM_KEYS = Object.keys(ITEMS);
const RIVALS = [
    "Vessa Crow",
    "Harlan Dredge",
    "Oskar Pyre",
    "The Marrow Guild"
];
}),
"[project]/src/lib/server/store.ts [app-route] (ecmascript)", ((__turbopack_context__) => {
"use strict";

return __turbopack_context__.a(async (__turbopack_handle_async_dependencies__, __turbopack_async_result__) => { try {

__turbopack_context__.s([
    "addItem",
    ()=>addItem,
    "ensureMarketSeed",
    ()=>ensureMarketSeed,
    "getEquipment",
    ()=>getEquipment,
    "getInventory",
    ()=>getInventory,
    "getOrCreateCharacter",
    ()=>getOrCreateCharacter,
    "removeItem",
    ()=>removeItem
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/db/index.ts [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/db/schema.ts [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/game/content.ts [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/drizzle-orm/sql/expressions/conditions.js [app-route] (ecmascript)");
var __turbopack_async_dependencies__ = __turbopack_handle_async_dependencies__([
    __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__
]);
[__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__] = __turbopack_async_dependencies__.then ? (await __turbopack_async_dependencies__)() : __turbopack_async_dependencies__;
;
;
;
;
async function getEquipment(characterId) {
    const rows = await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].select().from(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["equipment"]).where((0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["eq"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["equipment"].characterId, characterId));
    const map = {};
    for (const r of rows)map[r.slot] = r.itemKey;
    return {
        equipped: map,
        loadout: (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["computeLoadout"])(map)
    };
}
async function getOrCreateCharacter(rawName) {
    const name = rawName.trim().slice(0, 18) || "Wanderer";
    const existing = await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].select().from(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["characters"]).where((0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["eq"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["characters"].name, name)).limit(1);
    if (existing.length) return existing[0];
    const inserted = await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].insert(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["characters"]).values({
        name,
        lootFilter: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["DEFAULT_LOOT_FILTER"]
    }).returning();
    await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].insert(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"]).values([
        {
            characterId: inserted[0].id,
            itemKey: "salve",
            qty: 3
        },
        {
            characterId: inserted[0].id,
            itemKey: "mana_draught",
            qty: 2
        }
    ]);
    // Every Warden starts dressed. Naked characters make the armour maths unreadable.
    await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].insert(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["equipment"]).values([
        {
            characterId: inserted[0].id,
            slot: "weapon",
            itemKey: "bone_knife"
        },
        {
            characterId: inserted[0].id,
            slot: "armor",
            itemKey: "leather_vest"
        }
    ]);
    return inserted[0];
}
async function getInventory(characterId) {
    const rows = await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].select().from(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"]).where((0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["eq"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"].characterId, characterId));
    return rows.filter((r)=>r.qty > 0).map((r)=>({
            id: r.id,
            itemKey: r.itemKey,
            qty: r.qty,
            name: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["ITEMS"][r.itemKey]?.name ?? r.itemKey,
            glyph: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["ITEMS"][r.itemKey]?.glyph ?? "❔",
            rarity: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["ITEMS"][r.itemKey]?.rarity ?? "common",
            basePrice: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["ITEMS"][r.itemKey]?.basePrice ?? 1
        }));
}
async function addItem(characterId, itemKey, qty) {
    if (!__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["ITEMS"][itemKey] || qty <= 0) return;
    const found = await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].select().from(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"]).where((0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["and"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["eq"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"].characterId, characterId), (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["eq"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"].itemKey, itemKey))).limit(1);
    if (found.length) {
        await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].update(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"]).set({
            qty: found[0].qty + qty
        }).where((0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["eq"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"].id, found[0].id));
    } else {
        await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].insert(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"]).values({
            characterId,
            itemKey,
            qty
        });
    }
}
async function removeItem(characterId, itemKey, qty) {
    const found = await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].select().from(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"]).where((0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["and"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["eq"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"].characterId, characterId), (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["eq"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"].itemKey, itemKey))).limit(1);
    if (!found.length || found[0].qty < qty) return false;
    const left = found[0].qty - qty;
    if (left <= 0) await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].delete(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"]).where((0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["eq"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"].id, found[0].id));
    else await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].update(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"]).set({
        qty: left
    }).where((0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["eq"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["inventoryItems"].id, found[0].id));
    return true;
}
async function ensureMarketSeed() {
    const active = await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].select({
        itemKey: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["marketListings"].itemKey
    }).from(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["marketListings"]).where((0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["eq"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["marketListings"].active, true));
    const have = new Set(active.map((r)=>r.itemKey));
    const brokers = [
        "Vell the Broker",
        "Marrow Guild",
        "Sable Caravan",
        "Ashfall Co-op"
    ];
    // Gold is currency, never merchandise.
    const missing = Object.values(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["ITEMS"]).filter((it)=>it.key !== "gold" && !have.has(it.key));
    if (missing.length === 0) return;
    const rows = missing.flatMap((item, i)=>{
        const n = item.rarity === "epic" ? 1 : item.rarity === "rare" ? 2 : 3;
        return Array.from({
            length: n
        }, (_, j)=>({
                sellerName: brokers[(i + j) % brokers.length],
                itemKey: item.key,
                qty: item.kind === "material" ? 3 + (i + j) % 8 : 1 + (i + j) % 3,
                pricePerUnit: Math.max(1, Math.round(item.basePrice * (0.82 + (i * 7 + j * 13) % 45 / 100)))
            }));
    });
    await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].insert(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["marketListings"]).values(rows);
}
__turbopack_async_result__();
} catch(e) { __turbopack_async_result__(e); } }, false);}),
"[project]/src/app/api/character/sync/route.ts [app-route] (ecmascript)", ((__turbopack_context__) => {
"use strict";

return __turbopack_context__.a(async (__turbopack_handle_async_dependencies__, __turbopack_async_result__) => { try {

__turbopack_context__.s([
    "POST",
    ()=>POST,
    "dynamic",
    ()=>dynamic
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/server.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/db/index.ts [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/db/schema.ts [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$server$2f$store$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/server/store.ts [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/drizzle-orm/sql/expressions/conditions.js [app-route] (ecmascript)");
var __turbopack_async_dependencies__ = __turbopack_handle_async_dependencies__([
    __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__,
    __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$server$2f$store$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__
]);
[__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$server$2f$store$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__] = __turbopack_async_dependencies__.then ? (await __turbopack_async_dependencies__)() : __turbopack_async_dependencies__;
;
;
;
;
;
const dynamic = "force-dynamic";
async function POST(req) {
    try {
        const body = await req.json();
        const character = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$server$2f$store$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["getOrCreateCharacter"])(body.name);
        await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].update(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["characters"]).set({
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
            lastSeen: new Date()
        }).where((0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$drizzle$2d$orm$2f$sql$2f$expressions$2f$conditions$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["eq"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["characters"].id, character.id));
        for (const l of body.loot ?? [])await (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$server$2f$store$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["addItem"])(character.id, l.itemKey, l.qty);
        if (body.death) {
            await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].insert(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["deathLog"]).values({
                characterId: character.id,
                characterName: character.name,
                level: body.death.level,
                killedBy: body.death.killedBy,
                region: body.death.region,
                xpLost: body.death.xpLost,
                goldDropped: body.death.goldDropped,
                tileX: body.death.tileX,
                tileY: body.death.tileY
            });
            await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].insert(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["remnants"]).values({
                ownerName: character.name,
                tileX: body.death.tileX,
                tileY: body.death.tileY,
                gold: body.death.goldDropped,
                contents: []
            });
        }
        if (body.events?.length) {
            await __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$index$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["db"].insert(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$db$2f$schema$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["telemetry"]).values(body.events.slice(0, 20).map((e)=>({
                    characterName: character.name,
                    event: e.event,
                    payload: e.payload ?? {}
                })));
        }
        const inventory = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$server$2f$store$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["getInventory"])(character.id);
        return __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"].json({
            ok: true,
            inventory,
            gold: body.state.gold
        });
    } catch (err) {
        return __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"].json({
            error: err.message
        }, {
            status: 500
        });
    }
}
__turbopack_async_result__();
} catch(e) { __turbopack_async_result__(e); } }, false);}),
];

//# sourceMappingURL=%5Broot-of-the-server%5D__0xrxga6._.js.map