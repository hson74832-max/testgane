# BlackTek demo client entry point: boots the game server (MockDB session),
# the world renderer and the HUD, and owns player input (movement, hotkeys,
# mouse push/click-walk) plus persisted graphics options.
# Rendering lives in world_view.gd, the HUD in hud.gd (+ ui/ modules), the
# mock server in game/server.gd (+ game/world.gd, game/database.gd,
# game/action_scripts.gd, game/loaders/*).
extends Node2D

const STEP_COOLDOWN := 0.15
const DIAG_STEP_COOLDOWN := 0.21 # diagonal sidesteps cover sqrt(2)x distance
const LOCAL_PLAYER_ID := 1
const CFG_PATH := "user://blacktek_demo.cfg"
const PIXEL_STEPS := [1, 2, 4]

var server: BlackTekGameServer
var hud: BlackTekHud
var view: BlackTekWorldView
var _cam: Camera2D
var _cooldown := 0.0
var _cfg := {retro = false, pixels = 1}

func _ready() -> void:
	randomize()
	server = BlackTekGameServer.new()
	server.load_real_data("res://assets/assets.dat", "res://assets/forgotten.otbm")
	print("BlackTekDemo: %s" % server.stats_text)
	# World renderer on the default canvas; HUD on its own CanvasLayer so world
	# camera zoom never scales the UI.
	view = BlackTekWorldView.new()
	view.server = server
	add_child(view)
	var ui_layer := CanvasLayer.new()
	add_child(ui_layer)
	hud = BlackTekHud.new()
	hud.game = server
	ui_layer.add_child(hud)
	hud.connect_game()
	hud.hotbar_command.connect(_on_hotbar_command)
	hud.chat_submitted.connect(func(text: String): server.request_say(LOCAL_PLAYER_ID, text))
	hud._opt_retro.toggled.connect(func(_o: bool): _set_gfx())
	hud._opt_pixels.pressed.connect(_on_pixels_pressed)
	hud.apply_hotbar_layout(cfg_hotbar_load())
	view.hud = hud # enables click-path dots + push feedback in the world view
	hud.game_view = view # enables floor drops (bag drags ending over the world)
	# Boot log.
	if server.use_real_sprites:
		hud.chat_line("System", "Real Tibia.spr rendering. Log in (demo/demo) and enter the world.")
	else:
		hud.chat_line("System", "Placeholder graphics (no Tibia.spr). Walkability from assets.dat blockSolid.")
	server.world_entered.connect(_on_world_entered)
	server.damage_float.connect(func(pos, z, amount, from_player): view.on_damage_float(pos, z, amount, from_player))
	# Keep the rendered position glued to the server: click-to-walk path steps,
	# teleports, stairs and respawns all emit this (manual steps set it directly
	# too — same value, harmless). Without it the player dot freezes during
	# click-walks and jumps ("teleports") on the next key step.
	server.player_moved.connect(_on_player_moved)
	_load_gfx()
	_cam = Camera2D.new()
	_cam.enabled = true
	add_child(_cam)
	_center_camera()
	_apply_gfx()
	# Headless smoke test: Godot ... -- --autotest logs in and opens panels.
	if OS.get_cmdline_user_args().has("--autotest"):
		_autotest_enter.call_deferred()
	# Screenshot mode (windowed): Godot ... -- --shot saves user://shot.png.
	if OS.get_cmdline_user_args().has("--shot"):
		_shot_sequence.call_deferred()
	if OS.get_cmdline_user_args().has("--shot-login"):
		_shot_login.call_deferred()

func _autotest_enter() -> void:
	server.login_account("demo", "demo")
	var chars: Array = server.character_list()
	if not chars.is_empty():
		server.enter_world(chars[0])
		hud.toggle_gear()
		hud.toggle_stats()
		print("BlackTekDemo: autotest entered world as %s" % String(chars[0].name))
		_autotest_click() # synthetic press+release through the push/walk path

