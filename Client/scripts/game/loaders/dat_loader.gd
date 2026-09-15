# Real assets.dat parser — GDScript port of Items::unserializeDatItem (src/items.cpp:1063).
# Gives actual server logic: blockSolid, blockPathFind, speed, stackable, etc.
# No sprites: assets.dat stores only flags + sprite IDs, pixel data lives in
# Tibia.spr 10.98 (not shipped with the server repo).
class_name BlackTekDat
extends RefCounted

# id -> {block_solid, block_pathfind, block_projectile, speed, group, stackable, pickupable, moveable, sprite_count}
var items: Dictionary = {}
var item_count := 0
var _stair_names := {}
# id -> {name: String, weight: int (grams)} from data/items/items.toml (server names).
var item_meta: Dictionary = {}
# id -> {"to": int partner_id, "open": bool} for usable door pairs.
var door_pairs: Dictionary = {}

# Minimal items.toml name scan: returns {id -> true} for stair-like items.
# Only whole-word matches; direction is resolved later by landing geometry.
static func load_stair_names(path: String) -> Dictionary:
	var out := {}
	var keys := ["stair", "stairs", "staircase", "stairway", "stairwell", "ramp",
		"ladder", "steps", "escalator", "sewer", "hole", "pit", "trapdoor",
		"grate", "hatch", "chute", "manhole", "gangway", "staircase"]
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var ids: Array = []
	var pending_from := -1
	var pending_to := -1
	var pending_name := ""
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "[[items]]" or f.eof_reached():
			_apply_stair_block(ids, pending_from, pending_to, pending_name, keys, out)
			ids = []
			pending_from = -1
			pending_to = -1
			pending_name = ""
			continue
		if line.begins_with("id =") or line.begins_with("id="):
			ids.append(int(line.get_slice("=", 1).strip_edges()))
		elif line.begins_with("fromid"):
			pending_from = int(line.get_slice("=", 1).strip_edges())
		elif line.begins_with("toid"):
			pending_to = int(line.get_slice("=", 1).strip_edges())
		elif line.begins_with("name"):
			var q1 := line.find("\"")
			var q2 := line.find("\"", q1 + 1)
			if q1 >= 0 and q2 > q1:
				pending_name = line.substr(q1 + 1, q2 - q1 - 1)
	_apply_stair_block(ids, pending_from, pending_to, pending_name, keys, out)
	f.close()
	return out

# Door pair scan over items.toml: {id -> {"to": partner, "open": bool}}.
# Tibia names door variants "closed door" C / "open door" O (also trapdoors)
# with the open leaf a step or two above its closed leaf (e.g. 1210->1211).
# Only mutual nearest pairs (gap <= 2) qualify, so unrelated styles never mix.
static func load_door_pairs(path: String) -> Dictionary:
	var closed: Array = []
	var opened: Array = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var ids: Array = []
	var pending_name := ""
	var pending_from := -1
	var pending_to := -1
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "[[items]]" or f.eof_reached():
			_apply_door_block(ids, pending_from, pending_to, pending_name, closed, opened)
			ids = []
			pending_name = ""
			pending_from = -1
			pending_to = -1
			continue
		if line.begins_with("id =") or line.begins_with("id="):
			ids.append(int(line.get_slice("=", 1).strip_edges()))
		elif line.begins_with("fromid"):
			pending_from = int(line.get_slice("=", 1).strip_edges())
		elif line.begins_with("toid"):
			pending_to = int(line.get_slice("=", 1).strip_edges())
		elif line.begins_with("name"):
			var q1 := line.find("\"")
			var q2 := line.find("\"", q1 + 1)
			if q1 >= 0 and q2 > q1:
				pending_name = line.substr(q1 + 1, q2 - q1 - 1)
	_apply_door_block(ids, pending_from, pending_to, pending_name, closed, opened)
	f.close()
	closed.sort()
	opened.sort()
	var out := {}
	for c in closed:
		var best := -1
		for o in opened:
			if o > c and (best < 0 or o < best):
				best = o
		if best >= 0 and best - c <= 2:
			out[c] = {"to": best, "open": false}
	for o2 in opened:
		var best2 := -1
		for c2 in closed:
			if c2 < o2 and (best2 < 0 or c2 > best2):
				best2 = c2
		if best2 >= 0 and o2 - best2 <= 2 and out.get(best2, {}).get("to", -1) == o2:
			out[o2] = {"to": best2, "open": true}
	return out

