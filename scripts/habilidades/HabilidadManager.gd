extends Node
# ═══════════════════════════════════════════════════
# HABILIDAD MANAGER — Void Sentinel
# Sistema de las 8 habilidades manuales activas (la Forja).
#
# Ref. de diseño: VoidSentinel_Habilidades_Manuales.docx (v1.0).
#
# Esta es la capa de INFRAESTRUCTURA (datos + meta-progresión):
#   - Catálogo de las 8 habilidades con valores base y líneas de mejora.
#   - Desbloqueo y mejora con FRAGMENTOS (Economia).
#   - Selección de habilidades activas para la partida (sin límite).
#   - Persistencia en user://habilidades.save.
# El GAMEPLAY (efecto real de cada habilidad in-run) se implementa aparte.
#
# ⚠ Los costes de desbloqueo/mejora NO están en el documento de diseño:
#   son PLACEHOLDERS ajustables (constantes COSTE_* y campo coste_base).
# ═══════════════════════════════════════════════════

signal habilidad_cambiada          # desbloqueo o mejora
signal seleccion_cambiada          # activar/desactivar para la partida

# Factor de escalado del coste de mejora por nivel ya comprado.
const FACTOR_COSTE_MEJORA := 1.6

# Catálogo. Cada habilidad mezcla datos ESTÁTICOS (nombre, base, definición
# de mejoras) con ESTADO dinámico que se persiste: "desbloqueada", "activa"
# y el "nivel" de cada mejora.
#
# Cada mejora:
#   afecta:     parámetro de "base" (o "cooldown") que modifica; "" si es feature.
#   incremento: delta por nivel aplicado al parámetro.
#   max_nivel:  tope (derivado de los límites del documento).
#   coste_base: placeholder de coste en fragmentos del primer nivel.
#   nivel:      estado dinámico (persistido).
var habilidades: Dictionary = {
	# ═══════════ OFENSIVAS ═══════════
	"enjambre": {
		"nombre": "Enjambre de Fragmentos",
		"tipo": "ofensiva",
		"descripcion": "Libera una tormenta de proyectiles en todas las direcciones. Ideal para limpiar la pantalla cuando estás rodeado.",
		"coste_desbloqueo": 0,            # inicial (gratis)
		"desbloqueada": true,
		"activa": true,
		"cooldown_base": 18.0,
		"base": {"proyectiles": 24, "danio_pct": 0.40, "velocidad": 400.0, "penetracion": 1},
		"mejoras": {
			"proyectiles": {"nombre": "Más proyectiles", "afecta": "proyectiles", "incremento": 4, "max_nivel": 6, "coste_base": 60, "nivel": 0},
			"danio":       {"nombre": "Daño",            "afecta": "danio_pct",   "incremento": 0.10, "max_nivel": 10, "coste_base": 50, "nivel": 0},
			"penetracion": {"nombre": "Penetración",     "afecta": "penetracion", "incremento": 1, "max_nivel": 3, "coste_base": 70, "nivel": 0},
			"cooldown":    {"nombre": "Cooldown",        "afecta": "cooldown",    "incremento": -1.0, "max_nivel": 8, "coste_base": 80, "nivel": 0},
		},
	},
	"singularidad": {
		"nombre": "Singularidad",
		"tipo": "ofensiva",
		"descripcion": "Crea un agujero negro temporal que atrae y aplasta a los enemigos. Perfecta contra grupos compactos.",
		"coste_desbloqueo": 350,
		"desbloqueada": false,
		"activa": false,
		"cooldown_base": 25.0,
		"base": {"fuerza": 8.0, "danio_implosion": 1.50, "danio_explosion": 0.80, "radio_explosion": 80.0, "duracion": 3.0},
		"mejoras": {
			"fuerza":    {"nombre": "Atracción",     "afecta": "fuerza",          "incremento": 2.0, "max_nivel": 10, "coste_base": 70, "nivel": 0},
			"implosion": {"nombre": "Daño implosión", "afecta": "danio_implosion", "incremento": 0.25, "max_nivel": 10, "coste_base": 80, "nivel": 0},
			"duracion":  {"nombre": "Duración",      "afecta": "duracion",        "incremento": 0.5, "max_nivel": 4, "coste_base": 90, "nivel": 0},
			"cooldown":  {"nombre": "Cooldown",      "afecta": "cooldown",        "incremento": -2.0, "max_nivel": 5, "coste_base": 100, "nivel": 0},
		},
	},
	"pulso_emp": {
		"nombre": "Pulso EMP",
		"tipo": "ofensiva",
		"descripcion": "Pulso electromagnético que arrasa escudos y armaduras. Su objetivo ideal son los enemigos defensivos.",
		"coste_desbloqueo": 120,
		"desbloqueada": false,
		"activa": false,
		"cooldown_base": 20.0,
		"base": {"danio_pct": 1.20, "mult_escudo": 2.5, "mult_armadura": 1.8, "stun_escudo": 4.0},
		"mejoras": {
			"danio":       {"nombre": "Daño base",     "afecta": "danio_pct",    "incremento": 0.20, "max_nivel": 10, "coste_base": 55, "nivel": 0},
			"vs_escudo":   {"nombre": "Vs escudo",     "afecta": "mult_escudo",  "incremento": 0.30, "max_nivel": 10, "coste_base": 70, "nivel": 0},
			"stun":        {"nombre": "Duración stun", "afecta": "stun_escudo",  "incremento": 1.0, "max_nivel": 5, "coste_base": 65, "nivel": 0},
			"cooldown":    {"nombre": "Cooldown",      "afecta": "cooldown",     "incremento": -1.5, "max_nivel": 5, "coste_base": 80, "nivel": 0},
		},
	},
	"detonacion": {
		"nombre": "Detonación en Cadena",
		"tipo": "ofensiva",
		"descripcion": "El impacto detona al enemigo y propaga la explosión a los cercanos en reacción en cadena.",
		"coste_desbloqueo": 250,
		"desbloqueada": false,
		"activa": false,
		"cooldown_base": 22.0,
		"base": {"danio_pct": 2.00, "radio": 100.0, "saltos": 3, "reduccion": 0.20, "marca": 5.0},
		"mejoras": {
			"danio":     {"nombre": "Daño explosión", "afecta": "danio_pct",  "incremento": 0.30, "max_nivel": 10, "coste_base": 60, "nivel": 0},
			"radio":     {"nombre": "Radio",          "afecta": "radio",      "incremento": 15.0, "max_nivel": 10, "coste_base": 55, "nivel": 0},
			"saltos":    {"nombre": "Saltos cadena",  "afecta": "saltos",     "incremento": 1, "max_nivel": 3, "coste_base": 90, "nivel": 0},
			"reduccion": {"nombre": "Menos pérdida",  "afecta": "reduccion",  "incremento": -0.05, "max_nivel": 4, "coste_base": 75, "nivel": 0},
			"cooldown":  {"nombre": "Cooldown",       "afecta": "cooldown",   "incremento": -2.0, "max_nivel": 5, "coste_base": 85, "nivel": 0},
		},
	},
	# ═══════════ DEFENSIVAS ═══════════
	"escudo_colapso": {
		"nombre": "Escudo de Colapso",
		"tipo": "defensiva",
		"descripcion": "Barrera de energía que absorbe el daño entrante durante unos segundos. Úsala de forma preventiva.",
		"coste_desbloqueo": 120,
		"desbloqueada": false,
		"activa": false,
		"cooldown_base": 30.0,
		"base": {"absorcion_pct": 3.00, "duracion": 6.0},
		"mejoras": {
			"absorcion": {"nombre": "Absorción", "afecta": "absorcion_pct", "incremento": 0.50, "max_nivel": 10, "coste_base": 65, "nivel": 0},
			"duracion":  {"nombre": "Duración",  "afecta": "duracion",      "incremento": 1.0, "max_nivel": 4, "coste_base": 70, "nivel": 0},
			"cooldown":  {"nombre": "Cooldown",  "afecta": "cooldown",      "incremento": -2.0, "max_nivel": 6, "coste_base": 80, "nivel": 0},
			"rebote":    {"nombre": "Rebote (al romper)", "afecta": "", "incremento": 0, "max_nivel": 1, "coste_base": 150, "nivel": 0},
		},
	},
	"protocolo": {
		"nombre": "Protocolo de Emergencia",
		"tipo": "defensiva",
		"descripcion": "Reparación instantánea: restaura un porcentaje de tu vida máxima. Para cuando el vacío te gana.",
		"coste_desbloqueo": 200,
		"desbloqueada": false,
		"activa": false,
		"cooldown_base": 35.0,
		"base": {"curacion_pct": 0.25},
		"mejoras": {
			"curacion":     {"nombre": "Curación",   "afecta": "curacion_pct", "incremento": 0.05, "max_nivel": 5, "coste_base": 70, "nivel": 0},
			"cooldown":     {"nombre": "Cooldown",   "afecta": "cooldown",     "incremento": -2.0, "max_nivel": 7, "coste_base": 80, "nivel": 0},
			"regen_pasiva": {"nombre": "Regen pasiva", "afecta": "", "incremento": 0, "max_nivel": 1, "coste_base": 150, "nivel": 0},
			"doble_pulso":  {"nombre": "Doble pulso",  "afecta": "", "incremento": 0, "max_nivel": 1, "coste_base": 180, "nivel": 0},
		},
	},
	"campo_tiempo": {
		"nombre": "Campo de Tiempo",
		"tipo": "defensiva",
		"descripcion": "Distorsiona el tiempo: ralentiza a todos los enemigos en pantalla. Tiempo para respirar y reposicionar.",
		"coste_desbloqueo": 180,
		"desbloqueada": false,
		"activa": false,
		"cooldown_base": 28.0,
		"base": {"slow_pct": 0.25, "duracion": 5.0},
		"mejoras": {
			"slow":         {"nombre": "Intensidad", "afecta": "slow_pct", "incremento": -0.05, "max_nivel": 3, "coste_base": 70, "nivel": 0},
			"duracion":     {"nombre": "Duración",   "afecta": "duracion", "incremento": 1.0, "max_nivel": 4, "coste_base": 75, "nivel": 0},
			"cooldown":     {"nombre": "Cooldown",   "afecta": "cooldown", "incremento": -2.0, "max_nivel": 6, "coste_base": 80, "nivel": 0},
			"danio_temporal": {"nombre": "Daño temporal", "afecta": "", "incremento": 0, "max_nivel": 1, "coste_base": 150, "nivel": 0},
		},
	},
	"manto": {
		"nombre": "Manto de Interferencia",
		"tipo": "defensiva",
		"descripcion": "Corrompe el targeting enemigo: dejan de dispararte y sus proyectiles se desvían durante unos segundos.",
		"coste_desbloqueo": 280,
		"desbloqueada": false,
		"activa": false,
		"cooldown_base": 32.0,
		"base": {"duracion": 4.0},
		"mejoras": {
			"duracion": {"nombre": "Duración", "afecta": "duracion", "incremento": 1.0, "max_nivel": 4, "coste_base": 70, "nivel": 0},
			"cooldown": {"nombre": "Cooldown", "afecta": "cooldown", "incremento": -2.0, "max_nivel": 6, "coste_base": 80, "nivel": 0},
			"reflejo":  {"nombre": "Reflejo", "afecta": "", "incremento": 0, "max_nivel": 1, "coste_base": 170, "nivel": 0},
		},
	},
}

