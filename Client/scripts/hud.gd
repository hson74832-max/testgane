# Modern HUD/UX for the BlackTek demo client (OTClient-style modules, rebuilt
# as Godot Controls): login/character select against the MockDB, HP/Mana/XP
# status bars, equipment+backpack gear panel, skills/stats panel, action
# hotbar with cooldowns, target frame and NPC shop. All server calls go
# through the BlackTekGameServer (game) — swap for TCP later.
class_name BlackTekHud
extends Control

signal chat_submitted(text: String)
signal hotbar_command(cmd: Dictionary) # {kind: "item", itemtype} | {kind: "spell", spell} | {kind: "attack"}

const HP_COLOR := Color("e5484d")
const MP_COLOR := Color("3b82f6")
const XP_COLOR := Color("a855f7")
const PANEL_BG := Color(0.055, 0.065, 0.095, 0.93)
const PANEL_BORDER := Color(1, 1, 1, 0.09)
const SLOT_BG := Color(0.09, 0.1, 0.14, 0.9)
const ACCENT := Color(0.25, 0.8, 0.72)
const GOLD_COLOR := Color("f5d76e")

# itemtype -> equipment slot (cf. CONST_SLOT_* in the server).
# Classic Tibia equipment layout (slot ids): amulet/head/backpack,
# right/armor/left, ring/legs/ammo, feet.
const SLOT_LAYOUT := [[2, 1, 3], [5, 4, 6], [9, 7, 10], [-1, 8, -1]]
const SLOT_NAMES := {1: "Head", 2: "Amulet", 3: "Backpack", 4: "Armor", 5: "Right hand", 6: "Left hand", 7: "Legs", 8: "Feet", 9: "Ring", 10: "Ammo"}
const SKILL_ORDER := ["fist", "club", "sword", "axe", "dist", "shield", "fishing"]
const SKILL_LABELS := {"fist": "Fist", "club": "Club", "sword": "Sword", "axe": "Axe", "dist": "Distance", "shield": "Shielding", "fishing": "Fishing"}
# Action bars: "item" slots use the first matching stack in the backpack,
# "spell" slots cast. Right-click a slot to cycle its binding, or drag an item
# from the backpack onto a slot to assign it.
const HOTBAR_BARS := [
	{"title": "Potions", "slots": [
		{"kind": "item", "value": 2666, "hotkey": "F1"},
		{"kind": "item", "value": 7618, "hotkey": "F2"},
		{"kind": "item", "value": 7620, "hotkey": "F3"},
	]},
	{"title": "Spells", "slots": [
		{"kind": "spell", "value": "exura", "hotkey": "F4"},
		{"kind": "spell", "value": "flame", "hotkey": "F5"},
		{"kind": "attack", "value": "attack", "hotkey": "F6"},
	]},
	{"title": "Test Spells", "slots": [
		{"kind": "spell", "value": "utevo lux", "hotkey": "F7"},
		{"kind": "spell", "value": "exana pox", "hotkey": "F8"},
		{"kind": "spell", "value": "exori", "hotkey": "F9"},
	]},
]
const SPELL_INFO := {
	"exura": {"label": "Exura", "glyph": "✚"},
	"flame": {"label": "Flame Strike", "glyph": "✦"},
	"attack": {"label": "Attack", "glyph": "⚔"},
	"utevo lux": {"label": "Magic Light", "glyph": "☀"},
	"exana pox": {"label": "Cure Poison", "glyph": "❀"},
	"exori": {"label": "Whirlwind", "glyph": "🌀"},
	"exura gran": {"label": "Greater Heal", "glyph": "✛"},
}

var game: BlackTekGameServer
var _pid := 1
var in_game := false

# --- login ---
var _login: Control
var _account_edit: LineEdit
var _pass_edit: LineEdit
var _login_error: Label
var _char_list: ItemList
var _create_name: LineEdit
var _create_voc: OptionButton
# --- status ---
var _status_panel: PanelContainer
var _name_label: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _mp_bar: ProgressBar
var _mp_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
# --- chat ---
var _chat_panel: PanelContainer
var _chat_log: RichTextLabel # "All" tab (kept name for compatibility)
var _chat_edit: LineEdit
var _chat_tabs: Dictionary = {} # tab name -> RichTextLabel
var _chat_tab_btns: Array = [] # {btn, name}
var _chat_tab := "All"
var _chat_pages: Control
# --- gear ---
var _gear_grid: GridContainer
var _bag_grid: GridContainer
var _equip_nodes: Dictionary = {}
var _bag_nodes: Dictionary = {}
var _gold_label: Label
# --- stats ---
var _stats_panel: PanelContainer
var _stats_box: VBoxContainer
# --- target / shop ---
var _shop_panel: PanelContainer
var _shop_gold: Label
var _shop_rows: VBoxContainer
var _shop_offer_rows: Array = []
var _shop_qty := 1
var _shop_qty_label: Label
var _shop_far_warned := false
# --- hotbar / rail ---
var _hotbar_slots: Array = []
var _rail_panel: PanelContainer
var _drag: Dictionary = {} # panel -> Vector2 grab offset (while dragging)
var _hotbar_wrap: Control
var _hud_surfaces: Array = []
var _idle_time := 0.0
var _ui_alpha := 1.0
var _cond_row: HBoxContainer
var _minimap_panel: PanelContainer
var _minimap_view: Control
var _minimap_clock := 0.0
var _opt_retro: CheckButton
var _opt_pixels: Button
var _settings_panel: PanelContainer
var _fps_label: Label
var _fps_clock := 0.0
# Inventory drag tracking for floor drops: the source button announces the
# drag, inventory moves mark it accepted, anything else released over the
# world becomes a drop. game_view is wired by main (untyped: view owns HUD).
var game_view = null
var drag_from := {}
var drag_accepted := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = BlackTekUiKit.pixel_theme()
	_build_login()
	_build_status()
	_build_chat()
	_build_hotbar()
	_build_rail()
	_build_settings()
	gear_panel.build(self)
	_build_stats()
	_build_shop()
	_fps_label = Label.new()
	_fps_label.add_theme_font_size_override("font_size", 11)
	_fps_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fps_label.position = Vector2(10, 8)
	_fps_label.visible = false
	add_child(_fps_label)
	# Weather/floor overlays live above the panels, below the login screen.
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_rect)
	_enter_game_mode(false)

var _ui_clock := 0.0

var _flash_rect: ColorRect
var _fade_rect: ColorRect
var _flash_a := 0.0
var _fade_a := 0.0

func flash(strength := 0.5) -> void:
	_flash_a = maxf(_flash_a, strength)

func fade(strength := 0.65) -> void:
	_fade_a = maxf(_fade_a, strength)

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseMotion or event is InputEventMouseButton:
		_idle_time = 0.0

