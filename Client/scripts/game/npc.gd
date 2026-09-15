# BlackTek NPCs: real entities (server.npcs), not just a chat anchor.
# Norf the shopkeeper holds a post at the temple: players hear him to
# say_range, but buying/selling and the shop window require trade_range.
# Tuning: say_range/trade_range in data/gameplay.toml, offers in
# data/shop_offers.toml. Consts below are deprecated compat aliases.
class_name BlackTekNpc
extends RefCounted

# Chat is local: only listeners within SAY_RANGE tiles (same floor) hear a
# line. Norf hears meaningfully at his post, like any other listener.
const SAY_RANGE := 9

# NPC shop offers (data/npc + modules game_shop): {itemtype, price/buy_price,
# sell_price, name}. Health/mana potions mirror actions/other/potions.lua ids.
const SHOP_OFFERS := [
	{"itemtype": 7618, "price": 50, "buy_price": 50, "sell_price": 20, "name": "health potion"},
	{"itemtype": 7620, "price": 50, "buy_price": 50, "sell_price": 20, "name": "mana potion"},
	{"itemtype": 2666, "price": 8, "buy_price": 8, "sell_price": 3, "name": "meat"},
	{"itemtype": 2671, "price": 12, "buy_price": 12, "sell_price": 5, "name": "ham"},
]

const NORF := "Norf (Shop NPC)"
const TRADE_RANGE := 3

static func say_range(game) -> int:
	return game.config.tune_int("say_range") if game.get("config") != null else SAY_RANGE

static func trade_range(game) -> int:
	return game.config.tune_int("trade_range") if game.get("config") != null else TRADE_RANGE

static func shop_offers(game) -> Array:
	if game.get("config") != null and not (game.config as BlackTekConfig).shop_offers.is_empty():
		return (game.config as BlackTekConfig).shop_offers
	return SHOP_OFFERS

# ---- real NPC entities (server.npcs: id -> {id, name, tile, z}) ----

# Spawn Norf next to the temple anchor on a free tile (never on the player).
# Keeps npc_tile/npc_z as compat aliases pointing at Norf's tile.
static func spawn_all(game) -> void:
	game.npcs.clear()
	var anchor: Vector2i = game.temple_tile
	if anchor == Vector2i(-9999, -9999):
		anchor = game.players[1].tile if game.players.has(1) else Vector2i(15, 11)
	var z: int = game.npc_z if int(game.npc_z) >= 0 else game.demo_z
	var spot := Vector2i(-9999, -9999)
	for r in range(0, 6):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := anchor + Vector2i(dx, dy)
				if c == anchor:
					continue # keep the anchor itself free for the player
				if not game.is_walkable(c, z):
					continue
				if not BlackTekMonsters.monster_at(game, c, z).is_empty():
					continue
				var busy := false
				for pl in game.players.values():
					if int(pl.z) == z and pl.tile == c:
						busy = true
						break
				if busy:
					continue
				spot = c
				break
			if spot != Vector2i(-9999, -9999):
				break
		if spot != Vector2i(-9999, -9999):
			break
	if spot == Vector2i(-9999, -9999):
		spot = anchor
	game.npcs[1] = {"id": 1, "name": "Norf", "tile": spot, "z": z}
	game.npc_tile = spot
	game.npc_z = z
	game.npcs_changed.emit()

static func npc_at(game, tile: Vector2i, z: int) -> Dictionary:
	for n in game.npcs.values():
		if int(n.z) == z and n.tile == tile:
			return n
	return {}

# Nearest NPC to the player within max_dist tiles (same floor), or {}.
static func nearest_npc(game, pid: int, max_dist := 999) -> Dictionary:
	if not game.players.has(pid):
		return {}
	var p: Dictionary = game.players[pid]
	var best := {}
	var best_d := max_dist + 1
	for n in game.npcs.values():
		if int(n.z) != int(p.z):
			continue
		var d: int = maxi(absi(int(n.tile.x) - int(p.tile.x)), absi(int(n.tile.y) - int(p.tile.y)))
		if d < best_d:
			best_d = d
			best = n
	return best if best_d <= max_dist else {}

# Trade gate: a real NPC within trade_range on the same floor.
static func can_trade(game, pid: int) -> bool:
	return not nearest_npc(game, pid, trade_range(game)).is_empty()

# Human reason when trade is refused ("" when allowed).
static func trade_blocker(game, pid: int) -> String:
	if not game.players.has(pid):
		return "no session"
	if game.npcs.is_empty():
		return "no NPC here"
	if nearest_npc(game, pid, trade_range(game)).is_empty():
		return "too far from Norf"
	return ""

