# Status bars: HP/Mana/XP with level/vocation plus condition chips
# (PZ, Poisoned, Lit, Fed/Hungry). Refreshed by the shell on a cadence and on
# every stats change.
class_name BlackTekStatusPanel
extends RefCounted

var hud: Control
var game: BlackTekGameServer
var panel: PanelContainer
var pid := 1
var name_label: Label
var hp_bar: ProgressBar
var hp_label: Label
var mp_bar: ProgressBar
var mp_label: Label
var xp_bar: ProgressBar
var xp_label: Label
var cond_row: HBoxContainer

func build(h: Control) -> void:
	hud = h
	game = hud.game
	pid = hud._pid
	panel = BlackTekUiKit.panel(hud, "bottom-left", Vector2(320, 156))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	name_label = BlackTekUiKit.label(box, "—", 14)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar = BlackTekUiKit.bar(box, BlackTekUiKit.HP_COLOR)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_label = BlackTekUiKit.bar_label(hp_bar, "HP 0/0")
	mp_bar = BlackTekUiKit.bar(box, BlackTekUiKit.MP_COLOR)
	mp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp_label = BlackTekUiKit.bar_label(mp_bar, "MP 0/0")
	xp_bar = BlackTekUiKit.bar(box, BlackTekUiKit.XP_COLOR, 12)
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_label = BlackTekUiKit.bar_label(xp_bar, "XP 0%", 9)
	cond_row = HBoxContainer.new()
	cond_row.add_theme_constant_override("separation", 4)
	box.add_child(cond_row)
	panel.tooltip_text = "Drag to move · release to drop on the grid"
	BlackTekUiKit.make_drag_handle(panel, panel)
	panel.visible = false

func update_status() -> void:
	if game.players.is_empty() or hp_bar == null:
		return
	var p: Dictionary = game.players[pid]
	name_label.text = "%s  ·  level %d %s" % [String(p.name), int(p.level), BlackTekVitals.vocation_name(game, int(p.vocation))]
	hp_bar.max_value = int(p.hpmax)
	hp_bar.value = int(p.hp)
	hp_label.text = "HP %d / %d" % [int(p.hp), int(p.hpmax)]
	mp_bar.max_value = maxi(1, int(p.manamax))
	mp_bar.value = int(p.mana)
	mp_label.text = "MP %d / %d" % [int(p.mana), int(p.manamax)]
	var prev := float(BlackTekGameServer.exp_for_level(int(p.level)))
	var next := float(BlackTekGameServer.exp_for_level(int(p.level) + 1))
	var frac := clampf((float(int(p.exp)) - prev) / maxf(1.0, next - prev), 0.0, 1.0)
	xp_bar.value = frac * 100.0
	xp_label.text = "XP %.1f%%  (%s / %s)" % [frac * 100.0, BlackTekUiKit.fmt(int(p.exp)), BlackTekUiKit.fmt(int(next))]
	# Condition chips (cf. client conditions icons).
	for c in cond_row.get_children():
		c.queue_free()
	if game.is_pz_tile(p.tile):
		BlackTekUiKit.chip(cond_row, "PZ", Color(0.35, 0.55, 1.0), "Protection zone (temple area) — you regenerate safely here.")
	if game.is_poisoned(pid):
		BlackTekUiKit.chip(cond_row, "Poisoned", Color(0.4, 0.75, 0.3), "Losing 2 hitpoints every 2 seconds.")
	if float(p.get("light_until", 0.0)) > Time.get_ticks_msec() / 1000.0:
		BlackTekUiKit.chip(cond_row, "Lit", Color(1.0, 0.85, 0.4), "utevo lux — personal light (see at night).")
	if game.is_fed(pid):
		BlackTekUiKit.chip(cond_row, "Fed", Color(0.35, 0.8, 0.45), "Well fed — regeneration interval halved.")
	else:
		BlackTekUiKit.chip(cond_row, "Hungry", Color(0.9, 0.6, 0.2), "Eat something (F1 or drag meat to the bar) to regenerate faster.")
