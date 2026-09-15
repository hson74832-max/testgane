# BlackTek day/night cycle: ambient darkness + torch glow driver.
# State (day_ambient/day_time) lives on the game server; step logic here so it
# is unit-testable without a full server (pass a dict-like game or server).
# Tuning (day_cycle/day_min/day_min_surface/day_start) comes from
# data/gameplay.toml. Surface floors (z<=7) bottom out at day_min_surface so
# aboveground nights stay readable; underground keeps full day_min darkness.
class_name BlackTekDayCycle
extends RefCounted

static func set_ambient(game, a: float) -> void:
	var cycle: float = game.config.tune("day_cycle")
	# Pin the cycle: /day jumps to noon, /night to midnight; ambient fades there.
	game.day_time = 0.0 if a >= 0.6 else cycle / 2.0
	game.message_local(1, "Ambient light: %d%%" % int(a * 100.0))

# Effective midnight floor for the current floor (surface vs underground).
static func night_min(game) -> float:
	if int(game.demo_z) <= 7:
		return game.config.tune("day_min_surface")
	return game.config.tune("day_min")

static func tick(game, delta: float) -> void:
	var cycle: float = game.config.tune("day_cycle")
	var floor_a: float = night_min(game)
	game.day_time = fmod(float(game.day_time) + delta, cycle)
	var phase: float = float(game.day_time) / cycle * TAU
	var target: float = floor_a + (1.0 - floor_a) * (0.5 + 0.5 * cos(phase)) # noon 1.0, midnight floor
	game.day_ambient = lerpf(float(game.day_ambient), target, minf(1.0, delta * 0.4))
