extends PanelContainer
## Skill sheet: one point per level, five tracks. Points never expire.

const UiKit := preload("res://scripts/ui/ui_kit.gd")

var world: WorldView = null
var player: PlayerGrid = null
var sim: CombatSim = null
var S := 1.0
var _body: VBoxContainer

func setup(w, p, s, scale: float) -> void:
	world = w
	player = p
	sim = s
	S = scale
	UiKit.apply_sheet_geometry(self, S)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	add_child(_body)

func refresh() -> void:
	for c in _body.get_children():
		c.queue_free()
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	_body.add_child(head)
	var title := UiKit.label("SKILLS", 20, S)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(UiKit.label("%d pt" % int(player.get("skill_points")), 20, S, Color(1.0, 0.82, 0.4)))
	var close_b := UiKit.big_button("X", Color(0.5, 0.3, 0.3), Vector2(56, 40), 16, S)
	head.add_child(close_b)
	close_b.pressed.connect(func() -> void: visible = false)
	_body.add_child(UiKit.label("One point per level. Spend it — points never expire.", 13, S, Color(0.65, 0.68, 0.72)))
	var ranks: Dictionary = player.get("skills")
	for key in (GameBalance.SKILL_ORDER as Array):
		var k := String(key)
		var def: Dictionary = (GameBalance.SKILLS as Dictionary)[k]
		var rank: int = int(ranks.get(k, 0))
		var cap: int = int(def["max"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_body.add_child(row)
		var info := UiKit.label("%s  %s\n%s" % [String(def["name"]), "●".repeat(rank) + "○".repeat(maxi(0, cap - rank)), String(def["desc"])], 15, S)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var take := UiKit.big_button("TAKE", Color(0.2, 0.5, 0.3), Vector2(96, 48), 15, S)
		take.disabled = rank >= cap or int(player.get("skill_points")) < 1
		row.add_child(take)
		take.pressed.connect(_on_take.bind(k))

func _on_take(key: String) -> void:
	if sim.spend_skill(key) >= 0:
		world.buzz(20)
		world.notify("Skill taken.")
	refresh()
