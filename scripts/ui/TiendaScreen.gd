class_name TiendaScreenUI
extends Control
# ============================================================
# TiendaScreen.gd
# Pantalla de tienda. 3 tabs: Gemas, Recursos, Paquetes.
# Usa Gemas (moneda premium).
#
# CONEXION CON EL JUEGO:
#   - Las compras con dinero real (IAP) y la recompensa diaria por
#     anuncio se conectan en FASE 8 del roadmap. Aqui hay logica
#     de demo y TODOs marcados.
# ============================================================

const MAGENTA := MenuTheme.MAGENTA

var _gems: int = 240
var _lbl_gems: Label
var _daily_claimed: bool = false
var _current_tab: String = "gemas"
var _sections: Dictionary = {}
var _tab_buttons: Dictionary = {}


func _ready() -> void:
	_build()


func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	root.add_child(_make_header())
	root.add_child(_make_tabs())

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var lists := Control.new()
	lists.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lists.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(lists)

	_sections["gemas"] = _make_gems_section()
	_sections["recursos"] = _make_resources_section()
	_sections["paquetes"] = _make_bundles_section()

	for key in _sections.keys():
		var s: Control = _sections[key]
		s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		s.visible = (key == _current_tab)
		lists.add_child(s)


# ------------------------------------------------------------
# HEADER.
# ------------------------------------------------------------
func _make_header() -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	var h := HBoxContainer.new()
	margin.add_child(h)

	var tb := VBoxContainer.new()
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.add_theme_constant_override("separation", 2)
	var eyebrow := Label.new()
	eyebrow.text = "RECURSOS Y MEJORAS"
	eyebrow.add_theme_font_size_override("font_size", 10)
	eyebrow.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(eyebrow)
	var title := Label.new()
	title.text = "TIENDA"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", MAGENTA)
	_apply_hud_font(title)
	tb.add_child(eyebrow)
	tb.add_child(title)
	h.add_child(tb)

	# Pildora de gemas.
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_END
	var lbl := Label.new()
	lbl.text = "GEMAS"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(lbl)
	var pill := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.08)
	style.border_color = Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(20)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", style)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 5)
	var icon := Label.new()
	icon.text = MenuTheme.SYM_GEM
	icon.add_theme_font_size_override("font_size", 15)
	icon.add_theme_color_override("font_color", MAGENTA)
	_lbl_gems = Label.new()
	_lbl_gems.text = _format_number(_gems)
	_lbl_gems.add_theme_font_size_override("font_size", 16)
	_lbl_gems.add_theme_color_override("font_color", MAGENTA)
	_apply_hud_font(_lbl_gems)
	ph.add_child(icon)
	ph.add_child(_lbl_gems)
	pill.add_child(ph)
	v.add_child(lbl)
	v.add_child(pill)
	h.add_child(v)
	return margin


# ------------------------------------------------------------
# TABS.
# ------------------------------------------------------------
func _make_tabs() -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(MenuTheme.BORDER_GLOW))
	margin.add_child(panel)
	var h := HBoxContainer.new()
	panel.add_child(h)
	h.add_child(_make_tab_button("gemas", "GEMAS"))
	h.add_child(_make_tab_button("recursos", "RECURSOS"))
	h.add_child(_make_tab_button("paquetes", "PAQUETES"))
	return margin


func _make_tab_button(tab: String, label: String) -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 40)
	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_hud_font(lbl)
	btn.add_child(lbl)
	btn.set_meta("label", lbl)
	btn.pressed.connect(func(): _switch_tab(tab))
	_tab_buttons[tab] = btn
	return btn


func _switch_tab(tab: String) -> void:
	_current_tab = tab
	for key in _sections.keys():
		_sections[key].visible = (key == tab)
	_update_tab_colors()


func _update_tab_colors() -> void:
	for tab in _tab_buttons.keys():
		var btn: Button = _tab_buttons[tab]
		var lbl: Label = btn.get_meta("label")
		var col: Color = MAGENTA if tab == _current_tab else MenuTheme.TEXT_MUTED
		lbl.add_theme_color_override("font_color", col)


