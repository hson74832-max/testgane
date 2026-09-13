extends RefCounted
## FlowField — one shared BFS distance field from a target tile.
## Owned by PathfindingSystem (scripts/combat/systems/pathfinding_system.gd):
## static terrain only (walkable + not-PZ).
## Bodies (monsters, NPCs) MUST stay enqueued: the deaggro rule reads
## own-cell values, and a body-blocked field deaggros the whole map.
## Separation happens at step time (PathfindingSystem checks occupancy there).
##
## The field deliberately allows diagonals past wall corners (no corner-cut
## rule): PlayerGrid._try_step and PathfindingSystem.chase_step both do, so a
## corner-cut field marks corner-squeeze regions -1 and the deaggro rule
## drops aggro the frame it fires — creatures stop closing to attack and
## wander sideways instead (regression covered in tests/smoke_runner.gd).

var field: Array = []
var origin := Vector3i(-999, -999, -999)
var w := 0
var h := 0
var _tiles: Array = []

func set_tiles(tiles: Array) -> void:
	_tiles = tiles
	origin = Vector3i(-999, -999, -999)
	field = []

func value(x: int, y: int) -> int:
	if field.is_empty() or y < 0 or y >= h or x < 0 or x >= w:
		return -1
	return int((field[y] as Array)[x])

func passable(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= w or y >= h:
		return false
	if not WorldGen.is_walkable(_tiles, x, y):
		return false
	if WorldGen.in_safe_zone(x, y):
		return false
	return true

func refresh(o: Vector3i) -> void:
	origin = o
	h = _tiles.size()
	w = (_tiles[0] as Array).size() if h > 0 else 0
	field = []
	for y in range(h):
		var row: Array = []
		row.resize(w)
		row.fill(-1)
		field.append(row)
	if w <= 0 or h <= 0:
		return
	var start := Vector2i(o.x, o.y)
	if start.x < 0 or start.y < 0 or start.x >= w or start.y >= h:
		return
	var frontier: Array = [start]
	field[start.y][start.x] = 0
	var head := 0
	while head < frontier.size():
		var cur: Vector2i = frontier[head]
		head += 1
		var d: int = int((field[cur.y] as Array)[cur.x])
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var nx: int = cur.x + dx
				var ny: int = cur.y + dy
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				if int((field[ny] as Array)[nx]) != -1:
					continue
				if not passable(nx, ny) and not (nx == start.x and ny == start.y):
					continue
				(field[ny] as Array)[nx] = d + 1
				frontier.append(Vector2i(nx, ny))