# Input smoke test: a staged left-click exercises try_begin_push/finish_push
# and click-to-walk end to end (a stale view property name crashed here once).
func _autotest_click() -> void:
	var at: Vector2 = get_viewport().get_visible_rect().size * 0.5
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = at
	Input.parse_input_event(press)
	var rel := InputEventMouseButton.new()
	rel.button_index = MOUSE_BUTTON_LEFT
	rel.pressed = false
	rel.position = at
	Input.parse_input_event(rel)
	print("BlackTekDemo: autotest click done (push=%s)" % str(view.push.is_empty()))

func _shot_login() -> void:
	await get_tree().create_timer(0.8).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_user_data_dir() + "/shot_login.png")
	print("BlackTekDemo: login shot saved to %s/shot_login.png" % OS.get_user_data_dir())
	get_tree().quit()

func _shot_sequence() -> void:
	await get_tree().create_timer(0.5).timeout
	server.login_account("demo", "demo")
	var chars: Array = server.character_list()
	if chars.is_empty():
		get_tree().quit()
		return
	server.enter_world(chars[0])
	hud.toggle_gear()
	hud.toggle_stats()
	hud.toggle_minimap()
	# Trigger combat UI: a rat adjacent + one hit (damage floater + target ring).
	for m in server.monsters.values():
		m.tile = server.players[LOCAL_PLAYER_ID].tile + Vector2i(1, 0)
		server.monsters[m.id].hp = maxi(1, int(m.hpmax) - 12)
		server.set_target(LOCAL_PLAYER_ID, m)
		server.attack_current_target(LOCAL_PLAYER_ID)
		break
	server.request_say(LOCAL_PLAYER_ID, "hi")
	server.request_say(LOCAL_PLAYER_ID, "trade")
	await get_tree().create_timer(1.0).timeout
	server.day_ambient = 1.0 # day reference frame (no light pass)
	await get_tree().create_timer(0.12).timeout
	var img_day := get_viewport().get_texture().get_image()
	img_day.save_png(OS.get_user_data_dir() + "/shot_day.png")
	print("BlackTekDemo: day shot saved to %s/shot_day.png" % OS.get_user_data_dir())
	server.day_ambient = 0.3 # night for the light-pool demo
	# Pose next to a torch so the night frame shows a real fire pool.
	var pz: int = server.demo_z
	var pp: Vector2i = server.players[LOCAL_PLAYER_ID].tile
	var posed := false
	for r in range(1, 30):
		if posed:
			break
		for yy in range(-r, r + 1):
			for xx in range(-r, r + 1):
				if maxi(absi(xx), absi(yy)) != r:
					continue
				var wt := pp + Vector2i(xx, yy)
				if server.tile_light_radius(wt, pz) > 0.0:
					for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						if server.is_walkable(wt + off, pz) and server.monster_at(wt + off, pz).is_empty():
							server.players[LOCAL_PLAYER_ID].tile = wt + off
							view.player_tile = wt + off
							posed = true
							break
				if posed:
					break
	print("BlackTekDemo: torch pose: %s" % str(posed))
	await get_tree().create_timer(0.6).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_user_data_dir() + "/shot.png")
	print("BlackTekDemo: shot saved to %s/shot.png" % OS.get_user_data_dir())
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if server != null:
			server.save_all()
			_save_gfx() # also persists hotbar bindings
			print("BlackTekDemo: MockDB saved on exit.")

# ---- session ------------------------------------------------------------------

func _center_camera() -> void:
	if view != null and server != null and server.use_real_map:
		# 15x11 viewport draws at 0..VIEW*TILE: keep it centered on screen.
		_cam.position = Vector2(BlackTekWorldView.VIEW_W * BlackTekWorldView.TILE, BlackTekWorldView.VIEW_H * BlackTekWorldView.TILE) * 0.5
	else:
		_cam.position = Vector2(480, 320)

func _on_player_moved(pid: int, new_tile: Vector2i) -> void:
	if pid != LOCAL_PLAYER_ID or view == null:
		return
	view.player_tile = new_tile

func _on_world_entered(pid: int) -> void:
	view.player_tile = server.players[pid].tile
	view.player_px = view.tile_to_px(view.player_tile)
	_center_camera()
	if server.use_real_sprites:
		server.prewarm_sprites(view.player_tile, 8)
	hud.update_status()
	hud.refresh_inventory()
	hud.game_message("Map: %s" % server.stats_text)
	hud.game_message("Space = target next creature (auto-attacks adjacent targets). Right-click = target. Hold left click on an adjacent creature + drag to push it (or drag from yourself to quick-step). F1-F5 potions/spells, F6 attack.")

