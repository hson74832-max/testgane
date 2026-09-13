import {
  ABILITIES,
  COMBAT,
  ITEMS,
  MONSTERS,
  NPCS,
  NPC_FERRY_COST,
  NPC_HEAL_COST,
  NPC_STOCK,
  NPC_TALK_RANGE,
  RIVALS,
  SKILLS,
  VOCATIONS,
  FERRY,
  type AbilityDef,
  type Loadout,
  type MonsterDef,
  type NpcDef,
  levelFromXp,
  mitigate,
  statsForLevel,
  stepMsFor,
  xpForLevel,
} from "./content";
import {
  CRYPT,
  TEMPLE,
  blocksProjectile,
  gateDest,
  generateCrypt,
  generateMap,
  inSafeZone,
  isWalkable,
  regionAt,
  regionNameAt,
  type WorldMap,
} from "./world";

export type StatusKey = "poison" | "burn" | "slow" | "ward";

export type Status = { key: StatusKey; until: number; nextTick?: number; power: number };

export type Monster = {
  id: number;
  def: MonsterDef;
  x: number;
  y: number;
  /** Floor. 0 = surface, 1 = Barrow Crypt. */
  z: number;
  rx: number;
  ry: number;
  hp: number;
  maxHp: number;
  /** HP at spawn — out-of-combat wounds close up to here, rival marks stay ledger-only. */
  spawnHp: number;
  aggro: boolean;
  /** Per-individual aggro radius: base aggroRange ± 1, so packs don't sync-aggro. */
  sense: number;
  nextMoveAt: number;
  nextAttackAt: number;
  nextHealAt: number;
  windupUntil: number;
  hitFlash: number;
  statuses: Status[];
  dying: number;
  /** Damage ledger — decides who owns the drop for LOOT_PROTECT_MS. */
  damageBy: Record<string, number>;
  /** Shove immunity so a creature can't be chain-pushed forever. */
  pushLockUntil: number;
  shoveFrom: { x: number; y: number } | null;
};

export type Telegraph = {
  id: number;
  tiles: { x: number; y: number }[];
  /** Floor the geometry lives on — resolving checks it against the player's. */
  z: number;
  startAt: number;
  resolveAt: number;
  color: string;
  damage: number;
  source: "monster" | "player";
  sourceId: number;
  status?: StatusKey;
  resolved: boolean;
};

export type FloatText = {
  id: number;
  x: number;
  y: number;
  text: string;
  color: string;
  born: number;
  crit?: boolean;
};

/** A single stack of loot lying on one tile. */
export type GroundItem = {
  id: number;
  x: number;
  y: number;
  z: number;
  itemKey: string;
  qty: number;
  /** Top damage dealer. Only they may loot until protectedUntil elapses. */
  owner: string;
  protectedUntil: number;
  born: number;
  /** Slight render offset so a 1-sqm spread reads as a scatter, not a stack. */
  jx: number;
  jy: number;
};

export type Projectile = {
  id: number;
  fx: number;
  fy: number;
  tx: number;
  ty: number;
  z: number;
  born: number;
  duration: number;
  color: string;
};

export type PlayerState = {
  name: string;
  x: number;
  y: number;
  z: number;
  rx: number;
  ry: number;
  facing: { x: number; y: number };
  hp: number;
  maxHp: number;
  mana: number;
  maxMana: number;
  level: number;
  xp: number;
  gold: number;
  kills: number;
  deaths: number;
  vocation: string;
  skills: Record<string, number>;
  skillPoints: number;
  statuses: Status[];
  cooldowns: Record<string, number>;
  castUntil: number;
  castKey: string | null;
  nextStepAt: number;
  hitFlash: number;
  dead: boolean;
  deadUntil: number;
  wardHp: number;
  /** Derived from equipped gear. */
  armor: number;
  heavy: number;
  weaponDamage: number;
  pushReadyAt: number;
};

export type GameEvent =
  | { type: "loot"; items: { itemKey: string; qty: number }[]; gold: number }
  | { type: "kill"; monster: string; xp: number }
  | { type: "levelup"; level: number }
  | { type: "death"; killedBy: string; xpLost: number; goldDropped: number; x: number; y: number }
  | { type: "damaged"; amount: number; blocked: number }
  | { type: "region"; name: string }
  | { type: "rift"; name: string }
  | { type: "vocation"; name: string; blurb: string }
  | { type: "push"; ok: boolean; reason?: string }
  | { type: "denied"; reason: string }
  | { type: "blocked" }
  | { type: "nomana" };

let uid = 1;
const nid = () => uid++;

/**
 * All tuning lives in content.ts COMBAT (exported to content.json for Godot):
 * spawn tables via world.REGIONS.spawns + world.CRYPT.SPAWNS. Adding a
 * creature, spell, consumable or skill is a data edit — no code here.
 */

export class GameEngine {
  /** Floor 0 = surface, floor 1 = Barrow Crypt. `map` mirrors the player's floor. */
  maps: Record<number, WorldMap>;
  map: WorldMap;
  player: PlayerState;
  monsters: Monster[] = [];
  telegraphs: Telegraph[] = [];
  floats: FloatText[] = [];
  ground: GroundItem[] = [];
  projectiles: Projectile[] = [];
  targetId: number | null = null;
  /** Auto-attack tick clock for the Marked creature. */
  markedAt = 0;
  nextAutoAt = 0;
  autoAttack = true;
  autoPickup = true;
  lootFilter: Set<string> = new Set();
  now = 0;
  heldDir: { x: number; y: number } | null = null;
  events: GameEvent[] = [];
  lastRegion = "";
  /** Live shove preview driven by the drag gesture. */
  pushPreview: { from: { x: number; y: number }; to: { x: number; y: number }; valid: boolean } | null =
    null;
  /** Rift re-trigger cooldown against bounce (Godot parity). */
  private gateCdUntil = 0;
  private nextRegen = 0;
  private nextSpawnCheck = 0;
  camX = 0;
  camY = 0;

