# Inventory screens: equipment slots + backpack grid, click to use/equip and
# inventory-only drag & drop (rearrange with stack merging, equip, unequip).
class_name BlackTekGearPanel
extends RefCounted

# Classic Tibia equipment layout (slot ids): amulet/head/backpack,
# right/armor/left, ring/legs/ammo, feet.
const SLOT_LAYOUT := [[2, 1, 3], [5, 4, 6], [9, 7, 10], [-1, 8, -1]]
const SLOT_NAMES := {1: "Head", 2: "Amulet", 3: "Backpack", 4: "Armor", 5: "Right hand", 6: "Left hand", 7: "Legs", 8: "Feet", 9: "Ring", 10: "Ammo"}




class InvDragButton extends Button:
	var panel_mod: BlackTekGearPanel
	var from := {} # {"kind": "bag"/"equip", "index": int}
	func _get_drag_data(_pos):
		var it := int(get_meta("itemtype", 0))
		if it <= 0:
			return null
		var preview := TextureRect.new()
		preview.texture = panel_mod.game.get_item_icon(it)
		preview.custom_minimum_size = Vector2(32, 32)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var wrapc := Control.new()
		wrapc.add_child(preview)
		set_drag_preview(wrapc)
		panel_mod.hud.begin_world_drag(from)
		return {"for": "inv", "from": from, "itemtype": it}
	func _notification(what: int) -> void:
		# Drag finished anywhere: if no inventory slot accepted it, the HUD
		# turns a world release into a floor drop.
		if what == NOTIFICATION_DRAG_END:
			panel_mod.hud.finish_world_drag()
	func _can_drop_data(_pos, data) -> bool:
		return typeof(data) == TYPE_DICTIONARY and String(data.get("for", "")) == "inv" and not panel_mod._same_slot(data.from, from)
	func _drop_data(_pos, data) -> void:
		panel_mod._inv_move(data.from, from)

var hud: Control
var game: BlackTekGameServer
var panel: PanelContainer
var gear_grid: GridContainer
var bag_grid: GridContainer
var equip_nodes: Dictionary = {}
var bag_nodes: Dictionary = {}
var gold_label: Label

func build(h: Control) -> void:
	hud = h
	game = hud.game
	panel = BlackTekUiKit.panel(hud, "top-right", Vector2(236, 434))
	panel.offset_top = 190
	panel.offset_bottom = 630
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var gold_spacer := Control.new()
	gold_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gold_spacer)
	gold_label = BlackTekUiKit.label(head, "0 gold", 11, BlackTekUiKit.GOLD_COLOR)
	gear_grid = GridContainer.new()
	gear_grid.columns = 3
	gear_grid.add_theme_constant_override("h_separation", 5)
	gear_grid.add_theme_constant_override("v_separation", 4)
	gear_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(gear_grid)
	for row in SLOT_LAYOUT:
		for slot_id in row:
			if slot_id == -1:
				var spacer := Control.new()
				spacer.custom_minimum_size = Vector2(46, 46)
				gear_grid.add_child(spacer)
			else:
				gear_grid.add_child(_make_item_slot("equip", slot_id))
	box.add_child(HSeparator.new())
	BlackTekUiKit.label(box, "Backpack", 11, Color(0.6, 0.65, 0.72))
	bag_grid = GridContainer.new()
	bag_grid.columns = 5
	bag_grid.add_theme_constant_override("h_separation", 4)
	bag_grid.add_theme_constant_override("v_separation", 4)
	box.add_child(bag_grid)
	for i in range(20):
		bag_grid.add_child(_make_item_slot("bag", i))
	var hint := BlackTekUiKit.label(box, "Click to use/equip. Drag items to rearrange or equip.", 9, Color(0.55, 0.58, 0.66))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_wrap_panel_chrome()
	panel.visible = false
# Delegates to the shared static header in the HUD root.

func _wrap_panel_chrome() -> void:
	hud.panel_header(panel, box_of(), "Gear")

