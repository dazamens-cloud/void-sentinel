class_name PerfilScreenUI
extends Control
# ============================================================
# PerfilScreen.gd
# Pantalla de perfil del jugador.
# 3 tabs: Resumen (stats), Logros, Historial de runs.
# El avatar es el mismo orbe Sentinel que en Home.
#
# CONEXION CON EL JUEGO:
#   - Los stats se leen de tus autoloads cuando existan (TODO).
#   - Reclamar logro: aqui logica de demo + TODO para recompensa real.
# ============================================================

var _current_tab: String = "stats"
var _sections: Dictionary = {}
var _tab_buttons: Dictionary = {}
var _logros_box: VBoxContainer
var _stats_box: VBoxContainer


func _ready() -> void:
	_build()
	if EstadisticasManager.has_signal("logros_actualizados"):
		EstadisticasManager.logros_actualizados.connect(_refresh_logros)
		EstadisticasManager.logros_actualizados.connect(_refresh_stats)


func _exit_tree() -> void:
	# ✅ Desconectar signals para prevenir memory leak
	if EstadisticasManager.logros_actualizados.is_connected(_refresh_logros):
		EstadisticasManager.logros_actualizados.disconnect(_refresh_logros)
	if EstadisticasManager.logros_actualizados.is_connected(_refresh_stats):
		EstadisticasManager.logros_actualizados.disconnect(_refresh_stats)


func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	root.add_child(_make_hero())
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

	_sections["stats"] = _make_stats_section()
	_sections["logros"] = _make_achievements_section()
	_sections["historial"] = _make_history_section()

	for key in _sections.keys():
		var s: Control = _sections[key]
		s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		s.visible = (key == _current_tab)
		lists.add_child(s)


# ------------------------------------------------------------
# HERO: avatar orbe + nombre + rango + barra XP.
# ------------------------------------------------------------
func _make_hero() -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	margin.add_child(h)

	# Avatar (mismo orbe que Home, mas pequeno).
	var orb := AvatarOrb.new()
	orb.custom_minimum_size = Vector2(78, 78)
	h.add_child(orb)

	# Info.
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)

	var name_lbl := Label.new()
	name_lbl.text = "CENTINELA_X"
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(name_lbl)

	var rank_row := HBoxContainer.new()
	rank_row.add_theme_constant_override("separation", 6)
	var badge := _make_pill("ELITE", MenuTheme.GOLD)
	var pts := Label.new()
	pts.text = "4,820 pts"
	pts.add_theme_font_size_override("font_size", 11)
	pts.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	pts.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_row.add_child(badge)
	rank_row.add_child(pts)

	# Barra XP.
	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 6)
	var xp := ProgressBar.new()
	xp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp.custom_minimum_size = Vector2(0, 4)
	xp.min_value = 0
	xp.max_value = 10000
	xp.value = 6800
	xp.show_percentage = false
	xp.add_theme_stylebox_override("background", MenuTheme.make_progress_track())
	xp.add_theme_stylebox_override("fill", MenuTheme.make_progress_fill(MenuTheme.GOLD))
	var xp_lbl := Label.new()
	xp_lbl.text = "6,800 / 10,000 XP"
	xp_lbl.add_theme_font_size_override("font_size", 10)
	xp_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(xp_lbl)
	xp_row.add_child(xp)
	xp_row.add_child(xp_lbl)

	info.add_child(name_lbl)
	info.add_child(rank_row)
	info.add_child(xp_row)
	h.add_child(info)

	return margin


