# Mock authoritative server — in-memory only, no MariaDB, no TCP.
# Uses REAL assets.dat flags + forgotten.otbm tiles when available (fallback:
# hardcoded walls). Mirrors Game::internalMoveCreature / canWalkTo (dat
# blockSolid) plus the demo game layer: DB session, vocations, regen, combat,
# monsters, NPC shop — all through mock_scripts.gd "action scripts".
class_name BlackTekGameServer
extends RefCounted

signal player_moved(player_id: int, new_tile: Vector2i)
signal chat_received(sender: String, text: String)
signal msg_local(player_id: int, text: String)      # server->client game message (green)
signal stats_changed(player_id: int)
signal inventory_changed(player_id: int)
signal target_changed(player_id: int, target: Dictionary)
signal monsters_changed()
signal damage_float(pos: Vector2i, z: int, amount: int, from_player: bool)
signal level_up(player_id: int, new_level: int)
signal shop_requested(player_id: int)
signal login_error(text: String)
signal world_entered(player_id: int)

const DatLoader := preload("res://scripts/game/loaders/dat_loader.gd")
const OtbmLoader := preload("res://scripts/game/loaders/otbm_loader.gd")
const SprLoader := preload("res://scripts/game/loaders/spr_loader.gd")
const Database := preload("res://scripts/game/database.gd")
const ActionScripts := preload("res://scripts/game/action_scripts.gd")

const MAP_W := 30
const MAP_H := 22

# Vocation table (scaled from data/vocations/*.toml):
# per-level {cap, hp, mana} + regeneration {hp, mana} in ticks of seconds.
const VOCATIONS := {
	0: {"id": 0, "name": "None", "short": "N", "per_level": {"cap": 10, "hp": 5, "mana": 5}, "regen": {"hp": [1, 6], "mana": [1, 6]}, "attack_speed": 2.0, "skill_rate": 3.0},
	1: {"id": 1, "name": "Sorcerer", "short": "S", "per_level": {"cap": 10, "hp": 5, "mana": 30}, "regen": {"hp": [5, 6], "mana": [5, 3]}, "attack_speed": 2.0, "skill_rate": 3.0},
	2: {"id": 2, "name": "Druid", "short": "D", "per_level": {"cap": 10, "hp": 5, "mana": 30}, "regen": {"hp": [5, 6], "mana": [5, 3]}, "attack_speed": 2.0, "skill_rate": 3.0},
	3: {"id": 3, "name": "Paladin", "short": "P", "per_level": {"cap": 20, "hp": 10, "mana": 15}, "regen": {"hp": [5, 4], "mana": [5, 3]}, "attack_speed": 2.0, "skill_rate": 3.0},
	4: {"id": 4, "name": "Knight", "short": "K", "per_level": {"cap": 25, "hp": 15, "mana": 5}, "regen": {"hp": [5, 3], "mana": [5, 6]}, "attack_speed": 2.0, "skill_rate": 3.0},
}
# config/rates.toml: experience 5, skill 3, magic 3, loot 2. Demo also applies
# the first stage from config/stages.toml (levels 1-8, multiplier 7) for pace.
const RATE_EXP := 5.0
const RATE_STAGE := 7.0
const RATE_SKILL := 3.0
const RATE_MAGIC := 3.0
const RATE_LOOT := 2.0

# Demo monster (data/monsters rat): hp 25, exp 8, melee 1-4.
const MONSTER_DEF := {"name": "Rat", "hp": 25, "exp": 8, "dmg_min": 1, "dmg_max": 4, "speed_s": 0.5, "attack_s": 2.0, "range": 6}
const MAX_MONSTERS := 3
const RESPAWN_S := 6.0

# Weapons/armor (client ids per items.toml): sword 2376, wand of vortex 2190.
const WEAPON_ATK := {2376: 14, 2190: 10}
const ITEM_ARMOR := {2461: 1, 2463: 10, 2467: 4, 2511: 9, 2643: 1}

const WorldScript := preload("res://scripts/game/world.gd")

var world: BlackTekWorld
var db: BlackTekDatabase
var scripts: BlackTekActionScripts
var account: Dictionary = {}

# Map/sprite layer delegates (implementation in game/world.gd).
var walls: Dictionary:
	get:
		return world.walls
var dat: BlackTekDat:
	get:
		return world.dat
var otbm: BlackTekOtbm:
	get:
		return world.otbm
var spr: BlackTekSpr:
	get:
		return world.spr
var use_real_map: bool:
	get:
		return world.use_real_map
var use_real_sprites: bool:
	get:
		return world.use_real_sprites
var demo_z: int:
	get:
		return world.demo_z
	set(value):
		world.demo_z = value
var stats_text: String:
	get:
		return world.stats_text

var players: Dictionary = {} # id -> game state dict (see enter_world)
var monsters: Dictionary = {} # id -> {id,name,tile,z,hp,hpmax,...,target_pid}
var _next_monster_id := 1
var _respawn_t := 0.0


func _init(db_path := "") -> void:
	world = WorldScript.new()
	db = Database.new()
	if db_path != "":
		db.db_path = db_path
	db.load_db()
	scripts = ActionScripts.new()
	# Border walls + a few obstacles (replaces OTBM load for demo).
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

# ---- session (cf. protocollogin / protocolgame) ------------------------------

func login_account(account_name: String, password: String) -> bool:
	if db.db.accounts.is_empty():
		login_error.emit("MockDB has no accounts.")
		return false
	if not account_name.is_empty():
		account = db.auth(account_name, password)
		if account.is_empty():
			login_error.emit("Wrong account name or password.")
			return false
	else:
		account = db.db.accounts[0]
	return true

func character_list() -> Array:
	return db.characters(int(account.id))

func create_character(player_name: String, vocation: int) -> Dictionary:
	if player_name.strip_edges().length() < 3:
		login_error.emit("Name too short (min 3 chars).")
		return {}
	if not db.find_player_by_name(player_name).is_empty():
		login_error.emit("Name already taken.")
		return {}
	var row := db.create_character(int(account.id), player_name.strip_edges(), vocation)
	if row.is_empty():
		login_error.emit("Could not create character.")
	return row

