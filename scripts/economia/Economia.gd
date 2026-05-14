# res://scripts/economia/Economia.gd
# Autoload: Economia
# Gestiona dinero, oleadas y drops.

extends Node

signal recursos_actualizados
signal oleada_cambiada(numero: int)
signal juego_terminado(causa: String)

var efectivo: float = 50.0
var monedas: int = 0
var numero_oleada: int = 0
var enemigos_eliminados: int = 0

func _ready() -> void:
	_cargar_datos()

func iniciar_partida() -> void:
	efectivo = 50.0
	numero_oleada = 0
	enemigos_eliminados = 0
	recursos_actualizados.emit()
	oleada_cambiada.emit(0)

func añadir_efectivo(cantidad: float) -> void:
	efectivo += cantidad
	recursos_actualizados.emit()

func gastar_efectivo(cantidad: float) -> bool:
	if efectivo >= cantidad:
		efectivo -= cantidad
		recursos_actualizados.emit()
		return true
	return false

func avanzar_oleada() -> void:
	numero_oleada += 1
	oleada_cambiada.emit(numero_oleada)
	añadir_efectivo(10.0 + float(numero_oleada))

func procesar_drop_enemigo(datos: Dictionary) -> void:
	enemigos_eliminados += 1
	var recompensa = float(datos.get("recompensa", 5))
	añadir_efectivo(recompensa)
	
	if enemigos_eliminados % 5 == 0:
		monedas += 1
		guardar_datos()
		recursos_actualizados.emit()

func get_defensa() -> float:
	return 0.0

# ✅ NUEVO: Método para terminar el juego
func terminar_juego(causa: String = "Desconocida") -> void:
	juego_terminado.emit(causa)

func guardar_datos() -> void:
	var file = FileAccess.open("user://economia.save", FileAccess.WRITE)
	if file:
		file.store_var({"monedas": monedas})
		file.close()

func _cargar_datos() -> void:
	if FileAccess.file_exists("user://economia.save"):
		var file = FileAccess.open("user://economia.save", FileAccess.READ)
		if file:
			var data = file.get_var()
			if data is Dictionary:
				monedas = data.get("monedas", 0)
			file.close()