func _make_pill(text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.12)
	style.border_color = Color(color.r, color.g, color.b, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", color)
	_apply_hud_font(lbl)
	panel.add_child(lbl)
	return panel


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
	h.add_child(_make_tab_button("stats", "RESUMEN"))
	h.add_child(_make_tab_button("logros", "LOGROS"))
	h.add_child(_make_tab_button("historial", "HISTORIAL"))
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
		var col: Color = MenuTheme.GOLD if tab == _current_tab else MenuTheme.TEXT_MUTED
		lbl.add_theme_color_override("font_color", col)


# ------------------------------------------------------------
# SECCION STATS.
# ------------------------------------------------------------
func _make_stats_section() -> Control:
	_stats_box = VBoxContainer.new()
	_stats_box.add_theme_constant_override("separation", 14)
	_stats_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_refresh_stats()
	return _stats_box


# Rellena el resumen con los datos reales actuales (refrescable en on_show).
func _refresh_stats() -> void:
	if _stats_box == null:
		return
	for c in _stats_box.get_children():
		c.queue_free()
	var v := _stats_box

	# 4 big stats en grid 2x2.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	var em := EstadisticasManager
	grid.add_child(_make_big_stat(_miles(em.mejor_ascension), "RECORD ASCENSION", "Tu mejor marca", MenuTheme.GOLD))
	grid.add_child(_make_big_stat(_miles(em.partidas_jugadas), "PARTIDAS TOTALES", "Completadas", MenuTheme.CYAN))
	grid.add_child(_make_big_stat(_miles(em.kills_total), "ENEMIGOS DESTRUIDOS", "Acumulado", MenuTheme.RED))
	grid.add_child(_make_big_stat("%d/%d" % [_logros_completos(), em.ids_logros().size()], "LOGROS NIVEL MAX", "Al máximo", MenuTheme.VIOLET))
	v.add_child(grid)

	# Stats de economia (saldo actual real).
	var eco := get_node_or_null("/root/Economia")
	var ecos_val := _miles(eco.ecos) if eco else "0"
	var frag_val := _miles(eco.fragmentos) if eco else "0"
	v.add_child(_make_section_title("ECONOMIA"))
	v.add_child(_make_stat_row(MenuTheme.SYM_ECOS, "Ecos disponibles", ecos_val, MenuTheme.CYAN))
	v.add_child(_make_stat_row(MenuTheme.SYM_FRAG, "Fragmentos disponibles", frag_val, MenuTheme.VIOLET))


# Cuántos logros están en su nivel máximo (todos los tiers reclamados).
func _logros_completos() -> int:
	var n := 0
	for id in EstadisticasManager.ids_logros():
		if EstadisticasManager.todos_reclamados(id):
			n += 1
	return n


func _make_big_stat(value: String, label: String, sub: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(MenuTheme.BORDER_DIM))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 26)
	val.add_theme_color_override("font_color", color)
	_apply_hud_font(val)
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(lbl)
	var sub_lbl := Label.new()
	sub_lbl.text = sub
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	v.add_child(val)
	v.add_child(lbl)
	v.add_child(sub_lbl)
	return panel


func _make_section_title(text: String) -> Control:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", MenuTheme.GOLD)
	_apply_hud_font(lbl)
	return lbl


func _make_stat_row(symbol: String, name: String, value: String, color: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var icon := Label.new()
	icon.text = symbol
	icon.add_theme_font_size_override("font_size", 16)
	icon.custom_minimum_size = Vector2(20, 0)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var name_lbl := Label.new()
	name_lbl.text = name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 14)
	val.add_theme_color_override("font_color", color)
	_apply_hud_font(val)
	h.add_child(icon)
	h.add_child(name_lbl)
	h.add_child(val)
	return h


# ------------------------------------------------------------
# SECCION LOGROS.
# ------------------------------------------------------------
func _make_achievements_section() -> Control:
	_logros_box = VBoxContainer.new()
	_logros_box.add_theme_constant_override("separation", 8)
	_logros_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_refresh_logros()
	return _logros_box


# Reconstruye las cards de logros desde EstadisticasManager.
func _refresh_logros(_a = null) -> void:
	if _logros_box == null:
		return
	for c in _logros_box.get_children():
		c.queue_free()
	for id in EstadisticasManager.ids_logros():
		_logros_box.add_child(_make_achievement_card(id))


