extends Control

# ============================================================================
# FORJA SCREEN - Árbol de habilidades manuales
# ============================================================================

var current_side: String = "ofensiva"
var detalle_id: String   = ""

@onready var view_lista   = $ViewLista
@onready var view_detalle = $ViewDetalle
@onready var hab_list     = $ViewLista/HabilidadesScroll/HabilidadesList
@onready var params_list  = $ViewDetalle/ParamsScroll/ParamsList
@onready var btn_ofensiva = $ViewLista/TabsBar/BtnOfensiva
@onready var btn_defensiva= $ViewLista/TabsBar/BtnDefensiva
@onready var btn_volver   = $ViewDetalle/BtnVolver
@onready var lbl_nombre   = $ViewDetalle/HeaderDetalle/InfoVBox/LblNombreDetalle
@onready var lbl_desc     = $ViewDetalle/HeaderDetalle/InfoVBox/LblDescDetalle
@onready var lbl_frag_det = $ViewDetalle/HeaderDetalle/FragBadgeDetalle/HBox/LblFragDetalle

const COLOR_OFENSIVA  = Color(0.878, 0.314, 0.314)
const COLOR_DEFENSIVA = Color(0.29, 0.608, 1.0)
const COLOR_ORANGE    = Color(1.0, 0.42, 0.0)
const COLOR_INACTIVE  = Color(0.2, 0.2, 0.251)
const COLOR_GREEN     = Color(0.29, 0.667, 0.29)

