extends PanelContainer
# ═══════════════════════════════════════════════════
# MEJORA CARD — Void Sentinel
# Izquierda: nombre y valor (abre el modal). Derecha: botón de compra con el
# coste. Mantener pulsado compra en ráfaga (tras un pequeño delay).
#
# La escena solo aporta los nodos base; la maquetación se monta en _construir().
# Ninguna etiqueta impone su ancho (recortan o parten línea) y los botones no
# tienen tamaño mínimo, así que todas las cards miden lo mismo sea cual sea el
# texto. Referencia de estructura: el Taller de The Tower.
# ═══════════════════════════════════════════════════

signal info_solicitada(mejora_id: String, color_categoria: Color)

@export var mejora_id:  String = ""
var mejora_manager     = null
var multiplicador: int = 1
var color_boton:   Color = MenuTheme.CAT_DEFENSA
var _senales_conectadas: bool = false
var _construida: bool = false

const ALTO_CARD: float = 112.0

# Compra en ráfaga al mantener pulsado
const HOLD_DELAY:  float = 0.45  # espera antes de empezar la ráfaga
const HOLD_REPEAT: float = 0.12  # intervalo entre compras de la ráfaga
var _hold_timer: Timer = null
var _compras_en_hold: int = 0

# Las cards viven en un ScrollContainer: un dedo que se desplaza más que esto
# está haciendo scroll, y no debe comprar ni abrir el modal al soltar.
const UMBRAL_ARRASTRE: float = 16.0
var _pos_pulsacion: Vector2 = Vector2.ZERO
var _arrastrando: bool = false
var _scroll: ScrollContainer = null
var _scroll_y: float = 0.0
# Inercia al soltar: sin ella el panel se para en seco y hacen falta varios
# arrastres para llegar al final de Bonus.
const ROZAMIENTO: float = 5.0     # cuánto frena por segundo
const INERCIA_MINIMA: float = 60.0  # por debajo de esto, ni se lanza ni sigue
var _velocidad: float = 0.0
var _inercia: float = 0.0

var _tween_pulso: Tween = null

const COLOR_COSTE_CARO := Color("ff8a80")

# Lado izquierdo — área info
@onready var btn_info:     Button = $HBoxMain/BtnInfo
var lbl_info_nombre:       Label  = null  # creada por código
var lbl_siguiente:         Label  = null  # creada por código

# Lado derecho — botón compra (las etiquetas vienen de la escena y se recolocan)
@onready var lbl_valor:    Label  = $HBoxMain/BtnComprar/VBox/LblValor
@onready var lbl_coste:    Label  = $HBoxMain/BtnComprar/VBox/LblCoste
@onready var lbl_accion:   Label  = $HBoxMain/BtnComprar/VBox/LblAccion
@onready var btn_comprar:  Button = $HBoxMain/BtnComprar
@onready var lbl_bloqueada:Label  = $HBoxMain/BtnComprar/VBox/LblBloqueada
var fila_coste: HBoxContainer = null

var _estilo_card:     StyleBoxFlat = null
var _estilo_card_max: StyleBoxFlat = null
var _estilo_agotado:  StyleBoxFlat = null
var _estilo_max:      StyleBoxFlat = null

func inicializar(manager, color: Color) -> void:
	mejora_manager = manager
	color_boton    = color
	if not _construida:
		_construir()
		_construida = true
		# _process solo corre mientras hay inercia; las 25 cards no gastan frames.
		set_process(false)
	if not _senales_conectadas:
		btn_info.pressed.connect(_on_info_presionado)
		btn_info.gui_input.connect(_on_boton_input)
		btn_comprar.pressed.connect(_on_comprar)
		btn_comprar.button_down.connect(_on_comprar_down)
		btn_comprar.button_up.connect(_on_comprar_up)
		btn_comprar.gui_input.connect(_on_boton_input)
		# El borde de la card también sirve para arrastrar.
		gui_input.connect(_on_boton_input)
		_senales_conectadas = true
	if not _hold_timer:
		_hold_timer = Timer.new()
		_hold_timer.one_shot = true
		_hold_timer.timeout.connect(_on_hold_tick)
		add_child(_hold_timer)
	_aplicar_estilos()
	refrescar()

