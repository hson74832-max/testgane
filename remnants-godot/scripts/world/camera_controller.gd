extends RefCounted
## CameraController — camera creation, follow, and visible-bounds math.
## Extracted from WorldView. Smoothing is Godot's position_smoothing (speed
## 8); follow() snaps instead of gliding when the player jumped (rifts,
## ferries, respawns) so the camera never slides across the map.

var world  # WorldView — wired at setup (untyped: no preload cycle)
var camera: Camera2D

## Creates the camera under `parent` and aims it at `target` (the player).
func setup(parent: Node2D, target: Node2D) -> void:
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	parent.add_child(camera)
	camera.make_current()
	camera.position = target.position

## Per-frame follow. Rifts, ferries and respawns jump floors: snap instead
## of gliding.
func follow(target: Vector2) -> void:
	if not is_instance_valid(camera):
		return
	if camera.position.distance_to(target) > 8.0 * float(WorldGen.TILE_PX):
		camera.position = target
		camera.reset_smoothing()
	else:
		camera.position = target

## Visible tile bounds (INCLUSIVE end), shared by floor culling and mark
## clipping. Bounds come from the tiles array so surface and crypt share it.
func visible_tiles(tiles: Array) -> Rect2i:
	var t := float(WorldGen.TILE_PX)
	var w: int = int((tiles[0] as Array).size()) if not tiles.is_empty() else 0
	var h: int = tiles.size()
	if not is_instance_valid(camera) or w <= 0 or h <= 0:
		return Rect2i(0, 0, mini(24, w), mini(24, h))
	var view: Vector2 = world.get_viewport_rect().size / maxf(0.01, camera.zoom.x)
	var tl: Vector2 = camera.get_screen_center_position() / t - view / t / 2.0 - Vector2(1, 1)
	var br: Vector2 = tl + view / t + Vector2(2, 2)
	var x0: int = maxi(0, int(tl.x))
	var y0: int = maxi(0, int(tl.y))
	return Rect2i(x0, y0, maxi(0, mini(w - 1, int(br.x)) - x0), maxi(0, mini(h - 1, int(br.y)) - y0))
