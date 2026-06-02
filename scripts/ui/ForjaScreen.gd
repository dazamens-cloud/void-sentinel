class_name ForjaScreenUI
extends Control
# ============================================================
# ForjaScreen.gd
# Pantalla de la Forja (Armeria contra Commander).
# Usa Fragmentos. 3 tabs: Equipado, Inventario, Forjar.
#
# CONEXION CON EL JUEGO:
#   - Saldo de Fragmentos del autoload Economia.
#   - Forjar/mejorar modulos: aqui logica de demo. Conecta con
#     tu sistema real cuando lo tengas (TODO marcado).
# ============================================================

var _frag: int = 384
var _lbl_frag: Label
var _current_tab: String = "equipamiento"
var _sections: Dictionary = {}
var _tab_buttons: Dictionary = {}

# Rarezas -> color.
const RAREZA_COLOR := {
	"comun": MenuTheme.R_COMUN,
	"raro": MenuTheme.R_RARO,
	"epico": MenuTheme.R_EPICO,
	"legendario": MenuTheme.R_LEGENDARIO,
}


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

	_sections["equipamiento"] = _make_equip_section()
	_sections["inventario"] = _make_inventory_section()
	_sections["forjar"] = _make_craft_section()

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
	eyebrow.text = "ARMERIA CONTRA COMMANDER"
	eyebrow.add_theme_font_size_override("font_size", 8)
	eyebrow.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(eyebrow)
	var title := Label.new()
	title.text = "FORJA"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", MenuTheme.FRAG)
	_apply_hud_font(title)
	tb.add_child(eyebrow)
	tb.add_child(title)
	h.add_child(tb)

	h.add_child(_make_frag_pill())
	return margin


func _make_frag_pill() -> Control:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_END
	var lbl := Label.new()
	lbl.text = "FRAGMENTOS"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(lbl)

	var pill := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MenuTheme.FRAG.r, MenuTheme.FRAG.g, MenuTheme.FRAG.b, 0.08)
	style.border_color = Color(MenuTheme.FRAG.r, MenuTheme.FRAG.g, MenuTheme.FRAG.b, 0.28)
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
	icon.text = MenuTheme.SYM_FRAG
	icon.add_theme_font_size_override("font_size", 13)
	icon.add_theme_color_override("font_color", MenuTheme.FRAG)
	_lbl_frag = Label.new()
	_lbl_frag.text = _format_number(_frag)
	_lbl_frag.add_theme_font_size_override("font_size", 14)
	_lbl_frag.add_theme_color_override("font_color", MenuTheme.FRAG)
	_apply_hud_font(_lbl_frag)
	ph.add_child(icon)
	ph.add_child(_lbl_frag)
	pill.add_child(ph)

	v.add_child(lbl)
	v.add_child(pill)
	return v


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
	h.add_child(_make_tab_button("equipamiento", "EQUIPADO"))
	h.add_child(_make_tab_button("inventario", "INVENTARIO"))
	h.add_child(_make_tab_button("forjar", "FORJAR"))
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
	lbl.add_theme_font_size_override("font_size", 8)
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
		var col: Color = MenuTheme.FRAG if tab == _current_tab else MenuTheme.TEXT_MUTED
		lbl.add_theme_color_override("font_color", col)


# ------------------------------------------------------------
# SECCION EQUIPADO: orbe con slots + strip de stats.
# ------------------------------------------------------------
func _make_equip_section() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Arena del Sentinel con slots (clase interna que dibuja).
	var arena := ForgeArena.new()
	arena.custom_minimum_size = Vector2(0, 240)
	v.add_child(arena)

	# Strip de stats agregadas.
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 8)
	strip.add_child(_make_stat_pill("+340", "DANO"))
	strip.add_child(_make_stat_pill("+18%", "DEF."))
	strip.add_child(_make_stat_pill("x1.6", "ECOS"))
	strip.add_child(_make_stat_pill("3/5", "SLOTS"))
	v.add_child(strip)

	return v


