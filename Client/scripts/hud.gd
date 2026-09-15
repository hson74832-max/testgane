# Modern HUD/UX for the BlackTek demo client (OTClient-style modules, rebuilt
# as Godot Controls): login/character select against the MockDB, HP/Mana/XP
# status bars, equipment+backpack gear panel, skills/stats panel, action
# hotbar with cooldowns, target frame and NPC shop. All server calls go
# through the BlackTekGameServer (game) — swap for TCP later.
#
# Architecture: thin shell — panel content lives in ui/* modules (login,
# status, chat, gear, stats, shop, hotbar, target), built here and reached
# through same-named delegates so existing callers (main, world_view, tests)
# never change. Shared machinery (headers, placement, rail, settings,
# minimap, drag-drop, wiring, fade) stays here.
class_name BlackTekHud
extends Control

signal chat_submitted(text: String)
signal hotbar_command(cmd: Dictionary) # {kind: "item", itemtype} | {kind: "spell", spell} | {kind: "attack"}

var game: BlackTekGameServer
var _pid := 1
var in_game := false

# --- login ---
var login_panel := BlackTekLoginPanel.new() # built in _ready
# --- status ---
var status_panel := BlackTekStatusPanel.new() # built in _ready
# --- chat ---
var chat_panel := BlackTekChatPanel.new() # built in _ready
# --- stats ---
var stats_panel := BlackTekStatsPanel.new() # built in _ready
# --- target / shop ---
var target_panel := BlackTekTargetPanel.new() # built in _ready
var shop_panel := BlackTekShopPanel.new() # built in _ready
# --- hotbar / rail ---
var hotbar_panel := BlackTekHotbarPanel.new() # built in _ready
var _rail_panel: PanelContainer
var _hud_surfaces: Array = []
var _idle_time := 0.0
var _ui_alpha := 1.0
var minimap_panel := BlackTekMinimapPanel.new() # built in _ready
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
	login_panel.build(self)
	status_panel.build(self)
	chat_panel.build(self)
	hotbar_panel.build(self)
	_build_rail()
	_build_settings()
	gear_panel.build(self)
	stats_panel.build(self)
	shop_panel.build(self)
	target_panel.build(self)
	minimap_panel.build(self)
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
	hotbar_panel.update_cooldowns()
	# Auto-hide: fade the whole HUD out after 10s without input, back on input.
	if in_game:
		_idle_time += delta
		var target := 0.0 if _idle_time > 10.0 else 1.0
		_ui_alpha = move_toward(_ui_alpha, target, delta * 2.5)
		for c in [status_panel.panel, chat_panel.panel, _rail_panel, hotbar_panel.wrap, gear_panel.panel, stats_panel.panel, shop_panel.panel, target_panel.panel, minimap_panel.panel, _settings_panel, _fps_label]:
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
		if stats_panel.panel.visible:
			refresh_stats()
		shop_panel.tick() # proximity auto-close (no-op unless open)
		if shop_panel.panel.visible:
			refresh_shop_gold()
		target_panel.refresh()
	# Minimap repaints on its own cadence while visible (fog, arrival, follow).
	minimap_panel.tick(delta)

# ---- shared styles -----------------------------------------------------------
# Static panel header: title label, minimize + close buttons, drag handle.
# Both buttons hide the panel; it reopens from the right-rail icons (or the
# G/K/T/M/O hotkeys). Panels are never collapsed.
func panel_header(panel: PanelContainer, box: VBoxContainer, title: String) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	header.tooltip_text = "Drag to move - release to drop on the grid"
	var lab := BlackTekUiKit.label(header, title, 13, BlackTekUiKit.ACCENT)
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

# ---- game mode ---------------------------------------------------------------

func _enter_game_mode(playing: bool) -> void:
	in_game = playing
	login_panel.root.visible = not playing
	chat_panel.panel.visible = playing
	status_panel.panel.visible = playing
	_rail_panel.visible = playing
	if _fps_label != null:
		_fps_label.visible = playing

	hotbar_panel.set_slots_visible(playing)
	if not playing:
		gear_panel.panel.visible = false
		stats_panel.panel.visible = false
		shop_panel.panel.visible = false
		target_panel.panel.visible = false
		if _settings_panel != null:
			_settings_panel.visible = false

# ---- status (HP/Mana/XP): content lives in ui/status_panel.gd ----

func update_status() -> void:
	status_panel.update_status()


# ---- chat: content lives in ui/chat_panel.gd ----

func chat_open() -> bool:
	return chat_panel.chat_open()

func open_chat() -> void:
	chat_panel.open_chat()

func close_chat(submit := false) -> void:
	chat_panel.close_chat(submit)

func chat_line(sender: String, text: String, color := Color(0.85, 0.86, 0.9)) -> void:
	chat_panel.chat_line(sender, text, color)

func game_message(text: String) -> void:
	chat_panel.game_message(text)

