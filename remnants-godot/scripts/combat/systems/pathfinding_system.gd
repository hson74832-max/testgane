extends RefCounted
## PathfindingSystem — flow-field ownership, line of sight, chase stepping.
## Extracted from CombatSim; the distance field itself is FlowField
## (scripts/combat/flow_field.gd). Terrain-only field, bodies avoided at
## step time (separation) — see flow_field.gd's header for the corner-cut
## regression contract covered in tests/smoke_runner.gd.

const FlowField := preload("res://scripts/combat/flow_field.gd")

var sim  # CombatSim — wired by the sim at construction (untyped: no preload cycle)

## Shared chase field. CombatSim forwards it as `flow` for the debug overlay.
var flow := FlowField.new()

## `tiles` mirrors the player's floor; call after any z change.
func set_tiles(tiles: Array) -> void:
	flow.set_tiles(tiles)

## Rebuild the field when stale (player moved or floor changed).
func ensure_field(origin: Vector3i) -> void:
	if flow.field.is_empty() or flow.origin != origin:
		flow.refresh(origin)

func value(x: int, y: int) -> int:
	return flow.value(x, y)

## Line of sight for projectiles (archer tick, Ash Bolt). Endpoints excluded;
## walls block, water and gates do not. Different floors never see each other.
func has_sight(a: Vector3i, b: Vector3i) -> bool:
	if a.z != b.z:
		return false
	var dx: int = absi(b.x - a.x)
	var dy: int = absi(b.y - a.y)
	var steps: int = maxi(dx, dy)
	if steps <= 1:
		return true
	var tiles: Array = sim.tiles
	for i in range(1, steps):
		var t: float = float(i) / float(steps)
		var cx: int = int(round(lerpf(float(a.x), float(b.x), t)))
		var cy: int = int(round(lerpf(float(a.y), float(b.y), t)))
		if WorldGen.blocks_projectile(tiles, cx, cy):
			return false
	return true

## One chase step downhill on the field. False = boxed in (retry next cadence).
func chase_step(m) -> bool:
	if flow.field.is_empty():
		return false
	var player: Node2D = sim.player
	var best_d := 999999
	var cands: Array = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = m.grid.x + dx
			var ny: int = m.grid.y + dy
			if not flow.passable(nx, ny):
				continue
			if nx == player.grid.x and ny == player.grid.y:
				continue
			if sim.is_occupied(nx, ny):
				continue  # separation: never stack, take the next-best lane
			if sim._blocked(nx, ny):
				continue  # NPC fixtures (dynamic bodies steer around at step time)
			var fd: int = flow.value(nx, ny)
			if fd < 0:
				continue
			if fd < best_d:
				best_d = fd
				cands = [Vector3i(nx, ny, m.grid.z)]
			elif fd == best_d:
				cands.append(Vector3i(nx, ny, m.grid.z))
	if cands.is_empty():
		return false
	m.grid = cands[randi() % cands.size()]
	return true