# ---- input ---------------------------------------------------------------------

func _process(delta: float) -> void:
	_cooldown -= delta
	server.tick(delta)
	var dir := Vector2i.ZERO
	if hud.in_game and not hud.chat_open():
		var left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_KP_4) or Input.is_key_pressed(KEY_KP_7) or Input.is_key_pressed(KEY_KP_1)
		var right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_C) or Input.is_key_pressed(KEY_KP_6) or Input.is_key_pressed(KEY_KP_9) or Input.is_key_pressed(KEY_KP_3)
		var up := Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_KP_8) or Input.is_key_pressed(KEY_KP_7) or Input.is_key_pressed(KEY_KP_9)
		var down := Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_C) or Input.is_key_pressed(KEY_KP_2) or Input.is_key_pressed(KEY_KP_1) or Input.is_key_pressed(KEY_KP_3)
		dir = Vector2i(int(right) - int(left), int(down) - int(up))
	if dir != Vector2i.ZERO:
		server.cancel_path(LOCAL_PLAYER_ID)
	if dir != Vector2i.ZERO and _cooldown <= 0.0:
		_cooldown = DIAG_STEP_COOLDOWN if (dir.x != 0 and dir.y != 0) else STEP_COOLDOWN
		# Snapshot BEFORE the move: request_move emits player_moved, which
		# already syncs view.player_tile via signal, so comparing against it
		# afterwards would always look like "no movement" and skip stairs.
		var before: Vector2i = view.player_tile
		var stepped: Vector2i = server.request_move(LOCAL_PLAYER_ID, dir)
		if stepped != before:
			var nz := server.try_stair_teleport(LOCAL_PLAYER_ID)
			if nz >= 0:
				if server.use_real_sprites:
					server.prewarm_sprites(view.player_tile, 8)
				hud.fade()
				hud.game_message("Took stairs (z=%d)." % nz)
	view.player_px = view.player_px.lerp(view.tile_to_px(view.player_tile), minf(1.0, delta * 14.0))
	if _cam != null:
		if not server.use_real_map:
			_cam.position = view.player_px # fallback map draws in absolute coords
		else:
			_center_camera() # 15x11 viewport is fixed in canvas space

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		if event is InputEventMouseButton and event.pressed and hud.in_game and not hud.chat_open():
			if event.button_index == MOUSE_BUTTON_RIGHT:
				view.right_click_target()
				return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and hud.in_game and not hud.chat_open():
			if event.pressed:
				view.try_begin_push()
			else:
				var was_push: bool = not view.push.is_empty()
				var pressed_pushable: bool = view.press_on_pushable
				view.finish_push()
				if not was_push and not pressed_pushable and hud.in_game and not hud.chat_open():
					var dest := view.mouse_tile()
					if server.use_real_map and not view._is_in_view(dest):
						return # clicks outside the 15x11 viewport do nothing
					if not server.door_at(dest, server.demo_z).is_empty():
						# Door tile clicked: swing it when standing next to it.
						# Further away the click falls through to normal
						# click-to-walk (open leaves are walkable; closed
						# ones refuse the path, so nothing happens).
						var pt: Vector2i = view.player_tile
						if maxi(absi(dest.x - pt.x), absi(dest.y - pt.y)) <= 1:
							server.use_door(dest, server.demo_z, LOCAL_PLAYER_ID)
							return
					server.request_path(LOCAL_PLAYER_ID, dest) # click-to-walk
		return
	var k: InputEventKey = event
	if hud.chat_open():
		if k.keycode == KEY_ESCAPE:
			hud.close_chat(false)
		return # LineEdit handles text/enter via text_submitted
	if not hud.in_game:
		return
	match k.keycode:
		KEY_T:
			hud.open_chat()
		KEY_SPACE:
			server.target_next(LOCAL_PLAYER_ID) # Space targets, never hits
		KEY_G:
			hud.toggle_gear()
		KEY_K:
			hud.toggle_stats()
		KEY_R:
			server.teleport_town(LOCAL_PLAYER_ID)
		KEY_M:
			hud.toggle_minimap()
		KEY_O:
			hud.toggle_settings()
		KEY_F1:
			hud.activate_slot(0, 0)
		KEY_F2:
			hud.activate_slot(0, 1)
		KEY_F3:
			hud.activate_slot(0, 2)
		KEY_F4:
			hud.activate_slot(1, 0)
		KEY_F5:
			hud.activate_slot(1, 1)
		KEY_F6:
			hud.activate_slot(1, 2) # attack slot
		KEY_PAGEUP:
			_change_floor(-1)
		KEY_PAGEDOWN:
			_change_floor(1)

