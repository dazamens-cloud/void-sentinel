extends Control

# ============================================================================
# TIENDA SCREEN
# ============================================================================

@onready var packs_list = $VBox/PacksList
@onready var otros_list = $VBox/OtrosList

const PACKS = [
	{ "cantidad": 50,   "precio": "0,99€",  "bonus": "",          "highlight": false },
	{ "cantidad": 150,  "precio": "2,49€",  "bonus": "+20 extra", "highlight": false },
	{ "cantidad": 400,  "precio": "5,99€",  "bonus": "+80 extra", "highlight": true  },
	{ "cantidad": 1000, "precio": "13,99€", "bonus": "+250 extra","highlight": false },
]

const OTROS = [
	{ "nombre": "Sin anuncios",  "desc": "Elimina los anuncios para siempre",         "precio": "2,99€" },
	{ "nombre": "Starter Pack",  "desc": "200 Platinum + boost x2 primera semana",    "precio": "1,99€" },
]

const COLOR_ORANGE = Color(1.0, 0.42, 0.0)
const COLOR_PLAT   = Color(0.494, 0.784, 0.89)

func _ready():
	_build_packs()
	_build_otros()

func on_enter() -> void:
	pass

func _build_packs() -> void:
	for child in packs_list.get_children():
		child.queue_free()
	for pack in PACKS:
		packs_list.add_child(_make_pack_card(pack))

func _build_otros() -> void:
	for child in otros_list.get_children():
		child.queue_free()
	for item in OTROS:
		otros_list.add_child(_make_otro_card(item))

func _make_pack_card(pack: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var s = StyleBoxFlat.new()
	s.bg_color     = Color(0.071, 0.051, 0.0) if pack.highlight else Color(0.051, 0.051, 0.118)
	s.border_color = COLOR_ORANGE if pack.highlight else Color(0.102, 0.102, 0.18)
	s.border_width_top    = 2 if pack.highlight else 1
	s.border_width_bottom = 2 if pack.highlight else 1
	s.border_width_left   = 2 if pack.highlight else 1
	s.border_width_right  = 2 if pack.highlight else 1
	s.corner_radius_top_left = 11
	s.corner_radius_top_right = 11
	s.corner_radius_bottom_left = 11
	s.corner_radius_bottom_right = 11
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 11
	s.content_margin_bottom = 11
	card.add_theme_stylebox_override("panel", s)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	# Icono
	var icon_box = PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(36, 36)
	var is = StyleBoxFlat.new()
	is.bg_color     = Color(0.165, 0.082, 0.0) if pack.highlight else Color(0.067, 0.067, 0.067)
	is.border_color = COLOR_ORANGE if pack.highlight else Color(0.102, 0.102, 0.18)
	is.set_border_width_all(1)
	is.corner_radius_top_left = 8
	is.corner_radius_top_right = 8
	is.corner_radius_bottom_left = 8
	is.corner_radius_bottom_right = 8
	icon_box.add_theme_stylebox_override("panel", is)
	var icon_lbl = Label.new()
	icon_lbl.text = "◆"
	icon_lbl.add_theme_color_override("font_color", COLOR_PLAT)
	icon_lbl.add_theme_font_size_override("font_size", 16)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_box.add_child(icon_lbl)

	# Texto
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_hbox = HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 5)
	var lbl_cant = Label.new()
	lbl_cant.text = "%d Platinum" % pack.cantidad
	lbl_cant.add_theme_font_size_override("font_size", 13)
	lbl_cant.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	name_hbox.add_child(lbl_cant)
	if pack.bonus != "":
		var lbl_bonus = Label.new()
		lbl_bonus.text = pack.bonus
		lbl_bonus.add_theme_font_size_override("font_size", 10)
		lbl_bonus.add_theme_color_override("font_color", COLOR_ORANGE)
		name_hbox.add_child(lbl_bonus)
	var lbl_sub = Label.new()
	lbl_sub.text = "MEJOR VALOR" if pack.highlight else " "
	lbl_sub.add_theme_font_size_override("font_size", 9)
	lbl_sub.add_theme_color_override("font_color", COLOR_ORANGE if pack.highlight else Color(0.2, 0.2, 0.2))
	text_vbox.add_child(name_hbox)
	text_vbox.add_child(lbl_sub)

	# Botón precio
	var btn = Button.new()
	btn.text = pack.precio
	btn.flat = false
	btn.custom_minimum_size = Vector2(60, 0)
	var bs = StyleBoxFlat.new()
	bs.bg_color     = COLOR_ORANGE if pack.highlight else Color(0.067, 0.067, 0.067)
	bs.border_color = COLOR_ORANGE if pack.highlight else Color(0.102, 0.102, 0.18)
	bs.set_border_width_all(1)
	bs.corner_radius_top_left = 8
	bs.corner_radius_top_right = 8
	bs.corner_radius_bottom_left = 8
	bs.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", bs)
	btn.add_theme_color_override("font_color", Color.WHITE if pack.highlight else Color(0.267, 0.267, 0.267))
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(func(): _on_pack_pressed(pack))

	hbox.add_child(icon_box)
	hbox.add_child(text_vbox)
	hbox.add_child(btn)
	card.add_child(hbox)
	return card

