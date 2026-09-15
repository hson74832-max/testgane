# World layer: real assets.dat / forgotten.otbm / Tibia.spr loading, walkability,
# sprite anchoring, spawn finding and light-source data. Pure map data — no
# gameplay state; the game server (game/server.gd) owns creatures and sessions.
class_name BlackTekWorld
extends RefCounted

const DatLoader := preload("res://scripts/game/loaders/dat_loader.gd")
const OtbmLoader := preload("res://scripts/game/loaders/otbm_loader.gd")
const SprLoader := preload("res://scripts/game/loaders/spr_loader.gd")

const MAP_W := 30
const MAP_H := 22
# NOTE: fallback map size/tuning is authoritative in data/gameplay.toml
# (BlackTekConfig); consts here stay as compat defaults for the no-OTBM path.

var walls: Dictionary = {} # fallback Vector2i -> true
var dat: BlackTekDat
var otbm: BlackTekOtbm
var spr: BlackTekSpr
var use_real_map := false
var use_real_sprites := false
var demo_z := 7
var stats_text := "fallback map"

func _init() -> void:
	# Border walls + a few obstacles (replaces OTBM load for the fallback map).
	for x in range(MAP_W):
		walls[Vector2i(x, 0)] = true
		walls[Vector2i(x, MAP_H - 1)] = true
	for y in range(MAP_H):
		walls[Vector2i(0, y)] = true
		walls[Vector2i(MAP_W - 1, y)] = true
	for x in range(8, 14):
		walls[Vector2i(x, 8)] = true
	for y in range(12, 17):
		walls[Vector2i(18, y)] = true



func load_real_data(dat_path: String, otbm_path: String) -> bool:
	dat = DatLoader.new()
	var t0 := Time.get_ticks_msec()
	if not dat.load_cache("res://assets/assets.cache"):
		var stairs := DatLoader.load_stair_names("res://assets/items.toml")
		print("BlackTekMock: stair items found: %d" % stairs.size())
		if not dat.load(dat_path, stairs):
			return false
		dat.load_item_meta("res://assets/items.toml")
		dat.save_cache("res://assets/assets.cache")
	else:
		dat.load_item_meta("res://assets/items.toml")
	dat.door_pairs = DatLoader.load_door_pairs("res://assets/items.toml")
	print("BlackTekMock: door leaves found: %d" % dat.door_pairs.size())
	otbm = OtbmLoader.new()
	if not otbm.load_cache("res://assets/forgotten.cache"):
		if not otbm.load(otbm_path):
			return false
		otbm.save_cache("res://assets/forgotten.cache")
	print("BlackTekMock: parsed in %d ms" % [Time.get_ticks_msec() - t0])
	var lit_n := 0
	var lit_max := 0
	for it in dat.items.values():
		var lv := int(it.get("light", 0))
		if lv > 0:
			lit_n += 1
			lit_max = maxi(lit_max, lv)
	print("BlackTekMock: light sources: %d items, max level %d" % [lit_n, lit_max])
	# Pick the z-level with most tiles as demo floor (usually 7 for ground).
	var per_z := {}
	for pos in otbm.tiles.keys():
		per_z[pos.z] = int(per_z.get(pos.z, 0)) + 1
	var best_z := 7
	var best_n := -1
	for z in per_z.keys():
		if per_z[z] > best_n:
			best_n = per_z[z]
			best_z = z
	demo_z = best_z
	use_real_map = true
	stats_text = "dat %d items, otbm %d tiles (z=%d), %d towns" % [dat.items.size(), otbm.tiles.size(), demo_z, otbm.towns.size()]
	# Optional real sprites: res://assets/Tibia.spr (not shipped with server repo).
	if FileAccess.file_exists("res://assets/Tibia.spr"):
		spr = SprLoader.new()
		var spr_ok := spr.load_cache("res://assets/spr.cache")
		if spr_ok:
			spr_ok = spr.open_pixels("res://assets/Tibia.spr")
		else:
			spr_ok = spr.load("res://assets/Tibia.spr")
			if spr_ok:
				spr.save_cache("res://assets/spr.cache")
		if spr_ok and not spr.offsets.is_empty():
			use_real_sprites = true
			stats_text += ", spr %d" % spr.count
		else:
			spr = null
	return true

