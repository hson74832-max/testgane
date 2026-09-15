# World renderer, OTClient-style (cf. opentibiabr/otclient MapView/Tile/ThingType):
# visible 15x11 viewport, drawDimension = visible + margin for multi-sprite
# overhang; per-tile order ground/border/bottom/middle/top with displacement,
# position-based patterns and elevation; creatures/HP bars, damage numbers,
# click-path, push feedback and the day/night light pass on top.
# Pure presentation — gameplay state lives in the server.
class_name BlackTekWorldView
extends Node2D

const TILE := 32.0
const LOCAL_PLAYER_ID := 1
# Tibia 10.98 viewport: the area a player can see and directly interact with.
const VIEW_W := 15
const VIEW_H := 11

var server: BlackTekGameServer
var hud: BlackTekHud
var player_tile := Vector2i(15, 11)
var player_px := Vector2.ZERO
var floaters: Array = [] # {tile, z, amount, t, player}
var push: Dictionary = {} # {kind, mid/tile, start} while mouse-pushing
var press_on_pushable := false # left press began on a pushable (push or nothing, never walk)
var spell_flashes: Array = [] # {tile, z, t, dur, col} impact squares (exori hit)
var spell_marks: Array = [] # {tile, z, t, dur} wind-up warning squares (exori warn)

# Engine lighting (cf. OTClient LightView): CanvasModulate tints the whole
# world canvas by the day phase, PointLight2Ds add smooth round fire pools.
# No shadow occluders (lights bleed through walls, like the old overlay did).
var _modulate: CanvasModulate
var _light_layer: Node2D
var _torch_lights: Dictionary = {} # Vector3i tile -> PointLight2D
var _player_light: PointLight2D
var _light_tex: Texture2D
var _light_origin := Vector2i(1 << 30, 1 << 30)
var _light_z := -1

func _ready() -> void:
	_light_tex = _make_light_texture()
	_modulate = CanvasModulate.new()
	_modulate.color = Color.WHITE
	add_child(_modulate)
	_light_layer = Node2D.new()
	add_child(_light_layer)
	_player_light = PointLight2D.new()
	_player_light.texture = _light_tex
	_player_light.color = Color(1.0, 0.92, 0.75)
	_player_light.energy = 0.9
	_player_light.texture_scale = 2.0 * 3.5 * TILE / float(LIGHT_TEX_SIZE)
	add_child(_player_light)

const LIGHT_TEX_SIZE := 128

# Soft radial falloff texture shared by all lights (alpha = (1-d)^1.6).
static func _make_light_texture() -> Texture2D:
	var size := LIGHT_TEX_SIZE
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half := float(size) * 0.5
	for y in range(size):
		for x in range(size):
			var d := Vector2(x + 0.5 - half, y + 0.5 - half).length() / half
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, pow(a, 1.6)))
	return ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	# Age damage floaters (0.9s life) and spell impact squares (0.6s life).
	for f in floaters:
		f.t = float(f.t) + delta
	floaters = floaters.filter(func(f): return float(f.t) < 0.9)
	for s in spell_flashes:
		s.t = float(s.t) + delta
	spell_flashes = spell_flashes.filter(func(s): return float(s.t) < float(s.dur))
	for w in spell_marks:
		w.t = float(w.t) + delta
	spell_marks = spell_marks.filter(func(w): return float(w.t) < float(w.dur))
	_update_lights()
	queue_redraw()

# Spell area feedback: casts emit wind-up marks then impact squares.
# Footprints come from BlackTekActionScripts.spell_aoe_tiles; the server
# decides damage via the spell_area signal.
func on_spell_area(_center: Vector2i, z: int, tiles: Array, kind := "hit") -> void:
	if kind == "warn":
		# Wind-up telegraph: show for the tuned delay, then damage lands.
		var dur := 0.8
		if server != null and server.get("config") != null:
			dur = server.config.tune("whirlwind_delay")
		for t in tiles:
			spell_marks.append({"tile": t, "z": z, "t": 0.0, "dur": dur})
		return
	for t in tiles:
		spell_flashes.append({"tile": t, "z": z, "t": 0.0, "dur": 0.6, "col": Color(1.0, 0.35, 0.25, 0.9)})