# ------------------------------------------------------------
# SECCION GEMAS: recompensa diaria + grid de packs.
# ------------------------------------------------------------
func _make_gems_section() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Recompensa diaria.
	v.add_child(_make_daily_banner())

	# Grid de packs de gemas.
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.add_child(_make_gem_pack("110", "", "4.99 EUR", false))
	grid.add_child(_make_gem_pack("248", "+13% mas", "9.99 EUR", true))
	grid.add_child(_make_gem_pack("550", "+25% mas", "22.99 EUR", false))
	grid.add_child(_make_gem_pack("1200", "+45% mas", "49.99 EUR", false))
	grid.add_child(_make_gem_pack("2800", "+75% mas", "99.99 EUR", false))
	v.add_child(grid)

	return v


func _make_daily_banner() -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MenuTheme.BG_MID.r, MenuTheme.BG_MID.g, MenuTheme.BG_MID.b, 0.9)
	style.border_color = Color(MenuTheme.GREEN.r, MenuTheme.GREEN.g, MenuTheme.GREEN.b, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	panel.add_child(h)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	var lbl := Label.new()
	lbl.text = "RECOMPENSA DIARIA"
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", MenuTheme.GREEN)
	_apply_hud_font(lbl)
	var t := Label.new()
	t.text = "Ver un anuncio gratis"
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	var timer := Label.new()
	timer.text = "Siguiente en 17h 24m"
	timer.add_theme_font_size_override("font_size", 11)
	timer.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(timer)
	info.add_child(lbl)
	info.add_child(t)
	info.add_child(timer)
	h.add_child(info)

	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = "+5 " + MenuTheme.SYM_GEM
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", MAGENTA)
	btn.add_theme_stylebox_override("normal", MenuTheme.make_button_style(MenuTheme.GREEN, true))
	btn.add_theme_stylebox_override("hover", MenuTheme.make_button_style(MenuTheme.GREEN, true))
	btn.add_theme_stylebox_override("pressed", MenuTheme.make_button_style(MenuTheme.GREEN, true))
	_apply_hud_font(btn)
	btn.pressed.connect(_on_daily)
	h.add_child(btn)

	return panel


func _make_gem_pack(amount: String, bonus: String, price: String, best: bool) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MenuTheme.BG_MID.r, MenuTheme.BG_MID.g, MenuTheme.BG_MID.b, 0.85)
	if best:
		style.border_color = Color(MenuTheme.GOLD.r, MenuTheme.GOLD.g, MenuTheme.GOLD.b, 0.35)
	else:
		style.border_color = Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.15)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 12
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	# VBox de contenido como hijo directo (da el minimum size de la card) y
	# Button flat encima: el PanelContainer estira ambos a su rect.
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon := Label.new()
	icon.text = MenuTheme.SYM_GEM
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 26)
	icon.add_theme_color_override("font_color", MAGENTA)
	var amt := Label.new()
	amt.text = amount
	amt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amt.add_theme_font_size_override("font_size", 17)
	amt.add_theme_color_override("font_color", MAGENTA)
	_apply_hud_font(amt)
	var bon := Label.new()
	bon.text = bonus if bonus != "" else " "
	bon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bon.add_theme_font_size_override("font_size", 12)
	bon.add_theme_color_override("font_color", MenuTheme.GREEN)
	_apply_hud_font(bon)
	var pr := Label.new()
	pr.text = price
	pr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pr.add_theme_font_size_override("font_size", 14)
	pr.add_theme_color_override("font_color", MenuTheme.GOLD)
	_apply_hud_font(pr)

	v.add_child(icon)
	v.add_child(amt)
	v.add_child(bon)
	v.add_child(pr)
	panel.add_child(v)

	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func(): _on_buy_iap(amount + " gemas", price))
	panel.add_child(btn)

	return panel


