# BlackTek item data: tooltip text + stat lookups (attack/armor/heal/mana/food).
# Stateless — values come from BlackTekConfig (data/item_stats.toml), so adding
# an item is a TOML edit. Weight still comes from assets/items.toml via dat.
class_name BlackTekItemData
extends RefCounted

static func stats(game, itemtype: int) -> Dictionary:
	return (game.config as BlackTekConfig).stat(itemtype)

static func text(game, itemtype: int) -> String:
	var lines: Array = []
	var st: Dictionary = stats(game, itemtype)
	if st.has("atk"):
		lines.append("Attack: +%d%s" % [int(st.atk), " (magic)" if bool(st.get("magic", false)) else ""])
	if st.has("armor"):
		lines.append("Defense: +%d%s" % [int(st.armor), " (shield)" if bool(st.get("shield", false)) else ""])
	if st.has("heal"):
		lines.append("Heals %d-%d hitpoints" % [int(st.heal[0]), int(st.heal[1])])
	if st.has("mana"):
		lines.append("Restores %d-%d mana" % [int(st.mana[0]), int(st.mana[1])])
	if bool(st.get("food", false)):
		lines.append("Food - speeds up regeneration")
	if st.has("quest"):
		lines.append("Quest item")
	if game.dat != null:
		var w: int = (game.dat as BlackTekDat).item_weight(itemtype)
		if w > 0:
			lines.append("Weight: %.2f oz" % (w / 100.0))
	return "\n".join(lines)
