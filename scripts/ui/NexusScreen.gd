extends Control

# ============================================================================
# NEXUS SCREEN - Meta-mejoras permanentes
# ============================================================================

enum Categoria { ATAQUE, DEFENSA, BONUS, COMMANDER }

var current_cat: Categoria = Categoria.ATAQUE

@onready var mejoras_list = $VBox/MejorasScroll/MejorasList
@onready var tabs = {
	Categoria.ATAQUE:    $VBox/TabsBar/BtnAtaque,
	Categoria.DEFENSA:   $VBox/TabsBar/BtnDefensa,
	Categoria.BONUS:     $VBox/TabsBar/BtnBonus,
	Categoria.COMMANDER: $VBox/TabsBar/BtnCommander,
}

const TAB_COLORS = {
	Categoria.ATAQUE:    Color(0.878, 0.314, 0.314),
	Categoria.DEFENSA:   Color(0.29, 0.608, 1.0),
	Categoria.BONUS:     Color(0.482, 0.188, 1.0),
	Categoria.COMMANDER: Color(1.0, 0.42, 0.0),
}
const COLOR_INACTIVE = Color(0.2, 0.2, 0.251)
const COLOR_GOLD     = Color(0.961, 0.651, 0.137)

# Datos de mejoras — se sincronizan con SaveSystem
var mejoras_data = {
	Categoria.ATAQUE: [
		{ "id": "danio",          "nombre": "Daño base",          "nivel": 0, "coste_base": 1840, "desc": "+2.5% daño por nivel"      },
		{ "id": "velocidad_ataque","nombre": "Velocidad de ataque","nivel": 0, "coste_base": 2100, "desc": "+1 disparo/seg por nivel"   },
		{ "id": "disparo_critico","nombre": "Disparo crítico",     "nivel": 0, "coste_base": 3200, "desc": "+5% probabilidad crítico"   },
		{ "id": "multidisparo",   "nombre": "Multidisparo",        "nivel": 0, "coste_base": 5800, "desc": "+1 proyectil adicional"     },
		{ "id": "rebote",         "nombre": "Rebote",              "nivel": 0, "coste_base": 8400, "desc": "+1 rebote por proyectil"    },
		{ "id": "alcance_rebote", "nombre": "Alcance de rebote",   "nivel": 0, "coste_base": 9200, "desc": "+20% distancia de rebote"   },
	],
	Categoria.DEFENSA: [
		{ "id": "salud",          "nombre": "Salud máxima",        "nivel": 0, "coste_base": 1600, "desc": "+500 HP por nivel"          },
		{ "id": "recuperacion",   "nombre": "Recuperación",        "nivel": 0, "coste_base": 2400, "desc": "+0.5% regen/seg"            },
		{ "id": "escudo",         "nombre": "Escudo",              "nivel": 0, "coste_base": 4200, "desc": "+10% absorción de escudo"   },
		{ "id": "dureza_escudo",  "nombre": "Dureza de escudo",    "nivel": 0, "coste_base": 5600, "desc": "-5% daño con escudo"        },
		{ "id": "pulso_quartz",   "nombre": "Pulso Quartz",        "nivel": 0, "coste_base": 7800, "desc": "+15% daño del pulso"        },
		{ "id": "poder_pulso",    "nombre": "Poder del pulso",     "nivel": 0, "coste_base": 10200,"desc": "+25% radio del pulso"       },
	],
	Categoria.BONUS: [
		{ "id": "energia_ascension","nombre": "Energía por ascensión","nivel": 0,"coste_base": 2200, "desc": "+5% monedas al subir"     },
		{ "id": "energia_espectro","nombre": "Energía por espectro", "nivel": 0,"coste_base": 2600, "desc": "+3% drop por enemigo"      },
		{ "id": "ecos_ascension", "nombre": "Ecos de ascensión",    "nivel": 0, "coste_base": 3400, "desc": "+2% fragmentos/ascensión"  },
		{ "id": "ecos_rapido",    "nombre": "Ecos rápidos",         "nivel": 0, "coste_base": 4800, "desc": "-10% tiempo entre drops"   },
		{ "id": "mejora_X_gratis","nombre": "Mejora gratuita I",    "nivel": 0, "coste_base": 12000,"desc": "1 mejora gratis/10 asc."   },
		{ "id": "mejora_X_gratis2","nombre": "Mejora gratuita II",  "nivel": 0, "coste_base": 18000,"desc": "2 mejoras gratis/15 asc."  },
		{ "id": "interes_tasa",   "nombre": "Tasa de interés",      "nivel": 0, "coste_base": 6000, "desc": "+2.5% interés monedas"     },
	],
	Categoria.COMMANDER: [
		{ "id": "blindaje",           "nombre": "Blindaje Commander",   "nivel": 0, "coste_base": 4400,  "desc": "-8% daño del Commander"  },
		{ "id": "precision_comandante","nombre": "Precisión Commander",  "nivel": 0, "coste_base": 7200,  "desc": "+10% crítico al Cmd."    },
		{ "id": "aura_comandante",    "nombre": "Aura Commander",       "nivel": 0, "coste_base": 9800,  "desc": "-5% vel. spawn Cmd."     },
		{ "id": "cadencia_comandante","nombre": "Cadencia Commander",   "nivel": 0, "coste_base": 14000, "desc": "+15% daño zona Cmd."     },
	],
}

