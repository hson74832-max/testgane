# Minimap: zoomable radius map with floor layers, markers (monsters, Norf,
# stairs, temple, waypoints) and fog of war. Left-click walks + marks,
# right-click clears. Waypoints persist through the shell (user cfg).
class_name BlackTekMinimapPanel
extends RefCounted

const R := 40 # half-view radius in tiles (81x81 canvas)
const PX_MIN := 2.0
const PX_MAX := 6.0
const FOG_R := 8 # "seen" radius around the player (Chebyshev tiles)
const FOG_COL := Color(0.012, 0.012, 0.02)
const MAX_WP := 12

class MinimapView extends Control:
	var panel: BlackTekMinimapPanel
	func _init(p: BlackTekMinimapPanel) -> void:
		panel = p
		mouse_filter = Control.MOUSE_FILTER_STOP
	func _draw() -> void:
		panel.draw_map(self)
	func _gui_input(ev: InputEvent) -> void:
		panel.map_input(ev)

var hud: Control
var game: BlackTekGameServer
var pid := 1
var panel: PanelContainer
var view: Control
var px := 3.0
var view_z := 7
var last_player_z := 7
var fog := {} # Vector3i -> true (explored this session)
var waypoints: Array = [] # {name, tile, z}
var active_wp := {} # {tile, z} destination marker (cleared on arrival)
var wp_list: VBoxContainer
var zoom_label: Label
var floor_label: Label
var _wp_n := 0
var _clock := 0.0

func build(h: Control) -> void:
	hud = h
	game = hud.game
	pid = hud._pid
	panel = BlackTekUiKit.panel(hud, "top-right", Vector2(270, 300))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	# Zoom + floor layer controls.
	var ctl := HBoxContainer.new()
	ctl.add_theme_constant_override("separation", 4)
	ctl.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(ctl)
	var zout := Button.new()
	zout.text = "−"
	zout.focus_mode = Control.FOCUS_NONE
	zout.tooltip_text = "Zoom out"
	zout.pressed.connect(func(): set_zoom(px - 1.0))
	ctl.add_child(zout)
	zoom_label = BlackTekUiKit.label(ctl, "", 11, Color(0.6, 0.65, 0.72))
	var zin := Button.new()
	zin.text = "+"
	zin.focus_mode = Control.FOCUS_NONE
	zin.tooltip_text = "Zoom in"
	zin.pressed.connect(func(): set_zoom(px + 1.0))
	ctl.add_child(zin)
	var fdown := Button.new()
	fdown.text = "▼"
	fdown.focus_mode = Control.FOCUS_NONE
	fdown.tooltip_text = "View floor below (auto-follows you)"
	fdown.pressed.connect(func(): set_floor(view_z + 1))
	ctl.add_child(fdown)
	floor_label = BlackTekUiKit.label(ctl, "", 11, Color(0.6, 0.65, 0.72))
	var fup := Button.new()
	fup.text = "▲"
	fup.focus_mode = Control.FOCUS_NONE
	fup.tooltip_text = "View floor above (auto-follows you)"
	fup.pressed.connect(func(): set_floor(view_z - 1))
	ctl.add_child(fup)
	view = MinimapView.new(self)
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	view.tooltip_text = "Click: walk + mark · Right-click: stop"
	box.add_child(view)
	# Waypoint list.
	var whead := HBoxContainer.new()
	whead.add_theme_constant_override("separation", 4)
	box.add_child(whead)
	BlackTekUiKit.label(whead, "Waypoints", 12, BlackTekUiKit.ACCENT).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var add := Button.new()
	add.text = "+ mark"
	add.focus_mode = Control.FOCUS_NONE
	add.tooltip_text = "Save current position as waypoint"
	add.pressed.connect(func(): add_waypoint_here())
	whead.add_child(add)
	wp_list = VBoxContainer.new()
	wp_list.add_theme_constant_override("separation", 2)
	box.add_child(wp_list)
	hud.panel_header(panel, box, "Minimap")
	if not game.players.is_empty():
		last_player_z = int(game.players[pid].z)
		view_z = last_player_z
	_refresh_labels()
	_update_view_size()
	rebuild_wp_list()
	panel.visible = false

