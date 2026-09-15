# BlackTek interaction: item/door pushes, drops, pickups (melee-range world
# edits). Stateless — live OTBM tiles are mutated session-only (the map
# reloads pristine next run since caches are only written at import).
class_name BlackTekInteraction
extends RefCounted

# Any live-tile content change (push/drop/pickup/doors) bumps the world map
# version so the sprite draw cache drops its stale entries.
static func touch(game) -> void:
	game.world.bump_map()

# Topmost movable object on a tile (ground/borders, stairs and static
# decor are never pushable). Returns {itemtype, index} into the tile's list.
static func pushable_item_at(game, tile: Vector2i, z: int) -> Dictionary:
	var ids: PackedInt32Array = game.tile_info(tile, z).get("items", PackedInt32Array())
	if game.dat == null:
		return {}
	for i in range(ids.size() - 1, -1, -1):
		var d: Dictionary = game.dat.items.get(int(ids[i]), {})
		if d.is_empty():
			continue
		if bool(d.get("is_ground", false)) or bool(d.get("is_border", false)):
			continue
		if bool(d.get("is_stair", false)):
			continue
		if bool(d.get("moveable", false)):
			return {"itemtype": int(ids[i]), "index": i}
	return {}

# Preview for the client arrow: the shove works if the item is still there
# and the destination tile exists and holds no creature/NPC/player.
static func can_push_item(game, tile: Vector2i, dir: Vector2i, z: int) -> bool:
	if pushable_item_at(game, tile, z).is_empty():
		return false
	var d: int = maxi(absi(dir.x), absi(dir.y))
	if d != 1:
		return false
	var dest := tile + dir
	if game.tile_info(dest, z).is_empty():
		return false
	if not BlackTekMonsters.monster_at(game, dest, z).is_empty():
		return false
	if not BlackTekNpc.npc_at(game, dest, z).is_empty():
		return false
	for p in game.players.values():
		if int(p.z) == z and p.tile == dest:
			return false
	return true