# Right-click / click interaction with an NPC: greet at chat range, open the
# shop window at trade range, otherwise tell the player to come closer.
static func interact_npc(game, pid: int, nid: int) -> bool:
	var n: Dictionary = game.npcs.get(nid, {})
	if n.is_empty() or not game.players.has(pid):
		return false
	var p: Dictionary = game.players[pid]
	if int(n.z) != int(p.z):
		game.message_local(pid, "There is no NPC to talk to here.")
		return false
	var d: int = maxi(absi(int(n.tile.x) - int(p.tile.x)), absi(int(n.tile.y) - int(p.tile.y)))
	if d > say_range(game):
		game.message_local(pid, "Nobody hears you. Norf keeps his post at the temple.")
		return false
	if d > trade_range(game):
		game.say_to_range(n.tile, int(n.z), NORF, "Come closer, %s, and say 'trade'!" % String(p.get("name", "traveller")))
		game.message_local(pid, "Walk up to Norf to trade (within %d tiles)." % trade_range(game))
		return true
	game.say_to_range(n.tile, int(n.z), NORF, "Greetings, %s! Have a look at my wares." % String(p.get("name", "traveller")))
	game.shop_requested.emit(pid)
	return true

# Player said something spells/talkactions didn't consume: shop dialogue if
# Norf can hear it (within SAY_RANGE of his post), else a hint for talky
# keywords and silence for the rest. Returns true when NPC-handled.
# Trade language: `hi`, `trade` (opens the shop window), `buy <name>`,
# `sell <name> [count]`, `bye`.
static func handle_dialogue(game, pid: int, low: String) -> bool:
	var p: Dictionary = game.players.get(pid, {})
	var home: Vector2i = game.npc_tile
	var rng: int = say_range(game)
	var heard: bool = home != Vector2i(-9999, -9999) and int(p.get("z", -1)) == int(game.npc_z) and maxi(absi(int(p.tile.x) - home.x), absi(int(p.tile.y) - home.y)) <= rng
	var wants_npc := low.begins_with("hi") or low == "trade" or low.begins_with("buy ") or low.begins_with("sell ") or low.begins_with("bye")
	if not heard:
		if wants_npc:
			game.message_local(pid, "Nobody hears you. Norf keeps his post at the temple.")
		return wants_npc
	var pname := String(p.get("name", "traveller"))
	if low.begins_with("hi"):
		game.say_to_range(home, int(game.demo_z), NORF, "Greetings, %s! Say 'trade' to see my wares." % pname)
	elif low == "trade":
		if not can_trade(game, pid):
			game.say_to_range(home, int(game.demo_z), NORF, "Come closer, %s, and I will show my wares!" % pname)
			game.message_local(pid, "Walk up to Norf to trade (within %d tiles)." % trade_range(game))
		else:
			game.say_to_range(home, int(game.demo_z), NORF, "Have a look! %s" % trade_list(game))
			game.shop_requested.emit(pid)
	elif low.begins_with("buy "):
		if not can_trade(game, pid):
			game.message_local(pid, "There is no NPC to trade with here. Walk up to Norf at the temple.")
			return true
		var what_args := low.substr(4).strip_edges()
		var buy_count := 1
		# Trailing number = quantity ("buy meat 5").
		var buy_parts := what_args.rsplit(" ", false, 1)
		if buy_parts.size() == 2 and buy_parts[1].is_valid_int():
			buy_count = maxi(1, int(buy_parts[1]))
			what_args = buy_parts[0].strip_edges()
		var offer := find_offer(game, what_args)
		if offer.is_empty():
			game.say_to_range(home, int(game.demo_z), NORF, "I don't sell '%s'. Try trade." % what_args)
		else:
			game.buy_shop_item(pid, offer, buy_count)
			return true
	elif low.begins_with("sell "):
		if not can_trade(game, pid):
			game.message_local(pid, "There is no NPC to trade with here. Walk up to Norf at the temple.")
			return true
		var args := low.substr(5).strip_edges()
		var count := 1
		# Trailing number = quantity ("sell meat 5").
		var parts := args.rsplit(" ", false, 1)
		if parts.size() == 2 and parts[1].is_valid_int():
			count = maxi(1, int(parts[1]))
			args = parts[0].strip_edges()
		var offer2 := find_offer(game, args)
		if offer2.is_empty():
			game.say_to_range(home, int(game.demo_z), NORF, "I don't buy '%s'. Try trade." % args)
		else:
			game.sell_shop_item(pid, offer2, count)
			return true
	elif low.begins_with("bye"):
		game.say_to_range(home, int(game.demo_z), NORF, "Farewell, %s." % pname)
	return wants_npc

# One-line trade summary for the chat ("trade" answer).
static func trade_list(game) -> String:
	var bits: Array = []
	for offer in shop_offers(game):
		var buy: int = BlackTekConfig.offer_buy_price(offer)
		var sell: int = BlackTekConfig.offer_sell_price(offer)
		if sell > 0:
			bits.append("%s %d/%d gp" % [String(offer.name), buy, sell])
		else:
			bits.append("%s %d gp" % [String(offer.name), buy])
	return "Buying and selling: %s. Say 'buy <name> [count]' or 'sell <name> [count]'." % ", ".join(bits)

# Match a typed name against offer names (either direction prefix-matches).
static func find_offer(game, what: String) -> Dictionary:
	var w := what.strip_edges().to_lower()
	if w == "":
		return {}
	for offer in shop_offers(game):
		var n := String(offer.name).to_lower()
		if n.begins_with(w) or w.begins_with(n):
			return offer
	return {}