func toggle() -> void:
	hud._toggle_panel(panel)

# ---- shell cadence (repaint, floor follow, arrival, fog) ----

func tick(delta: float) -> void:
	if game == null or game.players.is_empty():
		return
	var p: Dictionary = game.players.get(pid, {})
	var pz: int = int(p.get("z", 7))
	if pz != last_player_z:
		last_player_z = pz
		view_z = pz # player changed floor: re-follow
		_refresh_labels()
	if not active_wp.is_empty():
		var at: Vector2i = active_wp.tile
		if p.get("tile", Vector2i(-9999, -9999)) == at and pz == int(active_wp.z):
			active_wp = {}
			game.message_local(pid, "Arrived at waypoint.")
	_clock += delta
	if _clock >= 0.4:
		_clock = 0.0
		fog_mark(p.get("tile", Vector2i.ZERO), pz)
		view.queue_redraw()

# ---- zoom + floor layers ----

func set_zoom(v: float) -> void:
	px = clampf(v, PX_MIN, PX_MAX)
	_update_view_size()
	_refresh_labels()
	_refit()
	if panel.visible:
		view.queue_redraw()

func set_floor(z: int) -> void:
	view_z = clampi(z, 0, 15)
	_refresh_labels()
	if panel.visible:
		view.queue_redraw()

func _update_view_size() -> void:
	view.custom_minimum_size = Vector2((2 * R + 1) * px, (2 * R + 1) * px)
	view.size = view.custom_minimum_size

func _refresh_labels() -> void:
	zoom_label.text = "%dpx" % int(px)
	floor_label.text = "Floor %d" % view_z

func _refit() -> void:
	var m := panel.get_combined_minimum_size()
	panel.offset_right = panel.offset_left + m.x
	panel.offset_bottom = panel.offset_top + m.y
	hud._clamp_panel(panel)

# ---- fog of war (session exploration) ----

func fog_mark(center: Vector2i, z: int) -> void:
	for dy in range(-FOG_R, FOG_R + 1):
		for dx in range(-FOG_R, FOG_R + 1):
			fog[Vector3i(center.x + dx, center.y + dy, z)] = true

func is_explored(t: Vector2i, z: int) -> bool:
	return fog.has(Vector3i(t.x, t.y, z))

# ---- waypoints (persisted through the shell user cfg) ----

func add_waypoint_here() -> String:
	if game.players.is_empty():
		return ""
	var p: Dictionary = game.players[pid]
	return add_waypoint(p.tile, int(p.z), "")

func add_waypoint(tile: Vector2i, z: int, wp_name: String) -> String:
	if waypoints.size() >= MAX_WP:
		game.message_local(pid, "Waypoint list is full (max %d)." % MAX_WP)
		return ""
	_wp_n += 1
	var nm := wp_name.strip_edges() if wp_name.strip_edges() != "" else "Mark %d" % _wp_n
	waypoints.append({"name": nm, "tile": tile, "z": z})
	rebuild_wp_list()
	return nm

func remove_waypoint(i: int) -> void:
	if i >= 0 and i < waypoints.size():
		waypoints.remove_at(i)
		rebuild_wp_list()

func goto_waypoint(i: int) -> bool:
	if i < 0 or i >= waypoints.size() or game.players.is_empty():
		return false
	var w: Dictionary = waypoints[i]
	if int(w.z) != int(game.players[pid].z):
		set_floor(int(w.z))
		game.message_local(pid, "Waypoint is on Floor %d (shown, walk there yourself)." % int(w.z))
		return false
	active_wp = {"tile": w.tile, "z": int(w.z)}
	var res: int = game.request_path(pid, w.tile)
	if res < 0:
		active_wp = {}
		game.message_local(pid, "Can't walk there.")
		return false
	return true

func clear_active(silent := false) -> void:
	active_wp = {}
	game.cancel_path(pid)
	if not silent:
		game.message_local(pid, "Waypoint cleared.")

