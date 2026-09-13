class_name PlayerGrid
extends Node2D
## Grid-locked player BODY: movement, render lerp, drawing. ALL serializable
## data lives in the PlayerState Resource this node holds; property access is
## forwarded via _get/_set, so the whole game keeps calling
## player.get(...)/player.set(...) while observers bind to this node's relay
## signals. Movement slice: step cadence = step_ms_for(heavy), diagonal costs
## 1.4x, slow x1.6. Render pos lerps toward grid pos; camera follows render.

signal stepped(grid: Vector3i, region_name: String)
# --- vitals observers (relayed from PlayerState's signals) ---
signal player_hp_changed(hp: int, max_hp: int)
signal player_mana_changed(mana: int, max_mana: int)
signal player_xp_changed(xp: int, level: int)
signal player_gold_changed(gold: int)
signal player_gear_changed(armor: int, heavy: int, weapon_damage: int)

const StateScript := preload("res://scripts/player/player_state.gd")
const Constants := preload("res://scripts/core/constants.gd")

## The one source of truth for serializable player data.
var state: StateScript

# --- view / behavior (not serializable) ---
var render: Vector2 = Vector2(20, 35)
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

func _init() -> void:
	state = StateScript.new()
	state.player_hp_changed.connect(func(hp: int, max_hp: int) -> void: player_hp_changed.emit(hp, max_hp))
	state.player_mana_changed.connect(func(mana: int, max_mana: int) -> void: player_mana_changed.emit(mana, max_mana))
	state.player_xp_changed.connect(func(xp: int, level: int) -> void: player_xp_changed.emit(xp, level))
	state.player_gold_changed.connect(func(gold: int) -> void: player_gold_changed.emit(gold))
	state.player_gear_changed.connect(func(armor: int, heavy: int, weapon_damage: int) -> void: player_gear_changed.emit(armor, heavy, weapon_damage))

## Serializable state forwarding — data lives in PlayerState; reads and
## writes through this node stay exactly where they always were.
func _get(property: StringName) -> Variant:
	match String(property):
		"vocation": return state.vocation
		"level": return state.level
		"xp": return state.xp
		"gold": return state.gold
		"kills": return state.kills
		"deaths": return state.deaths
		"skill_points": return state.skill_points
		"skills": return state.skills
		"swift": return state.swift
		"hp": return state.hp
		"max_hp": return state.max_hp
		"mana": return state.mana
		"max_mana": return state.max_mana
		"ward_hp": return state.ward_hp
		"statuses": return state.statuses
		"armor": return state.armor
		"weapon_damage": return state.weapon_damage
		"heavy": return state.heavy
		"dead": return state.dead
		"dead_until": return state.dead_until
		"push_ready_at": return state.push_ready_at
		"cast_until": return state.cast_until
		"hit_flash_until": return state.hit_flash_until
		"slowed": return state.slowed
		"cooldowns": return state.cooldowns
		"grid": return state.grid
		"facing": return state.facing
	return null

func _set(property: StringName, value: Variant) -> bool:
	match String(property):
		"vocation": state.vocation = value
		"level": state.level = value
		"xp": state.xp = value
		"gold": state.gold = value
		"kills": state.kills = value
		"deaths": state.deaths = value
		"skill_points": state.skill_points = value
		"skills": state.skills = value
		"swift": state.swift = value
		"hp": state.hp = value
		"max_hp": state.max_hp = value
		"mana": state.mana = value
		"max_mana": state.max_mana = value
		"ward_hp": state.ward_hp = value
		"statuses": state.statuses = value
		"armor": state.armor = value
		"weapon_damage": state.weapon_damage = value
		"heavy": state.heavy = value
		"dead": state.dead = value
		"dead_until": state.dead_until = value
		"push_ready_at": state.push_ready_at = value
		"cast_until": state.cast_until = value
		"hit_flash_until": state.hit_flash_until = value
		"slowed": state.slowed = value
		"cooldowns": state.cooldowns = value
		"grid": state.grid = value
		"facing": state.facing = value
		_:
			return false
	return true

func setup(tiles: Array, start: Vector3i) -> void:
	_tiles = tiles
	state.grid = start
	render = Vector2(start.x, start.y)
	position = render * float(WorldGen.TILE_PX)

