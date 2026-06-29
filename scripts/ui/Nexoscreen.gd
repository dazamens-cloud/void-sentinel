class_name NexoScreen
extends Control
# ============================================================
# NexoScreen.gd  (REESCRITO - opcion B, data-driven)
#
# Lee TODAS las mejoras directamente de MejoraManager.mejoras
# y las filtra por categoria. Si anades/quitas una mejora en
# MejoraManager, aparece sola aqui sin tocar este script.
#
# FLUJO DE COMPRA CORRECTO (Nexo paga con ECOS, no Energia):
#   1. Verificar nivel < max y no bloqueada
#   2. Leer coste de MejoraManager.get_coste(id)
#   3. Verificar Economia.ecos >= coste
#   4. Llamar Economia.gastar_ecos(coste) -> bool
#   5. Si OK, llamar MejoraManager.subir_nivel_nexo(id)
#   6. Refrescar UI desde las senales mejoras_actualizadas y
#      recursos_actualizados
#
# Las mejoras de categoria "commander" se OCULTAN (van en Forja).
# ============================================================

# Cache de referencias a autoloads (se setean en _ready).
var _eco: Node = null
var _mm: Node = null

# Label del saldo de Ecos en el header (refrescado por senal).
var _lbl_ecos: Label

# Pestana actual.
var _current_cat: String = "ataque"
var _sections: Dictionary = {}      # "ataque" -> VBoxContainer con las cards
var _tab_buttons: Dictionary = {}   # "ataque" -> Button del tab

# Cards generadas (id_mejora -> dict con refs a labels/botones para refrescar).
var _card_refs: Dictionary = {}

# Categorias visibles en el Nexo (commander NO se muestra aqui).
const CATS_VISIBLES := ["ataque", "defensa", "bonificacion"]

# Color por categoria.
const CAT_COLORS := {
	"ataque": MenuTheme.CAT_ATAQUE,
	"defensa": MenuTheme.CAT_DEFENSA,
	"bonificacion": MenuTheme.CAT_BONIFICACION,
}

# Etiquetas de los tabs (mas cortas que la categoria).
const CAT_LABELS := {
	"ataque": "ATAQUE",
	"defensa": "DEFENSA",
	"bonificacion": "BONIFIC.",
}


func _ready() -> void:
	_eco = get_node_or_null("/root/Economia")
	_mm = get_node_or_null("/root/MejoraManager")

	if _eco == null:
		push_warning("NexoScreen: autoload 'Economia' no encontrado, usando placeholders")
	if _mm == null:
		push_warning("NexoScreen: autoload 'MejoraManager' no encontrado, usando placeholders")

	_build()

	# Conectar senales de los autoloads para refresco automatico.
	# Asi cuando otras partes del juego cambien ecos o mejoras, la UI
	# se mantiene sincronizada sin necesidad de pollear.
	if _eco and _eco.has_signal("recursos_actualizados"):
		if not _eco.recursos_actualizados.is_connected(_on_recursos_actualizados):
			_eco.recursos_actualizados.connect(_on_recursos_actualizados)
	if _mm and _mm.has_signal("mejoras_actualizadas"):
		if not _mm.mejoras_actualizadas.is_connected(_on_mejoras_actualizadas):
			_mm.mejoras_actualizadas.connect(_on_mejoras_actualizadas)


func _exit_tree() -> void:
	# ✅ Desconectar signals para prevenir memory leak
	if _eco and _eco.recursos_actualizados.is_connected(_on_recursos_actualizados):
		_eco.recursos_actualizados.disconnect(_on_recursos_actualizados)
	if _mm and _mm.mejoras_actualizadas.is_connected(_on_mejoras_actualizadas):
		_mm.mejoras_actualizadas.disconnect(_on_mejoras_actualizadas)


