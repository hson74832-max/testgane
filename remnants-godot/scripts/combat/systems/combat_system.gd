extends RefCounted
## CombatSystem — damage + abilities + shove.
## Extracted from CombatSim. One cast pipeline, data-dispatched by def.shape
## (see content.ts AbilityDef): adjacent = single marked tile (Strike),
## radial = 8 around you (Cleave), line = projectile + delayed resolve (Bolt),
## self = instant buff (Ward). A new spell = a new content row. New SHAPES
## need one executor here. Damage school follows shape: adjacent swings steel
## (melee_mult), radial/line channel spells (spell_mult).
## Also owns damage application (monster + player), death + kill credit,
## status dots, auto-attack ticks, telegraph resolution and the shove kit.

const Vocations := preload("res://scripts/combat/vocations.gd")

var sim  # CombatSim — wired by the sim at construction (untyped: no preload cycle)

## Shove destination preview: {from:Vector3i, to:Vector3i, valid:bool}.
## CombatSim forwards it as `push_preview` for SimDraw.
var push_preview: Dictionary = {}

# ---------------------------------------------------------------- abilities
func cast_ability(key: String) -> void:
	var player: Node2D = sim.player
	if player == null or bool(player.get("dead")):
		return
	var def: Dictionary = _ability_def(key)
	if def.is_empty():
		return
	var shape: String = String(def.get("shape", "adjacent"))
	if shape != "self" and sim.is_player_pacified():
		sim._deny_pacified()
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
			sim.add_float("unshaped", sim._v(player.grid), Color(0.58, 0.64, 0.72), false)

func _need_target(def: Dictionary):
	var player: Node2D = sim.player
	var tgt = sim.target()
	if tgt == null:
		sim.add_float("nothing marked", sim._v(player.grid), Color(0.58, 0.64, 0.72), false)
		return null
	var d: int = maxi(absi(tgt.grid.x - player.grid.x), absi(tgt.grid.y - player.grid.y))
	if d > int(def.get("range", 1)):
		sim.add_float("too far", sim._v(player.grid), Color(0.58, 0.64, 0.72), false)
		return null
	return tgt

func _face(tgt) -> void:
	var player: Node2D = sim.player
	player.set("facing", Vector2i(sim.signi(tgt.grid.x - player.grid.x), sim.signi(tgt.grid.y - player.grid.y)))

func _melee_damage(base: int) -> int:
	var player: Node2D = sim.player
	var bonus: int = int(GameBalance.stats_for_level(int(player.get("level")))["damageBonus"]) + int(player.get("weapon_damage"))
	return maxi(1, int(round(float(base + bonus) * float((Vocations.def(sim.vocation) as Dictionary).get("melee_mult", 1.0)))))

func _exec_single(def: Dictionary) -> void:
	var player: Node2D = sim.player
	var now: int = Time.get_ticks_msec()
	if now < int((player.get("cooldowns") as Dictionary).get(String(def.get("key", "")), 0)):
		return
	var tgt = _need_target(def)
	if tgt == null:
		return
	# validated first so fizzles never charge; _pay re-checks and spends.
	if int(player.get("mana")) < int(def.get("manaCost", 0)):
		sim.add_float("no mana", sim._v(player.grid), Color(0.49, 0.83, 0.99), false)
		sim.toast.emit("Not enough mana", "bad")
		return
	if not bool(_pay_ability(String(def.get("key", ""))).get("ok", false)):
		return
	_face(tgt)
	player.set("cast_until", now + int(def.get("windup", 260)))
	sim.telegraphs.append({
		"id": sim._nid(), "tiles": [tgt.grid], "start_at": now, "resolve_at": now + int(def.get("windup", 260)),
		"color": Color.html(String(def.get("color", "#ffd166"))), "damage": _melee_damage(int(def.get("damage", 14))),
		"z": int(player.grid.z), "source": "player", "source_id": tgt.mid, "status": "", "resolved": false,
	})
	sim.queue_redraw()

