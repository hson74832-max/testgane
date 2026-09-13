extends Control
## Thumb stick. Mirrors web Joystick.tsx: analogue drag in, 8-way quantise
## happens in PlayerGrid. Left-half thumb zone, always visible like web.

signal moved(v: Vector2)

var value := Vector2.ZERO
var base_r := 88.0
var knob_r := 32.0
var dead_px := 18.0
var _knob := Vector2.ZERO
var _held := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			if get_global_rect().has_point(mb.position):
				_held = true
				_drag(mb.position)
		elif _held:
			_held = false
			_release()
	elif event is InputEventMouseMotion and _held:
		_drag((event as InputEventMouseMotion).position)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if get_global_rect().has_point(st.position):
				_held = true
				_drag(st.position)
		elif _held:
			_held = false
			_release()
	elif event is InputEventScreenDrag and _held:
		_drag((event as InputEventScreenDrag).position)

func _local_pos(screen_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen_pos

func _drag(screen_pos: Vector2) -> void:
	var d: Vector2 = _local_pos(screen_pos) - size / 2.0
	if d.length() < dead_px:
		value = Vector2.ZERO
		_knob = Vector2.ZERO
	else:
		var l: float = minf(d.length(), base_r)
		value = d.normalized() * (l / base_r)
		_knob = d.normalized() * l
	moved.emit(value)
	queue_redraw()

func _release() -> void:
	value = Vector2.ZERO
	_knob = Vector2.ZERO
	moved.emit(value)
	queue_redraw()

func _draw() -> void:
	var c: Vector2 = size / 2.0
	draw_circle(c, base_r, Color(0, 0, 0, 0.35))
	draw_arc(c, base_r, 0.0, TAU, 48, Color(1, 1, 1, 0.15), 2.0)
	draw_arc(c, base_r * 0.62, 0.0, TAU, 40, Color(1, 1, 1, 0.10), 1.5)
	draw_circle(c + _knob, knob_r, Color(0.85, 0.87, 0.9, 0.95))
	draw_arc(c + _knob, knob_r, 0.0, TAU, 32, Color(0, 0, 0, 0.5), 3.0)
