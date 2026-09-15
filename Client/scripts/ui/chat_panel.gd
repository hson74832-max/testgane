# Chat: tabbed log (All/Server/Chat) plus the one-line input. The header
# doubles as the drag handle; window buttons ride the far right of the tab
# bar. Submit events go out through the shell's chat_submitted signal.
class_name BlackTekChatPanel
extends RefCounted

var hud: Control
var game: BlackTekGameServer
var panel: PanelContainer
var log: RichTextLabel # "All" tab (kept name for compatibility)
var edit: LineEdit
var tabs: Dictionary = {} # tab name -> RichTextLabel
var tab_btns: Array = [] # {btn, name}
var tab := "All"
var pages: Control

func build(h: Control) -> void:
	hud = h
	game = hud.game
	panel = BlackTekUiKit.panel(hud, "bottom-left", Vector2(320, 300))
	panel.offset_top = -472
	panel.offset_bottom = -152
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	# Header: tab buttons (click a tab to switch; the mouse wheel scrolls the
	# chat text up/down and never changes tabs). The header doubles as the
	# drag handle. Panels are never collapsed.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	box.add_child(header)
	header.tooltip_text = "Drag to move · release to drop on the grid"
	BlackTekUiKit.make_drag_handle(panel, header)
	for t in ["All", "Server", "Chat"]:
		var b := Button.new()
		b.text = t
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 11)
		b.tooltip_text = "Show %s messages" % t
		b.pressed.connect(func(): set_chat_tab(t))
		header.add_child(b)
		tab_btns.append({"btn": b, "name": t})
	# Spacer pushes the window buttons to the far right of the tab bar.
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(spacer)
	header.add_child(hud._header_btn("-", "Minimize to the tab bar", func(): hud._toggle_minimize(panel, box)))
	header.add_child(hud._header_btn("X", "Close chat (T or the rail icon reopens it)", func(): panel.visible = false))
	# Pages: one RichTextLabel per tab, only the active one visible. The labels
	# take the mouse wheel so it scrolls the text up/down (scroll_active);
	# wheel input never switches tabs.
	pages = Control.new()
	pages.clip_contents = true
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(pages)
	for tab2 in ["All", "Server", "Chat"]:
		var l := RichTextLabel.new()
		l.scroll_following = true
		l.scroll_active = true
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.add_theme_font_size_override("normal_font_size", 12)
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		l.visible = tab2 == "All"
		pages.add_child(l)
		tabs[tab2] = l
	log = tabs["All"]
	edit = LineEdit.new()
	edit.placeholder_text = "Type + Enter — try: hi, trade, exura, /pos"
	edit.visible = false
	edit.text_submitted.connect(_on_chat_submit)
	box.add_child(edit)
	panel.visible = false

func set_chat_tab(t: String) -> void:
	tab = t
	for k in tabs.keys():
		tabs[k].visible = k == t
	for rec in tab_btns:
		var b: Button = rec.btn
		b.modulate = Color(1, 1, 1, 1.0) if rec.name == t else Color(1, 1, 1, 0.45)

func chat_open() -> bool:
	return edit != null and edit.visible and edit.has_focus()

func open_chat() -> void:
	edit.visible = true
	edit.grab_focus()

func close_chat(submit := false) -> void:
	if submit and not edit.text.strip_edges().is_empty():
		hud.chat_submitted.emit(edit.text)
	edit.text = ""
	edit.visible = false
	edit.release_focus()

func _on_chat_submit(_text: String) -> void:
	close_chat(true)

func chat_line(sender: String, text: String, color := Color(0.85, 0.86, 0.9)) -> void:
	var bb := "[color=#%s][%s] %s[/color]\n" % [color.to_html(false), sender, text]
	if log == null:
		return
	log.append_text(bb) # All tab
	# Route: server/system messages -> Server tab, players + NPCs -> Chat tab.
	var target := "Chat"
	if sender == "Server" or sender == "System":
		target = "Server"
	tabs[target].append_text(bb)

func game_message(text: String) -> void:
	chat_line("Server", text, Color(0.45, 0.9, 0.55))
