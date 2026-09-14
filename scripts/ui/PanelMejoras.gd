extends Control
# ═══════════════════════════════════════════════════
# PANEL MEJORAS — Void Sentinel
# Altura fija con scroll interior; estilo del menú (MenuTheme) aplicado por
# código en _estilizar() para no editar el .tscn a mano.
# ═══════════════════════════════════════════════════

@onready var btn_toggle:   Button = $BarraTitulo/BtnToggle
@onready var btn_mult_x1:  Button = $BarraTitulo/MultContainer/BtnX1
@onready var btn_mult_x5:  Button = $BarraTitulo/MultContainer/BtnX5
@onready var btn_mult_x10: Button = $BarraTitulo/MultContainer/BtnX10
@onready var btn_mult_max: Button = $BarraTitulo/MultContainer/BtnMax

@onready var btn_ataque:       Button  = $Contenido/Tabs/BtnAtaque
@onready var btn_defensa:      Button  = $Contenido/Tabs/BtnDefensa
@onready var btn_bonificacion: Button  = $Contenido/Tabs/BtnBonificacion
@onready var btn_commander:    Button  = $Contenido/Tabs/BtnCommander
@onready var contenido:        Control = $Contenido
@onready var scroll:           ScrollContainer = $Contenido/ScrollContainer

@onready var ataque_container:       GridContainer = $Contenido/ScrollContainer/MejorasContainer/AtaqueContainer
@onready var defensa_container:      GridContainer = $Contenido/ScrollContainer/MejorasContainer/DefensaContainer
@onready var bonificacion_container: GridContainer = $Contenido/ScrollContainer/MejorasContainer/BonificacionContainer
@onready var commander_container:    GridContainer = $Contenido/ScrollContainer/MejorasContainer/CommanderContainer

var modal_overlay:    ColorRect      = null
var modal_panel:      PanelContainer = null
var modal_titulo:     Label          = null
var modal_desc:       Label          = null
var modal_nivel:      Label          = null
var modal_stats:      Label          = null  # creada por código (valor y coste)
var btn_cerrar_modal: Button         = null
var modal_mejora_id:  String         = ""

var mejora_manager    = null
var categoria_actual: String = "ataque"
var expandido:        bool   = true
var multiplicador:    int    = 1
var _tween_panel: Tween = null
var _tween_modal: Tween = null

const ALTURA_BARRA: float = 50.0
# Altura FIJA del panel (sin la barra). Antes se ajustaba al contenido de cada
# pestaña y la fila de pestañas cambiaba de sitio al pasar de Ataque (6 mejoras)
# a Bonus (9). Lo que no cabe se desplaza dentro del ScrollContainer; la altura
# deja asomar parte de la cuarta fila para que se note que hay más.
const ALTURA_PANEL: float = 500.0
var altura_panel: float = ALTURA_PANEL
# Franja de las pestañas; el scroll empieza debajo.
const ALTURA_TABS: float = 52.0
# Separación de las rejillas con los bordes de la pantalla y entre cards.
const MARGEN_LATERAL: float = 12.0
const SEPARACION_CARDS: int = 10
# Margen inferior para que la barra (sobre todo colapsada) no quede pegada al
# borde y la tape la barra de gestos del móvil.
const MARGEN_INFERIOR: float = 48.0

const COLORES_CAT := {
	"ataque":       MenuTheme.CAT_ATAQUE,
	"defensa":      MenuTheme.CAT_DEFENSA,
	"bonificacion": MenuTheme.CAT_BONIFICACION,
	"commander":    MenuTheme.CAT_COMMANDER,
}

# ═══════════════════════════════════════════════════
func _ready() -> void:
	mejora_manager = get_node("/root/MejoraManager")
	if not mejora_manager:
		push_error("PanelMejoras: MejoraManager no encontrado")
		return

	modal_overlay    = get_node_or_null("ModalOverlay")
	if modal_overlay:
		modal_panel      = modal_overlay.get_node_or_null("ModalPanel")
	if modal_panel:
		modal_titulo     = modal_panel.get_node_or_null("VBox/FilaCerrar/Titulo")
		modal_desc       = modal_panel.get_node_or_null("VBox/Descripcion")
		modal_nivel      = modal_panel.get_node_or_null("VBox/FilaNivel/LblNivel")
		btn_cerrar_modal = modal_panel.get_node_or_null("VBox/FilaCerrar/BtnCerrar")
		_crear_label_stats_modal()

	if modal_overlay:
		modal_overlay.visible = false

	await get_tree().process_frame
	_estilizar()
	_reposicionar()
	_inicializar_cards()
	_conectar_senales()
	cambiar_categoria("ataque")
	_expandir(false, false)
	_actualizar_botones_mult()

