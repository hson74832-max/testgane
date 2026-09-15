# Simulated BlackTek "server action scripts" — GDScript stand-ins for the Lua
# content in data/scripts (actions, talkactions, spells) and data/npc shops.
# Each entry carries the Lua file it mirrors so the port stays traceable; all
# state changes go through the mock server (game) the way real scripts call
# the C++ Game singleton. Swap this file for the real protocol later.
class_name BlackTekActionScripts
extends RefCounted

const HEALTH_POTION := 7618   # items.toml: "health potion"
const MANA_POTION := 7620     # "mana potion"
const MEAT := 2666
const HAM := 2671
const QUEST_CHEST := 1740     # "chest" quest container
const GOLD_COIN := 2148

# actions registry: itemtype -> {src: mirrored Lua file, run: Callable(game, pid, row) -> bool}
var actions: Dictionary = {}
# talkactions registry: word -> {src, gm: bool, run: Callable(game, pid, args) -> bool}
var talkactions: Dictionary = {}
# spells registry: words -> {src, mana, min_level, cooldown_s, run: Callable(game, pid) -> bool}
var spells: Dictionary = {}
# NPC wares live in game/npc.gd (BlackTekNpc.SHOP_OFFERS).

func _init() -> void:
	# ---- data/scripts/actions (use item) ------------------------------------
	actions[HEALTH_POTION] = {"src": "actions/other/potions.lua", "run": _use_health_potion}
	actions[MANA_POTION] = {"src": "actions/other/potions.lua", "run": _use_mana_potion}
	actions[MEAT] = {"src": "actions/other/food.lua", "run": _use_food}
	actions[HAM] = {"src": "actions/other/food.lua", "run": _use_food}
	actions[QUEST_CHEST] = {"src": "actions/quests/system.lua", "run": _use_quest_chest}

	# ---- data/scripts/talkactions -------------------------------------------
	talkactions["/pos"] = {"src": "talkactions/position.lua", "gm": false, "run": _talk_position}
	talkactions["/t"] = {"src": "talkactions/teleport_to_town.lua", "gm": true, "run": _talk_to_town}
	talkactions["!online"] = {"src": "talkactions/online.lua", "gm": false, "run": _talk_online}
	talkactions["/save"] = {"src": "talkactions/server_save.lua (demo: single player)", "gm": true, "run": _talk_save}
	talkactions["/day"] = {"src": "demo: set ambient light to day", "gm": false, "run": _talk_day}
	talkactions["/night"] = {"src": "demo: set ambient light to night", "gm": false, "run": _talk_night}

	# ---- data/scripts/spells (instant player spells) -------------------------
	# Test set: exura (small heal) + exura gran (big heal), exana pox (cure),
	# utevo lux (personal light for night testing), exori flam (single-target
	# strike), exori (whirlwind hitting everything adjacent). All min_level 0
	# so they are usable straight away at demo level 8.
	spells["exura"] = {"src": "spells/scripts/healing/heal.lua (words exura)", "mana": 20, "min_level": 0, "cooldown_s": 1.0, "run": _spell_heal}
	spells["exura gran"] = {"src": "spells/scripts/healing/ultimate heal.lua (words exura gran)", "mana": 40, "min_level": 0, "cooldown_s": 1.0, "run": _spell_gran_heal}
	spells["exana pox"] = {"src": "spells/scripts/healing/cure poison.lua (words exana pox)", "mana": 15, "min_level": 0, "cooldown_s": 1.0, "run": _spell_cure_poison}
	spells["utevo lux"] = {"src": "spells/scripts/support/magic light.lua (words utevo lux)", "mana": 10, "min_level": 0, "cooldown_s": 1.0, "run": _spell_magic_light}
	spells["exori flam"] = {"src": "spells/scripts/attack/flame strike.lua (words exori flam)", "mana": 20, "min_level": 12, "cooldown_s": 2.0, "run": _spell_flame_strike}
	spells["exori"] = {"src": "spells/scripts/attack/berserk.lua (words exori)", "mana": 30, "min_level": 0, "cooldown_s": 2.0, "run": _spell_whirlwind}

# Hotbar shorthand: the F5 slot sends "flame", which is the classic short
# form of "exori flam". Aliases resolve before the registry lookup.
const SPELL_ALIASES := {"flame": "exori flam"}

# AoE footprint per spell words (pure, shared by the caster and the hover
# warning in the world view). exori hits the 8 tiles around the caster.
static func spell_aoe_tiles(center: Vector2i, words: String) -> Array:
	if words == "exori":
		var out := []
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx != 0 or dy != 0:
					out.append(center + Vector2i(dx, dy))
		return out
	return []

# ---- dispatch (cf. Game::useItem -> actions::registerAction callbacks) ------

