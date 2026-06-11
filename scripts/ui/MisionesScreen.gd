class_name MisionesScreenUI
extends Control
# ============================================================
# MisionesScreen.gd
# Pantalla de MISIONES DIARIAS (3 misiones, reset a medianoche).
#
# Data-driven: lee las misiones del día de MisionesManager y pinta
# una card por misión con barra de progreso y botón RECLAMAR.
#
# Construida 100% por código (patrón LabScreen/NexoScreen).
# Se accede desde la card "MISIONES" del Home (MainMenu.navigate("misiones")).
# ============================================================

var _mm: Node = null
var _eco: Node = null

var _lbl_reset: Label
var _cards_box: VBoxContainer
var _card_refs: Dictionary = {}   # id -> refs a controles

var _timer_ui: Timer


func _ready() -> void:
	_mm = get_node_or_null("/root/MisionesManager")
	_eco = get_node_or_null("/root/Economia")

	if _mm == null:
		push_warning("MisionesScreen: autoload 'MisionesManager' no encontrado")
		return

	_build()

	if _mm.has_signal("misiones_actualizadas"):
		_mm.misiones_actualizadas.connect(_refresh_all)

	# Contador de "se renuevan en HH:MM" cada segundo (solo visible).
	_timer_ui = Timer.new()
	_timer_ui.wait_time = 1.0
	_timer_ui.timeout.connect(_on_tick)
	add_child(_timer_ui)
	_timer_ui.start()

	_refresh_all()


func on_show() -> void:
	_refresh_all()


func _on_tick() -> void:
	if not is_visible_in_tree():
		return
	_refresh_reset_label()


# ------------------------------------------------------------
# CONSTRUCCIÓN
# ------------------------------------------------------------
func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	root.add_child(_make_header())

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	_cards_box = VBoxContainer.new()
	_cards_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_box.add_theme_constant_override("separation", 10)
	margin.add_child(_cards_box)

	_rebuild_cards()


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
	eyebrow.text = "OBJETIVOS DEL DÍA"
	eyebrow.add_theme_font_size_override("font_size", 10)
	eyebrow.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(eyebrow)

	var title := Label.new()
	title.text = "MISIONES"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", MenuTheme.GOLD)
	_apply_hud_font(title)

	_lbl_reset = Label.new()
	_lbl_reset.text = ""
	_lbl_reset.add_theme_font_size_override("font_size", 13)
	_lbl_reset.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(_lbl_reset)

	titleblock.add_child(eyebrow)
	titleblock.add_child(title)
	titleblock.add_child(_lbl_reset)
	h.add_child(titleblock)

	return margin


# Reconstruye las 3 cards (al cambiar el día cambian las misiones).
func _rebuild_cards() -> void:
	for c in _cards_box.get_children():
		c.queue_free()
	_card_refs.clear()

	for id in _mm.ids_activas():
		_cards_box.add_child(_make_card(id))