func set_multiplicador(valor: int) -> void:
	multiplicador = valor
	refrescar()

# ═══════════════════════════════════════════════════
# MAQUETACIÓN
# ═══════════════════════════════════════════════════
func _construir() -> void:
	custom_minimum_size = Vector2(0, ALTO_CARD)
	var hbox: HBoxContainer = $HBoxMain
	hbox.add_theme_constant_override("separation", 8)

	for boton in [btn_info, btn_comprar]:
		boton.text = ""
		boton.custom_minimum_size = Vector2.ZERO
		boton.clip_contents = true
		boton.focus_mode = Control.FOCUS_NONE
		# PASS: el arrastre tiene que llegar al ScrollContainer para desplazar.
		boton.mouse_filter = Control.MOUSE_FILTER_PASS
	btn_info.size_flags_stretch_ratio    = 1.45
	btn_comprar.size_flags_stretch_ratio = 1.0

	# Izquierda: nombre (hasta 2 líneas), valor actual y el siguiente.
	var col_info := _columna(btn_info, 4)
	lbl_info_nombre = Label.new()
	_estilo_etiqueta(lbl_info_nombre, MenuTheme.FS_TINY - 1, color_boton, true)
	lbl_info_nombre.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	lbl_info_nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_info_nombre.max_lines_visible = 2
	col_info.add_child(lbl_info_nombre)
	lbl_valor.reparent(col_info, false)
	_estilo_etiqueta(lbl_valor, MenuTheme.FS_BODY + 2, MenuTheme.TEXT_PRIMARY, false)
	lbl_siguiente = Label.new()
	_estilo_etiqueta(lbl_siguiente, MenuTheme.FS_SMALL, MenuTheme.GREEN, false)
	col_info.add_child(lbl_siguiente)

	# Derecha: coste con el rayo dibujado (el emoji no se pinta en Android) y acción.
	var vieja := btn_comprar.get_node("VBox")
	var col_compra := _columna(btn_comprar, 6)
	fila_coste = HBoxContainer.new()
	fila_coste.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_coste.add_theme_constant_override("separation", 4)
	fila_coste.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(IconoVec.crear(IconoVec.Forma.RAYO, 22, MenuTheme.GOLD))
	fila_coste.add_child(centro)
	lbl_coste.reparent(fila_coste, false)
	# Sin recorte: en un HBox centrado, una etiqueta recortable se queda en "…".
	_estilo_etiqueta(lbl_coste, MenuTheme.FS_BODY + 2, MenuTheme.GOLD, false, HORIZONTAL_ALIGNMENT_CENTER)
	lbl_coste.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	col_compra.add_child(fila_coste)
	lbl_accion.reparent(col_compra, false)
	_estilo_etiqueta(lbl_accion, MenuTheme.FS_TINY + 1, MenuTheme.TEXT_PRIMARY, false, HORIZONTAL_ALIGNMENT_CENTER)
	lbl_bloqueada.reparent(col_compra, false)
	_estilo_etiqueta(lbl_bloqueada, MenuTheme.FS_TINY, MenuTheme.RED, false, HORIZONTAL_ALIGNMENT_CENTER)
	vieja.queue_free()

# Button no es un contenedor: sus hijos no se colocan solos. Un MarginContainer
# anclado a todo el botón sigue su tamaño sin imponerle ninguno.
func _columna(boton: Button, margen: int) -> VBoxContainer:
	var marco := MarginContainer.new()
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		marco.add_theme_constant_override(lado, margen)
	boton.add_child(marco)
	marco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.add_child(v)
	return v

