extends RefCounted
## Renderer — every CanvasItem paint call for the world floor (WorldView
## delegates from _draw). Owns the windowed tile pass with per-row run
## batching: consecutive same-kind tiles emit all shade rects, then all top
## rects, so Godot's 2D renderer merges same-color draws into batched
## primitives — identical pixels, fewer draw calls. Wall caps reach 0.2 tiles
## up into the row above, so rows must keep painting top-to-bottom (they do).
## Entity visualization lives on the entities themselves (PlayerGrid,
## Monster._draw, NPC fixtures) plus SimDraw for sim state — this module is
## the floor and world fixtures (temple ring, gate pulses).

## Top color per walkable-ish tile kind; unknown kinds fall back to grass.
const TILE_COLORS: Dictionary = {
	"grass": Color(0.25, 0.49, 0.31),
	"brush": Color(0.21, 0.42, 0.27),
	"path": Color(0.63, 0.54, 0.39),
	"ash": Color(0.36, 0.33, 0.38),
	"stone": Color(0.44, 0.45, 0.50),
	"water": Color(0.18, 0.50, 0.71),
	"temple": Color(0.79, 0.70, 0.48),
	"gate": Color(0.35, 0.2, 0.5),
}

var world: WorldView  # wired at setup

func draw(canvas: CanvasItem) -> void:
	var tiles: Array = world.tiles
	if tiles.is_empty():
		return
	var t := float(WorldGen.TILE_PX)
	var vis: Rect2i = world._visible_tiles()
	for y in range(vis.position.y, vis.position.y + vis.size.y + 1):
		var row: Array = tiles[y]
		var x_end: int = vis.position.x + vis.size.x + 1
		var x: int = vis.position.x
		# run-length batch: consecutive same-kind tiles share two passes
		while x < x_end:
			var kind: String = String(row[x])
			var run_end: int = x + 1
			while run_end < x_end and String(row[run_end]) == kind:
				run_end += 1
			_draw_run(canvas, x, run_end, y, kind, t)
			x = run_end
	if int(world.player.grid.z) == 0:
		_draw_temple_ring(canvas, t)

## One horizontal run of identical tiles. Layers stay in the original
## per-tile order (shade under top, caps over the row above).
func _draw_run(canvas: CanvasItem, x0: int, x1: int, y: int, kind: String, t: float) -> void:
	if kind == "wall":
		for x in range(x0, x1):
			canvas.draw_rect(Rect2(Vector2(x, y) * t, Vector2(t, t)), Color(0.35, 0.33, 0.30))
		for x in range(x0, x1):
			canvas.draw_rect(Rect2(Vector2(x, y) * t + Vector2(2, -t * 0.2), Vector2(t - 4, t * 0.72)), Color(0.55, 0.52, 0.47))
		return
	var top: Color = TILE_COLORS.get(kind, Color(0.25, 0.49, 0.31))
	var shade: Color = top.darkened(0.35)
	for x in range(x0, x1):
		canvas.draw_rect(Rect2(Vector2(x, y) * t + Vector2(1, 3), Vector2(t - 2, t - 3)), shade)
	for x in range(x0, x1):
		var pos := Vector2(x, y) * t
		canvas.draw_rect(Rect2(pos + Vector2(1, 1), Vector2(t - 2, t - 5)), top)
		if kind == "gate":
			var c := pos + Vector2(t, t) / 2.0
			var pulse: float = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 400.0)
			canvas.draw_arc(c, t * 0.3 * pulse, 0.0, TAU, 24, Color(0.85, 0.6, 1.0), 3.0)
			canvas.draw_circle(c, t * 0.08, Color(1, 1, 1, 0.9))

## Sanctuary boundary ring around the Temple plaza (surface floor only).
func _draw_temple_ring(canvas: CanvasItem, t: float) -> void:
	var c := Vector2(WorldGen.TEMPLE) * t + Vector2(t, t) / 2.0
	var pts := PackedVector2Array()
	for i in range(48):
		var a0: float = TAU * float(i) / 48.0
		pts.append(c + Vector2(cos(a0), sin(a0)) * t * 3.5)
	canvas.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1.0, 0.88, 0.51, 0.6), 3.0)
