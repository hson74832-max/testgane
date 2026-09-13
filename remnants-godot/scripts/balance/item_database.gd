extends RefCounted
## ItemDatabase — item stats and everything item-keyed.
## Slice of GameBalance (which owns content.json loading and the public API):
##   ITEMS               item rows (slot, armor, heavy, damage, effect, rarity...)
##   EQUIP_SLOTS         gear slot order from content
##   DEFAULT_LOOT_FILTER what shows on the floor before the player tunes it
##   ALL_ITEM_KEYS       every item key (filter sheet's "ALL" button)
## A new item is a data row in content.json — no code.

var ITEMS: Dictionary = {}
var EQUIP_SLOTS: Array = []
var DEFAULT_LOOT_FILTER: Array = []
var ALL_ITEM_KEYS: Array = []

## Pull the item slice out of the parsed content.json root.
func load_content(parsed: Dictionary) -> void:
	ITEMS = parsed.get("items", {})
	EQUIP_SLOTS = parsed.get("equipSlots", [])
	DEFAULT_LOOT_FILTER = parsed.get("defaultLootFilter", [])
	ALL_ITEM_KEYS = parsed.get("allItemKeys", [])

func item_def(key: String) -> Dictionary:
	return ITEMS.get(key, {})