# Datos de habilidades
var habilidades = {
	"ofensiva": [
		{ "id": "enjambre",     "nombre": "Enjambre de Proyectiles", "desc": "24 proyectiles en 360°",   "coste": 80,  "umbral": 2100, "req": [],
		  "params": [
			{ "id": "p_cant", "nombre": "Proyectiles",       "nivel": 0, "max": 4, "coste_base": 20, "desc": "+4 proyectiles"    },
			{ "id": "p_dan",  "nombre": "Daño por proyectil","nivel": 0, "max": 4, "coste_base": 20, "desc": "+10% daño base"    },
			{ "id": "p_vel",  "nombre": "Velocidad",         "nivel": 0, "max": 4, "coste_base": 20, "desc": "+50 px/s"          },
			{ "id": "p_cd",   "nombre": "Cooldown",          "nivel": 0, "max": 4, "coste_base": 35, "desc": "-1s cooldown"      },
			{ "id": "p_pen",  "nombre": "Penetración",       "nivel": 0, "max": 4, "coste_base": 55, "desc": "+1 enemigo"        },
		  ]},
		{ "id": "emp",          "nombre": "Pulso EMP",               "desc": "Anti-escudo y anti-armadura","coste": 120, "umbral": 2500, "req": ["enjambre"],
		  "params": [
			{ "id": "e_dan",  "nombre": "Daño base",         "nivel": 0, "max": 4, "coste_base": 35, "desc": "+20% daño"         },
			{ "id": "e_mul",  "nombre": "Multiplicador",     "nivel": 0, "max": 4, "coste_base": 55, "desc": "+0.3x vs escudo"   },
			{ "id": "e_stu",  "nombre": "Duración stun",     "nivel": 0, "max": 4, "coste_base": 35, "desc": "+1s escudos caídos"},
			{ "id": "e_cd",   "nombre": "Cooldown",          "nivel": 0, "max": 4, "coste_base": 55, "desc": "-1.5s cooldown"    },
		  ]},
		{ "id": "cadena",       "nombre": "Detonación en Cadena",    "desc": "Explosión en cascada",      "coste": 180, "umbral": 3500, "req": ["enjambre","emp","escudoc","tiempo"],
		  "params": [
			{ "id": "c_dan",  "nombre": "Daño explosión",   "nivel": 0, "max": 4, "coste_base": 55, "desc": "+30% daño"         },
			{ "id": "c_rad",  "nombre": "Radio",            "nivel": 0, "max": 4, "coste_base": 55, "desc": "+15px radio"       },
			{ "id": "c_sal",  "nombre": "Saltos",           "nivel": 0, "max": 4, "coste_base": 80, "desc": "+1 salto"          },
			{ "id": "c_cd",   "nombre": "Cooldown",         "nivel": 0, "max": 4, "coste_base": 80, "desc": "-2s cooldown"      },
		  ]},
		{ "id": "singularidad", "nombre": "Singularidad",            "desc": "Agujero negro temporal",    "coste": 280, "umbral": 5000, "req": ["enjambre","emp","cadena","escudoc","tiempo","emergencia"],
		  "params": [
			{ "id": "s_fue",  "nombre": "Fuerza atracción", "nivel": 0, "max": 4, "coste_base": 80,  "desc": "+2 unidades/s²"  },
			{ "id": "s_dan",  "nombre": "Daño implosión",   "nivel": 0, "max": 4, "coste_base": 80,  "desc": "+25% daño"       },
			{ "id": "s_dur",  "nombre": "Duración",         "nivel": 0, "max": 4, "coste_base": 80,  "desc": "+0.5s"           },
			{ "id": "s_cd",   "nombre": "Cooldown",         "nivel": 0, "max": 4, "coste_base": 120, "desc": "-2s cooldown"    },
		  ]},
	],
	"defensiva": [
		{ "id": "escudoc",      "nombre": "Escudo de Colapso",       "desc": "Barrera de absorción",      "coste": 80,  "umbral": 2100, "req": [],
		  "params": [
			{ "id": "ec_abs", "nombre": "Absorción",       "nivel": 0, "max": 4, "coste_base": 20, "desc": "+50% vida máx."    },
			{ "id": "ec_dur", "nombre": "Duración",        "nivel": 0, "max": 4, "coste_base": 35, "desc": "+1s duración"      },
			{ "id": "ec_cd",  "nombre": "Cooldown",        "nivel": 0, "max": 4, "coste_base": 35, "desc": "-2s cooldown"      },
			{ "id": "ec_reb", "nombre": "Rebote al romper","nivel": 0, "max": 4, "coste_base": 80, "desc": "Daño al romperse"  },
		  ]},
		{ "id": "tiempo",       "nombre": "Campo de Tiempo",         "desc": "Ralentiza todos los enemigos","coste": 120,"umbral": 2500, "req": ["escudoc"],
		  "params": [
			{ "id": "t_slo",  "nombre": "Intensidad slow", "nivel": 0, "max": 4, "coste_base": 35, "desc": "-5% vel. enemigos" },
			{ "id": "t_dur",  "nombre": "Duración",        "nivel": 0, "max": 4, "coste_base": 35, "desc": "+1s duración"      },
			{ "id": "t_cd",   "nombre": "Cooldown",        "nivel": 0, "max": 4, "coste_base": 55, "desc": "-2s cooldown"      },
			{ "id": "t_dan",  "nombre": "Daño en slow",    "nivel": 0, "max": 4, "coste_base": 80, "desc": "+15% daño a lentos"},
		  ]},
		{ "id": "emergencia",   "nombre": "Protocolo de Emergencia", "desc": "Curación instantánea",      "coste": 180, "umbral": 3500, "req": ["escudoc","tiempo","enjambre","emp"],
		  "params": [
			{ "id": "em_cur", "nombre": "% Curación",     "nivel": 0, "max": 4, "coste_base": 55, "desc": "+5% vida máx."     },
			{ "id": "em_cd",  "nombre": "Cooldown",       "nivel": 0, "max": 4, "coste_base": 55, "desc": "-2s cooldown"      },
			{ "id": "em_reg", "nombre": "Regen post-cura","nivel": 0, "max": 4, "coste_base": 80, "desc": "+1% regen/s 10s"   },
		  ]},
		{ "id": "interferencia","nombre": "Manto de Interferencia",  "desc": "Bloquea targeting enemigo", "coste": 280, "umbral": 5000, "req": ["escudoc","tiempo","emergencia","enjambre","emp","cadena"],
		  "params": [
			{ "id": "i_dur",  "nombre": "Duración",   "nivel": 0, "max": 4, "coste_base": 80,  "desc": "+1s duración"          },
			{ "id": "i_cd",   "nombre": "Cooldown",   "nivel": 0, "max": 4, "coste_base": 80,  "desc": "-2s cooldown"          },
			{ "id": "i_ref",  "nombre": "Reflejo",    "nivel": 0, "max": 4, "coste_base": 180, "desc": "Proyectiles al enemigo" },
		  ]},
	],
}