  constructor(
    name: string,
    seed = 1337,
    saved?: Partial<PlayerState>,
    loadout: Loadout = { armor: 0, heavy: 0, weaponDamage: 0 },
    opts?: { autoPickup?: boolean; autoAttack?: boolean; lootFilter?: string[] },
  ) {
    this.maps = { 0: generateMap(seed), 1: generateCrypt(seed) };
    const z = saved?.z ?? 0;
    this.map = this.maps[z] ?? this.maps[0];
    const level = saved?.level ?? 1;
    this.player = {
      name,
      x: saved?.x ?? TEMPLE.x,
      y: saved?.y ?? TEMPLE.y,
      z,
      rx: saved?.x ?? TEMPLE.x,
      ry: saved?.y ?? TEMPLE.y,
      facing: { x: 0, y: 1 },
      hp: saved?.hp ?? 0,
      maxHp: 0,
      mana: saved?.mana ?? 0,
      maxMana: 0,
      level,
      xp: saved?.xp ?? 0,
      gold: saved?.gold ?? 50,
      kills: saved?.kills ?? 0,
      deaths: saved?.deaths ?? 0,
      vocation: saved?.vocation ?? "warrior",
      skills: saved?.skills ?? {},
      skillPoints: saved?.skillPoints ?? 0,
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
      pushReadyAt: 0,
    };
    if (!VOCATIONS[this.player.vocation]) this.player.vocation = "warrior";
    // Vocation-scaled growth with skill ranks folded in (Godot parity).
    this.applyVocationStats(false);
    if (saved?.hp == null) this.player.hp = this.player.maxHp;
    if (saved?.mana == null) this.player.mana = this.player.maxMana;
    this.autoPickup = opts?.autoPickup ?? true;
    this.autoAttack = opts?.autoAttack ?? true;
    this.lootFilter = new Set(opts?.lootFilter ?? Object.keys(ITEMS));
    this.camX = this.player.x;
    this.camY = this.player.y;
    this.populate();
  }

  // ---------------------------------------------------------- configuration
  setLoadout(l: Loadout) {
    this.player.armor = l.armor;
    this.player.heavy = l.heavy;
    this.player.weaponDamage = l.weaponDamage;
  }

  setLootFilter(keys: string[]) {
    this.lootFilter = new Set(keys);
  }

  setAutoPickup(v: boolean) {
    this.autoPickup = v;
  }

  setAutoAttackEnabled(v: boolean) {
    this.autoAttack = v;
    if (v) this.nextAutoAt = this.now + COMBAT.AUTO_ATTACK_MS;
  }

  get stepMs() {
    // Swiftness reduction is data (skills.*.effect.stepMs); floor from content.
    return Math.max(COMBAT.STEP_MIN_MS, stepMsFor(this.player.heavy) - this.skillBonus("stepMs"));
  }

  // ------------------------------------------------- vocations + skill tree
  /** Summed per-rank skill payload (skills.*.effect). */
  private skillBonus(key: "maxHp" | "maxMana" | "stepMs" | "damage" | "ward") {
    let total = 0;
    for (const [k, rank] of Object.entries(this.player.skills)) {
      total += (SKILLS[k]?.effect?.[key] ?? 0) * rank;
    }
    return total;
  }
  private applyVocationStats(keepCurrent: boolean) {
    const p = this.player;
    const base = statsForLevel(p.level);
    const v = VOCATIONS[p.vocation] ?? VOCATIONS.warrior;
    p.maxHp = Math.max(1, Math.floor(base.maxHp * v.hpMult)) + this.skillBonus("maxHp");
    p.maxMana = Math.max(1, Math.floor(base.maxMana * v.manaMult)) + this.skillBonus("maxMana");
    if (!keepCurrent) {
      p.hp = p.maxHp;
      p.mana = p.maxMana;
    } else {
      p.hp = Math.min(p.hp, p.maxHp);
      p.mana = Math.min(p.mana, p.maxMana);
    }
  }

  /** Switch path. Growth re-applies, current hp/mana are clamped (Godot parity). */
  setVocation(key: string): boolean {
    const p = this.player;
    if (!VOCATIONS[key] || key === p.vocation) return false;
    p.vocation = key;
    this.applyVocationStats(true);
    const def = VOCATIONS[key];
    this.push_text(String(def.name).toUpperCase(), p.x, p.y - 0.6, "#ffd166", true);
    this.events.push({ type: "vocation", name: def.name, blurb: def.blurb });
    return true;
  }

  skillRank(key: string): number {
    return this.player.skills[key] ?? 0;
  }

  /** Spend one point. Returns the new rank, or -1 when rejected. */
  spendSkill(key: string): number {
    const p = this.player;
    const def = SKILLS[key];
    if (!def) return -1;
    const rank = this.skillRank(key);
    if (p.skillPoints < 1 || rank >= def.max) return -1;
    p.skillPoints -= 1;
    p.skills[key] = rank + 1;
    this.applyVocationStats(true);
    if (def.effect.maxHp) p.hp = Math.min(p.maxHp, p.hp + def.effect.maxHp);
    if (def.effect.maxMana) p.mana = Math.min(p.maxMana, p.mana + def.effect.maxMana);
    this.push_text(`${def.name} ${rank + 1}`, p.x, p.y - 0.6, "#ffd166", true);
    return rank + 1;
  }

  private tickRange() {
    const v = VOCATIONS[this.player.vocation] ?? VOCATIONS.warrior;
    return v.tickRange;
  }

  // ---------------------------------------------------------------- floors
  private switchFloor(z: number) {
    this.map = this.maps[z] ?? this.maps[0];
  }

  // ---------------------------------------------------------------- spawning
  private populate() {
    for (let i = 0; i < COMBAT.MAX_MONSTERS; i++) this.spawnMonster(true, 0);
    for (let i = 0; i < COMBAT.CRYPT_MONSTERS; i++) this.spawnMonster(true, 1);
  }

  private aliveOn(fz: number) {
    return this.monsters.filter((m) => m.z === fz && !m.dying).length;
  }

  private spawnMonster(initial = false, fz = 0) {
    const map = this.maps[fz];
    if (!map) return;
    const w = map.tiles[0].length;
    const h = map.tiles.length;
    const p = this.player;
    for (let attempt = 0; attempt < 40; attempt++) {
      const x = 1 + Math.floor(Math.random() * (w - 2));
      const y = 1 + Math.floor(Math.random() * (h - 2));
      if (!isWalkable(map, x, y)) continue;
      if (fz === 0 && inSafeZone(x, y)) continue;
      if (!initial && fz === p.z) {
        const dist = Math.max(Math.abs(x - p.x), Math.abs(y - p.y));
        if (dist < 9) continue;
        // one soul per tile: never spawn onto the player
        if (x === p.x && y === p.y) continue;
      }
      if (this.occupiedZ(x, y, fz)) continue;
      const key = this.pickSpawnKey(fz, x, y);
      const def = MONSTERS[key];
      if (!def) continue;
      // ~RIVAL_MARK_CHANCE of spawns arrive pre-tagged by a rival adventurer.
      const damageBy: Record<string, number> = {};
      let hp = def.hp;
      if (Math.random() < COMBAT.RIVAL_MARK_CHANCE) {
        const rival = RIVALS[Math.floor(Math.random() * RIVALS.length)];
        const chunk = Math.floor(
          def.hp * (COMBAT.RIVAL_MARK_MIN + Math.random() * COMBAT.RIVAL_MARK_SPREAD),
        );
        damageBy[rival] = chunk;
        hp = Math.max(1, def.hp - chunk);
      }
      const jitter = COMBAT.SENSE_JITTER;
      this.monsters.push({
        id: nid(),
        def,
        x,
        y,
        z: fz,
        rx: x,
        ry: y,
        hp,
        maxHp: def.hp,
        spawnHp: hp,
        aggro: false,
        sense: Math.max(
          COMBAT.SENSE_MIN,
          Math.min(COMBAT.SENSE_MAX, def.aggroRange + Math.floor(Math.random() * (jitter * 2 + 1)) - jitter),
        ),
        nextMoveAt: 0,
        nextAttackAt: 0,
        nextHealAt: 0,
        windupUntil: 0,
        hitFlash: 0,
        statuses: [],
        dying: 0,
        damageBy,
        pushLockUntil: 0,
        shoveFrom: null,
      });
      return;
    }
  }

