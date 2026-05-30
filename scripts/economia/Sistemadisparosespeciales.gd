extends Node
# ═══════════════════════════════════════════════════
# SISTEMA DE DISPAROS ESPECIALES
# ═══════════════════════════════════════════════════

signal disparos_actualizados(disponibles: int, usados: int)
signal disparo_especial_usado
signal nuevo_disparo_ganado

var disparos_disponibles: int = 0
var disparos_usados: int = 0
var enemigos_killcount_oleada: int = 0

const DISPAROS_INICIALES: int = 3
const ENEMIGOS_POR_DISPARO: int = 10

# Referencia al CommanderManager — se busca en _ready de forma segura
var _commander_manager: Node = null

func _ready() -> void:
	# Conectar economía
	if Economia.has_signal("ascension_cambiada"):
		Economia.ascension_cambiada.connect(_on_ascension_cambiada)

	# Buscar CommanderManager por ruta segura
	_commander_manager = get_node_or_null("/root/CommaderManager")
	if _commander_manager == null:
		_commander_manager = get_node_or_null("/root/CommanderManager")

	if _commander_manager:
		if _commander_manager.has_signal("commander_spawned"):
			_commander_manager.commander_spawned.connect(_on_commander_spawned)
		if _commander_manager.has_signal("commander_reaparec"):
			_commander_manager.commander_reaparec.connect(_on_commander_reaparec)
		if _commander_manager.has_signal("commander_died"):
			_commander_manager.commander_died.connect(_on_commander_died)
		print("✅ SistemaDisparosEspeciales conectado a CommanderManager")
	else:
		print("⚠️ SistemaDisparosEspeciales: CommanderManager no encontrado")

# ────────────────────────────────────────────────
# MANEJO DE ASCENSIONES
# ────────────────────────────────────────────────

func _on_ascension_cambiada(_numero_asc: int) -> void:
	enemigos_killcount_oleada = 0

func _on_commander_spawned(_numero_asc: int, _commander_id: int) -> void:
	disparos_disponibles = DISPAROS_INICIALES
	disparos_usados = 0
	enemigos_killcount_oleada = 0
	print("⚔️ DISPAROS INICIALES: ", disparos_disponibles)
	disparos_actualizados.emit(disparos_disponibles, disparos_usados)

func _on_commander_reaparec(_numero_asc: int, _hp_multiplicado: float) -> void:
	disparos_disponibles += DISPAROS_INICIALES
	disparos_usados = 0
	enemigos_killcount_oleada = 0
	print("⚔️ COMMANDER REAPAREC: +", DISPAROS_INICIALES, " disparos (Total: ", disparos_disponibles, ")")
	disparos_actualizados.emit(disparos_disponibles, disparos_usados)

func _on_commander_died(_numero_asc: int, _es_penalizado: bool) -> void:
	print("✨ Commander derrotado. Disparos reseteados.")
	reset_contador()

# ────────────────────────────────────────────────
# REGISTRAR KILLS
# ────────────────────────────────────────────────

func registrar_kill_enemigo() -> void:
	# Solo contar si hay un Commander activo
	if _commander_manager == null: return
	if not _commander_manager.has_method("get_commander_activo"): return
	if not _commander_manager.get_commander_activo(): return

	enemigos_killcount_oleada += 1

	if enemigos_killcount_oleada % ENEMIGOS_POR_DISPARO == 0:
		disparos_disponibles += 1
		print("🎯 +1 DISPARO ESPECIAL por ", ENEMIGOS_POR_DISPARO, " kills! (Total: ", disparos_disponibles, ")")
		nuevo_disparo_ganado.emit()
		disparos_actualizados.emit(disparos_disponibles, disparos_usados)

# ────────────────────────────────────────────────
# USAR DISPAROS
# ────────────────────────────────────────────────

func usar_disparo_especial() -> bool:
	if disparos_disponibles > disparos_usados:
		disparos_usados += 1
		print("💥 DISPARO ESPECIAL USADO! (", disparos_usados, "/", disparos_disponibles, ")")
		disparo_especial_usado.emit()
		disparos_actualizados.emit(disparos_disponibles, disparos_usados)
		return true
	print("❌ Sin disparos especiales disponibles")
	return false

func hay_disparos_disponibles() -> bool:
	return disparos_usados < disparos_disponibles

# ────────────────────────────────────────────────
# RESET Y GESTIÓN
# ────────────────────────────────────────────────

func reset_contador() -> void:
	disparos_disponibles = 0
	disparos_usados = 0
	enemigos_killcount_oleada = 0

func añadir_disparos_gratuitos(cantidad: int) -> void:
	disparos_disponibles += cantidad
	disparos_usados = 0
	print("➕ +", cantidad, " disparos gratuitos (Total: ", disparos_disponibles, ")")
	disparos_actualizados.emit(disparos_disponibles, disparos_usados)

# ────────────────────────────────────────────────
# GETTERS
# ────────────────────────────────────────────────

func get_disparos_disponibles() -> int:
	return disparos_disponibles

func get_disparos_usados() -> int:
	return disparos_usados

func get_disparos_restantes() -> int:
	return disparos_disponibles - disparos_usados

func get_enemigos_para_proximo_disparo() -> int:
	var modulo = enemigos_killcount_oleada % ENEMIGOS_POR_DISPARO
	if modulo == 0:
		return ENEMIGOS_POR_DISPARO
	return ENEMIGOS_POR_DISPARO - modulo

func get_porcentaje_carga() -> float:
	return float(enemigos_killcount_oleada % ENEMIGOS_POR_DISPARO) / float(ENEMIGOS_POR_DISPARO)
