class_name PlayerGrid
extends Node2D
## Grid-locked player. Port of engine.ts movement slice:
## step cadence = step_ms_for(heavy), diagonal costs 1.4x, slow x1.6.
## Render pos lerps toward grid pos; camera follows render pos.

signal stepped(grid: Vector3i, region_name: String)
# --- vitals observers (StatusBar + HUD listen; setters emit on every write,
# including the sim's dynamic player.set(...) calls) ---
signal player_hp_changed(hp: int, max_hp: int)
signal player_mana_changed(mana: int, max_mana: int)
signal player_xp_changed(xp: int, level: int)
signal player_gold_changed(gold: int)
signal player_gear_changed(armor: int, heavy: int, weapon_damage: int)

## Tibia-style position triple: x, y on the floor, z is the floor itself.
var grid: Vector3i = Vector3i(20, 35, 0)
var render: Vector2 = Vector2(20, 35)
var facing: Vector2i = Vector2i(0, 1)
var heavy: int = 2:
	set(v):
		heavy = v
		player_gear_changed.emit(armor, heavy, weapon_damage)
var slowed: bool = false
var hp: int = 120:
	set(v):
		hp = v
		player_hp_changed.emit(hp, max_hp)
var max_hp: int = 120:
	set(v):
		max_hp = v
		player_hp_changed.emit(hp, max_hp)
var mana: int = 60:
	set(v):
		mana = v
		player_mana_changed.emit(mana, max_mana)
var max_mana: int = 60:
	set(v):
		max_mana = v
		player_mana_changed.emit(mana, max_mana)
var level: int = 1:
	set(v):
		level = v
		player_xp_changed.emit(xp, level)
# --- Phase 2 combat state (mirrors engine.ts PlayerState, trimmed) ---
var xp: int = 0:
	set(v):
		xp = v
		player_xp_changed.emit(xp, level)
var gold: int = 50:
	set(v):
		gold = v
		player_gold_changed.emit(gold)
var kills: int = 0
var deaths: int = 0
var armor: int = 3:
	set(v):
		armor = v
		player_gear_changed.emit(armor, heavy, weapon_damage)
var weapon_damage: int = 3:
	set(v):
		weapon_damage = v
		player_gear_changed.emit(armor, heavy, weapon_damage)
var ward_hp: int = 0
var statuses: Array = []
var cooldowns: Dictionary = {}
var dead: bool = false
var dead_until: int = 0
var push_ready_at: int = 0
var hit_flash_until: int = 0
var cast_until: int = 0
# --- skill tree (1 point per level, spent in the SKILL sheet) ---
var skill_points: int = 0
var skills: Dictionary = {}
## Step quickness ranks (Swiftness): mirrors skills["swift"] for step_ms().
var swift: int = 0
## Set by WorldView: CombatSim.is_occupied — blocks stepping onto live mobs.
var tile_blocker: Callable = Callable()
## While the chat box (or any modal text field) owns the keyboard, key polling
## stops: GUI consumption doesn't cover Input.is_*_key_pressed polling.
## The thumb stick keeps working — it never types.
var input_blocked := false

var _tiles: Array = []
var _next_step_at: int = 0
var _held: Vector2i = Vector2i.ZERO
var _joy: Vector2 = Vector2.ZERO

func setup(tiles: Array, start: Vector3i) -> void:
	_tiles = tiles
	grid = start
	render = Vector2(start.x, start.y)
	position = Vector2(start.x, start.y) * float(WorldGen.TILE_PX)

func set_held(d: Vector2i) -> void:
	_held = d

func set_joystick(v: Vector2) -> void:
	# Quantise analogue stick to 8-way grid dirs (same as web Joystick.tsx).
	_joy = v
	if v.length() < 0.25:
		if _held_from_keys() == Vector2i.ZERO:
			_held = Vector2i.ZERO
		return
	var ang: float = atan2(v.y, v.x)
	var oct: int = int(round(ang / (PI / 4.0)))
	match oct:
		-4, 4: _held = Vector2i(-1, 0)
		-3: _held = Vector2i(-1, -1)
		-2: _held = Vector2i(0, -1)
		-1: _held = Vector2i(1, -1)
		0: _held = Vector2i(1, 0)
		1: _held = Vector2i(1, 1)
		2: _held = Vector2i(0, 1)
		3: _held = Vector2i(-1, 1)

