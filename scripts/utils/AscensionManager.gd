extends Node
# ═══════════════════════════════════════════════════
# ASCENSION MANAGER — Gestor de oleadas de Void Sentinel
# ═══════════════════════════════════════════════════

signal ascension_iniciada(numero: int)
signal ascension_completada(numero: int)
signal pausa_entre_ascensiones(segundos: float)

@export var escena_espectro: PackedScene

var espectros_vivos: int = 0
var espectros_a_spawnear: int = 0
var temporizador_spawn: float = 0.0
var temporizador_pausa: float = 5.0
var en_combate: bool = false

const DURACION_ASCENSION: float = 35.0  # ✅ 35 segundos
const PAUSA_ENTRE_ASCENSIONES: float = 15.0  # ✅ 15 segundos
const ESPECTROS_BASE: int = 8
const MAX_ENEMIGOS_SIMULTANEOS: int = 15

func _process(delta: float) -> void:
	if not en_combate:
		temporizador_pausa -= delta
		if temporizador_pausa <= 0.0:
			_iniciar_ascension()
	else:
		temporizador_spawn -= delta
		if temporizador_spawn <= 0.0 and espectros_a_spawnear > 0:
			_generar_espectro()
			temporizador_spawn = _obtener_intervalo_spawn()

func _iniciar_ascension() -> void:
	en_combate = true
	Economia.avanzar_ascension()
	espectros_a_spawnear = ESPECTROS_BASE + Economia.numero_ascension * 2
	temporizador_spawn = 0.0
	print("🚀 Ascensión ", Economia.numero_ascension, " iniciada")
	ascension_iniciada.emit(Economia.numero_ascension)
	await get_tree().create_timer(DURACION_ASCENSION).timeout
	if en_combate:
		_terminar_ascension()

func _terminar_ascension() -> void:
	en_combate = false
	temporizador_pausa = PAUSA_ENTRE_ASCENSIONES
	ascension_completada.emit(Economia.numero_ascension)
	pausa_entre_ascensiones.emit(temporizador_pausa)
	print("⏸️ Ascensión ", Economia.numero_ascension, " completada. Pausa de ", PAUSA_ENTRE_ASCENSIONES, "s")

func _generar_espectro() -> void:
	if not escena_espectro: return
	
	# ✅ Verificar límite de enemigos simultáneos
	if espectros_vivos >= MAX_ENEMIGOS_SIMULTANEOS:
		return
	
	var espectro = escena_espectro.instantiate()
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
	var nivel = (ascension - 1) / 5
	var multiplicador_salud = pow(1.6, nivel)
	var multiplicador_ataque = pow(1.3, nivel)
	
	espectro.configurar({
		"hp": 100.0 * multiplicador_salud,
		"atk": 5.0 * multiplicador_ataque,
		"spd_px": 80.0,
		"recompensa": 5 + ascension,
		"tipo": "basico"
	})
	print("📢 Generando espectro. Restantes por spawnear: ", espectros_a_spawnear)
	
	if espectro.has_signal("espectro_destruido"):
		espectro.espectro_destruido.connect(_on_espectro_destruido)
	
	espectros_a_spawnear -= 1
	espectros_vivos += 1

func _on_espectro_destruido(_pos: Vector2, _recompensa: int) -> void:
	espectros_vivos -= 1
	print("💀 Espectro destruido. Vivos: ", espectros_vivos, " | Por spawnear: ", espectros_a_spawnear)
	if espectros_a_spawnear == 0 and espectros_vivos <= 0 and en_combate:
		_terminar_ascension()

func _obtener_intervalo_spawn() -> float:
	# Tasa base: 0.75 enem/seg = 1.33 segundos entre spawns
	# Rango: 0.5 a 1.0 enem/seg = 1.0 a 2.0 segundos entre spawns
	return randf_range(1.0, 2.0)
	