func _exec_radial(def: Dictionary) -> void:
	var player: Node2D = sim.player
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
	sim.telegraphs.append({
		"id": sim._nid(), "tiles": tiles8, "start_at": now, "resolve_at": now + int(def.get("windup", 420)),
		"color": Color.html(String(def.get("color", "#ef476f"))), "damage": _spell_damage(int(def.get("damage", 19))),
		"z": int(player.grid.z), "source": "player", "source_id": 0, "status": "", "resolved": false,
	})
	sim.queue_redraw()

func _exec_beam(def: Dictionary) -> void:
	var player: Node2D = sim.player
	var tgt = _need_target(def)
	if tgt == null:
		return
	if not sim.has_sight(player.grid, tgt.grid):
		sim.add_float("blocked", sim._v(player.grid), Color(0.58, 0.64, 0.72), false)
		return
	var r: Dictionary = _pay_ability(String(def.get("key", "")))
	if not bool(r.get("ok", false)):
		return
	var now: int = Time.get_ticks_msec()
	_face(tgt)
	player.set("cast_until", now + int(def.get("windup", 340)))
	sim.projectiles.append({
		"fx": player.grid.x, "fy": player.grid.y, "tx": tgt.grid.x, "ty": tgt.grid.y,
		"z": int(player.grid.z),
		"born": now, "duration": int(def.get("windup", 340)) + 120, "color": Color.html(String(def.get("color", "#4cc9f0"))),
	})
	sim.telegraphs.append({
		"id": sim._nid(), "tiles": [tgt.grid], "start_at": now, "resolve_at": now + int(def.get("windup", 340)) + 120,
		"color": Color.html(String(def.get("color", "#4cc9f0"))), "damage": _spell_damage(int(def.get("damage", 26))),
		"z": int(player.grid.z), "source": "player", "source_id": tgt.mid, "status": "", "resolved": false,
	})
	sim.queue_redraw()

func _exec_self(def: Dictionary) -> void:
	var player: Node2D = sim.player
	var r: Dictionary = _pay_ability(String(def.get("key", "")))
	if not bool(r.get("ok", false)):
		return
	var now: int = Time.get_ticks_msec()
	var amount: int = int(GameBalance.COMBAT.get("WARD_BASE", 45)) + int(player.get("level")) * int(GameBalance.COMBAT.get("WARD_PER_LEVEL", 5)) + _skill_bonus("ward")
	player.set("ward_hp", amount)
	var sts: Array = player.get("statuses")
	sts.assign(sts.filter(func(s): return String(s.get("key", "")) != "ward"))
	sts.append({"key": "ward", "until": now + int(GameBalance.COMBAT.get("WARD_MS", 6000)), "next_tick": 0, "power": amount})
	sim.add_float("WARD", sim._v(player.grid), Color(0.02, 0.84, 0.63), false)
	sim.queue_redraw()

func _ability_def(key: String) -> Dictionary:
	for a in (GameBalance.ABILITIES as Array):
		if String(a.get("key", "")) == key:
			return a
	return {}

func ability_cooldown_pct(key: String) -> float:
	var player: Node2D = sim.player
	var def: Dictionary = _ability_def(key)
	if def.is_empty():
		return 0.0
	var left: int = int((player.get("cooldowns") as Dictionary).get(key, 0)) - Time.get_ticks_msec()
	if left <= 0:
		return 0.0
	return float(left) / float(maxi(1, int(def.get("cooldown", 1))))

func strike_cooldown_pct() -> float:
	var player: Node2D = sim.player
	var cd: int = int(_ability_def("strike").get("cooldown", 850))
	var ready: int = int((player.get("cooldowns") as Dictionary).get("strike", 0))
	var left: int = ready - Time.get_ticks_msec()
	if left <= 0:
		return 0.0
	return float(left) / float(cd)

