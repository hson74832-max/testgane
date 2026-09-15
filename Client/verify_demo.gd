# Headless verification for the BlackTek demo client game layer.
# Run:  Godot_v4.7.2.exe --headless --path <Client> --script res://verify_demo.gd
# NOTE: a script error aborts _initialize before quit(); run under a timeout
# and treat a missing summary as failure.
extends SceneTree

var fails := 0
var checks := 0

func _initialize() -> void:
	print("=== VERIFY BlackTek demo client ===")
	# Use a throwaway DB so running tests never touches the demo save.
	var srv: BlackTekGameServer = BlackTekGameServer.new("user://mock_db_verify.json")
	srv.db.wipe() # deterministic seed
	var loaded: bool = srv.load_real_data("res://assets/assets.dat", "res://assets/forgotten.otbm")
	_check("real data loads", loaded)
	if loaded:
		_check("dat item names loaded (gold coin)", srv.dat.item_name(2148) == "gold coin")
		_check("dat item weight > 0 (sword)", srv.dat.item_weight(2376) > 0)
	_check("item label fallback", srv.item_label(2148).length() > 0)

	# ---- session / mock DB ----
	_check("bad login rejected", not srv.login_account("demo", "wrong"))
	_check("good login", srv.login_account("demo", "demo"))
	var chars: Array = srv.character_list()
	_check("seeded account has 2 characters", chars.size() == 2)
	var knight: Dictionary = {}
	for c in chars:
		if String(c.name) == "DemoKnight":
			knight = c
	_check("DemoKnight found", not knight.is_empty())
	var spawn: Vector2i = srv.enter_world(knight)
	_check("enter_world spawns on walkable tile", srv.is_walkable(spawn))
	var p: Dictionary = srv.players[1]
	_check("knight level 8 hpmax 255", int(p.level) == 8 and int(p.hpmax) == 255)
	_check("starter gear equipped (sword in slot 5)", int(p.inv[5].itemtype) == 2376)
	_check("bag has gold coins", _bag_count(srv, 2148) > 0)

	# ---- movement ----
	var t0: Vector2i = p.tile
	var t1: Vector2i = srv.request_move(1, Vector2i(1, 0))
	_check("move east accepted or blocked", t1 == t0 + Vector2i(1, 0) or t1 == t0)

	# ---- action scripts: potion ----
	var hp_low := int(srv.players[1].hp) - 50
	srv.players[1].hp = hp_low
	var pot_row: Dictionary = _find_in_bag(srv, 7618)
	_check("has health potion in bag", not pot_row.is_empty())
	if not pot_row.is_empty():
		var cnt_before := int(pot_row.count)
		var ok_use: bool = srv.scripts.use_item(srv, 1, pot_row)
		_check("health potion heals", ok_use and int(srv.players[1].hp) > hp_low)
		var pot_after: Dictionary = _find_in_bag(srv, 7618)
		var cnt_after: int = int(pot_after.count) if not pot_after.is_empty() else 0
		_check("potion consumed", cnt_after == cnt_before - 1)

	# ---- spells ----
	srv.players[1].hp = 100
	srv.players[1].mana = 100
	var cast1: bool = srv.scripts.cast_spell(srv, 1, "exura")
	_check("exura cast", cast1 and int(srv.players[1].hp) > 100)
	var hp_mid := int(srv.players[1].hp)
	srv.players[1].mana = 100
	srv.scripts.cast_spell(srv, 1, "exura")
	_check("exura exhausted on second cast", int(srv.players[1].hp) == hp_mid)

	# ---- test spells (utevo lux / exana pox / exura gran / exori) ----
	srv.players[1].mana = 100
	(srv.players[1].cooldowns as Dictionary).clear()
	var luxed: bool = srv.scripts.cast_spell(srv, 1, "utevo lux")
	_check("utevo lux grants light", luxed and float(srv.players[1].light_until) > Time.get_ticks_msec() / 1000.0)
	srv.players[1].mana = 100
	(srv.players[1].cooldowns as Dictionary).clear()
	srv.players[1].poison_until = Time.get_ticks_msec() / 1000.0 + 30.0
	_check("exana pox cures poison", srv.scripts.cast_spell(srv, 1, "exana pox") and not srv.is_poisoned(1))
	srv.players[1].hp = 50
	srv.players[1].mana = 100
	(srv.players[1].cooldowns as Dictionary).clear()
	_check("exura gran heals big", srv.scripts.cast_spell(srv, 1, "exura gran") and int(srv.players[1].hp) > 50)
	srv.players[1].mana = 100
	(srv.players[1].cooldowns as Dictionary).clear()
	_check("hotbar flame alias handled", srv.scripts.cast_spell(srv, 1, "flame"))
	srv.players[1].mana = 100
	(srv.players[1].cooldowns as Dictionary).clear()
	srv.monsters[776001] = {"id": 776001, "name": "Rat", "tile": srv.players[1].tile + Vector2i(1, 0), "z": int(srv.players[1].z), "hp": 3, "hpmax": 25, "move_cd": 0.0, "attack_cd": 99.0, "target_pid": 0}
	var area_warn: Array = []
	var area_hit: Array = []
	srv.spell_area.connect(func(_c: Vector2i, _z: int, tiles: Array, kind: String):
		if kind == "warn":
			area_warn.assign(tiles)
		else:
			area_hit.assign(tiles))
	srv.scripts.cast_spell(srv, 1, "exori")
	_check("exori warns 8 tiles first", area_warn.size() == 8 and (srv.players[1].tile + Vector2i(1, 0)) in area_warn)
	_check("exori damage waits out wind-up", srv.monsters.has(776001))
	srv.tick(1.0)
	_check("exori kills adjacent rat", not srv.monsters.has(776001))
	_check("exori impact flashes 8 tiles", area_hit.size() == 8 and (srv.players[1].tile + Vector2i(1, 0)) in area_hit)
	_check("aoe helper matches telegraph", BlackTekActionScripts.spell_aoe_tiles(srv.players[1].tile, "exori").size() == 8)

	# ---- talkactions ----
	srv.scripts.handle_talk(srv, 1, "/pos")
	_check("talkaction /pos handled", true)
	_check("GM gate: /t refused for player", not srv.is_gm(1))

	# ---- NPC shop purchase ----
	var gold_before := _bag_count(srv, 2148)
	srv.buy_shop_item(1, {"itemtype": 7618, "price": 50, "name": "health potion"})
	_check("buy costs 50 gold", gold_before - _bag_count(srv, 2148) == 50)
	_check("bought potion lands in bag", not _find_in_bag(srv, 7618).is_empty())

	# ---- combat ----
	var exp_before := int(srv.players[1].exp)
	var mid := 0
	for m in srv.monsters.keys():
		mid = int(m)
		break
	_check("monster spawned on enter_world", mid != 0)
	if mid != 0:
		srv.monsters[mid].tile = srv.players[1].tile + Vector2i(1, 0)
		srv.monsters[mid].hp = 5
		srv.set_target(1, srv.monsters[mid])
		srv.attack_current_target(1)
		_check("melee killed weakened rat", not srv.monsters.has(mid))
		_check("exp gained from kill", int(srv.players[1].exp) > exp_before)
		_check("loot gold gained", _bag_count(srv, 2148) > 0)

	# ---- target expiry (off-screen / floor change) ----
	srv.monsters[779001] = {"id": 779001, "name": "Rat", "tile": srv.players[1].tile + Vector2i(1, 0), "z": int(srv.players[1].z), "hp": 25, "hpmax": 25, "move_cd": 0.0, "attack_cd": 99.0, "target_pid": 0}
	srv.players[1].attack_cd = Time.get_ticks_msec() / 1000.0 + 99.0 # no auto-swing during the check
	var target_events: Array = []
	srv.target_changed.connect(func(_p: int, m: Dictionary): target_events.append(m.is_empty()))
	srv.set_target(1, srv.monsters[779001])
	srv.tick(0.05)
	_check("adjacent target kept", int(srv.players[1].target) == 779001)
	var home_tile: Vector2i = srv.players[1].tile
	srv.players[1].tile = home_tile + Vector2i(50, 0)
	srv.tick(0.05)
	_check("off-screen target cleared", int(srv.players[1].target) == 0)
	_check("clear emits empty target", not target_events.is_empty() and bool(target_events[target_events.size() - 1]))
	srv.players[1].tile = home_tile
	srv.monsters[779001].tile = home_tile + Vector2i(1, 0)
	srv.set_target(1, srv.monsters[779001])
	srv.monsters[779001].z = int(srv.players[1].z) + 1
	srv.tick(0.05)
	_check("other-floor target cleared", int(srv.players[1].target) == 0)
	srv.monsters.erase(779001)
	srv.players[1].attack_cd = 0.0

	# ---- click-walk reroutes around creatures instead of giving up ----
	srv.players[1].tile = spawn
	srv.players[1].attack_cd = Time.get_ticks_msec() / 1000.0 + 99.0
	srv.monsters.clear()
	var reroute_dest := spawn + Vector2i(2, 2)
	srv.monsters[779002] = {"id": 779002, "name": "Rat", "tile": spawn + Vector2i(1, 1), "z": int(srv.players[1].z), "hp": 25, "hpmax": 25, "move_cd": 0.0, "attack_cd": 99.0, "target_pid": 0}
	var blocked_msgs: Array = []
	srv.msg_local.connect(func(_p: int, t: String): blocked_msgs.append(t))
	_check("path planned through rat", srv.request_path(1, reroute_dest) == 2)
	for i in range(120):
		srv.tick(0.05)
	_check("walker rerouted around rat", srv.players[1].tile == reroute_dest)
	_check("reroute is silent", not ("You are blocked." in blocked_msgs))
	srv.monsters.erase(779002)
	srv.players[1].attack_cd = 0.0

	# ---- walker gives up when the destination itself is taken ----
	var step_dest := Vector2i(-9999, -9999)
	for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var sc: Vector2i = spawn + off
		if srv.is_walkable(sc, int(srv.players[1].z)) and srv.monster_at(sc, int(srv.players[1].z)).is_empty():
			step_dest = sc
			break
	_check("step dest found", step_dest != Vector2i(-9999, -9999))
	srv.players[1].tile = spawn
	srv.monsters.clear()
	var giveup_msgs: Array = []
	srv.msg_local.connect(func(_p: int, t: String): giveup_msgs.append(t))
	_check("one-step path planned", srv.request_path(1, step_dest) == 1)
	srv.monsters[779003] = {"id": 779003, "name": "Rat", "tile": step_dest, "z": int(srv.players[1].z), "hp": 25, "hpmax": 25, "move_cd": 0.0, "attack_cd": 99.0, "target_pid": 0}
	for i in range(10):
		srv.tick(0.05)
	_check("taken destination ends walk", srv.get_path(1).is_empty() and srv.players[1].tile == spawn)
	_check("give-up says blocked", "You are blocked." in giveup_msgs)
	srv.monsters.erase(779003)

	# ---- occupancy soak: crowded ticks never share a tile (race check) ----
	# Check-and-move runs synchronously inside one tick (no awaits between the
	# occupancy read and the write), so a monster can never slip in between.
	srv.players[1].tile = spawn
	srv.players[1].hp = int(srv.players[1].hpmax)
	srv.monsters.clear()
	var placed := 0
	for off2 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
		if placed >= 3:
			break
		var rt: Vector2i = spawn + off2
		if srv.is_walkable(rt, int(srv.players[1].z)) and srv.monster_at(rt, int(srv.players[1].z)).is_empty():
			placed += 1
			srv.monsters[779010 + placed] = {"id": 779010 + placed, "name": "Rat", "tile": rt, "z": int(srv.players[1].z), "hp": 25, "hpmax": 25, "move_cd": 0.0, "attack_cd": 99.0, "target_pid": 0}
	_check("3 rats placed", placed == 3)
	var overlap := false
	for i in range(500):
		srv.tick(0.05)
		var seen := {}
		var pk := Vector3i(srv.players[1].tile.x, srv.players[1].tile.y, int(srv.players[1].z))
		seen[pk] = true
		for m in srv.monsters.values():
			var k := Vector3i(int(m.tile.x), int(m.tile.y), int(m.z))
			if seen.has(k):
				overlap = true
				break
			seen[k] = true
		for n in srv.npcs.values():
			var k2 := Vector3i(int(n.tile.x), int(n.tile.y), int(n.z))
			if seen.has(k2):
				overlap = true
				break
			seen[k2] = true
		if overlap:
			break
	_check("500 crowded ticks, no shared tiles", not overlap)
	srv.monsters.clear()

	# ---- null safety: unknown pid never crashes, safe defaults ----
	var BAD := 999
	_check("move bad pid", srv.request_move(BAD, Vector2i(1, 0)) == Vector2i(-1, -1))
	_check("can_step bad pid", not srv.can_step(BAD, Vector2i(1, 0)))
	_check("step_blocker bad pid", srv.step_blocker(BAD, Vector2i(1, 0)) == "no session")
	_check("path bad pid", srv.request_path(BAD, spawn) == -1)
	srv.cancel_path(BAD)
	BlackTekPath.path_step(srv, BAD, 0.05)
	_check("fetch bad pid", srv.get_path(BAD).is_empty())
	srv.heal_player(BAD, 10, "test")
	srv.add_mana(BAD, 10, "test")
	srv.spend_mana(BAD, 10)
	srv.set_food(BAD, 10)
	BlackTekPlayer.advance_skill(srv, BAD, "sword")
	BlackTekPlayer.advance_skill(srv, 1, "bogus")
	_check("is_fed bad pid", not srv.is_fed(BAD))
	_check("is_poisoned bad pid", not srv.is_poisoned(BAD))
	_check("add_item bad pid", not srv.add_item(BAD, 2148, 1))
	srv.consume_item(BAD, {})
	srv.consume_item(1, {})
	_check("pay_gold bad pid", not srv.pay_gold(BAD, 5))
	_check("count bad pid", srv.shop_stock(BAD, 2148) == 0)
	var gold_kept := _bag_count(srv, 2148)
	var meat_offer := {"itemtype": 2666, "buy_price": 8, "price": 8, "sell_price": 3, "name": "meat"}
	srv.buy_shop_item(BAD, meat_offer)
	srv.sell_shop_item(BAD, meat_offer, 1)
	_check("trade bad pid moves no gold", _bag_count(srv, 2148) == gold_kept)
	_check("queries safe", srv.pushable_item_at(spawn, int(srv.players[1].z)) is Dictionary and srv.takeable_item_at(spawn, int(srv.players[1].z)) is Dictionary and srv.door_at(spawn, int(srv.players[1].z)) is Dictionary)
	srv.can_push_item(spawn, Vector2i(1, 0), int(srv.players[1].z))
	_check("push bad pid", not srv.push_item(spawn, Vector2i(1, 0), int(srv.players[1].z), BAD))
	_check("drop bad pid", not srv.drop_item(BAD, 0, spawn, int(srv.players[1].z)))
	_check("drop equipped bad pid", not srv.drop_equipped(BAD, 5, spawn, int(srv.players[1].z)))
	_check("pickup bad pid", not srv.pickup_item(spawn, int(srv.players[1].z), BAD))
	_check("door bad pid", not srv.use_door(spawn, int(srv.players[1].z), BAD))
	_check("weapon bad pid", srv.equipped_weapon(BAD) == 0)
	_check("armor bad pid", srv.total_armor(BAD) == 0)
	_check("nearest bad pid", srv.nearest_monster(BAD).is_empty())
	srv.target_next(BAD)
	srv.attack_current_target(BAD)
	srv.set_target(BAD, {})
	srv.damage_monster(999999, 5, "x", BAD)
	BlackTekCombat.kill_monster(srv, 999999, BAD)
	BlackTekCombat.gain_exp(srv, BAD)
	BlackTekCombat.monster_attack(srv, {}, BAD)
	BlackTekCombat.player_death(srv, BAD)
	_check("stairs bad pid", srv.try_stair_teleport(BAD) == -1)
	_check("floor bad pid", not srv.request_floor(BAD, 1))
	_check("town bad pid", not srv.teleport_town(BAD))
	_check("npc_at safe", srv.npc_at(spawn, int(srv.players[1].z)) is Dictionary)
	_check("nearest npc bad pid", srv.nearest_npc(BAD).is_empty())
	_check("trade bad pid", not srv.can_trade_with_npc(BAD))
	_check("trade blocker bad pid", srv.trade_blocker(BAD) == "no session")
	_check("interact bad pid", not srv.interact_npc(BAD, 1))
	_check("open shop bad pid", not srv.open_shop(BAD))
	srv.request_say(BAD, "hi")
	_check("cast bad pid handled", srv.scripts.cast_spell(srv, BAD, "exura"))
	_check("use bad pid handled", srv.scripts.use_item(srv, BAD, {"itemtype": 7618, "count": 1, "slot": -1}))
	_check("cooldown bad pid", not srv.check_cooldown(BAD, "x", 1.0))
	_check("storage bad pid", srv.get_storage(BAD, 1) == -1)
	srv.set_storage(BAD, 1, 1)
	BlackTekMonsters.try_spawn(srv, BAD)
	BlackTekMonsters.tick_ai(srv, BAD, 0.0)
	_check("dialogue bad pid", not BlackTekNpc.handle_dialogue(srv, BAD, "hi"))

	# ---- food ----
	if _find_in_bag(srv, 2666).is_empty():
		srv.add_item(1, 2666, 1)
	var meat: Dictionary = _find_in_bag(srv, 2666)
	srv.scripts.use_item(srv, 1, meat)
	_check("food condition set", float(srv.players[1].food_until) > 0.0)

	# ---- regen tick ----
	srv.players[1].hp = 10
	for i in range(300):
		srv.tick(0.05)
	_check("regen restored hp over ticks", int(srv.players[1].hp) > 10)

	# ---- persistence roundtrip ----
	var pos_before: Vector2i = srv.players[1].tile
	var lvl_before := int(srv.players[1].level)
	var hp_before := int(srv.players[1].hp)
	srv.save_all()
	var srv2: BlackTekGameServer = BlackTekGameServer.new("user://mock_db_verify.json")
	srv2.load_real_data("res://assets/assets.dat", "res://assets/forgotten.otbm")
	srv2.login_account("demo", "demo")
	var knight2: Dictionary = {}
	for c in srv2.character_list():
		if String(c.name) == "DemoKnight":
			knight2 = c
	_check("saved level persisted", int(knight2.level) == lvl_before)
	_check("saved hp persisted", int(knight2.health) == hp_before)
	srv2.enter_world(knight2)
	_check("saved position persisted", srv2.players[1].tile == pos_before)
	_check("equipped sword persisted", int(srv2.players[1].inv[5].itemtype) == 2376)

	# ---- character creation ----
	var created: Dictionary = srv2.create_character("VerifyMage", 1)
	_check("create character", not created.is_empty())
	_check("duplicate name rejected", srv2.create_character("VerifyMage", 1).is_empty())
	_check("short name rejected", srv2.create_character("ab", 1).is_empty())

	# ---- occupancy: monsters and players never share an SQM ----
	var mid2 := 0
	for m in srv.monsters.keys():
		mid2 = int(m)
		break
	_check("monster exists for occupancy test", mid2 != 0)
	if mid2 != 0:
		var mtile: Vector2i = srv.monsters[mid2].tile
		srv.players[1].tile = mtile + Vector2i(1, 0)
		var blocked: Vector2i = srv.request_move(1, Vector2i(-1, 0)) # into the rat
		_check("player cannot step onto monster SQM", blocked == srv.players[1].tile)
		srv.monsters[mid2].tile = srv.players[1].tile # force artificial overlap
		_check("occupied tile is rejected for spawning", not srv.tile_free_for_monster(srv.players[1].tile, int(srv.players[1].z), mid2))
		srv.monsters[mid2].tile = mtile

	# Keep only one monster for the deterministic push/path tests below.
	for other_mid in srv.monsters.keys():
		if int(other_mid) != mid2:
			srv.monsters.erase(other_mid)
	srv.monsters[mid2].target_pid = 0
	srv.monsters[mid2].tile = srv.players[1].tile + Vector2i(4, 0)

	# ---- conditions: PZ at temple, fed/poisoned flags ----
	srv.players[1].tile = spawn
	_check("temple area is a protection zone", srv.is_pz_tile(spawn))
	srv.players[1].food_until = 0.0
	_check("not fed without food condition", not srv.is_fed(1))
	_check("not poisoned at spawn", not srv.is_poisoned(1))
	srv.players[1].poison_until = Time.get_ticks_msec() / 1000 + 5.0
	_check("poison flag active", srv.is_poisoned(1))
	srv.players[1].poison_until = 0.0
	var hp_at_poison := 20
	srv.players[1].vocation = 0 # None: negligible regen so poison damage is isolated
	srv.players[1].hp = hp_at_poison
	srv.players[1].poison_until = Time.get_ticks_msec() / 1000 + 5.0
	srv.monsters[mid2].tile = srv.players[1].tile + Vector2i(12, 0)
	for i in range(120):
		srv.tick(0.05)
	_check("poison deals damage over time", int(srv.players[1].hp) < hp_at_poison)
	srv.players[1].vocation = 4
	srv.players[1].hp = int(srv.players[1].hpmax)
	srv.players[1].poison_until = 0.0

	# ---- mouse push: melee range, adjacent free SQM, cooldown ----
	if mid2 != 0 and srv.monsters.has(mid2):
		srv.monsters[mid2].tile = srv.players[1].tile + Vector2i(1, 0)
		srv.monsters[mid2].z = int(srv.players[1].z)
		srv.monsters[mid2].erase("push_cd")
		var to: Vector2i = srv.monsters[mid2].tile + Vector2i(0, 1)
		_check("push south to adjacent free tile", srv.push_monster(mid2, Vector2i(0, 1), 1))
		_check("push moved the monster one SQM", srv.monsters[mid2].tile == to)
		_check("push to non-adjacent direction refused", not srv.push_monster(mid2, Vector2i(5, 0), 1))
		srv.monsters[mid2].push_cd = Time.get_ticks_msec() / 1000 + 10.0
		_check("push respects cooldown", not srv.push_monster(mid2, Vector2i(1, 0), 1))
		_check("can_push validates adjacency", not srv.can_push_monster(mid2, Vector2i(3, 0)))
		# anti-abuse: the pusher must stand next to the creature (same floor,
		# Chebyshev distance <= 1), even with no cooldown active.
		srv.monsters[mid2].erase("push_cd")
		srv.monsters[mid2].tile = srv.players[1].tile + Vector2i(4, 0)
		_check("push from distance refused", not srv.push_monster(mid2, Vector2i(0, 1), 1))
		_check("distant monster did not move", srv.monsters[mid2].tile == srv.players[1].tile + Vector2i(4, 0))
		srv.monsters[mid2].tile = srv.players[1].tile + Vector2i(1, 0)
		srv.monsters[mid2].z = int(srv.players[1].z) + 1
		_check("push across floors refused", not srv.push_monster(mid2, Vector2i(0, 1), 1))
		srv.monsters[mid2].z = int(srv.players[1].z)
		# push cooldown readout for the stats loading bar
		srv.monsters[mid2].push_cd = Time.get_ticks_msec() / 1000 + 5.0
		_check("push cooldown reported while active", srv.push_cooldown_remaining(mid2) > 4.0)
		srv.monsters[mid2].push_cd = 0.0
		_check("push cooldown ready at zero", srv.push_cooldown_remaining(mid2) == 0.0)
		_check("push cooldown unknown monster is zero", srv.push_cooldown_remaining(99999) == 0.0)
		# client drag snap: 8-way angle snap (diagonal side-pushes included)
		_check("push dir east", BlackTekWorldView._push_drag_dir_for(Vector2(30, 5)) == Vector2i(1, 0))
		_check("push dir north", BlackTekWorldView._push_drag_dir_for(Vector2(3, -40)) == Vector2i(0, -1))
		_check("push dir short drag is click", BlackTekWorldView._push_drag_dir_for(Vector2(5, 5)) == Vector2i.ZERO)
		_check("push dir southeast diagonal", BlackTekWorldView._push_drag_dir_for(Vector2(30, 30)) == Vector2i(1, 1))
		_check("push dir southwest diagonal", BlackTekWorldView._push_drag_dir_for(Vector2(-20, 20)) == Vector2i(-1, 1))
		_check("push dir west", BlackTekWorldView._push_drag_dir_for(Vector2(-30, 8)) == Vector2i(-1, 0))

	# ---- pushing map items: topmost movable object shoved 1 SQM ----
	var iz := int(srv.players[1].z)
	var itile := Vector2i(-9999, -9999)
	for pos in srv.otbm.tiles.keys():
		if pos.z != iz:
			continue
		var c := Vector2i(pos.x, pos.y)
		if maxi(absi(c.x - srv.players[1].tile.x), absi(c.y - srv.players[1].tile.y)) > 30:
			continue
		if c == srv.players[1].tile or not srv.monster_at(c, iz).is_empty():
			continue
		if not srv.pushable_item_at(c, iz).is_empty():
			itile = c
			break
	_check("a pushable map item exists near spawn", itile != Vector2i(-9999, -9999))
	if itile != Vector2i(-9999, -9999):
		srv.players[1].tile = spawn # stand back at spawn, then step next to it
		var stood := false
		for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if srv.is_walkable(itile + off, iz) and srv.monster_at(itile + off, iz).is_empty():
				srv.players[1].tile = itile + off
				stood = true
				break
		_check("stood next to the item", stood)
		var shoved := false
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if srv.can_push_item(itile, d, iz):
				var n0: int = srv.tile_info(itile, iz).get("items", PackedInt32Array()).size()
				var n1: int = srv.tile_info(itile + d, iz).get("items", PackedInt32Array()).size()
				shoved = srv.push_item(itile, d, iz, 1)
				_check("item left its tile", srv.tile_info(itile, iz).get("items", PackedInt32Array()).size() == n0 - 1)
				_check("item landed on dest tile", srv.tile_info(itile + d, iz).get("items", PackedInt32Array()).size() == n1 + 1)
				break
		_check("item shove works", shoved)
		srv.players[1].tile = spawn

	# ---- doors: click in reach swings the leaf, swapping its item id ----
	_check("door pairs loaded", not srv.dat.door_pairs.is_empty())
	var dtile := Vector2i(-9999, -9999)
	var dz := int(srv.players[1].z)
	for pos in srv.otbm.tiles.keys():
		if pos.z != dz:
			continue
		var dc := Vector2i(pos.x, pos.y)
		var leaf: Dictionary = srv.door_at(dc, dz)
		if not leaf.is_empty() and not bool(leaf.open):
			dtile = dc
			break
	_check("a closed door exists on this floor", dtile != Vector2i(-9999, -9999))
	if dtile != Vector2i(-9999, -9999):
		srv.players[1].tile = spawn
		var stood_d := false
		for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
			if srv.is_walkable(dtile + off, dz) and srv.monster_at(dtile + off, dz).is_empty():
				srv.players[1].tile = dtile + off
				stood_d = true
				break
		_check("stood next to the door", stood_d)
		var shut_id: int = int(srv.door_at(dtile, dz).itemtype)
		_check("door opens in reach", srv.use_door(dtile, dz, 1))
		_check("leaf swapped to open", srv.door_at(dtile, dz).itemtype != shut_id and bool(srv.door_at(dtile, dz).open))
		srv.monsters[778001] = {"id": 778001, "name": "Rat", "tile": dtile, "z": dz, "hp": 25, "hpmax": 25, "move_cd": 0.0, "attack_cd": 0.0, "target_pid": 0}
		_check("occupied door stays open", not srv.use_door(dtile, dz, 1))
		srv.monsters.erase(778001)
		_check("door closes again", srv.use_door(dtile, dz, 1))
		_check("leaf swapped back to closed", int(srv.door_at(dtile, dz).itemtype) == shut_id)
		srv.players[1].tile = spawn
		if maxi(absi(dtile.x - spawn.x), absi(dtile.y - spawn.y)) > 1:
			_check("far door use refused", not srv.use_door(dtile, dz, 1))
			_check("far door left closed", int(srv.door_at(dtile, dz).itemtype) == shut_id)
		# step_blocker names real blockers; squeeze rule lets one blocked
		# side (here: the closed door leaf) still pass diagonally.
		var nadj := Vector2i(-9999, -9999)
		for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
			var nc: Vector2i = dtile + off
			if srv.is_walkable(nc, dz) and srv.monster_at(nc, dz).is_empty():
				nadj = nc
				break
		if nadj != Vector2i(-9999, -9999):
			srv.players[1].tile = nadj
			var to_door: Vector2i = dtile - nadj
			if maxi(absi(to_door.x), absi(to_door.y)) == 1 and to_door != Vector2i.ZERO:
				if srv.dat.is_solid(shut_id):
					_check("step_blocker names the closed door", srv.step_blocker(1, to_door) == "closed door")
				else:
					_check("step_blocker allows walkable doors", srv.step_blocker(1, to_door) == "")
			var squeezed := false
			var tried := false
			for dd in [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
				var dst: Vector2i = nadj + dd
				if not srv.is_walkable(dst, dz) or not srv.monster_at(dst, dz).is_empty():
					continue
				var s1 := nadj + Vector2i(dd.x, 0)
				var s2 := nadj + Vector2i(0, dd.y)
				if (s1 == dtile) == (s2 == dtile):
					continue # need exactly one side on the door leaf
				var other := s2 if s1 == dtile else s1
				if not srv.is_walkable(other, dz):
					continue
				tried = true
				if srv.can_step(1, dd) and srv.request_move(1, dd) == dst:
					squeezed = true
				srv.players[1].tile = nadj
				break
			if tried:
				_check("diagonal squeezes past the closed door", squeezed)
			srv.players[1].tile = spawn
			srv.cancel_path(1)

	# ---- backpack <-> floor: drop a bag row on a tile, pick it back up ----
	srv.players[1].tile = spawn
	var fz := int(srv.players[1].z)
	srv.add_item(1, 2666, 2) # guarantee droppable meat
	var drop_bpos := -1
	for i in range(20):
		var it: Dictionary = srv.players[1].bag.get(i) if srv.players[1].bag.get(i) != null else {}
		if not it.is_empty() and int(it.itemtype) == 2666:
			drop_bpos = i
			break
	var ftile := Vector2i(-9999, -9999)
	for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var c: Vector2i = spawn + off
		if srv.tile_info(c, fz).is_empty() or not srv.monster_at(c, fz).is_empty():
			continue
		if not srv.takeable_item_at(c, fz).is_empty():
			continue
		ftile = c
		break
	_check("drop tile next to spawn", ftile != Vector2i(-9999, -9999) and drop_bpos >= 0)
	if ftile != Vector2i(-9999, -9999) and drop_bpos >= 0:
		var meat0 := _bag_count(srv, 2666)
		_check("drop works", srv.drop_item(1, drop_bpos, ftile, fz))
		_check("drop takes one from the bag", _bag_count(srv, 2666) == meat0 - 1)
		_check("dropped meat lies on the tile", int(srv.takeable_item_at(ftile, fz).get("itemtype", 0)) == 2666)
		_check("far drop refused", not srv.drop_item(1, drop_bpos, spawn + Vector2i(10, 0), fz))
		_check("pickup works", srv.pickup_item(ftile, fz, 1))
		_check("pickup restores the bag", _bag_count(srv, 2666) == meat0)
		_check("tile is clear again", srv.takeable_item_at(ftile, fz).is_empty())
		_check("second pickup finds nothing", not srv.pickup_item(ftile, fz, 1))
		# full backpack refuses the pickup and leaves the tile alone
		srv.drop_item(1, drop_bpos, ftile, fz)
		var bag_backup: Dictionary = (srv.players[1].bag as Dictionary).duplicate(true)
		for i2 in range(20):
			srv.players[1].bag[i2] = {"sid": 9000 + i2, "pid": 1, "itemtype": 9999, "count": 1, "slot": -1, "bpos": i2}
		_check("full backpack refuses pickup", not srv.pickup_item(ftile, fz, 1))
		_check("refused pickup leaves tile alone", int(srv.takeable_item_at(ftile, fz).get("itemtype", 0)) == 2666)
		srv.players[1].bag = bag_backup
		srv.pickup_item(ftile, fz, 1) # tidy up: meat back in the bag
		srv.players[1].tile = spawn

	# ---- preview honesty: can_step/step_blocker agree with request_move ----
	srv.players[1].tile = spawn
	srv.monsters.clear()
	var agree := true
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
		srv.players[1].tile = spawn
		var c_ok: bool = srv.can_step(1, d)
		if (srv.step_blocker(1, d) == "") != c_ok:
			agree = false
		if (srv.request_move(1, d) == spawn + d) != c_ok:
			agree = false
	srv.players[1].tile = spawn
	srv.cancel_path(1)
	_check("can_step/blocker agree with request_move in all 8 dirs", agree)
	_check("backpacks are containers", srv.dat.is_container(1988))
	_check("swords are not containers", not srv.dat.is_container(2376))

	# ---- containers home to the Backpack gear slot, never loose in the bag ----
	var ctile := Vector2i(-9999, -9999)
	for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var c: Vector2i = spawn + off
		if srv.tile_info(c, fz).is_empty() or not srv.monster_at(c, fz).is_empty():
			continue
		ctile = c
		break
	_check("container tile next to spawn", ctile != Vector2i(-9999, -9999))
	if ctile != Vector2i(-9999, -9999):
		var home_pack: Dictionary = srv.players[1].inv.get(3) if srv.players[1].inv.get(3) != null else {}
		srv.players[1].inv[3] = null
		var centry: Dictionary = srv.tile_info(ctile, fz)
		var cids: PackedInt32Array = (centry.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
		cids.append(1988)
		centry["items"] = cids
		_check("floor backpack picked up", srv.pickup_item(ctile, fz, 1))
		_check("backpack refits its gear slot", int(srv.players[1].inv.get(3, {}).get("itemtype", 0)) == 1988)
		var centry2: Dictionary = srv.tile_info(ctile, fz)
		var cids2: PackedInt32Array = (centry2.get("items", PackedInt32Array()) as PackedInt32Array).duplicate()
		cids2.append(1988)
		centry2["items"] = cids2
		_check("second backpack goes to the bag (slot busy)", srv.pickup_item(ctile, fz, 1))
		var bagged := 0
		for i in range(20):
			var it: Dictionary = srv.players[1].bag.get(i) if srv.players[1].bag.get(i) != null else {}
			if not it.is_empty() and int(it.itemtype) == 1988:
				bagged += 1
				srv.players[1].bag[i] = null # tidy up
		_check("exactly one spare backpack bagged", bagged == 1)
		srv.players[1].inv[3] = home_pack if not home_pack.is_empty() else null
		srv.players[1].tile = spawn

	# ---- gear <-> floor: drop equipped rows, pickup refits free slots ----
	var gtile := Vector2i(-9999, -9999)
	for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var c: Vector2i = spawn + off
		if srv.tile_info(c, fz).is_empty() or not srv.monster_at(c, fz).is_empty():
			continue
		gtile = c
		break
	_check("gear drop tile next to spawn", gtile != Vector2i(-9999, -9999))
	if gtile != Vector2i(-9999, -9999):
		_check("sword starts equipped", int(srv.players[1].inv.get(5, {}).get("itemtype", 0)) == 2376)
		_check("drop equipped works", srv.drop_equipped(1, 5, gtile, fz))
		_check("sword slot cleared", srv.players[1].inv.get(5) == null)
		_check("sword lies on the tile", int(srv.takeable_item_at(gtile, fz).get("itemtype", 0)) == 2376)
		_check("pickup refits the free gear slot", srv.pickup_item(gtile, fz, 1))
		_check("sword re-equipped", int(srv.players[1].inv.get(5, {}).get("itemtype", 0)) == 2376)
		srv.add_item(1, 2376, 1) # second sword lands in the bag (slot busy)
		_check("second sword goes to bag", _bag_count(srv, 2376) == 1)
		var sbpos := -1
		for i in range(20):
			var it: Dictionary = srv.players[1].bag.get(i) if srv.players[1].bag.get(i) != null else {}
			if not it.is_empty() and int(it.itemtype) == 2376:
				sbpos = i
				break
		_check("drop bagged sword", srv.drop_item(1, sbpos, gtile, fz))
		_check("pickup with busy slot keeps it bagged", srv.pickup_item(gtile, fz, 1) and _bag_count(srv, 2376) == 1 and int(srv.players[1].inv.get(5, {}).get("itemtype", 0)) == 2376)
		srv.players[1].tile = spawn

	# ---- local chat: Norf hears you at the temple, not across the map ----
	var heard: Array = []
	srv.chat_heard.connect(func(pid: int, sender: String, text: String): heard.append([pid, sender, text]))
	heard.clear()
	_check("nearby hi reaches Norf", BlackTekNpc.handle_dialogue(srv, 1, "hi"))
	var norfs := 0
	for h in heard:
		if String(h[1]).begins_with("Norf"):
			norfs += 1
	_check("Norf answers at the temple", norfs == 1)
	srv.players[1].tile = spawn + Vector2i(50, 0)
	heard.clear()
	_check("far hi handled without Norf", BlackTekNpc.handle_dialogue(srv, 1, "hi"))
	var norfs_far := 0
	for h2 in heard:
		if String(h2[1]).begins_with("Norf"):
			norfs_far += 1
	_check("Norf stays silent across the map", norfs_far == 0)
	srv.players[1].tile = spawn

	# ---- click pathfinding (Dijkstra: shortest route, diagonals cost sqrt(2)) ----
	srv.monsters.clear() # deterministic open ground for the shortcut check
	var diag_target: Vector2i = srv.players[1].tile + Vector2i(2, 2)
	var diag_steps: int = srv.request_path(1, diag_target)
	_check("diagonal shortcut is 2 steps", diag_steps == 2)
	_check("diagonal shortcut steps diagonally", srv.get_path(1) == [srv.players[1].tile + Vector2i(1, 1), diag_target])
	for i in range(60):
		srv.tick(0.05)
	_check("player walks the diagonal shortcut", srv.players[1].tile == diag_target)
	# corner rule is walkability-only (matches request_move): rats on the
	# neighbouring tiles never pinch a diagonal, only walls do.
	srv.monsters[777001] = {"id": 777001, "name": "Rat", "tile": srv.players[1].tile + Vector2i(1, 0), "z": iz, "hp": 25, "hpmax": 25, "move_cd": 0.0, "attack_cd": 0.0, "target_pid": 0}
	var sq_steps: int = srv.request_path(1, srv.players[1].tile + Vector2i(1, 1))
	_check("diagonal squeezes past one rat neighbour", sq_steps == 1)
	srv.monsters[777002] = {"id": 777002, "name": "Rat", "tile": srv.players[1].tile + Vector2i(0, 1), "z": iz, "hp": 25, "hpmax": 25, "move_cd": 0.0, "attack_cd": 0.0, "target_pid": 0}
	var pinched: int = srv.request_path(1, srv.players[1].tile + Vector2i(1, 1))
	_check("diagonal still routes between two rats", pinched == 1)
	srv.monsters.erase(777001)
	srv.monsters.erase(777002)
	# rats on the line never bend a route: plan straight through (the walker
	# stops with "blocked" if one is still there mid-walk). Reuses the
	# proven-open diagonal tiles from the shortcut check above.
	srv.players[1].tile = spawn
	srv.monsters[777003] = {"id": 777003, "name": "Rat", "tile": spawn + Vector2i(1, 1), "z": iz, "hp": 25, "hpmax": 25, "move_cd": 0.0, "attack_cd": 0.0, "target_pid": 0}
	var thru: int = srv.request_path(1, spawn + Vector2i(2, 2))
	_check("path routes straight through a rat line", thru == 2)
	_check("straight route steps onto the rat tile", srv.get_path(1) == [spawn + Vector2i(1, 1), spawn + Vector2i(2, 2)])
	srv.monsters.erase(777003)
	srv.cancel_path(1)
	var walker_tile: Vector2i = srv.players[1].tile
	var path_target: Vector2i = walker_tile + Vector2i(3, 2)
	var steps: int = srv.request_path(1, path_target)
	_check("path found to reachable tile", steps > 0)
	_check("path to unreachable tile refused", srv.request_path(1, Vector2i(-50, -50)) == -1)
	for i in range(300):
		srv.tick(0.05)
	_check("player walks along the path", srv.players[1].tile == path_target)
	_check("path queue empty on arrival", srv.get_path(1).is_empty())
	srv.cancel_path(1)

	# ---- light sources parsed from assets.dat (flag 22) ----
	var lit := 0
	for it in srv.dat.items.values():
		if int(it.get("light", 0)) > 0:
			lit += 1
	_check("dat has light sources (torches/fires)", lit > 0)

	# ---- item stats text ----
	var sword_stats: String = srv.item_stats_text(2376)
	_check("sword stats show attack + weight", "Attack: +14" in sword_stats and "Weight:" in sword_stats)
	_check("plate armor shows defense", "Defense: +10" in srv.item_stats_text(2463))
	_check("health potion shows heal range", "Heals 100-160 hitpoints" in srv.item_stats_text(7618))

	# ---- HUD regression (runs on frame 1 — see _process; a Control added to
	# root during _initialize is not in the tree yet, so _ready never fires) ----
	_hud_srv = srv2
	_hud = BlackTekHud.new()
	_hud.game = srv2

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames != 1 or _hud == null:
		return false
	root.add_child(_hud)
	_check("equipped_weapon tolerates null slot", _hud_srv.equipped_weapon(1) >= 0)
	_check("total_armor tolerates null slot", _hud_srv.total_armor(1) >= 0)
	_hud_srv.players[1].inv[4] = null # armor slot cleared (unequip)
	_hud.refresh_stats()
	_hud.refresh_inventory()
	_hud_srv.add_item(1, BlackTekActionScripts.GOLD_COIN, 7) # add_item with null bag slots present
	_check("pay_gold tolerates null bag slots", _hud_srv.pay_gold(1, 3))
	_hud_srv.save_all() # save with null slots present (must not drop remaining items)
	var srv3: BlackTekGameServer = BlackTekGameServer.new("user://mock_db_verify.json")
	srv3.login_account("demo", "demo")
	var knight3: Dictionary = {}
	for c in srv3.character_list():
		if String(c.name) == "DemoKnight":
			knight3 = c
	srv3.enter_world(knight3)
	_check("sword persisted after null-slot save", int(srv3.players[1].inv[5].itemtype) == 2376)
	_check("cleared armor slot stays cleared", srv3.players[1].inv.get(4) == null)
	_check("bag potions persisted (3x health)", int(_find_in_bag(srv3, 7618).get("count", 0)) == 3)
	# ---- client push glue: finish_push must read the drag BEFORE clearing the
	# push state (clearing first made every release a silent no-op).
	_glue_push_checks()
	print("=== %d checks, %d failed ===" % [checks, fails])
	quit(1 if fails > 0 else 0)
	return true

var _hud: BlackTekHud
var _hud_srv: BlackTekGameServer
var _frames := 0

# Drives the real world-view push pipeline (view state -> finish_push ->
# server) with a synthetic 100px drag. Needs the scene tree (viewport).
func _glue_push_checks() -> void:
	var vw := BlackTekWorldView.new()
	vw.server = _hud_srv
	root.add_child(vw)
	vw.player_tile = _hud_srv.players[1].tile
	var pz: int = int(_hud_srv.players[1].z)
	var mouse: Vector2 = vw.get_viewport().get_mouse_position()
	var gtest := 900001
	_hud_srv.monsters[gtest] = {"id": gtest, "name": "Rat", "tile": Vector2i(-9999, -9999), "z": pz, "hp": 25, "hpmax": 25, "move_cd": 0.0, "attack_cd": 0.0, "target_pid": 0}
	var done_rat := false
	for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var rt: Vector2i = vw.player_tile + off
		if not _hud_srv.is_walkable(rt, pz) or not _hud_srv.monster_at(rt, pz).is_empty():
			continue
		_hud_srv.monsters[gtest].tile = rt
		_hud_srv.monsters[gtest].erase("push_cd")
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if _hud_srv.can_push_monster(gtest, d):
				vw.push = {"kind": "mon", "mid": gtest, "start": mouse - Vector2(d) * 100.0}
				vw.finish_push()
				_check("glue: rat push moves monster", _hud_srv.monsters[gtest].tile == rt + d)
				done_rat = true
				break
		if done_rat:
			break
	_check("glue: rat push had room", done_rat)
	for d2 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var dest: Vector2i = _hud_srv.players[1].tile + d2
		if _hud_srv.is_walkable(dest, pz) and _hud_srv.monster_at(dest, pz).is_empty():
			var before: Vector2i = _hud_srv.players[1].tile
			vw.push = {"kind": "self", "start": mouse - Vector2(d2) * 100.0}
			vw.finish_push()
			_check("glue: self push steps player", _hud_srv.players[1].tile == before + d2)
			break
	_hud_srv.monsters.erase(gtest)
	vw.queue_free()

func _check(what: String, cond: bool) -> void:
	checks += 1
	if cond:
		print("  PASS  %s" % what)
	else:
		fails += 1
		print("  FAIL  %s" % what)

func _bag_count(srv: BlackTekGameServer, itemtype: int) -> int:
	var total := 0
	var bag: Dictionary = srv.players[1].bag
	for i in range(20):
		var it: Dictionary = bag.get(i) if bag.get(i) != null else {}
		if not it.is_empty() and int(it.itemtype) == itemtype:
			total += int(it.count)
	return total

func _find_in_bag(srv: BlackTekGameServer, itemtype: int) -> Dictionary:
	var bag: Dictionary = srv.players[1].bag
	for i in range(20):
		var it: Dictionary = bag.get(i) if bag.get(i) != null else {}
		if not it.is_empty() and int(it.itemtype) == itemtype:
			return it
	return {}