  private pickSpawnKey(fz: number, x: number, y: number): string {
    const table = fz === 0 ? regionAt(x, y).spawns : CRYPT.SPAWNS;
    const total = table.reduce((a, s) => a + s.weight, 0);
    let roll = Math.random() * total;
    let key = table[0].key;
    for (const s of table) {
      roll -= s.weight;
      if (roll <= 0) {
        key = s.key;
        break;
      }
    }
    return key;
  }

  // ------------------------------------------------------------------ input
  setHeld(dir: { x: number; y: number } | null) {
    this.heldDir = dir;
  }

  /** Sanctuary rule (Godot parity): no offensive action may originate in a PZ. */
  private isPacified() {
    return inSafeZone(this.player.x, this.player.y);
  }

  private denyPacified() {
    this.push_text("pacified", this.player.x, this.player.y - 0.4, "#ffe08a");
    this.events.push({ type: "denied", reason: "Pacified — step out of the Sanctuary to fight" });
  }

  /** Marking a creature starts the 2s auto-attack clock. */
  setTarget(id: number | null) {
    if (id != null && this.isPacified()) {
      this.denyPacified();
      return;
    }
    if (this.targetId !== id) {
      this.targetId = id;
      this.markedAt = this.now;
      this.nextAutoAt = this.now + COMBAT.AUTO_ATTACK_MS;
    }
  }

  tapTile(tx: number, ty: number) {
    const m = this.monsterAt(tx, ty);
    if (m) {
      this.setTarget(m.id);
      return;
    }
    this.lootTile(tx, ty);
  }

  ability(index: number) {
    const def = ABILITIES[index];
    if (def) this.castAbility(def);
  }

  monsterAt(x: number, y: number, fz = this.player.z) {
    return this.monsters.find((m) => m.x === x && m.y === y && m.z === fz && m.dying === 0) ?? null;
  }

  // ------------------------------------------------------------------- push
  /** Live validity check used to paint the drag preview. */
  canPush(m: Monster, tx: number, ty: number): { ok: boolean; reason?: string } {
    const p = this.player;
    if (p.dead) return { ok: false, reason: "dead" };
    if (this.now < p.pushReadyAt) return { ok: false, reason: "Shove recharging" };
    if (this.now < m.pushLockUntil) return { ok: false, reason: "Braced" };
    if (m.z !== p.z) return { ok: false, reason: "Step closer to shove" };
    const reach = Math.max(Math.abs(m.x - p.x), Math.abs(m.y - p.y));
    if (reach > 1) return { ok: false, reason: "Step closer to shove" };
    const d = Math.max(Math.abs(tx - m.x), Math.abs(ty - m.y));
    if (d !== 1 || (tx === m.x && ty === m.y)) return { ok: false, reason: "Shove is exactly 1 tile" };
    if (!isWalkable(this.map, tx, ty)) return { ok: false, reason: "Blocked" };
    if (this.monsterAt(tx, ty)) return { ok: false, reason: "Occupied" };
    if (this.npcBlockedZ(tx, ty, m.z)) return { ok: false, reason: "Occupied" };
    if (tx === p.x && ty === p.y) return { ok: false, reason: "That is your tile" };
    if (inSafeZone(tx, ty)) return { ok: false, reason: "Cannot shove into Sanctuary" };
    return { ok: true };
  }

  previewPush(m: Monster | null, tx: number, ty: number) {
    if (!m) {
      this.pushPreview = null;
      return;
    }
    const v = this.canPush(m, tx, ty);
    this.pushPreview = { from: { x: m.x, y: m.y }, to: { x: tx, y: ty }, valid: v.ok };
  }

  clearPushPreview() {
    this.pushPreview = null;
  }

  /** Shove a creature one tile. Cancels its wind-up — the core tactical payoff. */
  push(m: Monster, tx: number, ty: number): { ok: boolean; reason?: string } {
    const v = this.canPush(m, tx, ty);
    this.pushPreview = null;
    if (!v.ok) {
      if (v.reason) this.push_text(v.reason, m.x, m.y, "#94a3b8");
      this.events.push({ type: "push", ok: false, reason: v.reason });
      return v;
    }
    m.shoveFrom = { x: m.x, y: m.y };
    m.x = tx;
    m.y = ty;
    m.aggro = true;
    m.pushLockUntil = this.now + 1200;
    m.nextMoveAt = Math.max(m.nextMoveAt, this.now + 350);
    // Interrupting the telegraph is the whole reason shove exists.
    if (this.now < m.windupUntil) {
      m.windupUntil = 0;
      this.telegraphs = this.telegraphs.filter(
        (t) => !(t.source === "monster" && t.sourceId === m.id && !t.resolved),
      );
      this.push_text("INTERRUPTED", tx, ty - 0.4, "#4cc9f0", true);
    } else {
      this.push_text("shoved", tx, ty - 0.3, "#cbd5e1");
    }
    this.player.pushReadyAt = this.now + COMBAT.PUSH_CD_MS;
    this.events.push({ type: "push", ok: true });
    return { ok: true };
  }

  // ----------------------------------------------------------------- helpers
  private occupiedZ(x: number, y: number, fz: number) {
    return this.monsters.some((m) => m.x === x && m.y === y && m.z === fz && m.dying === 0);
  }

  private npcBlockedZ(x: number, y: number, fz: number) {
    return NPCS.some((n) => n.pos[0] === x && n.pos[1] === y && n.pos[2] === fz);
  }

  private push_text(text: string, x: number, y: number, color: string, crit = false) {
    this.floats.push({ id: nid(), x, y, text, color, born: this.now, crit });
    if (this.floats.length > 40) this.floats.shift();
  }

  target(): Monster | null {
    if (this.targetId == null) return null;
    const p = this.player;
    return (
      this.monsters.find((m) => m.id === this.targetId && m.dying === 0 && m.z === p.z) ?? null
    );
  }