func use_item(game, pid: int, row: Dictionary) -> bool:
	var a: Dictionary = actions.get(int(row.itemtype), {})
	if a.is_empty():
		game.message_local(pid, "Nothing to use here.") # real server: silent
		return false
	return bool(a.run.call(game, pid, row))

func handle_talk(game, pid: int, text: String) -> bool:
	var words := text.strip_edges()
	var args := ""
	var sp := words.find(" ")
	if sp >= 0:
		args = words.substr(sp + 1).strip_edges()
		words = words.substr(0, sp)
	var t: Dictionary = talkactions.get(words, {})
	if t.is_empty():
		return false
	if bool(t.gm) and not game.is_gm(pid):
		game.message_local(pid, "You need a gamemaster account to use '%s'." % words)
		return true
	return bool(t.run.call(game, pid, args))

func cast_spell(game, pid: int, text: String) -> bool:
	var words := text.strip_edges().to_lower()
	words = String(SPELL_ALIASES.get(words, words))
	var s: Dictionary = spells.get(words, {})
	if s.is_empty():
		return false
	var p: Dictionary = game.players.get(pid, {})
	if int(p.get("mana", 0)) < int(s.mana):
		game.message_local(pid, "You do not have enough mana.")
		return true
	if int(p.get("level", 1)) < int(s.min_level):
		game.message_local(pid, "You need level %d for '%s'." % [int(s.min_level), words])
		return true
	if not game.check_cooldown(pid, "spell", float(s.cooldown_s)):
		game.message_local(pid, "You are exhausted.")
		return true
	return bool(s.run.call(game, pid))

# ---- actions ----------------------------------------------------------------

func _use_health_potion(game, pid: int, row: Dictionary) -> bool:
	if not game.check_cooldown(pid, "potion", 1.0):
		game.message_local(pid, "You are exhausted.")
		return true
	var heal: int = game.vocation_roll(pid, 100, 160) # demo potion power
	game.heal_player(pid, heal, "health potion")
	game.consume_item(pid, row)
	return true

func _use_mana_potion(game, pid: int, row: Dictionary) -> bool:
	if not game.check_cooldown(pid, "potion", 1.0):
		game.message_local(pid, "You are exhausted.")
		return true
	var mana: int = game.vocation_roll(pid, 90, 150)
	game.add_mana(pid, mana, "mana potion")
	game.consume_item(pid, row)
	return true

func _use_food(game, pid: int, row: Dictionary) -> bool:
	game.set_food(pid, 240) # food condition: passive regen for 240s (cf. conditions)
	game.message_local(pid, "Munch. You feel strangely full.")
	game.consume_item(pid, row)
	return true

func _use_quest_chest(game, pid: int, _row: Dictionary) -> bool:
	var key := 50001 # storage key, cf. player_storage table
	if game.get_storage(pid, key) > 0:
		game.message_local(pid, "It is empty.")
		return true
	game.set_storage(pid, key, 1)
	game.add_item(pid, GOLD_COIN, 50)
	game.message_local(pid, "You have found 50 gold coins.")
	return true

# ---- talkactions ------------------------------------------------------------

func _talk_position(game, pid: int, _args: String) -> bool:
	var pos: Vector3i = game.player_pos3(pid)
	game.message_local(pid, "Your position is %d,%d,%d." % [pos.x, pos.y, pos.z])
	return true

func _talk_to_town(game, pid: int, _args: String) -> bool:
	return game.teleport_town(pid)

func _talk_online(game, pid: int, _args: String) -> bool:
	var names: Array = []
	for other in game.players.values():
		names.append("%s [level %d]" % [other.name, other.level])
	game.message_local(pid, "%d player(s) online: %s" % [names.size(), ", ".join(names)])
	return true

func _talk_day(game, _pid: int, _args: String) -> bool:
	game.set_ambient(1.0)
	return true

func _talk_night(game, _pid: int, _args: String) -> bool:
	game.set_ambient(0.25)
	return true

func _talk_save(game, pid: int, _args: String) -> bool:
	game.save_all()
	game.message_local(pid, "MockDB saved.")
	return true

# ---- spells -----------------------------------------------------------------

func _spell_heal(game, pid: int) -> bool:
	var p: Dictionary = game.players.get(pid, {})
	var mlvl := int(p.get("maglevel", 0))
	var amount: int = game.vocation_roll(pid, 30 + 4 * mlvl, 60 + 8 * mlvl)
	game.spend_mana(pid, int(spells["exura"].mana))
	game.heal_player(pid, amount, "spell")
	return true

# Test spell: big single-target heal (no level gate so it works at demo level).
func _spell_gran_heal(game, pid: int) -> bool:
	var p: Dictionary = game.players.get(pid, {})
	var mlvl := int(p.get("maglevel", 0))
	var amount: int = game.vocation_roll(pid, 90 + 8 * mlvl, 150 + 12 * mlvl)
	game.spend_mana(pid, int(spells["exura gran"].mana))
	game.heal_player(pid, amount, "spell")
	return true