# Loads a DB row into the live player (pid fixed to 1 for the demo client).
func enter_world(player_row: Dictionary) -> Vector2i:
	var pid := 1
	var lvl := int(player_row.get("level", 1))
	var voc := int(player_row.get("vocation", 0))
	var hpmax := _max_hp(voc, lvl)
	var manamax := _max_mana(voc, lvl)
	players[pid] = {
		"name": String(player_row.name), "vocation": voc, "level": lvl,
		"exp": int(player_row.get("experience", 0)),
		"hp": clampi(int(player_row.get("health", hpmax)), 1, hpmax), "hpmax": hpmax,
		"mana": clampi(int(player_row.get("mana", manamax)), 0, manamax), "manamax": manamax,
		"cap": 400 + VOCATIONS[voc].per_level.cap * (lvl - 1),
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
	for it in db.items_of(int(player_row.id)):
		var slot := int(it.slot)
		if slot == -1:
			players[pid].bag[int(it.bpos)] = it
		else:
			players[pid].inv[slot] = it
	# Spawn: saved position if walkable, else town/first open tile.
	var saved := Vector2i(int(player_row.get("posx", 0)), int(player_row.get("posy", 0)))
	if (not use_real_map or is_walkable(saved)) and saved != Vector2i.ZERO:
		if not use_real_map and walls.has(saved):
			saved = Vector2i(15, 11)
		players[pid].tile = saved
		players[pid].z = int(player_row.get("posz", 7))
		demo_z = players[pid].z
	else:
		players[pid].tile = _spawn_tile()
		players[pid].z = demo_z
	# Spawn tile = town temple in the demo -> protection zone around it.
	if account.is_empty() or not use_real_map:
		_temple_tile = players[pid].tile
	elif _temple_tile == Vector2i(-9999, -9999):
		_temple_tile = players[pid].tile
	monsters.clear()
	monsters_changed.emit()
	_try_spawn_monster(pid)
	stats_changed.emit(pid)
	inventory_changed.emit(pid)
	msg_local.emit(pid, "Welcome, %s! MockDB session active (no MariaDB)." % String(player_row.name))
	world_entered.emit(pid)
	return players[pid].tile

func save_all() -> void:
	var pid := 1
	if not players.has(pid) or account.is_empty():
		return
	var p: Dictionary = players[pid]
	for row in db.db.players:
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
	db.db.player_items = db.db.player_items.filter(func(it): return int(it.pid) != int(p.row_id))
	for slot in p.inv.keys():
		var it: Dictionary = p.inv[slot] if p.inv[slot] != null else {}
		if not it.is_empty():
			db.add_item(int(p.row_id), int(it.itemtype), int(it.count), int(slot), -1)
	for bpos in p.bag.keys():
		var it2: Dictionary = p.bag[bpos] if p.bag[bpos] != null else {}
		if not it2.is_empty():
			db.add_item(int(p.row_id), int(it2.itemtype), int(it2.count), -1, int(bpos))
	db.save_db()

# ---- vocation math -----------------------------------------------------------

func _max_hp(voc: int, level: int) -> int:
	return 150 + int(VOCATIONS[voc].per_level.hp) * (level - 1)

func _max_mana(voc: int, level: int) -> int:
	return 35 + int(VOCATIONS[voc].per_level.mana) * (level - 1)

static func exp_for_level(level: int) -> int:
	var l := float(level)
	return int(50.0 / 3.0 * (pow(l, 3) - 6.0 * l * l + 17.0 * l - 12.0))

func vocation_roll(_pid: int, min_v: int, max_v: int) -> int:
	return randi_range(min_v, max_v)

func is_gm(_pid: int) -> bool:
	return false # demo account is a normal player; GM talkactions show the gate

# ---- generic script-facing helpers (used by mock_scripts.gd) -----------------

func message_local(pid: int, text: String) -> void:
	msg_local.emit(pid, text)

func player_pos3(pid: int) -> Vector3i:
	var p: Dictionary = players.get(pid, {})
	var t: Vector2i = p.get("tile", Vector2i.ZERO)
	return Vector3i(t.x, t.y, int(p.get("z", demo_z)))

func check_cooldown(pid: int, key: String, secs: float) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	var cds: Dictionary = players[pid].cooldowns
	if float(cds.get(key, 0.0)) > now:
		return false
	cds[key] = now + secs
	return true

func heal_player(pid: int, amount: int, source: String) -> void:
	var p: Dictionary = players[pid]
	var before := int(p.hp)
	p.hp = mini(int(p.hp) + amount, int(p.hpmax))
	if p.hp > before:
		damage_float.emit(p.tile, int(p.z), int(p.hp) - before, false)
		message_local(pid, "You healed yourself for %d hitpoints (%s)." % [int(p.hp) - before, source])
	else:
		message_local(pid, "Your health is already full.")
	stats_changed.emit(pid)

func add_mana(pid: int, amount: int, source: String) -> void:
	var p: Dictionary = players[pid]
	var before := int(p.mana)
	p.mana = mini(int(p.mana) + amount, int(p.manamax))
	message_local(pid, "You gained %d mana (%s)." % [int(p.mana) - before, source])
	stats_changed.emit(pid)

func spend_mana(pid: int, amount: int) -> void:
	var p: Dictionary = players[pid]
	p.mana = maxi(0, int(p.mana) - amount)
	# Magic level advance (demo-scaled; real: mana spent vs vocation magic rate).
	p.mlvl_tries = int(p.get("mlvl_tries", 0)) + amount
	var need := int((int(p.maglevel) + 1) * 80.0 / RATE_MAGIC)
	if p.mlvl_tries >= need:
		p.mlvl_tries -= need
		p.maglevel = int(p.maglevel) + 1
		message_local(pid, "You advanced to magic level %d." % int(p.maglevel))
	stats_changed.emit(pid)

func set_food(pid: int, seconds: int) -> void:
	players[pid].food_until = Time.get_ticks_msec() / 1000 + seconds
	message_local(pid, "Well fed: faster regeneration for %ds." % seconds)

func get_storage(pid: int, key: int) -> int:
	return db.get_storage(int(players[pid].row_id), key)

func set_storage(pid: int, key: int, value: int) -> void:
	db.set_storage(int(players[pid].row_id), key, value)

func add_item(pid: int, itemtype: int, count := 1) -> bool:
	var p: Dictionary = players[pid]
	if dat != null and bool(dat.items.get(itemtype, {}).get("stackable", false)):
		for bpos in p.bag.keys():
			var it: Dictionary = p.bag[bpos] if p.bag[bpos] != null else {}
			if not it.is_empty() and int(it.itemtype) == itemtype:
				it.count = int(it.count) + count
				inventory_changed.emit(pid)
				return true
	for i in range(20):
		if p.bag.get(i) == null:
			p.bag[i] = {"sid": 0, "pid": int(p.row_id), "itemtype": itemtype, "count": count, "slot": -1, "bpos": i}
			inventory_changed.emit(pid)
			return true
	message_local(pid, "Your backpack is full.")
	return false

func consume_item(pid: int, row: Dictionary) -> void:
	var p: Dictionary = players[pid]
	row.count = int(row.count) - 1
	if int(row.count) <= 0:
		if p.inv.get(int(row.slot)) == row:
			p.inv[int(row.slot)] = null
		for bpos in p.bag.keys():
			if p.bag[bpos] == row:
				p.bag[bpos] = null
	inventory_changed.emit(pid)

# Pays gold coins from the backpack (NPC trades, cf. npcsystem).
func pay_gold(pid: int, amount: int) -> bool:
	var p: Dictionary = players[pid]
	var have := 0
	for bpos in p.bag.keys():
		var it: Dictionary = p.bag.get(bpos) if p.bag.get(bpos) != null else {}
		if not it.is_empty() and int(it.itemtype) == BlackTekActionScripts.GOLD_COIN:
			have += int(it.count)
	if have < amount:
		message_local(pid, "You do not have enough gold.")
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
	consume_refresh(pid)
	return true

func consume_refresh(pid: int) -> void:
	inventory_changed.emit(pid)

func buy_shop_item(pid: int, offer: Dictionary) -> void:
	if pay_gold(pid, int(offer.price)):
		if add_item(pid, int(offer.itemtype), 1):
			message_local(pid, "You bought 1x %s for %d gold." % [String(offer.name), int(offer.price)])

# ---- combat ------------------------------------------------------------------

func equipped_weapon(pid: int) -> int:
	var w: Dictionary = players[pid].inv.get(5) if players[pid].inv.get(5) != null else {} # CONST_SLOT_RIGHT = 5
	return int(w.get("itemtype", 0)) if not w.is_empty() else 0

func total_armor(pid: int) -> int:
	var p: Dictionary = players[pid]
	var armor := 0
	for slot in [1, 4, 6, 7, 8]:
		var it: Dictionary = p.inv.get(slot) if p.inv.get(slot) != null else {}
		if not it.is_empty():
			armor += int(ITEM_ARMOR.get(int(it.itemtype), 0))
	return armor

func nearest_monster(pid: int, max_tiles := 1) -> Dictionary:
	var p: Dictionary = players[pid]
	var best := {}
	var best_d := max_tiles + 1
	for m in monsters.values():
		if int(m.z) != int(p.z):
			continue
		var d: int = maxi(absi(int(m.tile.x) - int(p.tile.x)), absi(int(m.tile.y) - int(p.tile.y)))
		if d < best_d:
			best_d = d
			best = m
	return best

# Space / right click: mark the nearest (or next) creature as target.
func target_next(pid: int) -> void:
	var p: Dictionary = players[pid]
	var candidates: Array = []
	for m in monsters.values():
		if int(m.z) != int(p.z):
			continue
		var d: int = maxi(absi(int(m.tile.x) - int(p.tile.x)), absi(int(m.tile.y) - int(p.tile.y)))
		if d <= int(MONSTER_DEF.range):
			candidates.append([d, int(m.id), m])
	candidates.sort()
	if candidates.is_empty():
		set_target(pid, {})
		message_local(pid, "No monster nearby to target.")
		return
	for c in candidates: # cycle: first candidate that is not the current target
		if int(c[1]) != int(p.target):
			set_target(pid, c[2])
			message_local(pid, "Target: %s." % String(c[2].name))
			return
	set_target(pid, candidates[0][2])
	message_local(pid, "Target: %s." % String(candidates[0][2].name))

# Attack the current target when it is adjacent (hotbar slot / auto-attack).
func attack_current_target(pid: int) -> void:
	var p: Dictionary = players[pid]
	p.path = []
	var m: Dictionary = monsters.get(int(p.target), {})
	if m.is_empty():
		message_local(pid, "You have no target. Right-click or press Space next to a creature.")
		return
	var d: int = maxi(absi(int(m.tile.x) - int(p.tile.x)), absi(int(m.tile.y) - int(p.tile.y)))
	if d > 1:
		message_local(pid, "%s is too far away. Step closer." % String(m.name))
		return
	_melee_swing(pid, m)

# One melee hit against m (damage roll, skill training, cooldown).
func _melee_swing(pid: int, m: Dictionary) -> void:
	var p: Dictionary = players[pid]
	var now := Time.get_ticks_msec() / 1000.0
	p.attack_cd = now + float(VOCATIONS[int(p.vocation)].attack_speed)
	set_target(pid, m)
	var weapon := equipped_weapon(pid)
	var dmg := 0
	if weapon == 2190: # wand of vortex: magic damage scaled by magic level
		dmg = randi_range(int(p.maglevel) + 2, 8 + int(p.maglevel) * 4)
	else:
		var skill := int(p.skills.get("sword", 10))
		var atk := int(WEAPON_ATK.get(weapon, 3))
		dmg = randi_range(maxi(1, skill / 2), skill + atk / 2 + int(p.level) / 5)
		_advance_skill(pid, "sword")
	damage_monster(int(m.id), dmg, "melee", pid)


func _advance_skill(pid: int, skill: String) -> void:
	var p: Dictionary = players[pid]
	var tries: Dictionary = p.skill_tries
	tries[skill] = int(tries.get(skill, 0)) + 10
	# Demo-scaled advance (real: skill_tries vs (skill+1)^3 / vocation rate).
	var need := int((int(p.skills[skill]) + 1) * 12.0 / RATE_SKILL)
	if int(tries[skill]) >= need:
		tries[skill] = 0
		p.skills[skill] = int(p.skills[skill]) + 1
		message_local(pid, "You advanced to %s skill %d." % [skill, int(p.skills[skill])])
	stats_changed.emit(pid)

func set_target(pid: int, m: Dictionary) -> void:
	var tid := int(m.get("id", 0)) if not m.is_empty() else 0
	if int(players[pid].target) != tid:
		players[pid].target = tid
	target_changed.emit(pid, m)

func damage_monster(mid: int, dmg: int, kind: String, from_pid: int) -> void:
	var m: Dictionary = monsters.get(mid, {})
	if m.is_empty():
		return
	m.hp = maxi(0, int(m.hp) - dmg)
	m.target_pid = from_pid
	damage_float.emit(m.tile, int(m.z), dmg, true)
	if int(m.hp) <= 0:
		_kill_monster(mid, from_pid)
	else:
		stats_changed.emit(from_pid) # refresh target frame hp
		target_changed.emit(from_pid, m)

func _kill_monster(mid: int, pid: int) -> void:
	var m: Dictionary = monsters.get(mid, {})
	if m.is_empty():
		return
	monsters.erase(mid)
	target_changed.emit(pid, {})
	var exp_gain := int(float(MONSTER_DEF.exp) * RATE_EXP * RATE_STAGE)
	var p: Dictionary = players[pid]
	p.exp = int(p.exp) + exp_gain
	message_local(pid, "You defeated the %s and gained %d experience." % [String(m.name), exp_gain])
	# Loot (rate loot 2): gold coins stack + occasional meat.
	var gold := randi_range(1, 8) * int(RATE_LOOT)
	if add_item(pid, BlackTekActionScripts.GOLD_COIN, gold):
		message_local(pid, "Loot: %d gold coins." % gold)
	if randf() < 0.2 * RATE_LOOT:
		if add_item(pid, BlackTekActionScripts.MEAT, 1):
			message_local(pid, "Loot: meat.")
	_gain_exp(pid)
	monsters_changed.emit()
	stats_changed.emit(pid)

func _gain_exp(pid: int) -> void:
	var p: Dictionary = players[pid]
	while int(p.exp) >= exp_for_level(int(p.level) + 1):
		p.level = int(p.level) + 1
		var voc: int = int(p.vocation)
		p.hpmax = _max_hp(voc, int(p.level))
		p.manamax = _max_mana(voc, int(p.level))
		p.hp = p.hpmax
		p.mana = p.manamax
		p.cap = 400 + int(VOCATIONS[voc].per_level.cap) * (int(p.level) - 1)
		level_up.emit(pid, int(p.level))
		message_local(pid, "You advanced from level %d to %d!" % [int(p.level) - 1, int(p.level)])

# ---- monsters AI (tick) ------------------------------------------------------

func _try_spawn_monster(pid: int) -> void:
	if monsters.size() >= MAX_MONSTERS:
		return
	var p: Dictionary = players[pid]
	for _attempt in range(24):
		var off := Vector2i(randi_range(-5, 5), randi_range(-5, 5))
		if off == Vector2i.ZERO:
			continue
		var c: Vector2i = p.tile + off
		if not _tile_free_for_monster(c, int(p.z)):
			continue
		# Don't spawn on the player or next to them.
		if maxi(absi(off.x), absi(off.y)) < 3:
			continue
		var mid := _next_monster_id
		_next_monster_id += 1
		monsters[mid] = {
			"id": mid, "name": String(MONSTER_DEF.name), "tile": c, "z": int(p.z),
			"hp": int(MONSTER_DEF.hp), "hpmax": int(MONSTER_DEF.hp),
			"move_cd": 0.0, "attack_cd": 0.0, "target_pid": 0,
		}
		monsters_changed.emit()
		return

func tick(delta: float) -> void:
	if players.is_empty():
		return
	var pid := 1
	var p: Dictionary = players[pid]
	var now := Time.get_ticks_msec() / 1000.0
	var fed: bool = float(p.food_until) > now
	_tick_day_cycle(delta)
	_path_step(pid, delta)
	# Auto-attack: hit the marked target while it stands adjacent.
	if int(p.target) != 0 and float(p.get("attack_cd", 0.0)) <= now:
		var tm: Dictionary = monsters.get(int(p.target), {})
		if not tm.is_empty() and int(tm.z) == int(p.z):
			var td: int = maxi(absi(int(tm.tile.x) - int(p.tile.x)), absi(int(tm.tile.y) - int(p.tile.y)))
			if td <= 1:
				_melee_swing(pid, tm)
	# Poison condition: 2 damage every 2s while active.
	if float(p.get("poison_until", 0.0)) > now:
		var pt := "_poison_t"
		var ptv := float(p.get(pt, 0.0)) + delta
		if ptv >= 2.0:
			ptv = 0.0
			p.hp = maxi(0, int(p.hp) - 2)
			damage_float.emit(p.tile, int(p.z), 2, false)
			message_local(pid, "You lose 2 hitpoints (poison).")
			if int(p.hp) <= 0:
				_player_death(pid)
			else:
				stats_changed.emit(pid)
		p[pt] = ptv
	# Regeneration per vocation intervals (food halves the interval, demo rule).
	var regen: Dictionary = VOCATIONS[int(p.vocation)].regen
	_regen(p, "hp", float(regen.hp[1]) / (2.0 if fed else 1.0), int(regen.hp[0]), delta, now)
	_regen(p, "mana", float(regen.mana[1]) / (2.0 if fed else 1.0), int(regen.mana[0]), delta, now)
	# Monster AI.
	for mid in monsters.keys().duplicate():
		var m: Dictionary = monsters.get(mid)
		if m == null:
			continue
		var mt: Vector2i = m.tile
		var dist: int = maxi(absi(mt.x - int(p.tile.x)), absi(mt.y - int(p.tile.y)))
		if int(m.target_pid) == 0 and dist <= int(MONSTER_DEF.range):
			m.target_pid = pid
		if int(m.target_pid) != 0:
			if dist > int(MONSTER_DEF.range) * 2:
				m.target_pid = 0
				continue
		if dist <= 1:
			if float(m.attack_cd) <= now:
				m.attack_cd = now + float(MONSTER_DEF.attack_s)
				_monster_attack(m, pid)
			elif float(m.move_cd) <= now:
				m.move_cd = now + float(MONSTER_DEF.speed_s)
				var step := Vector2i(signi(int(p.tile.x) - mt.x), signi(int(p.tile.y) - mt.y))
				var next := mt
				if absi(int(p.tile.x) - mt.x) >= absi(int(p.tile.y) - mt.y):
					next = mt + Vector2i(step.x, 0)
					if not is_walkable(next, int(m.z)):
						next = mt + Vector2i(0, step.y)
				else:
					next = mt + Vector2i(0, step.y)
					if not is_walkable(next, int(m.z)):
						next = mt + Vector2i(step.x, 0)
				if next != mt and _tile_free_for_monster(next, int(m.z), mid):
					m.tile = next
	# Respawn pacing.
	_respawn_t -= delta
	if _respawn_t <= 0.0:
		_respawn_t = RESPAWN_S
		_try_spawn_monster(pid)

func _regen(p: Dictionary, which: String, interval_s: float, amount: int, delta: float, _now: float) -> void:
	if interval_s <= 0.0:
		return
	var key := "_regen_t_" + which
	var t := float(p.get(key, 0.0)) + delta
	if t >= interval_s:
		t = 0.0
		if which == "hp":
			if int(p.hp) < int(p.hpmax):
				p.hp = mini(int(p.hp) + amount, int(p.hpmax))
				stats_changed.emit(1)
		else:
			if int(p.mana) < int(p.manamax):
				p.mana = mini(int(p.mana) + amount, int(p.manamax))
				stats_changed.emit(1)
	p[key] = t

func _monster_attack(m: Dictionary, pid: int) -> void:
	var p: Dictionary = players[pid]
	var now := Time.get_ticks_msec() / 1000.0
	var raw := randi_range(int(MONSTER_DEF.dmg_min), int(MONSTER_DEF.dmg_max))
	var reduce: int = randi_range(0, total_armor(pid) / 2 + 1)
	var dmg := maxi(0, raw - reduce)
	damage_float.emit(p.tile, int(p.z), dmg, false)
	if dmg > 0:
		p.hp = maxi(0, int(p.hp) - dmg)
		message_local(pid, "You lose %d hitpoints (attacked by %s)." % [dmg, String(m.name)])
		if randf() < 0.2 and float(p.get("poison_until", 0.0)) <= now:
			p.poison_until = now + 10.0
			message_local(pid, "You are poisoned.")
		if int(p.hp) <= 0:
			_player_death(pid)
	else:
		message_local(pid, "A %s attacked you but your armor blocked it." % String(m.name))
	stats_changed.emit(pid)

func _player_death(pid: int) -> void:
	var p: Dictionary = players[pid]
	message_local(pid, "You are dead. Respawn at town with full health (demo: no penalty).")
	p.path = []
	p.hp = int(p.hpmax)
	p.mana = int(p.manamax)
	p.poison_until = 0.0
	p.target = 0
	target_changed.emit(pid, {})
	for m in monsters.values():
		m.target_pid = 0
	if use_real_map:
		p.tile = find_spawn()
		p.z = demo_z
	else:
		p.tile = Vector2i(15, 11)
	player_moved.emit(pid, p.tile)

# ---- map layer delegates (game/world.gd) --------------------------------------
func try_stair_teleport(player_id: int) -> int:
	if not players.has(player_id) or dat == null:
		return -1
	var cur: Vector2i = players[player_id]["tile"]
	var has_stair := false
	for id in tile_info(cur).get("items", []):
		if bool(dat.items.get(int(id), {}).get("is_stair", false)):
			has_stair = true
			break
	if not has_stair:
		return -1
	for dz in [-1, 1]:
		var nz: int = demo_z + dz
		if nz < 0 or nz > 15:
			continue
		for r in range(0, 5):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if maxi(abs(dx), abs(dy)) != r:
						continue
					var c := cur + Vector2i(dx, dy)
					if is_walkable(c, nz):
						demo_z = nz
						players[player_id]["tile"] = c
						players[player_id]["z"] = nz
						player_moved.emit(player_id, c)
						return nz
	return -1

# Manual upstairs/downstairs travel (PgUp/PgDn stand-in for stair tiles).
func request_floor(player_id: int, dz: int) -> bool:
	if not players.has(player_id):
		return false
	players[player_id].path = []
	var nz: int = clampi(demo_z + dz, 0, 15)
	if nz == demo_z:
		return false
	var cur: Vector2i = players[player_id]["tile"]
	for r in range(0, 13):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(abs(dx), abs(dy)) != r:
					continue
				var c := cur + Vector2i(dx, dy)
				if is_walkable(c, nz):
					demo_z = nz
					players[player_id]["tile"] = c
					players[player_id]["z"] = nz
					player_moved.emit(player_id, c)
					return true
	return false

# ---- tile occupancy (creatures never share an SQM) ---------------------------

func monster_at(tile: Vector2i, z: int, ignore_id := 0) -> Dictionary:
	for m in monsters.values():
		if int(m.id) != ignore_id and int(m.z) == z and m.tile == tile:
			return m
	return {}

func _tile_free_for_monster(tile: Vector2i, z: int, ignore_id := 0) -> bool:
	if not is_walkable(tile, z):
		return false
	if not monster_at(tile, z, ignore_id).is_empty():
		return false
	for p in players.values():
		if int(p.z) == z and p.tile == tile:
			return false
	return true

# Mouse push: drag a creature onto an adjacent free SQM (per-monster cooldown).
const PUSH_CD := 2.0

func can_push_monster(mid: int, dir: Vector2i) -> bool:
	var m: Dictionary = monsters.get(mid, {})
	if m.is_empty():
		return false
	var d: int = maxi(absi(dir.x), absi(dir.y))
	if d != 1:
		return false
	return _tile_free_for_monster(m.tile + dir, int(m.z), mid)

# Hold left click on a creature, drag, release: push 1 SQM in the drag direction.
# Melee-range interaction: the creature must stand next to the pusher (same
# floor, Chebyshev distance <= 1), otherwise the push is refused (anti-abuse:
# the client gates this too, but the server decides).
func push_monster(mid: int, dir: Vector2i, pid: int) -> bool:
	var m: Dictionary = monsters.get(mid, {})
	if m.is_empty():
		return false
	if not players.has(pid):
		return false
	var pp: Dictionary = players[pid]
	if int(m.z) != int(pp.z):
		message_local(pid, "You are too far away to push that creature.")
		return false
	var mtd: int = maxi(absi(int(m.tile.x) - int(pp.tile.x)), absi(int(m.tile.y) - int(pp.tile.y)))
	if mtd > 1:
		message_local(pid, "You are too far away to push that creature.")
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if float(m.get("push_cd", 0.0)) > now:
		message_local(pid, "You cannot push this creature again yet.")
		return false
	if not can_push_monster(mid, dir):
		message_local(pid, "You cannot push the creature there.")
		return false
	m.push_cd = now + PUSH_CD
	m.tile = m.tile + dir
	message_local(pid, "You push the %s %s." % [String(m.name), _dir_name(dir)])
	return true

static func _dir_name(dir: Vector2i) -> String:
	if dir == Vector2i(1, 0):
		return "east"
	if dir == Vector2i(-1, 0):
		return "west"
	if dir == Vector2i(0, 1):
		return "south"
	if dir == Vector2i(0, -1):
		return "north"
	return "aside"

# Seconds until this creature can be pushed again (per-monster PUSH_CD).
# The stats panel shows it as a loading bar so players see wait vs. ready.
func push_cooldown_remaining(mid: int) -> float:
	var m: Dictionary = monsters.get(mid, {})
	if m.is_empty():
		return 0.0
	return maxf(0.0, float(m.get("push_cd", 0.0)) - Time.get_ticks_msec() / 1000.0)

# ---- pushing map items (pots, boxes, ... 1 SQM shoves, session-only) ---------

# Topmost movable object on a tile (ground/borders, stairs and static
# decor are never pushable). Returns {itemtype, index} into the tile's list.
func pushable_item_at(tile: Vector2i, z: int) -> Dictionary:
	var ids: PackedInt32Array = tile_info(tile, z).get("items", PackedInt32Array())
	if dat == null:
		return {}
	for i in range(ids.size() - 1, -1, -1):
		var d: Dictionary = dat.items.get(int(ids[i]), {})
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
func can_push_item(tile: Vector2i, dir: Vector2i, z: int) -> bool:
	if pushable_item_at(tile, z).is_empty():
		return false
	var d: int = maxi(absi(dir.x), absi(dir.y))
	if d != 1:
		return false
	var dest := tile + dir
	if tile_info(dest, z).is_empty():
		return false
	if not monster_at(dest, z).is_empty():
		return false
	for p in players.values():
		if int(p.z) == z and p.tile == dest:
			return false
	return true

# Shove the topmost movable item 1 SQM. Melee range, same floor, like
# creatures. Mutates the live OTBM tile lists (session-only: the map
# reloads pristine next run since caches are only written at import).
func push_item(tile: Vector2i, dir: Vector2i, z: int, pid: int) -> bool:
	if not players.has(pid):
		return false
	var pp: Dictionary = players[pid]
	if z != int(pp.z):
		message_local(pid, "You are too far away to push that.")
		return false
	if maxi(absi(tile.x - int(pp.tile.x)), absi(tile.y - int(pp.tile.y))) > 1:
		message_local(pid, "You are too far away to push that.")
		return false
	var pick := pushable_item_at(tile, z)
	if pick.is_empty() or not can_push_item(tile, dir, z):
		message_local(pid, "You cannot push that there.")
		return false
	# NOTE: PackedInt32Array is copy-on-write, so mutating a .get() result
	# would silently discard the change — duplicate, edit, write back into
	# the live tile dicts instead.
	var moving := int(pick.itemtype)
	var src_entry: Dictionary = tile_info(tile, z)
	var src_ids: PackedInt32Array = (src_entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	src_ids.remove_at(clampi(int(pick.index), 0, src_ids.size() - 1))
	src_entry["items"] = src_ids
	var dst_entry: Dictionary = tile_info(tile + dir, z)
	var dst_ids: PackedInt32Array = (dst_entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	dst_ids.append(moving)
	dst_entry["items"] = dst_ids
	message_local(pid, "You push the %s %s." % [item_label(moving), _dir_name(dir)])
	return true

# ---- doors: open/close usable leaves by swapping the leaf item id ---------

# Topmost usable door leaf on a tile, or {}: {itemtype, index, open}.
func door_at(tile: Vector2i, z: int) -> Dictionary:
	if dat == null:
		return {}
	var ids: PackedInt32Array = tile_info(tile, z).get("items", PackedInt32Array())
	for i in range(ids.size() - 1, -1, -1):
		var leaf: Dictionary = dat.door_pairs.get(int(ids[i]), {})
		if not leaf.is_empty():
			return {"itemtype": int(ids[i]), "index": i, "open": bool(leaf.get("open", false)), "to": int(leaf.get("to", 0))}
	return {}

# Left-click a door within reach: closed leaves swing open, open leaves swing
# shut unless someone stands on the tile. Swaps the leaf id in the live tile
# list (session-only, like pushed items), so walkability follows the leaf.
func use_door(tile: Vector2i, z: int, pid: int) -> bool:
	if not players.has(pid):
		return false
	var pp: Dictionary = players[pid]
	if z != int(pp.z) or maxi(absi(tile.x - int(pp.tile.x)), absi(tile.y - int(pp.tile.y))) > 1:
		return false # out of reach: silent, the click just walks closer
	var door := door_at(tile, z)
	if door.is_empty():
		return false
	if bool(door.open):
		for p2 in players.values():
			if int(p2.z) == z and p2.tile == tile:
				message_local(pid, "You cannot close this door.")
				return false
		if not monster_at(tile, z).is_empty():
			message_local(pid, "You cannot close this door.")
			return false
	var entry: Dictionary = tile_info(tile, z)
	var ids: PackedInt32Array = (entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	if int(door.index) >= ids.size() or int(ids[int(door.index)]) != int(door.itemtype):
		return false # tile changed under us; be safe, not sorry
	ids[int(door.index)] = int(door.to)
	entry["items"] = ids
	message_local(pid, "You close the door." if bool(door.open) else "You open the door.")
	return true

# ---- conditions (shown next to the HP/MP/XP bars) -----------------------------

var _temple_tile := Vector2i(-9999, -9999)

# Demo protection zone: the town temple area (spawn) — tiles within 3 SQM.
func is_pz_tile(tile: Vector2i) -> bool:
	return _temple_tile != Vector2i(-9999, -9999) and maxi(absi(tile.x - _temple_tile.x), absi(tile.y - _temple_tile.y)) <= 3

func is_fed(pid: int) -> bool:
	return float(players[pid].get("food_until", 0.0)) > Time.get_ticks_msec() / 1000.0

func is_poisoned(pid: int) -> bool:
	return float(players[pid].get("poison_until", 0.0)) > Time.get_ticks_msec() / 1000.0

func request_move(player_id: int, dir: Vector2i) -> Vector2i:
	if not players.has(player_id):
		return Vector2i(-1, -1)
	players[player_id].path = [] # manual step cancels click-walking
	var cur: Vector2i = players[player_id]["tile"]
	# Diagonal sidestep: squeeze through unless BOTH orthogonal neighbours
	# are blocked (Tibia lets you slip past a single blocking tile).
	if dir.x != 0 and dir.y != 0:
		if not is_walkable(cur + Vector2i(dir.x, 0)) and not is_walkable(cur + Vector2i(0, dir.y)):
			return cur
	var next: Vector2i = cur + dir
	if is_walkable(next) and monster_at(next, demo_z).is_empty():
		players[player_id]["tile"] = next
		players[player_id]["z"] = demo_z
		player_moved.emit(player_id, next)
		return next
	return cur

# Spawns the loaded player on a walkable tile (town or open spot).
func _spawn_tile() -> Vector2i:
	if use_real_map:
		return find_spawn()
	var c := Vector2i(15, 11)
	if walls.has(c):
		c = Vector2i(15, 12)
	return c

# /t talkaction + demo R key: back to town temple.
func teleport_town(pid: int) -> bool:
	if not players.has(pid):
		return false
	players[pid].path = []
	if use_real_map:
		players[pid].tile = find_spawn()
	else:
		players[pid].tile = Vector2i(15, 11)
	players[pid].z = demo_z
	player_moved.emit(pid, players[pid].tile)
	message_local(pid, "Teleported to town temple.")
	return true

# ---- click pathfinding (BFS, 8-way, occupancy aware) --------------------------

# Step cadence in seconds (matches client key walking): diagonal sidesteps
# cover sqrt(2)x distance, so they pace slightly slower than cardinal steps.
const WALK_CD := 0.15
const DIAG_WALK_CD := 0.21

func request_path(pid: int, target: Vector2i) -> int:
	var p: Dictionary = players[pid]
	var start: Vector2i = p.tile
	var z: int = int(p.z)
	if target == start:
		p.path = []
		return 0
	if not is_walkable(target, z) or not monster_at(target, z).is_empty():
		return -1
	# Dijkstra over walkable, unoccupied tiles (cf. Game::pathFind): plain BFS
	# only minimizes the step COUNT, which prefers diagonal zigzags and reads
	# as "weird" routing. Orthogonal steps cost 1.0, diagonal steps sqrt(2),
	# so the result is the geometrically shortest walkable route (which also
	# matches the 0.15s / 0.21s walk pacing).
	var came_from: Dictionary = {start: start}
	var dist: Dictionary = {start: 0.0}
	var closed := {}
	var open: Array = [start]
	var found := false
	var guard := 0
	while not open.is_empty() and guard < 12000:
		guard += 1
		var bi := 0
		for i in range(1, open.size()):
			if float(dist[open[i]]) < float(dist[open[bi]]):
				bi = i
		var cur: Vector2i = open[bi]
		open.remove_at(bi)
		if closed.has(cur):
			continue
		closed[cur] = true
		if cur == target:
			found = true
			break
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
			var next: Vector2i = cur + dir
			if closed.has(next):
				continue
			if not is_walkable(next, z) or not monster_at(next, z).is_empty():
				continue
			# Squeeze through unless BOTH orthogonal neighbours are blocked.
			if dir.x != 0 and dir.y != 0:
				if not is_walkable(cur + Vector2i(dir.x, 0), z) and not is_walkable(cur + Vector2i(0, dir.y), z):
					continue
			var nd: float = float(dist[cur]) + (1.4142 if (dir.x != 0 and dir.y != 0) else 1.0)
			if nd < float(dist.get(next, 1e30)):
				dist[next] = nd
				came_from[next] = cur
				open.append(next)
	if not found:
		return -1
	# Reconstruct start-exclusive path.
	var path: Array = []
	var cur2: Vector2i = target
	while cur2 != start:
		path.push_front(cur2)
		cur2 = came_from[cur2]
	p.path = path
	return path.size()

func cancel_path(pid: int) -> void:
	players[pid].path = []

func get_path(pid: int) -> Array:
	return players[pid].get("path", [])

# Walks one step along the queued path (called from tick).
func _path_step(pid: int, delta: float) -> void:
	var p: Dictionary = players[pid]
	var path: Array = p.get("path", [])
	if path.is_empty():
		return
	p._walk_cd = float(p.get("_walk_cd", 0.0)) - delta
	if float(p._walk_cd) > 0.0:
		return
	var next: Vector2i = path[0]
	var cur: Vector2i = p.tile
	var dir: Vector2i = next - cur
	# Diagonal sidesteps cover sqrt(2)x distance, so they pace slower — same
	# cadence as key walking (0.15 cardinal / 0.21 diagonal).
	p._walk_cd = DIAG_WALK_CD if (dir.x != 0 and dir.y != 0) else WALK_CD
	var z: int = int(p.z)
	var ok: bool = maxi(absi(dir.x), absi(dir.y)) == 1 and is_walkable(next, z) and monster_at(next, z).is_empty()
	if ok and dir.x != 0 and dir.y != 0:
		ok = is_walkable(cur + Vector2i(dir.x, 0), z) or is_walkable(cur + Vector2i(0, dir.y), z)
	if not ok:
		p.path = [] # blocked mid-route (monster moved in): stop
		message_local(pid, "You are blocked.")
		return
	p.tile = next
	p.z = z
	path.pop_front()
	player_moved.emit(pid, next)

# ---- light sources (dat flag 22 radius) + ambient day/night --------------------

var day_ambient := 1.0 # rendered darkness level (smoothly faded)
var day_time := 50.0 # seconds into the day/night cycle (0 = noon)
const DAY_CYCLE := 960.0 # full day+night in seconds (4x slower than 240s)

func set_ambient(a: float) -> void:
	# Pin the cycle: /day jumps to noon, /night to midnight; ambient fades there.
	day_time = 0.0 if a >= 0.6 else DAY_CYCLE / 2.0
	message_local(1, "Ambient light: %d%%" % int(a * 100.0))

func _tick_day_cycle(delta: float) -> void:
	day_time = fmod(day_time + delta, DAY_CYCLE)
	var phase := day_time / DAY_CYCLE * TAU
	var target := 0.25 + 0.75 * (0.5 + 0.5 * cos(phase)) # noon 1.0, midnight 0.25
	day_ambient = lerpf(day_ambient, target, minf(1.0, delta * 0.4))

const ITEM_STATS := {
	2376: {"atk": 14}, 2190: {"atk": 10, "magic": true},
	2461: {"armor": 1}, 2463: {"armor": 10}, 2467: {"armor": 4},
	2511: {"armor": 9, "shield": true}, 2643: {"armor": 1},
	7618: {"heal": [100, 160]}, 7620: {"mana": [90, 150]},
	2666: {"food": true}, 2671: {"food": true},
}

func item_stats_text(itemtype: int) -> String:
	var lines: Array = []
	var st: Dictionary = ITEM_STATS.get(itemtype, {})
	if st.has("atk"):
		lines.append("Attack: +%d%s" % [int(st.atk), " (magic)" if bool(st.get("magic", false)) else ""])
	if st.has("armor"):
		lines.append("Defense: +%d%s" % [int(st.armor), " (shield)" if bool(st.get("shield", false)) else ""])
	if st.has("heal"):
		lines.append("Heals %d-%d hitpoints" % [int(st.heal[0]), int(st.heal[1])])
	if st.has("mana"):
		lines.append("Restores %d-%d mana" % [int(st.mana[0]), int(st.mana[1])])
	if bool(st.get("food", false)):
		lines.append("Food - speeds up regeneration")
	if st.has("quest"):
		lines.append("Quest item")
	if dat != null:
		var w := dat.item_weight(itemtype)
		if w > 0:
			lines.append("Weight: %.2f oz" % (w / 100.0))
	return "
".join(lines)



func load_real_data(dat_path: String, otbm_path: String) -> bool:
	return world.load_real_data(dat_path, otbm_path)

func get_tile_draws(tile: Vector2i, z := -1) -> Array:
	return world.get_tile_draws(tile, z)

func get_item_icon(itemtype: int) -> Texture2D:
	return world.get_item_icon(itemtype)

func item_label(itemtype: int) -> String:
	return world.item_label(itemtype)

func prewarm_sprites(center: Vector2i, radius := 16) -> int:
	return world.prewarm_sprites(center, radius)

func find_spawn() -> Vector2i:
	return world.find_spawn()

func tile_info(tile: Vector2i, z := -1) -> Dictionary:
	return world.tile_info(tile, z)

func floors_to_draw() -> Array:
	return world.floors_to_draw()

func is_walkable(tile: Vector2i, z := -1) -> bool:
	return world.is_walkable(tile, z)

func tile_light_radius(tile: Vector2i, z: int) -> int:
	return world.tile_light_radius(tile, z)

# ---- say: talkactions -> spells -> NPC --------------------------------------

func request_say(pid: int, text: String) -> void:
	if not players.has(pid):
		return
	var pname: String = players[pid].name
	chat_received.emit(pname, text)
	if scripts.handle_talk(self, pid, text):
		return
	if scripts.cast_spell(self, pid, text):
		return
	# NPC dialogue (stand-in for data/npc + npcsystem).
	var low := text.strip_edges().to_lower()
	if low.begins_with("hi"):
		chat_received.emit("Norf (Shop NPC)", "Greetings, %s! Say 'trade' to see my wares." % pname)
	elif low == "trade":
		chat_received.emit("Norf (Shop NPC)", "Have a look! Buying health/mana potions, meat, ham.")
		shop_requested.emit(pid)
	elif low.begins_with("buy "):
		var what := low.substr(4).strip_edges()
		for offer in scripts.shop:
			if String(offer.name).begins_with(what) or what.begins_with(String(offer.name)):
				buy_shop_item(pid, offer)
				return
		chat_received.emit("Norf (Shop NPC)", "I don't sell '%s'. Try trade." % what)
	elif low.begins_with("bye"):
		chat_received.emit("Norf (Shop NPC)", "Farewell, %s." % pname)
