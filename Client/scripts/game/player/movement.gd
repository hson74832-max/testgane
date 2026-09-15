# BlackTek movement: step validation, key walking, stairs/floors, spawn/town.
# Stateless — live players and signals live on the game server.
# Mirrors the real server (Game::internalMoveCreature -> Tile::canEnter):
# only the DESTINATION tile matters; diagonals never check neighbours.
class_name BlackTekMovement
extends RefCounted

# Exact step validation, shared by request_move and the self-push preview so
# the preview can never promise a step the server then refuses.
static func can_step(game, pid: int, dir: Vector2i) -> bool:
	return step_blocker(game, pid, dir) == ""

# Why a step fails: "" when it would land, otherwise a short reason naming
# the blocker (solid item label) or the occupant.
static func step_blocker(game, pid: int, dir: Vector2i) -> String:
	if not game.players.has(pid):
		return "no session"
	var cur: Vector2i = game.players[pid]["tile"]
	var z: int = game.demo_z
	if dir == Vector2i.ZERO:
		return "no direction"
	var next: Vector2i = cur + dir
	if not game.is_walkable(next):
		return solid_label(game, next, z)
	if not BlackTekMonsters.monster_at(game, next, z).is_empty():
		return "creature in the way"
	if not BlackTekNpc.npc_at(game, next, z).is_empty():
		return "Norf is in the way"
	return ""

# Human label of the first solid item on a tile ("bush", "wall", ...).
static func solid_label(game, tile: Vector2i, z: int) -> String:
	for id in game.tile_info(tile, z).get("items", []):
		if game.dat != null and bool(game.dat.items.get(int(id), {}).get("block_solid", false)):
			var n: String = game.item_label(int(id))
			return n if n != "" else "wall"
	return "blocked tile"

static func request_move(game, player_id: int, dir: Vector2i) -> Vector2i:
	if not game.players.has(player_id):
		return Vector2i(-1, -1)
	game.players[player_id].path = [] # manual step cancels click-walking
	var cur: Vector2i = game.players[player_id]["tile"]
	if not can_step(game, player_id, dir):
		return cur
	var next: Vector2i = cur + dir
	game.players[player_id]["tile"] = next
	game.players[player_id]["z"] = game.demo_z
	game.player_moved.emit(player_id, next)
	return next

# Spawns the loaded player on a walkable tile (town or open spot).
static func spawn_tile(game) -> Vector2i:
	if game.use_real_map:
		return game.find_spawn()
	var c := Vector2i(15, 11)
	if game.walls.has(c):
		c = Vector2i(15, 12)
	return c

# /t talkaction + demo R key: back to town temple.
static func teleport_town(game, pid: int) -> bool:
	if not game.players.has(pid):
		return false
	game.players[pid].path = []
	if game.use_real_map:
		game.players[pid].tile = game.find_spawn()
	else:
		game.players[pid].tile = Vector2i(15, 11)
	game.players[pid].z = game.demo_z
	game.player_moved.emit(pid, game.players[pid].tile)
	game.message_local(pid, "Teleported to town temple.")
	return true

# Step-onto-stairs teleport (stand-in for stair/use logic): if the player's
# tile holds a stair-like item, head for a walkable landing on the floor
# above first (same tile, then rings to 4), else the floor below.
# Returns new z or -1. Clears any click-path (a new floor voids old routes).
static func try_stair_teleport(game, player_id: int) -> int:
	if not game.players.has(player_id) or game.dat == null:
		return -1
	var cur: Vector2i = game.players[player_id]["tile"]
	var has_stair := false
	for id in game.tile_info(cur).get("items", []):
		if bool(game.dat.items.get(int(id), {}).get("is_stair", false)):
			has_stair = true
			break
	if not has_stair:
		return -1
	game.players[player_id].path = []
	for dz in [-1, 1]:
		var nz: int = game.demo_z + dz
		if nz < 0 or nz > 15:
			continue
		for r in range(0, 5):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if maxi(abs(dx), abs(dy)) != r:
						continue
					var c := cur + Vector2i(dx, dy)
					if game.is_walkable(c, nz):
						game.demo_z = nz
						game.players[player_id]["tile"] = c
						game.players[player_id]["z"] = nz
						game.player_moved.emit(player_id, c)
						return nz
	return -1

# Manual upstairs/downstairs travel (PgUp/PgDn stand-in for stair tiles).
static func request_floor(game, player_id: int, dz: int) -> bool:
	if not game.players.has(player_id):
		return false
	game.players[player_id].path = []
	var nz: int = clampi(game.demo_z + dz, 0, 15)
	if nz == game.demo_z:
		return false
	var cur: Vector2i = game.players[player_id]["tile"]
	for r in range(0, 13):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(abs(dx), abs(dy)) != r:
					continue
				var c := cur + Vector2i(dx, dy)
				if game.is_walkable(c, nz):
					game.demo_z = nz
					game.players[player_id]["tile"] = c
					game.players[player_id]["z"] = nz
					game.player_moved.emit(player_id, c)
					return true
	return false
