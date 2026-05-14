extends Node
# ═══════════════════════════════════════════════════
# ECONOMIA ECOS — Sistema económico de Void Sentinel
# ═══════════════════════════════════════════════════

signal recursos_actualizados
signal ascension_cambiada(numero: int)
signal juego_terminado(causa: String)

var energia: float = 50.0        # antes "efectivo"
var ecos: int = 0                # antes "monedas"
var numero_ascension: int = 0    # antes "numero_oleada"
var espectros_eliminados: int = 0 # antes "enemigos_eliminados"

func _ready() -> void:
	_cargar_datos()

func iniciar_partida() -> void:
	energia = 50.0
	numero_ascension = 0
	espectros_eliminados = 0
	recursos_actualizados.emit()
	ascension_cambiada.emit(0)

func añadir_energia(cantidad: float) -> void:
	energia += cantidad
	recursos_actualizados.emit()

func gastar_energia(cantidad: float) -> bool:
	if energia >= cantidad:
		energia -= cantidad
		recursos_actualizados.emit()
		return true
	return false

func avanzar_ascension() -> void:
	numero_ascension += 1
	ascension_cambiada.emit(numero_ascension)
	añadir_energia(10.0 + float(numero_ascension))

func procesar_drop_espectro(datos: Dictionary) -> void:
	espectros_eliminados += 1
	var recompensa = float(datos.get("recompensa", 5))
	añadir_energia(recompensa)
	
	if espectros_eliminados % 5 == 0:
		ecos += 1
		guardar_datos()
		recursos_actualizados.emit()

# ── Funciones para el Nexus ──────────────────────────
func get_rango_escaneo() -> float:
	return 200.0

func get_danio() -> float:
	return 10.0

func get_cadencia_timer() -> float:
	return 1.0

func get_regeneracion() -> float:
	return 0.0

func get_defensa() -> float:
	return 0.0

# ── Guardado ─────────────────────────────────────────
func guardar_datos() -> void:
	var file = FileAccess.open("user://economia.save", FileAccess.WRITE)
	if file:
		file.store_var({"ecos": ecos})
		file.close()

func _cargar_datos() -> void:
	if FileAccess.file_exists("user://economia.save"):
		var file = FileAccess.open("user://economia.save", FileAccess.READ)
		if file:
			var data = file.get_var()
			if data is Dictionary:
				ecos = data.get("ecos", 0)
			file.close()
