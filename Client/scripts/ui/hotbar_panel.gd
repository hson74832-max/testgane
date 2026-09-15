# Action bars: potion/spell/attack slots with cooldown sweeps, F-key entry and
# persisted bindings. Slot commands go out through the shell's hotbar_command
# signal (main.gd executes them against the server).
class_name BlackTekHotbarPanel
extends RefCounted

# Action bars: "item" slots use the first matching stack in the backpack,
# "spell" slots cast. Drag an item from the backpack onto a slot to assign it.
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

var hud: Control
var game: BlackTekGameServer
var wrap: Control
var slots: Array = []
var records: Array = [] # per-bar slot recs (persisted bindings)

func build(h: Control) -> void:
	hud = h
	game = hud.game
	var w := VBoxContainer.new()
	w.add_theme_constant_override("separation", 5)
	w.anchor_left = 0.5; w.anchor_top = 1.0; w.anchor_right = 0.5; w.anchor_bottom = 1.0
	w.offset_left = -95; w.offset_top = -176; w.offset_right = 95; w.offset_bottom = -12
	hud.add_child(w)
	wrap = w
	for bar in HOTBAR_BARS:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		w.add_child(col)
		var cap := Label.new()
		cap.text = bar.title
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.add_theme_font_size_override("font_size", 8)
		cap.add_theme_color_override("font_color", Color(0.6, 0.65, 0.72))
		cap.mouse_filter = Control.MOUSE_FILTER_STOP
		cap.tooltip_text = "Drag to move the bars"
		BlackTekUiKit.make_drag_handle(w, cap)
		col.add_child(cap)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(row)
		var recs: Array = []
		for sl in bar.slots:
			var rec: Dictionary = {"kind": sl.kind, "value": sl.value, "hotkey": sl.get("hotkey", "")}
			var slot := _make_hotbar_slot(rec)
			row.add_child(slot)
			slot.visible = false
			recs.append(rec)
		records.append(recs)

func set_slots_visible(playing: bool) -> void:
	for rec in slots:
		(rec.node.btn as Button).visible = playing

func _slot_label(rec: Dictionary) -> String:
	if String(rec.kind) == "item":
		var n: String = game.item_label(int(rec.value)) if game != null else ""
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

func _make_hotbar_slot(rec: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(56, 56)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", BlackTekUiKit.panel_style(BlackTekUiKit.SLOT_BG))
	btn.add_theme_stylebox_override("hover", BlackTekUiKit.panel_style(BlackTekUiKit.SLOT_BG.lightened(0.06)))
	btn.add_theme_stylebox_override("pressed", BlackTekUiKit.panel_style(BlackTekUiKit.SLOT_BG.lightened(0.1)))
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
	glyph.add_theme_color_override("font_color", BlackTekUiKit.ACCENT)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(glyph)
	var cap := Label.new()
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 9)
	cap.add_theme_color_override("font_color", BlackTekUiKit.GOLD_COLOR)
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
	slots.append(rec)
	return btn

func _emit_slot(rec: Dictionary) -> void:
	match String(rec.kind):
		"item":
			hud.hotbar_command.emit({"kind": "item", "itemtype": int(rec.value)})
		"spell":
			hud.hotbar_command.emit({"kind": "spell", "spell": String(rec.value)})
		_:
			hud.hotbar_command.emit({"kind": "attack"})

# F-key entry point: trigger bar/idx (0-based) as if clicked.
func activate_slot(bar: int, idx: int) -> void:
	if bar >= 0 and bar < records.size() and idx >= 0 and idx < records[bar].size():
		_emit_slot(records[bar][idx])

# Persisted layout: flat [kind, value] pairs for all slots.
func hotbar_layout() -> Array:
	var out := []
	for bar_recs in records:
		for rec in bar_recs:
			out.append([String(rec.kind), rec.value])
	return out

func apply_hotbar_layout(layout: Array) -> void:
	var flat: Array = []
	for bar_recs in records:
		for rec in bar_recs:
			flat.append(rec)
	for i in range(mini(flat.size(), layout.size())):
		var entry: Array = layout[i]
		if entry.size() >= 2 and ["item", "spell", "attack"].has(String(entry[0])):
			flat[i].kind = String(entry[0])
			flat[i].value = entry[1]
			_refresh_slot_content(flat[i])

func update_cooldowns() -> void:
	if game.players.is_empty():
		return
	var p: Dictionary = game.players.get(hud._pid, {})
	var now := Time.get_ticks_msec() / 1000.0
	var cds: Dictionary = p.get("cooldowns", {})
	for rec in slots:
		var frac := 0.0
		match String(rec.kind):
			"item":
				frac = _cd_frac(float(cds.get("potion", 0.0)), now)
			"spell":
				frac = _cd_frac(float(cds.get("spell", 0.0)), now)
			"attack":
				frac = _cd_frac(float(p.get("attack_cd", 0.0)), now)
		var cd: ColorRect = rec.node.cd
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
