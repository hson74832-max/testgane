extends PanelContainer
## Loot filter sheet. Unchecked items are invisible on the floor and skipped
## by pick-up — the single biggest readability lever on a phone screen.

const UiKit := preload("res://scripts/ui/ui_kit.gd")

var world: WorldView = null
var sim: CombatSim = null
var S := 1.0
var _grid: GridContainer
var _pickup_check: CheckButton
var _attack_check: CheckButton

func setup(w, _p, s, scale: float) -> void:
	world = w
	sim = s
	S = scale
	UiKit.apply_sheet_geometry(self, S)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)
	var close_b := UiKit.sheet_head(vb, "LOOT FILTER", S)
	close_b.pressed.connect(func() -> void: visible = false)
	var toggles := HBoxContainer.new()
	toggles.add_theme_constant_override("separation", 16)
	vb.add_child(toggles)
	_pickup_check = CheckButton.new()
	_pickup_check.text = "Auto pick-up"
	_pickup_check.add_theme_font_size_override("font_size", UiKit.fs(15, S))
	_pickup_check.button_pressed = true
	toggles.add_child(_pickup_check)
	_pickup_check.toggled.connect(func(on: bool) -> void: sim.set_auto_pickup(on))
	_attack_check = CheckButton.new()
	_attack_check.text = "Auto attack tick"
	_attack_check.add_theme_font_size_override("font_size", UiKit.fs(15, S))
	_attack_check.button_pressed = true
	toggles.add_child(_attack_check)
	_attack_check.toggled.connect(func(on: bool) -> void: sim.set_auto_attack(on))
	vb.add_child(UiKit.label("Unchecked items are invisible on the floor and skipped by pick-up.", 13, S, Color(0.65, 0.68, 0.72)))
	var quick := HBoxContainer.new()
	quick.add_theme_constant_override("separation", 8)
	vb.add_child(quick)
	var all_b := UiKit.big_button("ALL", Color(0.3, 0.35, 0.45), Vector2(90, 40), 14, S)
	quick.add_child(all_b)
	all_b.pressed.connect(func() -> void:
		sim.set_loot_filter(GameBalance.ALL_ITEM_KEYS.duplicate())
		refresh()
	)
	var rec_b := UiKit.big_button("REC", Color(0.3, 0.5, 0.35), Vector2(90, 40), 14, S)
	quick.add_child(rec_b)
	rec_b.pressed.connect(func() -> void:
		sim.set_loot_filter(GameBalance.DEFAULT_LOOT_FILTER.duplicate())
		refresh()
	)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380.0 * S)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 4)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

func refresh() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_pickup_check.set_pressed_no_signal(bool(sim.get("auto_pickup")))
	_attack_check.set_pressed_no_signal(bool(sim.get("auto_attack")))
	var filt: Array = sim.get("loot_filter")
	var satchel: Dictionary = sim.get("local_inventory")
	for key in (GameBalance.ALL_ITEM_KEYS as Array):
		var k := String(key)
		var def: Dictionary = GameBalance.item_def(k)
		var held: int = int(satchel.get(k, 0))
		var cb := CheckButton.new()
		cb.text = "%s%s" % [String(def.get("name", k)), (" x%d" % held) if held > 0 else ""]
		cb.button_pressed = filt.has(k)
		cb.add_theme_color_override("font_color", sim._rarity_color(k))
		cb.add_theme_font_size_override("font_size", UiKit.fs(15, S))
		_grid.add_child(cb)
		cb.toggled.connect(_on_filter_toggled.bind(k))

func _on_filter_toggled(on: bool, item_key: String) -> void:
	var cur: Array = (sim.get("loot_filter") as Array).duplicate()
	if on and not cur.has(item_key):
		cur.append(item_key)
	elif not on and cur.has(item_key):
		cur.erase(item_key)
	sim.set_loot_filter(cur)
