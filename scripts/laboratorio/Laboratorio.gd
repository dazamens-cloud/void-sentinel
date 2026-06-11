extends Node
# ═══════════════════════════════════════════════════
# LABORATORIO — Investigaciones pasivas con timers reales (autoload).
#
# Sistema idle: el jugador invierte ECOS en investigaciones que tardan
# TIEMPO REAL en completarse (siguen avanzando con la app cerrada, vía
# Time.get_unix_time_from_system()). Cada nivel completado da un bonus
# pasivo permanente que consultan NexusStats / Economia / MejoraManager
# con get_bonus(id).
#
# - 1 slot de investigación base; +1 con la investigación "despertar_centinela".
# - Acelerar con FRAGMENTOS: completa la investigación al instante
#   (1 fragmento por minuto restante, mínimo 1).
# - Persistencia en user://laboratorio.save (niveles + activas).
# ═══════════════════════════════════════════════════

signal lab_actualizado
signal investigacion_completada(id: String, nivel: int)

const RUTA: String = "user://laboratorio.save"
const SLOTS_BASE: int = 1
const FACTOR_COSTE: float = 1.6      # coste en ecos × 1.6 por nivel
const FACTOR_DURACION: float = 1.5   # duración × 1.5 por nivel
const FRAGMENTOS_POR_MINUTO: float = 1.0  # coste de acelerar

