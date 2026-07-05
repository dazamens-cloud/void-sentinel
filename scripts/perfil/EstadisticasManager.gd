extends Node
# ═══════════════════════════════════════════════════
# ESTADISTICAS MANAGER — Void Sentinel
# Contadores PERSISTENTES del jugador (acumulados entre partidas) y
# sistema de LOGROS POR NIVELES (tiers): un mismo logro con varios
# escalones cada vez más difíciles y con mayor recompensa en ecos.
#
# Los contadores se alimentan de señales de Economia. Se persisten en
# user://estadisticas.save (en fin de partida y al reclamar logros).
# ═══════════════════════════════════════════════════

signal logros_actualizados
signal estadisticas_actualizadas

# ── Contadores persistentes ──────────────────────────
var kills_total: int = 0
var mejor_ascension: int = 0
var partidas_jugadas: int = 0

# ── Última run (para banner HomeScreen) ───────────────
var ultima_ascension: int = 0
var ultimo_kills: int = 0
var ultimos_ecos: int = 0
var ultima_causa: String = ""

# ── Logros por niveles ───────────────────────────────
# Cada logro mide un "stat" contra una lista de "tiers" (objetivo creciente
# + recompensa creciente). El jugador reclama un tier cuando lo alcanza y
# se desbloquea el siguiente. "desc_fmt" usa %s para el objetivo del tier.
const LOGROS := {
	"cazador": {
		"nombre": "Cazador",
		"stat": "kills_total",
		"desc_fmt": "Elimina %s enemigos",
		"tiers": [
			{"objetivo": 100,   "reward": 100},
			{"objetivo": 1000,  "reward": 300},
			{"objetivo": 10000, "reward": 1000},
			{"objetivo": 50000, "reward": 3000},
		],
	},
	"ascendido": {
		"nombre": "Ascendido",
		"stat": "mejor_ascension",
		"desc_fmt": "Alcanza la Ascensión %s",
		"tiers": [
			{"objetivo": 5,   "reward": 100},
			{"objetivo": 25,  "reward": 500},
			{"objetivo": 50,  "reward": 2000},
			{"objetivo": 100, "reward": 5000},
		],
	},
	"persistente": {
		"nombre": "Persistente",
		"stat": "partidas_jugadas",
		"desc_fmt": "Juega %s partidas",
		"tiers": [
			{"objetivo": 5,   "reward": 50},
			{"objetivo": 25,  "reward": 200},
			{"objetivo": 100, "reward": 800},
		],
	},
}

# Estado dinámico (persistido): índice del último tier RECLAMADO por logro.
# -1 = ninguno reclamado todavía.
var _tier_reclamado: Dictionary = {}

# ═══════════════════════════════════════════════════
func _ready() -> void:
	for id in LOGROS.keys():
		_tier_reclamado[id] = -1
	cargar()
	# Engancha los contadores a los eventos de Economia.
	if Economia.has_signal("espectro_eliminado"):
		Economia.espectro_eliminado.connect(_on_espectro_eliminado)
	if Economia.has_signal("ascension_cambiada"):
		Economia.ascension_cambiada.connect(_on_ascension_cambiada)
	if Economia.has_signal("juego_terminado"):
		Economia.juego_terminado.connect(_on_juego_terminado)

# ── Hooks de eventos ─────────────────────────────────
func _on_espectro_eliminado() -> void:
	kills_total += 1
	estadisticas_actualizadas.emit()
	logros_actualizados.emit()

func _on_ascension_cambiada(numero: int) -> void:
	if numero > mejor_ascension:
		mejor_ascension = numero
		estadisticas_actualizadas.emit()
		logros_actualizados.emit()

func _on_juego_terminado(causa: String) -> void:
	partidas_jugadas += 1
	# Guardar datos de la última run para el banner del HomeScreen
	ultima_ascension = Economia.numero_ascension
	ultimo_kills     = Economia.espectros_eliminados
	ultimos_ecos     = Economia.ecos - Economia.ecos_inicio_partida
	ultima_causa     = causa
	guardar()
	estadisticas_actualizadas.emit()
	logros_actualizados.emit()

# ═══════════════════════════════════════════════════
# CONSULTAS DE ESTADÍSTICAS
# ═══════════════════════════════════════════════════
func get_stat(nombre: String) -> int:
	match nombre:
		"kills_total":      return kills_total
		"mejor_ascension":  return mejor_ascension
		"partidas_jugadas": return partidas_jugadas
	return 0

