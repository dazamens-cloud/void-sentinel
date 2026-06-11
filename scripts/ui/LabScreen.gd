class_name LabScreenUI
extends Control
# ============================================================
# LabScreen.gd
# Pantalla del LABORATORIO (investigaciones idle con timers reales).
#
# Data-driven: lee el catálogo de Laboratorio.INVESTIGACIONES y lo
# filtra por categoría. Si añades una investigación al autoload,
# aparece sola aquí sin tocar este script.
#
# Construida 100% por código (patrón NexoScreen/HomeScreen).
# Se accede desde la card "LABORATORIO" del Home (MainMenu.navigate("lab")).
#
# FLUJO:
#   - INVESTIGAR: paga ecos (Laboratorio.iniciar) y arranca el timer real.
#   - En curso: barra de progreso + tiempo restante + ACELERAR (fragmentos).
#   - Completada: el bonus pasivo aplica solo (NexusStats/Economia lo leen).
# ============================================================

var _lab: Node = null
var _eco: Node = null

var _lbl_ecos: Label
var _lbl_slots: Label

var _current_cat: String = "principal"
var _sections: Dictionary = {}     # cat -> VBoxContainer con las cards
var _tab_buttons: Dictionary = {}  # cat -> Button
var _card_refs: Dictionary = {}    # id -> dict con refs a controles

const CATS := ["principal", "ataque", "defensa", "utilidad"]

const CAT_COLORS := {
	"principal": MenuTheme.GOLD,
	"ataque": MenuTheme.CAT_ATAQUE,
	"defensa": MenuTheme.CAT_DEFENSA,
	"utilidad": MenuTheme.GREEN,
}

const CAT_LABELS := {
	"principal": "PRINCIPAL",
	"ataque": "ATAQUE",
	"defensa": "DEFENSA",
	"utilidad": "UTILIDAD",
}

# Timer de refresco de progreso (solo refresca si la pantalla es visible).
var _timer_ui: Timer


func _ready() -> void:
	_lab = get_node_or_null("/root/Laboratorio")
	_eco = get_node_or_null("/root/Economia")

	if _lab == null:
		push_warning("LabScreen: autoload 'Laboratorio' no encontrado")
		return

	_build()

	if _lab.has_signal("lab_actualizado"):
		_lab.lab_actualizado.connect(_refresh_all)
	if _eco and _eco.has_signal("recursos_actualizados"):
		_eco.recursos_actualizados.connect(_refresh_all)

	_timer_ui = Timer.new()
	_timer_ui.wait_time = 1.0
	_timer_ui.timeout.connect(_on_tick)
	add_child(_timer_ui)
	_timer_ui.start()

	_refresh_all()


func on_show() -> void:
	_refresh_all()


func _on_tick() -> void:
	# Solo refresca barras/tiempos si hay algo activo y la pantalla se ve.
	if not is_visible_in_tree():
		return
	for id in _card_refs.keys():
		if _lab.esta_activa(id):
			_refresh_card(id)


# ------------------------------------------------------------
# CONSTRUCCIÓN
# ------------------------------------------------------------
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

	for cat in CATS:
		var section := _make_category_list(cat)
		section.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		section.visible = (cat == _current_cat)
		_sections[cat] = section
		lists.add_child(section)

	_update_tab_colors()


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
	eyebrow.text = "INVESTIGACIÓN PASIVA"
	eyebrow.add_theme_font_size_override("font_size", 10)
	eyebrow.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(eyebrow)

	var title := Label.new()
	title.text = "LABORATORIO"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", MenuTheme.VIOLET)
	_apply_hud_font(title)

	# Slots ocupados/total bajo el título.
	_lbl_slots = Label.new()
	_lbl_slots.text = ""
	_lbl_slots.add_theme_font_size_override("font_size", 13)
	_lbl_slots.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(_lbl_slots)

	titleblock.add_child(eyebrow)
	titleblock.add_child(title)
	titleblock.add_child(_lbl_slots)
	h.add_child(titleblock)

	# Píldora con el saldo de ecos.
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_END

	var lbl := Label.new()
	lbl.text = "ECOS"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(lbl)

	_lbl_ecos = Label.new()
	_lbl_ecos.text = "--"
	_lbl_ecos.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_ecos.add_theme_font_size_override("font_size", 20)
	_lbl_ecos.add_theme_color_override("font_color", MenuTheme.CYAN)
	_apply_hud_font(_lbl_ecos)

	v.add_child(lbl)
	v.add_child(_lbl_ecos)
	h.add_child(v)

	return margin


