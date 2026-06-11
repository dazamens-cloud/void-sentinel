extends PanelContainer
# ═══════════════════════════════════════════════════
# MEJORA CARD — Void Sentinel
# Lado izquierdo abre modal global; lado derecho = botón de compra.
# Mantener pulsado el botón compra en ráfaga (tras un pequeño delay).
# ═══════════════════════════════════════════════════

signal info_solicitada(mejora_id: String, color_categoria: Color)

@export var mejora_id:  String = ""
var mejora_manager     = null
var multiplicador: int = 1
var color_boton:   Color = Color(0.06, 0.35, 0.54)  # azul por defecto
var _senales_conectadas: bool = false

# Compra en ráfaga al mantener pulsado
const HOLD_DELAY:  float = 0.45  # espera antes de empezar la ráfaga
const HOLD_REPEAT: float = 0.12  # intervalo entre compras de la ráfaga
var _hold_timer: Timer = null
var _compras_en_hold: int = 0

var _tween_pulso: Tween = null

const COLOR_COSTE_OK    := Color(1.0, 0.85, 0.0)
const COLOR_COSTE_CARO  := Color(0.85, 0.4, 0.35)

# Lado izquierdo — área info (Button contenedor)
@onready var btn_info:     Button = $HBoxMain/BtnInfo
var lbl_info_nombre:       Label  = null  # creada por código

# Lado derecho — botón compra
@onready var lbl_valor:    Label  = $HBoxMain/BtnComprar/VBox/LblValor
@onready var lbl_coste:    Label  = $HBoxMain/BtnComprar/VBox/LblCoste
@onready var lbl_accion:   Label  = $HBoxMain/BtnComprar/VBox/LblAccion
@onready var btn_comprar:  Button = $HBoxMain/BtnComprar
@onready var lbl_bloqueada:Label  = $HBoxMain/BtnComprar/VBox/LblBloqueada

func inicializar(manager, color: Color) -> void:
	mejora_manager = manager
	color_boton    = color
	if not _senales_conectadas:
		btn_info.pressed.connect(_on_info_presionado)
		btn_comprar.pressed.connect(_on_comprar)
		btn_comprar.button_down.connect(_on_comprar_down)
		btn_comprar.button_up.connect(_on_comprar_up)
		_senales_conectadas = true
	if not _hold_timer:
		_hold_timer = Timer.new()
		_hold_timer.one_shot = true
		_hold_timer.timeout.connect(_on_hold_tick)
		add_child(_hold_timer)
	# ✅ Crear Label dentro del BtnInfo para tener autowrap real
	if not lbl_info_nombre:
		# Limpiar el texto del botón (lo mostrará la label)
		btn_info.text = ""
		lbl_info_nombre = Label.new()
		lbl_info_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_info_nombre.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl_info_nombre.autowrap_mode        = TextServer.AUTOWRAP_WORD
		lbl_info_nombre.size_flags_horizontal = Control.SIZE_FILL
		lbl_info_nombre.size_flags_vertical   = Control.SIZE_FILL
		lbl_info_nombre.add_theme_font_size_override("font_size", 18)
		# La label no debe capturar input — el botón padre lo hace
		lbl_info_nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_info.add_child(lbl_info_nombre)
	# Agrandar las etiquetas del lado de compra (override sobre la escena).
	lbl_valor.add_theme_font_size_override("font_size", 17)
	lbl_coste.add_theme_font_size_override("font_size", 16)
	lbl_accion.add_theme_font_size_override("font_size", 16)
	lbl_bloqueada.add_theme_font_size_override("font_size", 15)
	refrescar()

func set_multiplicador(valor: int) -> void:
	multiplicador = valor
	refrescar()