func get_waypoints() -> Array:
	var out := []
	for w in waypoints:
		out.append([int(w.tile.x), int(w.tile.y), int(w.z), String(w.name)])
	return out

func set_waypoints(arr: Array) -> void:
	waypoints.clear()
	for e in arr:
		if e is Array and e.size() >= 4:
			waypoints.append({"name": String(e[3]), "tile": Vector2i(int(e[0]), int(e[1])), "z": int(e[2])})
			if waypoints.size() >= MAX_WP:
				break
	rebuild_wp_list()

func rebuild_wp_list() -> void:
	if wp_list == null:
		return
	for c in wp_list.get_children():
		c.queue_free()
	for i in range(waypoints.size()):
		var w: Dictionary = waypoints[i]
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 4)
		wp_list.add_child(h)
		BlackTekUiKit.label(h, "%s (%d,%d,%d)" % [String(w.name), int(w.tile.x), int(w.tile.y), int(w.z)], 10).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var go := Button.new()
		go.text = "Go"
		go.focus_mode = Control.FOCUS_NONE
		var idx := i
		go.pressed.connect(func(): goto_waypoint(idx))
		h.add_child(go)
		var del := Button.new()
		del.text = "X"
		del.focus_mode = Control.FOCUS_NONE
		del.pressed.connect(func(): remove_waypoint(idx))
		h.add_child(del)

# ---- map clicks ----

func pick_tile(local: Vector2) -> Dictionary:
	if game.players.is_empty():
		return {"tile": Vector2i.ZERO, "inside": false}
	var center: Vector2i = game.players[pid].tile
	var dx := int(floor(local.x / px)) - R
	var dy := int(floor(local.y / px)) - R
	var inside: bool = absi(dx) <= R and absi(dy) <= R
	return {"tile": center + Vector2i(dx, dy), "inside": inside}

func map_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		_hover_info(ev.position)
		return
	if not (ev is InputEventMouseButton and ev.pressed):
		return
	var mb := ev as InputEventMouseButton
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		game.cancel_path(pid) # stop walking, keep the mark
		return
	if mb.button_index != MOUSE_BUTTON_LEFT or game.players.is_empty():
		return
	if view_z != int(game.players[pid].z):
		set_floor(int(game.players[pid].z)) # browsing: first click re-follows
		return
	click_goto(mb.position)

func click_goto(local: Vector2) -> bool:
	var pick := pick_tile(local)
	if not bool(pick.inside):
		return false
	var t: Vector2i = pick.tile
	active_wp = {"tile": t, "z": int(game.players[pid].z)}
	if game.request_path(pid, t) < 0:
		active_wp = {}
		game.message_local(pid, "Can't walk there.")
		return false
	return true

# Hover infotext: what lives under the cursor (NPC, waypoint, stairs,
// temple, you). Updates the view tooltip live.
func _hover_info(local: Vector2) -> void:
	var info := ""
	if game != null and not game.players.is_empty():
		var pick := pick_tile(local)
		if bool(pick.inside):
			var t: Vector2i = pick.tile
			var n := game.npc_at(t, view_z)
			if not n.is_empty():
				info = "%s (shop — right-click the world to trade)" % String(n.get("name", "Norf"))
			else:
				for w in waypoints:
					if w.tile == t and int(w.z) == view_z:
						info = "Mark: %s (%d,%d,%d)" % [String(w.name), t.x, t.y, view_z]
						break
			if info == "" and not active_wp.is_empty() and active_wp.tile == t and int(active_wp.z) == view_z:
				info = "Destination (%d,%d,%d)" % [t.x, t.y, view_z]
			if info == "" and game.use_real_map and _is_stair(t, view_z):
				info = "Stairs"
			if info == "" and t == game.temple_tile and view_z == game.npc_z:
				info = "Temple (protection zone)"
			if info == "" and t == game.players[pid].tile and view_z == int(game.players[pid].z):
				info = "You (%s)" % String(game.players[pid].get("name", ""))
	view.tooltip_text = info