# ═══════════════════════════════════════════════════
func _ready() -> void:
	cargar()

# ═══════════════════════════════════════════════════
# CONSULTAS
# ═══════════════════════════════════════════════════
func get_hab(id: String) -> Dictionary:
	return habilidades.get(id, {})

func ids_por_tipo(tipo: String) -> Array:
	var res: Array = []
	for id in habilidades.keys():
		if habilidades[id].get("tipo", "") == tipo:
			res.append(id)
	return res

func esta_desbloqueada(id: String) -> bool:
	return habilidades.get(id, {}).get("desbloqueada", false)

func esta_activa(id: String) -> bool:
	return habilidades.get(id, {}).get("activa", false)

func get_activas() -> Array:
	var res: Array = []
	for id in habilidades.keys():
		if esta_desbloqueada(id) and esta_activa(id):
			res.append(id)
	return res

# Nivel actual de una línea de mejora.
func get_nivel(id: String, mid: String) -> int:
	return habilidades.get(id, {}).get("mejoras", {}).get(mid, {}).get("nivel", 0)

func es_max_mejora(id: String, mid: String) -> bool:
	var m = habilidades.get(id, {}).get("mejoras", {}).get(mid, {})
	if m.is_empty():
		return true
	return m.get("nivel", 0) >= m.get("max_nivel", 0)

