extends CanvasLayer
## Mobile-first HUD. Mirrors web GamePlay.tsx layout: vitals top-left,
## target plate top-center, thumb stick bottom-left, action pads bottom-right,
## toasts center, death card overlay. Top UI fades after 3.8s idle like web.

const StickScript := preload("res://scripts/ui/virtual_joystick.gd")
const MinimapScript := preload("res://scripts/ui/minimap.gd")
const FilterSheet := preload("res://scripts/ui/sheets/filter_sheet.gd")
const GearSheet := preload("res://scripts/ui/sheets/gear_sheet.gd")
const BagSheet := preload("res://scripts/ui/sheets/bag_sheet.gd")
const SkillSheet := preload("res://scripts/ui/sheets/skill_sheet.gd")
const NpcSheet := preload("res://scripts/ui/sheets/npc_sheet.gd")
const FADE_AFTER_MS := 3800
const FADE_ALPHA := 0.32

var world: Node = null
var player: Node = null
var sim: Node = null

var _vitals: PanelContainer
var _level_badge: Label
var _name_label: Label
var _hp_bar: ProgressBar
var _mp_bar: ProgressBar
var _xp_bar: ProgressBar
var _vitals_line: Label
var _status_row: HBoxContainer
var _status_sig := ""
var _toast_label: Label
var _toast_until := 0
var _death_dim: ColorRect
var _death_title: Label
var _death_sub: Label
var _strike_btn: Button
var _cleave_btn: Button
var _bolt_btn: Button
var _ward_btn: Button
var _mark_btn: Button
var _loot_btn: Button
var _sheet_btns := {}
var _shove_bar: ProgressBar
var _filter_sheet: PanelContainer
var _gear_sheet: PanelContainer
var _bag_sheet: PanelContainer
var _skill_sheet: PanelContainer
var _npc_sheet: PanelContainer
var _chat_panel: PanelContainer
var _chat_box: VBoxContainer
var _chat_lines: Array = []
var _chat_input: LineEdit
var _chat_last := 0
var _minimap: Control
var _stick: Control
var _last_kills := -1
## Responsive scale: smaller display → smaller UI. 1.0 at 720px wide.
var S := 1.0
var _toast_text := ""
var _resize_hooked := false

func setup(w: Node, p: Node, s: Node) -> void:
	world = w
	player = p
	sim = s
	_compute_scale()
	if not _resize_hooked:
		_resize_hooked = true
		get_viewport().size_changed.connect(_on_resize)
	_build()
	sim.leveled_up.connect(func(_lvl: int) -> void: pass)  # toasts come via world
	_last_kills = int(player.get("kills"))
	_refresh_static()

func _compute_scale() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if vp.x >= vp.y:
		# Landscape desktop: fit the short axis so the top block (minimap +
		# utility rail) and the bottom block (stick + pads) never collide.
		# 760 chosen so 1152x648 lands at ~0.85 — verified layout below that.
		S = clampf(vp.y / 760.0, 0.6, 1.25)
	else:
		# Portrait phone: tuned against the 720-wide base (unchanged).
		S = clampf(vp.x / 720.0, 0.7, 1.25)

func _on_resize() -> void:
	_compute_scale()
	_build()

func _fs(base: int) -> int:
	return maxi(10, int(round(float(base) * S)))

func _panel_style() -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0.55)
	st.set_corner_radius_all(16)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	return st

func _bar(fill: Color, h: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0
	b.max_value = 100
	b.value = 100
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, h * S)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bg.set_corner_radius_all(int(h * S / 2.0))
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(int(h * S / 2.0))
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b

