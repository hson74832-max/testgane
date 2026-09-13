/**
 * REMNANTS — content tables.
 * Single source of truth shared by the client prototype, the codex pages and
 * the server-side market/loot routes.
 */

export type Rarity = "common" | "uncommon" | "rare" | "epic";

export type EquipSlot =
  | "helmet"
  | "amulet"
  | "armor"
  | "weapon"
  | "shield"
  | "legs"
  | "boots"
  | "ring";

export const EQUIP_SLOTS: { key: EquipSlot; label: string; glyph: string }[] = [
  { key: "helmet", label: "Head", glyph: "🪖" },
  { key: "amulet", label: "Neck", glyph: "📿" },
  { key: "armor", label: "Chest", glyph: "🎽" },
  { key: "weapon", label: "Weapon", glyph: "🗡️" },
  { key: "shield", label: "Off-hand", glyph: "🛡️" },
  { key: "legs", label: "Legs", glyph: "👖" },
  { key: "boots", label: "Feet", glyph: "🥾" },
  { key: "ring", label: "Ring", glyph: "💍" },
];

export type ItemDef = {
  key: string;
  name: string;
  glyph: string;
  rarity: Rarity;
  basePrice: number;
  kind: "material" | "consumable" | "gear" | "relic";
  blurb: string;
  /** Equipment only */
  slot?: EquipSlot;
  /** Flat physical damage reduction contributed by this piece. */
  armor?: number;
  /** Weapon damage added to the auto-attack tick and to Strike. */
  damage?: number;
  /** Encumbrance points. Each point adds 5ms to the grid step cadence. */
  heavy?: number;
  /** Consumables only — applied when the item is used. */
  effect?: { hp?: number; mana?: number };
};

export const ITEMS: Record<string, ItemDef> = {
  rat_pelt: {
    key: "rat_pelt",
    name: "Sewer Pelt",
    glyph: "🐀",
    rarity: "common",
    basePrice: 6,
    kind: "material",
    blurb: "Matted, cheap, endless. The copper standard of the Hollow economy.",
  },
  chitin_plate: {
    key: "chitin_plate",
    name: "Chitin Plate",
    glyph: "🕷️",
    rarity: "uncommon",
    basePrice: 24,
    kind: "material",
    blurb: "Crafters buy these in stacks of twenty. Stacks of twenty are hard to carry home.",
  },
  ember_core: {
    key: "ember_core",
    name: "Ember Core",
    glyph: "🔥",
    rarity: "rare",
    basePrice: 90,
    kind: "material",
    blurb: "Still warm. Fuels the only known method of re-forging a broken ward.",
  },
  grave_silk: {
    key: "grave_silk",
    name: "Grave Silk",
    glyph: "🕸️",
    rarity: "rare",
    basePrice: 120,
    kind: "material",
    blurb: "Harvested from wraiths. The single most volatile commodity on the board.",
  },
  salve: {
    key: "salve",
    name: "Field Salve",
    glyph: "🧪",
    rarity: "common",
    basePrice: 18,
    kind: "consumable",
    effect: { hp: 55 },
    blurb: "Restores 55 HP over a 3s channel. You cannot move while drinking. That is the point.",
  },
  mana_draught: {
    key: "mana_draught",
    name: "Blue Draught",
    glyph: "🫙",
    rarity: "common",
    basePrice: 22,
    kind: "consumable",
    effect: { mana: 40 },
    blurb: "Restores 40 mana. Mana is the real currency of survival.",
  },
  gold: {
    key: "gold",
    name: "Gold",
    glyph: "🪙",
    rarity: "common",
    basePrice: 1,
    kind: "material",
    blurb: "Carried gold is at risk. Banked gold is not. That is the whole risk system in one line.",
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
    blurb: "Starter steel. Weightless, so your step cadence stays at a clean 205ms.",
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
    blurb: "Heavy enough that you feel it in your feet. The classic damage-versus-footwork trade.",
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
    blurb: "+9 damage, near weightless. Drops 1-in-400 from wraiths. A server event when it lands.",
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
    blurb: "One flat point off every physical hit. Against a Hollow Rat that is 17% of its damage.",
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
    blurb: "Crafted from six plates. The first meaningful spider-farming milestone.",
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
    blurb: "The default chest piece. Cheap enough that losing it in the Barrow is survivable.",
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
    blurb: "Turns an Ember Husk from a 17-damage threat into a 10-damage nuisance.",
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
    blurb: "Best-in-slot mitigation, worst-in-slot mobility. +40ms per step is a real telegraph tax.",
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
    blurb: "Off-hand mitigation with almost no encumbrance cost.",
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
    blurb: "Pulled off the dead of the Grey Barrow. Still cold.",
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
    blurb: "Emberfield standard issue. Leg armour is the cheapest armour-per-gold in the game.",
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
    blurb: "Weightless. Every serious Barrow runner wears these and nothing heavier below the waist.",
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
    blurb: "Woven from wraith silk. Two flat points, zero weight — the arbitrage everyone wants.",
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
    blurb: "A warm band. One point of mitigation and a small social signal that you farm Emberfield.",
  },
  soul_token: {
    key: "soul_token",
    name: "Soul Token",
    glyph: "💠",
    rarity: "epic",
    basePrice: 400,
    kind: "relic",
    blurb: "Consumed on death to protect your XP. The whole economy prices itself against this.",
  },
};

