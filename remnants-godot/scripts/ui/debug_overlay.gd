extends CanvasLayer
## Debug overlay (F3, or REMNANTS_DEBUG=1 to start visible). Answers "why is
## that monster just standing there": heartbeat proves the sim ticks, then
## per-creature rows show the exact aggro inputs (dist/sense/safe/flow) and
## attack state (windup-in/cadence-in/telegraph?). Screenshot this with bugs.

var world = null
var _label: Label
var _acc := 0.0

func setup(w) -> void:
	world = w
	layer = 90
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.position = Vector2(16, 300)
	add_child(_label)
	visible = OS.get_environment("REMNANTS_DEBUG") == "1"

func toggle() -> void:
	visible = not visible

func _process(_delta: float) -> void:
	if not visible or world == null:
		return
	_acc += _delta
	if _acc < 0.25:
		return
	_acc = 0.0
	var sim = world.get("sim")
	var player = world.get("player")
	if sim == null or player == null:
		return
	var pg: Vector3i = player.get("grid")
	var now: int = Time.get_ticks_msec()
	var lines: Array = []
	lines.append("tick=%d fps=%d" % [int(sim.get("_tick_count")), int(Engine.get_frames_per_second())])
	lines.append("you (%d,%d,%d) %s%s flow=%s" % [pg.x, pg.y, pg.z,
		"DEAD" if bool(player.get("dead")) else ("SAFE" if WorldGen.in_safe_zone(pg.x, pg.y) and pg.z == 0 else "wild"),
		" tgt=%d" % int(sim.get("target_id")),
		"ok" if not (sim.flow.field as Array).is_empty() else "EMPTY"])
	var rows: Array = []
	for m in (sim.get("monsters") as Array):
		if int(m.get("dying_at")) != 0:
			continue
		var mg: Vector3i = m.get("grid")
		if mg.z != pg.z:
			continue
		var d: int = maxi(absi(mg.x - pg.x), absi(mg.y - pg.y))
		rows.append({"m": m, "d": d})
	rows.sort_custom(func(a, b): return a["d"] < b["d"])
	var shown := 0
	for r in rows:
		if shown >= 6:
			break
		shown += 1
		var m = r["m"]
		var mg: Vector3i = m.get("grid")
		var tele := false
		for tg in (sim.get("telegraphs") as Array):
			if String(tg.get("source", "")) == "monster" and int(tg.get("source_id", -1)) == int(m.get("mid")) and not bool(tg.get("resolved", true)):
				tele = true
		lines.append("%s(%d,%d) d=%d s=%d %s w%ds c%ds fl=%d%s" % [
			String((m.get("def") as Dictionary).get("key", "?")), mg.x, mg.y,
			int(r["d"]), int(m.get("sense")),
			"AGGRO" if bool(m.get("aggro")) else "idle",
			maxi(0, int(m.get("windup_until")) - now) / 1000,
			maxi(0, int(m.get("next_attack_at")) - now) / 1000,
			sim.flow.value(mg.x, mg.y),
			" TELE" if tele else "",
		])
	_label.text = "\n".join(lines)