func _label(text: String, size: int, color: Color = Color(0.92, 0.93, 0.95)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", _fs(size))
	l.add_theme_color_override("font_color", color)
	return l

func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_status_sig = ""
	var m: float = 16.0 * S  # base margin
	# ---- vitals top-left ----
	_vitals = PanelContainer.new()
	_vitals.add_theme_stylebox_override("panel", _panel_style())
	_vitals.position = Vector2(m, m)
	_vitals.custom_minimum_size = Vector2(260.0 * S, 0)
	add_child(_vitals)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	_vitals.add_child(vb)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	vb.add_child(top)
	_level_badge = _label("1", 24, Color(0, 0, 0))
	_level_badge.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	top.add_child(_level_badge)
	_name_label = _label("Wanderer", 17)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_name_label)
	_hp_bar = _bar(Color(0.85, 0.25, 0.32), 12)
	vb.add_child(_hp_bar)
	_mp_bar = _bar(Color(0.25, 0.6, 0.95), 9)
	vb.add_child(_mp_bar)
	_xp_bar = _bar(Color(0.65, 0.9, 0.25), 5)
	vb.add_child(_xp_bar)
	_vitals_line = _label("", 13, Color(0.75, 0.78, 0.82))
	_vitals_line.clip_text = true
	vb.add_child(_vitals_line)
	_status_row = HBoxContainer.new()
	_status_row.add_theme_constant_override("separation", 6)
	vb.add_child(_status_row)
	# ---- target plate removed: the creature itself carries name + tiered
	# hp bar in-world now; wind-up reads from its swell + the tick reticle.
	# ---- toast center ----
	_toast_label = _label("", 24, Color(1.0, 0.9, 0.6))
	_toast_label.anchor_left = 0.5
	_toast_label.anchor_right = 0.5
	_toast_label.offset_left = -330.0 * S
	_toast_label.offset_right = 330.0 * S
	_toast_label.offset_top = 370.0 * S
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_toast_label)
	if _toast_text != "" and Time.get_ticks_msec() < _toast_until:
		_toast_label.text = _toast_text
	# ---- death overlay ----
	_death_dim = ColorRect.new()
	_death_dim.color = Color(0.35, 0.05, 0.1, 0.45)
	_death_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_dim.visible = false
	add_child(_death_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_dim.add_child(center)
	var dp := PanelContainer.new()
	dp.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(dp)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 8)
	dp.add_child(dv)
	_death_title = _label("YOU DIED", 40, Color(1.0, 0.4, 0.45))
	_death_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(_death_title)
	_death_sub = _label("", 17, Color(0.75, 0.78, 0.82))
	_death_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(_death_sub)
	# ---- stick bottom-left (200px zone, scaled) ----
	_stick = StickScript.new()
	_stick.anchor_top = 1.0
	_stick.anchor_bottom = 1.0
	_stick.offset_left = 24.0 * S
	_stick.offset_top = -64.0 * S - 200.0 * S
	_stick.offset_right = 24.0 * S + 200.0 * S
	_stick.offset_bottom = -64.0 * S
	add_child(_stick)
	_stick.set("base_r", 88.0 * S)
	_stick.set("knob_r", 32.0 * S)
	_stick.set("dead_px", 18.0 * S)
	_stick.moved.connect(func(v: Vector2) -> void:
		world.input_mgr.set_stick(v)
		if v.length() > 0.05:
			world.mark_input()
	)
	# ---- action pads bottom-right: combat only (2x2 + MARK/LOOT + shove) ----
	var pads := VBoxContainer.new()
	pads.add_theme_constant_override("separation", 10)
	pads.anchor_left = 1.0
	pads.anchor_top = 1.0
	pads.anchor_right = 1.0
	pads.anchor_bottom = 1.0
	pads.offset_left = -240.0 * S
	pads.offset_top = -310.0 * S
	pads.offset_right = -24.0 * S
	pads.offset_bottom = -24.0 * S
	add_child(pads)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", int(8 * S))
	grid.add_theme_constant_override("v_separation", int(8 * S))
	pads.add_child(grid)
	_strike_btn = _big_button("STRIKE %d" % _mana_cost("strike"), Color(0.95, 0.75, 0.3), Vector2(104, 80) * S, 14)
	grid.add_child(_strike_btn)
	_strike_btn.pressed.connect(func() -> void: world.on_strike_pad())
	_cleave_btn = _big_button("CLEAVE %d" % _mana_cost("cleave"), Color(0.94, 0.28, 0.44), Vector2(104, 80) * S, 14)
	grid.add_child(_cleave_btn)
	_cleave_btn.pressed.connect(func() -> void: world.on_cleave_pad())
	_bolt_btn = _big_button("BOLT %d" % _mana_cost("bolt"), Color(0.3, 0.79, 0.94), Vector2(104, 80) * S, 14)
	grid.add_child(_bolt_btn)
	_bolt_btn.pressed.connect(func() -> void: world.on_bolt_pad())
	_ward_btn = _big_button("WARD %d" % _mana_cost("ward"), Color(0.02, 0.84, 0.63), Vector2(104, 80) * S, 14)
	grid.add_child(_ward_btn)
	_ward_btn.pressed.connect(func() -> void: world.on_ward_pad())
	var midrow := HBoxContainer.new()
	midrow.add_theme_constant_override("separation", 8)
	pads.add_child(midrow)
	_mark_btn = _big_button("MARK", Color(0.25, 0.3, 0.38), Vector2(0, 52.0 * S), 18)
	_mark_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	midrow.add_child(_mark_btn)
	_mark_btn.pressed.connect(func() -> void: world.on_mark_pad())
	_loot_btn = _big_button("LOOT", Color(0.95, 0.65, 0.25), Vector2(0, 52.0 * S), 18)
	_loot_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	midrow.add_child(_loot_btn)
	_loot_btn.pressed.connect(func() -> void: world.on_loot_pad())
	# utility rail top-right under the minimap (web parity: menus live up top,
	# combat lives in the thumbs). BAG / GEAR / SKILLS / FILTER / CHAT.
	var util := VBoxContainer.new()
	util.add_theme_constant_override("separation", 6)
	util.anchor_left = 1.0
	util.anchor_top = 0.0
	util.anchor_right = 1.0
	util.anchor_bottom = 0.0
	util.offset_left = -120.0 * S
	util.offset_top = 128.0 * S
	util.offset_right = -16.0 * S
	util.offset_bottom = 128.0 * S + 5 * 40.0 * S + 4 * 6.0
	add_child(util)
	for spec in [["BAG", "bag"], ["GEAR", "gear"], ["SKILLS", "skill"], ["FILTER", "filter"], ["CHAT", "chat"]]:
		var sb := _big_button(String(spec[0]), Color(0.3, 0.35, 0.45), Vector2(104.0 * S, 40.0 * S), 14)
		util.add_child(sb)
		_sheet_btns[String(spec[1])] = sb
		sb.pressed.connect(toggle_sheet.bind(String(spec[1])))
	var shove_box := VBoxContainer.new()
	shove_box.add_theme_constant_override("separation", 2)
	pads.add_child(shove_box)
	var shove_lab := _label("SHOVE — drag a creature or yourself", 13, Color(0.7, 0.75, 0.8))
	# clip: an unclipped label's min width would shove the whole pad block
	# past the window edge (its text is wider than the pad column).
	shove_lab.clip_text = true
	shove_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shove_box.add_child(shove_lab)
	_shove_bar = _bar(Color(0.3, 0.8, 0.95), 8)
	shove_box.add_child(_shove_bar)
	# ---- chat log bottom-left, above the stick ----
	_chat_panel = PanelContainer.new()
	_chat_panel.add_theme_stylebox_override("panel", _panel_style())
	_chat_panel.anchor_top = 1.0
	_chat_panel.anchor_bottom = 1.0
	_chat_panel.offset_left = 24.0 * S
	_chat_panel.offset_top = -430.0 * S
	_chat_panel.offset_right = 24.0 * S + 340.0 * S
	_chat_panel.offset_bottom = -280.0 * S
	add_child(_chat_panel)
	_chat_box = VBoxContainer.new()
	_chat_box.add_theme_constant_override("separation", 2)
	_chat_panel.add_child(_chat_box)
	# ---- chat input bottom-center, hidden until CHAT/Enter ----
	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "Say something… (Enter sends, Esc closes)"
	_chat_input.max_length = 60
	_chat_input.visible = false
	_chat_input.anchor_left = 0.5
	_chat_input.anchor_top = 1.0
	_chat_input.anchor_right = 0.5
	_chat_input.anchor_bottom = 1.0
	_chat_input.offset_left = -210.0 * S
	_chat_input.offset_right = 210.0 * S
	_chat_input.offset_top = -330.0 * S
	_chat_input.offset_bottom = -286.0 * S
	_chat_input.add_theme_font_size_override("font_size", _fs(16))
	add_child(_chat_input)
	_chat_input.text_submitted.connect(_submit_chat)
	# ---- minimap top-right (104px board at S=1) ----
	_minimap = MinimapScript.new()
	_minimap.anchor_left = 1.0
	_minimap.anchor_right = 1.0
	_minimap.offset_left = -16.0 * S - 104.0 * S
	_minimap.offset_top = 16.0 * S
	_minimap.offset_right = -16.0 * S
	_minimap.offset_bottom = 16.0 * S + 104.0 * S
	add_child(_minimap)
	_minimap.setup(world.get("tiles"), player, sim)
	_host_sheets()
	_refresh_static()