func box_of() -> VBoxContainer:
	return panel.get_child(0)

func toggle() -> void:
	if panel.visible:
		hud.hide_panel(panel)
	else:
		hud.show_panel(panel)
		refresh_inventory()

func _make_item_slot(kind: String, index: int) -> Button:
	var btn: Button = InvDragButton.new()
	(btn as InvDragButton).panel_mod = self
	(btn as InvDragButton).from = {"kind": kind, "index": index}
	var side := 46 if kind == "equip" else 40
	btn.custom_minimum_size = Vector2(side, side)
	btn.focus_mode = Control.FOCUS_NONE
	var sb := BlackTekUiKit.panel_style(BlackTekUiKit.SLOT_BG)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", BlackTekUiKit.panel_style(BlackTekUiKit.SLOT_BG.lightened(0.06)))
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4; icon.offset_top = 4; icon.offset_right = -4; icon.offset_bottom = -4
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)
	var count := Label.new()
	count.add_theme_font_size_override("font_size", 9)
	count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	count.offset_left = -24; count.offset_top = -14; count.offset_right = -3; count.offset_bottom = -2
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(count)
	btn.pressed.connect(func(): _on_slot_clicked(kind, index))
	var record := {"btn": btn, "icon": icon, "count": count}
	if kind == "equip":
		equip_nodes[index] = record
	else:
		bag_nodes[index] = record
	return btn

# Drag & drop inside the inventory screens only: bag<->bag swap/merge,
# bag->equip, equip->bag (cf. Game::moveItem between slots).
func _same_slot(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("kind", "")) == String(b.get("kind", "")) and int(a.get("index", -1)) == int(b.get("index", -1))

func _inv_move(from: Dictionary, to: Dictionary) -> void:
	var p: Dictionary = game.players[hud._pid]
	var fkind: String = String(from.get("kind", ""))
	var tkind: String = String(to.get("kind", ""))
	var fidx: int = int(from.get("index", -1))
	var tidx: int = int(to.get("index", -1))
	var row: Dictionary = {}
	if fkind == "equip":
		row = p.inv.get(fidx) if p.inv.get(fidx) != null else {}
	else:
		row = p.bag.get(fidx) if p.bag.get(fidx) != null else {}
	if row.is_empty() or _same_slot(from, to):
		return
	if fkind == "bag" and tkind == "bag":
		var dst: Dictionary = p.bag.get(tidx) if p.bag.get(tidx) != null else {}
		if not dst.is_empty() and is_same(dst, row):
			return # same object dropped onto itself: a container can never
			# go inside itself — no-op instead of a bogus swap/merge.
		# Merge stacks of the same stackable type, else swap positions.
		if not dst.is_empty() and int(dst.itemtype) == int(row.itemtype) and game.dat != null and bool(game.dat.items.get(int(row.itemtype), {}).get("stackable", false)):
			dst.count = int(dst.count) + int(row.count)
			p.bag[fidx] = null
		else:
			p.bag[tidx] = row
			p.bag[fidx] = dst if not dst.is_empty() else null
		hud.drag_accepted = true
	elif fkind == "bag" and tkind == "equip":
		# Drag-equip follows the same slot rules as click-equip: an item only
		# goes into its own equipment slot (containers belong in Backpack).
		var want := int(BlackTekGameServer.EQUIP_SLOT.get(int(row.itemtype), -1))
		if want < 0 and game.dat != null and game.dat.is_container(int(row.itemtype)):
			want = 3
		if want != tidx:
			game.message_local(hud._pid, "That item doesn't go in the %s slot." % String(SLOT_NAMES.get(tidx, "equipment")))
			return
		hud.drag_accepted = _do_equip(p, row, tidx)
	elif fkind == "equip" and tkind == "equip":
		return # gear-to-gear moves are not supported: click to unequip first
	elif fkind == "equip" and tkind == "bag":
		for i in range(20):
			if p.bag.get(i) == null:
				p.bag[i] = row
				p.inv[fidx] = null
				hud.drag_accepted = true
				break
	game.inventory_changed.emit(hud._pid)

