extends RefCounted
## constants — the global vocabularies data and code share. The sim keeps
## string keys (web parity: content.json is the source of truth); these lists
## are the contract that scripts/tools/validator.gd enforces and the place to
## look up "what values can this field take". Keep in step with the web export.

const ITEM_KINDS: Array = ["material", "consumable", "gear", "relic"]
const RARITIES: Array = ["common", "uncommon", "rare", "epic"]
const EQUIP_SLOTS: Array = ["helmet", "amulet", "armor", "weapon", "shield", "legs", "boots", "ring"]

## Ability (spell) shapes: one executor per shape in CombatSystem.
const ABILITY_SHAPES: Array = ["adjacent", "radial", "line", "self"]
## Monster attack telegraph shapes (AISystem.telegraph_shape).
const MONSTER_SHAPES: Array = ["single", "line", "radial"]

const NPC_ROLES: Array = ["trader", "healer", "ferry"]
## Status keys the sim understands (CombatSystem.apply/damage, healer purge).
const STATUS_KEYS: Array = ["poison", "burn", "slow", "ward"]
## Skill-tree effect keys (CombatBalance._skill_bonus reads these).
const SKILL_EFFECT_KEYS: Array = ["maxHp", "maxMana", "damage", "ward", "stepMs"]

## Tile kinds WorldGen can generate (tile RULES live in WorldConfig.TILE_DEFS).
const TILE_KINDS: Array = ["grass", "brush", "path", "ash", "stone", "water", "wall", "temple", "gate"]