func _big_button(text: String, color: Color, min_size: Vector2, font_size: int = 22) -> Button:
	var b := Button.new()
	b.text = text
	b.clip_text = true
	# NOTE: flexible buttons (min x == 0) must NOT demand a fixed width —
	# a 192px fallback once pushed LOOT/GEAR/FILTER off the screen edge.
	b.custom_minimum_size = min_size if min_size.x > 0 else Vector2(0, min_size.y)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", _fs(font_size))
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

func _refresh_static() -> void:
	if player == null:
		return

func toggle_chat_input() -> void:
	_chat_input.visible = not _chat_input.visible
	if _chat_input.visible:
		_chat_input.grab_focus()
	else:
		_chat_input.release_focus()

func chat_open() -> bool:
	return _chat_input != null and _chat_input.visible

func _submit_chat(text: String) -> void:
	_chat_input.text = ""
	_chat_input.visible = false
	_chat_input.release_focus()
	world.say(text)

func chat_add(line: String) -> void:
	_chat_lines.append(line)
	while _chat_lines.size() > 30:
		_chat_lines.pop_front()
	for c in _chat_box.get_children():
		c.queue_free()
	for l in _chat_lines.slice(maxi(0, _chat_lines.size() - 6)):
		_chat_box.add_child(_label(String(l), 12, Color(0.85, 0.88, 0.9)))
	_chat_last = Time.get_ticks_msec()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo or k.keycode != KEY_ESCAPE:
		return
	# Esc closes topmost UI first: sheets, then the chat box.
	if _any_sheet_open():
		_close_sheets()
		get_viewport().set_input_as_handled()
		return
	if _chat_input != null and _chat_input.visible:
		_chat_input.text = ""
		toggle_chat_input()
		get_viewport().set_input_as_handled()

