extends RefCounted
## MonsterDatabase — creature defs and their AI parameters.
## Slice of GameBalance (which owns content.json loading and the public API):
##   MONSTERS   creature rows incl. AI params (aggroRange, moveMs, windup,
##              cadence, attackRange, shape, status) and loot/gold/xp
##   RIVALS     names that pre-damage spawns (rival marks, ledger-only)
## Spawn TABLES live on region rows in WorldConfig.WORLD (content.json
## world.REGIONS.spawns + world.CRYPT.SPAWNS) and are surfaced through
## WorldGen; this module owns the creature defs those tables point into.
## A new creature is a data row in content.json — no code.

var MONSTERS: Dictionary = {}
var RIVALS: Array = []

## Pull the monster slice out of the parsed content.json root.
func load_content(parsed: Dictionary) -> void:
	MONSTERS = parsed.get("monsters", {})
	RIVALS = parsed.get("rivals", [])

func monster_def(key: String) -> Dictionary:
	return MONSTERS.get(key, {})