# Test spell: cure poison (rats poison — handy without antidotes).
func _spell_cure_poison(game, pid: int) -> bool:
	var p: Dictionary = game.players.get(pid, {})
	game.spend_mana(pid, int(spells["exana pox"].mana))
	if float(p.get("poison_until", 0.0)) > Time.get_ticks_msec() / 1000.0:
		p.poison_until = 0.0
		game.message_local(pid, "You are cleansed of poison.")
	else:
		game.message_local(pid, "You feel a warm tingle (no poison to cure).")
	game.stats_changed.emit(pid)
	return true

# Test spell: personal light for 120s (night testing without torch hunting).
func _spell_magic_light(game, pid: int) -> bool:
	var p: Dictionary = game.players.get(pid, {})
	game.spend_mana(pid, int(spells["utevo lux"].mana))
	p.light_until = Time.get_ticks_msec() / 1000.0 + 120.0
	game.message_local(pid, "A warm light surrounds you for 120 seconds.")
	game.stats_changed.emit(pid)
	return true

func _spell_flame_strike(game, pid: int) -> bool:
	var target: Dictionary = game.nearest_monster(pid, 5)
	if target.is_empty():
		game.message_local(pid, "You need a target in range.")
		return true
	var p: Dictionary = game.players.get(pid, {})
	var mlvl := int(p.get("maglevel", 0))
	var dmg: int = game.vocation_roll(pid, 10 + 2 * mlvl, 25 + 4 * mlvl)
	game.spend_mana(pid, int(spells["exori flam"].mana))
	game.damage_monster(int(target.get("id", 0)), dmg, "flame strike", pid)
	return true

# Test spell: whirlwind with a wind-up telegraph. Cast shows warning squares
# for whirlwind_delay, then damage lands on whatever stands in the area.
# Mana/cooldown are spent up front; magic level is snapshotted at cast.
func _spell_whirlwind(game, pid: int) -> bool:
	var p: Dictionary = game.players.get(pid, {})
	var has_foe := false
	for m in game.monsters.values():
		if int(m.z) != int(p.z):
			continue
		if maxi(absi(int(m.tile.x) - int(p.tile.x)), absi(int(m.tile.y) - int(p.tile.y))) <= 1:
			has_foe = true
			break
	if not has_foe:
		game.message_local(pid, "You need enemies next to you.")
		return true
	game.spend_mana(pid, int(spells["exori"].mana))
	var delay: float = game.config.tune("whirlwind_delay") if game.get("config") != null else 0.8
	var area: Array = BlackTekActionScripts.spell_aoe_tiles(p.tile, "exori")
	game.pending_spells.append({"kind": "exori", "center": p.tile, "z": int(p.z),
		"pid": pid, "mlvl": int(p.get("maglevel", 0)), "left": delay})
	game.spell_area.emit(p.tile, int(p.z), area, "warn")
	game.message_local(pid, "You gather the winds...")
	return true

# Wind-up driver (called from the server tick with frame delta): anchored
# telegraphs count down, then damage lands on the stored tiles.
static func tick_pending(game, delta: float) -> void:
	if game.pending_spells.is_empty():
		return
	var due := []
	for pend in game.pending_spells:
		pend.left = float(pend.left) - delta
		if float(pend.left) <= 0.0:
			due.append(pend)
	for pend in due:
		game.pending_spells.erase(pend)
		if String(pend.kind) == "exori":
			_execute_whirlwind(game, pend)

static func _execute_whirlwind(game, pend: Dictionary) -> void:
	var pid: int = int(pend.pid)
	if not game.players.has(pid):
		return
	var center: Vector2i = pend.center
	var z: int = int(pend.z)
	var mlvl: int = int(pend.mlvl)
	game.spell_area.emit(center, z, BlackTekActionScripts.spell_aoe_tiles(center, "exori"), "hit")
	var hits := 0
	for m in game.monsters.values().duplicate():
		var mm: Dictionary = m
		if int(mm.z) != z:
			continue
		if maxi(absi(int(mm.tile.x) - center.x), absi(int(mm.tile.y) - center.y)) > 1:
			continue
		if mm.tile == center:
			continue
		var dmg: int = game.vocation_roll(pid, 8 + 2 * mlvl, 20 + 4 * mlvl)
		game.damage_monster(int(mm.id), dmg, "whirlwind", pid)
		hits += 1
	if hits > 0:
		game.message_local(pid, "Your whirlwind hits %d target(s)." % hits)
	else:
		game.message_local(pid, "Your whirlwind hits nothing.")