func _ready():
	_apply_tab_styles()
	for cat in tabs:
		var c = cat
		tabs[c].pressed.connect(func(): _switch_cat(c))
	_switch_cat(Categoria.ATAQUE)

func on_enter() -> void:
	_load_niveles_from_save()
	_render_mejoras()

func _load_niveles_from_save() -> void:
	if not SaveSystem:
		return
	var saved = SaveSystem.get_mejoras_nexus()
	if not saved:
		return
	for cat in mejoras_data:
		for m in mejoras_data[cat]:
			if saved.has(m.id):
				m.nivel = saved[m.id]

func _get_coste(m: Dictionary) -> int:
	return int(m.coste_base * pow(1.09, m.nivel))

func _switch_cat(cat: Categoria) -> void:
	current_cat = cat
	for c in tabs:
		var color = TAB_COLORS[c] if c == cat else COLOR_INACTIVE
		tabs[c].add_theme_color_override("font_color", color)
	_render_mejoras()

func _render_mejoras() -> void:
	for child in mejoras_list.get_children():
		child.queue_free()

	var gold = SaveSystem.get_gold() if SaveSystem else 0
	var color = TAB_COLORS[current_cat]

	for m in mejoras_data[current_cat]:
		mejoras_list.add_child(_make_mejora_card(m, gold, color))

func _make_mejora_card(m: Dictionary, gold: int, color: Color) -> PanelContainer:
	var coste = _get_coste(m)
	var afford = gold >= coste

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

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	# Lado izquierdo
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl_nombre = Label.new()
	lbl_nombre.text = m.nombre
	lbl_nombre.add_theme_font_size_override("font_size", 12)
	lbl_nombre.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	lbl_nombre.clip_text = true

	var lbl_desc = Label.new()
	lbl_desc.text = m.desc
	lbl_desc.add_theme_font_size_override("font_size", 9)
	lbl_desc.add_theme_color_override("font_color", Color(0.267, 0.267, 0.267))

	var nivel_hbox = HBoxContainer.new()
	nivel_hbox.add_theme_constant_override("separation", 4)
	var lbl_nv_key = Label.new()
	lbl_nv_key.text = "Nv."
	lbl_nv_key.add_theme_font_size_override("font_size", 9)
	lbl_nv_key.add_theme_color_override("font_color", Color(0.333, 0.333, 0.333))
	var lbl_nv_val = Label.new()
	lbl_nv_val.text = str(m.nivel)
	lbl_nv_val.add_theme_font_size_override("font_size", 11)
	lbl_nv_val.add_theme_color_override("font_color", color)
	nivel_hbox.add_child(lbl_nv_key)
	nivel_hbox.add_child(lbl_nv_val)

	left.add_child(lbl_nombre)
	left.add_child(lbl_desc)
	left.add_child(nivel_hbox)

	# Lado derecho
	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(68, 0)
	right.alignment = BoxContainer.ALIGNMENT_CENTER

	var btn = Button.new()
	btn.text = "MEJORAR"
	btn.flat = false
	btn.add_theme_font_size_override("font_size", 10)
	var bs = StyleBoxFlat.new()
	bs.bg_color     = Color(color.r, color.g, color.b, 0.13) if afford else Color(0.067, 0.067, 0.067)
	bs.border_color = color if afford else Color(0.102, 0.102, 0.18)
	bs.set_border_width_all(1)
	bs.corner_radius_top_left = 8
	bs.corner_radius_top_right = 8
	bs.corner_radius_bottom_left = 8
	bs.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", bs)
	btn.add_theme_color_override("font_color", color if afford else Color(0.2, 0.2, 0.2))
	btn.disabled = not afford
	if afford:
		btn.pressed.connect(func(): _comprar_mejora(m))

	var coste_hbox = HBoxContainer.new()
	coste_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var sym = Label.new()
	sym.text = "©"
	sym.add_theme_font_size_override("font_size", 9)
	sym.add_theme_color_override("font_color", COLOR_GOLD if afford else Color(0.165, 0.165, 0.165))
	var lbl_coste = Label.new()
	lbl_coste.text = _fmt(coste)
	lbl_coste.add_theme_font_size_override("font_size", 9)
	lbl_coste.add_theme_color_override("font_color", Color(0.667, 0.667, 0.667) if afford else Color(0.165, 0.165, 0.165))
	coste_hbox.add_child(sym)
	coste_hbox.add_child(lbl_coste)

	right.add_child(btn)
	right.add_child(coste_hbox)

	hbox.add_child(left)
	hbox.add_child(right)
	margin.add_child(hbox)
	card.add_child(margin)
	return card

func _comprar_mejora(m: Dictionary) -> void:
	var coste = _get_coste(m)
	if not SaveSystem:
		return
	if SaveSystem.get_gold() < coste:
		return
	SaveSystem.spend_gold(coste)
	m.nivel += 1
	SaveSystem.set_mejora_nexus(m.id, m.nivel)
	_render_mejoras()

func _apply_tab_styles() -> void:
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color     = Color(0.043, 0.043, 0.094)
	bar_style.border_color = Color(0.078, 0.078, 0.157)
	bar_style.border_width_top = 1
	# No se puede aplicar directamente a HBoxContainer, se hace via theme

func _fmt(n: int) -> String:
	if n >= 1_000_000: return "%.1fM" % (n / 1_000_000.0)
	elif n >= 1000:    return "%.1fk" % (n / 1000.0)
	return str(n)