# ── Catálogo de investigaciones ──────────────────────
# incremento = bonus que aporta CADA nivel (get_bonus = nivel × incremento).
# formato: "pct" (mostrar como %), "plano" (número directo), "slot".
const INVESTIGACIONES := {
	# ========== PRINCIPAL ==========
	"nucleo_sincronizado": {
		"nombre": "Núcleo Sincronizado",
		"categoria": "principal",
		"incremento": 0.02,
		"max_nivel": 10,
		"coste_base": 200,
		"duracion_base": 300.0,
		"formato": "pct",
		"descripcion": "Sincroniza el núcleo del Nexus: +2% de daño global por nivel."
	},
	"matriz_vital": {
		"nombre": "Matriz Vital",
		"categoria": "principal",
		"incremento": 0.02,
		"max_nivel": 10,
		"coste_base": 200,
		"duracion_base": 300.0,
		"formato": "pct",
		"descripcion": "Refuerza la matriz del Nexus: +2% de vida máxima por nivel."
	},
	"protocolo_eficiencia": {
		"nombre": "Protocolo de Eficiencia",
		"categoria": "principal",
		"incremento": 0.01,
		"max_nivel": 8,
		"coste_base": 400,
		"duracion_base": 900.0,
		"formato": "pct",
		"descripcion": "Optimiza el Workshop: las mejoras in-run cuestan 1% menos por nivel."
	},
	"despertar_centinela": {
		"nombre": "Despertar del Centinela",
		"categoria": "principal",
		"incremento": 1.0,
		"max_nivel": 1,
		"coste_base": 2000,
		"duracion_base": 3600.0,
		"formato": "slot",
		"descripcion": "Despierta un segundo núcleo de cálculo: +1 slot de investigación."
	},

	# ========== ATAQUE ==========
	"balistica_avanzada": {
		"nombre": "Balística Avanzada",
		"categoria": "ataque",
		"incremento": 0.01,
		"max_nivel": 5,
		"coste_base": 300,
		"duracion_base": 600.0,
		"formato": "pct",
		"descripcion": "Trayectorias optimizadas: +1% de probabilidad de crítico por nivel."
	},
	"nucleos_perforantes": {
		"nombre": "Núcleos Perforantes",
		"categoria": "ataque",
		"incremento": 0.10,
		"max_nivel": 10,
		"coste_base": 250,
		"duracion_base": 450.0,
		"formato": "pct",
		"descripcion": "Proyectiles endurecidos: +10% de daño crítico por nivel."
	},
	"condensadores_rapidos": {
		"nombre": "Condensadores Rápidos",
		"categoria": "ataque",
		"incremento": 0.01,
		"max_nivel": 10,
		"coste_base": 350,
		"duracion_base": 600.0,
		"formato": "pct",
		"descripcion": "Recarga acelerada: +1% de velocidad de ataque por nivel."
	},
	"sensores_largo_alcance": {
		"nombre": "Sensores de Largo Alcance",
		"categoria": "ataque",
		"incremento": 0.03,
		"max_nivel": 5,
		"coste_base": 250,
		"duracion_base": 450.0,
		"formato": "pct",
		"descripcion": "Amplía el radar del Nexus: +3% de rango de escaneo por nivel."
	},

	# ========== DEFENSA ==========
	"regeneracion_celular": {
		"nombre": "Regeneración Celular",
		"categoria": "defensa",
		"incremento": 0.3,
		"max_nivel": 10,
		"coste_base": 200,
		"duracion_base": 400.0,
		"formato": "plano",
		"descripcion": "Nanobots reparadores: +0.3 de regeneración por segundo por nivel."
	},
	"aleacion_reforzada": {
		"nombre": "Aleación Reforzada",
		"categoria": "defensa",
		"incremento": 0.01,
		"max_nivel": 8,
		"coste_base": 350,
		"duracion_base": 700.0,
		"formato": "pct",
		"descripcion": "Blindaje del casco: +1% de reducción de daño por nivel."
	},
	"condensador_escudo": {
		"nombre": "Condensador de Escudo",
		"categoria": "defensa",
		"incremento": 25.0,
		"max_nivel": 10,
		"coste_base": 300,
		"duracion_base": 500.0,
		"formato": "plano",
		"descripcion": "Células de energía extra: +25 de escudo máximo por nivel."
	},

	# ========== UTILIDAD ==========
	"extraccion_optimizada": {
		"nombre": "Extracción Optimizada",
		"categoria": "utilidad",
		"incremento": 0.03,
		"max_nivel": 10,
		"coste_base": 250,
		"duracion_base": 400.0,
		"formato": "pct",
		"descripcion": "Recolectores mejorados: +3% de energía por enemigo por nivel."
	},
	"resonancia_ecos": {
		"nombre": "Resonancia de Ecos",
		"categoria": "utilidad",
		"incremento": 0.005,
		"max_nivel": 10,
		"coste_base": 400,
		"duracion_base": 800.0,
		"formato": "pct",
		"descripcion": "Sintoniza el vacío: +0.5% de probabilidad de eco extra por nivel."
	},
	"interes_compuesto": {
		"nombre": "Interés Compuesto",
		"categoria": "utilidad",
		"incremento": 0.0005,
		"max_nivel": 10,
		"coste_base": 350,
		"duracion_base": 700.0,
		"formato": "pct",
		"descripcion": "Algoritmos financieros: +0.05% de tasa de interés por nivel."
	},
	"arranque_energizado": {
		"nombre": "Arranque Energizado",
		"categoria": "utilidad",
		"incremento": 25.0,
		"max_nivel": 10,
		"coste_base": 200,
		"duracion_base": 300.0,
		"formato": "plano",
		"descripcion": "Reservas precargadas: +25 de energía inicial por nivel."
	},
}

# ── Estado dinámico (persistido) ─────────────────────
# id → nivel COMPLETADO (los bonus solo cuentan niveles terminados).
var _niveles: Dictionary = {}
# Investigaciones en curso: [{ "id": String, "inicio": int, "fin": int }] (unix).
var _activas: Array = []

var _timer_check: Timer


func _ready() -> void:
	# El Lab cuenta tiempo real: debe seguir chequeando aunque el árbol
	# esté pausado (menú de pausa, tutorial, game over).
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in INVESTIGACIONES.keys():
		_niveles[id] = 0
	_cargar()
	# Completa lo que terminó con la app cerrada (progreso offline).
	_chequear_completadas()
	# Chequeo periódico mientras la app está abierta.
	_timer_check = Timer.new()
	_timer_check.wait_time = 1.0
	_timer_check.timeout.connect(_chequear_completadas)
	add_child(_timer_check)
	_timer_check.start()


