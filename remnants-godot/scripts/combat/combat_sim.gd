class_name CombatSim
extends Node2D
## Phase 2 + 2.5 combat. 1:1 port of testttt/src/lib/game/engine.ts:
## spawn/AI/telegraphs/2s tick/Strike/shove/damage/death plus loot spread /
## 60s claim / filter / ground items and Cleave/Bolt/Ward.
## Session inventory lives in local_inventory until WebSync flushes it.

signal leveled_up(level: int)
signal player_died(killed_by: String, xp_lost: int, gold_dropped: int)
signal toast(text: String, kind: String)
signal looted(item_key: String, qty: int)
signal mob_killed(monster_name: String)

const MonsterScript := preload("res://scripts/combat/monster.gd")
const Vocations := preload("res://scripts/combat/vocations.gd")
const FlowField := preload("res://scripts/combat/flow_field.gd")
const SimDraw := preload("res://scripts/combat/sim_draw.gd")

var vocation: String = "warrior"
## Shared chase field (extracted system; see flow_field.gd).
var flow := FlowField.new()

## Spawn tables live in content.json (world.REGIONS spawns + world.CRYPT),
## surfaced through WorldGen; monster counts and all tuning in GameBalance.COMBAT.
## Adding a creature or a spell is a data edit — no code here.

var tiles: Array = []
var player: Node2D = null
var player_name: String = "Wanderer"

var monsters: Array = []  # Array[Monster], all floors (update only current)
var telegraphs: Array = []  # {id, tiles:Array[Vector3i], z, start_at, resolve_at, color, damage, source, source_id, status, resolved}
var floats: Array = []  # {pos:Vector2, text, color:Color, born:int, crit:bool}
var ground: Array = []  # {id, grid:Vector3i, item_key, qty, owner, protected_until, born, jx, jy}
var projectiles: Array = []  # {fx,fy,tx,ty tile ints, z, born, duration, color}
## Session satchel: item_key -> qty. Flushed to web by WebSync, listed in filter sheet.
var local_inventory: Dictionary = {}
var loot_filter: Array = []
var auto_pickup: bool = true

var target_id: int = -1
var next_auto_at: int = 0
var auto_attack: bool = true
var push_preview: Dictionary = {}  # {from:Vector3i, to:Vector3i, valid:bool}
## Extra occupancy (NPCs): Callable(x, y) -> bool, current floor only.
var tile_blocker: Callable = Callable()
var gate_cd_until: int = 0

var _uid: int = 1
var _next_regen: int = 0
var _next_spawn_check: int = 0
var _last_player_grid := Vector3i(-999, -999, -999)
## Debug invariant: frames where any tile held 2+ bodies. Must stay 0.
var overlap_hits: int = 0
## Heartbeat for the debug overlay: total physics ticks since boot.
var _tick_count: int = 0
## Floor maps: z -> tiles 2D array. `tiles` always mirrors the player's floor.
var floor_maps: Dictionary = {}

func _nid() -> int:
	_uid += 1
	return _uid

func setup(maps: Dictionary, p_player: Node2D, p_name: String = "Wanderer") -> void:
	floor_maps = maps
	player = p_player
	player_name = p_name
	add_to_group("combat_sim")
	# Layering (all z relative): floor (Main, 0) < telegraphs + monsters (here, 1)
	# < player (5). Parent _draw runs before children, so telegraphs stay under
	# monsters within this layer. Do NOT go negative: the floor would cover us.
	z_index = 1
	loot_filter = GameBalance.DEFAULT_LOOT_FILTER.duplicate()
	_sync_floor()
	_last_player_grid = player.grid
	_seed_kit()
	_apply_vocation_stats(false)
	for i in range(_max_monsters()):
		spawn_monster(true, 0)
	for i in range(_crypt_monsters()):
		spawn_monster(true, 1)
	next_auto_at = Time.get_ticks_msec() + GameBalance.auto_attack_ms()

func set_vocation(key: String) -> bool:
	if not Vocations.valid(key) or key == vocation:
		return key == vocation
	vocation = key
	_apply_vocation_stats(true)
	var def: Dictionary = Vocations.def(key)
	toast.emit("Path of the %s — %s" % [String(def["name"]), String(def["blurb"])], "good")
	add_float(String(def["name"]).to_upper(), _v(player.grid) + Vector2(0, -0.6), Color(1.0, 0.82, 0.4), true)
	return true

## Vocation-scaled growth. announce=false at boot (world already toasted).
func _apply_vocation_stats(keep_current: bool) -> void:
	var base: Dictionary = GameBalance.stats_for_level(int(player.get("level")))
	var v: Dictionary = Vocations.def(vocation)
	var max_hp: int = maxi(1, int(floor(float(base["maxHp"]) * float(v["hp_mult"])))) + _skill_bonus("maxHp")
	var max_mana: int = maxi(1, int(floor(float(base["maxMana"]) * float(v["mana_mult"])))) + _skill_bonus("maxMana")
	player.set("max_hp", max_hp)
	player.set("max_mana", max_mana)
	if not keep_current:
		player.set("hp", max_hp)
		player.set("mana", max_mana)
	else:
		player.set("hp", mini(int(player.get("hp")), max_hp))
		player.set("mana", mini(int(player.get("mana")), max_mana))

func tick_range() -> int:
	return int((Vocations.def(vocation) as Dictionary).get("tick_range", 1))

## `tiles` mirrors the player's current floor; call after any z change.
func _sync_floor() -> void:
	var z: int = int(player.grid.z) if player != null else 0
	tiles = floor_maps.get(z, floor_maps.get(0, []))
	flow.set_tiles(tiles)

func current_tiles() -> Array:
	return tiles

func floor_size(fz: int) -> Vector2i:
	var ft: Array = floor_maps.get(fz, [])
	if ft.is_empty():
		return Vector2i(WorldGen.MAP_W, WorldGen.MAP_H)
	return Vector2i((ft[0] as Array).size(), ft.size())

## Tile-float helper: entity Vector3i -> Vector2 tile coords for float text.
func _v(p) -> Vector2:
	return Vector2(p.x, p.y)

func set_loot_filter(keys: Array) -> void:
	loot_filter = keys.duplicate()
	queue_redraw()

func set_auto_pickup(v: bool) -> void:
	auto_pickup = v

func set_auto_attack(v: bool) -> void:
	auto_attack = v
	if v:
		next_auto_at = Time.get_ticks_msec() + GameBalance.auto_attack_ms()

# ---------------------------------------------------------------- queries
func monster_at(x: int, y: int, fz: int = -1):
	var z: int = fz if fz >= 0 else (int(player.grid.z) if player != null else 0)
	for m in monsters:
		if m.grid == Vector3i(x, y, z) and m.dying_at == 0:
			return m
	return null

func is_occupied(x: int, y: int, fz: int = -1) -> bool:
	return monster_at(x, y, fz) != null

## Extra blockers (NPC tiles): current floor, x/y only.
func _blocked(x: int, y: int) -> bool:
	return tile_blocker.is_valid() and bool(tile_blocker.call(x, y))

func target():
	if target_id < 0 or player == null:
		return null
	for m in monsters:
		if m.mid == target_id and m.dying_at == 0 and m.grid.z == player.grid.z:
			return m
	return null

func set_target(mid: int) -> void:
	if mid >= 0 and is_player_pacified():
		_deny_pacified()
		return
	if target_id != mid:
		target_id = mid
		next_auto_at = Time.get_ticks_msec() + GameBalance.auto_attack_ms()

## Marks die off-screen: called every frame with the visible tile rect
## (+2 hysteresis against edge flicker). Silent — the vanishing reticle speaks.
func clip_target_to_view(r: Rect2i) -> void:
	if target_id < 0:
		return
	var t = target()
	if t == null:
		target_id = -1
		return
	if not r.grow(2).has_point(Vector2i(t.grid.x, t.grid.y)):
		target_id = -1

