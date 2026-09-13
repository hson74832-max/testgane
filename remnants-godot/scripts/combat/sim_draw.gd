extends RefCounted
## SimDraw — every CanvasItem paint call for the sim (mirrors web renderer.ts).
## CombatSim owns state + tick and delegates from _draw. Pure presentation:
## no timers advanced, no state mutated here.

static func rarity_color(item_key: String) -> Color:
	var rarity: String = String((GameBalance.item_def(item_key) as Dictionary).get("rarity", "common"))
	match rarity:
		"epic":
			return Color(0.75, 0.15, 0.83)
		"rare":
			return Color(0.05, 0.65, 0.91)
		"uncommon":
			return Color(0.06, 0.73, 0.51)
	return Color(0.58, 0.64, 0.72)

static func item_label(item_key: String) -> String:
	if item_key == "gold":
		return "Gold"
	return String((GameBalance.item_def(item_key) as Dictionary).get("name", item_key))

static func all(canvas: CanvasItem, sim) -> void:
	var t := float(WorldGen.TILE_PX)
	var font: Font = ThemeDB.fallback_font
	var now: int = Time.get_ticks_msec()
	telegraphs(canvas, sim, t, now)
	ground(canvas, sim, t, font, now)
	projectiles(canvas, sim, t, now)
	reticle(canvas, sim, t, now)
	push_preview(canvas, sim, t)
	floats(canvas, sim, t, font, now)

static func telegraphs(canvas: CanvasItem, sim, t: float, now: int) -> void:
	var pz: int = int(sim.player.grid.z)
	for tg in (sim.get("telegraphs") as Array):
		if int(tg.get("z", 0)) != pz:
			continue
		var total: float = maxf(1.0, float(int(tg["resolve_at"]) - int(tg["start_at"])))
		var p: float = clampf(float(now - int(tg["start_at"])) / total, 0.0, 1.0)
		var done: bool = now >= int(tg["resolve_at"])
		var flash: float = maxf(0.0, 1.0 - float(now - int(tg["resolve_at"])) / 220.0) if done else 0.0
		for cell in (tg["tiles"] as Array):
			var pos := Vector2((cell as Vector3i).x, (cell as Vector3i).y) * t
			var col: Color = tg["color"]
			if done:
				canvas.draw_rect(Rect2(pos + Vector2(2, 2), Vector2(t - 4, t - 6)), Color(col, flash * 0.85))
			else:
				canvas.draw_rect(Rect2(pos + Vector2(2, 2), Vector2(t - 4, t - 6)), Color(col, 0.22 + p * 0.42))
				canvas.draw_rect(Rect2(pos + Vector2(3, t - 8 - (t - 12) * p), Vector2(t - 6, (t - 12) * p)), Color(1, 1, 1, 0.5))

static func ground(canvas: CanvasItem, sim, t: float, font: Font, now: int) -> void:
	var pz: int = int(sim.player.grid.z)
	for g in (sim.get("ground") as Array):
		if not sim.is_visible_loot(g) or int((g["grid"] as Vector3i).z) != pz:
			continue
		ground_one(canvas, sim, g, t, font, now)

static func ground_one(canvas: CanvasItem, sim, g: Dictionary, t: float, font: Font, now: int) -> void:
	var cell: Vector3i = g["grid"]
	var base := Vector2(cell.x, cell.y) * t + Vector2(float(g.get("jx", 0.0)), float(g.get("jy", 0.0))) * t
	var bob: float = sin(float(now) / 320.0 + float(int(g.get("id", 0)))) * 2.0
	var locked: bool = not sim.can_loot(g)
	var tint: Color = rarity_color(String(g.get("item_key", "")))
	var cx: float = base.x + t / 2.0
	# shadow
	var sh := PackedVector2Array()
	for i in range(16):
		var a: float = TAU * float(i) / 16.0
		sh.append(Vector2(cx, base.y + t * 0.74 + bob) + Vector2(cos(a) * t * 0.2, sin(a) * t * 0.09))
	canvas.draw_colored_polygon(sh, Color(0, 0, 0, 0.3))
	# rarity plinth: dark box + colored ring, item initial instead of emoji
	var box := Rect2(base.x + t * 0.24, base.y + t * 0.26 + bob, t * 0.52, t * 0.44)
	canvas.draw_rect(box, Color(0, 0, 0, 0.6 if not locked else 0.35))
	canvas.draw_rect(box, Color(tint, 0.9 if not locked else 0.35), false, 2.5)
	var initial: String = item_label(String(g.get("item_key", "?"))).left(1).to_upper()
	canvas.draw_string(font, Vector2(cx, base.y + t * 0.62 + bob), initial, HORIZONTAL_ALIGNMENT_CENTER, -1.0, int(t * 0.34), Color(1, 1, 1, 1.0 if not locked else 0.45))
	if int(g.get("qty", 1)) > 1:
		canvas.draw_string(font, Vector2(base.x + t * 0.78, base.y + t * 0.78 + bob), str(int(g.get("qty", 0))), HORIZONTAL_ALIGNMENT_CENTER, -1.0, int(t * 0.2), Color(0.99, 0.88, 0.28))
	if locked:
		var left: int = maxi(0, int(g.get("protected_until", 0)) - now)
		var pct: float = clampf(float(left) / float(maxi(1, int(GameBalance.COMBAT.get("LOOT_PROTECT_MS", 60000)))), 0.0, 1.0)
		canvas.draw_arc(Vector2(cx, base.y + t * 0.48 + bob), t * 0.33, -PI / 2.0, -PI / 2.0 + TAU * pct, 20, Color(0.97, 0.44, 0.44), 3.0)
		canvas.draw_rect(Rect2(cx - 5, base.y + t * 0.08 + bob, 10, 8), Color(0.97, 0.44, 0.44))

