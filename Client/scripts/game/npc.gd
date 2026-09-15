# BlackTek NPCs: Norf the shopkeeper — post anchor, local-chat hearing and
# dialogue plus his wares (cf. data/npc + npcsystem on the server).
class_name BlackTekNpc
extends RefCounted

# Chat is local: only listeners within SAY_RANGE tiles (same floor) hear a
# line. Norf hears meaningfully at his post, like any other listener.
const SAY_RANGE := 9

# NPC shop offers (data/npc + modules game_shop): {itemtype, price, name}.
# Health/mana potions mirror actions/other/potions.lua item ids.
const SHOP_OFFERS := [
	{"itemtype": 7618, "price": 50, "name": "health potion"},
	{"itemtype": 7620, "price": 50, "name": "mana potion"},
	{"itemtype": 2666, "price": 8, "name": "meat"},
	{"itemtype": 2671, "price": 12, "name": "ham"},
]

const NORF := "Norf (Shop NPC)"

# Player said something spells/talkactions didn't consume: shop dialogue if
# Norf can hear it (within SAY_RANGE of his post), else a hint for talky
# keywords and silence for the rest. Returns true when NPC-handled.
static func handle_dialogue(game, pid: int, low: String) -> bool:
	var p: Dictionary = game.players.get(pid, {})
	var home: Vector2i = game.npc_tile
	var heard: bool = home != Vector2i(-9999, -9999) and int(p.get("z", -1)) == int(game.npc_z) and maxi(absi(int(p.tile.x) - home.x), absi(int(p.tile.y) - home.y)) <= SAY_RANGE
	var wants_npc := low.begins_with("hi") or low == "trade" or low.begins_with("buy ") or low.begins_with("bye")
	if not heard:
		if wants_npc:
			game.message_local(pid, "Nobody hears you. Norf keeps his post at the temple.")
		return wants_npc
	var pname := String(p.get("name", "traveller"))
	if low.begins_with("hi"):
		game.say_to_range(home, int(game.demo_z), NORF, "Greetings, %s! Say 'trade' to see my wares." % pname)
	elif low == "trade":
		game.say_to_range(home, int(game.demo_z), NORF, "Have a look! Buying health/mana potions, meat, ham.")
		game.shop_requested.emit(pid)
	elif low.begins_with("buy "):
		var what := low.substr(4).strip_edges()
		for offer in BlackTekNpc.SHOP_OFFERS:
			if String(offer.name).begins_with(what) or what.begins_with(String(offer.name)):
				game.buy_shop_item(pid, offer)
				return true
		game.say_to_range(home, int(game.demo_z), NORF, "I don't sell '%s'. Try trade." % what)
	elif low.begins_with("bye"):
		game.say_to_range(home, int(game.demo_z), NORF, "Farewell, %s." % pname)
	return wants_npc
