class_name CombatSim
extends Node2D
## Phase 2 + 2.5 combat. 1:1 port of testttt/src/lib/game/engine.ts:
## spawn/AI/telegraphs/2s tick/Strike/shove/damage/death plus loot spread /
## 60s claim / filter / ground items and Cleave/Bolt/Ward.
##
## Architecture: this node is the aggregate root. It owns the shared state
## (player, monsters, telegraphs, floats, projectiles, floor maps) and the
## tick, and delegates domain logic to four extracted systems:
##   combat       — damage, abilities, shove        (systems/combat_system.gd)
##   loot         — drops, pickup, satchel/gear     (systems/loot_system.gd)
##   ai           — spawning, monster behavior      (systems/ai_system.gd)
##   pathfinding  — flow field, sight, chase step   (systems/pathfinding_system.gd)
## The public API is unchanged: HUD/sheets/tests keep calling CombatSim, and
## forwarders below route to the owning system.

signal leveled_up(level: int)
signal player_died(killed_by: String, xp_lost: int, gold_dropped: int)
signal toast(text: String, kind: String)
signal looted(item_key: String, qty: int)
signal mob_killed(monster_name: String)
signal vocation_changed(key: String)

const MonsterScript := preload("res://scripts/combat/monster.gd")
const Vocations := preload("res://scripts/combat/vocations.gd")
const FlowField := preload("res://scripts/combat/flow_field.gd")
const SimDraw := preload("res://scripts/combat/sim_draw.gd")
const CombatSystem := preload("res://scripts/combat/systems/combat_system.gd")
const LootSystem := preload("res://scripts/combat/systems/loot_system.gd")
const AISystem := preload("res://scripts/combat/systems/ai_system.gd")
const PathfindingSystem := preload("res://scripts/combat/systems/pathfinding_system.gd")

# Port of the web satchel/equipment sheets: 8 slots, flat armour sum,
# encumbrance sum, weapon damage sum. Starter kit matches web getOrCreate.
const GEAR_ORDER: Array = ["helmet", "amulet", "armor", "weapon", "shield", "legs", "boots", "ring"]

var vocation: String = "warrior"

var tiles: Array = []
var player: Node2D = null
var player_name: String = "Wanderer"

var monsters: Array = []  # Array[Monster], all floors (update only current)
var telegraphs: Array = []  # {id, tiles:Array[Vector3i], z, start_at, resolve_at, color, damage, source, source_id, status, resolved}
var floats: Array = []  # {pos:Vector2, text, color:Color, born:int, crit:bool}
var projectiles: Array = []  # {fx,fy,tx,ty tile ints, z, born, duration, color}

var target_id: int = -1
var next_auto_at: int = 0
var auto_attack: bool = true
## Extra occupancy (NPCs): Callable(x, y) -> bool, current floor only.
var tile_blocker: Callable = Callable()
var gate_cd_until: int = 0

var _uid: int = 1
var _next_regen: int = 0
var _last_player_grid := Vector3i(-999, -999, -999)
## Debug invariant: frames where any tile held 2+ bodies. Must stay 0.
var overlap_hits: int = 0
## Heartbeat for the debug overlay: total physics ticks since boot.
var _tick_count: int = 0
## Floor maps: z -> tiles 2D array. `tiles` always mirrors the player's floor.
var floor_maps: Dictionary = {}

# ---------------------------------------------------------------- systems
var combat: CombatSystem
var loot: LootSystem
var ai: AISystem
var pathfinding: PathfindingSystem

## Shared chase field (owned by pathfinding; forwarded for the debug overlay
## and tests that read sim.flow directly).
var flow: FlowField:
	get: return pathfinding.flow

## Loot domain state lives in the loot system; forwarded for HUD/sheets/SimDraw.
var ground: Array:
	get: return loot.ground
var local_inventory: Dictionary:
	get: return loot.local_inventory
var loot_filter: Array:
	get: return loot.loot_filter
var auto_pickup: bool:
	get: return loot.auto_pickup
var equipped: Dictionary:
	get: return loot.equipped

## Shove preview (owned by combat, painted by SimDraw).
var push_preview: Dictionary:
	get: return combat.push_preview