func _any_sheet_open() -> bool:
	for sh in [_bag_sheet, _gear_sheet, _filter_sheet, _skill_sheet, _npc_sheet]:
		if is_instance_valid(sh) and sh.visible:
			return true
	return false

func _close_sheets() -> void:
	for sh in [_bag_sheet, _gear_sheet, _filter_sheet, _skill_sheet, _npc_sheet]:
		if is_instance_valid(sh):
			sh.visible = false

func show_toast(text: String) -> void:
	_toast_text = text
	_toast_label.text = text
	_toast_until = Time.get_ticks_msec() + 2600

func show_death(killed_by: String, xp_lost: int, gold: int) -> void:
	_death_sub.text = "Slain by %s\n-%d xp   -%dg dropped where you fell (60s claim)\nRespawning at Sanctuary…" % [killed_by, xp_lost, gold]

func _process(_delta: float) -> void:
	if player == null or sim == null or world == null:
		return
	var now: int = Time.get_ticks_msec()
	_minimap.set("tiles", world.get("tiles"))  # follow rift travel across floors
	# vitals
	var lvl: int = int(player.get("level"))
	var pg: Vector3i = player.get("grid")
	_level_badge.text = str(lvl)
	_name_label.text = "%s · %s   %dg" % [str(sim.get("player_name")), str((sim.Vocations.def(sim.get("vocation")) as Dictionary).get("name", "?")), int(player.get("gold"))]
	_hp_bar.max_value = maxi(1, int(player.get("max_hp")))
	_hp_bar.value = maxi(0, int(player.get("hp")))
	_mp_bar.max_value = maxi(1, int(player.get("max_mana")))
	_mp_bar.value = maxi(0, int(player.get("mana")))
	var prev: int = GameBalance.xp_for_level(maxi(1, lvl - 1)) if lvl > 1 else 0
	var next: int = GameBalance.xp_for_level(lvl)
	_xp_bar.max_value = maxi(1, next - prev)
	_xp_bar.value = clampi(int(player.get("xp")) - prev, 0, maxi(1, next - prev))
	var region: String = WorldGen.region_name_at(pg)
	_vitals_line.text = "%s · %s · A%d · %dms" % [
		region,
		"PZ" if WorldGen.in_safe_zone(pg.x, pg.y) else "wilds",
		int(player.get("armor")), GameBalance.step_ms_for(int(player.get("heavy"))),
	]
	_update_statuses()
	# target info lives on the creature (name + tiered bar above it) — no plate.
	# strike cooldown + shove readiness (offensive pads die inside the Sanctuary)
	_update_pad(_strike_btn, "strike", "STRIKE", true)
	_update_pad(_cleave_btn, "cleave", "CLEAVE", true)
	_update_pad(_bolt_btn, "bolt", "BOLT", true)
	_update_pad(_ward_btn, "ward", "WARD", false)
	_shove_bar.value = (1.0 - sim.push_cooldown_pct()) * 100.0
	var near: int = sim.nearby_loot_count()
	_loot_btn.text = "LOOT %d" % near if near > 0 else "LOOT"
	var pts: int = int(player.get("skill_points"))
	var sk: Button = _sheet_btns.get("skill")
	if sk != null:
		sk.text = "SKILL·%d" % pts if pts > 0 else "SKILLS"
	# toast decay
	if _toast_label.text != "" and now > _toast_until:
		_toast_label.text = ""
	# NPC deals close past talk range: no cross-map trading through an open sheet
	if _npc_sheet != null and _npc_sheet.visible:
		var npcs = world.get("npcs")
		var cur: Dictionary = _npc_sheet.get("_current")
		if cur.is_empty() or not npcs.can_talk(cur):
			_npc_sheet.visible = false
			sim.toast.emit("Deal closed — too far from the counter.", "info")
	# chat hides when idle (unless typing) — sheets cover the rest
	_chat_panel.modulate.a = 0.0 if (now - _chat_last > 6000 and not _chat_input.visible) else 1.0
	# death overlay + kill haptic
	_death_dim.visible = bool(player.get("dead"))
	var kills: int = int(player.get("kills"))
	if _last_kills >= 0 and kills > _last_kills:
		Input.vibrate_handheld(30)
	_last_kills = kills
	# idle fade (web parity: 3.8s -> 32%)
	var dim: bool = now - int(world.get("last_input_msec")) > FADE_AFTER_MS
	var a: float = FADE_ALPHA if dim else 1.0
	_vitals.modulate.a = a

