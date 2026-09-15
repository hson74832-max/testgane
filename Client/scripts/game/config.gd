# BlackTek central config — single source for all data-driven tuning.
# Loads data/*.toml once (with hardcoded fallbacks so a missing file never
# breaks the demo) and exposes typed accessors. Systems (server, combat,
# monsters, npc, pathfinding, regen) read from here instead of duplicating
# consts, so adding a vocation/item/offer is a TOML edit, not a code change.
#
# Testability: pure parsing (parse_* take text lines) + `load_all()` with
# explicit paths, so headless tests can inject temp files or rely on fallbacks.
class_name BlackTekConfig
extends RefCounted

# ---- fallback defaults (must match the pre-refactor hardcoded values) ----

const FALLBACK_VOCATIONS := {
	0: {"id": 0, "name": "None", "short": "N", "per_level": {"cap": 10, "hp": 5, "mana": 5}, "regen": {"hp": [1, 6], "mana": [1, 6]}, "attack_speed": 2.0, "skill_rate": 3.0},
	1: {"id": 1, "name": "Sorcerer", "short": "S", "per_level": {"cap": 10, "hp": 5, "mana": 30}, "regen": {"hp": [5, 6], "mana": [5, 3]}, "attack_speed": 2.0, "skill_rate": 3.0},
	2: {"id": 2, "name": "Druid", "short": "D", "per_level": {"cap": 10, "hp": 5, "mana": 30}, "regen": {"hp": [5, 6], "mana": [5, 3]}, "attack_speed": 2.0, "skill_rate": 3.0},
	3: {"id": 3, "name": "Paladin", "short": "P", "per_level": {"cap": 20, "hp": 10, "mana": 15}, "regen": {"hp": [5, 4], "mana": [5, 3]}, "attack_speed": 2.0, "skill_rate": 3.0},
	4: {"id": 4, "name": "Knight", "short": "K", "per_level": {"cap": 25, "hp": 15, "mana": 5}, "regen": {"hp": [5, 3], "mana": [5, 6]}, "attack_speed": 2.0, "skill_rate": 3.0},
}

const FALLBACK_RATES := {"exp": 5.0, "stage": 7.0, "skill": 3.0, "magic": 3.0, "loot": 2.0}

const FALLBACK_EQUIP_SLOT := {2461: 1, 2467: 4, 2463: 4, 2376: 5, 2190: 5, 2511: 6, 2643: 8}

const FALLBACK_ITEM_STATS := {
	2376: {"atk": 14}, 2190: {"atk": 10, "magic": true},
	2461: {"armor": 1}, 2463: {"armor": 10}, 2467: {"armor": 4},
	2511: {"armor": 9, "shield": true}, 2643: {"armor": 1},
	7618: {"heal": [100, 160]}, 7620: {"mana": [90, 150]},
	2666: {"food": true}, 2671: {"food": true},
}

const FALLBACK_GAMEPLAY := {
	"push_cd": 2.0, "day_cycle": 960.0, "day_start": 50.0, "day_min": 0.25,
	"day_min_surface": 0.45,
	"say_range": 9, "trade_range": 3, "max_monsters": 3, "respawn_s": 6.0,
	"walk_cd": 0.15, "diag_walk_cd": 0.21, "map_w": 30, "map_h": 22,
	"whirlwind_delay": 0.8,
}

const FALLBACK_SHOP := [
	{"itemtype": 7618, "price": 50, "buy_price": 50, "sell_price": 20, "name": "health potion"},
	{"itemtype": 7620, "price": 50, "buy_price": 50, "sell_price": 20, "name": "mana potion"},
	{"itemtype": 2666, "price": 8, "buy_price": 8, "sell_price": 3, "name": "meat"},
	{"itemtype": 2671, "price": 12, "buy_price": 12, "sell_price": 5, "name": "ham"},
]

# ---- loaded state (instance per server, but statics share parsed tables) ----