func cycle_target() -> void:
	if player == null:
		return
	if is_player_pacified():
		_deny_pacified()
		return
	var near: Array = []
	for m in monsters:
		var mm = m
		if mm.dying_at != 0 or mm.grid.z != player.grid.z:
			continue
		var d: int = maxi(absi(mm.grid.x - player.grid.x), absi(mm.grid.y - player.grid.y))
		if d <= 6:
			near.append({"m": mm, "d": d})
	if near.is_empty():
		return
	near.sort_custom(func(a, b): return a["d"] < b["d"])
	var idx := -1
	for i in range(near.size()):
		if near[i]["m"].mid == target_id:
			idx = i
	var nm = near[(idx + 1) % near.size()]["m"]
	set_target(nm.mid)

func tap_tile(tx: int, ty: int) -> void:
	var m = monster_at(tx, ty)
	if m != null:
		if is_player_pacified():
			_deny_pacified()
			return
		set_target(int(m.get("mid")))
		return
	loot_tile(tx, ty)

func auto_tick_pct() -> float:
	if not auto_attack or target() == null:
		return 0.0
	var left: int = next_auto_at - Time.get_ticks_msec()
	if left <= 0:
		return 1.0
	return 1.0 - float(left) / float(GameBalance.auto_attack_ms())

func push_cooldown_pct() -> float:
	var left: int = int(player.get("push_ready_at")) - Time.get_ticks_msec()
	if left <= 0:
		return 0.0
	return float(left) / float(GameBalance.COMBAT.get("PUSH_CD_MS", 2500))

func strike_cooldown_pct() -> float:
	var cd: int = int(_ability_def("strike").get("cooldown", 850))
	var ready: int = int((player.get("cooldowns") as Dictionary).get("strike", 0))
	var left: int = ready - Time.get_ticks_msec()
	if left <= 0:
		return 0.0
	return float(left) / float(cd)

# ---------------------------------------------------------------- spawning
func _max_monsters() -> int:
	return int(GameBalance.COMBAT.get("MAX_MONSTERS", 34))

func _crypt_monsters() -> int:
	return int(GameBalance.COMBAT.get("CRYPT_MONSTERS", 8))

func _pick_spawn_key(region: Dictionary) -> String:
	return _pick_weighted(region.get("spawns", []))

func _pick_weighted(table: Array) -> String:
	if table.is_empty():
		return "rat"
	var total := 0
	for s in table:
		total += int(s["weight"])
	var roll: int = randi() % maxi(1, total)
	for s in table:
		roll -= int(s["weight"])
		if roll < 0:
			return String(s["key"])
	return String(table[0]["key"])

func spawn_monster(initial: bool = false, fz: int = 0) -> void:
	if player == null:
		return
	var ft: Array = floor_maps.get(fz, [])
	if ft.is_empty():
		return
	var fw: int = (ft[0] as Array).size()
	var fh: int = ft.size()
	for attempt in range(40):
		var x: int = 1 + randi() % maxi(1, fw - 2)
		var y: int = 1 + randi() % maxi(1, fh - 2)
		if not WorldGen.is_walkable(ft, x, y):
			continue
		if fz == 0 and WorldGen.in_safe_zone(x, y):
			continue
		if not initial and fz == int(player.grid.z):
			var dist: int = maxi(absi(x - player.grid.x), absi(y - player.grid.y))
			if dist < 9:
				continue
		if fz == int(player.grid.z) and x == player.grid.x and y == player.grid.y:
			continue  # one soul per tile: never spawn onto the player
		if is_occupied(x, y, fz):
			continue
		var key: String
		if fz == 0:
			key = _pick_spawn_key(WorldGen.region_at(x, y))
		else:
			key = _pick_weighted(WorldGen.crypt_spawns())
		var def: Dictionary = GameBalance.monster_def(key)
		if def.is_empty():
			continue
		var damage_by := {}
		var hp: int = int(def.get("hp", 26))
		if randf() < float(GameBalance.COMBAT.get("RIVAL_MARK_CHANCE", 0.14)) and not GameBalance.RIVALS.is_empty():
			var rival: String = String(GameBalance.RIVALS[randi() % GameBalance.RIVALS.size()])
			var chunk: int = int(floor(float(hp) * (float(GameBalance.COMBAT.get("RIVAL_MARK_MIN", 0.3)) + randf() * float(GameBalance.COMBAT.get("RIVAL_MARK_SPREAD", 0.3)))))
			damage_by[rival] = chunk
			hp = maxi(1, hp - chunk)
		var m = MonsterScript.new()
		m.setup(_nid(), key, def, Vector3i(x, y, fz), hp, damage_by)
		var jitter: int = int(GameBalance.COMBAT.get("SENSE_JITTER", 1))
		m.sense = clampi(int(def.get("aggroRange", 4)) + randi_range(-jitter, jitter), int(GameBalance.COMBAT.get("SENSE_MIN", 2)), int(GameBalance.COMBAT.get("SENSE_MAX", 9)))
		add_child(m)
		monsters.append(m)
		return

func _floor_count(fz: int) -> int:
	var n := 0
	for m in monsters:
		if m.grid.z == fz and m.dying_at == 0:
			n += 1
	return n

# ---------------------------------------------------------------- abilities
# One pipeline, data-dispatched by def.shape (see content.ts AbilityDef):
# adjacent = single marked tile (Strike), radial = 8 around you (Cleave),
# line = projectile + delayed resolve (Bolt), self = instant buff (Ward).
# A new spell = a new content row. New SHAPES need one executor below.
# Damage school follows shape: adjacent swings steel (melee_mult),
# radial/line channel spells (spell_mult).
func ability_strike() -> void:
	cast_ability("strike")

func ability_cleave() -> void:
	cast_ability("cleave")

func ability_bolt() -> void:
	cast_ability("bolt")

func ability_ward() -> void:
	cast_ability("ward")

func cast_ability(key: String) -> void:
	if player == null or bool(player.get("dead")):
		return
	var def: Dictionary = _ability_def(key)
	if def.is_empty():
		return
	var shape: String = String(def.get("shape", "adjacent"))
	if shape != "self" and is_player_pacified():
		_deny_pacified()
		return
	match shape:
		"adjacent":
			_exec_single(def)
		"radial":
			_exec_radial(def)
		"line":
			_exec_beam(def)
		"self":
			_exec_self(def)
		_:
			add_float("unshaped", _v(player.grid), Color(0.58, 0.64, 0.72), false)

func _need_target(def: Dictionary):
	var tgt = target()
	if tgt == null:
		add_float("nothing marked", _v(player.grid), Color(0.58, 0.64, 0.72), false)
		return null
	var d: int = maxi(absi(tgt.grid.x - player.grid.x), absi(tgt.grid.y - player.grid.y))
	if d > int(def.get("range", 1)):
		add_float("too far", _v(player.grid), Color(0.58, 0.64, 0.72), false)
		return null
	return tgt

func _face(tgt) -> void:
	player.set("facing", Vector2i(signi(tgt.grid.x - player.grid.x), signi(tgt.grid.y - player.grid.y)))

func _melee_damage(base: int) -> int:
	var bonus: int = int(GameBalance.stats_for_level(int(player.get("level")))["damageBonus"]) + int(player.get("weapon_damage"))
	return maxi(1, int(round(float(base + bonus) * float((Vocations.def(vocation) as Dictionary).get("melee_mult", 1.0)))))