func _make_stat_pill(value: String, label: String) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(MenuTheme.BORDER_DIM, 0.8))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	panel.add_child(v)
	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.add_theme_font_size_override("font_size", 12)
	val.add_theme_color_override("font_color", MenuTheme.FRAG)
	_apply_hud_font(val)
	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(lbl)
	v.add_child(val)
	v.add_child(lbl)
	return panel


# ------------------------------------------------------------
# SECCION INVENTARIO: grid 3 columnas de modulos.
# ------------------------------------------------------------
func _make_inventory_section() -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)

	var modulos := [
		{"nombre": "Canon",    "rareza": "epico",      "lv": "Lv.4 EQ"},
		{"nombre": "Nucleo+",  "rareza": "legendario", "lv": "Lv.7 EQ"},
		{"nombre": "Escudo",   "rareza": "raro",       "lv": "Lv.2 EQ"},
		{"nombre": "Iones",    "rareza": "epico",      "lv": "Lv.1"},
		{"nombre": "Blindaje", "rareza": "comun",      "lv": "Lv.3"},
		{"nombre": "P.Vacio",  "rareza": "legendario", "lv": "Lv.1"},
	]
	for m in modulos:
		grid.add_child(_make_inventory_item(m))
	return grid


func _make_inventory_item(m: Dictionary) -> Control:
	var col: Color = RAREZA_COLOR[m["rareza"]]
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MenuTheme.BG_MID.r, MenuTheme.BG_MID.g, MenuTheme.BG_MID.b, 0.85)
	style.border_color = Color(col.r, col.g, col.b, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 3)
	panel.add_child(v)

	var name_lbl := Label.new()
	name_lbl.text = m["nombre"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 8)
	name_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(name_lbl)

	var lv_lbl := Label.new()
	lv_lbl.text = m["lv"]
	lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv_lbl.add_theme_font_size_override("font_size", 7)
	lv_lbl.add_theme_color_override("font_color", col)
	_apply_hud_font(lv_lbl)

	v.add_child(name_lbl)
	v.add_child(lv_lbl)
	return panel


# ------------------------------------------------------------
# SECCION FORJAR: 4 capsulas con coste y probabilidades.
# ------------------------------------------------------------
func _make_craft_section() -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)

	grid.add_child(_make_capsule("Capsula Basica", "Alta prob. comun/raro", 40))
	grid.add_child(_make_capsule("Capsula Avanz.", "Mayor prob. epico", 100))
	grid.add_child(_make_capsule("Capsula Nexo", "Garantizado epico+", 200))
	grid.add_child(_make_capsule("Capsula Void", "Legendario garantizado", 500))
	return grid


func _make_capsule(nombre: String, desc: String, coste: int) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(MenuTheme.BORDER_DIM))

	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(btn)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var name_lbl := Label.new()
	name_lbl.text = nombre
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var cost_lbl := Label.new()
	cost_lbl.text = "%s %d" % [MenuTheme.SYM_FRAG, coste]
	cost_lbl.add_theme_font_size_override("font_size", 10)
	cost_lbl.add_theme_color_override("font_color", MenuTheme.FRAG)
	_apply_hud_font(cost_lbl)

	v.add_child(name_lbl)
	v.add_child(desc_lbl)
	v.add_child(cost_lbl)
	btn.add_child(v)

	btn.pressed.connect(func(): _on_craft(nombre, coste))
	return panel


func _on_craft(nombre: String, coste: int) -> void:
	if _frag < coste:
		_toast("Fragmentos insuficientes")
		return
	_frag -= coste
	var eco := get_node_or_null("/root/Economia")
	if eco and "fragmentos" in eco:
		# TODO: descontar en el sistema real cuando exista forja.
		_frag = eco.fragmentos
	_lbl_frag.text = _format_number(_frag)
	# TODO: aqui generas el modulo aleatorio segun probabilidades.
	_toast("Forjado: " + nombre)