static func projectiles(canvas: CanvasItem, sim, t: float, now: int) -> void:
	var pz: int = int(sim.player.grid.z)
	for pr in (sim.get("projectiles") as Array):
		if int(pr.get("z", 0)) != pz:
			continue
		var pp: float = clampf(float(now - int(pr["born"])) / float(maxi(1, int(pr["duration"]))), 0.0, 1.0)
		var pos: Vector2 = (Vector2(float(pr["fx"]), float(pr["fy"])).lerp(Vector2(float(pr["tx"]), float(pr["ty"])), pp)) * t + Vector2(t, t) / 2.0
		canvas.draw_circle(pos, t * 0.16, pr["color"])

static func reticle(canvas: CanvasItem, sim, t: float, now: int) -> void:
	var tgt = sim.target()
	if tgt == null:
		return
	var c: Vector2 = Vector2(tgt.grid.x, tgt.grid.y) * t + Vector2(t, t) / 2.0
	var r := t * 0.5
	for i in range(12):
		var a0: float = TAU * float(i) / 12.0 + float(now) / 900.0
		canvas.draw_arc(c, r, a0, a0 + TAU / 24.0, 6, Color(1.0, 0.82, 0.4), 3.0)
	var pct: float = sim.auto_tick_pct()
	canvas.draw_arc(c, r * 0.78, -PI / 2.0, -PI / 2.0 + TAU * pct, 24, Color.WHITE if pct >= 1.0 else Color(1.0, 0.54, 0.24), 4.0)

static func push_preview(canvas: CanvasItem, sim, t: float) -> void:
	var preview: Dictionary = sim.get("push_preview")
	if preview.is_empty():
		return
	var f: Vector3i = preview["from"]
	var to: Vector3i = preview["to"]
	var col := Color(0.3, 0.79, 0.94) if bool(preview["valid"]) else Color(0.94, 0.27, 0.27)
	canvas.draw_rect(Rect2(Vector2(to.x, to.y) * t + Vector2(2, 2), Vector2(t - 4, t - 6)), Color(col, 0.3))
	var fc: Vector2 = Vector2(f.x, f.y) * t + Vector2(t, t) / 2.0
	var tc: Vector2 = Vector2(to.x, to.y) * t + Vector2(t, t) / 2.0
	canvas.draw_line(fc, tc, col, 5.0)
	var ang: float = (tc - fc).angle()
	canvas.draw_colored_polygon(PackedVector2Array([tc, tc - Vector2(cos(ang - 0.5), sin(ang - 0.5)) * t * 0.28, tc - Vector2(cos(ang + 0.5), sin(ang + 0.5)) * t * 0.28]), col)

static func floats(canvas: CanvasItem, sim, t: float, font: Font, now: int) -> void:
	for fl in (sim.get("floats") as Array):
		var ttl: float = maxf(1.0, float(int(fl.get("ttl", 1100))))
		var age: float = float(now - int(fl["born"])) / ttl
		var fp: Vector2 = (fl["pos"] as Vector2) * t + Vector2(t / 2.0, t * 0.4 - age * t * 0.9)
		var size: int = int(t * (0.4 if bool(fl["crit"]) else 0.3))
		canvas.draw_string_outline(font, fp, String(fl["text"]), HORIZONTAL_ALIGNMENT_CENTER, -1.0, size, 4, Color(0, 0, 0, maxf(0.0, 1.0 - age * age)))
		canvas.draw_string(font, fp, String(fl["text"]), HORIZONTAL_ALIGNMENT_CENTER, -1.0, size, Color(fl["color"], maxf(0.0, 1.0 - age * age)))
