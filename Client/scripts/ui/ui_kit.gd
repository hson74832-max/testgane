# Shared UI toolkit for all HUD panels: theme colors, widget factories and
# free panel placement (drag a header, release to drop on an invisible 16px
# grid — no edge docking).
# Typeface: one pixel-crisp monospace stack everywhere (panels, chat, canvas
# damage numbers, overhead names) — no bundled font file needed, the OS
# provides the faces and antialiasing stays off for the retro look.
class_name BlackTekUiKit
extends RefCounted

static var _px_font: SystemFont = null

static func px_font() -> Font:
	if _px_font == null:
		_px_font = SystemFont.new()
		_px_font.font_names = PackedStringArray(["Cascadia Mono", "Consolas", "DejaVu Sans Mono", "Courier New", "monospace"])
		_px_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	return _px_font

# Theme carrying the pixel typeface at Godot's default size (16), so only the
# look changes — every control with an explicit size override keeps it.
static func pixel_theme() -> Theme:
	var th := Theme.new()
	th.default_font = px_font()
	th.default_font_size = 16
	return th

const HP_COLOR := Color("e5484d")
const MP_COLOR := Color("3b82f6")
const XP_COLOR := Color("a855f7")
const PANEL_BG := Color(0.055, 0.065, 0.095, 0.93)
const PANEL_BORDER := Color(1, 1, 1, 0.09)
const SLOT_BG := Color(0.09, 0.1, 0.14, 0.9)
const ACCENT := Color(0.25, 0.8, 0.72)
const GOLD_COLOR := Color("f5d76e")

# ---- free drag & drop ----------------------------------------------------------

static var drag: Dictionary = {} # panel -> {"off": Vector2, "size": Vector2}

static func make_drag_handle(panel: Control, handle: Control) -> void:
	handle.mouse_filter = Control.MOUSE_FILTER_STOP
	handle.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				var r := panel.get_global_rect()
				panel.anchor_left = 0.0; panel.anchor_top = 0.0
				panel.anchor_right = 0.0; panel.anchor_bottom = 0.0
				panel.offset_left = r.position.x; panel.offset_top = r.position.y
				panel.offset_right = r.position.x + r.size.x
				panel.offset_bottom = r.position.y + r.size.y
				# Fixed size while dragging: store it, move all four offsets.
				# A plain click (press+release without motion) must NOT move or
				# re-dock the panel, so track whether it really moved.
				drag[panel] = {"off": r.position - handle.get_global_mouse_position(), "size": r.size, "press": handle.get_global_mouse_position(), "moved": false}
			else:
				var done: Dictionary = drag.get(panel, {})
				drag.erase(panel)
				if not done.is_empty() and bool(done.get("moved", false)):
					drop_panel(panel)
				# else: pure click on the bar — leave the panel exactly where
				# it was.
		elif ev is InputEventMouseMotion and drag.has(panel):
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				drag.erase(panel) # release happened off-handle: drop stale state
				return
			var d: Dictionary = drag[panel]
			if not bool(d.get("moved", false)):
				if handle.get_global_mouse_position().distance_to(d.press) < 5.0:
					return # click jitter, not a drag yet
				d.moved = true
			var pos: Vector2 = handle.get_global_mouse_position() + d.off
			var sz: Vector2 = d.size
			panel.offset_left = pos.x
			panel.offset_top = pos.y
			panel.offset_right = pos.x + sz.x
			panel.offset_bottom = pos.y + sz.y)

