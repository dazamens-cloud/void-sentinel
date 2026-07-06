class_name ForjaScreenUI
extends Control
# ============================================================
# ForjaScreen.gd
# Pantalla de la Forja: las 8 HABILIDADES manuales.
# Ref. de diseño: VoidSentinel_Habilidades_Manuales.docx.
#
# 2 tabs (OFENSIVAS / DEFENSIVAS). Por cada habilidad:
#   - Bloqueada:   botón DESBLOQUEAR (gasta fragmentos).
#   - Desbloqueada: toggle ACTIVA/INACTIVA + líneas de mejora.
# Toda la lógica/persistencia vive en el autoload HabilidadManager.
# El efecto in-run de cada habilidad se implementa aparte (gameplay).
# ============================================================

var _lbl_frag: Label
var _lista: VBoxContainer
var _current_cat: String = "ofensiva"
var _tab_buttons: Dictionary = {}

const CAT_COLOR := {
	"ofensiva": MenuTheme.CAT_ATAQUE,
	"defensiva": MenuTheme.CAT_DEFENSA,
}
const CAT_LABEL := {
	"ofensiva": "OFENSIVAS",
	"defensiva": "DEFENSIVAS",
}


func _ready() -> void:
	_build()
	if HabilidadManager.has_signal("habilidad_cambiada"):
		HabilidadManager.habilidad_cambiada.connect(_on_habilidad_cambiada)
	if HabilidadManager.has_signal("seleccion_cambiada"):
		HabilidadManager.seleccion_cambiada.connect(_on_seleccion_cambiada)
	var eco := get_node_or_null("/root/Economia")
	if eco and eco.has_signal("fragmentos_actualizados"):
		eco.fragmentos_actualizados.connect(_on_fragmentos_actualizados)


func _exit_tree() -> void:
	# ✅ Desconectar signals para prevenir memory leak
	if HabilidadManager.habilidad_cambiada.is_connected(_on_habilidad_cambiada):
		HabilidadManager.habilidad_cambiada.disconnect(_on_habilidad_cambiada)
	if HabilidadManager.seleccion_cambiada.is_connected(_on_seleccion_cambiada):
		HabilidadManager.seleccion_cambiada.disconnect(_on_seleccion_cambiada)
	var eco := get_node_or_null("/root/Economia")
	if eco and eco.fragmentos_actualizados.is_connected(_on_fragmentos_actualizados):
		eco.fragmentos_actualizados.disconnect(_on_fragmentos_actualizados)


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

	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 10)
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_lista)

	_refrescar()


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
	eyebrow.text = "HABILIDADES MANUALES"
	eyebrow.add_theme_font_size_override("font_size", 10)
	eyebrow.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(eyebrow)
	var title := Label.new()
	title.text = "FORJA"
	title.add_theme_font_size_override("font_size", 26)
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
	lbl.add_theme_font_size_override("font_size", 10)
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
	icon.add_theme_font_size_override("font_size", 15)
	icon.add_theme_color_override("font_color", MenuTheme.FRAG)
	_lbl_frag = Label.new()
	_lbl_frag.text = _format_number(_leer_frag())
	_lbl_frag.add_theme_font_size_override("font_size", 16)
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
	h.add_child(_make_tab_button("ofensiva"))
	h.add_child(_make_tab_button("defensiva"))
	return margin


func _make_tab_button(cat: String) -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 40)
	var lbl := Label.new()
	lbl.text = CAT_LABEL[cat]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_hud_font(lbl)
	btn.add_child(lbl)
	btn.set_meta("label", lbl)
	btn.pressed.connect(func(): _switch_cat(cat))
	_tab_buttons[cat] = btn
	return btn


func _switch_cat(cat: String) -> void:
	_current_cat = cat
	_refrescar()