var vocations: Dictionary = {}
var rates: Dictionary = {}
var equip_slot: Dictionary = {}
var item_stats: Dictionary = {}
var gameplay: Dictionary = {}
var shop_offers: Array = []
var base_dir := "res://data"

static var _shared: BlackTekConfig = null

static func shared() -> BlackTekConfig:
	if _shared == null:
		_shared = BlackTekConfig.new()
		_shared.load_all()
	return _shared

static func reset_shared() -> void:
	_shared = null

func _init(p_base_dir := "res://data") -> void:
	base_dir = p_base_dir

func load_all() -> void:
	vocations = _load_vocations(base_dir + "/vocations.toml")
	rates = _load_rates(base_dir + "/rates.toml")
	equip_slot = _load_equip(base_dir + "/equipment_slots.toml")
	item_stats = _load_item_stats(base_dir + "/item_stats.toml")
	gameplay = _load_gameplay(base_dir + "/gameplay.toml")
	shop_offers = _load_shop(base_dir + "/shop_offers.toml")

# ---- typed accessors (used by game systems; always fall back) ----

func vocation(voc: int) -> Dictionary:
	return vocations.get(voc, FALLBACK_VOCATIONS.get(voc, FALLBACK_VOCATIONS[0]))

func rate(key: String) -> float:
	return float(rates.get(key, FALLBACK_RATES.get(key, 1.0)))

func equip(itemtype: int) -> int:
	return int(equip_slot.get(itemtype, FALLBACK_EQUIP_SLOT.get(itemtype, -1)))

func stat(itemtype: int) -> Dictionary:
	return item_stats.get(itemtype, FALLBACK_ITEM_STATS.get(itemtype, {}))

func tune(key: String) -> float:
	return float(gameplay.get(key, FALLBACK_GAMEPLAY.get(key, 0.0)))

func tune_int(key: String) -> int:
	return int(gameplay.get(key, FALLBACK_GAMEPLAY.get(key, 0)))

func weapon_atk(itemtype: int) -> int:
	var st := stat(itemtype)
	if st.has("atk"):
		return int(st.atk)
	# Legacy combat defaults for unknown weapons.
	return 3 if itemtype == 0 else 0

func item_armor(itemtype: int) -> int:
	return int(stat(itemtype).get("armor", 0))

# ---- TOML loading (minimal [[block]] + key = value, like the other loaders) ----

