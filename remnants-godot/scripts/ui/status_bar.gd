extends RefCounted
## StatusBar — vitals observer. Listens to PlayerGrid's stat signals
## (player_hp_changed / player_mana_changed / player_xp_changed) and paints
## the three bars: no polling. Every writer mutates stats through property
## setters on PlayerGrid, which emit — so any future source of damage,
## healing or xp updates this bar with zero HUD code.
## HUD rebuilds (resize) recreate the bars; observe() connects only once and
## handlers read the current refs, then hud calls refresh_all() after rebuild.

var hp_bar: ProgressBar
var mp_bar: ProgressBar
var xp_bar: ProgressBar
var _player: PlayerGrid = null

func build(make_bar: Callable) -> void:
	hp_bar = make_bar.call(Color(0.85, 0.25, 0.32), 12)
	mp_bar = make_bar.call(Color(0.25, 0.6, 0.95), 9)
	xp_bar = make_bar.call(Color(0.65, 0.9, 0.25), 5)

## Wire once; survives HUD rebuilds because handlers read current refs.
func observe(p: PlayerGrid) -> void:
	_player = p
	p.player_hp_changed.connect(_on_hp)
	p.player_mana_changed.connect(_on_mana)
	p.player_xp_changed.connect(_on_xp)
	refresh_all()

## Initial paint (and re-paint after a HUD rebuild).
func refresh_all() -> void:
	if _player == null or hp_bar == null:
		return
	_on_hp(int(_player.get("hp")), int(_player.get("max_hp")))
	_on_mana(int(_player.get("mana")), int(_player.get("max_mana")))
	_on_xp(int(_player.get("xp")), int(_player.get("level")))

func _on_hp(hp: int, max_hp: int) -> void:
	if hp_bar == null:
		return
	hp_bar.max_value = maxi(1, max_hp)
	hp_bar.value = maxi(0, hp)

func _on_mana(mana: int, max_mana: int) -> void:
	if mp_bar == null:
		return
	mp_bar.max_value = maxi(1, max_mana)
	mp_bar.value = maxi(0, mana)

func _on_xp(xp: int, level: int) -> void:
	if xp_bar == null:
		return
	var prev: int = GameBalance.xp_for_level(maxi(1, level - 1)) if level > 1 else 0
	var next: int = GameBalance.xp_for_level(level)
	var span := maxi(1, next - prev)
	xp_bar.max_value = span
	xp_bar.value = clampi(xp - prev, 0, span)
