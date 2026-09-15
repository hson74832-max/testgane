# NPC shop: Norf's wares with buy/sell buttons, a trade-quantity slider and
# owned/gold readouts. Opening, trading and the per-refresh gating all require
# a real NPC in trade range; the shell auto-closes the window when you walk
# away (see tick()).
class_name BlackTekShopPanel
extends RefCounted

var hud: Control
var game: BlackTekGameServer
var panel: PanelContainer
var pid := 1
var gold_label: Label
var rows: VBoxContainer
var offer_rows: Array = []
var qty := 1
var qty_label: Label
var far_warned := false

func build(h: Control) -> void:
	hud = h
	game = hud.game
	pid = hud._pid
	panel = BlackTekUiKit.panel(hud, "center", Vector2(340, 300))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	BlackTekUiKit.label(head, "Norf's Wares", 14, BlackTekUiKit.ACCENT).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hud._header_btn("-", "Minimize to the title bar", func(): hud._toggle_minimize(panel, box)))
	var close := Button.new()
	close.text = "X"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func(): panel.visible = false)
	head.add_child(close)
	BlackTekUiKit.make_drag_handle(panel, head)
	gold_label = BlackTekUiKit.label(box, "You carry 0 gold.", 11, BlackTekUiKit.GOLD_COLOR)
	var qty_row := HBoxContainer.new()
	qty_row.add_theme_constant_override("separation", 8)
	box.add_child(qty_row)
	BlackTekUiKit.label(qty_row, "Qty:", 11, Color(0.6, 0.65, 0.72))
	var qty_slider := HSlider.new()
	qty_slider.min_value = 1.0
	qty_slider.max_value = 100.0
	qty_slider.step = 1.0
	qty_slider.value = 1.0
	qty_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qty_slider.focus_mode = Control.FOCUS_NONE
	qty_slider.tooltip_text = "Trade quantity for the Buy/Sell buttons"
	qty_row.add_child(qty_slider)
	qty_label = BlackTekUiKit.label(qty_row, "1x", 11, BlackTekUiKit.GOLD_COLOR)
	qty_label.custom_minimum_size = Vector2(36, 0)
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_slider.value_changed.connect(func(v: float):
		qty = maxi(1, int(round(v)))
		qty_label.text = "%dx" % qty
		refresh_shop_gold())
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	box.add_child(rows)
	panel.visible = false
	refresh_shop()

func toggle() -> void:
	if game.players.is_empty():
		return
	# The shop window is an NPC interaction: it only opens next to a real NPC.
	if not game.can_trade_with_npc(pid):
		game.message_local(pid, "There is no NPC to trade with here. Walk up to Norf at the temple.")
		return
	refresh_shop()
	if panel.visible:
		hud.hide_panel(panel)
	else:
		far_warned = false
		hud.show_panel(panel)

# Auto-close tick (called from the shell cadence): walking out of trade range
# closes the window so it can't be kept open as a remote supply.
func tick() -> void:
	if not panel.visible or game.players.is_empty():
		return
	if not game.can_trade_with_npc(pid):
		hud.hide_panel(panel)
		if not far_warned:
			far_warned = true
			game.message_local(pid, "You walked too far from Norf — trade closed.")

# Rebuild trade rows from the data-driven offers (buy + sell + owned count).
# Called when the shop opens; lightweight owned-count refresh runs separately.
func refresh_shop() -> void:
	if rows == null:
		return
	for c in rows.get_children():
		c.queue_free()
	offer_rows.clear()
	if game == null:
		return
	for offer in BlackTekNpc.shop_offers(game):
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		rows.add_child(h)
		var icon := TextureRect.new()
		icon.texture = game.get_item_icon(int(offer.itemtype)) if game != null else null
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(icon)
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(info)
		BlackTekUiKit.label(info, String(offer.name), 11).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sub := BlackTekUiKit.label(info, "", 10, Color(0.6, 0.65, 0.72))
		var owned_l := BlackTekUiKit.label(info, "", 10, BlackTekUiKit.GOLD_COLOR)
		var buy := Button.new()
		buy.focus_mode = Control.FOCUS_NONE
		var o: Dictionary = (offer as Dictionary).duplicate()
		buy.pressed.connect(func(): game.buy_shop_item(pid, o, qty))
		h.add_child(buy)
		var sell := Button.new()
		sell.focus_mode = Control.FOCUS_NONE
		var o2: Dictionary = (offer as Dictionary).duplicate()
		sell.pressed.connect(func(): game.sell_shop_item(pid, o2, qty))
		h.add_child(sell)
		offer_rows.append({"offer": offer, "sub": sub, "owned": owned_l, "buy_btn": buy, "sell_btn": sell})
	refresh_shop_gold()

func refresh_shop_gold() -> void:
	if game.players.is_empty():
		return
	var p: Dictionary = game.players[pid]
	var gold := 0
	for i in range(20):
		var it: Dictionary = p.bag.get(i) if p.bag.get(i) != null else {}
		if not it.is_empty() and int(it.itemtype) == BlackTekActionScripts.GOLD_COIN:
			gold += int(it.count)
	gold_label.text = "You carry %d gold." % gold
	# Trade buttons are NPC interactions: without a real NPC in trade range
	# every row stays disabled (walking away auto-closes the panel anyway).
	var near_npc: bool = game.can_trade_with_npc(pid) if game.has_method("can_trade_with_npc") else true
	var q: int = maxi(1, qty)
	# Lightweight per-row refresh (no rebuild, so button presses never break).
	for rec in offer_rows:
		var offer: Dictionary = rec.offer
		var buy_p: int = BlackTekConfig.offer_buy_price(offer)
		var sell_p: int = BlackTekConfig.offer_sell_price(offer)
		var owned: int = game.shop_stock(pid, int(offer.itemtype)) if game.has_method("shop_stock") else 0
		var buy_btn: Button = rec.buy_btn
		var sell_btn: Button = rec.sell_btn
		if not near_npc:
			(rec.sub as Label).text = "Walk up to Norf to trade"
		else:
			(rec.sub as Label).text = "Buy %d gp · Sell %d gp" % [buy_p, sell_p] if sell_p > 0 else "Buy %d gp · Norf won't buy this" % buy_p
		(rec.owned as Label).text = "You: %d · %d gold" % [owned, gold]
		buy_btn.text = "Buy %dx" % q
		buy_btn.tooltip_text = "Buy %dx %s for %d gold" % [q, String(offer.name), buy_p * q]
		if sell_p > 0:
			sell_btn.text = "Sell %dx" % q
			sell_btn.tooltip_text = "Sell %dx %s for %d gold" % [q, String(offer.name), sell_p * q]
		else:
			sell_btn.text = "No buy"
			sell_btn.tooltip_text = "Norf doesn't buy %s" % String(offer.name)
		buy_btn.disabled = (not near_npc) or gold < buy_p * q
		sell_btn.disabled = (not near_npc) or sell_p <= 0 or owned < q