# Shove the topmost movable item 1 SQM. Melee range, same floor, like creatures.
static func push_item(game, tile: Vector2i, dir: Vector2i, z: int, pid: int) -> bool:
	if not game.players.has(pid):
		return false
	var pp: Dictionary = game.players[pid]
	if z != int(pp.z):
		game.message_local(pid, "You are too far away to push that.")
		return false
	if maxi(absi(tile.x - int(pp.tile.x)), absi(tile.y - int(pp.tile.y))) > 1:
		game.message_local(pid, "You are too far away to push that.")
		return false
	var pick := pushable_item_at(game, tile, z)
	if pick.is_empty() or not can_push_item(game, tile, dir, z):
		game.message_local(pid, "You cannot push that there.")
		return false
	# NOTE: PackedInt32Array is copy-on-write, so mutating a .get() result
	# would silently discard the change — duplicate, edit, write back into
	# the live tile dicts instead.
	var moving := int(pick.itemtype)
	var src_entry: Dictionary = game.tile_info(tile, z)
	var src_ids: PackedInt32Array = (src_entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	src_ids.remove_at(clampi(int(pick.index), 0, src_ids.size() - 1))
	src_entry["items"] = src_ids
	var dst_entry: Dictionary = game.tile_info(tile + dir, z)
	var dst_ids: PackedInt32Array = (dst_entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	dst_ids.append(moving)
	dst_entry["items"] = dst_ids
	BlackTekInteraction.touch(game)
	game.message_local(pid, "You push the %s %s." % [game.item_label(moving), BlackTekGameServer.dir_name(dir)])
	return true

# Topmost takeable object on a tile (pickupable decor, loot, dropped gear —
# never ground, stairs or doors). Returns {itemtype, index}.
static func takeable_item_at(game, tile: Vector2i, z: int) -> Dictionary:
	if game.dat == null:
		return {}
	var ids: PackedInt32Array = game.tile_info(tile, z).get("items", PackedInt32Array())
	for i in range(ids.size() - 1, -1, -1):
		var id := int(ids[i])
		if game.dat.door_pairs.has(id):
			continue
		var d: Dictionary = game.dat.items.get(id, {})
		if d.is_empty():
			continue
		if bool(d.get("is_ground", false)) or bool(d.get("is_border", false)):
			continue
		if bool(d.get("is_stair", false)):
			continue
		if bool(d.get("pickupable", false)):
			return {"itemtype": id, "index": i}
	return {}

# Dragged a bag row onto a world tile: leave the item on the ground (one
# piece per drag; stacks stay mostly in the bag). Session-only like pushes.
static func drop_item(game, pid: int, bpos: int, tile: Vector2i, z: int) -> bool:
	if not game.players.has(pid):
		return false
	var p: Dictionary = game.players[pid]
	var row: Dictionary = p.bag.get(bpos) if p.bag.get(bpos) != null else {}
	if row.is_empty():
		return false # stale drag; stay silent
	if z != int(p.z) or maxi(absi(tile.x - int(p.tile.x)), absi(tile.y - int(p.tile.y))) > 1:
		game.message_local(pid, "You cannot reach that far.")
		return false
	if game.tile_info(tile, z).is_empty():
		game.message_local(pid, "You cannot drop that there.")
		return false
	if not BlackTekMonsters.monster_at(game, tile, z).is_empty():
		game.message_local(pid, "Something is in the way.")
		return false
	if not BlackTekNpc.npc_at(game, tile, z).is_empty():
		game.message_local(pid, "Something is in the way.")
		return false
	for opid in game.players.keys():
		if int(opid) == pid:
			continue # dropping at your own feet is fine
		var p2: Dictionary = game.players[opid]
		if int(p2.z) == z and p2.tile == tile:
			game.message_local(pid, "Something is in the way.")
			return false
	var itemtype := int(row.itemtype)
	if int(row.count) > 1:
		row.count = int(row.count) - 1
	else:
		p.bag[bpos] = null
	var entry: Dictionary = game.tile_info(tile, z)
	var ids: PackedInt32Array = (entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	ids.append(itemtype)
	entry["items"] = ids
	BlackTekInteraction.touch(game)
	game.inventory_changed.emit(pid)
	game.message_local(pid, "You drop the %s." % game.item_label(itemtype))
	return true

# Dragged an equipped row onto a world tile: same as a bag drop.
static func drop_equipped(game, pid: int, slot: int, tile: Vector2i, z: int) -> bool:
	if not game.players.has(pid):
		return false
	var p: Dictionary = game.players[pid]
	var row: Dictionary = p.inv.get(slot) if p.inv.get(slot) != null else {}
	if row.is_empty():
		return false # stale drag; stay silent
	if z != int(p.z) or maxi(absi(tile.x - int(p.tile.x)), absi(tile.y - int(p.tile.y))) > 1:
		game.message_local(pid, "You cannot reach that far.")
		return false
	if game.tile_info(tile, z).is_empty():
		game.message_local(pid, "You cannot drop that there.")
		return false
	if not BlackTekMonsters.monster_at(game, tile, z).is_empty():
		game.message_local(pid, "Something is in the way.")
		return false
	if not BlackTekNpc.npc_at(game, tile, z).is_empty():
		game.message_local(pid, "Something is in the way.")
		return false
	for opid in game.players.keys():
		if int(opid) == pid:
			continue
		var p2: Dictionary = game.players[opid]
		if int(p2.z) == z and p2.tile == tile:
			game.message_local(pid, "Something is in the way.")
			return false
	var itemtype := int(row.itemtype)
	p.inv[slot] = null
	var entry: Dictionary = game.tile_info(tile, z)
	var ids: PackedInt32Array = (entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	ids.append(itemtype)
	entry["items"] = ids
	BlackTekInteraction.touch(game)
	game.inventory_changed.emit(pid)
	game.message_local(pid, "You drop the %s." % game.item_label(itemtype))
	return true

# Dragged a floor item onto the open gear panel: take it into the backpack —
# straight into its equipment slot when it fits and the slot is free.
static func pickup_item(game, tile: Vector2i, z: int, pid: int) -> bool:
	if not game.players.has(pid):
		return false
	var pp: Dictionary = game.players[pid]
	if z != int(pp.z) or maxi(absi(tile.x - int(pp.tile.x)), absi(tile.y - int(pp.tile.y))) > 1:
		game.message_local(pid, "You cannot reach that far.")
		return false
	var pick := takeable_item_at(game, tile, z)
	if pick.is_empty():
		game.message_local(pid, "There is nothing to take.")
		return false
	var itemtype := int(pick.itemtype)
	if not BlackTekInventory.can_pickup(game, pid, itemtype):
		game.message_local(pid, "Your backpack is full.")
		return false
	var entry: Dictionary = game.tile_info(tile, z)
	var ids: PackedInt32Array = (entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	if int(pick.index) >= ids.size() or int(ids[int(pick.index)]) != itemtype:
		return false # tile changed under us; be safe, not sorry
	ids.remove_at(int(pick.index))
	entry["items"] = ids
	BlackTekInteraction.touch(game)
	# Gear fitting straight into its slot (containers home to Backpack 3),
	# anything else lands in the backpack as usual.
	var slot := BlackTekInventory.equip_slot(game, itemtype)
	if slot < 0 and game.dat != null and game.dat.is_container(itemtype):
		slot = 3
	var voc := int(pp.vocation)
	if slot >= 0 and pp.inv.get(slot) == null and not (slot == 6 and (voc == 1 or voc == 2)):
		pp.inv[slot] = {"sid": 0, "pid": int(pp.row_id), "itemtype": itemtype, "count": 1, "slot": slot, "bpos": -1}
		game.inventory_changed.emit(pid)
		game.message_local(pid, "You equip the %s." % game.item_label(itemtype))
		return true
	BlackTekInventory.add_item(game, pid, itemtype, 1)
	game.message_local(pid, "You pick up the %s." % game.item_label(itemtype))
	return true

# ---- doors: open/close usable leaves by swapping the leaf item id ---------

# Topmost usable door leaf on a tile, or {}: {itemtype, index, open}.
static func door_at(game, tile: Vector2i, z: int) -> Dictionary:
	if game.dat == null:
		return {}
	var ids: PackedInt32Array = game.tile_info(tile, z).get("items", PackedInt32Array())
	for i in range(ids.size() - 1, -1, -1):
		var leaf: Dictionary = game.dat.door_pairs.get(int(ids[i]), {})
		if not leaf.is_empty():
			return {"itemtype": int(ids[i]), "index": i, "open": bool(leaf.get("open", false)), "to": int(leaf.get("to", 0))}
	return {}

# Left-click a door within reach: closed leaves swing open, open leaves swing
# shut unless someone stands on the tile. Swaps the leaf id in the live tile
# list (session-only, like pushed items), so walkability follows the leaf.
static func use_door(game, tile: Vector2i, z: int, pid: int) -> bool:
	if not game.players.has(pid):
		return false
	var pp: Dictionary = game.players[pid]
	if z != int(pp.z) or maxi(absi(tile.x - int(pp.tile.x)), absi(tile.y - int(pp.tile.y))) > 1:
		return false # out of reach: silent, the click just walks closer
	var door := door_at(game, tile, z)
	if door.is_empty():
		return false
	if bool(door.open):
		for p2 in game.players.values():
			if int(p2.z) == z and p2.tile == tile:
				game.message_local(pid, "You cannot close this door.")
				return false
		if not BlackTekMonsters.monster_at(game, tile, z).is_empty():
			game.message_local(pid, "You cannot close this door.")
			return false
		if not BlackTekNpc.npc_at(game, tile, z).is_empty():
			game.message_local(pid, "You cannot close this door.")
			return false
	var entry: Dictionary = game.tile_info(tile, z)
	var ids: PackedInt32Array = (entry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
	if int(door.index) >= ids.size() or int(ids[int(door.index)]) != int(door.itemtype):
		return false # tile changed under us; be safe, not sorry
	ids[int(door.index)] = int(door.to)
	entry["items"] = ids
	BlackTekInteraction.touch(game)
	game.message_local(pid, "You close the door." if bool(door.open) else "You open the door.")
	return true
