extends RefCounted
## LootSystem — drops, ground items, pickup and the satchel.
## Extracted from CombatSim: 3x3 spread corpse-first, 60s top-dealer claim,
## filter hides stacks entirely, auto-pickup on step. XP still grants
## instantly; goods travel via ground -> satchel -> WebSync.
## Also the gear/equipment kit (8 slots, flat armour / encumbrance / weapon
## sums) and consumables: port of the web satchel/equipment sheets; starter
## kit matches web getOrCreate. Consumable effects live on the item row
## (content.json items.*.effect) — a new potion is a data row, no code.

var sim  # CombatSim — wired by the sim at construction (untyped: no preload cycle)

## Ground items: {id, grid:Vector3i, item_key, qty, owner, protected_until, born, jx, jy}
var ground: Array = []
## Session satchel: item_key -> qty. Flushed to web by WebSync, listed in filter sheet.
var local_inventory: Dictionary = {}
## Which item keys render/pick up at all (HUD filter sheet).
var loot_filter: Array = []
var auto_pickup: bool = true
## Equipment: slot -> item_key (slot order lives in CombatSim.GEAR_ORDER).
var equipped: Dictionary = {}

func set_filter(keys: Array) -> void:
	loot_filter = keys.duplicate()

func set_auto_pickup(v: bool) -> void:
	auto_pickup = v

# ---------------------------------------------------------------- drops
func drop_loot(m, owner: String, now: int) -> void:
	var drops: Array = []
	for entry in (m.def.get("loot", []) as Array):
		if randf() < float(entry.get("chance", 0.0)):
			var qr: Array = entry.get("qty", [1, 1])
			drops.append({"item_key": String(entry.get("itemKey", "")), "qty": int(qr[0]) + (randi() % maxi(1, int(qr[1]) - int(qr[0]) + 1))})
	var gold_range: Array = m.def.get("gold", [1, 6])
	var gold: int = int(gold_range[0]) + (randi() % maxi(1, int(gold_range[1]) - int(gold_range[0]) + 1))
	if gold > 0:
		drops.append({"item_key": "gold", "qty": gold})
	if drops.is_empty():
		return
	var spread: Array = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if WorldGen.is_walkable(sim.tiles, m.grid.x + dx, m.grid.y + dy):
				spread.append(Vector3i(m.grid.x + dx, m.grid.y + dy, m.grid.z))
	if spread.is_empty():
		spread.append(m.grid)
	spread.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return absi(a.x - m.grid.x) + absi(a.y - m.grid.y) < absi(b.x - m.grid.x) + absi(b.y - m.grid.y))
	var protect: int = int(GameBalance.COMBAT.get("LOOT_PROTECT_MS", 60000))
	for i in range(drops.size()):
		var tile: Vector3i = spread[i % spread.size()]
		ground.append({
			"id": sim._nid(), "grid": tile,
			"item_key": String(drops[i]["item_key"]), "qty": int(drops[i]["qty"]),
			"owner": owner, "protected_until": now + protect, "born": now,
			"jx": randf_range(-0.21, 0.21), "jy": randf_range(-0.16, 0.16),
		})
	sim.queue_redraw()

## Death cache: the gold you dropped lands where you fell, locked to you for
## the standard claim window (CombatSystem announces it).
func drop_gold_cache(grid: Vector3i, qty: int, now: int) -> void:
	ground.append({
		"id": sim._nid(), "grid": grid,
		"item_key": "gold", "qty": qty,
		"owner": sim.player_name, "protected_until": now + int(GameBalance.COMBAT.get("LOOT_PROTECT_MS", 60000)),
		"born": now, "jx": 0.0, "jy": 0.0,
	})

## Ground decay, called from the sim's decay pass.
func decay(now: int) -> void:
	ground.assign(ground.filter(func(g: Dictionary) -> bool: return now - int(g.get("born", 0)) < int(GameBalance.COMBAT.get("GROUND_DECAY_MS", 180000))))

# ---------------------------------------------------------------- query
func is_visible_loot(g: Dictionary) -> bool:
	return loot_filter.has(String(g.get("item_key", "")))

func can_loot(g: Dictionary) -> bool:
	return String(g.get("owner", "")) == sim.player_name or Time.get_ticks_msec() >= int(g.get("protected_until", 0))

func visible_ground() -> Array:
	return ground.filter(func(g: Dictionary) -> bool: return is_visible_loot(g))

