class_name CabeceraMenu
extends RefCounted
# ============================================================
# CABECERA DE LAS PANTALLAS DEL MENU — Void Sentinel
#
# Las seis pantallas (Nexo, Forja, Perfil, Tienda, Lab, Misiones) repetian la
# misma cabecera copiada: una linea pequena arriba, el titulo, y a la derecha una
# pildora con el recurso de esa pantalla. Y las seis la repetian con los tamanos
# del mockup de 390 px (10 y 26 px), que en el viewport de 720 se quedan
# diminutos. Aqui vive una sola vez, ya con las constantes de MenuTheme.
#
# Uso:
#   root.add_child(CabeceraMenu.crear("HABILIDADES MANUALES", "FORJA",
#       MenuTheme.FRAG, _make_frag_pill()))
# ============================================================


static func crear(linea: String, titulo: String, color: Color,
		extra: Control = null) -> Control:
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_right", 20)
	margen.add_theme_constant_override("margin_top", 16)
	margen.add_theme_constant_override("margin_bottom", 10)

	var fila := HBoxContainer.new()
	margen.add_child(fila)

	var bloque := VBoxContainer.new()
	bloque.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bloque.add_theme_constant_override("separation", 2)
	bloque.add_child(etiqueta(linea, MenuTheme.FS_TINY, MenuTheme.TEXT_MUTED))
	bloque.add_child(etiqueta(titulo, MenuTheme.FS_TITLE, color))
	fila.add_child(bloque)

	if extra:
		extra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(extra)
	return margen


# Etiqueta con la fuente del HUD (Orbitron). Las cifras NO deberian usarla: su
# cero es un rectangulo con barra y parece un glifo roto.
static func etiqueta(texto: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	var f: Font = MenuTheme.get_font_hud()
	if f:
		l.add_theme_font_override("font", f)
	return l


# Pildora de recurso de la esquina: rotulo pequeno arriba e icono + cifra debajo.
# `forma` es una IconoVec.Forma; devuelve tambien la etiqueta de la cifra para
# que la pantalla pueda ir actualizandola.
static func pildora(rotulo: String, forma: int, color: Color) -> Array:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_END
	v.add_theme_constant_override("separation", 2)

	var rot := etiqueta(rotulo, MenuTheme.FS_TINY, MenuTheme.TEXT_MUTED)
	rot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(rot)

	var caja := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(color, 0.08)
	estilo.border_color = Color(color, 0.30)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(16)
	estilo.content_margin_left = 14
	estilo.content_margin_right = 14
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	caja.add_theme_stylebox_override("panel", estilo)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var centro := CenterContainer.new()
	centro.add_child(IconoVec.crear(forma, 24, color))
	h.add_child(centro)

	# La cifra va en la fuente de cuerpo a proposito (cero de Orbitron).
	var cifra := Label.new()
	cifra.add_theme_font_size_override("font_size", MenuTheme.FS_BODY + 2)
	cifra.add_theme_color_override("font_color", color)
	var fb: Font = MenuTheme.get_font_body()
	if fb:
		cifra.add_theme_font_override("font", fb)
	h.add_child(cifra)
	caja.add_child(h)
	v.add_child(caja)
	return [v, cifra]