static func _read_lines(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var out := []
	while not f.eof_reached():
		out.append(f.get_line())
	f.close()
	return out

static func _parse_value(raw: String) -> Variant:
	var v := raw.strip_edges()
	if v.begins_with("\""):
		var q2 := v.find("\"", 1)
		return v.substr(1, q2 - 1) if q2 > 1 else ""
	if v == "true":
		return true
	if v == "false":
		return false
	if v.begins_with("["):
		# Small int/float arrays like [100, 160] or [1, 6].
		var inner := v.trim_prefix("[").trim_suffix("]").strip_edges()
		var arr := []
		for part in inner.split(",", false):
			arr.append(_parse_value(part))
		return arr
	if "." in v:
		return v.to_float()
	return int(v)

static func _split_blocks(lines: Array) -> Array:
	# Returns Array of {header: String, kv: Dictionary}; header "" = top-level.
	var blocks := [{"header": "", "kv": {}}]
	for line in lines:
		var s: String = String(line).strip_edges()
		if s == "" or s.begins_with("#"):
			continue
		if s.begins_with("[[") and s.ends_with("]]"):
			blocks.append({"header": s.substr(2, s.length() - 4).strip_edges(), "kv": {}})
			continue
		var eq := s.find("=")
		if eq < 0:
			continue
		var k := s.substr(0, eq).strip_edges()
		var val: Variant = _parse_value(s.substr(eq + 1))
		(blocks[blocks.size() - 1] as Dictionary).kv[k] = val
	return blocks

func _load_vocations(path: String) -> Dictionary:
	var out := {}
	for b in _split_blocks(_read_lines(path)):
		var d: Dictionary = b.kv
		if String(b.header) != "vocation" or not d.has("id"):
			continue
		var vid := int(d.id)
		out[vid] = {
			"id": vid, "name": String(d.get("name", "Vocation%d" % vid)),
			"short": String(d.get("short", "?")),
			"per_level": {"cap": int(d.get("cap", 10)), "hp": int(d.get("hp", 5)), "mana": int(d.get("mana", 5))},
			"regen": {"hp": [int(d.get("regen_hp_amount", 1)), int(d.get("regen_hp_interval", 6))], "mana": [int(d.get("regen_mana_amount", 1)), int(d.get("regen_mana_interval", 6))]},
			"attack_speed": float(d.get("attack_speed", 2.0)), "skill_rate": float(d.get("skill_rate", 3.0)),
		}
	return out if not out.is_empty() else FALLBACK_VOCATIONS.duplicate(true)

func _load_rates(path: String) -> Dictionary:
	var out := FALLBACK_RATES.duplicate()
	for b in _split_blocks(_read_lines(path)):
		var d: Dictionary = b.kv
		for k in FALLBACK_RATES.keys():
			if d.has(k):
				out[k] = float(d[k])
	return out

func _load_equip(path: String) -> Dictionary:
	var out := {}
	for b in _split_blocks(_read_lines(path)):
		if String(b.header) != "slot":
			continue
		var d: Dictionary = b.kv
		if d.has("itemtype") and d.has("slot"):
			out[int(d.itemtype)] = int(d.slot)
	return out if not out.is_empty() else FALLBACK_EQUIP_SLOT.duplicate()

func _load_item_stats(path: String) -> Dictionary:
	var out := {}
	for b in _split_blocks(_read_lines(path)):
		if String(b.header) != "item":
			continue
		var d: Dictionary = b.kv
		if not d.has("itemtype"):
			continue
		var iid := int(d.itemtype)
		var st := {}
		for k in ["atk", "armor", "magic", "shield", "food", "quest"]:
			if d.has(k):
				st[k] = d[k]
		if d.has("heal_min") and d.has("heal_max"):
			st["heal"] = [int(d.heal_min), int(d.heal_max)]
		if d.has("mana_min") and d.has("mana_max"):
			st["mana"] = [int(d.mana_min), int(d.mana_max)]
		out[iid] = st
	return out if not out.is_empty() else FALLBACK_ITEM_STATS.duplicate(true)

func _load_gameplay(path: String) -> Dictionary:
	var out := FALLBACK_GAMEPLAY.duplicate()
	var walls_h := []
	var walls_v := []
	for b in _split_blocks(_read_lines(path)):
		var d: Dictionary = b.kv
		if String(b.header) == "":
			for k in FALLBACK_GAMEPLAY.keys():
				if d.has(k):
					out[k] = d[k]
		elif String(b.header) == "wall_h":
			walls_h.append(d)
		elif String(b.header) == "wall_v":
			walls_v.append(d)
	out["walls_h"] = walls_h
	out["walls_v"] = walls_v
	return out

func _load_shop(path: String) -> Array:
	var out := []
	for b in _split_blocks(_read_lines(path)):
		if String(b.header) != "offer":
			continue
		var d: Dictionary = b.kv
		if d.has("itemtype") and (d.has("price") or d.has("buy_price")):
			var buy: int = int(d.get("buy_price", d.get("price", 0)))
			out.append({"itemtype": int(d.itemtype), "price": buy, "buy_price": buy,
				"sell_price": int(d.get("sell_price", 0)),
				"name": String(d.get("name", "item %d" % int(d.itemtype)))})
	return out if not out.is_empty() else FALLBACK_SHOP.duplicate(true)

# Shop price helpers (legacy `price` = buy price).
static func offer_buy_price(offer: Dictionary) -> int:
	return int(offer.get("buy_price", offer.get("price", 0)))

static func offer_sell_price(offer: Dictionary) -> int:
	return int(offer.get("sell_price", 0))