# ------------------------------------------------------------
# SECCION RECURSOS.
# ------------------------------------------------------------
func _make_resources_section() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	v.add_child(_make_resource_card("ECOS", MenuTheme.SYM_ECOS, "Divisa para el Nexo", MenuTheme.CYAN,
		[["250", 30], ["800", 80], ["2K", 180]]))
	v.add_child(_make_resource_card("FRAGMENTOS", MenuTheme.SYM_FRAG, "Para la Forja", MenuTheme.VIOLET,
		[["100", 25], ["300", 65], ["800", 150]]))
	v.add_child(_make_resource_card("ENERGIA DE ARRANQUE", MenuTheme.SYM_ENERGIA, "Extra al inicio de tu run", MenuTheme.GOLD,
		[["+5K", 20], ["+20K", 60], ["+100K", 120], ["+500K", 250]]))

	return v


func _make_resource_card(nombre: String, sym: String, desc: String, color: Color, tiers: Array) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MenuTheme.BG_MID.r, MenuTheme.BG_MID.g, MenuTheme.BG_MID.b, 0.85)
	style.border_color = Color(color.r, color.g, color.b, 0.15)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var icon := Label.new()
	icon.text = sym
	icon.add_theme_font_size_override("font_size", 26)
	icon.add_theme_color_override("font_color", color)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl := Label.new()
	name_lbl.text = nombre
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", color)
	_apply_hud_font(name_lbl)
	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	titles.add_child(name_lbl)
	titles.add_child(desc_lbl)
	head.add_child(icon)
	head.add_child(titles)
	v.add_child(head)

	# Botones de tiers.
	var tiers_row := HBoxContainer.new()
	tiers_row.add_theme_constant_override("separation", 4)
	for tier in tiers:
		var amount: String = tier[0]
		var cost: int = tier[1]
		tiers_row.add_child(_make_tier_button(amount, cost, color))
	v.add_child(tiers_row)

	return panel


func _make_tier_button(amount: String, cost: int, color: Color) -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_stylebox_override("normal", MenuTheme.make_button_style(color))
	btn.add_theme_stylebox_override("hover", MenuTheme.make_button_style(color, true))
	btn.add_theme_stylebox_override("pressed", MenuTheme.make_button_style(color, true))

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var amt := Label.new()
	amt.text = amount
	amt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amt.add_theme_font_size_override("font_size", 12)
	amt.add_theme_color_override("font_color", color)
	_apply_hud_font(amt)
	var pr := Label.new()
	pr.text = "%d %s" % [cost, MenuTheme.SYM_GEM]
	pr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pr.add_theme_font_size_override("font_size", 10)
	pr.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(pr)
	v.add_child(amt)
	v.add_child(pr)
	btn.add_child(v)

	btn.pressed.connect(func(): _on_buy_resource(amount, cost))
	return btn


# ------------------------------------------------------------
# SECCION PAQUETES.
# ------------------------------------------------------------
func _make_bundles_section() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	v.add_child(_make_bundle("starter", "Starter", "Pack Iniciado", "1.99 EUR", "",
		["50 " + MenuTheme.SYM_GEM, "200 " + MenuTheme.SYM_ECOS, "50 " + MenuTheme.SYM_FRAG]))
	v.add_child(_make_bundle("valor", "Valor", "Pack Centinela", "9.99 EUR", "14.99 EUR",
		["248 " + MenuTheme.SYM_GEM, "1,000 " + MenuTheme.SYM_ECOS, "250 " + MenuTheme.SYM_FRAG, "x2 Ecos 24h"]))
	v.add_child(_make_bundle("elite", "Elite", "Pack Nexo", "34.99 EUR", "49.99 EUR",
		["750 " + MenuTheme.SYM_GEM, "4,000 " + MenuTheme.SYM_ECOS, "800 " + MenuTheme.SYM_FRAG, "Modulo Epico"]))
	v.add_child(_make_bundle("void", "Void", "Pack Supremo", "66.99 EUR", "99.99 EUR",
		["2,000 " + MenuTheme.SYM_GEM, "10,000 " + MenuTheme.SYM_ECOS, "2,000 " + MenuTheme.SYM_FRAG, "Modulo Legendario"]))

	return v