  cooldownPct(key: string) {
    const def = ABILITIES.find((a) => a.key === key);
    if (!def) return 0;
    const ready = this.player.cooldowns[key] ?? 0;
    if (this.now >= ready) return 0;
    return (ready - this.now) / def.cooldown;
  }

  pushCooldownPct() {
    const left = this.player.pushReadyAt - this.now;
    return left <= 0 ? 0 : left / COMBAT.PUSH_CD_MS;
  }

  /** 0→1 progress toward the next auto-attack tick. */
  autoTickPct() {
    if (!this.autoAttack || !this.target()) return 0;
    const left = this.nextAutoAt - this.now;
    if (left <= 0) return 1;
    return 1 - left / COMBAT.AUTO_ATTACK_MS;
  }

  get inProtectedZone() {
    return inSafeZone(this.player.x, this.player.y);
  }

  // --------------------------------------------------------------- abilities
  private castAbility(def: AbilityDef) {
    const p = this.player;
    if (p.dead) return;
    if (this.now < (p.cooldowns[def.key] ?? 0)) return;
    // Ward is defensive and stays; everything offensive is pacified in a PZ.
    if (def.shape !== "self" && this.isPacified()) {
      this.denyPacified();
      return;
    }
    if (p.mana < def.manaCost) {
      this.events.push({ type: "nomana" });
      this.push_text("no mana", p.x, p.y, "#7dd3fc");
      return;
    }

    if (def.shape === "self") {
      p.mana -= def.manaCost;
      p.cooldowns[def.key] = this.now + def.cooldown;
      p.wardHp =
        COMBAT.WARD_BASE + p.level * COMBAT.WARD_PER_LEVEL + this.skillBonus("ward");
      p.statuses = p.statuses.filter((s) => s.key !== "ward");
      p.statuses.push({ key: "ward", until: this.now + COMBAT.WARD_MS, power: p.wardHp });
      this.push_text("WARD", p.x, p.y, "#06d6a0");
      return;
    }

    const v = VOCATIONS[p.vocation] ?? VOCATIONS.warrior;
    const bonus = statsForLevel(p.level).damageBonus + p.weaponDamage + this.skillBonus("damage");

    // Cleave hits the 8 tiles around you and needs no mark (Godot parity).
    if (def.shape === "radial") {
      p.mana -= def.manaCost;
      p.cooldowns[def.key] = this.now + def.cooldown;
      p.castUntil = this.now + def.windup;
      p.castKey = def.key;
      this.nextAutoAt = this.now + COMBAT.AUTO_ATTACK_MS;
      const tiles: { x: number; y: number }[] = [];
      for (let dy = -1; dy <= 1; dy++)
        for (let dx = -1; dx <= 1; dx++) {
          if (dx === 0 && dy === 0) continue;
          tiles.push({ x: p.x + dx, y: p.y + dy });
        }
      this.telegraphs.push({
        id: nid(),
        tiles,
        z: p.z,
        startAt: this.now,
        resolveAt: this.now + def.windup,
        color: def.color,
        damage: Math.max(1, Math.round((def.damage + bonus) * v.spellMult)),
        source: "player",
        sourceId: 0,
        resolved: false,
      });
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
    p.facing = { x: Math.sign(tgt.x - p.x), y: Math.sign(tgt.y - p.y) };

    p.mana -= def.manaCost;
    p.cooldowns[def.key] = this.now + def.cooldown;
    p.castUntil = this.now + def.windup;
    p.castKey = def.key;
    // A manual swing resets the auto clock: manual play is strictly faster.
    this.nextAutoAt = this.now + COMBAT.AUTO_ATTACK_MS;

    const resolveAt = this.now + def.windup;

    if (def.key === "bolt") {
      if (!this.hasSight(p.x, p.y, tgt.x, tgt.y)) {
        this.push_text("blocked", p.x, p.y - 0.4, "#94a3b8");
        return;
      }
      this.projectiles.push({
        id: nid(),
        fx: p.x,
        fy: p.y,
        tx: tgt.x,
        ty: tgt.y,
        z: p.z,
        born: this.now,
        duration: def.windup + 120,
        color: def.color,
      });
      this.telegraphs.push({
        id: nid(),
        tiles: [{ x: tgt.x, y: tgt.y }],
        z: p.z,
        startAt: this.now,
        resolveAt: resolveAt + 120,
        color: def.color,
        damage: Math.max(1, Math.round((def.damage + bonus) * v.spellMult)),
        source: "player",
        sourceId: tgt.id,
        resolved: false,
      });
    } else {
      this.telegraphs.push({
        id: nid(),
        tiles: [{ x: tgt.x, y: tgt.y }],
        z: p.z,
        startAt: this.now,
        resolveAt,
        color: def.color,
        // Steel school: the melee multiplier bends Strike (Godot parity).
        damage: Math.max(1, Math.round((def.damage + bonus) * v.meleeMult)),
        source: "player",
        sourceId: tgt.id,
        resolved: false,
      });
    }
  }

  /** Line of sight for projectiles. Endpoints excluded; walls block (Godot parity). */
  hasSight(ax: number, ay: number, bx: number, by: number) {
    const dx = Math.abs(bx - ax);
    const dy = Math.abs(by - ay);
    const steps = Math.max(dx, dy);
    if (steps <= 1) return true;
    for (let i = 1; i < steps; i++) {
      const t = i / steps;
      const cx = Math.round(ax + (bx - ax) * t);
      const cy = Math.round(ay + (by - ay) * t);
      if (blocksProjectile(this.map, cx, cy)) return false;
    }
    return true;
  }

  /** The 2-second tick. Vocation profile bends reach, base and school. */
  private autoSwing(m: Monster) {
    const p = this.player;
    const v = VOCATIONS[p.vocation] ?? VOCATIONS.warrior;
    if (v.tickShot) {
      // Archer: arrows fly the tick range but walls stop them. No steel bonus.
      if (!this.hasSight(p.x, p.y, m.x, m.y)) {
        this.push_text("blocked", p.x, p.y - 0.55, "#94a3b8");
        return;
      }
      this.projectiles.push({
        id: nid(),
        fx: p.x,
        fy: p.y,
        tx: m.x,
        ty: m.y,
        z: p.z,
        born: this.now,
        duration: 150,
        color: "#fff2bf",
      });
      this.damageMonster(
        m,
        v.tickBase + Math.floor(p.level * v.tickScale) + this.skillBonus("damage"),
      );
    } else {
      const base =
        v.tickBase + Math.floor(p.level * v.tickScale) + p.weaponDamage + this.skillBonus("damage");
      this.damageMonster(m, Math.max(1, Math.round(base * v.meleeMult)));
    }
    this.push_text("tick", p.x, p.y - 0.55, "#94a3b8");
  }

  private damageMonster(m: Monster, amount: number) {
    const crit = Math.random() < COMBAT.CRIT_CHANCE;
    const dmg = Math.max(1, Math.round(crit ? amount * COMBAT.CRIT_MULT : amount));
    m.hp -= dmg;
    m.hitFlash = this.now + 160;
    m.aggro = true;
    m.damageBy[this.player.name] = (m.damageBy[this.player.name] ?? 0) + dmg;
    this.push_text(crit ? `${dmg}!` : `${dmg}`, m.x, m.y, crit ? "#ffd166" : "#fff", crit);
    if (m.hp <= 0) this.killMonster(m);
  }

  /** Who out-damaged everyone else on this corpse. */
  private claimant(m: Monster) {
    let best = this.player.name;
    let bestVal = -1;
    for (const [k, v] of Object.entries(m.damageBy)) {
      if (v > bestVal) {
        best = k;
        bestVal = v;
      }
    }
    return best;
  }

  private killMonster(m: Monster) {
    m.dying = this.now;
    const p = this.player;
    p.kills += 1;
    const xp = m.def.xp + Math.floor(Math.random() * 4);
    p.xp += xp;
    this.push_text(`+${xp} xp`, m.x, m.y - 0.4, "#a3e635");
    this.events.push({ type: "kill", monster: m.def.name, xp });

    const owner = this.claimant(m);
    const protectedUntil = this.now + COMBAT.LOOT_PROTECT_MS;

    const drops: { itemKey: string; qty: number }[] = [];
    for (const l of m.def.loot) {
      if (Math.random() < l.chance) {
        const qty = l.qty[0] + Math.floor(Math.random() * (l.qty[1] - l.qty[0] + 1));
        drops.push({ itemKey: l.itemKey, qty });
      }
    }
    const gold = m.def.gold[0] + Math.floor(Math.random() * (m.def.gold[1] - m.def.gold[0] + 1));
    if (gold > 0) drops.push({ itemKey: "gold", qty: gold });

    // Spread the drop across the 3x3 around the corpse so stacks stay readable.
    const spread: { x: number; y: number }[] = [];
    for (let dy = -1; dy <= 1; dy++)
      for (let dx = -1; dx <= 1; dx++) {
        const x = m.x + dx;
        const y = m.y + dy;
        if (isWalkable(this.maps[m.z], x, y)) spread.push({ x, y });
      }
    if (spread.length === 0) spread.push({ x: m.x, y: m.y });
    // Corpse tile first, then outward — the common case stays a single tap.
    spread.sort((a, b) => {
      const da = Math.abs(a.x - m.x) + Math.abs(a.y - m.y);
      const db = Math.abs(b.x - m.x) + Math.abs(b.y - m.y);
      return da - db;
    });

    drops.forEach((d, i) => {
      const tile = spread[i % spread.length];
      this.ground.push({
        id: nid(),
        x: tile.x,
        y: tile.y,
        z: m.z,
        itemKey: d.itemKey,
        qty: d.qty,
        owner,
        protectedUntil,
        born: this.now,
        jx: (Math.random() - 0.5) * 0.42,
        jy: (Math.random() - 0.5) * 0.32,
      });
    });

    if (owner !== p.name) {
      this.push_text(`claimed by ${owner}`, m.x, m.y - 0.75, "#f87171");
    }

    const newLevel = levelFromXp(p.xp);
    if (newLevel > p.level) {
      p.skillPoints += newLevel - p.level;
      p.level = newLevel;
      this.applyVocationStats(false);
      this.push_text("LEVEL UP", p.x, p.y - 0.6, "#ffd166", true);
      this.events.push({ type: "levelup", level: newLevel });
    }
    if (this.targetId === m.id) this.targetId = null;
  }

  // ------------------------------------------------------------------- loot
  /** Filtered out = invisible on the floor and skipped by auto-pickup. */
  isVisibleLoot(g: GroundItem) {
    return this.lootFilter.has(g.itemKey);
  }

  canLoot(g: GroundItem) {
    return g.owner === this.player.name || this.now >= g.protectedUntil;
  }

  visibleGround() {
    const pz = this.player.z;
    return this.ground.filter((g) => g.z === pz && this.isVisibleLoot(g));
  }

  private takeGround(g: GroundItem, silent = false) {
    const p = this.player;
    if (!this.canLoot(g)) {
      if (!silent) {
        const left = Math.ceil((g.protectedUntil - this.now) / 1000);
        this.push_text(`${g.owner} · ${left}s`, g.x, g.y - 0.4, "#f87171");
        this.events.push({ type: "denied", reason: `Loot protected for ${g.owner} (${left}s)` });
      }
      return false;
    }
    this.ground = this.ground.filter((x) => x.id !== g.id);
    if (g.itemKey === "gold") {
      p.gold += g.qty;
      this.push_text(`+${g.qty}g`, g.x, g.y, "#fbbf24");
      this.events.push({ type: "loot", items: [], gold: g.qty });
    } else {
      this.push_text(`+${ITEMS[g.itemKey]?.glyph ?? ""}${g.qty > 1 ? ` x${g.qty}` : ""}`, g.x, g.y, "#a3e635");
      this.events.push({ type: "loot", items: [{ itemKey: g.itemKey, qty: g.qty }], gold: 0 });
    }
    return true;
  }

  /** Manual loot of one tile (tap). Must be within 1 tile, same floor. */
  lootTile(x: number, y: number) {
    const p = this.player;
    const d = Math.max(Math.abs(x - p.x), Math.abs(y - p.y));
    if (d > 1) return;
    const here = this.ground.filter(
      (g) => g.x === x && g.y === y && g.z === p.z && this.isVisibleLoot(g),
    );
    for (const g of here) this.takeGround(g);
  }

  /** Sweep everything claimable and filtered within 1 tile, same floor. */
  lootAllNearby() {
    const p = this.player;
    const near = this.ground.filter(
      (g) =>
        g.z === p.z &&
        this.isVisibleLoot(g) &&
        Math.max(Math.abs(g.x - p.x), Math.abs(g.y - p.y)) <= 1,
    );
    if (near.length === 0) {
      this.push_text("nothing here", p.x, p.y - 0.4, "#94a3b8");
      return;
    }
    let got = 0;
    for (const g of near) if (this.takeGround(g, true)) got += 1;
    if (got === 0) {
      const blocked = near[0];
      const left = Math.ceil((blocked.protectedUntil - this.now) / 1000);
      this.push_text(`${blocked.owner} · ${left}s`, p.x, p.y - 0.4, "#f87171");
      this.events.push({ type: "denied", reason: `Loot protected for ${blocked.owner} (${left}s)` });
    }
  }

  private autoPickupAt(x: number, y: number) {
    if (!this.autoPickup) return;
    const pz = this.player.z;
    const here = this.ground.filter(
      (g) => g.x === x && g.y === y && g.z === pz && this.isVisibleLoot(g),
    );
    for (const g of here) this.takeGround(g, true);
  }

  // -------------------------------------------------------------------- NPCs
  npcAt(x: number, y: number, fz = this.player.z): NpcDef | null {
    return NPCS.find((n) => n.pos[0] === x && n.pos[1] === y && n.pos[2] === fz) ?? null;
  }

  canTalkNpc(n: NpcDef) {
    const p = this.player;
    if (n.pos[2] !== p.z) return false;
    return Math.max(Math.abs(n.pos[0] - p.x), Math.abs(n.pos[1] - p.y)) <= NPC_TALK_RANGE;
  }

  private atCounter(role: NpcDef["role"]): NpcDef | null {
    const npc = NPCS.find((n) => n.role === role) ?? null;
    if (!npc || !this.canTalkNpc(npc)) {
      this.events.push({ type: "denied", reason: "Too far from the counter." });
      return null;
    }
    return npc;
  }

  /** Buy from Sister Mallow. The item travels to the server via the loot queue. */
  npcBuy(itemKey: string): { ok: boolean; reason?: string } {
    const p = this.player;
    if (!NPC_STOCK.includes(itemKey)) return { ok: false, reason: "Not stocked." };
    if (!this.atCounter("trader")) return { ok: false, reason: "Too far from the counter." };
    const cost = Math.max(1, ITEMS[itemKey]?.basePrice ?? 1);
    if (p.gold < cost) return { ok: false, reason: `Not enough gold (need ${cost}).` };
    p.gold -= cost;
    // Acquisition flows through the same pipe as ground loot so the server
    // inventory and the local view stay consistent.
    this.events.push({ type: "loot", items: [{ itemKey, qty: 1 }], gold: 0 });
    this.push_text(`-${cost}g`, p.x, p.y, "#fbbf24");
    return { ok: true };
  }

  npcHeal(): { ok: boolean; reason?: string } {
    const p = this.player;
    if (!this.atCounter("healer")) return { ok: false, reason: "Too far from the counter." };
    const needs = p.hp < p.maxHp || p.statuses.some((s) => ["poison", "burn", "slow"].includes(s.key));
    if (!needs) return { ok: false, reason: "Brother Ansel: you feel whole already." };
    if (p.gold < NPC_HEAL_COST) return { ok: false, reason: `Not enough gold (need ${NPC_HEAL_COST}).` };
    p.gold -= NPC_HEAL_COST;
    p.hp = p.maxHp;
    p.statuses = p.statuses.filter((s) => !["poison", "burn", "slow"].includes(s.key));
    this.push_text("mended", p.x, p.y, "#4ade80");
    return { ok: true };
  }

  npcTravel(destKey: string): { ok: boolean; reason?: string } {
    const p = this.player;
    if (!this.atCounter("ferry")) return { ok: false, reason: "Too far from the counter." };
    const dest = FERRY.find((f) => f.key === destKey);
    if (!dest) return { ok: false, reason: "No such crossing." };
    if (p.gold < NPC_FERRY_COST) return { ok: false, reason: `Not enough gold (need ${NPC_FERRY_COST}).` };
    const spot = this.nearestOpenTile({ x: dest.pos[0], y: dest.pos[1], z: dest.pos[2] });
    if (!spot) return { ok: false, reason: "The crossing is blocked." };
    p.gold -= NPC_FERRY_COST;
    p.x = spot.x;
    p.y = spot.y;
    p.z = spot.z;
    this.switchFloor(spot.z);
    this.push_text("RIFT", spot.x, spot.y, "#8ab4ff", true);
    this.events.push({ type: "rift", name: dest.name });
    return { ok: true };
  }

  private nearestOpenTile(dest: { x: number; y: number; z: number }) {
    for (let r = 0; r < 4; r++) {
      for (let dy = -r; dy <= r; dy++) {
        for (let dx = -r; dx <= r; dx++) {
          const cx = dest.x + dx;
          const cy = dest.y + dy;
          if (
            isWalkable(this.maps[dest.z], cx, cy) &&
            !this.occupiedZ(cx, cy, dest.z) &&
            !this.npcBlockedZ(cx, cy, dest.z)
          ) {
            return { x: cx, y: cy, z: dest.z };
          }
        }
      }
    }
    return null;
  }

  // ------------------------------------------------------------------ damage
  private damagePlayer(amount: number, source: string, status?: StatusKey) {
    const p = this.player;
    if (p.dead) return;
    // Protected zone: creatures cannot land anything here.
    if (inSafeZone(p.x, p.y)) {
      this.push_text("PROTECTED", p.x, p.y - 0.4, "#ffd166");
      return;
    }
    const raw = amount;
    let dmg = mitigate(raw, p.armor);
    const blocked = raw - dmg;
    if (p.wardHp > 0) {
      const absorbed = Math.min(p.wardHp, dmg);
      p.wardHp -= absorbed;
      dmg -= absorbed;
      this.push_text(`-${absorbed}`, p.x, p.y - 0.3, "#06d6a0");
      if (p.wardHp <= 0) p.statuses = p.statuses.filter((s) => s.key !== "ward");
    }
    if (dmg > 0) {
      p.hp -= dmg;
      p.hitFlash = this.now + 220;
      this.push_text(blocked > 0 ? `${dmg} (-${blocked})` : `${dmg}`, p.x, p.y, "#ff5a6e");
      this.events.push({ type: "damaged", amount: dmg, blocked });
    }
    if (status) {
      p.statuses = p.statuses.filter((s) => s.key !== status);
      p.statuses.push({
        key: status,
        until: this.now + COMBAT.STATUS_MS,
        nextTick: this.now + COMBAT.STATUS_TICK_MS,
        power: status === "poison" ? COMBAT.POISON_POWER : COMBAT.BURN_POWER,
      });
    }
    if (p.hp <= 0) this.killPlayer(source);
  }

  private killPlayer(source: string) {
    const p = this.player;
    p.dead = true;
    p.hp = 0;
    p.deadUntil = this.now + COMBAT.RESPAWN_MS;
    p.deaths += 1;
    const xpLost = Math.floor(p.xp * COMBAT.XP_LOSS_PCT);
    const goldDropped = Math.floor(p.gold * COMBAT.GOLD_DROP_PCT);
    p.xp = Math.max(0, p.xp - xpLost);
    p.gold -= goldDropped;
    p.statuses = [];
    p.wardHp = 0;
    if (goldDropped > 0) {
      this.ground.push({
        id: nid(),
        x: p.x,
        y: p.y,
        z: p.z,
        itemKey: "gold",
        qty: goldDropped,
        owner: p.name,
        protectedUntil: this.now + COMBAT.LOOT_PROTECT_MS,
        born: this.now,
        jx: 0,
        jy: 0,
      });
    }
    this.push_text("YOU DIED", p.x, p.y - 0.5, "#ff5a6e", true);
    this.events.push({ type: "death", killedBy: source, xpLost, goldDropped, x: p.x, y: p.y });
  }

  private respawn() {
    const p = this.player;
    p.level = levelFromXp(p.xp);
    this.applyVocationStats(false);
    p.x = TEMPLE.x;
    p.y = TEMPLE.y;
    p.z = 0;
    p.rx = TEMPLE.x;
    p.ry = TEMPLE.y;
    p.dead = false;
    p.cooldowns = {};
    this.targetId = null;
    this.switchFloor(0);
    this.camX = p.x;
    this.camY = p.y;
  }

  // ------------------------------------------------------------------- gates
  private travelGate(dest: { x: number; y: number; z: number; name: string }, now: number) {
    if (now < this.gateCdUntil) return;
    this.gateCdUntil = now + 1500;
    const p = this.player;
    // one soul per tile: never materialize inside a monster; slide to air.
    let spot: { x: number; y: number; z: number } = dest;
    if (this.occupiedZ(dest.x, dest.y, dest.z)) {
      spot = { x: -999, y: -999, z: dest.z };
      const dt = this.maps[dest.z];
      outer: for (let r = 0; r < 4; r++) {
        for (let dy = -r; dy <= r; dy++) {
          for (let dx = -r; dx <= r; dx++) {
            const cx = dest.x + dx;
            const cy = dest.y + dy;
            if (isWalkable(dt, cx, cy) && !this.occupiedZ(cx, cy, dest.z)) {
              spot = { x: cx, y: cy, z: dest.z };
              break outer;
            }
          }
        }
      }
      if (spot.x < -900) {
        this.push_text("The rift is crowded", p.x, p.y - 0.5, "#94a3b8");
        this.events.push({ type: "denied", reason: "The rift is crowded on the other side." });
        return;
      }
    }
    p.x = spot.x;
    p.y = spot.y;
    p.z = spot.z;
    this.switchFloor(spot.z);
    this.targetId = null;
    this.push_text("RIFT", spot.x, spot.y, "#cc99ff", true);
    this.events.push({ type: "rift", name: dest.name });
  }

  // -------------------------------------------------------------------- tick
  update(dt: number, now: number) {
    this.now = now;
    const p = this.player;

    if (p.dead) {
      if (now >= p.deadUntil) this.respawn();
      this.decay(now);
      this.lerpCamera(dt);
      return;
    }

    // Crossing into the Sanctuary drops the mark: offense cannot stage from a PZ.
    if (this.isPacified() && this.targetId != null) this.targetId = null;

    const slowed = p.statuses.some((s) => s.key === "slow");
    if (this.heldDir && now >= p.nextStepAt && now >= p.castUntil) {
      const { x: dx, y: dy } = this.heldDir;
      if (dx !== 0 || dy !== 0) {
        p.facing = { x: dx, y: dy };
        const nx = p.x + dx;
        const ny = p.y + dy;
        if (isWalkable(this.map, nx, ny) && !this.occupiedZ(nx, ny, p.z) && !this.npcBlockedZ(nx, ny, p.z)) {
          p.x = nx;
          p.y = ny;
          const cost =
            this.stepMs *
            (dx !== 0 && dy !== 0 ? COMBAT.STEP_DIAGONAL_MULT : 1) *
            (slowed ? COMBAT.STEP_SLOW_MULT : 1);
          p.nextStepAt = now + cost;
          this.autoPickupAt(nx, ny);
          // Rift travel shares the step hook: the tile changed under our feet.
          const gate = gateDest(p.x, p.y, p.z);
          if (gate) this.travelGate(gate, now);
          const r = regionNameAt(p.x, p.y, p.z);
          if (r !== this.lastRegion) {
            this.lastRegion = r;
            this.events.push({ type: "region", name: r });
          }
        } else {
          p.nextStepAt = now + 120;
          this.events.push({ type: "blocked" });
        }
      }
    }

    const k = Math.min(1, dt / 90);
    p.rx += (p.x - p.rx) * k;
    p.ry += (p.y - p.ry) * k;
    if (now >= p.castUntil) p.castKey = null;

    // ---- auto-attack tick on the Marked creature (held while pacified:
    // the Sanctuary never deals damage)
    const marked = this.target();
    if (!marked || this.isPacified()) {
      this.nextAutoAt = now + COMBAT.AUTO_ATTACK_MS;
    } else if (this.autoAttack && now >= this.nextAutoAt) {
      const reach = Math.max(Math.abs(marked.x - p.x), Math.abs(marked.y - p.y));
      if (reach <= this.tickRange()) {
        this.autoSwing(marked);
        this.nextAutoAt = now + COMBAT.AUTO_ATTACK_MS;
      } else {
        // Out of reach: hold the tick at full so it fires the instant you close.
        this.nextAutoAt = now;
      }
    }

    if (now >= this.nextRegen) {
      this.nextRegen = now + COMBAT.REGEN_MS;
      p.hp = Math.min(p.maxHp, p.hp + COMBAT.REGEN_HP_BASE + Math.floor(p.level / COMBAT.REGEN_HP_DIV));
      p.mana = Math.min(p.maxMana, p.mana + COMBAT.REGEN_MANA_BASE + Math.floor(p.level / COMBAT.REGEN_MANA_DIV));
    }

    for (const s of p.statuses) {
      if (s.nextTick && now >= s.nextTick && now < s.until) {
        s.nextTick = now + 1500;
        this.damagePlayer(s.power, s.key === "poison" ? "Venom" : "Cinders");
      }
    }
    p.statuses = p.statuses.filter((s) => now < s.until);
    if (!p.statuses.some((s) => s.key === "ward")) p.wardHp = 0;

    const playerSafe = inSafeZone(p.x, p.y);

    for (const m of this.monsters) {
      if (m.dying) continue;
      if (m.z !== p.z) continue; // other floors are frozen while you are away
      const dist = Math.max(Math.abs(m.x - p.x), Math.abs(m.y - p.y));
      if (!m.aggro && dist <= m.sense && !playerSafe) {
        m.aggro = true;
        // react promptly: a stale wander cooldown must not root a mob that
        // just noticed you for up to 3 seconds.
        m.nextMoveAt = Math.min(m.nextMoveAt, now + COMBAT.AGGRO_REACT_MS);
      }
      if (m.aggro && dist > m.sense + COMBAT.DEAGGRO_TILES) m.aggro = false;

      if (!m.aggro) {
        // wounds close out of combat (up to spawn HP — rival marks stay
        // ledger-only). No more permanently half-barred roamers.
        if (m.hp < m.spawnHp && now >= m.nextHealAt) {
          m.nextHealAt = now + COMBAT.MOB_HEAL_MS;
          m.hp = Math.min(m.spawnHp, m.hp + Math.max(1, Math.floor(m.maxHp / COMBAT.MOB_HEAL_DIV)));
        }
        if (now >= m.nextMoveAt) {
          m.nextMoveAt = now + m.def.moveMs * (3 + Math.random() * 4);
          const dx = Math.floor(Math.random() * 3) - 1;
          const dy = Math.floor(Math.random() * 3) - 1;
          const nx = m.x + dx;
          const ny = m.y + dy;
          if (
            isWalkable(this.map, nx, ny) &&
            !this.occupiedZ(nx, ny, m.z) &&
            !this.npcBlockedZ(nx, ny, m.z) &&
            !inSafeZone(nx, ny)
          ) {
            m.x = nx;
            m.y = ny;
          }
        }
      } else {
        // Protected zone rule: creatures may not attack a player standing inside.
        const canAttack =
          !playerSafe && dist <= m.def.attackRange && now >= m.nextAttackAt && now >= m.windupUntil;
        if (canAttack) {
          m.windupUntil = now + m.def.windup;
          m.nextAttackAt = now + m.def.cadence;
          this.telegraphs.push({
            id: nid(),
            tiles: this.telegraphShape(m, p.x, p.y),
            z: m.z,
            startAt: now,
            resolveAt: now + m.def.windup,
            color: m.def.color,
            damage: m.def.damage,
            source: "monster",
            sourceId: m.id,
            status: m.def.key === "spider" ? "poison" : m.def.key === "ember" ? "burn" : undefined,
            resolved: false,
          });
        } else if (now >= m.nextMoveAt && now >= m.windupUntil && dist > m.def.attackRange) {
          m.nextMoveAt = now + m.def.moveMs;
          const dx = Math.sign(p.x - m.x);
          const dy = Math.sign(p.y - m.y);
          for (const t of [
            { x: dx, y: dy },
            { x: dx, y: 0 },
            { x: 0, y: dy },
          ]) {
            const nx = m.x + t.x;
            const ny = m.y + t.y;
            if (
              (t.x || t.y) &&
              isWalkable(this.map, nx, ny) &&
              !this.occupiedZ(nx, ny, m.z) &&
              !this.npcBlockedZ(nx, ny, m.z) &&
              !(nx === p.x && ny === p.y) &&
              !inSafeZone(nx, ny)
            ) {
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

    for (const t of this.telegraphs) {
      if (t.resolved || now < t.resolveAt) continue;
      t.resolved = true;
      if (t.z !== p.z) continue; // other floor: decay handles cleanup
      if (t.source === "monster") {
        const inZone = t.tiles.some((tile) => tile.x === p.x && tile.y === p.y);
        const src = this.monsters.find((m) => m.id === t.sourceId);
        if (inZone) this.damagePlayer(t.damage, src?.def.name ?? "Something in the dark", t.status);
        else this.push_text("dodged", p.x, p.y - 0.4, "#94a3b8");
      } else if (t.sourceId) {
        const m = this.monsters.find((mo) => mo.id === t.sourceId && mo.dying === 0);
        if (m) {
          const stillThere = t.tiles.some((tile) => tile.x === m.x && tile.y === m.y);
          const reach = Math.max(Math.abs(m.x - p.x), Math.abs(m.y - p.y));
          if (stillThere || reach <= 1) this.damageMonster(m, t.damage);
          else this.push_text("miss", m.x, m.y, "#94a3b8");
        }
      } else {
        for (const m of this.monsters) {
          if (m.dying || m.z !== p.z) continue;
          if (t.tiles.some((tile) => tile.x === m.x && tile.y === m.y)) this.damageMonster(m, t.damage);
        }
      }
    }

    this.decay(now);
    this.lerpCamera(dt);

    if (now >= this.nextSpawnCheck) {
      this.nextSpawnCheck = now + 2500;
      if (this.aliveOn(0) < COMBAT.MAX_MONSTERS) this.spawnMonster(false, 0);
      if (this.aliveOn(1) < COMBAT.CRYPT_MONSTERS) this.spawnMonster(false, 1);
    }
  }

  private telegraphShape(m: Monster, px: number, py: number) {
    const tiles: { x: number; y: number }[] = [];
    if (m.def.key === "wraith") {
      for (let dy = -1; dy <= 1; dy++)
        for (let dx = -1; dx <= 1; dx++) tiles.push({ x: px + dx, y: py + dy });
    } else if (m.def.key === "ember") {
      const dx = Math.sign(px - m.x);
      const dy = Math.sign(py - m.y);
      for (let i = 1; i <= 3; i++) tiles.push({ x: m.x + dx * i, y: m.y + dy * i });
      tiles.push({ x: px, y: py });
    } else {
      tiles.push({ x: px, y: py });
    }
    return tiles;
  }

  private decay(now: number) {
    this.telegraphs = this.telegraphs.filter((t) => now < t.resolveAt + 220);
    this.floats = this.floats.filter((f) => now - f.born < 1100);
    this.projectiles = this.projectiles.filter((pr) => now - pr.born < pr.duration);
    this.ground = this.ground.filter((g) => now - g.born < COMBAT.GROUND_DECAY_MS);
    this.monsters = this.monsters.filter((m) => !m.dying || now - m.dying < 320);
  }

  private lerpCamera(dt: number) {
    const p = this.player;
    // rifts, ferries and respawns jump floors: snap instead of gliding.
    if (Math.max(Math.abs(p.rx - this.camX), Math.abs(p.ry - this.camY)) > 8) {
      this.camX = p.rx;
      this.camY = p.ry;
      return;
    }
    const k = Math.min(1, dt / 170);
    this.camX += (p.rx - this.camX) * k;
    this.camY += (p.ry - this.camY) * k;
  }

  /** Consumables root you for 1.2s — drinking is a commitment, like everything else. */
  consume(hp = 0, mana = 0) {
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
    p.nextStepAt = this.now + COMBAT.ROOT_MS;
  }

  drainEvents(): GameEvent[] {
    const e = this.events;
    this.events = [];
    return e;
  }

  xpProgress() {
    const p = this.player;
    const prev = p.level > 1 ? xpForLevel(p.level - 1) : 0;
    const next = xpForLevel(p.level);
    return Math.max(0, Math.min(1, (p.xp - prev) / Math.max(1, next - prev)));
  }

  get mapSize() {
    return { w: this.map.tiles[0].length, h: this.map.tiles.length };
  }
}