func _change_floor(dz: int) -> void:
	if server.request_floor(LOCAL_PLAYER_ID, dz):
		view.player_tile = server.players[LOCAL_PLAYER_ID].tile
		hud.fade()
		if server.use_real_sprites:
			server.prewarm_sprites(view.player_tile, 8)
		hud.game_message("Went %s (z=%d)." % ["upstairs" if dz < 0 else "downstairs", server.demo_z])
	else:
		hud.game_message("No floor that way (z=%d)." % server.demo_z)

# ---- hotbar ----------------------------------------------------------------------

func _on_hotbar_command(cmd: Dictionary) -> void:
	if not hud.in_game:
		return
	match String(cmd.get("kind", "")):
		"item":
			var it: Dictionary = _find_in_bag(int(cmd.itemtype))
			if it.is_empty():
				server.message_local(LOCAL_PLAYER_ID, "You have no %s." % server.item_label(int(cmd.itemtype)))
			else:
				server.scripts.use_item(server, LOCAL_PLAYER_ID, it)
		"spell":
			server.scripts.cast_spell(server, LOCAL_PLAYER_ID, String(cmd.spell))
		"attack":
			server.attack_current_target(LOCAL_PLAYER_ID)

func _find_in_bag(itemtype: int) -> Dictionary:
	var bag: Dictionary = server.players[LOCAL_PLAYER_ID].bag
	for i in range(20):
		var it: Dictionary = bag.get(i) if bag.get(i) != null else {}
		if not it.is_empty() and int(it.itemtype) == itemtype:
			return it
	return {}

# ---- graphics options (persisted; UI lives in the HUD right rail) ------------------

func _load_gfx() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK:
		_cfg.retro = bool(cfg.get_value("graphics", "retro", false))
		_cfg.pixels = int(cfg.get_value("graphics", "pixels", 1))
		if not PIXEL_STEPS.has(_cfg.pixels):
			_cfg.pixels = 1
	_apply_gfx()

func _set_gfx() -> void:
	_cfg.retro = hud._opt_retro.button_pressed
	_apply_gfx()
	_save_gfx()

func _on_pixels_pressed() -> void:
	_cfg.pixels = PIXEL_STEPS[(PIXEL_STEPS.find(_cfg.pixels) + 1) % PIXEL_STEPS.size()]
	_apply_gfx()
	_save_gfx()
	hud.game_message("Sprites upscaled to %dpx per tile (%dx). Toggle Retro for crisp vs. smooth scaling." % [32 * _cfg.pixels, _cfg.pixels])

func _apply_gfx() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if _cfg.retro else CanvasItem.TEXTURE_FILTER_LINEAR
	if _cam != null:
		_cam.zoom = Vector2(float(_cfg.pixels), float(_cfg.pixels))
	if hud != null:
		hud._opt_retro.set_pressed_no_signal(_cfg.retro)
		hud._opt_pixels.text = "Sprites: %dpx" % (32 * _cfg.pixels)

func _save_gfx() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("graphics", "retro", _cfg.retro)
	cfg.set_value("graphics", "pixels", _cfg.pixels)
	cfg.set_value("hotbar", "slots", hud.hotbar_layout())
	cfg.save(CFG_PATH)

func cfg_hotbar_load() -> Array:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK:
		var v: Variant = cfg.get_value("hotbar", "slots", [])
		return v if v is Array else []
	return []