func _update_tab_colors() -> void:
	for cat in _tab_buttons.keys():
		var lbl: Label = _tab_buttons[cat].get_meta("label")
		var col: Color = CAT_COLOR[cat] if cat == _current_cat else MenuTheme.TEXT_MUTED
		lbl.add_theme_color_override("font_color", col)


# ✅ Optimizaciones: actualizar solo lo que cambió (no rebuild completo)
func _on_habilidad_cambiada() -> void:
	_refresh_frag()

func _on_seleccion_cambiada() -> void:
	_refrescar()

func _on_fragmentos_actualizados() -> void:
	_refresh_frag()  # Solo actualizar fragmentos, no recrear lista


# ------------------------------------------------------------
# REFRESCO: reconstruye la lista de la categoría actual.
# ------------------------------------------------------------
func _refrescar(_a = null) -> void:
	if _lista == null:
		return
	_refresh_frag()
	_update_tab_colors()
	for c in _lista.get_children():
		c.queue_free()
	for id in HabilidadManager.ids_por_tipo(_current_cat):
		_lista.add_child(_make_card(id))


# ------------------------------------------------------------
# CARD de una habilidad.
# ------------------------------------------------------------
func _make_card(id: String) -> Control:
	var hab: Dictionary = HabilidadManager.get_hab(id)
	var accent: Color = CAT_COLOR.get(hab.get("tipo", "ofensiva"), MenuTheme.CYAN)
	var desbloqueada: bool = HabilidadManager.esta_desbloqueada(id)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(MenuTheme.BORDER_DIM))
	if not desbloqueada:
		panel.modulate.a = 0.85

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	# Cabecera: nombre + cooldown.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var name_lbl := Label.new()
	name_lbl.text = hab.get("nombre", id)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", accent)
	_apply_hud_font(name_lbl)
	var cd_lbl := Label.new()
	cd_lbl.text = "CD %ss" % _fmt_num(HabilidadManager.get_cooldown(id))
	cd_lbl.add_theme_font_size_override("font_size", 11)
	cd_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(cd_lbl)
	head.add_child(name_lbl)
	head.add_child(cd_lbl)
	v.add_child(head)

	# Descripción.
	var desc := Label.new()
	desc.text = hab.get("descripcion", "")
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)

	if not desbloqueada:
		v.add_child(_make_unlock_button(id, accent))
	else:
		v.add_child(_make_toggle_button(id, accent))
		v.add_child(_make_sep(accent))
		for mid in hab.get("mejoras", {}).keys():
			v.add_child(_make_mejora_row(id, mid, accent))

	return panel


func _make_unlock_button(id: String, accent: Color) -> Control:
	var coste: int = HabilidadManager.get_hab(id).get("coste_desbloqueo", 0)
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 34)
	btn.text = "DESBLOQUEAR  %s %s" % [MenuTheme.SYM_FRAG, _format_number(coste)]
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_stylebox_override("normal", MenuTheme.make_button_style(accent))
	btn.add_theme_stylebox_override("hover", MenuTheme.make_button_style(accent, true))
	btn.add_theme_stylebox_override("pressed", MenuTheme.make_button_style(accent, true))
	_apply_hud_font(btn)
	btn.modulate.a = 1.0 if _leer_frag() >= coste else 0.4
	btn.pressed.connect(func(): _on_desbloquear(id))
	return btn


func _make_toggle_button(id: String, accent: Color) -> Control:
	var activa: bool = HabilidadManager.esta_activa(id)
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 30)
	btn.text = "✓ ACTIVA  (en partida)" if activa else "INACTIVA  (toca para activar)"
	btn.add_theme_font_size_override("font_size", 11)
	var col: Color = accent if activa else MenuTheme.TEXT_MUTED
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_stylebox_override("normal", MenuTheme.make_button_style(col, activa))
	btn.add_theme_stylebox_override("hover", MenuTheme.make_button_style(col, true))
	btn.add_theme_stylebox_override("pressed", MenuTheme.make_button_style(col, true))
	_apply_hud_font(btn)
	btn.pressed.connect(func(): HabilidadManager.toggle_activa(id))
	return btn


