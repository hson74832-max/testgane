extends PanelContainer
## Equipment sheet: vocation path, derived stats, 8 slots, satchel spares.
## Armour is flat (a 17-damage Ember Husk hits for max(1, 17 - armour)) and
## heavy plate slows the step — both numbers stay on screen as decisions.

const UiKit := preload("res://scripts/ui/ui_kit.gd")

var world = null
var player = null
var sim = null
var S := 1.0
var _path_row: HBoxContainer
var _stats: Label
var _slots: GridContainer
var _spares: GridContainer
var _note: Label

const SLOT_TITLES: Dictionary = {
	"helmet": "Head", "amulet": "Neck", "armor": "Chest", "weapon": "Weapon",
	"shield": "Off-hand", "legs": "Legs", "boots": "Feet", "ring": "Ring",
}

func setup(w, p, s, scale: float) -> void:
	world = w
	player = p
	sim = s
	S = scale
	UiKit.apply_sheet_geometry(self, S)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)
	var close_b := UiKit.sheet_head(vb, "EQUIPMENT", S)
	close_b.pressed.connect(func() -> void: visible = false)
	_path_row = HBoxContainer.new()
	_path_row.add_theme_constant_override("separation", 8)
	vb.add_child(_path_row)
	_stats = UiKit.label("", 17, S, Color(0.85, 0.88, 0.92))
	vb.add_child(_stats)
	_slots = GridContainer.new()
	_slots.columns = 4
	_slots.add_theme_constant_override("h_separation", 8)
	_slots.add_theme_constant_override("v_separation", 6)
	vb.add_child(_slots)
	vb.add_child(UiKit.label("IN SATCHEL — tap to equip", 14, S, Color(0.65, 0.68, 0.72)))
	_spares = GridContainer.new()
	_spares.columns = 4
	_spares.add_theme_constant_override("h_separation", 8)
	_spares.add_theme_constant_override("v_separation", 6)
	vb.add_child(_spares)
	_note = UiKit.label("", 14, S, Color(0.65, 0.68, 0.72))
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_note)

func refresh() -> void:
	for c in _path_row.get_children():
		c.queue_free()
	for c in _slots.get_children():
		c.queue_free()
	for c in _spares.get_children():
		c.queue_free()
	var cur: String = String(sim.get("vocation"))
	for key in (sim.Vocations.order() as Array):
		var k := String(key)
		var vd: Dictionary = sim.Vocations.def(k)
		var pb := UiKit.big_button(String(vd["name"]).to_upper(), Color(0.5, 0.4, 0.2) if k == cur else Color(0.3, 0.35, 0.45), Vector2(0, 44), 14, S)
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.disabled = k == cur
		_path_row.add_child(pb)
		pb.pressed.connect(_on_path_pressed.bind(k))
	var armor: int = int(player.get("armor"))
	_stats.text = "Armor %d flat  ·  Weapon +%d  ·  Step %dms (%d heavy)" % [
		armor, int(player.get("weapon_damage")),
		GameBalance.step_ms_for(int(player.get("heavy"))), int(player.get("heavy"))]
	for slot in (sim.GEAR_ORDER as Array):
		var s := String(slot)
		var key: String = String((sim.get("equipped") as Dictionary).get(s, ""))
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 62.0 * S)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", UiKit.fs(13, S))
		if key == "":
			b.text = "%s\n— empty —" % SLOT_TITLES.get(s, s)
			b.disabled = true
		else:
			var def: Dictionary = GameBalance.item_def(key)
			b.text = "%s\n%s\nA%d H%d" % [SLOT_TITLES.get(s, s), String(def.get("name", key)), int(def.get("armor", 0)), int(def.get("heavy", 0))]
			b.pressed.connect(_on_slot_pressed.bind(s))
		_slots.add_child(b)
	var satchel: Dictionary = sim.get("local_inventory")
	var any := false
	for key in satchel.keys():
		var k := String(key)
		if not sim.is_equippable(k):
			continue
		any = true
		var def2: Dictionary = GameBalance.item_def(k)
		var b2 := Button.new()
		b2.custom_minimum_size = Vector2(0, 62.0 * S)
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b2.add_theme_font_size_override("font_size", UiKit.fs(13, S))
		b2.text = "%s x%d\nA%d H%d %s" % [String(def2.get("name", k)), int(satchel[k]), int(def2.get("armor", 0)), int(def2.get("heavy", 0)), ("+%ddmg" % int(def2.get("damage", 0))) if String(def2.get("slot", "")) == "weapon" else ""]
		b2.pressed.connect(_on_spare_pressed.bind(k))
		_spares.add_child(b2)
	if not any:
		_spares.add_child(UiKit.label("No spare gear — kills drop it.", 13, S, Color(0.55, 0.58, 0.62)))
	_note.text = "Armour is flat: a 17-damage Ember Husk hits for %d against your %d armour. Heavy plate slows your step — the Barrow punishes it." % [maxi(1, 17 - armor), armor]

func _on_slot_pressed(slot: String) -> void:
	sim.unequip(slot)
	world.buzz(12)
	refresh()

func _on_spare_pressed(item_key: String) -> void:
	if sim.equip(item_key):
		world.buzz(16)
	refresh()

func _on_path_pressed(key: String) -> void:
	if sim.set_vocation(key):
		world.buzz(20)
		world.notify("Path of the %s." % key)
	refresh()
