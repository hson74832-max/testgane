# Mock database for the offline demo — in-memory + JSON file at user://mock_db.json.
# Mirrors the real BlackTek schema.sql tables used by the demo:
#   accounts, players, player_items, player_storage (subset of columns).
# Replace this class with a TCP client (blacktek_msg.gd) to talk to the real
# server; the rest of the client only uses the API below.
class_name BlackTekDatabase
extends RefCounted

# Equipment slots (cf. src/creatures/players/... CONST_SLOT_*):
# 1 head, 2 amulet, 3 backpack, 4 armor, 5 right hand, 6 left hand,
# 7 legs, 8 feet, 9 ring, 10 ammo.
const SLOT_NAMES := {1: "head", 2: "amulet", 3: "backpack", 4: "armor", 5: "right hand", 6: "left hand", 7: "legs", 8: "feet", 9: "ring", 10: "ammo"}

const DB_PATH := "user://mock_db.json"

var db_path := DB_PATH # override (e.g. the verify suite) before MockServer._init loads

var db: Dictionary = {"accounts": [], "players": [], "player_items": [], "player_storage": [], "next_id": {"account": 1, "player": 1, "item": 1}}
var load_ms := 0

func load_db() -> bool:
	var t0 := Time.get_ticks_msec()
	if not FileAccess.file_exists(db_path):
		_seed_demo()
		save_db()
		load_ms = Time.get_ticks_msec() - t0
		return true
	var f := FileAccess.open(db_path, FileAccess.READ)
	if f == null:
		_seed_demo()
		save_db()
		return true
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary and parsed.has("players"):
		db = parsed
		load_ms = Time.get_ticks_msec() - t0
		return true
	_seed_demo()
	save_db()
	return true

func save_db() -> bool:
	var f := FileAccess.open(db_path, FileAccess.WRITE)
	if f == null:
		push_error("MockDB: cannot write %s" % db_path)
		return false
	f.store_string(JSON.stringify(db, "  "))
	f.close()
	return true

func wipe() -> void:
	if FileAccess.file_exists(db_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(db_path))
	db = {"accounts": [], "players": [], "player_items": [], "player_storage": [], "next_id": {"account": 1, "player": 1, "item": 1}}
	_seed_demo()
	save_db()

# ---- accounts ---------------------------------------------------------------

func auth(account_name: String, password: String) -> Dictionary:
	for a in db.accounts:
		if String(a.name).to_lower() == account_name.to_lower() and String(a.password) == password:
			return a
	return {}

func characters(account_id: int) -> Array:
	var out := []
	for p in db.players:
		if int(p.account_id) == account_id:
			out.append(p)
	return out

func create_account(account_name: String, password: String) -> Dictionary:
	if not auth(account_name, password).is_empty():
		return {}
	var a := {"id": int(db.next_id.account), "name": account_name, "password": password, "premium": 0, "coins": 0}
	db.next_id.account = int(a.id) + 1
	db.accounts.append(a)
	save_db()
	return a

# ---- players ----------------------------------------------------------------

func find_player_by_name(player_name: String) -> Dictionary:
	for p in db.players:
		if String(p.name).to_lower() == player_name.to_lower():
			return p
	return {}

# Empty row per schema.sql defaults; gameplay values come from vocation+level.
func create_character(account_id: int, player_name: String, vocation: int, town_id := 1) -> Dictionary:
	if not find_player_by_name(player_name).is_empty():
		return {}
	var p := {
		"id": int(db.next_id.player), "name": player_name, "account_id": account_id,
		"vocation": vocation, "level": 1, "experience": 0,
		"health": 150, "healthmax": 150, "mana": 0, "manamax": 0,
		"cap": 400, "soul": 100, "maglevel": 0,
		"town_id": town_id, "posx": 0, "posy": 0, "posz": 7,
		"balance": 0,
		"skills": {"fist": 10, "club": 10, "sword": 10, "axe": 10, "dist": 10, "shield": 10, "fishing": 10},
	}
	db.next_id.player = int(p.id) + 1
	db.players.append(p)
	save_db()
	return p

