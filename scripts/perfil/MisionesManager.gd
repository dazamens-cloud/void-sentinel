extends Node
# ═══════════════════════════════════════════════════
# MISIONES MANAGER — Misiones diarias de Void Sentinel (autoload).
#
# Cada día (fecha local) se eligen 3 misiones del POOL con semilla
# derivada de la fecha (todos los jugadores ven las mismas ese día y
# no se pueden re-rollear reiniciando). El progreso se alimenta de las
# señales de Economia y se persiste en user://misiones.save.
#
# Al cambiar de día las misiones se regeneran (progreso y reclamos a 0).
# Las recompensas se reclaman a mano (ecos o fragmentos).
# ═══════════════════════════════════════════════════

signal misiones_actualizadas

const RUTA: String = "user://misiones.save"
const MISIONES_POR_DIA: int = 3

# ── Pool de misiones ─────────────────────────────────
# stat: contador DIARIO que la alimenta ("kills", "ascensiones",
# "partidas", "ecos"). recompensa_tipo: "ecos" | "fragmentos".
const POOL := {
	"kills_50": {
		"descripcion": "Elimina 50 espectros",
		"stat": "kills", "objetivo": 50,
		"recompensa": 150, "recompensa_tipo": "ecos",
	},
	"kills_200": {
		"descripcion": "Elimina 200 espectros",
		"stat": "kills", "objetivo": 200,
		"recompensa": 400, "recompensa_tipo": "ecos",
	},
	"asc_10": {
		"descripcion": "Completa 10 ascensiones",
		"stat": "ascensiones", "objetivo": 10,
		"recompensa": 200, "recompensa_tipo": "ecos",
	},
	"asc_25": {
		"descripcion": "Completa 25 ascensiones",
		"stat": "ascensiones", "objetivo": 25,
		"recompensa": 450, "recompensa_tipo": "ecos",
	},
	"partidas_2": {
		"descripcion": "Juega 2 partidas",
		"stat": "partidas", "objetivo": 2,
		"recompensa": 150, "recompensa_tipo": "ecos",
	},
	"partidas_5": {
		"descripcion": "Juega 5 partidas",
		"stat": "partidas", "objetivo": 5,
		"recompensa": 350, "recompensa_tipo": "ecos",
	},
	"ecos_100": {
		"descripcion": "Recoge 100 ecos",
		"stat": "ecos", "objetivo": 100,
		"recompensa": 25, "recompensa_tipo": "fragmentos",
	},
	"ecos_300": {
		"descripcion": "Recoge 300 ecos",
		"stat": "ecos", "objetivo": 300,
		"recompensa": 60, "recompensa_tipo": "fragmentos",
	},
}

# ── Estado (persistido) ──────────────────────────────
var _fecha: String = ""              # "YYYY-MM-DD" de las misiones vigentes
var _activas: Array = []             # ids de las 3 misiones del día
var _progreso: Dictionary = {}       # stat diario → cantidad acumulada hoy
var _reclamadas: Dictionary = {}     # id → bool


func _ready() -> void:
	_cargar()
	_chequear_reset()
	# Alimentar los contadores diarios desde las señales de Economia.
	Economia.espectro_eliminado.connect(func(): _sumar("kills", 1))
	Economia.ascension_cambiada.connect(_on_ascension)
	Economia.juego_terminado.connect(func(_c): _sumar("partidas", 1))
	Economia.ecos_obtenidos.connect(func(cantidad, _pos): _sumar("ecos", cantidad))


func _on_ascension(numero: int) -> void:
	# Solo cuentan los avances (numero 0 es el reset de iniciar_partida).
	if numero > 0:
		_sumar("ascensiones", 1)


func _sumar(stat: String, cantidad: int) -> void:
	_chequear_reset()
	_progreso[stat] = _progreso.get(stat, 0) + cantidad
	_guardar()
	misiones_actualizadas.emit()


# ═══════════════════════════════════════════════════
# RESET DIARIO
# ═══════════════════════════════════════════════════
static func _hoy() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]

func _chequear_reset() -> void:
	var hoy := _hoy()
	if _fecha == hoy and _activas.size() == MISIONES_POR_DIA:
		return
	_fecha = hoy
	_activas = _elegir_misiones(hoy)
	_progreso = {}
	_reclamadas = {}
	_guardar()
	misiones_actualizadas.emit()

# Selección determinista por fecha: misma terna para todo el día.
func _elegir_misiones(fecha: String) -> Array:
	var ids := POOL.keys()
	ids.sort()  # orden estable antes de barajar con semilla
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(fecha)
	# Fisher-Yates con el rng sembrado.
	for i in range(ids.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = ids[i]
		ids[i] = ids[j]
		ids[j] = tmp
	return ids.slice(0, MISIONES_POR_DIA)


# ═══════════════════════════════════════════════════
# CONSULTAS (para la UI)
# ═══════════════════════════════════════════════════
func ids_activas() -> Array:
	_chequear_reset()
	return _activas

func get_data(id: String) -> Dictionary:
	return POOL.get(id, {})

func get_progreso(id: String) -> int:
	var data: Dictionary = POOL.get(id, {})
	if data.is_empty():
		return 0
	return mini(_progreso.get(data["stat"], 0), data["objetivo"])

func progreso_frac(id: String) -> float:
	var data: Dictionary = POOL.get(id, {})
	if data.is_empty() or data["objetivo"] <= 0:
		return 0.0
	return clampf(float(get_progreso(id)) / float(data["objetivo"]), 0.0, 1.0)

func completada(id: String) -> bool:
	var data: Dictionary = POOL.get(id, {})
	return not data.is_empty() and get_progreso(id) >= data["objetivo"]

func reclamada(id: String) -> bool:
	return _reclamadas.get(id, false)

func es_reclamable(id: String) -> bool:
	return completada(id) and not reclamada(id)

# Segundos hasta la medianoche local (para el contador "se renuevan en...").
func segundos_para_reset() -> int:
	var ahora := Time.get_datetime_dict_from_system()
	return maxi(0, 86400 - (int(ahora["hour"]) * 3600 + int(ahora["minute"]) * 60 + int(ahora["second"])))


# ═══════════════════════════════════════════════════
# RECLAMAR
# ═══════════════════════════════════════════════════
func reclamar(id: String) -> bool:
	_chequear_reset()
	if not es_reclamable(id):
		return false
	var data: Dictionary = POOL[id]
	if data["recompensa_tipo"] == "fragmentos":
		Economia.añadir_fragmentos(data["recompensa"])
	else:
		Economia.añadir_ecos(data["recompensa"])
	_reclamadas[id] = true
	_guardar()
	misiones_actualizadas.emit()
	return true


# ═══════════════════════════════════════════════════
# PERSISTENCIA
# ═══════════════════════════════════════════════════
func _guardar() -> void:
	var datos := {
		"fecha": _fecha,
		"activas": _activas,
		"progreso": _progreso,
		"reclamadas": _reclamadas,
	}
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	if f:
		f.store_var(datos)
		f.close()

func _cargar() -> void:
	if not FileAccess.file_exists(RUTA):
		return
	var f := FileAccess.open(RUTA, FileAccess.READ)
	if not f:
		return
	var datos = f.get_var()
	f.close()
	if not (datos is Dictionary):
		return
	_fecha = datos.get("fecha", "")
	_activas = datos.get("activas", [])
	_progreso = datos.get("progreso", {})
	_reclamadas = datos.get("reclamadas", {})
