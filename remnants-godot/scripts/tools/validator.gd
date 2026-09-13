extends SceneTree
## Validator: checks the data/ tree for integrity errors (the image's
## "tools/validator.gd"). Run after any data edit or web export:
##   Godot --headless --path . --script res://scripts/tools/validator.gd
## Exits 0 when clean, 1 with a failure list. Duplicate-ID checks are free
## here too (IDs live in dictionary keys / unique id fields) — that covers
## the "id_generator" concern: IDs come from the web export or the .def rows,
## and this catches collisions and dangling references.

const DataLoader := preload("res://scripts/core/data_loader.gd")
const Constants := preload("res://scripts/core/constants.gd")

var failures: Array = []

func _check(cond: bool, label: String) -> void:
	print("[VALIDATE] %s: %s" % ["PASS" if cond else "FAIL", label])
	if not cond:
		failures.append(label)

func _init() -> void:
	var loader := DataLoader.new()
	var root: Dictionary = loader.load_content()
	_check(not root.is_empty(), "content root loads (sources: %s)" % str(loader.sources))
	if root.is_empty():
		printerr("[VALIDATE] no data to validate")
		quit(1)
		return
	var items: Dictionary = root.get("items", {})
	var monsters: Dictionary = root.get("monsters", {})
	var abilities: Array = root.get("abilities", [])
	var npcs: Array = root.get("npcs", [])
	var skills: Dictionary = root.get("skills", {})
	var world: Dictionary = root.get("world", {})
	_validate_items(items, root)
	_validate_monsters(monsters, items, root)
	_validate_abilities(abilities)
	_validate_skills(skills)
	_validate_npcs(npcs, items)
	_validate_world(world, monsters)
	_check((root.get("allItemKeys", []) as Array).size() == items.size(), "allItemKeys covers every item (%d)" % items.size())
	var lost: Array = (root.get("defaultLootFilter", []) as Array).filter(func(k): return not items.has(k))
	_check(lost.is_empty(), "defaultLootFilter references real items")
	print("[VALIDATE] done failures=%d" % failures.size())
	if failures.is_empty():
		print("[VALIDATE] ALL PASS")
	else:
		printerr("[VALIDATE] FAILURES: %s" % str(failures))
	quit(0 if failures.is_empty() else 1)

func _validate_items(items: Dictionary, root: Dictionary) -> void:
	for key in items.keys():
		var def: Dictionary = items[key]
		_check(String(def.get("key", key)) == String(key), "item '%s' id matches its key field" % String(key))
		_check(Constants.ITEM_KINDS.has(String(def.get("kind", ""))), "item '%s' kind is known (%s)" % [String(key), String(def.get("kind", ""))])
		_check(Constants.RARITIES.has(String(def.get("rarity", ""))), "item '%s' rarity is known" % String(key))
		if String(def.get("kind", "")) == "consumable":
			_check(not (def.get("effect", {}) as Dictionary).is_empty(), "consumable '%s' carries an effect" % String(key))
		var slot := String(def.get("slot", ""))
		if slot != "":
			_check(Constants.EQUIP_SLOTS.has(slot), "item '%s' slot is a real equip slot (%s)" % [String(key), slot])
	for key in (root.get("npcStock", []) as Array):
		_check(items.has(String(key)), "npc stock item '%s' exists" % String(key))

func _validate_monsters(monsters: Dictionary, items: Dictionary, root: Dictionary) -> void:
	var spawn_keys := {}
	for reg in (root.get("world", {}).get("REGIONS", []) as Array):
		for s in ((reg as Dictionary).get("spawns", []) as Array):
			spawn_keys[String(s["key"])] = true
	for s in ((root.get("world", {}) as Dictionary).get("CRYPT", {}) as Dictionary).get("SPAWNS", []):
		spawn_keys[String(s["key"])] = true
	for mk in monsters.keys():
		var def: Dictionary = monsters[mk]
		_check(String(def.get("key", mk)) == String(mk), "monster '%s' id matches its key field" % String(mk))
		_check(spawn_keys.has(String(mk)), "monster '%s' reachable from a spawn table" % String(mk))
		_check(int(def.get("hp", 0)) > 0, "monster '%s' has positive hp" % String(mk))
		_check(Constants.MONSTER_SHAPES.has(String(def.get("shape", "single"))), "monster '%s' attack shape is known" % String(mk))
		for entry in (def.get("loot", []) as Array):
			_check(items.has(String(entry.get("itemKey", ""))), "monster '%s' loot '%s' exists" % [String(mk), String(entry.get("itemKey", ""))])
			_check(float(entry.get("chance", -1.0)) >= 0.0 and float(entry.get("chance", -1.0)) <= 1.0, "monster '%s' loot chance in range" % String(mk))
	_check(not spawn_keys.is_empty(), "at least one spawn table exists")

func _validate_abilities(abilities: Array) -> void:
	for a in abilities:
		var def: Dictionary = a
		var key := String(def.get("key", ""))
		_check(key != "", "ability has a key")
		_check(Constants.ABILITY_SHAPES.has(String(def.get("shape", ""))), "ability '%s' shape is known (%s)" % [key, String(def.get("shape", ""))])
		_check(int(def.get("cooldown", 0)) >= 0 and int(def.get("manaCost", 0)) >= 0, "ability '%s' cost/cooldown non-negative" % key)

func _validate_skills(skills: Dictionary) -> void:
	for sk in skills.keys():
		var def: Dictionary = skills[sk]
		var eff: Dictionary = def.get("effect", {})
		_check(not eff.is_empty(), "skill '%s' carries an effect" % String(sk))
		var unknown: Array = eff.keys().filter(func(k): return not Constants.SKILL_EFFECT_KEYS.has(String(k)))
		_check(unknown.is_empty(), "skill '%s' effect keys understood %s" % [String(sk), str(unknown)])

func _validate_npcs(npcs: Array, _items: Dictionary) -> void:
	var ids := {}
	for n in npcs:
		var def: Dictionary = n
		var id := String(def.get("id", ""))
		_check(id != "" and not ids.has(id), "npc id '%s' unique" % id)
		ids[id] = true
		_check(Constants.NPC_ROLES.has(String(def.get("role", ""))), "npc '%s' role known (%s)" % [id, String(def.get("role", ""))])
		_check((def.get("pos", []) as Array).size() == 3, "npc '%s' pos is x,y,z" % id)

func _validate_world(world: Dictionary, monsters: Dictionary) -> void:
	var regions: Array = world.get("REGIONS", [])
	_check(not regions.is_empty(), "regions present (%d)" % regions.size())
	for reg in regions:
		var r: Dictionary = reg
		var key := String(r.get("key", ""))
		_check(key != "", "region has a key")
		for s in (r.get("spawns", []) as Array):
			_check(monsters.has(String(s["key"])), "region '%s' spawn '%s' has a monster def" % [key, String(s["key"])])
			_check(int(s.get("weight", 0)) > 0, "region '%s' spawn '%s' has positive weight" % [key, String(s["key"])])
	var crypt: Dictionary = world.get("CRYPT", {})
	if not crypt.is_empty():
		for s in (crypt.get("SPAWNS", []) as Array):
			_check(monsters.has(String(s["key"])), "crypt spawn '%s' has a monster def" % String(s["key"]))
		_check(int(crypt.get("W", 0)) > 0 and int(crypt.get("H", 0)) > 0, "crypt floor size positive")
