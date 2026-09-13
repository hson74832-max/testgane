extends Node
## GameBalance — autoload singleton and facade over the balance modules.
## Loads res://data/content.json exported from testttt/ (web single source of truth).
## Run `node scripts/export-content.mjs` in testttt/ after any balance change,
## then copy shared/content.json -> remnants-godot/data/content.json (script does it).
## Web owns the numbers. Godot owns the sim.
##
## Architecture: this autoload gets the merged content root from DataLoader
## (core/data_loader.gd — slice files under data/ win, content.json is the
## web-export fallback) and hands each slice to the module that owns it:
##   combat_balance  formulas, cooldowns, abilities, vocations, skills
##   item_db         item stats, equip slots, loot filter
##   monster_db      creature defs + AI params (spawn tables: WorldConfig.WORLD)
##   world_cfg       tile rules, floor settings, NPC fixtures
## The public API is unchanged — every GameBalance.X read forwards below, so
## sim/UI/test call sites never touch the modules directly.

const CombatBalance := preload("res://scripts/balance/combat_balance.gd")
const ItemDatabase := preload("res://scripts/balance/item_database.gd")
const MonsterDatabase := preload("res://scripts/balance/monster_database.gd")
const WorldConfig := preload("res://scripts/balance/world_config.gd")
const DataLoader := preload("res://scripts/core/data_loader.gd")

var combat_balance: CombatBalance
var item_db: ItemDatabase
var monster_db: MonsterDatabase
var world_cfg: WorldConfig
var data_loader: DataLoader

## Content version (bumped by the web export). Loader metadata, not balance.
var VERSION: int = 0

# --- facade over the modules (signatures unchanged; forwarders only) --------
var ITEMS: Dictionary:
	get: return item_db.ITEMS
var MONSTERS: Dictionary:
	get: return monster_db.MONSTERS
var ABILITIES: Array:
	get: return combat_balance.ABILITIES
var EQUIP_SLOTS: Array:
	get: return item_db.EQUIP_SLOTS
var COMBAT: Dictionary:
	get: return combat_balance.COMBAT
var DEFAULT_LOOT_FILTER: Array:
	get: return item_db.DEFAULT_LOOT_FILTER
var ALL_ITEM_KEYS: Array:
	get: return item_db.ALL_ITEM_KEYS
var RIVALS: Array:
	get: return monster_db.RIVALS
var NPCS: Array:
	get: return world_cfg.NPCS
var NPC_STOCK: Array:
	get: return world_cfg.NPC_STOCK
var FERRY: Array:
	get: return world_cfg.FERRY
var NPC_TALK_RANGE := 2:
	get: return world_cfg.NPC_TALK_RANGE
var NPC_HEAL_COST := 30:
	get: return world_cfg.NPC_HEAL_COST
var NPC_FERRY_COST := 10:
	get: return world_cfg.NPC_FERRY_COST
var NPC_SELL_PCT := 0.5:
	get: return world_cfg.NPC_SELL_PCT
## Raw world block from content.json (REGIONS spawns, CRYPT config).
var WORLD: Dictionary:
	get: return world_cfg.WORLD
var VOCATION_ORDER: Array:
	get: return combat_balance.VOCATION_ORDER
var VOCATIONS: Dictionary:
	get: return combat_balance.VOCATIONS
var SKILL_ORDER: Array:
	get: return combat_balance.SKILL_ORDER
var SKILLS: Dictionary:
	get: return combat_balance.SKILLS

func _init() -> void:
	combat_balance = CombatBalance.new()
	item_db = ItemDatabase.new()
	monster_db = MonsterDatabase.new()
	world_cfg = WorldConfig.new()
	data_loader = DataLoader.new()

func _ready() -> void:
	load_balance()

func load_balance(path: String = "res://data/content.json") -> bool:
	var parsed: Dictionary = data_loader.load_content(path)
	if parsed.is_empty():
		push_warning("[GameBalance] no content found under data/ (slices or content.json), using built-in defaults")
		return false
	VERSION = int(parsed.get("version", 0))
	combat_balance.load_content(parsed)
	item_db.load_content(parsed)
	monster_db.load_content(parsed)
	world_cfg.load_content(parsed)
	print("[GameBalance] v%d items=%d monsters=%d abilities=%d sources=%s" % [VERSION, item_db.ITEMS.size(), monster_db.MONSTERS.size(), combat_balance.ABILITIES.size(), str(data_loader.sources)])
	return true

# --- formulas, 1:1 with testttt/src/lib/game/content.ts (CombatBalance) -----

func mitigate(raw: int, armor: int) -> int:
	return combat_balance.mitigate(raw, armor)

func xp_for_level(level: int) -> int:
	return combat_balance.xp_for_level(level)

func level_from_xp(xp: int) -> int:
	return combat_balance.level_from_xp(xp)

func stats_for_level(level: int) -> Dictionary:
	return combat_balance.stats_for_level(level)

func step_ms_for(heavy: int) -> int:
	return combat_balance.step_ms_for(heavy)

func auto_attack_ms() -> int:
	return combat_balance.auto_attack_ms()

func item_def(key: String) -> Dictionary:
	return item_db.item_def(key)

func monster_def(key: String) -> Dictionary:
	return monster_db.monster_def(key)

func skill_def(key: String) -> Dictionary:
	return (combat_balance.SKILLS as Dictionary).get(key, {})
