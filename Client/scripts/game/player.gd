# BlackTek players: sessions (enter world, save), vocation math, health/mana/
# food/conditions, inventory and gold, movement (steps, stairs, floors, town),
# and player-initiated world interactions (item/door pushes, drops, pickups).
# Stateless algorithms — live players, signals and the clock live on the game.
class_name BlackTekPlayer
extends RefCounted

# ---- vocation math -----------------------------------------------------------
# NOTE: the itemtype -> equipment slot map lives on the server
# (BlackTekGameServer.EQUIP_SLOT), shared with the gear panel and HUD.

static func max_hp(voc: int, level: int) -> int:
	return 150 + int(BlackTekGameServer.VOCATIONS[voc].per_level.hp) * (level - 1)

static func max_mana(voc: int, level: int) -> int:
	return 35 + int(BlackTekGameServer.VOCATIONS[voc].per_level.mana) * (level - 1)

static func exp_for_level(level: int) -> int:
	var l := float(level)
	return int(50.0 / 3.0 * (pow(l, 3) - 6.0 * l * l + 17.0 * l - 12.0))

static func vocation_roll(_game, _pid: int, min_v: int, max_v: int) -> int:
	return randi_range(min_v, max_v)

static func is_gm(_game, _pid: int) -> bool:
	return false # demo account is a normal player; GM talkactions show the gate

# ---- session (cf. protocollogin / protocolgame) -------------------------------