func _process(delta: float) -> void:
	_update_hotbar_cooldowns()
	# Auto-hide: fade the whole HUD out after 10s without input, back on input.
	if in_game:
		_idle_time += delta
		var target := 0.0 if _idle_time > 10.0 else 1.0
		_ui_alpha = move_toward(_ui_alpha, target, delta * 2.5)
		for c in [_status_panel, _chat_panel, _rail_panel, _hotbar_wrap, gear_panel.panel, _stats_panel, _shop_panel, _minimap_panel, _settings_panel, _fps_label]:
			if c != null:
				c.modulate.a = _ui_alpha
	_fps_clock += delta
	if _fps_clock >= 0.5:
		_fps_clock = 0.0
		if _fps_label != null:
			_fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	if _flash_a > 0.0 or _fade_a > 0.0:
		_flash_a = maxf(0.0, _flash_a - delta * 1.3)
		_fade_a = maxf(0.0, _fade_a - delta * 1.5)
		if _flash_rect != null:
			_flash_rect.color = Color(1, 1, 1, _flash_a * 0.75)
		if _fade_rect != null:
			_fade_rect.color = Color(0, 0, 0, _fade_a)
	# Live-refresh UI even outside combat events (gold/cap pick-up, regen, etc.).
	_ui_clock += delta
	if _ui_clock >= 0.5:
		_ui_clock = 0.0
		if game.players.is_empty():
			return
		update_status()
		if _stats_panel.visible:
			refresh_stats()
		if _shop_panel.visible:
			# NPC trade window is proximity-bound: walking away closes it so
			# it can't be kept open as a remote supply window.
			if not game.can_trade_with_npc(_pid):
				hide_panel(_shop_panel)
				if not _shop_far_warned:
					_shop_far_warned = true
					game.message_local(_pid, "You walked too far from Norf — trade closed.")
			else:
				_shop_far_warned = false
				refresh_shop_gold()
	# Minimap repaints on its own cadence while visible.
	if _minimap_panel != null and _minimap_panel.visible:
		_minimap_clock += delta
		if _minimap_clock >= 0.4:
			_minimap_clock = 0.0
			_minimap_view.queue_redraw()

# ---- shared styles -----------------------------------------------------------
# Static panel header: title label, minimize + close buttons, drag handle.
# Both buttons hide the panel; it reopens from the right-rail icons (or the
# G/K/T/M/O hotkeys). Panels are never collapsed.
func panel_header(panel: PanelContainer, box: VBoxContainer, title: String) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	header.tooltip_text = "Drag to move - release to drop on the grid"
	var lab := BlackTekUiKit.label(header, title, 13, ACCENT)
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_header_btn("-", "Minimize to the title bar", func(): _toggle_minimize(panel, box)))
	header.add_child(_header_btn("X", "Close panel (reopen from the right rail)", func(): panel.visible = false))
	box.add_child(header)
	box.move_child(header, 0)
	BlackTekUiKit.make_drag_handle(panel, header)

# Minimize toggles a panel between its full rect and title-bar-only form.
# Visibility-only plus one height change in absolute screen coordinates, so
# it can never wander off-screen; dragging while minimized keeps working and
# restoring keeps the current position (only the height snaps back).
func _toggle_minimize(panel: PanelContainer, box: VBoxContainer) -> void:
	if panel.has_meta("minimized"):
		panel.remove_meta("minimized")
		var h_full: float = float(panel.get_meta("min_h_full", 320.0))
		var vis: Array = panel.get_meta("min_vis", [])
		panel.offset_bottom = panel.offset_top + h_full
		for i in range(box.get_child_count()):
			if i == 0:
				continue
			box.get_child(i).visible = vis.has(i)
		panel.remove_meta("min_vis")
		panel.remove_meta("min_h_full")
		_clamp_panel(panel) # restoring grows downward: stay inside
		return
	var r := panel.get_global_rect()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = r.position.x
	panel.offset_top = r.position.y
	panel.offset_right = r.position.x + r.size.x
	panel.offset_bottom = r.position.y + r.size.y
	var shown := []
	for i in range(box.get_child_count()):
		if i == 0:
			continue
		var c: Control = box.get_child(i)
		if c.visible:
			shown.append(i)
		c.visible = false
	panel.set_meta("min_vis", shown)
	panel.set_meta("min_h_full", r.size.y)
	panel.offset_bottom = panel.offset_top + maxf(40.0, panel.get_combined_minimum_size().y)
	panel.set_meta("minimized", true)

static func _header_btn(text: String, tip: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tip
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(on_press)
	return b

# Drag handle: press -> convert panel to free-floating rect, motion -> follow
# mouse, release -> drop on the invisible 16px grid.

func _build_login() -> void:
	_login = Control.new()
	_login.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_login.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_login)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.04, 0.06)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_login.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_login.add_child(center)
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
	_account_edit = LineEdit.new()
	_account_edit.text = "demo"
	acc_row.add_child(_account_edit)
	var pass_row := HBoxContainer.new()
	box.add_child(pass_row)
	BlackTekUiKit.label(pass_row, "Password:", 12).custom_minimum_size = Vector2(80, 0)
	_pass_edit = LineEdit.new()
	_pass_edit.text = "demo"
	_pass_edit.secret = true
	pass_row.add_child(_pass_edit)
	var login_btn := Button.new()
	login_btn.text = "Log in"
	login_btn.add_theme_font_size_override("font_size", 14)
	login_btn.pressed.connect(_on_login_pressed)
	box.add_child(login_btn)
	_login_error = BlackTekUiKit.label(box, " ", 11, Color("ff6b6b"))
	BlackTekUiKit.label(box, "Characters", 13, ACCENT)
	_char_list = ItemList.new()
	_char_list.custom_minimum_size = Vector2(0, 84)
	_char_list.add_theme_font_size_override("font_size", 12)
	box.add_child(_char_list)
	BlackTekUiKit.label(box, "Hint: press Log in first (demo/demo pre-filled), pick a character, Enter world.", 10, Color(0.55, 0.58, 0.66))
	var play := Button.new()
	play.text = "Enter world"
	play.add_theme_font_size_override("font_size", 14)
	play.pressed.connect(_on_play_pressed)
	box.add_child(play)
	box.add_child(HSeparator.new())
	BlackTekUiKit.label(box, "Create new character", 13, ACCENT)
	var name_row := HBoxContainer.new()
	box.add_child(name_row)
	_create_name = LineEdit.new()
	_create_name.placeholder_text = "Character name"
	_create_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_create_name)
	_create_voc = OptionButton.new()
	for v in [4, 1, 3, 2]:
		_create_voc.add_item(BlackTekGameServer.VOCATIONS[v].name, v)
	name_row.add_child(_create_voc)
	var create := Button.new()
	create.text = "Create"
	create.pressed.connect(_on_create_pressed)
	box.add_child(create)

func _fill_char_list() -> void:
	_char_list.clear()
	for row in game.character_list():
		var voc: Dictionary = BlackTekGameServer.VOCATIONS[int(row.vocation)]
		var idx := _char_list.add_item("%s — %s, level %d" % [String(row.name), voc.name, int(row.level)])
		_char_list.set_item_metadata(idx, row)
	if _char_list.item_count > 0:
		_char_list.select(0)

func _on_login_pressed() -> void:
	if game.login_account(_account_edit.text.strip_edges(), _pass_edit.text):
		_login_error.text = " "
		_fill_char_list()

