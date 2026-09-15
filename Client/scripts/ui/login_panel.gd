# Login + character select against the MockDB (account auth, character list,
# creation). Full-screen overlay; the shell hides it on entering the world.
class_name BlackTekLoginPanel
extends RefCounted

var hud: Control
var game: BlackTekGameServer
var root: Control
var account_edit: LineEdit
var pass_edit: LineEdit
var login_error: Label
var char_list: ItemList
var create_name: LineEdit
var create_voc: OptionButton

func build(h: Control) -> void:
	hud = h
	game = hud.game
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.04, 0.06)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", BlackTekUiKit.panel_style())
	center.add_child(card)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(380, 0)
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	BlackTekUiKit.label(box, "BlackTek Demo Client", 22)
	BlackTekUiKit.label(box, "Connected to MockDB (offline test server) — no MariaDB", 11, Color(0.65, 0.68, 0.75))
	var acc_row := HBoxContainer.new()
	box.add_child(acc_row)
	BlackTekUiKit.label(acc_row, "Account:", 12).custom_minimum_size = Vector2(80, 0)
	account_edit = LineEdit.new()
	account_edit.text = "demo"
	acc_row.add_child(account_edit)
	var pass_row := HBoxContainer.new()
	box.add_child(pass_row)
	BlackTekUiKit.label(pass_row, "Password:", 12).custom_minimum_size = Vector2(80, 0)
	pass_edit = LineEdit.new()
	pass_edit.text = "demo"
	pass_edit.secret = true
	pass_row.add_child(pass_edit)
	var login_btn := Button.new()
	login_btn.text = "Log in"
	login_btn.add_theme_font_size_override("font_size", 14)
	login_btn.pressed.connect(_on_login_pressed)
	box.add_child(login_btn)
	login_error = BlackTekUiKit.label(box, " ", 11, Color("ff6b6b"))
	BlackTekUiKit.label(box, "Characters", 13, BlackTekUiKit.ACCENT)
	char_list = ItemList.new()
	char_list.custom_minimum_size = Vector2(0, 84)
	char_list.add_theme_font_size_override("font_size", 12)
	box.add_child(char_list)
	BlackTekUiKit.label(box, "Hint: press Log in first (demo/demo pre-filled), pick a character, Enter world.", 10, Color(0.55, 0.58, 0.66))
	var play := Button.new()
	play.text = "Enter world"
	play.add_theme_font_size_override("font_size", 14)
	play.pressed.connect(_on_play_pressed)
	box.add_child(play)
	box.add_child(HSeparator.new())
	BlackTekUiKit.label(box, "Create new character", 13, BlackTekUiKit.ACCENT)
	var name_row := HBoxContainer.new()
	box.add_child(name_row)
	create_name = LineEdit.new()
	create_name.placeholder_text = "Character name"
	create_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(create_name)
	create_voc = OptionButton.new()
	for v in [4, 1, 3, 2]:
		create_voc.add_item(BlackTekVitals.vocation_name(game, v), v)
	name_row.add_child(create_voc)
	var create := Button.new()
	create.text = "Create"
	create.pressed.connect(_on_create_pressed)
	box.add_child(create)

func _fill_char_list() -> void:
	char_list.clear()
	for row in game.character_list():
		var idx := char_list.add_item("%s — %s, level %d" % [String(row.name), BlackTekVitals.vocation_name(game, int(row.vocation)), int(row.level)])
		char_list.set_item_metadata(idx, row)
	if char_list.item_count > 0:
		char_list.select(0)

func _on_login_pressed() -> void:
	if game.login_account(account_edit.text.strip_edges(), pass_edit.text):
		login_error.text = " "
		_fill_char_list()

func _on_play_pressed() -> void:
	var sel := char_list.get_selected_items()
	if sel.is_empty():
		login_error.text = "Log in and select a character first."
		return
	var row: Dictionary = char_list.get_item_metadata(sel[0])
	game.enter_world(row)
	hud._enter_game_mode(true)

func _on_create_pressed() -> void:
	var row := game.create_character(create_name.text.strip_edges(), create_voc.get_item_id(create_voc.selected))
	if row.is_empty():
		return # login_error signal already surfaced the reason
	game.db.save_db()
	_fill_char_list()
	login_error.text = "Created %s." % String(row.name)