func _is_stair(t: Vector2i, z: int) -> bool:
	if game.dat == null:
		return false
	for id in game.tile_info(t, z).get("items", []):
		if bool(game.dat.items.get(int(id), {}).get("is_stair", false)):
			return true
	return false

func draw_map(v: Control) -> void:
	if game == null or game.players.is_empty():
		return
	var p: Dictionary = game.players.get(pid, {})
	var center: Vector2i = p.get("tile", Vector2i.ZERO)
	var z: int = view_z
	for dy in range(-R, R + 1):
		for dx in range(-R, R + 1):
			var t := center + Vector2i(dx, dy)
			var col := Color(0.03, 0.03, 0.045)
			var explored: bool = fog.has(Vector3i(t.x, t.y, z))
			if game.use_real_map:
				var entry := game.tile_info(t, z)
				if not entry.is_empty():
					if game.is_walkable(t, z):
						var ids: Array = entry.get("items", [])
						var gid := int(ids[0]) if not ids.is_empty() else 0
						var s := 0.32 + 0.05 * float(gid % 5)
						col = Color(s * 0.65, s, s * 0.65)
					else:
						col = Color(0.1, 0.1, 0.13)
			else:
				col = Color(0.28, 0.34, 0.28) if game.is_walkable(t) else Color(0.1, 0.1, 0.12)
			if not explored:
				col = FOG_COL
			v.draw_rect(Rect2(Vector2((dx + R) * px, (dy + R) * px), Vector2(px, px)), col)
			if explored and game.use_real_map and _is_stair(t, z):
				v.draw_rect(Rect2(Vector2((dx + R) * px + 1, (dy + R) * px + 1), Vector2(px - 2, px - 2)), Color(0.95, 0.8, 0.25), false, 1.0)
			if explored and t == game.temple_tile and z == game.npc_z:
				var cx := (dx + R) * px + px * 0.5
				var cy := (dy + R) * px + px * 0.5
				var r := px * 0.32
				v.draw_line(Vector2(cx - r, cy) , Vector2(cx + r, cy), Color(0.35, 0.9, 0.45), 1.0)
				v.draw_line(Vector2(cx, cy - r), Vector2(cx, cy + r), Color(0.35, 0.9, 0.45), 1.0)
	for m in game.monsters.values():
		if int(m.z) != z:
			continue
		var off: Vector2i = Vector2i(int(m.tile.x), int(m.tile.y)) - center
		if absi(off.x) > R or absi(off.y) > R:
			continue
		v.draw_rect(Rect2(Vector2((off.x + R) * px + 0.5, (off.y + R) * px + 0.5), Vector2(px - 1, px - 1)), Color(0.95, 0.3, 0.3))
	for n in game.npcs.values():
		if int(n.z) != z:
			continue
		var off2: Vector2i = Vector2i(int(n.tile.x), int(n.tile.y)) - center
		if absi(off2.x) > R or absi(off2.y) > R:
			continue
		v.draw_rect(Rect2(Vector2((off2.x + R) * px + 0.5, (off2.y + R) * px + 0.5), Vector2(px - 1, px - 1)), Color(0.3, 0.6, 1.0))
	for w in waypoints:
		if int(w.z) != z:
			continue
		_draw_diamond(v, center, w.tile, Color(0.4, 0.95, 0.9))
	if not active_wp.is_empty() and int(active_wp.z) == z:
		_draw_diamond(v, center, active_wp.tile, Color(1.0, 1.0, 1.0))
	v.draw_rect(Rect2(Vector2(R * px - 1.5, R * px - 1.5), Vector2(px + 3, px + 3)), Color(0.35, 0.8, 1.0))

func _draw_diamond(v: Control, center: Vector2i, t: Vector2i, col: Color) -> void:
	var off: Vector2i = t - center
	if absi(off.x) > R or absi(off.y) > R:
		return
	var cx := (off.x + R) * px + px * 0.5
	var cy := (off.y + R) * px + px * 0.5
	var r := px * 0.5
	v.draw_colored_polygon([Vector2(cx, cy - r), Vector2(cx + r, cy), Vector2(cx, cy + r), Vector2(cx - r, cy)], col)