export const ITEM_LIST = Object.values(ITEMS);

export type MonsterDef = {
  key: string;
  name: string;
  glyph: string;
  hp: number;
  damage: number;
  xp: number;
  gold: [number, number];
  /** ms between the telegraph starting and damage landing */
  windup: number;
  /** ms between attacks */
  cadence: number;
  /** tiles */
  aggroRange: number;
  attackRange: number;
  moveMs: number;
  color: string;
  tell: string;
  loot: { itemKey: string; chance: number; qty: [number, number] }[];
  behaviour: string;
  /**
   * Telegraph geometry, read by every client (web canvas + Godot).
   * single = the victim's tile, line = 3 tiles toward the victim + victim,
   * radial = 3x3 around the victim. New monsters need no code, just a shape.
   */
  shape: "single" | "line" | "radial";
  /** Status applied on hit, if any. */
  status?: "poison" | "burn" | "slow";
};

export const MONSTERS: Record<string, MonsterDef> = {
  rat: {
    key: "rat",
    name: "Hollow Rat",
    glyph: "🐀",
    hp: 26,
    damage: 6,
    xp: 12,
    gold: [1, 6],
    windup: 520,
    cadence: 1500,
    aggroRange: 4,
    attackRange: 1,
    moveMs: 420,
    color: "#a98467",
    tell: "Rears up on hind legs — one tile of orange floor.",
    loot: [
      { itemKey: "rat_pelt", chance: 0.7, qty: [1, 2] },
      { itemKey: "bone_knife", chance: 0.05, qty: [1, 1] },
      { itemKey: "rusted_helm", chance: 0.04, qty: [1, 1] },
    ],
    behaviour: "Swarms. Individually trivial, lethal in fours because each one resets your step timer.",
    shape: "single",
  },
  spider: {
    key: "spider",
    name: "Cave Spider",
    glyph: "🕷️",
    hp: 54,
    damage: 11,
    xp: 34,
    gold: [4, 14],
    windup: 700,
    cadence: 2000,
    aggroRange: 5,
    attackRange: 1,
    moveMs: 340,
    color: "#6b5b95",
    tell: "Fangs flare violet — applies POISON, a 3-tick DOT shown as green pips.",
    loot: [
      { itemKey: "chitin_plate", chance: 0.5, qty: [1, 2] },
      { itemKey: "salve", chance: 0.15, qty: [1, 1] },
      { itemKey: "leather_vest", chance: 0.07, qty: [1, 1] },
      { itemKey: "wooden_buckler", chance: 0.06, qty: [1, 1] },
      { itemKey: "chitin_helm", chance: 0.04, qty: [1, 1] },
    ],
    behaviour: "Fast mover, slow attacker. Punishes players who stand still to heal.",
    shape: "single",
    status: "poison",
  },
  ember: {
    key: "ember",
    name: "Ember Husk",
    glyph: "🔥",
    hp: 88,
    damage: 17,
    xp: 70,
    gold: [12, 30],
    windup: 950,
    cadence: 2600,
    aggroRange: 6,
    attackRange: 3,
    moveMs: 620,
    color: "#e07a3f",
    tell: "Telegraphs a 3-tile line of glowing floor. Sidestep, do not outrun.",
    loot: [
      { itemKey: "ember_core", chance: 0.35, qty: [1, 1] },
      { itemKey: "mana_draught", chance: 0.2, qty: [1, 1] },
      { itemKey: "ash_greaves", chance: 0.08, qty: [1, 1] },
      { itemKey: "travel_boots", chance: 0.07, qty: [1, 1] },
      { itemKey: "ember_ring", chance: 0.05, qty: [1, 1] },
      { itemKey: "ember_axe", chance: 0.03, qty: [1, 1] },
    ],
    behaviour: "Ranged zoner. Teaches the core lesson: read the floor, not the monster.",
    shape: "line",
    status: "burn",
  },
  wraith: {
    key: "wraith",
    name: "Grave Wraith",
    glyph: "👻",
    hp: 150,
    damage: 26,
    xp: 165,
    gold: [40, 90],
    windup: 1150,
    cadence: 3000,
    aggroRange: 7,
    attackRange: 2,
    moveMs: 520,
    color: "#4cc9f0",
    tell: "Screams and paints a 3x3 cyan bloom. Full 1.15s to leave the zone.",
    loot: [
      { itemKey: "grave_silk", chance: 0.4, qty: [1, 1] },
      { itemKey: "barrow_shield", chance: 0.09, qty: [1, 1] },
      { itemKey: "silk_amulet", chance: 0.07, qty: [1, 1] },
      { itemKey: "chitin_mail", chance: 0.05, qty: [1, 1] },
      { itemKey: "soul_token", chance: 0.04, qty: [1, 1] },
      { itemKey: "ember_plate", chance: 0.012, qty: [1, 1] },
      { itemKey: "hollow_blade", chance: 0.0025, qty: [1, 1] },
    ],
    behaviour: "Territory boss of the Barrow. Solo-able at level 8 with perfect footwork, never before.",
    shape: "radial",
  },
};

