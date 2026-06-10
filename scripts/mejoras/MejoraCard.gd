extends PanelContainer
# ═══════════════════════════════════════════════════
# MEJORA CARD — Void Sentinel
# FASE 3: Lado izquierdo abre modal global
#         Lado derecho = botón de compra completo
# ═══════════════════════════════════════════════════

signal info_solicitada(mejora_id: String, color_categoria: Color)

@export var mejora_id:  String = ""
var mejora_manager     = null
var multiplicador: int = 1
var color_boton:   Color = Color(0.06, 0.35, 0.54)  # azul por defecto
var _senales_conectadas: bool = false

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
		_senales_conectadas = true
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
	lbl_accion.text = "COMPRAR" if not bloqueada else ""

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
	var nivel: int      = mejora_manager.get_nivel(mejora_id)
	var max_nivel: int  = mejora_manager.get_max_nivel(mejora_id)
	var bloqueada: bool = mejora_manager.esta_bloqueada(mejora_id)
	var cantidad: int   = _calcular_cantidad(nivel, max_nivel, bloqueada)
	if cantidad <= 0: return
	var compradas: int = mejora_manager.comprar_mejora(mejora_id, cantidad)
	if compradas > 0:
		AudioManager.sfx("compra")
		refrescar()

func _calcular_cantidad(nivel: int, max_nivel: int, bloqueada: bool) -> int:
	if bloqueada: return 0
	if multiplicador == -1: return min(max_nivel - nivel, 50)
	return min(multiplicador, max_nivel - nivel)


# ═══════════════════════════════════════════════════
# FORMATEO
# ═══════════════════════════════════════════════════
func _formatear_valor_siguiente(nivel: int, cantidad: int) -> String:
	if cantidad <= 0: return _valor_en_nivel(nivel)
	return _valor_en_nivel(nivel) + " → " + _valor_en_nivel(nivel + cantidad)

func _valor_en_nivel(nivel: int) -> String:
	var data = mejora_manager.mejoras[mejora_id]
	match mejora_id:
		"danio":
			# Daño es MULTIPLICATIVO: daño real = base × 1.03^nivel (no aditivo).
			var d: float = NexusStats.danio_base * pow(mejora_manager.FACTOR_MULTIPLICATIVO, nivel)
			return str(int(d)) + " atk"
		"velocidad_ataque":
			# Cadencia REAL = max(0.05, 1 - |nivel×0.01|) × base. Antes hacía
			# max(delta_negativo, min_valor) → mostraba siempre el mínimo (0.05s).
			var factor: float = max(0.05, 1.0 - abs(nivel * data.get("incremento", -0.01)))
			return "%.2fs" % factor
		"disparo_critico":
			# Incluye la base del Nexus (5% prob, ×1.5 factor) para que el número
			# coincida con el crítico real que ves en combate.
			var prob: float  = min(0.75, NexusStats.critico_chance_base + nivel * data.get("incremento_prob", 0.005)) * 100.0
			var danio: float = NexusStats.critico_factor_base + nivel * data.get("incremento_danio", 0.25)
			return "%d%% / %.1fx" % [int(prob), danio]
		"multidisparo":
			# Ahora es nº de objetivos distintos atacados a la vez, no proyectiles.
			return "+" + str(int(nivel * data.get("incremento", 1.0))) + " obj"
		"rebote":
			return str(int(nivel * data.get("incremento", 1.0))) + " reb"
		"alcance_rebote":
			return str(int(nivel * data.get("incremento", 30.0))) + "px"
		"salud":
			# Salud es MULTIPLICATIVA: HP real = 100 × 1.03^nivel (no aditivo).
			var hp: float = 100.0 * pow(mejora_manager.FACTOR_MULTIPLICATIVO, nivel)
			return str(int(hp)) + " HP"
		"recuperacion":
			return "+%.1f HP/s" % (nivel * data.get("incremento", 0.1))
		"escudo":
			return "+" + str(int(nivel * data.get("incremento", 5.0))) + " esc"
		"dureza_escudo":
			var v2: float = nivel * data.get("incremento", -0.005)
			if data.has("min_valor"): v2 = max(v2, data["min_valor"])
			return "-%d%%" % int(abs(v2) * 100.0)
		"pulso_quartz":
			return str(int(nivel * data.get("incremento", 40.0))) + "px"
		"poder_pulso":
			var lent: float = nivel * data.get("incremento_lentitud", 0.2)
			var emp: float  = nivel * data.get("incremento_empuje", 0.05) * 100.0
			return "%.1fs/+%d%%" % [lent, int(emp)]
		"interes_tasa":
			# Muestra la tasa TOTAL (base 2.5% + mejora) como porcentaje
			var tasa_total: float = (0.025 + nivel * data.get("incremento", 0.003)) * 100.0
			return "%.1f%%" % tasa_total
		"interes_cap":
			# Muestra el cap TOTAL (base 3,000 + mejora)
			var cap_total: int = int(3000.0 + nivel * data.get("incremento", 300.0))
			return str(cap_total) + "⚡ cap"
		_:
			return str(nivel * data.get("incremento", 1.0))

func _formatear_coste(cantidad: int) -> String:
	if cantidad <= 0: return ""
	var data = mejora_manager.mejoras[mejora_id]
	var coste_base: int = data["coste_base"]
	var factor: float = 1.09
	match data.get("categoria", ""):
		"ataque":       factor = 1.09
		"defensa":      factor = 1.08
		"bonificacion": factor = 1.11
		"commander":    factor = 1.12
	var nivel_actual: int = mejora_manager.get_nivel(mejora_id)
	var total: int = 0
	for i in range(cantidad):
		total += int(coste_base * pow(factor, nivel_actual + i))
	return _abreviar(total) + " ⚡"

func _abreviar(n: int) -> String:
	if n >= 1_000_000: return "%.1fM" % (n / 1_000_000.0)
	elif n >= 1_000:   return "%.1fK" % (n / 1_000.0)
	return str(n)