# ------------------------------------------------------------
# CONSTRUCCION DE LA UI.
# ------------------------------------------------------------
func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	root.add_child(_make_header())
	root.add_child(_make_tabs())

	# Scroll con las listas.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	# Contenedor donde apilamos las 3 secciones (solo una visible).
	var lists := Control.new()
	lists.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lists.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(lists)

	for cat in CATS_VISIBLES:
		var section := _make_category_list(cat)
		section.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		section.visible = (cat == _current_cat)
		_sections[cat] = section
		lists.add_child(section)

	_update_tab_colors()


# ------------------------------------------------------------
# HEADER (titulo "NEXO" + pildora con saldo de Ecos).
# ------------------------------------------------------------
func _make_header() -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)

	var h := HBoxContainer.new()
	margin.add_child(h)

	var titleblock := VBoxContainer.new()
	titleblock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titleblock.add_theme_constant_override("separation", 2)

	var eyebrow := Label.new()
	eyebrow.text = "MEJORAS PERMANENTES"
	eyebrow.add_theme_font_size_override("font_size", 10)
	eyebrow.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(eyebrow)

	var title := Label.new()
	title.text = "NEXO"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", MenuTheme.CYAN)
	_apply_hud_font(title)

	titleblock.add_child(eyebrow)
	titleblock.add_child(title)
	h.add_child(titleblock)

	h.add_child(_make_balance_pill())

	return margin


func _make_balance_pill() -> Control:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_END

	var lbl := Label.new()
	lbl.text = "ECOS"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(lbl)

	var pill := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MenuTheme.CYAN.r, MenuTheme.CYAN.g, MenuTheme.CYAN.b, 0.08)
	style.border_color = Color(MenuTheme.CYAN.r, MenuTheme.CYAN.g, MenuTheme.CYAN.b, 0.25)
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
	icon.text = MenuTheme.SYM_ECOS
	icon.add_theme_font_size_override("font_size", 15)
	icon.add_theme_color_override("font_color", MenuTheme.CYAN)

	_lbl_ecos = Label.new()
	_lbl_ecos.text = _format_number(_get_ecos())
	_lbl_ecos.add_theme_font_size_override("font_size", 16)
	_lbl_ecos.add_theme_color_override("font_color", MenuTheme.CYAN)
	_apply_hud_font(_lbl_ecos)

	ph.add_child(icon)
	ph.add_child(_lbl_ecos)
	pill.add_child(ph)

	v.add_child(lbl)
	v.add_child(pill)
	return v


# ------------------------------------------------------------
# TABS de categoria.
# ------------------------------------------------------------
func _make_tabs() -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(MenuTheme.BORDER_GLOW))
	margin.add_child(panel)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	panel.add_child(h)

	for cat in CATS_VISIBLES:
		h.add_child(_make_tab_button(cat, CAT_LABELS[cat]))

	return margin


func _make_tab_button(cat: String, label: String) -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 40)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_hud_font(lbl)
	btn.add_child(lbl)
	btn.set_meta("label", lbl)

	btn.pressed.connect(func(): _switch_category(cat))
	_tab_buttons[cat] = btn
	return btn


func _switch_category(cat: String) -> void:
	_current_cat = cat
	for key in _sections.keys():
		_sections[key].visible = (key == cat)
	_update_tab_colors()


func _update_tab_colors() -> void:
	for cat in _tab_buttons.keys():
		var btn: Button = _tab_buttons[cat]
		var lbl: Label = btn.get_meta("label")
		var is_active: bool = (cat == _current_cat)
		var col: Color = CAT_COLORS[cat] if is_active else MenuTheme.TEXT_MUTED
		lbl.add_theme_color_override("font_color", col)


