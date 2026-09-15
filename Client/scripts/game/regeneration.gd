# BlackTek regeneration ticks: poison damage plus hp/mana regen per vocation
# intervals (food halves the interval, demo rule). Called from the tick.
# Vocation table comes from BlackTekConfig (data/vocations.toml).
class_name BlackTekRegen
extends RefCounted

static func vocation_regen(game, vocation: int) -> Dictionary:
	if game.get("config") != null:
		return (game.config as BlackTekConfig).vocation(vocation).regen
	return BlackTekGameServer.VOCATIONS[vocation].regen

static func tick(game, pid: int, delta: float, now: float) -> void:
	var p: Dictionary = game.players[pid]
	var fed: bool = float(p.food_until) > now
	# Poison condition: 2 damage every 2s while active.
	if float(p.get("poison_until", 0.0)) > now:
		var pt := "_poison_t"
		var ptv := float(p.get(pt, 0.0)) + delta
		if ptv >= 2.0:
			ptv = 0.0
			p.hp = maxi(0, int(p.hp) - 2)
			game.damage_float.emit(p.tile, int(p.z), 2, false)
			game.message_local(pid, "You lose 2 hitpoints (poison).")
			if int(p.hp) <= 0:
				BlackTekCombat.player_death(game, pid)
			else:
				game.stats_changed.emit(pid)
		p[pt] = ptv
	var regen: Dictionary = vocation_regen(game, int(p.vocation))
	_regen(game, p, pid, "hp", float(regen.hp[1]) / (2.0 if fed else 1.0), int(regen.hp[0]), delta)
	_regen(game, p, pid, "mana", float(regen.mana[1]) / (2.0 if fed else 1.0), int(regen.mana[0]), delta)

static func _regen(game, p: Dictionary, pid: int, which: String, interval_s: float, amount: int, delta: float) -> void:
	if interval_s <= 0.0:
		return
	var key := "_regen_t_" + which
	var t := float(p.get(key, 0.0)) + delta
	if t >= interval_s:
		t = 0.0
		if which == "hp":
			if int(p.hp) < int(p.hpmax):
				p.hp = mini(int(p.hp) + amount, int(p.hpmax))
				game.stats_changed.emit(pid)
		else:
			if int(p.mana) < int(p.manamax):
				p.mana = mini(int(p.mana) + amount, int(p.manamax))
				game.stats_changed.emit(pid)
	p[key] = t
