extends Control
## 104px realm board. Web parity with renderMinimap: terrain + Sanctuary gold,
## monsters (red = aggro), loot (yellow = takable, red = locked), cyan player.

var tiles: Array = []
var player: PlayerGrid = null
var sim: CombatSim = null
var _acc := 0.0

const KIND_COLORS: Dictionary = {
	"grass": Color(0.25, 0.49, 0.31),
	"brush": Color(0.21, 0.42, 0.27),
	"path": Color(0.63, 0.54, 0.39),
	"ash": Color(0.36, 0.33, 0.38),
	"stone": Color(0.44, 0.45, 0.50),
	"water": Color(0.18, 0.50, 0.71),
	"wall": Color(0.10, 0.11, 0.14),
	"temple": Color(0.79, 0.70, 0.48),
}

func setup(t: Array, p, s) -> void:
	tiles = t
	player = p
	sim = s
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_acc += delta
	if _acc > 0.25:
		_acc = 0.0
		queue_redraw()

func _draw() -> void:
	if tiles.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.05, 0.07, 0.85))
	var w: int = (tiles[0] as Array).size()
	var h: int = tiles.size()
	var cell: Vector2 = size / Vector2(w, h)
	for y in range(h):
		for x in range(w):
			var kind: String = (tiles[y] as Array)[x]
			var col: Color = KIND_COLORS.get(kind, Color.MAGENTA)
			if kind == "gate":
				col = Color(0.6, 0.4, 0.85)
			draw_rect(Rect2(Vector2(x, y) * cell, cell + Vector2(1, 1)), col)
	if int(player.get("grid").z) == 0:
		var tcell: Vector2i = WorldGen.TEMPLE
		draw_rect(Rect2(Vector2(tcell - Vector2i(1, 1)) * cell, cell * 3.0), Color(1.0, 0.82, 0.4))
	for g in (sim.get("ground") as Array):
		if not sim.is_visible_loot(g):
			continue
		var gc: Vector3i = g["grid"]
		if gc.z != int(player.get("grid").z):
			continue
		draw_rect(Rect2(Vector2(gc.x, gc.y) * cell, cell + Vector2(1, 1)), Color(0.99, 0.88, 0.28) if sim.can_loot(g) else Color(0.97, 0.44, 0.44))
	for m in (sim.get("monsters") as Array):
		if int(m.get("dying_at")) != 0:
			continue
		var mc: Vector3i = m.get("grid")
		if mc.z != int(player.get("grid").z):
			continue
		draw_rect(Rect2(Vector2(mc.x, mc.y) * cell, cell + Vector2(1, 1)), Color(1.0, 0.35, 0.43) if bool(m.get("aggro")) else Color(1, 1, 1, 0.35))
	var pg: Vector3i = player.get("grid")
	draw_rect(Rect2(Vector2(pg.x, pg.y) * cell - cell * 0.5, cell * 2.0), Color(0.3, 0.79, 0.94))