var purchased: Dictionary = {}
var ascension_actual: int = 0

func _ready():
	_init_purchased()
	btn_ofensiva.pressed.connect(func(): _switch_side("ofensiva"))
	btn_defensiva.pressed.connect(func(): _switch_side("defensiva"))
	btn_volver.pressed.connect(_close_detalle)
	_apply_tab_style("ofensiva")

func on_enter() -> void:
	_load_from_save()
	_render_lista()

func _init_purchased() -> void:
	for side in habilidades:
		for h in habilidades[side]:
			purchased[h.id] = false

func _load_from_save() -> void:
	if not SaveSystem:
		return
	var data = SaveSystem.get_all_data()
	ascension_actual = data.get("max_ascension", 0)
	var saved_purchased = data.get("forja_purchased", {})
	var saved_params    = data.get("forja_params", {})
	for id in saved_purchased:
		purchased[id] = saved_purchased[id]
	for side in habilidades:
		for h in habilidades[side]:
			for p in h.params:
				if saved_params.has(p.id):
					p.nivel = saved_params[p.id]

func _get_state(h: Dictionary) -> String:
	if purchased.get(h.id, false):
		return "comprada"
	var reqs_met = h.req.all(func(r): return purchased.get(r, false))
	if not reqs_met:
		return "bloqueada_req"
	if ascension_actual < h.umbral:
		return "bloqueada_asc"
	var frags = SaveSystem.get_fragmentos() if SaveSystem else 0
	if frags < h.coste:
		return "sin_fondos"
	return "disponible"

func _switch_side(side: String) -> void:
	current_side = side
	_apply_tab_style(side)
	_render_lista()

func _apply_tab_style(side: String) -> void:
	var co = COLOR_OFENSIVA if side == "ofensiva" else COLOR_INACTIVE
	var cd = COLOR_DEFENSIVA if side == "defensiva" else COLOR_INACTIVE
	btn_ofensiva.add_theme_color_override("font_color", co)
	btn_defensiva.add_theme_color_override("font_color", cd)

func _render_lista() -> void:
	for child in hab_list.get_children():
		child.queue_free()
	var color = COLOR_OFENSIVA if current_side == "ofensiva" else COLOR_DEFENSIVA
	var side_data = habilidades[current_side]
	for i in side_data.size():
		var h = side_data[i]
		hab_list.add_child(_make_hab_card(h, i + 1, color))
		if i < side_data.size() - 1:
			hab_list.add_child(_make_connector(_get_state(h) == "comprada"))

func _make_connector(comprada: bool) -> Control:
	var c = ColorRect.new()
	c.custom_minimum_size = Vector2(1, 10)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.color = Color(0.118, 0.353, 0.118) if comprada else Color(0.102, 0.102, 0.18)
	return c