func _on_play_pressed() -> void:
	var sel := _char_list.get_selected_items()
	if sel.is_empty():
		_login_error.text = "Log in and select a character first."
		return
	var row: Dictionary = _char_list.get_item_metadata(sel[0])
	game.enter_world(row)
	_enter_game_mode(true)

func _on_create_pressed() -> void:
	var row := game.create_character(_create_name.text.strip_edges(), _create_voc.get_item_id(_create_voc.selected))
	if row.is_empty():
		return # login_error signal already surfaced the reason
	game.db.save_db()
	_fill_char_list()
	_login_error.text = "Created %s." % String(row.name)

# ---- game mode ---------------------------------------------------------------

func _enter_game_mode(playing: bool) -> void:
	in_game = playing
	_login.visible = not playing
	_chat_panel.visible = playing
	_status_panel.visible = playing
	_rail_panel.visible = playing
	if _fps_label != null:
		_fps_label.visible = playing

	for s in _hotbar_slots:
		s.node.btn.visible = playing
	if not playing:
		gear_panel.panel.visible = false
		_stats_panel.visible = false
		_shop_panel.visible = false
		if _settings_panel != null:
			_settings_panel.visible = false

# ---- status (HP/Mana/XP) ------------------------------------------------------

func _build_status() -> void:
	_status_panel = BlackTekUiKit.panel(self, "bottom-left", Vector2(320, 156))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_status_panel.add_child(box)
	_name_label = BlackTekUiKit.label(box, "—", 14)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar = BlackTekUiKit.bar(box, HP_COLOR)
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_label = BlackTekUiKit.bar_label(_hp_bar, "HP 0/0")
	_mp_bar = BlackTekUiKit.bar(box, MP_COLOR)
	_mp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mp_label = BlackTekUiKit.bar_label(_mp_bar, "MP 0/0")
	_xp_bar = BlackTekUiKit.bar(box, XP_COLOR, 12)
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_label = BlackTekUiKit.bar_label(_xp_bar, "XP 0%", 9)
	_cond_row = HBoxContainer.new()
	_cond_row.add_theme_constant_override("separation", 4)
	box.add_child(_cond_row)
	_status_panel.tooltip_text = "Drag to move · release to drop on the grid"
	BlackTekUiKit.make_drag_handle(_status_panel, _status_panel)
	_status_panel.visible = false

func update_status() -> void:
	if game.players.is_empty() or _hp_bar == null:
		return
	var p: Dictionary = game.players[_pid]
	var voc: Dictionary = BlackTekGameServer.VOCATIONS[int(p.vocation)]
	_name_label.text = "%s  ·  level %d %s" % [String(p.name), int(p.level), voc.name]
	_hp_bar.max_value = int(p.hpmax)
	_hp_bar.value = int(p.hp)
	_hp_label.text = "HP %d / %d" % [int(p.hp), int(p.hpmax)]
	_mp_bar.max_value = maxi(1, int(p.manamax))
	_mp_bar.value = int(p.mana)
	_mp_label.text = "MP %d / %d" % [int(p.mana), int(p.manamax)]
	var prev := float(BlackTekGameServer.exp_for_level(int(p.level)))
	var next := float(BlackTekGameServer.exp_for_level(int(p.level) + 1))
	var frac := clampf((float(int(p.exp)) - prev) / maxf(1.0, next - prev), 0.0, 1.0)
	_xp_bar.value = frac * 100.0
	_xp_label.text = "XP %.1f%%  (%s / %s)" % [frac * 100.0, BlackTekUiKit.fmt(int(p.exp)), BlackTekUiKit.fmt(int(next))]
	# Condition chips (cf. client conditions icons).
	for c in _cond_row.get_children():
		c.queue_free()
	if game.is_pz_tile(p.tile):
		BlackTekUiKit.chip(_cond_row, "PZ", Color(0.35, 0.55, 1.0), "Protection zone (temple area) — you regenerate safely here.")
	if game.is_poisoned(_pid):
		BlackTekUiKit.chip(_cond_row, "Poisoned", Color(0.4, 0.75, 0.3), "Losing 2 hitpoints every 2 seconds.")
	if float(p.get("light_until", 0.0)) > Time.get_ticks_msec() / 1000.0:
		BlackTekUiKit.chip(_cond_row, "Lit", Color(1.0, 0.85, 0.4), "utevo lux — personal light (see at night).")
	if game.is_fed(_pid):
		BlackTekUiKit.chip(_cond_row, "Fed", Color(0.35, 0.8, 0.45), "Well fed — regeneration interval halved.")
	else:
		BlackTekUiKit.chip(_cond_row, "Hungry", Color(0.9, 0.6, 0.2), "Eat something (F1 or drag meat to the bar) to regenerate faster.")


# ---- chat ---------------------------------------------------------------------

func _build_chat() -> void:
	_chat_panel = BlackTekUiKit.panel(self, "bottom-left", Vector2(320, 300))
	_chat_panel.offset_top = -472
	_chat_panel.offset_bottom = -152
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_chat_panel.add_child(box)
	# Header: tab buttons (click a tab to switch; the mouse wheel scrolls the
	# chat text up/down and never changes tabs). The header doubles as the
	# drag handle. Panels are never collapsed.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	box.add_child(header)
	header.tooltip_text = "Drag to move · release to drop on the grid"
	BlackTekUiKit.make_drag_handle(_chat_panel, header)
	for tab in ["All", "Server", "Chat"]:
		var b := Button.new()
		b.text = tab
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 11)
		b.tooltip_text = "Show %s messages" % tab
		b.pressed.connect(func(): _set_chat_tab(tab))
		header.add_child(b)
		_chat_tab_btns.append({"btn": b, "name": tab})
	# Spacer pushes the window buttons to the far right of the tab bar.
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(spacer)
	header.add_child(_header_btn("-", "Minimize to the tab bar", func(): _toggle_minimize(_chat_panel, box)))
	header.add_child(_header_btn("X", "Close chat (T or the rail icon reopens it)", func(): _chat_panel.visible = false))
	# Pages: one RichTextLabel per tab, only the active one visible. The labels
	# take the mouse wheel so it scrolls the text up/down (scroll_active);
	# wheel input never switches tabs.
	_chat_pages = Control.new()
	_chat_pages.clip_contents = true
	_chat_pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_pages.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(_chat_pages)
	for tab2 in ["All", "Server", "Chat"]:
		var l := RichTextLabel.new()
		l.scroll_following = true
		l.scroll_active = true
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.add_theme_font_size_override("normal_font_size", 12)
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		l.visible = tab2 == "All"
		_chat_pages.add_child(l)
		_chat_tabs[tab2] = l
	_chat_log = _chat_tabs["All"]
	_chat_edit = LineEdit.new()
	_chat_edit.placeholder_text = "Type + Enter — try: hi, trade, exura, /pos"
	_chat_edit.visible = false
	_chat_edit.text_submitted.connect(_on_chat_submit)
	box.add_child(_chat_edit)
	_chat_panel.visible = false

func _set_chat_tab(tab: String) -> void:
	_chat_tab = tab
	for t in _chat_tabs.keys():
		_chat_tabs[t].visible = t == tab
	for rec in _chat_tab_btns:
		var b: Button = rec.btn
		b.modulate = Color(1, 1, 1, 1.0) if rec.name == tab else Color(1, 1, 1, 0.45)

