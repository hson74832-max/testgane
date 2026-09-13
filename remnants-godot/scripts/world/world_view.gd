class_name WorldView
extends Node2D
## WorldView — Phase 2 + mobile HUD. Owns map + PlayerGrid + CombatSim + Hud,
## and delegates the three big concerns to extracted modules:
##   renderer      — all _draw() logic: windowed floor tiles (row-run batched),
##                   temple ring, gate pulses   (scripts/world/renderer.gd)
##   input_mgr     — normalizes keys/mouse/touch/gamepad into one GameAction
##                   stream this node reacts to (scripts/world/input_manager.gd)
##   camera_ctl    — camera smoothing, snap-after-jump, visible bounds
##                   (scripts/world/camera_controller.gd)
## Input parity with web GamePlay.tsx: WASD move, click/tap mark,
## hold-drag from monster = shove preview + release to push,
## Space/1/Strike-pad = Strike, Tab/T/Mark-pad = cycle mark.
## Left-half touch = same stick (invisible region kept for parity), plus the
## visible VirtualJoystick which feeds the same stick action.

const PlayerGridScript := preload("res://scripts/player/player_grid.gd")
const CombatSimScript := preload("res://scripts/combat/combat_sim.gd")
const HudScript := preload("res://scripts/ui/hud.gd")
const DebugOverlayScript := preload("res://scripts/ui/debug_overlay.gd")
const WebSyncScript := preload("res://scripts/net/web_sync.gd")
const Constants := preload("res://scripts/core/constants.gd")
const NpcsScript := preload("res://scripts/world/npcs.gd")
const RendererScript := preload("res://scripts/world/renderer.gd")
const InputManagerScript := preload("res://scripts/world/input_manager.gd")
const CameraControllerScript := preload("res://scripts/world/camera_controller.gd")

var tiles: Array = []
var floor_maps: Dictionary = {}
var player: PlayerGrid
var sim: CombatSim
var npcs: NpcsScript
var hud: CanvasLayer
var debug_overlay: CanvasLayer
var seed_value: int = 1337
var last_input_msec: int = 0

# --- extracted modules ---
var renderer: RendererScript
var input_mgr: InputManagerScript
var camera_ctl: CameraControllerScript

## Camera node lives in the controller; forwarded for HUD/tests that aim it.
var camera: Camera2D:
	get: return camera_ctl.camera

# --- WebSync live push (dev only, env-gated: REMNANTS_SYNC=1, REMNANTS_WEB=url) ---
var websync: WebSyncScript = null
var _loot_queue: Array = []
var _event_queue: Array = []
var _pending_death := {}
var _greeted := {}

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

	renderer = RendererScript.new()
	renderer.world = self
	camera_ctl = CameraControllerScript.new()
	camera_ctl.world = self
	camera_ctl.setup(self, player)
	input_mgr = InputManagerScript.new()
	add_child(input_mgr)
	input_mgr.setup(self, player, sim)
	input_mgr.game_action.connect(_on_game_action)

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
		timer.wait_time = Constants.SYNC_PERIOD_S
		timer.autostart = true
		add_child(timer)
		timer.timeout.connect(_push_sync)
	queue_redraw()
	if OS.get_environment("REMNANTS_SMOKE") == "1":
		add_child(load("res://tests/smoke_runner.gd").new())

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		camera_ctl.follow(player.position)
	if is_instance_valid(sim) and is_instance_valid(player):
		# follow the player across floors (rift gates, ferry, respawn)
		tiles = sim.current_tiles()
		player.set("_tiles", tiles)
		# chat owns the keyboard while open (GUI consumption misses polling)
		player.set("input_blocked", hud.chat_open())
		# marks die off-screen (2-tile hysteresis against edge flicker)
		sim.clip_target_to_view(_visible_tiles().grow(Constants.VIEW_HYSTERESIS_TILES))
	# Floor is drawn windowed around the camera: it must redraw every frame
	# or the camera slides onto never-drawn canvas (black tiles). Regression
	# from the Phase 2 rewrite, which dropped the stepped->redraw wiring.
	queue_redraw()

