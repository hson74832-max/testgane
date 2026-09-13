class_name WebSync
extends Node
## Split contract: Next.js (testttt/) owns persistence + market + bible.
## Godot owns sim + input + rendering. This client talks to web only for:
## character load, 5s state sync, consumable use, equipment, market.
## Authoritative MMO tick will replace the 5s sync later — same payload shape.
## Configure: export WEB_BASE_URL="http://localhost:3000" (dev) in project.

signal sync_done(inventory: Array)
signal sync_failed(reason: String)

@export var base_url: String = "http://localhost:3000"
@export var character_name: String = "Wanderer"

var _http: HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)

func _post(path: String, body: Dictionary) -> int:
	var headers := PackedStringArray(["Content-Type: application/json"])
	return _http.request(base_url + path, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

## Mirrors GamePlay.tsx boot(): POST /api/character {name}
func load_character(p_name: String) -> void:
	character_name = p_name
	_post("/api/character", {"name": p_name})

## Mirrors 5s sync in GamePlay.tsx — state + loot + death + events.
func push_state(state: Dictionary, loot: Array = [], death: Dictionary = {}, events: Array = []) -> void:
	var body := {"name": character_name, "state": state, "loot": loot, "events": events}
	if not death.is_empty():
		body["death"] = death
	_post("/api/character/sync", body)

func use_item(item_key: String) -> void:
	_post("/api/character/use", {"name": character_name, "itemKey": item_key})

func change_gear(action: String, item_key: String = "", slot: String = "") -> void:
	var body := {"name": character_name, "action": action}
	if not item_key.is_empty():
		body["itemKey"] = item_key
	if not slot.is_empty():
		body["slot"] = slot
	_post("/api/character/equipment", body)
