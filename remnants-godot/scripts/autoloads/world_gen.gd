extends Node
## WorldGen — autoload singleton. Port of testttt/src/lib/game/world.ts + Godot
## extensions (tile flags, rift gates, crypt floor). Positions are x,y,z triples:
## z is the floor (0 = surface 40x40, 1 = Barrow Crypt 12x12).
## RNG: mulberry32 equivalent (best-effort bit parity with JS; server owns
## canonical map long-term, so exact float parity is not load-bearing yet).

const MAP_W: int = 40
const MAP_H: int = 40
## Web canvas used 44px tiles; Godot renders at 64px for thumb readability.
const TILE_PX: int = 64
const TEMPLE: Vector2i = Vector2i(20, 35)
const TEMPLE_Z: int = 0
const PZ_RADIUS: int = 3
## Crypt config: defaults here, overridden from content.json world.CRYPT in
## _ready (GameBalance loads first). Spawn tables likewise come from content.
var crypt_w: int = 12
var crypt_h: int = 12
var crypt_name := "Barrow Crypt"
var crypt_spawns_arr: Array = [{"key": "wraith", "weight": 4}, {"key": "ember", "weight": 2}]

## Tile rules (walkable / blocks projectile) live in WorldConfig.TILE_DEFS
## (scripts/balance/world_config.gd) — one place for what a tile kind means.

## Region spawn tables come from content.json (world.REGIONS.spawns) — merged
## over these embedded fallbacks in _ready. Var, not const: _ready mutates.
var REGIONS: Array = [
	{"key": "barrow", "name": "The Grey Barrow", "x": 0, "y": 0, "w": 40, "h": 11,
		"spawns": [{"key": "wraith", "weight": 4}, {"key": "ember", "weight": 2}]},
	{"key": "webs", "name": "The Weeping Webs", "x": 0, "y": 11, "w": 22, "h": 11,
		"spawns": [{"key": "spider", "weight": 5}, {"key": "rat", "weight": 2}]},
	{"key": "emberfield", "name": "Emberfield", "x": 22, "y": 11, "w": 18, "h": 11,
		"spawns": [{"key": "ember", "weight": 5}, {"key": "spider", "weight": 1}]},
	{"key": "hollow", "name": "Ashfall Hollow", "x": 0, "y": 22, "w": 40, "h": 18,
		"spawns": [{"key": "rat", "weight": 5}]},
]

func _ready() -> void:
	# Content overrides (GameBalance autoloads before WorldGen): region spawn
	# tables and the crypt block live in content.json — a new creature is a
	# data edit, no code.
	var world_cfg: Dictionary = GameBalance.WORLD
	var crypt: Dictionary = world_cfg.get("CRYPT", {})
	if not crypt.is_empty():
		crypt_w = int(crypt.get("W", crypt_w))
		crypt_h = int(crypt.get("H", crypt_h))
		crypt_name = String(crypt.get("NAME", crypt_name))
		var csp: Array = crypt.get("SPAWNS", [])
		if not csp.is_empty():
			crypt_spawns_arr = csp
	for r in (world_cfg.get("REGIONS", []) as Array):
		var rk := String(r.get("key", ""))
		var sp: Array = r.get("spawns", [])
		if rk == "" or sp.is_empty():
			continue
		for local in REGIONS:
			if String(local["key"]) == rk:
				local["spawns"] = sp

## Crypt floor spawn table (content-driven).
func crypt_spawns() -> Array:
	return crypt_spawns_arr

## Rift gates: surface crossroad <-> crypt heart. Stepping on either end
## travels to the other (with a 1.5s re-trigger cooldown against bounce).
const GATES: Array = [
	{"a": Vector2i(18, 16), "az": 0, "b": Vector2i(6, 6), "bz": 1, "name": "Barrow Crypt"},
]

class Mulberry:
	var a: int
	func _init(seed_value: int) -> void:
		a = seed_value & 0xFFFFFFFF
	func next_float() -> float:
		a = (a + 0x6D2B79F5) & 0xFFFFFFFF
		var t: int = a
		# t = imul(a ^ (a >>> 15), 1 | a) — emulate low32 multiply
		var x: int = ((t ^ (t >> 15)) & 0xFFFFFFFF)
		# logical >> already OK because we masked to 32 bits (positive)
		var y: int = ((1 | t) & 0xFFFFFFFF)
		t = ((x * y) & 0xFFFFFFFF)
		var z: int = ((61 | t) & 0xFFFFFFFF)
		t = (((t ^ (t >> 7)) & 0xFFFFFFFF) * z) & 0xFFFFFFFF
		t = (t ^ (t >> 14)) & 0xFFFFFFFF
		return float(t) / 4294967296.0

func region_at(x: int, y: int) -> Dictionary:
	for r in REGIONS:
		if x >= int(r["x"]) and x < int(r["x"]) + int(r["w"]) and y >= int(r["y"]) and y < int(r["y"]) + int(r["h"]):
			return r
	return REGIONS[3]

func region_name_at(p: Vector3i) -> String:
	if p.z != 0:
		return crypt_name
	return String(region_at(p.x, p.y).get("name", ""))

func in_safe_zone(x: int, y: int) -> bool:
	return absi(x - TEMPLE.x) <= PZ_RADIUS and absi(y - TEMPLE.y) <= PZ_RADIUS