func _init() -> void:
	combat = CombatSystem.new()
	loot = LootSystem.new()
	ai = AISystem.new()
	pathfinding = PathfindingSystem.new()
	combat.sim = self
	loot.sim = self
	ai.sim = self
	pathfinding.sim = self

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
	loot.set_filter(GameBalance.DEFAULT_LOOT_FILTER.duplicate())
	_sync_floor()
	_last_player_grid = player.grid
	loot.seed_kit()
	combat.apply_vocation_stats(false)
	for i in range(ai.max_monsters()):
		ai.spawn_monster(true, 0)
	for i in range(ai.crypt_monsters()):
		ai.spawn_monster(true, 1)
	next_auto_at = Time.get_ticks_msec() + GameBalance.auto_attack_ms()

func set_vocation(key: String) -> bool:
	if not Vocations.valid(key) or key == vocation:
		return key == vocation
	vocation = key
	combat.apply_vocation_stats(true)
	vocation_changed.emit(key)
	var def: Dictionary = Vocations.def(key)
	toast.emit("Path of the %s — %s" % [String(def["name"]), String(def["blurb"])], "good")
	add_float(String(def["name"]).to_upper(), _v(player.grid) + Vector2(0, -0.6), Color(1.0, 0.82, 0.4), true)
	return true

## `tiles` mirrors the player's current floor; call after any z change.
func _sync_floor() -> void:
	var z: int = int(player.grid.z) if player != null else 0
	tiles = floor_maps.get(z, floor_maps.get(0, []))
	pathfinding.set_tiles(tiles)

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

func signi(v: int) -> int:
	return 1 if v > 0 else (-1 if v < 0 else 0)

func set_loot_filter(keys: Array) -> void:
	loot.set_filter(keys)
	queue_redraw()

func set_auto_pickup(v: bool) -> void:
	loot.set_auto_pickup(v)

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
	loot.loot_tile(tx, ty)

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

## Sanctuary rule (changed from the web slice's attack-out asymmetry):
## no offensive action may originate inside a PZ. Ward is defensive and stays.
func is_player_pacified() -> bool:
	return player != null and WorldGen.in_safe_zone(player.grid.x, player.grid.y)

func _deny_pacified() -> void:
	add_float("pacified", _v(player.grid) + Vector2(0, -0.4), Color(1.0, 0.88, 0.51), false)
	toast.emit("Pacified — step out of the Sanctuary to fight", "bad")

# ---------------------------------------------------------------- fx
func add_float(text: String, pos: Vector2, color: Color, crit: bool, ttl_ms: int = 1100) -> void:
	floats.append({"pos": pos, "text": text, "color": color, "born": Time.get_ticks_msec(), "crit": crit, "ttl": ttl_ms})
	if floats.size() > 40:
		floats.pop_front()

## Presentation helpers live in SimDraw; these forwarders keep HUD/sheet
## call sites stable (hud filter sheet uses rarity colors).
func _rarity_color(item_key: String) -> Color:
	return SimDraw.rarity_color(item_key)

func _item_label(item_key: String) -> String:
	return SimDraw.item_label(item_key)

# ---------------------------------------------------------------- combat (delegates)
func ability_strike() -> void:
	combat.cast_ability("strike")

func ability_cleave() -> void:
	combat.cast_ability("cleave")

func ability_bolt() -> void:
	combat.cast_ability("bolt")

func ability_ward() -> void:
	combat.cast_ability("ward")

func cast_ability(key: String) -> void:
	combat.cast_ability(key)

func ability_cooldown_pct(key: String) -> float:
	return combat.ability_cooldown_pct(key)

func strike_cooldown_pct() -> float:
	return combat.strike_cooldown_pct()

func tick_range() -> int:
	return combat.tick_range()

func damage_monster(m, amount: int) -> void:
	combat.damage_monster(m, amount)

func damage_player(amount: int, source: String, status: String = "") -> void:
	combat.damage_player(amount, source, status)

func _damage_bonus() -> int:
	return combat._damage_bonus()

func can_push(m, tx: int, ty: int) -> Dictionary:
	return combat.can_push(m, tx, ty)

func preview_push(m, tx: int, ty: int) -> void:
	combat.preview_push(m, tx, ty)

func clear_push_preview() -> void:
	combat.clear_push_preview()

func push(m, tx: int, ty: int) -> Dictionary:
	return combat.push(m, tx, ty)

func can_push_self(tx: int, ty: int) -> Dictionary:
	return combat.can_push_self(tx, ty)

