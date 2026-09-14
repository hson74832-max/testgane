# Minimal OTBM parser — mirrors OTB::Loader::parseTree (src/fileloader.cpp:36)
# + IOMap tile walk (src/iomap.cpp:280). Node framing: FE START / FF END,
# # FD ESCAPE. Only TILE_AREA -> TILE/HOUSETILE + inline/child item IDs are kept.
# Full forgotten.otbm is 3.4MB; parse once at startup, render viewport only.
class_name BlackTekOtbm
extends RefCounted

const START := 0xFE
const END := 0xFF
const ESC := 0xFD

const N_ROOT := 1
const N_MAP_DATA := 2
const N_TILE_AREA := 4
const N_TILE := 5
const N_ITEM := 6
const N_TOWNS := 12
const N_TOWN := 13
const N_HOUSETILE := 14

const ATTR_TILE_FLAGS := 3
const ATTR_ITEM := 9

# Vector3i(x,y,z) -> {flags:int, items:PackedInt32Array, house:bool}
var tiles: Dictionary = {}
var width := 0
var height := 0
var towns: Array = [] # {id, name, pos}
var _areas_done := 0

func load(path: String, max_tiles := 1000000) -> bool:
	var bytes := _read_all(path)
	if bytes.is_empty():
		return false
	print("BlackTekOtbm: size=%d head=%02X %02X %02X %02X" % [bytes.size(), bytes[0], bytes[1], bytes[2], bytes[3]])
	# Identifier is usually "OTBM", but RME-saved maps may carry 4 zero bytes —
	# the C++ loader accepts both (wildcard, cf. src/fileloader.cpp:11-25).
	var is_otbm := bytes[0] == 0x4F and bytes[1] == 0x54 and bytes[2] == 0x42 and bytes[3] == 0x4D
	var is_wild := bytes[0] == 0 and bytes[1] == 0 and bytes[2] == 0 and bytes[3] == 0
	if bytes.size() < 8 or not (is_otbm or is_wild):
		push_error("BlackTekOtbm: bad identifier")
		return false
	var root := _parse_tree(bytes)
	if root.is_empty():
		push_error("BlackTekOtbm: empty tree")
		return false
	print("BlackTekOtbm: tree ok root=%d children=%d" % [int(root["type"]), root["children"].size()])
	return _walk(root, max_tiles)

func tile_items(pos: Vector3i) -> PackedInt32Array:
	return tiles.get(pos, {}).get("items", PackedInt32Array())

