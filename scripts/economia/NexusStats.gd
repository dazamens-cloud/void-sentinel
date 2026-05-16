extends Node
# ═══════════════════════════════════════════════════
# NEXUS STATS — Estadísticas del Nexus
# ═══════════════════════════════════════════════════

signal salud_cambiada(actual: float, maxima: float)
signal stats_actualizadas

var salud_base: float = 100.0
var salud_actual: float = 100.0

func _ready() -> void:
	salud_actual = salud_base
	salud_cambiada.emit(salud_actual, salud_base)

func get_salud() -> float:
	return salud_base

func get_danio() -> float:
	return 105.0

func get_cadencia_timer() -> float:
	return 0.45

func get_regeneracion() -> float:
	return 0.0

func get_rango_escaneo() -> float:
	return 220.0

func get_critico_chance() -> float:
	return 0.05

func get_critico_factor() -> float:
	return 1.5

func recibir_ataque(cantidad: float) -> bool:
	salud_actual = max(0.0, salud_actual - cantidad)
	salud_cambiada.emit(salud_actual, salud_base)
	return salud_actual > 0.0

func curar(cantidad: float) -> void:
	salud_actual = min(salud_base, salud_actual + cantidad)
	salud_cambiada.emit(salud_actual, salud_base)

func reiniciar_partida() -> void:
	salud_actual = salud_base
	salud_cambiada.emit(salud_actual, salud_base)
	stats_actualizadas.emit()