# ---- push input (called from main's input handling) ----------------------------

# The map draws tiles at (tile - origin) * TILE in canvas space, so canvas
# position -> OTBM tile needs the view origin added back.
func mouse_tile() -> Vector2i:
	var canvas := get_global_mouse_position()
	return _view_origin() + Vector2i(int(floor(canvas.x / TILE)), int(floor(canvas.y / TILE)))

# Pushing is a melee-range interaction (cf. attack adjacency): the creature
# must stand on one of the 8 tiles around the player. Anything further is
# rejected so distant creatures can never be pushed (abuse) or show push UI.
func is_pushable_tile(t: Vector2i) -> bool:
	return maxi(absi(t.x - player_tile.x), absi(t.y - player_tile.y)) <= 1

# Push targets (push.kind): "mon" (adjacent creature), "self" (your own tile
# -> quick-step 1 SQM, same rules as key walking), "item" (a movable and/or
# takeable floor object on an adjacent tile). Release over the open gear
# panel to TAKE it into the backpack, anywhere else to SHOVE it 1 SQM.
# Anything further away is rejected so distant things can never be pushed
# (abuse) or show push UI.
func try_begin_push() -> void:
	press_on_pushable = false
	var t := mouse_tile()
	var m: Dictionary = server.monster_at(t, server.demo_z)
	if m.is_empty():
		if t == player_tile:
			press_on_pushable = true
			push = {"kind": "self", "start": _mouse_px()}
		elif is_pushable_tile(t) and (not server.pushable_item_at(t, server.demo_z).is_empty() or not server.takeable_item_at(t, server.demo_z).is_empty()):
			press_on_pushable = true
			push = {"kind": "item", "tile": t, "start": _mouse_px()}
		return
	press_on_pushable = true # release does push-or-nothing, never click-to-walk
	if not is_pushable_tile(t):
		return # too far away: no push state, no ring
	push = {"kind": "mon", "mid": int(m.id), "start": _mouse_px()}

# Drag start/current in viewport (screen) pixels: the click-vs-drag threshold
# must not depend on the camera zoom (world units shrink as sprites upscale).
func _mouse_px() -> Vector2:
	return get_viewport().get_mouse_position()

func right_click_target() -> void:
	var t := mouse_tile()
	var n: Dictionary = server.npc_at(t, server.demo_z)
	if not n.is_empty():
		server.interact_npc(LOCAL_PLAYER_ID, int(n.id))
		return
	var m: Dictionary = server.monster_at(t, server.demo_z)
	if not m.is_empty():
		server.set_target(LOCAL_PLAYER_ID, m)

# Push direction from the current drag: orthogonal only (Tibia has no diagonal
# pushes), snapped to the dominant axis so the preview and the server agree.
# Returns Vector2i.ZERO below the drag threshold (plain click).
func _push_drag() -> Vector2:
	# Current drag vector in viewport (screen) pixels, shared by the threshold,
	# the arrow preview and the push direction.
	if push.is_empty():
		return Vector2.ZERO
	return _mouse_px() - Vector2(push.start)

func _push_drag_dir() -> Vector2i:
	if push.is_empty():
		return Vector2i.ZERO
	return _push_drag_dir_for(_push_drag())

# Pure direction snap (headless-testable): below-threshold drags are clicks,
# otherwise the drag angle snaps to 8 directions so diagonal side-pushes
# work too. Screen y grows downward: east 0°, south +90°, west ±180°.
static func _push_drag_dir_for(drag: Vector2) -> Vector2i:
	if drag.length() < 14.0:
		return Vector2i.ZERO
	var dirs := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]
	return dirs[posmod(int(round(atan2(drag.y, drag.x) / (PI / 4.0))), 8)]

