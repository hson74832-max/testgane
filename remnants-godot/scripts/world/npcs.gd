extends Node2D
## NPCs — the Sanctuary's fixtures. Tibia-style: talk in range, trade potions
## at base price, sell loot at half base (economy review flag: the web bible
## forbids NPC gear vendors; here NPCs move consumables only, and buy loot
## as a gold faucet to watch), heal ills, ferry the surface.
## CONTENT LIVES IN content.ts (NPCS/FERRY/NPC_STOCK): new NPC = new row +
## export, zero code. NPC tiles block movement (player + monsters route around).

const Constants := preload("res://scripts/core/constants.gd")

var player: PlayerGrid = null
var sim: CombatSim = null
## Parsed rows: pos converted Vector3i, color converted Color.
var defs: Array = []
var ferry: Array = []

func setup(p, s) -> void:
	player = p
	sim = s
	z_index = 2
	defs = []
	for n in (GameBalance.NPCS as Array):
		var d: Dictionary = (n as Dictionary).duplicate()
		var pos: Array = d.get("pos", [0, 0, 0])
		d["pos"] = Vector3i(int(pos[0]), int(pos[1]), int(pos[2]))
		d["color"] = Color.html(String(d.get("color", "#ffffff")))
		defs.append(d)
	ferry = []
	for d in (GameBalance.FERRY as Array):
		var f: Dictionary = (d as Dictionary).duplicate()
		var fpos: Array = f.get("pos", [0, 0, 0])
		f["pos"] = Vector3i(int(fpos[0]), int(fpos[1]), int(fpos[2]))
		ferry.append(f)

func stock() -> Array:
	return GameBalance.NPC_STOCK

func talk_range() -> int:
	return GameBalance.NPC_TALK_RANGE

func heal_cost() -> int:
	return GameBalance.NPC_HEAL_COST

func ferry_cost() -> int:
	return GameBalance.NPC_FERRY_COST

func npc_at(x: int, y: int, fz: int) -> Variant:  # Dictionary or null
	for n in defs:
		var pos: Vector3i = n["pos"]
		if pos.x == x and pos.y == y and pos.z == fz:
			return n
	return null

func is_occupied(x: int, y: int) -> bool:
	return npc_at(x, y, 0) != null

func npc_pos(n: Dictionary) -> Vector3i:
	return n["pos"]

func can_talk(n: Dictionary) -> bool:
	var pos: Vector3i = npc_pos(n)
	if pos.z != int(player.grid.z):
		return false
	return maxi(absi(pos.x - player.grid.x), absi(pos.y - player.grid.y)) <= talk_range()

func price(item_key: String) -> int:
	return maxi(1, int((GameBalance.item_def(item_key) as Dictionary).get("basePrice", 1)))

func sell_value(item_key: String) -> int:
	return maxi(1, int(floor(float(price(item_key)) * GameBalance.NPC_SELL_PCT)))

func _role_npc(role: String) -> Dictionary:
	for n in defs:
		if String(n.get("role", "")) == role:
			return n
	return {}

## Server-side of the counter: every deal re-checks range, so walking away
## mid-sheet (or calling methods directly) cannot trade across the map.
func _at_counter(role: String) -> bool:
	var npc: Dictionary = _role_npc(role)
	if npc.is_empty() or not can_talk(npc):
		sim.toast.emit("Too far from the counter.", "bad")
		return false
	return true

func buy(item_key: String) -> bool:
	if not stock().has(item_key):
		return false
	if not _at_counter("trader"):
		return false
	var cost: int = price(item_key)
	if int(player.get("gold")) < cost:
		sim.toast.emit("Not enough gold (need %d)." % cost, "bad")
		return false
	player.set("gold", int(player.get("gold")) - cost)
	sim._put_satchel(item_key, 1)
	sim.add_float("+%s" % item_key, Vector3_to_v2(player.grid), Color(0.64, 0.9, 0.21), false)
	sim.toast.emit("Bought %s for %dg" % [item_key, cost], "good")
	return true

func sell(item_key: String) -> int:
	if item_key == "gold":
		return -1
	if not _at_counter("trader"):
		return -1
	if int((sim.get("local_inventory") as Dictionary).get(item_key, 0)) < 1:
		return -1
	var gain: int = sell_value(item_key)
	sim._take_satchel(item_key, 1)
	player.set("gold", int(player.get("gold")) + gain)
	sim.toast.emit("Sold %s for %dg" % [item_key, gain], "good")
	return gain