func _exec_single(def: Dictionary) -> void:
	var now: int = Time.get_ticks_msec()
	if now < int((player.get("cooldowns") as Dictionary).get(String(def.get("key", "")), 0)):
		return
	var tgt = _need_target(def)
	if tgt == null:
		return
	# validated first so fizzles never charge; _pay re-checks and spends.
	if int(player.get("mana")) < int(def.get("manaCost", 0)):
		add_float("no mana", _v(player.grid), Color(0.49, 0.83, 0.99), false)
		toast.emit("Not enough mana", "bad")
		return
	if not bool(_pay_ability(String(def.get("key", ""))).get("ok", false)):
		return
	_face(tgt)
	player.set("cast_until", now + int(def.get("windup", 260)))
	telegraphs.append({
		"id": _nid(), "tiles": [tgt.grid], "start_at": now, "resolve_at": now + int(def.get("windup", 260)),
		"color": Color.html(String(def.get("color", "#ffd166"))), "damage": _melee_damage(int(def.get("damage", 14))),
		"z": int(player.grid.z), "source": "player", "source_id": tgt.mid, "status": "", "resolved": false,
	})
	queue_redraw()

func _exec_radial(def: Dictionary) -> void:
	var r: Dictionary = _pay_ability(String(def.get("key", "")))
	if not bool(r.get("ok", false)):
		return
	var now: int = Time.get_ticks_msec()
	player.set("cast_until", now + int(def.get("windup", 420)))
	var tiles8: Array = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			tiles8.append(Vector3i(player.grid.x + dx, player.grid.y + dy, player.grid.z))
	telegraphs.append({
		"id": _nid(), "tiles": tiles8, "start_at": now, "resolve_at": now + int(def.get("windup", 420)),
		"color": Color.html(String(def.get("color", "#ef476f"))), "damage": _spell_damage(int(def.get("damage", 19))),
		"z": int(player.grid.z), "source": "player", "source_id": 0, "status": "", "resolved": false,
	})
	queue_redraw()

func _exec_beam(def: Dictionary) -> void:
	var tgt = _need_target(def)
	if tgt == null:
		return
	if not has_sight(player.grid, tgt.grid):
		add_float("blocked", _v(player.grid), Color(0.58, 0.64, 0.72), false)
		return
	var r: Dictionary = _pay_ability(String(def.get("key", "")))
	if not bool(r.get("ok", false)):
		return
	var now: int = Time.get_ticks_msec()
	_face(tgt)
	player.set("cast_until", now + int(def.get("windup", 340)))
	projectiles.append({
		"fx": player.grid.x, "fy": player.grid.y, "tx": tgt.grid.x, "ty": tgt.grid.y,
		"z": int(player.grid.z),
		"born": now, "duration": int(def.get("windup", 340)) + 120, "color": Color.html(String(def.get("color", "#4cc9f0"))),
	})
	telegraphs.append({
		"id": _nid(), "tiles": [tgt.grid], "start_at": now, "resolve_at": now + int(def.get("windup", 340)) + 120,
		"color": Color.html(String(def.get("color", "#4cc9f0"))), "damage": _spell_damage(int(def.get("damage", 26))),
		"z": int(player.grid.z), "source": "player", "source_id": tgt.mid, "status": "", "resolved": false,
	})
	queue_redraw()

func _exec_self(def: Dictionary) -> void:
	var r: Dictionary = _pay_ability(String(def.get("key", "")))
	if not bool(r.get("ok", false)):
		return
	var now: int = Time.get_ticks_msec()
	var amount: int = int(GameBalance.COMBAT.get("WARD_BASE", 45)) + int(player.get("level")) * int(GameBalance.COMBAT.get("WARD_PER_LEVEL", 5)) + _skill_bonus("ward")
	player.set("ward_hp", amount)
	var sts: Array = player.get("statuses")
	sts.assign(sts.filter(func(s): return String(s.get("key", "")) != "ward"))
	sts.append({"key": "ward", "until": now + int(GameBalance.COMBAT.get("WARD_MS", 6000)), "next_tick": 0, "power": amount})
	add_float("WARD", _v(player.grid), Color(0.02, 0.84, 0.63), false)
	queue_redraw()

func signi(v: int) -> int:
	return 1 if v > 0 else (-1 if v < 0 else 0)

func is_player_pacified() -> bool:
	# Sanctuary rule (changed from the web slice's attack-out asymmetry):
	# no offensive action may originate inside a PZ. Ward is defensive and stays.
	return player != null and WorldGen.in_safe_zone(player.grid.x, player.grid.y)

func _deny_pacified() -> void:
	add_float("pacified", _v(player.grid) + Vector2(0, -0.4), Color(1.0, 0.88, 0.51), false)
	toast.emit("Pacified — step out of the Sanctuary to fight", "bad")

func _ability_def(key: String) -> Dictionary:
	for a in (GameBalance.ABILITIES as Array):
		if String(a.get("key", "")) == key:
			return a
	return {}

func ability_cooldown_pct(key: String) -> float:
	var def: Dictionary = _ability_def(key)
	if def.is_empty():
		return 0.0
	var left: int = int((player.get("cooldowns") as Dictionary).get(key, 0)) - Time.get_ticks_msec()
	if left <= 0:
		return 0.0
	return float(left) / float(maxi(1, int(def.get("cooldown", 1))))

func _pay_ability(key: String) -> Dictionary:
	# Returns {ok, def} — checks dead/CD/mana like engine.ts castAbility.
	var out := {"ok": false, "def": {}}
	if player == null or bool(player.get("dead")):
		return out
	var def: Dictionary = _ability_def(key)
	if def.is_empty():
		return out
	var now: int = Time.get_ticks_msec()
	if now < int((player.get("cooldowns") as Dictionary).get(key, 0)):
		return out
	if int(player.get("mana")) < int(def.get("manaCost", 0)):
		add_float("no mana", _v(player.grid), Color(0.49, 0.83, 0.99), false)
		toast.emit("Not enough mana", "bad")
		return out
	player.set("mana", int(player.get("mana")) - int(def.get("manaCost", 0)))
	(player.get("cooldowns") as Dictionary)[key] = now + int(def.get("cooldown", 0))
	next_auto_at = now + GameBalance.auto_attack_ms()
	out["ok"] = true
	out["def"] = def
	return out

func _damage_bonus() -> int:
	return int(GameBalance.stats_for_level(int(player.get("level")))["damageBonus"]) + int(player.get("weapon_damage")) + _skill_bonus("damage")

## Spell damage for the magician path (Cleave/Bolt scale 35% up, steel down).
func _spell_damage(base: int) -> int:
	return maxi(1, int(round(float(base + _damage_bonus()) * float((Vocations.def(vocation) as Dictionary).get("spell_mult", 1.0)))))

# ---------------------------------------------------------------- shove
func can_push(m, tx: int, ty: int) -> Dictionary:
	var now: int = Time.get_ticks_msec()
	if bool(player.get("dead")):
		return {"ok": false, "reason": "dead"}
	if now < int(player.get("push_ready_at")):
		return {"ok": false, "reason": "Shove recharging"}
	if now < m.push_lock_until:
		return {"ok": false, "reason": "Braced"}
	var reach: int = maxi(absi(m.grid.x - player.grid.x), absi(m.grid.y - player.grid.y))
	if m.grid.z != int(player.grid.z):
		return {"ok": false, "reason": "Step closer to shove"}
	if reach > 1:
		return {"ok": false, "reason": "Step closer to shove"}
	if maxi(absi(tx - m.grid.x), absi(ty - m.grid.y)) != 1 or (tx == m.grid.x and ty == m.grid.y):
		return {"ok": false, "reason": "Shove is exactly 1 tile"}
	if not WorldGen.is_walkable(tiles, tx, ty):
		return {"ok": false, "reason": "Blocked"}
	if monster_at(tx, ty) != null:
		return {"ok": false, "reason": "Occupied"}
	if tile_blocker.is_valid() and bool(tile_blocker.call(tx, ty)):
		return {"ok": false, "reason": "Occupied"}
	if tx == player.grid.x and ty == player.grid.y:
		return {"ok": false, "reason": "That is your tile"}
	if WorldGen.in_safe_zone(tx, ty):
		return {"ok": false, "reason": "Cannot shove into Sanctuary"}
	return {"ok": true}

