# BlackTek vitals: vocation math, hp/mana/food/conditions, skills/magic levels.
# Stateless — live players, signals and the clock live on the game server.
# Vocation/rate tables come from BlackTekConfig (data/vocations.toml,
# data/rates.toml); no hardcoded progression here.
class_name BlackTekVitals
extends RefCounted

static func vocation_entry(game, voc: int) -> Dictionary:
	if game.get("config") != null:
		return (game.config as BlackTekConfig).vocation(voc)
	return BlackTekGameServer.VOCATIONS.get(voc, BlackTekGameServer.VOCATIONS[0])

static func max_hp(game, voc: int, level: int) -> int:
	return 150 + int(vocation_entry(game, voc).per_level.hp) * (level - 1)

static func max_mana(game, voc: int, level: int) -> int:
	return 35 + int(vocation_entry(game, voc).per_level.mana) * (level - 1)

static func exp_for_level(level: int) -> int:
	var l := float(level)
	return int(50.0 / 3.0 * (pow(l, 3) - 6.0 * l * l + 17.0 * l - 12.0))

static func vocation_roll(_game, _pid: int, min_v: int, max_v: int) -> int:
	return randi_range(min_v, max_v)

static func is_gm(_game, _pid: int) -> bool:
	return false # demo account is a normal player; GM talkactions show the gate

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
	var rate: float = game.config.rate("magic") if game.get("config") != null else BlackTekGameServer.RATE_MAGIC
	var need := int((int(p.maglevel) + 1) * 80.0 / rate)
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
	var rate: float = game.config.rate("skill") if game.get("config") != null else BlackTekGameServer.RATE_SKILL
	var need := int((int(p.skills[skill]) + 1) * 12.0 / rate)
	if int(tries[skill]) >= need:
		tries[skill] = 0
		p.skills[skill] = int(p.skills[skill]) + 1
		game.message_local(pid, "You advanced to %s skill %d." % [skill, int(p.skills[skill])])
	game.stats_changed.emit(pid)

# Demo protection zone: the town temple area (spawn) — tiles within 3 SQM.
static func is_pz_tile(game, tile: Vector2i) -> bool:
	return game.temple_tile != Vector2i(-9999, -9999) and maxi(absi(tile.x - game.temple_tile.x), absi(tile.y - game.temple_tile.y)) <= 3

static func is_fed(game, pid: int) -> bool:
	return float(game.players[pid].get("food_until", 0.0)) > Time.get_ticks_msec() / 1000.0

static func is_poisoned(game, pid: int) -> bool:
	return float(game.players[pid].get("poison_until", 0.0)) > Time.get_ticks_msec() / 1000.0
