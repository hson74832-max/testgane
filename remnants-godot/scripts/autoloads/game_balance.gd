extends Node
## GameBalance — autoload singleton.
## Loads res://data/content.json exported from testttt/ (web single source of truth).
## Run `node scripts/export-content.mjs` in testttt/ after any balance change,
## then copy shared/content.json -> remnants-godot/data/content.json (script does it).
## Web owns the numbers. Godot owns the sim.

var VERSION: int = 0
var ITEMS: Dictionary = {}
var MONSTERS: Dictionary = {}
var ABILITIES: Array = []
var EQUIP_SLOTS: Array = []
var COMBAT: Dictionary = {
	"AUTO_ATTACK_MS": 2000,
	"BASE_STEP_MS": 205,
	"MS_PER_HEAVY": 5,
	"MAX_STEP_PENALTY_MS": 90,
	"MIN_DAMAGE": 1,
	"PUSH_CD_MS": 2500,
	"LOOT_PROTECT_MS": 60000,
	"GROUND_DECAY_MS": 180000,
	"STEP_MIN_MS": 120,
	"STEP_DIAGONAL_MULT": 1.4,
	"STEP_SLOW_MULT": 1.6,
	"ROOT_MS": 1200,
	"REGEN_MS": 1400,
	"REGEN_HP_BASE": 1,
	"REGEN_HP_DIV": 3,
	"REGEN_MANA_BASE": 2,
	"REGEN_MANA_DIV": 2,
	"CRIT_CHANCE": 0.14,
	"CRIT_MULT": 1.85,
	"WARD_BASE": 45,
	"WARD_PER_LEVEL": 5,
	"WARD_PER_RANK": 10,
	"WARD_MS": 6000,
	"STATUS_MS": 6000,
	"STATUS_TICK_MS": 1500,
	"POISON_POWER": 4,
	"BURN_POWER": 6,
	"XP_LOSS_PCT": 0.1,
	"GOLD_DROP_PCT": 0.5,
	"RESPAWN_MS": 2600,
	"MAX_MONSTERS": 34,
	"CRYPT_MONSTERS": 8,
	"RIVAL_MARK_CHANCE": 0.14,
	"RIVAL_MARK_MIN": 0.3,
	"RIVAL_MARK_SPREAD": 0.3,
	"SENSE_JITTER": 1,
	"SENSE_MIN": 2,
	"SENSE_MAX": 9,
	"DEAGGRO_TILES": 4,
	"AGGRO_REACT_MS": 120,
	"MOB_HEAL_MS": 1500,
	"MOB_HEAL_DIV": 20,
}
var DEFAULT_LOOT_FILTER: Array = []
var ALL_ITEM_KEYS: Array = []
var RIVALS: Array = []
var NPCS: Array = []
var NPC_STOCK: Array = []
var FERRY: Array = []
var NPC_TALK_RANGE := 2
var NPC_HEAL_COST := 30
var NPC_FERRY_COST := 10
var NPC_SELL_PCT := 0.5
## Raw world block from content.json (REGIONS spawns, CRYPT config).
var WORLD: Dictionary = {}
var VOCATION_ORDER: Array = []
var VOCATIONS: Dictionary = {}
var SKILL_ORDER: Array = []
var SKILLS: Dictionary = {}

func _ready() -> void:
	load_balance()

func load_balance(path: String = "res://data/content.json") -> bool:
	if not FileAccess.file_exists(path):
		push_warning("[GameBalance] missing %s, using built-in defaults" % path)
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("[GameBalance] cannot open %s" % path)
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[GameBalance] content.json is not a Dictionary")
		return false
	VERSION = int(parsed.get("version", 0))
	ITEMS = parsed.get("items", {})
	MONSTERS = parsed.get("monsters", {})
	ABILITIES = parsed.get("abilities", [])
	EQUIP_SLOTS = parsed.get("equipSlots", [])
	DEFAULT_LOOT_FILTER = parsed.get("defaultLootFilter", [])
	ALL_ITEM_KEYS = parsed.get("allItemKeys", [])
	RIVALS = parsed.get("rivals", [])
	NPCS = parsed.get("npcs", [])
	NPC_STOCK = parsed.get("npcStock", [])
	FERRY = parsed.get("ferry", [])
	NPC_TALK_RANGE = int(parsed.get("npcTalkRange", 2))
	NPC_HEAL_COST = int(parsed.get("npcHealCost", 30))
	NPC_FERRY_COST = int(parsed.get("npcFerryCost", 10))
	NPC_SELL_PCT = float(parsed.get("npcSellPct", 0.5))
	WORLD = parsed.get("world", {})
	VOCATION_ORDER = parsed.get("vocationOrder", [])
	# Normalize TS camelCase to GDScript snake_case once, at the boundary.
	VOCATIONS = {}
	for vkey in (parsed.get("vocations", {}) as Dictionary).keys():
		var v: Dictionary = (parsed["vocations"] as Dictionary)[vkey]
		VOCATIONS[String(vkey)] = {
			"key": String(vkey),
			"name": String(v.get("name", vkey)),
			"blurb": String(v.get("blurb", "")),
			"hp_mult": float(v.get("hpMult", 1.0)),
			"mana_mult": float(v.get("manaMult", 1.0)),
			"tick_range": int(v.get("tickRange", 1)),
			"tick_base": int(v.get("tickBase", 6)),
			"tick_scale": float(v.get("tickScale", 0.9)),
			"tick_shot": bool(v.get("tickShot", false)),
			"melee_mult": float(v.get("meleeMult", 1.0)),
			"spell_mult": float(v.get("spellMult", 1.0)),
		}
	SKILL_ORDER = parsed.get("skillOrder", [])
	SKILLS = parsed.get("skills", {})
	var bal: Dictionary = parsed.get("balance", {})
	if bal.has("COMBAT"):
		for k in (bal["COMBAT"] as Dictionary).keys():
			COMBAT[k] = (bal["COMBAT"] as Dictionary)[k]
	print("[GameBalance] v%d items=%d monsters=%d abilities=%d" % [VERSION, ITEMS.size(), MONSTERS.size(), ABILITIES.size()])
	return true

# --- formulas, 1:1 with testttt/src/lib/game/content.ts ---

func mitigate(raw: int, armor: int) -> int:
	return maxi(int(COMBAT.get("MIN_DAMAGE", 1)), raw - armor)

func xp_for_level(level: int) -> int:
	return int(floor(60.0 * pow(float(level), 1.85)))

func level_from_xp(xp: int) -> int:
	var lvl := 1
	while lvl < 60 and xp >= xp_for_level(lvl):
		lvl += 1
	return lvl

func stats_for_level(level: int) -> Dictionary:
	return {
		"maxHp": 100 + level * 20,
		"maxMana": 45 + level * 15,
		"damageBonus": int(floor(float(level) * 1.6)),
	}

func step_ms_for(heavy: int) -> int:
	var base := int(COMBAT.get("BASE_STEP_MS", 205))
	var per := int(COMBAT.get("MS_PER_HEAVY", 5))
	var cap := int(COMBAT.get("MAX_STEP_PENALTY_MS", 90))
	return base + mini(cap, heavy * per)

func auto_attack_ms() -> int:
	return int(COMBAT.get("AUTO_ATTACK_MS", 2000))

func item_def(key: String) -> Dictionary:
	return ITEMS.get(key, {})

func monster_def(key: String) -> Dictionary:
	return MONSTERS.get(key, {})

func skill_def(key: String) -> Dictionary:
	return (SKILLS as Dictionary).get(key, {})
