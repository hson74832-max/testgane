# Stats panel: level/XP/health/mana/cap/armor/gold rows, skill progress bars
# and the push-cooldown readout for the marked target.
class_name BlackTekStatsPanel
extends RefCounted

const SKILL_ORDER := ["fist", "club", "sword", "axe", "dist", "shield", "fishing"]
const SKILL_LABELS := {"fist": "Fist", "club": "Club", "sword": "Sword", "axe": "Axe", "dist": "Distance", "shield": "Shielding", "fishing": "Fishing"}

var hud: Control
var game: BlackTekGameServer
var panel: PanelContainer
var pid := 1
var box: VBoxContainer

func build(h: Control) -> void:
	hud = h
	game = hud.game
	pid = hud._pid
	panel = BlackTekUiKit.panel(hud, "top-right", Vector2(232, 440))
	panel.offset_top = 190
	panel.offset_bottom = 630
	panel.offset_left = -248
	panel.offset_right = -16
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	panel.add_child(root)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	scroll.add_child(box)
	hud.panel_header(panel, root, "Stats")
	panel.visible = false

func toggle() -> void:
	hud._toggle_panel(panel)
	if panel.visible:
		refresh_stats()

func refresh_stats() -> void:
	if game.players.is_empty() or box == null:
		return
	for c in box.get_children():
		c.queue_free()
	var p: Dictionary = game.players[pid]
	BlackTekUiKit.label(box, "%s  ·  %s" % [String(p.name), BlackTekVitals.vocation_name(game, int(p.vocation))], 13, BlackTekUiKit.ACCENT)
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
		["Armor", str(game.total_armor(pid))],
		["Soul", str(int(p.soul))],
		["Gold", str(gold)],
		["Speed", "220"],
	]
	for r in rows:
		var h := HBoxContainer.new()
		box.add_child(h)
		BlackTekUiKit.label(h, r[0], 11, Color(0.6, 0.65, 0.72)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		BlackTekUiKit.label(h, r[1], 11)
		if String(r[0]) == "Experience":
			_push_cooldown_row(p) # push cooldown lives right below the XP row
	BlackTekUiKit.label(box, "Skills", 12, BlackTekUiKit.ACCENT)
	_skill_row("Magic level", int(p.maglevel), int(p.get("mlvl_tries", 0)), int((int(p.maglevel) + 1) * 80.0 / BlackTekGameServer.RATE_MAGIC))
	for sk in SKILL_ORDER:
		var lvl := int(p.skills.get(sk, 10))
		var need := int((lvl + 1) * 12.0 / BlackTekGameServer.RATE_SKILL)
		_skill_row(SKILL_LABELS[sk], lvl, int(p.skill_tries.get(sk, 0)), need)

# Push cooldown loading bar: drains while the current target cannot be pushed
# again, "Ready" when a push would go through, "Too far" when the target is
# outside melee range, "No target" without one. Refreshes with the stats.
func _push_cooldown_row(p: Dictionary) -> void:
	BlackTekUiKit.label(box, "Push", 12, BlackTekUiKit.ACCENT)
	var tid := int(p.get("target", 0))
	var tm: Dictionary = game.monsters.get(tid, {}) if tid != 0 else {}
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	box.add_child(h)
	var l := BlackTekUiKit.label(h, "Cooldown", 10, Color(0.6, 0.65, 0.72))
	l.custom_minimum_size = Vector2(88, 0)
	var bar := BlackTekUiKit.bar(h, BlackTekUiKit.ACCENT, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = game.push_cd()
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
	bar.value = clampf(rem, 0.0, game.push_cd())
	st.text = "Ready (%s)" % tname if rem <= 0.01 else "%.1fs (%s)" % [rem, tname]

func _skill_row(name_text: String, level: int, tries: int, need: int) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	box.add_child(h)
	var l := BlackTekUiKit.label(h, name_text, 10, Color(0.6, 0.65, 0.72))
	l.custom_minimum_size = Vector2(88, 0)
	var bar := BlackTekUiKit.bar(h, BlackTekUiKit.ACCENT, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = maxi(1, need)
	bar.value = clampi(tries, 0, need)
	var lv := BlackTekUiKit.label(h, str(level), 11)
	lv.custom_minimum_size = Vector2(24, 0)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
