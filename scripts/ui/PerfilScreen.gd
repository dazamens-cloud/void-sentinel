class_name PerfilScreen
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


func _ready() -> void:
	_build()


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
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(name_lbl)

	var rank_row := HBoxContainer.new()
	rank_row.add_theme_constant_override("separation", 6)
	var badge := _make_pill("ELITE", MenuTheme.GOLD)
	var pts := Label.new()
	pts.text = "4,820 pts"
	pts.add_theme_font_size_override("font_size", 9)
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
	xp_lbl.add_theme_font_size_override("font_size", 8)
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
	lbl.add_theme_font_size_override("font_size", 8)
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
	lbl.add_theme_font_size_override("font_size", 9)
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
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 4 big stats en grid 2x2.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.add_child(_make_big_stat("89", "RECORD ASCENSION", "Ultima: Asc. 47", MenuTheme.GOLD))
	grid.add_child(_make_big_stat("23", "PARTIDAS TOTALES", "Ult. 7 dias: 5", MenuTheme.CYAN))
	grid.add_child(_make_big_stat("12.4K", "ENEMIGOS DESTRUIDOS", "Record: 1,204", MenuTheme.RED))
	grid.add_child(_make_big_stat("14h", "TIEMPO TOTAL", "Media: 36min", MenuTheme.VIOLET))
	v.add_child(grid)

	# Stats de economia.
	v.add_child(_make_section_title("ECONOMIA"))
	v.add_child(_make_stat_row(MenuTheme.SYM_ENERGIA, "Energia total generada", "2.84M", MenuTheme.GOLD))
	v.add_child(_make_stat_row(MenuTheme.SYM_ECOS, "Ecos acumulados", "8,430", MenuTheme.CYAN))
	v.add_child(_make_stat_row(MenuTheme.SYM_FRAG, "Fragmentos forjados", "1,920", MenuTheme.VIOLET))

	return v


