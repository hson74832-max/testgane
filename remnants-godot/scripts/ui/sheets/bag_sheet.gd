extends PanelContainer
## Satchel sheet: session inventory. Tap a consumable to drink it (roots
## 1.2s), tap gear to equip it, materials point at the web market.

const UiKit := preload("res://scripts/ui/ui_kit.gd")

var world = null
var player = null
var sim = null
var S := 1.0
var _gold: Label
var _grid: GridContainer

func setup(w, p, s, scale: float) -> void:
	world = w
	player = p
	sim = s
	S = scale
	UiKit.apply_sheet_geometry(self, S)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)
	var close_b := UiKit.sheet_head(vb, "SATCHEL", S)
	close_b.pressed.connect(func() -> void: visible = false)
	_gold = UiKit.label("", 17, S, Color(0.98, 0.75, 0.14))
	vb.add_child(_gold)
	vb.add_child(UiKit.label("Tap a consumable to drink it (roots 1.2s). Tap gear to equip.", 13, S, Color(0.65, 0.68, 0.72)))
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 6)
	vb.add_child(_grid)

func refresh() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_gold.text = "Carried gold: %dg — at risk until banked" % int(player.get("gold"))
	var satchel: Dictionary = sim.get("local_inventory")
	if satchel.is_empty():
		_grid.add_child(UiKit.label("Empty. Kill something.", 14, S, Color(0.55, 0.58, 0.62)))
		return
	for key in satchel.keys():
		var k := String(key)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 62.0 * S)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", UiKit.fs(13, S))
		if sim.is_consumable(k):
			b.text = "%s x%d\nUSE" % [String(GameBalance.item_def(k).get("name", k)), int(satchel[k])]
		elif sim.is_equippable(k):
			b.text = "%s x%d\nEQUIP" % [String(GameBalance.item_def(k).get("name", k)), int(satchel[k])]
		else:
			b.text = "%s x%d" % [String(GameBalance.item_def(k).get("name", k)), int(satchel[k])]
		b.pressed.connect(_on_item_pressed.bind(k))
		_grid.add_child(b)

func _on_item_pressed(item_key: String) -> void:
	if sim.is_consumable(item_key):
		if sim.use_consumable(item_key):
			world.buzz(20)
	elif sim.is_equippable(item_key):
		if sim.equip(item_key):
			world.buzz(16)
	else:
		world.mark_input()
		sim.toast.emit("Trade good — the market lives on web for now", "info")
	refresh()