func _do_equip(p: Dictionary, row: Dictionary, slot: int) -> bool:
	var itemtype := int(row.itemtype)
	var voc := int(p.vocation)
	if slot == 6 and (voc == 1 or voc == 2):
		game.message_local(hud._pid, "Sorcerers and druids cannot use shields.")
		return false
	var old: Dictionary = p.inv.get(slot) if p.inv.get(slot) != null else {}
	for i in range(20):
		if p.bag.get(i) == row:
			p.bag[i] = null
			break
	p.inv[slot] = row
	if not old.is_empty():
		for i in range(20):
			if p.bag.get(i) == null:
				p.bag[i] = old
				break
	game.message_local(hud._pid, "Equipped %s." % game.item_label(itemtype))
	return true

func _on_slot_clicked(kind: String, index: int) -> void:
	var p: Dictionary = game.players[hud._pid]
	var row: Dictionary = {}
	if kind == "equip":
		row = p.inv.get(index) if p.inv.get(index) != null else {}
	else:
		row = p.bag.get(index) if p.bag.get(index) != null else {}
	if row.is_empty():
		return
	if kind == "equip":
		# Unequip -> first free bag slot (cf. Game::moveItem).
		for i in range(20):
			if p.bag.get(i) == null:
				p.bag[i] = row
				p.inv[index] = null
				game.inventory_changed.emit(hud._pid)
				return
		game.message_local(hud._pid, "Your backpack is full.")
		return
	var itemtype := int(row.itemtype)
	if BlackTekGameServer.EQUIP_SLOT.has(itemtype):
		_do_equip(p, row, int(BlackTekGameServer.EQUIP_SLOT[itemtype]))
		game.inventory_changed.emit(hud._pid)
		return
	if game.dat != null and game.dat.is_container(itemtype):
		# Containers live in the Backpack gear slot, never loose in the bag.
		_do_equip(p, row, 3)
		game.inventory_changed.emit(hud._pid)
		return
	game.scripts.use_item(game, hud._pid, row)

func refresh_inventory() -> void:
	if game.players.is_empty() or gold_label == null:
		return
	var p: Dictionary = game.players[hud._pid]
	for slot_id in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]:
		var row: Dictionary = p.inv.get(slot_id) if p.inv.get(slot_id) != null else {}
		_fill_slot(equip_nodes.get(slot_id, {}), row)
	var gold := 0
	for i in range(20):
		var row2: Dictionary = p.bag.get(i) if p.bag.get(i) != null else {}
		_fill_slot(bag_nodes.get(i, {}), row2)
		if not row2.is_empty() and int(row2.itemtype) == BlackTekActionScripts.GOLD_COIN:
			gold += int(row2.count)
	gold_label.text = "%d gold" % gold

func _fill_slot(node: Dictionary, row: Dictionary) -> void:
	if node.is_empty():
		return
	var icon: TextureRect = node.icon
	var count: Label = node.count
	var btn: Button = node.btn
	if row.is_empty():
		icon.texture = null
		count.text = ""
		btn.set_meta("itemtype", 0)
		btn.tooltip_text = ""
		return
	var itemtype := int(row.itemtype)
	icon.texture = game.get_item_icon(itemtype)
	count.text = str(int(row.count)) if int(row.count) > 1 else ""
	btn.set_meta("itemtype", itemtype) # drag payload
	var label : String = game.item_label(itemtype)
	if int(row.count) > 1:
		label += " x%d" % int(row.count)
	var tip : String = label + "
" + game.item_stats_text(itemtype)
	if BlackTekGameServer.EQUIP_SLOT.has(itemtype):
		tip += "
(equippable - drag onto a gear slot)"
	elif game.dat != null and game.dat.is_container(itemtype):
		tip += "
(container - belongs in the Backpack slot)"
	btn.tooltip_text = tip

# ---- stats panel -----------------------------------------------------------------
