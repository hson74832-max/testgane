module.exports = [
"[externals]/next/dist/shared/lib/no-fallback-error.external.js [external] (next/dist/shared/lib/no-fallback-error.external.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/shared/lib/no-fallback-error.external.js", () => require("next/dist/shared/lib/no-fallback-error.external.js"));

module.exports = mod;
}),
"[project]/src/lib/design.ts [app-rsc] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "COMBAT_LOOP",
    ()=>COMBAT_LOOP,
    "OPEN_ISSUES",
    ()=>OPEN_ISSUES,
    "PILLARS",
    ()=>PILLARS,
    "RISKS",
    ()=>RISKS,
    "ROADMAP",
    ()=>ROADMAP,
    "SYSTEMS",
    ()=>SYSTEMS,
    "UX_SPECS",
    ()=>UX_SPECS
]);
const PILLARS = [
    {
        id: "stakes",
        icon: "💀",
        title: "Deliberate Pacing & Real Stakes",
        tag: "The tick is the floor, your hands are the ceiling",
        accent: "from-rose-500 to-orange-500",
        body: "Marking a creature starts a 2-second auto-attack tick — a slow, legible metronome that keeps the fight alive without demanding a tap per swing. Everything above that baseline is manual: abilities, footwork, and the shove. Two seconds is deliberately long. It is a rhythm you fight around, not a DPS engine that plays for you. Death removes 10% of experience and half of carried gold.",
        rules: [
            "Auto-attack fires every 2000ms on a Marked creature, melee reach only",
            "A manual ability resets the tick — skilled play is strictly faster",
            "Grid-locked movement at a 205ms base step cadence, slowed by armour",
            "Death: −10% XP, −50% carried gold, gold drops on the floor"
        ]
    },
    {
        id: "clarity",
        icon: "👁️",
        title: "Visual Readability Above All",
        tag: "Read the floor, not the monster",
        accent: "from-amber-400 to-yellow-500",
        body: "Danger is communicated by painting the ground. Every hostile action projects a coloured tile zone with a rising fill-bar showing time-to-impact. Player abilities telegraph identically, so PvP is symmetrical and legible. Silhouettes are chunky, outlined, and colour-coded per faction.",
        rules: [
            "100% of incoming damage is floor-telegraphed before it lands",
            "Wind-up length scales with damage: 520ms rat → 1150ms wraith",
            "Status effects are pips above the head, never buried in a menu",
            "One glance rule: a 0.4s glance must convey HP, threat and escape route"
        ]
    },
    {
        id: "mobile",
        icon: "📱",
        title: "Mobile-First, Not Mobile-Ported",
        tag: "Thumbs first, mouse second",
        accent: "from-sky-400 to-cyan-500",
        body: "The bottom 38% of the screen is thumb territory: floating stick on the left, four 68pt action pads on the right. Everything else lives in the top 25% and fades to 32% opacity after 3.8 seconds of no input, so the world is never occluded during a fight. Desktop gets keyboard parity, never a different game.",
        rules: [
            "Minimum 68×68pt touch targets, 10pt gutters",
            "HUD auto-dims after 3.8s idle, instant restore on any input",
            "Haptics: 14ms tick on hit, 45ms thud on heavy damage, double-pulse on death",
            "Safe-area aware; nothing under a notch or home indicator"
        ]
    },
    {
        id: "economy",
        icon: "⚖️",
        title: "Player-Driven Economy",
        tag: "Every item has a human on both ends",
        accent: "from-emerald-400 to-teal-500",
        body: "No vendor sells gear. No shop generates items. Every object on the market was pulled off a corpse by a player who risked losing it on the way home. Gold enters through monster drops and leaves through a 5% market tax and death drops — the only two levers we tune against inflation.",
        rules: [
            "Zero NPC gear vendors — 100% player-listed supply",
            "5% transaction tax is the primary gold sink",
            "Death drops re-inject high-value goods into circulation",
            "Regional risk maps directly to material scarcity and price floor"
        ]
    }
];
const COMBAT_LOOP = [
    {
        step: "01",
        name: "Mark",
        ms: "one tap",
        text: "Tap the creature. A reticle locks on and an orange arc begins filling. That arc is the 2-second auto-attack tick."
    },
    {
        step: "02",
        name: "Read",
        ms: "520–1150ms",
        text: "The creature swells and the floor it will hit lights up with a rising fill bar. You know the shape and the deadline."
    },
    {
        step: "03",
        name: "Step, Shove or Commit",
        ms: "205ms+/tile",
        text: "Three answers to a telegraph: walk out, shove the creature out (cancelling its wind-up), or eat it behind armour and keep swinging."
    },
    {
        step: "04",
        name: "Resolve",
        ms: "instant",
        text: "Damage pops with the flat armour reduction shown inline — '11 (-6)'. Dodges print grey so a miss is legible too."
    },
    {
        step: "05",
        name: "Claim",
        ms: "60s window",
        text: "Loot scatters across the 3×3 around the corpse, locked to the top damage dealer for 60 seconds. Your filter decides what you even see."
    },
    {
        step: "06",
        name: "Bank It",
        ms: "the long walk",
        text: "Carrying it home is the real risk window — and the only reason the market has supply."
    }
];
const SYSTEMS = [
    {
        id: "tick",
        icon: "⏱️",
        title: "The 2-second tick",
        accent: "border-orange-500/40",
        summary: "Marking a creature starts an auto-attack that lands every 2000ms while you are within melee reach.",
        detail: "The original slice had no automation at all, and playtests showed the obvious mobile problem: keeping a thumb on an attack pad means you cannot also read the floor. The tick solves it by moving the baseline damage off the thumb, and it stays honest by being slow. Two seconds is roughly one telegraph window — you always have time to act between ticks.",
        rules: [
            "Melee reach only (1 tile). Out of range, the tick holds at full and fires the instant you close.",
            "Any manual ability resets the tick to zero — pressing buttons is always the higher-DPS play.",
            "Tick damage = 6 + floor(level × 0.9) + weapon damage.",
            "Rendered as a solid arc on the target reticle and a bar on the target plate.",
            "Toggleable per account. Off is a valid, higher-skill way to play."
        ]
    },
    {
        id: "shove",
        icon: "✋",
        title: "Shove — drag to displace",
        accent: "border-cyan-500/40",
        summary: "Hold on an adjacent creature, drag one tile, release. The creature is pushed and its wind-up is cancelled.",
        detail: "Shove is the answer to the 'nowhere to run' problem in a grid game. Instead of only moving yourself, you can move the board. Crucially it interrupts a telegraph in progress, which makes it a defensive cooldown with a positional payoff: shove a Grave Wraith out of its own 3×3 bloom and you have both dodged and repositioned it for a Cleave.",
        rules: [
            "Same gesture on both platforms: touch drag, or mouse hold-left-click and release.",
            "Exactly 1 tile. Destination must be walkable, unoccupied and not inside the Sanctuary.",
            "You must be adjacent to the creature. 2.5s cooldown; creature is braced for 1.2s after.",
            "Cancels an in-progress wind-up and deletes the telegraph — the whole reason it exists.",
            "A live arrow preview paints the destination cyan (valid) or red (invalid) before you release."
        ]
    },
    {
        id: "armor",
        icon: "🛡️",
        title: "Gear slots & flat armour",
        accent: "border-sky-500/40",
        summary: "Eight slots. Armour rating is the sum of equipped pieces and reduces physical damage by a flat value.",
        detail: "Percentage mitigation is unreadable on a phone — nobody computes 23% of 17 mid-telegraph. Flat mitigation is arithmetic a player does automatically: 17 damage against 6 armour is 11, every single time. That predictability is what lets a player decide to eat a hit rather than dodge it, which is the decision that makes armour interesting.",
        rules: [
            "Slots: head, neck, chest, weapon, off-hand, legs, feet, ring.",
            "damage = max(1, raw − armour). Armour can never fully negate a hit.",
            "Damage numbers show the reduction inline: '11 (-6)'.",
            "Heavy armour adds encumbrance: +5ms per point to the grid step, capped at +90ms.",
            "Ember Plate is 12 armour and 8 encumbrance — best mitigation, worst footwork."
        ]
    },
    {
        id: "loot",
        icon: "✦",
        title: "Loot: spread, claim, filter",
        accent: "border-amber-500/40",
        summary: "Drops scatter over 1 sqm, lock to the top damage dealer for 60 seconds, and are hidden entirely if your filter excludes them.",
        detail: "Three separate problems solved by three separate rules. Spread stops a nine-item drop becoming an unreadable pile on one 44px tile. The 60-second claim stops the highest-level player in the zone from stealing every kill they did not earn. The filter is the mobile clarity valve: if you are farming Grave Silk, sewer pelts should not be drawn on your screen at all.",
        rules: [
            "Drops distribute across the walkable 3×3 around the corpse, corpse tile first.",
            "Top damage dealer holds an exclusive 60s claim; a lock icon and countdown arc render on the stack.",
            "After 60s the stack is free for anyone. Ground items decay after 3 minutes.",
            "Filtered-out items are not drawn, not tappable, and skipped by auto pick-up.",
            "Auto pick-up takes claimable, filtered loot the moment you step onto its tile."
        ]
    },
    {
        id: "pz",
        icon: "🕊️",
        title: "Protected zones",
        accent: "border-emerald-500/40",
        summary: "Inside a Protected Zone creatures cannot land damage and PvP is hard-blocked. You may still attack out.",
        detail: "The Sanctuary is the only place in the world where the risk system switches off, and it has to be absolute: any ambiguity about whether you are safe makes banking loot feel like a gamble rather than a reward. Note the deliberate asymmetry requested for the slice — you can attack out of a PZ but nothing can attack in.",
        rules: [
            "Creatures may not path into a PZ and may not resolve damage against a player inside one.",
            "PvP attacks are rejected outright inside a PZ. No exceptions, no flagging.",
            "You may attack creatures standing outside the PZ from within it.",
            "Shoving a creature into a PZ is blocked — otherwise it becomes an untouchable-mob exploit.",
            "The zone border is drawn as a dashed gold ring, labelled, and shown on the HUD."
        ]
    }
];
const OPEN_ISSUES = [
    {
        title: "PZ safe-spotting is currently exploitable",
        body: "Attack-out / no-attack-in means a player can stand on the Sanctuary border and freely kill anything that wanders adjacent. Shipping mitigation: creatures leash and disengage after 4 seconds of being unable to reach their attacker, and regenerate to full. Implemented in the slice: creatures will not path adjacent to the PZ, and cannot be shoved into it."
    },
    {
        title: "Auto-attack weakens the anti-bot argument",
        body: "A 2s tick is trivially automatable, so combat is no longer inherently bot-hostile. The load moves to telegraph dodging and shove usage — telemetry now flags accounts with abnormally low damage-taken-per-hour alongside high tick counts."
    },
    {
        title: "Loot filters hide items from the economy",
        body: "If most players filter out common materials, those materials stop entering the market and low-level crafting stalls. We watch the ratio of dropped-to-collected per item and adjust drop rates, not filters — the filter must stay a pure player-clarity tool."
    }
];
const UX_SPECS = [
    {
        k: "Target frame rate",
        v: "60fps on iPhone 11 / Snapdragon 720G"
    },
    {
        k: "Cold start to input",
        v: "< 4.0s"
    },
    {
        k: "Session shape",
        v: "3–7 min loops, resumable mid-fight"
    },
    {
        k: "Portrait / landscape",
        v: "Both; HUD reflows, world scale constant"
    },
    {
        k: "Touch target minimum",
        v: "68pt (Apple HIG +30%)"
    },
    {
        k: "Idle HUD fade",
        v: "3.8s → 32% opacity, 450ms ease"
    },
    {
        k: "Network model",
        v: "Server-authoritative tick, 150ms client prediction"
    },
    {
        k: "Offline behaviour",
        v: "Local play continues; sync-on-reconnect every 5s"
    }
];
const RISKS = [
    {
        risk: "Manual combat feels like work on a 6-inch screen",
        mitigation: "Resolved by the 2s auto-attack tick: baseline damage no longer requires a thumb, freeing the player to read telegraphs. Abilities remain manual on 68pt pads with haptic confirmation, and resetting the tick rewards active play without punishing passive play.",
        severity: "Resolved"
    },
    {
        risk: "Heavy armour becomes mandatory and flattens build variety",
        mitigation: "Encumbrance is the counterweight: +5ms per point of step time, capped at +90ms. In the Grey Barrow, where every wraith telegraphs a 3×3, a +40ms step is measurably worse than 12 points of mitigation. Light builds win in high-telegraph zones, heavy builds win in swarm zones.",
        severity: "Medium"
    },
    {
        risk: "Full-loot death drives away casual players",
        mitigation: "Remnants uses partial loss: XP and carried gold only, never equipped gear — except in Emberfield and the Grey Barrow, which are opt-in and clearly labelled at the region border.",
        severity: "High"
    },
    {
        risk: "Player economy collapses from bot farming",
        mitigation: "Manual-input combat is inherently bot-hostile: telegraph dodging requires reactive play. Telemetry flags perfect-dodge-rate outliers automatically.",
        severity: "Medium"
    },
    {
        risk: "Telegraph spam becomes visual noise in group fights",
        mitigation: "Max 3 concurrent zones rendered per tile; overlapping zones merge to the highest-damage colour. Player-cast telegraphs render at 60% alpha of hostile ones.",
        severity: "Medium"
    }
];
const ROADMAP = [
    {
        phase: "Slice",
        state: "done",
        items: [
            "Grid movement",
            "Telegraph combat",
            "2s auto-attack tick",
            "Drag-to-shove",
            "8 gear slots + flat armour",
            "Loot spread / 60s claim / filter",
            "Protected zones",
            "Persistent character",
            "Market v1"
        ]
    },
    {
        phase: "Alpha",
        state: "next",
        items: [
            "Real-time multiplayer tick",
            "PvP in Emberfield",
            "Crafting",
            "Guild claims"
        ]
    },
    {
        phase: "Beta",
        state: "later",
        items: [
            "Housing",
            "Server-first world bosses",
            "Cross-play accounts",
            "Spectator mode"
        ]
    },
    {
        phase: "Launch",
        state: "later",
        items: [
            "Seasonal Barrow resets",
            "Cosmetic-only monetisation",
            "Creator API"
        ]
    }
];
}),
"[project]/src/lib/game/content.ts [app-rsc] (ecmascript)", ((__turbopack_context__) => {
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
"[project]/src/lib/game/world.ts [app-rsc] (ecmascript)", ((__turbopack_context__) => {
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
}),
"[project]/src/app/page.tsx [app-rsc] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>Home,
    "dynamic",
    ()=>dynamic
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/server/route-modules/app-page/vendored/rsc/react-jsx-dev-runtime.js [app-rsc] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$react$2d$server$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/dist/client/app-dir/link.react-server.js [app-rsc] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/image.js [app-rsc] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$design$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/design.ts [app-rsc] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/game/content.ts [app-rsc] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/game/world.ts [app-rsc] (ecmascript)");
;
;
;
;
;
;
const dynamic = "force-static";
function Section({ id, eyebrow, title, children }) {
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("section", {
        id: id,
        className: "mx-auto w-full max-w-6xl px-4 py-14 sm:py-20",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                className: "text-[11px] font-black uppercase tracking-[0.4em] text-amber-400",
                children: eyebrow
            }, void 0, false, {
                fileName: "[project]/src/app/page.tsx",
                lineNumber: 22,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                className: "mt-2 text-3xl font-black leading-tight text-slate-50 sm:text-4xl",
                children: title
            }, void 0, false, {
                fileName: "[project]/src/app/page.tsx",
                lineNumber: 23,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "mt-8",
                children: children
            }, void 0, false, {
                fileName: "[project]/src/app/page.tsx",
                lineNumber: 24,
                columnNumber: 7
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/src/app/page.tsx",
        lineNumber: 21,
        columnNumber: 5
    }, this);
}
function Home() {
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("main", {
        className: "pb-24",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "relative overflow-hidden border-b border-white/10",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["default"], {
                        src: "/images/keyart.jpg",
                        alt: "Remnants key art",
                        fill: true,
                        priority: true,
                        className: "object-cover opacity-45"
                    }, void 0, false, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 34,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "absolute inset-0 bg-gradient-to-b from-[#0b0d12]/60 via-[#0b0d12]/80 to-[#0b0d12]"
                    }, void 0, false, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 41,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "relative mx-auto max-w-6xl px-4 py-20 sm:py-28",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: "inline-block rounded-full border border-amber-500/40 bg-amber-500/10 px-3 py-1 text-[10px] font-black uppercase tracking-[0.3em] text-amber-300",
                                children: "Design Bible · v0.9 · Vertical Slice"
                            }, void 0, false, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 43,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h1", {
                                className: "mt-5 max-w-3xl text-5xl font-black leading-[0.95] text-white sm:text-7xl",
                                children: "REMNANTS"
                            }, void 0, false, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 46,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                className: "mt-4 max-w-2xl text-lg font-medium text-slate-300 sm:text-xl",
                                children: [
                                    "A tile-based, persistent-world MMORPG for phones. The grid-locked, high-stakes permanence of ",
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        className: "text-amber-300",
                                        children: "Tibia"
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 51,
                                        columnNumber: 27
                                    }, this),
                                    ", wearing the readable, thumb-native skin of ",
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        className: "text-sky-300",
                                        children: "Brawl Stars"
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 52,
                                        columnNumber: 34
                                    }, this),
                                    "."
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 49,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "mt-7 flex flex-wrap gap-3",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$react$2d$server$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["default"], {
                                        href: "/play",
                                        className: "rounded-2xl border-b-4 border-amber-700 bg-amber-500 px-6 py-3.5 text-sm font-black uppercase tracking-widest text-black active:translate-y-0.5 active:border-b-2",
                                        children: "▶ Play the slice"
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 55,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$react$2d$server$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["default"], {
                                        href: "#pillars",
                                        className: "rounded-2xl border border-white/20 bg-white/5 px-6 py-3.5 text-sm font-black uppercase tracking-widest text-slate-200 backdrop-blur",
                                        children: "Read the pillars"
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 61,
                                        columnNumber: 13
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 54,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("dl", {
                                className: "mt-10 grid max-w-3xl grid-cols-2 gap-3 sm:grid-cols-4",
                                children: [
                                    [
                                        "Platform",
                                        "iOS · Android · Web"
                                    ],
                                    [
                                        "Perspective",
                                        "Top-down 40×40 grid"
                                    ],
                                    [
                                        "Combat",
                                        "2s tick + manual"
                                    ],
                                    [
                                        "Economy",
                                        "100% player-driven"
                                    ]
                                ].map(([k, v])=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "rounded-2xl border border-white/10 bg-black/40 p-3 backdrop-blur",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("dt", {
                                                className: "text-[10px] font-bold uppercase tracking-widest text-slate-500",
                                                children: k
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 76,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("dd", {
                                                className: "mt-1 text-sm font-black text-slate-100",
                                                children: v
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 77,
                                                columnNumber: 17
                                            }, this)
                                        ]
                                    }, k, true, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 75,
                                        columnNumber: 15
                                    }, this))
                            }, void 0, false, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 68,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 42,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/app/page.tsx",
                lineNumber: 33,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])(Section, {
                id: "pillars",
                eyebrow: "Section 01",
                title: "The four pillars",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "grid gap-4 md:grid-cols-2",
                    children: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$design$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["PILLARS"].map((p)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("article", {
                            className: "relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-b from-white/[0.06] to-transparent p-6",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: `absolute inset-x-0 top-0 h-1 bg-gradient-to-r ${p.accent}`
                                }, void 0, false, {
                                    fileName: "[project]/src/app/page.tsx",
                                    lineNumber: 92,
                                    columnNumber: 15
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "flex items-start gap-3",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                            className: "text-3xl",
                                            children: p.icon
                                        }, void 0, false, {
                                            fileName: "[project]/src/app/page.tsx",
                                            lineNumber: 94,
                                            columnNumber: 17
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            children: [
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                                    className: "text-xl font-black text-slate-50",
                                                    children: p.title
                                                }, void 0, false, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 96,
                                                    columnNumber: 19
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                    className: "text-xs font-bold uppercase tracking-widest text-amber-400/80",
                                                    children: p.tag
                                                }, void 0, false, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 97,
                                                    columnNumber: 19
                                                }, this)
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/src/app/page.tsx",
                                            lineNumber: 95,
                                            columnNumber: 17
                                        }, this)
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/src/app/page.tsx",
                                    lineNumber: 93,
                                    columnNumber: 15
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                    className: "mt-4 text-sm leading-relaxed text-slate-400",
                                    children: p.body
                                }, void 0, false, {
                                    fileName: "[project]/src/app/page.tsx",
                                    lineNumber: 100,
                                    columnNumber: 15
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("ul", {
                                    className: "mt-4 space-y-1.5",
                                    children: p.rules.map((r)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                            className: "flex gap-2 text-xs text-slate-300",
                                            children: [
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                    className: "text-amber-400",
                                                    children: "▸"
                                                }, void 0, false, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 104,
                                                    columnNumber: 21
                                                }, this),
                                                r
                                            ]
                                        }, r, true, {
                                            fileName: "[project]/src/app/page.tsx",
                                            lineNumber: 103,
                                            columnNumber: 19
                                        }, this))
                                }, void 0, false, {
                                    fileName: "[project]/src/app/page.tsx",
                                    lineNumber: 101,
                                    columnNumber: 15
                                }, this)
                            ]
                        }, p.id, true, {
                            fileName: "[project]/src/app/page.tsx",
                            lineNumber: 88,
                            columnNumber: 13
                        }, this))
                }, void 0, false, {
                    fileName: "[project]/src/app/page.tsx",
                    lineNumber: 86,
                    columnNumber: 9
                }, this)
            }, void 0, false, {
                fileName: "[project]/src/app/page.tsx",
                lineNumber: 85,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])(Section, {
                eyebrow: "Section 02",
                title: "The core combat loop",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                        className: "-mt-4 mb-8 max-w-2xl text-sm text-slate-400",
                        children: "Six beats, repeated forever. Exactly one of them is automated — the tick — and everything else is a decision the player has to make with their hands."
                    }, void 0, false, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 116,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "grid gap-3 sm:grid-cols-2 lg:grid-cols-6",
                        children: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$design$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["COMBAT_LOOP"].map((c)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "rounded-2xl border border-white/10 bg-white/[0.04] p-4",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "flex items-baseline justify-between",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "text-2xl font-black text-amber-400/40",
                                                children: c.step
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 124,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "rounded-md bg-black/40 px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wider text-sky-300",
                                                children: c.ms
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 125,
                                                columnNumber: 17
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 123,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                        className: "mt-1 text-base font-black text-slate-100",
                                        children: c.name
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 129,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "mt-2 text-xs leading-relaxed text-slate-400",
                                        children: c.text
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 130,
                                        columnNumber: 15
                                    }, this)
                                ]
                            }, c.step, true, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 122,
                                columnNumber: 13
                            }, this))
                    }, void 0, false, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 120,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "mt-8 grid gap-4 md:grid-cols-2",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "rounded-3xl border border-white/10 bg-white/[0.04] p-6",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                        className: "text-sm font-black uppercase tracking-widest text-slate-300",
                                        children: "Why the tick is 2 seconds"
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 137,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "mt-3 text-sm leading-relaxed text-slate-400",
                                        children: "An earlier draft of this document banned automation outright. Playtesting killed it: on a 6-inch screen, a thumb parked on an attack pad is a thumb that cannot also read the floor, and the player ends up watching their own hands instead of the telegraph."
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 140,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "mt-3 text-sm leading-relaxed text-slate-400",
                                        children: [
                                            "So baseline damage moved onto a metronome — and the metronome was made deliberately slow. Two seconds is roughly one wind-up window, which means there is always room to act ",
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("em", {
                                                children: "between"
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 148,
                                                columnNumber: 19
                                            }, this),
                                            " ticks. The skill ceiling is preserved because any manual ability resets the tick: pressing buttons is always strictly faster than not pressing them. Automation sets the floor. It never touches the ceiling."
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 145,
                                        columnNumber: 13
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 136,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "rounded-3xl border border-white/10 bg-white/[0.04] p-6",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                        className: "text-sm font-black uppercase tracking-widest text-slate-300",
                                        children: "The death contract"
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 154,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("ul", {
                                        className: "mt-3 space-y-2 text-sm text-slate-400",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                        className: "text-rose-300",
                                                        children: "−10% experience."
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 159,
                                                        columnNumber: 17
                                                    }, this),
                                                    " Enough to erase an evening. Never enough to erase a character."
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 158,
                                                columnNumber: 15
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                        className: "text-amber-300",
                                                        children: "−50% carried gold."
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 163,
                                                        columnNumber: 17
                                                    }, this),
                                                    " Banked gold at the Sanctuary is safe. Deciding when to walk home ",
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("em", {
                                                        children: "is"
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 164,
                                                        columnNumber: 63
                                                    }, this),
                                                    " the risk system."
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 162,
                                                columnNumber: 15
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                        className: "text-sky-300",
                                                        children: "A Remnant spawns."
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 167,
                                                        columnNumber: 17
                                                    }, this),
                                                    " Your dropped gold lands on the floor, locked to you for 60 seconds. Get back inside that window and it is yours. Miss it and it belongs to whoever is standing there."
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 166,
                                                columnNumber: 15
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                        className: "text-emerald-300",
                                                        children: "Equipped gear is safe"
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 172,
                                                        columnNumber: 17
                                                    }, this),
                                                    " outside Emberfield and the Grey Barrow, which are labelled at the border."
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 171,
                                                columnNumber: 15
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 157,
                                        columnNumber: 13
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 153,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 135,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/app/page.tsx",
                lineNumber: 115,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])(Section, {
                id: "systems",
                eyebrow: "Section 02b",
                title: "Systems addendum — build 0.9",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                        className: "-mt-4 mb-8 max-w-2xl text-sm text-slate-400",
                        children: "Five systems added after the first slice review. Each one exists because a specific playtest problem could not be solved with tuning alone."
                    }, void 0, false, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 182,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "space-y-4",
                        children: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$design$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["SYSTEMS"].map((s)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("article", {
                                className: `rounded-3xl border ${s.accent} bg-white/[0.04] p-6`,
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "flex flex-wrap items-start gap-3",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "text-3xl",
                                                children: s.icon
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 190,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "min-w-[200px] flex-1",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                                        className: "text-xl font-black text-slate-50",
                                                        children: s.title
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 192,
                                                        columnNumber: 19
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                        className: "mt-1 text-sm font-medium text-amber-300/90",
                                                        children: s.summary
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 193,
                                                        columnNumber: 19
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 191,
                                                columnNumber: 17
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 189,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "mt-4 grid gap-5 md:grid-cols-2",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "text-sm leading-relaxed text-slate-400",
                                                children: s.detail
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 197,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("ul", {
                                                className: "space-y-1.5",
                                                children: s.rules.map((r)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                                        className: "flex gap-2 text-xs text-slate-300",
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                className: "text-amber-400",
                                                                children: "▸"
                                                            }, void 0, false, {
                                                                fileName: "[project]/src/app/page.tsx",
                                                                lineNumber: 201,
                                                                columnNumber: 23
                                                            }, this),
                                                            r
                                                        ]
                                                    }, r, true, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 200,
                                                        columnNumber: 21
                                                    }, this))
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 198,
                                                columnNumber: 17
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 196,
                                        columnNumber: 15
                                    }, this)
                                ]
                            }, s.id, true, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 188,
                                columnNumber: 13
                            }, this))
                    }, void 0, false, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 186,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "mt-6 rounded-3xl border border-rose-500/30 bg-rose-500/5 p-6",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                className: "text-sm font-black uppercase tracking-widest text-rose-300",
                                children: "Known open issues these rules create"
                            }, void 0, false, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 212,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                className: "mt-1 text-xs text-slate-500",
                                children: "A design bible that only lists wins is a sales deck. These are live and unresolved."
                            }, void 0, false, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 215,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "mt-4 grid gap-4 md:grid-cols-3",
                                children: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$design$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["OPEN_ISSUES"].map((o)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "rounded-2xl bg-black/40 p-4",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h4", {
                                                className: "text-xs font-black text-slate-100",
                                                children: o.title
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 221,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "mt-2 text-[11px] leading-relaxed text-slate-400",
                                                children: o.body
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 222,
                                                columnNumber: 17
                                            }, this)
                                        ]
                                    }, o.title, true, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 220,
                                        columnNumber: 15
                                    }, this))
                            }, void 0, false, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 218,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 211,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/app/page.tsx",
                lineNumber: 181,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])(Section, {
                eyebrow: "Section 03",
                title: "Mobile-first UX specification",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "grid gap-4 lg:grid-cols-[1.1fr_0.9fr]",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "rounded-3xl border border-white/10 bg-white/[0.04] p-6",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "mx-auto aspect-[9/17] w-full max-w-[280px] overflow-hidden rounded-[2rem] border-4 border-black/70 bg-[#12141c] p-2",
                                    children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "relative h-full w-full rounded-[1.4rem] bg-gradient-to-b from-[#2b4a33] to-[#1a2a3a]",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "absolute inset-x-2 top-2 flex justify-between",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: "rounded-lg border border-sky-400/40 bg-sky-400/10 px-2 py-3 text-[8px] font-black uppercase text-sky-200",
                                                        children: "Vitals"
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 237,
                                                        columnNumber: 19
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: "rounded-lg border border-sky-400/40 bg-sky-400/10 px-2 py-3 text-[8px] font-black uppercase text-sky-200",
                                                        children: "Map"
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 240,
                                                        columnNumber: 19
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 236,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "absolute inset-x-6 top-[38%] rounded-lg border border-dashed border-white/25 py-3 text-center text-[8px] font-bold uppercase tracking-widest text-white/50",
                                                children: "World · never occluded"
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 244,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "absolute inset-x-0 bottom-0 h-[38%] border-t border-dashed border-amber-400/40 bg-amber-400/[0.06]",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                        className: "pt-1 text-center text-[8px] font-black uppercase tracking-widest text-amber-300/80",
                                                        children: "Thumb zone · 38%"
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 248,
                                                        columnNumber: 19
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: "mt-1 flex items-end justify-between px-3 pb-3",
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                                className: "h-16 w-16 rounded-full border-2 border-white/30 bg-white/10"
                                                            }, void 0, false, {
                                                                fileName: "[project]/src/app/page.tsx",
                                                                lineNumber: 252,
                                                                columnNumber: 21
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                                className: "grid grid-cols-2 gap-1.5",
                                                                children: [
                                                                    "⚔️",
                                                                    "🌀",
                                                                    "✨",
                                                                    "🛡️"
                                                                ].map((a)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                                        className: "grid h-7 w-7 place-items-center rounded-lg border border-white/30 bg-white/10 text-[11px]",
                                                                        children: a
                                                                    }, a, false, {
                                                                        fileName: "[project]/src/app/page.tsx",
                                                                        lineNumber: 255,
                                                                        columnNumber: 25
                                                                    }, this))
                                                            }, void 0, false, {
                                                                fileName: "[project]/src/app/page.tsx",
                                                                lineNumber: 253,
                                                                columnNumber: 21
                                                            }, this)
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 251,
                                                        columnNumber: 19
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 247,
                                                columnNumber: 17
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 235,
                                        columnNumber: 15
                                    }, this)
                                }, void 0, false, {
                                    fileName: "[project]/src/app/page.tsx",
                                    lineNumber: 234,
                                    columnNumber: 13
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                    className: "mt-4 text-center text-xs text-slate-500",
                                    children: "Reachability model: everything interactive lives inside a 62mm arc of the resting thumb. Informational UI lives above the world and fades out of the way."
                                }, void 0, false, {
                                    fileName: "[project]/src/app/page.tsx",
                                    lineNumber: 267,
                                    columnNumber: 13
                                }, this)
                            ]
                        }, void 0, true, {
                            fileName: "[project]/src/app/page.tsx",
                            lineNumber: 233,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "space-y-4",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "rounded-3xl border border-white/10 bg-white/[0.04] p-5",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                            className: "text-sm font-black uppercase tracking-widest text-slate-300",
                                            children: "Hard numbers"
                                        }, void 0, false, {
                                            fileName: "[project]/src/app/page.tsx",
                                            lineNumber: 275,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("dl", {
                                            className: "mt-3 divide-y divide-white/5",
                                            children: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$design$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["UX_SPECS"].map((s)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                    className: "flex items-baseline justify-between gap-4 py-2",
                                                    children: [
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("dt", {
                                                            className: "text-xs text-slate-500",
                                                            children: s.k
                                                        }, void 0, false, {
                                                            fileName: "[project]/src/app/page.tsx",
                                                            lineNumber: 281,
                                                            columnNumber: 21
                                                        }, this),
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("dd", {
                                                            className: "text-right text-xs font-bold text-slate-200",
                                                            children: s.v
                                                        }, void 0, false, {
                                                            fileName: "[project]/src/app/page.tsx",
                                                            lineNumber: 282,
                                                            columnNumber: 21
                                                        }, this)
                                                    ]
                                                }, s.k, true, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 280,
                                                    columnNumber: 19
                                                }, this))
                                        }, void 0, false, {
                                            fileName: "[project]/src/app/page.tsx",
                                            lineNumber: 278,
                                            columnNumber: 15
                                        }, this)
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/src/app/page.tsx",
                                    lineNumber: 274,
                                    columnNumber: 13
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "rounded-3xl border border-white/10 bg-white/[0.04] p-5",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                            className: "text-sm font-black uppercase tracking-widest text-slate-300",
                                            children: "Haptic language"
                                        }, void 0, false, {
                                            fileName: "[project]/src/app/page.tsx",
                                            lineNumber: 288,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("ul", {
                                            className: "mt-3 space-y-2 text-xs text-slate-400",
                                            children: [
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                                    children: [
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                            className: "text-slate-200",
                                                            children: "8ms tick"
                                                        }, void 0, false, {
                                                            fileName: "[project]/src/app/page.tsx",
                                                            lineNumber: 292,
                                                            columnNumber: 21
                                                        }, this),
                                                        " — target acquired, ability on cooldown (rejection)"
                                                    ]
                                                }, void 0, true, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 292,
                                                    columnNumber: 17
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                                    children: [
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                            className: "text-slate-200",
                                                            children: "14ms tap"
                                                        }, void 0, false, {
                                                            fileName: "[project]/src/app/page.tsx",
                                                            lineNumber: 293,
                                                            columnNumber: 21
                                                        }, this),
                                                        " — you land a hit"
                                                    ]
                                                }, void 0, true, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 293,
                                                    columnNumber: 17
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                                    children: [
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                            className: "text-slate-200",
                                                            children: "45ms thud"
                                                        }, void 0, false, {
                                                            fileName: "[project]/src/app/page.tsx",
                                                            lineNumber: 294,
                                                            columnNumber: 21
                                                        }, this),
                                                        " — you take >15 damage"
                                                    ]
                                                }, void 0, true, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 294,
                                                    columnNumber: 17
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                                    children: [
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                            className: "text-slate-200",
                                                            children: "12/30/18 triple"
                                                        }, void 0, false, {
                                                            fileName: "[project]/src/app/page.tsx",
                                                            lineNumber: 295,
                                                            columnNumber: 21
                                                        }, this),
                                                        " — kill confirmed"
                                                    ]
                                                }, void 0, true, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 295,
                                                    columnNumber: 17
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                                    children: [
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                            className: "text-slate-200",
                                                            children: "26/20/12 decay"
                                                        }, void 0, false, {
                                                            fileName: "[project]/src/app/page.tsx",
                                                            lineNumber: 296,
                                                            columnNumber: 21
                                                        }, this),
                                                        " — shove connects"
                                                    ]
                                                }, void 0, true, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 296,
                                                    columnNumber: 17
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                                    children: [
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                            className: "text-slate-200",
                                                            children: "90/60/140 double-thud"
                                                        }, void 0, false, {
                                                            fileName: "[project]/src/app/page.tsx",
                                                            lineNumber: 297,
                                                            columnNumber: 21
                                                        }, this),
                                                        " — death"
                                                    ]
                                                }, void 0, true, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 297,
                                                    columnNumber: 17
                                                }, this)
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/src/app/page.tsx",
                                            lineNumber: 291,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                            className: "mt-3 text-[11px] text-slate-500",
                                            children: "Haptics are never decorative. If it buzzes, world state changed."
                                        }, void 0, false, {
                                            fileName: "[project]/src/app/page.tsx",
                                            lineNumber: 299,
                                            columnNumber: 15
                                        }, this)
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/src/app/page.tsx",
                                    lineNumber: 287,
                                    columnNumber: 13
                                }, this)
                            ]
                        }, void 0, true, {
                            fileName: "[project]/src/app/page.tsx",
                            lineNumber: 273,
                            columnNumber: 11
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/src/app/page.tsx",
                    lineNumber: 231,
                    columnNumber: 9
                }, this)
            }, void 0, false, {
                fileName: "[project]/src/app/page.tsx",
                lineNumber: 230,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])(Section, {
                eyebrow: "Section 04",
                title: "Telegraphing & the bestiary",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                        className: "-mt-4 mb-8 max-w-2xl text-sm text-slate-400",
                        children: "Every enemy is defined first by its tell, second by its numbers. If a designer cannot describe the tell in one sentence, the monster does not ship."
                    }, void 0, false, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 309,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "grid gap-3 sm:grid-cols-2",
                        children: Object.values(__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["MONSTERS"]).map((m)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "rounded-2xl border border-white/10 bg-white/[0.04] p-5",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "flex items-center gap-3",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "grid h-12 w-12 place-items-center rounded-2xl border-2 border-black/60 text-2xl",
                                                style: {
                                                    background: m.color
                                                },
                                                children: m.glyph
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 317,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                                        className: "text-base font-black text-slate-100",
                                                        children: m.name
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 324,
                                                        columnNumber: 19
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                        className: "text-[10px] font-bold uppercase tracking-widest text-slate-500",
                                                        children: [
                                                            m.hp,
                                                            " hp · ",
                                                            m.damage,
                                                            " dmg · ",
                                                            m.xp,
                                                            " xp"
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 325,
                                                        columnNumber: 19
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 323,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "ml-auto rounded-lg bg-black/50 px-2 py-1 text-[10px] font-black text-amber-300",
                                                children: [
                                                    m.windup,
                                                    "ms tell"
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 329,
                                                columnNumber: 17
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 316,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "mt-3 text-xs leading-relaxed text-slate-300",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                className: "text-amber-400",
                                                children: "Tell —"
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 334,
                                                columnNumber: 17
                                            }, this),
                                            " ",
                                            m.tell
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 333,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "mt-2 text-xs leading-relaxed text-slate-500",
                                        children: m.behaviour
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 336,
                                        columnNumber: 15
                                    }, this)
                                ]
                            }, m.key, true, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 315,
                                columnNumber: 13
                            }, this))
                    }, void 0, false, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 313,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                        className: "mt-10 text-sm font-black uppercase tracking-widest text-slate-300",
                        children: "Player kit — four buttons, four decisions"
                    }, void 0, false, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 341,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4",
                        children: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["ABILITIES"].map((a)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "rounded-2xl border border-white/10 bg-white/[0.04] p-4",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "flex items-center gap-2",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "grid h-10 w-10 place-items-center rounded-xl border-2 border-black/60 bg-slate-200 text-xl",
                                                style: {
                                                    boxShadow: `inset 0 0 0 3px ${a.color}`
                                                },
                                                children: a.glyph
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 348,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                        className: "text-sm font-black text-slate-100",
                                                        children: a.name
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 355,
                                                        columnNumber: 19
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                        className: "text-[10px] font-bold uppercase tracking-wider text-slate-500",
                                                        children: [
                                                            a.manaCost,
                                                            " mana · ",
                                                            (a.cooldown / 1000).toFixed(1),
                                                            "s cd"
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 356,
                                                        columnNumber: 19
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 354,
                                                columnNumber: 17
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 347,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "mt-3 text-xs text-slate-400",
                                        children: a.description
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 361,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "mt-2 border-l-2 border-amber-500/50 pl-2 text-[11px] italic leading-relaxed text-slate-500",
                                        children: a.designNote
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 362,
                                        columnNumber: 15
                                    }, this)
                                ]
                            }, a.key, true, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 346,
                                columnNumber: 13
                            }, this))
                    }, void 0, false, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 344,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/app/page.tsx",
                lineNumber: 308,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])(Section, {
                eyebrow: "Section 05",
                title: "World structure & risk gradient",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                        className: "-mt-4 mb-8 max-w-2xl text-sm text-slate-400",
                        children: "One contiguous 40×40 grid, no loading screens, no instances. Risk rises as you walk north. The single Sanctuary sits at the southern tip, which means every trip home is a decision."
                    }, void 0, false, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 372,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "space-y-3",
                        children: [
                            ...__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$world$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["REGIONS"]
                        ].reverse().map((r, i)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "flex flex-col gap-3 rounded-2xl border border-white/10 bg-white/[0.04] p-5 sm:flex-row sm:items-center",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "h-14 w-14 shrink-0 rounded-2xl border-2 border-black/60",
                                        style: {
                                            background: r.tint
                                        }
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 382,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "min-w-0 flex-1",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                                className: "text-base font-black text-slate-100",
                                                children: r.name
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 387,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "text-[11px] font-bold uppercase tracking-widest text-amber-400/80",
                                                children: r.levelBand
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 388,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "mt-1 text-xs text-slate-500",
                                                children: [
                                                    "Spawns: ",
                                                    r.spawns.map((s)=>__TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$game$2f$content$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["MONSTERS"][s.key]?.name ?? s.key).join(", "),
                                                    " · tiles",
                                                    " ",
                                                    r.w,
                                                    "×",
                                                    r.h
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 391,
                                                columnNumber: 17
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 386,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "flex shrink-0 items-center gap-1",
                                        children: [
                                            Array.from({
                                                length: 4
                                            }).map((_, k)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                    className: `h-2 w-8 rounded-full ${k <= i ? "bg-rose-500" : "bg-white/10"}`
                                                }, k, false, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 398,
                                                    columnNumber: 19
                                                }, this)),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "ml-2 text-[10px] font-black uppercase text-rose-400",
                                                children: "risk"
                                            }, void 0, false, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 403,
                                                columnNumber: 17
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 396,
                                        columnNumber: 15
                                    }, this)
                                ]
                            }, r.key, true, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 378,
                                columnNumber: 13
                            }, this))
                    }, void 0, false, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 376,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/app/page.tsx",
                lineNumber: 371,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])(Section, {
                eyebrow: "Section 06",
                title: "Economy design",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "grid gap-4 md:grid-cols-3",
                        children: [
                            {
                                t: "Faucets",
                                c: "text-emerald-300",
                                items: [
                                    "Monster gold drops (1–90 per kill, region-scaled)",
                                    "Material drops with hard rarity gates",
                                    "Unclaimed Remnants decaying back into the world"
                                ]
                            },
                            {
                                t: "Sinks",
                                c: "text-rose-300",
                                items: [
                                    "5% market transaction tax (burned)",
                                    "50% carried gold destroyed on death",
                                    "Consumables: salves and draughts are never refundable"
                                ]
                            },
                            {
                                t: "Levers we will pull",
                                c: "text-sky-300",
                                items: [
                                    "Region respawn density (supply)",
                                    "Rarity table weights (scarcity)",
                                    "Tax rate, 3%–8% band (velocity)",
                                    "Barrow seasonal reset (shock absorber)"
                                ]
                            }
                        ].map((col)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "rounded-3xl border border-white/10 bg-white/[0.04] p-5",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                        className: `text-sm font-black uppercase tracking-widest ${col.c}`,
                                        children: col.t
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 444,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("ul", {
                                        className: "mt-3 space-y-2 text-xs text-slate-400",
                                        children: col.items.map((i)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("li", {
                                                className: "flex gap-2",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                        className: "text-slate-600",
                                                        children: "—"
                                                    }, void 0, false, {
                                                        fileName: "[project]/src/app/page.tsx",
                                                        lineNumber: 448,
                                                        columnNumber: 21
                                                    }, this),
                                                    i
                                                ]
                                            }, i, true, {
                                                fileName: "[project]/src/app/page.tsx",
                                                lineNumber: 447,
                                                columnNumber: 19
                                            }, this))
                                    }, void 0, false, {
                                        fileName: "[project]/src/app/page.tsx",
                                        lineNumber: 445,
                                        columnNumber: 15
                                    }, this)
                                ]
                            }, col.t, true, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 443,
                                columnNumber: 13
                            }, this))
                    }, void 0, false, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 412,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "mt-4 rounded-3xl border border-amber-500/30 bg-amber-500/5 p-6",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                className: "text-sm font-black uppercase tracking-widest text-amber-300",
                                children: "The one rule"
                            }, void 0, false, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 457,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                className: "mt-2 text-sm leading-relaxed text-slate-300",
                                children: "No item enters the world except through a player killing something and physically carrying it home. Monetisation touches cosmetics only — the moment gold or gear can be bought, the risk system that makes the walk home meaningful becomes optional, and the entire design collapses."
                            }, void 0, false, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 460,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$react$2d$server$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["default"], {
                                href: "/market",
                                className: "mt-4 inline-block rounded-xl border-b-4 border-amber-700 bg-amber-500 px-5 py-2.5 text-xs font-black uppercase tracking-widest text-black",
                                children: "Open the live market →"
                            }, void 0, false, {
                                fileName: "[project]/src/app/page.tsx",
                                lineNumber: 466,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/src/app/page.tsx",
                        lineNumber: 456,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/src/app/page.tsx",
                lineNumber: 411,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])(Section, {
                eyebrow: "Section 07",
                title: "Risk register & roadmap",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "grid gap-4 lg:grid-cols-2",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "space-y-3",
                            children: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$design$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["RISKS"].map((r)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "rounded-2xl border border-white/10 bg-white/[0.04] p-5",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "flex items-start gap-3",
                                            children: [
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                    className: `mt-0.5 shrink-0 rounded-md px-2 py-0.5 text-[9px] font-black uppercase tracking-wider ${r.severity === "High" ? "bg-rose-500/20 text-rose-300" : r.severity === "Resolved" ? "bg-emerald-500/20 text-emerald-300" : "bg-amber-500/20 text-amber-300"}`,
                                                    children: r.severity
                                                }, void 0, false, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 482,
                                                    columnNumber: 19
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                                    className: "text-sm font-black text-slate-100",
                                                    children: r.risk
                                                }, void 0, false, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 493,
                                                    columnNumber: 19
                                                }, this)
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/src/app/page.tsx",
                                            lineNumber: 481,
                                            columnNumber: 17
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                            className: "mt-2 text-xs leading-relaxed text-slate-400",
                                            children: r.mitigation
                                        }, void 0, false, {
                                            fileName: "[project]/src/app/page.tsx",
                                            lineNumber: 495,
                                            columnNumber: 17
                                        }, this)
                                    ]
                                }, r.risk, true, {
                                    fileName: "[project]/src/app/page.tsx",
                                    lineNumber: 480,
                                    columnNumber: 15
                                }, this))
                        }, void 0, false, {
                            fileName: "[project]/src/app/page.tsx",
                            lineNumber: 478,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "space-y-3",
                            children: __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$design$2e$ts__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["ROADMAP"].map((p)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "rounded-2xl border border-white/10 bg-white/[0.04] p-5",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "flex items-center gap-2",
                                            children: [
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                                    className: "text-sm font-black uppercase tracking-widest text-slate-100",
                                                    children: p.phase
                                                }, void 0, false, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 503,
                                                    columnNumber: 19
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                    className: `rounded-md px-2 py-0.5 text-[9px] font-black uppercase ${p.state === "done" ? "bg-emerald-500/20 text-emerald-300" : p.state === "next" ? "bg-sky-500/20 text-sky-300" : "bg-white/10 text-slate-400"}`,
                                                    children: p.state
                                                }, void 0, false, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 506,
                                                    columnNumber: 19
                                                }, this)
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/src/app/page.tsx",
                                            lineNumber: 502,
                                            columnNumber: 17
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "mt-3 flex flex-wrap gap-1.5",
                                            children: p.items.map((i)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                    className: "rounded-lg bg-black/40 px-2 py-1 text-[11px] text-slate-300",
                                                    children: i
                                                }, i, false, {
                                                    fileName: "[project]/src/app/page.tsx",
                                                    lineNumber: 520,
                                                    columnNumber: 21
                                                }, this))
                                        }, void 0, false, {
                                            fileName: "[project]/src/app/page.tsx",
                                            lineNumber: 518,
                                            columnNumber: 17
                                        }, this)
                                    ]
                                }, p.phase, true, {
                                    fileName: "[project]/src/app/page.tsx",
                                    lineNumber: 501,
                                    columnNumber: 15
                                }, this))
                        }, void 0, false, {
                            fileName: "[project]/src/app/page.tsx",
                            lineNumber: 499,
                            columnNumber: 11
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/src/app/page.tsx",
                    lineNumber: 477,
                    columnNumber: 9
                }, this)
            }, void 0, false, {
                fileName: "[project]/src/app/page.tsx",
                lineNumber: 476,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "mx-auto max-w-6xl px-4",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "rounded-3xl border border-white/10 bg-gradient-to-br from-amber-500/15 to-rose-500/10 p-8 text-center",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                            className: "text-2xl font-black text-slate-50 sm:text-3xl",
                            children: "Documents lie. Prototypes don't."
                        }, void 0, false, {
                            fileName: "[project]/src/app/page.tsx",
                            lineNumber: 533,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                            className: "mx-auto mt-2 max-w-xl text-sm text-slate-400",
                            children: "The slice below runs the real telegraph timings, the real death penalty, and writes to the real persistent database. Play it on your phone."
                        }, void 0, false, {
                            fileName: "[project]/src/app/page.tsx",
                            lineNumber: 536,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$rsc$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$react$2d$server$2e$js__$5b$app$2d$rsc$5d$__$28$ecmascript$29$__["default"], {
                            href: "/play",
                            className: "mt-6 inline-block rounded-2xl border-b-4 border-amber-700 bg-amber-500 px-8 py-4 text-sm font-black uppercase tracking-widest text-black active:translate-y-0.5 active:border-b-2",
                            children: "▶ Enter the Hollow"
                        }, void 0, false, {
                            fileName: "[project]/src/app/page.tsx",
                            lineNumber: 540,
                            columnNumber: 11
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/src/app/page.tsx",
                    lineNumber: 532,
                    columnNumber: 9
                }, this)
            }, void 0, false, {
                fileName: "[project]/src/app/page.tsx",
                lineNumber: 531,
                columnNumber: 7
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/src/app/page.tsx",
        lineNumber: 31,
        columnNumber: 5
    }, this);
}
}),
"[project]/src/app/page.tsx [app-rsc] (ecmascript, Next.js Server Component)", ((__turbopack_context__) => {

__turbopack_context__.n(__turbopack_context__.i("[project]/src/app/page.tsx [app-rsc] (ecmascript)"));
}),
];

//# sourceMappingURL=%5Broot-of-the-server%5D__12~9c8o._.js.map