extends RefCounted
## WorldConfig — tile rules, floor settings and world fixtures.
## Slice of GameBalance (which owns content.json loading and the public API):
##   WORLD        raw content world block: REGIONS (layout + spawn table rows)
##                and CRYPT (floor size/name/spawns). WorldGen merges the
##                region spawn tables over its embedded fallbacks in _ready.
##   NPCS/NPC_STOCK/FERRY + NPC_* costs   world fixtures and services
##   TILE_DEFS    what each tile kind means (walkable / blocks projectiles).
##                Moved here from WorldGen so tile rules live in one place;
##                WorldGen reads this table for is_walkable/blocks_projectile.
## Map GENERATION constants (map sizes, temple anchor, rift gates) stay in
## WorldGen — they are generator parameters, not content.

## Raw world block from content.json (REGIONS spawns, CRYPT config).
var WORLD: Dictionary = {}
var NPCS: Array = []
var NPC_STOCK: Array = []
var FERRY: Array = []
var NPC_TALK_RANGE := 2
var NPC_HEAL_COST := 30
var NPC_FERRY_COST := 10
var NPC_SELL_PCT := 0.5

## Tile kind -> movement rules. Matches the kinds WorldGen can generate.
const TILE_DEFS: Dictionary = {
	"grass": {"walkable": true, "projectile_blocked": false},
	"brush": {"walkable": true, "projectile_blocked": false},
	"path": {"walkable": true, "projectile_blocked": false},
	"ash": {"walkable": true, "projectile_blocked": false},
	"stone": {"walkable": true, "projectile_blocked": false},
	"water": {"walkable": false, "projectile_blocked": false},
	"wall": {"walkable": false, "projectile_blocked": true},
	"temple": {"walkable": true, "projectile_blocked": false},
	"gate": {"walkable": true, "projectile_blocked": false},
}

## Pull the world slice out of the parsed content.json root.
func load_content(parsed: Dictionary) -> void:
	WORLD = parsed.get("world", {})
	NPCS = parsed.get("npcs", [])
	NPC_STOCK = parsed.get("npcStock", [])
	FERRY = parsed.get("ferry", [])
	NPC_TALK_RANGE = int(parsed.get("npcTalkRange", 2))
	NPC_HEAL_COST = int(parsed.get("npcHealCost", 30))
	NPC_FERRY_COST = int(parsed.get("npcFerryCost", 10))
	NPC_SELL_PCT = float(parsed.get("npcSellPct", 0.5))