# ¿Una feature desbloocable (toggle) está activada?
func tiene_feature(id: String, mid: String) -> bool:
	return get_nivel(id, mid) > 0

# ═══════════════════════════════════════════════════
# VALOR EFECTIVO DE UN PARÁMETRO (base + mejoras aplicadas)
# ═══════════════════════════════════════════════════
func get_param(id: String, param: String) -> float:
	var hab = habilidades.get(id, {})
	if hab.is_empty():
		return 0.0
	var val: float
	if param == "cooldown":
		val = hab.get("cooldown_base", 0.0)
	else:
		val = float(hab.get("base", {}).get(param, 0.0))
	for mid in hab.get("mejoras", {}).keys():
		var m = hab["mejoras"][mid]
		if m.get("afecta", "") == param:
			val += float(m.get("incremento", 0)) * m.get("nivel", 0)
	return val

func get_cooldown(id: String) -> float:
	return get_param(id, "cooldown")

# ═══════════════════════════════════════════════════
# DESBLOQUEAR / MEJORAR / SELECCIONAR (gastan fragmentos)
# ═══════════════════════════════════════════════════
func desbloquear(id: String) -> bool:
	var hab = habilidades.get(id, {})
	if hab.is_empty() or hab.get("desbloqueada", false):
		return false
	var coste: int = hab.get("coste_desbloqueo", 0)
	if not Economia.gastar_fragmentos(coste):
		return false
	hab["desbloqueada"] = true
	hab["activa"] = true   # al desbloquear, queda activa por defecto
	guardar()
	habilidad_cambiada.emit()
	return true