# ═══════════════════════════════════════════════════
# CONSULTAS DE LOGROS
# ═══════════════════════════════════════════════════
func ids_logros() -> Array:
	return LOGROS.keys()

func get_logro(id: String) -> Dictionary:
	return LOGROS.get(id, {})

func num_tiers(id: String) -> int:
	return LOGROS.get(id, {}).get("tiers", []).size()

# Índice del tier que el jugador está persiguiendo ahora (el primero sin
# reclamar). Si == num_tiers, ya reclamó todos.
func tier_actual_idx(id: String) -> int:
	return _tier_reclamado.get(id, -1) + 1

func todos_reclamados(id: String) -> bool:
	return tier_actual_idx(id) >= num_tiers(id)

# Nivel mostrado al jugador (1-based): cuántos tiers lleva reclamados.
func nivel_reclamado(id: String) -> int:
	return _tier_reclamado.get(id, -1) + 1

func objetivo_actual(id: String) -> int:
	if todos_reclamados(id):
		return LOGROS[id]["tiers"][num_tiers(id) - 1]["objetivo"]
	return LOGROS[id]["tiers"][tier_actual_idx(id)]["objetivo"]

func reward_actual(id: String) -> int:
	if todos_reclamados(id):
		return 0
	return LOGROS[id]["tiers"][tier_actual_idx(id)]["reward"]

# Progreso (0..1) hacia el tier actual.
func progreso_actual(id: String) -> float:
	var obj := objetivo_actual(id)
	if obj <= 0:
		return 1.0
	return clampf(float(get_stat(LOGROS[id]["stat"])) / float(obj), 0.0, 1.0)

func es_reclamable(id: String) -> bool:
	if todos_reclamados(id):
		return false
	return get_stat(LOGROS[id]["stat"]) >= objetivo_actual(id)

# Texto descriptivo del tier actual ("Elimina 1,000 enemigos").
func descripcion_actual(id: String) -> String:
	var obj := objetivo_actual(id)
	return LOGROS[id]["desc_fmt"] % _miles(obj)

# ═══════════════════════════════════════════════════
# RECLAMAR (suma ecos reales)
# ═══════════════════════════════════════════════════
func reclamar(id: String) -> bool:
	if not es_reclamable(id):
		return false
	var reward: int = reward_actual(id)
	Economia.añadir_ecos(reward)
	_tier_reclamado[id] = tier_actual_idx(id)
	guardar()
	logros_actualizados.emit()
	return true

# ═══════════════════════════════════════════════════
# PERSISTENCIA
# ═══════════════════════════════════════════════════
func guardar() -> void:
	var datos := {
		"kills_total": kills_total,
		"mejor_ascension": mejor_ascension,
		"partidas_jugadas": partidas_jugadas,
		"reclamados": _tier_reclamado,
		"ultima_ascension": ultima_ascension,
		"ultimo_kills": ultimo_kills,
		"ultimos_ecos": ultimos_ecos,
		"ultima_causa": ultima_causa,
	}
	var file = FileAccess.open("user://estadisticas.save", FileAccess.WRITE)
	if file:
		file.store_var(datos)
		file.close()

func cargar() -> void:
	if not FileAccess.file_exists("user://estadisticas.save"):
		return
	var file = FileAccess.open("user://estadisticas.save", FileAccess.READ)
	if not file:
		return
	var datos = file.get_var()
	file.close()
	if not datos is Dictionary:
		return
	kills_total = datos.get("kills_total", 0)
	mejor_ascension = datos.get("mejor_ascension", 0)
	partidas_jugadas = datos.get("partidas_jugadas", 0)
	ultima_ascension = datos.get("ultima_ascension", 0)
	ultimo_kills     = datos.get("ultimo_kills", 0)
	ultimos_ecos     = datos.get("ultimos_ecos", 0)
	ultima_causa     = datos.get("ultima_causa", "")
	var rec = datos.get("reclamados", {})
	for id in LOGROS.keys():
		_tier_reclamado[id] = rec.get(id, -1)

# Formatea un entero con separador de miles.
func _miles(n: int) -> String:
	var s := str(n)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
	return result