func _pay_ability(key: String) -> Dictionary:
	# Returns {ok, def} — checks dead/CD/mana like engine.ts castAbility.
	var player: Node2D = sim.player
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
		sim.add_float("no mana", sim._v(player.grid), Color(0.49, 0.83, 0.99), false)
		sim.toast.emit("Not enough mana", "bad")
		return out
	player.set("mana", int(player.get("mana")) - int(def.get("manaCost", 0)))
	(player.get("cooldowns") as Dictionary)[key] = now + int(def.get("cooldown", 0))
	sim.next_auto_at = now + GameBalance.auto_attack_ms()
	out["ok"] = true
	out["def"] = def
	return out

# ---------------------------------------------------------------- damage math
func _damage_bonus() -> int:
	var player: Node2D = sim.player
	return int(GameBalance.stats_for_level(int(player.get("level")))["damageBonus"]) + int(player.get("weapon_damage")) + _skill_bonus("damage")

## Spell damage for the magician path (Cleave/Bolt scale 35% up, steel down).
func _spell_damage(base: int) -> int:
	return maxi(1, int(round(float(base + _damage_bonus()) * float((Vocations.def(sim.vocation) as Dictionary).get("spell_mult", 1.0)))))

func _skill_rank(key: String) -> int:
	return int((sim.player.get("skills") as Dictionary).get(key, 0))

## Summed per-rank skill payload, data-driven (content.json skills.*.effect).
## Understood keys: maxHp, maxMana, stepMs (reduction), damage, ward.
func _skill_bonus(key: String) -> int:
	var total := 0
	var ranks: Dictionary = sim.player.get("skills")
	for k in ranks.keys():
		var eff: Dictionary = GameBalance.skill_def(String(k)).get("effect", {})
		total += int(eff.get(key, 0)) * int(ranks[k])
	return total

## Vocation-scaled growth. announce=false at boot (world already toasted).
func apply_vocation_stats(keep_current: bool) -> void:
	var player: Node2D = sim.player
	var base: Dictionary = GameBalance.stats_for_level(int(player.get("level")))
	var v: Dictionary = Vocations.def(sim.vocation)
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
	return int((Vocations.def(sim.vocation) as Dictionary).get("tick_range", 1))

# ---------------------------------------------------------------- auto attack
## Auto tick on the marked target (held while pacified: Sanctuary never deals
## damage). next_auto_at / auto_attack live on the sim.
func try_auto_attack(now: int) -> void:
	var player: Node2D = sim.player
	var marked = sim.target()
	if marked == null or sim.is_player_pacified():
		sim.next_auto_at = now + GameBalance.auto_attack_ms()
	elif sim.auto_attack and now >= sim.next_auto_at:
		var reach: int = maxi(absi(marked.grid.x - player.grid.x), absi(marked.grid.y - player.grid.y))
		if reach <= tick_range():
			_auto_swing(marked)
			sim.next_auto_at = now + GameBalance.auto_attack_ms()
		else:
			sim.next_auto_at = now

func _auto_swing(m) -> void:
	var player: Node2D = sim.player
	var v: Dictionary = Vocations.def(sim.vocation)
	var lvl: int = int(player.get("level"))
	if bool(v.get("tick_shot", false)):
		# Archer: arrows fly the tick range but walls stop them. No steel bonus.
		if not sim.has_sight(player.grid, m.grid):
			sim.add_float("blocked", sim._v(player.grid) + Vector2(0, -0.55), Color(0.58, 0.64, 0.72), false)
			return
		sim.projectiles.append({
			"fx": player.grid.x, "fy": player.grid.y, "tx": m.grid.x, "ty": m.grid.y,
			"z": int(player.grid.z), "born": Time.get_ticks_msec(), "duration": 150,
			"color": Color(1.0, 0.95, 0.75),
		})
		damage_monster(m, int(v.get("tick_base", 4)) + int(floor(float(lvl) * float(v.get("tick_scale", 0.7)))) + _skill_bonus("damage"))
	else:
		var base: int = int(v.get("tick_base", 6)) + int(floor(float(lvl) * float(v.get("tick_scale", 0.9)))) + int(player.get("weapon_damage")) + _skill_bonus("damage")
		damage_monster(m, maxi(1, int(round(float(base) * float(v.get("melee_mult", 1.0))))))
	sim.add_float("tick", sim._v(player.grid) + Vector2(0, -0.55), Color(0.58, 0.64, 0.72), false)

