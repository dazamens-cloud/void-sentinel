extends Control

# ============================================================================
# PERFIL SCREEN
# ============================================================================

@onready var lbl_nombre      = $VBox/PlayerCard/InfoVBox/LblNombre
@onready var lbl_sub         = $VBox/PlayerCard/InfoVBox/LblSub
@onready var tier_bar        = $VBox/PlayerCard/InfoVBox/TierProgressBar
@onready var lbl_tier_prog   = $VBox/PlayerCard/InfoVBox/LblTierProgress
@onready var lbl_ascension   = $VBox/StatsRow/StatAscension/VBox/LblVal
@onready var lbl_partidas    = $VBox/StatsRow/StatPartidas/VBox/LblVal
@onready var lbl_commanders  = $VBox/StatsRow/StatCommanders/VBox/LblVal
@onready var logros_list     = $VBox/LogrosScroll/LogrosList
@onready var avatar_panel    = $VBox/PlayerCard/AvatarContainer

const TIER_DATA = [
	{ "min": 0,     "max": 4999,  "nombre": "I — Void Initiate",  "siguiente": 5000  },
	{ "min": 5000,  "max": 14999, "nombre": "II — Void Adept",    "siguiente": 15000 },
	{ "min": 15000, "max": 99999, "nombre": "III — Void Master",  "siguiente": 99999 },
]

const LOGROS_DATA = [
	{ "nombre": "Primera sangre",    "desc": "Completa tu primera partida",          "clave": "primera_partida"    },
	{ "nombre": "Commander Slayer",  "desc": "Elimina tu primer Commander",          "clave": "primer_commander"   },
	{ "nombre": "Superviviente",     "desc": "Alcanza la ascensión 500",             "clave": "asc_500"            },
	{ "nombre": "Forjador",          "desc": "Desbloquea la Forja",                  "clave": "forja_desbloqueada" },
	{ "nombre": "Tier II",           "desc": "Supera la ascensión 5.000",            "clave": "asc_5000"           },
	{ "nombre": "Intocable",         "desc": "Llega a asc. 200 sin recibir daño",    "clave": "intocable"          },
	{ "nombre": "Void Master",       "desc": "Alcanza la ascensión 10.000",          "clave": "asc_10000"          },
]

func _ready():
	_apply_styles()

func on_enter() -> void:
	_refresh_data()

func _refresh_data() -> void:
	var max_asc = Economia.numero_ascension

	lbl_ascension.text  = _fmt(max_asc)
	lbl_partidas.text   = "0"   # TODO: implementar contador de partidas
	lbl_commanders.text = "0"   # TODO: implementar contador de commanders eliminados

	var tier_info = _get_tier_info(max_asc)
	lbl_nombre.text = tier_info.nombre
	lbl_sub.text    = "Tier · Jugador desde v1.0"

	var rango = float(tier_info.max - tier_info.min)
	var progreso = float(max_asc - tier_info.min)
	tier_bar.value = clamp((progreso / rango) * 100.0, 0.0, 100.0)
	lbl_tier_prog.text = "Siguiente tier: asc. %s" % _fmt(tier_info.siguiente)

	# TODO: implementar sistema de logros persistente
	_build_logros({})

func _get_tier_info(max_asc: int) -> Dictionary:
	for t in TIER_DATA:
		if max_asc <= t.max:
			return t
	return TIER_DATA[-1]

func _build_logros(logros_desbloqueados: Dictionary) -> void:
	for child in logros_list.get_children():
		child.queue_free()

	for logro in LOGROS_DATA:
		var desbloqueado = logros_desbloqueados.get(logro.clave, false)
		var card = _make_logro_card(logro.nombre, logro.desc, desbloqueado)
		logros_list.add_child(card)

func _make_logro_card(nombre: String, desc: String, desbloqueado: bool) -> PanelContainer:
	var card = PanelContainer.new()
	var s = StyleBoxFlat.new()
	s.bg_color    = Color(0.051, 0.102, 0.051) if desbloqueado else Color(0.051, 0.051, 0.118)
	s.border_color = Color(0.102, 0.227, 0.102) if desbloqueado else Color(0.102, 0.102, 0.18)
	s.set_border_width_all(1)
	s.corner_radius_top_left = 9
	s.corner_radius_top_right = 9
	s.corner_radius_bottom_left = 9
	s.corner_radius_bottom_right = 9
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 9
	s.content_margin_bottom = 9
	card.add_theme_stylebox_override("panel", s)
	card.modulate.a = 1.0 if desbloqueado else 0.45

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var icon_box = PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(32, 32)
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color     = Color(0.118, 0.353, 0.118) if desbloqueado else Color(0.067, 0.067, 0.067)
	icon_style.border_color = Color(0.165, 0.541, 0.165) if desbloqueado else Color(0.102, 0.102, 0.18)
	icon_style.set_border_width_all(1)
	icon_style.corner_radius_top_left = 8
	icon_style.corner_radius_top_right = 8
	icon_style.corner_radius_bottom_left = 8
	icon_style.corner_radius_bottom_right = 8
	icon_box.add_theme_stylebox_override("panel", icon_style)
	var icon_lbl = Label.new()
	icon_lbl.text = "✓" if desbloqueado else "🔒"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 14)
	icon_lbl.add_theme_color_override("font_color",
		Color(0.29, 0.667, 0.29) if desbloqueado else Color(0.165, 0.165, 0.165))
	icon_box.add_child(icon_lbl)

	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl_n = Label.new()
	lbl_n.text = nombre
	lbl_n.add_theme_font_size_override("font_size", 11)
	lbl_n.add_theme_color_override("font_color",
		Color(0.667, 0.667, 0.667) if desbloqueado else Color(0.2, 0.2, 0.2))
	var lbl_d = Label.new()
	lbl_d.text = desc
	lbl_d.add_theme_font_size_override("font_size", 9)
	lbl_d.add_theme_color_override("font_color",
		Color(0.165, 0.353, 0.165) if desbloqueado else Color(0.133, 0.133, 0.133))
	text_vbox.add_child(lbl_n)
	text_vbox.add_child(lbl_d)

	hbox.add_child(icon_box)
	hbox.add_child(text_vbox)
	card.add_child(hbox)
	return card

func _apply_styles() -> void:
	var avatar_style = StyleBoxFlat.new()
	avatar_style.bg_color     = Color(0.059, 0.039, 0.118)
	avatar_style.border_color = Color(0.482, 0.188, 1.0)
	avatar_style.set_border_width_all(2)
	avatar_style.corner_radius_top_left = 26
	avatar_style.corner_radius_top_right = 26
	avatar_style.corner_radius_bottom_left = 26
	avatar_style.corner_radius_bottom_right = 26
	avatar_panel.add_theme_stylebox_override("panel", avatar_style)

	for card in [$VBox/StatsRow/StatAscension, $VBox/StatsRow/StatPartidas, $VBox/StatsRow/StatCommanders]:
		var s = StyleBoxFlat.new()
		s.bg_color     = Color(0.051, 0.051, 0.118)
		s.border_color = Color(0.102, 0.102, 0.188)
		s.set_border_width_all(1)
		s.corner_radius_top_left = 10
		s.corner_radius_top_right = 10
		s.corner_radius_bottom_left = 10
		s.corner_radius_bottom_right = 10
		s.content_margin_left = 8
		s.content_margin_right = 8
		s.content_margin_top = 8
		s.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", s)

func _fmt(n: int) -> String:
	if n >= 1_000_000: return "%.1fM" % (n / 1_000_000.0)
	elif n >= 1000:    return "%.1fk" % (n / 1000.0)
	return str(n)