# Per-tile draw list, OTClient-style (cf. opentibiabr/otclient ThingType::draw,
# Item::updatePatterns, Tile::draw):
# - sprite index cf. getSpriteIndex: pattern (px,py,pz) from tile position
#   (Item::updatePatterns else-branch: pos.x % patX etc), frame 0, width innermost.
# - anchoring: sprite (gx,gy) at -gx*32 - displacement (ThingType::draw:
#   dest + (offset - displacement - (size-1)*32) + (size-1-g)*32).
# - order: ground, ground-border, on-bottom, middle, on-top (Tile::draw).
# - elevation: later things shift up by accumulated pixels (Tile::drawElevation).
# Returns Array of {tex: Texture2D, ox: float, oy: float} pixel offsets from tile origin.
func get_tile_draws(tile: Vector2i, z := -1) -> Array:
	var draws := []
	if not use_real_sprites or spr == null or dat == null:
		return draws
	var zz: int = z if z >= 0 else demo_z
	var ids: Array = tile_info(tile, zz).get("items", [])
	# Bucket per OTClient Tile::draw pass, preserving OTBM order inside each.
	var grounds: Array = []
	var borders: Array = []
	var bottoms: Array = []
	var middles: Array = []
	var tops: Array = []
	for id in ids:
		var d: Dictionary = dat.items.get(int(id), {})
		if d.is_empty():
			continue
		if bool(d.get("is_ground", false)):
			grounds.append(id)
		elif bool(d.get("is_border", false)):
			borders.append(id)
		elif bool(d.get("is_bottom", false)):
			bottoms.append(id)
		elif bool(d.get("is_top", false)):
			tops.append(id)
		else:
			middles.append(id)
	var ordered: Array = []
	ordered.append_array(grounds)
	ordered.append_array(borders)
	ordered.append_array(bottoms)
	ordered.append_array(middles)
	ordered.append_array(tops)
	var elev_accum := 0
	for id in ordered:
		var d: Dictionary = dat.items.get(int(id), {})
		var sprites: PackedInt32Array = d.get("sprites", PackedInt32Array())
		if sprites.is_empty():
			continue
		var w: int = maxi(1, int(d.get("w", 1)))
		var h: int = maxi(1, int(d.get("h", 1)))
		var layers: int = maxi(1, int(d.get("layers", 1)))
		var pat_x: int = maxi(1, int(d.get("pat_x", 1)))
		var pat_y: int = maxi(1, int(d.get("pat_y", 1)))
		var pat_z: int = maxi(1, int(d.get("pat_z", 1)))
		# OTClient Item::updatePatterns: pattern from map position.
		var px: int = posmod(tile.x, pat_x)
		var py: int = posmod(tile.y, pat_y)
		var pz: int = posmod(zz, pat_z)
		var dx: int = int(d.get("displacement_x", 0))
		var dy: int = int(d.get("displacement_y", 0))
		# Items draw with layer 0; all dat layers are pre-composited stacked
		# (cf. ThingType::loadTexture: frame (0,x,y,z) blits every layer).
		for l in range(mini(layers, 2)):
			for gy in range(h):
				for gx in range(w):
					var idx := (((((pz * pat_y + py) * pat_x + px) * layers + l) * h + gy) * w + gx)
					if idx < 0 or idx >= sprites.size():
						continue
					var sid := sprites[idx]
					if sid <= 0:
						continue
					var t := spr.get_texture(sid)
					if t != null:
						draws.append({"tex": t, "ox": float(-gx * 32 - dx), "oy": float(-gy * 32 - dy - elev_accum)})
		elev_accum = mini(elev_accum + int(d.get("elevation", 0)), 32)
	return draws

