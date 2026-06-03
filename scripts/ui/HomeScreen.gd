class_name HomeScreenUI
extends Control
# ============================================================
# HomeScreen.gd
# Pantalla principal del menu.
# Contiene: HUD de monedas, orbe Sentinel, strip de stats,
# boton JUGAR grande, grid 2x2 "Proximamente", banner ultima run.
#
# Se instancia desde MainMenu con HomeScreen.new().
# Construye toda su UI por codigo en _ready().
#
# CONEXION CON EL JUEGO:
#   - Los valores de Ecos/Fragmentos se leen de los autoloads
#     Economia y MejoraManager si existen (ver _refresh_currencies).
#   - El boton JUGAR llama a start_game() -> ahi cambias de escena.
# ============================================================

signal play_pressed

# Labels que se refrescan con datos del juego.
var _lbl_ecos: Label
var _lbl_frag: Label


func _ready() -> void:
	_build()


func _build() -> void:
	# ScrollContainer raiz (la home puede crecer en pantallas pequenas).
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	# Margen lateral que contiene la columna principal.
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	_populate(root)


# Rellena la columna principal con todos los bloques.
func _populate(root: VBoxContainer) -> void:
	root.add_child(_make_currency_hud())
	root.add_child(_make_hero())
	root.add_child(_make_stats_strip())
	root.add_child(_make_play_button())
	root.add_child(_make_quick_grid())
	root.add_child(_make_last_run())


# ------------------------------------------------------------
# HUD de monedas: Energia / Ecos / Fragmentos.
# ------------------------------------------------------------
func _make_currency_hud() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(MenuTheme.BORDER_GLOW))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	panel.add_child(row)

	row.add_child(_make_currency_item(MenuTheme.SYM_ENERGIA, "--", "ENERGIA", MenuTheme.TEXT_PRIMARY))
	row.add_child(_make_vsep())
	_lbl_ecos = _make_value_label("1,247", MenuTheme.CYAN)
	row.add_child(_make_currency_item_with_label(MenuTheme.SYM_ECOS, _lbl_ecos, "ECOS", MenuTheme.CYAN))
	row.add_child(_make_vsep())
	_lbl_frag = _make_value_label("384", MenuTheme.VIOLET)
	row.add_child(_make_currency_item_with_label(MenuTheme.SYM_FRAG, _lbl_frag, "FRAGMENTOS", MenuTheme.VIOLET))

	return panel


func _make_currency_item(symbol: String, value: String, label: String, color: Color) -> Control:
	var lbl := _make_value_label(value, color)
	return _make_currency_item_with_label(symbol, lbl, label, color)


func _make_currency_item_with_label(symbol: String, value_lbl: Label, label: String, color: Color) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)

	var icon := Label.new()
	icon.text = symbol
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 16)
	icon.add_theme_color_override("font_color", color)

	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var name_lbl := Label.new()
	name_lbl.text = label
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 8)
	name_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(name_lbl)

	v.add_child(icon)
	v.add_child(value_lbl)
	v.add_child(name_lbl)
	return v


func _make_value_label(text: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", color)
	_apply_hud_font(lbl)
	return lbl


func _make_vsep() -> Control:
	var sep := ColorRect.new()
	sep.color = MenuTheme.BORDER_DIM
	sep.custom_minimum_size = Vector2(1, 36)
	return sep


# ------------------------------------------------------------
# HERO: orbe Sentinel + titulo + subtitulo.
# ------------------------------------------------------------
func _make_hero() -> Control:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)

	# Orbe (clase interna, dibuja un circulo con glow).
	var orb := SentinelOrb.new()
	orb.custom_minimum_size = Vector2(140, 140)
	orb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(orb)

	var title := Label.new()
	title.text = "VOID SENTINEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(title)
	v.add_child(title)

	var sub := Label.new()
	sub.text = "NEXO ACTIVO  -  NIVEL 12"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(sub)
	v.add_child(sub)

	return v


# ------------------------------------------------------------
# STRIP de stats: Ascension / Enemigos / Record / Partidas.
# ------------------------------------------------------------
func _make_stats_strip() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(MenuTheme.BORDER_GLOW))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	panel.add_child(row)

	row.add_child(_make_stat("47", "ULT. ASCENSION", MenuTheme.GOLD))
	row.add_child(_make_vsep())
	row.add_child(_make_stat("2,341", "ENEMIGOS", MenuTheme.GREEN))
	row.add_child(_make_vsep())
	row.add_child(_make_stat("89", "RECORD", MenuTheme.CYAN))
	row.add_child(_make_vsep())
	row.add_child(_make_stat("23", "PARTIDAS", MenuTheme.VIOLET))

	return panel