# ---------------------------------------------------------------- damage
func damage_monster(m, amount: int) -> void:
	if m.dying_at != 0:
		return
	var now: int = Time.get_ticks_msec()
	var crit: bool = randf() < float(GameBalance.COMBAT.get("CRIT_CHANCE", 0.14))
	var dmg: int = maxi(1, int(round((float(amount) * float(GameBalance.COMBAT.get("CRIT_MULT", 1.85))) if crit else float(amount))))
	m.hp -= dmg
	m.hit_flash_until = now + 160
	m.aggro = true
	m.damage_by[sim.player_name] = int(m.damage_by.get(sim.player_name, 0)) + dmg
	sim.add_float(("%d!" % dmg) if crit else str(dmg), sim._v(m.grid), Color(1.0, 0.82, 0.4) if crit else Color.WHITE, crit)
	if m.hp <= 0:
		kill_monster(m)
	sim.queue_redraw()

func _claimant(m) -> String:
	var best: String = sim.player_name
	var best_val := -1
	for k in m.damage_by.keys():
		if int(m.damage_by[k]) > best_val:
			best = String(k)
			best_val = int(m.damage_by[k])
	return best

func kill_monster(m) -> void:
	var player: Node2D = sim.player
	var now: int = Time.get_ticks_msec()
	m.dying_at = now
	player.set("kills", int(player.get("kills")) + 1)
	var xp: int = int(m.def.get("xp", 10)) + randi() % 4
	player.set("xp", int(player.get("xp")) + xp)
	sim.add_float("+%d xp" % xp, sim._v(m.grid) + Vector2(0, -0.4), Color(0.64, 0.9, 0.21), false)
	var owner: String = _claimant(m)
	sim.loot.drop_loot(m, owner, now)
	if owner != sim.player_name:
		sim.add_float("claimed by " + owner, sim._v(m.grid) + Vector2(0, -0.75), Color(0.97, 0.44, 0.44), false)
	sim.mob_killed.emit(String(m.def.get("name", "?")))
	var new_level: int = GameBalance.level_from_xp(int(player.get("xp")))
	if new_level > int(player.get("level")):
		player.set("skill_points", int(player.get("skill_points")) + (new_level - int(player.get("level"))))
		player.set("level", new_level)
		apply_vocation_stats(false)
		sim.add_float("LEVEL UP", sim._v(player.grid) + Vector2(0, -0.6), Color(1.0, 0.82, 0.4), true)
		sim.leveled_up.emit(new_level)
	if sim.target_id == m.mid:
		sim.target_id = -1

func damage_player(amount: int, source: String, status: String = "") -> void:
	var player: Node2D = sim.player
	if bool(player.get("dead")):
		return
	var now: int = Time.get_ticks_msec()
	if WorldGen.in_safe_zone(player.grid.x, player.grid.y):
		sim.add_float("PROTECTED", sim._v(player.grid) + Vector2(0, -0.4), Color(1.0, 0.82, 0.4), false)
		return
	var raw: int = amount
	var dmg: int = GameBalance.mitigate(raw, int(player.get("armor")))
	var blocked: int = raw - dmg
	if int(player.get("ward_hp")) > 0:
		var absorbed: int = mini(int(player.get("ward_hp")), dmg)
		player.set("ward_hp", int(player.get("ward_hp")) - absorbed)
		dmg -= absorbed
		sim.add_float("-%d" % absorbed, sim._v(player.grid) + Vector2(0, -0.3), Color(0.02, 0.84, 0.63), false)
		if int(player.get("ward_hp")) <= 0:
			(player.get("statuses") as Array).assign((player.get("statuses") as Array).filter(func(s): return String(s.get("key", "")) != "ward"))
	if dmg > 0:
		player.set("hp", int(player.get("hp")) - dmg)
		player.set("hit_flash_until", now + 220)
		sim.add_float(("%d (-%d)" % [dmg, blocked]) if blocked > 0 else str(dmg), sim._v(player.grid), Color(1.0, 0.35, 0.43), false)
	if status != "":
		var sts: Array = player.get("statuses")
		sts.assign(sts.filter(func(s): return String(s.get("key", "")) != status))
		var power: int = int(GameBalance.COMBAT.get("POISON_POWER", 4)) if status == "poison" else int(GameBalance.COMBAT.get("BURN_POWER", 6))
		sts.append({"key": status, "until": now + int(GameBalance.COMBAT.get("STATUS_MS", 6000)), "next_tick": now + int(GameBalance.COMBAT.get("STATUS_TICK_MS", 1500)), "power": power})
	if int(player.get("hp")) <= 0:
		kill_player(source)
	sim.queue_redraw()

