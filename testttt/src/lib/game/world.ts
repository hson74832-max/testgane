/** Deterministic tile world for the Remnants vertical slice. */

export const MAP_W = 40;
export const MAP_H = 40;
export const TILE = 44;

export type TileKind =
  | "grass"
  | "path"
  | "stone"
  | "water"
  | "wall"
  | "temple"
  | "brush"
  | "ash"
  | "gate";

export type TileDef = {
  kind: TileKind;
  walkable: boolean;
  top: string;
  side: string;
  detail?: string;
};

export const TILE_DEFS: Record<TileKind, TileDef> = {
  grass: { kind: "grass", walkable: true, top: "#3f7d4f", side: "#2c5a39", detail: "#4d9460" },
  brush: { kind: "brush", walkable: true, top: "#356b45", side: "#264d33", detail: "#2a5738" },
  path: { kind: "path", walkable: true, top: "#a08a63", side: "#7a684a", detail: "#b39a71" },
  ash: { kind: "ash", walkable: true, top: "#5b5560", side: "#413d47", detail: "#6b6472" },
  stone: { kind: "stone", walkable: true, top: "#6f7480", side: "#525763", detail: "#7d8390" },
  water: { kind: "water", walkable: false, top: "#2f7fb5", side: "#1f5c86", detail: "#4aa0d4" },
  wall: { kind: "wall", walkable: false, top: "#8d8577", side: "#5d574d" },
  temple: { kind: "temple", walkable: true, top: "#c9b27a", side: "#9a8557", detail: "#e0cd9c" },
  // Rift gate — surface crossroad <-> Barrow Crypt. Godot parity (world_gen.gd).
  gate: { kind: "gate", walkable: true, top: "#4a3568", side: "#33254a", detail: "#8a6ac0" },
};

export type Region = {
  key: string;
  name: string;
  x: number;
  y: number;
  w: number;
  h: number;
  tint: string;
  spawns: { key: string; weight: number }[];
  levelBand: string;
};

export const REGIONS: Region[] = [
  {
    key: "hollow",
    name: "Ashfall Hollow",
    x: 0,
    y: 22,
    w: 40,
    h: 18,
    tint: "#3f7d4f",
    spawns: [{ key: "rat", weight: 5 }],
    levelBand: "Lv 1–3 · Safe-adjacent",
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
      { key: "spider", weight: 5 },
      { key: "rat", weight: 2 },
    ],
    levelBand: "Lv 3–6 · Contested",
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
      { key: "ember", weight: 5 },
      { key: "spider", weight: 1 },
    ],
    levelBand: "Lv 6–9 · Full loot on death",
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
      { key: "wraith", weight: 4 },
      { key: "ember", weight: 2 },
    ],
    levelBand: "Lv 9+ · Deep world, no respawn shrine",
  },
];

export const TEMPLE = { x: 20, y: 35 };