func preview_push(m, tx: int, ty: int) -> void:
	if m == null:
		push_preview = {}
	else:
		var v: Dictionary = can_push(m, tx, ty)
		push_preview = {"from": m.grid, "to": Vector3i(tx, ty, m.grid.z), "valid": bool(v.get("ok", false))}
	queue_redraw()

func clear_push_preview() -> void:
	push_preview = {}
	queue_redraw()

func push(m, tx: int, ty: int) -> Dictionary:
	var v: Dictionary = can_push(m, tx, ty)
	var now: int = Time.get_ticks_msec()
	push_preview = {}
	if not bool(v.get("ok", false)):
		if String(v.get("reason", "")) != "":
			add_float(String(v["reason"]), _v(m.grid), Color(0.58, 0.64, 0.72), false)
			toast.emit(String(v["reason"]), "bad")
		queue_redraw()
		return v
	m.grid = Vector3i(tx, ty, m.grid.z)
	m.aggro = true
	m.push_lock_until = now + 1200
	m.next_move_at = maxi(m.next_move_at, now + 350)
	if now < m.windup_until:
		m.windup_until = 0
		var kept: Array = []
		for t in telegraphs:
			if not (String(t["source"]) == "monster" and int(t["source_id"]) == m.mid and not bool(t["resolved"])):
				kept.append(t)
		telegraphs = kept
		add_float("INTERRUPTED", Vector2(tx, ty) + Vector2(0, -0.4), Color(0.3, 0.79, 0.94), true)
	else:
		add_float("shoved", Vector2(tx, ty) + Vector2(0, -0.3), Color(0.8, 0.84, 0.88), false)
	player.set("push_ready_at", now + int(GameBalance.COMBAT.get("PUSH_CD_MS", 2500)))
	queue_redraw()
	return {"ok": true}

## Self-shove: drag from your own tile to hop one tile. Shares the shove
## cadence and cooldown, cannot bypass a drink/cast root, and never moves
## onto (or through) a creature or an NPC fixture.
func can_push_self(tx: int, ty: int) -> Dictionary:
	var now: int = Time.get_ticks_msec()
	if player == null or bool(player.get("dead")):
		return {"ok": false, "reason": "dead"}
	if now < int(player.get("push_ready_at")):
		return {"ok": false, "reason": "Shove recharging"}
	if now < int(player.get("cast_until")):
		return {"ok": false, "reason": "Rooted"}
	if maxi(absi(tx - player.grid.x), absi(ty - player.grid.y)) != 1 or (tx == player.grid.x and ty == player.grid.y):
		return {"ok": false, "reason": "Shove is exactly 1 tile"}
	if not WorldGen.is_walkable(tiles, tx, ty):
		return {"ok": false, "reason": "Blocked"}
	if monster_at(tx, ty) != null:
		return {"ok": false, "reason": "Occupied"}
	if _blocked(tx, ty):
		return {"ok": false, "reason": "Occupied"}
	return {"ok": true}

func preview_push_self(tx: int, ty: int) -> void:
	var v: Dictionary = can_push_self(tx, ty)
	push_preview = {"from": player.grid, "to": Vector3i(tx, ty, player.grid.z), "valid": bool(v.get("ok", false))}
	queue_redraw()

func push_self(tx: int, ty: int) -> Dictionary:
	var v: Dictionary = can_push_self(tx, ty)
	push_preview = {}
	if not bool(v.get("ok", false)):
		if String(v.get("reason", "")) != "":
			add_float(String(v["reason"]), _v(player.grid), Color(0.58, 0.64, 0.72), false)
			toast.emit(String(v["reason"]), "bad")
		queue_redraw()
		return v
	# grid change alone drives the hop: render lerps, and the grid-change hook
	# in _physics_process handles auto-pickup + rift-gate travel for us.
	player.set("grid", Vector3i(tx, ty, player.grid.z))
	player.set("push_ready_at", Time.get_ticks_msec() + int(GameBalance.COMBAT.get("PUSH_CD_MS", 2500)))
	add_float("shoved", _v(player.grid) + Vector2(0, -0.3), Color(0.8, 0.84, 0.88), false)
	queue_redraw()
	return {"ok": true}

# ---------------------------------------------------------------- gear
# Port of the web satchel/equipment sheets: 8 slots, flat armour sum,
# encumbrance sum, weapon damage sum. Starter kit matches web getOrCreate.
const GEAR_ORDER: Array = ["helmet", "amulet", "armor", "weapon", "shield", "legs", "boots", "ring"]

## Consumable effects live on the item row (content.json items.*.effect) —
## a new potion is a data row, no code.
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
## Skill tree lives in content.ts (SKILLS/SKILL_ORDER): one point per level,
## rank caps keep every path completable-ish. Accessors below.
func skill_order() -> Array:
	return GameBalance.SKILL_ORDER

func skill_def(key: String) -> Dictionary:
	return (GameBalance.SKILLS as Dictionary).get(key, {})

var equipped: Dictionary = {}  # slot -> item_key

func _seed_kit() -> void:
	equipped = {"weapon": "bone_knife", "armor": "leather_vest"}
	local_inventory["salve"] = int(local_inventory.get("salve", 0)) + 3
	local_inventory["mana_draught"] = int(local_inventory.get("mana_draught", 0)) + 2
	_recalc_gear()

func _recalc_gear() -> void:
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

func equip(item_key: String) -> bool:
	var def: Dictionary = GameBalance.item_def(item_key)
	var slot: String = String(def.get("slot", ""))
	if slot == "":
		toast.emit("That item has no gear slot", "bad")
		return false
	if int(local_inventory.get(item_key, 0)) < 1:
		toast.emit("You do not own that", "bad")
		return false
	_take_satchel(item_key, 1)
	if equipped.has(slot):
		_put_satchel(String(equipped[slot]), 1)
	equipped[slot] = item_key
	_recalc_gear()
	add_float("equipped %s" % String(def.get("name", item_key)), _v(player.grid) + Vector2(0, -0.4), Color(1.0, 0.82, 0.4), false)
	return true

func unequip(slot: String) -> bool:
	if not equipped.has(slot):
		return false
	_put_satchel(String(equipped[slot]), 1)
	equipped.erase(slot)
	_recalc_gear()
	return true

func _take_satchel(item_key: String, qty: int) -> void:
	var left: int = int(local_inventory.get(item_key, 0)) - qty
	if left <= 0:
		local_inventory.erase(item_key)
	else:
		local_inventory[item_key] = left

func _put_satchel(item_key: String, qty: int) -> void:
	local_inventory[item_key] = int(local_inventory.get(item_key, 0)) + qty

## Consumables root you for a content-tuned moment — drinking is a commitment.
func use_consumable(item_key: String) -> bool:
	var fx: Dictionary = _consumable_fx(item_key)
	if fx.is_empty():
		return false
	if int(local_inventory.get(item_key, 0)) < 1:
		toast.emit("You have none left", "bad")
		return false
	var now: int = Time.get_ticks_msec()
	_take_satchel(item_key, 1)
	if int(fx.get("hp", 0)) > 0:
		player.set("hp", mini(int(player.get("max_hp")), int(player.get("hp")) + int(fx["hp"])))
		add_float("+%d" % int(fx["hp"]), _v(player.grid) + Vector2(0, -0.3), Color(0.3, 0.87, 0.5), false)
	if int(fx.get("mana", 0)) > 0:
		player.set("mana", mini(int(player.get("max_mana")), int(player.get("mana")) + int(fx["mana"])))
		add_float("+%d mp" % int(fx["mana"]), _v(player.grid) + Vector2(0, -0.6), Color(0.22, 0.74, 0.97), false)
	player.set("cast_until", now + int(GameBalance.COMBAT.get("ROOT_MS", 1200)))
	toast.emit(_consumable_label(item_key), "good")
	return true

