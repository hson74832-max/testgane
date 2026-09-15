# BlackTek click-pathfinding: Dijkstra over walkable tiles (orthogonal cost
# 1.0, diagonal sqrt(2)), plus the per-tick walker.
# NOTE: mirrors the real server (Game::internalMoveCreature -> Tile::canEnter
# + Map::getPathMatching): only the destination tile must be walkable.
# Diagonal steps never check orthogonal neighbours, so corner-cutting past
# blocking tiles is allowed — same as key walking / self-push.
# The walker reroutes around creatures that step in mid-route (up to
# MAX_REPLANS silent replans) and only reports "blocked" when truly stuck.
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

# How often the walker may silently replan around a blocked step before it
# gives up with "You are blocked." (bounds oscillation against wandering rats).
const MAX_REPLANS := 4

static func request_path(game, pid: int, target: Vector2i, avoid := []) -> int:
	if not game.players.has(pid):
		return -1
	var p: Dictionary = game.players[pid]
	var start: Vector2i = p.tile
	var z: int = int(p.z)
	if target == start:
		clear_path(game, pid)
		return 0
	if not game.is_walkable(target, z) or not BlackTekMonsters.monster_at(game, target, z).is_empty() or not BlackTekNpc.npc_at(game, target, z).is_empty():
		return -1
	var path := find_path(game, start, target, z, avoid)
	if path.is_empty():
		return -1
	p.path = path
	p.path_dest = target
	p.path_replans = 0
	return path.size()

static func find_path(game, start: Vector2i, target: Vector2i, z: int, avoid: Array) -> Array:
	var came_from: Dictionary = {start: start}
	var dist: Dictionary = {start: 0.0}
	var closed := {}
	var heap := BlackTekHeap.new()
	heap.push(0.0, start)
	var found := false
	var guard := 0
	while not heap.empty() and guard < 12000:
		guard += 1
		var cur: Vector2i = heap.pop()
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
			if next != target and avoid.has(next):
				continue
			var nd: float = float(dist[cur]) + (1.4142 if (dir.x != 0 and dir.y != 0) else 1.0)
			if nd < float(dist.get(next, 1e30)):
				dist[next] = nd
				came_from[next] = cur
				heap.push(nd, next)
	if not found:
		return []
	# Reconstruct start-exclusive path.
	var path: Array = []
	var cur2: Vector2i = target
	while cur2 != start:
		path.push_front(cur2)
		cur2 = came_from[cur2]
	return path

static func cancel_path(game, pid: int) -> void:
	clear_path(game, pid)

# Drop the queued route and its reroute state (manual steps, teleports,
# stair/floor changes and death all cancel click-walking through here).
static func clear_path(game, pid: int) -> void:
	if not game.players.has(pid):
		return
	game.players[pid].path = []
	game.players[pid].erase("path_dest")
	game.players[pid].path_replans = 0

static func fetch_path(game, pid: int) -> Array:
	if not game.players.has(pid):
		return []
	return game.players[pid].get("path", [])

# Walks one step along the queued path (called from tick).
static func path_step(game, pid: int, delta: float) -> void:
	if not game.players.has(pid):
		return
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
		if try_replan(game, pid):
			return # silent reroute; the walker continues next tick
		clear_path(game, pid)
		game.message_local(pid, "You are blocked.")
		return
	p.tile = next
	p.z = z
	path.pop_front()
	game.player_moved.emit(pid, next)

# A step failed mid-route (usually a creature wandered onto it): plan a fresh
# route from here to the remembered destination, treating current creature
# tiles as obstacles. Silent on success; false when there is nothing to
# replan (no destination, budget spent, or still unreachable).
static func try_replan(game, pid: int) -> bool:
	if not game.players.has(pid):
		return false
	var p: Dictionary = game.players[pid]
	if not p.has("path_dest"):
		return false
	if int(p.get("path_replans", 0)) >= MAX_REPLANS:
		return false
	var dest: Vector2i = p.path_dest
	var z: int = int(p.z)
	# Destination itself taken or unwalkable: no route can succeed.
	if not game.is_walkable(dest, z) or not BlackTekMonsters.monster_at(game, dest, z).is_empty() or not BlackTekNpc.npc_at(game, dest, z).is_empty():
		return false
	var avoid: Array = []
	for m in game.monsters.values():
		if int(m.z) == z and m.tile != dest and not avoid.has(m.tile):
			avoid.append(m.tile)
	for n in game.npcs.values():
		if int(n.z) == z and n.tile != dest and not avoid.has(n.tile):
			avoid.append(n.tile)
	var fresh := find_path(game, p.tile, dest, z, avoid)
	if fresh.is_empty():
		return false
	p.path = fresh
	p.path_replans = int(p.get("path_replans", 0)) + 1
	return true
