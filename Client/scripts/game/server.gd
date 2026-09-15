# Mock authoritative server — in-memory only, no MariaDB, no TCP.
# Uses REAL assets.dat flags + forgotten.otbm tiles when available (fallback:
# hardcoded walls). Mirrors Game::internalMoveCreature / canWalkTo (dat
# blockSolid) plus the demo game layer. Gameplay logic lives in focused
# modules (game/player.gd, monsters.gd, combat.gd, loot.gd, regeneration.gd,
# pathfinding.gd, npc.gd + data/*.toml); this class keeps the signals, the
# session/DB state and thin delegates so existing callers never change.
class_name BlackTekGameServer
extends RefCounted

signal player_moved(player_id: int, new_tile: Vector2i)
signal chat_heard(player_id: int, sender: String, text: String) # local chat: only listeners in range
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

# itemtype -> equipment slot (cf. CONST_SLOT_*). Single source for the gear
# panel, the HUD and the pickup-equip logic.
const EQUIP_SLOT := {2461: 1, 2467: 4, 2463: 4, 2376: 5, 2190: 5, 2511: 6, 2643: 8}

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
var temple_tile := Vector2i(-9999, -9999) # protection-zone anchor (player.gd)
var npc_tile := Vector2i(-9999, -9999) # Norf's post (npc.gd local-chat anchor)
var npc_z := 7


func _init(db_path := "") -> void:
	world = WorldScript.new()
	db = Database.new()
	if db_path != "":
		db.db_path = db_path
	db.load_db()
	scripts = ActionScripts.new()
	BlackTekMonsters.ensure_loaded()
	BlackTekLoot.ensure_loaded()
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

# Player session + vocation math live in game/player.gd; thin delegates here.
func enter_world(player_row: Dictionary) -> Vector2i:
	return BlackTekPlayer.enter_world(self, player_row)

func save_all() -> void:
	BlackTekPlayer.save_all(self)

static func exp_for_level(level: int) -> int:
	return BlackTekPlayer.exp_for_level(level)

func vocation_roll(_pid: int, min_v: int, max_v: int) -> int:
	return BlackTekPlayer.vocation_roll(self, _pid, min_v, max_v)

func is_gm(_pid: int) -> bool:
	return BlackTekPlayer.is_gm(self, _pid)

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
	BlackTekPlayer.heal_player(self, pid, amount, source)

func add_mana(pid: int, amount: int, source: String) -> void:
	BlackTekPlayer.add_mana(self, pid, amount, source)

func spend_mana(pid: int, amount: int) -> void:
	BlackTekPlayer.spend_mana(self, pid, amount)

func set_food(pid: int, seconds: int) -> void:
	BlackTekPlayer.set_food(self, pid, seconds)

func get_storage(pid: int, key: int) -> int:
	return db.get_storage(int(players[pid].row_id), key)

func set_storage(pid: int, key: int, value: int) -> void:
	db.set_storage(int(players[pid].row_id), key, value)

func add_item(pid: int, itemtype: int, count := 1) -> bool:
	return BlackTekPlayer.add_item(self, pid, itemtype, count)

func consume_item(pid: int, row: Dictionary) -> void:
	BlackTekPlayer.consume_item(self, pid, row)

# Pays gold coins from the backpack (NPC trades, cf. npcsystem).
func pay_gold(pid: int, amount: int) -> bool:
	return BlackTekPlayer.pay_gold(self, pid, amount)

func consume_refresh(pid: int) -> void:
	inventory_changed.emit(pid)

func buy_shop_item(pid: int, offer: Dictionary) -> void:
	BlackTekPlayer.buy_shop_item(self, pid, offer)

# ---- combat ------------------------------------------------------------------

func equipped_weapon(pid: int) -> int:
	return BlackTekCombat.equipped_weapon(self, pid)

func total_armor(pid: int) -> int:
	return BlackTekCombat.total_armor(self, pid)

func nearest_monster(pid: int, max_tiles := 1) -> Dictionary:
	return BlackTekCombat.nearest_monster(self, pid, max_tiles)

# Space / right click: mark the nearest (or next) creature as target.
func target_next(pid: int) -> void:
	BlackTekCombat.target_next(self, pid)

# Attack the current target when it is adjacent (hotbar slot / auto-attack).
func attack_current_target(pid: int) -> void:
	BlackTekCombat.attack_current_target(self, pid)

func set_target(pid: int, m: Dictionary) -> void:
	BlackTekCombat.set_target(self, pid, m)

func damage_monster(mid: int, dmg: int, kind: String, from_pid: int) -> void:
	BlackTekCombat.damage_monster(self, mid, dmg, kind, from_pid)

# ---- monsters AI (tick) ------------------------------------------------------

func next_monster_id() -> int:
	var mid := _next_monster_id
	_next_monster_id += 1
	return mid

func tick(delta: float) -> void:
	if players.is_empty():
		return
	var pid := 1
	var now := Time.get_ticks_msec() / 1000.0
	_tick_day_cycle(delta)
	BlackTekPath.path_step(self, pid, delta)
	BlackTekCombat.tick_auto_attack(self, pid, now)
	BlackTekRegen.tick(self, pid, delta, now)
	BlackTekMonsters.tick_ai(self, pid, now)
	# Respawn pacing.
	_respawn_t -= delta
	if _respawn_t <= 0.0:
		_respawn_t = BlackTekMonsters.RESPAWN_S
		BlackTekMonsters.try_spawn(self, pid)

