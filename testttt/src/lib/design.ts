export const PILLARS = [
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
      "Death: −10% XP, −50% carried gold, gold drops on the floor",
    ],
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
      "One glance rule: a 0.4s glance must convey HP, threat and escape route",
    ],
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
      "Safe-area aware; nothing under a notch or home indicator",
    ],
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
      "Regional risk maps directly to material scarcity and price floor",
    ],
  },
] as const;

export const COMBAT_LOOP = [
  {
    step: "01",
    name: "Mark",
    ms: "one tap",
    text: "Tap the creature. A reticle locks on and an orange arc begins filling. That arc is the 2-second auto-attack tick.",
  },
  {
    step: "02",
    name: "Read",
    ms: "520–1150ms",
    text: "The creature swells and the floor it will hit lights up with a rising fill bar. You know the shape and the deadline.",
  },
  {
    step: "03",
    name: "Step, Shove or Commit",
    ms: "205ms+/tile",
    text: "Three answers to a telegraph: walk out, shove the creature out (cancelling its wind-up), or eat it behind armour and keep swinging.",
  },
  {
    step: "04",
    name: "Resolve",
    ms: "instant",
    text: "Damage pops with the flat armour reduction shown inline — '11 (-6)'. Dodges print grey so a miss is legible too.",
  },
  {
    step: "05",
    name: "Claim",
    ms: "60s window",
    text: "Loot scatters across the 3×3 around the corpse, locked to the top damage dealer for 60 seconds. Your filter decides what you even see.",
  },
  {
    step: "06",
    name: "Bank It",
    ms: "the long walk",
    text: "Carrying it home is the real risk window — and the only reason the market has supply.",
  },
] as const;

/** Systems added after the first slice review. */
export const SYSTEMS = [
  {
    id: "tick",
    icon: "⏱️",
    title: "The 2-second tick",
    accent: "border-orange-500/40",
    summary:
      "Marking a creature starts an auto-attack that lands every 2000ms while you are within melee reach.",
    detail:
      "The original slice had no automation at all, and playtests showed the obvious mobile problem: keeping a thumb on an attack pad means you cannot also read the floor. The tick solves it by moving the baseline damage off the thumb, and it stays honest by being slow. Two seconds is roughly one telegraph window — you always have time to act between ticks.",
    rules: [
      "Melee reach only (1 tile). Out of range, the tick holds at full and fires the instant you close.",
      "Any manual ability resets the tick to zero — pressing buttons is always the higher-DPS play.",
      "Tick damage = 6 + floor(level × 0.9) + weapon damage.",
      "Rendered as a solid arc on the target reticle and a bar on the target plate.",
      "Toggleable per account. Off is a valid, higher-skill way to play.",
    ],
  },
  {
    id: "shove",
    icon: "✋",
    title: "Shove — drag to displace",
    accent: "border-cyan-500/40",
    summary:
      "Hold on an adjacent creature, drag one tile, release. The creature is pushed and its wind-up is cancelled.",
    detail:
      "Shove is the answer to the 'nowhere to run' problem in a grid game. Instead of only moving yourself, you can move the board. Crucially it interrupts a telegraph in progress, which makes it a defensive cooldown with a positional payoff: shove a Grave Wraith out of its own 3×3 bloom and you have both dodged and repositioned it for a Cleave.",
    rules: [
      "Same gesture on both platforms: touch drag, or mouse hold-left-click and release.",
      "Exactly 1 tile. Destination must be walkable, unoccupied and not inside the Sanctuary.",
      "You must be adjacent to the creature. 2.5s cooldown; creature is braced for 1.2s after.",
      "Cancels an in-progress wind-up and deletes the telegraph — the whole reason it exists.",
      "A live arrow preview paints the destination cyan (valid) or red (invalid) before you release.",
    ],
  },
  {
    id: "armor",
    icon: "🛡️",
    title: "Gear slots & flat armour",
    accent: "border-sky-500/40",
    summary:
      "Eight slots. Armour rating is the sum of equipped pieces and reduces physical damage by a flat value.",
    detail:
      "Percentage mitigation is unreadable on a phone — nobody computes 23% of 17 mid-telegraph. Flat mitigation is arithmetic a player does automatically: 17 damage against 6 armour is 11, every single time. That predictability is what lets a player decide to eat a hit rather than dodge it, which is the decision that makes armour interesting.",
    rules: [
      "Slots: head, neck, chest, weapon, off-hand, legs, feet, ring.",
      "damage = max(1, raw − armour). Armour can never fully negate a hit.",
      "Damage numbers show the reduction inline: '11 (-6)'.",
      "Heavy armour adds encumbrance: +5ms per point to the grid step, capped at +90ms.",
      "Ember Plate is 12 armour and 8 encumbrance — best mitigation, worst footwork.",
    ],
  },
  {
    id: "loot",
    icon: "✦",
    title: "Loot: spread, claim, filter",
    accent: "border-amber-500/40",
    summary:
      "Drops scatter over 1 sqm, lock to the top damage dealer for 60 seconds, and are hidden entirely if your filter excludes them.",
    detail:
      "Three separate problems solved by three separate rules. Spread stops a nine-item drop becoming an unreadable pile on one 44px tile. The 60-second claim stops the highest-level player in the zone from stealing every kill they did not earn. The filter is the mobile clarity valve: if you are farming Grave Silk, sewer pelts should not be drawn on your screen at all.",
    rules: [
      "Drops distribute across the walkable 3×3 around the corpse, corpse tile first.",
      "Top damage dealer holds an exclusive 60s claim; a lock icon and countdown arc render on the stack.",
      "After 60s the stack is free for anyone. Ground items decay after 3 minutes.",
      "Filtered-out items are not drawn, not tappable, and skipped by auto pick-up.",
      "Auto pick-up takes claimable, filtered loot the moment you step onto its tile.",
    ],
  },
  {
    id: "pz",
    icon: "🕊️",
    title: "Protected zones",
    accent: "border-emerald-500/40",
    summary:
      "Inside a Protected Zone creatures cannot land damage and PvP is hard-blocked. You may still attack out.",
    detail:
      "The Sanctuary is the only place in the world where the risk system switches off, and it has to be absolute: any ambiguity about whether you are safe makes banking loot feel like a gamble rather than a reward. Note the deliberate asymmetry requested for the slice — you can attack out of a PZ but nothing can attack in.",
    rules: [
      "Creatures may not path into a PZ and may not resolve damage against a player inside one.",
      "PvP attacks are rejected outright inside a PZ. No exceptions, no flagging.",
      "You may attack creatures standing outside the PZ from within it.",
      "Shoving a creature into a PZ is blocked — otherwise it becomes an untouchable-mob exploit.",
      "The zone border is drawn as a dashed gold ring, labelled, and shown on the HUD.",
    ],
  },
] as const;

