extends PanelContainer
## NPC dialog: trader (potions at base, loot at half), healer (mend 30g),
## ferryman (3 crossings, 10g). Rebuilt on every open and every deal.

const UiKit := preload("res://scripts/ui/ui_kit.gd")

var world = null
var player = null
var sim = null
var S := 1.0
var _body: VBoxContainer
var _current := {}

func setup(w, p, s, scale: float) -> void:
	world = w
	player = p
	sim = s
	S = scale
	UiKit.apply_sheet_geometry(self, S)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	add_child(_body)

func open(npc: Dictionary) -> void:
	_current = npc
	visible = true
	refresh()

func refresh() -> void:
	for c in _body.get_children():
		c.queue_free()
	var npcs = world.get("npcs")
	var close_b := UiKit.sheet_head(_body, String(_current.get("name", "Stranger")).to_upper(), S)
	close_b.pressed.connect(func() -> void: visible = false)
	_body.add_child(UiKit.label(String(_current.get("blurb", "")), 14, S, Color(0.85, 0.75, 0.5)))
	var role: String = String(_current.get("role", ""))
	if role == "trader":
		_refresh_trader(npcs)
	elif role == "healer":
		_refresh_healer(npcs)
	elif role == "ferry":
		_refresh_ferry(npcs)

func _refresh_trader(npcs) -> void:
	_body.add_child(UiKit.label("BUY — %dg in purse" % int(player.get("gold")), 15, S, Color(0.98, 0.75, 0.14)))
	for key in (npcs.stock() as Array):
		var k := String(key)
		var b := UiKit.big_button("%s — %dg" % [String(GameBalance.item_def(k).get("name", k)), npcs.price(k)], Color(0.2, 0.45, 0.3), Vector2(0, 44), 15, S)
		_body.add_child(b)
		b.pressed.connect(_on_buy.bind(k))
	_body.add_child(UiKit.label("SELL — half base, coin on the nail", 15, S, Color(0.75, 0.78, 0.82)))
	var satchel: Dictionary = sim.get("local_inventory")
	if satchel.is_empty():
		_body.add_child(UiKit.label("Satchel empty.", 14, S, Color(0.55, 0.58, 0.62)))
		return
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 150.0 * S)
	_body.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for key in satchel.keys():
		var k2 := String(key)
		var b2 := UiKit.big_button("%s x%d +%dg" % [String(GameBalance.item_def(k2).get("name", k2)), int(satchel[k2]), (world.get("npcs") as Node).sell_value(k2)], Color(0.35, 0.3, 0.25), Vector2(0, 40), 13, S)
		grid.add_child(b2)
		b2.pressed.connect(_on_sell.bind(k2))

func _refresh_healer(npcs) -> void:
	_body.add_child(UiKit.label("Mending: full HP + purge poison, burn, slow.", 14, S, Color(0.75, 0.78, 0.82)))
	var hb := UiKit.big_button("BE MENDED — %dg" % npcs.heal_cost(), Color(0.15, 0.55, 0.35), Vector2(0, 56), 17, S)
	_body.add_child(hb)
	hb.pressed.connect(func() -> void:
		if npcs.heal():
			world.buzz(20)
		refresh()
	)

func _refresh_ferry(npcs) -> void:
	_body.add_child(UiKit.label("Crossings — %dg a trip, %dg in purse" % [npcs.ferry_cost(), int(player.get("gold"))], 15, S, Color(0.98, 0.75, 0.14)))
	for d in (npcs.ferry as Array):
		var dk := String(d["key"])
		var fb := UiKit.big_button("Sail: %s — %dg" % [String(d["name"]), npcs.ferry_cost()], Color(0.2, 0.35, 0.55), Vector2(0, 52), 16, S)
		_body.add_child(fb)
		fb.pressed.connect(_on_ferry.bind(dk))

func _on_buy(item_key: String) -> void:
	var npcs = world.get("npcs")
	if npcs.buy(item_key):
		world.buzz(16)
		world.notify("Bought %s." % item_key)
	refresh()

func _on_sell(item_key: String) -> void:
	var npcs = world.get("npcs")
	if npcs.sell(item_key) >= 0:
		world.buzz(12)
		world.notify("Sold %s." % item_key)
	refresh()

func _on_ferry(dest_key: String) -> void:
	var npcs = world.get("npcs")
	if npcs.travel(dest_key):
		world.buzz(25)
		world.notify("Ferried across.")
		visible = false