func heal() -> bool:
	if not _at_counter("healer"):
		return false
	var needs: bool = int(player.get("hp")) < int(player.get("max_hp"))
	var sts: Array = player.get("statuses")
	for s in sts:
		if ["poison", "burn", "slow"].has(String(s.get("key", ""))):
			needs = true
	if not needs:
		sim.toast.emit("Brother Ansel: you feel whole already.", "info")
		return false
	if int(player.get("gold")) < heal_cost():
		sim.toast.emit("Not enough gold (need %d)." % heal_cost(), "bad")
		return false
	player.set("gold", int(player.get("gold")) - heal_cost())
	player.set("hp", int(player.get("max_hp")))
	sts.assign(sts.filter(func(s: Dictionary) -> bool: return not ["poison", "burn", "slow"].has(String(s.get("key", "")))))
	sim.add_float("mended", Vector3_to_v2(player.grid), Color(0.3, 0.87, 0.5), false)
	sim.toast.emit("Mended for %dg" % heal_cost(), "good")
	return true

func travel(dest_key: String) -> bool:
	if not _at_counter("ferry"):
		return false
	var dest: Vector3i = Vector3i(-999, -999, -999)
	var label := ""
	for d in ferry:
		if String(d["key"]) == dest_key:
			dest = d["pos"]
			label = String(d["name"])
	if dest.x < -900:
		return false
	if int(player.get("gold")) < ferry_cost():
		sim.toast.emit("Not enough gold (need %d)." % ferry_cost(), "bad")
		return false
	var spot: Vector3i = _nearest_open(dest)
	if spot.x < -900:
		sim.toast.emit("The crossing is blocked.", "bad")
		return false
	player.set("gold", int(player.get("gold")) - ferry_cost())
	player.set("grid", spot)
	player.set("render", Vector2(spot.x, spot.y))
	sim.toast.emit("Dredge poles you to %s (%dg)" % [label, ferry_cost()], "good")
	return true

func _nearest_open(dest: Vector3i) -> Vector3i:
	var ft: Array = sim.current_tiles()
	for r in range(0, Constants.COUNTER_SLIDE_RADIUS):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var c := Vector3i(dest.x + dx, dest.y + dy, dest.z)
				if WorldGen.is_walkable(ft, c.x, c.y) and sim.monster_at(c.x, c.y, c.z) == null and not is_occupied(c.x, c.y):
					return c
	return Vector3i(-999, -999, -999)

static func Vector3_to_v2(p: Vector3i) -> Vector2:
	return Vector2(p.x, p.y)

func _draw() -> void:
	var t := float(WorldGen.TILE_PX)
	var font: Font = ThemeDB.fallback_font
	for n in defs:
		var pos: Vector3i = n["pos"]
		if pos.z != int(player.grid.z):
			continue
		var base := Vector2(pos.x, pos.y) * t
		var cx: float = base.x + t / 2.0
		# shadow + robed body with role color sash
		var sh := PackedVector2Array()
		for i in range(16):
			var a: float = TAU * float(i) / 16.0
			sh.append(Vector2(cx, base.y + t * 0.8) + Vector2(cos(a) * t * 0.3, sin(a) * t * 0.12))
		draw_colored_polygon(sh, Color(0, 0, 0, 0.35))
		var bw: float = t * 0.6
		var bh: float = t * 0.68
		draw_rect(Rect2(base.x + (t - bw) / 2.0 - 3, base.y + t * 0.12 - 3, bw + 6, bh + 6), Color(0, 0, 0, 0.85))
		draw_rect(Rect2(base.x + (t - bw) / 2.0, base.y + t * 0.12, bw, bh), Color(0.92, 0.9, 0.84))
		draw_rect(Rect2(base.x + (t - bw) / 2.0, base.y + t * 0.12 + bh * 0.55, bw, bh * 0.45), n["color"])
		# attention pip + name (blue, centered on the tile)
		draw_circle(Vector2(cx, base.y + t * 0.02), 7.0, Color(1, 0.82, 0.4))
		var nname := String(n["name"])
		var nsize := maxi(10, int(t * 0.2))
		var nw: float = font.get_string_size(nname, HORIZONTAL_ALIGNMENT_LEFT, -1, nsize).x
		var npos := Vector2(cx - nw / 2.0, base.y - t * 0.12)
		draw_string_outline(font, npos, nname, HORIZONTAL_ALIGNMENT_LEFT, -1, nsize, 3, Color(0, 0, 0, 0.7))
		draw_string(font, npos, nname, HORIZONTAL_ALIGNMENT_LEFT, -1, nsize, Color(0.45, 0.68, 1.0))

func _process(_delta: float) -> void:
	queue_redraw()