func chat_open() -> bool:
	return _chat_edit != null and _chat_edit.visible and _chat_edit.has_focus()

func open_chat() -> void:
	_chat_edit.visible = true
	_chat_edit.grab_focus()

func close_chat(submit := false) -> void:
	if submit and not _chat_edit.text.strip_edges().is_empty():
		chat_submitted.emit(_chat_edit.text)
	_chat_edit.text = ""
	_chat_edit.visible = false
	_chat_edit.release_focus()

func _on_chat_submit(text: String) -> void:
	close_chat(true)

func chat_line(sender: String, text: String, color := Color(0.85, 0.86, 0.9)) -> void:
	var bb := "[color=#%s][%s] %s[/color]\n" % [color.to_html(false), sender, text]
	if _chat_log == null:
		return
	_chat_log.append_text(bb) # All tab
	# Route: server/system messages -> Server tab, players + NPCs -> Chat tab.
	var tab := "Chat"
	if sender == "Server" or sender == "System":
		tab = "Server"
	_chat_tabs[tab].append_text(bb)

func game_message(text: String) -> void:
	chat_line("Server", text, Color(0.45, 0.9, 0.55))

# ---- hotbar --------------------------------------------------------------------

# Inventory slot button: drag source (bag + equipment) and drop target, so
# items can be rearranged/equipped by drag inside the inventory screens only.
# Minimap canvas: walkable ground tinted, monsters red, player center.
class MinimapView extends Control:
	var game: BlackTekGameServer
	var pid := 1
	const PX := 3.0
	const R := 40
	func _init() -> void:
		custom_minimum_size = Vector2((2 * R + 1) * PX, (2 * R + 1) * PX)
	func _draw() -> void:
		if game == null or game.players.is_empty():
			return
		var p: Dictionary = game.players.get(pid, {})
		var center: Vector2i = p.get("tile", Vector2i.ZERO)
		var z: int = int(p.get("z", 7))
		for dy in range(-R, R + 1):
			for dx in range(-R, R + 1):
				var t := center + Vector2i(dx, dy)
				var col := Color(0.03, 0.03, 0.045)
				if game.use_real_map:
					var entry := game.tile_info(t, z)
					if not entry.is_empty():
						if game.is_walkable(t, z):
							var ids: Array = entry.get("items", [])
							var gid := int(ids[0]) if not ids.is_empty() else 0
							var s := 0.32 + 0.05 * float(gid % 5)
							col = Color(s * 0.65, s, s * 0.65)
						else:
							col = Color(0.1, 0.1, 0.13)
				else:
					col = Color(0.28, 0.34, 0.28) if game.is_walkable(t) else Color(0.1, 0.1, 0.12)
				draw_rect(Rect2(Vector2((dx + R) * PX, (dy + R) * PX), Vector2(PX, PX)), col)
		for m in game.monsters.values():
			if int(m.z) != z:
				continue
			var off: Vector2i = Vector2i(int(m.tile.x), int(m.tile.y)) - center
			if absi(off.x) > R or absi(off.y) > R:
				continue
			draw_rect(Rect2(Vector2((off.x + R) * PX + 0.5, (off.y + R) * PX + 0.5), Vector2(PX - 1, PX - 1)), Color(0.95, 0.3, 0.3))
		for n in game.npcs.values():
			if int(n.z) != z:
				continue
			var off2: Vector2i = Vector2i(int(n.tile.x), int(n.tile.y)) - center
			if absi(off2.x) > R or absi(off2.y) > R:
				continue
			draw_rect(Rect2(Vector2((off2.x + R) * PX + 0.5, (off2.y + R) * PX + 0.5), Vector2(PX - 1, PX - 1)), Color(0.3, 0.6, 1.0))
		draw_rect(Rect2(Vector2(R * PX - 1.5, R * PX - 1.5), Vector2(PX + 3, PX + 3)), Color(0.35, 0.8, 1.0))

func _build_hotbar() -> void:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 5)
	wrap.anchor_left = 0.5; wrap.anchor_top = 1.0; wrap.anchor_right = 0.5; wrap.anchor_bottom = 1.0
	wrap.offset_left = -95; wrap.offset_top = -176; wrap.offset_right = 95; wrap.offset_bottom = -12
	add_child(wrap)
	_hotbar_wrap = wrap
	for bar in HOTBAR_BARS:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		wrap.add_child(col)
		var cap := Label.new()
		cap.text = bar.title
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.add_theme_font_size_override("font_size", 8)
		cap.add_theme_color_override("font_color", Color(0.6, 0.65, 0.72))
		cap.mouse_filter = Control.MOUSE_FILTER_STOP
		cap.tooltip_text = "Drag to move the bars"
		BlackTekUiKit.make_drag_handle(wrap, cap)
		col.add_child(cap)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(row)
		var recs: Array = []
		for h in bar.slots:
			var rec: Dictionary = {"kind": h.kind, "value": h.value, "hotkey": h.get("hotkey", "")}
			var slot := _make_hotbar_slot(rec)
			row.add_child(slot)
			slot.visible = false
			recs.append(rec)
		_slot_records.append(recs)

func _slot_label(rec: Dictionary) -> String:
	if String(rec.kind) == "item":
		var n : String = game.item_label(int(rec.value)) if game != null else ""
		return n if n != "" else "item %d" % int(rec.value)
	return String(SPELL_INFO[String(rec.value)].label)

func _refresh_slot_content(rec: Dictionary) -> void:
	var node: Dictionary = rec.node
	var icon: TextureRect = node.icon
	var glyph: Label = node.glyph
	var cap: Label = node.cap
	var btn: Button = node.btn
	if String(rec.kind) == "item":
		icon.texture = game.get_item_icon(int(rec.value))
		icon.visible = icon.texture != null
		glyph.visible = icon.texture == null
		glyph.text = "?"
	else:
		icon.visible = false
		glyph.visible = true
		glyph.text = String(SPELL_INFO[String(rec.value)].glyph)
	cap.text = String(rec.get("hotkey", ""))
	var tip := _slot_label(rec)
	if String(rec.kind) == "item":
		var stats: String = game.item_stats_text(int(rec.value))
		if stats != "":
			tip += "\n" + stats
	else:
		var spell := String(rec.value)
		if spell == "exura":
			tip += "\nHeals you (20 mana)"
		elif spell == "flame":
			tip += "\nFire strike on your target (20 mana)"
		elif spell == "utevo lux":
			tip += "\nPersonal light for 120s (10 mana)"
		elif spell == "exana pox":
			tip += "\nCures poison (15 mana)"
		elif spell == "exori":
			tip += "\nHits everything next to you after a 0.8s wind-up (30 mana)"
		elif spell == "exura gran":
			tip += "\nBig heal (40 mana)"
	btn.tooltip_text = "%s\nLeft-click: use - Hotkey: %s" % [tip, String(rec.get("hotkey", ""))]

func _bag_count_of(itemtype: int) -> int:
	if game.players.is_empty():
		return 0
	var bag: Dictionary = game.players[_pid].bag
	var total := 0
	for i in range(20):
		var it: Dictionary = bag.get(i) if bag.get(i) != null else {}
		if not it.is_empty() and int(it.itemtype) == itemtype:
			total += int(it.count)
	return total

