# BlackTek players: compatibility facade over focused player/* modules.
# New code should call the submodules directly:
#   BlackTekVitals (vocation math, hp/mana/food/skills/conditions),
#   BlackTekInventory (bag/equipment/gold/shop),
#   BlackTekMovement (steps/stairs/floors/spawn/town),
#   BlackTekInteraction (push/drop/pickup/doors).
# This class keeps the old BlackTekPlayer.* API stable so callers,
# combat/loot/regen and the headless suite never change.
class_name BlackTekPlayer
extends RefCounted

# ---- vocation math (impl in player/vitals.gd) ----

static func max_hp(voc: int, level: int) -> int:
	# Legacy 2-arg form (no game ref): uses shared config fallback.
	return BlackTekVitals.max_hp(BlackTekConfig.shared(), voc, level)

static func max_hp_for(game, voc: int, level: int) -> int:
	return BlackTekVitals.max_hp(game, voc, level)

static func max_mana(voc: int, level: int) -> int:
	return BlackTekVitals.max_mana(BlackTekConfig.shared(), voc, level)

static func max_mana_for(game, voc: int, level: int) -> int:
	return BlackTekVitals.max_mana(game, voc, level)

static func exp_for_level(level: int) -> int:
	return BlackTekVitals.exp_for_level(level)

static func vocation_roll(game, pid: int, min_v: int, max_v: int) -> int:
	return BlackTekVitals.vocation_roll(game, pid, min_v, max_v)

static func is_gm(game, pid: int) -> bool:
	return BlackTekVitals.is_gm(game, pid)

# ---- session (cf. protocollogin / protocolgame) ----

# Loads a DB row into the live player (pid fixed to 1 for the demo client).
static func enter_world(game, player_row: Dictionary) -> Vector2i:
	var pid := 1
	var lvl := int(player_row.get("level", 1))
	var voc := int(player_row.get("vocation", 0))
	var hpmax: int = BlackTekVitals.max_hp(game, voc, lvl)
	var manamax: int = BlackTekVitals.max_mana(game, voc, lvl)
	var cap: int = 400 + int(BlackTekVitals.vocation_entry(game, voc).per_level.cap) * (lvl - 1)
	game.players[pid] = {
		"name": String(player_row.name), "vocation": voc, "level": lvl,
		"exp": int(player_row.get("experience", 0)),
		"hp": clampi(int(player_row.get("health", hpmax)), 1, hpmax), "hpmax": hpmax,
		"mana": clampi(int(player_row.get("mana", manamax)), 0, manamax), "manamax": manamax,
		"cap": cap,
		"soul": 100, "town_id": int(player_row.get("town_id", 1)),
		"skills": player_row.get("skills", {"fist": 10, "club": 10, "sword": 10, "axe": 10, "dist": 10, "shield": 10, "fishing": 10}).duplicate(true),
		"maglevel": int(player_row.get("maglevel", 0)),
		"mlvl_tries": 0, "skill_tries": {},
		"inv": {}, # slot -> item row
		"bag": {}, # bpos -> item row
		"target": 0, "food_until": 0, "poison_until": 0, "light_until": 0.0, "path": [], "_walk_cd": 0.0, "cooldowns": {},
		"attack_cd": 0.0, "row_id": int(player_row.id),
	}
	# Load items from player_items (bag rows have slot -1 + bpos index).
	for it in game.db.items_of(int(player_row.id)):
		var slot := int(it.slot)
		if slot == -1:
			game.players[pid].bag[int(it.bpos)] = it
		else:
			game.players[pid].inv[slot] = it
	# Spawn: saved position if walkable, else town/first open tile.
	var saved := Vector2i(int(player_row.get("posx", 0)), int(player_row.get("posy", 0)))
	if (not game.use_real_map or game.is_walkable(saved)) and saved != Vector2i.ZERO:
		if not game.use_real_map and game.walls.has(saved):
			saved = Vector2i(15, 11)
		game.players[pid].tile = saved
		game.players[pid].z = int(player_row.get("posz", 7))
		game.demo_z = game.players[pid].z
	else:
		game.players[pid].tile = BlackTekMovement.spawn_tile(game)
		game.players[pid].z = game.demo_z
	# Spawn tile = town temple in the demo -> protection zone around it.
	if (game.account as Dictionary).is_empty() or not game.use_real_map:
		game.temple_tile = game.players[pid].tile
	elif game.temple_tile == Vector2i(-9999, -9999):
		game.temple_tile = game.players[pid].tile
	# Norf the shop NPC holds a real post next to the temple (own entity on
	# a free neighbouring tile — never stacked on the player). Trading,
	# buying and selling all require standing next to him.
	game.npc_tile = game.players[pid].tile
	game.npc_z = game.players[pid].z
	game.monsters.clear()
	game.monsters_changed.emit()
	BlackTekNpc.spawn_all(game)
	BlackTekMonsters.try_spawn(game, pid)
	game.stats_changed.emit(pid)
	game.inventory_changed.emit(pid)
	game.msg_local.emit(pid, "Welcome, %s! MockDB session active (no MariaDB)." % String(player_row.name))
	game.world_entered.emit(pid)
	return game.players[pid].tile