# Línea de "Valor: X → Y · Siguiente nivel: Z energía" del modal. Se crea por
# código para no tocar la escena (.tscn solo se edita desde el editor).
func _crear_label_stats_modal() -> void:
	var vbox := modal_panel.get_node_or_null("VBox")
	if not vbox:
		return
	modal_stats = Label.new()
	_fuente(modal_stats, MenuTheme.FS_SMALL, MenuTheme.TEXT_PRIMARY, false)
	modal_stats.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(modal_stats)
	# Colocarla entre la descripción y la fila de nivel.
	var desc_idx: int = modal_desc.get_index() if modal_desc else vbox.get_child_count() - 1
	vbox.move_child(modal_stats, desc_idx + 1)

# ═══════════════════════════════════════════════════
# ESTILO
# ═══════════════════════════════════════════════════
func _estilizar() -> void:
	var fondo := get_node_or_null("Background") as ColorRect
	if fondo:
		fondo.color = Color(MenuTheme.BG_DEEP, 0.96)
		# Filo superior: separa el panel del campo de batalla.
		var filo := ColorRect.new()
		filo.color = MenuTheme.BORDER_GLOW
		filo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fondo.add_child(filo)
		filo.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		filo.offset_bottom = 1.0

	# Barra de título: ancho completo con margen, en vez de 720 px fijos.
	var barra := $BarraTitulo as HBoxContainer
	barra.anchor_right  = 1.0
	barra.offset_left   = MARGEN_LATERAL
	barra.offset_right  = -MARGEN_LATERAL
	barra.add_theme_constant_override("separation", 6)
	var titulo := $BarraTitulo/Titulo as Label
	titulo.text = "MEJORAS"
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fuente(titulo, MenuTheme.FS_SMALL, MenuTheme.CYAN, true)
	($BarraTitulo/MultContainer as HBoxContainer).add_theme_constant_override("separation", 6)
	for btn in [btn_mult_x1, btn_mult_x5, btn_mult_x10, btn_mult_max, btn_toggle]:
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(54, 40)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_fuente(btn, MenuTheme.FS_SMALL, MenuTheme.TEXT_MUTED, false)
	_aplicar_pildora(btn_toggle, MenuTheme.CYAN, false)
	btn_toggle.add_theme_color_override("font_color", MenuTheme.CYAN)

	# Pestañas
	var tabs := $Contenido/Tabs as HBoxContainer
	tabs.offset_left   = MARGEN_LATERAL
	tabs.offset_right  = -MARGEN_LATERAL
	tabs.offset_top    = 4.0
	tabs.offset_bottom = ALTURA_TABS - 6.0
	tabs.add_theme_constant_override("separation", 6)
	for btn in [btn_ataque, btn_defensa, btn_bonificacion, btn_commander]:
		btn.focus_mode = Control.FOCUS_NONE
		_fuente(btn, MenuTheme.FS_TINY, MenuTheme.TEXT_MUTED, true)

	# Rejillas: margen lateral y aire entre cards. Sin barra de scroll visible
	# (se desplaza con el dedo); la fila cortada abajo ya indica que hay más.
	scroll.offset_left   = MARGEN_LATERAL
	scroll.offset_right  = -MARGEN_LATERAL
	scroll.offset_top    = ALTURA_TABS
	scroll.offset_bottom = -6.0
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.scroll_deadzone = 12
	for grid in [ataque_container, defensa_container, bonificacion_container, commander_container]:
		grid.add_theme_constant_override("h_separation", SEPARACION_CARDS)
		grid.add_theme_constant_override("v_separation", SEPARACION_CARDS)

	# Modal: a escala del viewport (tenía fuentes de 13-16 px).
	if modal_panel:
		var ancho_modal := Vector2(520, 0)
		var vbox := modal_panel.get_node_or_null("VBox") as VBoxContainer
		if vbox:
			vbox.custom_minimum_size = ancho_modal
			vbox.add_theme_constant_override("separation", 12)
		if modal_titulo:
			_fuente(modal_titulo, MenuTheme.FS_BODY, MenuTheme.TEXT_PRIMARY, true)
		if modal_desc:
			modal_desc.custom_minimum_size = ancho_modal
			_fuente(modal_desc, MenuTheme.FS_SMALL, Color(MenuTheme.TEXT_PRIMARY, 0.7), false)
		var lbl_nivel_txt := modal_panel.get_node_or_null("VBox/FilaNivel/LblNivelLabel") as Label
		if lbl_nivel_txt:
			_fuente(lbl_nivel_txt, MenuTheme.FS_SMALL, MenuTheme.TEXT_MUTED, false)
		if modal_nivel:
			_fuente(modal_nivel, MenuTheme.FS_SMALL, MenuTheme.TEXT_PRIMARY, false)
		if btn_cerrar_modal:
			btn_cerrar_modal.text = "✕"
			btn_cerrar_modal.focus_mode = Control.FOCUS_NONE
			btn_cerrar_modal.custom_minimum_size = Vector2(48, 48)
			_fuente(btn_cerrar_modal, MenuTheme.FS_BODY, MenuTheme.TEXT_PRIMARY, false)
			_aplicar_pildora(btn_cerrar_modal, MenuTheme.TEXT_MUTED, false)