func _make_stat(value: String, label: String, color: Color) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)

	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.add_theme_font_size_override("font_size", 16)
	val.add_theme_color_override("font_color", color)
	_apply_hud_font(val)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(lbl)

	v.add_child(val)
	v.add_child(lbl)
	return v


# ------------------------------------------------------------
# BOTON JUGAR grande.
# ------------------------------------------------------------
func _make_play_button() -> Control:
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 72)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.27, 0.47, 0.9)
	style.border_color = Color(MenuTheme.CYAN.r, MenuTheme.CYAN.g, MenuTheme.CYAN.b, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var play_icon := Label.new()
	play_icon.text = MenuTheme.SYM_PLAY
	play_icon.add_theme_font_size_override("font_size", 28)
	play_icon.add_theme_color_override("font_color", MenuTheme.CYAN)
	play_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var txt_box := VBoxContainer.new()
	txt_box.alignment = BoxContainer.ALIGNMENT_CENTER
	txt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var txt := Label.new()
	txt.text = "JUGAR"
	txt.add_theme_font_size_override("font_size", 20)
	txt.add_theme_color_override("font_color", Color.WHITE)
	_apply_hud_font(txt)

	var sub := Label.new()
	sub.text = "INICIAR DEFENSA"
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", MenuTheme.CYAN)
	_apply_hud_font(sub)

	txt_box.add_child(txt)
	txt_box.add_child(sub)
	h.add_child(play_icon)
	h.add_child(txt_box)
	btn.add_child(h)

	btn.pressed.connect(_on_play_pressed)
	return btn


func _on_play_pressed() -> void:
	play_pressed.emit()
	start_game()


# Cambia a la escena de juego.
func start_game() -> void:
	# Llama a iniciar_partida() en Economia para resetear energia,
	# ascension, kills y el sistema de interes antes de cargar mundo.
	# Asi cada vez que pulses JUGAR arrancas con valores limpios sin
	# tocar los Ecos/Fragmentos permanentes.
	var eco := get_node_or_null("/root/Economia")
	if eco and eco.has_method("iniciar_partida"):
		eco.iniciar_partida()

	# Cambiar a la escena del juego.
	var err := get_tree().change_scene_to_file("res://escenas/mundo.tscn")
	if err != OK:
		push_error("[HomeScreen] No se pudo cargar mundo.tscn (codigo %d)" % err)


# ------------------------------------------------------------
# GRID 2x2 "Proximamente" (placeholders para futuras features).
# ------------------------------------------------------------
func _make_quick_grid() -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)

	grid.add_child(_make_test_card())
	grid.add_child(_make_soon_card("TORNEOS", "Eventos y clasificatorias"))
	grid.add_child(_make_soon_card("MISIONES", "Objetivos diarios y semanales"))
	grid.add_child(_make_soon_card("ALIANZAS", "Juega con otros Centinelas"))

	return grid


# 🧪 Card clicable que lanza la partida en MODO PRUEBA (testing endgame).
func _make_test_card() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(MenuTheme.GOLD.r, MenuTheme.GOLD.g, MenuTheme.GOLD.b, 0.10)
	style.border_color = Color(MenuTheme.GOLD.r, MenuTheme.GOLD.g, MenuTheme.GOLD.b, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(btn)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var t := Label.new()
	t.text = "JUGAR PRUEBA"
	t.add_theme_font_size_override("font_size", 12)
	t.add_theme_color_override("font_color", MenuTheme.GOLD)
	_apply_hud_font(t)

	var d := Label.new()
	d.text = "Asc avanzada + recursos. Tecla C: Commander."
	d.add_theme_font_size_override("font_size", 10)
	d.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var badge := Label.new()
	badge.text = "TESTING"
	badge.add_theme_font_size_override("font_size", 7)
	badge.add_theme_color_override("font_color", MenuTheme.GOLD)
	_apply_hud_font(badge)

	v.add_child(t)
	v.add_child(d)
	v.add_child(badge)
	btn.add_child(v)

	btn.pressed.connect(_on_test_pressed)
	return panel


func _on_test_pressed() -> void:
	var mp := get_node_or_null("/root/ModoPrueba")
	if mp:
		mp.activo = true
	start_game()


func _make_soon_card(title: String, desc: String) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(MenuTheme.BG_MID.r, MenuTheme.BG_MID.g, MenuTheme.BG_MID.b, 0.8)
	style.border_color = Color(1, 1, 1, 0.08)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 12)
	t.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(t)

	var d := Label.new()
	d.text = desc
	d.add_theme_font_size_override("font_size", 10)
	d.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var badge := Label.new()
	badge.text = "PROXIMAMENTE"
	badge.add_theme_font_size_override("font_size", 7)
	badge.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(badge)

	v.add_child(t)
	v.add_child(d)
	v.add_child(badge)
	return panel