static func save_all(game) -> void:
	var pid := 1
	if not game.players.has(pid) or (game.account as Dictionary).is_empty():
		return
	var p: Dictionary = game.players[pid]
	for row in game.db.db.players:
		if int(row.id) == int(p.row_id):
			row.level = int(p.level)
			row.experience = int(p.exp)
			row.health = int(p.hp)
			row.healthmax = int(p.hpmax)
			row.mana = int(p.mana)
			row.manamax = int(p.manamax)
			row.maglevel = int(p.maglevel)
			row.posx = int(p.tile.x)
			row.posy = int(p.tile.y)
			row.posz = int(p.z)
			row.skills = p.skills.duplicate(true)
			break
	# Items: rebuild rows (sid preserved where possible).
	game.db.db.player_items = game.db.db.player_items.filter(func(it): return int(it.pid) != int(p.row_id))
	for slot in p.inv.keys():
		var it: Dictionary = p.inv[slot] if p.inv[slot] != null else {}
		if not it.is_empty():
			game.db.add_item(int(p.row_id), int(it.itemtype), int(it.count), int(slot), -1)
	for bpos in p.bag.keys():
		var it2: Dictionary = p.bag[bpos] if p.bag[bpos] != null else {}
		if not it2.is_empty():
			game.db.add_item(int(p.row_id), int(it2.itemtype), int(it2.count), -1, int(bpos))
	game.db.save_db()

# ---- vitals (impl in player/vitals.gd) ----

static func heal_player(game, pid: int, amount: int, source: String) -> void:
	BlackTekVitals.heal_player(game, pid, amount, source)

static func add_mana(game, pid: int, amount: int, source: String) -> void:
	BlackTekVitals.add_mana(game, pid, amount, source)

static func spend_mana(game, pid: int, amount: int) -> void:
	BlackTekVitals.spend_mana(game, pid, amount)

static func set_food(game, pid: int, seconds: int) -> void:
	BlackTekVitals.set_food(game, pid, seconds)

static func advance_skill(game, pid: int, skill: String) -> void:
	BlackTekVitals.advance_skill(game, pid, skill)

# ---- inventory and gold (impl in player/inventory.gd) ----

static func add_item(game, pid: int, itemtype: int, count := 1) -> bool:
	return BlackTekInventory.add_item(game, pid, itemtype, count)

static func consume_item(game, pid: int, row: Dictionary) -> void:
	BlackTekInventory.consume_item(game, pid, row)

static func pay_gold(game, pid: int, amount: int) -> bool:
	return BlackTekInventory.pay_gold(game, pid, amount)

static func buy_shop_item(game, pid: int, offer: Dictionary, count := 1) -> void:
	BlackTekInventory.buy_shop_item(game, pid, offer, count)

static func sell_shop_item(game, pid: int, offer: Dictionary, count := 1) -> void:
	BlackTekInventory.sell_shop_item(game, pid, offer, count)

static func count_of(game, pid: int, itemtype: int) -> int:
	return BlackTekInventory.count_of(game, pid, itemtype)

static func remove_items(game, pid: int, itemtype: int, count: int) -> bool:
	return BlackTekInventory.remove_items(game, pid, itemtype, count)

# ---- movement (impl in player/movement.gd) ----

static func can_step(game, pid: int, dir: Vector2i) -> bool:
	return BlackTekMovement.can_step(game, pid, dir)

static func step_blocker(game, pid: int, dir: Vector2i) -> String:
	return BlackTekMovement.step_blocker(game, pid, dir)

static func solid_label(game, tile: Vector2i, z: int) -> String:
	return BlackTekMovement.solid_label(game, tile, z)

static func request_move(game, player_id: int, dir: Vector2i) -> Vector2i:
	return BlackTekMovement.request_move(game, player_id, dir)

static func spawn_tile(game) -> Vector2i:
	return BlackTekMovement.spawn_tile(game)

static func teleport_town(game, pid: int) -> bool:
	return BlackTekMovement.teleport_town(game, pid)

static func try_stair_teleport(game, player_id: int) -> int:
	return BlackTekMovement.try_stair_teleport(game, player_id)

static func request_floor(game, player_id: int, dz: int) -> bool:
	return BlackTekMovement.request_floor(game, player_id, dz)

# ---- conditions (impl in player/vitals.gd) ----

static func is_pz_tile(game, tile: Vector2i) -> bool:
	return BlackTekVitals.is_pz_tile(game, tile)

static func is_fed(game, pid: int) -> bool:
	return BlackTekVitals.is_fed(game, pid)

static func is_poisoned(game, pid: int) -> bool:
	return BlackTekVitals.is_poisoned(game, pid)

# ---- player-initiated world interactions (impl in player/interaction.gd) ----

static func pushable_item_at(game, tile: Vector2i, z: int) -> Dictionary:
	return BlackTekInteraction.pushable_item_at(game, tile, z)

static func can_push_item(game, tile: Vector2i, dir: Vector2i, z: int) -> bool:
	return BlackTekInteraction.can_push_item(game, tile, dir, z)

static func push_item(game, tile: Vector2i, dir: Vector2i, z: int, pid: int) -> bool:
	return BlackTekInteraction.push_item(game, tile, dir, z, pid)

static func takeable_item_at(game, tile: Vector2i, z: int) -> Dictionary:
	return BlackTekInteraction.takeable_item_at(game, tile, z)

static func can_pickup(game, pid: int, itemtype: int) -> bool:
	return BlackTekInventory.can_pickup(game, pid, itemtype)

static func drop_item(game, pid: int, bpos: int, tile: Vector2i, z: int) -> bool:
	return BlackTekInteraction.drop_item(game, pid, bpos, tile, z)

static func drop_equipped(game, pid: int, slot: int, tile: Vector2i, z: int) -> bool:
	return BlackTekInteraction.drop_equipped(game, pid, slot, tile, z)

static func pickup_item(game, tile: Vector2i, z: int, pid: int) -> bool:
	return BlackTekInteraction.pickup_item(game, tile, z, pid)

# ---- doors (impl in player/interaction.gd) ----

static func door_at(game, tile: Vector2i, z: int) -> Dictionary:
	return BlackTekInteraction.door_at(game, tile, z)

static func use_door(game, tile: Vector2i, z: int, pid: int) -> bool:
	return BlackTekInteraction.use_door(game, tile, z, pid)