# Fila de una línea de mejora: nombre + nivel/max + botón coste/MAX.
func _make_mejora_row(id: String, mid: String, accent: Color) -> Control:
	var hab := HabilidadManager.get_hab(id)
	var m: Dictionary = hab.get("mejoras", {}).get(mid, {})
	var es_toggle: bool = m.get("max_nivel", 1) == 1 and m.get("afecta", "") == ""
	var nivel: int = HabilidadManager.get_nivel(id, mid)
	var es_max: bool = HabilidadManager.es_max_mejora(id, mid)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	var nom := Label.new()
	nom.text = m.get("nombre", mid)
	nom.add_theme_font_size_override("font_size", 11)
	nom.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(nom)
	info.add_child(nom)
	if not es_toggle:
		var prog := Label.new()
		prog.text = "%d/%d" % [nivel, m.get("max_nivel", 0)]
		prog.add_theme_font_size_override("font_size", 10)
		prog.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
		_apply_hud_font(prog)
		info.add_child(prog)
	h.add_child(info)

	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(96, 28)
	btn.add_theme_font_size_override("font_size", 11)
	_apply_hud_font(btn)
	if es_max:
		btn.text = "✓" if es_toggle else "MAX"
		btn.add_theme_color_override("font_color", MenuTheme.GOLD)
		btn.disabled = true
	else:
		var coste := HabilidadManager.get_coste_mejora(id, mid)
		btn.text = "%s %s" % [MenuTheme.SYM_FRAG, _format_number(coste)]
		btn.add_theme_color_override("font_color", accent)
		btn.add_theme_stylebox_override("normal", MenuTheme.make_button_style(accent))
		btn.add_theme_stylebox_override("hover", MenuTheme.make_button_style(accent, true))
		btn.add_theme_stylebox_override("pressed", MenuTheme.make_button_style(accent, true))
		btn.modulate.a = 1.0 if _leer_frag() >= coste else 0.4
		btn.pressed.connect(func(): _on_mejorar(id, mid))
	h.add_child(btn)
	return h


func _make_sep(accent: Color) -> Control:
	var line := ColorRect.new()
	line.color = Color(accent.r, accent.g, accent.b, 0.18)
	line.custom_minimum_size = Vector2(0, 1)
	return line


# ------------------------------------------------------------
# ACCIONES.
# ------------------------------------------------------------
func _on_desbloquear(id: String) -> void:
	var coste: int = HabilidadManager.get_hab(id).get("coste_desbloqueo", 0)
	if _leer_frag() < coste:
		_toast("Fragmentos insuficientes")
		return
	if HabilidadManager.desbloquear(id):
		_toast("Desbloqueada: " + HabilidadManager.get_hab(id).get("nombre", id))


func _on_mejorar(id: String, mid: String) -> void:
	if _leer_frag() < HabilidadManager.get_coste_mejora(id, mid):
		_toast("Fragmentos insuficientes")
		return
	HabilidadManager.mejorar(id, mid)


# ------------------------------------------------------------
# Refresco / helpers.
# ------------------------------------------------------------
func on_show() -> void:
	_refrescar()


func _refresh_frag() -> void:
	if _lbl_frag:
		_lbl_frag.text = _format_number(_leer_frag())


func _leer_frag() -> int:
	var eco := get_node_or_null("/root/Economia")
	if eco and "fragmentos" in eco:
		return eco.fragmentos
	return 0


func _toast(msg: String) -> void:
	push_warning("[Forja] ", msg)


# Formatea un float quitando decimales innecesarios (18.0 -> "18", 1.5 -> "1.5").
func _fmt_num(n: float) -> String:
	if absf(n - round(n)) < 0.001:
		return str(int(round(n)))
	return str(snappedf(n, 0.1))


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