/** Known-unresolved consequences of the rules above. Honesty beats polish in a bible. */
export const OPEN_ISSUES = [
  {
    title: "PZ safe-spotting is currently exploitable",
    body: "Attack-out / no-attack-in means a player can stand on the Sanctuary border and freely kill anything that wanders adjacent. Shipping mitigation: creatures leash and disengage after 4 seconds of being unable to reach their attacker, and regenerate to full. Implemented in the slice: creatures will not path adjacent to the PZ, and cannot be shoved into it.",
  },
  {
    title: "Auto-attack weakens the anti-bot argument",
    body: "A 2s tick is trivially automatable, so combat is no longer inherently bot-hostile. The load moves to telegraph dodging and shove usage — telemetry now flags accounts with abnormally low damage-taken-per-hour alongside high tick counts.",
  },
  {
    title: "Loot filters hide items from the economy",
    body: "If most players filter out common materials, those materials stop entering the market and low-level crafting stalls. We watch the ratio of dropped-to-collected per item and adjust drop rates, not filters — the filter must stay a pure player-clarity tool.",
  },
];

export const UX_SPECS = [
  { k: "Target frame rate", v: "60fps on iPhone 11 / Snapdragon 720G" },
  { k: "Cold start to input", v: "< 4.0s" },
  { k: "Session shape", v: "3–7 min loops, resumable mid-fight" },
  { k: "Portrait / landscape", v: "Both; HUD reflows, world scale constant" },
  { k: "Touch target minimum", v: "68pt (Apple HIG +30%)" },
  { k: "Idle HUD fade", v: "3.8s → 32% opacity, 450ms ease" },
  { k: "Network model", v: "Server-authoritative tick, 150ms client prediction" },
  { k: "Offline behaviour", v: "Local play continues; sync-on-reconnect every 5s" },
];

export const RISKS = [
  {
    risk: "Manual combat feels like work on a 6-inch screen",
    mitigation:
      "Resolved by the 2s auto-attack tick: baseline damage no longer requires a thumb, freeing the player to read telegraphs. Abilities remain manual on 68pt pads with haptic confirmation, and resetting the tick rewards active play without punishing passive play.",
    severity: "Resolved",
  },
  {
    risk: "Heavy armour becomes mandatory and flattens build variety",
    mitigation:
      "Encumbrance is the counterweight: +5ms per point of step time, capped at +90ms. In the Grey Barrow, where every wraith telegraphs a 3×3, a +40ms step is measurably worse than 12 points of mitigation. Light builds win in high-telegraph zones, heavy builds win in swarm zones.",
    severity: "Medium",
  },
  {
    risk: "Full-loot death drives away casual players",
    mitigation:
      "Remnants uses partial loss: XP and carried gold only, never equipped gear — except in Emberfield and the Grey Barrow, which are opt-in and clearly labelled at the region border.",
    severity: "High",
  },
  {
    risk: "Player economy collapses from bot farming",
    mitigation:
      "Manual-input combat is inherently bot-hostile: telegraph dodging requires reactive play. Telemetry flags perfect-dodge-rate outliers automatically.",
    severity: "Medium",
  },
  {
    risk: "Telegraph spam becomes visual noise in group fights",
    mitigation:
      "Max 3 concurrent zones rendered per tile; overlapping zones merge to the highest-damage colour. Player-cast telegraphs render at 60% alpha of hostile ones.",
    severity: "Medium",
  },
];

export const ROADMAP = [
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
      "Market v1",
    ],
  },
  { phase: "Alpha", state: "next", items: ["Real-time multiplayer tick", "PvP in Emberfield", "Crafting", "Guild claims"] },
  { phase: "Beta", state: "later", items: ["Housing", "Server-first world bosses", "Cross-play accounts", "Spectator mode"] },
  { phase: "Launch", state: "later", items: ["Seasonal Barrow resets", "Cosmetic-only monetisation", "Creator API"] },
];