/** Mulberry32 — small deterministic PRNG so client & server agree on the map. */
export function makeRng(seed: number) {
  let a = seed >>> 0;
  return function rng() {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function regionAt(x: number, y: number): Region {
  for (const r of REGIONS) {
    if (x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h) return r;
  }
  return REGIONS[0];
}

export type WorldMap = {
  tiles: TileKind[][];
  seed: number;
};

export function generateMap(seed = 1337): WorldMap {
  const rng = makeRng(seed);
  const tiles: TileKind[][] = [];

  for (let y = 0; y < MAP_H; y++) {
    const row: TileKind[] = [];
    for (let x = 0; x < MAP_W; x++) {
      const region = regionAt(x, y);
      let kind: TileKind;
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
  for (let i = 0; i < clusters; i++) {
    const cx = 2 + Math.floor(rng() * (MAP_W - 4));
    const cy = 2 + Math.floor(rng() * (MAP_H - 4));
    const size = 1 + Math.floor(rng() * 3);
    for (let y = cy - size; y <= cy + size; y++) {
      for (let x = cx - size; x <= cx + size; x++) {
        if (x < 1 || y < 1 || x >= MAP_W - 1 || y >= MAP_H - 1) continue;
        if (rng() < 0.55) tiles[y][x] = "wall";
      }
    }
  }

  // Two ponds in the Hollow
  for (const [px, py, pr] of [
    [7, 30, 3],
    [32, 27, 2],
  ]) {
    for (let y = py - pr; y <= py + pr; y++) {
      for (let x = px - pr; x <= px + pr; x++) {
        if (x < 1 || y < 1 || x >= MAP_W - 1 || y >= MAP_H - 1) continue;
        if ((x - px) ** 2 + (y - py) ** 2 <= pr * pr) tiles[y][x] = "water";
      }
    }
  }

  // The Long Road — the one guaranteed traversal spine, north/south.
  for (let y = 1; y < MAP_H - 1; y++) {
    const wob = Math.round(Math.sin(y * 0.35) * 2);
    for (let dx = -1; dx <= 1; dx++) {
      const x = TEMPLE.x + wob + dx;
      if (x > 0 && x < MAP_W - 1) tiles[y][x] = "path";
    }
  }
  // East/west crossroad
  for (let x = 1; x < MAP_W - 1; x++) {
    tiles[16][x] = "path";
  }

  // Temple plaza (safe zone)
  for (let y = TEMPLE.y - 2; y <= TEMPLE.y + 2; y++) {
    for (let x = TEMPLE.x - 2; x <= TEMPLE.x + 2; x++) {
      if (x < 1 || y < 1 || x >= MAP_W - 1 || y >= MAP_H - 1) continue;
      tiles[y][x] = "temple";
    }
  }

  // Rift gates last so nothing overwrites them (Godot parity).
  for (const g of GATES) {
    if (g.az === 0) tiles[g.a[1]][g.a[0]] = "gate";
  }

  return { tiles, seed };
}

export function isWalkable(map: WorldMap, x: number, y: number): boolean {
  // Bounds come from the map itself so the 12x12 crypt shares this path.
  if (x < 0 || y < 0 || y >= map.tiles.length || x >= (map.tiles[0]?.length ?? 0)) return false;
  return TILE_DEFS[map.tiles[y][x]].walkable;
}

/** Walls stop arrows and bolts; water and gates do not (Godot parity). */
export function blocksProjectile(map: WorldMap, x: number, y: number): boolean {
  if (x < 0 || y < 0 || y >= map.tiles.length || x >= (map.tiles[0]?.length ?? 0)) return true;
  return map.tiles[y][x] === "wall";
}

export function inSafeZone(x: number, y: number): boolean {
  return Math.abs(x - TEMPLE.x) <= 3 && Math.abs(y - TEMPLE.y) <= 3;
}

/* ------------------------------------------------------------------ floors
 * Godot extension (world_gen.gd): z is the floor. 0 = surface 40x40,
 * 1 = Barrow Crypt 12x12, reached by the rift gate on the crossroad.
 */

export const CRYPT_W = 12;
export const CRYPT_H = 12;
export const CRYPT_NAME = "Barrow Crypt";

/** Crypt config as content: both clients and the exporter read this block. */
export const CRYPT = {
  W: CRYPT_W,
  H: CRYPT_H,
  NAME: CRYPT_NAME,
  SPAWNS: [
    { key: "wraith", weight: 4 },
    { key: "ember", weight: 2 },
  ],
};

export type RiftGate = {
  a: [number, number];
  az: number;
  b: [number, number];
  bz: number;
  name: string;
};

export const GATES: RiftGate[] = [
  { a: [18, 16], az: 0, b: [6, 6], bz: 1, name: "Barrow Crypt" },
];

/** Rift destination for a position, or null when the tile is not a gate. */
export function gateDest(x: number, y: number, z: number): { x: number; y: number; z: number; name: string } | null {
  for (const g of GATES) {
    if (z === g.az && x === g.a[0] && y === g.a[1])
      return { x: g.b[0], y: g.b[1], z: g.bz, name: g.name };
    if (z === g.bz && x === g.b[0] && y === g.b[1])
      return { x: g.a[0], y: g.a[1], z: g.az, name: g.name };
  }
  return null;
}

export function regionNameAt(x: number, y: number, z: number): string {
  if (z !== 0) return CRYPT_NAME;
  return regionAt(x, y).name;
}

export function generateCrypt(seed = 1337): WorldMap {
  const rng = makeRng(seed + 77);
  const tiles: TileKind[][] = [];
  for (let y = 0; y < CRYPT.H; y++) {
    const row: TileKind[] = [];
    for (let x = 0; x < CRYPT.W; x++) {
      if (x === 0 || y === 0 || x === CRYPT.W - 1 || y === CRYPT.H - 1) row.push("wall");
      else row.push(rng() < 0.5 ? "stone" : "ash");
    }
    tiles.push(row);
  }
  for (const [px, py] of [
    [3, 4],
    [8, 3],
    [5, 8],
  ]) {
    tiles[py][px] = "wall";
  }
  // Rift gates last so nothing overwrites them.
  for (const g of GATES) {
    if (g.bz === 1) tiles[g.b[1]][g.b[0]] = "gate";
  }
  return { tiles, seed };
}