func is_consumable(item_key: String) -> bool:
	return not _consumable_fx(item_key).is_empty()

func is_equippable(item_key: String) -> bool:
	return String(GameBalance.item_def(item_key).get("slot", "")) != ""

# ---------------------------------------------------------------- skills
func _skill_rank(key: String) -> int:
	return int((player.get("skills") as Dictionary).get(key, 0))

## Summed per-rank skill payload, data-driven (content.json skills.*.effect).
## Understood keys: maxHp, maxMana, stepMs (reduction), damage, ward.
func _skill_bonus(key: String) -> int:
	var total := 0
	var ranks: Dictionary = player.get("skills")
	for k in ranks.keys():
		var eff: Dictionary = GameBalance.skill_def(String(k)).get("effect", {})
		total += int(eff.get(key, 0)) * int(ranks[k])
	return total

## Spend one point. Returns the new rank, or -1 when rejected.
func spend_skill(key: String) -> int:
	if not (GameBalance.SKILLS as Dictionary).has(key):
		return -1
	var ranks: Dictionary = player.get("skills")
	var rank: int = int(ranks.get(key, 0))
	if int(player.get("skill_points")) < 1 or rank >= int((GameBalance.SKILLS as Dictionary)[key]["max"]):
		return -1
	player.set("skill_points", int(player.get("skill_points")) - 1)
	ranks[key] = rank + 1
	if key == "swift":
		player.set("swift", rank + 1)
	_apply_vocation_stats(true)
	var eff: Dictionary = GameBalance.skill_def(key).get("effect", {})
	if int(eff.get("maxHp", 0)) > 0:
		player.set("hp", mini(int(player.get("max_hp")), int(player.get("hp")) + int(eff["maxHp"])))
	if int(eff.get("maxMana", 0)) > 0:
		player.set("mana", mini(int(player.get("max_mana")), int(player.get("mana")) + int(eff["maxMana"])))
	add_float("%s %d" % [String((GameBalance.SKILLS as Dictionary)[key]["name"]), rank + 1], _v(player.grid) + Vector2(0, -0.6), Color(1.0, 0.82, 0.4), true)
	return rank + 1

# ---------------------------------------------------------------- damage
func add_float(text: String, pos: Vector2, color: Color, crit: bool, ttl_ms: int = 1100) -> void:
	floats.append({"pos": pos, "text": text, "color": color, "born": Time.get_ticks_msec(), "crit": crit, "ttl": ttl_ms})
	if floats.size() > 40:
		floats.pop_front()

func _auto_swing(m) -> void:
	var v: Dictionary = Vocations.def(vocation)
	var lvl: int = int(player.get("level"))
	if bool(v.get("tick_shot", false)):
		# Archer: arrows fly the tick range but walls stop them. No steel bonus.
		if not has_sight(player.grid, m.grid):
			add_float("blocked", _v(player.grid) + Vector2(0, -0.55), Color(0.58, 0.64, 0.72), false)
			return
		projectiles.append({
			"fx": player.grid.x, "fy": player.grid.y, "tx": m.grid.x, "ty": m.grid.y,
			"z": int(player.grid.z), "born": Time.get_ticks_msec(), "duration": 150,
			"color": Color(1.0, 0.95, 0.75),
		})
		damage_monster(m, int(v.get("tick_base", 4)) + int(floor(float(lvl) * float(v.get("tick_scale", 0.7)))) + _skill_bonus("damage"))
	else:
		var base: int = int(v.get("tick_base", 6)) + int(floor(float(lvl) * float(v.get("tick_scale", 0.9)))) + int(player.get("weapon_damage")) + _skill_bonus("damage")
		damage_monster(m, maxi(1, int(round(float(base) * float(v.get("melee_mult", 1.0))))))
	add_float("tick", _v(player.grid) + Vector2(0, -0.55), Color(0.58, 0.64, 0.72), false)

func damage_monster(m, amount: int) -> void:
	if m.dying_at != 0:
		return
	var now: int = Time.get_ticks_msec()
	var crit: bool = randf() < float(GameBalance.COMBAT.get("CRIT_CHANCE", 0.14))
	var dmg: int = maxi(1, int(round((float(amount) * float(GameBalance.COMBAT.get("CRIT_MULT", 1.85))) if crit else float(amount))))
	m.hp -= dmg
	m.hit_flash_until = now + 160
	m.aggro = true
	m.damage_by[player_name] = int(m.damage_by.get(player_name, 0)) + dmg
	add_float(("%d!" % dmg) if crit else str(dmg), _v(m.grid), Color(1.0, 0.82, 0.4) if crit else Color.WHITE, crit)
	if m.hp <= 0:
		kill_monster(m)
	queue_redraw()

func _claimant(m) -> String:
	var best: String = player_name
	var best_val := -1
	for k in m.damage_by.keys():
		if int(m.damage_by[k]) > best_val:
			best = String(k)
			best_val = int(m.damage_by[k])
	return best

func kill_monster(m) -> void:
	var now: int = Time.get_ticks_msec()
	m.dying_at = now
	player.set("kills", int(player.get("kills")) + 1)
	var xp: int = int(m.def.get("xp", 10)) + randi() % 4
	player.set("xp", int(player.get("xp")) + xp)
	add_float("+%d xp" % xp, _v(m.grid) + Vector2(0, -0.4), Color(0.64, 0.9, 0.21), false)
	var owner: String = _claimant(m)
	_drop_loot(m, owner, now)
	if owner != player_name:
		add_float("claimed by " + owner, _v(m.grid) + Vector2(0, -0.75), Color(0.97, 0.44, 0.44), false)
	mob_killed.emit(String(m.def.get("name", "?")))
	var new_level: int = GameBalance.level_from_xp(int(player.get("xp")))
	if new_level > int(player.get("level")):
		player.set("skill_points", int(player.get("skill_points")) + (new_level - int(player.get("level"))))
		player.set("level", new_level)
		_apply_vocation_stats(false)
		add_float("LEVEL UP", _v(player.grid) + Vector2(0, -0.6), Color(1.0, 0.82, 0.4), true)
		leveled_up.emit(new_level)
	if target_id == m.mid:
		target_id = -1

# ------------------------------------------------------------------- loot
# Port of engine.ts loot: 3x3 spread corpse-first, 60s top-dealer claim,
# filter hides stacks entirely, auto-pickup on step. XP still grants
# instantly; goods travel via ground -> satchel -> WebSync.

func _drop_loot(m, owner: String, now: int) -> void:
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
			if WorldGen.is_walkable(tiles, m.grid.x + dx, m.grid.y + dy):
				spread.append(Vector3i(m.grid.x + dx, m.grid.y + dy, m.grid.z))
	if spread.is_empty():
		spread.append(m.grid)
	spread.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return absi(a.x - m.grid.x) + absi(a.y - m.grid.y) < absi(b.x - m.grid.x) + absi(b.y - m.grid.y))
	var protect: int = int(GameBalance.COMBAT.get("LOOT_PROTECT_MS", 60000))
	for i in range(drops.size()):
		var tile: Vector3i = spread[i % spread.size()]
		ground.append({
			"id": _nid(), "grid": tile,
			"item_key": String(drops[i]["item_key"]), "qty": int(drops[i]["qty"]),
			"owner": owner, "protected_until": now + protect, "born": now,
			"jx": randf_range(-0.21, 0.21), "jy": randf_range(-0.16, 0.16),
		})
	queue_redraw()

func is_visible_loot(g: Dictionary) -> bool:
	return loot_filter.has(String(g.get("item_key", "")))

func can_loot(g: Dictionary) -> bool:
	return String(g.get("owner", "")) == player_name or Time.get_ticks_msec() >= int(g.get("protected_until", 0))

func visible_ground() -> Array:
	return ground.filter(func(g: Dictionary) -> bool: return is_visible_loot(g))