# 32x32 texture for one item type (first sprite) — used by HUD gear/bag icons.
func get_item_icon(itemtype: int) -> Texture2D:
	if not use_real_sprites or spr == null or dat == null:
		return null
	var sid := dat.first_sprite(itemtype)
	if sid <= 0:
		return null
	return spr.get_texture(sid)

func item_label(itemtype: int) -> String:
	var n := dat.item_name(itemtype) if dat != null else ""
	return n if n != "" else "item %d" % itemtype

func prewarm_sprites(center: Vector2i, radius := 16) -> int:
	if not use_real_sprites or spr == null:
		return 0
	var n := 0
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			n += get_tile_draws(center + Vector2i(dx, dy)).size()
	return n

func find_spawn() -> Vector2i:
	if otbm != null and not otbm.towns.is_empty():
		var t: Vector3i = otbm.towns[0]["pos"]
		demo_z = t.z
		var cand := Vector2i(t.x, t.y)
		if is_walkable(cand):
			return cand
		for r in range(1, 12):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var c := cand + Vector2i(dx, dy)
					if is_walkable(c):
						return c
	# Fallback: sample tiles on demo floor, pick open walkable spot (town-less maps).
	var best := Vector2i(15, 11)
	var best_score := -1
	var checked := 0
	for pos in otbm.tiles.keys():
		if pos.z != demo_z:
			continue
		checked += 1
		if checked > 4000:
			break
		var c := Vector2i(pos.x, pos.y)
		if not is_walkable(c):
			continue
		var score := 0
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				if is_walkable(c + Vector2i(dx, dy)):
					score += 1
		if score > best_score:
			best_score = score
			best = c
			if score >= 24:
				return best
	return best

func tile_info(tile: Vector2i, z := -1) -> Dictionary:
	if not use_real_map or otbm == null:
		return {}
	if z < 0:
		z = demo_z
	return otbm.tiles.get(Vector3i(tile.x, tile.y, z), {})

# Floor stack cf. OTClient/Tibia 10.98 (see also opentibiabr/otclient mapview):
# surface (z<=7) draws demo_z..7 stacked so upper floors show ground through openings;
# underground draws the current floor only. Returned bottom-first for painter order.
func floors_to_draw() -> Array:
	if not use_real_map:
		return [demo_z]
	if demo_z > 7:
		return [demo_z]
	var out := []
	for z in range(7, demo_z - 1, -1):
		out.append(z)
	return out

# Step-onto-stairs teleport (stand-in for stair/use logic): if the player's tile
# holds a stair-like item, head for a walkable landing on the floor above first
# (same tile, then rings to 4), else the floor below. Returns new z or -1.
func is_walkable(tile: Vector2i, z := -1) -> bool:
	if z < 0:
		z = demo_z
	if use_real_map and otbm != null and dat != null:
		var entry: Dictionary = otbm.tiles.get(Vector3i(tile.x, tile.y, z), {})
		if entry.is_empty():
			return false # outside real map = blocked (no fallback holes)
		for id in entry.get("items", []):
			if dat.is_solid(int(id)):
				return false
		return true
	if tile.x < 0 or tile.y < 0 or tile.x >= MAP_W or tile.y >= MAP_H:
		return false
	if walls.has(tile):
		return false
	# No stacking check in demo (real Game::internalPlaceCreature checks creatures/items).
	return true

func tile_light_radius(tile: Vector2i, z: int) -> int:
	var radius := 0
	if dat == null:
		return 0
	for id in tile_info(tile, z).get("items", []):
		radius = maxi(radius, int(dat.items.get(int(id), {}).get("light", 0)))
	return radius

# ---- item stats (tooltips; values from items.toml/armor/weapon tables) --------