func _make_otro_card(item: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var s = StyleBoxFlat.new()
	s.bg_color     = Color(0.051, 0.051, 0.118)
	s.border_color = Color(0.102, 0.102, 0.18)
	s.set_border_width_all(1)
	s.corner_radius_top_left = 11
	s.corner_radius_top_right = 11
	s.corner_radius_bottom_left = 11
	s.corner_radius_bottom_right = 11
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 11
	s.content_margin_bottom = 11
	card.add_theme_stylebox_override("panel", s)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var icon_box = PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(36, 36)
	var is = StyleBoxFlat.new()
	is.bg_color     = Color(0.067, 0.067, 0.067)
	is.border_color = Color(0.102, 0.102, 0.18)
	is.set_border_width_all(1)
	is.corner_radius_top_left = 8
	is.corner_radius_top_right = 8
	is.corner_radius_bottom_left = 8
	is.corner_radius_bottom_right = 8
	icon_box.add_theme_stylebox_override("panel", is)
	var icon_lbl = Label.new()
	icon_lbl.text = "★"
	icon_lbl.add_theme_color_override("font_color", Color(0.333, 0.333, 0.333))
	icon_lbl.add_theme_font_size_override("font_size", 16)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_box.add_child(icon_lbl)

	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl_n = Label.new()
	lbl_n.text = item.nombre
	lbl_n.add_theme_font_size_override("font_size", 13)
	lbl_n.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	var lbl_d = Label.new()
	lbl_d.text = item.desc
	lbl_d.add_theme_font_size_override("font_size", 9)
	lbl_d.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	text_vbox.add_child(lbl_n)
	text_vbox.add_child(lbl_d)

	var btn = Button.new()
	btn.text = item.precio
	btn.flat = false
	btn.custom_minimum_size = Vector2(60, 0)
	var bs = StyleBoxFlat.new()
	bs.bg_color     = Color(0.067, 0.067, 0.067)
	bs.border_color = Color(0.102, 0.102, 0.18)
	bs.set_border_width_all(1)
	bs.corner_radius_top_left = 8
	bs.corner_radius_top_right = 8
	bs.corner_radius_bottom_left = 8
	bs.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", bs)
	btn.add_theme_color_override("font_color", Color(0.267, 0.267, 0.267))
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(func(): _on_otro_pressed(item))

	hbox.add_child(icon_box)
	hbox.add_child(text_vbox)
	hbox.add_child(btn)
	card.add_child(hbox)
	return card

func _on_pack_pressed(pack: Dictionary) -> void:
	print("Comprar pack: %d Platinum por %s" % [pack.cantidad, pack.precio])
	# Aquí irá la integración con la tienda de Google Play

func _on_otro_pressed(item: Dictionary) -> void:
	print("Comprar: %s por %s" % [item.nombre, item.precio])
	# Aquí irá la integración con la tienda de Google Play