## Bounds come from the array itself so surface and crypt share this path.
func kind_at(tiles: Array, x: int, y: int) -> String:
	if tiles.is_empty() or y < 0 or y >= tiles.size():
		return ""
	var row: Array = tiles[y]
	if x < 0 or x >= row.size():
		return ""
	return String(row[x])

func is_walkable(tiles: Array, x: int, y: int) -> bool:
	var kind: String = kind_at(tiles, x, y)
	if kind == "":
		return false
	return bool((GameBalance.world_cfg.TILE_DEFS[kind] as Dictionary).get("walkable", false))

func blocks_projectile(tiles: Array, x: int, y: int) -> bool:
	var kind: String = kind_at(tiles, x, y)
	if kind == "":
		return true
	return bool((GameBalance.world_cfg.TILE_DEFS[kind] as Dictionary).get("projectile_blocked", false))

## Rift destination for a position, or Vector3i(-1,-1,-1) when not on a gate.
func gate_dest(p: Vector3i) -> Vector3i:
	for g in GATES:
		if p.z == int(g["az"]) and Vector2i(p.x, p.y) == g["a"]:
			return Vector3i((g["b"] as Vector2i).x, (g["b"] as Vector2i).y, int(g["bz"]))
		if p.z == int(g["bz"]) and Vector2i(p.x, p.y) == g["b"]:
			return Vector3i((g["a"] as Vector2i).x, (g["a"] as Vector2i).y, int(g["az"]))
	return Vector3i(-1, -1, -1)

func generate_map(seed_value: int = 1337) -> Array:
	var rng := Mulberry.new(seed_value)
	var tiles: Array = []
	for y in range(MAP_H):
		var row: Array = []
		for x in range(MAP_W):
			row.append(_base_kind(x, y, rng.next_float()))
		tiles.append(row)
	# rocky outcrops
	for i in range(46):
		var cx: int = 2 + int(rng.next_float() * float(MAP_W - 4))
		var cy: int = 2 + int(rng.next_float() * float(MAP_H - 4))
		var size: int = 1 + int(rng.next_float() * 3.0)
		for y in range(cy - size, cy + size + 1):
			for x in range(cx - size, cx + size + 1):
				if x < 1 or y < 1 or x >= MAP_W - 1 or y >= MAP_H - 1:
					continue
				if rng.next_float() < 0.55:
					tiles[y][x] = "wall"
	# ponds in the Hollow
	_stamp_disc(tiles, 7, 30, 3, "water")
	_stamp_disc(tiles, 32, 27, 2, "water")
	# Long Road N/S with sine wobble
	for y in range(1, MAP_H - 1):
		var wob: int = int(round(sin(float(y) * 0.35) * 2.0))
		for dx in range(-1, 2):
			var x: int = TEMPLE.x + wob + dx
			if x > 0 and x < MAP_W - 1:
				tiles[y][x] = "path"
	# crossroad E/W
	for x in range(1, MAP_W - 1):
		tiles[16][x] = "path"
	# temple plaza
	for y in range(TEMPLE.y - 2, TEMPLE.y + 3):
		for x in range(TEMPLE.x - 2, TEMPLE.x + 3):
			if x < 1 or y < 1 or x >= MAP_W - 1 or y >= MAP_H - 1:
				continue
			tiles[y][x] = "temple"
	# rift gates last so nothing overwrites them
	for g in GATES:
		if int(g["az"]) == 0:
			tiles[(g["a"] as Vector2i).y][(g["a"] as Vector2i).x] = "gate"
	return tiles

func generate_crypt(seed_value: int = 1337) -> Array:
	var rng := Mulberry.new(seed_value + 77)
	var tiles: Array = []
	for y in range(crypt_h):
		var row: Array = []
		for x in range(crypt_w):
			if x == 0 or y == 0 or x == crypt_w - 1 or y == crypt_h - 1:
				row.append("wall")
			else:
				row.append("stone" if rng.next_float() < 0.5 else "ash")
		tiles.append(row)
	for pillar in [Vector2i(3, 4), Vector2i(8, 3), Vector2i(5, 8)]:
		tiles[pillar.y][pillar.x] = "wall"
	for g in GATES:
		if int(g["bz"]) == 1:
			tiles[(g["b"] as Vector2i).y][(g["b"] as Vector2i).x] = "gate"
	return tiles

func _base_kind(x: int, y: int, n: float) -> String:
	if x == 0 or y == 0 or x == MAP_W - 1 or y == MAP_H - 1:
		return "wall"
	var r: Dictionary = region_at(x, y)
	match String(r["key"]):
		"hollow":
			return "brush" if n < 0.16 else "grass"
		"webs":
			if n < 0.22:
				return "stone"
			if n < 0.34:
				return "brush"
			return "grass"
		"emberfield":
			return "ash" if n < 0.4 else "stone"
		_:
			return "ash" if n < 0.55 else "stone"

func _stamp_disc(tiles: Array, px: int, py: int, pr: int, kind: String) -> void:
	for y in range(py - pr, py + pr + 1):
		for x in range(px - pr, px + pr + 1):
			if x < 1 or y < 1 or x >= MAP_W - 1 or y >= MAP_H - 1:
				continue
			if (x - px) * (x - px) + (y - py) * (y - py) <= pr * pr:
				tiles[y][x] = kind
