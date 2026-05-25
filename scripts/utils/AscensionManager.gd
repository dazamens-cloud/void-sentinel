extends Node
# ═══════════════════════════════════════════════════
# ASCENSION MANAGER — Gestor de oleadas de Void Sentinel
# ═══════════════════════════════════════════════════

signal ascension_iniciada(numero: int)
signal ascension_completada(numero: int)
signal pausa_entre_ascensiones(segundos: float)

@export var escena_espectro: PackedScene
@export var escena_espectro_tanque: PackedScene
@export var escena_espectro_jefe: PackedScene
@export var escena_espectro_kamikaze: PackedScene
@export var escena_espectro_sniper: PackedScene
@export var escena_espectro_comander: PackedScene

var espectros_vivos: int = 0
var espectros_a_spawnear: int = 0
var temporizador_spawn: float = 0.0
var temporizador_pausa: float = 5.0
var temporizador_ascension: float = 0.0
var en_combate: bool = false
var jefe_generado_esta_ascension: bool = false
var commander_generado_esta_ascension: bool = false

const DURACION_ASCENSION: float = 35.0
const PAUSA_ENTRE_ASCENSIONES: float = 15.0
const ESPECTROS_BASE: int = 8
const MAX_ENEMIGOS_SIMULTANEOS: int = 15
const PROB_TANQUE: float = 0.05
const PROB_JEFE: float = 1.0
const ASCENSION_JEFE_INTERVALO: int = 15

func _ready() -> void:
	Economia.juego_terminado.connect(_on_juego_terminado)

func _process(delta: float) -> void:
	if not en_combate:
		temporizador_pausa -= delta
		if temporizador_pausa <= 0.0:
			_iniciar_ascension()
	else:
		temporizador_ascension -= delta
		temporizador_spawn -= delta
		if temporizador_spawn <= 0.0 and espectros_a_spawnear > 0:
			_generar_espectro()
			temporizador_spawn = _obtener_intervalo_spawn()

func _iniciar_ascension() -> void:
	en_combate = true
	jefe_generado_esta_ascension = false
	commander_generado_esta_ascension = false
	Economia.avanzar_ascension()
	espectros_a_spawnear = ESPECTROS_BASE + Economia.numero_ascension * 2
	temporizador_spawn = 0.0
	temporizador_ascension = DURACION_ASCENSION
	print("🚀 Ascensión ", Economia.numero_ascension, " iniciada")
	ascension_iniciada.emit(Economia.numero_ascension)
	await get_tree().create_timer(DURACION_ASCENSION).timeout
	if en_combate:
		_terminar_ascension()

func _terminar_ascension() -> void:
	en_combate = false
	temporizador_pausa = PAUSA_ENTRE_ASCENSIONES
	# ✅ Limpiar espectros vivos al terminar por tiempo
	espectros_vivos = 0
	espectros_a_spawnear = 0
	ascension_completada.emit(Economia.numero_ascension)
	pausa_entre_ascensiones.emit(temporizador_pausa)
	print("⏸️ Ascensión ", Economia.numero_ascension, " completada. Pausa de ", PAUSA_ENTRE_ASCENSIONES, "s")

func get_tiempo_restante() -> float:
	return temporizador_ascension if en_combate else 0.0