func set_held(d: Vector2i) -> void:
	_held = d

func set_joystick(v: Vector2) -> void:
	# Quantise analogue stick to 8-way grid dirs (same as web Joystick.tsx).
	_joy = v
	if v.length() < Constants.STICK_DEADZONE:
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
	if not state.dead and now >= state.cast_until:
		var key_dir: Vector2i = _held_from_keys()
		# Tibia-style turn: Ctrl + arrows rotates facing without stepping.
		if _turn_held() and key_dir != Vector2i.ZERO:
			state.facing = key_dir
			queue_redraw()
		else:
			var dir: Vector2i = key_dir if key_dir != Vector2i.ZERO else _held
			if dir != Vector2i.ZERO and now >= _next_step_at:
				_try_step(dir, now)
	# lerp render -> grid (matches web k = dt/90ms)
	var k: float = minf(1.0, delta / Constants.RENDER_LERP_PLAYER_S)
	render = render.lerp(Vector2(state.grid.x, state.grid.y), k)
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
	for k: String in state.skills.keys():
		reduce += int(GameBalance.skill_def(String(k)).get("effect", {}).get("stepMs", 0)) * int(state.skills[k])
	return maxi(int(GameBalance.COMBAT.get("STEP_MIN_MS", 120)), GameBalance.step_ms_for(state.heavy) - reduce)

func _try_step(dir: Vector2i, now: int) -> void:
	state.facing = dir
	var nx: int = state.grid.x + dir.x
	var ny: int = state.grid.y + dir.y
	if not WorldGen.is_walkable(_tiles, nx, ny):
		_next_step_at = now + Constants.STEP_RETRY_MS
		return
	if tile_blocker.is_valid() and tile_blocker.call(nx, ny):
		_next_step_at = now + Constants.STEP_RETRY_MS
		return
	state.grid = Vector3i(nx, ny, state.grid.z)
	var cost: float = float(step_ms())
	if dir.x != 0 and dir.y != 0:
		cost *= 1.4
	if state.slowed:
		cost *= 1.6
	_next_step_at = now + int(cost)
	stepped.emit(state.grid, String(WorldGen.region_at(nx, ny).get("name", "")))

func _draw() -> void:
	var t := float(WorldGen.TILE_PX)
	var now: int = Time.get_ticks_msec()
	var bw: float = t * 0.66
	var bh: float = t * 0.70
	var bx: float = (t - bw) / 2.0
	var by: float = t * 0.10
	if state.ward_hp > 0:
		draw_arc(Vector2(t / 2.0, t * 0.45), t * 0.52, 0.0, TAU, 32, Color(0.02, 0.84, 0.63, 0.75), 3.0)
	# shadow
	_shadow_ellipse(Vector2(t / 2.0, t * 0.80), t * 0.32, t * 0.14, Color(0, 0, 0, 0.4))
	# body + cloak + visor (same readability as web renderer.ts)
	_block(Rect2(bx - 3.5, by - 3.5, bw + 7, bh + 7), Color(0, 0, 0, 0.85))
	var flash: bool = now < state.hit_flash_until
	_block(Rect2(bx, by, bw, bh), Color.WHITE if flash else (Color(0.36, 0.38, 0.44) if state.dead else Color(0.91, 0.92, 0.94)))
	_block(Rect2(bx, by + bh * 0.45, bw, bh * 0.55), Color(0.75, 0.22, 0.17))
	_block(Rect2(bx + bw * 0.18, by + bh * 0.2, bw * 0.64, bh * 0.16), Color(0.1, 0.11, 0.15))
	# facing pip
	var pip := Vector2(t / 2.0, t * 0.45) + Vector2(state.facing) * t * 0.30
	draw_circle(pip, t * 0.07, Color(1.0, 0.82, 0.4))

func _shadow_ellipse(center: Vector2, rx: float, ry: float, color: Color, points: int = 24) -> void:
	var pts := PackedVector2Array()
	for i in range(points):
		var a: float = TAU * float(i) / float(points)
		pts.append(center + Vector2(cos(a), sin(a)) * Vector2(rx, ry))
	draw_colored_polygon(pts, color)

func _block(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
