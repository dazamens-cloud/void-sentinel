extends Node
# ═══════════════════════════════════════════════════
# ECONOMIA ECOS — Sistema económico de Void Sentinel
# ═══════════════════════════════════════════════════

signal recursos_actualizados
signal ascension_cambiada(numero: int)
signal juego_terminado(causa: String)
signal ecos_obtenidos(cantidad: int, posicion: Vector2)
signal energia_cambiada(nueva_energia: float)

var energia: float = 50.0
var ecos: int = 0
var numero_ascension: int = 0
var espectros_eliminados: int = 0

# ═══════════════════════════════════════════════════
# SISTEMA DE INTERÉS (DOC_B)
# ═══════════════════════════════════════════════════
var tasa_interes: float = 0.025   # 2.5% base (mejorable hasta 5%)
var cap_interes: float = 3000.0   # Cap $3,000 (mejorable hasta $10,000)

func _ready() -> void:
	_cargar_datos()

func iniciar_partida() -> void:
	energia = 50.0
	numero_ascension = 0
	espectros_eliminados = 0
	# ✅ Resetear interés al reiniciar
	tasa_interes = 0.025
	cap_interes = 3000.0
	recursos_actualizados.emit()
	ascension_cambiada.emit(0)

func añadir_energia(cantidad: float) -> void:
	energia += cantidad
	recursos_actualizados.emit()
	energia_cambiada.emit(energia)

func gastar_energia(cantidad: float) -> bool:
	if energia >= cantidad:
		energia -= cantidad
		recursos_actualizados.emit()
		energia_cambiada.emit(energia)
		return true
	return false

func avanzar_ascension() -> void:
	numero_ascension += 1
	aplicar_interes()  # ✅ Interés ANTES de la recompensa base
	ascension_cambiada.emit(numero_ascension)
	añadir_energia(10.0 + float(numero_ascension))

# ═══════════════════════════════════════════════════
# SISTEMA DE INTERÉS
# ═══════════════════════════════════════════════════
func calcular_interes() -> float:
	var interes = energia * tasa_interes
	return min(interes, cap_interes)

func aplicar_interes() -> void:
	var interes_ganado = calcular_interes()
	if interes_ganado > 0.5:  # Solo si es significativo
		añadir_energia(interes_ganado)
		print("💰 Interés: +", int(interes_ganado), "⚡ (", int(tasa_interes * 100), "% de ", int(energia - interes_ganado), ")")

func mejorar_tasa_interes(nueva_tasa: float) -> void:
	tasa_interes = nueva_tasa

func mejorar_cap_interes(nuevo_cap: float) -> void:
	cap_interes = nuevo_cap

func get_tasa_interes() -> float:
	return tasa_interes

func get_cap_interes() -> float:
	return cap_interes

# ═══════════════════════════════════════════════════
# RECOMPENSAS AL MATAR ESPECTROS
# ═══════════════════════════════════════════════════
func obtener_energia_por_espectro() -> int:
	return min(50, 5 + numero_ascension)

func obtener_ecos_por_5_muertes() -> int:
	return 1 + int(numero_ascension / 5)

func procesar_drop_espectro(datos: Dictionary) -> void:
	espectros_eliminados += 1
	var recompensa = float(datos.get("recompensa", 5))
	var posicion = datos.get("posicion", Vector2.ZERO)
	
	añadir_energia(recompensa)
	
	if espectros_eliminados % 5 == 0:
		var ecos_ganados = obtener_ecos_por_5_muertes()
		ecos += ecos_ganados
		guardar_datos()
		recursos_actualizados.emit()
		ecos_obtenidos.emit(ecos_ganados, posicion)

# ── Funciones para el Nexus ──────────────────────────
func get_rango_escaneo() -> float:
	return 200.0

func get_danio() -> float:
	return 150

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
