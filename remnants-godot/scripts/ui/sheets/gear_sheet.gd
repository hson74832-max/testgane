extends PanelContainer
## Equipment sheet: vocation path, derived stats, 8 slots, satchel spares.
## Armour is flat (a 17-damage Ember Husk hits for max(1, 17 - armour)) and
## heavy plate slows the step — both numbers stay on screen as decisions.
## Slot/spare cells, tooltips and drag-drop (spare -> slot equips, slot ->
## spare unequips) live in InventoryUI; this shell keeps path, stats, note.

const UiKit := preload("res://scripts/ui/ui_kit.gd")
const InventoryUIScript := preload("res://scripts/ui/inventory_ui.gd")

var world = null
var player = null
var sim = null
var S := 1.0
var inv: InventoryUIScript
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
	inv = InventoryUIScript.new()
	inv.setup(world, sim)
	inv.changed.connect(refresh)
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
	vb.add_child(UiKit.label("IN SATCHEL — tap to equip, or drag onto a slot", 14, S, Color(0.65, 0.68, 0.72)))
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
	inv.fill_gear_slots(_slots, S, SLOT_TITLES)
	inv.fill_spares(_spares, S)
	_note.text = "Armour is flat: a 17-damage Ember Husk hits for %d against your %d armour. Heavy plate slows your step — the Barrow punishes it." % [maxi(1, 17 - armor), armor]

func _on_path_pressed(key: String) -> void:
	if sim.set_vocation(key):
		world.buzz(20)
		world.notify("Path of the %s." % key)
	refresh()
