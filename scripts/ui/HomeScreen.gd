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
# Pide a MainMenu navegar a una pantalla sin botón en la NavBar ("lab", ...).
signal nav_requested(screen_name: String)

# Labels que se refrescan con datos del juego.
var _lbl_ecos: Label
var _lbl_frag: Label

# Stats strip — se guardan refs para refrescar en on_show().
var _lbl_stat_record: Label
var _lbl_stat_enemies: Label
var _lbl_stat_runs: Label
var _lbl_stat_asc: Label

# Última run — refs para refrescar.
var _lbl_run_asc: Label
var _lbl_run_kills: Label
var _lbl_run_ecos: Label
var _lbl_run_cause: Label


func _ready() -> void:
	_build()
	# 🎵 Música del menú (loop). Si no hay archivo, no suena.
	var am := get_node_or_null("/root/AudioManager")
	if am:
		am.musica("menu")


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
	# ▶️ Botón de reanudar solo si hay una partida guardada en curso.
	var rp := get_node_or_null("/root/ReanudarPartida")
	if rp and rp.hay_partida():
		root.add_child(_make_resume_button())
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
	icon.add_theme_font_size_override("font_size", 26)
	icon.add_theme_color_override("font_color", color)

	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var name_lbl := Label.new()
	name_lbl.text = label
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(name_lbl)

	v.add_child(icon)
	v.add_child(value_lbl)
	v.add_child(name_lbl)
	return v


func _make_value_label(text: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 17)
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
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(title)
	v.add_child(title)

	var sub := Label.new()
	sub.text = "NEXO ACTIVO"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 17)
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

	_lbl_stat_asc     = _make_value_label("--", MenuTheme.GOLD)
	_lbl_stat_record  = _make_value_label("--", MenuTheme.CYAN)
	_lbl_stat_enemies = _make_value_label("--", MenuTheme.GREEN)
	_lbl_stat_runs    = _make_value_label("--", MenuTheme.VIOLET)

	row.add_child(_make_stat_with_label(_lbl_stat_asc,     "ULT. ASC",  MenuTheme.GOLD))
	row.add_child(_make_vsep())
	row.add_child(_make_stat_with_label(_lbl_stat_record,  "RECORD",    MenuTheme.CYAN))
	row.add_child(_make_vsep())
	row.add_child(_make_stat_with_label(_lbl_stat_enemies, "BAJAS",     MenuTheme.GREEN))
	row.add_child(_make_vsep())
	row.add_child(_make_stat_with_label(_lbl_stat_runs,    "PARTIDAS",  MenuTheme.VIOLET))

	return panel


func _make_stat(value: String, label: String, color: Color) -> Control:
	var lbl_val := _make_value_label(value, color)
	return _make_stat_with_label(lbl_val, label, color)


func _make_stat_with_label(value_lbl: Label, label: String, color: Color) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)

	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_lbl.add_theme_font_size_override("font_size", 26)
	value_lbl.add_theme_color_override("font_color", color)
	_apply_hud_font(value_lbl)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(lbl)

	v.add_child(value_lbl)
	v.add_child(lbl)
	return v


# ------------------------------------------------------------
# BOTON JUGAR grande.
# ------------------------------------------------------------
func _make_play_button() -> Control:
	var btn := Button.new()
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
	play_icon.add_theme_font_size_override("font_size", 38)
	play_icon.add_theme_color_override("font_color", MenuTheme.CYAN)
	play_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var txt_box := VBoxContainer.new()
	txt_box.alignment = BoxContainer.ALIGNMENT_CENTER
	txt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var txt := Label.new()
	txt.text = "JUGAR"
	txt.add_theme_font_size_override("font_size", 28)
	txt.add_theme_color_override("font_color", Color.WHITE)
	_apply_hud_font(txt)

	var sub := Label.new()
	sub.text = "INICIAR DEFENSA"
	sub.add_theme_font_size_override("font_size", 16)
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


