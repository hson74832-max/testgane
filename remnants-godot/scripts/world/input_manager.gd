extends Node
## InputManager — normalizes every input source into one GameAction stream.
## Extracted from WorldView. Sources wired here:
##   keys     Space/1 Strike · 2 Cleave · 3 Bolt · 4 Ward · G loot ·
##            Tab/T cycle mark · F3 debug · Enter chat
##   mouse    press/drag/release on the board = shove gesture, or a tap
##   touch    left 45% of the screen = invisible stick (web parity),
##            right half = shove gesture / tap
##   gamepad  A/X/Y/B = Strike/Cleave/Bolt/loot · LB cycle mark ·
##            Start chat · Back debug · left stick + d-pad = movement
## Discrete actions and the continuous movement vector all flow through the
## single `game_action` signal; WorldView owns the game reactions (and the
## HUD action pads join the same stream by calling the same handlers).
## Movement (stick + d-pad) bypasses the chat keyboard lock on purpose —
## like the thumb stick, it never types.

signal game_action(action: String, data: Dictionary)

const ACTION_STRIKE := "strike"
const ACTION_CLEAVE := "cleave"
const ACTION_BOLT := "bolt"
const ACTION_WARD := "ward"
const ACTION_LOOT := "loot"
const ACTION_CYCLE_MARK := "cycle_mark"
const ACTION_TOGGLE_DEBUG := "toggle_debug"
const ACTION_TOGGLE_CHAT := "toggle_chat"
const ACTION_STICK := "stick"
const ACTION_SHOVE_PREVIEW := "shove_preview"
const ACTION_SHOVE := "shove"
const ACTION_SHOVE_SELF := "shove_self"
const ACTION_TAP := "tap"

var world  # WorldView — wired at setup (untyped: no preload cycle)
var player: Node2D
var sim: Node2D

# touch joystick state (left-half drag, invisible parity region)
var _touch_origin: Vector2 = Vector2.ZERO
var _touch_active: bool = false
var _touch_id: int = -1
# shove gesture (mouse + right-half touch share this shape)
var _press_tile: Vector2i = Vector2i(-999, -999)
var _press_monster: int = -1  # mid or -1
var _press_self := false  # drag started on the player's own tile: self-shove
var _dragging_shove: bool = false
var _touch_shove_id: int = -1
# gamepad left stick + d-pad (combined into one movement vector)
var _pad_stick := Vector2.ZERO
var _dpad := Vector2i.ZERO

func setup(p_world, p_player: Node2D, p_sim: Node2D) -> void:
	world = p_world
	player = p_player
	sim = p_sim

## Funnel for stick-style movement (the HUD's virtual joystick joins here).
func set_stick(v: Vector2) -> void:
	game_action.emit(ACTION_STICK, {"vec": v})

# ---- keys -------------------------------------------------------------------
func _unhandled_key_input(event: InputEvent) -> void:
	var k: InputEventKey = event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	world.mark_input()
	match k.physical_keycode:
		KEY_SPACE, KEY_1:
			game_action.emit(ACTION_STRIKE, {})
		KEY_2:
			game_action.emit(ACTION_CLEAVE, {})
		KEY_3:
			game_action.emit(ACTION_BOLT, {})
		KEY_4:
			game_action.emit(ACTION_WARD, {})
		KEY_G:
			game_action.emit(ACTION_LOOT, {})
		KEY_TAB, KEY_T:
			game_action.emit(ACTION_CYCLE_MARK, {})
		KEY_F3:
			game_action.emit(ACTION_TOGGLE_DEBUG, {})
		KEY_ENTER, KEY_KP_ENTER:
			game_action.emit(ACTION_TOGGLE_CHAT, {})

