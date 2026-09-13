extends RefCounted
## Vocations — paths bending the shared kit. CONTENT LIVES IN content.ts
## (VOCATIONS/VOCATION_ORDER): tuning a path is a data edit + export.
## Warrior holds the line in melee, Archer owns sight-checked air,
## Magician is frail with vast mana and +35% spells.

static func order() -> Array:
	return GameBalance.VOCATION_ORDER

static func def(key: String) -> Dictionary:
	return ((GameBalance.VOCATIONS as Dictionary).get(key, (GameBalance.VOCATIONS as Dictionary).get("warrior", {})) as Dictionary).duplicate()

static func valid(key: String) -> bool:
	return (GameBalance.VOCATIONS as Dictionary).has(key)