# ═══════════════════════════════════════════════════
func refrescar() -> void:
	if not mejora_manager or mejora_id.is_empty():
		return

	var data       = mejora_manager.mejoras[mejora_id]
	var nivel: int      = mejora_manager.get_nivel(mejora_id)
	var max_nivel: int  = mejora_manager.get_max_nivel(mejora_id)
	var bloqueada: bool = mejora_manager.esta_bloqueada(mejora_id)
	var cantidad: int   = _calcular_cantidad(nivel, max_nivel, bloqueada)
	var puede: bool     = mejora_manager.puede_comprar(mejora_id) and not bloqueada

	# Lado izquierdo: nombre en dos líneas si es largo
	btn_info.text = data["nombre"].to_upper()

	# Lado derecho: info + acción
	lbl_valor.text  = _formatear_valor_siguiente(nivel, cantidad)
	lbl_coste.text  = _formatear_coste(cantidad)
	lbl_accion.text = _texto_accion(cantidad, bloqueada)
	# Coste dorado si alcanza, rojizo si no: se ve de un vistazo qué es pagable.
	lbl_coste.add_theme_color_override("font_color", COLOR_COSTE_OK if puede else COLOR_COSTE_CARO)

	# Color del botón de compra según categoría
	var color_oscuro = color_boton.darkened(0.3)
	btn_comprar.add_theme_color_override("font_color",         Color.WHITE)
	btn_comprar.add_theme_color_override("font_hover_color",   Color.WHITE)
	btn_comprar.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn_comprar.add_theme_stylebox_override("normal",  _hacer_stylebox(color_oscuro, 0.9))
	btn_comprar.add_theme_stylebox_override("hover",   _hacer_stylebox(color_boton,  1.0))
	btn_comprar.add_theme_stylebox_override("pressed", _hacer_stylebox(color_oscuro, 1.0))
	btn_comprar.add_theme_stylebox_override("disabled",_hacer_stylebox(Color(0.15, 0.15, 0.15), 0.5))

	# Solo deshabilitar si no quedan niveles (max alcanzado o bloqueada). La
	# falta de energía NO deshabilita el botón: solo lo atenúa. Así evitamos
	# que en táctil quede "pillado" al drenarse la energía bajo el dedo, y
	# comprar_mejora ya ignora el toque si no alcanza para ningún nivel.
	btn_comprar.disabled    = (cantidad == 0)
	btn_comprar.modulate    = Color.WHITE if puede else Color(0.55, 0.55, 0.55)
	lbl_bloqueada.visible   = bloqueada
	lbl_valor.visible       = not bloqueada
	lbl_coste.visible       = not bloqueada
	lbl_accion.visible      = not bloqueada

func _texto_accion(cantidad: int, bloqueada: bool) -> String:
	if bloqueada: return ""
	if cantidad > 1: return "COMPRAR x%d" % cantidad
	return "COMPRAR"

func _hacer_stylebox(color: Color, alpha: float) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color          = Color(color.r, color.g, color.b, alpha)
	sb.corner_radius_top_right    = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left   = 6
	sb.content_margin_right  = 6
	sb.content_margin_top    = 4
	sb.content_margin_bottom = 4
	return sb

# ═══════════════════════════════════════════════════
# ACCIONES
# ═══════════════════════════════════════════════════
func _on_info_presionado() -> void:
	info_solicitada.emit(mejora_id, color_boton)

func _on_comprar() -> void:
	# `pressed` salta al soltar: si la ráfaga del hold ya compró, no repetir.
	if _compras_en_hold > 0:
		return
	_comprar()

func _on_comprar_down() -> void:
	_compras_en_hold = 0
	_hold_timer.start(HOLD_DELAY)

func _on_comprar_up() -> void:
	_hold_timer.stop()

func _on_hold_tick() -> void:
	if btn_comprar.disabled:
		return
	_compras_en_hold += 1
	_comprar()
	_hold_timer.start(HOLD_REPEAT)

func _comprar() -> void:
	var nivel: int      = mejora_manager.get_nivel(mejora_id)
	var max_nivel: int  = mejora_manager.get_max_nivel(mejora_id)
	var bloqueada: bool = mejora_manager.esta_bloqueada(mejora_id)
	var cantidad: int   = _calcular_cantidad(nivel, max_nivel, bloqueada)
	if cantidad <= 0: return
	var compradas: int = mejora_manager.comprar_mejora(mejora_id, cantidad)
	if compradas > 0:
		AudioManager.sfx("compra")
		_pulso_compra()
		refrescar()

# Pulso breve del botón al comprar: feedback táctil sin bloquear nada.
func _pulso_compra() -> void:
	btn_comprar.pivot_offset = btn_comprar.size / 2.0
	if _tween_pulso:
		_tween_pulso.kill()
	btn_comprar.scale = Vector2.ONE
	_tween_pulso = create_tween()
	_tween_pulso.tween_property(btn_comprar, "scale", Vector2(1.07, 1.07), 0.05)
	_tween_pulso.tween_property(btn_comprar, "scale", Vector2.ONE, 0.09)

func _calcular_cantidad(nivel: int, max_nivel: int, bloqueada: bool) -> int:
	if bloqueada: return 0
	var restantes: int = max_nivel - nivel
	if restantes <= 0: return 0
	if multiplicador == -1:
		# MAX = tantos niveles como alcance la energía actual (mínimo 1 para
		# que el botón siga mostrando el coste del siguiente nivel).
		return clampi(mejora_manager.get_max_comprables(mejora_id), 1, restantes)
	return min(multiplicador, restantes)


# ═══════════════════════════════════════════════════
# FORMATEO (delegado en MejoraManager para compartirlo con el modal)
# ═══════════════════════════════════════════════════
func _formatear_valor_siguiente(nivel: int, cantidad: int) -> String:
	if cantidad <= 0: return _valor_en_nivel(nivel)
	return _valor_en_nivel(nivel) + " → " + _valor_en_nivel(nivel + cantidad)

func _valor_en_nivel(nivel: int) -> String:
	return mejora_manager.formatear_valor(mejora_id, nivel)

func _formatear_coste(cantidad: int) -> String:
	if cantidad <= 0: return ""
	return Formato.abreviar(mejora_manager.get_coste_acumulado(mejora_id, cantidad)) + " ⚡"
