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
var _commander_activo: Node2D = null  # ✅ Caché para evitar O(n) get_nodes_in_group()

const DURACION_ASCENSION: float = 35.0
const PAUSA_ENTRE_ASCENSIONES: float = 8.0
const ESPECTROS_BASE: int = 8
const MAX_ENEMIGOS_SIMULTANEOS: int = 15
# Tope de enemigos por oleada. La cantidad crece (8 + asc) hasta este techo y
# se aplana: en asc altas la dificultad la lleva el HP, no más enemigos.
const TOPE_ESPECTROS_OLEADA: int = 30

# Total de enemigos de la oleada actual (para repartir el spawn en la ventana).
var _total_oleada: int = 0

# ✅ Batch cleanup para evitar frame drops en game over
var _enemigos_pendientes_delete: Array = []
var _deleting_batch: bool = false

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
		# La ascensión termina cuando vence el tiempo PERO solo si ya se
		# soltaron todos los enemigos estipulados. Si el cap de simultáneos
		# retrasó algún spawn, esperamos a soltarlos (no se descartan); el otro
		# criterio (_on_espectro_destruido) cierra cuando además mueren.
		if temporizador_ascension <= 0.0 and espectros_a_spawnear <= 0:
			_terminar_ascension()

func _iniciar_ascension() -> void:
	en_combate = true
	jefe_generado_esta_ascension = false
	commander_generado_esta_ascension = false
	Economia.avanzar_ascension()
	# Cantidad acotada: crece 8+asc hasta el tope y se aplana (antes era 8+asc*2
	# sin techo → miles de enemigos imposibles en asc altas).
	espectros_a_spawnear = min(TOPE_ESPECTROS_OLEADA, ESPECTROS_BASE + Economia.numero_ascension)
	_total_oleada = espectros_a_spawnear
	temporizador_spawn = 0.0
	temporizador_ascension = DURACION_ASCENSION

	# ✅ Evaluar aparición/reingreso del Commander
	_evaluar_commander()

	ascension_iniciada.emit(Economia.numero_ascension)

func _terminar_ascension() -> void:
	en_combate = false
	temporizador_pausa = PAUSA_ENTRE_ASCENSIONES
	espectros_vivos = 0
	espectros_a_spawnear = 0
	ascension_completada.emit(Economia.numero_ascension)
	pausa_entre_ascensiones.emit(temporizador_pausa)

func get_tiempo_restante() -> float:
	return temporizador_ascension if en_combate else 0.0

func get_duracion_ascension() -> float:
	return DURACION_ASCENSION

func _generar_espectro() -> void:
	if not escena_espectro: return

	# _elegir_tipo_enemigo() nunca devuelve el Commander (se gestiona aparte en
	# _evaluar_commander), por eso aquí solo aplicamos el cap normal de enemigos.
	var escena_elegida = _elegir_tipo_enemigo()
	if escena_elegida == null:
		push_error("❌ _generar_espectro: _elegir_tipo_enemigo devolvió null")
		return

	if espectros_vivos >= MAX_ENEMIGOS_SIMULTANEOS:
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

# ✅ Garantizar distancia mínima al nexus (usando distance_squared_to para evitar sqrt)
	var nexus_node = get_tree().get_first_node_in_group("nexus")
	if nexus_node:
		var intentos = 0
		var distancia_minima_sq = 300.0 * 300.0  # 90000 (evita sqrt)
		while espectro.global_position.distance_squared_to(nexus_node.global_position) < distancia_minima_sq and intentos < 10:
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
	espectro.configurar(datos)

	if espectro.has_signal("espectro_destruido"):
		espectro.espectro_destruido.connect(_on_espectro_destruido)

	espectros_a_spawnear -= 1
	espectros_vivos += 1