func nearby_loot_count() -> int:
	var player: Node2D = sim.player
	var n := 0
	for g in ground:
		if not is_visible_loot(g) or int((g["grid"] as Vector3i).z) != int(player.grid.z):
			continue
		var cell: Vector3i = g["grid"]
		if maxi(absi(cell.x - player.grid.x), absi(cell.y - player.grid.y)) <= 1:
			n += 1
	return n

# ---------------------------------------------------------------- pickup
func _take_ground(g: Dictionary, silent: bool) -> bool:
	var player: Node2D = sim.player
	if not can_loot(g):
		if not silent:
			var left: int = maxi(0, int((int(g.get("protected_until", 0)) - Time.get_ticks_msec()) / 1000))
			sim.add_float("%s · %ds" % [String(g.get("owner", "?")), left], sim._v(g["grid"]) + Vector2(0, -0.4), Color(0.97, 0.44, 0.44), false)
			sim.toast.emit("Loot protected for %s (%ds)" % [String(g.get("owner", "?")), left], "bad")
		return false
	ground.erase(g)
	if String(g.get("item_key", "")) == "gold":
		player.set("gold", int(player.get("gold")) + int(g.get("qty", 0)))
		sim.add_float("+%dg" % int(g.get("qty", 0)), sim._v(g["grid"]), Color(0.98, 0.75, 0.14), false)
		sim.looted.emit("gold", int(g.get("qty", 0)))
	else:
		local_inventory[String(g.get("item_key", ""))] = int(local_inventory.get(String(g.get("item_key", "")), 0)) + int(g.get("qty", 0))
		sim.add_float("+%s%s" % [sim._item_label(String(g.get("item_key", ""))), (" x%d" % int(g.get("qty", 0))) if int(g.get("qty", 0)) > 1 else ""], sim._v(g["grid"]), Color(0.64, 0.9, 0.21), false)
		sim.looted.emit(String(g.get("item_key", "")), int(g.get("qty", 0)))
	sim.queue_redraw()
	return true

## Manual loot of one tile (tap). Must be within 1 tile, same floor.
func loot_tile(x: int, y: int) -> void:
	var player: Node2D = sim.player
	if maxi(absi(x - player.grid.x), absi(y - player.grid.y)) > 1:
		return
	var here := Vector3i(x, y, player.grid.z)
	for g in ground.filter(func(d: Dictionary) -> bool: return (d["grid"] as Vector3i) == here and is_visible_loot(d)).duplicate():
		_take_ground(g, false)

## Sweep everything claimable and filtered within 1 tile, same floor.
func loot_all_nearby() -> void:
	var player: Node2D = sim.player
	var pz: int = int(player.grid.z)
	var near: Array = ground.filter(func(d: Dictionary) -> bool:
		if not is_visible_loot(d) or int((d["grid"] as Vector3i).z) != pz:
			return false
		var cell: Vector3i = d["grid"]
		return maxi(absi(cell.x - player.grid.x), absi(cell.y - player.grid.y)) <= 1)
	if near.is_empty():
		sim.add_float("nothing here", sim._v(player.grid) + Vector2(0, -0.4), Color(0.58, 0.64, 0.72), false)
		return
	var got := 0
	for g in near:
		if _take_ground(g, true):
			got += 1
	if got == 0 and not near.is_empty():
		var blocked: Dictionary = near[0]
		var left: int = maxi(0, int((int(blocked.get("protected_until", 0)) - Time.get_ticks_msec()) / 1000))
		sim.add_float("%s · %ds" % [String(blocked.get("owner", "?")), left], sim._v(player.grid) + Vector2(0, -0.4), Color(0.97, 0.44, 0.44), false)
		sim.toast.emit("Loot protected for %s (%ds)" % [String(blocked.get("owner", "?")), left], "bad")

## Sweep onto-the-tile stacks after a step (web parity: walk onto a stack).
func auto_pickup_at(x: int, y: int) -> void:
	if not auto_pickup:
		return
	var here := Vector3i(x, y, sim.player.grid.z)
	for g in ground.filter(func(d: Dictionary) -> bool: return (d["grid"] as Vector3i) == here and is_visible_loot(d)).duplicate():
		_take_ground(g, true)