# ------------------------------------------------------------
# BANNER ultima partida.
# ------------------------------------------------------------
func _make_last_run() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(MenuTheme.BORDER_DIM, 0.7))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	panel.add_child(h)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)

	var label := Label.new()
	label.text = "ULTIMA PARTIDA"
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(label)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 12)
	stats.add_child(_make_mini_stat("Asc 47", "ALCANZADO"))
	stats.add_child(_make_mini_stat("+84", "ECOS"))
	stats.add_child(_make_mini_stat("312", "KILLS"))

	info.add_child(label)
	info.add_child(stats)
	h.add_child(info)

	var cause := VBoxContainer.new()
	cause.alignment = BoxContainer.ALIGNMENT_CENTER
	var skull := Label.new()
	skull.text = MenuTheme.SYM_SKULL
	skull.add_theme_font_size_override("font_size", 16)
	skull.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var cause_txt := Label.new()
	cause_txt.text = "NUCLEO DESTRUIDO"
	cause_txt.add_theme_font_size_override("font_size", 8)
	cause_txt.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 0.7))
	_apply_hud_font(cause_txt)
	cause.add_child(skull)
	cause.add_child(cause_txt)
	h.add_child(cause)

	return panel


func _make_mini_stat(value: String, label: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(val)
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(lbl)
	v.add_child(val)
	v.add_child(lbl)
	return v


# ------------------------------------------------------------
# REFRESCO de datos: se llama al mostrar la pantalla.
# ------------------------------------------------------------
func on_show() -> void:
	_refresh_currencies()


func _refresh_currencies() -> void:
	# Lee de los autoloads si existen. Si no, deja el placeholder.
	# Economia y MejoraManager son tus autoloads actuales.
	var eco_node := get_node_or_null("/root/Economia")
	if eco_node and eco_node.has_method("get_ecos"):
		_lbl_ecos.text = _format_number(eco_node.get_ecos())
	elif eco_node and "ecos" in eco_node:
		_lbl_ecos.text = _format_number(eco_node.ecos)

	if eco_node and eco_node.has_method("get_fragmentos"):
		_lbl_frag.text = _format_number(eco_node.get_fragmentos())
	elif eco_node and "fragmentos" in eco_node:
		_lbl_frag.text = _format_number(eco_node.fragmentos)


# Formatea numeros con separador de miles.
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


# Aplica la fuente HUD (Orbitron) si esta disponible.
func _apply_hud_font(lbl: Label) -> void:
	var f := MenuTheme.get_font_hud()
	if f:
		lbl.add_theme_font_override("font", f)


# ============================================================
# SentinelOrb: clase interna que dibuja el orbe azul con glow.
# ============================================================
class SentinelOrb extends Control:
	var _t: float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var center := size / 2.0
		var base_r := minf(size.x, size.y) * 0.26

		# Pulso suave del nucleo.
		var pulse := 1.0 + sin(_t * 2.0) * 0.05
		var r := base_r * pulse

		# Glow exterior (circulos concentricos con alpha decreciente).
		for i in range(6, 0, -1):
			var gr := r + i * 6.0
			var a := 0.05 * (1.0 - float(i) / 7.0) + 0.02
			draw_circle(center, gr, Color(0.0, 0.78, 1.0, a))

		# Nucleo (degradado simulado con circulos).
		draw_circle(center, r, Color("003c78"))
		draw_circle(center - Vector2(r * 0.2, r * 0.2), r * 0.75, Color("008cdc"))
		draw_circle(center - Vector2(r * 0.3, r * 0.3), r * 0.4, Color("b4dcff"))

		# Anillo exterior giratorio.
		var ring_r := base_r * 2.0
		draw_arc(center, ring_r, 0, TAU, 64, Color(0.0, 0.898, 1.0, 0.3), 1.0, true)

		# Punto orbital sobre el anillo.
		var orbit_angle := _t * 0.8
		var dot_pos := center + Vector2(cos(orbit_angle), sin(orbit_angle)) * ring_r
		draw_circle(dot_pos, 3.0, MenuTheme.CYAN)
