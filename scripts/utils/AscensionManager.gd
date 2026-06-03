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
var escena_espectro_comander_ref: Node2D = null

# ── Estado del Commander (reingreso si escapó) ──────
var commander_escapo: bool = false
var commander_hp_al_escapar: float = 0.0
var commander_reaparicion_en_ascension: int = -1

const DURACION_ASCENSION: float = 35.0
const PAUSA_ENTRE_ASCENSIONES: float = 15.0
const ESPECTROS_BASE: int = 8
const MAX_ENEMIGOS_SIMULTANEOS: int = 15

# El escalado de stats de enemigos vive centralizado en EscaladoEnemigos.gd
# (clase estática). Tunea la dificultad ahí, no aquí.

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

	# ✅ Evaluar aparición/reingreso del Commander
	_evaluar_commander()

	ascension_iniciada.emit(Economia.numero_ascension)
	await get_tree().create_timer(DURACION_ASCENSION).timeout
	if en_combate:
		_terminar_ascension()

func _terminar_ascension() -> void:
	en_combate = false
	temporizador_pausa = PAUSA_ENTRE_ASCENSIONES
	espectros_vivos = 0
	espectros_a_spawnear = 0
	ascension_completada.emit(Economia.numero_ascension)
	pausa_entre_ascensiones.emit(temporizador_pausa)
	print("⏸️ Ascensión ", Economia.numero_ascension, " completada. Pausa de ", PAUSA_ENTRE_ASCENSIONES, "s")

func get_tiempo_restante() -> float:
	return temporizador_ascension if en_combate else 0.0

func _generar_espectro() -> void:
	if not escena_espectro: return

	var escena_elegida = _elegir_tipo_enemigo()
	var es_commander = (escena_elegida == escena_espectro_comander)

	if not es_commander and espectros_vivos >= MAX_ENEMIGOS_SIMULTANEOS:
		return

	var espectro = escena_elegida.instantiate()
	# Hijo de la escena del mundo (no de root) para que se libere al cambiar
	# de escena; si no, quedan huérfanos congelados entre partidas.
	var _padre := get_tree().current_scene
	if _padre == null:
		_padre = get_tree().root
	_padre.add_child(espectro)

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

# ✅ Garantizar distancia mínima al nexus
	var nexus_node = get_tree().get_first_node_in_group("nexus")
	if nexus_node:
		var intentos = 0
		while espectro.global_position.distance_to(nexus_node.global_position) < 300.0 and intentos < 10:
			lado = randi() % 4
			match lado:
				0: espectro.global_position = Vector2(randf_range(0, tam_vista.x), -50)
				1: espectro.global_position = Vector2(randf_range(0, tam_vista.x), tam_vista.y + 50)
				2: espectro.global_position = Vector2(-50, randf_range(0, tam_vista.y))
				3: espectro.global_position = Vector2(tam_vista.x + 50, randf_range(0, tam_vista.y))
			intentos += 1

	var ascension = Economia.numero_ascension
	var tipo_str = "basico"
	if escena_elegida == escena_espectro_jefe:
		tipo_str = "jefe"
	elif escena_elegida == escena_espectro_tanque:
		tipo_str = "tanque"
	elif escena_elegida == escena_espectro_kamikaze:
		tipo_str = "kamikaze"
	elif escena_elegida == escena_espectro_sniper:
		tipo_str = "sniper"
	elif escena_elegida == escena_espectro_comander:
		tipo_str = "commander"

	# Escalado centralizado (EscaladoEnemigos).
	var datos := EscaladoEnemigos.stats(tipo_str, ascension)
	print("📊 Stats: ", tipo_str, " | HP: ", snapped(datos["hp"], 0.1), " | ATK: ", snapped(datos["atk"], 0.1))
	espectro.configurar(datos)

	print("📢 Generando espectro. Restantes por spawnear: ", espectros_a_spawnear)

	if espectro.has_signal("espectro_destruido"):
		espectro.espectro_destruido.connect(_on_espectro_destruido)

	espectros_a_spawnear -= 1
	espectros_vivos += 1