func _fuente(ctrl: Control, tam: int, color: Color, fuente_hud: bool) -> void:
	ctrl.add_theme_font_size_override("font_size", tam)
	ctrl.add_theme_color_override("font_color", color)
	var f: Font = MenuTheme.get_font_hud() if fuente_hud else MenuTheme.get_font_body()
	if f:
		ctrl.add_theme_font_override("font", f)

# Botón pequeño con borde redondeado; relleno del color si está activo.
func _aplicar_pildora(btn: Button, color: Color, activo: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, 0.22 if activo else 0.0)
	sb.border_color = Color(color, 0.7 if activo else 0.2)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	sb.content_margin_left  = 8
	sb.content_margin_right = 8
	for estado in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(estado, sb)
	btn.modulate = Color.WHITE

# Pestaña: la activa lleva un velo y un subrayado del color de su categoría.
func _estilo_pestana(color: Color, activa: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, 0.14 if activa else 0.0)
	sb.border_color = Color(color, 0.9 if activa else 0.0)
	sb.border_width_bottom = 3 if activa else 0
	sb.corner_radius_top_left  = 10
	sb.corner_radius_top_right = 10
	sb.set_content_margin_all(4)
	return sb

func _reposicionar(animar: bool = false) -> void:
	var vp := get_viewport_rect().size
	# Reserva, además del margen fijo, la barra de navegación del sistema (móvil).
	var safe_bottom: float = SafeArea.margenes(vp)["bottom"]
	var base := vp.y - MARGEN_INFERIOR - safe_bottom
	offset_left   = 0.0
	offset_right  = vp.x
	offset_bottom = base
	var top_destino: float = base - ALTURA_BARRA - (altura_panel if expandido else 0.0)
	if _tween_panel:
		_tween_panel.kill()
	if animar:
		_tween_panel = create_tween()
		_tween_panel.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_tween_panel.tween_property(self, "offset_top", top_destino, 0.2)
	else:
		offset_top = top_destino

func _container_activo() -> GridContainer:
	match categoria_actual:
		"ataque":       return ataque_container
		"defensa":      return defensa_container
		"bonificacion": return bonificacion_container
		"commander":    return commander_container
	return ataque_container

func _inicializar_cards() -> void:
	for container in [ataque_container, defensa_container, bonificacion_container, commander_container]:
		var cat   := _categoria_de_container(container)
		var color: Color = COLORES_CAT.get(cat, COLORES_CAT["ataque"])
		for card in container.get_children():
			if card.has_method("inicializar"):
				card.inicializar(mejora_manager, color)
				if not card.info_solicitada.is_connected(_mostrar_modal):
					card.info_solicitada.connect(_mostrar_modal)

func _categoria_de_container(container: GridContainer) -> String:
	match container.name:
		"AtaqueContainer":       return "ataque"
		"DefensaContainer":      return "defensa"
		"BonificacionContainer": return "bonificacion"
		"CommanderContainer":    return "commander"
	return "ataque"

func _conectar_senales() -> void:
	btn_toggle.pressed.connect(_toggle_panel)
	btn_ataque.pressed.connect(func(): cambiar_categoria("ataque"))
	btn_defensa.pressed.connect(func(): cambiar_categoria("defensa"))
	btn_bonificacion.pressed.connect(func(): cambiar_categoria("bonificacion"))
	btn_commander.pressed.connect(func(): cambiar_categoria("commander"))
	btn_mult_x1.pressed.connect(func(): _set_multiplicador(1))
	btn_mult_x5.pressed.connect(func(): _set_multiplicador(5))
	btn_mult_x10.pressed.connect(func(): _set_multiplicador(10))
	btn_mult_max.pressed.connect(func(): _set_multiplicador(-1))
	if btn_cerrar_modal:
		btn_cerrar_modal.pressed.connect(_cerrar_modal)
	if modal_overlay:
		modal_overlay.gui_input.connect(_on_overlay_input)
	mejora_manager.mejoras_actualizadas.connect(_actualizar_ui)
	if Economia.has_signal("energia_cambiada"):
		Economia.energia_cambiada.connect(_on_energia_cambiada)


