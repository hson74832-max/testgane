class_name Monster
extends Node2D
## Data + view for one creature. This is a data container: it has NO
## _process/_physics_process. Behavior is centralized in AISystem
## (scripts/combat/systems/ai_system.gd — one loop over live, same-floor
## monsters), the central tick drives sync_pos, and _draw only fires on a
## dirty repaint (idle bodies stop redrawing entirely). State the systems
## read (grid/hp/aggro/...) is shared, not per-instance logic.
## Mirrors engine.ts Monster fields (trimmed: no mob statuses in Phase 2).

const Constants := preload("res://scripts/core/constants.gd")

var mid: int = 0
var def_key: String = "rat"
var def: Dictionary = {}
var grid: Vector3i = Vector3i.ZERO
var render: Vector2 = Vector2.ZERO
var hp: int = 26
var max_hp: int = 26
## HP at spawn: ~14% of spawns arrive pre-damaged by rivals. The bar must not
## be permanent for them — it appears only below spawn HP (real new damage).
var spawn_hp: int = 26
var aggro: bool = false
var next_move_at: int = 0
var next_attack_at: int = 0
var windup_until: int = 0
var hit_flash_until: int = 0
var dying_at: int = 0  # 0 = alive, else msec timestamp
var damage_by: Dictionary = {}
var push_lock_until: int = 0
## Out-of-combat healing clock (Tibia-like: disengage and wounds close).
var next_heal_at: int = 0
## Per-individual sense radius: base aggroRange ± 1, so packs don't sync-aggro.
var sense: int = 4
## Last player cell this creature aimed at. Ranged types reposition when the
## target sidesteps instead of recasting at stale ground.
var last_seen := Vector3i(-999, -999, -999)
## Set by AISystem each tick: marked, within 3 tiles, (or damaged below).
var show_bar := false
## Dirty-repaint ledger: what the last _draw painted. sync_pos compares and
## only queue_redraw()s when something visible changed (motion, fade, flash,
## wind-up swell, hp, bar visibility) — idle creatures cost one branch/frame.
var _drawn_hp := -1
var _drawn_bar := false
var _drawn_flash := false
var _drawn_winding := false
var _drawn_dying := false

func setup(p_mid: int, p_key: String, p_def: Dictionary, p_grid: Vector3i, p_hp: int, p_damage_by: Dictionary) -> void:
	mid = p_mid
	def_key = p_key
	def = p_def
	grid = p_grid
	render = Vector2(p_grid.x, p_grid.y)
	hp = p_hp
	spawn_hp = p_hp
	max_hp = int(p_def.get("hp", 26))
	damage_by = p_damage_by.duplicate()
	position = render * float(WorldGen.TILE_PX)
	z_index = 0

func is_alive() -> bool:
	return dying_at == 0

func is_dying(now: int) -> bool:
	return dying_at != 0 and now - dying_at < 320

## View sync, driven by the central tick (CombatSim._physics_process). The
## render position lerps toward the grid cell and snaps once converged, then
## the body stops repainting until something visible changes again.
func sync_pos(delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	var target := Vector2(grid.x, grid.y)
	var moving := render.distance_squared_to(target) > 0.0001
	if moving:
		var k: float = minf(1.0, delta / Constants.RENDER_LERP_MONSTER_S)
		render = render.lerp(target, k)
		if render.distance_squared_to(target) <= 0.0001:
			render = target  # snap: no sub-pixel drift, the lerp can stop
		position = render * float(WorldGen.TILE_PX)
	var flash_on: bool = now < hit_flash_until
	var winding: bool = now < windup_until
	var dirty := moving \
		or (dying_at != 0 and now - dying_at < Constants.CORPSE_FADE_MS) \
		or flash_on or winding \
		or hp != _drawn_hp or show_bar != _drawn_bar \
		or flash_on != _drawn_flash or winding != _drawn_winding \
		or (dying_at != 0) != _drawn_dying
	if dirty:
		queue_redraw()
		_drawn_hp = hp
		_drawn_bar = show_bar
		_drawn_flash = flash_on
		_drawn_winding = winding
		_drawn_dying = dying_at != 0

func body_color() -> Color:
	return Color.html(String(def.get("color", "#a98467")))

func _draw() -> void:
	var now: int = Time.get_ticks_msec()
	var t := float(WorldGen.TILE_PX)
	if dying_at != 0:
		var d: float = clampf(float(now - dying_at) / 320.0, 0.0, 1.0)
		if d >= 1.0:
			return
		modulate.a = 1.0 - d
	# shadow
	var sh := PackedVector2Array()
	for i in range(20):
		var a: float = TAU * float(i) / 20.0
		sh.append(Vector2(t / 2.0, t * 0.78) + Vector2(cos(a) * t * 0.30, sin(a) * t * 0.13))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.35))
	# windup swell (readability: creature grows as floor fills)
	var scale_f := 1.0
	if now < windup_until:
		var windup: float = maxf(1.0, float(def.get("windup", 600)))
		scale_f = 1.0 + sin((float(now) / windup) * PI) * 0.12
	var bw: float = t * 0.62 * scale_f
	var bh: float = t * 0.62 * scale_f
	var bx: float = (t - bw) / 2.0
	var by: float = t * 0.16
	draw_rect(Rect2(bx - 3, by - 3, bw + 6, bh + 6), Color(0, 0, 0, 0.85))
	var col: Color = Color.WHITE if now < hit_flash_until else body_color()
	draw_rect(Rect2(bx, by, bw, bh), col)
	draw_rect(Rect2(bx + 4, by + 4, bw - 8, bh * 0.3), Color(1, 1, 1, 0.22))
	# hp bar: fresh damage below spawn HP, marked, or close enough to read (3 tiles).
	# Fill tiers: green at full, yellow under 50%, red under 25%, dark red under 10%.
	if hp < mini(max_hp, spawn_hp) or show_bar:
		var w: float = t * 0.66
		var xx: float = (t - w) / 2.0
		var yy: float = by - 10.0
		var pct: float = clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
		var fill: Color
		if pct < 0.10:
			fill = Color(0.45, 0.06, 0.06)
		elif pct < 0.25:
			fill = Color(0.95, 0.25, 0.25)
		elif pct < 0.50:
			fill = Color(0.96, 0.82, 0.25)
		else:
			fill = Color(0.30, 0.82, 0.38)
		draw_rect(Rect2(xx - 1.5, yy - 1.5, w + 3, 7), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(xx, yy, w * pct, 4), fill)
		# name above the bar, tiered in the same color as the fill
		var fname := String(def.get("name", def_key))
		var fsize := maxi(9, int(t * 0.17))
		var mfont: Font = ThemeDB.fallback_font
		var name_w: float = mfont.get_string_size(fname, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		var npos := Vector2((t - name_w) / 2.0, yy - 5.0)
		draw_string_outline(mfont, npos, fname, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, 3, Color(0, 0, 0, 0.85))
		draw_string(mfont, npos, fname, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, fill)