## Visible tile bounds (INCLUSIVE end), shared by culling and mark clipping.
func _visible_tiles() -> Rect2i:
	return camera_ctl.visible_tiles(tiles)

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

## ChatSystem network hook (dev WebSync only): player-sent lines join the
## event queue pushed every 5s; system lines stay local.
func on_chat_submitted(text: String) -> void:
	if websync == null:
		return
	_event_queue.append({"event": "chat", "payload": {"text": text}})

func _on_loot_chat(item_key: String, qty: int) -> void:
	var rarity: String = String(GameBalance.item_def(item_key).get("rarity", "common"))
	if rarity == "rare" or rarity == "epic":
		notify("Looted %s%s." % [String(GameBalance.item_def(item_key).get("name", item_key)), (" x%d" % qty) if qty > 1 else ""])

# ---- pads / keys (same handlers feed the HUD pads and the action stream) ---
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

func on_mark_pad() -> void:
	mark_input()
	sim.cycle_target()
	buzz(10)

# ---- GameAction stream -------------------------------------------------------
## One consumer for everything InputManager normalizes (keys, mouse, touch,
## gamepad, virtual stick). HUD pads call the same on_*_pad handlers.
func _on_game_action(action: String, data: Dictionary) -> void:
	match action:
		InputManagerScript.ACTION_STRIKE:
			on_strike_pad()
		InputManagerScript.ACTION_CLEAVE:
			on_cleave_pad()
		InputManagerScript.ACTION_BOLT:
			on_bolt_pad()
		InputManagerScript.ACTION_WARD:
			on_ward_pad()
		InputManagerScript.ACTION_LOOT:
			on_loot_pad()
		InputManagerScript.ACTION_CYCLE_MARK:
			on_mark_pad()
		InputManagerScript.ACTION_TOGGLE_DEBUG:
			debug_overlay.toggle()
		InputManagerScript.ACTION_TOGGLE_CHAT:
			hud.toggle_chat_input()
		InputManagerScript.ACTION_STICK:
			player.set_joystick(data["vec"])
		InputManagerScript.ACTION_SHOVE_PREVIEW:
			if int(data["mid"]) >= 0:
				var tile: Vector2i = data["to"]
				sim.preview_push(_monster_by_id(int(data["mid"])), tile.x, tile.y)
			else:
				var tile_s: Vector2i = data["to"]
				sim.preview_push_self(tile_s.x, tile_s.y)
		InputManagerScript.ACTION_SHOVE:
			sim.clear_push_preview()
			var to: Vector2i = data["to"]
			var r: Dictionary = sim.push(_monster_by_id(int(data["mid"])), to.x, to.y)
			if bool(r.get("ok", false)):
				buzz(25)
		InputManagerScript.ACTION_SHOVE_SELF:
			sim.clear_push_preview()
			var to_s: Vector2i = data["to"]
			var rs: Dictionary = sim.push_self(to_s.x, to_s.y)
			if bool(rs.get("ok", false)):
				buzz(25)
		InputManagerScript.ACTION_TAP:
			sim.clear_push_preview()
			var tile_t: Vector2i = data["tile"]
			# NPCs first (their tile may hold loot underneath), then mark/loot.
			var npc = npcs.npc_at(tile_t.x, tile_t.y, int(player.grid.z))
			if npc != null:
				interact_npc(npc)
			else:
				sim.tap_tile(tile_t.x, tile_t.y)
				buzz(8)

func _monster_by_id(mid: int):
	for m in (sim.get("monsters") as Array):
		if int(m.get("mid")) == mid and int(m.get("dying_at")) == 0:
			return m
	return null

# ---- websync ----------------------------------------------------------------
func _on_looted(item_key: String, qty: int) -> void:
	_loot_queue.append({"itemKey": item_key, "qty": qty})
	if _loot_queue.size() > Constants.LOOT_QUEUE_MAX:
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

# ---- sim events ---------------------------------------------------------------
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

# ---- draw ---------------------------------------------------------------------
func _draw() -> void:
	renderer.draw(self)
