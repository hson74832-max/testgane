class_name PlayerState
extends Resource
## ALL serializable player state in one Resource: identity, progression,
## vitals, vocation, world position. PlayerGrid holds an instance (the body /
## view) and forwards property access to it, so the rest of the game keeps
## using player.get(...)/player.set(...) unchanged.
##
## Every numeric setter VALIDATES — no negative HP, no gold overflow, level
## capped, grid non-negative — and emits its change signal, so observers
## (StatusBar, HUD) and any future save/sync path see one canonical structure.
## Note: statuses/cooldowns/skills are mutated in place by the sim (setter
## validation fires on replacement, not per-key writes).

signal player_hp_changed(hp: int, max_hp: int)
signal player_mana_changed(mana: int, max_mana: int)
signal player_xp_changed(xp: int, level: int)
signal player_gold_changed(gold: int)
signal player_gear_changed(armor: int, heavy: int, weapon_damage: int)
signal vocation_changed(key: String)

const Constants := preload("res://scripts/core/constants.gd")

# --- identity / progression ---------------------------------------------------
## Character path; validated against the vocation table (bogus -> unchanged).
@export var vocation: String = "warrior":
	set(value):
		var key := String(value)
		if (GameBalance.VOCATIONS as Dictionary).has(key):
			vocation = key
		vocation_changed.emit(vocation)
@export var level: int = 1:
	set(value):
		level = clampi(int(value), 1, Constants.MAX_LEVEL)
		player_xp_changed.emit(xp, level)
@export var xp: int = 0:
	set(value):
		xp = clampi(int(value), 0, Constants.XP_MAX)
		player_xp_changed.emit(xp, level)
@export var gold: int = 50:
	set(value):
		gold = clampi(int(value), 0, Constants.GOLD_MAX)
		player_gold_changed.emit(gold)
@export var kills: int = 0:
	set(value):
		kills = maxi(int(value), 0)
@export var deaths: int = 0:
	set(value):
		deaths = maxi(int(value), 0)
@export var skill_points: int = 0:
	set(value):
		skill_points = maxi(int(value), 0)
## skill key -> rank. Ranks are capped at spend time (GameBalance.SKILLS.max).
@export var skills: Dictionary = {}:
	set(value):
		if value is Dictionary:
			skills = value
## Mirrors skills["swift"] for step cadence (Swiftness).
@export var swift: int = 0:
	set(value):
		swift = maxi(int(value), 0)

# --- vitals ---------------------------------------------------------------------
@export var hp: int = 120:
	set(value):
		hp = clampi(int(value), 0, maxi(1, max_hp))
		player_hp_changed.emit(hp, max_hp)
@export var max_hp: int = 120:
	set(value):
		max_hp = maxi(int(value), 1)
		player_hp_changed.emit(hp, max_hp)
@export var mana: int = 60:
	set(value):
		mana = clampi(int(value), 0, maxi(1, max_mana))
		player_mana_changed.emit(mana, max_mana)
@export var max_mana: int = 60:
	set(value):
		max_mana = maxi(int(value), 1)
		player_mana_changed.emit(mana, max_mana)
@export var ward_hp: int = 0:
	set(value):
		ward_hp = maxi(int(value), 0)
## Active status rows: {key, until, next_tick, power}.
@export var statuses: Array = []:
	set(value):
		if value is Array:
			statuses = value

# --- gear (flat sums, recalculated by LootSystem) --------------------------------
@export var armor: int = 3:
	set(value):
		armor = maxi(int(value), 0)
		player_gear_changed.emit(armor, heavy, weapon_damage)
@export var weapon_damage: int = 3:
	set(value):
		weapon_damage = maxi(int(value), 0)
		player_gear_changed.emit(armor, heavy, weapon_damage)
@export var heavy: int = 2:
	set(value):
		heavy = maxi(int(value), 0)
		player_gear_changed.emit(armor, heavy, weapon_damage)

# --- combat clocks / flags (msec timestamps; validated non-negative) -----------
@export var dead: bool = false
@export var dead_until: int = 0:
	set(value):
		dead_until = maxi(int(value), 0)
@export var push_ready_at: int = 0:
	set(value):
		push_ready_at = maxi(int(value), 0)
@export var cast_until: int = 0:
	set(value):
		cast_until = maxi(int(value), 0)
@export var hit_flash_until: int = 0:
	set(value):
		hit_flash_until = maxi(int(value), 0)
@export var slowed: bool = false
## ability key -> ready_at msec.
@export var cooldowns: Dictionary = {}:
	set(value):
		if value is Dictionary:
			cooldowns = value

# --- world position ----------------------------------------------------------------
## Tibia-style triple: x, y on the floor, z is the floor itself.
@export var grid: Vector3i = Vector3i(20, 35, 0):
	set(value):
		grid = Vector3i(maxi(value.x, 0), maxi(value.y, 0), clampi(value.z, 0, Constants.MAX_FLOOR_INDEX))
## Facing unit (-1..1 per axis).
@export var facing: Vector2i = Vector2i(0, 1):
	set(value):
		facing = Vector2i(clampi(value.x, -1, 1), clampi(value.y, -1, 1))