func _make_tabs() -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)

	for cat in CATS:
		var btn := Button.new()
		btn.text = CAT_LABELS[cat]
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 13)
		var f := MenuTheme.get_font_hud()
		if f:
			btn.add_theme_font_override("font", f)
		btn.pressed.connect(_on_tab_pressed.bind(cat))
		_tab_buttons[cat] = btn
		row.add_child(btn)

	return margin


func _on_tab_pressed(cat: String) -> void:
	_current_cat = cat
	for c in CATS:
		_sections[c].visible = (c == cat)
	_update_tab_colors()


func _update_tab_colors() -> void:
	for cat in CATS:
		var btn: Button = _tab_buttons[cat]
		var color: Color = CAT_COLORS[cat]
		if cat == _current_cat:
			btn.add_theme_stylebox_override("normal", MenuTheme.make_button_style(color, true))
			btn.add_theme_stylebox_override("hover", MenuTheme.make_button_style(color, true))
			btn.add_theme_stylebox_override("pressed", MenuTheme.make_button_style(color, true))
			btn.add_theme_color_override("font_color", color)
		else:
			var dim := MenuTheme.make_card_style(MenuTheme.BORDER_DIM, 0.5)
			btn.add_theme_stylebox_override("normal", dim)
			btn.add_theme_stylebox_override("hover", dim)
			btn.add_theme_stylebox_override("pressed", dim)
			btn.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)


func _make_category_list(cat: String) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)

	for id in _lab.ids_investigaciones():
		var data: Dictionary = _lab.get_data(id)
		if data.get("categoria", "") != cat:
			continue
		v.add_child(_make_card(id, data, CAT_COLORS[cat]))

	# Hueco final para que la última card no pegue con la NavBar.
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	v.add_child(spacer)

	return v


# ------------------------------------------------------------
# CARD de investigación.
# ------------------------------------------------------------
func _make_card(id: String, data: Dictionary, accent: Color) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(
		Color(accent.r, accent.g, accent.b, 0.25)))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	# Fila 1: nombre + nivel.
	var fila1 := HBoxContainer.new()
	var nombre := Label.new()
	nombre.text = data["nombre"]
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nombre.add_theme_font_size_override("font_size", 17)
	nombre.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(nombre)

	var nivel := Label.new()
	nivel.add_theme_font_size_override("font_size", 15)
	nivel.add_theme_color_override("font_color", accent)
	_apply_hud_font(nivel)

	fila1.add_child(nombre)
	fila1.add_child(nivel)
	v.add_child(fila1)

	# Fila 2: descripción.
	var desc := Label.new()
	desc.text = data["descripcion"]
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)

	# Fila 3: bonus actual → siguiente.
	var bonus := Label.new()
	bonus.add_theme_font_size_override("font_size", 14)
	bonus.add_theme_color_override("font_color", MenuTheme.GREEN)
	v.add_child(bonus)

	# Zona INVESTIGAR (visible cuando NO está activa ni al máximo).
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 38)
	btn.add_theme_font_size_override("font_size", 15)
	var f := MenuTheme.get_font_hud()
	if f:
		btn.add_theme_font_override("font", f)
	btn.pressed.connect(_on_investigar.bind(id))
	v.add_child(btn)

	# Zona EN CURSO: barra + tiempo + acelerar.
	var curso := VBoxContainer.new()
	curso.add_theme_constant_override("separation", 4)

	var barra := ProgressBar.new()
	barra.min_value = 0.0
	barra.max_value = 1.0
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 8)
	barra.add_theme_stylebox_override("background", MenuTheme.make_progress_track())
	barra.add_theme_stylebox_override("fill", MenuTheme.make_progress_fill(accent))
	curso.add_child(barra)

	var fila_curso := HBoxContainer.new()
	fila_curso.add_theme_constant_override("separation", 8)

	var tiempo := Label.new()
	tiempo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tiempo.add_theme_font_size_override("font_size", 14)
	tiempo.add_theme_color_override("font_color", accent)
	_apply_hud_font(tiempo)

	var btn_acel := Button.new()
	btn_acel.focus_mode = Control.FOCUS_NONE
	btn_acel.add_theme_font_size_override("font_size", 13)
	if f:
		btn_acel.add_theme_font_override("font", f)
	btn_acel.add_theme_stylebox_override("normal", MenuTheme.make_button_style(MenuTheme.VIOLET))
	btn_acel.add_theme_stylebox_override("hover", MenuTheme.make_button_style(MenuTheme.VIOLET, true))
	btn_acel.add_theme_stylebox_override("pressed", MenuTheme.make_button_style(MenuTheme.VIOLET, true))
	btn_acel.add_theme_color_override("font_color", MenuTheme.VIOLET)
	btn_acel.pressed.connect(_on_acelerar.bind(id))

	fila_curso.add_child(tiempo)
	fila_curso.add_child(btn_acel)
	curso.add_child(fila_curso)
	v.add_child(curso)

	_card_refs[id] = {
		"nivel": nivel,
		"bonus": bonus,
		"btn": btn,
		"curso": curso,
		"barra": barra,
		"tiempo": tiempo,
		"btn_acel": btn_acel,
		"accent": accent,
	}

	return panel