func _make_hotbar_slot(rec: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(56, 56)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", BlackTekUiKit.panel_style(SLOT_BG))
	btn.add_theme_stylebox_override("hover", BlackTekUiKit.panel_style(SLOT_BG.lightened(0.06)))
	btn.add_theme_stylebox_override("pressed", BlackTekUiKit.panel_style(SLOT_BG.lightened(0.1)))
	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 4; inner.offset_top = 4; inner.offset_right = -4; inner.offset_bottom = -22
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 0)
	btn.add_child(inner)
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(icon)
	var glyph := Label.new()
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	glyph.add_theme_font_size_override("font_size", 22)
	glyph.add_theme_color_override("font_color", ACCENT)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(glyph)
	var cap := Label.new()
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 9)
	cap.add_theme_color_override("font_color", GOLD_COLOR)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	cap.offset_left = 2; cap.offset_right = -2; cap.offset_top = -16; cap.offset_bottom = -4
	btn.add_child(cap)
	var cd := ColorRect.new()
	cd.color = Color(0, 0, 0, 0.55)
	cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd.visible = false
	btn.add_child(cd)
	rec["node"] = {"btn": btn, "icon": icon, "glyph": glyph, "cap": cap, "cd": cd}
	rec["hotkey"] = rec.get("hotkey", "")
	_refresh_slot_content(rec)
	btn.pressed.connect(func(): _emit_slot(rec))
	_hotbar_slots.append(rec)
	return btn

func _emit_slot(rec: Dictionary) -> void:
	match String(rec.kind):
		"item":
			hotbar_command.emit({"kind": "item", "itemtype": int(rec.value)})
		"spell":
			hotbar_command.emit({"kind": "spell", "spell": String(rec.value)})
		_:
			hotbar_command.emit({"kind": "attack"})

# F-key entry point: trigger bar/idx (0-based) as if clicked.
func activate_slot(bar: int, idx: int) -> void:
	if bar >= 0 and bar < _slot_records.size() and idx >= 0 and idx < _slot_records[bar].size():
		_emit_slot(_slot_records[bar][idx])

# Persisted layout: flat [kind, value] pairs for all slots.
func hotbar_layout() -> Array:
	var out := []
	for bar_recs in _slot_records:
		for rec in bar_recs:
			out.append([String(rec.kind), rec.value])
	return out

func apply_hotbar_layout(layout: Array) -> void:
	var flat: Array = []
	for bar_recs in _slot_records:
		for rec in bar_recs:
			flat.append(rec)
	for i in range(mini(flat.size(), layout.size())):
		var entry: Array = layout[i]
		if entry.size() >= 2 and ["item", "spell", "attack"].has(String(entry[0])):
			flat[i].kind = String(entry[0])
			flat[i].value = entry[1]
			_refresh_slot_content(flat[i])

var _slot_records: Array = []

func _update_hotbar_cooldowns() -> void:
	if game.players.is_empty():
		return
	var p: Dictionary = game.players.get(_pid, {})
	var now := Time.get_ticks_msec() / 1000.0
	var cds: Dictionary = p.get("cooldowns", {})
	for rec in _hotbar_slots:
		var frac := 0.0
		match String(rec.kind):
			"item":
				frac = _cd_frac(float(cds.get("potion", 0.0)), now)
			"spell":
				frac = _cd_frac(float(cds.get("spell", 0.0)), now)
			"attack":
				frac = _cd_frac(float(p.get("attack_cd", 0.0)), now)
		var cd: ColorRect = rec.node.cd
		var btn: Button = rec.node.btn
		if frac > 0.001:
			cd.visible = true
			cd.anchor_left = 0.0; cd.anchor_right = 1.0
			cd.anchor_top = 0.0; cd.anchor_bottom = frac
			cd.offset_left = 0; cd.offset_right = 0; cd.offset_top = 0; cd.offset_bottom = 0
		else:
			cd.visible = false

func _cd_frac(until: float, now: float) -> float:
	if until <= now:
		return 0.0
	return clampf((until - now) / 1.5, 0.02, 1.0)

# ---- right rail (icon tabs) + settings panel ------------------------------------

func _build_rail() -> void:
	_rail_panel = BlackTekUiKit.panel(self, "top-right", Vector2(250, 64))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	_rail_panel.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	# Icon tabs: click to show/hide the panels.
	row.add_child(_make_icon_button("", "Gear (G)", func(): gear_panel.toggle(), 1988))
	row.add_child(_make_icon_button("☰", "Stats (K)", func(): _toggle_panel(_stats_panel), -1))
	row.add_child(_make_icon_button("", "Chat (T)", func(): toggle_chat(), 1949))
	row.add_child(_make_icon_button("", "Shop (trade with Norf)", func(): toggle_shop(), 2148))
	row.add_child(_make_icon_button("", "Minimap (M)", func(): toggle_minimap(), 1956))
	row.add_child(_make_icon_button("⚙", "Settings (O)", func(): toggle_settings(), -1))

func _build_settings() -> void:
	_settings_panel = BlackTekUiKit.panel(self, "top-right", Vector2(250, 220))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	_settings_panel.add_child(box)
	BlackTekUiKit.label(box, "Graphics", 12, ACCENT)
	_opt_retro = CheckButton.new()
	_opt_retro.text = "Retro pixels"
	_opt_retro.tooltip_text = "Sprite sampling: nearest = crisp pixels, off = smooth bilinear."
	_opt_retro.focus_mode = Control.FOCUS_NONE
	_opt_retro.add_theme_font_size_override("font_size", 11)
	box.add_child(_opt_retro)
	_opt_pixels = Button.new()
	_opt_pixels.text = "Sprites: 32px"
	_opt_pixels.tooltip_text = "Upscale world rendering: 32px (1x), 64px (2x) or 128px (4x) per tile/sprite.\nSource art is 32x32. Combine with 'Retro pixels' for crisp vs. smooth scaling."
	_opt_pixels.focus_mode = Control.FOCUS_NONE
	_opt_pixels.add_theme_font_size_override("font_size", 11)
	box.add_child(_opt_pixels)
	BlackTekUiKit.label(box, "Day / night", 12, ACCENT)
	var day_row := HBoxContainer.new()
	day_row.add_theme_constant_override("separation", 6)
	box.add_child(day_row)
	var day_btn := Button.new()
	day_btn.text = "☀ Day"
	day_btn.tooltip_text = "Pin the light cycle to noon (/day)"
	day_btn.focus_mode = Control.FOCUS_NONE
	day_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_btn.pressed.connect(func(): game.set_ambient(1.0))
	day_row.add_child(day_btn)
	var night_btn := Button.new()
	night_btn.text = "☾ Night"
	night_btn.tooltip_text = "Pin the light cycle to midnight (/night)"
	night_btn.focus_mode = Control.FOCUS_NONE
	night_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	night_btn.pressed.connect(func(): game.set_ambient(0.25))
	day_row.add_child(night_btn)
	BlackTekUiKit.label(box, "Session: Godot client + MockDB (offline).", 10, Color(0.55, 0.58, 0.66))
	panel_header(_settings_panel, box, "Settings")
	_settings_panel.visible = false