func _make_hab_card(h: Dictionary, idx: int, color: Color) -> PanelContainer:
	var state = _get_state(h)
	var is_locked   = state in ["bloqueada_req", "bloqueada_asc"]
	var is_comprada = state == "comprada"
	var is_avail    = state == "disponible"

	var card = PanelContainer.new()
	var s = StyleBoxFlat.new()
	s.bg_color     = Color(0.051, 0.102, 0.051) if is_comprada else Color(0.051, 0.051, 0.118)
	s.border_color = Color(0.102, 0.227, 0.102) if is_comprada else Color(0.102, 0.102, 0.18)
	s.set_border_width_all(1)
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 11
	s.content_margin_bottom = 11
	card.add_theme_stylebox_override("panel", s)
	card.modulate.a = 0.45 if is_locked else 1.0

	if is_comprada:
		card.gui_input.connect(func(ev): _on_card_click(ev, h.id))

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	# Número / estado
	var num_box = PanelContainer.new()
	num_box.custom_minimum_size = Vector2(24, 24)
	var ns = StyleBoxFlat.new()
	ns.bg_color     = Color(0.118, 0.353, 0.118) if is_comprada else (Color(0.067,0.067,0.067) if is_locked else Color(color.r,color.g,color.b,0.13))
	ns.border_color = Color(0.165, 0.541, 0.165) if is_comprada else (Color(0.102,0.102,0.18) if is_locked else color)
	ns.set_border_width_all(1)
	ns.corner_radius_top_left = 12
	ns.corner_radius_top_right = 12
	ns.corner_radius_bottom_left = 12
	ns.corner_radius_bottom_right = 12
	num_box.add_theme_stylebox_override("panel", ns)
	var num_lbl = Label.new()
	num_lbl.text = "✓" if is_comprada else ("🔒" if is_locked else str(idx))
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", 10)
	num_lbl.add_theme_color_override("font_color",
		COLOR_GREEN if is_comprada else (Color(0.165,0.165,0.165) if is_locked else color))
	num_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	num_box.add_child(num_lbl)

	# Texto
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl_n = Label.new()
	lbl_n.text = h.nombre
	lbl_n.clip_text = true
	lbl_n.add_theme_font_size_override("font_size", 12)
	lbl_n.add_theme_color_override("font_color", Color(0.8,0.8,0.8) if not is_locked else Color(0.2,0.2,0.2))
	var lbl_d = Label.new()
	lbl_d.text = h.desc
	lbl_d.add_theme_font_size_override("font_size", 9)
	lbl_d.add_theme_color_override("font_color", Color(0.267,0.267,0.267) if not is_locked else Color(0.133,0.133,0.133))
	left.add_child(lbl_n)
	left.add_child(lbl_d)

	if is_comprada:
		var total_niv = h.params.reduce(func(acc, p): return acc + p.nivel, 0)
		var total_max = h.params.size() * 4
		var prog_hbox = HBoxContainer.new()
		prog_hbox.add_theme_constant_override("separation", 4)
		var lbl_prog_key = Label.new()
		lbl_prog_key.text = "Mejoras"
		lbl_prog_key.add_theme_font_size_override("font_size", 9)
		lbl_prog_key.add_theme_color_override("font_color", Color(0.165,0.353,0.165))
		var lbl_prog_val = Label.new()
		lbl_prog_val.text = "%d/%d" % [total_niv, total_max]
		lbl_prog_val.add_theme_font_size_override("font_size", 9)
		lbl_prog_val.add_theme_color_override("font_color", Color(0.165,0.353,0.165))
		prog_hbox.add_child(lbl_prog_key)
		prog_hbox.add_child(lbl_prog_val)
		left.add_child(prog_hbox)

	# Botón derecho
	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(72, 0)
	right.alignment = BoxContainer.ALIGNMENT_CENTER

	if is_comprada:
		var btn = Button.new()
		btn.text = "VER MEJORAS"
		btn.flat = false
		btn.add_theme_font_size_override("font_size", 9)
		var bs = StyleBoxFlat.new()
		bs.bg_color     = Color(0.102, 0.227, 0.102)
		bs.border_color = Color(0.165, 0.353, 0.165)
		bs.set_border_width_all(1)
		bs.corner_radius_top_left = 8
		bs.corner_radius_top_right = 8
		bs.corner_radius_bottom_left = 8
		bs.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", bs)
		btn.add_theme_color_override("font_color", COLOR_GREEN)
		btn.pressed.connect(func(): _open_detalle(h.id))
		right.add_child(btn)
	elif is_avail:
		var frags = SaveSystem.get_fragmentos() if SaveSystem else 0
		var afford = frags >= h.coste
		var btn = Button.new()
		btn.text = "DESBLOQUEAR"
		btn.flat = false
		btn.add_theme_font_size_override("font_size", 9)
		var bs = StyleBoxFlat.new()
		bs.bg_color     = Color(color.r, color.g, color.b, 0.13) if afford else Color(0.067,0.067,0.067)
		bs.border_color = color if afford else Color(0.102,0.102,0.18)
		bs.set_border_width_all(1)
		bs.corner_radius_top_left = 8
		bs.corner_radius_top_right = 8
		bs.corner_radius_bottom_left = 8
		bs.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", bs)
		btn.add_theme_color_override("font_color", color if afford else Color(0.2,0.2,0.2))
		btn.disabled = not afford
		if afford:
			btn.pressed.connect(func(): _comprar_habilidad(h))
		var coste_hbox = HBoxContainer.new()
		coste_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var sym = Label.new()
		sym.text = "⬡"
		sym.add_theme_font_size_override("font_size", 9)
		sym.add_theme_color_override("font_color", COLOR_ORANGE if afford else Color(0.227,0.165,0.102))
		var lbl_c = Label.new()
		lbl_c.text = str(h.coste)
		lbl_c.add_theme_font_size_override("font_size", 9)
		lbl_c.add_theme_color_override("font_color", Color(0.667,0.667,0.667) if afford else Color(0.165,0.165,0.165))
		coste_hbox.add_child(sym)
		coste_hbox.add_child(lbl_c)
		right.add_child(btn)
		right.add_child(coste_hbox)
	else:
		var lbl_blk = Label.new()
		lbl_blk.text = "Asc. %d" % h.umbral if state == "bloqueada_asc" else "BLOQUEADA"
		lbl_blk.add_theme_font_size_override("font_size", 9)
		lbl_blk.add_theme_color_override("font_color", Color(0.165,0.165,0.227))
		right.add_child(lbl_blk)

	hbox.add_child(num_box)
	hbox.add_child(left)
	hbox.add_child(right)
	card.add_child(hbox)
	return card

