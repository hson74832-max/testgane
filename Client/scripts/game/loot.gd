# BlackTek loot: per-monster tables (data/loot_tables.toml) rolled on kills.
# Stateless — game state and messages flow through the server.
class_name BlackTekLoot
extends RefCounted

const FALLBACK := [
	{"monster": "Rat", "itemtype": 2148, "min": 1, "max": 8, "chance": 1.0, "scaled": true},
	{"monster": "Rat", "itemtype": 2666, "min": 1, "max": 1, "chance": 0.4, "scaled": false},
]

static var _tables: Array = []

static func ensure_loaded() -> void:
	if not _tables.is_empty():
		return
	_tables = _load_tables("res://data/loot_tables.toml")
	if _tables.is_empty():
		_tables = FALLBACK.duplicate(true)

# Minimal TOML reader: [[loot]] blocks with monster/itemtype/min/max/chance
# plus scaled = true/false (scaled rolls multiply by the loot rate).
static func _load_tables(path: String) -> Array:
	var out := []
	if not FileAccess.file_exists(path):
		return out
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var cur := {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		if line == "[[loot]]":
			_flush_entry(cur, out)
			cur = {}
			continue
		var eq := line.find("=")
		if eq < 0:
			continue
		var key := line.substr(0, eq).strip_edges()
		var val := line.substr(eq + 1).strip_edges()
		if val.begins_with("\""):
			var q2 := val.find("\"", 1)
			cur[key] = val.substr(1, q2 - 1) if q2 > 1 else ""
		elif val == "true" or val == "false":
			cur[key] = val == "true"
		elif "." in val:
			cur[key] = val.to_float()
		else:
			cur[key] = int(val)
	_flush_entry(cur, out)
	f.close()
	return out

static func _flush_entry(cur: Dictionary, out: Array) -> void:
	if cur.is_empty() or not cur.has("monster") or not cur.has("itemtype"):
		return
	out.append({
		"monster": String(cur.get("monster", "")),
		"itemtype": int(cur.get("itemtype", 0)),
		"min": int(cur.get("min", 1)),
		"max": maxi(int(cur.get("min", 1)), int(cur.get("max", 1))),
		"chance": clampf(float(cur.get("chance", 1.0)), 0.0, 1.0),
		"scaled": bool(cur.get("scaled", false)),
	})

# Roll one monster's table: chance per entry, count x loot rate when scaled.
static func grant(game, pid: int, monster_name: String) -> void:
	BlackTekLoot.ensure_loaded()
	var loot_rate: float = game.config.rate("loot") if game.get("config") != null else BlackTekGameServer.RATE_LOOT
	for e in _tables:
		if String(e.get("monster", "")) != monster_name:
			continue
		if randf() > float(e.get("chance", 1.0)):
			continue
		var n := randi_range(int(e.get("min", 1)), int(e.get("max", 1)))
		if bool(e.get("scaled", false)):
			n *= int(loot_rate)
		if n <= 0:
			continue
		if game.add_item(pid, int(e.get("itemtype", 0)), n):
			var label: String = game.item_label(int(e.get("itemtype", 0)))
			if n > 1:
				game.message_local(pid, "Loot: %d x %s." % [n, label])
			else:
				game.message_local(pid, "Loot: %s." % label)