func toggle_settings() -> void:
	if _settings_panel == null:
		_build_settings()
	_toggle_panel(_settings_panel)

func toggle_minimap() -> void:
	if _minimap_panel == null:
		_build_minimap()
	if _minimap_panel.visible:
		hide_panel(_minimap_panel)
	else:
		show_panel(_minimap_panel)

func _build_minimap() -> void:
	_minimap_panel = BlackTekUiKit.panel(self, "top-right", Vector2(270, 300))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_minimap_panel.add_child(box)
	_minimap_view = MinimapView.new()
	_minimap_view.game = game
	_minimap_view.pid = _pid
	_minimap_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_minimap_view)
	panel_header(_minimap_panel, box, "Minimap")
	_minimap_panel.visible = false

func toggle_shop() -> void:
	if game.players.is_empty():
		return
	# The shop window is an NPC interaction: it only opens next to a real NPC.
	if not game.can_trade_with_npc(_pid):
		game.message_local(_pid, "There is no NPC to trade with here. Walk up to Norf at the temple.")
		return
	refresh_shop()
	if _shop_panel.visible:
		hide_panel(_shop_panel)
	else:
		_shop_far_warned = false
		show_panel(_shop_panel)

# Small square toggle button with an item icon (itemtype >= 0) or a text glyph.
func _make_icon_button(glyph: String, tip: String, on_press: Callable, itemtype := -1) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(36, 36)
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = tip
	btn.add_theme_stylebox_override("normal", BlackTekUiKit.panel_style(SLOT_BG))
	btn.add_theme_stylebox_override("hover", BlackTekUiKit.panel_style(SLOT_BG.lightened(0.06)))
	btn.add_theme_stylebox_override("pressed", BlackTekUiKit.panel_style(SLOT_BG.lightened(0.12)))
	if itemtype >= 0:
		var icon := TextureRect.new()
		icon.texture = game.get_item_icon(itemtype)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 4; icon.offset_top = 4; icon.offset_right = -4; icon.offset_bottom = -4
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon)
	else:
		var lab := Label.new()
		lab.text = glyph
		lab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.add_theme_font_size_override("font_size", 18)
		lab.add_theme_color_override("font_color", ACCENT)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lab)
	btn.pressed.connect(on_press)
	return btn

func toggle_chat() -> void:
	if _chat_panel.visible:
		hide_panel(_chat_panel)
	else:
		show_panel(_chat_panel)

# Showing a tab: unhide it in place, but never buried — anything that would
# open >30% covered (including designer spots that stack over each other)
# slides to the first free 32px grid slot (cascading from top-left when the
# screen is crammed).
func show_panel(p: PanelContainer) -> void:
	p.visible = true
	var r := _panel_rect(p)
	var vp := get_viewport_rect().size
	# Clamp fully inside first (a hidden panel reports stale zeros, so work
	# from the analytic rect which is valid even before layout).
	var cx := clampf(r.position.x, minf(8.0, vp.x - r.size.x - 8.0), maxf(8.0, vp.x - r.size.x - 8.0))
	var cy := clampf(r.position.y, minf(8.0, vp.y - r.size.y - 8.0), maxf(8.0, vp.y - r.size.y - 8.0))
	_write_panel_rect(p, Rect2(cx, cy, r.size.x, r.size.y))
	if not _rect_buried(Rect2(cx, cy, r.size.x, r.size.y), p):
		return
	var y := 8.0
	while y + r.size.y <= vp.y - 8.0:
		var x := 8.0
		while x + r.size.x <= vp.x - 8.0:
			var cand := Rect2(x, y, r.size.x, r.size.y)
			if not _rect_buried(cand, p):
				_write_panel_rect(p, cand)
				return
			x += 32.0
		y += 32.0
	var n := 0
	for c in _hud_panels():
		if c != null and (c as Control).visible:
			n += 1
	_write_panel_rect(p, Rect2(8.0 + 40.0 * float(n % 8), 8.0 + 40.0 * float(n % 6), r.size.x, r.size.y))

func hide_panel(p: PanelContainer) -> void:
	p.visible = false

# Every panel that can cover another one.
func _hud_panels() -> Array:
	return [_status_panel, _chat_panel, _rail_panel, _hotbar_wrap, gear_panel.panel, _stats_panel, _shop_panel, _minimap_panel, _settings_panel]

func begin_world_drag(from: Dictionary) -> void:
	drag_from = from
	drag_accepted = false

# An inventory drag ended outside every gear slot: dropping it over the
# world leaves the item on that floor tile (melee reach, same floor).
func finish_world_drag() -> void:
	var from: Dictionary = drag_from
	drag_from = {}
	var ok := drag_accepted
	drag_accepted = false
	if from.is_empty() or ok:
		return # landed in the inventory (or nowhere to track)
	if game == null or game.players.is_empty() or game_view == null or not in_game:
		return
	var mouse: Vector2 = game_view.get_viewport().get_mouse_position()
	if is_over_ui(mouse):
		return # aimed at a panel, not the world: cancel quietly
	var t: Vector2i = game_view.mouse_tile()
	if not game_view._is_in_view(t):
		return
	if String(from.get("kind", "")) == "equip":
		game.drop_equipped(_pid, int(from.get("index", -1)), t, game.demo_z)
	else:
		game.drop_item(_pid, int(from.get("index", -1)), t, game.demo_z)

func _panel_rects() -> Array:
	var out := []
	for c in _hud_panels():
		if c != null and (c as Control).visible:
			out.append((c as Control).get_global_rect())
	return out

# Grabbing floor loot needs the open gear panel under the cursor.
func is_over_gear() -> bool:
	return is_over_gear_at(game_view.get_viewport().get_mouse_position()) if game_view != null else false

func is_over_gear_at(px: Vector2) -> bool:
	var gp: PanelContainer = gear_panel.panel
	return gp != null and gp.visible and gp.get_global_rect().has_point(px)

func is_over_ui(px: Vector2) -> bool:
	for r in _panel_rects():
		if r.has_point(px):
			return true
	return false

# Analytic panel rect: position from anchors + offsets, size floored with
# the combined minimum. Valid even before the first layout pass, unlike
# get_global_rect() on a just-unhidden panel (stale zeros).
func _panel_rect(p: PanelContainer) -> Rect2:
	var vp := get_viewport_rect().size
	var m := p.get_combined_minimum_size()
	var w: float = p.offset_right - p.offset_left
	var h: float = p.offset_bottom - p.offset_top
	if w <= 0.0:
		w = m.x
	if h <= 0.0:
		h = m.y
	return Rect2(p.anchor_left * vp.x + p.offset_left, p.anchor_top * vp.y + p.offset_top, w, h)

func _write_panel_rect(p: PanelContainer, r: Rect2) -> void:
	p.anchor_left = 0.0; p.anchor_top = 0.0
	p.anchor_right = 0.0; p.anchor_bottom = 0.0
	p.offset_left = r.position.x
	p.offset_top = r.position.y
	p.offset_right = r.position.x + r.size.x
	p.offset_bottom = r.position.y + r.size.y

