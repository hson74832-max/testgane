# BlackTek combat: weapon/armor math, targeting, melee swings, monster
# attacks, damage floats and death. Stateless — fighters live on the server.
class_name BlackTekCombat
extends RefCounted

# Weapons/armor by client item id (cf. items.toml): sword 2376, wand 2190.
const WEAPON_ATK := {2376: 14, 2190: 10}
const ITEM_ARMOR := {2461: 1, 2463: 10, 2467: 4, 2511: 9, 2643: 1}

static func equipped_weapon(game, pid: int) -> int:
	var w: Dictionary = game.players[pid].inv.get(5) if game.players[pid].inv.get(5) != null else {} # CONST_SLOT_RIGHT = 5
	return int(w.get("itemtype", 0)) if not w.is_empty() else 0

static func total_armor(game, pid: int) -> int:
	var p: Dictionary = game.players[pid]
	var armor := 0
	for slot in [1, 4, 6, 7, 8]:
		var it: Dictionary = p.inv.get(slot) if p.inv.get(slot) != null else {}
		if not it.is_empty():
			armor += int(BlackTekCombat.ITEM_ARMOR.get(int(it.itemtype), 0))
	return armor

static func nearest_monster(game, pid: int, max_tiles := 1) -> Dictionary:
	var p: Dictionary = game.players[pid]
	var best := {}
	var best_d := max_tiles + 1
	for m in game.monsters.values():
		if int(m.z) != int(p.z):
			continue
		var d: int = maxi(absi(int(m.tile.x) - int(p.tile.x)), absi(int(m.tile.y) - int(p.tile.y)))
		if d < best_d:
			best_d = d
			best = m
	return best

# Space / right click: mark the nearest (or next) creature as target.
static func target_next(game, pid: int) -> void:
	var p: Dictionary = game.players[pid]
	var spec := BlackTekMonsters.archetype(game)
	var candidates: Array = []
	for m in game.monsters.values():
		if int(m.z) != int(p.z):
			continue
		var d: int = maxi(absi(int(m.tile.x) - int(p.tile.x)), absi(int(m.tile.y) - int(p.tile.y)))
		if d <= int(spec.get("range", 6)):
			candidates.append([d, int(m.id), m])
	candidates.sort()
	if candidates.is_empty():
		BlackTekCombat.set_target(game, pid, {})
		game.message_local(pid, "No monster nearby to target.")
		return
	for c in candidates: # cycle: first candidate that is not the current target
		if int(c[1]) != int(p.target):
			BlackTekCombat.set_target(game, pid, c[2])
			game.message_local(pid, "Target: %s." % String(c[2].name))
			return
	BlackTekCombat.set_target(game, pid, candidates[0][2])
	game.message_local(pid, "Target: %s." % String(candidates[0][2].name))

# Attack the current target when it is adjacent (hotbar slot / auto-attack).
static func attack_current_target(game, pid: int) -> void:
	var p: Dictionary = game.players[pid]
	p.path = []
	var m: Dictionary = game.monsters.get(int(p.target), {})
	if m.is_empty():
		game.message_local(pid, "You have no target. Right-click or press Space next to a creature.")
		return
	var d: int = maxi(absi(int(m.tile.x) - int(p.tile.x)), absi(int(m.tile.y) - int(p.tile.y)))
	if d > 1:
		game.message_local(pid, "%s is too far away. Step closer." % String(m.name))
		return
	BlackTekCombat.melee_swing(game, pid, m)

# One melee hit against m (damage roll, skill training, cooldown).
static func melee_swing(game, pid: int, m: Dictionary) -> void:
	var p: Dictionary = game.players[pid]
	var now := Time.get_ticks_msec() / 1000.0
	p.attack_cd = now + float(BlackTekGameServer.VOCATIONS[int(p.vocation)].attack_speed)
	BlackTekCombat.set_target(game, pid, m)
	var weapon := BlackTekCombat.equipped_weapon(game, pid)
	var dmg := 0
	if weapon == 2190: # wand of vortex: magic damage scaled by magic level
		dmg = randi_range(int(p.maglevel) + 2, 8 + int(p.maglevel) * 4)
	else:
		var skill := int(p.skills.get("sword", 10))
		var atk := int(BlackTekCombat.WEAPON_ATK.get(weapon, 3))
		dmg = randi_range(maxi(1, skill / 2), skill + atk / 2 + int(p.level) / 5)
		BlackTekPlayer.advance_skill(game, pid, "sword")
	BlackTekCombat.damage_monster(game, int(m.id), dmg, "melee", pid)

