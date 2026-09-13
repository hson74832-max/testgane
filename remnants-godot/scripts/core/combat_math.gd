class_name CombatMath
extends RefCounted
## Pure formulas, no autoload dependency — usable in client, headless server, tests.
## Must stay 1:1 with testttt/src/lib/game/content.ts + GameBalance autoload.

static func mitigate(raw: int, armor: int, min_damage: int = 1) -> int:
	return maxi(min_damage, raw - armor)

static func xp_for_level(level: int) -> int:
	return int(floor(60.0 * pow(float(level), 1.85)))

static func level_from_xp(xp: int) -> int:
	var lvl := 1
	while lvl < 60 and xp >= xp_for_level(lvl):
		lvl += 1
	return lvl

static func stats_for_level(level: int) -> Dictionary:
	return {
		"maxHp": 100 + level * 20,
		"maxMana": 45 + level * 15,
		"damageBonus": int(floor(float(level) * 1.6)),
	}

static func step_ms_for(heavy: int, base_ms: int = 205, per_heavy: int = 5, cap_ms: int = 90) -> int:
	return base_ms + mini(cap_ms, heavy * per_heavy)

static func death_penalty(xp: int, gold: int) -> Dictionary:
	return {"xpLost": int(floor(float(xp) * 0.10)), "goldDropped": int(floor(float(gold) * 0.50))}