func _make_achievement_card(id: String) -> Control:
	var em := EstadisticasManager
	var completo: bool = em.todos_reclamados(id)
	var reclamable: bool = em.es_reclamable(id)
	var nivel: int = em.nivel_reclamado(id)          # tiers ya reclamados
	var total: int = em.num_tiers(id)

	# Color: dorado si reclamable, verde si completo, cian si en progreso.
	var accent := MenuTheme.CYAN
	if completo:
		accent = MenuTheme.GREEN
	elif reclamable:
		accent = MenuTheme.GOLD

	var panel := PanelContainer.new()
	var style := MenuTheme.make_card_style(MenuTheme.BORDER_DIM)
	if reclamable:
		style.border_color = Color(MenuTheme.GOLD.r, MenuTheme.GOLD.g, MenuTheme.GOLD.b, 0.35)
	panel.add_theme_stylebox_override("panel", style)
	if completo:
		panel.modulate.a = 0.65

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	panel.add_child(h)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)

	# Nombre + indicador de nivel (Nv. 2/4).
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	var name_lbl := Label.new()
	name_lbl.text = em.get_logro(id).get("nombre", id)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(name_lbl)
	var nivel_lbl := Label.new()
	nivel_lbl.text = "Nv. %d/%d" % [nivel, total]
	nivel_lbl.add_theme_font_size_override("font_size", 10)
	nivel_lbl.add_theme_color_override("font_color", accent)
	_apply_hud_font(nivel_lbl)
	name_row.add_child(name_lbl)
	name_row.add_child(nivel_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = "Completado — máximo nivel" if completo else em.descripcion_actual(id)
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)

	var prog_row := HBoxContainer.new()
	prog_row.add_theme_constant_override("separation", 6)
	var track := ProgressBar.new()
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.custom_minimum_size = Vector2(0, 2)
	track.min_value = 0
	track.max_value = 1.0
	track.value = em.progreso_actual(id)
	track.show_percentage = false
	track.add_theme_stylebox_override("background", MenuTheme.make_progress_track())
	track.add_theme_stylebox_override("fill", MenuTheme.make_progress_fill(accent))
	var prog_lbl := Label.new()
	if completo:
		prog_lbl.text = "MAX"
	else:
		var stat_val: int = em.get_stat(em.get_logro(id).get("stat", ""))
		prog_lbl.text = "%s / %s" % [_miles(stat_val), _miles(em.objetivo_actual(id))]
	prog_lbl.add_theme_font_size_override("font_size", 10)
	prog_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(prog_lbl)
	prog_row.add_child(track)
	prog_row.add_child(prog_lbl)

	info.add_child(name_row)
	info.add_child(desc_lbl)
	info.add_child(prog_row)
	h.add_child(info)

	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 4)
	var reward := Label.new()
	reward.text = "—" if completo else "%s %s" % [MenuTheme.SYM_ECOS, _miles(em.reward_actual(id))]
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward.add_theme_font_size_override("font_size", 11)
	reward.add_theme_color_override("font_color", MenuTheme.GOLD)
	_apply_hud_font(reward)

	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(80, 26)
	btn.add_theme_font_size_override("font_size", 10)
	_apply_hud_font(btn)
	if completo:
		btn.text = "✓ MAX"
		btn.disabled = true
		btn.add_theme_color_override("font_color", MenuTheme.GREEN)
	elif reclamable:
		btn.text = "Reclamar"
		btn.add_theme_color_override("font_color", MenuTheme.GOLD)
		btn.add_theme_stylebox_override("normal", MenuTheme.make_button_style(MenuTheme.GOLD, true))
		btn.add_theme_stylebox_override("hover", MenuTheme.make_button_style(MenuTheme.GOLD, true))
		btn.add_theme_stylebox_override("pressed", MenuTheme.make_button_style(MenuTheme.GOLD, true))
		btn.pressed.connect(func(): EstadisticasManager.reclamar(id))
	else:
		btn.text = "Pendiente"
		btn.disabled = true
		btn.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)

	right.add_child(reward)
	right.add_child(btn)
	h.add_child(right)

	return panel


func _miles(n: int) -> String:
	var s := str(n)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
	return result


# ------------------------------------------------------------
# SECCION HISTORIAL.
# ------------------------------------------------------------
func _make_history_section() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var runs := [
		{"asc": "Ascension 89", "tipo": "best",   "kills": "1,204", "ecos": "+312", "frags": "+84", "tiempo": "48m", "causa": "Limite de oleadas alcanzado", "fecha": "Hace 3 dias", "won": true},
		{"asc": "Ascension 47", "tipo": "normal", "kills": "312",   "ecos": "+84",  "frags": "+22", "tiempo": "31m", "causa": "Nucleo destruido por Tanque", "fecha": "Ayer", "won": false},
		{"asc": "Ascension 12", "tipo": "lost",   "kills": "88",    "ecos": "+20",  "frags": "+6",  "tiempo": "11m", "causa": "Desbordamiento de Kamikazes", "fecha": "Hace 3 dias", "won": false},
	]
	for r in runs:
		v.add_child(_make_run_card(r))
	return v


