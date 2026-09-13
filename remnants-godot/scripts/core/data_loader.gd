extends RefCounted
## DataLoader — core loader for the data/ tree (the image's "core/data_loader").
## GameBalance (the autoload singleton) owns the parsed content and the public
## API; this class owns the FILES: split-slice-first, content.json fallback.
##
## Layout (each slice file is a JSON object whose top-level keys are slices of
## the original content.json root — related keys stay together, the merge is
## a shallow top-level union, slice files win over content.json):
##   data/balance/combat.json     balance, vocations, vocationOrder, skills, skillOrder
##   data/balance/world.json      world (crypt floor + generation reference data)
##   data/maps/regions.json       REGIONS (region bounds + spawn tables)
##   data/definitions/items.def   items, itemList, equipSlots, defaultLootFilter, allItemKeys
##   data/definitions/monsters.def monsters, rivals
##   data/definitions/spells.def  abilities
##   data/definitions/npcs.def    npcs, npcStock, npc* costs
##   data/definitions/quests.def  quests (scaffold — no quest system yet)
## Note: .def files are plain JSON; the extension marks them as data
## definitions (Godot does not import them as resources).

const SLICE_FILES: Array = [
	"res://data/balance/combat.json",
	"res://data/balance/world.json",
	"res://data/maps/regions.json",
	"res://data/definitions/items.def",
	"res://data/definitions/monsters.def",
	"res://data/definitions/spells.def",
	"res://data/definitions/npcs.def",
	"res://data/definitions/quests.def",
]

## Files the last load_content() actually read (GameBalance logs this).
var sources: Array = []

## Build the content root: content.json as the base (web export fallback),
## then every present slice file merged over it. Merge rule per top-level
## key: when both sides are Dictionaries they combine one level deep (slice
## sub-keys win, base sub-keys survive) so world.json and maps/regions.json
## can both contribute to `world`; anything else replaces outright.
func load_content(primary: String = "res://data/content.json") -> Dictionary:
	sources = []
	var root: Dictionary = {}
	if FileAccess.file_exists(primary):
		var base: Variant = read_json(primary)
		if typeof(base) == TYPE_DICTIONARY:
			root = base
			sources.append(primary)
		else:
			push_error("[DataLoader] %s is not a Dictionary" % primary)
	for path in SLICE_FILES:
		if not FileAccess.file_exists(path):
			continue
		var slice: Variant = read_json(path)
		if typeof(slice) != TYPE_DICTIONARY:
			push_error("[DataLoader] %s is not a Dictionary (slices are objects, not bare arrays)" % path)
			continue
		for k in (slice as Dictionary).keys():
			var slice_val: Variant = slice[k]
			var base_val: Variant = root.get(k, null)
			if typeof(base_val) == TYPE_DICTIONARY and typeof(slice_val) == TYPE_DICTIONARY:
				var merged: Dictionary = (base_val as Dictionary).duplicate()
				for sub_k in (slice_val as Dictionary).keys():
					merged[sub_k] = slice_val[sub_k]
				root[k] = merged
			else:
				root[k] = slice_val
		sources.append(path)
	return root

func read_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("[DataLoader] cannot open %s" % path)
		return null
	return JSON.parse_string(f.get_as_text())
