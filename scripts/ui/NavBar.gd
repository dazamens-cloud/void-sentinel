class_name NavBarUI
extends Control
# ============================================================
# NavBar.gd
# Barra de navegacion inferior.
# Orden: Nexo - Forja - [HOME central] - Perfil - Tienda
#
# Emite la senal "screen_requested(nombre)" cuando se pulsa un
# boton. MainMenu la escucha y cambia de pantalla.
#
# Es un Control puro construido por codigo (sin .tscn propio).
# MainMenu lo instancia con NavBar.new().
# ============================================================

signal screen_requested(screen_name: String)

# Guardamos referencias a cada boton para poder marcar el activo.
var _buttons: Dictionary = {}
var _active: String = "home"

# Definicion de los items: [clave, simbolo, etiqueta, es_central]
const ITEMS := [
	["nexo",   MenuTheme.SYM_ECOS,   "NEXO",   false],
	["forja",  MenuTheme.SYM_FRAG,   "FORJA",  false],
	["home",   MenuTheme.SYM_HOME,   "INICIO", true],
	["perfil", MenuTheme.SYM_PERFIL, "PERFIL", false],
	["tienda", MenuTheme.SYM_TIENDA, "TIENDA", false],
]


func _ready() -> void:
	custom_minimum_size = Vector2(0, 86)
	_build()


func _build() -> void:
	# Fondo de la barra.
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.016, 0.035, 0.063, 0.97)
	bg_style.border_color = MenuTheme.BORDER_GLOW
	bg_style.border_width_top = 1
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)

	# Contenedor horizontal de los 5 items.
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	# Margen interior: empuja un poco hacia arriba (deja hueco a la barra
	# de gestos del movil abajo).
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_child(row)
	add_child(margin)

	# Crear cada boton.
	for item in ITEMS:
		var key: String = item[0]
		var sym: String = item[1]
		var lbl: String = item[2]
		var central: bool = item[3]
		var btn := _make_nav_button(key, sym, lbl, central)
		row.add_child(btn)
		_buttons[key] = btn

	set_active("home")


# Crea un boton de navegacion (icono arriba, etiqueta abajo).
func _make_nav_button(key: String, sym: String, lbl: String, central: bool) -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 58)

	# El boton central (Home) lleva un fondo destacado.
	if central:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(MenuTheme.CYAN.r, MenuTheme.CYAN.g, MenuTheme.CYAN.b, 0.08)
		style.border_color = Color(MenuTheme.CYAN.r, MenuTheme.CYAN.g, MenuTheme.CYAN.b, 0.35)
		style.set_border_width_all(1)
		style.set_corner_radius_all(12)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

	# Contenido vertical: icono + etiqueta.
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var icon := Label.new()
	icon.text = sym
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 18)
	icon.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hud_font := MenuTheme.get_font_hud()
	if hud_font:
		icon.add_theme_font_override("font", hud_font)

	var label := Label.new()
	label.text = lbl
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", MenuTheme.TEXT_MUTED)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if hud_font:
		label.add_theme_font_override("font", hud_font)

	vbox.add_child(icon)
	vbox.add_child(label)
	btn.add_child(vbox)

	# Guardamos refs internas para recolorear al activar.
	btn.set_meta("icon", icon)
	btn.set_meta("label", label)
	btn.set_meta("central", central)

	# Al pulsar, emitimos la senal con la clave de la pantalla.
	btn.pressed.connect(func(): screen_requested.emit(key))

	return btn


# Marca visualmente el boton de la pantalla activa.
func set_active(screen_name: String) -> void:
	_active = screen_name
	for key in _buttons.keys():
		var btn: Button = _buttons[key]
		var icon: Label = btn.get_meta("icon")
		var label: Label = btn.get_meta("label")
		var is_active: bool = (key == screen_name)
		var col: Color = MenuTheme.CYAN if is_active else MenuTheme.TEXT_MUTED
		icon.add_theme_color_override("font_color", col)
		label.add_theme_color_override("font_color", col)