func _make_big_stat(value: String, label: String, sub: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", MenuTheme.make_card_style(MenuTheme.BORDER_DIM))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 22)
	val.add_theme_color_override("font_color", color)
	_apply_hud_font(val)
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(lbl)
	var sub_lbl := Label.new()
	sub_lbl.text = sub
	sub_lbl.add_theme_font_size_override("font_size", 10)
	sub_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	v.add_child(val)
	v.add_child(lbl)
	v.add_child(sub_lbl)
	return panel


func _make_section_title(text: String) -> Control:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", MenuTheme.GOLD)
	_apply_hud_font(lbl)
	return lbl


func _make_stat_row(symbol: String, name: String, value: String, color: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var icon := Label.new()
	icon.text = symbol
	icon.add_theme_font_size_override("font_size", 14)
	icon.custom_minimum_size = Vector2(20, 0)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var name_lbl := Label.new()
	name_lbl.text = name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 12)
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
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var logros := [
		{"nombre": "Veterano",      "desc": "Alcanza Ascension 25",      "estado": "unlocked",    "prog": 1.0,  "reward": "1,000", "prog_txt": "Completado"},
		{"nombre": "Cazador",       "desc": "Elimina 1,000 enemigos",    "estado": "unlocked",    "prog": 1.0,  "reward": "500",   "prog_txt": "Completado"},
		{"nombre": "Elite",         "desc": "Alcanza Ascension 50",      "estado": "in_progress", "prog": 0.94, "reward": "5,000", "prog_txt": "47 / 50"},
		{"nombre": "Exterminador",  "desc": "Elimina 10,000 enemigos",   "estado": "in_progress", "prog": 0.62, "reward": "2,000", "prog_txt": "6,200 / 10,000"},
		{"nombre": "Primera Sangre","desc": "Alcanza Ascension 5",       "estado": "claimed",     "prog": 1.0,  "reward": "100",   "prog_txt": "Reclamado"},
	]
	for l in logros:
		v.add_child(_make_achievement_card(l))
	return v


func _make_achievement_card(l: Dictionary) -> Control:
	var estado: String = l["estado"]
	var accent := MenuTheme.GOLD
	if estado == "claimed":
		accent = MenuTheme.GREEN
	elif estado == "in_progress":
		accent = MenuTheme.CYAN

	var panel := PanelContainer.new()
	var style := MenuTheme.make_card_style(MenuTheme.BORDER_DIM)
	if estado == "unlocked":
		style.border_color = Color(MenuTheme.GOLD.r, MenuTheme.GOLD.g, MenuTheme.GOLD.b, 0.2)
	panel.add_theme_stylebox_override("panel", style)
	if estado == "claimed":
		panel.modulate.a = 0.65

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	panel.add_child(h)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	var name_lbl := Label.new()
	name_lbl.text = l["nombre"]
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_PRIMARY)
	_apply_hud_font(name_lbl)
	var desc_lbl := Label.new()
	desc_lbl.text = l["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	var prog_row := HBoxContainer.new()
	prog_row.add_theme_constant_override("separation", 6)
	var track := ProgressBar.new()
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.custom_minimum_size = Vector2(0, 2)
	track.min_value = 0
	track.max_value = 1.0
	track.value = l["prog"]
	track.show_percentage = false
	track.add_theme_stylebox_override("background", MenuTheme.make_progress_track())
	track.add_theme_stylebox_override("fill", MenuTheme.make_progress_fill(accent))
	var prog_lbl := Label.new()
	prog_lbl.text = l["prog_txt"]
	prog_lbl.add_theme_font_size_override("font_size", 8)
	prog_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	_apply_hud_font(prog_lbl)
	prog_row.add_child(track)
	prog_row.add_child(prog_lbl)
	info.add_child(name_lbl)
	info.add_child(desc_lbl)
	info.add_child(prog_row)
	h.add_child(info)

	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 4)
	var reward := Label.new()
	reward.text = "%s %s" % [MenuTheme.SYM_ECOS, l["reward"]]
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward.add_theme_font_size_override("font_size", 9)
	reward.add_theme_color_override("font_color", MenuTheme.GOLD)
	_apply_hud_font(reward)

	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 8)
	_apply_hud_font(btn)
	match estado:
		"unlocked":
			btn.text = "Reclamar"
			btn.add_theme_color_override("font_color", MenuTheme.GOLD)
			btn.add_theme_stylebox_override("normal", MenuTheme.make_button_style(MenuTheme.GOLD, true))
			btn.add_theme_stylebox_override("hover", MenuTheme.make_button_style(MenuTheme.GOLD, true))
			btn.add_theme_stylebox_override("pressed", MenuTheme.make_button_style(MenuTheme.GOLD, true))
			btn.pressed.connect(func(): _on_claim(btn, panel, l["reward"]))
		"claimed":
			btn.text = "OK"
			btn.disabled = true
			btn.add_theme_color_override("font_color", MenuTheme.GREEN)
		"in_progress":
			btn.text = "Pendiente"
			btn.disabled = true
			btn.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)

	right.add_child(reward)
	right.add_child(btn)
	h.add_child(right)

	return panel


func _on_claim(btn: Button, panel: PanelContainer, reward: String) -> void:
	btn.text = "OK"
	btn.disabled = true
	btn.add_theme_color_override("font_color", MenuTheme.GREEN)
	panel.modulate.a = 0.65
	# TODO: sumar la recompensa real al saldo de Ecos via Economia.
	_toast("Recompensa: " + reward)


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
	asc.add_theme_font_size_override("font_size", 16)
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
	cause_txt.add_theme_font_size_override("font_size", 9)
	cause_txt.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	var fecha := Label.new()
	fecha.text = r["fecha"]
	fecha.add_theme_font_size_override("font_size", 9)
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
	val.add_theme_font_size_override("font_size", 12)
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
# Helpers.
# ------------------------------------------------------------
func on_show() -> void:
	_update_tab_colors()


func _toast(msg: String) -> void:
	print("[Perfil] ", msg)


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