# ------------------------------------------------------------
# REFRESCO
# ------------------------------------------------------------
func _refresh_all() -> void:
	if _lab == null:
		return
	if _lbl_ecos and _eco:
		_lbl_ecos.text = Formato.abreviar(float(_eco.ecos))
	if _lbl_slots:
		var ocupados: int = _lab.get_slots() - _lab.slots_libres()
		_lbl_slots.text = "SLOTS %d/%d" % [ocupados, _lab.get_slots()]
	for id in _card_refs.keys():
		_refresh_card(id)


func _refresh_card(id: String) -> void:
	var refs: Dictionary = _card_refs[id]
	var nivel_actual: int = _lab.get_nivel(id)
	var max_nivel: int = _lab.get_max_nivel(id)
	var accent: Color = refs["accent"]

	refs["nivel"].text = "NV %d/%d" % [nivel_actual, max_nivel]

	# Bonus actual → siguiente.
	var actual: String = _lab.formatear_bonus(id, nivel_actual)
	if _lab.nivel_maximo_alcanzado(id):
		refs["bonus"].text = "Bonus: %s (MÁX)" % actual
	else:
		refs["bonus"].text = "Bonus: %s  →  %s" % [actual, _lab.formatear_bonus(id, nivel_actual + 1)]

	var activa: bool = _lab.esta_activa(id)
	refs["curso"].visible = activa
	refs["btn"].visible = not activa

	if activa:
		refs["barra"].value = _lab.progreso(id)
		refs["tiempo"].text = Laboratorio.formatear_tiempo(_lab.tiempo_restante(id))
		refs["btn_acel"].text = "ACELERAR  %d %s" % [_lab.coste_acelerar(id), MenuTheme.SYM_FRAG]
		refs["btn_acel"].disabled = _eco == null or _eco.fragmentos < _lab.coste_acelerar(id)
		return

	# No activa: botón de investigar / completado.
	var btn: Button = refs["btn"]
	if _lab.nivel_maximo_alcanzado(id):
		btn.text = "INVESTIGACIÓN COMPLETA"
		btn.disabled = true
		var sb := MenuTheme.make_card_style(MenuTheme.BORDER_DIM, 0.4)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("disabled", sb)
		btn.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
		btn.add_theme_color_override("font_disabled_color", MenuTheme.TEXT_MUTED)
		return

	var coste: int = _lab.get_coste(id)
	var dur: int = int(_lab.get_duracion(id))
	btn.text = "INVESTIGAR  %d %s  ·  %s" % [coste, MenuTheme.SYM_ECOS, Laboratorio.formatear_tiempo(dur)]
	var puede: bool = _lab.puede_investigar(id)
	btn.disabled = not puede
	var color: Color = accent if puede else MenuTheme.TEXT_MUTED
	btn.add_theme_stylebox_override("normal", MenuTheme.make_button_style(color))
	btn.add_theme_stylebox_override("hover", MenuTheme.make_button_style(color, true))
	btn.add_theme_stylebox_override("pressed", MenuTheme.make_button_style(color, true))
	btn.add_theme_stylebox_override("disabled", MenuTheme.make_button_style(color))
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_disabled_color", color)


# ------------------------------------------------------------
# ACCIONES
# ------------------------------------------------------------
func _on_investigar(id: String) -> void:
	if _lab.iniciar(id):
		AudioManager.sfx("compra")
	_refresh_all()


func _on_acelerar(id: String) -> void:
	if _lab.acelerar(id):
		AudioManager.sfx("compra")
	_refresh_all()


# ------------------------------------------------------------
# HELPERS
# ------------------------------------------------------------
func _apply_hud_font(lbl: Label) -> void:
	var f := MenuTheme.get_font_hud()
	if f:
		lbl.add_theme_font_override("font", f)