export type AbilityDef = {
  key: string;
  name: string;
  glyph: string;
  manaCost: number;
  cooldown: number;
  windup: number;
  damage: number;
  range: number;
  shape: "adjacent" | "radial" | "line" | "self";
  color: string;
  description: string;
  designNote: string;
};

export const ABILITIES: AbilityDef[] = [
  {
    key: "strike",
    name: "Strike",
    glyph: "⚔️",
    manaCost: 8,
    cooldown: 850,
    windup: 260,
    damage: 14,
    range: 1,
    shape: "adjacent",
    color: "#ffd166",
    description: "Manual melee swing on the targeted adjacent tile. Costs mana — the 2s tick is the free baseline, Strike is the burst.",
    designNote:
      "Strike used to be free and spammable, which made the 2-second tick pointless: optimal play was hammering one button. The 8-mana price restores the intended rhythm — free metronome damage plus deliberate, mana-gated bursts — and gives Blue Draughts a job in every fight, not just mage fights.",
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
    shape: "radial",
    color: "#ef476f",
    description: "Hits every enemy in the 8 tiles around you after a 0.42s wind-up.",
    designNote:
      "Your own wind-up is telegraphed to other players too. Committing to Cleave is a readable, punishable choice — symmetry with monster tells.",
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
    designNote:
      "The only reliable way to open on an Ember Husk before it zones you. Mana-gated so it can never become the default attack.",
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
    designNote:
      "Defensive cooldowns are held, not spammed. Long CD + visible bubble = other players can count your Ward down out loud.",
  },
];

export const RARITY_STYLES: Record<Rarity, { text: string; ring: string; bg: string }> = {
  common: { text: "text-slate-300", ring: "ring-slate-600", bg: "bg-slate-800/60" },
  uncommon: { text: "text-emerald-300", ring: "ring-emerald-600/60", bg: "bg-emerald-950/40" },
  rare: { text: "text-sky-300", ring: "ring-sky-500/60", bg: "bg-sky-950/40" },
  epic: { text: "text-fuchsia-300", ring: "ring-fuchsia-500/60", bg: "bg-fuchsia-950/40" },
};

export function xpForLevel(level: number): number {
  // Deliberately steep after 8 — the mid-game is where death should hurt most.
  return Math.floor(60 * Math.pow(level, 1.85));
}

export function levelFromXp(xp: number): number {
  let lvl = 1;
  while (lvl < 60 && xp >= xpForLevel(lvl)) lvl += 1;
  return lvl;
}

export function statsForLevel(level: number) {
  return {
    maxHp: 100 + level * 20,
    maxMana: 45 + level * 15,
    damageBonus: Math.floor(level * 1.6),
  };
}

/* ------------------------------------------------------------------ tuning */

