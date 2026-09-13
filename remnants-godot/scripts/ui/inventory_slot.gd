extends Button
## One inventory/gear cell. A plain Button extended with Godot's drag-and-drop
## virtuals so InventoryUI can wire satchel <-> equipment drags without
## per-sheet code. `payload` conventions (set by InventoryUI):
##   {kind: "bag_item", item_key: String, label: String}   satchel stack
##   {kind: "gear_slot", slot: String, item_key: String}   equipment slot
## Empty slots keep disabled=true (tap parity), which also opts them out of
## drag-drop; dragging lives between filled cells and drop targets.

var payload := {}
var inv = null  # InventoryUI — handles can_drop/drop

func _get_drag_data(_at: Vector2):
	var kind := String(payload.get("kind", ""))
	if kind == "":
		return null
	if kind == "gear_slot" and String(payload.get("item_key", "")) == "":
		return null  # nothing in the slot to drag
	var l := Label.new()
	l.text = String(payload.get("label", ""))
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	var wrap := Control.new()
	wrap.add_child(l)
	set_drag_preview(wrap)
	return payload

func _can_drop_data(_at: Vector2, data) -> bool:
	if inv == null:
		return false
	return inv.can_drop(payload, data)

func _drop_data(_at: Vector2, data) -> void:
	inv.drop(payload, data)
