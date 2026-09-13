extends RefCounted
## CombatBalance — combat formulas, cooldowns and combat-facing content.
## Slice of GameBalance (which owns content.json loading and the public API):
##   COMBAT          every combat tuning knob (cooldowns, crit, regen, leash...)
##   ABILITIES       the cast pipeline rows (shape/damage/mana/cooldown)
##   VOCATIONS       path multipliers + tick kit (camelCase normalized here)
##   SKILLS          per-rank effects for the skill tree
## Web owns the numbers (testttt/src/lib/game/content.ts); this module owns
## the Godot-side copy once load_content() has normalized it.

## Combat tuning. Defaults match content.json balance.COMBAT; overridden at
## load. Keys are shared with the web build — keep both sides in step.
var COMBAT: Dictionary = {
	"AUTO_ATTACK_MS": 2000,
	"BASE_STEP_MS": 205,
	"MS_PER_HEAVY": 5,
	"MAX_STEP_PENALTY_MS": 90,
	"MIN_DAMAGE": 1,
	"PUSH_CD_MS": 2500,
	"LOOT_PROTECT_MS": 60000,
	"GROUND_DECAY_MS": 180000,
	"STEP_MIN_MS": 120,
	"STEP_DIAGONAL_MULT": 1.4,
	"STEP_SLOW_MULT": 1.6,
	"ROOT_MS": 1200,
	"REGEN_MS": 1400,
	"REGEN_HP_BASE": 1,
	"REGEN_HP_DIV": 3,
	"REGEN_MANA_BASE": 2,
	"REGEN_MANA_DIV": 2,
	"CRIT_CHANCE": 0.14,
	"CRIT_MULT": 1.85,
	"WARD_BASE": 45,
	"WARD_PER_LEVEL": 5,
	"WARD_PER_RANK": 10,
	"WARD_MS": 6000,
	"STATUS_MS": 6000,
	"STATUS_TICK_MS": 1500,
	"POISON_POWER": 4,
	"BURN_POWER": 6,
	"XP_LOSS_PCT": 0.1,
	"GOLD_DROP_PCT": 0.5,
	"RESPAWN_MS": 2600,
	"MAX_MONSTERS": 34,
	"CRYPT_MONSTERS": 8,
	"RIVAL_MARK_CHANCE": 0.14,
	"RIVAL_MARK_MIN": 0.3,
	"RIVAL_MARK_SPREAD": 0.3,
	"SENSE_JITTER": 1,
	"SENSE_MIN": 2,
	"SENSE_MAX": 9,
	"DEAGGRO_TILES": 4,
	"AGGRO_REACT_MS": 120,
	"MOB_HEAL_MS": 1500,
	"MOB_HEAL_DIV": 20,
}
var ABILITIES: Array = []
var VOCATION_ORDER: Array = []
var VOCATIONS: Dictionary = {}
var SKILL_ORDER: Array = []
var SKILLS: Dictionary = {}

## Pull the combat slice out of the parsed content.json root.
func load_content(parsed: Dictionary) -> void:
	ABILITIES = parsed.get("abilities", [])
	VOCATION_ORDER = parsed.get("vocationOrder", [])
	# Normalize TS camelCase to GDScript snake_case once, at the boundary.
	VOCATIONS = {}
	for vkey in (parsed.get("vocations", {}) as Dictionary).keys():
		var v: Dictionary = (parsed["vocations"] as Dictionary)[vkey]
		VOCATIONS[String(vkey)] = {
			"key": String(vkey),
			"name": String(v.get("name", vkey)),
			"blurb": String(v.get("blurb", "")),
			"hp_mult": float(v.get("hpMult", 1.0)),
			"mana_mult": float(v.get("manaMult", 1.0)),
			"tick_range": int(v.get("tickRange", 1)),
			"tick_base": int(v.get("tickBase", 6)),
			"tick_scale": float(v.get("tickScale", 0.9)),
			"tick_shot": bool(v.get("tickShot", false)),
			"melee_mult": float(v.get("meleeMult", 1.0)),
			"spell_mult": float(v.get("spellMult", 1.0)),
		}
	SKILL_ORDER = parsed.get("skillOrder", [])
	SKILLS = parsed.get("skills", {})
	var bal: Dictionary = parsed.get("balance", {})
	if bal.has("COMBAT"):
		for k in (bal["COMBAT"] as Dictionary).keys():
			COMBAT[k] = (bal["COMBAT"] as Dictionary)[k]

# --- formulas, 1:1 with testttt/src/lib/game/content.ts ---

func mitigate(raw: int, armor: int) -> int:
	return maxi(int(COMBAT.get("MIN_DAMAGE", 1)), raw - armor)

func xp_for_level(level: int) -> int:
	return int(floor(60.0 * pow(float(level), 1.85)))

func level_from_xp(xp: int) -> int:
	var lvl := 1
	while lvl < 60 and xp >= xp_for_level(lvl):
		lvl += 1
	return lvl

func stats_for_level(level: int) -> Dictionary:
	return {
		"maxHp": 100 + level * 20,
		"maxMana": 45 + level * 15,
		"damageBonus": int(floor(float(level) * 1.6)),
	}

func step_ms_for(heavy: int) -> int:
	var base := int(COMBAT.get("BASE_STEP_MS", 205))
	var per := int(COMBAT.get("MS_PER_HEAVY", 5))
	var cap := int(COMBAT.get("MAX_STEP_PENALTY_MS", 90))
	return base + mini(cap, heavy * per)

func auto_attack_ms() -> int:
	return int(COMBAT.get("AUTO_ATTACK_MS", 2000))