# ---------------------------------------------------------------- satchel / gear
func seed_kit() -> void:
	equipped = {"weapon": "bone_knife", "armor": "leather_vest"}
	local_inventory["salve"] = int(local_inventory.get("salve", 0)) + 3
	local_inventory["mana_draught"] = int(local_inventory.get("mana_draught", 0)) + 2
	_recalc_gear()

func take_satchel(item_key: String, qty: int) -> void:
	var left: int = int(local_inventory.get(item_key, 0)) - qty
	if left <= 0:
		local_inventory.erase(item_key)
	else:
		local_inventory[item_key] = left

func put_satchel(item_key: String, qty: int) -> void:
	local_inventory[item_key] = int(local_inventory.get(item_key, 0)) + qty

func equip(item_key: String) -> bool:
	var player: Node2D = sim.player
	var def: Dictionary = GameBalance.item_def(item_key)
	var slot: String = String(def.get("slot", ""))
	if slot == "":
		sim.toast.emit("That item has no gear slot", "bad")
		return false
	if int(local_inventory.get(item_key, 0)) < 1:
		sim.toast.emit("You do not own that", "bad")
		return false
	take_satchel(item_key, 1)
	if equipped.has(slot):
		put_satchel(String(equipped[slot]), 1)
	equipped[slot] = item_key
	_recalc_gear()
	sim.add_float("equipped %s" % String(def.get("name", item_key)), sim._v(player.grid) + Vector2(0, -0.4), Color(1.0, 0.82, 0.4), false)
	return true

func unequip(slot: String) -> bool:
	if not equipped.has(slot):
		return false
	put_satchel(String(equipped[slot]), 1)
	equipped.erase(slot)
	_recalc_gear()
	return true

func _recalc_gear() -> void:
	var player: Node2D = sim.player
	var armor := 0
	var heavy := 0
	var weapon := 0
	for slot in equipped.keys():
		var def: Dictionary = GameBalance.item_def(String(equipped[slot]))
		armor += int(def.get("armor", 0))
		heavy += int(def.get("heavy", 0))
		if String(def.get("slot", "")) == "weapon":
			weapon += int(def.get("damage", 0))
	player.set("armor", armor)
	player.set("heavy", heavy)
	player.set("weapon_damage", weapon)

func _consumable_fx(item_key: String) -> Dictionary:
	return GameBalance.item_def(item_key).get("effect", {})

func _consumable_label(item_key: String) -> String:
	var fx: Dictionary = _consumable_fx(item_key)
	var iname := String(GameBalance.item_def(item_key).get("name", item_key))
	var bits: Array = []
	if int(fx.get("hp", 0)) > 0:
		bits.append("+%d HP" % int(fx["hp"]))
	if int(fx.get("mana", 0)) > 0:
		bits.append("+%d mana" % int(fx["mana"]))
	if bits.is_empty():
		return iname
	return "%s %s (rooted)" % [iname, " ".join(bits)]

## Consumables root you for a content-tuned moment — drinking is a commitment.
func use_consumable(item_key: String) -> bool:
	var player: Node2D = sim.player
	var fx: Dictionary = _consumable_fx(item_key)
	if fx.is_empty():
		return false
	if int(local_inventory.get(item_key, 0)) < 1:
		sim.toast.emit("You have none left", "bad")
		return false
	var now: int = Time.get_ticks_msec()
	take_satchel(item_key, 1)
	if int(fx.get("hp", 0)) > 0:
		player.set("hp", mini(int(player.get("max_hp")), int(player.get("hp")) + int(fx["hp"])))
		sim.add_float("+%d" % int(fx["hp"]), sim._v(player.grid) + Vector2(0, -0.3), Color(0.3, 0.87, 0.5), false)
	if int(fx.get("mana", 0)) > 0:
		player.set("mana", mini(int(player.get("max_mana")), int(player.get("mana")) + int(fx["mana"])))
		sim.add_float("+%d mp" % int(fx["mana"]), sim._v(player.grid) + Vector2(0, -0.6), Color(0.22, 0.74, 0.97), false)
	player.set("cast_until", now + int(GameBalance.COMBAT.get("ROOT_MS", 1200)))
	sim.toast.emit(_consumable_label(item_key), "good")
	return true

func is_consumable(item_key: String) -> bool:
	return not _consumable_fx(item_key).is_empty()

func is_equippable(item_key: String) -> bool:
	return String(GameBalance.item_def(item_key).get("slot", "")) != ""