func _physics_process(delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	# Casting roots you briefly (web parity: heldDir ignored until cast_until).
	if not dead and now >= cast_until:
		var key_dir: Vector2i = _held_from_keys()
		# Tibia-style turn: Ctrl + arrows rotates facing without stepping.
		if _turn_held() and key_dir != Vector2i.ZERO:
			facing = key_dir
			queue_redraw()
		else:
			var dir: Vector2i = key_dir if key_dir != Vector2i.ZERO else _held
			if dir != Vector2i.ZERO and now >= _next_step_at:
				_try_step(dir, now)
	# lerp render -> grid (matches web k = dt/90ms)
	var k: float = minf(1.0, delta / 0.09)
	render = render.lerp(Vector2(grid.x, grid.y), k)
	position = render * float(WorldGen.TILE_PX)
	queue_redraw()

func _held_from_keys() -> Vector2i:
	if input_blocked:
		return Vector2i.ZERO
	var x := 0
	var y := 0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		y += 1
	return Vector2i(x, y)

func _turn_held() -> bool:
	return Input.is_key_pressed(KEY_CTRL) or Input.is_physical_key_pressed(KEY_CTRL)

func step_ms() -> int:
	# Swiftness reduction is data (skills.*.effect.stepMs); floor from content.
	var reduce := 0
	for k in skills.keys():
		reduce += int(GameBalance.skill_def(String(k)).get("effect", {}).get("stepMs", 0)) * int(skills[k])
	return maxi(int(GameBalance.COMBAT.get("STEP_MIN_MS", 120)), GameBalance.step_ms_for(heavy) - reduce)

func _try_step(dir: Vector2i, now: int) -> void:
	facing = dir
	var nx: int = grid.x + dir.x
	var ny: int = grid.y + dir.y
	if not WorldGen.is_walkable(_tiles, nx, ny):
		_next_step_at = now + 120
		return
	if tile_blocker.is_valid() and tile_blocker.call(nx, ny):
		_next_step_at = now + 120
		return
	grid = Vector3i(nx, ny, grid.z)
	var cost: float = float(step_ms())
	if dir.x != 0 and dir.y != 0:
		cost *= 1.4
	if slowed:
		cost *= 1.6
	_next_step_at = now + int(cost)
	stepped.emit(grid, String(WorldGen.region_at(nx, ny).get("name", "")))

func _draw() -> void:
	var t := float(WorldGen.TILE_PX)
	var now: int = Time.get_ticks_msec()
	var bw: float = t * 0.66
	var bh: float = t * 0.70
	var bx: float = (t - bw) / 2.0
	var by: float = t * 0.10
	if ward_hp > 0:
		draw_arc(Vector2(t / 2.0, t * 0.45), t * 0.52, 0.0, TAU, 32, Color(0.02, 0.84, 0.63, 0.75), 3.0)
	# shadow
	_shadow_ellipse(Vector2(t / 2.0, t * 0.80), t * 0.32, t * 0.14, Color(0, 0, 0, 0.4))
	# body + cloak + visor (same readability as web renderer.ts)
	_block(Rect2(bx - 3.5, by - 3.5, bw + 7, bh + 7), Color(0, 0, 0, 0.85))
	var flash: bool = now < hit_flash_until
	_block(Rect2(bx, by, bw, bh), Color.WHITE if flash else (Color(0.36, 0.38, 0.44) if dead else Color(0.91, 0.92, 0.94)))
	_block(Rect2(bx, by + bh * 0.45, bw, bh * 0.55), Color(0.75, 0.22, 0.17))
	_block(Rect2(bx + bw * 0.18, by + bh * 0.2, bw * 0.64, bh * 0.16), Color(0.1, 0.11, 0.15))
	# facing pip
	var pip := Vector2(t / 2.0, t * 0.45) + Vector2(facing) * t * 0.30
	draw_circle(pip, t * 0.07, Color(1.0, 0.82, 0.4))

func _shadow_ellipse(center: Vector2, rx: float, ry: float, color: Color, points: int = 24) -> void:
	var pts := PackedVector2Array()
	for i in range(points):
		var a: float = TAU * float(i) / float(points)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)

func _block(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