# ---- mouse / touch / gamepad -------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		return  # handled in _unhandled_key_input
	world.mark_input()
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event
		var vp: Vector2 = world.get_viewport_rect().size
		if t.pressed and t.position.x < vp.x * 0.45 and not _touch_active and _touch_shove_id < 0:
			_touch_active = true
			_touch_id = t.index
			_touch_origin = t.position
		elif t.pressed and t.position.x >= vp.x * 0.45:
			var tile := _tile_from_screen(t.position)
			var pg := player.get("grid") as Vector3i
			_press_tile = tile
			_press_monster = _monster_id_at(tile)
			_press_self = tile.x == pg.x and tile.y == pg.y
			_touch_shove_id = t.index
			_dragging_shove = false
		elif not t.pressed and t.index == _touch_id:
			_touch_active = false
			game_action.emit(ACTION_STICK, {"vec": Vector2.ZERO})
		elif not t.pressed and t.index == _touch_shove_id:
			_touch_shove_id = -1
			_finish_shove_gesture(_tile_from_screen(t.position))
	elif event is InputEventScreenDrag:
		var d: InputEventScreenDrag = event
		if _touch_active and d.index == _touch_id:
			game_action.emit(ACTION_STICK, {"vec": (d.position - _touch_origin) / 52.0})
		elif d.index == _touch_shove_id and _press_monster >= 0:
			var tile2 := _tile_from_screen(d.position)
			if tile2 != _press_tile:
				_dragging_shove = true
				game_action.emit(ACTION_SHOVE_PREVIEW, {"mid": _press_monster, "to": tile2})
		elif d.index == _touch_shove_id and _press_self:
			var tile2s := _tile_from_screen(d.position)
			if tile2s != _press_tile:
				_dragging_shove = true
				game_action.emit(ACTION_SHOVE_PREVIEW, {"mid": -1, "to": tile2s})
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb: InputEventMouseButton = event
		if mb.pressed:
			var tile3 := _tile_from_screen(mb.position)
			var pgm := player.get("grid") as Vector3i
			_press_tile = tile3
			_press_monster = _monster_id_at(tile3)
			_press_self = tile3.x == pgm.x and tile3.y == pgm.y
			_dragging_shove = false
		else:
			_finish_shove_gesture(_tile_from_screen(mb.position))
	elif event is InputEventMouseMotion and _press_monster >= 0:
		var mm: InputEventMouseMotion = event
		if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			var tile4 := _tile_from_screen(mm.position)
			if tile4 != _press_tile:
				_dragging_shove = true
				game_action.emit(ACTION_SHOVE_PREVIEW, {"mid": _press_monster, "to": tile4})
	elif event is InputEventMouseMotion and _press_self:
		var ms: InputEventMouseMotion = event
		if (ms.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			var tile5 := _tile_from_screen(ms.position)
			if tile5 != _press_tile:
				_dragging_shove = true
				game_action.emit(ACTION_SHOVE_PREVIEW, {"mid": -1, "to": tile5})
	elif event is InputEventJoypadButton:
		var jb: InputEventJoypadButton = event
		if not jb.pressed:
			return
		match jb.button_index:
			JOY_BUTTON_A:
				game_action.emit(ACTION_STRIKE, {})
			JOY_BUTTON_X:
				game_action.emit(ACTION_CLEAVE, {})
			JOY_BUTTON_Y:
				game_action.emit(ACTION_BOLT, {})
			JOY_BUTTON_B:
				game_action.emit(ACTION_LOOT, {})
			JOY_BUTTON_LEFT_SHOULDER:
				game_action.emit(ACTION_CYCLE_MARK, {})
			JOY_BUTTON_START:
				game_action.emit(ACTION_TOGGLE_CHAT, {})
			JOY_BUTTON_BACK:
				game_action.emit(ACTION_TOGGLE_DEBUG, {})
			JOY_BUTTON_DPAD_LEFT:
				_dpad.x = -1
				_emit_pad_move()
			JOY_BUTTON_DPAD_RIGHT:
				_dpad.x = 1
				_emit_pad_move()
			JOY_BUTTON_DPAD_UP:
				_dpad.y = -1
				_emit_pad_move()
			JOY_BUTTON_DPAD_DOWN:
				_dpad.y = 1
				_emit_pad_move()
	elif event is InputEventJoypadMotion:
		var jm: InputEventJoypadMotion = event
		if jm.axis == JOY_AXIS_LEFT_X:
			_pad_stick.x = jm.axis_value
		elif jm.axis == JOY_AXIS_LEFT_Y:
			_pad_stick.y = jm.axis_value
		else:
			return
		_emit_pad_move()

## Gamepad movement: left stick wins over d-pad; both quantize to 8-way in
## PlayerGrid.set_joystick like every other stick source.
func _emit_pad_move() -> void:
	var vec := _pad_stick
	if vec.length() < 0.25:
		vec = Vector2(_dpad)
	game_action.emit(ACTION_STICK, {"vec": vec})

## Screen point -> board tile (world canvas space).
func _tile_from_screen(screen_pos: Vector2) -> Vector2i:
	var world_pos: Vector2 = world.get_canvas_transform().affine_inverse() * screen_pos
	var t := float(WorldGen.TILE_PX)
	return Vector2i(int(floor(world_pos.x / t)), int(floor(world_pos.y / t)))

func _monster_id_at(tile: Vector2i) -> int:
	var m = sim.monster_at(tile.x, tile.y)
	return int(m.get("mid")) if m != null else -1

## Press/release lifecycle of the shove gesture: drag = push, plain tap =
## NPC talk / mark / loot. WorldView reacts to the emitted actions.
func _finish_shove_gesture(release: Vector2i) -> void:
	if _press_monster >= 0 and _dragging_shove and release != _press_tile:
		game_action.emit(ACTION_SHOVE, {"mid": _press_monster, "to": release})
	elif _press_self and _dragging_shove and release != _press_tile:
		# drag from your own tile: shove yourself one tile (never across NPCs)
		game_action.emit(ACTION_SHOVE_SELF, {"to": release})
	else:
		# NPCs first (their tile may hold loot underneath), then mark/loot.
		game_action.emit(ACTION_TAP, {"tile": _press_tile})
	_press_tile = Vector2i(-999, -999)
	_press_monster = -1
	_press_self = false
	_dragging_shove = false