# ------------------------------------------------------------
# Refresco.
# ------------------------------------------------------------
func on_show() -> void:
	var eco := get_node_or_null("/root/Economia")
	if eco and "fragmentos" in eco:
		_frag = eco.fragmentos
		_lbl_frag.text = _format_number(_frag)
	_update_tab_colors()


func _toast(msg: String) -> void:
	print("[Forja] ", msg)


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


# ============================================================
# ForgeArena: clase interna que dibuja el Sentinel con anillos
# y posiciona los 5 slots de equipamiento alrededor.
# ============================================================
class ForgeArena extends Control:
	var _t: float = 0.0

	func _ready() -> void:
		_create_slots()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var center := size / 2.0
		var r := 32.0
		# Glow del nucleo.
		for i in range(5, 0, -1):
			draw_circle(center, r + i * 5.0, Color(0.59, 0.31, 0.86, 0.04))
		# Nucleo violeta.
		draw_circle(center, r, Color("32064b"))
		draw_circle(center - Vector2(r*0.2, r*0.2), r*0.7, Color("783cdc"))
		draw_circle(center - Vector2(r*0.3, r*0.3), r*0.35, Color("c8aaff"))
		# Anillo.
		draw_arc(center, 55, 0, TAU, 48, Color(0.70, 0.53, 1.0, 0.3), 1.0, true)
		var ang := _t * 0.7
		draw_circle(center + Vector2(cos(ang), sin(ang)) * 55.0, 3.0, MenuTheme.FRAG)

	# Coloca los 5 slots como labels alrededor del centro.
	func _create_slots() -> void:
		var slots := [
			{"sym": "C", "pos": "top",    "rareza": "epico",      "lv": "Lv.4"},
			{"sym": "E", "pos": "left",   "rareza": "raro",       "lv": "Lv.2"},
			{"sym": "N", "pos": "right",  "rareza": "legendario", "lv": "Lv.7"},
			{"sym": "+", "pos": "bottom", "rareza": "empty",      "lv": ""},
			{"sym": "L", "pos": "topr",   "rareza": "locked",     "lv": ""},
		]
		for s in slots:
			var slot := _make_slot(s)
			add_child(slot)

	func _make_slot(data: Dictionary) -> Control:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(52, 52)
		panel.size = Vector2(52, 52)

		var col := Color(MenuTheme.FRAG.r, MenuTheme.FRAG.g, MenuTheme.FRAG.b, 0.25)
		var rareza: String = data["rareza"]
		if rareza in ForjaScreenUI.RAREZA_COLOR:
			col = ForjaScreenUI.RAREZA_COLOR[rareza]

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.04, 0.14, 0.9)
		style.border_color = col
		style.set_border_width_all(1)
		style.set_corner_radius_all(10)
		panel.add_theme_stylebox_override("panel", style)

		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var lbl := Label.new()
		lbl.text = data["sym"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", col)
		v.add_child(lbl)
		if data["lv"] != "":
			var lv := Label.new()
			lv.text = data["lv"]
			lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lv.add_theme_font_size_override("font_size", 7)
			lv.add_theme_color_override("font_color", col)
			v.add_child(lv)
		panel.add_child(v)

		# Posicionar tras el layout (usamos call_deferred para tener size).
		panel.set_meta("pos", data["pos"])
		call_deferred("_position_slot", panel, data["pos"])
		return panel

	func _position_slot(panel: Control, pos: String) -> void:
		var c := size / 2.0
		var off := Vector2(26, 26)  # mitad del slot
		match pos:
			"top":    panel.position = Vector2(c.x - off.x, 14)
			"bottom": panel.position = Vector2(c.x - off.x, size.y - 66)
			"left":   panel.position = Vector2(14, c.y - off.y)
			"right":  panel.position = Vector2(size.x - 66, c.y - off.y)
			"topr":   panel.position = Vector2(size.x - 80, 36)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			for child in get_children():
				if child.has_meta("pos"):
					_position_slot(child, child.get_meta("pos"))
			
