# BlackTek click-pathfinding: Dijkstra over walkable tiles (orthogonal cost
# 1.0, diagonal sqrt(2)), plus the per-tick walker.
# NOTE: mirrors the real server (Game::internalMoveCreature -> Tile::canEnter
# + Map::getPathMatching): only the destination tile must be walkable.
# Diagonal steps never check orthogonal neighbours, so corner-cutting past
# blocking tiles is allowed — same as key walking / self-push.
class_name BlackTekPath
extends RefCounted

# Step cadence in seconds (matches client key walking): diagonal sidesteps
# cover sqrt(2)x distance, so they pace slightly slower than cardinal steps.
# Tuned in data/gameplay.toml; consts are deprecated compat aliases.
const WALK_CD := 0.15
const DIAG_WALK_CD := 0.21

static func walk_cd(game) -> float:
	return game.config.tune("walk_cd") if game.get("config") != null else WALK_CD

static func diag_walk_cd(game) -> float:
	return game.config.tune("diag_walk_cd") if game.get("config") != null else DIAG_WALK_CD

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]

static func request_path(game, pid: int, target: Vector2i) -> int:
	var p: Dictionary = game.players[pid]
	var start: Vector2i = p.tile
	var z: int = int(p.z)
	if target == start:
		p.path = []
		return 0
	if not game.is_walkable(target, z) or not BlackTekMonsters.monster_at(game, target, z).is_empty() or not BlackTekNpc.npc_at(game, target, z).is_empty():
		return -1
	# Dijkstra (cf. Game::pathFind): plain BFS only minimizes the step COUNT,
	# which prefers diagonal zigzags and reads as "weird" routing. The sqrt(2)
	# diagonal cost yields the geometrically shortest walkable route (which
	# also matches the 0.15s / 0.21s walk pacing). Creatures are ignored while
	# routing (only an occupied TARGET refuses the path) — the walker stops
	# with "blocked" if one actually steps in the way, Tibia-style.
	var came_from: Dictionary = {start: start}
	var dist: Dictionary = {start: 0.0}
	var closed := {}
	var open: Array = [start]
	var found := false
	var guard := 0
	while not open.is_empty() and guard < 12000:
		guard += 1
		var bi := 0
		for i in range(1, open.size()):
			if float(dist[open[i]]) < float(dist[open[bi]]):
				bi = i
		var cur: Vector2i = open[bi]
		open.remove_at(bi)
		if closed.has(cur):
			continue
		closed[cur] = true
		if cur == target:
			found = true
			break
		for dir in BlackTekPath.DIRS:
			var next: Vector2i = cur + dir
			if closed.has(next):
				continue
			if not game.is_walkable(next, z):
				continue
			var nd: float = float(dist[cur]) + (1.4142 if (dir.x != 0 and dir.y != 0) else 1.0)
			if nd < float(dist.get(next, 1e30)):
				dist[next] = nd
				came_from[next] = cur
				open.append(next)
	if not found:
		return -1
	# Reconstruct start-exclusive path.
	var path: Array = []
	var cur2: Vector2i = target
	while cur2 != start:
		path.push_front(cur2)
		cur2 = came_from[cur2]
	p.path = path
	return path.size()

static func cancel_path(game, pid: int) -> void:
	game.players[pid].path = []

static func fetch_path(game, pid: int) -> Array:
	return game.players[pid].get("path", [])

# Walks one step along the queued path (called from tick).
static func path_step(game, pid: int, delta: float) -> void:
	var p: Dictionary = game.players[pid]
	var path: Array = p.get("path", [])
	if path.is_empty():
		return
	p._walk_cd = float(p.get("_walk_cd", 0.0)) - delta
	if float(p._walk_cd) > 0.0:
		return
	var next: Vector2i = path[0]
	var cur: Vector2i = p.tile
	var dir: Vector2i = next - cur
	# Diagonal sidesteps cover sqrt(2)x distance, so they pace slower — same
	# cadence as key walking (0.15 cardinal / 0.21 diagonal).
	p._walk_cd = diag_walk_cd(game) if (dir.x != 0 and dir.y != 0) else walk_cd(game)
	var z: int = int(p.z)
	var ok: bool = maxi(absi(dir.x), absi(dir.y)) == 1 and game.is_walkable(next, z) and BlackTekMonsters.monster_at(game, next, z).is_empty() and BlackTekNpc.npc_at(game, next, z).is_empty()
	if not ok:
		p.path = [] # blocked mid-route (creature moved in): stop
		game.message_local(pid, "You are blocked.")
		return
	p.tile = next
	p.z = z
	path.pop_front()
	game.player_moved.emit(pid, next)
