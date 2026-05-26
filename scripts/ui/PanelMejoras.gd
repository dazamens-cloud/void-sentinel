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
var btn_cerrar_modal: Button         = null

var mejora_manager    = null
var categoria_actual: String = "ataque"
var expandido:        bool   = true
var multiplicador:    int    = 1

const ALTURA_BARRA: float = 50.0
const ALTURA_PANEL: float = 500.0

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

	if modal_overlay:
		modal_overlay.visible = false

	await get_tree().process_frame
	_reposicionar()
	_inicializar_cards()
	_conectar_senales()
	cambiar_categoria("ataque")
	_expandir(true)
	_actualizar_botones_mult()

func _reposicionar() -> void:
	var vp := get_viewport_rect().size
	offset_left   = 0.0
	offset_right  = vp.x
	if expandido:
		offset_top    = vp.y - ALTURA_PANEL - ALTURA_BARRA
		offset_bottom = vp.y
	else:
		offset_top    = vp.y - ALTURA_BARRA
		offset_bottom = vp.y
	print("📐 PanelMejoras reposicionado: vp=", vp, " top=", offset_top, " expandido=", expandido)

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

	modal_titulo.text = data["nombre"]
	modal_desc.text   = data.get("descripcion", "Sin descripcion.")
	modal_nivel.text  = "Nv %d / %d" % [nivel, max_nivel]

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

func _expandir(estado: bool) -> void:
	expandido = estado
	contenido.visible = estado
	btn_toggle.text = "▲" if estado else "▼"
	_reposicionar()

# ═══════════════════════════════════════════════════
# PESTAÑAS
# ═══════════════════════════════════════════════════
func cambiar_categoria(categoria: String) -> void:
	categoria_actual = categoria
	_actualizar_visual_pestanas()
	ataque_container.visible       = (categoria == "ataque")
	defensa_container.visible      = (categoria == "defensa")
	bonificacion_container.visible = (categoria == "bonificacion")
	commander_container.visible    = (categoria == "commander")

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

func _refrescar_container_activo() -> void:
	var container_activo: GridContainer
	match categoria_actual:
		"ataque":       container_activo = ataque_container
		"defensa":      container_activo = defensa_container
		"bonificacion": container_activo = bonificacion_container
		"commander":    container_activo = commander_container
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