# Loads a DB row into the live player (pid fixed to 1 for the demo client).
static func enter_world(game, player_row: Dictionary) -> Vector2i:
	var pid := 1
	var lvl := int(player_row.get("level", 1))
	var voc := int(player_row.get("vocation", 0))
	var hpmax := BlackTekPlayer.max_hp(voc, lvl)
	var manamax := BlackTekPlayer.max_mana(voc, lvl)
	game.players[pid] = {
		"name": String(player_row.name), "vocation": voc, "level": lvl,
		"exp": int(player_row.get("experience", 0)),
		"hp": clampi(int(player_row.get("health", hpmax)), 1, hpmax), "hpmax": hpmax,
		"mana": clampi(int(player_row.get("mana", manamax)), 0, manamax), "manamax": manamax,
		"cap": 400 + BlackTekGameServer.VOCATIONS[voc].per_level.cap * (lvl - 1),
		"soul": 100, "town_id": int(player_row.get("town_id", 1)),
		"skills": player_row.get("skills", {"fist": 10, "club": 10, "sword": 10, "axe": 10, "dist": 10, "shield": 10, "fishing": 10}).duplicate(true),
		"maglevel": int(player_row.get("maglevel", 0)),
		"mlvl_tries": 0, "skill_tries": {},
		"inv": {}, # slot -> item row
		"bag": {}, # bpos -> item row
		"target": 0, "food_until": 0, "poison_until": 0, "path": [], "_walk_cd": 0.0, "cooldowns": {},
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
		game.players[pid].tile = BlackTekPlayer.spawn_tile(game)
		game.players[pid].z = game.demo_z
	# Spawn tile = town temple in the demo -> protection zone around it.
	if game.account.is_empty() or not game.use_real_map:
		game.temple_tile = game.players[pid].tile
	elif game.temple_tile == Vector2i(-9999, -9999):
		game.temple_tile = game.players[pid].tile
	# Norf the shop NPC holds his post at the temple (local-chat anchor).
	game.npc_tile = game.players[pid].tile
	game.npc_z = game.players[pid].z
	game.monsters.clear()
	game.monsters_changed.emit()
	BlackTekMonsters.try_spawn(game, pid)
	game.stats_changed.emit(pid)
	game.inventory_changed.emit(pid)
	game.msg_local.emit(pid, "Welcome, %s! MockDB session active (no MariaDB)." % String(player_row.name))
	game.world_entered.emit(pid)
	return game.players[pid].tile

static func save_all(game) -> void:
	var pid := 1
	if not game.players.has(pid) or game.account.is_empty():
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

# ---- vitals -------------------------------------------------------------------

static func heal_player(game, pid: int, amount: int, source: String) -> void:
	var p: Dictionary = game.players[pid]
	var before := int(p.hp)
	p.hp = mini(int(p.hp) + amount, int(p.hpmax))
	if p.hp > before:
		game.damage_float.emit(p.tile, int(p.z), int(p.hp) - before, false)
		game.message_local(pid, "You healed yourself for %d hitpoints (%s)." % [int(p.hp) - before, source])
	else:
		game.message_local(pid, "Your health is already full.")
	game.stats_changed.emit(pid)

static func add_mana(game, pid: int, amount: int, source: String) -> void:
	var p: Dictionary = game.players[pid]
	var before := int(p.mana)
	p.mana = mini(int(p.mana) + amount, int(p.manamax))
	game.message_local(pid, "You gained %d mana (%s)." % [int(p.mana) - before, source])
	game.stats_changed.emit(pid)

static func spend_mana(game, pid: int, amount: int) -> void:
	var p: Dictionary = game.players[pid]
	p.mana = maxi(0, int(p.mana) - amount)
	# Magic level advance (demo-scaled; real: mana spent vs vocation magic rate).
	p.mlvl_tries = int(p.get("mlvl_tries", 0)) + amount
	var need := int((int(p.maglevel) + 1) * 80.0 / BlackTekGameServer.RATE_MAGIC)
	if p.mlvl_tries >= need:
		p.mlvl_tries -= need
		p.maglevel = int(p.maglevel) + 1
		game.message_local(pid, "You advanced to magic level %d." % int(p.maglevel))
	game.stats_changed.emit(pid)

static func set_food(game, pid: int, seconds: int) -> void:
	game.players[pid].food_until = Time.get_ticks_msec() / 1000 + seconds
	game.message_local(pid, "Well fed: faster regeneration for %ds." % seconds)

static func advance_skill(game, pid: int, skill: String) -> void:
	var p: Dictionary = game.players[pid]
	var tries: Dictionary = p.skill_tries
	tries[skill] = int(tries.get(skill, 0)) + 10
	# Demo-scaled advance (real: skill_tries vs (skill+1)^3 / vocation rate).
	var need := int((int(p.skills[skill]) + 1) * 12.0 / BlackTekGameServer.RATE_SKILL)
	if int(tries[skill]) >= need:
		tries[skill] = 0
		p.skills[skill] = int(p.skills[skill]) + 1
		game.message_local(pid, "You advanced to %s skill %d." % [skill, int(p.skills[skill])])
	game.stats_changed.emit(pid)

# ---- inventory and gold ---------------------------------------------------------

static func add_item(game, pid: int, itemtype: int, count := 1) -> bool:
	var p: Dictionary = game.players[pid]
	if game.dat != null and bool(game.dat.items.get(itemtype, {}).get("stackable", false)):
		for bpos in p.bag.keys():
			var it: Dictionary = p.bag[bpos] if p.bag[bpos] != null else {}
			if not it.is_empty() and int(it.itemtype) == itemtype:
				it.count = int(it.count) + count
				game.inventory_changed.emit(pid)
				return true
	for i in range(20):
		if p.bag.get(i) == null:
			p.bag[i] = {"sid": 0, "pid": int(p.row_id), "itemtype": itemtype, "count": count, "slot": -1, "bpos": i}
			game.inventory_changed.emit(pid)
			return true
	game.message_local(pid, "Your backpack is full.")
	return false

static func consume_item(game, pid: int, row: Dictionary) -> void:
	var p: Dictionary = game.players[pid]
	row.count = int(row.count) - 1
	if int(row.count) <= 0:
		if p.inv.get(int(row.slot)) == row:
			p.inv[int(row.slot)] = null
		for bpos in p.bag.keys():
			if p.bag[bpos] == row:
				p.bag[bpos] = null
	game.inventory_changed.emit(pid)

# Pays gold coins from the backpack (NPC trades, cf. npcsystem).
static func pay_gold(game, pid: int, amount: int) -> bool:
	var p: Dictionary = game.players[pid]
	var have := 0
	for bpos in p.bag.keys():
		var it: Dictionary = p.bag.get(bpos) if p.bag.get(bpos) != null else {}
		if not it.is_empty() and int(it.itemtype) == BlackTekActionScripts.GOLD_COIN:
			have += int(it.count)
	if have < amount:
		game.message_local(pid, "You do not have enough gold.")
		return false
	var left := amount
	for bpos in p.bag.keys():
		var it2: Dictionary = p.bag.get(bpos) if p.bag.get(bpos) != null else {}
		if not it2.is_empty() and int(it2.itemtype) == BlackTekActionScripts.GOLD_COIN and left > 0:
			var take: int = mini(left, int(it2.count))
			it2.count = int(it2.count) - take
			left -= take
			if int(it2.count) <= 0:
				p.bag[bpos] = null
	game.consume_refresh(pid)
	return true

static func buy_shop_item(game, pid: int, offer: Dictionary) -> void:
	if BlackTekPlayer.pay_gold(game, pid, int(offer.price)):
		if BlackTekPlayer.add_item(game, pid, int(offer.itemtype), 1):
			game.message_local(pid, "You bought 1x %s for %d gold." % [String(offer.name), int(offer.price)])

# ---- movement --------------------------------------------------------------------

# Exact step validation, shared by request_move and the self-push preview so
# the preview can never promise a step the server then refuses.
static func can_step(game, pid: int, dir: Vector2i) -> bool:
	return BlackTekPlayer.step_blocker(game, pid, dir) == ""

# Why a step fails: "" when it would land, otherwise a short reason naming
# the blocker (solid item label) or the occupant. Used for the red
# preview explanation and the failed quick-step message.
# NOTE: mirrors the real server (Game::internalMoveCreature -> Tile::canEnter):
# only the DESTINATION tile matters. Diagonal steps never check the two
# orthogonal neighbours, so slipping between a well and water (or any two
# blocking tiles) is allowed as long as the dest SQM itself is walkable.
static func step_blocker(game, pid: int, dir: Vector2i) -> String:
	if not game.players.has(pid):
		return "no session"
	var cur: Vector2i = game.players[pid]["tile"]
	var z: int = game.demo_z
	if dir == Vector2i.ZERO:
		return "no direction"
	var next: Vector2i = cur + dir
	if not game.is_walkable(next):
		return BlackTekPlayer.solid_label(game, next, z)
	if not BlackTekMonsters.monster_at(game, next, z).is_empty():
		return "creature in the way"
	return ""

# Human label of the first solid item on a tile ("bush", "wall", ...).
static func solid_label(game, tile: Vector2i, z: int) -> String:
	for id in game.tile_info(tile, z).get("items", []):
		if game.dat != null and bool(game.dat.items.get(int(id), {}).get("block_solid", false)):
			var n: String = game.item_label(int(id))
			return n if n != "" else "wall"
	return "blocked tile"

static func request_move(game, player_id: int, dir: Vector2i) -> Vector2i:
	if not game.players.has(player_id):
		return Vector2i(-1, -1)
	game.players[player_id].path = [] # manual step cancels click-walking
	var cur: Vector2i = game.players[player_id]["tile"]
	if not BlackTekPlayer.can_step(game, player_id, dir):
		return cur
	var next: Vector2i = cur + dir
	game.players[player_id]["tile"] = next
	game.players[player_id]["z"] = game.demo_z
	game.player_moved.emit(player_id, next)
	return next

# Spawns the loaded player on a walkable tile (town or open spot).
static func spawn_tile(game) -> Vector2i:
	if game.use_real_map:
		return game.find_spawn()
	var c := Vector2i(15, 11)
	if game.walls.has(c):
		c = Vector2i(15, 12)
	return c

# /t talkaction + demo R key: back to town temple.
static func teleport_town(game, pid: int) -> bool:
	if not game.players.has(pid):
		return false
	game.players[pid].path = []
	if game.use_real_map:
		game.players[pid].tile = game.find_spawn()
	else:
		game.players[pid].tile = Vector2i(15, 11)
	game.players[pid].z = game.demo_z
	game.player_moved.emit(pid, game.players[pid].tile)
	game.message_local(pid, "Teleported to town temple.")
	return true

# Step-onto-stairs teleport (stand-in for stair/use logic): if the player's
# tile holds a stair-like item, head for a walkable landing on the floor
# above first (same tile, then rings to 4), else the floor below.
# Returns new z or -1. Clears any click-path (a new floor voids old routes).
static func try_stair_teleport(game, player_id: int) -> int:
	if not game.players.has(player_id) or game.dat == null:
		return -1
	var cur: Vector2i = game.players[player_id]["tile"]
	var has_stair := false
	for id in game.tile_info(cur).get("items", []):
		if bool(game.dat.items.get(int(id), {}).get("is_stair", false)):
			has_stair = true
			break
	if not has_stair:
		return -1
	game.players[player_id].path = []
	for dz in [-1, 1]:
		var nz: int = game.demo_z + dz
		if nz < 0 or nz > 15:
			continue
		for r in range(0, 5):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if maxi(abs(dx), abs(dy)) != r:
						continue
					var c := cur + Vector2i(dx, dy)
					if game.is_walkable(c, nz):
						game.demo_z = nz
						game.players[player_id]["tile"] = c
						game.players[player_id]["z"] = nz
						game.player_moved.emit(player_id, c)
						return nz
	return -1

# Manual upstairs/downstairs travel (PgUp/PgDn stand-in for stair tiles).
static func request_floor(game, player_id: int, dz: int) -> bool:
	if not game.players.has(player_id):
		return false
	game.players[player_id].path = []
	var nz: int = clampi(game.demo_z + dz, 0, 15)
	if nz == game.demo_z:
		return false
	var cur: Vector2i = game.players[player_id]["tile"]
	for r in range(0, 13):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(abs(dx), abs(dy)) != r:
					continue
				var c := cur + Vector2i(dx, dy)
				if game.is_walkable(c, nz):
					game.demo_z = nz
					game.players[player_id]["tile"] = c
					game.players[player_id]["z"] = nz
					game.player_moved.emit(player_id, c)
					return true
	return false

# ---- conditions (shown next to the HP/MP/XP bars) -------------------------------

# Demo protection zone: the town temple area (spawn) — tiles within 3 SQM.
static func is_pz_tile(game, tile: Vector2i) -> bool:
	return game.temple_tile != Vector2i(-9999, -9999) and maxi(absi(tile.x - game.temple_tile.x), absi(tile.y - game.temple_tile.y)) <= 3

static func is_fed(game, pid: int) -> bool:
	return float(game.players[pid].get("food_until", 0.0)) > Time.get_ticks_msec() / 1000.0

static func is_poisoned(game, pid: int) -> bool:
	return float(game.players[pid].get("poison_until", 0.0)) > Time.get_ticks_msec() / 1000.0

# ---- player-initiated world interactions -----------------------------------------

# Topmost movable object on a tile (ground/borders, stairs and static
# decor are never pushable). Returns {itemtype, index} into the tile's list.
static func pushable_item_at(game, tile: Vector2i, z: int) -> Dictionary:
	var ids: PackedInt32Array = game.tile_info(tile, z).get("items", PackedInt32Array())
	if game.dat == null:
		return {}
	for i in range(ids.size() - 1, -1, -1):
		var d: Dictionary = game.dat.items.get(int(ids[i]), {})
		if d.is_empty():
			continue
		if bool(d.get("is_ground", false)) or bool(d.get("is_border", false)):
			continue
		if bool(d.get("is_stair", false)):
			continue
		if bool(d.get("moveable", false)):
			return {"itemtype": int(ids[i]), "index": i}
	return {}

# Preview for the client arrow: the shove works if the item is still there
# and the destination tile exists and holds no creature/player.
static func can_push_item(game, tile: Vector2i, dir: Vector2i, z: int) -> bool:
	if BlackTekPlayer.pushable_item_at(game, tile, z).is_empty():
		return false
	var d: int = maxi(absi(dir.x), absi(dir.y))
	if d != 1:
		return false
	var dest := tile + dir
	if game.tile_info(dest, z).is_empty():
		return false
	if not BlackTekMonsters.monster_at(game, dest, z).is_empty():
		return false
	for p in game.players.values():
		if int(p.z) == z and p.tile == dest:
			return false
	return true

# Shove the topmost movable item 1 SQM. Melee range, same floor, like
# creatures. Mutates the live OTBM tile lists (session-only: the map
# reloads pristine next run since caches are only written at import).
static func push_item(game, tile: Vector2i, dir: Vector2i, z: int, pid: int) -> bool:
	if not game.players.has(pid):
		return false
	var pp: Dictionary = game.players[pid]
	if z != int(pp.z):
		game.message_local(pid, "You are too far away to push that.")
		return false
	if maxi(absi(tile.x - int(pp.tile.x)), absi(tile.y - int(pp.tile.y))) > 1:
		game.message_local(pid, "You are too far away to push that.")
		return false
	var pick := BlackTekPlayer.pushable_item_at(game, tile, z)
	if pick.is_empty() or not BlackTekPlayer.can_push_item(game, tile, dir, z):
		game.message_local(pid, "You cannot push that there.")
		return false
	# NOTE: PackedInt32Array is copy-on-write, so mutating a .get() result
	# would silently discard the change — duplicate, edit, write back into
	# the live tile dicts instead.
	var moving := int(pick.itemtype)
	var src_entry: Dictionary = game.tile_info(tile, z)
	var src_ids: PackedInt32Array = (src_entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	src_ids.remove_at(clampi(int(pick.index), 0, src_ids.size() - 1))
	src_entry["items"] = src_ids
	var dst_entry: Dictionary = game.tile_info(tile + dir, z)
	var dst_ids: PackedInt32Array = (dst_entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	dst_ids.append(moving)
	dst_entry["items"] = dst_ids
	game.message_local(pid, "You push the %s %s." % [game.item_label(moving), BlackTekGameServer.dir_name(dir)])
	return true

# Topmost takeable object on a tile (pickupable decor, loot, dropped gear —
# never ground, stairs or doors). Returns {itemtype, index}.
static func takeable_item_at(game, tile: Vector2i, z: int) -> Dictionary:
	if game.dat == null:
		return {}
	var ids: PackedInt32Array = game.tile_info(tile, z).get("items", PackedInt32Array())
	for i in range(ids.size() - 1, -1, -1):
		var id := int(ids[i])
		if game.dat.door_pairs.has(id):
			continue
		var d: Dictionary = game.dat.items.get(id, {})
		if d.is_empty():
			continue
		if bool(d.get("is_ground", false)) or bool(d.get("is_border", false)):
			continue
		if bool(d.get("is_stair", false)):
			continue
		if bool(d.get("pickupable", false)):
			return {"itemtype": id, "index": i}
	return {}

# True when the backpack can take one more of this type (stack merge or a
# free slot). Used for the grab preview so it never promises a full bag.
static func can_pickup(game, pid: int, itemtype: int) -> bool:
	if not game.players.has(pid):
		return false
	var p: Dictionary = game.players[pid]
	if game.dat != null and bool(game.dat.items.get(itemtype, {}).get("stackable", false)):
		for bpos in p.bag.keys():
			var it: Dictionary = p.bag[bpos] if p.bag[bpos] != null else {}
			if not it.is_empty() and int(it.itemtype) == itemtype:
				return true
	for i in range(20):
		if p.bag.get(i) == null:
			return true
	return false

# Dragged a bag row onto a world tile: leave the item on the ground (one
# piece per drag; stacks stay mostly in the bag). Session-only like pushes.
static func drop_item(game, pid: int, bpos: int, tile: Vector2i, z: int) -> bool:
	if not game.players.has(pid):
		return false
	var p: Dictionary = game.players[pid]
	var row: Dictionary = p.bag.get(bpos) if p.bag.get(bpos) != null else {}
	if row.is_empty():
		return false # stale drag; stay silent
	if z != int(p.z) or maxi(absi(tile.x - int(p.tile.x)), absi(tile.y - int(p.tile.y))) > 1:
		game.message_local(pid, "You cannot reach that far.")
		return false
	if game.tile_info(tile, z).is_empty():
		game.message_local(pid, "You cannot drop that there.")
		return false
	if not BlackTekMonsters.monster_at(game, tile, z).is_empty():
		game.message_local(pid, "Something is in the way.")
		return false
	for opid in game.players.keys():
		if int(opid) == pid:
			continue # dropping at your own feet is fine
		var p2: Dictionary = game.players[opid]
		if int(p2.z) == z and p2.tile == tile:
			game.message_local(pid, "Something is in the way.")
			return false
	var itemtype := int(row.itemtype)
	if int(row.count) > 1:
		row.count = int(row.count) - 1
	else:
		p.bag[bpos] = null
	var entry: Dictionary = game.tile_info(tile, z)
	var ids: PackedInt32Array = (entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	ids.append(itemtype)
	entry["items"] = ids
	game.inventory_changed.emit(pid)
	game.message_local(pid, "You drop the %s." % game.item_label(itemtype))
	return true

# Dragged an equipped row onto a world tile: same as a bag drop.
static func drop_equipped(game, pid: int, slot: int, tile: Vector2i, z: int) -> bool:
	if not game.players.has(pid):
		return false
	var p: Dictionary = game.players[pid]
	var row: Dictionary = p.inv.get(slot) if p.inv.get(slot) != null else {}
	if row.is_empty():
		return false # stale drag; stay silent
	if z != int(p.z) or maxi(absi(tile.x - int(p.tile.x)), absi(tile.y - int(p.tile.y))) > 1:
		game.message_local(pid, "You cannot reach that far.")
		return false
	if game.tile_info(tile, z).is_empty():
		game.message_local(pid, "You cannot drop that there.")
		return false
	if not BlackTekMonsters.monster_at(game, tile, z).is_empty():
		game.message_local(pid, "Something is in the way.")
		return false
	for opid in game.players.keys():
		if int(opid) == pid:
			continue
		var p2: Dictionary = game.players[opid]
		if int(p2.z) == z and p2.tile == tile:
			game.message_local(pid, "Something is in the way.")
			return false
	var itemtype := int(row.itemtype)
	p.inv[slot] = null
	var entry: Dictionary = game.tile_info(tile, z)
	var ids: PackedInt32Array = (entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	ids.append(itemtype)
	entry["items"] = ids
	game.inventory_changed.emit(pid)
	game.message_local(pid, "You drop the %s." % game.item_label(itemtype))
	return true

# Dragged a floor item onto the open gear panel: take it into the backpack —
# straight into its equipment slot when it fits and the slot is free.
static func pickup_item(game, tile: Vector2i, z: int, pid: int) -> bool:
	if not game.players.has(pid):
		return false
	var pp: Dictionary = game.players[pid]
	if z != int(pp.z) or maxi(absi(tile.x - int(pp.tile.x)), absi(tile.y - int(pp.tile.y))) > 1:
		game.message_local(pid, "You cannot reach that far.")
		return false
	var pick := BlackTekPlayer.takeable_item_at(game, tile, z)
	if pick.is_empty():
		game.message_local(pid, "There is nothing to take.")
		return false
	var itemtype := int(pick.itemtype)
	if not BlackTekPlayer.can_pickup(game, pid, itemtype):
		game.message_local(pid, "Your backpack is full.")
		return false
	var entry: Dictionary = game.tile_info(tile, z)
	var ids: PackedInt32Array = (entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	if int(pick.index) >= ids.size() or int(ids[int(pick.index)]) != itemtype:
		return false # tile changed under us; be safe, not sorry
	ids.remove_at(int(pick.index))
	entry["items"] = ids
	# Gear fitting straight into its slot (containers home to Backpack 3),
	# anything else lands in the backpack as usual.
	var slot := int(BlackTekGameServer.EQUIP_SLOT.get(itemtype, -1))
	if slot < 0 and game.dat != null and game.dat.is_container(itemtype):
		slot = 3
	var voc := int(pp.vocation)
	if slot >= 0 and pp.inv.get(slot) == null and not (slot == 6 and (voc == 1 or voc == 2)):
		pp.inv[slot] = {"sid": 0, "pid": int(pp.row_id), "itemtype": itemtype, "count": 1, "slot": slot, "bpos": -1}
		game.inventory_changed.emit(pid)
		game.message_local(pid, "You equip the %s." % game.item_label(itemtype))
		return true
	BlackTekPlayer.add_item(game, pid, itemtype, 1)
	game.message_local(pid, "You pick up the %s." % game.item_label(itemtype))
	return true

# ---- doors: open/close usable leaves by swapping the leaf item id ---------

# Topmost usable door leaf on a tile, or {}: {itemtype, index, open}.
static func door_at(game, tile: Vector2i, z: int) -> Dictionary:
	if game.dat == null:
		return {}
	var ids: PackedInt32Array = game.tile_info(tile, z).get("items", PackedInt32Array())
	for i in range(ids.size() - 1, -1, -1):
		var leaf: Dictionary = game.dat.door_pairs.get(int(ids[i]), {})
		if not leaf.is_empty():
			return {"itemtype": int(ids[i]), "index": i, "open": bool(leaf.get("open", false)), "to": int(leaf.get("to", 0))}
	return {}

# Left-click a door within reach: closed leaves swing open, open leaves swing
# shut unless someone stands on the tile. Swaps the leaf id in the live tile
# list (session-only, like pushed items), so walkability follows the leaf.
static func use_door(game, tile: Vector2i, z: int, pid: int) -> bool:
	if not game.players.has(pid):
		return false
	var pp: Dictionary = game.players[pid]
	if z != int(pp.z) or maxi(absi(tile.x - int(pp.tile.x)), absi(tile.y - int(pp.tile.y))) > 1:
		return false # out of reach: silent, the click just walks closer
	var door := BlackTekPlayer.door_at(game, tile, z)
	if door.is_empty():
		return false
	if bool(door.open):
		for p2 in game.players.values():
			if int(p2.z) == z and p2.tile == tile:
				game.message_local(pid, "You cannot close this door.")
				return false
		if not BlackTekMonsters.monster_at(game, tile, z).is_empty():
			game.message_local(pid, "You cannot close this door.")
			return false
	var entry: Dictionary = game.tile_info(tile, z)
	var ids: PackedInt32Array = (entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	if int(door.index) >= ids.size() or int(ids[int(door.index)]) != int(door.itemtype):
		return false # tile changed under us; be safe, not sorry
	ids[int(door.index)] = int(door.to)
	entry["items"] = ids
	game.message_local(pid, "You close the door." if bool(door.open) else "You open the door.")
	return true