# ═══════════════════════════════════════════════════
# CONSULTAS
# ═══════════════════════════════════════════════════
func ids_investigaciones() -> Array:
	return INVESTIGACIONES.keys()

func get_data(id: String) -> Dictionary:
	return INVESTIGACIONES.get(id, {})

func get_nivel(id: String) -> int:
	return _niveles.get(id, 0)

func get_max_nivel(id: String) -> int:
	return INVESTIGACIONES.get(id, {}).get("max_nivel", 0)

func nivel_maximo_alcanzado(id: String) -> bool:
	return get_nivel(id) >= get_max_nivel(id)

# Bonus pasivo acumulado de los niveles COMPLETADOS.
# Es lo que consultan NexusStats / Economia / MejoraManager.
func get_bonus(id: String) -> float:
	var data: Dictionary = INVESTIGACIONES.get(id, {})
	if data.is_empty():
		return 0.0
	return get_nivel(id) * data.get("incremento", 0.0)

func get_slots() -> int:
	return SLOTS_BASE + get_nivel("despertar_centinela")

func slots_libres() -> int:
	return get_slots() - _activas.size()

# Coste en ECOS del siguiente nivel.
func get_coste(id: String) -> int:
	var data: Dictionary = INVESTIGACIONES.get(id, {})
	if data.is_empty():
		return 0
	return int(data["coste_base"] * pow(FACTOR_COSTE, get_nivel(id)))

# Duración en segundos del siguiente nivel.
func get_duracion(id: String) -> float:
	var data: Dictionary = INVESTIGACIONES.get(id, {})
	if data.is_empty():
		return 0.0
	return data["duracion_base"] * pow(FACTOR_DURACION, get_nivel(id))

func esta_activa(id: String) -> bool:
	for inv in _activas:
		if inv["id"] == id:
			return true
	return false

# Segundos restantes de una investigación activa (0 si no está activa).
func tiempo_restante(id: String) -> int:
	var ahora := int(Time.get_unix_time_from_system())
	for inv in _activas:
		if inv["id"] == id:
			return maxi(0, inv["fin"] - ahora)
	return 0

# Progreso 0..1 de una investigación activa.
func progreso(id: String) -> float:
	var ahora := int(Time.get_unix_time_from_system())
	for inv in _activas:
		if inv["id"] == id:
			var total: int = inv["fin"] - inv["inicio"]
			if total <= 0:
				return 1.0
			return clampf(float(ahora - inv["inicio"]) / float(total), 0.0, 1.0)
	return 0.0

func puede_investigar(id: String) -> bool:
	if not INVESTIGACIONES.has(id):
		return false
	if nivel_maximo_alcanzado(id) or esta_activa(id):
		return false
	if slots_libres() <= 0:
		return false
	return Economia.ecos >= get_coste(id)


# ═══════════════════════════════════════════════════
# ACCIONES
# ═══════════════════════════════════════════════════
func iniciar(id: String) -> bool:
	if not puede_investigar(id):
		return false
	if not Economia.gastar_ecos(get_coste(id)):
		return false
	var ahora := int(Time.get_unix_time_from_system())
	_activas.append({
		"id": id,
		"inicio": ahora,
		"fin": ahora + int(get_duracion(id)),
	})
	_guardar()
	lab_actualizado.emit()
	return true

# Coste en FRAGMENTOS de completar ya una investigación activa.
func coste_acelerar(id: String) -> int:
	var restante := tiempo_restante(id)
	if restante <= 0:
		return 0
	return maxi(1, int(ceil(restante / 60.0 * FRAGMENTOS_POR_MINUTO)))

