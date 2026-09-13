extends RefCounted
## AISystem — spawning + monster behavior.
## Extracted from CombatSim: spawn tables/rates, aggro + leash + wound-heal,
## wander drift, chase steps (via PathfindingSystem) and monster attack
## telegraphs. Damage resolution lives in CombatSystem.
##
## Spawn tables live in content.json (world.REGIONS spawns + world.CRYPT),
## surfaced through WorldGen; monster counts and all tuning in GameBalance.COMBAT.
## Adding a creature is a data edit — no code here.

const MonsterScript := preload("res://scripts/combat/monster.gd")
const Constants := preload("res://scripts/core/constants.gd")

var sim: CombatSim  # wired by the sim at construction (global class, no cycle)

var _next_spawn_check: int = 0

# ---------------------------------------------------------------- spawning
func max_monsters() -> int:
	return int(GameBalance.COMBAT.get("MAX_MONSTERS", 34))

func crypt_monsters() -> int:
	return int(GameBalance.COMBAT.get("CRYPT_MONSTERS", 8))

func pick_spawn_key(region: Dictionary) -> String:
	return pick_weighted(region.get("spawns", []))

func pick_weighted(table: Array) -> String:
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
	var player: PlayerGrid = sim.player
	if player == null:
		return
	var ft: Array = sim.floor_maps.get(fz, [])
	if ft.is_empty():
		return
	var fw: int = (ft[0] as Array).size()
	var fh: int = ft.size()
	for attempt in range(Constants.SPAWN_ATTEMPTS):
		var x: int = 1 + randi() % maxi(1, fw - 2)
		var y: int = 1 + randi() % maxi(1, fh - 2)
		if not WorldGen.is_walkable(ft, x, y):
			continue
		if fz == 0 and WorldGen.in_safe_zone(x, y):
			continue
		if not initial and fz == int(player.grid.z):
			var dist: int = maxi(absi(x - player.grid.x), absi(y - player.grid.y))
			if dist < Constants.SPAWN_MIN_DIST_TILES:
				continue
		if fz == int(player.grid.z) and x == player.grid.x and y == player.grid.y:
			continue  # one soul per tile: never spawn onto the player
		if sim.is_occupied(x, y, fz):
			continue
		var key: String
		if fz == 0:
			key = pick_spawn_key(WorldGen.region_at(x, y))
		else:
			key = pick_weighted(WorldGen.crypt_spawns())
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
		m.setup(sim._nid(), key, def, Vector3i(x, y, fz), hp, damage_by)
		var jitter: int = int(GameBalance.COMBAT.get("SENSE_JITTER", 1))
		m.sense = clampi(int(def.get("aggroRange", 4)) + randi_range(-jitter, jitter), int(GameBalance.COMBAT.get("SENSE_MIN", 2)), int(GameBalance.COMBAT.get("SENSE_MAX", 9)))
		sim.add_child(m)
		sim.monsters.append(m)
		return

func floor_count(fz: int) -> int:
	var n := 0
	for m: Monster in sim.monsters:
		if m.grid.z == fz and m.dying_at == 0:
			n += 1
	return n

## Population top-up, called from the sim's decay pass.
func maybe_top_up(now: int) -> void:
	if now < _next_spawn_check:
		return
	_next_spawn_check = now + 2500
	if floor_count(0) < max_monsters():
		spawn_monster(false, 0)
	if floor_count(1) < crypt_monsters():
		spawn_monster(false, 1)

# ---------------------------------------------------------------- behavior
func update_mobs(now: int) -> void:
	var player: PlayerGrid = sim.player
	var player_safe: bool = WorldGen.in_safe_zone(player.grid.x, player.grid.y)
	sim.pathfinding.ensure_field(player.grid)
	for m: Monster in sim.monsters:
		var mm: Monster = m
		if mm.dying_at != 0:
			continue
		if mm.grid.z != int(player.grid.z):
			mm.show_bar = false
			continue  # other floors are frozen while you are away
		var dist: int = maxi(absi(mm.grid.x - player.grid.x), absi(mm.grid.y - player.grid.y))
		# readable at a glance: bar on when marked, within 3 tiles, or damaged.
		mm.show_bar = mm.dying_at == 0 and (sim.target_id == mm.mid or dist <= Constants.BAR_RANGE_TILES)
		if not mm.aggro and dist <= mm.sense and not player_safe:
			mm.aggro = true
			# react promptly: a stale wander cooldown must not root a mob
			# that just noticed you for up to 3 seconds.
			mm.next_move_at = mini(mm.next_move_at, now + int(GameBalance.COMBAT.get("AGGRO_REACT_MS", 120)))
		if mm.aggro and (dist > mm.sense + int(GameBalance.COMBAT.get("DEAGGRO_TILES", 4)) or sim.pathfinding.value(mm.grid.x, mm.grid.y) < 0):
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
				wander_step(mm)
		else:
			var can_attack: bool = not player_safe and dist <= int(mm.def.get("attackRange", 1)) and now >= mm.next_attack_at and now >= mm.windup_until
			if can_attack and int(mm.def.get("attackRange", 1)) > 1 and dist > 1 and mm.last_seen != player.grid and now >= mm.next_move_at:
				# ranged sidestep chase: the target moved — step to re-aim
				# instead of recasting at stale ground. Reads as pursuit.
				mm.last_seen = player.grid
				mm.next_move_at = now + int(mm.def.get("moveMs", 420))
				mm.next_attack_at = now + 600
				sim.pathfinding.chase_step(mm)
			elif can_attack:
				mm.last_seen = player.grid
				mm.windup_until = now + int(mm.def.get("windup", 600))
				mm.next_attack_at = now + int(mm.def.get("cadence", 1500))
				sim.telegraphs.append({
					"id": sim._nid(), "tiles": telegraph_shape(mm), "start_at": now,
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
				sim.pathfinding.chase_step(mm)

## Idle drift: try all 8 lanes shuffled, take the first legal one. The old
## single-die-roll version left pocketed monsters standing still for minutes.
func wander_step(mm: Monster) -> bool:
	var player: PlayerGrid = sim.player
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
		if WorldGen.is_walkable(sim.tiles, nx, ny) and not sim.is_occupied(nx, ny) and not WorldGen.in_safe_zone(nx, ny) and not sim._blocked(nx, ny):
			mm.grid = Vector3i(nx, ny, mm.grid.z)
			return true
	return false

func telegraph_shape(m: Monster) -> Array:
	# Geometry comes from the content row (single/line/radial) — new monsters
	# need no code here, just a shape in content.ts.
	var out: Array = []
	var player: PlayerGrid = sim.player
	var pz: int = int(player.grid.z)
	match String((m.def as Dictionary).get("shape", "single")):
		"radial":
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					out.append(Vector3i(player.grid.x + dx, player.grid.y + dy, pz))
		"line":
			var dx: int = sim.signi(player.grid.x - m.grid.x)
			var dy: int = sim.signi(player.grid.y - m.grid.y)
			for i in range(1, 4):
				out.append(Vector3i(m.grid.x + dx * i, m.grid.y + dy * i, m.grid.z))
			out.append(player.grid)
		_:
			out.append(player.grid)
	return out
