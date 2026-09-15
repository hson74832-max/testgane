# BlackTek inventory: backpack/equipment rows, stacking, gold, shop trading.
# Stateless — live players and signals live on the game server.
# Equip map comes from BlackTekConfig (data/equipment_slots.toml).
class_name BlackTekInventory
extends RefCounted

static func equip_slot(game, itemtype: int) -> int:
	if game.get("config") != null:
		return (game.config as BlackTekConfig).equip(itemtype)
	return int(BlackTekGameServer.EQUIP_SLOT.get(itemtype, -1))

static func add_item(game, pid: int, itemtype: int, count := 1) -> bool:
	if not game.players.has(pid):
		return false
	var p: Dictionary = game.players[pid]
	if game.dat != null and bool(game.dat.items.get(itemtype, {}).get("stackable", false)):
		for bpos in p.bag.keys():
			var it: Dictionary = p.bag[bpos] if p.bag[bpos] != null else {}
			if not it.is_empty() and int(it.itemtype) == itemtype:
				it.count = int(it.count) + count
				game.inventory_changed.emit(pid)
				return true
	for i in range(20):
		if p.bag.get(i) == null:
			p.bag[i] = {"sid": 0, "pid": int(p.row_id), "itemtype": itemtype, "count": count, "slot": -1, "bpos": i}
			game.inventory_changed.emit(pid)
			return true
	game.message_local(pid, "Your backpack is full.")
	return false

static func consume_item(game, pid: int, row: Dictionary) -> void:
	if not game.players.has(pid):
		return
	if row.is_empty() or not row.has("count"):
		return
	var p: Dictionary = game.players[pid]
	row.count = int(row.count) - 1
	if int(row.count) <= 0:
		if p.inv.get(int(row.get("slot", -2))) == row:
			p.inv[int(row.get("slot", -2))] = null
		for bpos in p.bag.keys():
			if p.bag[bpos] == row:
				p.bag[bpos] = null
	game.inventory_changed.emit(pid)

# Pays gold coins from the backpack (NPC trades, cf. npcsystem).
static func pay_gold(game, pid: int, amount: int) -> bool:
	if not game.players.has(pid):
		return false
	var p: Dictionary = game.players[pid]
	var have := 0
	for bpos in p.bag.keys():
		var it: Dictionary = p.bag.get(bpos) if p.bag.get(bpos) != null else {}
		if not it.is_empty() and int(it.itemtype) == BlackTekActionScripts.GOLD_COIN:
			have += int(it.count)
	if have < amount:
		game.message_local(pid, "You do not have enough gold.")
		return false
	var left := amount
	for bpos in p.bag.keys():
		var it2: Dictionary = p.bag.get(bpos) if p.bag.get(bpos) != null else {}
		if not it2.is_empty() and int(it2.itemtype) == BlackTekActionScripts.GOLD_COIN and left > 0:
			var take: int = mini(left, int(it2.count))
			it2.count = int(it2.count) - take
			left -= take
			if int(it2.count) <= 0:
				p.bag[bpos] = null
	game.consume_refresh(pid)
	return true

static func buy_shop_item(game, pid: int, offer: Dictionary, count := 1) -> void:
	if not BlackTekNpc.can_trade(game, pid):
		game.message_local(pid, "There is no NPC to trade with here. Walk up to Norf at the temple.")
		return
	if count <= 0:
		return
	var price: int = BlackTekConfig.offer_buy_price(offer)
	var total: int = price * count
	if pay_gold(game, pid, total):
		if add_item(game, pid, int(offer.itemtype), count):
			if count > 1:
				game.message_local(pid, "You bought %dx %s for %d gold." % [count, String(offer.name), total])
			else:
				game.message_local(pid, "You bought 1x %s for %d gold." % [String(offer.name), total])

# ---- selling (Norf buys back wares at sell_price) ----

# How many of an itemtype sit in the backpack (sellable stock; equipped
# gear is never auto-sold so a misclick can't strip your sword).
static func count_of(game, pid: int, itemtype: int) -> int:
	if not game.players.has(pid):
		return 0
	var total := 0
	var bag: Dictionary = (game.players as Dictionary)[pid].bag
	for bpos in bag.keys():
		var it: Dictionary = bag.get(bpos) if bag.get(bpos) != null else {}
		if not it.is_empty() and int(it.itemtype) == itemtype:
			total += int(it.count)
	return total

# Remove `count` pieces from backpack stacks. Returns false (no mutation)
# when stock is insufficient.
static func remove_items(game, pid: int, itemtype: int, count: int) -> bool:
	if count <= 0 or not game.players.has(pid):
		return false
	if count_of(game, pid, itemtype) < count:
		return false
	var p: Dictionary = (game.players as Dictionary)[pid]
	var left: int = count
	# Walk slots in order so partial stacks drain deterministically.
	var keys: Array = p.bag.keys().duplicate()
	keys.sort()
	for bpos in keys:
		if left <= 0:
			break
		var it: Dictionary = p.bag.get(bpos) if p.bag.get(bpos) != null else {}
		if it.is_empty() or int(it.itemtype) != itemtype:
			continue
		var take: int = mini(left, int(it.count))
		it.count = int(it.count) - take
		left -= take
		if int(it.count) <= 0:
			p.bag[bpos] = null
	game.inventory_changed.emit(pid)
	return true

static func add_gold(game, pid: int, amount: int) -> bool:
	if amount <= 0:
		return false
	return add_item(game, pid, BlackTekActionScripts.GOLD_COIN, amount)

# Sell `count` pieces of the offer back to the NPC at sell_price each.
static func sell_shop_item(game, pid: int, offer: Dictionary, count := 1) -> void:
	if not BlackTekNpc.can_trade(game, pid):
		game.message_local(pid, "There is no NPC to trade with here. Walk up to Norf at the temple.")
		return
	var sell: int = BlackTekConfig.offer_sell_price(offer)
	if sell <= 0:
		game.message_local(pid, "Norf doesn't buy %s." % String(offer.get("name", "that")))
		return
	if count <= 0:
		return
	if not remove_items(game, pid, int(offer.itemtype), count):
		game.message_local(pid, "You have no %s to sell." % String(offer.name))
		return
	add_gold(game, pid, sell * count)
	if count > 1:
		game.message_local(pid, "You sold %dx %s for %d gold." % [count, String(offer.name), sell * count])
	else:
		game.message_local(pid, "You sold 1x %s for %d gold." % [String(offer.name), sell])

# True when the backpack can take one more of this type (stack merge or a
# free slot). Used for the grab preview so it never promises a full bag.
static func can_pickup(game, pid: int, itemtype: int) -> bool:
	if not game.players.has(pid):
		return false
	var p: Dictionary = game.players[pid]
	if game.dat != null and bool(game.dat.items.get(itemtype, {}).get("stackable", false)):
		for bpos in p.bag.keys():
			var it: Dictionary = p.bag[bpos] if p.bag[bpos] != null else {}
			if not it.is_empty() and int(it.itemtype) == itemtype:
				return true
	for i in range(20):
		if p.bag.get(i) == null:
			return true
	return false