# Release after a drag: drop the panel freely on an invisible 16px grid.
# No edge docking — the grid extends past the screen edges, so panels may
# hang halfway off-screen while always keeping a grabbable sliver visible
# to pull them back.
static func drop_panel(panel: Control) -> void:
	drag.erase(panel)
	var vp := panel.get_viewport_rect().size
	var r := panel.get_global_rect()
	var w: float = r.size.x
	var h: float = r.size.y
	var gx := clampf(snappedf(r.position.x, 16.0), minf(48.0 - w, vp.x - 48.0), maxf(48.0 - w, vp.x - 48.0))
	var gy := clampf(snappedf(r.position.y, 16.0), minf(32.0 - h, vp.y - 32.0), maxf(32.0 - h, vp.y - 32.0))
	panel.anchor_left = 0.0; panel.anchor_top = 0.0
	panel.anchor_right = 0.0; panel.anchor_bottom = 0.0
	panel.offset_left = gx
	panel.offset_top = gy
	panel.offset_right = gx + w
	panel.offset_bottom = gy + h

# ---- widget factories -----------------------------------------------------------

static func panel_style(bg := PANEL_BG) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(1)
	sb.border_color = PANEL_BORDER
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

# Anchored panel on the HUD root. `at`: bottom-left, bottom-center, top-right,
# top-center, center.
static func panel(root: Control, at: String, rect: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style())
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	if at == "bottom-left":
		p.anchor_left = 0.0; p.anchor_top = 1.0; p.anchor_right = 0.0; p.anchor_bottom = 1.0
		p.offset_left = 12; p.offset_top = -rect.y - 12; p.offset_right = rect.x + 12; p.offset_bottom = -12
	elif at == "bottom-center":
		p.anchor_left = 0.5; p.anchor_top = 1.0; p.anchor_right = 0.5; p.anchor_bottom = 1.0
		p.offset_left = -rect.x / 2; p.offset_top = -rect.y - 10; p.offset_right = rect.x / 2; p.offset_bottom = -10
	elif at == "top-right":
		p.anchor_left = 1.0; p.anchor_top = 0.0; p.anchor_right = 1.0; p.anchor_bottom = 0.0
		p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		p.offset_left = -rect.x - 12; p.offset_top = 12; p.offset_right = -12; p.offset_bottom = 12 + rect.y
	elif at == "top-center":
		p.anchor_left = 0.5; p.anchor_top = 0.0; p.anchor_right = 0.5; p.anchor_bottom = 0.0
		p.offset_left = -rect.x / 2; p.offset_top = 10; p.offset_right = rect.x / 2; p.offset_bottom = 10 + rect.y
	elif at == "center":
		p.anchor_left = 0.5; p.anchor_top = 0.5; p.anchor_right = 0.5; p.anchor_bottom = 0.5
		p.offset_left = -rect.x / 2; p.offset_top = -rect.y / 2; p.offset_right = rect.x / 2; p.offset_bottom = rect.y / 2
	root.add_child(p)
	return p

static func label(parent: Control, text: String, size := 12, color := Color(0.92, 0.93, 0.96)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

static func bar(parent: Control, color: Color, height := 18) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.07)
	bg.set_corner_radius_all(height / 2)
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.set_corner_radius_all(height / 2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	parent.add_child(bar)
	return bar

static func bar_label(bar: ProgressBar, text: String, size := 10) -> Label:
	var l := Label.new()
	l.text = text
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(l)
	return l

static func fmt(n: int) -> String:
	if n >= 1000000:
		return "%.1fm" % [n / 1000000.0]
	if n >= 1000:
		return "%.1fk" % [n / 1000.0]
	return str(n)

static func chip(parent: Control, text: String, color: Color, tip: String) -> void:
	var chip := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color.r * 0.25, color.g * 0.25, color.b * 0.25, 0.9)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	chip.add_theme_stylebox_override("panel", sb)
	chip.tooltip_text = tip
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", color.lightened(0.25))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(l)
	parent.add_child(chip)

static func icon_button(glyph: String, tip: String, on_press: Callable, itemtype := -1, game: BlackTekGameServer = null) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(36, 36)
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = tip
	btn.add_theme_stylebox_override("normal", panel_style(SLOT_BG))
	btn.add_theme_stylebox_override("hover", panel_style(SLOT_BG.lightened(0.06)))
	btn.add_theme_stylebox_override("pressed", panel_style(SLOT_BG.lightened(0.12)))
	if itemtype >= 0 and game != null:
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