# Keep a shown panel fully inside the window (panels hanging off-screen is
# a critical bug: they must always be reachable).
func _clamp_panel(p: PanelContainer) -> void:
	var vp := get_viewport_rect().size
	var r := _panel_rect(p)
	var x := clampf(r.position.x, minf(8.0, vp.x - r.size.x - 8.0), maxf(8.0, vp.x - r.size.x - 8.0))
	var y := clampf(r.position.y, minf(8.0, vp.y - r.size.y - 8.0), maxf(8.0, vp.y - r.size.y - 8.0))
	_write_panel_rect(p, Rect2(x, y, r.size.x, r.size.y))

# Buried = sharing a substantial 2D patch with another visible panel (both
# dimensions overlap by >24px). Thin edge kisses like the chat/status strip
# do not count, but side-by-side piles do.
func _rect_buried(r: Rect2, ignore: Control) -> bool:
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return false
	for c in _hud_panels():
		if c == null or c == ignore or not (c is Control) or not c.visible:
			continue
		var cc: Control = c
		if r.intersects(cc.get_global_rect()):
			var inter := r.intersection(cc.get_global_rect())
			if inter.size.x > 24.0 and inter.size.y > 24.0:
				return true
	return false

func _panel_buried(p: PanelContainer) -> bool:
	return _rect_buried(_panel_rect(p), p)

# Free placement: toggling only flips visibility, panels stay where dropped.
func _toggle_panel(p: PanelContainer) -> void:
	if p.visible:
		hide_panel(p)
	else:
		show_panel(p)

func toggle_stats() -> void:
	_toggle_panel(_stats_panel)
	if _stats_panel.visible:
		refresh_stats()

# ---- gear (equipment + backpack) ------------------------------------------------

var gear_panel := BlackTekGearPanel.new()  # built in _ready via gear_panel.build(self)

func refresh_inventory() -> void:
	gear_panel.refresh_inventory()

func toggle_gear() -> void:
	gear_panel.toggle()

func _build_stats() -> void:
	_stats_panel = BlackTekUiKit.panel(self, "top-right", Vector2(232, 440))
	_stats_panel.offset_top = 190
	_stats_panel.offset_bottom = 630
	_stats_panel.offset_left = -248
	_stats_panel.offset_right = -16
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_stats_panel.add_child(box)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	_stats_box = VBoxContainer.new()
	_stats_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_box.add_theme_constant_override("separation", 3)
	scroll.add_child(_stats_box)
	panel_header(_stats_panel, box, "Stats")
	_stats_panel.visible = false

