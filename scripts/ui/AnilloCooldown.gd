class_name AnilloCooldown
extends Control
# ============================================================
# ANILLO DE COOLDOWN — Void Sentinel
#
# Aro de progreso que rodea al icono de una habilidad. Sustituye al texto
# "LISTA" / "17s", que en el movil era casi ilegible.
#
# Uso:
#   var a := AnilloCooldown.crear(64, MenuTheme.CYAN)
#   a.progreso = 0.4   # 0 = recien lanzada, 1 = lista
# ============================================================

const GROSOR: float = 4.0

var color: Color = Color.WHITE
# 0 = acaba de lanzarse, 1 = lista. Redibuja solo al cambiar.
var progreso: float = 1.0:
	set(valor):
		var nuevo := clampf(valor, 0.0, 1.0)
		if is_equal_approx(nuevo, progreso):
			return
		progreso = nuevo
		queue_redraw()


static func crear(tam: float, c: Color) -> AnilloCooldown:
	var a := AnilloCooldown.new()
	a.color = c
	a.custom_minimum_size = Vector2(tam, tam)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return a


func _draw() -> void:
	var centro := size / 2.0
	var radio: float = minf(size.x, size.y) / 2.0 - GROSOR / 2.0
	if radio <= 0.0:
		return
	# Pista de fondo siempre visible: sin ella el aro a medias no se entiende.
	draw_arc(centro, radio, 0.0, TAU, 48, Color(color, 0.18), GROSOR, true)
	if progreso <= 0.0:
		return
	# Desde arriba y en el sentido del reloj.
	var inicio := -PI / 2.0
	draw_arc(centro, radio, inicio, inicio + TAU * progreso, 48, color, GROSOR, true)