func _make_run_card(r: Dictionary) -> Control:
	var accent := MenuTheme.CYAN
	var badge_txt := "PARTIDA"
	match r["tipo"]:
		"best":
			accent = MenuTheme.GOLD
			badge_txt = "RECORD"
		"lost":
			accent = MenuTheme.RED
			badge_txt = "DERROTA"

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(MenuTheme.BORDER_DIM))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	# Top: ascension + badge.
	var top := HBoxContainer.new()
	var asc := Label.new()
	asc.text = r["asc"]
	asc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	asc.add_theme_font_size_override("font_size", 18)
	asc.add_theme_color_override("font_color", accent if r["tipo"] == "best" else MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(asc)
	top.add_child(asc)
	top.add_child(_make_pill(badge_txt, accent))
	v.add_child(top)

	# Stats row.
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 0)
	stats.add_child(_make_run_stat(r["kills"], "KILLS", MenuTheme.TEXT_PRIMARY))
	stats.add_child(_make_run_stat(r["ecos"] + " " + MenuTheme.SYM_ECOS, "ECOS", MenuTheme.CYAN))
	stats.add_child(_make_run_stat(r["frags"] + " " + MenuTheme.SYM_FRAG, "FRAGS", MenuTheme.VIOLET))
	stats.add_child(_make_run_stat(r["tiempo"], "TIEMPO", MenuTheme.TEXT_PRIMARY))
	v.add_child(stats)

	# Causa + fecha.
	var cause := HBoxContainer.new()
	cause.add_theme_constant_override("separation", 6)
	var cause_txt := Label.new()
	cause_txt.text = r["causa"]
	cause_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cause_txt.add_theme_font_size_override("font_size", 11)
	cause_txt.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	var fecha := Label.new()
	fecha.text = r["fecha"]
	fecha.add_theme_font_size_override("font_size", 11)
	fecha.add_theme_color_override("font_color", Color(MenuTheme.TEXT_MUTED.r, MenuTheme.TEXT_MUTED.g, MenuTheme.TEXT_MUTED.b, 0.6))
	cause.add_child(cause_txt)
	cause.add_child(fecha)
	v.add_child(cause)

	return panel


func _make_run_stat(value: String, label: String, color: Color) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.add_theme_font_size_override("font_size", 14)
	val.add_theme_color_override("font_color", color)
	_apply_hud_font(val)
	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(lbl)
	v.add_child(val)
	v.add_child(lbl)
	return v


# ------------------------------------------------------------
# Helpers.
# ------------------------------------------------------------
func on_show() -> void:
	_refresh_stats()
	_refresh_logros()
	_update_tab_colors()


func _toast(msg: String) -> void:
	push_warning("[Perfil] ", msg)


func _apply_hud_font(node) -> void:
	var f := MenuTheme.get_font_hud()
	if f and node.has_method("add_theme_font_override"):
		node.add_theme_font_override("font", f)


# ============================================================
# AvatarOrb: orbe Sentinel pequeno para el avatar de perfil.
# ============================================================
class AvatarOrb extends Control:
	var _t: float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var center := size / 2.0
		var r := 23.0
		var pulse := 1.0 + sin(_t * 2.0) * 0.05
		r *= pulse
		for i in range(4, 0, -1):
			draw_circle(center, r + i * 4.0, Color(0.0, 0.78, 1.0, 0.05))
		draw_circle(center, r, Color("003c78"))
		draw_circle(center - Vector2(r*0.2, r*0.2), r*0.7, Color("008cdc"))
		draw_circle(center - Vector2(r*0.3, r*0.3), r*0.4, Color("b4dcff"))
		# Anillo exterior cyan.
		draw_arc(center, 37, 0, TAU, 48, Color(0.0, 0.78, 1.0, 0.35), 1.0, true)
		var ang := _t * 0.8
		draw_circle(center + Vector2(cos(ang), sin(ang)) * 37.0, 2.5, MenuTheme.CYAN)
		# Anillo interior dorado punteado (giro inverso).
		var ang2 := -_t * 1.2
		draw_circle(center + Vector2(cos(ang2), sin(ang2)) * 29.0, 2.0, MenuTheme.GOLD)
