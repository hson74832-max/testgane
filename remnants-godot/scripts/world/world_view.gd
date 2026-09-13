extends Node2D
## WorldView — Phase 2 + mobile HUD. Owns map + PlayerGrid + CombatSim + Hud.
## Input parity with web GamePlay.tsx: WASD move, click/tap mark,
## hold-drag from monster = shove preview + release to push,
## Space/1/Strike-pad = Strike, Tab/T/Mark-pad = cycle mark.
## Left-half touch = same stick (invisible region kept for parity), plus the
## visible VirtualJoystick which feeds the same PlayerGrid input.

const PlayerGridScript := preload("res://scripts/player/player_grid.gd")
const CombatSimScript := preload("res://scripts/combat/combat_sim.gd")
const HudScript := preload("res://scripts/ui/hud.gd")
const DebugOverlayScript := preload("res://scripts/ui/debug_overlay.gd")
const WebSyncScript := preload("res://scripts/net/web_sync.gd")
const NpcsScript := preload("res://scripts/world/npcs.gd")

var tiles: Array = []
var floor_maps: Dictionary = {}
var player: Node2D
var sim: Node2D
var npcs: Node2D
var hud: CanvasLayer
var debug_overlay: CanvasLayer
var camera: Camera2D
var seed_value: int = 1337
var last_input_msec: int = 0
# --- WebSync live push (dev only, env-gated: REMNANTS_SYNC=1, REMNANTS_WEB=url) ---
var websync = null
var _loot_queue: Array = []
var _event_queue: Array = []
var _pending_death := {}
var _greeted := {}

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

func _ready() -> void:
	last_input_msec = Time.get_ticks_msec()
	floor_maps = {0: WorldGen.generate_map(seed_value), 1: WorldGen.generate_crypt(seed_value)}
	tiles = floor_maps[0]
	player = PlayerGridScript.new()
	# starter kit parity: bone knife (+3) + leather vest (3 armor, 2 heavy)
	player.setup(tiles, Vector3i(WorldGen.TEMPLE.x, WorldGen.TEMPLE.y, WorldGen.TEMPLE_Z))
	player.set("armor", 3)
	player.set("weapon_damage", 3)
	player.set("heavy", 2)
	var s: Dictionary = GameBalance.stats_for_level(1)
	player.set("max_hp", int(s["maxHp"]))
	player.set("max_mana", int(s["maxMana"]))
	player.set("hp", int(s["maxHp"]))
	player.set("mana", int(s["maxMana"]))
	player.z_index = 5
	add_child(player)

	sim = CombatSimScript.new()
	add_child(sim)
	sim.setup(floor_maps, player, "Wanderer")

	npcs = NpcsScript.new()
	add_child(npcs)
	npcs.setup(player, sim)

	player.set("tile_blocker", _is_blocked)
	sim.set("tile_blocker", _is_blocked)
	sim.leveled_up.connect(_on_leveled)
	sim.player_died.connect(_on_died)
	sim.toast.connect(_on_toast)
	sim.looted.connect(_on_loot_chat)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()
	camera.position = player.position

	hud = HudScript.new()
	add_child(hud)
	hud.setup(self, player, sim)
	hud.show_toast("Tap a creature to MARK · 1-4 abilities · G loot")
	debug_overlay = DebugOverlayScript.new()
	add_child(debug_overlay)
	debug_overlay.setup(self)
	if OS.get_environment("REMNANTS_SYNC") == "1":
		websync = WebSyncScript.new()
		websync.base_url = OS.get_environment("REMNANTS_WEB") if OS.get_environment("REMNANTS_WEB") != "" else "http://localhost:3000"
		websync.character_name = "Wanderer"
		add_child(websync)
		sim.looted.connect(_on_looted)
		sim.mob_killed.connect(func(monster_name: String) -> void: _event_queue.append({"event": "kill", "payload": {"monster": monster_name}}))
		sim.leveled_up.connect(func(level: int) -> void: _event_queue.append({"event": "levelup", "payload": {"level": level}}))
		websync.load_character("Wanderer")
		var timer := Timer.new()
		timer.wait_time = 5.0
		timer.autostart = true
		add_child(timer)
		timer.timeout.connect(_push_sync)
	queue_redraw()
	if OS.get_environment("REMNANTS_SMOKE") == "1":
		add_child(load("res://tests/smoke_runner.gd").new())