func _on_card_click(ev: InputEvent, hab_id: String) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_open_detalle(hab_id)

func _comprar_habilidad(h: Dictionary) -> void:
	if not SaveSystem: return
	if SaveSystem.get_fragmentos() < h.coste: return
	SaveSystem.spend_fragmentos(h.coste)
	purchased[h.id] = true
	SaveSystem.set_forja_purchased(h.id, true)
	_render_lista()

func _open_detalle(hab_id: String) -> void:
	detalle_id = hab_id
	var h = _find_hab(hab_id)
	if not h: return
	lbl_nombre.text = h.nombre
	lbl_desc.text   = h.desc
	view_lista.visible   = false
	view_detalle.visible = true
	_render_params()

func _close_detalle() -> void:
	view_detalle.visible = false
	view_lista.visible   = true
	_render_lista()

func _render_params() -> void:
	for child in params_list.get_children():
		child.queue_free()
	var h = _find_hab(detalle_id)
	if not h: return
	var frags = SaveSystem.get_fragmentos() if SaveSystem else 0
	lbl_frag_det.text = _fmt(frags)
	var color = COLOR_OFENSIVA if current_side == "ofensiva" else COLOR_DEFENSIVA
	var lbl_section = Label.new()
	lbl_section.text = "MEJORAS DE HABILIDAD"
	lbl_section.add_theme_font_size_override("font_size", 9)
	lbl_section.add_theme_color_override("font_color", Color(0.267,0.267,0.267))
	params_list.add_child(lbl_section)
	for p in h.params:
		params_list.add_child(_make_param_card(p, frags, color))