# Compact cache: magic BTC1, u32 count, per tile x u16/y u16/z u8/flags u32/n u8/items u16.
# Full GDScript OTBM parse takes minutes; cache loads in <1s.
func load_cache(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null or f.get_32() != 0x31435442: # "BTC1" LE
		return false
	var n := f.get_32()
	for _i in range(n):
		var x := f.get_16()
		var y := f.get_16()
		var z := f.get_8()
		var flags := f.get_32()
		var c := f.get_8()
		var ids := PackedInt32Array()
		ids.resize(c)
		for k in range(c):
			ids[k] = f.get_16()
		tiles[Vector3i(x, y, z)] = {"flags": flags, "items": ids, "house": false}
	var nt := f.get_16()
	for _i in range(nt):
		var id := f.get_32()
		var nl := f.get_8()
		var nm := _safe_name(f.get_buffer(nl))
		var tx := f.get_16()
		var ty := f.get_16()
		var tz := f.get_8()
		towns.append({"id": id, "name": nm, "pos": Vector3i(tx, ty, tz)})
	f.close()
	return not tiles.is_empty()

func save_cache(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_32(0x31435442)
	f.store_32(tiles.size())
	for pos in tiles.keys():
		var e: Dictionary = tiles[pos]
		f.store_16(pos.x)
		f.store_16(pos.y)
		f.store_8(pos.z)
		f.store_32(int(e.get("flags", 0)))
		var ids: PackedInt32Array = e.get("items", PackedInt32Array())
		f.store_8(mini(ids.size(), 255))
		for k in range(mini(ids.size(), 255)):
			f.store_16(ids[k])
	f.store_16(mini(towns.size(), 32767))
	for t in towns:
		f.store_32(int(t["id"]))
		var nb := String(t["name"]).to_ascii_buffer()
		f.store_8(mini(nb.size(), 255))
		f.store_buffer(nb.slice(0, mini(nb.size(), 255)))
		var tp: Vector3i = t["pos"]
		f.store_16(tp.x)
		f.store_16(tp.y)
		f.store_8(tp.z)
	f.close()
	return true

func _read_all(path: String) -> PackedByteArray:
	# Static read avoids cursor issues seen with get_buffer on large binaries.
	if not FileAccess.file_exists(path):
		push_error("BlackTekOtbm: cannot open %s" % path)
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(path)

# Returns nested dict {type, props:PackedByteArray, children:Array}, props still escaped.
func _parse_tree(b: PackedByteArray) -> Dictionary:
	var pos := 4
	if b[pos] != START:
		push_error("BlackTekOtbm: no root START")
		return {}
	var root := {"type": b[pos + 1], "props": PackedByteArray(), "children": []}
	pos += 2
	var prop_start := pos
	var stack: Array = [root]
	while pos < b.size():
		var c := b[pos]
		if c == START:
			# Mirror C++ (fileloader.cpp): parent props end at the FIRST child only.
			var cur: Dictionary = stack[stack.size() - 1]
			if (cur["children"] as Array).is_empty():
				cur["props"] = b.slice(prop_start, pos)
			var child := {"type": b[pos + 1], "props": PackedByteArray(), "children": []}
			(cur["children"] as Array).append(child)
			stack.append(child)
			pos += 2
			prop_start = pos
		elif c == END:
			var cur2: Dictionary = stack[stack.size() - 1]
			if (cur2["children"] as Array).is_empty():
				cur2["props"] = b.slice(prop_start, pos)
			stack.pop_back()
			if stack.is_empty():
				break
			pos += 1
			prop_start = pos
		elif c == ESC:
			pos += 2 # keep escaped pair inside props slice; unescaped later
		else:
			pos += 1
	return root

func _cur(stack: Array) -> Dictionary:
	return stack[stack.size() - 1]

func _unescape(p: PackedByteArray) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(p.size())
	var w := 0
	var i := 0
	while i < p.size():
		if p[i] == ESC and i + 1 < p.size():
			i += 1
			out[w] = p[i]
		else:
			out[w] = p[i]
		w += 1
		i += 1
	out.resize(w)
	return out

func _walk(root: Dictionary, max_tiles: int) -> bool:
	if root["children"].is_empty() or root["children"][0]["type"] != N_MAP_DATA:
		push_error("BlackTekOtbm: no MAP_DATA")
		return false
	var map_node: Dictionary = root["children"][0]
	# Root props = OTBM_root_header: version u32, w u16, h u16, major u32, minor u32.
	var rp := _unescape(root["props"])
	if rp.size() >= 12:
		width = rp.decode_u16(4)
		height = rp.decode_u16(6)
	var kinds := {}
	for child in map_node["children"]:
		kinds[int(child["type"])] = int(kinds.get(int(child["type"]), 0)) + 1
	print("BlackTekOtbm: map %dx%d node kinds=%s" % [width, height, str(kinds)])
	for child in map_node["children"]:
		if child["type"] == N_TILE_AREA:
			_parse_area(child)
			_areas_done += 1
			if tiles.size() >= max_tiles:
				break
		elif child["type"] == N_TOWNS:
			_parse_towns(child)
	print("BlackTekOtbm: done areas=%d tiles=%d towns=%d" % [_areas_done, tiles.size(), towns.size()])
	return not tiles.is_empty()

func _parse_area(area: Dictionary) -> void:
	var ap := _unescape(area["props"])
	if ap.size() < 5:
		return
	var base_x := ap.decode_u16(0)
	var base_y := ap.decode_u16(2)
	var base_z := ap[4]
	for t in area["children"]:
		if t["type"] != N_TILE and t["type"] != N_HOUSETILE:
			continue
		var tp := _unescape(t["props"])
		if tp.size() < 2:
			continue
		var pos := Vector3i(base_x + tp[0], base_y + tp[1], base_z)
		var flags := 0
		var item_ids := PackedInt32Array()
		var p := 2
		if t["type"] == N_HOUSETILE:
			p += 4 # houseId u32
		while p < tp.size():
			var attr := tp[p]
			p += 1
			if attr == ATTR_TILE_FLAGS and p + 4 <= tp.size():
				flags = tp.decode_u32(p)
				p += 4
			elif attr == ATTR_ITEM and p + 2 <= tp.size():
				item_ids.append(tp.decode_u16(p))
				p += 2 # CreateItem reads u16 id; extra attrs live in child nodes
			else:
				break # unknown attr -> stop, child ITEM nodes handled below
		for sub in t["children"]:
			if sub["type"] == N_ITEM:
				var sp := _unescape(sub["props"])
				if sp.size() >= 2:
					item_ids.append(sp.decode_u16(0))
		tiles[pos] = {"flags": flags, "items": item_ids, "house": t["type"] == N_HOUSETILE}

func _parse_towns(RespawnNode: Dictionary) -> void:
	for t in RespawnNode["children"]:
		if t["type"] != N_TOWN:
			continue
		var p := _unescape(t["props"])
		# Layout cf. IOMap::parseTowns: u32 id, string(u16 len + bytes), x u16, y u16, z u8.
		if p.size() < 11:
			continue
		var id := p.decode_u32(0)
		var nl: int = p.decode_u16(4)
		if 6 + nl + 5 > p.size():
			continue
		var name := _safe_name(p.slice(6, 6 + nl))
		var x := p.decode_u16(6 + nl)
		var y := p.decode_u16(8 + nl)
		var z := p[10 + nl]
		towns.append({"id": id, "name": name, "pos": Vector3i(x, y, z)})

func _safe_name(b: PackedByteArray) -> String:
	# Town names may contain latin-1 bytes; decode ASCII-safe to avoid UTF-8 errors.
	var out := PackedByteArray()
	for byte in b:
		out.append(byte if byte < 128 else 63) # '?' for non-ASCII
	return out.get_string_from_ascii()