# Auto-attack tick: hit the marked target while it stands adjacent.
static func tick_auto_attack(game, pid: int, now: float) -> void:
	var p: Dictionary = game.players[pid]
	if int(p.target) != 0 and float(p.get("attack_cd", 0.0)) <= now:
		var tm: Dictionary = game.monsters.get(int(p.target), {})
		if not tm.is_empty() and int(tm.z) == int(p.z):
			var td: int = maxi(absi(int(tm.tile.x) - int(p.tile.x)), absi(int(tm.tile.y) - int(p.tile.y)))
			if td <= 1:
				BlackTekCombat.melee_swing(game, pid, tm)

static func set_target(game, pid: int, m: Dictionary) -> void:
	var tid := int(m.get("id", 0)) if not m.is_empty() else 0
	if int(game.players[pid].target) != tid:
		game.players[pid].target = tid
	game.target_changed.emit(pid, m)

static func damage_monster(game, mid: int, dmg: int, kind: String, from_pid: int) -> void:
	var m: Dictionary = game.monsters.get(mid, {})
	if m.is_empty():
		return
	m.hp = maxi(0, int(m.hp) - dmg)
	m.target_pid = from_pid
	game.damage_float.emit(m.tile, int(m.z), dmg, true)
	if int(m.hp) <= 0:
		BlackTekCombat.kill_monster(game, mid, from_pid)
	else:
		game.stats_changed.emit(from_pid) # refresh target frame hp
		game.target_changed.emit(from_pid, m)

static func kill_monster(game, mid: int, pid: int) -> void:
	var m: Dictionary = game.monsters.get(mid, {})
	if m.is_empty():
		return
	game.monsters.erase(mid)
	game.target_changed.emit(pid, {})
	var spec := BlackTekMonsters.archetype(game, String(m.name))
	var exp_gain := int(float(spec.get("exp", 8)) * BlackTekGameServer.RATE_EXP * BlackTekGameServer.RATE_STAGE)
	var p: Dictionary = game.players[pid]
	p.exp = int(p.exp) + exp_gain
	game.message_local(pid, "You defeated the %s and gained %d experience." % [String(m.name), exp_gain])
	BlackTekLoot.grant(game, pid, String(m.name))
	BlackTekCombat.gain_exp(game, pid)
	game.monsters_changed.emit()
	game.stats_changed.emit(pid)

static func gain_exp(game, pid: int) -> void:
	var p: Dictionary = game.players[pid]
	while int(p.exp) >= BlackTekPlayer.exp_for_level(int(p.level) + 1):
		p.level = int(p.level) + 1
		var voc: int = int(p.vocation)
		p.hpmax = BlackTekPlayer.max_hp(voc, int(p.level))
		p.manamax = BlackTekPlayer.max_mana(voc, int(p.level))
		p.hp = p.hpmax
		p.mana = p.manamax
		p.cap = 400 + int(BlackTekGameServer.VOCATIONS[voc].per_level.cap) * (int(p.level) - 1)
		game.level_up.emit(pid, int(p.level))
		game.message_local(pid, "You advanced from level %d to %d!" % [int(p.level) - 1, int(p.level)])

static func monster_attack(game, m: Dictionary, pid: int) -> void:
	var p: Dictionary = game.players[pid]
	var now := Time.get_ticks_msec() / 1000.0
	var spec := BlackTekMonsters.archetype(game, String(m.name))
	var raw := randi_range(int(spec.get("dmg_min", 1)), int(spec.get("dmg_max", 4)))
	var reduce: int = randi_range(0, BlackTekCombat.total_armor(game, pid) / 2 + 1)
	var dmg := maxi(0, raw - reduce)
	game.damage_float.emit(p.tile, int(p.z), dmg, false)
	if dmg > 0:
		p.hp = maxi(0, int(p.hp) - dmg)
		game.message_local(pid, "You lose %d hitpoints (attacked by %s)." % [dmg, String(m.name)])
		if randf() < 0.2 and float(p.get("poison_until", 0.0)) <= now:
			p.poison_until = now + 10.0
			game.message_local(pid, "You are poisoned.")
		if int(p.hp) <= 0:
			BlackTekCombat.player_death(game, pid)
	else:
		game.message_local(pid, "A %s attacked you but your armor blocked it." % String(m.name))
	game.stats_changed.emit(pid)

static func player_death(game, pid: int) -> void:
	var p: Dictionary = game.players[pid]
	game.message_local(pid, "You are dead. Respawn at town with full health (demo: no penalty).")
	p.path = []
	p.hp = int(p.hpmax)
	p.mana = int(p.manamax)
	p.poison_until = 0.0
	p.target = 0
	game.target_changed.emit(pid, {})
	for m in game.monsters.values():
		m.target_pid = 0
	if game.use_real_map:
		p.tile = game.find_spawn()
		p.z = game.demo_z
	else:
		p.tile = Vector2i(15, 11)
	game.player_moved.emit(pid, p.tile)