func _process(_delta: float) -> void:
	if is_instance_valid(camera) and is_instance_valid(player):
		# rifts, ferries and respawns jump floors: snap instead of gliding.
		if camera.position.distance_to(player.position) > 8.0 * float(WorldGen.TILE_PX):
			camera.position = player.position
			camera.reset_smoothing()
		else:
			camera.position = player.position
	if is_instance_valid(sim) and is_instance_valid(player):
		# follow the player across floors (rift gates, ferry, respawn)
		tiles = sim.current_tiles()
		player.set("_tiles", tiles)
		# chat owns the keyboard while open (GUI consumption misses polling)
		player.set("input_blocked", hud.chat_open())
		# marks die off-screen (2-tile hysteresis against edge flicker)
		sim.clip_target_to_view(_visible_tiles().grow(2))
	# Floor is drawn windowed around the camera: it must redraw every frame
	# or the camera slides onto never-drawn canvas (black tiles). Regression
	# from the Phase 2 rewrite, which dropped the stepped->redraw wiring.
	queue_redraw()

## Combined occupancy: live monsters (sim) + NPC fixtures, current floor.
func _is_blocked(x: int, y: int) -> bool:
	var fz: int = int(player.grid.z)
	if sim.is_occupied(x, y, fz):
		return true
	return fz == 0 and npcs.is_occupied(x, y)

func interact_npc(npc: Dictionary) -> void:
	mark_input()
	if not npcs.can_talk(npc):
		sim.add_float("come closer", Vector2((npc["pos"] as Vector3i).x, (npc["pos"] as Vector3i).y), Color(0.58, 0.64, 0.72), false)
		return
	buzz(10)
	var nid: String = String(npc.get("id", "?"))
	if not _greeted.has(nid):
		_greeted[nid] = true
		notify("%s: %s" % [String(npc.get("name", "?")), String(npc.get("blurb", ""))])
	hud.open_npc_sheet(npc)

func mark_input() -> void:
	last_input_msec = Time.get_ticks_msec()

func buzz(ms: int) -> void:
	Input.vibrate_handheld(ms)

## Basic chat: local log + say floats. No server yet — lines stay in-session.
func say(text: String) -> void:
	mark_input()
	var clean: String = text.strip_edges().left(60)
	if clean == "":
		return
	hud.chat_add("You: " + clean)
	# speech floats linger ~6s so people can actually read a sentence
	sim.add_float(clean, Vector2(player.grid.x, player.grid.y - 0.7), Color.WHITE, false, 6000)
	buzz(8)

func notify(text: String) -> void:
	hud.chat_add(text)

func _on_loot_chat(item_key: String, qty: int) -> void:
	var rarity: String = String(GameBalance.item_def(item_key).get("rarity", "common"))
	if rarity == "rare" or rarity == "epic":
		notify("Looted %s%s." % [String(GameBalance.item_def(item_key).get("name", item_key)), (" x%d" % qty) if qty > 1 else ""])

# ---- pads / keys -----------------------------------------------------------
func on_strike_pad() -> void:
	mark_input()
	sim.ability_strike()
	buzz(15)

func on_cleave_pad() -> void:
	mark_input()
	sim.ability_cleave()
	buzz(16)

func on_bolt_pad() -> void:
	mark_input()
	sim.ability_bolt()
	buzz(16)

func on_ward_pad() -> void:
	mark_input()
	sim.ability_ward()
	buzz(20)

func on_loot_pad() -> void:
	mark_input()
	sim.loot_all_nearby()
	buzz(12)

func _on_looted(item_key: String, qty: int) -> void:
	_loot_queue.append({"itemKey": item_key, "qty": qty})
	if _loot_queue.size() > 50:
		_loot_queue.pop_front()

func _player_state() -> Dictionary:
	return {
		"level": int(player.get("level")), "xp": int(player.get("xp")),
		"hp": maxi(1, int(player.get("hp"))), "maxHp": int(player.get("max_hp")),
		"mana": int(player.get("mana")), "maxMana": int(player.get("max_mana")),
		"gold": int(player.get("gold")),
		"tileX": (player.get("grid") as Vector3i).x, "tileY": (player.get("grid") as Vector3i).y,
		"region": String(WorldGen.region_at((player.get("grid") as Vector3i).x, (player.get("grid") as Vector3i).y).get("name", "")),
		"kills": int(player.get("kills")), "deaths": int(player.get("deaths")),
	}

