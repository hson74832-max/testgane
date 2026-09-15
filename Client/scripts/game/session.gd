# BlackTek session: account auth + character list/creation (cf. protocollogin).
# Stateless — account/db state and signals live on the game server.
class_name BlackTekSession
extends RefCounted

static func login_account(game, account_name: String, password: String) -> bool:
	if game.db.db.accounts.is_empty():
		game.login_error.emit("MockDB has no accounts.")
		return false
	if not account_name.is_empty():
		game.account = game.db.auth(account_name, password)
		if (game.account as Dictionary).is_empty():
			game.login_error.emit("Wrong account name or password.")
			return false
	else:
		game.account = (game.db.db.accounts as Array)[0]
	return true

static func character_list(game) -> Array:
	return game.db.characters(int((game.account as Dictionary).id))

static func create_character(game, player_name: String, vocation: int) -> Dictionary:
	if player_name.strip_edges().length() < 3:
		game.login_error.emit("Name too short (min 3 chars).")
		return {}
	if not game.db.find_player_by_name(player_name).is_empty():
		game.login_error.emit("Name already taken.")
		return {}
	var row: Dictionary = game.db.create_character(int((game.account as Dictionary).id), player_name.strip_edges(), vocation)
	if row.is_empty():
		game.login_error.emit("Could not create character.")
	return row