# Coste de subir UN nivel de una línea de mejora (escala con el nivel actual).
func get_coste_mejora(id: String, mid: String) -> int:
	var m = habilidades.get(id, {}).get("mejoras", {}).get(mid, {})
	if m.is_empty():
		return 0
	return int(m.get("coste_base", 0) * pow(FACTOR_COSTE_MEJORA, m.get("nivel", 0)))

func mejorar(id: String, mid: String) -> bool:
	var hab = habilidades.get(id, {})
	if hab.is_empty() or not hab.get("desbloqueada", false):
		return false
	var m = hab.get("mejoras", {}).get(mid, {})
	if m.is_empty() or m.get("nivel", 0) >= m.get("max_nivel", 0):
		return false
	var coste := get_coste_mejora(id, mid)
	if not Economia.gastar_fragmentos(coste):
		return false
	m["nivel"] = m.get("nivel", 0) + 1
	guardar()
	habilidad_cambiada.emit()
	return true

# Activar/desactivar para la partida (solo si está desbloqueada).
func set_activa(id: String, activa: bool) -> void:
	var hab = habilidades.get(id, {})
	if hab.is_empty() or not hab.get("desbloqueada", false):
		return
	hab["activa"] = activa
	guardar()
	seleccion_cambiada.emit()

func toggle_activa(id: String) -> void:
	set_activa(id, not esta_activa(id))

# ═══════════════════════════════════════════════════
# PERSISTENCIA (solo estado dinámico: desbloqueo, activa, niveles)
# ═══════════════════════════════════════════════════
func guardar() -> void:
	var datos: Dictionary = {}
	for id in habilidades.keys():
		var hab = habilidades[id]
		var niveles: Dictionary = {}
		for mid in hab.get("mejoras", {}).keys():
			var n: int = hab["mejoras"][mid].get("nivel", 0)
			if n > 0:
				niveles[mid] = n
		datos[id] = {
			"desbloqueada": hab.get("desbloqueada", false),
			"activa": hab.get("activa", false),
			"niveles": niveles,
		}
	var file = FileAccess.open("user://habilidades.save", FileAccess.WRITE)
	if file:
		file.store_var(datos)
		file.close()

func cargar() -> void:
	if not FileAccess.file_exists("user://habilidades.save"):
		return
	var file = FileAccess.open("user://habilidades.save", FileAccess.READ)
	if not file:
		return
	var datos = file.get_var()
	file.close()
	if not datos is Dictionary:
		return
	for id in datos.keys():
		if not habilidades.has(id):
			continue
		var hab = habilidades[id]
		var d = datos[id]
		hab["desbloqueada"] = d.get("desbloqueada", hab.get("desbloqueada", false))
		hab["activa"] = d.get("activa", hab.get("activa", false))
		var niveles = d.get("niveles", {})
		for mid in niveles.keys():
			if hab.get("mejoras", {}).has(mid):
				hab["mejoras"][mid]["nivel"] = niveles[mid]
