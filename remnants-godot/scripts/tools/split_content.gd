extends SceneTree
## Splitter: data/content.json -> the data/ slice tree (re-runnable).
## Run: Godot --headless --path . --script res://scripts/tools/split_content.gd
## After a fresh web export (new content.json), re-run this to refresh the
## slices — or edit slices directly and treat content.json as the fallback.
## Each slice file is a JSON object of content.json root keys (see DataLoader).

func _init() -> void:
	var f := FileAccess.open("res://data/content.json", FileAccess.READ)
	if f == null:
		printerr("[split] data/content.json not found — nothing to split")
		quit(1)
		return
	var root: Variant = JSON.parse_string(f.get_as_text())
	if typeof(root) != TYPE_DICTIONARY:
		printerr("[split] content.json is not a Dictionary")
		quit(1)
		return
	var world: Dictionary = root.get("world", {})
	var slices := {
		"res://data/balance/combat.json": _pick(root, ["balance", "vocationOrder", "vocations", "skillOrder", "skills"]),
		"res://data/balance/world.json": {"world": _without(world, ["REGIONS"])},
		"res://data/maps/regions.json": {"REGIONS": world.get("REGIONS", [])},
		"res://data/definitions/items.def": _pick(root, ["items", "itemList", "equipSlots", "defaultLootFilter", "allItemKeys"]),
		"res://data/definitions/monsters.def": _pick(root, ["monsters", "rivals"]),
		"res://data/definitions/spells.def": _pick(root, ["abilities"]),
		"res://data/definitions/npcs.def": _pick(root, ["npcs", "npcStock", "npcTalkRange", "npcHealCost", "npcFerryCost", "npcSellPct"]),
		"res://data/definitions/quests.def": {"quests": root.get("quests", [])},
	}
	var written := 0
	for path in slices:
		if _write(path, slices[path]):
			written += 1
	print("[split] wrote %d slice files from content.json (v%s)" % [written, str(root.get("version", "?"))])
	quit(0 if written == slices.size() else 1)

func _pick(root: Dictionary, keys: Array) -> Dictionary:
	var out := {}
	for k in keys:
		if root.has(k):
			out[k] = root[k]
	return out

func _without(d: Dictionary, keys: Array) -> Dictionary:
	var out := {}
	for k in d.keys():
		if not keys.has(k):
			out[k] = d[k]
	return out

func _write(path: String, data: Dictionary) -> bool:
	var dir: String = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		printerr("[split] cannot write %s" % path)
		return false
	f.store_string(JSON.stringify(data, "\t") + "\n")
	f.close()
	print("[split] %s (%d keys)" % [path, data.size()])
	return true