static func _apply_door_block(ids: Array, pending_from: int, pending_to: int, pending_name: String, closed: Array, opened: Array) -> void:
	if pending_name == "" or not "door" in pending_name.to_lower():
		return
	var all_ids := ids.duplicate()
	if pending_from >= 0 and pending_to >= pending_from and pending_to - pending_from < 2000:
		for sid2 in range(pending_from, pending_to + 1):
			if not all_ids.has(sid2):
				all_ids.append(sid2)
	var low := pending_name.to_lower().strip_edges()
	if low.begins_with("closed"):
		for sid in all_ids:
			if not closed.has(sid):
				closed.append(sid)
	elif low.begins_with("open"):
		for sid in all_ids:
			if not opened.has(sid):
				opened.append(sid)

# Helper (static: lambdas capture locals by value, so flush must be a real function).
static func _apply_stair_block(ids: Array, pending_from: int, pending_to: int, pending_name: String, keys: Array, out: Dictionary) -> void:
	if pending_name == "":
		return
	var hit := false
	for w in pending_name.to_lower().split(" ", false):
		var clean := ""
		for i in range(w.length()):
			var code := w.unicode_at(i)
			if (code >= 97 and code <= 122) or (code >= 48 and code <= 57):
				clean += String.chr(code)
		if clean != "" and keys.has(clean):
			hit = true
			break
	if not hit:
		return
	for sid in ids:
		out[sid] = true
	if pending_from >= 0 and pending_to >= pending_from and pending_to - pending_from < 2000:
		for sid2 in range(pending_from, pending_to + 1):
			out[sid2] = true

func load(path: String, stair_names := {}) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("BlackTekDat: cannot open %s" % path)
		return false
	_stair_names = stair_names
	f.seek(4) # signature, cf. Items::loadFromDat
	item_count = f.get_16()
	print("BlackTekDat: item_count=%d size=%d" % [item_count, f.get_length()])
	f.seek(f.get_position() + 6) # outfit/effect/missile counts
	items.clear()
	# Cf. Items::loadFromDat: ids 100..item_count inclusive.
	var id := 100
	while id <= item_count:
		var it := _parse_one(f, id)
		if it.is_empty():
			push_error("BlackTekDat: parse failed at id %d (pos %d/%d)" % [id, f.get_position(), f.get_length()])
			f.close()
			return false
		items[id] = it
		id += 1
	f.close()
	return true

func is_solid(id: int) -> bool:
	return bool(items.get(id, {}).get("block_solid", id >= 100 and id < 200))

func is_container(id: int) -> bool:
	return int(items.get(id, {}).get("group", 0)) == 2

func item_name(id: int) -> String:
	return String(item_meta.get(id, {}).get("name", ""))

func item_weight(id: int) -> int:
	return int(item_meta.get(id, {}).get("weight", 0))

