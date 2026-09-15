# Target frame: the marked creature (name, HP, distance). Auto-shows while a
# target is set, hides when it clears — no manual open/close needed.
class_name BlackTekTargetPanel
extends RefCounted

var hud: Control
var game: BlackTekGameServer
var panel: PanelContainer
var pid := 1
var name_label: Label
var hp_bar: ProgressBar
var hp_label: Label
var dist_label: Label

func build(h: Control) -> void:
	hud = h
	game = hud.game
	pid = hud._pid
	panel = BlackTekUiKit.panel(hud, "top-center", Vector2(220, 96))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	name_label = BlackTekUiKit.label(box, "No target", 13, BlackTekUiKit.ACCENT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_bar = BlackTekUiKit.bar(box, BlackTekUiKit.HP_COLOR, 12)
	hp_label = BlackTekUiKit.bar_label(hp_bar, "", 9)
	dist_label = BlackTekUiKit.label(box, "", 10, Color(0.6, 0.65, 0.72))
	dist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.visible = false

func refresh() -> void:
	if game.players.is_empty():
		panel.visible = false
		return
	var p: Dictionary = game.players.get(pid, {})
	var tid := int(p.get("target", 0))
	var tm: Dictionary = game.monsters.get(tid, {}) if tid != 0 else {}
	if tm.is_empty():
		panel.visible = false
		return
	panel.visible = true
	var hpmax := maxi(1, int(tm.get("hpmax", 1)))
	name_label.text = String(tm.get("name", "creature"))
	hp_bar.max_value = hpmax
	hp_bar.value = clampi(int(tm.get("hp", 0)), 0, hpmax)
	hp_label.text = "%d / %d" % [int(tm.get("hp", 0)), hpmax]
	var ptile: Vector2i = p.get("tile", Vector2i.ZERO)
	var d: int = maxi(absi(int(tm.tile.x) - ptile.x), absi(int(tm.tile.y) - ptile.y))
	if int(tm.z) != int(p.get("z", 7)):
		dist_label.text = "another floor"
	else:
		dist_label.text = "next to you" if d <= 1 else "%d tiles away" % d
