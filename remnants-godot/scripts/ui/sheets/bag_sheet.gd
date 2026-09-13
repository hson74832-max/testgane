extends PanelContainer
## Satchel sheet: session inventory. Tap a consumable to drink it (roots
## 1.2s), tap gear to equip it, materials point at the web market. The grid,
## tooltips and interactions live in InventoryUI — this shell keeps the
## sheet chrome and the gold line.

const UiKit := preload("res://scripts/ui/ui_kit.gd")
const InventoryUIScript := preload("res://scripts/ui/inventory_ui.gd")

var world = null
var player = null
var sim = null
var S := 1.0
var inv: InventoryUIScript
var _gold: Label
var _grid: GridContainer

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
	_gold.text = "Carried gold: %dg — at risk until banked" % int(player.get("gold"))
	inv.fill_bag(_grid, S)
