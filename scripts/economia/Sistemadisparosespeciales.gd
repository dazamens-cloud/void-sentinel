extends Node
# ═══════════════════════════════════════════════════
# SISTEMA DE DISPAROS ESPECIALES
# ═══════════════════════════════════════════════════

signal disparos_actualizados(disponibles: int)
signal disparo_especial_usado
signal nuevo_disparo_ganado
signal commander_apareci
signal commander_finalizado(escapo: bool)

var disparos_disponibles: int = 0
var kills_desde_ultimo_disparo: int = 0
var commander_activo: bool = false

const DISPAROS_INICIALES: int = 3
const KILLS_POR_DISPARO_BASE: int = 10
const CAP_MAXIMO_DISPAROS: int = 20

# ────────────────────────────────────────────────
# CONSULTA DE MEJORAS (categoría "commander")
# ────────────────────────────────────────────────

func _nivel_disparos_iniciales() -> int:
	if MejoraManager and MejoraManager.has_method("get_nivel"):
		return MejoraManager.get_nivel("disparos_iniciales")
	return 0

func _kills_por_disparo() -> int:
	# Mejora "recarga_rapida": -1 kill por nivel, mínimo 3
	var nivel := 0
	if MejoraManager and MejoraManager.has_method("get_nivel"):
		nivel = MejoraManager.get_nivel("recarga_rapida")
	return maxi(3, KILLS_POR_DISPARO_BASE - nivel)

# ────────────────────────────────────────────────
# REGISTRO DEL COMMANDER (señales directas del EspectroComander)
# ────────────────────────────────────────────────

# El EspectroComander se auto-registra en su _ready() (aparición nueva o reingreso).
func registrar_commander(commander: Node) -> void:
	# +3 disparos (+1 por nivel de "disparos_iniciales"), conservando los acumulados.
	var extra := DISPAROS_INICIALES + _nivel_disparos_iniciales()
	disparos_disponibles = mini(disparos_disponibles + extra, CAP_MAXIMO_DISPAROS)
	kills_desde_ultimo_disparo = 0
	commander_activo = true

	if commander.has_signal("commander_muerto") \
	and not commander.commander_muerto.is_connected(_on_commander_muerto):
		commander.commander_muerto.connect(_on_commander_muerto)
	if commander.has_signal("commander_escapo") \
	and not commander.commander_escapo.is_connected(_on_commander_escapo):
		commander.commander_escapo.connect(_on_commander_escapo)

	commander_apareci.emit()
	disparos_actualizados.emit(disparos_disponibles)

func _on_commander_muerto() -> void:
	commander_activo = false
	disparos_disponibles = 0
	kills_desde_ultimo_disparo = 0
	commander_finalizado.emit(false)
	disparos_actualizados.emit(disparos_disponibles)

func _on_commander_escapo() -> void:
	commander_activo = false
	kills_desde_ultimo_disparo = 0
	# disparos_disponibles se MANTIENE (se conservan hasta la próxima aparición)
	commander_finalizado.emit(true)
	disparos_actualizados.emit(disparos_disponibles)

# ────────────────────────────────────────────────
# REGISTRAR KILLS
# ────────────────────────────────────────────────

func registrar_kill_enemigo() -> void:
	# Solo cuenta mientras hay un Commander activo (con Commander fuera, se pausa)
	if not commander_activo: return

	kills_desde_ultimo_disparo += 1
	if kills_desde_ultimo_disparo % _kills_por_disparo() == 0:
		disparos_disponibles = mini(disparos_disponibles + 1, CAP_MAXIMO_DISPAROS)
		nuevo_disparo_ganado.emit()
		disparos_actualizados.emit(disparos_disponibles)

# ────────────────────────────────────────────────
# USAR DISPAROS
# ────────────────────────────────────────────────

func usar_disparo_especial() -> bool:
	if disparos_disponibles > 0:
		disparos_disponibles -= 1
		disparo_especial_usado.emit()
		disparos_actualizados.emit(disparos_disponibles)
		return true
	return false

func hay_disparos_disponibles() -> bool:
	return disparos_disponibles > 0

# ────────────────────────────────────────────────
# GETTERS
# ────────────────────────────────────────────────

func get_disparos_disponibles() -> int:
	return disparos_disponibles

func get_commander_activo() -> bool:
	return commander_activo

func get_kills_para_proximo_disparo() -> int:
	var kpd := _kills_por_disparo()
	var modulo := kills_desde_ultimo_disparo % kpd
	if modulo == 0:
		return kpd
	return kpd - modulo

func get_porcentaje_carga() -> float:
	var kpd := _kills_por_disparo()
	return float(kills_desde_ultimo_disparo % kpd) / float(kpd)
