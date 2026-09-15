# BlackTek monsters: archetype data (data/monster_definitions.toml), spawn and
# respawn, AI movement/attacks per tick, occupancy checks and pushing.
# Stateless algorithms — creature tables and timers live on the game server.
# Tuning (max_monsters/respawn_s/push_cd) comes from BlackTekConfig
# (data/gameplay.toml); consts below are deprecated compat aliases.
class_name BlackTekMonsters
extends RefCounted

const MAX_MONSTERS := 3
const RESPAWN_S := 6.0

const FALLBACK_RAT := {"name": "Rat", "hp": 25, "exp": 8, "dmg_min": 1, "dmg_max": 4, "speed_s": 0.5, "attack_s": 2.0, "range": 6}

static var _defs: Dictionary = {}

static func ensure_loaded() -> void:
	if not _defs.is_empty():
		return
	_defs = _load_defs("res://data/monster_definitions.toml")
	if _defs.is_empty():
		_defs = {"Rat": FALLBACK_RAT.duplicate()}

# Minimal TOML reader: [[monster]] blocks with name = "..." plus ints/floats.
static func _load_defs(path: String) -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(path):
		return out
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var cur := {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		if line == "[[monster]]":
			_flush_def(cur, out)
			cur = {}
			continue
		var eq := line.find("=")
		if eq < 0:
			continue
		var key := line.substr(0, eq).strip_edges()
		var val := line.substr(eq + 1).strip_edges()
		if val.begins_with("\""):
			var q2 := val.find("\"", 1)
			cur[key] = val.substr(1, q2 - 1) if q2 > 1 else ""
		elif "." in val:
			cur[key] = val.to_float()
		else:
			cur[key] = int(val)
	_flush_def(cur, out)
	f.close()
	return out

static func _flush_def(cur: Dictionary, out: Dictionary) -> void:
	if cur.is_empty() or not cur.has("name"):
		return
	out[String(cur.name)] = cur.duplicate()

static func archetype(_game, name := "Rat") -> Dictionary:
	ensure_loaded()
	if _defs.has(name):
		return _defs[name]
	return _defs.get("Rat", FALLBACK_RAT.duplicate())

static func max_monsters(game) -> int:
	return game.config.tune_int("max_monsters") if game.get("config") != null else MAX_MONSTERS

static func respawn_s(game) -> float:
	return game.config.tune("respawn_s") if game.get("config") != null else RESPAWN_S

static func push_cd(game) -> float:
	# Prefers server.push_cd() (config), falls back to the legacy const.
	if game.has_method("push_cd"):
		return game.push_cd()
	return game.config.tune("push_cd") if game.get("config") != null else BlackTekGameServer.PUSH_CD

static func try_spawn(game, pid: int) -> void:
	if game.monsters.size() >= max_monsters(game):
		return
	var p: Dictionary = game.players[pid]
	for _attempt in range(24):
		var off := Vector2i(randi_range(-5, 5), randi_range(-5, 5))
		if off == Vector2i.ZERO:
			continue
		var c: Vector2i = p.tile + off
		if not tile_free_for_monster(game, c, int(p.z)):
			continue
		# Don't spawn on the player or next to them.
		if maxi(absi(off.x), absi(off.y)) < 3:
			continue
		var spec := BlackTekMonsters.archetype(game)
		var mid: int = game.next_monster_id()
		game.monsters[mid] = {
			"id": mid, "name": String(spec.get("name", "Rat")), "tile": c, "z": int(p.z),
			"hp": int(spec.get("hp", 25)), "hpmax": int(spec.get("hp", 25)),
			"move_cd": 0.0, "attack_cd": 0.0, "target_pid": 0,
		}
		game.monsters_changed.emit()
		return

# One AI pass over every monster: acquire targets in range, step toward the
# player, swing when adjacent.
static func tick_ai(game, pid: int, now: float) -> void:
	var p: Dictionary = game.players[pid]
	var spec := BlackTekMonsters.archetype(game)
	var aggro := int(spec.get("range", 6))
	for mid in game.monsters.keys().duplicate():
		var m: Dictionary = game.monsters.get(mid)
		if m == null:
			continue
		var mt: Vector2i = m.tile
		var dist: int = maxi(absi(mt.x - int(p.tile.x)), absi(mt.y - int(p.tile.y)))
		if int(m.target_pid) == 0 and dist <= aggro:
			m.target_pid = pid
		if int(m.target_pid) != 0:
			if dist > aggro * 2:
				m.target_pid = 0
				continue
		if dist <= 1:
			if float(m.attack_cd) <= now:
				m.attack_cd = now + float(spec.get("attack_s", 2.0))
				BlackTekCombat.monster_attack(game, m, pid)
			elif float(m.move_cd) <= now:
				m.move_cd = now + float(spec.get("speed_s", 0.5))
				var step := Vector2i(signi(int(p.tile.x) - mt.x), signi(int(p.tile.y) - mt.y))
				var next := mt
				if absi(int(p.tile.x) - mt.x) >= absi(int(p.tile.y) - mt.y):
					next = mt + Vector2i(step.x, 0)
					if not game.is_walkable(next, int(m.z)):
						next = mt + Vector2i(0, step.y)
				else:
					next = mt + Vector2i(0, step.y)
					if not game.is_walkable(next, int(m.z)):
						next = mt + Vector2i(step.x, 0)
				if next != mt and tile_free_for_monster(game, next, int(m.z), mid):
					m.tile = next

# ---- tile occupancy (creatures never share an SQM) ---------------------------

static func monster_at(game, tile: Vector2i, z: int, ignore_id := 0) -> Dictionary:
	for m in game.monsters.values():
		if int(m.id) != ignore_id and int(m.z) == z and m.tile == tile:
			return m
	return {}

static func tile_free_for_monster(game, tile: Vector2i, z: int, ignore_id := 0) -> bool:
	if not game.is_walkable(tile, z):
		return false
	if not BlackTekMonsters.monster_at(game, tile, z, ignore_id).is_empty():
		return false
	if not BlackTekNpc.npc_at(game, tile, z).is_empty():
		return false
	for pl in game.players.values():
		if int(pl.z) == z and pl.tile == tile:
			return false
	return true

# ---- pushing (melee range, per-monster cooldown) ------------------------------

# Mouse push: drag a creature onto an adjacent free SQM (per-monster cooldown).
static func can_push_monster(game, mid: int, dir: Vector2i) -> bool:
	var m: Dictionary = game.monsters.get(mid, {})
	if m.is_empty():
		return false
	var d: int = maxi(absi(dir.x), absi(dir.y))
	if d != 1:
		return false
	return BlackTekMonsters.tile_free_for_monster(game, m.tile + dir, int(m.z), mid)

# Hold left click on a creature, drag, release: push 1 SQM in the drag
# direction. The pusher must stand next to it (anti-abuse: the client gates
# this too, but the server decides).
static func push_monster(game, mid: int, dir: Vector2i, pid: int) -> bool:
	var m: Dictionary = game.monsters.get(mid, {})
	if m.is_empty():
		return false
	if not game.players.has(pid):
		return false
	var pp: Dictionary = game.players[pid]
	if int(m.z) != int(pp.z):
		game.message_local(pid, "You are too far away to push that creature.")
		return false
	var mtd: int = maxi(absi(int(m.tile.x) - int(pp.tile.x)), absi(int(m.tile.y) - int(pp.tile.y)))
	if mtd > 1:
		game.message_local(pid, "You are too far away to push that creature.")
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if float(m.get("push_cd", 0.0)) > now:
		game.message_local(pid, "You cannot push this creature again yet.")
		return false
	if not BlackTekMonsters.can_push_monster(game, mid, dir):
		game.message_local(pid, "You cannot push the creature there.")
		return false
	m.push_cd = now + push_cd(game)
	m.tile = m.tile + dir
	game.message_local(pid, "You push the %s %s." % [String(m.name), BlackTekGameServer.dir_name(dir)])
	return true

# Seconds until this creature can be pushed again. The stats panel shows it
# as a loading bar so players see wait vs. ready.
static func push_cooldown_remaining(game, mid: int) -> float:
	var m: Dictionary = game.monsters.get(mid, {})
	if m.is_empty():
		return 0.0
	return maxf(0.0, float(m.get("push_cd", 0.0)) - Time.get_ticks_msec() / 1000.0)