# Las cifras van en la fuente de cuerpo: el cero de Orbitron parece un glifo roto.
func _estilo_etiqueta(lbl: Label, tam: int, color: Color, fuente_hud: bool,
		alineacion: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	var f: Font = MenuTheme.get_font_hud() if fuente_hud else MenuTheme.get_font_body()
	if f:
		lbl.add_theme_font_override("font", f)
	lbl.horizontal_alignment = alineacion
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _aplicar_estilos() -> void:
	# Translúcidas a propósito, como el fondo del panel: con el panel abierto se
	# ve moverse lo que pasa detrás sin perder legibilidad del texto.
	var fondo := Color(MenuTheme.BG_CARD, 0.72)
	_estilo_card     = _caja(fondo, Color(color_boton, 0.35), 14, 8)
	_estilo_card_max = _caja(fondo, Color(MenuTheme.GOLD, 0.7), 14, 8)
	_estilo_agotado  = _caja(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.10), 10, 0)
	_estilo_max      = _caja(Color(MenuTheme.GOLD, 0.08), Color(MenuTheme.GOLD, 0.30), 10, 0)
	add_theme_stylebox_override("panel", _estilo_card)
	lbl_info_nombre.add_theme_color_override("font_color", color_boton)

	var vacio := StyleBoxEmpty.new()
	for estado in ["normal", "hover", "focus", "disabled"]:
		btn_info.add_theme_stylebox_override(estado, vacio)
	btn_info.add_theme_stylebox_override("pressed", _caja(Color(color_boton, 0.10), Color(0, 0, 0, 0), 10, 0))

	btn_comprar.add_theme_stylebox_override("normal",  _caja(Color(color_boton, 0.14), Color(color_boton, 0.45), 10, 0))
	btn_comprar.add_theme_stylebox_override("hover",   _caja(Color(color_boton, 0.20), Color(color_boton, 0.60), 10, 0))
	btn_comprar.add_theme_stylebox_override("pressed", _caja(Color(color_boton, 0.30), Color(color_boton, 0.85), 10, 0))
	btn_comprar.add_theme_stylebox_override("focus",   vacio)
	btn_comprar.add_theme_stylebox_override("disabled", _estilo_agotado)

