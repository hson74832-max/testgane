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
	spells["exura"] = {"src": "spells/scripts/healing/heal.lua (words exura)", "mana": 20, "min_level": 0, "cooldown_s": 1.0, "run": _spell_heal}
	spells["exori flam"] = {"src": "spells/scripts/attack/flame strike.lua (words exori flam)", "mana": 20, "min_level": 12, "cooldown_s": 2.0, "run": _spell_flame_strike}

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