# Full items.toml scan (superset of load_stair_names): id -> {name, weight}.
# Handles plain ids, fromid/toid ranges and stacked entries.
func load_item_meta(path: String) -> Dictionary:
	var out := {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var ids: Array = []
	var pending_name := ""
	var pending_weight := -1
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.begins_with("[[items]]") or f.eof_reached():
			# Lambdas capture locals by value (cf. load_stair_names), flush inline.
			if pending_name != "" and not ids.is_empty():
				for sid in ids:
					out[sid] = {"name": pending_name, "weight": pending_weight}
			ids = []
			pending_name = ""
			pending_weight = -1
		elif line.begins_with("id =") or line.begins_with("id="):
			ids.append(int(line.get_slice("=", 1).strip_edges()))
		elif line.begins_with("fromid"):
			ids.append(int(line.get_slice("=", 1).strip_edges()))
		elif line.begins_with("toid"):
			var to := int(line.get_slice("=", 1).strip_edges())
			if not ids.is_empty() and to > int(ids[0]) and to - int(ids[0]) < 5000:
				for sid in range(int(ids[0]) + 1, to + 1):
					ids.append(sid)
		elif line.begins_with("name"):
			var q1 := line.find("\"")
			var q2 := line.find("\"", q1 + 1)
			if q1 >= 0 and q2 > q1:
				pending_name = line.substr(q1 + 1, q2 - q1 - 1)
		elif line.begins_with("weight"):
			pending_weight = int(line.get_slice("=", 1).strip_edges().to_float())
	f.close()
	# Merge into item_meta (stair detection still uses the dedicated scanner).
	for id in out.keys():
		item_meta[id] = out[id]
	print("BlackTekDat: item names loaded: %d" % out.size())
	return out

# Compact cache: magic BTD8, u16 max_id, then per id 100..max bitmask u8 + speed u16
# + dims (w,h,layers,patX,patY,patZ,frames as u8) + layer flags u8
# + displacement (u16 x2, only if flag set) + elevation (u16, only if >0)
# + light (u16, only if flag set) + sprite list (u16 n + n×u32).
# Bit 0=solid 1=pathfind 2=projectile 3=stackable 4=pickupable 5=moveable 6=stair 7=light.
# Layer bits: 0=ground 1=border 2=bottom 3=top 4=has displacement 5=has elevation 6=container.
func load_cache(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null or f.get_32() != 0x38445442: # "BTD8" LE
		return false
	item_count = f.get_16()
	items.clear()
	for id in range(100, item_count + 1):
		var m := f.get_8()
		var sp := f.get_16()
		var dims := [f.get_8(), f.get_8(), f.get_8(), f.get_8(), f.get_8(), f.get_8(), f.get_8()]
		var lay := f.get_8()
		var dx := 0
		var dyy := 0
		if lay & 16:
			dx = f.get_16()
			dyy = f.get_16()
		var elev := 0
		if lay & 32:
			elev = f.get_16()
		var light: int = f.get_16() if (m & 128) else 0
		var ns := f.get_16()
		var ids := PackedInt32Array()
		ids.resize(ns)
		for k in range(ns):
			ids[k] = f.get_32()
		items[id] = {
			"id": id, "group": 2 if (lay & 64) else (1 if (lay & 1) else 0), "speed": sp,
			"block_solid": bool(m & 1), "block_pathfind": bool(m & 2),
			"block_projectile": bool(m & 4), "stackable": bool(m & 8),
			"pickupable": bool(m & 16), "moveable": bool(m & 32),
			"sprite_count": ns, "sprites": ids,
			"w": dims[0], "h": dims[1], "layers": dims[2],
			"pat_x": dims[3], "pat_y": dims[4], "pat_z": dims[5], "frames": dims[6],
			"is_ground": bool(lay & 1), "is_border": bool(lay & 2),
			"is_bottom": bool(lay & 4), "is_top": bool(lay & 8),
			"displacement_x": dx, "displacement_y": dyy, "elevation": elev,
			"is_stair": bool(m & 64), "light": light,
		}
	f.close()
	return true

func save_cache(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_32(0x38445442) # "BTD8" LE
	f.store_16(item_count)
	for id in range(100, item_count + 1):
		var it: Dictionary = items.get(id, {})
		var m := 0
		if it.get("block_solid", false): m |= 1
		if it.get("block_pathfind", false): m |= 2
		if it.get("block_projectile", false): m |= 4
		if it.get("stackable", false): m |= 8
		if it.get("pickupable", false): m |= 16
		if it.get("moveable", true): m |= 32
		if it.get("is_stair", false): m |= 64
		var has_light: bool = int(it.get("light", 0)) > 0
		if has_light:
			m |= 128
		f.store_8(m)
		f.store_16(int(it.get("speed", 0)))
		for k in ["w", "h", "layers", "pat_x", "pat_y", "pat_z", "frames"]:
			f.store_8(maxi(1, int(it.get(k, 1))))
		var lay := 0
		if bool(it.get("is_ground", false)): lay |= 1
		if bool(it.get("is_border", false)): lay |= 2
		if bool(it.get("is_bottom", false)): lay |= 4
		if bool(it.get("is_top", false)): lay |= 8
		if int(it.get("group", 0)) == 2: lay |= 64 # container
		var dx := int(it.get("displacement_x", 0))
		var dyy := int(it.get("displacement_y", 0))
		if dx != 0 or dyy != 0:
			lay |= 16
		var elev := int(it.get("elevation", 0))
		if elev != 0:
			lay |= 32
		f.store_8(lay)
		if lay & 16:
			f.store_16(dx)
			f.store_16(dyy)
		if lay & 32:
			f.store_16(elev)
		if has_light:
			f.store_16(int(it.light))
		var ids: PackedInt32Array = it.get("sprites", PackedInt32Array())
		f.store_16(mini(ids.size(), 32767))
		for k in range(ids.size()):
			f.store_32(ids[k])
	f.close()
	return true

func _parse_one(f: FileAccess, id: int) -> Dictionary:
	var it := {
		"id": id, "group": 0, "speed": 0, "block_solid": false,
		"block_pathfind": false, "block_projectile": false,
		"stackable": false, "pickupable": false, "moveable": true,
		"sprite_count": 0, "w": 1, "h": 1, "layers": 1, "light": 0,
		"pat_x": 1, "pat_y": 1, "pat_z": 1, "frames": 1,
		"is_ground": false, "is_border": false, "is_bottom": false, "is_top": false,
		"displacement_x": 0, "displacement_y": 0, "elevation": 0,
		"is_stair": _stair_names.has(id),
	}
	while true:
		if f.eof_reached():
			return {}
		var flag := f.get_8()
		match flag:
			0: # Ground (cf. OTClient ThingAttrGround)
				it["group"] = 1
				it["is_ground"] = true
				it["speed"] = f.get_16()
			1: # GroundBorder
				it["is_border"] = true
			2: # OnBottom (walls etc, drawn after ground)
				it["is_bottom"] = true
			3: # OnTop (drawn above creatures)
				it["is_top"] = true
			4:
				it["group"] = 2 # Container
			5:
				it["stackable"] = true
			6, 7:
				pass # ForceUse/MultiUse
			8, 9:
				f.get_16() # maxTextLen
			10, 11:
				pass # FluidContainer/Fluid
			12:
				it["block_solid"] = true
			13:
				it["moveable"] = false
			14:
				it["block_projectile"] = true
			15:
				it["block_pathfind"] = true
			16:
				pass # NoMoveAnimation
			17:
				it["pickupable"] = true
			18, 19, 20, 21:
				pass # Hangable/Horizontal/Vertical/Rotatable
			22: # Light (cf. OTClient ThingAttrLight: intensity first, color second)
				it["light"] = f.get_16() # light level/intensity
				f.get_16() # light color
			23, 24:
				pass # DontHide/Translucent
			25: # Displacement (cf. OTClient ThingAttrDisplacement)
				it["displacement_x"] = f.get_16()
				it["displacement_y"] = f.get_16()
			26: # Elevation (cf. OTClient ThingAttrElevation, pixels above ground)
				it["elevation"] = f.get_16()
			27, 28:
				pass # Lying/AnimateAlways
			29:
				f.get_16() # minimap color
			30:
				f.get_16() # lensHelp
			31, 32:
				pass # FullGround/IgnoreLook
			33:
				f.get_16() # cloth
			34: # Market: category + wareId + showAs + name + profession + level
				f.get_16()
				f.get_16(); f.get_16()
				var nl := f.get_16()
				for _i in range(nl):
					f.get_8()
				f.get_16(); f.get_16()
			35:
				f.get_16() # DefaultAction
			254, 36, 37, 38:
				pass # Usable/Wrappable/Unwrappable/TopEffect
			255:
				break # LastFlag
			_:
				push_error("BlackTekDat: unknown flag %d at id %d" % [flag, id])
				return {}
	# Trailer: width/height/layers/patterns/frames/sprite ids (cf. items.cpp:1287).
	var w := f.get_8()
	var h := f.get_8()
	if w > 1 or h > 1:
		f.get_8()
	var layers := f.get_8()
	var pat_x := f.get_8()
	var pat_y := f.get_8()
	var pat_z := f.get_8()
	var frames := f.get_8()
	var n: int = w * h * layers * pat_x * pat_y * pat_z * frames
	if frames > 1: # frame durations block, true for 10.98
		var skip := 6 + 8 * frames
		for _i in range(skip):
			f.get_8()
	# Sprite IDs are u32 (cf. items.cpp:1312). Needed to map items -> Tibia.spr.
	# Block layout cf. OTClient getSpriteIndex: width innermost, drawn bottom-right anchored.
	var ids := PackedInt32Array()
	ids.resize(n)
	for i in range(n):
		ids[i] = f.get_32()
	it["sprite_count"] = n
	it["sprites"] = ids
	it["w"] = w
	it["h"] = h
	it["layers"] = layers
	it["pat_x"] = pat_x
	it["pat_y"] = pat_y
	it["pat_z"] = pat_z
	it["frames"] = frames
	return it

func first_sprite(id: int) -> int:
	var sprites: PackedInt32Array = items.get(id, {}).get("sprites", PackedInt32Array())
	for s in sprites:
		if s > 0:
			return s
	return 0