func _abil(key: String) -> Dictionary:
	for a in (GameBalance.ABILITIES as Array):
		if String(a.get("key", "")) == key:
			return a
	return {}

func _mana_cost(key: String) -> int:
	return int(_abil(key).get("manaCost", 0))

func _update_pad(btn: Button, key: String, school: String, offensive: bool) -> void:
	var cd: float = sim.ability_cooldown_pct(key)
	var cost: int = _mana_cost(key)
	var pacified: bool = offensive and sim.is_player_pacified()
	var off: bool = cd > 0.0 or int(player.get("mana")) < cost or bool(player.get("dead")) or pacified
	btn.disabled = off
	btn.text = "…" if cd > 0.0 else "%s %d" % [school, cost]
	btn.modulate.a = 0.45 if pacified else 1.0

func _host_sheets() -> void:
	_filter_sheet = FilterSheet.new()
	_filter_sheet.setup(world, player, sim, S)
	add_child(_filter_sheet)
	_gear_sheet = GearSheet.new()
	_gear_sheet.setup(world, player, sim, S)
	add_child(_gear_sheet)
	_bag_sheet = BagSheet.new()
	_bag_sheet.setup(world, player, sim, S)
	add_child(_bag_sheet)
	_skill_sheet = SkillSheet.new()
	_skill_sheet.setup(world, player, sim, S)
	add_child(_skill_sheet)
	_npc_sheet = NpcSheet.new()
	_npc_sheet.setup(world, player, sim, S)
	add_child(_npc_sheet)
	for sh in [_filter_sheet, _gear_sheet, _bag_sheet, _skill_sheet, _npc_sheet]:
		_cap_sheet(sh)

## Short landscape windows must never get a sheet taller than ~70% of them.
func _cap_sheet(sh: Control) -> void:
	var vh: float = get_viewport().get_visible_rect().size.y
	sh.offset_top = maxf(sh.offset_top, -(vh * 0.70 + 16.0 * S))

func toggle_sheet(which: String) -> void:
	world.mark_input()
	world.buzz(8)
	if which == "chat":
		toggle_chat_input()
		return
	var target: PanelContainer = {"bag": _bag_sheet, "gear": _gear_sheet, "filter": _filter_sheet, "skill": _skill_sheet}.get(which, null)
	if target == null:
		return
	var opening: bool = not target.visible
	_bag_sheet.visible = false
	_gear_sheet.visible = false
	_filter_sheet.visible = false
	_skill_sheet.visible = false
	_npc_sheet.visible = false
	if opening:
		target.visible = true
		target.refresh()

func open_npc_sheet(npc: Dictionary) -> void:
	world.mark_input()
	_bag_sheet.visible = false
	_gear_sheet.visible = false
	_filter_sheet.visible = false
	_skill_sheet.visible = false
	_npc_sheet.open(npc)

func _update_statuses() -> void:
	var sts: Array = player.get("statuses")
	var sig := ""
	for s in sts:
		sig += String(s.get("key", "")) + ";"
	if sig == _status_sig:
		return
	_status_sig = sig
	for c in _status_row.get_children():
		c.queue_free()
	for s in sts:
		var key: String = String(s.get("key", ""))
		var col := Color(0.6, 0.8, 1.0)
		if key == "poison":
			col = Color(0.65, 0.9, 0.25)
		elif key == "burn":
			col = Color(1.0, 0.6, 0.25)
		elif key == "ward":
			col = Color(0.1, 0.85, 0.6)
		var chip := _label(key.to_upper(), 12, col)
		_status_row.add_child(chip)