func acelerar(id: String) -> bool:
	if not esta_activa(id):
		return false
	var coste := coste_acelerar(id)
	if coste > 0 and not Economia.gastar_fragmentos(coste):
		return false
	# Adelanta el fin a "ahora" y deja que el chequeo la complete.
	for inv in _activas:
		if inv["id"] == id:
			inv["fin"] = int(Time.get_unix_time_from_system())
			break
	_chequear_completadas()
	return true

# Cancela una investigación en curso (sin reembolso del tiempo; devuelve
# los ecos para no castigar el toque accidental).
func cancelar(id: String) -> bool:
	for i in range(_activas.size()):
		if _activas[i]["id"] == id:
			_activas.remove_at(i)
			Economia.añadir_ecos(get_coste(id))
			_guardar()
			lab_actualizado.emit()
			return true
	return false


# ═══════════════════════════════════════════════════
# CHEQUEO DE FINALIZACIÓN (timer 1s + arranque)
# ═══════════════════════════════════════════════════
func _chequear_completadas() -> void:
	var ahora := int(Time.get_unix_time_from_system())
	var completadas: Array = []
	for inv in _activas:
		if ahora >= inv["fin"]:
			completadas.append(inv)
	if completadas.is_empty():
		return
	for inv in completadas:
		_activas.erase(inv)
		var id: String = inv["id"]
		_niveles[id] = mini(get_nivel(id) + 1, get_max_nivel(id))
		print("🔬 Investigación completada: ", INVESTIGACIONES[id]["nombre"], " → nivel ", _niveles[id])
		investigacion_completada.emit(id, _niveles[id])
		_reaplicar_efecto(id)
	_guardar()
	lab_actualizado.emit()

# La mayoría de bonus se consultan en caliente (cada disparo/kill), pero la
# vida máxima se materializa en NexusStats.salud_base: hay que recalcularla
# si "matriz_vital" sube en mitad de una partida.
func _reaplicar_efecto(id: String) -> void:
	if id == "matriz_vital":
		NexusStats.set_mult_salud(NexusStats.mult_salud)


# ═══════════════════════════════════════════════════
# PERSISTENCIA
# ═══════════════════════════════════════════════════
func _guardar() -> void:
	var datos := {
		"niveles": _niveles,
		"activas": _activas,
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
	var niv = datos.get("niveles", {})
	for id in INVESTIGACIONES.keys():
		_niveles[id] = niv.get(id, 0)
	_activas = []
	for inv in datos.get("activas", []):
		if inv is Dictionary and INVESTIGACIONES.has(inv.get("id", "")):
			_activas.append(inv)


# ═══════════════════════════════════════════════════
# HELPERS DE PRESENTACIÓN (para la UI)
# ═══════════════════════════════════════════════════
# Texto del bonus de un nivel dado ("+2%", "+0.3", "+1 slot").
func formatear_bonus(id: String, niveles_n: int) -> String:
	var data: Dictionary = INVESTIGACIONES.get(id, {})
	if data.is_empty():
		return ""
	var valor: float = niveles_n * data.get("incremento", 0.0)
	match data.get("formato", "plano"):
		"pct":
			return "+%s%%" % _trim(valor * 100.0)
		"slot":
			return "+%d slot" % int(valor)
		_:
			return "+%s" % _trim(valor)

# Duración legible ("2h 30m", "45m", "30s").
static func formatear_tiempo(segundos: int) -> String:
	if segundos >= 3600:
		var h := int(segundos / 3600.0)
		var m := int((segundos % 3600) / 60.0)
		return "%dh %02dm" % [h, m]
	if segundos >= 60:
		var m2 := int(segundos / 60.0)
		var s := segundos % 60
		return "%dm %02ds" % [m2, s]
	return "%ds" % segundos

# Quita decimales innecesarios (2.0 → "2", 0.5 → "0.5").
static func _trim(v: float) -> String:
	if absf(v - roundf(v)) < 0.001:
		return str(int(roundf(v)))
	return ("%.1f" % v) if absf(v * 10.0 - roundf(v * 10.0)) < 0.01 else "%.2f" % v