# ------------------------------------------------------------
# LISTA de mejoras de una categoria.
# Lee las mejoras directamente del MejoraManager (data-driven).
# ------------------------------------------------------------
func _make_category_list(cat: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Cabecera estilizada de la categoria.
	v.add_child(_make_section_heading(cat))

	# Si no hay MejoraManager, mostrar mensaje y salir.
	if _mm == null:
		var msg := Label.new()
		msg.text = "MejoraManager no disponible"
		msg.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
		v.add_child(msg)
		return v

	# Recorrer las mejoras del MejoraManager y filtrar por categoria.
	# Usamos un orden estable (claves del diccionario en orden de insercion).
	for id in _mm.mejoras.keys():
		var data: Dictionary = _mm.mejoras[id]
		if data.get("categoria", "") != cat:
			continue
		# Las bloqueadas (commander) ya estarian filtradas porque no esta
		# en CATS_VISIBLES, pero por seguridad las ocultamos tambien aqui.
		if data.get("bloqueado", false):
			continue
		v.add_child(_make_upgrade_card(id, data, cat))

	return v


func _make_section_heading(cat: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var color: Color = CAT_COLORS[cat]

	var line1 := ColorRect.new()
	line1.color = Color(color.r, color.g, color.b, 0.3)
	line1.custom_minimum_size = Vector2(0, 1)
	line1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line1.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var label := Label.new()
	label.text = CAT_LABELS[cat]
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	_apply_hud_font(label)

	var line2 := ColorRect.new()
	line2.color = Color(color.r, color.g, color.b, 0.3)
	line2.custom_minimum_size = Vector2(0, 1)
	line2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line2.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	h.add_child(line1)
	h.add_child(label)
	h.add_child(line2)
	return h


# Crea la card de una mejora. Guarda referencias para refrescar mas tarde.
func _make_upgrade_card(id: String, data: Dictionary, cat: String) -> Control:
	var accent: Color = CAT_COLORS[cat]

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(MenuTheme.BORDER_DIM))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	panel.add_child(h)

	# Info (nombre + descripcion + barra de progreso).
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)

	var name_lbl := Label.new()
	name_lbl.text = data.get("nombre", id)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = data.get("descripcion", "")
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var prog_row := HBoxContainer.new()
	prog_row.add_theme_constant_override("separation", 6)

	var track := ProgressBar.new()
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.custom_minimum_size = Vector2(0, 3)
	track.min_value = 0
	track.max_value = data.get("max_nivel", 1)
	track.value = data.get("nivel", 0)
	track.show_percentage = false
	track.add_theme_stylebox_override("background", MenuTheme.make_progress_track())
	track.add_theme_stylebox_override("fill", MenuTheme.make_progress_fill(accent))

	var lvl_lbl := Label.new()
	lvl_lbl.add_theme_font_size_override("font_size", 10)
	_apply_hud_font(lvl_lbl)

	prog_row.add_child(track)
	prog_row.add_child(lvl_lbl)

	info.add_child(name_lbl)
	info.add_child(desc_lbl)
	info.add_child(prog_row)
	h.add_child(info)

	# Derecha (boton de compra).
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 4)
	right.custom_minimum_size = Vector2(90, 0)

	var buy_btn := Button.new()
	buy_btn.flat = true
	buy_btn.focus_mode = Control.FOCUS_NONE
	buy_btn.add_theme_font_size_override("font_size", 11)
	buy_btn.add_theme_color_override("font_color", accent)
	buy_btn.add_theme_stylebox_override("normal", MenuTheme.make_button_style(accent))
	buy_btn.add_theme_stylebox_override("hover", MenuTheme.make_button_style(accent, true))
	buy_btn.add_theme_stylebox_override("pressed", MenuTheme.make_button_style(accent, true))
	_apply_hud_font(buy_btn)

	buy_btn.pressed.connect(func(): _on_buy(id))

	right.add_child(buy_btn)
	h.add_child(right)

	# Guardar refs para refresco posterior.
	_card_refs[id] = {
		"panel": panel,
		"track": track,
		"lvl_lbl": lvl_lbl,
		"buy_btn": buy_btn,
	}

	# Pintar estado inicial.
	_refresh_card(id)
	return panel