func finish_push() -> void:
	press_on_pushable = false
	if push.is_empty():
		return
	var kind := String(push.get("kind", "mon"))
	var mid: int = int(push.get("mid", 0))
	var grabbed: Vector2i = push.get("tile", player_tile)
	# Direction BEFORE clearing: _push_drag_dir() reads push.start.
	var dir := _push_drag_dir()
	push = {}
	if dir == Vector2i.ZERO:
		return # plain click: no push, no step, no walk
	if kind == "self":
		# Self-push: quick-step 1 SQM (same validation as key walking, stairs
		# included; the view also follows via the player_moved signal).
		# A refusal is messaged with its reason instead of silent nothing.
		var before: Vector2i = server.players[LOCAL_PLAYER_ID].tile
		var stepped: Vector2i = server.request_move(LOCAL_PLAYER_ID, dir)
		if stepped != before:
			player_tile = server.players[LOCAL_PLAYER_ID].tile
			var nz := server.try_stair_teleport(LOCAL_PLAYER_ID)
			if nz >= 0:
				player_tile = server.players[LOCAL_PLAYER_ID].tile
				if hud != null:
					hud.fade()
					hud.game_message("Took stairs (z=%d)." % nz)
		else:
			var why := server.step_blocker(LOCAL_PLAYER_ID, dir)
			if why == "pinched corner" or why == "creature in the way":
				server.message_local(LOCAL_PLAYER_ID, "You cannot step there (%s)." % why)
			elif why != "" and why != "no session" and why != "no direction":
				server.message_local(LOCAL_PLAYER_ID, "Blocked by %s." % why)
		return
	if kind == "item":
		# Release over the open gear panel takes it into the backpack,
		# anywhere else shoves it 1 SQM in the drag direction.
		if hud != null and hud.is_over_gear():
			server.pickup_item(grabbed, server.demo_z, LOCAL_PLAYER_ID)
			return
		server.push_item(grabbed, dir, server.demo_z, LOCAL_PLAYER_ID)
		return
	server.push_monster(mid, dir, LOCAL_PLAYER_ID)

func on_damage_float(pos: Vector2i, z: int, amount: int, from_player: bool) -> void:
	if amount == 0:
		return
	floaters.append({"tile": pos, "z": z, "amount": amount, "t": 0.0, "player": from_player})

# ---- rendering ------------------------------------------------------------------

func tile_to_px(t: Vector2i) -> Vector2:
	return Vector2(t) * TILE + Vector2(TILE, TILE) * 0.5

func view_size() -> Vector2i:
	return Vector2i(VIEW_W, VIEW_H)

func _view_origin() -> Vector2i:
	if not server.use_real_map:
		return Vector2i.ZERO
	# Center the 15x11 viewport on the player (7 left/right, 5 up/down).
	return player_tile - Vector2i(VIEW_W / 2, VIEW_H / 2)

func _draw() -> void:
	if server.use_real_map:
		_draw_real_map()
		return
	_draw_fallback_map()

func _draw_fallback_map() -> void:
	for y in range(BlackTekGameServer.MAP_H):
		for x in range(BlackTekGameServer.MAP_W):
			var t := Vector2i(x, y)
			var r := Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE))
			if not server.is_walkable(t):
				draw_rect(r, Color(0.16, 0.16, 0.2))
			else:
				var shade := 0.24 + 0.03 * float((x + y) % 2)
				draw_rect(r, Color(shade, shade + 0.02, shade + 0.06))
			draw_rect(r, Color(0, 0, 0, 0.35), false, 1.0)
	draw_circle(tile_to_px(Vector2i(15, 12)), 6.0, Color(0.3, 1.0, 0.5, 0.5))
	_draw_monsters()
	_draw_npcs()
	_draw_player(player_px)
	_draw_floaters(Vector2i.ZERO)
	_draw_push(Vector2i.ZERO)
	_draw_path(Vector2i.ZERO)
	_draw_spell_fx(Vector2i.ZERO)

