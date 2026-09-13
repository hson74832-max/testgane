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

# --- caps (PlayerState setters enforce these) --------------------------------
const MAX_LEVEL: int = 60            # matches CombatBalance.level_from_xp loop
const GOLD_MAX: int = 99_999_999     # purse overflow guard
const XP_MAX: int = 2_000_000_000    # xp keeps counting past level 60, capped
const MAX_FLOOR_INDEX: int = 16      # z is the floor index; generous ceiling

# --- combat feel / timing (code constants; content.json owns BALANCE numbers)
const HIT_FLASH_MS: int = 160        # monster body flashes white when hit
const PLAYER_HIT_FLASH_MS: int = 220
const CORPSE_FADE_MS: int = 320      # dying body fades, then despawns
const ARROW_FLY_MS: int = 150        # archer tick projectile lifetime
const BOLT_TRAVEL_EXTRA_MS: int = 120  # beam resolve lags the visual
const PUSH_LOCK_MS: int = 1200       # shoved body braces against re-shoves
const PUSH_MOVE_LOCK_MS: int = 350   # shoved body pauses before it moves
const STEP_RETRY_MS: int = 120       # blocked step: retry cadence
const SPAWN_ATTEMPTS: int = 40       # random placement tries per spawn
const SPAWN_MIN_DIST_TILES: int = 9  # live top-ups never spawn this close
const NO_PATH_DIST: int = 999999     # "no candidate" sentinel in chase steps
const LOOT_REACH_TILES: int = 1      # pickup/tap range from the player tile
const MARK_RANGE_TILES: int = 6      # cycle-target scan radius
const BAR_RANGE_TILES: int = 3      # hp bar shown within this distance

# --- presentation -------------------------------------------------------------
const CAMERA_SNAP_TILES: float = 8.0   # follow distance that snaps, not glides
const RENDER_LERP_MONSTER_S: float = 0.11  # render lerp: dt/k, web parity
const RENDER_LERP_PLAYER_S: float = 0.09
const MIN_VIEW_TILES: int = 24         # cull-window fallback without a camera
const VIEW_HYSTERESIS_TILES: int = 2   # mark clipping + window padding
const FLOAT_TTL_MS: int = 1100         # combat float text lifetime
const FLOAT_MAX: int = 40              # ring buffer cap
const CHAT_VISIBLE_MS: int = 6000      # panel fade + speech float lifetime
const TOAST_VISIBLE_MS: int = 2600
const JOYSTICK_RANGE_PX: float = 52.0  # thumb drag distance -> full stick
const TOUCH_STICK_ZONE: float = 0.45   # left screen fraction = stick region
const STICK_DEADZONE: float = 0.25     # quantize threshold (8-way snap)
const GATE_SLIDE_RADIUS: int = 4       # gate arrival search around the pad
const COUNTER_SLIDE_RADIUS: int = 4    # ferry landing search around the stop
const SYNC_PERIOD_S: float = 5.0       # dev WebSync push cadence
const LOOT_QUEUE_MAX: int = 50         # WebSync queued loot lines
