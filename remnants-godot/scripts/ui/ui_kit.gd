extends RefCounted
## UiKit — one visual language for HUD + sheets. Every builder takes the
## responsive scale S so panels, type and touch targets shrink together.

static func fs(base: int, s: float) -> int:
	return maxi(10, int(round(float(base) * s)))

static func panel_style() -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0.55)
	st.set_corner_radius_all(16)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	return st

static func bar(fill: Color, h: float, s: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0
	b.max_value = 100
	b.value = 100
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, h * s)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bg.set_corner_radius_all(int(h * s / 2.0))
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(int(h * s / 2.0))
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b

static func label(text: String, size: int, s: float, color: Color = Color(0.92, 0.93, 0.95)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs(size, s))
	l.add_theme_color_override("font_color", color)
	return l

static func big_button(text: String, color: Color, min_size: Vector2, font_size: int, s: float) -> Button:
	var b := Button.new()
	b.text = text
	b.clip_text = true
	# NOTE: flexible buttons (min x == 0) must NOT demand a fixed width —
	# a 192px fallback once pushed LOOT/GEAR/FILTER off the screen edge.
	b.custom_minimum_size = Vector2(min_size.x * s, min_size.y * s) if min_size.x > 0 else Vector2(0, min_size.y * s)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", fs(font_size, s))
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_corner_radius_all(16)
	normal.border_width_bottom = 5
	normal.border_color = Color(0, 0, 0, 0.5)
	b.add_theme_stylebox_override("normal", normal)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.2)
	b.add_theme_stylebox_override("pressed", pressed)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.3, 0.32, 0.36, 0.8)
	b.add_theme_stylebox_override("disabled", disabled)
	return b

## Bottom-sheet shell: full-width, content height capped, hidden by default.
static func sheet_panel(s: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style())
	apply_sheet_geometry(panel, s)
	panel.visible = false
	return panel

## Geometry shared by standalone sheet scripts (they extend PanelContainer).
## NOTE: sheets are styled before add_child, so the viewport-height cap for
## short landscape windows is applied later by Hud._cap_sheet.
static func apply_sheet_geometry(panel: PanelContainer, s: float) -> void:
	panel.add_theme_stylebox_override("panel", panel_style())
	panel.anchor_left = 0.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 16.0 * s
	panel.offset_top = -620.0 * s
	panel.offset_right = -16.0 * s
	panel.offset_bottom = -16.0 * s
	panel.visible = false

## Title row with a close button. Returns the close button for wiring.
static func sheet_head(parent: VBoxContainer, title: String, s: float) -> Button:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	parent.add_child(head)
	var t := label(title, 20, s)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var close_b := big_button("X", Color(0.5, 0.3, 0.3), Vector2(56, 40), 16, s)
	head.add_child(close_b)
	return close_b
