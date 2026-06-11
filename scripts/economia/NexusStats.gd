extends Node
# ═══════════════════════════════════════════════════
# NEXUS STATS — Estadísticas del Nexus
# ═══════════════════════════════════════════════════

signal salud_cambiada(actual: float, maxima: float)
signal stats_actualizadas

# ── Stats base ──────────────────────────────────────────
var salud_base: float = 100.0
var danio_base: float = 200.0
var cadencia_base: float = 1.0
var regeneracion_base: float = 0.5
var rango_escaneo_base: float = 280.0
var critico_chance_base: float = 0.05
var critico_factor_base: float = 1.5

# ── Stats actuales ──────────────────────────────────────
var salud_actual: float = 100.0

# ── Mejoras ────────────────────────────────────────────
# Daño y vida son MULTIPLICATIVOS (fase 2): valor = base × multiplicador,
# donde el multiplicador = FACTOR^nivel lo calcula MejoraManager. Esto deja
# que el poder escale lo suficiente para techos de miles de ascensiones.
var mult_danio: float = 1.0
var mult_salud: float = 1.0
var mejora_cadencia: float = 0.0
var mejora_critico_chance: float = 0.0
var mejora_critico_factor: float = 0.0
var mejora_regeneracion: float = 0.0
var mejora_defensa: float = 0.0
var mejora_multidisparo: int = 0
var mejora_rebote_cantidad: int = 0
var mejora_rebote_alcance: float = 0.0
var mejora_escudo_max: float = 0.0
var mejora_pulso_radio: float = 0.0
var mejora_pulso_lentitud: float = 0.0
var mejora_pulso_empuje: float = 0.0

# ── Escudo (absorbe daño antes que la salud) ────────────
var escudo_actual: float = 0.0

# ── Control interno ─────────────────────────────────────
var _ultimo_salud_emitida: float = -1.0  # Para evitar spam de señal

# ═══════════════════════════════════════════════════════
func _ready() -> void:
	salud_actual = salud_base
	_ultimo_salud_emitida = salud_actual
	salud_cambiada.emit(salud_actual, salud_base)

# ── Bonus pasivos del Laboratorio (investigaciones completadas) ──
# Consulta defensiva: si el autoload no existe aún, bonus 0.
func _lab(id: String) -> float:
	var lab := get_node_or_null("/root/Laboratorio")
	if lab:
		return lab.get_bonus(id)
	return 0.0

# ═══════════════════════════════════════════════════════
# GETTERS PRINCIPALES
# ═══════════════════════════════════════════════════════
func get_salud() -> float:
	return salud_base

func get_danio() -> float:
	return danio_base * mult_danio * (1.0 + _lab("nucleo_sincronizado"))

func get_cadencia_timer() -> float:
	var base = 1.0 / max(cadencia_base, 0.01)
	# Suelo 0.05 = cadencia mínima 0.05s (20 disparos/s). El tope de nivel de
	# 'velocidad_ataque' (95 × -0.01 = -0.95) deja el factor justo en 0.05.
	var mejora = max(0.05, 1.0 - abs(mejora_cadencia))
	# Lab "condensadores_rapidos": reduce el timer un % extra (mismo suelo).
	return base * mejora * maxf(0.05, 1.0 - _lab("condensadores_rapidos"))

func get_regeneracion() -> float:
	return regeneracion_base + mejora_regeneracion + _lab("regeneracion_celular")

func get_rango_escaneo() -> float:
	return rango_escaneo_base * (1.0 + _lab("sensores_largo_alcance"))

func get_critico_chance() -> float:
	return min(0.75, critico_chance_base + mejora_critico_chance + _lab("balistica_avanzada"))

func get_critico_factor() -> float:
	return critico_factor_base + mejora_critico_factor + _lab("nucleos_perforantes")

func get_defensa() -> float:
	# mejora_defensa llega como delta negativo (incremento -0.005/nivel).
	# Lo convertimos en reducción positiva de daño, máx 75% ("dureza_escudo").
	return clampf(-mejora_defensa + _lab("aleacion_reforzada"), 0.0, 0.75)

func get_multidisparo() -> int:
	return mejora_multidisparo

func get_rebote_cantidad() -> int:
	return mejora_rebote_cantidad

func get_rebote_alcance() -> float:
	return mejora_rebote_alcance

func get_escudo_max() -> float:
	return mejora_escudo_max + _lab("condensador_escudo")

func get_escudo_actual() -> float:
	return escudo_actual