export const COMBAT = {
  /** Auto-attack tick while a creature is Marked. */
  AUTO_ATTACK_MS: 2000,
  /** Base grid step cadence before encumbrance. */
  BASE_STEP_MS: 205,
  /** Each encumbrance point adds this many ms to a step. */
  MS_PER_HEAVY: 5,
  /** Hard ceiling so full plate can never be unplayable. */
  MAX_STEP_PENALTY_MS: 90,
  /** Flat mitigation floor — armour can never fully negate a hit. */
  MIN_DAMAGE: 1,
  /** Shove cooldown. */
  PUSH_CD_MS: 2500,
  /** How long the top-damage dealer holds an exclusive claim on a drop. */
  LOOT_PROTECT_MS: 60_000,
  /** Ground items despawn after this. */
  GROUND_DECAY_MS: 180_000,

  /* ---- movement, casting, regen ---- */
  STEP_MIN_MS: 120,
  STEP_DIAGONAL_MULT: 1.4,
  STEP_SLOW_MULT: 1.6,
  ROOT_MS: 1200,
  REGEN_MS: 1400,
  REGEN_HP_BASE: 1,
  REGEN_HP_DIV: 3,
  REGEN_MANA_BASE: 2,
  REGEN_MANA_DIV: 2,

  /* ---- crits ---- */
  CRIT_CHANCE: 0.14,
  CRIT_MULT: 1.85,

  /* ---- ward ---- */
  WARD_BASE: 45,
  WARD_PER_LEVEL: 5,
  WARD_PER_RANK: 10,
  WARD_MS: 6000,

  /* ---- statuses ---- */
  STATUS_MS: 6000,
  STATUS_TICK_MS: 1500,
  POISON_POWER: 4,
  BURN_POWER: 6,

  /* ---- death ---- */
  XP_LOSS_PCT: 0.1,
  GOLD_DROP_PCT: 0.5,
  RESPAWN_MS: 2600,

  /* ---- spawning & monster AI ---- */
  MAX_MONSTERS: 34,
  CRYPT_MONSTERS: 8,
  RIVAL_MARK_CHANCE: 0.14,
  RIVAL_MARK_MIN: 0.3,
  RIVAL_MARK_SPREAD: 0.3,
  SENSE_JITTER: 1,
  SENSE_MIN: 2,
  SENSE_MAX: 9,
  DEAGGRO_TILES: 4,
  AGGRO_REACT_MS: 120,
  MOB_HEAL_MS: 1500,
  MOB_HEAL_DIV: 20,
} as const;

export type Loadout = {
  armor: number;
  heavy: number;
  weaponDamage: number;
};

export function computeLoadout(equipped: Partial<Record<EquipSlot, string>>): Loadout {
  let armor = 0;
  let heavy = 0;
  let weaponDamage = 0;
  for (const key of Object.values(equipped)) {
    if (!key) continue;
    const it = ITEMS[key];
    if (!it) continue;
    armor += it.armor ?? 0;
    heavy += it.heavy ?? 0;
    if (it.slot === "weapon") weaponDamage += it.damage ?? 0;
  }
  return { armor, heavy, weaponDamage };
}

export function stepMsFor(heavy: number) {
  return (
    COMBAT.BASE_STEP_MS +
    Math.min(COMBAT.MAX_STEP_PENALTY_MS, heavy * COMBAT.MS_PER_HEAVY)
  );
}

/** Flat mitigation. No percentages anywhere — players must be able to do this in their head. */
export function mitigate(raw: number, armor: number) {
  return Math.max(COMBAT.MIN_DAMAGE, raw - armor);
}

export const DEFAULT_LOOT_FILTER: string[] = Object.values(ITEMS)
  .filter((i) => i.rarity !== "common" || i.kind !== "material" || i.key === "gold")
  .map((i) => i.key);

export const ALL_ITEM_KEYS = Object.keys(ITEMS);

/** Rival adventurers used to demonstrate contested loot claims in the slice. */
export const RIVALS = ["Vessa Crow", "Harlan Dredge", "Oskar Pyre", "The Marrow Guild"];

/* ------------------------------------------------------------------ NPCs
 * Sanctuary fixtures. Godot-only for now (the web slice has no NPCs):
 * trader moves consumables at base price and buys loot at half base
 * (economy review flag: gear vendors stay forbidden), healer mends for
 * 30g, ferryman sails 3 surface crossings for 10g. Talk range is 2 tiles.
 * tile = [x, y, z].
 */
export type NpcDef = {
  id: string;
  name: string;
  role: "trader" | "healer" | "ferry";
  blurb: string;
  pos: [number, number, number];
  color: string;
};