func _make_param_card(p: Dictionary, frags: int, color: Color) -> PanelContainer:
	var coste   = _param_cost(p)
	var afford  = frags >= coste
	var maxed   = p.nivel >= p.max

	var card = PanelContainer.new()
	var s = StyleBoxFlat.new()
	s.bg_color     = Color(0.051, 0.051, 0.118)
	s.border_color = Color(0.102, 0.102, 0.188)
	s.set_border_width_all(1)
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", s)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl_n = Label.new()
	lbl_n.text = p.nombre
	lbl_n.add_theme_font_size_override("font_size", 12)
	lbl_n.add_theme_color_override("font_color", Color(0.8,0.8,0.8))
	var lbl_d = Label.new()
	lbl_d.text = p.desc
	lbl_d.add_theme_font_size_override("font_size", 9)
	lbl_d.add_theme_color_override("font_color", Color(0.267,0.267,0.267))
	var niv_hbox = HBoxContainer.new()
	niv_hbox.add_theme_constant_override("separation", 4)
	var lk = Label.new(); lk.text = "Nv."; lk.add_theme_font_size_override("font_size", 9)
	lk.add_theme_color_override("font_color", Color(0.333,0.333,0.333))
	var lv = Label.new(); lv.text = str(p.nivel); lv.add_theme_font_size_override("font_size", 11)
	lv.add_theme_color_override("font_color", color)
	var lmax = Label.new(); lmax.text = "/ %d" % p.max; lmax.add_theme_font_size_override("font_size", 9)
	lmax.add_theme_color_override("font_color", Color(0.165,0.165,0.227))
	niv_hbox.add_child(lk); niv_hbox.add_child(lv); niv_hbox.add_child(lmax)
	left.add_child(lbl_n); left.add_child(lbl_d); left.add_child(niv_hbox)

	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(68, 0)
	right.alignment = BoxContainer.ALIGNMENT_CENTER

	if maxed:
		var lbl_max = Label.new()
		lbl_max.text = "MAX"
		lbl_max.add_theme_font_size_override("font_size", 10)
		lbl_max.add_theme_color_override("font_color", Color(0.118,0.353,0.118))
		right.add_child(lbl_max)
	else:
		var btn = Button.new()
		btn.text = "MEJORAR"
		btn.flat = false
		btn.add_theme_font_size_override("font_size", 10)
		var bs = StyleBoxFlat.new()
		bs.bg_color     = Color(color.r,color.g,color.b,0.13) if afford else Color(0.067,0.067,0.067)
		bs.border_color = color if afford else Color(0.102,0.102,0.18)
		bs.set_border_width_all(1)
		bs.corner_radius_top_left = 8
		bs.corner_radius_top_right = 8
		bs.corner_radius_bottom_left = 8
		bs.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", bs)
		btn.add_theme_color_override("font_color", color if afford else Color(0.2,0.2,0.2))
		btn.disabled = not afford
		if afford:
			btn.pressed.connect(func(): _comprar_param(p))
		var ch = HBoxContainer.new()
		ch.alignment = BoxContainer.ALIGNMENT_CENTER
		var sym = Label.new(); sym.text = "⬡"; sym.add_theme_font_size_override("font_size", 9)
		sym.add_theme_color_override("font_color", COLOR_ORANGE if afford else Color(0.227,0.165,0.102))
		var lc = Label.new(); lc.text = _fmt(coste); lc.add_theme_font_size_override("font_size", 9)
		lc.add_theme_color_override("font_color", Color(0.667,0.667,0.667) if afford else Color(0.165,0.165,0.165))
		ch.add_child(sym); ch.add_child(lc)
		right.add_child(btn); right.add_child(ch)

	hbox.add_child(left); hbox.add_child(right)
	card.add_child(hbox)
	return card

func _comprar_param(p: Dictionary) -> void:
	if not SaveSystem: return
	var coste = _param_cost(p)
	if SaveSystem.get_fragmentos() < coste: return
	SaveSystem.spend_fragmentos(coste)
	p.nivel += 1
	SaveSystem.set_forja_param(p.id, p.nivel)
	_render_params()

func _param_cost(p: Dictionary) -> int:
	return int(p.coste_base * pow(1.09, p.nivel))

func _find_hab(hab_id: String) -> Dictionary:
	for side in habilidades:
		for h in habilidades[side]:
			if h.id == hab_id:
				return h
	return {}

func _fmt(n: int) -> String:
	if n >= 1_000_000: return "%.1fM" % (n / 1_000_000.0)
	elif n >= 1000:    return "%.1fk" % (n / 1000.0)
	return str(n)
