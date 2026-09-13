(globalThis["TURBOPACK"] || (globalThis["TURBOPACK"] = [])).push([typeof document === "object" ? document.currentScript : undefined,
"[project]/src/lib/game/content.ts [app-client] (ecmascript)", ((__turbopack_context__) => {
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
_c = ITEM_LIST;
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
const DEFAULT_LOOT_FILTER = Object.values(ITEMS).filter((i)=>i.rarity !== "common" || i.kind !== "material" || i.key === "gold").map(_c1 = (i)=>i.key);
_c2 = DEFAULT_LOOT_FILTER;
const ALL_ITEM_KEYS = Object.keys(ITEMS);
_c3 = ALL_ITEM_KEYS;
const RIVALS = [
    "Vessa Crow",
    "Harlan Dredge",
    "Oskar Pyre",
    "The Marrow Guild"
];
var _c, _c1, _c2, _c3;
__turbopack_context__.k.register(_c, "ITEM_LIST");
__turbopack_context__.k.register(_c1, 'DEFAULT_LOOT_FILTER$Object.values(ITEMS)\n  .filter((i) => i.rarity !== "common" || i.kind !== "material" || i.key === "gold")\n  .map');
__turbopack_context__.k.register(_c2, "DEFAULT_LOOT_FILTER");
__turbopack_context__.k.register(_c3, "ALL_ITEM_KEYS");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/src/lib/game/world.ts [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

/** Deterministic tile world for the Remnants vertical slice. */ __turbopack_context__.s([
    "MAP_H",
    ()=>MAP_H,
    "MAP_W",
    ()=>MAP_W,
    "REGIONS",
    ()=>REGIONS,
    "TEMPLE",
    ()=>TEMPLE,
    "TILE",
    ()=>TILE,
    "TILE_DEFS",
    ()=>TILE_DEFS,
    "generateMap",
    ()=>generateMap,
    "inSafeZone",
    ()=>inSafeZone,
    "isWalkable",
    ()=>isWalkable,
    "makeRng",
    ()=>makeRng,
    "regionAt",
    ()=>regionAt
]);
const MAP_W = 40;
const MAP_H = 40;
const TILE = 44;
const TILE_DEFS = {
    grass: {
        kind: "grass",
        walkable: true,
        top: "#3f7d4f",
        side: "#2c5a39",
        detail: "#4d9460"
    },
    brush: {
        kind: "brush",
        walkable: true,
        top: "#356b45",
        side: "#264d33",
        detail: "#2a5738"
    },
    path: {
        kind: "path",
        walkable: true,
        top: "#a08a63",
        side: "#7a684a",
        detail: "#b39a71"
    },
    ash: {
        kind: "ash",
        walkable: true,
        top: "#5b5560",
        side: "#413d47",
        detail: "#6b6472"
    },
    stone: {
        kind: "stone",
        walkable: true,
        top: "#6f7480",
        side: "#525763",
        detail: "#7d8390"
    },
    water: {
        kind: "water",
        walkable: false,
        top: "#2f7fb5",
        side: "#1f5c86",
        detail: "#4aa0d4"
    },
    wall: {
        kind: "wall",
        walkable: false,
        top: "#8d8577",
        side: "#5d574d"
    },
    temple: {
        kind: "temple",
        walkable: true,
        top: "#c9b27a",
        side: "#9a8557",
        detail: "#e0cd9c"
    }
};
const REGIONS = [
    {
        key: "hollow",
        name: "Ashfall Hollow",
        x: 0,
        y: 22,
        w: 40,
        h: 18,
        tint: "#3f7d4f",
        spawns: [
            {
                key: "rat",
                weight: 5
            }
        ],
        levelBand: "Lv 1–3 · Safe-adjacent"
    },
    {
        key: "webs",
        name: "The Weeping Webs",
        x: 0,
        y: 11,
        w: 22,
        h: 11,
        tint: "#4a4360",
        spawns: [
            {
                key: "spider",
                weight: 5
            },
            {
                key: "rat",
                weight: 2
            }
        ],
        levelBand: "Lv 3–6 · Contested"
    },
    {
        key: "emberfield",
        name: "Emberfield",
        x: 22,
        y: 11,
        w: 18,
        h: 11,
        tint: "#7a4a30",
        spawns: [
            {
                key: "ember",
                weight: 5
            },
            {
                key: "spider",
                weight: 1
            }
        ],
        levelBand: "Lv 6–9 · Full loot on death"
    },
    {
        key: "barrow",
        name: "The Grey Barrow",
        x: 0,
        y: 0,
        w: 40,
        h: 11,
        tint: "#2b3a4a",
        spawns: [
            {
                key: "wraith",
                weight: 4
            },
            {
                key: "ember",
                weight: 2
            }
        ],
        levelBand: "Lv 9+ · Deep world, no respawn shrine"
    }
];
const TEMPLE = {
    x: 20,
    y: 35
};
function makeRng(seed) {
    let a = seed >>> 0;
    return function rng() {
        a |= 0;
        a = a + 0x6d2b79f5 | 0;
        let t = Math.imul(a ^ a >>> 15, 1 | a);
        t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
        return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
}
function regionAt(x, y) {
    for (const r of REGIONS){
        if (x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h) return r;
    }
    return REGIONS[0];
}
function generateMap(seed = 1337) {
    const rng = makeRng(seed);
    const tiles = [];
    for(let y = 0; y < MAP_H; y++){
        const row = [];
        for(let x = 0; x < MAP_W; x++){
            const region = regionAt(x, y);
            let kind;
            const n = rng();
            if (region.key === "hollow") kind = n < 0.16 ? "brush" : "grass";
            else if (region.key === "webs") kind = n < 0.22 ? "stone" : n < 0.34 ? "brush" : "grass";
            else if (region.key === "emberfield") kind = n < 0.4 ? "ash" : "stone";
            else kind = n < 0.55 ? "ash" : "stone";
            // Border walls
            if (x === 0 || y === 0 || x === MAP_W - 1 || y === MAP_H - 1) kind = "wall";
            row.push(kind);
        }
        tiles.push(row);
    }
    // Rocky outcrops / walls
    const clusters = 46;
    for(let i = 0; i < clusters; i++){
        const cx = 2 + Math.floor(rng() * (MAP_W - 4));
        const cy = 2 + Math.floor(rng() * (MAP_H - 4));
        const size = 1 + Math.floor(rng() * 3);
        for(let y = cy - size; y <= cy + size; y++){
            for(let x = cx - size; x <= cx + size; x++){
                if (x < 1 || y < 1 || x >= MAP_W - 1 || y >= MAP_H - 1) continue;
                if (rng() < 0.55) tiles[y][x] = "wall";
            }
        }
    }
    // Two ponds in the Hollow
    for (const [px, py, pr] of [
        [
            7,
            30,
            3
        ],
        [
            32,
            27,
            2
        ]
    ]){
        for(let y = py - pr; y <= py + pr; y++){
            for(let x = px - pr; x <= px + pr; x++){
                if (x < 1 || y < 1 || x >= MAP_W - 1 || y >= MAP_H - 1) continue;
                if ((x - px) ** 2 + (y - py) ** 2 <= pr * pr) tiles[y][x] = "water";
            }
        }
    }
    // The Long Road — the one guaranteed traversal spine, north/south.
    for(let y = 1; y < MAP_H - 1; y++){
        const wob = Math.round(Math.sin(y * 0.35) * 2);
        for(let dx = -1; dx <= 1; dx++){
            const x = TEMPLE.x + wob + dx;
            if (x > 0 && x < MAP_W - 1) tiles[y][x] = "path";
        }
    }
    // East/west crossroad
    for(let x = 1; x < MAP_W - 1; x++){
        tiles[16][x] = "path";
    }
    // Temple plaza (safe zone)
    for(let y = TEMPLE.y - 2; y <= TEMPLE.y + 2; y++){
        for(let x = TEMPLE.x - 2; x <= TEMPLE.x + 2; x++){
            if (x < 1 || y < 1 || x >= MAP_W - 1 || y >= MAP_H - 1) continue;
            tiles[y][x] = "temple";
        }
    }
    return {
        tiles,
        seed
    };
}
function isWalkable(map, x, y) {
    if (x < 0 || y < 0 || x >= MAP_W || y >= MAP_H) return false;
    return TILE_DEFS[map.tiles[y][x]].walkable;
}
function inSafeZone(x, y) {
    return Math.abs(x - TEMPLE.x) <= 3 && Math.abs(y - TEMPLE.y) <= 3;
}
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/src/lib/game/engine.ts [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "GameEngine",
    ()=>GameEngine
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/game/content.ts [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/game/world.ts [app-client] (ecmascript)");
;
;
let uid = 1;
const nid = ()=>uid++;
const REGEN_MS = 1400;
class GameEngine {
    map;
    player;
    monsters = [];
    telegraphs = [];
    floats = [];
    ground = [];
    projectiles = [];
    targetId = null;
    /** Auto-attack tick clock for the Marked creature. */ markedAt = 0;
    nextAutoAt = 0;
    autoAttack = true;
    autoPickup = true;
    lootFilter = new Set();
    now = 0;
    heldDir = null;
    events = [];
    lastRegion = "";
    /** Live shove preview driven by the drag gesture. */ pushPreview = null;
    nextRegen = 0;
    nextSpawnCheck = 0;
    camX = 0;
    camY = 0;
    constructor(name, seed = 1337, saved, loadout = {
        armor: 0,
        heavy: 0,
        weaponDamage: 0
    }, opts){
        this.map = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["generateMap"])(seed);
        const level = saved?.level ?? 1;
        const s = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["statsForLevel"])(level);
        this.player = {
            name,
            x: saved?.x ?? __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TEMPLE"].x,
            y: saved?.y ?? __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TEMPLE"].y,
            rx: saved?.x ?? __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TEMPLE"].x,
            ry: saved?.y ?? __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TEMPLE"].y,
            facing: {
                x: 0,
                y: 1
            },
            hp: saved?.hp ?? s.maxHp,
            maxHp: s.maxHp,
            mana: saved?.mana ?? s.maxMana,
            maxMana: s.maxMana,
            level,
            xp: saved?.xp ?? 0,
            gold: saved?.gold ?? 50,
            kills: saved?.kills ?? 0,
            deaths: saved?.deaths ?? 0,
            statuses: [],
            cooldowns: {},
            castUntil: 0,
            castKey: null,
            nextStepAt: 0,
            hitFlash: 0,
            dead: false,
            deadUntil: 0,
            wardHp: 0,
            armor: loadout.armor,
            heavy: loadout.heavy,
            weaponDamage: loadout.weaponDamage,
            pushReadyAt: 0
        };
        this.autoPickup = opts?.autoPickup ?? true;
        this.autoAttack = opts?.autoAttack ?? true;
        this.lootFilter = new Set(opts?.lootFilter ?? Object.keys(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ITEMS"]));
        this.camX = this.player.x;
        this.camY = this.player.y;
        this.populate();
    }
    // ---------------------------------------------------------- configuration
    setLoadout(l) {
        this.player.armor = l.armor;
        this.player.heavy = l.heavy;
        this.player.weaponDamage = l.weaponDamage;
    }
    setLootFilter(keys) {
        this.lootFilter = new Set(keys);
    }
    setAutoPickup(v) {
        this.autoPickup = v;
    }
    setAutoAttackEnabled(v) {
        this.autoAttack = v;
        if (v) this.nextAutoAt = this.now + __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["COMBAT"].AUTO_ATTACK_MS;
    }
    get stepMs() {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["stepMsFor"])(this.player.heavy);
    }
    // ---------------------------------------------------------------- spawning
    populate() {
        for(let i = 0; i < 34; i++)this.spawnMonster(true);
    }
    spawnMonster(initial = false) {
        for(let attempt = 0; attempt < 40; attempt++){
            const x = 1 + Math.floor(Math.random() * (__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MAP_W"] - 2));
            const y = 1 + Math.floor(Math.random() * (__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MAP_H"] - 2));
            if (!(0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["isWalkable"])(this.map, x, y)) continue;
            if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["inSafeZone"])(x, y)) continue;
            const dist = Math.max(Math.abs(x - this.player.x), Math.abs(y - this.player.y));
            if (!initial && dist < 9) continue;
            if (this.monsters.some((m)=>m.x === x && m.y === y)) continue;
            const region = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["regionAt"])(x, y);
            const total = region.spawns.reduce((a, s)=>a + s.weight, 0);
            let roll = Math.random() * total;
            let key = region.spawns[0].key;
            for (const s of region.spawns){
                roll -= s.weight;
                if (roll <= 0) {
                    key = s.key;
                    break;
                }
            }
            const def = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MONSTERS"][key];
            // ~14% of spawns are already tagged by a rival adventurer. This is how the
            // slice demonstrates contested loot claims without a second live client.
            const damageBy = {};
            let hp = def.hp;
            if (Math.random() < 0.14) {
                const rival = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["RIVALS"][Math.floor(Math.random() * __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["RIVALS"].length)];
                const chunk = Math.floor(def.hp * (0.3 + Math.random() * 0.3));
                damageBy[rival] = chunk;
                hp = def.hp - chunk;
            }
            this.monsters.push({
                id: nid(),
                def,
                x,
                y,
                rx: x,
                ry: y,
                hp,
                maxHp: def.hp,
                aggro: false,
                nextMoveAt: 0,
                nextAttackAt: 0,
                windupUntil: 0,
                hitFlash: 0,
                statuses: [],
                dying: 0,
                damageBy,
                pushLockUntil: 0,
                shoveFrom: null
            });
            return;
        }
    }
    // ------------------------------------------------------------------ input
    setHeld(dir) {
        this.heldDir = dir;
    }
    /** Marking a creature starts the 2s auto-attack clock. */ setTarget(id) {
        if (this.targetId !== id) {
            this.targetId = id;
            this.markedAt = this.now;
            this.nextAutoAt = this.now + __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["COMBAT"].AUTO_ATTACK_MS;
        }
    }
    tapTile(tx, ty) {
        const m = this.monsterAt(tx, ty);
        if (m) {
            this.setTarget(m.id);
            return;
        }
        this.lootTile(tx, ty);
    }
    ability(index) {
        const def = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ABILITIES"][index];
        if (def) this.castAbility(def);
    }
    monsterAt(x, y) {
        return this.monsters.find((m)=>m.x === x && m.y === y && m.dying === 0) ?? null;
    }
    // ------------------------------------------------------------------- push
    /** Live validity check used to paint the drag preview. */ canPush(m, tx, ty) {
        const p = this.player;
        if (p.dead) return {
            ok: false,
            reason: "dead"
        };
        if (this.now < p.pushReadyAt) return {
            ok: false,
            reason: "Shove recharging"
        };
        if (this.now < m.pushLockUntil) return {
            ok: false,
            reason: "Braced"
        };
        const reach = Math.max(Math.abs(m.x - p.x), Math.abs(m.y - p.y));
        if (reach > 1) return {
            ok: false,
            reason: "Step closer to shove"
        };
        const d = Math.max(Math.abs(tx - m.x), Math.abs(ty - m.y));
        if (d !== 1) return {
            ok: false,
            reason: "Shove is exactly 1 tile"
        };
        if (!(0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["isWalkable"])(this.map, tx, ty)) return {
            ok: false,
            reason: "Blocked"
        };
        if (this.monsterAt(tx, ty)) return {
            ok: false,
            reason: "Occupied"
        };
        if (tx === p.x && ty === p.y) return {
            ok: false,
            reason: "That is your tile"
        };
        if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["inSafeZone"])(tx, ty)) return {
            ok: false,
            reason: "Cannot shove into Sanctuary"
        };
        return {
            ok: true
        };
    }
    previewPush(m, tx, ty) {
        if (!m) {
            this.pushPreview = null;
            return;
        }
        const v = this.canPush(m, tx, ty);
        this.pushPreview = {
            from: {
                x: m.x,
                y: m.y
            },
            to: {
                x: tx,
                y: ty
            },
            valid: v.ok
        };
    }
    clearPushPreview() {
        this.pushPreview = null;
    }
    /** Shove a creature one tile. Cancels its wind-up — the core tactical payoff. */ push(m, tx, ty) {
        const v = this.canPush(m, tx, ty);
        this.pushPreview = null;
        if (!v.ok) {
            if (v.reason) this.push_text(v.reason, m.x, m.y, "#94a3b8");
            this.events.push({
                type: "push",
                ok: false,
                reason: v.reason
            });
            return v;
        }
        m.shoveFrom = {
            x: m.x,
            y: m.y
        };
        m.x = tx;
        m.y = ty;
        m.aggro = true;
        m.pushLockUntil = this.now + 1200;
        m.nextMoveAt = Math.max(m.nextMoveAt, this.now + 350);
        // Interrupting the telegraph is the whole reason shove exists.
        if (this.now < m.windupUntil) {
            m.windupUntil = 0;
            this.telegraphs = this.telegraphs.filter((t)=>!(t.source === "monster" && t.sourceId === m.id && !t.resolved));
            this.push_text("INTERRUPTED", tx, ty - 0.4, "#4cc9f0", true);
        } else {
            this.push_text("shoved", tx, ty - 0.3, "#cbd5e1");
        }
        this.player.pushReadyAt = this.now + __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["COMBAT"].PUSH_CD_MS;
        this.events.push({
            type: "push",
            ok: true
        });
        return {
            ok: true
        };
    }
    // ----------------------------------------------------------------- helpers
    occupied(x, y) {
        return this.monsters.some((m)=>m.x === x && m.y === y && m.dying === 0);
    }
    push_text(text, x, y, color, crit = false) {
        this.floats.push({
            id: nid(),
            x,
            y,
            text,
            color,
            born: this.now,
            crit
        });
        if (this.floats.length > 40) this.floats.shift();
    }
    target() {
        if (this.targetId == null) return null;
        return this.monsters.find((m)=>m.id === this.targetId && m.dying === 0) ?? null;
    }
    cooldownPct(key) {
        const def = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ABILITIES"].find((a)=>a.key === key);
        if (!def) return 0;
        const ready = this.player.cooldowns[key] ?? 0;
        if (this.now >= ready) return 0;
        return (ready - this.now) / def.cooldown;
    }
    pushCooldownPct() {
        const left = this.player.pushReadyAt - this.now;
        return left <= 0 ? 0 : left / __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["COMBAT"].PUSH_CD_MS;
    }
    /** 0→1 progress toward the next auto-attack tick. */ autoTickPct() {
        if (!this.autoAttack || !this.target()) return 0;
        const left = this.nextAutoAt - this.now;
        if (left <= 0) return 1;
        return 1 - left / __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["COMBAT"].AUTO_ATTACK_MS;
    }
    get inProtectedZone() {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["inSafeZone"])(this.player.x, this.player.y);
    }
    // --------------------------------------------------------------- abilities
    castAbility(def) {
        const p = this.player;
        if (p.dead) return;
        if (this.now < (p.cooldowns[def.key] ?? 0)) return;
        if (p.mana < def.manaCost) {
            this.events.push({
                type: "nomana"
            });
            this.push_text("no mana", p.x, p.y, "#7dd3fc");
            return;
        }
        if (def.shape === "self") {
            p.mana -= def.manaCost;
            p.cooldowns[def.key] = this.now + def.cooldown;
            p.wardHp = 45 + p.level * 5;
            p.statuses = p.statuses.filter((s)=>s.key !== "ward");
            p.statuses.push({
                key: "ward",
                until: this.now + 6000,
                power: p.wardHp
            });
            this.push_text("WARD", p.x, p.y, "#06d6a0");
            return;
        }
        const tgt = this.target();
        if (!tgt) {
            this.push_text("nothing marked", p.x, p.y, "#94a3b8");
            return;
        }
        const d = Math.max(Math.abs(tgt.x - p.x), Math.abs(tgt.y - p.y));
        if (d > def.range) {
            this.push_text("too far", p.x, p.y, "#94a3b8");
            return;
        }
        p.facing = {
            x: Math.sign(tgt.x - p.x),
            y: Math.sign(tgt.y - p.y)
        };
        p.mana -= def.manaCost;
        p.cooldowns[def.key] = this.now + def.cooldown;
        p.castUntil = this.now + def.windup;
        p.castKey = def.key;
        // A manual swing resets the auto clock: manual play is strictly faster.
        this.nextAutoAt = this.now + __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["COMBAT"].AUTO_ATTACK_MS;
        const resolveAt = this.now + def.windup;
        const bonus = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["statsForLevel"])(p.level).damageBonus + p.weaponDamage;
        if (def.key === "cleave") {
            const tiles = [];
            for(let dy = -1; dy <= 1; dy++)for(let dx = -1; dx <= 1; dx++){
                if (dx === 0 && dy === 0) continue;
                tiles.push({
                    x: p.x + dx,
                    y: p.y + dy
                });
            }
            this.telegraphs.push({
                id: nid(),
                tiles,
                startAt: this.now,
                resolveAt,
                color: def.color,
                damage: def.damage + bonus,
                source: "player",
                sourceId: 0,
                resolved: false
            });
        } else if (def.key === "bolt") {
            this.projectiles.push({
                id: nid(),
                fx: p.x,
                fy: p.y,
                tx: tgt.x,
                ty: tgt.y,
                born: this.now,
                duration: def.windup + 120,
                color: def.color
            });
            this.telegraphs.push({
                id: nid(),
                tiles: [
                    {
                        x: tgt.x,
                        y: tgt.y
                    }
                ],
                startAt: this.now,
                resolveAt: resolveAt + 120,
                color: def.color,
                damage: def.damage + bonus,
                source: "player",
                sourceId: tgt.id,
                resolved: false
            });
        } else {
            this.telegraphs.push({
                id: nid(),
                tiles: [
                    {
                        x: tgt.x,
                        y: tgt.y
                    }
                ],
                startAt: this.now,
                resolveAt,
                color: def.color,
                damage: def.damage + bonus,
                source: "player",
                sourceId: tgt.id,
                resolved: false
            });
        }
    }
    /** The 2-second tick. Melee reach only, no input required. */ autoSwing(m) {
        const p = this.player;
        const base = 6 + Math.floor(p.level * 0.9) + p.weaponDamage;
        this.damageMonster(m, base);
        this.push_text("tick", p.x, p.y - 0.55, "#94a3b8");
    }
    damageMonster(m, amount) {
        const crit = Math.random() < 0.14;
        const dmg = Math.max(1, Math.round(crit ? amount * 1.85 : amount));
        m.hp -= dmg;
        m.hitFlash = this.now + 160;
        m.aggro = true;
        m.damageBy[this.player.name] = (m.damageBy[this.player.name] ?? 0) + dmg;
        this.push_text(crit ? `${dmg}!` : `${dmg}`, m.x, m.y, crit ? "#ffd166" : "#fff", crit);
        if (m.hp <= 0) this.killMonster(m);
    }
    /** Who out-damaged everyone else on this corpse. */ claimant(m) {
        let best = this.player.name;
        let bestVal = -1;
        for (const [k, v] of Object.entries(m.damageBy)){
            if (v > bestVal) {
                best = k;
                bestVal = v;
            }
        }
        return best;
    }
    killMonster(m) {
        m.dying = this.now;
        const p = this.player;
        p.kills += 1;
        const xp = m.def.xp + Math.floor(Math.random() * 4);
        p.xp += xp;
        this.push_text(`+${xp} xp`, m.x, m.y - 0.4, "#a3e635");
        this.events.push({
            type: "kill",
            monster: m.def.name,
            xp
        });
        const owner = this.claimant(m);
        const protectedUntil = this.now + __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["COMBAT"].LOOT_PROTECT_MS;
        const drops = [];
        for (const l of m.def.loot){
            if (Math.random() < l.chance) {
                const qty = l.qty[0] + Math.floor(Math.random() * (l.qty[1] - l.qty[0] + 1));
                drops.push({
                    itemKey: l.itemKey,
                    qty
                });
            }
        }
        const gold = m.def.gold[0] + Math.floor(Math.random() * (m.def.gold[1] - m.def.gold[0] + 1));
        if (gold > 0) drops.push({
            itemKey: "gold",
            qty: gold
        });
        // Spread the drop across the 3x3 around the corpse so stacks stay readable.
        const spread = [];
        for(let dy = -1; dy <= 1; dy++)for(let dx = -1; dx <= 1; dx++){
            const x = m.x + dx;
            const y = m.y + dy;
            if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["isWalkable"])(this.map, x, y)) spread.push({
                x,
                y
            });
        }
        if (spread.length === 0) spread.push({
            x: m.x,
            y: m.y
        });
        // Corpse tile first, then outward — the common case stays a single tap.
        spread.sort((a, b)=>{
            const da = Math.abs(a.x - m.x) + Math.abs(a.y - m.y);
            const db = Math.abs(b.x - m.x) + Math.abs(b.y - m.y);
            return da - db;
        });
        drops.forEach((d, i)=>{
            const tile = spread[i % spread.length];
            this.ground.push({
                id: nid(),
                x: tile.x,
                y: tile.y,
                itemKey: d.itemKey,
                qty: d.qty,
                owner,
                protectedUntil,
                born: this.now,
                jx: (Math.random() - 0.5) * 0.42,
                jy: (Math.random() - 0.5) * 0.32
            });
        });
        if (owner !== p.name) {
            this.push_text(`claimed by ${owner}`, m.x, m.y - 0.75, "#f87171");
        }
        const newLevel = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["levelFromXp"])(p.xp);
        if (newLevel > p.level) {
            p.level = newLevel;
            const s = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["statsForLevel"])(newLevel);
            p.maxHp = s.maxHp;
            p.maxMana = s.maxMana;
            p.hp = s.maxHp;
            p.mana = s.maxMana;
            this.push_text("LEVEL UP", p.x, p.y - 0.6, "#ffd166", true);
            this.events.push({
                type: "levelup",
                level: newLevel
            });
        }
        if (this.targetId === m.id) this.targetId = null;
    }
    // ------------------------------------------------------------------- loot
    /** Filtered out = invisible on the floor and skipped by auto-pickup. */ isVisibleLoot(g) {
        return this.lootFilter.has(g.itemKey);
    }
    canLoot(g) {
        return g.owner === this.player.name || this.now >= g.protectedUntil;
    }
    visibleGround() {
        return this.ground.filter((g)=>this.isVisibleLoot(g));
    }
    takeGround(g, silent = false) {
        const p = this.player;
        if (!this.canLoot(g)) {
            if (!silent) {
                const left = Math.ceil((g.protectedUntil - this.now) / 1000);
                this.push_text(`${g.owner} · ${left}s`, g.x, g.y - 0.4, "#f87171");
                this.events.push({
                    type: "denied",
                    reason: `Loot protected for ${g.owner} (${left}s)`
                });
            }
            return false;
        }
        this.ground = this.ground.filter((x)=>x.id !== g.id);
        if (g.itemKey === "gold") {
            p.gold += g.qty;
            this.push_text(`+${g.qty}g`, g.x, g.y, "#fbbf24");
            this.events.push({
                type: "loot",
                items: [],
                gold: g.qty
            });
        } else {
            this.push_text(`+${__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ITEMS"][g.itemKey]?.glyph ?? ""}${g.qty > 1 ? ` x${g.qty}` : ""}`, g.x, g.y, "#a3e635");
            this.events.push({
                type: "loot",
                items: [
                    {
                        itemKey: g.itemKey,
                        qty: g.qty
                    }
                ],
                gold: 0
            });
        }
        return true;
    }
    /** Manual loot of one tile (tap). Must be within 1 tile. */ lootTile(x, y) {
        const d = Math.max(Math.abs(x - this.player.x), Math.abs(y - this.player.y));
        if (d > 1) return;
        const here = this.ground.filter((g)=>g.x === x && g.y === y && this.isVisibleLoot(g));
        for (const g of here)this.takeGround(g);
    }
    /** Sweep everything claimable and filtered within 1 tile. */ lootAllNearby() {
        const p = this.player;
        const near = this.ground.filter((g)=>this.isVisibleLoot(g) && Math.max(Math.abs(g.x - p.x), Math.abs(g.y - p.y)) <= 1);
        if (near.length === 0) {
            this.push_text("nothing here", p.x, p.y - 0.4, "#94a3b8");
            return;
        }
        let got = 0;
        for (const g of near)if (this.takeGround(g, true)) got += 1;
        if (got === 0) {
            const blocked = near[0];
            const left = Math.ceil((blocked.protectedUntil - this.now) / 1000);
            this.push_text(`${blocked.owner} · ${left}s`, p.x, p.y - 0.4, "#f87171");
            this.events.push({
                type: "denied",
                reason: `Loot protected for ${blocked.owner} (${left}s)`
            });
        }
    }
    autoPickupAt(x, y) {
        if (!this.autoPickup) return;
        const here = this.ground.filter((g)=>g.x === x && g.y === y && this.isVisibleLoot(g));
        for (const g of here)this.takeGround(g, true);
    }
    // ------------------------------------------------------------------ damage
    damagePlayer(amount, source, status) {
        const p = this.player;
        if (p.dead) return;
        // Protected zone: creatures cannot land anything here.
        if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["inSafeZone"])(p.x, p.y)) {
            this.push_text("PROTECTED", p.x, p.y - 0.4, "#ffd166");
            return;
        }
        const raw = amount;
        let dmg = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["mitigate"])(raw, p.armor);
        const blocked = raw - dmg;
        if (p.wardHp > 0) {
            const absorbed = Math.min(p.wardHp, dmg);
            p.wardHp -= absorbed;
            dmg -= absorbed;
            this.push_text(`-${absorbed}`, p.x, p.y - 0.3, "#06d6a0");
            if (p.wardHp <= 0) p.statuses = p.statuses.filter((s)=>s.key !== "ward");
        }
        if (dmg > 0) {
            p.hp -= dmg;
            p.hitFlash = this.now + 220;
            this.push_text(blocked > 0 ? `${dmg} (-${blocked})` : `${dmg}`, p.x, p.y, "#ff5a6e");
            this.events.push({
                type: "damaged",
                amount: dmg,
                blocked
            });
        }
        if (status) {
            p.statuses = p.statuses.filter((s)=>s.key !== status);
            p.statuses.push({
                key: status,
                until: this.now + 6000,
                nextTick: this.now + 1500,
                power: status === "poison" ? 4 : 6
            });
        }
        if (p.hp <= 0) this.killPlayer(source);
    }
    killPlayer(source) {
        const p = this.player;
        p.dead = true;
        p.hp = 0;
        p.deadUntil = this.now + 2600;
        p.deaths += 1;
        const xpLost = Math.floor(p.xp * 0.1);
        const goldDropped = Math.floor(p.gold * 0.5);
        p.xp = Math.max(0, p.xp - xpLost);
        p.gold -= goldDropped;
        p.statuses = [];
        p.wardHp = 0;
        if (goldDropped > 0) {
            this.ground.push({
                id: nid(),
                x: p.x,
                y: p.y,
                itemKey: "gold",
                qty: goldDropped,
                owner: p.name,
                protectedUntil: this.now + __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["COMBAT"].LOOT_PROTECT_MS,
                born: this.now,
                jx: 0,
                jy: 0
            });
        }
        this.push_text("YOU DIED", p.x, p.y - 0.5, "#ff5a6e", true);
        this.events.push({
            type: "death",
            killedBy: source,
            xpLost,
            goldDropped,
            x: p.x,
            y: p.y
        });
    }
    respawn() {
        const p = this.player;
        p.level = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["levelFromXp"])(p.xp);
        const s = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["statsForLevel"])(p.level);
        p.maxHp = s.maxHp;
        p.maxMana = s.maxMana;
        p.hp = s.maxHp;
        p.mana = s.maxMana;
        p.x = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TEMPLE"].x;
        p.y = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TEMPLE"].y;
        p.rx = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TEMPLE"].x;
        p.ry = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TEMPLE"].y;
        p.dead = false;
        p.cooldowns = {};
        this.targetId = null;
        this.camX = p.x;
        this.camY = p.y;
    }
    // -------------------------------------------------------------------- tick
    update(dt, now) {
        this.now = now;
        const p = this.player;
        if (p.dead) {
            if (now >= p.deadUntil) this.respawn();
            this.decay(now);
            this.lerpCamera(dt);
            return;
        }
        const slowed = p.statuses.some((s)=>s.key === "slow");
        if (this.heldDir && now >= p.nextStepAt && now >= p.castUntil) {
            const { x: dx, y: dy } = this.heldDir;
            if (dx !== 0 || dy !== 0) {
                p.facing = {
                    x: dx,
                    y: dy
                };
                const nx = p.x + dx;
                const ny = p.y + dy;
                if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["isWalkable"])(this.map, nx, ny) && !this.occupied(nx, ny)) {
                    p.x = nx;
                    p.y = ny;
                    const cost = this.stepMs * (dx !== 0 && dy !== 0 ? 1.4 : 1) * (slowed ? 1.6 : 1);
                    p.nextStepAt = now + cost;
                    this.autoPickupAt(nx, ny);
                    const r = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["regionAt"])(nx, ny);
                    if (r.name !== this.lastRegion) {
                        this.lastRegion = r.name;
                        this.events.push({
                            type: "region",
                            name: r.name
                        });
                    }
                } else {
                    p.nextStepAt = now + 120;
                    this.events.push({
                        type: "blocked"
                    });
                }
            }
        }
        const k = Math.min(1, dt / 90);
        p.rx += (p.x - p.rx) * k;
        p.ry += (p.y - p.ry) * k;
        if (now >= p.castUntil) p.castKey = null;
        // ---- auto-attack tick on the Marked creature
        const marked = this.target();
        if (!marked) {
            this.nextAutoAt = now + __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["COMBAT"].AUTO_ATTACK_MS;
        } else if (this.autoAttack && now >= this.nextAutoAt) {
            const reach = Math.max(Math.abs(marked.x - p.x), Math.abs(marked.y - p.y));
            if (reach <= 1) {
                this.autoSwing(marked);
                this.nextAutoAt = now + __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["COMBAT"].AUTO_ATTACK_MS;
            } else {
                // Out of reach: hold the tick at full so it fires the instant you close.
                this.nextAutoAt = now;
            }
        }
        if (now >= this.nextRegen) {
            this.nextRegen = now + REGEN_MS;
            p.hp = Math.min(p.maxHp, p.hp + 1 + Math.floor(p.level / 3));
            p.mana = Math.min(p.maxMana, p.mana + 2 + Math.floor(p.level / 2));
        }
        for (const s of p.statuses){
            if (s.nextTick && now >= s.nextTick && now < s.until) {
                s.nextTick = now + 1500;
                this.damagePlayer(s.power, s.key === "poison" ? "Venom" : "Cinders");
            }
        }
        p.statuses = p.statuses.filter((s)=>now < s.until);
        if (!p.statuses.some((s)=>s.key === "ward")) p.wardHp = 0;
        const playerSafe = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["inSafeZone"])(p.x, p.y);
        for (const m of this.monsters){
            if (m.dying) continue;
            const dist = Math.max(Math.abs(m.x - p.x), Math.abs(m.y - p.y));
            if (!m.aggro && dist <= m.def.aggroRange && !playerSafe) m.aggro = true;
            if (m.aggro && dist > m.def.aggroRange + 4) m.aggro = false;
            if (!m.aggro) {
                if (now >= m.nextMoveAt) {
                    m.nextMoveAt = now + m.def.moveMs * (3 + Math.random() * 4);
                    const dx = Math.floor(Math.random() * 3) - 1;
                    const dy = Math.floor(Math.random() * 3) - 1;
                    const nx = m.x + dx;
                    const ny = m.y + dy;
                    if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["isWalkable"])(this.map, nx, ny) && !this.occupied(nx, ny) && !(0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["inSafeZone"])(nx, ny)) {
                        m.x = nx;
                        m.y = ny;
                    }
                }
            } else {
                // Protected zone rule: creatures may not attack a player standing inside.
                const canAttack = !playerSafe && dist <= m.def.attackRange && now >= m.nextAttackAt && now >= m.windupUntil;
                if (canAttack) {
                    m.windupUntil = now + m.def.windup;
                    m.nextAttackAt = now + m.def.cadence;
                    this.telegraphs.push({
                        id: nid(),
                        tiles: this.telegraphShape(m, p.x, p.y),
                        startAt: now,
                        resolveAt: now + m.def.windup,
                        color: m.def.color,
                        damage: m.def.damage,
                        source: "monster",
                        sourceId: m.id,
                        status: m.def.key === "spider" ? "poison" : m.def.key === "ember" ? "burn" : undefined,
                        resolved: false
                    });
                } else if (now >= m.nextMoveAt && now >= m.windupUntil && dist > m.def.attackRange) {
                    m.nextMoveAt = now + m.def.moveMs;
                    const dx = Math.sign(p.x - m.x);
                    const dy = Math.sign(p.y - m.y);
                    for (const t of [
                        {
                            x: dx,
                            y: dy
                        },
                        {
                            x: dx,
                            y: 0
                        },
                        {
                            x: 0,
                            y: dy
                        }
                    ]){
                        const nx = m.x + t.x;
                        const ny = m.y + t.y;
                        if ((t.x || t.y) && (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["isWalkable"])(this.map, nx, ny) && !this.occupied(nx, ny) && !(nx === p.x && ny === p.y) && !(0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["inSafeZone"])(nx, ny)) {
                            m.x = nx;
                            m.y = ny;
                            break;
                        }
                    }
                }
            }
            m.rx += (m.x - m.rx) * Math.min(1, dt / 110);
            m.ry += (m.y - m.ry) * Math.min(1, dt / 110);
        }
        for (const t of this.telegraphs){
            if (t.resolved || now < t.resolveAt) continue;
            t.resolved = true;
            if (t.source === "monster") {
                const inZone = t.tiles.some((tile)=>tile.x === p.x && tile.y === p.y);
                const src = this.monsters.find((m)=>m.id === t.sourceId);
                if (inZone) this.damagePlayer(t.damage, src?.def.name ?? "Something in the dark", t.status);
                else this.push_text("dodged", p.x, p.y - 0.4, "#94a3b8");
            } else if (t.sourceId) {
                const m = this.monsters.find((mo)=>mo.id === t.sourceId && mo.dying === 0);
                if (m) {
                    const stillThere = t.tiles.some((tile)=>tile.x === m.x && tile.y === m.y);
                    const reach = Math.max(Math.abs(m.x - p.x), Math.abs(m.y - p.y));
                    if (stillThere || reach <= 1) this.damageMonster(m, t.damage);
                    else this.push_text("miss", m.x, m.y, "#94a3b8");
                }
            } else {
                for (const m of this.monsters){
                    if (m.dying) continue;
                    if (t.tiles.some((tile)=>tile.x === m.x && tile.y === m.y)) this.damageMonster(m, t.damage);
                }
            }
        }
        this.decay(now);
        this.lerpCamera(dt);
        if (now >= this.nextSpawnCheck) {
            this.nextSpawnCheck = now + 2500;
            if (this.monsters.filter((m)=>!m.dying).length < 34) this.spawnMonster();
        }
    }
    telegraphShape(m, px, py) {
        const tiles = [];
        if (m.def.key === "wraith") {
            for(let dy = -1; dy <= 1; dy++)for(let dx = -1; dx <= 1; dx++)tiles.push({
                x: px + dx,
                y: py + dy
            });
        } else if (m.def.key === "ember") {
            const dx = Math.sign(px - m.x);
            const dy = Math.sign(py - m.y);
            for(let i = 1; i <= 3; i++)tiles.push({
                x: m.x + dx * i,
                y: m.y + dy * i
            });
            tiles.push({
                x: px,
                y: py
            });
        } else {
            tiles.push({
                x: px,
                y: py
            });
        }
        return tiles;
    }
    decay(now) {
        this.telegraphs = this.telegraphs.filter((t)=>now < t.resolveAt + 220);
        this.floats = this.floats.filter((f)=>now - f.born < 1100);
        this.projectiles = this.projectiles.filter((pr)=>now - pr.born < pr.duration);
        this.ground = this.ground.filter((g)=>now - g.born < __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["COMBAT"].GROUND_DECAY_MS);
        this.monsters = this.monsters.filter((m)=>!m.dying || now - m.dying < 320);
    }
    lerpCamera(dt) {
        const k = Math.min(1, dt / 170);
        this.camX += (this.player.rx - this.camX) * k;
        this.camY += (this.player.ry - this.camY) * k;
    }
    /** Consumables root you for 1.2s — drinking is a commitment, like everything else. */ consume(hp = 0, mana = 0) {
        const p = this.player;
        if (p.dead) return;
        if (hp) {
            p.hp = Math.min(p.maxHp, p.hp + hp);
            this.push_text(`+${hp}`, p.x, p.y - 0.3, "#4ade80");
        }
        if (mana) {
            p.mana = Math.min(p.maxMana, p.mana + mana);
            this.push_text(`+${mana} mp`, p.x, p.y - 0.6, "#38bdf8");
        }
        p.nextStepAt = this.now + 1200;
    }
    drainEvents() {
        const e = this.events;
        this.events = [];
        return e;
    }
    xpProgress() {
        const p = this.player;
        const prev = p.level > 1 ? (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["xpForLevel"])(p.level - 1) : 0;
        const next = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["xpForLevel"])(p.level);
        return Math.max(0, Math.min(1, (p.xp - prev) / Math.max(1, next - prev)));
    }
    get mapSize() {
        return {
            w: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MAP_W"],
            h: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MAP_H"]
        };
    }
}
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/src/lib/game/renderer.ts [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "render",
    ()=>render,
    "renderMinimap",
    ()=>renderMinimap
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/game/content.ts [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/game/world.ts [app-client] (ecmascript)");
;
;
function rr(ctx, x, y, w, h, r) {
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
}
function render(ctx, g, vp, now) {
    const T = vp.tile;
    const cx = vp.w / 2;
    const cy = vp.h / 2;
    const offX = cx - g.camX * T - T / 2;
    const offY = cy - g.camY * T - T / 2;
    const sx = (tx)=>offX + tx * T;
    const sy = (ty)=>offY + ty * T;
    const minTx = Math.max(0, Math.floor(-offX / T) - 1);
    const maxTx = Math.min(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MAP_W"] - 1, Math.ceil((vp.w - offX) / T) + 1);
    const minTy = Math.max(0, Math.floor(-offY / T) - 1);
    const maxTy = Math.min(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MAP_H"] - 1, Math.ceil((vp.h - offY) / T) + 1);
    ctx.clearRect(0, 0, vp.w, vp.h);
    ctx.fillStyle = "#11131a";
    ctx.fillRect(0, 0, vp.w, vp.h);
    // ---- floor
    for(let ty = minTy; ty <= maxTy; ty++){
        for(let tx = minTx; tx <= maxTx; tx++){
            const def = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TILE_DEFS"][g.map.tiles[ty][tx]];
            const X = sx(tx);
            const Y = sy(ty);
            if (def.kind === "wall") continue;
            ctx.fillStyle = def.side;
            rr(ctx, X + 1, Y + 3, T - 2, T - 3, 7);
            ctx.fill();
            ctx.fillStyle = def.top;
            rr(ctx, X + 1, Y + 1, T - 2, T - 5, 7);
            ctx.fill();
            if (def.detail) {
                const h = tx * 73856093 ^ ty * 19349663;
                if ((h & 7) === 0) {
                    ctx.fillStyle = def.detail;
                    ctx.globalAlpha = 0.85;
                    rr(ctx, X + T * 0.28, Y + T * 0.3, T * 0.22, T * 0.18, 4);
                    ctx.fill();
                    ctx.globalAlpha = 1;
                }
            }
            if (def.kind === "water") {
                ctx.fillStyle = "rgba(255,255,255,0.14)";
                const wob = Math.sin(now / 500 + tx + ty) * 2;
                rr(ctx, X + 6, Y + T * 0.4 + wob, T - 12, 4, 2);
                ctx.fill();
            }
        }
    }
    // ---- safe-zone plaza glow
    {
        const X = sx(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TEMPLE"].x - 3);
        const Y = sy(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TEMPLE"].y - 3);
        ctx.strokeStyle = "rgba(255, 224, 130, 0.5)";
        ctx.lineWidth = 3;
        ctx.setLineDash([
            10,
            8
        ]);
        rr(ctx, X, Y, T * 7, T * 7, 14);
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.fillStyle = "rgba(255, 224, 130, 0.07)";
        ctx.fill();
        ctx.font = `700 ${Math.round(T * 0.3)}px ui-sans-serif, system-ui`;
        ctx.fillStyle = "rgba(255,235,180,0.8)";
        ctx.textAlign = "center";
        ctx.fillText("SANCTUARY · PROTECTED ZONE", sx(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TEMPLE"].x) + T / 2, Y - 8);
    }
    // ---- telegraphs (drawn under actors: readability first)
    for (const t of g.telegraphs){
        const total = Math.max(1, t.resolveAt - t.startAt);
        const p = Math.min(1, (now - t.startAt) / total);
        const done = now >= t.resolveAt;
        const flash = done ? Math.max(0, 1 - (now - t.resolveAt) / 220) : 0;
        for (const tile of t.tiles){
            if (tile.x < 0 || tile.y < 0 || tile.x >= __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MAP_W"] || tile.y >= __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MAP_H"]) continue;
            const X = sx(tile.x);
            const Y = sy(tile.y);
            ctx.globalAlpha = done ? flash * 0.85 : 0.22 + p * 0.42;
            ctx.fillStyle = t.color;
            rr(ctx, X + 2, Y + 2, T - 4, T - 6, 8);
            ctx.fill();
            ctx.globalAlpha = done ? flash : 0.55 + p * 0.45;
            ctx.strokeStyle = t.color;
            ctx.lineWidth = 3;
            rr(ctx, X + 2, Y + 2, T - 4, T - 6, 8);
            ctx.stroke();
            // fill-up wipe = time remaining, readable at a glance
            if (!done) {
                ctx.globalAlpha = 0.5;
                ctx.fillStyle = "rgba(255,255,255,0.65)";
                rr(ctx, X + 3, Y + T - 8 - (T - 12) * p, T - 6, (T - 12) * p, 5);
                ctx.fill();
            }
            ctx.globalAlpha = 1;
        }
    }
    // ---- ground loot (filtered items are simply not drawn)
    ctx.textAlign = "center";
    for (const it of g.visibleGround()){
        const X = sx(it.x + it.jx);
        const Y = sy(it.y + it.jy);
        const def = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ITEMS"][it.itemKey];
        const bob = Math.sin(now / 320 + it.id) * 2;
        const locked = !g.canLoot(it);
        ctx.globalAlpha = 0.3;
        ctx.fillStyle = "#000";
        ctx.beginPath();
        ctx.ellipse(X + T / 2, Y + T * 0.74, T * 0.2, T * 0.09, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.globalAlpha = 1;
        // rarity plinth
        const tint = def?.rarity === "epic" ? "#c026d3" : def?.rarity === "rare" ? "#0ea5e9" : def?.rarity === "uncommon" ? "#10b981" : "#94a3b8";
        ctx.globalAlpha = locked ? 0.35 : 0.9;
        ctx.fillStyle = "rgba(0,0,0,0.6)";
        rr(ctx, X + T * 0.24, Y + T * 0.26 + bob, T * 0.52, T * 0.44, 8);
        ctx.fill();
        ctx.strokeStyle = tint;
        ctx.lineWidth = 2.5;
        rr(ctx, X + T * 0.24, Y + T * 0.26 + bob, T * 0.52, T * 0.44, 8);
        ctx.stroke();
        ctx.globalAlpha = locked ? 0.45 : 1;
        ctx.font = `${Math.round(T * 0.3)}px serif`;
        ctx.textBaseline = "middle";
        ctx.fillStyle = "#fff";
        ctx.fillText(def?.glyph ?? "❔", X + T / 2, Y + T * 0.49 + bob);
        ctx.textBaseline = "alphabetic";
        if (it.qty > 1) {
            ctx.font = `900 ${Math.round(T * 0.19)}px ui-sans-serif, system-ui`;
            ctx.lineWidth = 3;
            ctx.strokeStyle = "rgba(0,0,0,0.9)";
            ctx.strokeText(`${it.qty}`, X + T * 0.74, Y + T * 0.74 + bob);
            ctx.fillStyle = "#fde047";
            ctx.fillText(`${it.qty}`, X + T * 0.74, Y + T * 0.74 + bob);
        }
        // 60s loot-protection lock + countdown arc
        if (locked) {
            const left = Math.max(0, it.protectedUntil - now);
            const pct = left / __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["COMBAT"].LOOT_PROTECT_MS;
            ctx.globalAlpha = 1;
            ctx.strokeStyle = "#f87171";
            ctx.lineWidth = 3;
            ctx.beginPath();
            ctx.arc(X + T / 2, Y + T * 0.48 + bob, T * 0.33, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * pct);
            ctx.stroke();
            ctx.font = `${Math.round(T * 0.22)}px serif`;
            ctx.fillText("🔒", X + T / 2, Y + T * 0.16 + bob);
        }
        ctx.globalAlpha = 1;
    }
    // ---- walls (drawn after floor so they overlap the tile above)
    for(let ty = minTy; ty <= maxTy; ty++){
        for(let tx = minTx; tx <= maxTx; tx++){
            if (g.map.tiles[ty][tx] !== "wall") continue;
            const X = sx(tx);
            const Y = sy(ty);
            const def = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TILE_DEFS"].wall;
            ctx.fillStyle = def.side;
            rr(ctx, X, Y - T * 0.18, T, T * 1.18, 8);
            ctx.fill();
            ctx.fillStyle = def.top;
            rr(ctx, X + 2, Y - T * 0.2, T - 4, T * 0.72, 8);
            ctx.fill();
            ctx.fillStyle = "rgba(0,0,0,0.18)";
            rr(ctx, X + 5, Y + T * 0.16, T - 10, T * 0.16, 4);
            ctx.fill();
        }
    }
    // ---- projectiles
    for (const pr of g.projectiles){
        const p = Math.min(1, (now - pr.born) / pr.duration);
        const X = sx(pr.fx + (pr.tx - pr.fx) * p) + T / 2;
        const Y = sy(pr.fy + (pr.ty - pr.fy) * p) + T / 2;
        ctx.fillStyle = pr.color;
        ctx.shadowColor = pr.color;
        ctx.shadowBlur = 14;
        ctx.beginPath();
        ctx.arc(X, Y, T * 0.16, 0, Math.PI * 2);
        ctx.fill();
        ctx.shadowBlur = 0;
    }
    // ---- monsters
    const sorted = [
        ...g.monsters
    ].sort((a, b)=>a.ry - b.ry);
    for (const m of sorted){
        const X = sx(m.rx);
        const Y = sy(m.ry);
        const dying = m.dying ? Math.min(1, (now - m.dying) / 320) : 0;
        ctx.save();
        if (dying) {
            ctx.globalAlpha = 1 - dying;
            ctx.translate(X + T / 2, Y + T / 2);
            ctx.scale(1 + dying * 0.5, 1 - dying * 0.4);
            ctx.translate(-(X + T / 2), -(Y + T / 2));
        }
        // shadow
        ctx.globalAlpha *= 0.35;
        ctx.fillStyle = "#000";
        ctx.beginPath();
        ctx.ellipse(X + T / 2, Y + T * 0.78, T * 0.3, T * 0.13, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.globalAlpha = dying ? 1 - dying : 1;
        const bob = Math.sin(now / 300 + m.id * 1.7) * T * 0.03;
        const winding = now < m.windupUntil;
        const scale = winding ? 1 + Math.sin(now / m.def.windup * Math.PI) * 0.12 : 1;
        const bw = T * 0.62 * scale;
        const bh = T * 0.62 * scale;
        const bx = X + (T - bw) / 2;
        const by = Y + T * 0.16 + bob;
        // chunky outline body
        ctx.fillStyle = "rgba(0,0,0,0.85)";
        rr(ctx, bx - 3, by - 3, bw + 6, bh + 6, 12);
        ctx.fill();
        ctx.fillStyle = now < m.hitFlash ? "#ffffff" : m.def.color;
        rr(ctx, bx, by, bw, bh, 10);
        ctx.fill();
        // top highlight
        ctx.fillStyle = "rgba(255,255,255,0.22)";
        rr(ctx, bx + 4, by + 4, bw - 8, bh * 0.3, 6);
        ctx.fill();
        ctx.font = `${Math.round(bh * 0.62)}px serif`;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText(m.def.glyph, bx + bw / 2, by + bh / 2 + 1);
        ctx.textBaseline = "alphabetic";
        // hp bar
        if (m.hp < m.maxHp || g.targetId === m.id) {
            const bwid = T * 0.66;
            const bxx = X + (T - bwid) / 2;
            const byy = by - 10;
            ctx.fillStyle = "rgba(0,0,0,0.7)";
            rr(ctx, bxx - 1.5, byy - 1.5, bwid + 3, 7, 3.5);
            ctx.fill();
            ctx.fillStyle = "#ff5a6e";
            rr(ctx, bxx, byy, bwid * Math.max(0, m.hp / m.maxHp), 4, 2);
            ctx.fill();
        }
        ctx.restore();
        // MARK reticle + 2s auto-attack tick arc
        if (g.targetId === m.id && !m.dying) {
            const r = T * 0.5;
            ctx.save();
            ctx.translate(X + T / 2, Y + T / 2);
            ctx.rotate(now / 900);
            ctx.strokeStyle = "#ffd166";
            ctx.lineWidth = 3;
            ctx.setLineDash([
                r * 0.5,
                r * 0.55
            ]);
            ctx.beginPath();
            ctx.arc(0, 0, r, 0, Math.PI * 2);
            ctx.stroke();
            ctx.setLineDash([]);
            ctx.restore();
            // Solid arc filling over COMBAT.AUTO_ATTACK_MS — the tick you can read.
            const pct = g.autoTickPct();
            ctx.save();
            ctx.translate(X + T / 2, Y + T / 2);
            ctx.strokeStyle = pct >= 1 ? "#ffffff" : "#ff8a3d";
            ctx.lineWidth = 4;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.arc(0, 0, r * 0.78, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * pct);
            ctx.stroke();
            ctx.restore();
        }
    }
    // ---- player
    {
        const p = g.player;
        const X = sx(p.rx);
        const Y = sy(p.ry);
        ctx.globalAlpha = p.dead ? 0.35 : 1;
        ctx.save();
        ctx.globalAlpha = p.dead ? 0.25 : 0.4;
        ctx.fillStyle = "#000";
        ctx.beginPath();
        ctx.ellipse(X + T / 2, Y + T * 0.8, T * 0.32, T * 0.14, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
        ctx.globalAlpha = p.dead ? 0.4 : 1;
        const bob = Math.sin(now / 260) * T * 0.03;
        const bw = T * 0.66;
        const bh = T * 0.7;
        const bx = X + (T - bw) / 2;
        const by = Y + T * 0.1 + bob;
        if (p.wardHp > 0) {
            ctx.strokeStyle = "#06d6a0";
            ctx.lineWidth = 3;
            ctx.globalAlpha = 0.75;
            ctx.beginPath();
            ctx.arc(X + T / 2, Y + T * 0.45, T * 0.52, 0, Math.PI * 2);
            ctx.stroke();
            ctx.fillStyle = "rgba(6,214,160,0.14)";
            ctx.fill();
            ctx.globalAlpha = 1;
        }
        ctx.fillStyle = "rgba(0,0,0,0.85)";
        rr(ctx, bx - 3.5, by - 3.5, bw + 7, bh + 7, 13);
        ctx.fill();
        ctx.fillStyle = now < p.hitFlash ? "#ffffff" : p.dead ? "#5b6270" : "#e8eaf0";
        rr(ctx, bx, by, bw, bh, 11);
        ctx.fill();
        // cloak
        ctx.fillStyle = p.dead ? "#3a3f4b" : "#c0392b";
        rr(ctx, bx, by + bh * 0.45, bw, bh * 0.55, 10);
        ctx.fill();
        // visor
        ctx.fillStyle = "#1a1d26";
        rr(ctx, bx + bw * 0.18, by + bh * 0.2, bw * 0.64, bh * 0.16, 4);
        ctx.fill();
        // facing pip
        ctx.fillStyle = "#ffd166";
        ctx.beginPath();
        ctx.arc(X + T / 2 + p.facing.x * T * 0.36, Y + T * 0.45 + p.facing.y * T * 0.36, T * 0.07, 0, Math.PI * 2);
        ctx.fill();
        // cast ring
        if (p.castKey && now < p.castUntil) {
            ctx.strokeStyle = "#ffd166";
            ctx.lineWidth = 4;
            ctx.beginPath();
            ctx.arc(X + T / 2, Y + T * 0.45, T * 0.45, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * 0.7);
            ctx.stroke();
        }
        // status pips
        const pips = p.statuses.filter((s)=>s.key !== "ward");
        pips.forEach((s, i)=>{
            const c = s.key === "poison" ? "#84cc16" : s.key === "burn" ? "#f97316" : "#38bdf8";
            ctx.fillStyle = c;
            ctx.beginPath();
            ctx.arc(bx + 6 + i * 11, by - 9, 4.5, 0, Math.PI * 2);
            ctx.fill();
            ctx.strokeStyle = "rgba(0,0,0,0.8)";
            ctx.lineWidth = 1.5;
            ctx.stroke();
        });
        ctx.globalAlpha = 1;
    }
    // ---- shove preview (drag gesture)
    if (g.pushPreview) {
        const { from, to, valid } = g.pushPreview;
        const col = valid ? "#4cc9f0" : "#ef4444";
        const FX = sx(from.x) + T / 2;
        const FY = sy(from.y) + T / 2;
        const TX = sx(to.x) + T / 2;
        const TY = sy(to.y) + T / 2;
        ctx.globalAlpha = 0.3;
        ctx.fillStyle = col;
        rr(ctx, sx(to.x) + 2, sy(to.y) + 2, T - 4, T - 6, 8);
        ctx.fill();
        ctx.globalAlpha = 0.95;
        ctx.strokeStyle = col;
        ctx.lineWidth = 3.5;
        ctx.setLineDash([
            7,
            6
        ]);
        rr(ctx, sx(to.x) + 2, sy(to.y) + 2, T - 4, T - 6, 8);
        ctx.stroke();
        ctx.setLineDash([]);
        // arrow shaft + head
        ctx.beginPath();
        ctx.moveTo(FX, FY);
        ctx.lineTo(TX, TY);
        ctx.lineWidth = 5;
        ctx.stroke();
        const ang = Math.atan2(TY - FY, TX - FX);
        ctx.beginPath();
        ctx.moveTo(TX, TY);
        ctx.lineTo(TX - Math.cos(ang - 0.5) * T * 0.28, TY - Math.sin(ang - 0.5) * T * 0.28);
        ctx.lineTo(TX - Math.cos(ang + 0.5) * T * 0.28, TY - Math.sin(ang + 0.5) * T * 0.28);
        ctx.closePath();
        ctx.fillStyle = col;
        ctx.fill();
        if (!valid) {
            ctx.font = `900 ${Math.round(T * 0.3)}px ui-sans-serif, system-ui`;
            ctx.textAlign = "center";
            ctx.fillStyle = "#fff";
            ctx.fillText("✕", TX, TY + T * 0.1);
        }
        ctx.globalAlpha = 1;
    }
    // ---- floating combat text
    ctx.textAlign = "center";
    for (const f of g.floats){
        const age = (now - f.born) / 1100;
        const X = sx(f.x) + T / 2;
        const Y = sy(f.y) + T * 0.4 - age * T * 0.9;
        ctx.globalAlpha = Math.max(0, 1 - age * age);
        const size = Math.round(T * (f.crit ? 0.4 : 0.3));
        ctx.font = `900 ${size}px ui-sans-serif, system-ui, sans-serif`;
        ctx.lineWidth = 4;
        ctx.strokeStyle = "rgba(0,0,0,0.85)";
        ctx.strokeText(f.text, X, Y);
        ctx.fillStyle = f.color;
        ctx.fillText(f.text, X, Y);
        ctx.globalAlpha = 1;
    }
    // ---- region banner tint at edges (soft vignette)
    const grad = ctx.createRadialGradient(cx, cy, Math.min(vp.w, vp.h) * 0.32, cx, cy, Math.max(vp.w, vp.h) * 0.75);
    const region = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["regionAt"])(g.player.x, g.player.y);
    grad.addColorStop(0, "rgba(0,0,0,0)");
    grad.addColorStop(1, region.tint + "aa");
    ctx.globalCompositeOperation = "multiply";
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, vp.w, vp.h);
    ctx.globalCompositeOperation = "source-over";
}
function renderMinimap(ctx, g, size) {
    const s = size / __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MAP_W"];
    ctx.clearRect(0, 0, size, size);
    ctx.fillStyle = "#0b0d12";
    ctx.fillRect(0, 0, size, size);
    for(let y = 0; y < __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MAP_H"]; y++){
        for(let x = 0; x < __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MAP_W"]; x++){
            const k = g.map.tiles[y][x];
            const d = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TILE_DEFS"][k];
            ctx.fillStyle = k === "wall" ? "#2a2d36" : d.top;
            ctx.fillRect(x * s, y * s, s, s);
        }
    }
    ctx.fillStyle = "#ffd166";
    ctx.fillRect((__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TEMPLE"].x - 1) * s, (__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["TEMPLE"].y - 1) * s, s * 3, s * 3);
    for (const m of g.monsters){
        if (m.dying) continue;
        ctx.fillStyle = m.aggro ? "#ff5a6e" : "rgba(255,255,255,0.35)";
        ctx.fillRect(m.x * s, m.y * s, s, s);
    }
    for (const it of g.visibleGround()){
        ctx.fillStyle = g.canLoot(it) ? "#fde047" : "#f87171";
        ctx.fillRect(it.x * s, it.y * s, s, s);
    }
    ctx.fillStyle = "#4cc9f0";
    ctx.fillRect(g.player.x * s - s * 0.5, g.player.y * s - s * 0.5, s * 2, s * 2);
}
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/src/components/game/Joystick.tsx [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>Joystick
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/compiled/react/jsx-dev-runtime.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/compiled/react/index.js [app-client] (ecmascript)");
;
var _s = __turbopack_context__.k.signature();
"use client";
;
function Joystick({ onDir, dim }) {
    _s();
    const ref = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])(null);
    const [knob, setKnob] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])({
        x: 0,
        y: 0
    });
    const [active, setActive] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(false);
    const originRef = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])({
        x: 0,
        y: 0
    });
    const compute = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "Joystick.useCallback[compute]": (cx, cy)=>{
            const dx = cx - originRef.current.x;
            const dy = cy - originRef.current.y;
            const len = Math.hypot(dx, dy);
            const max = 52;
            const clamped = Math.min(len, max);
            const nx = len > 0 ? dx / len * clamped : 0;
            const ny = len > 0 ? dy / len * clamped : 0;
            setKnob({
                x: nx,
                y: ny
            });
            if (len < 16) {
                onDir(null);
                return;
            }
            const ang = Math.atan2(dy, dx);
            const oct = Math.round(ang / (Math.PI / 4));
            const table = {
                [-4]: {
                    x: -1,
                    y: 0
                },
                [-3]: {
                    x: -1,
                    y: -1
                },
                [-2]: {
                    x: 0,
                    y: -1
                },
                [-1]: {
                    x: 1,
                    y: -1
                },
                [0]: {
                    x: 1,
                    y: 0
                },
                [1]: {
                    x: 1,
                    y: 1
                },
                [2]: {
                    x: 0,
                    y: 1
                },
                [3]: {
                    x: -1,
                    y: 1
                },
                [4]: {
                    x: -1,
                    y: 0
                }
            };
            onDir(table[oct] ?? null);
        }
    }["Joystick.useCallback[compute]"], [
        onDir
    ]);
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        ref: ref,
        className: "pointer-events-auto touch-none select-none",
        style: {
            opacity: dim && !active ? 0.4 : 1,
            transition: "opacity .45s ease"
        },
        onPointerDown: (e)=>{
            e.target.setPointerCapture(e.pointerId);
            const r = ref.current.getBoundingClientRect();
            originRef.current = {
                x: r.left + r.width / 2,
                y: r.top + r.height / 2
            };
            setActive(true);
            compute(e.clientX, e.clientY);
        },
        onPointerMove: (e)=>{
            if (!active) return;
            compute(e.clientX, e.clientY);
        },
        onPointerUp: ()=>{
            setActive(false);
            setKnob({
                x: 0,
                y: 0
            });
            onDir(null);
        },
        onPointerCancel: ()=>{
            setActive(false);
            setKnob({
                x: 0,
                y: 0
            });
            onDir(null);
        },
        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
            className: "relative grid h-36 w-36 place-items-center rounded-full border-2 border-white/15 bg-black/35 backdrop-blur-sm",
            children: [
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "absolute inset-5 rounded-full border border-white/10"
                }, void 0, false, {
                    fileName: "[project]/src/components/game/Joystick.tsx",
                    lineNumber: 77,
                    columnNumber: 9
                }, this),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "h-16 w-16 rounded-full border-4 border-black/50 bg-gradient-to-b from-slate-100 to-slate-400 shadow-[0_6px_0_rgba(0,0,0,0.45)]",
                    style: {
                        transform: `translate(${knob.x}px, ${knob.y}px)`,
                        transition: active ? "none" : "transform .18s ease"
                    }
                }, void 0, false, {
                    fileName: "[project]/src/components/game/Joystick.tsx",
                    lineNumber: 78,
                    columnNumber: 9
                }, this)
            ]
        }, void 0, true, {
            fileName: "[project]/src/components/game/Joystick.tsx",
            lineNumber: 76,
            columnNumber: 7
        }, this)
    }, void 0, false, {
        fileName: "[project]/src/components/game/Joystick.tsx",
        lineNumber: 50,
        columnNumber: 5
    }, this);
}
_s(Joystick, "7thEGVfKb/xQQgeWrnbltOaYrpU=");
_c = Joystick;
var _c;
__turbopack_context__.k.register(_c, "Joystick");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/src/components/game/GamePlay.tsx [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>GamePlay
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/compiled/react/jsx-dev-runtime.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/compiled/react/index.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/client/app-dir/link.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$engine$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/game/engine.ts [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$renderer$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/game/renderer.ts [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/game/content.ts [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/game/world.ts [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$components$2f$game$2f$Joystick$2e$tsx__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/components/game/Joystick.tsx [app-client] (ecmascript)");
;
var _s = __turbopack_context__.k.signature();
"use client";
;
;
;
;
;
;
;
const haptic = (pattern)=>{
    if (typeof navigator !== "undefined" && "vibrate" in navigator) {
        try {
            navigator.vibrate(pattern);
        } catch  {
        /* unsupported */ }
    }
};
function GamePlay({ initialName }) {
    _s();
    const canvasRef = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])(null);
    const miniRef = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])(null);
    const engineRef = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])(null);
    const [engine, setEngine] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(null);
    const [name, setName] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(initialName);
    const nameFieldRef = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])(null);
    const [started, setStarted] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(false);
    const [, force] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(0);
    const [toasts, setToasts] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])([]);
    const [inventory, setInventory] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])([]);
    const [equipped, setEquipped] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])({});
    const [lootFilter, setLootFilter] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["DEFAULT_LOOT_FILTER"]);
    const [autoPickup, setAutoPickup] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(true);
    const [autoAttack, setAutoAttack] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(true);
    const [sheet, setSheet] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])("none");
    const [banner, setBanner] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(null);
    const [dim, setDim] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(false);
    const [deathCard, setDeathCard] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(null);
    const lastInputRef = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])(0);
    const lootQueue = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])([]);
    const deathQueue = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])(null);
    const teleQueue = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])([]);
    /** Drag-to-shove gesture bookkeeping. */ const dragRef = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])(null);
    const loadout = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["computeLoadout"])(equipped);
    const toast = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "GamePlay.useCallback[toast]": (text, tone = "info")=>{
            const id = Math.random();
            setToasts({
                "GamePlay.useCallback[toast]": (t)=>[
                        ...t.slice(-4),
                        {
                            id,
                            text,
                            tone
                        }
                    ]
            }["GamePlay.useCallback[toast]"]);
            setTimeout({
                "GamePlay.useCallback[toast]": ()=>setToasts({
                        "GamePlay.useCallback[toast]": (t)=>t.filter({
                                "GamePlay.useCallback[toast]": (x)=>x.id !== id
                            }["GamePlay.useCallback[toast]"])
                    }["GamePlay.useCallback[toast]"])
            }["GamePlay.useCallback[toast]"], 2600);
        }
    }["GamePlay.useCallback[toast]"], []);
    const markInput = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "GamePlay.useCallback[markInput]": ()=>{
            lastInputRef.current = Date.now();
            setDim(false);
        }
    }["GamePlay.useCallback[markInput]"], []);
    // Restore the last character name straight into the uncontrolled field. Doing
    // this via DOM avoids a synchronous setState-in-effect cascade on mount.
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "GamePlay.useEffect": ()=>{
            const stored = window.localStorage.getItem("remnants.name");
            if (stored && nameFieldRef.current) nameFieldRef.current.value = stored;
        }
    }["GamePlay.useEffect"], []);
    // ------------------------------------------------------------ boot session
    const boot = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "GamePlay.useCallback[boot]": async ()=>{
            const clean = (nameFieldRef.current?.value ?? "").trim().slice(0, 18) || "Wanderer";
            setName(clean);
            let saved;
            let gear = {};
            let filter = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["DEFAULT_LOOT_FILTER"];
            let pickup = true;
            let auto = true;
            try {
                const res = await fetch("/api/character", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({
                        name: clean
                    })
                });
                const data = await res.json();
                if (data.character) {
                    saved = {
                        level: data.character.level,
                        xp: data.character.xp,
                        hp: data.character.hp,
                        mana: data.character.mana,
                        gold: data.character.gold,
                        x: data.character.tileX,
                        y: data.character.tileY,
                        kills: data.character.kills,
                        deaths: data.character.deaths
                    };
                    setInventory(data.inventory ?? []);
                    gear = data.equipped ?? {};
                    setEquipped(gear);
                    filter = data.settings?.lootFilter?.length ? data.settings.lootFilter : __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["DEFAULT_LOOT_FILTER"];
                    pickup = data.settings?.autoPickup ?? true;
                    auto = data.settings?.autoAttack ?? true;
                    setLootFilter(filter);
                    setAutoPickup(pickup);
                    setAutoAttack(auto);
                }
                window.localStorage.setItem("remnants.name", clean);
            } catch  {
                toast("Offline mode — progress will not persist.", "bad");
            }
            const created = new __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$engine$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["GameEngine"](clean, 1337, saved, (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["computeLoadout"])(gear), {
                autoPickup: pickup,
                autoAttack: auto,
                lootFilter: filter
            });
            engineRef.current = created;
            setEngine(created);
            setStarted(true);
            haptic(24);
        }
    }["GamePlay.useCallback[boot]"], [
        toast
    ]);
    // ---------------------------------------------- push engine config changes
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "GamePlay.useEffect": ()=>{
            engineRef.current?.setLoadout((0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["computeLoadout"])(equipped));
        }
    }["GamePlay.useEffect"], [
        equipped
    ]);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "GamePlay.useEffect": ()=>{
            engineRef.current?.setLootFilter(lootFilter);
        }
    }["GamePlay.useEffect"], [
        lootFilter
    ]);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "GamePlay.useEffect": ()=>{
            engineRef.current?.setAutoPickup(autoPickup);
        }
    }["GamePlay.useEffect"], [
        autoPickup
    ]);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "GamePlay.useEffect": ()=>{
            engineRef.current?.setAutoAttackEnabled(autoAttack);
        }
    }["GamePlay.useEffect"], [
        autoAttack
    ]);
    // ------------------------------------------------------------- game loop
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "GamePlay.useEffect": ()=>{
            if (!started) return;
            const canvas = canvasRef.current;
            if (!canvas) return;
            const ctx = canvas.getContext("2d");
            if (!ctx) return;
            let raf = 0;
            let last = performance.now();
            let vp = {
                w: 0,
                h: 0,
                tile: 48,
                dpr: 1
            };
            const resize = {
                "GamePlay.useEffect.resize": ()=>{
                    const dpr = Math.min(2, window.devicePixelRatio || 1);
                    const w = canvas.clientWidth;
                    const h = canvas.clientHeight;
                    canvas.width = Math.floor(w * dpr);
                    canvas.height = Math.floor(h * dpr);
                    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
                    vp = {
                        w,
                        h,
                        tile: Math.max(38, Math.min(76, Math.min(w, h) / 8.5)),
                        dpr
                    };
                }
            }["GamePlay.useEffect.resize"];
            resize();
            window.addEventListener("resize", resize);
            const mini = miniRef.current;
            const mctx = mini?.getContext("2d") ?? null;
            let miniAcc = 0;
            let uiAcc = 0;
            const handleEvent = {
                "GamePlay.useEffect.handleEvent": (e)=>{
                    switch(e.type){
                        case "kill":
                            haptic([
                                12,
                                30,
                                18
                            ]);
                            teleQueue.current.push({
                                event: "kill",
                                payload: {
                                    monster: e.monster
                                }
                            });
                            break;
                        case "loot":
                            if (e.items.length) {
                                for (const it of e.items)lootQueue.current.push(it);
                                toast(e.items.map({
                                    "GamePlay.useEffect.handleEvent": (i)=>`${__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ITEMS"][i.itemKey]?.glyph ?? ""} ${__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ITEMS"][i.itemKey]?.name ?? i.itemKey} x${i.qty}`
                                }["GamePlay.useEffect.handleEvent"]).join(", "), "good");
                                haptic(18);
                            }
                            break;
                        case "levelup":
                            haptic([
                                0,
                                40,
                                60,
                                80
                            ]);
                            setBanner(`LEVEL ${e.level}`);
                            setTimeout({
                                "GamePlay.useEffect.handleEvent": ()=>setBanner(null)
                            }["GamePlay.useEffect.handleEvent"], 2200);
                            teleQueue.current.push({
                                event: "levelup",
                                payload: {
                                    level: e.level
                                }
                            });
                            break;
                        case "damaged":
                            haptic(e.amount > 15 ? [
                                0,
                                45
                            ] : 14);
                            break;
                        case "death":
                            haptic([
                                0,
                                90,
                                60,
                                140
                            ]);
                            deathQueue.current = e;
                            setDeathCard({
                                killedBy: e.killedBy,
                                xpLost: e.xpLost,
                                gold: e.goldDropped
                            });
                            setTimeout({
                                "GamePlay.useEffect.handleEvent": ()=>setDeathCard(null)
                            }["GamePlay.useEffect.handleEvent"], 5200);
                            break;
                        case "push":
                            haptic(e.ok ? [
                                0,
                                26,
                                20,
                                12
                            ] : 6);
                            if (e.ok) teleQueue.current.push({
                                event: "shove",
                                payload: {}
                            });
                            else if (e.reason) toast(e.reason, "bad");
                            break;
                        case "denied":
                            haptic(6);
                            toast(e.reason, "bad");
                            break;
                        case "region":
                            setBanner(e.name);
                            setTimeout({
                                "GamePlay.useEffect.handleEvent": ()=>setBanner({
                                        "GamePlay.useEffect.handleEvent": (b)=>b === e.name ? null : b
                                    }["GamePlay.useEffect.handleEvent"])
                            }["GamePlay.useEffect.handleEvent"], 1900);
                            break;
                        case "nomana":
                            haptic(8);
                            break;
                        default:
                            break;
                    }
                }
            }["GamePlay.useEffect.handleEvent"];
            const loop = {
                "GamePlay.useEffect.loop": (t)=>{
                    const dt = Math.min(64, t - last);
                    last = t;
                    const g = engineRef.current;
                    if (g) {
                        g.update(dt, t);
                        (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$renderer$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["render"])(ctx, g, vp, t);
                        miniAcc += dt;
                        if (mctx && miniAcc > 220) {
                            miniAcc = 0;
                            (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$renderer$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["renderMinimap"])(mctx, g, mini.width);
                        }
                        uiAcc += dt;
                        if (uiAcc > 90) {
                            uiAcc = 0;
                            force({
                                "GamePlay.useEffect.loop": (n)=>n + 1
                            }["GamePlay.useEffect.loop"]);
                        }
                        for (const e of g.drainEvents())handleEvent(e);
                        if (Date.now() - lastInputRef.current > 3800) setDim(true);
                    }
                    raf = requestAnimationFrame(loop);
                }
            }["GamePlay.useEffect.loop"];
            raf = requestAnimationFrame(loop);
            return ({
                "GamePlay.useEffect": ()=>{
                    cancelAnimationFrame(raf);
                    window.removeEventListener("resize", resize);
                }
            })["GamePlay.useEffect"];
        }
    }["GamePlay.useEffect"], [
        started,
        toast
    ]);
    // ------------------------------------------------------------- persistence
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "GamePlay.useEffect": ()=>{
            if (!started) return;
            const iv = setInterval({
                "GamePlay.useEffect.iv": async ()=>{
                    const g = engineRef.current;
                    if (!g) return;
                    const p = g.player;
                    const loot = lootQueue.current.splice(0, lootQueue.current.length);
                    const deathEv = deathQueue.current;
                    deathQueue.current = null;
                    const events = teleQueue.current.splice(0, teleQueue.current.length);
                    try {
                        const res = await fetch("/api/character/sync", {
                            method: "POST",
                            headers: {
                                "Content-Type": "application/json"
                            },
                            body: JSON.stringify({
                                name: p.name,
                                state: {
                                    level: p.level,
                                    xp: p.xp,
                                    hp: Math.max(1, Math.round(p.hp)),
                                    maxHp: p.maxHp,
                                    mana: Math.round(p.mana),
                                    maxMana: p.maxMana,
                                    gold: p.gold,
                                    tileX: p.x,
                                    tileY: p.y,
                                    region: (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["regionAt"])(p.x, p.y).name,
                                    kills: p.kills,
                                    deaths: p.deaths
                                },
                                loot,
                                events,
                                death: deathEv && deathEv.type === "death" ? {
                                    killedBy: deathEv.killedBy,
                                    xpLost: deathEv.xpLost,
                                    goldDropped: deathEv.goldDropped,
                                    tileX: deathEv.x,
                                    tileY: deathEv.y,
                                    region: (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["regionAt"])(deathEv.x, deathEv.y).name,
                                    level: p.level
                                } : undefined
                            })
                        });
                        const data = await res.json();
                        if (data.inventory) setInventory(data.inventory);
                    } catch  {
                    /* keep playing offline */ }
                }
            }["GamePlay.useEffect.iv"], 5000);
            return ({
                "GamePlay.useEffect": ()=>clearInterval(iv)
            })["GamePlay.useEffect"];
        }
    }["GamePlay.useEffect"], [
        started
    ]);
    const saveSettings = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "GamePlay.useCallback[saveSettings]": async (patch)=>{
            try {
                await fetch("/api/character/settings", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({
                        name,
                        ...patch
                    })
                });
            } catch  {
            /* non-critical */ }
        }
    }["GamePlay.useCallback[saveSettings]"], [
        name
    ]);
    // --------------------------------------------------------------- targeting
    const cycleTarget = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "GamePlay.useCallback[cycleTarget]": ()=>{
            const g = engineRef.current;
            if (!g) return;
            const near = g.monsters.filter({
                "GamePlay.useCallback[cycleTarget].near": (m)=>!m.dying
            }["GamePlay.useCallback[cycleTarget].near"]).map({
                "GamePlay.useCallback[cycleTarget].near": (m)=>({
                        m,
                        d: Math.max(Math.abs(m.x - g.player.x), Math.abs(m.y - g.player.y))
                    })
            }["GamePlay.useCallback[cycleTarget].near"]).filter({
                "GamePlay.useCallback[cycleTarget].near": (o)=>o.d <= 6
            }["GamePlay.useCallback[cycleTarget].near"]).sort({
                "GamePlay.useCallback[cycleTarget].near": (a, b)=>a.d - b.d
            }["GamePlay.useCallback[cycleTarget].near"]);
            if (!near.length) return;
            const idx = near.findIndex({
                "GamePlay.useCallback[cycleTarget].idx": (o)=>o.m.id === g.targetId
            }["GamePlay.useCallback[cycleTarget].idx"]);
            g.setTarget(near[(idx + 1) % near.length].m.id);
            haptic(10);
        }
    }["GamePlay.useCallback[cycleTarget]"], []);
    const drinkItem = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "GamePlay.useCallback[drinkItem]": async (itemKey)=>{
            markInput();
            try {
                const res = await fetch("/api/character/use", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({
                        name,
                        itemKey
                    })
                });
                const data = await res.json();
                if (!res.ok) return toast(data.error ?? "Cannot use that", "bad");
                engineRef.current?.consume(data.effect.hp ?? 0, data.effect.mana ?? 0);
                setInventory(data.inventory);
                toast(data.effect.label, "good");
                haptic([
                    0,
                    20,
                    40,
                    20
                ]);
            } catch  {
                toast("Server unreachable", "bad");
            }
        }
    }["GamePlay.useCallback[drinkItem]"], [
        name,
        markInput,
        toast
    ]);
    const changeGear = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "GamePlay.useCallback[changeGear]": async (action, payload)=>{
            markInput();
            try {
                const res = await fetch("/api/character/equipment", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({
                        name,
                        action,
                        ...payload
                    })
                });
                const data = await res.json();
                if (!res.ok) return toast(data.error ?? "Could not change gear", "bad");
                setEquipped(data.equipped ?? {});
                setInventory(data.inventory ?? []);
                haptic(16);
            } catch  {
                toast("Server unreachable", "bad");
            }
        }
    }["GamePlay.useCallback[changeGear]"], [
        name,
        markInput,
        toast
    ]);
    const toggleFilter = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "GamePlay.useCallback[toggleFilter]": (key)=>{
            setLootFilter({
                "GamePlay.useCallback[toggleFilter]": (prev)=>{
                    const next = prev.includes(key) ? prev.filter({
                        "GamePlay.useCallback[toggleFilter]": (k)=>k !== key
                    }["GamePlay.useCallback[toggleFilter]"]) : [
                        ...prev,
                        key
                    ];
                    saveSettings({
                        lootFilter: next
                    });
                    return next;
                }
            }["GamePlay.useCallback[toggleFilter]"]);
            haptic(8);
        }
    }["GamePlay.useCallback[toggleFilter]"], [
        saveSettings
    ]);
    // -------------------------------------------------- canvas pointer: tap/drag
    const tileFromPointer = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "GamePlay.useCallback[tileFromPointer]": (clientX, clientY)=>{
            const g = engineRef.current;
            const canvas = canvasRef.current;
            if (!g || !canvas) return null;
            const rect = canvas.getBoundingClientRect();
            const tile = Math.max(38, Math.min(76, Math.min(rect.width, rect.height) / 8.5));
            const offX = rect.width / 2 - g.camX * tile - tile / 2;
            const offY = rect.height / 2 - g.camY * tile - tile / 2;
            return {
                x: Math.floor((clientX - rect.left - offX) / tile),
                y: Math.floor((clientY - rect.top - offY) / tile),
                tile
            };
        }
    }["GamePlay.useCallback[tileFromPointer]"], []);
    const onPointerDown = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "GamePlay.useCallback[onPointerDown]": (e)=>{
            markInput();
            const g = engineRef.current;
            const t = tileFromPointer(e.clientX, e.clientY);
            if (!g || !t) return;
            e.target.setPointerCapture(e.pointerId);
            dragRef.current = {
                monster: g.monsterAt(t.x, t.y),
                startTile: {
                    x: t.x,
                    y: t.y
                },
                startPx: {
                    x: e.clientX,
                    y: e.clientY
                },
                moved: false
            };
        }
    }["GamePlay.useCallback[onPointerDown]"], [
        markInput,
        tileFromPointer
    ]);
    const onPointerMove = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "GamePlay.useCallback[onPointerMove]": (e)=>{
            const d = dragRef.current;
            const g = engineRef.current;
            if (!d || !g) return;
            const dist = Math.hypot(e.clientX - d.startPx.x, e.clientY - d.startPx.y);
            const t = tileFromPointer(e.clientX, e.clientY);
            if (!t) return;
            if (dist > 14) d.moved = true;
            if (d.monster && d.moved && (t.x !== d.startTile.x || t.y !== d.startTile.y)) {
                g.previewPush(d.monster, t.x, t.y);
            } else {
                g.clearPushPreview();
            }
        }
    }["GamePlay.useCallback[onPointerMove]"], [
        tileFromPointer
    ]);
    const onPointerUp = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "GamePlay.useCallback[onPointerUp]": (e)=>{
            const d = dragRef.current;
            const g = engineRef.current;
            dragRef.current = null;
            if (!d || !g) return;
            g.clearPushPreview();
            const t = tileFromPointer(e.clientX, e.clientY);
            if (!t) return;
            const sameTile = t.x === d.startTile.x && t.y === d.startTile.y;
            if (d.monster && d.moved && !sameTile) {
                // Hold-and-release on a creature = shove one tile toward the release point.
                g.push(d.monster, t.x, t.y);
                return;
            }
            // Plain tap: mark a creature or loot a tile.
            g.tapTile(d.startTile.x, d.startTile.y);
            haptic(8);
        }
    }["GamePlay.useCallback[onPointerUp]"], [
        tileFromPointer
    ]);
    // ------------------------------------------------------------- keyboard
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "GamePlay.useEffect": ()=>{
            if (!started) return;
            const held = new Set();
            const dirFor = {
                "GamePlay.useEffect.dirFor": ()=>{
                    let x = 0;
                    let y = 0;
                    if (held.has("a") || held.has("arrowleft")) x -= 1;
                    if (held.has("d") || held.has("arrowright")) x += 1;
                    if (held.has("w") || held.has("arrowup")) y -= 1;
                    if (held.has("s") || held.has("arrowdown")) y += 1;
                    return x || y ? {
                        x,
                        y
                    } : null;
                }
            }["GamePlay.useEffect.dirFor"];
            const down = {
                "GamePlay.useEffect.down": (e)=>{
                    const k = e.key.toLowerCase();
                    markInput();
                    if ([
                        "1",
                        "2",
                        "3",
                        "4"
                    ].includes(k)) return engineRef.current?.ability(Number(k) - 1);
                    if (k === " ") {
                        e.preventDefault();
                        return engineRef.current?.ability(0);
                    }
                    if (k === "tab") {
                        e.preventDefault();
                        return cycleTarget();
                    }
                    if (k === "g") return engineRef.current?.lootAllNearby();
                    if (k === "i") return setSheet({
                        "GamePlay.useEffect.down": (s)=>s === "bag" ? "none" : "bag"
                    }["GamePlay.useEffect.down"]);
                    if (k === "c") return setSheet({
                        "GamePlay.useEffect.down": (s)=>s === "gear" ? "none" : "gear"
                    }["GamePlay.useEffect.down"]);
                    if (k === "f") return setSheet({
                        "GamePlay.useEffect.down": (s)=>s === "filter" ? "none" : "filter"
                    }["GamePlay.useEffect.down"]);
                    held.add(k);
                    engineRef.current?.setHeld(dirFor());
                }
            }["GamePlay.useEffect.down"];
            const up = {
                "GamePlay.useEffect.up": (e)=>{
                    held.delete(e.key.toLowerCase());
                    engineRef.current?.setHeld(dirFor());
                }
            }["GamePlay.useEffect.up"];
            window.addEventListener("keydown", down);
            window.addEventListener("keyup", up);
            return ({
                "GamePlay.useEffect": ()=>{
                    window.removeEventListener("keydown", down);
                    window.removeEventListener("keyup", up);
                }
            })["GamePlay.useEffect"];
        }
    }["GamePlay.useEffect"], [
        started,
        markInput,
        cycleTarget
    ]);
    // The engine is a long-lived mutable object; it lives in state (not a ref) so
    // render may read it. Re-renders are driven by the rAF loop's `force` tick.
    const g = engine;
    const p = g?.player;
    // ------------------------------------------------------------------ gate
    if (!started) {
        return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
            className: "relative flex min-h-dvh flex-col items-center justify-center overflow-hidden bg-[#0b0d12] px-6 text-slate-100",
            children: [
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "pointer-events-none absolute inset-0 opacity-40 [background:radial-gradient(circle_at_30%_20%,#1e3a5f,transparent_55%),radial-gradient(circle_at_75%_75%,#4a2b3d,transparent_55%)]"
                }, void 0, false, {
                    fileName: "[project]/src/components/game/GamePlay.tsx",
                    lineNumber: 536,
                    columnNumber: 9
                }, this),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "relative w-full max-w-sm rounded-3xl border border-white/10 bg-black/50 p-6 backdrop-blur-xl",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                            className: "text-xs font-black uppercase tracking-[0.35em] text-amber-400",
                            children: "Remnants"
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 538,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h1", {
                            className: "mt-2 text-3xl font-black leading-tight",
                            children: "Enter the Hollow"
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 539,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                            className: "mt-2 text-sm text-slate-400",
                            children: "Mark a creature and it is struck every 2 seconds. Drag a creature to shove it one tile. Death costs 10% XP and half your carried gold."
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 540,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("label", {
                            className: "mt-6 block text-[11px] font-bold uppercase tracking-widest text-slate-400",
                            children: "Character name"
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 544,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("input", {
                            ref: nameFieldRef,
                            defaultValue: initialName,
                            onKeyDown: (e)=>e.key === "Enter" && boot(),
                            maxLength: 18,
                            placeholder: "Wanderer",
                            className: "mt-2 w-full rounded-xl border border-white/15 bg-white/5 px-4 py-3 text-lg font-bold outline-none focus:border-amber-400"
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 547,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                            onClick: boot,
                            className: "mt-4 w-full rounded-xl border-b-4 border-amber-700 bg-amber-500 px-4 py-3.5 text-base font-black uppercase tracking-wide text-black active:translate-y-0.5 active:border-b-2",
                            children: "Descend"
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 555,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "mt-4 grid grid-cols-2 gap-2 text-[11px] text-slate-500",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                    children: "📱 Tap to mark · drag creature to shove"
                                }, void 0, false, {
                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                    lineNumber: 562,
                                    columnNumber: 13
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                    children: "⌨️ WASD · 1-4 · Tab · G loot"
                                }, void 0, false, {
                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                    lineNumber: 563,
                                    columnNumber: 13
                                }, this)
                            ]
                        }, void 0, true, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 561,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["default"], {
                            href: "/",
                            className: "mt-4 block text-center text-xs text-slate-500 underline",
                            children: "Back to the design bible"
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 565,
                            columnNumber: 11
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/src/components/game/GamePlay.tsx",
                    lineNumber: 537,
                    columnNumber: 9
                }, this)
            ]
        }, void 0, true, {
            fileName: "[project]/src/components/game/GamePlay.tsx",
            lineNumber: 535,
            columnNumber: 7
        }, this);
    }
    const hpPct = p ? Math.max(0, p.hp / p.maxHp) : 1;
    const mpPct = p ? Math.max(0, p.mana / p.maxMana) : 1;
    const xpPct = g ? g.xpProgress() : 0;
    const region = p ? (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["regionAt"])(p.x, p.y) : null;
    const tgt = g?.target() ?? null;
    const fade = dim ? 0.32 : 1;
    const inPz = g?.inProtectedZone ?? false;
    const pushPct = g?.pushCooldownPct() ?? 0;
    const autoPct = g?.autoTickPct() ?? 0;
    const nearbyLoot = g ? g.visibleGround().filter((it)=>Math.max(Math.abs(it.x - g.player.x), Math.abs(it.y - g.player.y)) <= 1) : [];
    const equippable = inventory.filter((i)=>__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ITEMS"][i.itemKey]?.slot);
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        className: "relative h-dvh w-full select-none overflow-hidden bg-[#0b0d12] text-slate-100",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("canvas", {
                ref: canvasRef,
                onPointerDown: onPointerDown,
                onPointerMove: onPointerMove,
                onPointerUp: onPointerUp,
                onPointerCancel: ()=>{
                    dragRef.current = null;
                    engineRef.current?.clearPushPreview();
                },
                className: "absolute inset-0 h-full w-full touch-none"
            }, void 0, false, {
                fileName: "[project]/src/components/game/GamePlay.tsx",
                lineNumber: 591,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "pointer-events-none absolute left-3 top-3 w-56 max-w-[52vw]",
                style: {
                    opacity: fade,
                    transition: "opacity .5s ease"
                },
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "rounded-2xl border border-white/10 bg-black/55 p-2.5 backdrop-blur-md",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "flex items-center gap-2",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "grid h-9 w-9 shrink-0 place-items-center rounded-xl border-2 border-black/60 bg-gradient-to-b from-amber-300 to-amber-600 text-sm font-black text-black",
                                        children: p?.level ?? 1
                                    }, void 0, false, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 610,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "min-w-0 flex-1",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "truncate text-xs font-black uppercase tracking-wide",
                                                children: name
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 614,
                                                columnNumber: 15
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "mt-1 h-2.5 w-full overflow-hidden rounded-full bg-black/60",
                                                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                    className: "h-full rounded-full bg-gradient-to-r from-rose-600 to-rose-400 transition-[width] duration-150",
                                                    style: {
                                                        width: `${hpPct * 100}%`
                                                    }
                                                }, void 0, false, {
                                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                                    lineNumber: 616,
                                                    columnNumber: 17
                                                }, this)
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 615,
                                                columnNumber: 15
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "mt-1 h-2 w-full overflow-hidden rounded-full bg-black/60",
                                                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                    className: "h-full rounded-full bg-gradient-to-r from-sky-600 to-sky-400 transition-[width] duration-150",
                                                    style: {
                                                        width: `${mpPct * 100}%`
                                                    }
                                                }, void 0, false, {
                                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                                    lineNumber: 622,
                                                    columnNumber: 17
                                                }, this)
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 621,
                                                columnNumber: 15
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 613,
                                        columnNumber: 13
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 609,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "mt-1.5 h-1 w-full overflow-hidden rounded-full bg-black/60",
                                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "h-full rounded-full bg-lime-400",
                                    style: {
                                        width: `${xpPct * 100}%`
                                    }
                                }, void 0, false, {
                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                    lineNumber: 630,
                                    columnNumber: 13
                                }, this)
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 629,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "mt-1.5 flex items-center justify-between text-[10px] font-bold text-slate-400",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        children: [
                                            Math.max(0, Math.round(p?.hp ?? 0)),
                                            "/",
                                            p?.maxHp
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 633,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        className: "text-amber-300",
                                        children: [
                                            p?.gold ?? 0,
                                            "g"
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 636,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        className: "text-slate-300",
                                        children: [
                                            "🛡 ",
                                            loadout.armor
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 637,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        children: [
                                            p ? Math.max(0, (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["xpForLevel"])(p.level) - p.xp) : 0,
                                            " xp→"
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 638,
                                        columnNumber: 13
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 632,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/components/game/GamePlay.tsx",
                        lineNumber: 608,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "mt-1.5 flex flex-wrap gap-1.5",
                        children: [
                            inPz && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: "rounded-lg bg-amber-500/25 px-2 py-0.5 text-[10px] font-black uppercase text-amber-200",
                                children: "🕊 protected zone"
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 643,
                                columnNumber: 13
                            }, this),
                            loadout.heavy > 0 && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: "rounded-lg bg-slate-500/25 px-2 py-0.5 text-[10px] font-black uppercase text-slate-300",
                                children: [
                                    "⚓ ",
                                    (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["stepMsFor"])(loadout.heavy),
                                    "ms step"
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 648,
                                columnNumber: 13
                            }, this),
                            p?.statuses.map((s)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                    className: `rounded-lg px-2 py-0.5 text-[10px] font-black uppercase ${s.key === "poison" ? "bg-lime-500/25 text-lime-300" : s.key === "burn" ? "bg-orange-500/25 text-orange-300" : s.key === "ward" ? "bg-emerald-500/25 text-emerald-300" : "bg-sky-500/25 text-sky-300"}`,
                                    children: s.key
                                }, s.key, false, {
                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                    lineNumber: 653,
                                    columnNumber: 13
                                }, this))
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/components/game/GamePlay.tsx",
                        lineNumber: 641,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/components/game/GamePlay.tsx",
                lineNumber: 604,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "absolute right-3 top-3 flex flex-col items-end gap-2",
                style: {
                    opacity: fade,
                    transition: "opacity .5s ease"
                },
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "rounded-2xl border border-white/10 bg-black/55 p-1.5 backdrop-blur-md",
                        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("canvas", {
                            ref: miniRef,
                            width: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MAP_W"] * 3,
                            height: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["MAP_W"] * 3,
                            className: "h-[104px] w-[104px] rounded-xl"
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 677,
                            columnNumber: 11
                        }, this)
                    }, void 0, false, {
                        fileName: "[project]/src/components/game/GamePlay.tsx",
                        lineNumber: 676,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "rounded-xl border border-white/10 bg-black/55 px-2.5 py-1 text-right backdrop-blur-md",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                className: "text-[10px] font-black uppercase tracking-wider text-amber-300",
                                children: region?.name
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 680,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                className: "text-[9px] text-slate-400",
                                children: region?.levelBand
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 681,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/components/game/GamePlay.tsx",
                        lineNumber: 679,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "pointer-events-auto flex gap-1.5",
                        children: [
                            [
                                [
                                    "bag",
                                    "🎒"
                                ],
                                [
                                    "gear",
                                    "🧰"
                                ],
                                [
                                    "filter",
                                    "🔎"
                                ]
                            ].map(([s, glyph])=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                    onClick: ()=>{
                                        markInput();
                                        setSheet((cur)=>cur === s ? "none" : s);
                                    },
                                    className: `rounded-xl border px-2.5 py-1.5 text-xs font-bold backdrop-blur-md active:scale-95 ${sheet === s ? "border-amber-400 bg-amber-500/25" : "border-white/15 bg-black/55"}`,
                                    children: glyph
                                }, s, false, {
                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                    lineNumber: 691,
                                    columnNumber: 13
                                }, this)),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["default"], {
                                href: "/",
                                className: "rounded-xl border border-white/15 bg-black/55 px-2.5 py-1.5 text-xs font-bold backdrop-blur-md active:scale-95",
                                children: "✕"
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 704,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/components/game/GamePlay.tsx",
                        lineNumber: 683,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/components/game/GamePlay.tsx",
                lineNumber: 672,
                columnNumber: 7
            }, this),
            tgt && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "pointer-events-none absolute left-1/2 top-3 w-56 -translate-x-1/2",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "rounded-2xl border border-rose-500/40 bg-black/65 px-3 py-2 backdrop-blur-md",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "flex items-center justify-between text-[11px] font-black uppercase",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                    children: [
                                        tgt.def.glyph,
                                        " ",
                                        tgt.def.name
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                    lineNumber: 718,
                                    columnNumber: 15
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                    className: "text-rose-300",
                                    children: Math.max(0, tgt.hp)
                                }, void 0, false, {
                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                    lineNumber: 721,
                                    columnNumber: 15
                                }, this)
                            ]
                        }, void 0, true, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 717,
                            columnNumber: 13
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "mt-1 h-2 overflow-hidden rounded-full bg-black/60",
                            children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "h-full bg-gradient-to-r from-rose-600 to-rose-400",
                                style: {
                                    width: `${Math.max(0, tgt.hp / tgt.maxHp * 100)}%`
                                }
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 724,
                                columnNumber: 15
                            }, this)
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 723,
                            columnNumber: 13
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "mt-1.5 flex items-center gap-1.5",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                    className: "text-[9px] font-black uppercase tracking-wider text-slate-400",
                                    children: autoAttack ? "tick" : "auto off"
                                }, void 0, false, {
                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                    lineNumber: 731,
                                    columnNumber: 15
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "h-1.5 flex-1 overflow-hidden rounded-full bg-black/60",
                                    children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "h-full rounded-full bg-orange-400",
                                        style: {
                                            width: `${autoPct * 100}%`
                                        }
                                    }, void 0, false, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 735,
                                        columnNumber: 17
                                    }, this)
                                }, void 0, false, {
                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                    lineNumber: 734,
                                    columnNumber: 15
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                    className: "text-[9px] font-black text-orange-300",
                                    children: [
                                        (__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["COMBAT"].AUTO_ATTACK_MS / 1000).toFixed(0),
                                        "s"
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                    lineNumber: 740,
                                    columnNumber: 15
                                }, this)
                            ]
                        }, void 0, true, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 730,
                            columnNumber: 13
                        }, this),
                        g && g.now < tgt.windupUntil && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                            className: "mt-1 animate-pulse text-[10px] font-black uppercase tracking-widest text-amber-300",
                            children: "⚠ winding up — move or shove"
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 745,
                            columnNumber: 15
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/src/components/game/GamePlay.tsx",
                    lineNumber: 716,
                    columnNumber: 11
                }, this)
            }, void 0, false, {
                fileName: "[project]/src/components/game/GamePlay.tsx",
                lineNumber: 715,
                columnNumber: 9
            }, this),
            banner && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "pointer-events-none absolute left-1/2 top-1/3 -translate-x-1/2 text-center",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                    className: "animate-pulse text-3xl font-black uppercase tracking-[0.2em] text-amber-300 drop-shadow-[0_4px_0_rgba(0,0,0,0.8)]",
                    children: banner
                }, void 0, false, {
                    fileName: "[project]/src/components/game/GamePlay.tsx",
                    lineNumber: 755,
                    columnNumber: 11
                }, this)
            }, void 0, false, {
                fileName: "[project]/src/components/game/GamePlay.tsx",
                lineNumber: 754,
                columnNumber: 9
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "pointer-events-none absolute left-3 top-44 flex w-56 flex-col gap-1.5",
                children: toasts.map((t)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: `rounded-xl border px-2.5 py-1.5 text-[11px] font-bold backdrop-blur-md ${t.tone === "good" ? "border-lime-500/40 bg-lime-950/70 text-lime-200" : t.tone === "bad" ? "border-rose-500/40 bg-rose-950/70 text-rose-200" : "border-white/15 bg-black/60 text-slate-200"}`,
                        children: t.text
                    }, t.id, false, {
                        fileName: "[project]/src/components/game/GamePlay.tsx",
                        lineNumber: 763,
                        columnNumber: 11
                    }, this))
            }, void 0, false, {
                fileName: "[project]/src/components/game/GamePlay.tsx",
                lineNumber: 761,
                columnNumber: 7
            }, this),
            deathCard && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "pointer-events-none absolute inset-0 grid place-items-center bg-rose-950/35 backdrop-blur-[2px]",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "w-72 rounded-3xl border-2 border-rose-600/60 bg-black/85 p-5 text-center",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                            className: "text-4xl",
                            children: "💀"
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 781,
                            columnNumber: 13
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                            className: "mt-1 text-2xl font-black uppercase tracking-widest text-rose-400",
                            children: "You died"
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 782,
                            columnNumber: 13
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                            className: "mt-1 text-xs text-slate-400",
                            children: [
                                "Slain by ",
                                deathCard.killedBy
                            ]
                        }, void 0, true, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 783,
                            columnNumber: 13
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "mt-4 grid grid-cols-2 gap-2 text-xs",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "rounded-xl bg-white/5 p-2",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                            className: "font-black text-rose-300",
                                            children: [
                                                "-",
                                                deathCard.xpLost
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/src/components/game/GamePlay.tsx",
                                            lineNumber: 786,
                                            columnNumber: 17
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                            className: "text-[10px] uppercase text-slate-500",
                                            children: "experience"
                                        }, void 0, false, {
                                            fileName: "[project]/src/components/game/GamePlay.tsx",
                                            lineNumber: 787,
                                            columnNumber: 17
                                        }, this)
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                    lineNumber: 785,
                                    columnNumber: 15
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "rounded-xl bg-white/5 p-2",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                            className: "font-black text-amber-300",
                                            children: [
                                                "-",
                                                deathCard.gold,
                                                "g"
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/src/components/game/GamePlay.tsx",
                                            lineNumber: 790,
                                            columnNumber: 17
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                            className: "text-[10px] uppercase text-slate-500",
                                            children: "dropped"
                                        }, void 0, false, {
                                            fileName: "[project]/src/components/game/GamePlay.tsx",
                                            lineNumber: 791,
                                            columnNumber: 17
                                        }, this)
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                    lineNumber: 789,
                                    columnNumber: 15
                                }, this)
                            ]
                        }, void 0, true, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 784,
                            columnNumber: 13
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                            className: "mt-3 text-[11px] leading-relaxed text-slate-500",
                            children: "Your gold is on the floor, locked to you for 60 seconds. After that anyone may take it."
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 794,
                            columnNumber: 13
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/src/components/game/GamePlay.tsx",
                    lineNumber: 780,
                    columnNumber: 11
                }, this)
            }, void 0, false, {
                fileName: "[project]/src/components/game/GamePlay.tsx",
                lineNumber: 779,
                columnNumber: 9
            }, this),
            sheet !== "none" && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "absolute inset-x-0 bottom-0 z-20 max-h-[62dvh] overflow-y-auto rounded-t-3xl border-t border-white/15 bg-[#12141c]/96 p-4 backdrop-blur-xl",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "mb-3 flex items-center justify-between",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                                className: "text-sm font-black uppercase tracking-widest",
                                children: sheet === "bag" ? "Satchel" : sheet === "gear" ? "Equipment" : "Loot filter"
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 805,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                onClick: ()=>setSheet("none"),
                                className: "rounded-lg bg-white/10 px-3 py-1 text-xs font-bold",
                                children: "Close"
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 808,
                                columnNumber: 13
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/components/game/GamePlay.tsx",
                        lineNumber: 804,
                        columnNumber: 11
                    }, this),
                    sheet === "bag" && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["Fragment"], {
                        children: [
                            inventory.length === 0 ? /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                className: "text-xs text-slate-500",
                                children: "Empty. Kill something — loot scatters over the 3×3 around the corpse."
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 819,
                                columnNumber: 17
                            }, this) : /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "grid grid-cols-4 gap-2 sm:grid-cols-6",
                                children: inventory.map((it)=>{
                                    const def = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ITEMS"][it.itemKey];
                                    const usable = it.itemKey === "salve" || it.itemKey === "mana_draught";
                                    const wearable = Boolean(def?.slot);
                                    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        disabled: !usable && !wearable,
                                        onClick: ()=>usable ? drinkItem(it.itemKey) : changeGear("equip", {
                                                itemKey: it.itemKey
                                            }),
                                        className: `rounded-xl border p-2 text-center ${usable ? "border-emerald-500/40 bg-emerald-500/10 active:scale-95" : wearable ? "border-sky-500/40 bg-sky-500/10 active:scale-95" : "border-white/10 bg-white/5"}`,
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "text-xl",
                                                children: it.glyph
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 843,
                                                columnNumber: 25
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "mt-0.5 truncate text-[10px] font-bold",
                                                children: it.name
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 844,
                                                columnNumber: 25
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "text-[10px] text-amber-300",
                                                children: [
                                                    "x",
                                                    it.qty
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 845,
                                                columnNumber: 25
                                            }, this),
                                            usable && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "text-[9px] font-black uppercase text-emerald-300",
                                                children: "use"
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 846,
                                                columnNumber: 36
                                            }, this),
                                            wearable && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "text-[9px] font-black uppercase text-sky-300",
                                                children: "equip"
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 847,
                                                columnNumber: 38
                                            }, this)
                                        ]
                                    }, it.itemKey, true, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 829,
                                        columnNumber: 23
                                    }, this);
                                })
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 823,
                                columnNumber: 17
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["default"], {
                                href: "/market",
                                className: "mt-3 block rounded-xl border-b-4 border-amber-700 bg-amber-500 py-2.5 text-center text-xs font-black uppercase text-black",
                                children: "Take it to the market"
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 853,
                                columnNumber: 15
                            }, this)
                        ]
                    }, void 0, true),
                    sheet === "gear" && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["Fragment"], {
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "mb-3 grid grid-cols-3 gap-2",
                                children: [
                                    [
                                        "Armor",
                                        `${loadout.armor}`,
                                        "flat physical reduction",
                                        "text-sky-300"
                                    ],
                                    [
                                        "Weapon",
                                        `+${loadout.weaponDamage}`,
                                        "added to every tick",
                                        "text-orange-300"
                                    ],
                                    [
                                        "Step",
                                        `${(0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["stepMsFor"])(loadout.heavy)}ms`,
                                        `${loadout.heavy} encumbrance`,
                                        "text-lime-300"
                                    ]
                                ].map(([k, v, sub, c])=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "rounded-2xl border border-white/10 bg-white/5 p-3 text-center",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: `text-xl font-black ${c}`,
                                                children: v
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 871,
                                                columnNumber: 21
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "text-[10px] font-black uppercase tracking-wider text-slate-300",
                                                children: k
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 872,
                                                columnNumber: 21
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "text-[9px] text-slate-500",
                                                children: sub
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 873,
                                                columnNumber: 21
                                            }, this)
                                        ]
                                    }, k, true, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 870,
                                        columnNumber: 19
                                    }, this))
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 864,
                                columnNumber: 15
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "grid grid-cols-4 gap-2",
                                children: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["EQUIP_SLOTS"].map((s)=>{
                                    const key = equipped[s.key];
                                    const def = key ? __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ITEMS"][key] : null;
                                    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        onClick: ()=>def && changeGear("unequip", {
                                                slot: s.key
                                            }),
                                        className: `rounded-xl border p-2 text-center ${def ? "border-amber-400/50 bg-amber-500/10 active:scale-95" : "border-dashed border-white/15 bg-white/[0.03]"}`,
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "text-xl",
                                                children: def?.glyph ?? s.glyph
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 891,
                                                columnNumber: 23
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "mt-0.5 truncate text-[10px] font-bold",
                                                children: def?.name ?? s.label
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 892,
                                                columnNumber: 23
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "text-[9px] text-slate-500",
                                                children: def ? `🛡${def.armor ?? 0} ⚓${def.heavy ?? 0}` : "empty"
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 893,
                                                columnNumber: 23
                                            }, this)
                                        ]
                                    }, s.key, true, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 882,
                                        columnNumber: 21
                                    }, this);
                                })
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 877,
                                columnNumber: 15
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                className: "mt-3 text-[11px] text-slate-500",
                                children: [
                                    "Armour is ",
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                        className: "text-slate-300",
                                        children: "flat"
                                    }, void 0, false, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 901,
                                        columnNumber: 27
                                    }, this),
                                    ": a 17-damage Ember Husk hits for ",
                                    Math.max(1, 17 - loadout.armor),
                                    " against your current ",
                                    loadout.armor,
                                    " armour. Tap a slot to unequip."
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 900,
                                columnNumber: 15
                            }, this),
                            equippable.length > 0 && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["Fragment"], {
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "mt-4 text-[10px] font-black uppercase tracking-widest text-slate-400",
                                        children: "In satchel"
                                    }, void 0, false, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 907,
                                        columnNumber: 19
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "mt-2 grid grid-cols-4 gap-2 sm:grid-cols-6",
                                        children: equippable.map((it)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                                onClick: ()=>changeGear("equip", {
                                                        itemKey: it.itemKey
                                                    }),
                                                className: "rounded-xl border border-sky-500/40 bg-sky-500/10 p-2 text-center active:scale-95",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                        className: "text-xl",
                                                        children: it.glyph
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                                        lineNumber: 917,
                                                        columnNumber: 25
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                        className: "mt-0.5 truncate text-[10px] font-bold",
                                                        children: it.name
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                                        lineNumber: 918,
                                                        columnNumber: 25
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                        className: "text-[9px] text-slate-500",
                                                        children: [
                                                            "🛡",
                                                            __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ITEMS"][it.itemKey]?.armor ?? 0,
                                                            " ⚓",
                                                            __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ITEMS"][it.itemKey]?.heavy ?? 0
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                                        lineNumber: 919,
                                                        columnNumber: 25
                                                    }, this)
                                                ]
                                            }, it.itemKey, true, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 912,
                                                columnNumber: 23
                                            }, this))
                                    }, void 0, false, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 910,
                                        columnNumber: 19
                                    }, this)
                                ]
                            }, void 0, true)
                        ]
                    }, void 0, true),
                    sheet === "filter" && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["Fragment"], {
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "mb-3 grid grid-cols-2 gap-2",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        onClick: ()=>{
                                            const v = !autoPickup;
                                            setAutoPickup(v);
                                            saveSettings({
                                                autoPickup: v
                                            });
                                            haptic(12);
                                        },
                                        className: `rounded-2xl border p-3 text-left ${autoPickup ? "border-emerald-500/50 bg-emerald-500/15" : "border-white/15 bg-white/5"}`,
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "text-xs font-black uppercase tracking-wider",
                                                children: [
                                                    "Auto pick-up ",
                                                    autoPickup ? "ON" : "OFF"
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 944,
                                                columnNumber: 19
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "mt-0.5 text-[10px] text-slate-400",
                                                children: "Walk over a tile to take filtered loot you own."
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 947,
                                                columnNumber: 19
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 933,
                                        columnNumber: 17
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        onClick: ()=>{
                                            const v = !autoAttack;
                                            setAutoAttack(v);
                                            saveSettings({
                                                autoAttack: v
                                            });
                                            haptic(12);
                                        },
                                        className: `rounded-2xl border p-3 text-left ${autoAttack ? "border-orange-500/50 bg-orange-500/15" : "border-white/15 bg-white/5"}`,
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "text-xs font-black uppercase tracking-wider",
                                                children: [
                                                    "Auto attack ",
                                                    autoAttack ? "ON" : "OFF"
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 962,
                                                columnNumber: 19
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "mt-0.5 text-[10px] text-slate-400",
                                                children: "Marked creatures are struck every 2s."
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 965,
                                                columnNumber: 19
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 951,
                                        columnNumber: 17
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 932,
                                columnNumber: 15
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "mb-2 flex gap-2",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        onClick: ()=>{
                                            const all = Object.keys(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ITEMS"]);
                                            setLootFilter(all);
                                            saveSettings({
                                                lootFilter: all
                                            });
                                        },
                                        className: "rounded-lg bg-white/10 px-3 py-1 text-[10px] font-black uppercase",
                                        children: "All"
                                    }, void 0, false, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 971,
                                        columnNumber: 17
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        onClick: ()=>{
                                            setLootFilter([
                                                "gold"
                                            ]);
                                            saveSettings({
                                                lootFilter: [
                                                    "gold"
                                                ]
                                            });
                                        },
                                        className: "rounded-lg bg-white/10 px-3 py-1 text-[10px] font-black uppercase",
                                        children: "Gold only"
                                    }, void 0, false, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 981,
                                        columnNumber: 17
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        onClick: ()=>{
                                            setLootFilter(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["DEFAULT_LOOT_FILTER"]);
                                            saveSettings({
                                                lootFilter: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["DEFAULT_LOOT_FILTER"]
                                            });
                                        },
                                        className: "rounded-lg bg-white/10 px-3 py-1 text-[10px] font-black uppercase",
                                        children: "Recommended"
                                    }, void 0, false, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 990,
                                        columnNumber: 17
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 970,
                                columnNumber: 15
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                className: "mb-2 text-[11px] text-slate-500",
                                children: [
                                    "Unchecked items are ",
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                        className: "text-slate-300",
                                        children: "invisible on the floor"
                                    }, void 0, false, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 1001,
                                        columnNumber: 37
                                    }, this),
                                    " — they are not drawn, not tappable and skipped by auto pick-up. This is the single biggest readability lever on a phone screen."
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 1000,
                                columnNumber: 15
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "grid grid-cols-2 gap-1.5 sm:grid-cols-3",
                                children: Object.values(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ITEMS"]).map((it)=>{
                                    const on = lootFilter.includes(it.key);
                                    const r = __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["RARITY_STYLES"][it.rarity];
                                    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        onClick: ()=>toggleFilter(it.key),
                                        className: `flex items-center gap-2 rounded-xl border px-2.5 py-2 text-left ${on ? `border-white/20 ${r.bg}` : "border-white/10 bg-black/40 opacity-45"}`,
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "text-lg",
                                                children: it.glyph
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 1017,
                                                columnNumber: 23
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: `min-w-0 flex-1 truncate text-[11px] font-bold ${r.text}`,
                                                children: it.name
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 1018,
                                                columnNumber: 23
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: `grid h-4 w-4 shrink-0 place-items-center rounded border text-[9px] font-black ${on ? "border-emerald-400 bg-emerald-400 text-black" : "border-slate-600 text-transparent"}`,
                                                children: "✓"
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 1021,
                                                columnNumber: 23
                                            }, this)
                                        ]
                                    }, it.key, true, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 1010,
                                        columnNumber: 21
                                    }, this);
                                })
                            }, void 0, false, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 1005,
                                columnNumber: 15
                            }, this)
                        ]
                    }, void 0, true)
                ]
            }, void 0, true, {
                fileName: "[project]/src/components/game/GamePlay.tsx",
                lineNumber: 803,
                columnNumber: 9
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "pointer-events-none absolute inset-x-0 bottom-0 flex items-end justify-between p-4 pb-[max(1rem,env(safe-area-inset-bottom))]",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        onPointerDown: markInput,
                        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$components$2f$game$2f$Joystick$2e$tsx__$5b$app$2d$client$5d$__$28$ecmascript$29$__["default"], {
                            onDir: (d)=>{
                                engineRef.current?.setHeld(d);
                                if (d) markInput();
                            },
                            dim: dim
                        }, void 0, false, {
                            fileName: "[project]/src/components/game/GamePlay.tsx",
                            lineNumber: 1040,
                            columnNumber: 11
                        }, this)
                    }, void 0, false, {
                        fileName: "[project]/src/components/game/GamePlay.tsx",
                        lineNumber: 1039,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "pointer-events-auto grid grid-cols-2 gap-2.5",
                        style: {
                            opacity: dim ? 0.55 : 1,
                            transition: "opacity .45s ease"
                        },
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "col-span-2 flex gap-2",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        onPointerDown: (e)=>{
                                            e.preventDefault();
                                            markInput();
                                            cycleTarget();
                                        },
                                        className: "h-11 flex-1 rounded-2xl border-2 border-black/50 bg-slate-700/80 text-[11px] font-black uppercase tracking-widest text-slate-100 backdrop-blur-sm active:scale-95",
                                        children: "🎯 Mark"
                                    }, void 0, false, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 1054,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        onPointerDown: (e)=>{
                                            e.preventDefault();
                                            markInput();
                                            engineRef.current?.lootAllNearby();
                                            haptic(12);
                                        },
                                        className: `relative h-11 flex-1 overflow-hidden rounded-2xl border-2 border-black/50 text-[11px] font-black uppercase tracking-widest backdrop-blur-sm active:scale-95 ${nearbyLoot.length ? "bg-amber-500/85 text-black" : "bg-slate-700/80 text-slate-300"}`,
                                        children: [
                                            "✦ Loot",
                                            nearbyLoot.length ? ` ${nearbyLoot.length}` : ""
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 1064,
                                        columnNumber: 13
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 1053,
                                columnNumber: 11
                            }, this),
                            __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["ABILITIES"].map((a, i)=>{
                                const cd = g?.cooldownPct(a.key) ?? 0;
                                const noMana = (p?.mana ?? 0) < a.manaCost;
                                return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                    onPointerDown: (e)=>{
                                        e.preventDefault();
                                        markInput();
                                        engineRef.current?.ability(i);
                                        haptic(cd > 0 || noMana ? 6 : 16);
                                    },
                                    className: `relative grid h-[68px] w-[68px] place-items-center overflow-hidden rounded-2xl border-2 border-black/60 text-2xl active:translate-y-1 ${noMana ? "bg-slate-700/70" : "bg-gradient-to-b from-slate-200 to-slate-400"}`,
                                    style: {
                                        boxShadow: `0 5px 0 rgba(0,0,0,.5), inset 0 0 0 3px ${a.color}55`
                                    },
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                            className: noMana ? "opacity-40" : "",
                                            children: a.glyph
                                        }, void 0, false, {
                                            fileName: "[project]/src/components/game/GamePlay.tsx",
                                            lineNumber: 1097,
                                            columnNumber: 17
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                            className: "absolute bottom-0.5 right-1 text-[9px] font-black text-sky-900",
                                            children: a.manaCost > 0 ? a.manaCost : ""
                                        }, void 0, false, {
                                            fileName: "[project]/src/components/game/GamePlay.tsx",
                                            lineNumber: 1098,
                                            columnNumber: 17
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                            className: "absolute left-1 top-0.5 text-[9px] font-black text-black/50",
                                            children: i + 1
                                        }, void 0, false, {
                                            fileName: "[project]/src/components/game/GamePlay.tsx",
                                            lineNumber: 1101,
                                            columnNumber: 17
                                        }, this),
                                        cd > 0 && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                            className: "pointer-events-none absolute inset-x-0 bottom-0 bg-black/65",
                                            style: {
                                                height: `${cd * 100}%`
                                            }
                                        }, void 0, false, {
                                            fileName: "[project]/src/components/game/GamePlay.tsx",
                                            lineNumber: 1103,
                                            columnNumber: 19
                                        }, this)
                                    ]
                                }, a.key, true, {
                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                    lineNumber: 1084,
                                    columnNumber: 15
                                }, this);
                            }),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "col-span-2 rounded-xl border border-white/10 bg-black/55 px-2 py-1 backdrop-blur-md",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "flex items-center gap-1.5",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "text-[9px] font-black uppercase tracking-wider text-slate-400",
                                                children: "✋ shove"
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 1114,
                                                columnNumber: 15
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "h-1.5 flex-1 overflow-hidden rounded-full bg-black/60",
                                                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                    className: "h-full rounded-full bg-cyan-400",
                                                    style: {
                                                        width: `${(1 - pushPct) * 100}%`
                                                    }
                                                }, void 0, false, {
                                                    fileName: "[project]/src/components/game/GamePlay.tsx",
                                                    lineNumber: 1118,
                                                    columnNumber: 17
                                                }, this)
                                            }, void 0, false, {
                                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                                lineNumber: 1117,
                                                columnNumber: 15
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 1113,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "mt-0.5 text-center text-[8px] uppercase tracking-wider text-slate-500",
                                        children: "drag a creature 1 tile"
                                    }, void 0, false, {
                                        fileName: "[project]/src/components/game/GamePlay.tsx",
                                        lineNumber: 1124,
                                        columnNumber: 13
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/components/game/GamePlay.tsx",
                                lineNumber: 1112,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/components/game/GamePlay.tsx",
                        lineNumber: 1049,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/components/game/GamePlay.tsx",
                lineNumber: 1038,
                columnNumber: 7
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/src/components/game/GamePlay.tsx",
        lineNumber: 590,
        columnNumber: 5
    }, this);
}
_s(GamePlay, "LJylnShKgMypkDR9yS3WGZLJF/8=");
_c = GamePlay;
var _c;
__turbopack_context__.k.register(_c, "GamePlay");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
]);

//# sourceMappingURL=src_0mr7eoc._.js.map