func nearby_loot_count() -> int:
	var n := 0
	for g in ground:
		if not is_visible_loot(g) or int((g["grid"] as Vector3i).z) != int(player.grid.z):
			continue
		var cell: Vector3i = g["grid"]
		if maxi(absi(cell.x - player.grid.x), absi(cell.y - player.grid.y)) <= 1:
			n += 1
	return n

## Presentation helpers live in SimDraw; these forwarders keep HUD/sheet
## call sites stable (hud filter sheet uses rarity colors).
func _rarity_color(item_key: String) -> Color:
	return SimDraw.rarity_color(item_key)

func _item_label(item_key: String) -> String:
	return SimDraw.item_label(item_key)

func _take_ground(g: Dictionary, silent: bool) -> bool:
	if not can_loot(g):
		if not silent:
			var left: int = maxi(0, int((int(g.get("protected_until", 0)) - Time.get_ticks_msec()) / 1000))
			add_float("%s · %ds" % [String(g.get("owner", "?")), left], _v(g["grid"]) + Vector2(0, -0.4), Color(0.97, 0.44, 0.44), false)
			toast.emit("Loot protected for %s (%ds)" % [String(g.get("owner", "?")), left], "bad")
		return false
	ground.erase(g)
	if String(g.get("item_key", "")) == "gold":
		player.set("gold", int(player.get("gold")) + int(g.get("qty", 0)))
		add_float("+%dg" % int(g.get("qty", 0)), _v(g["grid"]), Color(0.98, 0.75, 0.14), false)
		looted.emit("gold", int(g.get("qty", 0)))
	else:
		local_inventory[String(g.get("item_key", ""))] = int(local_inventory.get(String(g.get("item_key", "")), 0)) + int(g.get("qty", 0))
		add_float("+%s%s" % [_item_label(String(g.get("item_key", ""))), (" x%d" % int(g.get("qty", 0))) if int(g.get("qty", 0)) > 1 else ""], _v(g["grid"]), Color(0.64, 0.9, 0.21), false)
		looted.emit(String(g.get("item_key", "")), int(g.get("qty", 0)))
	queue_redraw()
	return true

## Manual loot of one tile (tap). Must be within 1 tile, same floor.
func loot_tile(x: int, y: int) -> void:
	if maxi(absi(x - player.grid.x), absi(y - player.grid.y)) > 1:
		return
	var here := Vector3i(x, y, player.grid.z)
	for g in ground.filter(func(d: Dictionary) -> bool: return (d["grid"] as Vector3i) == here and is_visible_loot(d)).duplicate():
		_take_ground(g, false)

## Sweep everything claimable and filtered within 1 tile, same floor.
func loot_all_nearby() -> void:
	var pz: int = int(player.grid.z)
	var near: Array = ground.filter(func(d: Dictionary) -> bool:
		if not is_visible_loot(d) or int((d["grid"] as Vector3i).z) != pz:
			return false
		var cell: Vector3i = d["grid"]
		return maxi(absi(cell.x - player.grid.x), absi(cell.y - player.grid.y)) <= 1)
	if near.is_empty():
		add_float("nothing here", _v(player.grid) + Vector2(0, -0.4), Color(0.58, 0.64, 0.72), false)
		return
	var got := 0
	for g in near:
		if _take_ground(g, true):
			got += 1
	if got == 0 and not near.is_empty():
		var blocked: Dictionary = near[0]
		var left: int = maxi(0, int((int(blocked.get("protected_until", 0)) - Time.get_ticks_msec()) / 1000))
		add_float("%s · %ds" % [String(blocked.get("owner", "?")), left], _v(player.grid) + Vector2(0, -0.4), Color(0.97, 0.44, 0.44), false)
		toast.emit("Loot protected for %s (%ds)" % [String(blocked.get("owner", "?")), left], "bad")

func _try_gate(now: int) -> void:
	if now < gate_cd_until:
		return
	if WorldGen.kind_at(tiles, player.grid.x, player.grid.y) != "gate":
		return
	var dest: Vector3i = WorldGen.gate_dest(player.grid)
	if dest.x < 0:
		return
	gate_cd_until = now + 1500
	# one soul per tile: never materialize inside a monster; slide to air.
	var spot: Vector3i = dest
	if monster_at(dest.x, dest.y, dest.z) != null:
		spot = Vector3i(-999, -999, -999)
		var dt: Array = floor_maps.get(dest.z, [])
		for r in range(0, 4):
			if spot.x > -900:
				break
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var c := Vector3i(dest.x + dx, dest.y + dy, dest.z)
					if WorldGen.is_walkable(dt, c.x, c.y) and monster_at(c.x, c.y, c.z) == null:
						spot = c
						break
				if spot.x > -900:
					break
		if spot.x < -900:
			toast.emit("The rift is crowded on the other side.", "bad")
			return
	player.set("grid", spot)
	player.set("render", Vector2(spot.x, spot.y))
	_last_player_grid = spot
	target_id = -1
	_sync_floor()
	var label := ""
	for g in WorldGen.GATES:
		if Vector3i((g["b"] as Vector2i).x, (g["b"] as Vector2i).y, int(g["bz"])) == dest or Vector3i((g["a"] as Vector2i).x, (g["a"] as Vector2i).y, int(g["az"])) == dest:
			label = String(g.get("name", "elsewhere"))
	add_float("RIFT", Vector2(dest.x, dest.y), Color(0.8, 0.5, 1.0), true)
	toast.emit("Rift carries you to %s" % label if label != "" else "Rift travel", "info")
	queue_redraw()

## Line of sight for projectiles (archer tick, Ash Bolt). Endpoints excluded;
## walls block, water and gates do not. Different floors never see each other.
func has_sight(a: Vector3i, b: Vector3i) -> bool:
	if a.z != b.z:
		return false
	var dx: int = absi(b.x - a.x)
	var dy: int = absi(b.y - a.y)
	var steps: int = maxi(dx, dy)
	if steps <= 1:
		return true
	for i in range(1, steps):
		var t: float = float(i) / float(steps)
		var cx: int = int(round(lerpf(float(a.x), float(b.x), t)))
		var cy: int = int(round(lerpf(float(a.y), float(b.y), t)))
		if WorldGen.blocks_projectile(tiles, cx, cy):
			return false
	return true

func _auto_pickup_at(x: int, y: int) -> void:
	if not auto_pickup:
		return
	var here := Vector3i(x, y, player.grid.z)
	for g in ground.filter(func(d: Dictionary) -> bool: return (d["grid"] as Vector3i) == here and is_visible_loot(d)).duplicate():
		_take_ground(g, true)

func damage_player(amount: int, source: String, status: String = "") -> void:
	if bool(player.get("dead")):
		return
	var now: int = Time.get_ticks_msec()
	if WorldGen.in_safe_zone(player.grid.x, player.grid.y):
		add_float("PROTECTED", _v(player.grid) + Vector2(0, -0.4), Color(1.0, 0.82, 0.4), false)
		return
	var raw: int = amount
	var dmg: int = GameBalance.mitigate(raw, int(player.get("armor")))
	var blocked: int = raw - dmg
	if int(player.get("ward_hp")) > 0:
		var absorbed: int = mini(int(player.get("ward_hp")), dmg)
		player.set("ward_hp", int(player.get("ward_hp")) - absorbed)
		dmg -= absorbed
		add_float("-%d" % absorbed, _v(player.grid) + Vector2(0, -0.3), Color(0.02, 0.84, 0.63), false)
		if int(player.get("ward_hp")) <= 0:
			(player.get("statuses") as Array).assign((player.get("statuses") as Array).filter(func(s): return String(s.get("key", "")) != "ward"))
	if dmg > 0:
		player.set("hp", int(player.get("hp")) - dmg)
		player.set("hit_flash_until", now + 220)
		add_float(("%d (-%d)" % [dmg, blocked]) if blocked > 0 else str(dmg), _v(player.grid), Color(1.0, 0.35, 0.43), false)
	if status != "":
		var sts: Array = player.get("statuses")
		sts.assign(sts.filter(func(s): return String(s.get("key", "")) != status))
		var power: int = int(GameBalance.COMBAT.get("POISON_POWER", 4)) if status == "poison" else int(GameBalance.COMBAT.get("BURN_POWER", 6))
		sts.append({"key": status, "until": now + int(GameBalance.COMBAT.get("STATUS_MS", 6000)), "next_tick": now + int(GameBalance.COMBAT.get("STATUS_TICK_MS", 1500)), "power": power})
	if int(player.get("hp")) <= 0:
		kill_player(source)
	queue_redraw()