func _draw_real_map() -> void:
	# Multi-floor painter (cf. OTClient mapview / opentibiabr/otclient):
	# floors bottom-first; per floor backgrounds then SPR sprites north->south.
	# SPR pixels are the primary visuals; OTBM only decides walkability/stairs.
	var origin := _view_origin()
	var view := view_size()
	var want_sprites := server.use_real_sprites
	# Viewport-strict rendering: backgrounds cover exactly the 15x11 viewport
	# and nothing is painted outside it. Sprite anchors are still iterated
	# over a margin (cf. OTClient MapView: drawDimension = visibleDimension
	# + 3) because multi-sprite objects anchor bottom-right and extend
	# west/north (+displacement) — but each sprite is culled against the
	# viewport rect, so overhangs paint INTO the view while nothing spills
	# out past it.
	var margin := 2
	var view_rect := Rect2(Vector2.ZERO, Vector2(view) * TILE)
	var floors: Array = server.floors_to_draw()
	var cur_fi := floors.size() - 1
	for fi in range(floors.size()):
		var z: int = floors[fi]
		var is_bottom := fi == 0
		# Smooth floor fading: floors above the player fade with distance.
		var floor_alpha: float = clampf(1.0 - 0.28 * float(cur_fi - fi), 0.3, 1.0)
		for dy in range(view.y):
			for dx in range(view.x):
				var wt := origin + Vector2i(dx, dy)
				var r := Rect2(Vector2(dx, dy) * TILE, Vector2(TILE, TILE))
				var entry := server.tile_info(wt, z)
				if entry.is_empty():
					if is_bottom:
						# Void outside the map: flat dark, no grid.
						draw_rect(r, Color(0.02, 0.02, 0.03, floor_alpha))
					continue
				if want_sprites:
					# Sprite is the visual: dark underlay so gaps never flash
					# the placeholder green; no walkability tint, no grid.
					draw_rect(r, Color(0.02, 0.02, 0.03, floor_alpha))
				else:
					# No sprites: OTBM walkability debug view with grid.
					if not server.is_walkable(wt, z):
						draw_rect(r, Color(0.16, 0.16, 0.2, floor_alpha))
					else:
						var ids0: Array = entry.get("items", [])
						var gid := int(ids0[0]) if not ids0.is_empty() else 0
						var shade := 0.22 + 0.05 * float(gid % 3)
						draw_rect(r, Color(shade * 0.6, shade + 0.12, shade * 0.6, floor_alpha))
					draw_rect(r, Color(0, 0, 0, 0.35 * floor_alpha), false, 1.0)
		# Sprite pass: margin anchors north->south so southern tiles overlap
		# northern ones; each 32px sprite is culled to the viewport rect.
		for dy2 in range(-margin, view.y + margin):
			for dx2 in range(-margin, view.x + margin):
				var wt2 := origin + Vector2i(dx2, dy2)
				var in_view: bool = dx2 >= 0 and dy2 >= 0 and dx2 < view.x and dy2 < view.y
				if want_sprites and not server.tile_info(wt2, z).is_empty():
					var draws := server.get_tile_draws(wt2, z)
					for d in draws:
						var sp := Vector2(dx2, dy2) * TILE + Vector2(d.ox, d.oy)
						if Rect2(sp, Vector2(TILE, TILE)).intersects(view_rect):
							draw_texture(d.tex, sp, Color(1, 1, 1, floor_alpha))
					if in_view and draws.is_empty():
						# Tile known but sprite missing: subtle fallback so the
						# viewport never shows holes (still no grid lines).
						draw_rect(Rect2(Vector2(dx2, dy2) * TILE, Vector2(TILE, TILE)), Color(0.1, 0.12, 0.1, floor_alpha))
				if in_view and z == server.demo_z and wt2 == player_tile:
					var pp := Vector2(dx2, dy2) * TILE + Vector2(TILE, TILE) * 0.5
					player_px = player_px.lerp(pp, 0.5)
	_draw_monsters()
	_draw_npcs()
	_draw_player(tile_to_px(player_tile) - Vector2(_view_origin()) * TILE)
	_draw_floaters(origin)
	_draw_push(origin)
	_draw_path(origin)
	_draw_spell_fx(origin)

func _is_in_view(t: Vector2i) -> bool:
	if not server.use_real_map:
		return true
	var o := _view_origin()
	return t.x >= o.x and t.y >= o.y and t.x < o.x + VIEW_W and t.y < o.y + VIEW_H

