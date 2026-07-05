extends Node
# ═══════════════════════════════════════════════════
# ECONOMIA ECOS — Sistema económico de Void Sentinel
# ═══════════════════════════════════════════════════

signal recursos_actualizados
signal ascension_cambiada(numero: int)
signal juego_terminado(causa: String)
signal ecos_obtenidos(cantidad: int, posicion: Vector2)
signal energia_cambiada(nueva_energia: float)
signal ecos_actualizados
signal fragmentos_actualizados
signal espectro_eliminado   # se emite por cada espectro derrotado (para estadísticas/logros)

var energia: float = 50.0
var ecos: int = 0
var fragmentos: int = 0
var numero_ascension: int = 0
var espectros_eliminados: int = 0
var energia_total_partida: float = 0.0
# Snapshot de ecos al iniciar la run (para calcular ecos ganados en esa run).
var ecos_inicio_partida: int = 0

# ═══════════════════════════════════════════════════
# SISTEMA DE INTERÉS (DOC_B)
# Bases ÚNICAS del interés — MejoraManager y MejoraCard leen estas
# constantes (antes estaban duplicadas y desincronizables).
# Nerf 2026-06: 2.5%→2% y cap 3000→1000; el bucle de bonificación
# disparaba la energía y trivializaba el mid-game.
# ═══════════════════════════════════════════════════
const TASA_INTERES_BASE: float = 0.02
const CAP_INTERES_BASE: float = 1000.0

var tasa_interes: float = TASA_INTERES_BASE   # mejorable hasta 3.5%
var cap_interes: float = CAP_INTERES_BASE     # mejorable hasta 4000

func _ready() -> void:
	_cargar_datos()

# ── Bonus pasivos del Laboratorio (investigaciones completadas) ──
func _lab(id: String) -> float:
	var lab := get_node_or_null("/root/Laboratorio")
	if lab:
		return lab.get_bonus(id)
	return 0.0

func iniciar_partida() -> void:
	# Lab "arranque_energizado": energía inicial extra.
	energia = 50.0 + _lab("arranque_energizado")
	numero_ascension = 0
	espectros_eliminados = 0
	energia_total_partida = 0.0
	ecos_inicio_partida = ecos  # snapshot para calcular ecos ganados al final
	# ✅ Resetear interés al reiniciar (ecos y fragmentos NO se resetean)
	tasa_interes = TASA_INTERES_BASE
	cap_interes = CAP_INTERES_BASE
	recursos_actualizados.emit()
	ascension_cambiada.emit(0)

func añadir_energia(cantidad: float) -> void:
	energia += cantidad
	energia_total_partida += cantidad
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
	# Recompensa base + bonus de la mejora "energia_ascension".
	var bonus_energia := MejoraManager.get_valor("energia_ascension")
	añadir_energia(10.0 + float(numero_ascension) + bonus_energia)
	# Mejora "ecos_ascension": ecos al completar cada ascensión.
	var ecos_asc := int(MejoraManager.get_valor("ecos_ascension"))
	if ecos_asc > 0:
		añadir_ecos(ecos_asc)

# ═══════════════════════════════════════════════════
# SISTEMA DE INTERÉS
# ═══════════════════════════════════════════════════
func calcular_interes() -> float:
	# Lab "interes_compuesto": tasa extra permanente.
	var interes = energia * (tasa_interes + _lab("interes_compuesto"))
	return min(interes, cap_interes)

func aplicar_interes() -> void:
	var interes_ganado = calcular_interes()
	if interes_ganado > 0.5:  # Solo si es significativo
		añadir_energia(interes_ganado)

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
	espectro_eliminado.emit()
	# Cuenta el kill para la recarga del disparo especial (si hay Commander activo).
	Sistemadisparosespeciales.registrar_kill_enemigo()

	var recompensa = float(datos.get("recompensa", 5))
	# Mejora "energia_espectro": energía extra por cada enemigo destruido.
	recompensa += MejoraManager.get_valor("energia_espectro")
	# Lab "extraccion_optimizada": % de energía extra por enemigo.
	recompensa *= 1.0 + _lab("extraccion_optimizada")
	var posicion = datos.get("posicion", Vector2.ZERO)

	añadir_energia(recompensa)

	# Mejora "ecos_rapido": probabilidad de un eco extra por enemigo.
	# Lab "resonancia_ecos": probabilidad extra permanente.
	var prob_eco := MejoraManager.get_valor("ecos_rapido") + _lab("resonancia_ecos")
	if prob_eco > 0.0 and randf() < prob_eco:
		ecos += 1
		guardar_datos()
		ecos_obtenidos.emit(1, posicion)
		ecos_actualizados.emit()
		recursos_actualizados.emit()

	if espectros_eliminados % 5 == 0:
		var ecos_ganados = obtener_ecos_por_5_muertes()
		ecos += ecos_ganados
		guardar_datos()
		recursos_actualizados.emit()
		ecos_actualizados.emit()
		ecos_obtenidos.emit(ecos_ganados, posicion)

func añadir_ecos(cantidad: int) -> void:
	# Suma ecos directamente (recompensas de logros, Commander, etc.).
	ecos += cantidad
	guardar_datos()
	recursos_actualizados.emit()
	ecos_actualizados.emit()

func añadir_fragmentos(cantidad: int) -> void:
	fragmentos += cantidad
	guardar_datos()
	recursos_actualizados.emit()
	fragmentos_actualizados.emit()

func gastar_ecos(cantidad: int) -> bool:
	if ecos >= cantidad:
		ecos -= cantidad
		guardar_datos()
		recursos_actualizados.emit()
		ecos_actualizados.emit()
		return true
	return false

func gastar_fragmentos(cantidad: int) -> bool:
	if fragmentos >= cantidad:
		fragmentos -= cantidad
		guardar_datos()
		recursos_actualizados.emit()
		fragmentos_actualizados.emit()
		return true
	return false

# ── Guardado ─────────────────────────────────────────
func guardar_datos() -> void:
	var file = FileAccess.open("user://economia.save", FileAccess.WRITE)
	if file:
		file.store_var({"ecos": ecos, "fragmentos": fragmentos})
		file.close()

func _cargar_datos() -> void:
	if FileAccess.file_exists("user://economia.save"):
		var file = FileAccess.open("user://economia.save", FileAccess.READ)
		if file:
			var data = file.get_var()
			if data is Dictionary:
				ecos = data.get("ecos", 0)
				fragmentos = data.get("fragmentos", 0)
			file.close()