func kill_player(source: String) -> void:
	var now: int = Time.get_ticks_msec()
	player.set("dead", true)
	player.set("hp", 0)
	player.set("dead_until", now + int(GameBalance.COMBAT.get("RESPAWN_MS", 2600)))
	player.set("deaths", int(player.get("deaths")) + 1)
	var xp_lost: int = int(floor(float(player.get("xp")) * float(GameBalance.COMBAT.get("XP_LOSS_PCT", 0.1))))
	var gold_dropped: int = int(floor(float(player.get("gold")) * float(GameBalance.COMBAT.get("GOLD_DROP_PCT", 0.5))))
	player.set("xp", maxi(0, int(player.get("xp")) - xp_lost))
	player.set("gold", int(player.get("gold")) - gold_dropped)
	(player.get("statuses") as Array).clear()
	player.set("ward_hp", 0)
	# Loot protection: the dropped gold lands where you fell, locked to you
	# for the standard claim window. Get back in time and it is yours again.
	if gold_dropped > 0:
		ground.append({
			"id": _nid(), "grid": player.grid,
			"item_key": "gold", "qty": gold_dropped,
			"owner": player_name, "protected_until": now + int(GameBalance.COMBAT.get("LOOT_PROTECT_MS", 60000)),
			"born": now, "jx": 0.0, "jy": 0.0,
		})
		add_float("cache: %dg" % gold_dropped, _v(player.grid) + Vector2(0, 0.45), Color(0.98, 0.75, 0.14), false)
	add_float("YOU DIED", _v(player.grid) + Vector2(0, -0.5), Color(1.0, 0.35, 0.43), true)
	player_died.emit(source, xp_lost, gold_dropped)

func _respawn() -> void:
	var lvl: int = GameBalance.level_from_xp(int(player.get("xp")))
	player.set("level", lvl)
	_apply_vocation_stats(false)
	player.set("grid", Vector3i(WorldGen.TEMPLE.x, WorldGen.TEMPLE.y, WorldGen.TEMPLE_Z))
	player.set("render", Vector2(WorldGen.TEMPLE))
	player.set("dead", false)
	player.set("cooldowns", {})
	target_id = -1
	_sync_floor()
	_last_player_grid = player.grid