func _elegir_tipo_enemigo() -> PackedScene:
	var ascension = Economia.numero_ascension

	if ascension % 15 == 0 and ascension > 0 and not jefe_generado_esta_ascension:
		if escena_espectro_jefe:
			jefe_generado_esta_ascension = true
			print("👾 JEFE generado en ascensión ", ascension, " (único)")
			return escena_espectro_jefe

	if ascension >= 10 and escena_espectro_sniper and randf() < 0.06:
		return escena_espectro_sniper

	if ascension >= 6 and escena_espectro_kamikaze and randf() < 0.12:
		return escena_espectro_kamikaze

	if ascension >= 4 and escena_espectro_tanque and randf() < 0.08:
		return escena_espectro_tanque

	return escena_espectro

# ────────────────────────────────────────────────
# SISTEMA COMMANDER (aparición nueva + reingreso si escapó)
# ────────────────────────────────────────────────

func _evaluar_commander() -> void:
	if escena_espectro_comander == null:
		return
	# Solo puede haber 1 Commander activo a la vez
	if _hay_commander_activo():
		return

	var asc := Economia.numero_ascension

	# Reingreso del Commander que escapó (10-20 ascensiones después)
	if commander_escapo and commander_reaparicion_en_ascension > 0 \
	and asc >= commander_reaparicion_en_ascension:
		var hp_reingreso := maxf(1.0, commander_hp_al_escapar * 1.2)
		_spawn_commander(hp_reingreso)
		commander_escapo = false
		commander_reaparicion_en_ascension = -1
		print("👾 COMMANDER REGRESA con HP ", snapped(hp_reingreso, 0.1))
		return

	# Commander nuevo cada 50 ascensiones
	if asc > 0 and asc % 50 == 0 and not commander_generado_esta_ascension:
		var hp_nuevo := EscaladoEnemigos.vida("commander", asc)
		_spawn_commander(hp_nuevo)
		print("👾 COMMANDER NUEVO (Asc ", asc, ") HP ", snapped(hp_nuevo, 0.1))

## 🧪 Fuerza la aparición del Commander al instante (modo prueba).
func forzar_commander() -> void:
	if escena_espectro_comander == null:
		print("🧪 forzar_commander: no hay escena de Commander asignada")
		return
	if _hay_commander_activo():
		print("🧪 forzar_commander: ya hay un Commander activo")
		return
	var asc: int = max(Economia.numero_ascension, 1)
	var hp := EscaladoEnemigos.vida("commander", asc)
	_spawn_commander(hp)
	print("🧪 forzar_commander: Commander invocado (Asc ", asc, ") HP ", snapped(hp, 0.1))

func _spawn_commander(hp: float) -> void:
	var commander = escena_espectro_comander.instantiate()
	var _padre := get_tree().current_scene
	if _padre == null:
		_padre = get_tree().root
	_padre.add_child(commander)

	var nexus_node = get_tree().get_first_node_in_group("nexus")
	var centro: Vector2 = nexus_node.global_position if nexus_node else Vector2(360, 640)
	var ang := randf() * TAU
	commander.global_position = centro + Vector2(cos(ang), sin(ang)) * 600.0

	if commander.has_method("configurar"):
		commander.configurar({
			"hp": hp,
			"atk": 0.0,
			"spd_px": 100.0,
			"recompensa": 40,
			"tipo": "commander"
		})

	# El Commander NO cuenta para espectros_vivos (spawn especial):
	# por eso NO conectamos su espectro_destruido a _on_espectro_destruido.
	if commander.has_signal("commander_muerto"):
		commander.commander_muerto.connect(_on_commander_muerto_real)
	if commander.has_signal("commander_escapo"):
		commander.commander_escapo.connect(_on_commander_escapo_real)

	commander_generado_esta_ascension = true
	escena_espectro_comander_ref = commander

func _on_commander_muerto_real() -> void:
	commander_escapo = false
	commander_hp_al_escapar = 0.0
	commander_reaparicion_en_ascension = -1
	escena_espectro_comander_ref = null

func _on_commander_escapo_real() -> void:
	commander_escapo = true
	if is_instance_valid(escena_espectro_comander_ref):
		commander_hp_al_escapar = escena_espectro_comander_ref.get("salud_actual")
	commander_reaparicion_en_ascension = Economia.numero_ascension + randi_range(10, 20)
	escena_espectro_comander_ref = null
	print("🚀 Commander escapó. Regresará en Asc ", commander_reaparicion_en_ascension)

func _hay_commander_activo() -> bool:
	for c in get_tree().get_nodes_in_group("commanders"):
		if is_instance_valid(c) and not c.get("esta_destruido"):
			return true
	return false

func _on_espectro_destruido(_pos: Vector2, _recompensa: int) -> void:
	espectros_vivos -= 1
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