func _make_bundle(tier: String, tier_name: String, nombre: String, price: String, old_price: String, contents: Array) -> Control:
	var accent := MenuTheme.CYAN
	match tier:
		"starter": accent = MenuTheme.R_COMUN
		"valor":   accent = MenuTheme.CYAN
		"elite":   accent = MenuTheme.VIOLET
		"void":    accent = MenuTheme.GOLD

	var panel := PanelContainer.new()
	var style := MenuTheme.make_card_style(Color(accent.r, accent.g, accent.b, 0.22))
	style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", style)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	panel.add_child(h)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 5)
	# Badge de tier.
	var badge := PanelContainer.new()
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color = Color(accent.r, accent.g, accent.b, 0.12)
	bstyle.border_color = Color(accent.r, accent.g, accent.b, 0.3)
	bstyle.set_border_width_all(1)
	bstyle.set_corner_radius_all(3)
	bstyle.content_margin_left = 6
	bstyle.content_margin_right = 6
	bstyle.content_margin_top = 1
	bstyle.content_margin_bottom = 1
	badge.add_theme_stylebox_override("panel", bstyle)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var blbl := Label.new()
	blbl.text = tier_name.to_upper()
	blbl.add_theme_font_size_override("font_size", 7)
	blbl.add_theme_color_override("font_color", accent)
	_apply_hud_font(blbl)
	badge.add_child(blbl)

	var name_lbl := Label.new()
	name_lbl.text = nombre
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(name_lbl)

	# Contenido (pildoras pequenas).
	var contents_flow := HBoxContainer.new()
	contents_flow.add_theme_constant_override("separation", 6)
	for c in contents:
		var cpill := Label.new()
		cpill.text = c
		cpill.add_theme_font_size_override("font_size", 10)
		cpill.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
		_apply_hud_font(cpill)
		contents_flow.add_child(cpill)

	info.add_child(badge)
	info.add_child(name_lbl)
	info.add_child(contents_flow)
	h.add_child(info)

	# Derecha: precio + boton.
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 4)
	if old_price != "":
		var old := Label.new()
		old.text = old_price
		old.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		old.add_theme_font_size_override("font_size", 11)
		old.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
		_apply_hud_font(old)
		right.add_child(old)
	var pr := Label.new()
	pr.text = price
	pr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pr.add_theme_font_size_override("font_size", 18)
	pr.add_theme_color_override("font_color", accent)
	_apply_hud_font(pr)
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = "Comprar"
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_stylebox_override("normal", MenuTheme.make_button_style(accent))
	btn.add_theme_stylebox_override("hover", MenuTheme.make_button_style(accent, true))
	btn.add_theme_stylebox_override("pressed", MenuTheme.make_button_style(accent, true))
	_apply_hud_font(btn)
	btn.pressed.connect(func(): _on_buy_iap(nombre, price))
	right.add_child(pr)
	right.add_child(btn)
	h.add_child(right)

	return panel


# ------------------------------------------------------------
# ACCIONES.
# ------------------------------------------------------------
func _on_daily() -> void:
	if _daily_claimed:
		_toast("Ya reclamaste hoy")
		return
	_daily_claimed = true
	_gems += 5
	_lbl_gems.text = _format_number(_gems)
	# TODO: integrar con AdMob rewarded ad (FASE 8 del roadmap).
	_toast("+5 gemas recibidas")


func _on_buy_resource(amount: String, cost: int) -> void:
	if _gems < cost:
		_toast("Gemas insuficientes")
		return
	_gems -= cost
	_lbl_gems.text = _format_number(_gems)
	# TODO: sumar el recurso real (Ecos/Frag/Energia) via Economia.
	_toast(amount + " adquiridos")


func _on_buy_iap(nombre: String, price: String) -> void:
	# TODO: integrar con sistema IAP real (FASE 8 del roadmap).
	_toast("Comprar: " + nombre + " - " + price)


# ------------------------------------------------------------
# Helpers.
# ------------------------------------------------------------
func on_show() -> void:
	_update_tab_colors()


func _toast(msg: String) -> void:
	push_warning("[Tienda] ", msg)


func _format_number(n: int) -> String:
	var s := str(n)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
	return result


func _apply_hud_font(node) -> void:
	var f := MenuTheme.get_font_hud()
	if f and node.has_method("add_theme_font_override"):
		node.add_theme_font_override("font", f)