func _exit_tree() -> void:
	# ✅ Desconectar signals para prevenir memory leak
	if mejora_manager and mejora_manager.mejoras_actualizadas.is_connected(_actualizar_ui):
		mejora_manager.mejoras_actualizadas.disconnect(_actualizar_ui)
	if Economia.energia_cambiada.is_connected(_on_energia_cambiada):
		Economia.energia_cambiada.disconnect(_on_energia_cambiada)

# ═══════════════════════════════════════════════════
# MODAL
# ═══════════════════════════════════════════════════
func _mostrar_modal(mejora_id: String, color: Color) -> void:
	if not modal_overlay or not modal_titulo or not modal_desc or not modal_nivel:
		push_error("PanelMejoras: nodos del modal no disponibles")
		return
	if not mejora_manager.mejoras.has(mejora_id):
		return

	var data       = mejora_manager.mejoras[mejora_id]
	var nivel: int     = mejora_manager.get_nivel(mejora_id)
	var max_nivel: int = mejora_manager.get_max_nivel(mejora_id)

	modal_mejora_id   = mejora_id
	modal_titulo.text = data["nombre"].to_upper()
	modal_desc.text   = data.get("descripcion", "Sin descripcion.")
	modal_nivel.text  = "Nv %d / %d" % [nivel, max_nivel]
	_actualizar_stats_modal()

	# Tarjeta oscura con el borde y el título del color de la categoría.
	if modal_panel:
		var sb := StyleBoxFlat.new()
		sb.bg_color     = Color(MenuTheme.BG_CARD, 0.98)
		sb.border_color = Color(color, 0.6)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(18)
		sb.content_margin_left   = 24
		sb.content_margin_right  = 24
		sb.content_margin_top    = 20
		sb.content_margin_bottom = 22
		modal_panel.add_theme_stylebox_override("panel", sb)

	modal_titulo.add_theme_color_override("font_color", color)

	# El ModalOverlay cubre todo el PanelMejoras y el panel va anclado a su centro.
	modal_overlay.visible = true
	_animar_apertura_modal()

# Valor actual → siguiente nivel y su coste, debajo de la descripción.
func _actualizar_stats_modal() -> void:
	if not modal_stats or modal_mejora_id.is_empty():
		return
	var nivel: int     = mejora_manager.get_nivel(modal_mejora_id)
	var max_nivel: int = mejora_manager.get_max_nivel(modal_mejora_id)
	if modal_nivel:
		modal_nivel.text = "Nv %d / %d" % [nivel, max_nivel]
	var actual: String = mejora_manager.formatear_valor(modal_mejora_id, nivel)
	if nivel >= max_nivel:
		modal_stats.text = "Valor: %s (MÁX)" % actual
	else:
		var siguiente: String = mejora_manager.formatear_valor(modal_mejora_id, nivel + 1)
		var coste: int = mejora_manager.get_coste_acumulado(modal_mejora_id, 1)
		modal_stats.text = "Valor: %s → %s\nSiguiente nivel: %s energía" % [
			actual, siguiente, Formato.abreviar(coste),
		]

func _animar_apertura_modal() -> void:
	if not modal_panel:
		return
	modal_panel.pivot_offset = modal_panel.size / 2.0
	if _tween_modal:
		_tween_modal.kill()
	modal_panel.scale = Vector2(0.9, 0.9)
	modal_overlay.modulate.a = 0.0
	_tween_modal = create_tween().set_parallel(true)
	_tween_modal.tween_property(modal_overlay, "modulate:a", 1.0, 0.12)
	_tween_modal.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tween_modal.tween_property(modal_panel, "scale", Vector2.ONE, 0.18)

func _cerrar_modal() -> void:
	# Cortar la animación de apertura si seguía en vuelo y dejar el overlay con su
	# alpha íntegro; si no, la próxima apertura podía heredar un alpha a medias.
	if _tween_modal:
		_tween_modal.kill()
		_tween_modal = null
	if modal_overlay:
		modal_overlay.visible = false
		modal_overlay.modulate.a = 1.0
	modal_mejora_id = ""

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if modal_panel:
				var rect := modal_panel.get_global_rect()
				if not rect.has_point(event.global_position):
					_cerrar_modal()

