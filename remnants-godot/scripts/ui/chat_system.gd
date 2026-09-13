extends RefCounted
## ChatSystem — chat input, history, commands and network sending.
## Extracted from Hud: the HUD renders lines (it listens to
## chat_message_received) while this module owns the conversation itself:
## the LineEdit lifecycle, the canonical history, slash-command parsing and
## the outgoing-message hook WebSync consumes (dev push, event-gated).
## New commands register in _setup (or anywhere) via register_command().

signal chat_message_received(text: String)  # every line: say + system
signal chat_submitted(text: String)         # player-sent lines (network hook)

const MAX_HISTORY := 30

var world: WorldView  # wired at setup
var _input: LineEdit = null
var _history: Array = []  # canonical log; the HUD renders its own tail
var _commands: Dictionary = {}  # name -> Callable(args: Array[String])

func setup(p_world: WorldView) -> void:
	world = p_world
	register_command("help", _cmd_help)

## The HUD owns the widget (it is rebuilt on resize); re-bind after rebuilds.
func attach_input(le: LineEdit) -> void:
	_input = le

func register_command(name: String, handler: Callable) -> void:
	_commands[name] = handler

## Enter was pressed (or the CHAT pad toggled closed with text pending).
## Clears + closes the input, routes commands, and says plain messages.
func submit(text: String) -> void:
	if _input != null:
		_input.text = ""
		_input.visible = false
		_input.release_focus()
	var clean: String = text.strip_edges()
	if clean == "":
		return
	if clean.begins_with("/"):
		_run_command(clean)
		return
	chat_submitted.emit(clean)  # network sending hook (WebSync dev push)
	world.say(clean)            # local echo + speech float -> chat_message_received

## System/notify lines (and the local echo of says) land here. The HUD's
## rendered tail is rebuilt from chat_message_received — no polling.
func post(text: String) -> void:
	_history.append(text)
	while _history.size() > MAX_HISTORY:
		_history.pop_front()
	chat_message_received.emit(text)

func history() -> Array:
	return _history.duplicate()

# ---- commands ----------------------------------------------------------------
func _run_command(raw: String) -> void:
	var body := raw.substr(1).strip_edges()
	var parts: PackedStringArray = body.split(" ", false)
	if parts.is_empty():
		post("Empty command — try /help")
		return
	var name := String(parts[0]).to_lower()
	if not _commands.has(name):
		post("Unknown command: /%s — try /help" % name)
		return
	var args: Array = []
	for i in range(1, parts.size()):
		args.append(String(parts[i]))
	(_commands[name] as Callable).call(args)

func _cmd_help(_args: Array) -> void:
	var names: Array = []
	for k in _commands.keys():
		names.append("/" + String(k))
	post("Commands: %s" % ", ".join(names))