# Demo seed: account demo/demo with one Knight and one Sorcerer + starter gear.
func _seed_demo() -> void:
	var a := create_account("demo", "demo")
	var kn := create_character(int(a.id), "DemoKnight", 4)
	kn.level = 8
	kn.experience = 4200
	kn.posx = 0; kn.posy = 0; kn.posz = 7
	kn.skills.sword = 12
	var so := create_character(int(a.id), "DemoSorcerer", 1)
	so.level = 8
	so.experience = 4200
	so.posx = 0; so.posy = 0; so.posz = 7
	so.maglevel = 3
	# Starter kits (client item ids match data/items/items.toml / assets.dat):
	# 2461 leather helmet, 2467 leather armor, 2376 sword, 2511 brass shield,
	# 2643 leather boots, 1988 backpack, 7618 health potion, 7620 mana potion,
	# 2666 meat, 2190 wand of vortex, 2148 gold coin.
	var kit_knight := [
		{"itemtype": 2461, "count": 1, "slot": 1}, {"itemtype": 1988, "count": 1, "slot": 3},
		{"itemtype": 2467, "count": 1, "slot": 4}, {"itemtype": 2376, "count": 1, "slot": 5},
		{"itemtype": 2511, "count": 1, "slot": 6}, {"itemtype": 2643, "count": 1, "slot": 8},
		{"itemtype": 7618, "count": 3, "slot": -1, "bpos": 0},
		{"itemtype": 2666, "count": 2, "slot": -1, "bpos": 1},
		{"itemtype": 2148, "count": 100, "slot": -1, "bpos": 2},
	]
	var kit_sorcerer := [
		{"itemtype": 1988, "count": 1, "slot": 3}, {"itemtype": 2467, "count": 1, "slot": 4},
		{"itemtype": 2190, "count": 1, "slot": 5}, {"itemtype": 7620, "count": 5, "slot": -1, "bpos": 0},
		{"itemtype": 2666, "count": 2, "slot": -1, "bpos": 1},
		{"itemtype": 2148, "count": 100, "slot": -1, "bpos": 2},
	]
	for it in kit_knight:
		add_item(int(kn.id), int(it.itemtype), int(it.count), int(it.slot), int(it.get("bpos", 0)))
	for it in kit_sorcerer:
		add_item(int(so.id), int(it.itemtype), int(it.count), int(it.slot), int(it.get("bpos", 0)))

# ---- player_items / player_storage -------------------------------------------

func add_item(player_id: int, itemtype: int, count := 1, slot := -1, bpos := -1) -> Dictionary:
	var row := {"sid": int(db.next_id.item), "pid": player_id, "itemtype": itemtype, "count": count, "slot": slot, "bpos": bpos}
	db.next_id.item = int(row.sid) + 1
	db.player_items.append(row)
	return row

func items_of(player_id: int) -> Array:
	var out := []
	for it in db.player_items:
		if int(it.pid) == player_id:
			out.append(it)
	return out

func remove_item(sid: int) -> void:
	for i in range(db.player_items.size()):
		if int(db.player_items[i].sid) == sid:
			db.player_items.remove_at(i)
			return

# Set or clear (value < 0) a storage key (cf. player_storage table).
func set_storage(player_id: int, key: int, value: int) -> void:
	for s in db.player_storage:
		if int(s.pid) == player_id and int(s.key) == key:
			if value < 0:
				db.player_storage.erase(s)
			else:
				s.value = value
			return
	if value >= 0:
		db.player_storage.append({"pid": player_id, "key": key, "value": value})

func get_storage(player_id: int, key: int) -> int:
	for s in db.player_storage:
		if int(s.pid) == player_id and int(s.key) == key:
			return int(s.value)
	return -1

func delete_character(player_id: int) -> void:
	for i in range(db.players.size()):
		if int(db.players[i].id) == player_id:
			db.players.remove_at(i)
	db.player_items = db.player_items.filter(func(it): return int(it.pid) != player_id)
	db.player_storage = db.player_storage.filter(func(s): return int(s.pid) != player_id)
	save_db()