func preview_push_self(tx: int, ty: int) -> void:
	combat.preview_push_self(tx, ty)

func push_self(tx: int, ty: int) -> Dictionary:
	return combat.push_self(tx, ty)

# ---------------------------------------------------------------- pathing (delegates)
## Line of sight for projectiles (archer tick, Ash Bolt). Endpoints excluded;
## walls block, water and gates do not. Different floors never see each other.
func has_sight(a: Vector3i, b: Vector3i) -> bool:
	return pathfinding.has_sight(a, b)

func spawn_monster(initial: bool = false, fz: int = 0) -> void:
	ai.spawn_monster(initial, fz)

## One synchronous AI step (test hook: the smoke suite drives this directly).
func _update_mobs(now: int) -> void:
	ai.update_mobs(now)

# ---------------------------------------------------------------- loot (delegates)
func is_visible_loot(g: Dictionary) -> bool:
	return loot.is_visible_loot(g)

func can_loot(g: Dictionary) -> bool:
	return loot.can_loot(g)

func visible_ground() -> Array:
	return loot.visible_ground()

func nearby_loot_count() -> int:
	return loot.nearby_loot_count()

func loot_tile(x: int, y: int) -> void:
	loot.loot_tile(x, y)

func loot_all_nearby() -> void:
	loot.loot_all_nearby()

func equip(item_key: String) -> bool:
	return loot.equip(item_key)

func unequip(slot: String) -> bool:
	return loot.unequip(slot)

func use_consumable(item_key: String) -> bool:
	return loot.use_consumable(item_key)

func is_consumable(item_key: String) -> bool:
	return loot.is_consumable(item_key)

func is_equippable(item_key: String) -> bool:
	return loot.is_equippable(item_key)

func _put_satchel(item_key: String, qty: int) -> void:
	loot.put_satchel(item_key, qty)

func _take_satchel(item_key: String, qty: int) -> void:
	loot.take_satchel(item_key, qty)

# ---------------------------------------------------------------- skills
func skill_order() -> Array:
	return GameBalance.SKILL_ORDER

func skill_def(key: String) -> Dictionary:
	return (GameBalance.SKILLS as Dictionary).get(key, {})

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
	combat.apply_vocation_stats(true)
	var eff: Dictionary = GameBalance.skill_def(key).get("effect", {})
	if int(eff.get("maxHp", 0)) > 0:
		player.set("hp", mini(int(player.get("max_hp")), int(player.get("hp")) + int(eff["maxHp"])))
	if int(eff.get("maxMana", 0)) > 0:
		player.set("mana", mini(int(player.get("max_mana")), int(player.get("mana")) + int(eff["maxMana"])))
	add_float("%s %d" % [String((GameBalance.SKILLS as Dictionary)[key]["name"]), rank + 1], _v(player.grid) + Vector2(0, -0.6), Color(1.0, 0.82, 0.4), true)
	return rank + 1

# ---------------------------------------------------------------- travel
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

func _respawn() -> void:
	var lvl: int = GameBalance.level_from_xp(int(player.get("xp")))
	player.set("level", lvl)
	combat.apply_vocation_stats(false)
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
		loot.auto_pickup_at(_last_player_grid.x, _last_player_grid.y)
		_try_gate(now)
	# dots + ward expiry, then the auto tick on the marked target (held while
	# pacified: Sanctuary never deals damage)
	combat.process_statuses(now)
	combat.try_auto_attack(now)
	ai.update_mobs(now)
	combat.resolve_telegraphs(now)
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

func _decay(now: int) -> void:
	telegraphs.assign(telegraphs.filter(func(t): return now < int(t["resolve_at"]) + 220))
	floats.assign(floats.filter(func(f): return now - int(f["born"]) < int(f.get("ttl", 1100))))
	projectiles.assign(projectiles.filter(func(pr): return now - int(pr["born"]) < int(pr["duration"])))
	loot.decay(now)
	var kept: Array = []
	for m in monsters:
		var mm = m
		if mm.dying_at == 0 or now - mm.dying_at < 320:
			kept.append(mm)
		else:
			mm.queue_free()
	monsters = kept
	ai.maybe_top_up(now)

# ---------------------------------------------------------------- draw (telegraphs under monsters, floats on top)
func _draw() -> void:
	if tiles.is_empty():
		return
	SimDraw.all(self, self)
