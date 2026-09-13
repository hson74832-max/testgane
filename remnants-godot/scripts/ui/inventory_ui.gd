extends RefCounted
## InventoryUI — dedicated controller for the satchel + equipment grids:
## cell building, tooltips, drag-drop and the tap actions. The sheets keep
## their chrome (head, path row, notes); every item interaction routes here.
## Drag-drop works inside the Equipment sheet (spares -> slot to equip,
## slot -> spare to unequip); sheets are exclusive so cross-sheet drags are
## impossible by design, and the satchel keeps its tap-to-equip flow.
## `changed` fires after any inventory mutation — sheets re-render on it.

signal changed

const UiKit := preload("res://scripts/ui/ui_kit.gd")
const SlotScript := preload("res://scripts/ui/inventory_slot.gd")

var world = null
var sim = null

func setup(p_world, p_sim) -> void:
	world = p_world
	sim = p_sim

# ---- bag sheet ----------------------------------------------------------------
func fill_bag(grid: GridContainer, S: float) -> void:
	for c in grid.get_children():
		c.queue_free()
	var satchel: Dictionary = sim.get("local_inventory")
	if satchel.is_empty():
		grid.add_child(UiKit.label("Empty. Kill something.", 14, S, Color(0.55, 0.58, 0.62)))
		return
	for key in satchel.keys():
		var k := String(key)
		var action := "USE" if sim.is_consumable(k) else ("EQUIP" if sim.is_equippable(k) else "")
		var text := "%s x%d" % [String(GameBalance.item_def(k).get("name", k)), int(satchel[k])]
		if action != "":
			text += "\n" + action
		var cell := make_cell(text, tooltip(k), {"kind": "bag_item", "item_key": k, "label": String(GameBalance.item_def(k).get("name", k))}, S)
		cell.pressed.connect(on_bag_tap.bind(k))
		grid.add_child(cell)

## Tap semantics (unchanged): drink consumables, equip gear, materials point
## at the web market.
func on_bag_tap(item_key: String) -> void:
	if sim.is_consumable(item_key):
		if sim.use_consumable(item_key):
			world.buzz(20)
	elif sim.is_equippable(item_key):
		if sim.equip(item_key):
			world.buzz(16)
	else:
		world.mark_input()
		sim.toast.emit("Trade good — the market lives on web for now", "info")
	changed.emit()

# ---- gear sheet ----------------------------------------------------------------
func fill_gear_slots(grid: GridContainer, S: float, slot_titles: Dictionary) -> void:
	for c in grid.get_children():
		c.queue_free()
	for slot in (sim.GEAR_ORDER as Array):
		var s := String(slot)
		var key: String = String((sim.get("equipped") as Dictionary).get(s, ""))
		var b: Button = SlotScript.new()
		b.custom_minimum_size = Vector2(0, 62.0 * S)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", UiKit.fs(13, S))
		b.inv = self
		if key == "":
			b.text = "%s\n— empty —" % slot_titles.get(s, s)
			b.disabled = true  # parity: nothing to unequip; not a drop target
		else:
			var def: Dictionary = GameBalance.item_def(key)
			b.text = "%s\n%s\nA%d H%d" % [slot_titles.get(s, s), String(def.get("name", key)), int(def.get("armor", 0)), int(def.get("heavy", 0))]
			b.tooltip_text = tooltip(key)
			b.payload = {"kind": "gear_slot", "slot": s, "item_key": key, "label": String(def.get("name", key))}
			b.pressed.connect(unequip_slot.bind(s))
		grid.add_child(b)

func fill_spares(grid: GridContainer, S: float) -> void:
	for c in grid.get_children():
		c.queue_free()
	var satchel: Dictionary = sim.get("local_inventory")
	var any := false
	for key in satchel.keys():
		var k := String(key)
		if not sim.is_equippable(k):
			continue
		any = true
		var def: Dictionary = GameBalance.item_def(k)
		var text := "%s x%d\nA%d H%d %s" % [
			String(def.get("name", k)), int(satchel[k]),
			int(def.get("armor", 0)), int(def.get("heavy", 0)),
			("+%ddmg" % int(def.get("damage", 0))) if String(def.get("slot", "")) == "weapon" else ""]
		var cell := make_cell(text, tooltip(k), {"kind": "bag_item", "item_key": k, "label": String(def.get("name", k))}, S)
		cell.pressed.connect(on_bag_tap.bind(k))
		grid.add_child(cell)
	if not any:
		grid.add_child(UiKit.label("No spare gear — kills drop it.", 13, S, Color(0.55, 0.58, 0.62)))

func unequip_slot(slot: String) -> void:
	sim.unequip(slot)
	world.buzz(12)
	changed.emit()

# ---- drag-drop ------------------------------------------------------------------
## bag_item -> matching gear slot equips it; gear slot -> any satchel cell
## unequips it. Everything else is refused.
func can_drop(target: Dictionary, data) -> bool:
	var d: Dictionary = data if typeof(data) == TYPE_DICTIONARY else {}
	var tgt := String(target.get("kind", ""))
	var src := String(d.get("kind", ""))
	if tgt == "gear_slot" and src == "bag_item":
		var item: String = String(d.get("item_key", ""))
		return String((GameBalance.item_def(item) as Dictionary).get("slot", "")) == String(target.get("slot", ""))
	if tgt == "bag_item" and src == "gear_slot":
		return true
	return false

func drop(target: Dictionary, data) -> void:
	var d: Dictionary = data if typeof(data) == TYPE_DICTIONARY else {}
	if String(target.get("kind", "")) == "gear_slot" and String(d.get("kind", "")) == "bag_item":
		equip_item(String(d.get("item_key", "")))
	elif String(target.get("kind", "")) == "bag_item" and String(d.get("kind", "")) == "gear_slot":
		unequip_slot(String(d.get("slot", "")))

func equip_item(item_key: String) -> void:
	if sim.equip(item_key):
		world.buzz(16)
	changed.emit()

# ---- shared -----------------------------------------------------------------------
func make_cell(text: String, tip: String, cell_payload: Dictionary, S: float) -> Button:
	var b: Button = SlotScript.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 62.0 * S)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", UiKit.fs(13, S))
	b.tooltip_text = tip
	b.payload = cell_payload
	b.inv = self
	return b

## Item stat sheet for hover (desktop) — plain text, one line per stat.
func tooltip(item_key: String) -> String:
	var def: Dictionary = GameBalance.item_def(item_key)
	var lines: Array = [String(def.get("name", item_key))]
	var slot := String(def.get("slot", ""))
	if slot != "":
		lines.append("Slot: %s" % slot)
	if int(def.get("armor", 0)) > 0:
		lines.append("Armour +%d" % int(def["armor"]))
	if int(def.get("heavy", 0)) > 0:
		lines.append("Heavy +%d (slows step)" % int(def["heavy"]))
	if slot == "weapon" and int(def.get("damage", 0)) > 0:
		lines.append("Damage +%d" % int(def["damage"]))
	var fx: Dictionary = def.get("effect", {})
	if int(fx.get("hp", 0)) > 0:
		lines.append("Restores %d HP (roots you)" % int(fx["hp"]))
	if int(fx.get("mana", 0)) > 0:
		lines.append("Restores %d mana (roots you)" % int(fx["mana"]))
	lines.append("Base price %dg" % int(def.get("basePrice", 1)))
	return "\n".join(lines)