# ═══════════════════════════════════════════════════
# TOGGLE
# ═══════════════════════════════════════════════════
func _toggle_panel() -> void:
	_expandir(not expandido)

func _expandir(estado: bool, animar: bool = true) -> void:
	expandido = estado
	contenido.visible = estado
	btn_toggle.text = "▲" if estado else "▼"
	if not estado:
		# El ModalOverlay cubre el rect del panel: si se queda abierto al colapsar,
		# encoge con él hasta la barra de título y, como ColorRect con mouse_filter
		# STOP, se traga los clics del botón de toggle — el panel ya no se puede
		# volver a abrir. Al colapsar se cierra siempre.
		_cerrar_modal()
	_reposicionar(animar)

# ═══════════════════════════════════════════════════
# PESTAÑAS
# ═══════════════════════════════════════════════════
func cambiar_categoria(categoria: String) -> void:
	var anterior := categoria_actual
	categoria_actual = categoria
	_actualizar_visual_pestanas()
	ataque_container.visible       = (categoria == "ataque")
	defensa_container.visible      = (categoria == "defensa")
	bonificacion_container.visible = (categoria == "bonificacion")
	commander_container.visible    = (categoria == "commander")
	# Fundido suave del grid entrante al cambiar de pestaña.
	if anterior != categoria:
		var container := _container_activo()
		container.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(container, "modulate:a", 1.0, 0.15)
	# Cada pestaña empieza arriba; la altura del panel ya no cambia.
	scroll.scroll_vertical = 0
	_refrescar_container_activo()

func _actualizar_visual_pestanas() -> void:
	var tabs := {
		"ataque":       btn_ataque,
		"defensa":      btn_defensa,
		"bonificacion": btn_bonificacion,
		"commander":    btn_commander,
	}
	for cat in tabs:
		var btn: Button = tabs[cat]
		var c: Color = COLORES_CAT.get(cat, MenuTheme.CYAN)
		var activa: bool = cat == categoria_actual
		var sb := _estilo_pestana(c, activa)
		for estado in ["normal", "hover", "pressed", "focus"]:
			btn.add_theme_stylebox_override(estado, sb)
		btn.add_theme_stylebox_override("disabled", _estilo_pestana(c, false))
		var color_texto: Color = c if activa else MenuTheme.TEXT_MUTED
		for clave in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			btn.add_theme_color_override(clave, color_texto)
		btn.add_theme_color_override("font_disabled_color", Color(MenuTheme.TEXT_MUTED, 0.45))
		btn.modulate = Color.WHITE

# ═══════════════════════════════════════════════════
# MULTIPLICADOR
# ═══════════════════════════════════════════════════
func _set_multiplicador(valor: int) -> void:
	multiplicador = valor
	_actualizar_botones_mult()
	_notificar_multiplicador()

func _actualizar_botones_mult() -> void:
	var botones := {1: btn_mult_x1, 5: btn_mult_x5, 10: btn_mult_x10, -1: btn_mult_max}
	for valor in botones:
		var btn: Button = botones[valor]
		var activo: bool = valor == multiplicador
		_aplicar_pildora(btn, MenuTheme.CYAN, activo)
		var color_texto: Color = MenuTheme.CYAN if activo else MenuTheme.TEXT_MUTED
		for clave in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			btn.add_theme_color_override(clave, color_texto)

func _notificar_multiplicador() -> void:
	for container in [ataque_container, defensa_container, bonificacion_container, commander_container]:
		for card in container.get_children():
			if card.has_method("set_multiplicador"):
				card.set_multiplicador(multiplicador)

func get_multiplicador() -> int:
	return multiplicador

# ═══════════════════════════════════════════════════
# ACTUALIZAR UI
# ═══════════════════════════════════════════════════
func _on_energia_cambiada(_valor: float = 0.0) -> void:
	_refrescar_container_activo()

func _actualizar_ui() -> void:
	_refrescar_container_activo()
	# Si el modal está abierto, sus números también deben seguir la partida.
	if modal_overlay and modal_overlay.visible:
		_actualizar_stats_modal()

func _refrescar_container_activo() -> void:
	var container_activo := _container_activo()
	if container_activo:
		for card in container_activo.get_children():
			if card.has_method("refrescar"):
				card.refrescar()

func abrir() -> void:
	visible = true
	_expandir(true)
	_actualizar_ui()

func cerrar() -> void:
	_expandir(false)