func _generar_espectro() -> void:
	if not escena_espectro: return
	if espectros_vivos >= MAX_ENEMIGOS_SIMULTANEOS:
		return

	var escena_elegida = _elegir_tipo_enemigo()
	var espectro = escena_elegida.instantiate()
	get_tree().root.add_child(espectro)

	var viewport = get_viewport()
	if not viewport:
		viewport = Engine.get_main_loop().root
	var tam_vista = viewport.get_visible_rect().size

	var lado = randi() % 4
	match lado:
		0: espectro.global_position = Vector2(randf_range(0, tam_vista.x), -50)
		1: espectro.global_position = Vector2(randf_range(0, tam_vista.x), tam_vista.y + 50)
		2: espectro.global_position = Vector2(-50, randf_range(0, tam_vista.y))
		3: espectro.global_position = Vector2(tam_vista.x + 50, randf_range(0, tam_vista.y))

	var ascension = Economia.numero_ascension

	# ✅ Escalado directo por ascensión (DOC_B — como The Tower)
	var multiplicador_salud = pow(1.15, ascension)
	var multiplicador_ataque = pow(1.08, ascension)

	# ✅ Stats base reducidos — números pequeños = progresión más satisfactoria
	var salud_base = 15.0 * multiplicador_salud
	var ataque_base = 3.0 * multiplicador_ataque
	var velocidad_base = 100.0
	var recompensa_base = 5
	var tipo_str = "basico"

	if escena_elegida == escena_espectro_jefe:
		salud_base = 150.0 * multiplicador_salud    # 15 × 10
		ataque_base = 6.0 * multiplicador_ataque     # 3 × 2
		velocidad_base = 50.0
		recompensa_base = 50
		tipo_str = "jefe"
	elif escena_elegida == escena_espectro_tanque:
		salud_base = 75.0 * multiplicador_salud      # 15 × 5
		ataque_base = 3.0 * multiplicador_ataque     # igual que básico
		velocidad_base = 60.0
		recompensa_base = 15                          # 5 × 3
		tipo_str = "tanque"
	elif escena_elegida == escena_espectro_kamikaze:
		salud_base = 10.0 * multiplicador_salud      # 15 × 0.67
		ataque_base = 6.0 * multiplicador_ataque     # 3 × 2
		velocidad_base = 200.0
		recompensa_base = 8
		tipo_str = "kamikaze"
	elif escena_elegida == escena_espectro_sniper:
		salud_base = 12.0 * multiplicador_salud      # 15 × 0.8
		ataque_base = 4.5 * multiplicador_ataque     # 3 × 1.5
		velocidad_base = 80.0
		recompensa_base = 8
		tipo_str = "sniper"
	elif escena_elegida == escena_espectro_comander:
		salud_base = 30.0 * multiplicador_salud      # 15 × 2
		ataque_base = 0.0
		velocidad_base = 100.0
		recompensa_base = 40
		tipo_str = "commander"

	# TEST TEMPORAL — borrar después de verificar
	print("📊 Stats: ", tipo_str, " | HP: ", snapped(salud_base, 0.1), " | ATK: ", snapped(ataque_base, 0.1))

	espectro.configurar({
		"hp": salud_base,
		"atk": ataque_base,
		"spd_px": velocidad_base,
		"recompensa": recompensa_base + ascension,
		"tipo": tipo_str
	})
	print("📢 Generando espectro. Restantes por spawnear: ", espectros_a_spawnear)

	if espectro.has_signal("espectro_destruido"):
		espectro.espectro_destruido.connect(_on_espectro_destruido)

	espectros_a_spawnear -= 1
	espectros_vivos += 1

func _elegir_tipo_enemigo() -> PackedScene:
	var ascension = Economia.numero_ascension

	# JEFE: solo una vez por ascensión múltiplo de 15
	if ascension % 15 == 0 and ascension > 0 and not jefe_generado_esta_ascension:
		if escena_espectro_jefe:
			jefe_generado_esta_ascension = true
			print("👾 JEFE generado en ascensión ", ascension, " (único)")
			return escena_espectro_jefe

	# SNIPER: desde ascensión 10, 6% de probabilidad
	if ascension >= 10 and escena_espectro_sniper and randf() < 0.06:
		return escena_espectro_sniper

	# KAMIKAZE: desde ascensión 6, 12% de probabilidad
	if ascension >= 6 and escena_espectro_kamikaze and randf() < 0.12:
		return escena_espectro_kamikaze

	# TANQUE: desde ascensión 4, 8% de probabilidad
	if ascension >= 4 and escena_espectro_tanque and randf() < 0.08:
		return escena_espectro_tanque

# COMMANDER: desde ascensión 20, 5% de probabilidad
	if ascension % 50 == 0 and ascension > 0 and escena_espectro_comander and not commander_generado_esta_ascension:
		commander_generado_esta_ascension = true
		return escena_espectro_comander

	return escena_espectro

func _on_espectro_destruido(_pos: Vector2, _recompensa: int) -> void:
	espectros_vivos -= 1
	# ✅ Evitar negativos — si ya terminó la ascensión, ignorar
	if not en_combate:
		espectros_vivos = 0
		return
	print("💀 Espectro destruido. Vivos: ", espectros_vivos, " | Por spawnear: ", espectros_a_spawnear)
	if espectros_a_spawnear == 0 and espectros_vivos <= 0 and en_combate:
		_terminar_ascension()

func _obtener_intervalo_spawn() -> float:
	return randf_range(1.0, 2.0)

func _on_juego_terminado(_causa: String) -> void:
	print("🛑 GAME OVER - Deteniendo todo...")
	en_combate = false
	temporizador_pausa = 0.0
	temporizador_ascension = 0.0
	espectros_a_spawnear = 0
	for e in get_tree().get_nodes_in_group("espectros"):
		if is_instance_valid(e):
			e.queue_free()
	temporizador_spawn = 0.0

func _spawn_enemigo() -> void:
	var escena_elegida = _elegir_tipo_enemigo()
	if not escena_elegida:
		print("ERROR: No hay escena de enemigo seleccionada")
		return
	var espectro = escena_elegida.instantiate()
	if not espectro.has_method("configurar"):
		print("ERROR: El enemigo no tiene método 'configurar'. Escena: ", escena_elegida.resource_path)
		espectro.queue_free()
		return
	get_tree().root.add_child(espectro)