func kill_player(source: String) -> void:
	var player: Node2D = sim.player
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
	# Loot protection: the dropped gold lands where you fell (LootSystem keeps
	# it locked to you for the standard claim window — get back in time and it
	# is yours again).
	if gold_dropped > 0:
		sim.loot.drop_gold_cache(player.grid, gold_dropped, now)
		sim.add_float("cache: %dg" % gold_dropped, sim._v(player.grid) + Vector2(0, 0.45), Color(0.98, 0.75, 0.14), false)
	sim.add_float("YOU DIED", sim._v(player.grid) + Vector2(0, -0.5), Color(1.0, 0.35, 0.43), true)
	sim.player_died.emit(source, xp_lost, gold_dropped)

## Status dots + expiry + ward cleanup, called from the sim's tick.
func process_statuses(now: int) -> void:
	var player: Node2D = sim.player
	var sts: Array = player.get("statuses")
	for s in sts.duplicate():
		if int(s.get("next_tick", 0)) > 0 and now >= int(s["next_tick"]) and now < int(s["until"]):
			s["next_tick"] = now + 1500
			damage_player(int(s["power"]), "Venom" if String(s["key"]) == "poison" else "Cinders")
	sts.assign(sts.filter(func(s): return now < int(s.get("until", 0))))
	player.set("slowed", sts.any(func(s): return String(s.get("key", "")) == "slow"))
	if not sts.any(func(s): return String(s.get("key", "")) == "ward"):
		player.set("ward_hp", 0)

## Resolve due telegraphs: monster hits, player Strikes/Bolts, Cleaves.
func resolve_telegraphs(now: int) -> void:
	var player: Node2D = sim.player
	for t in sim.telegraphs:
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
				for m in sim.monsters:
					if m.mid == int(t["source_id"]):
						src = m
				damage_player(int(t["damage"]), String(src.def["name"]) if src != null else "Something in the dark", String(t.get("status", "")))
			else:
				sim.add_float("dodged", sim._v(player.grid) + Vector2(0, -0.4), Color(0.58, 0.64, 0.72), false)
		elif int(t["source_id"]) != 0:
			var m = null
			for mm in sim.monsters:
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
					sim.add_float("miss", sim._v(m.grid), Color(0.58, 0.64, 0.72), false)
		else:
			# Cleave: source_id 0, radial around the player at cast time.
			for mm2 in sim.monsters:
				if mm2.dying_at != 0:
					continue
				for cell in (t["tiles"] as Array):
					if cell == mm2.grid:
						damage_monster(mm2, int(t["damage"]))
						break

# ---------------------------------------------------------------- shove
func can_push(m, tx: int, ty: int) -> Dictionary:
	var player: Node2D = sim.player
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
	if not WorldGen.is_walkable(sim.tiles, tx, ty):
		return {"ok": false, "reason": "Blocked"}
	if sim.monster_at(tx, ty) != null:
		return {"ok": false, "reason": "Occupied"}
	if sim.tile_blocker.is_valid() and bool(sim.tile_blocker.call(tx, ty)):
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
	sim.queue_redraw()

func clear_push_preview() -> void:
	push_preview = {}
	sim.queue_redraw()

