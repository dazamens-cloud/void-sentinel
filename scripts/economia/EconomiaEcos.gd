extends Node
# ═══════════════════════════════════════════════════
# ECONOMIA ECOS — Sistema económico de Void Sentinel
# ═══════════════════════════════════════════════════

signal recursos_actualizados
signal ascension_cambiada(numero: int)
signal juego_terminado(causa: String)
signal ecos_obtenidos(cantidad: int, posicion: Vector2)

var energia: float = 50.0
var ecos: int = 0
var numero_ascension: int = 0
var espectros_eliminados: int = 0

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

# ═══════════════════════════════════════════════════════
# RECOMPENSAS AL MATAR ESPECTROS
# ═══════════════════════════════════════════════════════
func obtener_energia_por_espectro() -> int:
	return min(50, 5 + numero_ascension)

func obtener_ecos_por_5_muertes() -> int:
	return 1 + numero_ascension / 5

func procesar_drop_espectro(datos: Dictionary) -> void:
	espectros_eliminados += 1
	var recompensa = float(datos.get("recompensa", 5))
	var posicion = datos.get("posicion", Vector2.ZERO)
	
	# 1. Añadir energía (siempre)
	añadir_energia(recompensa)
	
	# 2. Cada 5 muertes, añadir ecos y emitir señal
	if espectros_eliminados % 5 == 0:
		var ecos_ganados = obtener_ecos_por_5_muertes()
		ecos += ecos_ganados
		guardar_datos()
		recursos_actualizados.emit()
		# 3. Emitir señal para mostrar texto flotante de ecos
		ecos_obtenidos.emit(ecos_ganados, posicion)

# ── Funciones para el Nexus ──────────────────────────
func get_rango_escaneo() -> float:
	return 200.0

func get_danio() -> float:
	return 15.0  # ✅ Balanceado: mata básico de 160HP en ~11 golpes

func get_cadencia_timer() -> float:
	return 0.85

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