# ▶️ Botón "Reanudar" (verde). Marca la bandera y arranca: mundo.gd restaurará
# el checkpoint en vez de empezar de cero.
func _make_resume_button() -> Control:
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 60)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(MenuTheme.GREEN.r, MenuTheme.GREEN.g, MenuTheme.GREEN.b, 0.12)
	style.border_color = Color(MenuTheme.GREEN.r, MenuTheme.GREEN.g, MenuTheme.GREEN.b, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

	var txt := Label.new()
	txt.text = "REANUDAR PARTIDA"
	txt.add_theme_font_size_override("font_size", 26)
	txt.add_theme_color_override("font_color", MenuTheme.GREEN)
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_hud_font(txt)
	btn.add_child(txt)

	btn.pressed.connect(_on_resume_pressed)
	return btn


func _on_resume_pressed() -> void:
	var rp := get_node_or_null("/root/ReanudarPartida")
	if rp:
		rp.debe_reanudar = true
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

	grid.add_child(_make_nav_card("LABORATORIO", "Investigaciones pasivas con timers reales", MenuTheme.VIOLET, "lab"))
	grid.add_child(_make_nav_card("MISIONES", "3 objetivos diarios con recompensas", MenuTheme.GOLD, "misiones"))
	grid.add_child(_make_soon_card("TORNEOS", "Eventos y clasificatorias"))
	grid.add_child(_make_soon_card("ALIANZAS", "Juega con otros Centinelas"))

	return grid


# Card clicable que navega a otra pantalla del menú (Lab, Misiones...).
# Estructura: PanelContainer con DOS hijos directos — el VBox de contenido
# (aporta el minimum size de la card) y un Button flat encima (el
# PanelContainer estira ambos a su rect, así el botón cubre toda la card).
func _make_nav_card(title: String, desc: String, accent: Color, screen_name: String) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.10)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", accent)
	_apply_hud_font(t)

	var d := Label.new()
	d.text = desc
	d.add_theme_font_size_override("font_size", 17)
	d.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var badge := Label.new()
	badge.text = "ABRIR " + MenuTheme.SYM_ARROW_R
	badge.add_theme_font_size_override("font_size", 14)
	badge.add_theme_color_override("font_color", accent)
	_apply_hud_font(badge)

	v.add_child(t)
	v.add_child(d)
	v.add_child(badge)
	panel.add_child(v)

	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func(): nav_requested.emit(screen_name))
	panel.add_child(btn)

	return panel


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
	t.add_theme_font_size_override("font_size", 18)
	t.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(t)

	var d := Label.new()
	d.text = desc
	d.add_theme_font_size_override("font_size", 16)
	d.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var badge := Label.new()
	badge.text = "PROXIMAMENTE"
	badge.add_theme_font_size_override("font_size", 12)
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
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(label)

	_lbl_run_asc   = Label.new()
	_lbl_run_kills = Label.new()
	_lbl_run_ecos  = Label.new()

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 12)
	stats.add_child(_make_mini_stat_with_label(_lbl_run_asc,   "--",  "ALCANZADO"))
	stats.add_child(_make_mini_stat_with_label(_lbl_run_ecos,  "--",  "ECOS"))
	stats.add_child(_make_mini_stat_with_label(_lbl_run_kills, "--",  "BAJAS"))

	info.add_child(label)
	info.add_child(stats)
	h.add_child(info)

	var cause := VBoxContainer.new()
	cause.alignment = BoxContainer.ALIGNMENT_CENTER
	var skull := Label.new()
	skull.text = MenuTheme.SYM_SKULL
	skull.add_theme_font_size_override("font_size", 26)
	skull.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_run_cause = Label.new()
	_lbl_run_cause.text = "SIN PARTIDAS"
	_lbl_run_cause.add_theme_font_size_override("font_size", 14)
	_lbl_run_cause.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 0.7))
	_apply_hud_font(_lbl_run_cause)
	cause.add_child(skull)
	cause.add_child(_lbl_run_cause)
	h.add_child(cause)

	return panel


func _make_mini_stat(value: String, label: String) -> Control:
	var val := Label.new()
	return _make_mini_stat_with_label(val, value, label)


func _make_mini_stat_with_label(val: Label, value: String, label: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	val.text = value
	val.add_theme_font_size_override("font_size", 20)
	val.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(val)
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 14)
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
	_refresh_stats()
	_refresh_last_run()


func _refresh_currencies() -> void:
	var eco_node := get_node_or_null("/root/Economia")
	if eco_node and "ecos" in eco_node:
		_lbl_ecos.text = _format_number(eco_node.ecos)
	if eco_node and "fragmentos" in eco_node:
		_lbl_frag.text = _format_number(eco_node.fragmentos)


func _refresh_stats() -> void:
	var stats := get_node_or_null("/root/EstadisticasManager")
	if not stats:
		return
	if _lbl_stat_asc:
		_lbl_stat_asc.text     = _format_number(stats.ultima_ascension)
	if _lbl_stat_record:
		_lbl_stat_record.text  = _format_number(stats.mejor_ascension)
	if _lbl_stat_enemies:
		_lbl_stat_enemies.text = _format_number(stats.kills_total)
	if _lbl_stat_runs:
		_lbl_stat_runs.text    = _format_number(stats.partidas_jugadas)


func _refresh_last_run() -> void:
	var stats := get_node_or_null("/root/EstadisticasManager")
	if not stats or stats.partidas_jugadas == 0:
		if _lbl_run_cause:
			_lbl_run_cause.text = "SIN PARTIDAS"
		return
	if _lbl_run_asc:
		_lbl_run_asc.text   = "Asc %d" % stats.ultima_ascension
	if _lbl_run_kills:
		_lbl_run_kills.text = _format_number(stats.ultimo_kills)
	if _lbl_run_ecos:
		var ecos_ganados := stats.ultimos_ecos
		_lbl_run_ecos.text = ("+%d" % ecos_ganados) if ecos_ganados > 0 else "0"
	if _lbl_run_cause:
		_lbl_run_cause.text = _formatear_causa_corta(stats.ultima_causa)


func _formatear_causa_corta(causa: String) -> String:
	match causa:
		"kamikaze":  return "KAMIKAZE"
		"tanque":    return "TANQUE"
		"sniper":    return "SNIPER"
		"jefe":      return "JEFE"
		"commander": return "COMMANDER"
		"basico":    return "ESPECTROS"
		"abandono":  return "ABANDONADO"
		_:           return "DERROTA"


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