func _push_sync() -> void:
	if websync == null:
		return
	var loot: Array = _loot_queue.duplicate()
	_loot_queue.clear()
	var events: Array = _event_queue.duplicate()
	_event_queue.clear()
	var death := {}
	if not _pending_death.is_empty():
		death = _pending_death
		_pending_death = {}
	websync.push_state(_player_state(), loot, death, events.slice(0, 20))

func on_mark_pad() -> void:
	mark_input()
	sim.cycle_target()
	buzz(10)

func _on_leveled(level: int) -> void:
	hud.show_toast("LEVEL %d" % level)
	notify("Level %d reached." % level)
	buzz(60)

func _on_died(killed_by: String, xp_lost: int, gold: int) -> void:
	hud.show_death(killed_by, xp_lost, gold)
	hud.show_toast("YOU DIED to %s" % killed_by)
	notify("Slain by %s (-%dxp -%dg)." % [killed_by, xp_lost, gold])
	_pending_death = {
		"killedBy": killed_by, "xpLost": xp_lost, "goldDropped": gold,
		"tileX": (player.get("grid") as Vector3i).x, "tileY": (player.get("grid") as Vector3i).y,
		"region": String(WorldGen.region_at((player.get("grid") as Vector3i).x, (player.get("grid") as Vector3i).y).get("name", "")),
		"level": int(player.get("level")),
	}
	buzz(150)

func _on_toast(text: String, _kind: String) -> void:
	hud.show_toast(text)

# ---- input -----------------------------------------------------------------
func _unhandled_key_input(event: InputEvent) -> void:
	var k: InputEventKey = event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	mark_input()
	match k.physical_keycode:
		KEY_SPACE, KEY_1:
			sim.ability_strike()
			buzz(15)
		KEY_2:
			sim.ability_cleave()
			buzz(16)
		KEY_3:
			sim.ability_bolt()
			buzz(16)
		KEY_4:
			sim.ability_ward()
			buzz(20)
		KEY_G:
			sim.loot_all_nearby()
			buzz(12)
		KEY_TAB, KEY_T:
			sim.cycle_target()
			buzz(10)
		KEY_F3:
			debug_overlay.toggle()
		KEY_ENTER, KEY_KP_ENTER:
			hud.toggle_chat_input()

func _tile_from_screen(screen_pos: Vector2) -> Vector2i:
	var world: Vector2 = get_canvas_transform().affine_inverse() * screen_pos
	var t := float(WorldGen.TILE_PX)
	return Vector2i(int(floor(world.x / t)), int(floor(world.y / t)))