func _elegir_tipo_enemigo() -> PackedScene:
	var ascension = Economia.numero_ascension

	if ascension % 15 == 0 and ascension > 0 and not jefe_generado_esta_ascension:
		if escena_espectro_jefe:
			jefe_generado_esta_ascension = true
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
		return

	# Commander nuevo cada 50 ascensiones
	if asc > 0 and asc % 50 == 0 and not commander_generado_esta_ascension:
		var hp_nuevo := EscaladoEnemigos.vida("commander", asc)
		_spawn_commander(hp_nuevo)

## 🧪 Fuerza la aparición del Commander al instante (modo prueba).
func forzar_commander() -> void:
	if escena_espectro_comander == null:
		return
	if _hay_commander_activo():
		return
	var asc: int = max(Economia.numero_ascension, 1)
	var hp := EscaladoEnemigos.vida("commander", asc)
	_spawn_commander(hp)

func _spawn_commander(hp: float) -> void:
	if escena_espectro_comander == null:
		push_error("❌ _spawn_commander: escena_espectro_comander no asignada en editor")
		return
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

	_commander_activo = commander  # ✅ Cachear referencia

	commander_generado_esta_ascension = true
	escena_espectro_comander_ref = commander

func _on_commander_muerto_real() -> void:
	commander_escapo = false
	commander_hp_al_escapar = 0.0
	commander_reaparicion_en_ascension = -1
	escena_espectro_comander_ref = null
	_commander_activo = null  # ✅ Limpiar caché

func _on_commander_escapo_real() -> void:
	commander_escapo = true
	if is_instance_valid(escena_espectro_comander_ref):
		commander_hp_al_escapar = escena_espectro_comander_ref.get("salud_actual")
	commander_reaparicion_en_ascension = Economia.numero_ascension + randi_range(10, 20)
	escena_espectro_comander_ref = null
	_commander_activo = null  # ✅ Limpiar caché

func _hay_commander_activo() -> bool:
	# ✅ Usar caché en lugar de O(n) get_nodes_in_group cada vez
	return is_instance_valid(_commander_activo) and not _commander_activo.get("esta_destruido")

func _on_espectro_destruido(_pos: Vector2, _recompensa: int) -> void:
	espectros_vivos -= 1
	if not en_combate:
		espectros_vivos = 0
		return
	if espectros_a_spawnear == 0 and espectros_vivos <= 0 and en_combate:
		_terminar_ascension()

func _obtener_intervalo_spawn() -> float:
	# Reparte la oleada completa a lo largo de la ventana de la ascensión, así
	# SIEMPRE da tiempo a soltar a todos (nada se descarta). Con tope 30 y 35s
	# sale uno cada ~1.2s; se acota entre 0.5s y 2.5s y se varía un poco para
	# que no suene robótico.
	var base := DURACION_ASCENSION / float(max(_total_oleada, 1))
	base = clampf(base, 0.5, 2.5)
	return base * randf_range(0.85, 1.15)

func _on_juego_terminado(_causa: String) -> void:
	en_combate = false
	temporizador_pausa = 0.0
	temporizador_ascension = 0.0
	espectros_a_spawnear = 0
	temporizador_spawn = 0.0
	# ✅ Batch queue_free para evitar 30+ queue_free en 1 frame (frame drop 5-15ms)
	_enemigos_pendientes_delete = get_tree().get_nodes_in_group("espectros")
	_deleting_batch = true
	_delete_enemies_batch()

# ✅ Eliminar enemigos en lotes (5 por frame) para evitar frame drops
func _delete_enemies_batch() -> void:
	if not _deleting_batch or _enemigos_pendientes_delete.is_empty():
		_deleting_batch = false
		return

	const BATCH_SIZE := 5
	var batch_count := 0

	while batch_count < BATCH_SIZE and _enemigos_pendientes_delete.size() > 0:
		var enemy = _enemigos_pendientes_delete.pop_front()
		if is_instance_valid(enemy):
			enemy.queue_free()
		batch_count += 1

	if _enemigos_pendientes_delete.size() > 0:
		await get_tree().process_frame
		_delete_enemies_batch()