func _draw_monsters() -> void:
	var font := BlackTekUiKit.px_font()
	for m in server.monsters.values():
		if int(m.z) != server.demo_z:
			continue
		if not _is_in_view(m.tile):
			continue # outside the 15x11 viewport: not visible, not drawn
		var mp := tile_to_px(m.tile)
		if server.use_real_map:
			mp -= Vector2(_view_origin()) * TILE
		# Red square frame on the marked target, faint white ring otherwise.
		var is_target: bool = int(server.players.get(LOCAL_PLAYER_ID, {}).get("target", 0)) == int(m.id)
		draw_circle(mp, 11.0, Color(0.85, 0.2, 0.25))
		if is_target:
			draw_rect(Rect2(mp - Vector2(15, 15), Vector2(30, 30)), Color(1.0, 0.25, 0.2, 0.95), false, 2.5)
			_draw_attack_timer(mp, is_target)
		else:
			draw_arc(mp, 13.5, 0.0, TAU, 24, Color(1, 1, 1, 0.3), 1.0)
		# Name + overhead HP bar: green > 50%, yellow 25-50%, red < 25%.
		var hpmax: int = maxi(1, int(m.hpmax))
		var pct: float = clampf(float(int(m.hp)) / float(hpmax), 0.0, 1.0)
		var hp_col := Color(0.3, 0.85, 0.4)
		if pct <= 0.25:
			hp_col = Color(0.9, 0.25, 0.25)
		elif pct <= 0.5:
			hp_col = Color(0.95, 0.8, 0.25)
		draw_rect(Rect2(mp + Vector2(-16, -24), Vector2(32, 4)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(mp + Vector2(-16, -24), Vector2(32.0 * pct, 4)), hp_col)
		if font != null:
			# Overhead name always matches the HP bar color.
			var w := 80.0
			draw_string(font, mp + Vector2(-w / 2, -28), String(m.name), HORIZONTAL_ALIGNMENT_CENTER, w, 10, hp_col)

# Real NPCs (cf. game/npc.gd): blue marker + name, no HP bar (NPCs are not
# combat targets). Never targetable, never pushable. Rendered above monsters
# so Norf stays visible in a crowd.
func _draw_npcs() -> void:
	var font := BlackTekUiKit.px_font()
	for n in server.npcs.values():
		if int(n.z) != server.demo_z:
			continue
		if not _is_in_view(n.tile):
			continue # outside the 15x11 viewport: not visible, not drawn
		var np := tile_to_px(n.tile)
		if server.use_real_map:
			np -= Vector2(_view_origin()) * TILE
		draw_circle(np, 11.0, Color(0.3, 0.6, 1.0))
		draw_arc(np, 13.5, 0.0, TAU, 24, Color(0.75, 0.87, 1.0, 0.95), 2.0)
		if font != null:
			var w := 80.0
			draw_string(font, np + Vector2(-w / 2, -28), String(n.name), HORIZONTAL_ALIGNMENT_CENTER, w, 10, Color(0.6, 0.78, 1.0))

# Yellow dashed circle around the target: sweep fills as the attack timer
# recharges (full circle = ready to swing).
func _draw_attack_timer(mp: Vector2, is_target: bool) -> void:
	var p: Dictionary = server.players.get(LOCAL_PLAYER_ID, {})
	var now := Time.get_ticks_msec() / 1000.0
	var until: float = float(p.get("attack_cd", 0.0))
	var speed: float = BlackTekCombat.attack_speed(server, int(p.get("vocation", 4)))
	var frac := 1.0 - clampf((until - now) / maxf(speed, 0.01), 0.0, 1.0)
	var dashes := 14
	var seg := TAU / dashes
	for i in range(dashes):
		var from := -PI / 2.0 + i * seg
		if from - (-PI / 2.0) + seg <= TAU * frac:
			draw_arc(mp, 18.0, from, from + seg * 0.62, 5, Color(1.0, 0.85, 0.2, 0.95), 2.0)

func _draw_player(pp: Vector2) -> void:
	draw_circle(pp, 11.0, Color(0.2, 0.7, 1.0))
	draw_arc(pp, 11.0, 0.0, TAU, 24, Color.WHITE, 2.0)

# Engine light update (runs every frame): the CanvasModulate tints the world
# by day phase (smooth midnight blue -> dawn/dusk ember -> noon white) and
# one PointLight2D per in-view torch plus the player light paint the fire
# pools. Torch colors vary deterministically per tile (deep orange to pale
# gold) with a whisper of flicker; energies stay modest so overlaps blend
# instead of blowing out to white.
func _update_lights() -> void:
	if server == null or _modulate == null:
		return
	var ambient: float = server.day_ambient
	var t := clampf((ambient - 0.25) / 0.75, 0.0, 1.0) # 0 night ... 1 day
	var phase := TAU * fmod(server.day_time, BlackTekGameServer.DAY_CYCLE) / BlackTekGameServer.DAY_CYCLE
	var daylight := 0.5 + 0.5 * cos(phase) # 1 noon ... 0 midnight
	var twilight := 1.0 - absf(daylight * 2.0 - 1.0) # peaks at dawn/dusk
	var col := Color(0.10, 0.12, 0.22).lerp(Color.WHITE, t)
	col = col.lerp(Color(0.30, 0.15, 0.10), twilight * (1.0 - t) * 0.5)
	_modulate.color = col
	# Lights fade with the daylight: full glow at night, fully out at noon, so
	# torches never blow out a sunlit room (your daylight screenshot).
	# Everything below is continuous in glow — no visibility toggles — so the
	# day/night change cross-fades instead of popping.
	var glow := clampf((0.995 - ambient) / 0.745, 0.0, 1.0)
	# utevo lux test spell: personal light buff, routed through the same
	# light script as the torch sources below (shared spawn + flicker).
	var now := Time.get_ticks_msec() / 1000.0
	var lux := false
	if server.players.has(LOCAL_PLAYER_ID):
		lux = float(server.players[LOCAL_PLAYER_ID].get("light_until", 0.0)) > now
	# The lux lamp only reads well in the dark — on a bright canvas the warm
	# pool renders as an ugly yellow blob — so it ramps in across a dusk band
	# instead of snapping on. The buff itself (timer, Lit chip) is unaffected.
	var lux_level := 0.0
	if lux:
		lux_level = glow * clampf((glow - LUX_FADE_LO) / (LUX_FADE_HI - LUX_FADE_LO), 0.0, 1.0)
	var lit := glow > 0.0005 or lux_level > 0.0005
	_light_layer.visible = true
	_player_light.visible = true
	if not lit:
		_free_lux_light()
		_player_light.energy = 0.0
		return
	var origin := _view_origin()
	if origin != _light_origin or server.demo_z != _light_z:
		_sync_torch_lights(origin)
	# Player light follows the smoothed position; torches shimmer gently.
	_player_light.position = player_px
	_player_light.energy = 0.9 * glow * (1.0 + 0.02 * sin(now * 2.1))
	_update_lux_light(origin, lux, lux_level, now)
	for key in _torch_lights.keys():
		_apply_flicker(_torch_lights[key] as PointLight2D, glow, now)

# Shared fire flicker (torches and the utevo lux lamp run the same script).
static func _apply_flicker(n: PointLight2D, glow: float, now: float) -> void:
	var base: float = float(n.get_meta("base_e", 0.85))
	var ph: float = float(n.get_meta("phase", 0.0))
	n.energy = base * glow * (1.0 + 0.05 * sin(now * 3.1 + ph))

# Shared fire-light spawn (torches and the utevo lux lamp are built alike):
# radial texture, deterministic ember-to-gold tint per tile, gentle flicker.
func _spawn_fire_light(viewport_px: Vector2, tile: Vector2i, lr: float, base_e := 0.85) -> PointLight2D:
	var n := PointLight2D.new()
	n.texture = _light_tex
	n.position = viewport_px
	# Deterministic fire tint per tile: deep ember orange to pale gold.
	var h := float(posmod(tile.x * 73856093 ^ tile.y * 19349663, 100)) / 100.0
	n.color = Color(1.0, 0.45, 0.10).lerp(Color(1.0, 0.80, 0.50), h)
	n.set_meta("base_e", base_e)
	n.set_meta("phase", h * TAU)
	n.energy = base_e
	n.texture_scale = 2.0 * lr * TILE / float(LIGHT_TEX_SIZE)
	_light_layer.add_child(n)
	return n

# utevo lux lamp: a torch-grade light pinned to the player tile, managed
# through the same spawn/flicker path as the map sources above. Its level
# ramps across the dusk band (LUX_FADE_LO..HI) so daybreak never pops.
const LUX_RADIUS := 4.0
const LUX_FADE_LO := 0.10
const LUX_FADE_HI := 0.35
var _lux_light: PointLight2D = null

func _free_lux_light() -> void:
	if is_instance_valid(_lux_light):
		_lux_light.queue_free()
	_lux_light = null

func _update_lux_light(origin: Vector2i, lux: bool, level: float, now: float) -> void:
	if not lux:
		_free_lux_light()
		return
	var pt: Vector2i = server.players[LOCAL_PLAYER_ID].tile
	if not is_instance_valid(_lux_light):
		_lux_light = _spawn_fire_light(tile_to_px(pt) - Vector2(origin) * TILE, pt, LUX_RADIUS)
	# Follow the player as the viewport recenters, flicker like a torch.
	_lux_light.position = tile_to_px(pt) - Vector2(origin) * TILE
	_apply_flicker(_lux_light, level, now)

# Torch pool, synced by diff: nodes are reused across viewport moves (only
# positions refresh) instead of freed and recreated every step. Light params
# are deterministic per tile, so an in-place sync is exactly equivalent.
func _sync_torch_lights(origin: Vector2i) -> void:
	var half := Vector2(TILE, TILE) * 0.5
	var view := view_size()
	var want := {}
	for dy in range(view.y):
		for dx in range(view.x):
			var wt := origin + Vector2i(dx, dy)
			var lr := clampf(float(server.tile_light_radius(wt, server.demo_z)) * 0.55, 0.0, 6.0)
			if lr <= 0.0:
				continue
			want[Vector3i(wt.x, wt.y, server.demo_z)] = [Vector2(dx, dy) * TILE + half, lr]
	for key in _torch_lights.keys():
		if not want.has(key):
			(_torch_lights[key] as PointLight2D).queue_free()
			_torch_lights.erase(key)
	for key in want.keys():
		var spec: Array = want[key]
		var n: PointLight2D = _torch_lights.get(key)
		if n == null or not is_instance_valid(n):
			_torch_lights[key] = _spawn_fire_light(spec[0], Vector2i(key.x, key.y), spec[1])
		else:
			n.position = spec[0]
	_light_origin = origin
	_light_z = server.demo_z

func _draw_path(origin: Vector2i) -> void:
	if hud == null or not hud.in_game:
		return
	# Dots stay inside the viewport like everything else.
	var bounds := Rect2(Vector2(-8, -8), Vector2(VIEW_W, VIEW_H) * TILE + Vector2(16, 16))
	for step in server.get_path(LOCAL_PLAYER_ID):
		var sp: Vector2 = tile_to_px(step) - Vector2(origin) * TILE
		if bounds.has_point(sp):
			draw_circle(sp, 5.0, Color(0.4, 0.9, 1.0, 0.6))

# Spell area feedback (cf. on_spell_area): pulsing yellow wind-up squares
# while the cast cooks, fading red impact squares when damage lands.
func _draw_spell_fx(origin: Vector2i) -> void:
	if server == null:
		return
	if hud != null and hud.in_game:
		var now_marks := Time.get_ticks_msec() / 1000.0
		for w in spell_marks:
			if int(w.z) != server.demo_z:
				continue
			var wp: Vector2 = tile_to_px(w.tile) - Vector2(origin) * TILE
			var pulse: float = 0.45 + 0.3 * sin(now_marks * 9.0)
			draw_rect(Rect2(wp - Vector2(16, 16), Vector2(32, 32)), Color(1.0, 0.8, 0.25, pulse), false, 2.0)
		for s in spell_flashes:
			if int(s.z) != server.demo_z:
				continue
			var fp: Vector2 = tile_to_px(s.tile) - Vector2(origin) * TILE
			var left: float = clampf(1.0 - float(s.t) / float(s.dur), 0.0, 1.0)
			var c: Color = s.col
			draw_rect(Rect2(fp - Vector2(16, 16), Vector2(32, 32)), Color(c.r, c.g, c.b, c.a * left), false, 2.0)

# Shared push preview: outline of the destination SQM (where the pushed thing
# would land) plus an arrow along the true mouse direction. Green = release
# goes through, red = blocked.
func _draw_push_arrow(center: Vector2, ok: bool, dest: Vector2) -> void:
	var drag := _push_drag()
	if drag.length() < 14.0:
		return
	var col := Color(0.4, 1.0, 0.5, 0.9) if ok else Color(1.0, 0.4, 0.4, 0.9)
	draw_rect(Rect2(dest - Vector2(16, 16), Vector2(32, 32)), col, false, 2.0)
	var tip := center + drag.normalized() * 26.0
	draw_line(center, tip, col, 3.0)
	draw_circle(tip, 5.0, col)

func _draw_push(origin: Vector2i) -> void:
	if push.is_empty():
		return
	var kind := String(push.get("kind", "mon"))
	if kind == "self":
		_draw_self_push(origin)
		return
	if kind == "item":
		_draw_item_push(origin)
		return
	var mid := int(push.get("mid", 0))
	var m: Dictionary = server.monsters.get(mid, {})
	if m.is_empty():
		push = {}
		return
	if not is_pushable_tile(m.tile):
		push = {} # walked/teleported away, or the creature moved off: no UI
		return
	# The ring is honest: gray while this creature cools down, yellow when a
	# release would actually push (green arrow) vs. red when blocked.
	var cooling := server.push_cooldown_remaining(mid) > 0.0
	var mp := tile_to_px(m.tile) - Vector2(origin) * TILE
	draw_arc(mp, 15.0, 0.0, TAU, 24, Color(0.55, 0.55, 0.6, 0.9) if cooling else Color(1.0, 0.85, 0.3, 0.9), 2.5)
	var dir_i := _push_drag_dir()
	if dir_i == Vector2i.ZERO:
		return
	_draw_push_arrow(mp, not cooling and server.can_push_monster(mid, dir_i), tile_to_px(m.tile + dir_i) - Vector2(origin) * TILE)

# Self-push preview: ring around the player, green when the step tile is free.
# Uses the exact server step validation (walkability + occupancy, dest-only
# like the real server), so green always means the release will move you.
func _draw_self_push(origin: Vector2i) -> void:
	var pp := tile_to_px(player_tile) - Vector2(origin) * TILE
	draw_arc(pp, 15.0, 0.0, TAU, 24, Color(0.4, 0.9, 1.0, 0.9), 2.5)
	var dir_i := _push_drag_dir()
	if dir_i == Vector2i.ZERO:
		return
	_draw_push_arrow(pp, server.can_step(LOCAL_PLAYER_ID, dir_i), tile_to_px(player_tile + dir_i) - Vector2(origin) * TILE)

# Floor-item preview: ring around the grabbed tile. Hovering the open gear
# panel previews the TAKE (green = fits, red = full backpack); anywhere else
# previews the SHOVE with its destination SQM highlighted.
func _draw_item_push(origin: Vector2i) -> void:
	var t: Vector2i = push.get("tile", player_tile)
	if not is_pushable_tile(t):
		push = {}
		return
	if server.pushable_item_at(t, server.demo_z).is_empty() and server.takeable_item_at(t, server.demo_z).is_empty():
		push = {} # item moved on while dragging: no UI
		return
	var tp := tile_to_px(t) - Vector2(origin) * TILE
	draw_arc(tp, 15.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.3, 0.9), 2.5)
	if hud != null and hud.is_over_gear():
		# Taking it into the backpack: ring only, no arrow or square — the
		# destination preview belongs to shoves, not pickups.
		return
	var dir_i := _push_drag_dir()
	if dir_i == Vector2i.ZERO:
		return
	_draw_push_arrow(tp, server.can_push_item(t, dir_i, server.demo_z), tile_to_px(t + dir_i) - Vector2(origin) * TILE)

func _draw_floaters(origin: Vector2i) -> void:
	var font := BlackTekUiKit.px_font()
	var bounds := Rect2(Vector2(-8, -40), Vector2(VIEW_W, VIEW_H) * TILE + Vector2(16, 48))
	for f in floaters:
		var age: float = float(f.t)
		var base := tile_to_px(f.tile) - Vector2(origin) * TILE
		if not bounds.has_point(base):
			continue # never float damage numbers outside the viewport
		var pos := base + Vector2(0, -16.0 - 22.0 * age)
		var alpha: float = 1.0 - age / 0.9
		var col := Color(0.55, 1.0, 0.6, alpha) if bool(f.player) else Color(1.0, 0.45, 0.45, alpha)
		if font != null:
			draw_string(font, pos + Vector2(-30, 0), str(int(f.amount)), HORIZONTAL_ALIGNMENT_CENTER, 60, 10, col)