func refresh_stats() -> void:
	if game.players.is_empty() or _stats_box == null:
		return
	for c in _stats_box.get_children():
		c.queue_free()
	var p: Dictionary = game.players[_pid]
	var voc: Dictionary = BlackTekGameServer.VOCATIONS[int(p.vocation)]
	BlackTekUiKit.label(_stats_box, "%s  ·  %s" % [String(p.name), voc.name], 13, ACCENT)
	var gold := 0
	var weight := 0
	for slot in p.inv.keys():
		var it: Dictionary = p.inv[slot] if p.inv[slot] != null else {}
		if not it.is_empty() and game.dat != null:
			weight += game.dat.item_weight(int(it.itemtype)) * int(it.count)
	for i in range(20):
		var it3: Dictionary = p.bag.get(i) if p.bag.get(i) != null else {}
		if not it3.is_empty():
			if int(it3.itemtype) == BlackTekActionScripts.GOLD_COIN:
				gold += int(it3.count)
			if game.dat != null:
				weight += game.dat.item_weight(int(it3.itemtype)) * int(it3.count)
	var rows := [
		["Level", str(int(p.level))],
		["Experience", "%s (%s to go)" % [BlackTekUiKit.fmt(int(p.exp)), BlackTekUiKit.fmt(maxi(0, BlackTekGameServer.exp_for_level(int(p.level) + 1) - int(p.exp)))]],
		["Health", "%d / %d" % [int(p.hp), int(p.hpmax)]],
		["Mana", "%d / %d" % [int(p.mana), int(p.manamax)]],
		["Magic level", str(int(p.maglevel))],
		["Capacity", "%d / %d oz" % [weight / 100, int(p.cap)]],
		["Armor", str(game.total_armor(_pid))],
		["Soul", str(int(p.soul))],
		["Gold", str(gold)],
		["Speed", "220"],
	]
	for r in rows:
		var h := HBoxContainer.new()
		_stats_box.add_child(h)
		BlackTekUiKit.label(h, r[0], 11, Color(0.6, 0.65, 0.72)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		BlackTekUiKit.label(h, r[1], 11)
		if String(r[0]) == "Experience":
			_push_cooldown_row(p) # push cooldown lives right below the XP row
	BlackTekUiKit.label(_stats_box, "Skills", 12, ACCENT)
	_skill_row("Magic level", int(p.maglevel), int(p.get("mlvl_tries", 0)), int((int(p.maglevel) + 1) * 80.0 / BlackTekGameServer.RATE_MAGIC))
	for sk in SKILL_ORDER:
		var lvl := int(p.skills.get(sk, 10))
		var need := int((lvl + 1) * 12.0 / BlackTekGameServer.RATE_SKILL)
		_skill_row(SKILL_LABELS[sk], lvl, int(p.skill_tries.get(sk, 0)), need)

# Push cooldown loading bar: drains while the current target cannot be pushed
# again, "Ready" when a push would go through, "Too far" when the target is
# outside melee range, "No target" without one. Refreshes with the stats.
func _push_cooldown_row(p: Dictionary) -> void:
	BlackTekUiKit.label(_stats_box, "Push", 12, ACCENT)
	var tid := int(p.get("target", 0))
	var tm: Dictionary = game.monsters.get(tid, {}) if tid != 0 else {}
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	_stats_box.add_child(h)
	var l := BlackTekUiKit.label(h, "Cooldown", 10, Color(0.6, 0.65, 0.72))
	l.custom_minimum_size = Vector2(88, 0)
	var bar := BlackTekUiKit.bar(h, ACCENT, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = BlackTekGameServer.PUSH_CD
	bar.value = 0.0
	var st := BlackTekUiKit.label(h, "", 11)
	st.custom_minimum_size = Vector2(96, 0)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if tm.is_empty():
		st.text = "No target"
		return
	var tname := String(tm.get("name", "creature"))
	var ptile: Vector2i = p.get("tile", Vector2i.ZERO)
	var mdist: int = maxi(absi(int(tm.tile.x) - ptile.x), absi(int(tm.tile.y) - ptile.y))
	if int(tm.z) != int(p.get("z", 7)) or mdist > 1:
		st.text = "Too far (%s)" % tname
		return
	var rem := game.push_cooldown_remaining(tid)
	bar.value = clampf(rem, 0.0, BlackTekGameServer.PUSH_CD)
	st.text = "Ready (%s)" % tname if rem <= 0.01 else "%.1fs (%s)" % [rem, tname]

func _skill_row(name_text: String, level: int, tries: int, need: int) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	_stats_box.add_child(h)
	var l := BlackTekUiKit.label(h, name_text, 10, Color(0.6, 0.65, 0.72))
	l.custom_minimum_size = Vector2(88, 0)
	var bar := BlackTekUiKit.bar(h, ACCENT, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = maxi(1, need)
	bar.value = clampi(tries, 0, need)
	var lv := BlackTekUiKit.label(h, str(level), 11)
	lv.custom_minimum_size = Vector2(24, 0)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

# ---- target frame ------------------------------------------------------------------

# ---- NPC shop ------------------------------------------------------------------------

func _build_shop() -> void:
	_shop_panel = BlackTekUiKit.panel(self, "center", Vector2(340, 300))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_shop_panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	BlackTekUiKit.label(head, "Norf's Wares", 14, ACCENT).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_header_btn("-", "Minimize to the title bar", func(): _toggle_minimize(_shop_panel, box)))
	var close := Button.new()
	close.text = "X"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func(): _shop_panel.visible = false)
	head.add_child(close)
	BlackTekUiKit.make_drag_handle(_shop_panel, head)
	_shop_gold = BlackTekUiKit.label(box, "You carry 0 gold.", 11, GOLD_COLOR)
	var qty_row := HBoxContainer.new()
	qty_row.add_theme_constant_override("separation", 8)
	box.add_child(qty_row)
	BlackTekUiKit.label(qty_row, "Qty:", 11, Color(0.6, 0.65, 0.72))
	var qty_slider := HSlider.new()
	qty_slider.min_value = 1.0
	qty_slider.max_value = 100.0
	qty_slider.step = 1.0
	qty_slider.value = 1.0
	qty_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qty_slider.focus_mode = Control.FOCUS_NONE
	qty_slider.tooltip_text = "Trade quantity for the Buy/Sell buttons"
	qty_row.add_child(qty_slider)
	_shop_qty_label = BlackTekUiKit.label(qty_row, "1x", 11, GOLD_COLOR)
	_shop_qty_label.custom_minimum_size = Vector2(36, 0)
	_shop_qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_slider.value_changed.connect(func(v: float):
		_shop_qty = maxi(1, int(round(v)))
		_shop_qty_label.text = "%dx" % _shop_qty
		refresh_shop_gold())
	_shop_rows = VBoxContainer.new()
	_shop_rows.add_theme_constant_override("separation", 6)
	box.add_child(_shop_rows)
	_shop_panel.visible = false
	refresh_shop()

# Rebuild trade rows from the data-driven offers (buy + sell + owned count).
# Called when the shop opens; lightweight owned-count refresh runs separately.
func refresh_shop() -> void:
	if _shop_rows == null:
		return
	for c in _shop_rows.get_children():
		c.queue_free()
	_shop_offer_rows.clear()
	if game == null:
		return
	for offer in BlackTekNpc.shop_offers(game):
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		_shop_rows.add_child(h)
		var icon := TextureRect.new()
		icon.texture = game.get_item_icon(int(offer.itemtype)) if game != null else null
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(icon)
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(info)
		BlackTekUiKit.label(info, String(offer.name), 11).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sub := BlackTekUiKit.label(info, "", 10, Color(0.6, 0.65, 0.72))
		var owned_l := BlackTekUiKit.label(info, "", 10, GOLD_COLOR)
		var buy := Button.new()
		buy.focus_mode = Control.FOCUS_NONE
		var o: Dictionary = (offer as Dictionary).duplicate()
		buy.pressed.connect(func(): game.buy_shop_item(_pid, o, _shop_qty))
		h.add_child(buy)
		var sell := Button.new()
		sell.focus_mode = Control.FOCUS_NONE
		var o2: Dictionary = (offer as Dictionary).duplicate()
		sell.pressed.connect(func(): game.sell_shop_item(_pid, o2, _shop_qty))
		h.add_child(sell)
		_shop_offer_rows.append({"offer": offer, "sub": sub, "owned": owned_l, "buy_btn": buy, "sell_btn": sell})
	refresh_shop_gold()

func refresh_shop_gold() -> void:
	if game.players.is_empty():
		return
	var p: Dictionary = game.players[_pid]
	var gold := 0
	for i in range(20):
		var it: Dictionary = p.bag.get(i) if p.bag.get(i) != null else {}
		if not it.is_empty() and int(it.itemtype) == BlackTekActionScripts.GOLD_COIN:
			gold += int(it.count)
	_shop_gold.text = "You carry %d gold." % gold
	# Trade buttons are NPC interactions: without a real NPC in trade range
	# every row stays disabled (walking away auto-closes the panel anyway).
	var near_npc: bool = game.can_trade_with_npc(_pid) if game.has_method("can_trade_with_npc") else true
	var qty: int = maxi(1, _shop_qty)
	# Lightweight per-row refresh (no rebuild, so button presses never break).
	for rec in _shop_offer_rows:
		var offer: Dictionary = rec.offer
		var buy_p: int = BlackTekConfig.offer_buy_price(offer)
		var sell_p: int = BlackTekConfig.offer_sell_price(offer)
		var owned: int = game.shop_stock(_pid, int(offer.itemtype)) if game.has_method("shop_stock") else 0
		var buy_btn: Button = rec.buy_btn
		var sell_btn: Button = rec.sell_btn
		if not near_npc:
			(rec.sub as Label).text = "Walk up to Norf to trade"
		else:
			(rec.sub as Label).text = "Buy %d gp · Sell %d gp" % [buy_p, sell_p] if sell_p > 0 else "Buy %d gp · Norf won't buy this" % buy_p
		(rec.owned as Label).text = "You: %d · %d gold" % [owned, gold]
		buy_btn.text = "Buy %dx" % qty
		buy_btn.tooltip_text = "Buy %dx %s for %d gold" % [qty, String(offer.name), buy_p * qty]
		if sell_p > 0:
			sell_btn.text = "Sell %dx" % qty
			sell_btn.tooltip_text = "Sell %dx %s for %d gold" % [qty, String(offer.name), sell_p * qty]
		else:
			sell_btn.text = "No buy"
			sell_btn.tooltip_text = "Norf doesn't buy %s" % String(offer.name)
		buy_btn.disabled = (not near_npc) or gold < buy_p * qty
		sell_btn.disabled = (not near_npc) or sell_p <= 0 or owned < qty

# ---- server signal wiring ------------------------------------------------------------

func connect_game() -> void:
	game.world_entered.connect(func(_pid: int): _enter_game_mode(true))
	game.stats_changed.connect(func(_pid: int):
		update_status()
		if _stats_panel.visible:
			refresh_stats())
	game.inventory_changed.connect(func(_pid: int):
		refresh_inventory()
		if _shop_panel.visible:
			refresh_shop_gold())
	game.msg_local.connect(func(_pid: int, text: String): game_message(text))
	game.chat_heard.connect(func(pid: int, sender: String, text: String):
		if pid == _pid:
			chat_line(sender, text))
	game.level_up.connect(func(_pid: int, _lvl: int):
		if _stats_panel.visible:
			refresh_stats())
	game.shop_requested.connect(func(_pid: int):
		_shop_far_warned = false
		refresh_shop()
		show_panel(_shop_panel))
	game.login_error.connect(func(text: String):
		if _login.visible:
			_login_error.text = text)