func toggle_chat() -> void:
	if chat_panel.panel.visible:
		hide_panel(chat_panel.panel)
	else:
		show_panel(chat_panel.panel)

# ---- hotbar: content lives in ui/hotbar_panel.gd ----

# F-key entry point: trigger bar/idx (0-based) as if clicked.
func activate_slot(bar: int, idx: int) -> void:
	hotbar_panel.activate_slot(bar, idx)

# Persisted layout: flat [kind, value] pairs for all slots.
func hotbar_layout() -> Array:
	return hotbar_panel.hotbar_layout()

func apply_hotbar_layout(layout: Array) -> void:
	hotbar_panel.apply_hotbar_layout(layout)

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
	row.add_child(_make_icon_button("☰", "Stats (K)", func(): stats_panel.toggle(), -1))
	row.add_child(_make_icon_button("", "Chat (T)", func(): toggle_chat(), 1949))
	row.add_child(_make_icon_button("", "Shop (trade with Norf)", func(): toggle_shop(), 2148))
	row.add_child(_make_icon_button("", "Minimap (M)", func(): toggle_minimap(), 1956))
	row.add_child(_make_icon_button("⚙", "Settings (O)", func(): toggle_settings(), -1))

func _build_settings() -> void:
	_settings_panel = BlackTekUiKit.panel(self, "top-right", Vector2(250, 220))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	_settings_panel.add_child(box)
	BlackTekUiKit.label(box, "Graphics", 12, BlackTekUiKit.ACCENT)
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
	BlackTekUiKit.label(box, "Day / night", 12, BlackTekUiKit.ACCENT)
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
	minimap_panel.toggle()

# Persisted waypoints: flat [x, y, z, name] entries (mirrors hotbar layout).
func get_waypoints() -> Array:
	return minimap_panel.get_waypoints()

func set_waypoints(arr: Array) -> void:
	minimap_panel.set_waypoints(arr)

# Small square toggle button with an item icon (itemtype >= 0) or a text glyph.
func _make_icon_button(glyph: String, tip: String, on_press: Callable, itemtype := -1) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(36, 36)
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = tip
	btn.add_theme_stylebox_override("normal", BlackTekUiKit.panel_style(BlackTekUiKit.SLOT_BG))
	btn.add_theme_stylebox_override("hover", BlackTekUiKit.panel_style(BlackTekUiKit.SLOT_BG.lightened(0.06)))
	btn.add_theme_stylebox_override("pressed", BlackTekUiKit.panel_style(BlackTekUiKit.SLOT_BG.lightened(0.12)))
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
		lab.add_theme_color_override("font_color", BlackTekUiKit.ACCENT)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lab)
	btn.pressed.connect(on_press)
	return btn

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
	return [status_panel.panel, chat_panel.panel, _rail_panel, hotbar_panel.wrap, gear_panel.panel, stats_panel.panel, target_panel.panel, shop_panel.panel, minimap_panel.panel, _settings_panel]

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
	stats_panel.toggle()

# ---- gear (equipment + backpack) ------------------------------------------------

var gear_panel := BlackTekGearPanel.new()  # built in _ready via gear_panel.build(self)

func refresh_inventory() -> void:
	gear_panel.refresh_inventory()

func toggle_gear() -> void:
	gear_panel.toggle()

# ---- stats: content lives in ui/stats_panel.gd ----

func refresh_stats() -> void:
	stats_panel.refresh_stats()

# ---- target frame: content lives in ui/target_panel.gd ----

# ---- NPC shop: content lives in ui/shop_panel.gd ----

func toggle_shop() -> void:
	shop_panel.toggle()

func refresh_shop() -> void:
	shop_panel.refresh_shop()

func refresh_shop_gold() -> void:
	shop_panel.refresh_shop_gold()

# ---- server signal wiring ------------------------------------------------------------

func connect_game() -> void:
	game.world_entered.connect(func(_pid: int): _enter_game_mode(true))
	game.stats_changed.connect(func(_pid: int):
		update_status()
		if stats_panel.panel.visible:
			refresh_stats())
	game.inventory_changed.connect(func(_pid: int):
		refresh_inventory()
		if shop_panel.panel.visible:
			refresh_shop_gold())
	game.msg_local.connect(func(_pid: int, text: String): game_message(text))
	game.chat_heard.connect(func(pid: int, sender: String, text: String):
		if pid == _pid:
			chat_line(sender, text))
	game.level_up.connect(func(_pid: int, _lvl: int):
		if stats_panel.panel.visible:
			refresh_stats())
	game.target_changed.connect(func(_pid: int, _m: Dictionary): target_panel.refresh())
	game.shop_requested.connect(func(_pid: int):
		shop_panel.far_warned = false
		refresh_shop()
		show_panel(shop_panel.panel))
	game.login_error.connect(func(text: String):
		if login_panel.root.visible:
			login_panel.login_error.text = text)