func _caja(fondo: Color, borde: Color, radio: int, margen: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fondo
	sb.border_color = borde
	sb.set_border_width_all(1 if borde.a > 0.0 else 0)
	sb.set_corner_radius_all(radio)
	sb.set_content_margin_all(margen)
	return sb

# ═══════════════════════════════════════════════════
func refrescar() -> void:
	if not mejora_manager or mejora_id.is_empty() or not _construida:
		return

	var data       = mejora_manager.mejoras[mejora_id]
	var nivel: int      = mejora_manager.get_nivel(mejora_id)
	var max_nivel: int  = mejora_manager.get_max_nivel(mejora_id)
	var bloqueada: bool = mejora_manager.esta_bloqueada(mejora_id)
	var cantidad: int   = _calcular_cantidad(nivel, max_nivel, bloqueada)
	var puede: bool     = mejora_manager.puede_comprar(mejora_id) and not bloqueada
	var al_max: bool    = nivel >= max_nivel

	# Izquierda: nombre, valor actual y a qué pasa con la compra.
	lbl_info_nombre.text = data["nombre"].to_upper()
	lbl_valor.text = _valor_en_nivel(nivel)
	if al_max:
		lbl_siguiente.text = "MÁX"
		lbl_siguiente.add_theme_color_override("font_color", MenuTheme.GOLD)
	elif bloqueada:
		lbl_siguiente.text = ""
	else:
		lbl_siguiente.text = "→ " + _valor_en_nivel(nivel + cantidad)
		lbl_siguiente.add_theme_color_override("font_color", MenuTheme.GREEN)

	# Derecha: coste dorado si alcanza, rojizo si no; se ve de un vistazo qué es pagable.
	lbl_coste.text = _formatear_coste(cantidad)
	lbl_coste.add_theme_color_override("font_color", MenuTheme.GOLD if puede else COLOR_COSTE_CARO)
	fila_coste.visible    = cantidad > 0
	lbl_accion.visible    = not bloqueada
	lbl_accion.text       = _texto_accion(cantidad, al_max)
	lbl_accion.add_theme_color_override("font_color",
		MenuTheme.GOLD if al_max else Color(MenuTheme.TEXT_PRIMARY, 0.75))
	lbl_bloqueada.visible = bloqueada

	# Solo deshabilitar si no quedan niveles (max alcanzado o bloqueada). La
	# falta de energía NO deshabilita el botón: solo lo atenúa. Así evitamos
	# que en táctil quede "pillado" al drenarse la energía bajo el dedo, y
	# comprar_mejora ya ignora el toque si no alcanza para ningún nivel.
	btn_comprar.disabled = (cantidad == 0)
	btn_comprar.modulate = Color.WHITE if (puede or cantidad == 0) else Color(0.6, 0.6, 0.6)
	btn_comprar.add_theme_stylebox_override("disabled", _estilo_max if al_max else _estilo_agotado)

	# Completada: borde dorado y el resto atenuado, como en el Taller de The Tower.
	add_theme_stylebox_override("panel", _estilo_card_max if al_max else _estilo_card)
	btn_info.modulate = Color(1, 1, 1, 0.7) if al_max else Color.WHITE

func _texto_accion(cantidad: int, al_max: bool) -> String:
	if al_max: return "MÁX"
	if cantidad > 1: return "COMPRAR x%d" % cantidad
	return "COMPRAR"

# ═══════════════════════════════════════════════════
# ACCIONES
# ═══════════════════════════════════════════════════
# El arrastre lo desplaza la propia card: probado en el móvil, el
# ScrollContainer no llega a desplazarse cuando el dedo empieza sobre un botón.
func _on_boton_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pos_pulsacion = event.global_position
			_arrastrando = false
			_velocidad = 0.0
			_parar_inercia()
		elif _arrastrando and _scroll and absf(_velocidad) > INERCIA_MINIMA:
			_inercia = _velocidad
			set_process(true)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if not _arrastrando and event.global_position.distance_to(_pos_pulsacion) > UMBRAL_ARRASTRE:
			_arrastrando = true
			_hold_timer.stop()
			_scroll = _buscar_scroll()
			if _scroll:
				_scroll_y = float(_scroll.scroll_vertical)
		if _arrastrando and _scroll:
			_velocidad = event.velocity.y
			_desplazar(event.relative.y)
			# Que no lo procese nadie más: ni otro nivel de la card ni el scroll nativo.
			accept_event()

func _process(delta: float) -> void:
	if not _scroll or absf(_inercia) < INERCIA_MINIMA:
		_parar_inercia()
		return
	_desplazar(_inercia * delta)
	_inercia = lerpf(_inercia, 0.0, clampf(ROZAMIENTO * delta, 0.0, 1.0))

func _desplazar(delta_y: float) -> void:
	var tope: float = maxf(_scroll.get_v_scroll_bar().max_value - _scroll.size.y, 0.0)
	_scroll_y = clampf(_scroll_y - delta_y, 0.0, tope)
	_scroll.scroll_vertical = int(_scroll_y)
	# Llegar al borde mata la inercia: si no, sigue gastando frames sin mover nada.
	if is_equal_approx(_scroll_y, 0.0) or is_equal_approx(_scroll_y, tope):
		_parar_inercia()

func _parar_inercia() -> void:
	_inercia = 0.0
	set_process(false)

func _buscar_scroll() -> ScrollContainer:
	var n := get_parent()
	while n and not n is ScrollContainer:
		n = n.get_parent()
	return n as ScrollContainer

func _on_info_presionado() -> void:
	if _arrastrando:
		return
	info_solicitada.emit(mejora_id, color_boton)

func _on_comprar() -> void:
	# `pressed` salta al soltar: si la ráfaga del hold ya compró, no repetir.
	if _compras_en_hold > 0 or _arrastrando:
		return
	_comprar()

func _on_comprar_down() -> void:
	_compras_en_hold = 0
	_hold_timer.start(HOLD_DELAY)

func _on_comprar_up() -> void:
	_hold_timer.stop()

func _on_hold_tick() -> void:
	if btn_comprar.disabled or _arrastrando:
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
func _valor_en_nivel(nivel: int) -> String:
	return mejora_manager.formatear_valor(mejora_id, nivel)

func _formatear_coste(cantidad: int) -> String:
	if cantidad <= 0: return ""
	return Formato.abreviar(mejora_manager.get_coste_acumulado(mejora_id, cantidad))
