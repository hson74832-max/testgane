# BlackTek local chat: range-scoped delivery + say/spell/NPC dispatch.
# Stateless — players, scripts and signals live on the game server.
# Radius defaults to the tuned say_range (was BlackTekNpc.SAY_RANGE).
class_name BlackTekChat
extends RefCounted

static func say_to_range(game, center: Vector2i, z: int, sender: String, text: String, radius := -1) -> void:
	var r: int = radius if radius >= 0 else game.config.tune_int("say_range")
	for opid in (game.players as Dictionary).keys():
		var o: Dictionary = (game.players as Dictionary)[opid]
		if int(o.z) != z:
			continue
		if maxi(absi(int(o.tile.x) - center.x), absi(int(o.tile.y) - center.y)) > r:
			continue
		game.chat_heard.emit(int(opid), sender, text)

static func request_say(game, pid: int, text: String) -> void:
	if not (game.players as Dictionary).has(pid):
		return
	var p: Dictionary = (game.players as Dictionary)[pid]
	say_to_range(game, p.tile, int(p.z), String(p.name), text)
	if (game.scripts as BlackTekActionScripts).handle_talk(game, pid, text):
		return
	if (game.scripts as BlackTekActionScripts).cast_spell(game, pid, text):
		return
	BlackTekNpc.handle_dialogue(game, pid, text.strip_edges().to_lower())