# ═══════════════════════════════════════════════════════
# SALUD Y DAÑO
# ═══════════════════════════════════════════════════════
func recibir_ataque(cantidad: float) -> bool:
	var restante := cantidad
	# El escudo absorbe primero
	if escudo_actual > 0.0:
		var absorbido := minf(escudo_actual, restante)
		escudo_actual -= absorbido
		restante -= absorbido
	salud_actual = max(0.0, salud_actual - restante)
	_emitir_salud_si_cambio()
	return salud_actual > 0.0

func curar(cantidad: float) -> void:
	# ✅ No curar si ya está al máximo — evita señal innecesaria cada frame
	if salud_actual >= salud_base:
		return
	salud_actual = min(salud_base, salud_actual + cantidad)
	_emitir_salud_si_cambio()

func reiniciar_partida() -> void:
	salud_base = 100.0
	danio_base = 200.0        # ← añadir
	rango_escaneo_base = 280.0  # ← añadir
	regeneracion_base = 0.5   # ← añadir
	mult_salud = 1.0
	mejora_regeneracion = 0.0
	mult_danio = 1.0
	mejora_cadencia = 0.0
	mejora_critico_chance = 0.0
	mejora_critico_factor = 0.0
	mejora_defensa = 0.0
	mejora_multidisparo = 0
	mejora_rebote_cantidad = 0
	mejora_rebote_alcance = 0.0
	mejora_escudo_max = 0.0
	mejora_pulso_radio = 0.0
	mejora_pulso_lentitud = 0.0
	mejora_pulso_empuje = 0.0
	escudo_actual = 0.0
	salud_actual = salud_base
	_ultimo_salud_emitida = -1.0
	salud_cambiada.emit(salud_actual, salud_base)
	stats_actualizadas.emit()

# ── Emite salud solo si cambió más de 0.5 HP (evita spam en consola) ──
func _emitir_salud_si_cambio() -> void:
	# ✅ Umbral 0.1 para capturar el último tramo hasta el máximo
	if abs(salud_actual - _ultimo_salud_emitida) >= 0.1:
		_ultimo_salud_emitida = salud_actual
		salud_cambiada.emit(salud_actual, salud_base)

# ═══════════════════════════════════════════════════════
# SETTERS DE MEJORAS
# ═══════════════════════════════════════════════════════
func set_mult_danio(m: float) -> void:
	mult_danio = maxf(1.0, m)

func set_mejora_cadencia(valor: float) -> void:
	mejora_cadencia = valor
	stats_actualizadas.emit()

func set_mejora_critico(chance: float, factor: float) -> void:
	mejora_critico_chance = chance
	mejora_critico_factor = factor

func set_mult_salud(m: float) -> void:
	var salud_base_anterior := salud_base
	mult_salud = maxf(1.0, m)
	# Lab "matriz_vital": % de vida extra sobre el total.
	salud_base = 100.0 * mult_salud * (1.0 + _lab("matriz_vital"))
	# Al subir el máximo, cura la diferencia (no al bajar).
	var delta := salud_base - salud_base_anterior
	if delta > 0.0:
		salud_actual += delta
	salud_actual = minf(salud_actual, salud_base)
	salud_cambiada.emit(salud_actual, salud_base)
	_ultimo_salud_emitida = salud_actual

func set_mejora_regen(valor: float) -> void:
	mejora_regeneracion = valor

func set_mejora_defensa(valor: float) -> void:
	mejora_defensa = valor

func set_mejora_multidisparo(cantidad: int) -> void:
	mejora_multidisparo = max(0, cantidad)

func set_mejora_rebote(cantidad: int, alcance: float) -> void:
	mejora_rebote_cantidad = max(0, cantidad)
	mejora_rebote_alcance = max(0.0, alcance)

func set_mejora_escudo(valor: float) -> void:
	# valor = escudo máximo total. Al subir el máximo, recarga la diferencia.
	var anterior := mejora_escudo_max
	mejora_escudo_max = max(0.0, valor)
	escudo_actual += maxf(0.0, mejora_escudo_max - anterior)
	escudo_actual = minf(escudo_actual, mejora_escudo_max)

func set_mejora_pulso(radio: float, lentitud: float, empuje: float) -> void:
	mejora_pulso_radio = radio
	mejora_pulso_lentitud = lentitud
	mejora_pulso_empuje = empuje

func get_pulso_radio() -> float:
	return mejora_pulso_radio

func get_pulso_lentitud() -> float:
	# Fracción de ralentización, máx 80%
	return clampf(mejora_pulso_lentitud, 0.0, 0.8)

func get_pulso_empuje() -> float:
	return maxf(0.0, mejora_pulso_empuje)
	
