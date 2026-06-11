extends Control
# ═══════════════════════════════════════════════════
# PANEL MEJORAS — Void Sentinel
# FIX MODAL: centrado en viewport + más opaco
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
# Altura del panel (sin la barra) ajustada al contenido de la pestaña activa.
# Se recalcula en _recalcular_altura(); arranca en el máximo por seguridad.
var altura_panel:     float  = 500.0

const ALTURA_BARRA: float = 50.0
# Tope: si el grid excede esta altura, el ScrollContainer toma el relevo.
const ALTURA_PANEL_MAX: float = 500.0
# Alto de la franja de pestañas + su separación (offset_top del Scroll en la escena).
const ALTURA_TABS: float = 44.0
# Margen inferior dentro del panel para que las cards no queden pegadas al borde.
const PAD_CONTENIDO: float = 8.0
# Margen inferior para que la barra (sobre todo colapsada) no quede pegada al
# borde y la tape la barra de gestos del móvil.
const MARGEN_INFERIOR: float = 48.0

const COLOR_ACTIVO   := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_INACTIVO := Color(0.5, 0.5, 0.5, 1.0)

const COLORES_CAT := {
	"ataque":       Color(0.06, 0.35, 0.54),
	"defensa":      Color(0.04, 0.29, 0.18),
	"bonificacion": Color(0.29, 0.22, 0.00),
	"commander":    Color(0.29, 0.16, 0.00),
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
	_reposicionar()
	_inicializar_cards()
	_conectar_senales()
	cambiar_categoria("ataque")
	_expandir(false, false)
	_actualizar_botones_mult()

# Línea de "Valor: X → Y · Siguiente: Z ⚡" del modal. Se crea por código
# para no tocar la escena (.tscn solo se edita desde el editor).
func _crear_label_stats_modal() -> void:
	var vbox := modal_panel.get_node_or_null("VBox")
	if not vbox:
		return
	modal_stats = Label.new()
	modal_stats.add_theme_font_size_override("font_size", 14)
	modal_stats.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	modal_stats.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(modal_stats)
	# Colocarla entre la descripción y la fila de nivel.
	var desc_idx: int = modal_desc.get_index() if modal_desc else vbox.get_child_count() - 1
	vbox.move_child(modal_stats, desc_idx + 1)

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

# Ajusta la altura del panel al contenido de la pestaña activa (con tope).
# Se difiere un frame porque el grid recién hecho visible aún no tiene
# calculado su get_combined_minimum_size() en el mismo frame.
func _recalcular_altura(animar: bool = true) -> void:
	if not expandido:
		return
	await get_tree().process_frame
	if not expandido or not is_inside_tree():
		return
	var container := _container_activo()
	var h_grid: float = 0.0
	if container:
		h_grid = container.get_combined_minimum_size().y
	altura_panel = minf(ALTURA_TABS + h_grid + PAD_CONTENIDO, ALTURA_PANEL_MAX)
	_reposicionar(animar)

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
	modal_titulo.text = data["nombre"]
	modal_desc.text   = data.get("descripcion", "Sin descripcion.")
	modal_nivel.text  = "Nv %d / %d" % [nivel, max_nivel]
	_actualizar_stats_modal()

	# Opción C: tinte sutil con más opacidad para legibilidad
	var color_borde := Color(color.r, color.g, color.b, 0.7)
	var color_fondo := Color(color.r * 0.15 + 0.05, color.g * 0.15 + 0.05, color.b * 0.15 + 0.05, 0.97)
	var color_titulo := Color(
		minf(color.r * 2.5 + 0.5, 1.0),
		minf(color.g * 2.5 + 0.5, 1.0),
		minf(color.b * 2.5 + 0.5, 1.0),
		1.0
	)

	if modal_panel:
		var sb := StyleBoxFlat.new()
		sb.bg_color                   = color_fondo
		sb.border_color               = color_borde
		sb.border_width_left          = 2
		sb.border_width_right         = 2
		sb.border_width_top           = 2
		sb.border_width_bottom        = 2
		sb.corner_radius_top_left     = 14
		sb.corner_radius_top_right    = 14
		sb.corner_radius_bottom_left  = 14
		sb.corner_radius_bottom_right = 14
		sb.content_margin_left   = 20
		sb.content_margin_right  = 20
		sb.content_margin_top    = 16
		sb.content_margin_bottom = 16
		modal_panel.add_theme_stylebox_override("panel", sb)

	modal_titulo.add_theme_color_override("font_color", color_titulo)

	# ✅ FIX: centrar el modal en el centro del viewport global
	# El ModalOverlay cubre todo el PanelMejoras, pero el juego
	# ocupa toda la pantalla — centramos el panel dentro del overlay
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
		modal_stats.text = "Valor: %s (MAX)" % actual
	else:
		var siguiente: String = mejora_manager.formatear_valor(modal_mejora_id, nivel + 1)
		var coste: int = mejora_manager.get_coste_acumulado(modal_mejora_id, 1)
		modal_stats.text = "Valor: %s → %s\nSiguiente nivel: %s ⚡" % [
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
	if modal_overlay:
		modal_overlay.visible = false

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
	if estado:
		_recalcular_altura(animar)
	else:
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
	_recalcular_altura()

func _actualizar_visual_pestanas() -> void:
	var tabs := {
		"ataque":       btn_ataque,
		"defensa":      btn_defensa,
		"bonificacion": btn_bonificacion,
		"commander":    btn_commander,
	}
	for cat in tabs:
		var btn: Button = tabs[cat]
		if cat == categoria_actual:
			var c: Color = COLORES_CAT.get(cat, COLOR_ACTIVO)
			btn.modulate = Color(
				minf(c.r * 3.0 + 0.3, 1.0),
				minf(c.g * 3.0 + 0.3, 1.0),
				minf(c.b * 3.0 + 0.3, 1.0),
				1.0
			)
		else:
			btn.modulate = COLOR_INACTIVO

# ═══════════════════════════════════════════════════
# MULTIPLICADOR
# ═══════════════════════════════════════════════════
func _set_multiplicador(valor: int) -> void:
	multiplicador = valor
	_actualizar_botones_mult()
	_notificar_multiplicador()

func _actualizar_botones_mult() -> void:
	btn_mult_x1.modulate  = COLOR_ACTIVO  if multiplicador == 1  else COLOR_INACTIVO
	btn_mult_x5.modulate  = COLOR_ACTIVO  if multiplicador == 5  else COLOR_INACTIVO
	btn_mult_x10.modulate = COLOR_ACTIVO  if multiplicador == 10 else COLOR_INACTIVO
	btn_mult_max.modulate = COLOR_ACTIVO  if multiplicador == -1 else COLOR_INACTIVO

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
