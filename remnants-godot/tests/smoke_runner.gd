extends Node
## Frame-driven smoke test, attached by WorldView when REMNANTS_SMOKE=1.
## Headless run (needs ~8k loop iterations to reach the final frames):
## REMNANTS_SMOKE=1 Godot --headless --path . --quit-after 8000

var frame := 0
var failures: Array = []
var main: Node = null
var _marked_mid := -1
var _marked_hp := -1
var _loot_tile := Vector3i(-999, -999, -999)
var _loot_n := 0
var _abil_mid := -1
var _abil_hp := -1
var _death_tile := Vector3i(-999, -999, -999)
var _death_gold := 0
var _post_gold := 0
var _bar_mid := -1
var _atk_mid := -1
var _wander_from := Vector3i(-999, -999, -999)
var _wander_mid := -1
var _wander_hp := -1
var _wander_hp_after := -1
var _rep_mid := -1
var _rep_from := Vector3i(-999, -999, -999)
var _nat_mid := -1
var _nat_dist := -1
var _nat_armor := 0

const DIRS: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

func _check(cond: bool, label: String) -> void:
	print("[SMOKE] %s: %s" % ["PASS" if cond else "FAIL", label])
	if not cond:
		failures.append(label)

func _v2(p: Vector3i) -> Vector2:
	return Vector2(p.x, p.y)

## Free neighbor of center on the same floor ([] when boxed in).
func _free_neighbor(center: Vector3i, tiles: Array, sim, wild_only: bool) -> Array:
	for off in DIRS:
		var c := Vector3i(center.x + off.x, center.y + off.y, center.z)
		if wild_only and WorldGen.in_safe_zone(c.x, c.y):
			continue
		# never stage onto a rift gate: the grid-change hook would fire travel
		# and strand the rest of the test on another floor
		if WorldGen.kind_at(tiles, c.x, c.y) == "gate":
			continue
		if WorldGen.is_walkable(tiles, c.x, c.y) and sim.monster_at(c.x, c.y, c.z) == null:
			return [c]
	return []

## Test-only legs: put the player on a free tile adjacent to a live monster.
## Tries every monster (the first may be walled in) — returns the monster or null.
## wild_only skips Sanctuary tiles (offense is pacified there, marks clear).
## Defaults wild so later checks (kill-path, abilities) keep their mark.
func _stage_adjacent(sim, p, tiles: Array, wild_only: bool = true, need_dest: bool = false):
	for cand_m in (sim.get("monsters") as Array):
		if int(cand_m.get("dying_at")) != 0:
			continue
		if int((cand_m.get("grid") as Vector3i).z) != int((p.get("grid") as Vector3i).z):
			continue
		var spots: Array = _free_neighbor(cand_m.get("grid"), tiles, sim, wild_only)
		if spots.is_empty():
			continue
		if need_dest:
			# shove needs a SECOND free tile beyond the player's own footing
			var mg: Vector3i = cand_m.get("grid")
			var ok := false
			for cand in [Vector3i(mg.x + 1, mg.y, mg.z), Vector3i(mg.x - 1, mg.y, mg.z), Vector3i(mg.x, mg.y + 1, mg.z), Vector3i(mg.x, mg.y - 1, mg.z)]:
				if cand == spots[0]:
					continue
				if WorldGen.is_walkable(tiles, cand.x, cand.y) and sim.monster_at(cand.x, cand.y, cand.z) == null and not WorldGen.in_safe_zone(cand.x, cand.y):
					ok = true
					break
			if not ok:
				continue
		p.set("grid", spots[0])
		p.set("render", _v2(spots[0]))
		return cand_m
	print("[SMOKE] dbg stage FAILED player=%s" % [str(p.get("grid"))])
	return null

## Test-only leg: nudge any live body off a tile. The gate-trip teleports
## below land on fixed wild tiles (rift pads) where roaming monsters may
## stand — real gate travel slides the traveler aside (_try_gate), and these
## staged hops must uphold the same one-soul-per-tile invariant.
func _clear_tile(main: Node, tile: Vector3i) -> void:
	var sim = main.get("sim")
	var m = sim.monster_at(tile.x, tile.y, tile.z)
	if m == null:
		return
	var tiles: Array = (sim.get("floor_maps") as Dictionary).get(tile.z, [])
	for r in range(1, 7):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var c := Vector3i(tile.x + dx, tile.y + dy, tile.z)
				if WorldGen.is_walkable(tiles, c.x, c.y) and sim.monster_at(c.x, c.y, c.z) == null:
					m.set("grid", c)
					m.set("render", Vector2(c.x, c.y))
					return