func _make_card(id: String) -> Control:
	var data: Dictionary = _mm.get_data(id)
	var es_frag: bool = data.get("recompensa_tipo", "ecos") == "fragmentos"
	var accent: Color = MenuTheme.VIOLET if es_frag else MenuTheme.CYAN

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(
		Color(accent.r, accent.g, accent.b, 0.25)))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	# Fila 1: descripción + recompensa.
	var fila1 := HBoxContainer.new()
	var desc := Label.new()
	desc.text = data.get("descripcion", id)
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_hud_font(desc)

	var sym: String = MenuTheme.SYM_FRAG if es_frag else MenuTheme.SYM_ECOS
	var reward := Label.new()
	reward.text = "+%d %s" % [data.get("recompensa", 0), sym]
	reward.add_theme_font_size_override("font_size", 16)
	reward.add_theme_color_override("font_color", accent)
	_apply_hud_font(reward)

	fila1.add_child(desc)
	fila1.add_child(reward)
	v.add_child(fila1)

	# Fila 2: barra de progreso + texto N/M.
	var barra := ProgressBar.new()
	barra.min_value = 0.0
	barra.max_value = 1.0
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 8)
	barra.add_theme_stylebox_override("background", MenuTheme.make_progress_track())
	barra.add_theme_stylebox_override("fill", MenuTheme.make_progress_fill(accent))
	v.add_child(barra)

	var fila2 := HBoxContainer.new()
	var prog := Label.new()
	prog.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog.add_theme_font_size_override("font_size", 14)
	prog.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(prog)

	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(140, 34)
	btn.add_theme_font_size_override("font_size", 14)
	var f := MenuTheme.get_font_hud()
	if f:
		btn.add_theme_font_override("font", f)
	btn.pressed.connect(_on_reclamar.bind(id))

	fila2.add_child(prog)
	fila2.add_child(btn)
	v.add_child(fila2)

	_card_refs[id] = {"barra": barra, "prog": prog, "btn": btn, "accent": accent}
	return panel


# ------------------------------------------------------------
# REFRESCO
# ------------------------------------------------------------
func _refresh_all() -> void:
	if _mm == null:
		return
	# Si cambió el día, las ids activas ya no coinciden con las cards.
	var ids: Array = _mm.ids_activas()
	if not _mismas_ids(ids):
		_rebuild_cards()

	_refresh_reset_label()
	for id in _card_refs.keys():
		_refresh_card(id)


func _mismas_ids(ids: Array) -> bool:
	if ids.size() != _card_refs.size():
		return false
	for id in ids:
		if not _card_refs.has(id):
			return false
	return true


func _refresh_reset_label() -> void:
	if _lbl_reset == null or _mm == null:
		return
	var s: int = _mm.segundos_para_reset()
	var h := int(s / 3600.0)
	var m := int((s % 3600) / 60.0)
	_lbl_reset.text = "SE RENUEVAN EN %02d:%02d" % [h, m]


func _refresh_card(id: String) -> void:
	var refs: Dictionary = _card_refs[id]
	var data: Dictionary = _mm.get_data(id)
	var accent: Color = refs["accent"]

	refs["barra"].value = _mm.progreso_frac(id)
	refs["prog"].text = "%d / %d" % [_mm.get_progreso(id), data.get("objetivo", 0)]

	var btn: Button = refs["btn"]
	if _mm.reclamada(id):
		btn.text = "RECLAMADA"
		btn.disabled = true
		var sb := MenuTheme.make_card_style(MenuTheme.BORDER_DIM, 0.4)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("disabled", sb)
		btn.add_theme_color_override("font_disabled_color", MenuTheme.TEXT_MUTED)
	elif _mm.es_reclamable(id):
		btn.text = "RECLAMAR"
		btn.disabled = false
		btn.add_theme_stylebox_override("normal", MenuTheme.make_button_style(MenuTheme.GREEN, true))
		btn.add_theme_stylebox_override("hover", MenuTheme.make_button_style(MenuTheme.GREEN, true))
		btn.add_theme_stylebox_override("pressed", MenuTheme.make_button_style(MenuTheme.GREEN, true))
		btn.add_theme_color_override("font_color", MenuTheme.GREEN)
	else:
		btn.text = "EN CURSO"
		btn.disabled = true
		btn.add_theme_stylebox_override("disabled", MenuTheme.make_button_style(accent))
		btn.add_theme_color_override("font_disabled_color", Color(accent.r, accent.g, accent.b, 0.5))


# ------------------------------------------------------------
# ACCIONES
# ------------------------------------------------------------
func _on_reclamar(id: String) -> void:
	if _mm.reclamar(id):
		AudioManager.sfx("compra")
	_refresh_all()


func _apply_hud_font(lbl: Label) -> void:
	var f := MenuTheme.get_font_hud()
	if f:
		lbl.add_theme_font_override("font", f)