# ---------------------------------------------------------------- tick
func _physics_process(delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	_tick_count += 1
	if player == null:
		return
	if bool(player.get("dead")):
		if now >= int(player.get("dead_until")):
			_respawn()
		_decay(now)
		queue_redraw()
		return
	# Crossing into the Sanctuary drops the mark: offense cannot stage from a PZ.
	if is_player_pacified() and target_id >= 0:
		target_id = -1
	# regen
	if now >= _next_regen:
		_next_regen = now + int(GameBalance.COMBAT.get("REGEN_MS", 1400))
		var hp_regen: int = int(GameBalance.COMBAT.get("REGEN_HP_BASE", 1)) + int(player.get("level")) / int(GameBalance.COMBAT.get("REGEN_HP_DIV", 3))
		var mp_regen: int = int(GameBalance.COMBAT.get("REGEN_MANA_BASE", 2)) + int(player.get("level")) / int(GameBalance.COMBAT.get("REGEN_MANA_DIV", 2))
		player.set("hp", mini(int(player.get("max_hp")), int(player.get("hp")) + hp_regen))
		player.set("mana", mini(int(player.get("max_mana")), int(player.get("mana")) + mp_regen))
	# step-triggered auto-pickup (web parity: walk onto a stack to take it)
	# plus rift-gate travel (shared hook: the tile changed under our feet).
	if (player.get("grid") as Vector3i) != _last_player_grid:
		_last_player_grid = player.get("grid")
		_auto_pickup_at(_last_player_grid.x, _last_player_grid.y)
		_try_gate(now)
	# dots
	var sts: Array = player.get("statuses")
	for s in sts.duplicate():
		if int(s.get("next_tick", 0)) > 0 and now >= int(s["next_tick"]) and now < int(s["until"]):
			s["next_tick"] = now + 1500
			damage_player(int(s["power"]), "Venom" if String(s["key"]) == "poison" else "Cinders")
	sts.assign(sts.filter(func(s): return now < int(s.get("until", 0))))
	player.set("slowed", sts.any(func(s): return String(s.get("key", "")) == "slow"))
	if not sts.any(func(s): return String(s.get("key", "")) == "ward"):
		player.set("ward_hp", 0)
	# auto tick on marked (held while pacified: Sanctuary never deals damage)
	var marked = target()
	if marked == null or is_player_pacified():
		next_auto_at = now + GameBalance.auto_attack_ms()
	elif auto_attack and now >= next_auto_at:
		var reach: int = maxi(absi(marked.grid.x - player.grid.x), absi(marked.grid.y - player.grid.y))
		if reach <= tick_range():
			_auto_swing(marked)
			next_auto_at = now + GameBalance.auto_attack_ms()
		else:
			next_auto_at = now
	_update_mobs(now)
	_resolve_telegraphs(now)
	_decay(now)
	for m in monsters:
		m.sync_pos(delta)
	_check_overlap()
	queue_redraw()

## One soul per tile: player + every live same-floor monster must be unique.
func _check_overlap() -> void:
	var seen := {}
	seen[player.grid] = true
	var pz: int = int(player.grid.z)
	for m in monsters:
		if m.dying_at != 0 or m.grid.z != pz:
			continue
		if seen.has(m.grid):
			overlap_hits += 1
			return
		seen[m.grid] = true

func _update_mobs(now: int) -> void:
	var player_safe: bool = WorldGen.in_safe_zone(player.grid.x, player.grid.y)
	if flow.field.is_empty() or flow.origin != player.grid:
		flow.refresh(player.grid)
	for m in monsters:
		var mm = m
		if mm.dying_at != 0:
			continue
		if mm.grid.z != int(player.grid.z):
			mm.show_bar = false
			continue  # other floors are frozen while you are away
		var dist: int = maxi(absi(mm.grid.x - player.grid.x), absi(mm.grid.y - player.grid.y))
		# readable at a glance: bar on when marked, within 3 tiles, or damaged.
		mm.show_bar = mm.dying_at == 0 and (target_id == mm.mid or dist <= 3)
		if not mm.aggro and dist <= mm.sense and not player_safe:
			mm.aggro = true
			# react promptly: a stale wander cooldown must not root a mob
			# that just noticed you for up to 3 seconds.
			mm.next_move_at = mini(mm.next_move_at, now + int(GameBalance.COMBAT.get("AGGRO_REACT_MS", 120)))
		if mm.aggro and (dist > mm.sense + int(GameBalance.COMBAT.get("DEAGGRO_TILES", 4)) or flow.value(mm.grid.x, mm.grid.y) < 0):
			# leashed out of earshot, or no walkable route at all: lose them.
			mm.aggro = false
		if not mm.aggro:
			# wounds close out of combat (up to spawn HP — rival marks stay
			# ledger-only). No more permanently half-barred roamers.
			if mm.hp < mm.spawn_hp and now >= mm.next_heal_at:
				mm.next_heal_at = now + int(GameBalance.COMBAT.get("MOB_HEAL_MS", 1500))
				mm.hp = mini(mm.spawn_hp, mm.hp + maxi(1, mm.max_hp / int(GameBalance.COMBAT.get("MOB_HEAL_DIV", 20))))
			if now >= mm.next_move_at:
				mm.next_move_at = now + int(int(mm.def.get("moveMs", 420)) * (3.0 + randf() * 4.0))
				_wander_step(mm)
		else:
			var can_attack: bool = not player_safe and dist <= int(mm.def.get("attackRange", 1)) and now >= mm.next_attack_at and now >= mm.windup_until
			if can_attack and int(mm.def.get("attackRange", 1)) > 1 and dist > 1 and mm.last_seen != player.grid and now >= mm.next_move_at:
				# ranged sidestep chase: the target moved — step to re-aim
				# instead of recasting at stale ground. Reads as pursuit.
				mm.last_seen = player.grid
				mm.next_move_at = now + int(mm.def.get("moveMs", 420))
				mm.next_attack_at = now + 600
				_flow_step(mm)
			elif can_attack:
				mm.last_seen = player.grid
				mm.windup_until = now + int(mm.def.get("windup", 600))
				mm.next_attack_at = now + int(mm.def.get("cadence", 1500))
				telegraphs.append({
					"id": _nid(), "tiles": _telegraph_shape(mm), "start_at": now,
					"resolve_at": now + int(mm.def.get("windup", 600)),
					"color": Color.html(String(mm.def.get("color", "#ff5a6e"))),
					"damage": int(mm.def.get("damage", 6)),
					"z": int(player.grid.z), "source": "monster", "source_id": mm.mid,
					"status": String(mm.def.get("status", "")),
					"resolved": false,
				})
			elif now >= mm.next_move_at and now >= mm.windup_until and dist > int(mm.def.get("attackRange", 1)):
				# desynced cadence: pack members must not step in lockstep or
				# nose-to-nose gridlock freezes the whole pack indefinitely.
				mm.next_move_at = now + int(float(mm.def.get("moveMs", 420)) * randf_range(0.7, 1.3))
				_flow_step(mm)

# ---------------------------------------------------------------- pathing
# Chase policy lives here; the distance field itself is FlowField
# (scripts/combat/flow_field.gd). Terrain-only field, bodies avoided here.

## Idle drift: try all 8 lanes shuffled, take the first legal one. The old
## single-die-roll version left pocketed monsters standing still for minutes.
func _wander_step(mm) -> bool:
	var dirs: Array = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]
	# Fisher-Yates with our own dice so every lane gets a fair hearing.
	for i in range(dirs.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: Vector2i = dirs[i]
		dirs[i] = dirs[j]
		dirs[j] = tmp
	for d in dirs:
		var dd: Vector2i = d
		var nx: int = mm.grid.x + dd.x
		var ny: int = mm.grid.y + dd.y
		# one soul per tile: wandering never steps onto the player either
		if nx == player.grid.x and ny == player.grid.y and mm.grid.z == int(player.grid.z):
			continue
		if WorldGen.is_walkable(tiles, nx, ny) and not is_occupied(nx, ny) and not WorldGen.in_safe_zone(nx, ny) and not _blocked(nx, ny):
			mm.grid = Vector3i(nx, ny, mm.grid.z)
			return true
	return false

## One chase step downhill on the field. False = boxed in (retry next cadence).
func _flow_step(mm) -> bool:
	if flow.field.is_empty():
		return false
	var best_d := 999999
	var cands: Array = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = mm.grid.x + dx
			var ny: int = mm.grid.y + dy
			if not flow.passable(nx, ny):
				continue
			if nx == player.grid.x and ny == player.grid.y:
				continue
			if is_occupied(nx, ny):
				continue  # separation: never stack, take the next-best lane
			if _blocked(nx, ny):
				continue  # NPC fixtures (dynamic bodies steer around at step time)
			var fd: int = flow.value(nx, ny)
			if fd < 0:
				continue
			if fd < best_d:
				best_d = fd
				cands = [Vector3i(nx, ny, mm.grid.z)]
			elif fd == best_d:
				cands.append(Vector3i(nx, ny, mm.grid.z))
	if cands.is_empty():
		return false
	mm.grid = cands[randi() % cands.size()]
	return true

func _telegraph_shape(m) -> Array:
	# Geometry comes from the content row (single/line/radial) — new monsters
	# need no code here, just a shape in content.ts.
	var out: Array = []
	var pz: int = int(player.grid.z)
	match String((m.def as Dictionary).get("shape", "single")):
		"radial":
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					out.append(Vector3i(player.grid.x + dx, player.grid.y + dy, pz))
		"line":
			var dx: int = signi(player.grid.x - m.grid.x)
			var dy: int = signi(player.grid.y - m.grid.y)
			for i in range(1, 4):
				out.append(Vector3i(m.grid.x + dx * i, m.grid.y + dy * i, m.grid.z))
			out.append(player.grid)
		_:
			out.append(player.grid)
	return out

func _resolve_telegraphs(now: int) -> void:
	for t in telegraphs:
		if bool(t["resolved"]) or now < int(t["resolve_at"]):
			continue
		t["resolved"] = true
		if int(t.get("z", 0)) != int(player.grid.z):
			continue  # other floor: decay handles cleanup
		if String(t["source"]) == "monster":
			var hit := false
			for cell in (t["tiles"] as Array):
				if cell == player.grid:
					hit = true
			if hit:
				var src = null
				for m in monsters:
					if m.mid == int(t["source_id"]):
						src = m
				damage_player(int(t["damage"]), String(src.def["name"]) if src != null else "Something in the dark", String(t.get("status", "")))
			else:
				add_float("dodged", _v(player.grid) + Vector2(0, -0.4), Color(0.58, 0.64, 0.72), false)
		elif int(t["source_id"]) != 0:
			var m = null
			for mm in monsters:
				if mm.mid == int(t["source_id"]) and mm.dying_at == 0:
					m = mm
			if m != null:
				var still := false
				for cell in (t["tiles"] as Array):
					if cell == m.grid:
						still = true
				var reach: int = maxi(absi(m.grid.x - player.grid.x), absi(m.grid.y - player.grid.y))
				if still or reach <= 1:
					damage_monster(m, int(t["damage"]))
				else:
					add_float("miss", _v(m.grid), Color(0.58, 0.64, 0.72), false)
		else:
			# Cleave: source_id 0, radial around the player at cast time.
			for mm2 in monsters:
				if mm2.dying_at != 0:
					continue
				for cell in (t["tiles"] as Array):
					if cell == mm2.grid:
						damage_monster(mm2, int(t["damage"]))
						break

func _decay(now: int) -> void:
	telegraphs.assign(telegraphs.filter(func(t): return now < int(t["resolve_at"]) + 220))
	floats.assign(floats.filter(func(f): return now - int(f["born"]) < int(f.get("ttl", 1100))))
	projectiles.assign(projectiles.filter(func(pr): return now - int(pr["born"]) < int(pr["duration"])))
	ground.assign(ground.filter(func(g: Dictionary) -> bool: return now - int(g.get("born", 0)) < int(GameBalance.COMBAT.get("GROUND_DECAY_MS", 180000))))
	var kept: Array = []
	for m in monsters:
		var mm = m
		if mm.dying_at == 0 or now - mm.dying_at < 320:
			kept.append(mm)
		else:
			mm.queue_free()
	monsters = kept
	if now >= _next_spawn_check:
		_next_spawn_check = now + 2500
		if _floor_count(0) < _max_monsters():
			spawn_monster(false, 0)
		if _floor_count(1) < _crypt_monsters():
			spawn_monster(false, 1)

# ---------------------------------------------------------------- draw (telegraphs under monsters, floats on top)
func _draw() -> void:
	if tiles.is_empty():
		return
	SimDraw.all(self, self)