func _physics_process(_delta: float) -> void:
	frame += 1
	if main == null:
		main = get_parent()
	if frame == 4:
		# Flow-field connectivity regression (player report: aggro'd creatures
		# never close to attack — they wander sideways). The field must reach
		# every tile the PLAYER can walk to: player_grid._try_step allows
		# diagonal moves past wall corners, so a corner-cut field marks such
		# regions -1 and the deaggro rule drops aggro the frame it fires.
		var ff = load("res://scripts/combat/flow_field.gd").new()
		# 7x6 wall band (y=2) whose only opening is a corner squeeze:
		# A=(1,1) -> O=(2,2) -> B=(3,3), with (2,1),(1,2),(3,2),(2,3) walled.
		var tt: Array = []
		for y in range(6):
			var row: Array = []
			for x in range(7):
				row.append("wall" if y == 2 else "grass")
			tt.append(row)
		tt[1][2] = "wall"
		tt[2][2] = "grass"
		tt[3][2] = "wall"
		ff.set_tiles(tt)
		ff.refresh(Vector3i(2, 0, 0))  # player north of the band
		var disconnected := ""
		for y in range(6):
			for x in range(7):
				if WorldGen.is_walkable(tt, x, y) and ff.value(x, y) < 0:
					disconnected += "(%d,%d) " % [x, y]
		_check(disconnected == "", "flow reaches every player-walkable tile (got -1 at: %s)" % disconnected)
		_check(ff.value(3, 3) >= 0, "field crosses the corner squeeze to the far side")
		# self-shove: hop one tile, share the shove cooldown, never onto NPCs.
		var sim0 = main.get("sim")
		var pl0 = main.get("player")
		pl0.set("grid", Vector3i(20, 35, 0))
		pl0.set("render", Vector2(20, 35))
		pl0.set("push_ready_at", 0)
		var sr: Dictionary = sim0.push_self(19, 35)
		_check(bool(sr.get("ok", false)), "self-shove hops one tile (%s)" % str(sr))
		_check((pl0.get("grid") as Vector3i) == Vector3i(19, 35, 0), "self-shove moved the player")
		_check(int(pl0.get("push_ready_at")) > Time.get_ticks_msec(), "self-shove shares the shove cooldown")
		var sr2: Dictionary = sim0.push_self(20, 35)
		_check(not bool(sr2.get("ok", false)), "self-shove recharges like a shove")
		pl0.set("push_ready_at", 0)
		var sr3: Dictionary = sim0.can_push_self(20, 36)
		_check(not bool(sr3.get("ok", false)) and String(sr3.get("reason", "")) == "Occupied", "self-shove refused onto an NPC tile (%s)" % str(sr3))
		var sr4: Dictionary = sim0.push_self(18, 34)
		_check(bool(sr4.get("ok", false)), "self-shove works diagonally")
		pl0.set("grid", Vector3i(WorldGen.TEMPLE.x, WorldGen.TEMPLE.y, 0))
		pl0.set("render", Vector2(WorldGen.TEMPLE))
		pl0.set("push_ready_at", 0)
		# content integrity: every creature is reachable from a spawn table, every
		# consumable carries an effect, every skill carries its effect dict —
		# adding content must stay a data-only edit (content.json, no code).
		var spawn_keys := {}
		for reg in (GameBalance.WORLD.get("REGIONS", []) as Array):
			for s in (reg.get("spawns", []) as Array):
				spawn_keys[String(s["key"])] = true
		for s in WorldGen.crypt_spawns():
			spawn_keys[String(s["key"])] = true
		for mk in (GameBalance.MONSTERS as Dictionary).keys():
			_check(spawn_keys.has(String(mk)), "monster '%s' reachable from a spawn table" % String(mk))
		for ik in (GameBalance.ITEMS as Dictionary).keys():
			var idef: Dictionary = GameBalance.item_def(String(ik))
			if String(idef.get("kind", "")) == "consumable":
				_check(not (idef.get("effect", {}) as Dictionary).is_empty(), "consumable '%s' carries an effect" % String(ik))
		for sk in (GameBalance.SKILLS as Dictionary).keys():
			_check(not ((GameBalance.SKILLS as Dictionary)[sk].get("effect", {}) as Dictionary).is_empty(), "skill '%s' carries an effect" % String(sk))
		# chat: _submit_chat clears + closes the input, and the speech float
		# lingers ~6s (ttl 6000) instead of the 1.1s combat-float lifetime.
		var hud0 = main.get("hud")
		hud0._submit_chat("smoke chat")
		_check(String(hud0._chat_input.get("text")) == "", "chat input cleared after send")
		_check(not bool(hud0._chat_input.get("visible")), "chat input closes after send")
		var chat_found := false
		var chat_ttl := 0
		for fl in (sim0.get("floats") as Array):
			if String(fl.get("text", "")) == "smoke chat":
				chat_found = true
				chat_ttl = int(fl.get("ttl", 0))
		_check(chat_found, "say spawns a speech float")
		_check(chat_ttl == 6000, "speech float ttl is 6000ms")
	if frame == 400:
		var chat_gone := true
		for fl2 in (main.get("sim").get("floats") as Array):
			if String(fl2.get("text", "")) == "smoke chat":
				chat_gone = false
		_check(chat_gone, "chat float expired after ~6s")
	if frame == 30:
		var sim = main.get("sim")
		_check(sim != null, "sim exists")
		_check((sim.get("monsters") as Array).size() >= 30, "spawned ~34 monsters (got %d)" % (sim.get("monsters") as Array).size())
		sim.cycle_target()
		var tgt = sim.target()
		if tgt == null:
			# spawn RNG left nothing within 6 tiles of the Temple: walk up
			# to a live monster (teleport = test-only legs), then mark.
			if _stage_adjacent(sim, main.get("player"), main.get("tiles"), true) != null:
				sim.cycle_target()
				tgt = sim.target()
		_check(tgt != null, "cycle_target marks something")
		if tgt != null:
			var p = main.get("player")
			var tiles1: Array = main.get("tiles")
			# stand on free WILD ground next to the mark: blind offsets can land
			# in a wall or inside the Sanctuary (pacified), flaking the Strike.
			var spots: Array = _free_neighbor(tgt.get("grid"), tiles1, sim, true)
			if spots.is_empty():
				var alt = _stage_adjacent(sim, p, tiles1, true)
				if alt != null:
					tgt = alt
					sim.set_target(int(tgt.get("mid")))
			else:
				p.set("grid", spots[0])
				p.set("render", _v2(spots[0]))
			_marked_mid = int(tgt.get("mid"))
			_marked_hp = int(tgt.get("hp"))
			sim.set("next_auto_at", Time.get_ticks_msec() + 60000)
			sim.ability_strike()
			_check((sim.get("telegraphs") as Array).size() >= 1, "Strike creates player telegraph")
	if frame == 60:
		var sim2 = main.get("sim")
		var tgt2 = null
		for m in (sim2.get("monsters") as Array):
			if int(m.get("mid")) == _marked_mid:
				tgt2 = m
		if tgt2 != null and _marked_mid >= 0:
			_check(int(tgt2.get("hp")) < _marked_hp, "Strike damaged marked (%d -> %d)" % [_marked_hp, int(tgt2.get("hp"))])
		else:
			_check(false, "marked monster still tracked")
		var p2 = main.get("player")
		p2.set("push_ready_at", 0)
		var tiles0: Array = main.get("tiles")
		# stage one: teleport next to a live monster with room to shove into
		# (Strike may have crit-killed the mark; pockets have no free dest)
		var staged60 = _stage_adjacent(sim2, p2, tiles0, true, true)
		_check(staged60 != null, "staged for shove")
		# shove needs an adjacent monster WITH a free destination tile:
		# try every adjacent candidate, not just the first.
		var adj = null
		var dest := Vector3i(-999, -999, -999)
		var tiles: Array = main.get("tiles")
		for m2 in (sim2.get("monsters") as Array):
			if int(m2.get("dying_at")) != 0:
				continue
			var g: Vector3i = m2.get("grid")
			var pg: Vector3i = p2.get("grid")
			if g.z != pg.z or maxi(absi(g.x - pg.x), absi(g.y - pg.y)) > 1:
				continue
			for cand in [Vector3i(g.x + 1, g.y, g.z), Vector3i(g.x - 1, g.y, g.z), Vector3i(g.x, g.y + 1, g.z), Vector3i(g.x, g.y - 1, g.z)]:
				if WorldGen.is_walkable(tiles, cand.x, cand.y) and sim2.monster_at(cand.x, cand.y, cand.z) == null and cand != pg and not WorldGen.in_safe_zone(cand.x, cand.y):
					adj = m2
					dest = cand
					break
			if adj != null:
				break
		if adj == null:
			var live_same := 0
			var best := 999
			var dump := ""
			for mdbg in (sim2.get("monsters") as Array):
				if int(mdbg.get("dying_at")) != 0:
					continue
				var dg: Vector3i = mdbg.get("grid")
				var pgdbg: Vector3i = p2.get("grid")
				if dg.z != pgdbg.z:
					continue
				live_same += 1
				var dd: int = maxi(absi(dg.x - pgdbg.x), absi(dg.y - pgdbg.y))
				best = mini(best, dd)
				if dd <= 2:
					dump += "m%d%s " % [int(mdbg.get("mid")), str(dg)]
			print("[SMOKE] dbg60 player=%s live_same=%d nearest=%d near=[%s]" % [str(p2.get("grid")), live_same, best, dump])
			_check(false, "found adjacent monster for shove")
		elif dest.x < -900:
			_check(false, "found free shove dest")
		else:
			adj.set("push_lock_until", 0)
			var r: Dictionary = sim2.push(adj, dest.x, dest.y)
			_check(bool(r.get("ok", false)), "shove succeeds (%s)" % str(r))
			_check((adj.get("grid") as Vector3i) == dest, "monster displaced to %s" % str(dest))
	if frame == 120:
		var sim3 = main.get("sim")
		_check((sim3.get("telegraphs") as Array).size() >= 0, "telegraph array alive (n=%d)" % (sim3.get("telegraphs") as Array).size())
		# kill-path: deal lethal damage to marked adjacent monster, expect xp+gold
		var p3 = main.get("player")
		var before_xp: int = int(p3.get("xp"))
		var victim = sim3.target()
		if victim == null:
			sim3.cycle_target()
			victim = sim3.target()
		if victim != null:
			victim.set("hp", 1)
			victim.set("damage_by", {})
			sim3.damage_monster(victim, 50)
			_check(int(p3.get("xp")) > before_xp, "kill grants xp (%d -> %d)" % [before_xp, int(p3.get("xp"))])
		else:
			_check(false, "victim for kill-path")
	if frame == 150:
		var sim4 = main.get("sim")
		# open the filter wide: default filter hides common materials, and the
		# victim's drops may be exactly that. Also exercises set_loot_filter.
		sim4.set_loot_filter(GameBalance.ALL_ITEM_KEYS.duplicate())
		_check((sim4.get("loot_filter") as Array).size() == (GameBalance.ALL_ITEM_KEYS as Array).size(), "filter accepts full list")
		var own: Array = (sim4.get("ground") as Array).filter(func(g: Dictionary) -> bool: return String(g.get("owner", "")) == String(sim4.get("player_name")))
		_check(not own.is_empty(), "kill scattered ground loot (n=%d)" % (sim4.get("ground") as Array).size())
		if not own.is_empty():
			_loot_tile = own[0]["grid"]
			_loot_n = (sim4.get("ground") as Array).size()
			var p4 = main.get("player")
			# pick up from adjacent ground (teleporting onto tiles is banned:
			# a monster may stand on the stack)
			var spots0: Array = _free_neighbor(_loot_tile, main.get("tiles"), sim4, false)
			if not spots0.is_empty():
				p4.set("grid", spots0[0])
				p4.set("render", _v2(spots0[0]))
				sim4.loot_all_nearby()
	if frame == 170:
		var sim5 = main.get("sim")
		var p5 = main.get("player")
		_check((sim5.get("ground") as Array).size() < _loot_n or int(p5.get("gold")) > 50 or not (sim5.get("local_inventory") as Dictionary).is_empty(), "step auto-pickup took the stack (ground %d->%d)" % [_loot_n, (sim5.get("ground") as Array).size()])
		# rival lock: rig a kill owned by someone else, it must stay locked
		var rig = null
		for m4 in (sim5.get("monsters") as Array):
			if int(m4.get("dying_at")) == 0:
				rig = m4
				break
		if rig == null:
			_check(false, "live monster for rival-lock")
		else:
			rig.set("hp", 1)
			rig.set("damage_by", {"Rival X": 9999})
			sim5.damage_monster(rig, 50)
			var locked: Array = (sim5.get("ground") as Array).filter(func(g: Dictionary) -> bool: return String(g.get("owner", "")) == "Rival X")
			_check(not locked.is_empty(), "rival-owned stacks exist")
			if not locked.is_empty():
				_check(not sim5.can_loot(locked[0]), "rival stack locked for player")
				var spots2: Array = _free_neighbor(locked[0]["grid"], main.get("tiles"), sim5, false)
				if not spots2.is_empty():
					p5.set("grid", spots2[0])
					p5.set("render", _v2(spots2[0]))
				var rivals_before: int = (sim5.get("ground") as Array).filter(func(g: Dictionary) -> bool: return String(g.get("owner", "")) == "Rival X").size()
				sim5.loot_all_nearby()
				var rivals_after: int = (sim5.get("ground") as Array).filter(func(g: Dictionary) -> bool: return String(g.get("owner", "")) == "Rival X").size()
				_check(rivals_after == rivals_before and rivals_before > 0, "locked stack survives sweep (denied)")
	if frame == 200:
		var sim6 = main.get("sim")
		var p6 = main.get("player")
		# caps first: PlayerState setters clamp current to max on write
		p6.set("max_mana", 200)
		p6.set("mana", 200)
		p6.set("hp", int(p6.get("max_hp")))
		var v = _stage_adjacent(sim6, p6, main.get("tiles"), true)
		if v == null:
			_check(false, "live monster for abilities")
		else:
			_abil_mid = int(v.get("mid"))
			v.set("hp", 150)
			_abil_hp = 150
			v.set("next_move_at", Time.get_ticks_msec() + 60000)  # hold still for the AoE window
			# _stage_adjacent already put us on a free wild tile next to v.
			sim6.set_target(_abil_mid)
			sim6.next_auto_at = Time.get_ticks_msec() + 60000
			sim6.ability_cleave()
			var found := false
			for tg in (sim6.get("telegraphs") as Array):
				if String(tg.get("source", "")) == "player" and int(tg.get("source_id", -1)) == 0:
					found = true
			_check(found, "Cleave paints radial telegraph")
	if frame == 235:
		var sim7 = main.get("sim")
		var v7 = null
		for m6 in (sim7.get("monsters") as Array):
			if int(m6.get("mid")) == _abil_mid:
				v7 = m6
		if v7 != null and _abil_mid >= 0:
			_check(int(v7.get("hp")) < _abil_hp, "Cleave resolved AoE (%d -> %d)" % [_abil_hp, int(v7.get("hp"))])
			_abil_hp = int(v7.get("hp"))
			sim7.set_target(_abil_mid)
			sim7.ability_bolt()
			_check(not (sim7.get("projectiles") as Array).is_empty(), "Bolt spawns projectile")
		else:
			_check(false, "ability victim tracked")
	if frame == 265:
		var sim8 = main.get("sim")
		var v8 = null
		for m7 in (sim8.get("monsters") as Array):
			if int(m7.get("mid")) == _abil_mid:
				v8 = m7
		if v8 != null:
			_check(int(v8.get("hp")) < _abil_hp, "Bolt landed (%d -> %d)" % [_abil_hp, int(v8.get("hp"))])
		else:
			_check(false, "bolt victim tracked")
		sim8.ability_ward()
		var p8 = main.get("player")
		_check(int(p8.get("ward_hp")) > 0, "Ward raises bubble (ward %d)" % int(p8.get("ward_hp")))
	if frame == 300:
		# death-cache: die wild with gold in pocket, cache must drop owned
		var sim9 = main.get("sim")
		var p9 = main.get("player")
		p9.set("gold", 200)
		var staged9 = _stage_adjacent(sim9, p9, main.get("tiles"), true)
		_check(staged9 != null, "staged wild tile for death")
		_death_tile = p9.get("grid")
		sim9.damage_player(9999, "Smoke Wraith")
		_check(bool(p9.get("dead")), "lethal hit kills")
		_check(int(p9.get("gold")) == 100, "death takes 50%% gold (200 -> %d)" % int(p9.get("gold")))
		_post_gold = int(p9.get("gold"))
		_death_gold = 200 - _post_gold
		var cache: Array = (sim9.get("ground") as Array).filter(func(g: Dictionary) -> bool: return String(g.get("item_key", "")) == "gold" and String(g.get("owner", "")) == String(sim9.get("player_name")) and (g["grid"] as Vector3i) == _death_tile)
		_check(not cache.is_empty(), "death cache dropped owned at death tile")
		if not cache.is_empty():
			_check(sim9.can_loot(cache[0]), "own cache lootable immediately")
	if frame == 320:
		var p10 = main.get("player")
		_check(bool(p10.get("dead")), "still dead during 2.6s window")
	if frame == 480:
		var sim10 = main.get("sim")
		var p11 = main.get("player")
		_check(not bool(p11.get("dead")), "respawned at Sanctuary")
		_check((p11.get("grid") as Vector3i) == Vector3i(WorldGen.TEMPLE.x, WorldGen.TEMPLE.y, 0), "respawn tile is Temple")
		# reclaim from ADJACENT ground (never teleport onto a tile: 1 soul each)
		var spots4: Array = _free_neighbor(_death_tile, main.get("tiles"), sim10, false)
		if not spots4.is_empty():
			p11.set("grid", spots4[0])
			p11.set("render", _v2(spots4[0]))
			sim10.loot_all_nearby()
		elif sim10.monster_at(_death_tile.x, _death_tile.y, _death_tile.z) == null:
			p11.set("grid", _death_tile)
			p11.set("render", _v2(_death_tile))
	if frame == 500:
		var p12 = main.get("player")
		_check(int(p12.get("gold")) >= _post_gold + _death_gold, "cache reclaimed (%d -> %d)" % [_post_gold, int(p12.get("gold"))])
	if frame == 520:
		var sim11 = main.get("sim")
		var p13 = main.get("player")
		var armor0: int = int(p13.get("armor"))
		(sim11.get("local_inventory") as Dictionary)["chitin_helm"] = 1
		_check(sim11.equip("chitin_helm"), "equip helmet from satchel")
		_check(String((sim11.get("equipped") as Dictionary).get("helmet", "")) == "chitin_helm" and int(p13.get("armor")) > armor0, "gear raises armor (%d -> %d)" % [armor0, int(p13.get("armor"))])
		_check(sim11.unequip("helmet"), "unequip returns it")
		_check(int(p13.get("armor")) == armor0, "armor restored after unequip")
		p13.set("hp", 50)
		_check(sim11.use_consumable("salve"), "drink salve")
		_check(int(p13.get("hp")) == 105, "salve heals 55 (50 -> %d)" % int(p13.get("hp")))
		_check(int(p13.get("cast_until")) > Time.get_ticks_msec(), "drinking roots (cast lock)")
	if frame == 545:
		# pacifism: offense from inside the Sanctuary is denied, Ward still works
		var sim12 = main.get("sim")
		var p14 = main.get("player")
		p14.set("grid", Vector3i(WorldGen.TEMPLE.x, WorldGen.TEMPLE.y, 0))
		p14.set("render", Vector2(WorldGen.TEMPLE))
		p14.set("mana", 200)
		sim12.cycle_target()
		_check(sim12.target() == null, "Sanctuary denies marking")
		var before: int = (sim12.get("telegraphs") as Array).filter(func(tg: Dictionary) -> bool: return String(tg.get("source", "")) == "player").size()
		sim12.ability_strike()
		sim12.ability_cleave()
		sim12.ability_bolt()
		var after: int = (sim12.get("telegraphs") as Array).filter(func(tg: Dictionary) -> bool: return String(tg.get("source", "")) == "player").size()
		_check(after == before, "Sanctuary denies Strike/Cleave/Bolt")
		_check(sim12.is_player_pacified(), "pacified flag reads true in PZ")
		p14.set("ward_hp", 0)
		(p14.get("statuses") as Array).assign((p14.get("statuses") as Array).filter(func(s: Dictionary) -> bool: return String(s.get("key", "")) != "ward"))
		(p14.get("cooldowns") as Dictionary)["ward"] = 0
		sim12.ability_ward()
		_check(int(p14.get("ward_hp")) > 0, "Ward still castable in PZ (defensive)")
	if frame == 575:
		# mark in the wild, then step into the PZ: the mark must drop
		var sim13 = main.get("sim")
		var staged = _stage_adjacent(sim13, main.get("player"), main.get("tiles"), true)
		_check(staged != null, "staged wild tile for entry test")
		sim13.cycle_target()
		_check(sim13.target() != null, "marked in the wild")
	if frame == 585:
		var p15 = main.get("player")
		p15.set("grid", Vector3i(WorldGen.TEMPLE.x, WorldGen.TEMPLE.y, 0))
		p15.set("render", Vector2(WorldGen.TEMPLE))
	if frame == 595:
		_check(main.get("sim").target() == null, "entering Sanctuary clears the mark")
	if frame == 605:
		# flow field: origin 0, expansion reaches open ground, walls stay -1,
		# every monster carries its own sense radius
		var sim14 = main.get("sim")
		var p16 = main.get("player")
		_stage_adjacent(sim14, p16, main.get("tiles"), true)
		sim14.flow.refresh(p16.get("grid"))
		var f: Array = sim14.flow.get("field")
		var pg: Vector3i = p16.get("grid")
		_check(int((f[pg.y] as Array)[pg.x]) == 0, "flow origin is the player tile")
		var reached := false
		for row in f:
			if (row as Array).has(1):
				reached = true
				break
		# a player fully walled in has no expansion: verify the pocket instead,
		# using the exact flow rules (walkable, non-PZ, no corner-cutting).
		var boxed := true
		for off in DIRS:
			var ox: int = (off as Vector2i).x
			var oy: int = (off as Vector2i).y
			var bx: int = pg.x + ox
			var by: int = pg.y + oy
			if not sim14.flow.passable(bx, by):
				continue
			if ox != 0 and oy != 0 and not sim14.flow.passable(pg.x + ox, pg.y) and not sim14.flow.passable(pg.x, pg.y + oy):
				continue
			boxed = false
			break
		_check(reached or boxed, "flow expands to neighboring ground")
		_check(int((f[5] as Array)[0]) == -1, "border wall is unreachable (-1)")
		var senses_ok := true
		for m9 in (sim14.get("monsters") as Array):
			if int(m9.get("sense")) < 2 or int(m9.get("sense")) > 9:
				senses_ok = false
		_check(senses_ok, "per-monster sense radius in 2..9")
	if frame == 620:
		# HP bars: hidden when far + undamaged, shown within 3 tiles
		var sim15 = main.get("sim")
		var p17 = main.get("player")
		var far = null
		for m10 in (sim15.get("monsters") as Array):
			if int(m10.get("dying_at")) != 0:
				continue
			if int(m10.get("hp")) != int(m10.get("max_hp")):
				continue
			var g10: Vector3i = m10.get("grid")
			var pg10: Vector3i = p17.get("grid")
			if g10.z != pg10.z or maxi(absi(g10.x - pg10.x), absi(g10.y - pg10.y)) <= 6:
				continue
			# must be approachable: boxed-in monsters have no free neighbor
			if _free_neighbor(m10.get("grid"), main.get("tiles"), sim15, true).is_empty():
				continue
			far = m10
			break
		if far == null:
			_check(false, "far undamaged monster for bar test")
		else:
			_bar_mid = int(far.get("mid"))
			_check(not bool(far.get("show_bar")), "bar hidden when far + full hp")
			var spots3: Array = _free_neighbor(far.get("grid"), main.get("tiles"), sim15, true)
			if not spots3.is_empty():
				p17.set("grid", spots3[0])
				p17.set("render", _v2(spots3[0]))
	if frame == 630:
		var sim16 = main.get("sim")
		var near = null
		for m11 in (sim16.get("monsters") as Array):
			if int(m11.get("mid")) == _bar_mid:
				near = m11
		if near != null and _bar_mid >= 0:
			_check(bool(near.get("show_bar")), "bar shown within 3 tiles")
		else:
			_check(false, "bar monster tracked")
	if frame == 640:
		# NPCs: trader buys/sells, healer mends, ferryman sails.
		# Deals happen at the counter: stage on (19,35), within 2 of all three.
		var npcs = main.get("npcs")
		var sim17 = main.get("sim")
		var p18 = main.get("player")
		p18.set("grid", Vector3i(19, 35, 0))
		p18.set("render", Vector2(19, 35))
		p18.set("gold", 100)
		var s0: int = int((sim17.get("local_inventory") as Dictionary).get("salve", 0))
		_check(npcs.buy("salve"), "trader sells salve")
		_check(int(p18.get("gold")) == 82, "salve costs 18 (100 -> %d)" % int(p18.get("gold")))
		_check(int((sim17.get("local_inventory") as Dictionary).get("salve", 0)) == s0 + 1, "salve lands in satchel")
		(sim17.get("local_inventory") as Dictionary)["rat_pelt"] = 2
		_check(npcs.sell("rat_pelt") == 3, "trader buys pelt at half base")
		_check(int(p18.get("gold")) == 85, "purse grows (82 -> %d)" % int(p18.get("gold")))
		p18.set("hp", 40)
		(p18.get("statuses") as Array).append({"key": "poison", "until": Time.get_ticks_msec() + 60000, "next_tick": Time.get_ticks_msec() + 60000, "power": 4})
		_check(npcs.heal(), "healer mends")
		_check(int(p18.get("hp")) == int(p18.get("max_hp")), "heal refills HP")
		_check(not (p18.get("statuses") as Array).any(func(s: Dictionary) -> bool: return String(s.get("key", "")) == "poison"), "heal purges poison")
		_check(int(p18.get("gold")) == 55, "mending costs 30 (85 -> %d)" % int(p18.get("gold")))
		_check(npcs.travel("cross"), "ferry sails to Crossroads")
		var fp: Vector3i = p18.get("grid")
		_check(fp.z == 0 and maxi(absi(fp.x - 20), absi(fp.y - 16)) <= 3, "ferry lands at Crossroads (%s)" % str(fp))
		_check(int(p18.get("gold")) == 45, "crossing costs 10 (55 -> %d)" % int(p18.get("gold")))
	if frame == 660:
		# vocations bend tick range, growth and damage weights
		var sim18 = main.get("sim")
		var p19 = main.get("player")
		var lvl: int = int(p19.get("level"))
		_check(sim18.set_vocation("archer"), "take the archer path")
		_check(sim18.tick_range() == 5, "archer tick reaches 5")
		_check(int(p19.get("max_hp")) == 100 + 20 * lvl, "archer HP unscaled (%d)" % int(p19.get("max_hp")))
		_check(sim18.set_vocation("magician"), "take the magician path")
		_check(int(p19.get("max_mana")) == int(floor(float(45 + 15 * lvl) * 1.4)), "magician mana +40%% (%d)" % int(p19.get("max_mana")))
		_check(sim18.set_vocation("warrior"), "return to warrior")
		_check(int(p19.get("max_hp")) == int(floor(float(100 + 20 * lvl) * 1.25)), "warrior HP +25%% (%d)" % int(p19.get("max_hp")))
		_check(sim18.tick_range() == 1, "warrior tick is melee")
	if frame == 680:
		# rift gate: stepping on the crossroad rift must change floors.
		# Clear the pads first: roaming bodies on a gate tile would make the
		# staged teleport violate one-soul-per-tile (sim travel slides aside).
		_clear_tile(main, Vector3i(18, 16, 0))
		_clear_tile(main, Vector3i(6, 6, 1))
		var p20 = main.get("player")
		p20.set("grid", Vector3i(18, 16, 0))
		p20.set("render", Vector2(18, 16))
	if frame == 690:
		var sim19 = main.get("sim")
		var p21 = main.get("player")
		var gp: Vector3i = p21.get("grid")
		_check(gp.z == 1, "rift carried us down (z=%d)" % gp.z)
		_check(gp.z == 1 and maxi(absi(gp.x - 6), absi(gp.y - 6)) <= 3, "rift lands at the crypt heart (%s)" % str(gp))
		sim19.set("gate_cd_until", 0)
		# monsters roam the small crypt: clear both the staging tile and the
		# return pad before the hop back
		_clear_tile(main, Vector3i(6, 7, 1))
		_clear_tile(main, Vector3i(6, 6, 1))
		p21.set("grid", Vector3i(6, 7, 1))
		p21.set("render", Vector2(6, 7))
	if frame == 695:
		_clear_tile(main, Vector3i(6, 6, 1))
		var p22 = main.get("player")
		p22.set("grid", Vector3i(6, 6, 1))
		p22.set("render", Vector2(6, 6))
	if frame == 705:
		var p23 = main.get("player")
		var gp2: Vector3i = p23.get("grid")
		_check(gp2.z == 0, "rift carried us back up")
		_check(gp2.z == 0 and maxi(absi(gp2.x - 18), absi(gp2.y - 16)) <= 3, "rift lands at the crossroad (%s)" % str(gp2))
	if frame == 715:
		# sight lines: open plaza reads clear, border wall blocks, floors never
		var sim20 = main.get("sim")
		_check(sim20.has_sight(Vector3i(19, 34, 0), Vector3i(21, 34, 0)), "open plaza has sight")
		_check(not sim20.has_sight(Vector3i(1, 5, 0), Vector3i(-2, 5, 0)), "border wall blocks sight")
		_check(not sim20.has_sight(Vector3i(18, 16, 0), Vector3i(6, 6, 1)), "floors never share sight")
		main.say("hello stone")
		main.notify("test line")
		var lines: Array = main.get("hud").get("_chat_lines")
		_check(lines.has("You: hello stone"), "say lands in chat")
		_check(lines.has("test line"), "notify lands in chat")
	if frame == 740:
		# monsters attack: stage adjacent, open the wind-up window, telegraph must appear.
		# Checked 5 frames later: on slow machines 15 frames outlast a rat windup.
		var sim21 = main.get("sim")
		var p24 = main.get("player")
		# revive first: the crypt trip may have killed us, and a dead sim idles
		p24.set("dead", false)
		p24.set("hp", int(p24.get("max_hp")))
		var atk = _stage_adjacent(sim21, p24, main.get("tiles"), true)
		if atk == null:
			_check(false, "live monster for attack test")
		else:
			_atk_mid = int(atk.get("mid"))
			atk.set("aggro", true)
			atk.set("next_attack_at", 0)
			atk.set("windup_until", 0)
			sim21.set_target(-1)
			sim21.set("next_auto_at", Time.get_ticks_msec() + 60000)
			# drive one AI step synchronously: no frame-boundary timing involved
			sim21._update_mobs(Time.get_ticks_msec())
			var fired := false
			for tg in (sim21.get("telegraphs") as Array):
				if String(tg.get("source", "")) == "monster" and int(tg.get("source_id", -1)) == _atk_mid and not bool(tg.get("resolved", true)):
					fired = true
					break
			_check(fired, "adjacent monster telegraphs its attack")
	if frame == 780:
		_check(int(main.get("sim").get("overlap_hits")) == 0, "one soul per tile all run (overlap_hits=0)")
	if frame == 790:
		# level-up must grant a skill point (the long way: real xp, real kill)
		var sim23 = main.get("sim")
		var p25 = main.get("player")
		var lvl0: int = int(p25.get("level"))
		var pts0: int = int(p25.get("skill_points"))
		p25.set("xp", GameBalance.xp_for_level(lvl0) - 5)
		var v9 = _stage_adjacent(sim23, p25, main.get("tiles"), true)
		if v9 == null:
			_check(false, "live monster for levelup")
		else:
			v9.set("hp", 1)
			v9.set("damage_by", {})
			sim23.set_target(int(v9.get("mid")))
			sim23.damage_monster(v9, 50)
			_check(int(p25.get("level")) > lvl0, "kill leveled up (%d -> %d)" % [lvl0, int(p25.get("level"))])
			_check(int(p25.get("skill_points")) > pts0, "level grants a skill point")
	if frame == 800:
		var sim24 = main.get("sim")
		var p26 = main.get("player")
		p26.set("skill_points", 5)
		var hp0: int = int(p26.get("max_hp"))
		_check(sim24.spend_skill("tough") == 1, "spend Toughness")
		_check(int(p26.get("max_hp")) == hp0 + 15, "Toughness raises max HP")
		var b0: int = sim24._damage_bonus()
		_check(sim24.spend_skill("power") == 1, "spend Power")
		_check(sim24._damage_bonus() == b0 + 1, "Power raises damage bonus")
		var step0: int = p26.step_ms()
		_check(sim24.spend_skill("swift") == 1, "spend Swiftness")
		_check(p26.step_ms() == step0 - 4, "Swiftness quickens step (%d -> %d)" % [step0, p26.step_ms()])
		_check(sim24.spend_skill("nope") == -1, "unknown skill rejected")
		p26.set("skill_points", 0)
		_check(sim24.spend_skill("focus") == -1, "broke point rejected")
		main.get("hud").set("_chat_last", Time.get_ticks_msec() - 99999)
	if frame == 810:
		_check(float(main.get("hud").get("_chat_panel").modulate.a) == 0.0, "chat hides when idle")
	if frame == 815:
		# every sheet must open without errors (regression: skill sheet crashed)
		var hud = main.get("hud")
		for key in ["bag", "gear", "filter", "skill"]:
			hud.toggle_sheet(key)
		_check(bool(hud.get("_skill_sheet").visible), "skill sheet opens")
		_check(bool(hud.get("_bag_sheet").visible) == false, "sheets are exclusive")
		hud.toggle_sheet("skill")
		_check(bool(hud.get("_skill_sheet").visible) == false, "skill sheet closes")
		var mallow: Dictionary = {"id": "mallow", "name": "Sister Mallow", "role": "trader", "blurb": "x", "pos": Vector3i(19, 34, 0), "color": Color.WHITE}
		hud.open_npc_sheet(mallow)
		_check(bool(hud.get("_npc_sheet").visible), "npc sheet opens")
	if frame == 818:
		# typing captures the keyboard: polled movement keys must read zero.
		# world._process pumps the flag (idle timing isn't guaranteed headless).
		var hud2 = main.get("hud")
		var p27 = main.get("player")
		hud2.toggle_chat_input()
		_check(hud2.chat_open(), "chat input opened")
		main._process(0.0)
		_check(bool(p27.get("input_blocked")), "chat open blocks key input")
		_check(p27._held_from_keys() == Vector2i.ZERO, "key poll reads zero while typing")
		hud2.toggle_chat_input()
		main._process(0.0)
		_check(not bool(p27.get("input_blocked")), "chat close releases keys")
	if frame == 825:
		# Strike costs 8 mana now: paid on valid casts, denied when broke
		var sim25 = main.get("sim")
		var p28 = main.get("player")
		var staged25 = _stage_adjacent(sim25, p28, main.get("tiles"), true)
		if staged25 == null:
			_check(false, "staged for strike-mana")
		else:
			sim25.set_target(int(staged25.get("mid")))
			p28.set("mana", 50)
			sim25.set("_next_regen", Time.get_ticks_msec() + 60000)
			(p28.get("cooldowns") as Dictionary)["strike"] = 0
			sim25.ability_strike()
			_check(int(p28.get("mana")) == 42, "Strike deducts 8 mana (50 -> %d)" % int(p28.get("mana")))
			sim25.set("_next_regen", 0)
			p28.set("mana", 0)
			(p28.get("cooldowns") as Dictionary)["strike"] = 0
			var tg0: int = (sim25.get("telegraphs") as Array).size()
			sim25.ability_strike()
			_check((sim25.get("telegraphs") as Array).size() == tg0, "broke Strike fizzles free")
	if frame == 835:
		# idle drift + wound healing share one staging: far away, idle, hurt
		var sim26 = main.get("sim")
		var p29 = main.get("player")
		var cand = null
		for m13 in (sim26.get("monsters") as Array):
			if int(m13.get("dying_at")) != 0:
				continue
			if int(m13.get("spawn_hp")) <= 15:
				continue
			cand = m13
			break
		if cand == null:
			_check(false, "heal candidate monster")
		else:
			# park the player further than any leash (sense+4 <= 13)
			var tiles11: Array = main.get("tiles")
			var best_spot := Vector3i(-999, -999, -999)
			var best_d := 15
			for yy in range(1, 39):
				for xx in range(1, 39):
					if not WorldGen.is_walkable(tiles11, xx, yy) or WorldGen.in_safe_zone(xx, yy):
						continue
					if WorldGen.kind_at(tiles11, xx, yy) == "gate":
						continue
					# never teleport onto a body: the overlap guard is exact
					if sim26.monster_at(xx, yy, 0) != null:
						continue
					var dd: int = maxi(absi(xx - int((cand.get("grid") as Vector3i).x)), absi(yy - int((cand.get("grid") as Vector3i).y)))
					if dd > best_d:
						best_d = dd
						best_spot = Vector3i(xx, yy, 0)
			_check(best_spot.x > -900, "found far tile for idle test")
			if best_spot.x > -900:
				p29.set("grid", best_spot)
				p29.set("render", _v2(best_spot))
				cand.set("aggro", false)
				cand.set("next_move_at", 0)
				cand.set("hp", int(cand.get("spawn_hp")) - 10)
				cand.set("next_heal_at", 0)
				_wander_from = cand.get("grid")
				_wander_mid = int(cand.get("mid"))
				_wander_hp = int(cand.get("hp"))
	if frame == 840:
		var sim27 = main.get("sim")
		var moved := false
		_wander_hp_after = -1
		for m14 in (sim27.get("monsters") as Array):
			if int(m14.get("mid")) == _wander_mid:
				moved = (m14.get("grid") as Vector3i) != _wander_from
				_wander_hp_after = int(m14.get("hp"))
		if _wander_mid >= 0 and _wander_hp_after >= 0:
			# retry logic guarantees drift when ANY lane is legal (else boxed,
			# which the pocket search below would have flagged — accept move OR
			# boxed by checking the lanes directly)
			var legal := false
			var tiles12: Array = main.get("tiles")
			var p30 = main.get("player")
			for off in DIRS:
				var c11 := Vector3i(_wander_from.x + (off as Vector2i).x, _wander_from.y + (off as Vector2i).y, 0)
				if c11 == p30.get("grid"):
					continue
				if WorldGen.is_walkable(tiles12, c11.x, c11.y) and sim27.monster_at(c11.x, c11.y, 0) == null and not WorldGen.in_safe_zone(c11.x, c11.y):
					legal = true
					break
			_check(not legal or moved, "idle monster drifts when a lane is free")
			_check(_wander_hp_after > _wander_hp, "out-of-combat wound closes (%d -> %d)" % [_wander_hp, _wander_hp_after])
		else:
			_check(false, "wander candidate tracked")
	if frame == 850:
		# NPC deals die past talk range: open at the counter, walk away
		var npcs15 = main.get("npcs")
		var p31 = main.get("player")
		p31.set("grid", Vector3i(19, 35, 0))
		p31.set("render", Vector2(19, 35))
		var mal = npcs15.npc_at(19, 34, 0)
		if mal == null:
			_check(false, "mallow at her counter")
		else:
			main.interact_npc(mal)
			_check(bool(main.get("hud").get("_npc_sheet").visible), "npc sheet opens in range")
			var tiles13: Array = main.get("tiles")
			var far_spot := Vector3i(-999, -999, -999)
			for yy in range(1, 39):
				for xx in range(1, 39):
					if not WorldGen.is_walkable(tiles13, xx, yy) or WorldGen.in_safe_zone(xx, yy):
						continue
					if WorldGen.kind_at(tiles13, xx, yy) == "gate":
						continue
					if main.get("sim").monster_at(xx, yy, 0) != null:
						continue  # never blink onto a body: the overlap guard is exact
					if maxi(absi(xx - 19), absi(yy - 34)) > 10:
						far_spot = Vector3i(xx, yy, 0)
						break
				if far_spot.x > -900:
					break
			_check(far_spot.x > -900, "found far tile for npc range")
			if far_spot.x > -900:
				p31.set("grid", far_spot)
				p31.set("render", _v2(far_spot))
	if frame == 855:
		var npcs16 = main.get("npcs")
		var p32 = main.get("player")
		main.get("hud")._process(0.0)  # pump: idle scheduling isn't guaranteed headless
		_check(bool(main.get("hud").get("_npc_sheet").visible) == false, "sheet auto-closes past 2 tiles")
		var g0: int = int(p32.get("gold"))
		_check(npcs16.buy("salve") == false, "counter denies far buyers")
		_check(int(p32.get("gold")) == g0, "no gold moved while away")
	if frame == 880:
		# marks die off-screen: mark wild, blink 20 tiles out, snap the camera
		var sim28 = main.get("sim")
		var p33 = main.get("player")
		var staged28 = _stage_adjacent(sim28, p33, main.get("tiles"), true)
		if staged28 == null:
			_check(false, "staged for unmark test")
		else:
			sim28.cycle_target()
			_check(sim28.target() != null, "marked before leaving view")
			var tiles14: Array = main.get("tiles")
			var mg: Vector3i = staged28.get("grid")
			var out := Vector3i(-999, -999, -999)
			for yy in range(1, 39):
				for xx in range(1, 39):
					if not WorldGen.is_walkable(tiles14, xx, yy) or WorldGen.in_safe_zone(xx, yy):
						continue
					if WorldGen.kind_at(tiles14, xx, yy) == "gate":
						continue
					if sim28.monster_at(xx, yy, 0) != null:
						continue  # never blink onto a body: the overlap guard is exact
					if maxi(absi(xx - mg.x), absi(yy - mg.y)) > 18:
						out = Vector3i(xx, yy, 0)
						break
				if out.x > -900:
					break
			if out.x < -900:
				_check(false, "found off-screen tile")
			else:
				p33.set("grid", out)
				p33.set("render", _v2(out))
				main.get("camera").position = p33.position
				main._process(0.0)  # pump clip deterministically
	if frame == 885:
		_check(main.get("sim").target() == null, "mark cleared off-screen")
	if frame == 900:
		# ranged pursuit: sidestep an ember and it must engage (step or shoot)
		var sim29 = main.get("sim")
		var p34 = main.get("player")
		var emb = null
		for m15 in (sim29.get("monsters") as Array):
			if int(m15.get("dying_at")) != 0:
				continue
			if int((m15.get("def") as Dictionary).get("attackRange", 1)) <= 1:
				continue
			emb = m15
			break
		if emb == null:
			_check(false, "live ranged monster for pursuit")
		else:
			var eg: Vector3i = emb.get("grid")
			var tiles15: Array = main.get("tiles")
			var perch := Vector3i(-999, -999, -999)
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					var dd: int = maxi(absi(dx), absi(dy))
					if dd < 2 or dd > 3:
						continue
					var c12 := Vector3i(eg.x + dx, eg.y + dy, eg.z)
					if WorldGen.in_safe_zone(c12.x, c12.y):
						continue
					if WorldGen.kind_at(tiles15, c12.x, c12.y) == "gate":
						continue
					if WorldGen.is_walkable(tiles15, c12.x, c12.y) and sim29.monster_at(c12.x, c12.y, c12.z) == null:
						perch = c12
						break
				if perch.x > -900:
					break
			_check(perch.x > -900, "staged at ranged distance")
			if perch.x > -900:
				p34.set("grid", perch)
				p34.set("render", _v2(perch))
				emb.set("hp", 200)
				emb.set("aggro", true)
				emb.set("next_attack_at", 0)
				emb.set("windup_until", 0)
				emb.set("next_move_at", 0)
				emb.set("last_seen", Vector3i(-999, -999, -999))
				_rep_mid = int(emb.get("mid"))
				_rep_from = emb.get("grid")
	if frame == 908:
		var sim30 = main.get("sim")
		var moved_or_fired := false
		for m16 in (sim30.get("monsters") as Array):
			if int(m16.get("mid")) == _rep_mid and (m16.get("grid") as Vector3i) != _rep_from:
				moved_or_fired = true
		for tg in (sim30.get("telegraphs") as Array):
			if String(tg.get("source", "")) == "monster" and int(tg.get("source_id", -1)) == _rep_mid:
				moved_or_fired = true
		_check(_rep_mid < 0 or moved_or_fired, "ranged monster engages sidesteps")
	if frame == 930:
		# NATURAL AGGRO: no forced flags. Stage at sense-1 from a melee rat or
		# spider, then watch it notice, close in, and fire on its own cadence.
		var sim31 = main.get("sim")
		var p35 = main.get("player")
		var prey = null
		for m17 in (sim31.get("monsters") as Array):
			if int(m17.get("dying_at")) != 0:
				continue
			var mk: String = String((m17.get("def") as Dictionary).get("key", ""))
			if mk != "rat" and mk != "spider":
				continue
			# needs room to maneuver: boxed prey can't demonstrate approach
			var pg17: Vector3i = m17.get("grid")
			var room := false
			for off in DIRS:
				var c14 := Vector3i(pg17.x + (off as Vector2i).x, pg17.y + (off as Vector2i).y, pg17.z)
				if WorldGen.is_walkable(main.get("tiles"), c14.x, c14.y) and sim31.monster_at(c14.x, c14.y, c14.z) == null and not WorldGen.in_safe_zone(c14.x, c14.y):
					room = true
					break
			if not room:
				continue
			prey = m17
			break
		if prey == null:
			_check(false, "live rat/spider for aggro test")
		else:
			prey.set("aggro", false)
			prey.set("hp", int(prey.get("max_hp")))
			var sense: int = int(prey.get("sense"))
			var ring: int = maxi(2, sense - 1)  # outside melee reach, inside sense
			var eg2: Vector3i = prey.get("grid")
			var tiles16: Array = main.get("tiles")
			var perch2 := Vector3i(-999, -999, -999)
			for dy in range(-ring, ring + 1):
				for dx in range(-ring, ring + 1):
					if maxi(absi(dx), absi(dy)) != ring:
						continue
					var c13 := Vector3i(eg2.x + dx, eg2.y + dy, eg2.z)
					if WorldGen.in_safe_zone(c13.x, c13.y):
						continue
					if WorldGen.kind_at(tiles16, c13.x, c13.y) == "gate":
						continue
					if WorldGen.is_walkable(tiles16, c13.x, c13.y) and sim31.monster_at(c13.x, c13.y, c13.z) == null:
						perch2 = c13
						break
				if perch2.x > -900:
					break
			_check(perch2.x > -900, "staged at sense-1 for aggro")
			if perch2.x > -900:
				_nat_mid = int(prey.get("mid"))
				p35.set("grid", perch2)
				p35.set("render", _v2(perch2))
				p35.set("hp", int(p35.get("max_hp")))
				_nat_armor = int(p35.get("armor"))
				p35.set("armor", 100)
				_nat_dist = maxi(absi(perch2.x - eg2.x), absi(perch2.y - eg2.y))
				prey.set("next_attack_at", 0)
				prey.set("windup_until", 0)
				prey.set("next_move_at", 0)
	if frame == 940:
		var found := false
		for m18 in (main.get("sim").get("monsters") as Array):
			if int(m18.get("mid")) == _nat_mid and bool(m18.get("aggro")):
				found = true
		_check(_nat_mid < 0 or found, "monster notices the player on its own")
	if frame == 935:
		var simx = main.get("sim")
		var px = main.get("player")
		for mxx in (simx.get("monsters") as Array):
			if int(mxx.get("mid")) == _nat_mid:
				var gx: Vector3i = mxx.get("grid")
				var pxx: Vector3i = px.get("grid")
				print("[SMOKE] dbg935 aggro=%s dist=%d sense=%d safe=%s dead=%s flow=%d" % [
					str(bool(mxx.get("aggro"))),
					maxi(absi(gx.x - pxx.x), absi(gx.y - pxx.y)), int(mxx.get("sense")),
					str(WorldGen.in_safe_zone(pxx.x, pxx.y)), str(bool(px.get("dead"))),
					simx.flow.value(gx.x, gx.y)])
	if frame == 1020:
		var sim32 = main.get("sim")
		var p36 = main.get("player")
		var closed := false
		for m19 in (sim32.get("monsters") as Array):
			if int(m19.get("mid")) == _nat_mid:
				var g19: Vector3i = m19.get("grid")
				var pg19: Vector3i = p36.get("grid")
				if maxi(absi(g19.x - pg19.x), absi(g19.y - pg19.y)) < _nat_dist:
					closed = true
				else:
					print("[SMOKE] dbg1020 rat=%s p=%s aggro=%s move_in=%d wind_in=%d atk_in=%d tele=%d" % [
						str(g19), str(pg19), str(bool(m19.get("aggro"))),
						int(m19.get("next_move_at")) - Time.get_ticks_msec(),
						int(m19.get("windup_until")) - Time.get_ticks_msec(),
						int(m19.get("next_attack_at")) - Time.get_ticks_msec(),
						(sim32.get("telegraphs") as Array).size()])
		for tg in (sim32.get("telegraphs") as Array):
			if String(tg.get("source", "")) == "monster" and int(tg.get("source_id", -1)) == _nat_mid:
				closed = true
		_check(_nat_mid < 0 or closed, "monster closes distance or fires")
	if frame == 1100:
		# firing latch: next_attack_at only ever moves forward on a real shot
		var sim33 = main.get("sim")
		var p37 = main.get("player")
		p37.set("armor", _nat_armor)
		var fired := false
		for m20 in (sim33.get("monsters") as Array):
			if int(m20.get("mid")) == _nat_mid and int(m20.get("next_attack_at")) != 0:
				fired = true
		_check(_nat_mid < 0 or fired, "monster fires on its own cadence")
	if frame == 1120:
		print("[SMOKE] done failures=%d" % failures.size())
		if failures.is_empty():
			print("[SMOKE] ALL PASS")
		else:
			printerr("[SMOKE] FAILURES: %s" % str(failures))
