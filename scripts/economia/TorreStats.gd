# res://scripts/economia/TorreStats.gd
# Autoload: TorreStats
# Gestiona todas las stats de combate del núcleo.

extends Node

signal vida_cambiada(actual: float, maxima: float)
signal stats_actualizadas

var base_salud: float = 100.0
var base_dano: float = 10.0
var base_cadencia: float = 1.0
var base_regeneracion: float = 2.0
var base_rango_escaneo: float = 400.0

var vida_actual: float = 100.0

func _ready() -> void:
	vida_actual = base_salud
	print("TorreStats inicializado. Vida: ", vida_actual, "/", base_salud)
	vida_cambiada.emit(vida_actual, base_salud)

func get_salud() -> float:
	return base_salud

func get_dano() -> float:
	return base_dano

func get_cadencia_timer() -> float:
	return 1.0 / max(base_cadencia, 0.01)

func get_regeneracion() -> float:
	return base_regeneracion

func get_rango_escaneo() -> float:
	return base_rango_escaneo

func recibir_dano(cantidad: float) -> bool:
	var vida_anterior = vida_actual
	vida_actual = max(0.0, vida_actual - cantidad)
	print("TorreStats.recibir_dano: ", vida_anterior, " -> ", vida_actual, " (daño: ", cantidad, ")")
	vida_cambiada.emit(vida_actual, base_salud)
	return vida_actual > 0.0

func curar(cantidad: float) -> void:
	var vida_anterior = vida_actual
	vida_actual = min(base_salud, vida_actual + cantidad)
	print("TorreStats.curar: ", vida_anterior, " -> ", vida_actual)
	vida_cambiada.emit(vida_actual, base_salud)

func reiniciar_partida() -> void:
	vida_actual = base_salud
	print("TorreStats.reiniciar_partida: Vida restablecida a ", vida_actual)
	vida_cambiada.emit(vida_actual, base_salud)
	stats_actualizadas.emit()