# ---- map layer delegates (game/world.gd, game/player.gd, game/monsters.gd) --
func try_stair_teleport(player_id: int) -> int:
	return BlackTekPlayer.try_stair_teleport(self, player_id)

# Manual upstairs/downstairs travel (PgUp/PgDn stand-in for stair tiles).
func request_floor(player_id: int, dz: int) -> bool:
	return BlackTekPlayer.request_floor(self, player_id, dz)

# ---- tile occupancy (creatures never share an SQM) ---------------------------

func tile_free_for_monster(tile: Vector2i, z: int, ignore_id := 0) -> bool:
	return BlackTekMonsters.tile_free_for_monster(self, tile, z, ignore_id)

func monster_at(tile: Vector2i, z: int, ignore_id := 0) -> Dictionary:
	return BlackTekMonsters.monster_at(self, tile, z, ignore_id)

# Mouse push: drag a creature onto an adjacent free SQM (per-monster cooldown).
const PUSH_CD := 2.0

func can_push_monster(mid: int, dir: Vector2i) -> bool:
	return BlackTekMonsters.can_push_monster(self, mid, dir)

func push_monster(mid: int, dir: Vector2i, pid: int) -> bool:
	return BlackTekMonsters.push_monster(self, mid, dir, pid)

static func dir_name(dir: Vector2i) -> String:
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
	return BlackTekMonsters.push_cooldown_remaining(self, mid)

# ---- world interactions (game/player.gd): shoves, doors, drops, pickups ----
func pushable_item_at(tile: Vector2i, z: int) -> Dictionary:
	return BlackTekPlayer.pushable_item_at(self, tile, z)

func can_push_item(tile: Vector2i, dir: Vector2i, z: int) -> bool:
	return BlackTekPlayer.can_push_item(self, tile, dir, z)

func push_item(tile: Vector2i, dir: Vector2i, z: int, pid: int) -> bool:
	return BlackTekPlayer.push_item(self, tile, dir, z, pid)

func door_at(tile: Vector2i, z: int) -> Dictionary:
	return BlackTekPlayer.door_at(self, tile, z)

func use_door(tile: Vector2i, z: int, pid: int) -> bool:
	return BlackTekPlayer.use_door(self, tile, z, pid)

func takeable_item_at(tile: Vector2i, z: int) -> Dictionary:
	return BlackTekPlayer.takeable_item_at(self, tile, z)

func can_pickup(pid: int, itemtype: int) -> bool:
	return BlackTekPlayer.can_pickup(self, pid, itemtype)

func drop_item(pid: int, bpos: int, tile: Vector2i, z: int) -> bool:
	return BlackTekPlayer.drop_item(self, pid, bpos, tile, z)

func drop_equipped(pid: int, slot: int, tile: Vector2i, z: int) -> bool:
	return BlackTekPlayer.drop_equipped(self, pid, slot, tile, z)

func pickup_item(tile: Vector2i, z: int, pid: int) -> bool:
	return BlackTekPlayer.pickup_item(self, tile, z, pid)

# ---- player state queries + movement (game/player.gd) -------------------------
func is_pz_tile(tile: Vector2i) -> bool:
	return BlackTekPlayer.is_pz_tile(self, tile)

func is_fed(pid: int) -> bool:
	return BlackTekPlayer.is_fed(self, pid)

func is_poisoned(pid: int) -> bool:
	return BlackTekPlayer.is_poisoned(self, pid)

func request_move(player_id: int, dir: Vector2i) -> Vector2i:
	return BlackTekPlayer.request_move(self, player_id, dir)

func can_step(pid: int, dir: Vector2i) -> bool:
	return BlackTekPlayer.can_step(self, pid, dir)

func step_blocker(pid: int, dir: Vector2i) -> String:
	return BlackTekPlayer.step_blocker(self, pid, dir)

# /t talkaction + demo R key: back to town temple.
func teleport_town(pid: int) -> bool:
	return BlackTekPlayer.teleport_town(self, pid)

# ---- click pathfinding (game/pathfinding.gd, Dijkstra, dest-only like real server) -----
func request_path(pid: int, target: Vector2i) -> int:
	return BlackTekPath.request_path(self, pid, target)

func cancel_path(pid: int) -> void:
	BlackTekPath.cancel_path(self, pid)

func get_path(pid: int) -> Array:
	return BlackTekPath.fetch_path(self, pid)

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

# ---- say: talkactions -> spells -> NPC (all range-scoped, game/npc.gd) ----

# Local chat delivery: every player within radius tiles (same floor) hears
# the line. The speaker always hears themselves (distance 0).
func say_to_range(center: Vector2i, z: int, sender: String, text: String, radius := BlackTekNpc.SAY_RANGE) -> void:
	for opid in players.keys():
		var o: Dictionary = players[opid]
		if int(o.z) != z:
			continue
		if maxi(absi(int(o.tile.x) - center.x), absi(int(o.tile.y) - center.y)) > radius:
			continue
		chat_heard.emit(int(opid), sender, text)

func request_say(pid: int, text: String) -> void:
	if not players.has(pid):
		return
	var p: Dictionary = players[pid]
	say_to_range(p.tile, int(p.z), String(p.name), text)
	if scripts.handle_talk(self, pid, text):
		return
	if scripts.cast_spell(self, pid, text):
		return
	BlackTekNpc.handle_dialogue(self, pid, text.strip_edges().to_lower())