func _monster_id_at(tile: Vector2i) -> int:
	var m = sim.monster_at(tile.x, tile.y)
	return int(m.get("mid")) if m != null else -1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		return  # handled in _unhandled_key_input
	mark_input()
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event
		var vp: Vector2 = get_viewport_rect().size
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
			player.set_joystick(Vector2.ZERO)
		elif not t.pressed and t.index == _touch_shove_id:
			_touch_shove_id = -1
			_finish_shove_gesture(_tile_from_screen(t.position))
	elif event is InputEventScreenDrag:
		var d: InputEventScreenDrag = event
		if _touch_active and d.index == _touch_id:
			player.set_joystick((d.position - _touch_origin) / 52.0)
		elif d.index == _touch_shove_id and _press_monster >= 0:
			var tile2 := _tile_from_screen(d.position)
			if tile2 != _press_tile:
				_dragging_shove = true
				sim.preview_push(_monster_by_id(_press_monster), tile2.x, tile2.y)
		elif d.index == _touch_shove_id and _press_self:
			var tile2s := _tile_from_screen(d.position)
			if tile2s != _press_tile:
				_dragging_shove = true
				sim.preview_push_self(tile2s.x, tile2s.y)
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
				sim.preview_push(_monster_by_id(_press_monster), tile4.x, tile4.y)
	elif event is InputEventMouseMotion and _press_self:
		var ms: InputEventMouseMotion = event
		if (ms.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			var tile5 := _tile_from_screen(ms.position)
			if tile5 != _press_tile:
				_dragging_shove = true
				sim.preview_push_self(tile5.x, tile5.y)

func _monster_by_id(mid: int):
	for m in (sim.get("monsters") as Array):
		if int(m.get("mid")) == mid and int(m.get("dying_at")) == 0:
			return m
	return null

func _finish_shove_gesture(release: Vector2i) -> void:
	var m = _monster_by_id(_press_monster) if _press_monster >= 0 else null
	sim.clear_push_preview()
	if m != null and _dragging_shove and release != _press_tile:
		var r: Dictionary = sim.push(m, release.x, release.y)
		if bool(r.get("ok", false)):
			buzz(25)
	elif _press_self and _dragging_shove and release != _press_tile:
		# drag from your own tile: shove yourself one tile (never across NPCs)
		var rs: Dictionary = sim.push_self(release.x, release.y)
		if bool(rs.get("ok", false)):
			buzz(25)
	else:
		# NPCs first (their tile may hold loot underneath), then mark/loot.
		var npc = npcs.npc_at(_press_tile.x, _press_tile.y, int(player.grid.z))
		if npc != null:
			interact_npc(npc)
		else:
			sim.tap_tile(_press_tile.x, _press_tile.y)
			buzz(8)
	_press_tile = Vector2i(-999, -999)
	_press_monster = -1
	_press_self = false
	_dragging_shove = false

# ---- floor -----------------------------------------------------------------
## Visible tile bounds (INCLUSIVE end), shared by culling and mark clipping.
func _visible_tiles() -> Rect2i:
	var t := float(WorldGen.TILE_PX)
	var w: int = int((tiles[0] as Array).size()) if not tiles.is_empty() else 0
	var h: int = tiles.size()
	if not is_instance_valid(camera) or w <= 0 or h <= 0:
		return Rect2i(0, 0, mini(24, w), mini(24, h))
	var view: Vector2 = get_viewport_rect().size / maxf(0.01, camera.zoom.x)
	var tl: Vector2 = camera.get_screen_center_position() / t - view / t / 2.0 - Vector2(1, 1)
	var br: Vector2 = tl + view / t + Vector2(2, 2)
	var x0: int = maxi(0, int(tl.x))
	var y0: int = maxi(0, int(tl.y))
	return Rect2i(x0, y0, maxi(0, mini(w - 1, int(br.x)) - x0), maxi(0, mini(h - 1, int(br.y)) - y0))

func _draw() -> void:
	if tiles.is_empty():
		return
	var t := float(WorldGen.TILE_PX)
	var vis := _visible_tiles()
	for y in range(vis.position.y, vis.position.y + vis.size.y + 1):
		for x in range(vis.position.x, vis.position.x + vis.size.x + 1):
			_draw_tile(x, y, t)
	if int(player.grid.z) == 0:
		var c := Vector2(WorldGen.TEMPLE) * t + Vector2(t, t) / 2.0
		var pts := PackedVector2Array()
		for i in range(48):
			var a0: float = TAU * float(i) / 48.0
			pts.append(c + Vector2(cos(a0), sin(a0)) * t * 3.5)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1.0, 0.88, 0.51, 0.6), 3.0)

func _draw_tile(x: int, y: int, t: float) -> void:
	var kind: String = tiles[y][x]
	if kind == "wall":
		draw_rect(Rect2(Vector2(x, y) * t, Vector2(t, t)), Color(0.35, 0.33, 0.30))
		draw_rect(Rect2(Vector2(x, y) * t + Vector2(2, -t * 0.2), Vector2(t - 4, t * 0.72)), Color(0.55, 0.52, 0.47))
		return
	var top := Color(0.25, 0.49, 0.31)
	match kind:
		"brush": top = Color(0.21, 0.42, 0.27)
		"path": top = Color(0.63, 0.54, 0.39)
		"ash": top = Color(0.36, 0.33, 0.38)
		"stone": top = Color(0.44, 0.45, 0.50)
		"water": top = Color(0.18, 0.50, 0.71)
		"temple": top = Color(0.79, 0.70, 0.48)
		"gate": top = Color(0.35, 0.2, 0.5)
	var pos := Vector2(x, y) * t
	draw_rect(Rect2(pos + Vector2(1, 3), Vector2(t - 2, t - 3)), top.darkened(0.35))
	draw_rect(Rect2(pos + Vector2(1, 1), Vector2(t - 2, t - 5)), top)
	if kind == "gate":
		var c := pos + Vector2(t, t) / 2.0
		var pulse: float = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 400.0)
		draw_arc(c, t * 0.3 * pulse, 0.0, TAU, 24, Color(0.85, 0.6, 1.0), 3.0)
		draw_circle(c, t * 0.08, Color(1, 1, 1, 0.9))
