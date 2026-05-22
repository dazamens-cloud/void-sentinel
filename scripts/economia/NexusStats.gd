extends Node
# ═══════════════════════════════════════════════════
# NEXUS STATS — Estadísticas del Nexus
# ═══════════════════════════════════════════════════

signal salud_cambiada(actual: float, maxima: float)
signal stats_actualizadas

# ── Stats base ──────────────────────────────────────────
var salud_base: float = 100.0
var danio_base: float = 100.0
var cadencia_base: float = 1.0
var regeneracion_base: float = 0.0
var rango_escaneo_base: float = 220.0
var critico_chance_base: float = 0.05
var critico_factor_base: float = 1.5

# ── Stats actuales ──────────────────────────────────────
var salud_actual: float = 100.0

# ── Mejoras ────────────────────────────────────────────
var mejora_danio_extra: float = 0.0
var mejora_cadencia: float = 0.0
var mejora_critico_chance: float = 0.0
var mejora_critico_factor: float = 0.0
var mejora_salud_extra: float = 0.0
var mejora_regeneracion: float = 0.0
var mejora_defensa: float = 0.0

# ═══════════════════════════════════════════════════════
func _ready() -> void:
	salud_actual = salud_base
	salud_cambiada.emit(salud_actual, salud_base)

# ═══════════════════════════════════════════════════════
# GETTERS PRINCIPALES
# ═══════════════════════════════════════════════════════
func get_salud() -> float:
	return salud_base

func get_danio() -> float:
	return danio_base + mejora_danio_extra

func get_cadencia_timer() -> float:
	var base = 1.0 / max(cadencia_base, 0.01)
	var mejora = max(0.2, 1.0 - abs(mejora_cadencia))
	return base * mejora

func get_regeneracion() -> float:
	return regeneracion_base + mejora_regeneracion

func get_rango_escaneo() -> float:
	return rango_escaneo_base

func get_critico_chance() -> float:
	return min(0.75, critico_chance_base + mejora_critico_chance)

func get_critico_factor() -> float:
	return critico_factor_base + mejora_critico_factor

func get_defensa() -> float:
	return mejora_defensa

# ═══════════════════════════════════════════════════════
# SALUD Y DAÑO
# ═══════════════════════════════════════════════════════
func recibir_ataque(cantidad: float) -> bool:
	salud_actual = max(0.0, salud_actual - cantidad)
	salud_cambiada.emit(salud_actual, salud_base)
	return salud_actual > 0.0

func curar(cantidad: float) -> void:
	salud_actual = min(salud_base, salud_actual + cantidad)
	salud_cambiada.emit(salud_actual, salud_base)

func reiniciar_partida() -> void:
	salud_actual = salud_base
	salud_cambiada.emit(salud_actual, salud_base)
	stats_actualizadas.emit()

# ═══════════════════════════════════════════════════════
# SETTERS DE MEJORAS
# ═══════════════════════════════════════════════════════
func set_mejora_danio(extra: float) -> void:
	mejora_danio_extra = extra

func set_mejora_cadencia(valor: float) -> void:
	mejora_cadencia = valor
	stats_actualizadas.emit()

func set_mejora_critico(chance: float, factor: float) -> void:
	mejora_critico_chance = chance
	mejora_critico_factor = factor

func set_mejora_salud(extra: float, regen: float) -> void:
	mejora_salud_extra = extra
	mejora_regeneracion = regen
	# Actualizar salud máxima
	salud_base = 100.0 + mejora_salud_extra
	if salud_actual > salud_base:
		salud_actual = salud_base
	salud_cambiada.emit(salud_actual, salud_base)

func set_mejora_defensa(valor: float) -> void:
	mejora_defensa = valor