# ------------------------------------------------------------
# REFRESCO de una card concreta (estado tras compra o on_show).
# ------------------------------------------------------------
func _refresh_card(id: String) -> void:
	if not _card_refs.has(id):
		return
	if _mm == null:
		return
	if not _mm.mejoras.has(id):
		return

	var data: Dictionary = _mm.mejoras[id]
	var refs: Dictionary = _card_refs[id]
	var panel: PanelContainer = refs["panel"]
	var track: ProgressBar = refs["track"]
	var lvl_lbl: Label = refs["lvl_lbl"]
	var buy_btn: Button = refs["buy_btn"]

	# El Nexo refleja el nivel PERMANENTE (suelo), no el efectivo de partida.
	var nivel: int = data.get("nivel_nexo", 0)
	var maxn: int = data.get("max_nivel", 1)
	var es_max: bool = (nivel >= maxn)

	track.value = nivel
	track.max_value = maxn

	if es_max:
		lvl_lbl.text = "MAX"
		lvl_lbl.add_theme_color_override("font_color", MenuTheme.GOLD)
		buy_btn.text = "MAX"
		buy_btn.disabled = true
		panel.modulate.a = 0.55
	else:
		lvl_lbl.text = "%d/%d" % [nivel, maxn]
		lvl_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
		var coste: int = _mm.get_coste_nexo(id)
		buy_btn.text = "%s %s" % [MenuTheme.SYM_ECOS, _format_number(coste)]
		buy_btn.disabled = false
		panel.modulate.a = 1.0
		# Atenuar si no llega para pagar.
		buy_btn.modulate.a = 1.0 if _get_ecos() >= coste else 0.35


# ------------------------------------------------------------
# COMPRA: gasta Ecos y sube nivel en MejoraManager.
# ------------------------------------------------------------
func _on_buy(id: String) -> void:
	if _mm == null or _eco == null:
		print("[Nexo] Autoloads no disponibles, ignorando compra")
		return
	if not _mm.mejoras.has(id):
		return

	var data: Dictionary = _mm.mejoras[id]
	var nivel: int = data.get("nivel_nexo", 0)
	var maxn: int = data.get("max_nivel", 1)
	if nivel >= maxn:
		return
	if data.get("bloqueado", false):
		print("[Nexo] Mejora bloqueada: ", id)
		return

	var coste: int = _mm.get_coste_nexo(id)
	if _eco.ecos < coste:
		print("[Nexo] Ecos insuficientes (necesarios ", coste, ", tienes ", _eco.ecos, ")")
		return

	# Pagar en Ecos. Si por alguna razon falla (race condition), abortar.
	if not _eco.gastar_ecos(coste):
		print("[Nexo] gastar_ecos fallo")
		return

	# Subir nivel en MejoraManager (NO cobra, asume que ya pagamos).
	_mm.subir_nivel_nexo(id)
	# Las senales recursos_actualizados y mejoras_actualizadas haran el
	# refresco automatico del label de Ecos y de la card.
	print("[Nexo] Comprada: ", id, " (-", coste, " ecos)")


# ------------------------------------------------------------
# CALLBACKS de senales (refresco automatico).
# ------------------------------------------------------------
func _on_recursos_actualizados() -> void:
	_refresh_ecos_label()
	# Tambien atenuamos botones que ya no podemos pagar.
	for id in _card_refs.keys():
		_refresh_card(id)


func _on_mejoras_actualizadas() -> void:
	for id in _card_refs.keys():
		_refresh_card(id)


# ------------------------------------------------------------
# Refresco al mostrarse la pantalla (lo llama MainMenu).
# ------------------------------------------------------------
func on_show() -> void:
	_refresh_ecos_label()
	for id in _card_refs.keys():
		_refresh_card(id)
	_update_tab_colors()


func _refresh_ecos_label() -> void:
	if _lbl_ecos:
		_lbl_ecos.text = _format_number(_get_ecos())


# ------------------------------------------------------------
# Helpers.
# ------------------------------------------------------------
func _get_ecos() -> int:
	if _eco and "ecos" in _eco:
		return _eco.ecos
	return 0


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