func push(m, tx: int, ty: int) -> Dictionary:
	var player: Node2D = sim.player
	var v: Dictionary = can_push(m, tx, ty)
	var now: int = Time.get_ticks_msec()
	push_preview = {}
	if not bool(v.get("ok", false)):
		if String(v.get("reason", "")) != "":
			sim.add_float(String(v["reason"]), sim._v(m.grid), Color(0.58, 0.64, 0.72), false)
			sim.toast.emit(String(v["reason"]), "bad")
		sim.queue_redraw()
		return v
	m.grid = Vector3i(tx, ty, m.grid.z)
	m.aggro = true
	m.push_lock_until = now + 1200
	m.next_move_at = maxi(m.next_move_at, now + 350)
	if now < m.windup_until:
		m.windup_until = 0
		var kept: Array = []
		for t in sim.telegraphs:
			if not (String(t["source"]) == "monster" and int(t["source_id"]) == m.mid and not bool(t["resolved"])):
				kept.append(t)
		sim.telegraphs = kept
		sim.add_float("INTERRUPTED", Vector2(tx, ty) + Vector2(0, -0.4), Color(0.3, 0.79, 0.94), true)
	else:
		sim.add_float("shoved", Vector2(tx, ty) + Vector2(0, -0.3), Color(0.8, 0.84, 0.88), false)
	player.set("push_ready_at", now + int(GameBalance.COMBAT.get("PUSH_CD_MS", 2500)))
	sim.queue_redraw()
	return {"ok": true}

## Self-shove: drag from your own tile to hop one tile. Shares the shove
## cadence and cooldown, cannot bypass a drink/cast root, and never moves
## onto (or through) a creature or an NPC fixture.
func can_push_self(tx: int, ty: int) -> Dictionary:
	var player: Node2D = sim.player
	var now: int = Time.get_ticks_msec()
	if player == null or bool(player.get("dead")):
		return {"ok": false, "reason": "dead"}
	if now < int(player.get("push_ready_at")):
		return {"ok": false, "reason": "Shove recharging"}
	if now < int(player.get("cast_until")):
		return {"ok": false, "reason": "Rooted"}
	if maxi(absi(tx - player.grid.x), absi(ty - player.grid.y)) != 1 or (tx == player.grid.x and ty == player.grid.y):
		return {"ok": false, "reason": "Shove is exactly 1 tile"}
	if not WorldGen.is_walkable(sim.tiles, tx, ty):
		return {"ok": false, "reason": "Blocked"}
	if sim.monster_at(tx, ty) != null:
		return {"ok": false, "reason": "Occupied"}
	if sim._blocked(tx, ty):
		return {"ok": false, "reason": "Occupied"}
	return {"ok": true}

func preview_push_self(tx: int, ty: int) -> void:
	var player: Node2D = sim.player
	var v: Dictionary = can_push_self(tx, ty)
	push_preview = {"from": player.grid, "to": Vector3i(tx, ty, player.grid.z), "valid": bool(v.get("ok", false))}
	sim.queue_redraw()

func push_self(tx: int, ty: int) -> Dictionary:
	var player: Node2D = sim.player
	var v: Dictionary = can_push_self(tx, ty)
	push_preview = {}
	if not bool(v.get("ok", false)):
		if String(v.get("reason", "")) != "":
			sim.add_float(String(v["reason"]), sim._v(player.grid), Color(0.58, 0.64, 0.72), false)
			sim.toast.emit(String(v["reason"]), "bad")
		sim.queue_redraw()
		return v
	# grid change alone drives the hop: render lerps, and the grid-change hook
	# in the sim's tick handles auto-pickup + rift-gate travel for us.
	player.set("grid", Vector3i(tx, ty, player.grid.z))
	player.set("push_ready_at", Time.get_ticks_msec() + int(GameBalance.COMBAT.get("PUSH_CD_MS", 2500)))
	sim.add_float("shoved", sim._v(player.grid) + Vector2(0, -0.3), Color(0.8, 0.84, 0.88), false)
	sim.queue_redraw()
	return {"ok": true}