export const NPCS: NpcDef[] = [
  {
    id: "mallow",
    name: "Sister Mallow",
    role: "trader",
    blurb: "Potions at cost. Loot at half — the Guild takes its cut.",
    pos: [19, 34, 0],
    color: "#1abfa5",
  },
  {
    id: "ansel",
    name: "Brother Ansel",
    role: "healer",
    blurb: "Mends wounds and bad humours. 30 gold, no questions.",
    pos: [21, 34, 0],
    color: "#73d957",
  },
  {
    id: "dredge",
    name: "Ferryman Dredge",
    role: "ferry",
    blurb: "Ten gold and my pole does the walking.",
    pos: [20, 36, 0],
    color: "#59a6f2",
  },
];

/** What the trader stocks (item keys into ITEMS, sold at basePrice). */
export const NPC_STOCK: string[] = ["salve", "mana_draught"];

/** Ferry crossings: tile = [x, y, z], snapped to nearest open tile. */
export const FERRY: { key: string; name: string; pos: [number, number, number] }[] = [
  { key: "temple", name: "Sanctuary", pos: [20, 35, 0] },
  { key: "cross", name: "Crossroads", pos: [20, 16, 0] },
  { key: "barrow", name: "Barrow Gate", pos: [20, 11, 0] },
];

export const NPC_TALK_RANGE = 2;
export const NPC_HEAL_COST = 30;
export const NPC_FERRY_COST = 10;
/** Loot sold to the trader NPC fetches this fraction of base price. */
export const NPC_SELL_PCT = 0.5;

/* -------------------------------------------------------------- vocations
 * Paths bend the shared 4-button kit: tick profile, growth, damage weights.
 * Warrior holds the line in melee, Archer owns 5 tiles of sight-checked
 * air, Magician is frail with vast mana and +35% spells.
 */
export type VocationDef = {
  key: string;
  name: string;
  blurb: string;
  hpMult: number;
  manaMult: number;
  tickRange: number;
  tickBase: number;
  tickScale: number;
  tickShot: boolean;
  meleeMult: number;
  spellMult: number;
};

export const VOCATION_ORDER = ["warrior", "archer", "magician"];

export const VOCATIONS: Record<string, VocationDef> = {
  warrior: {
    key: "warrior",
    name: "Warrior",
    blurb: "Melee metronome. Holds the line.",
    hpMult: 1.25,
    manaMult: 0.85,
    tickRange: 1,
    tickBase: 6,
    tickScale: 0.9,
    tickShot: false,
    meleeMult: 1.15,
    spellMult: 0.8,
  },
  archer: {
    key: "archer",
    name: "Archer",
    blurb: "5-tile tick. Walls stop arrows.",
    hpMult: 1.0,
    manaMult: 1.0,
    tickRange: 5,
    tickBase: 4,
    tickScale: 0.7,
    tickShot: true,
    meleeMult: 0.8,
    spellMult: 1.0,
  },
  magician: {
    key: "magician",
    name: "Magician",
    blurb: "Single-target ruin. Frail, vast mana.",
    hpMult: 0.8,
    manaMult: 1.4,
    tickRange: 1,
    tickBase: 3,
    tickScale: 0.5,
    tickShot: false,
    meleeMult: 0.7,
    spellMult: 1.35,
  },
};

/* ----------------------------------------------------------------- skills
 * One point per level. Rank caps keep every path completable-ish.
 * `effect` is the per-rank payload both clients read: a new skill is a data
 * row, no code — understood keys: maxHp, maxMana, stepMs (reduction), damage, ward.
 */
export type SkillDef = {
  key: string;
  name: string;
  desc: string;
  max: number;
  effect: { maxHp?: number; maxMana?: number; stepMs?: number; damage?: number; ward?: number };
};

export const SKILL_ORDER = ["tough", "focus", "swift", "power", "warding"];

export const SKILLS: Record<string, SkillDef> = {
  tough: { key: "tough", name: "Toughness", desc: "+15 max HP / rank", max: 5, effect: { maxHp: 15 } },
  focus: { key: "focus", name: "Focus", desc: "+10 max mana / rank", max: 5, effect: { maxMana: 10 } },
  swift: { key: "swift", name: "Swiftness", desc: "-4ms step / rank", max: 5, effect: { stepMs: 4 } },
  power: { key: "power", name: "Power", desc: "+1 all damage / rank", max: 5, effect: { damage: 1 } },
  warding: { key: "warding", name: "Warding", desc: "+10 ward strength / rank", max: 3, effect: { ward: 10 } },
};
