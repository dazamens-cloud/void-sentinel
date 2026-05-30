extends CharacterBody2D
# ═══════════════════════════════════════════════════
# ESPECTRO COMMANDER — Invocador orbital táctico
# ═══════════════════════════════════════════════════

signal espectro_destruido(posicion: Vector2, recompensa: int)

var salud_maxima: float = 200.0
var salud_actual: float = 200.0
var velocidad: float = 100.0
var recompensa_energia: int = 40
var tipo_espectro: String = "commander"

# Movimiento orbital
var angulo_actual: float = 0.0
const VELOCIDAD_ORBITAL: float = 0.5
const DISTANCIA_ORBITAL: float = 800.0

# Sistema de spawn
var cooldown_spawn: float = 0.0
var en_advertencia: bool = false
var tipo_spawn_pendiente: String = ""
var timer_advertencia: float = 0.0
const COOLDOWN_BASE_SPAWN: float = 3.0
const MAX_ESPECTROS_VIVOS: int = 20

var esta_destruido: bool = false

# Sistema de escape (3 minutos)
var timer_escape: float = 180.0
var escapando: bool = false

@onready var sprite: Sprite2D = $Sprite2D
var nexus: Node2D = null

const ESCENA_BASICO    = preload("res://escenas/enemigos/Espectro.tscn")
const ESCENA_TANQUE    = preload("res://escenas/enemigos/EspectroTanque.tscn")
const ESCENA_KAMIKAZE  = preload("res://escenas/enemigos/EspectroKamikaze.tscn")
const ESCENA_SNIPER    = preload("res://escenas/enemigos/EspectroSniper.tscn")
const ESCENA_TEXTO     = preload("res://escenas/Objetos/TextoFlotante.tscn")
const ESCENA_EXPLOSION = preload("res://escenas/Objetos/Explosion.tscn")
const ESCENA_FRAGMENTO = preload("res://escenas/Objetos/fragmento.tscn")

func _ready() -> void:
	add_to_group("espectros")
	add_to_group("commanders")
	await get_tree().process_frame
	nexus = get_tree().get_first_node_in_group("nexus")
	salud_actual = salud_maxima
	if nexus:
		angulo_actual = (global_position - nexus.global_position).angle()
	print("👾 Commander aparecido!")

func configurar(datos: Dictionary) -> void:
	salud_maxima = datos.get("hp", 200.0)
	salud_actual = salud_maxima
	velocidad = datos.get("spd_px", 100.0)
	recompensa_energia = datos.get("recompensa", 40)
	tipo_espectro = datos.get("tipo", "commander")

# ────────────────────────────────────────────────
# LOOP PRINCIPAL
# ────────────────────────────────────────────────

func _process(delta: float) -> void:
	if esta_destruido or not is_instance_valid(nexus): return

	if not escapando:
		timer_escape -= delta
		if timer_escape <= 0.0:
			_escapar()
			return

	if en_advertencia:
		_tick_advertencia(delta)
		return

	if cooldown_spawn > 0.0:
		cooldown_spawn -= delta
	elif _puede_spawnear():
		_preparar_spawn(_analizar_campo())

func _physics_process(delta: float) -> void:
	if esta_destruido or not is_instance_valid(nexus): return

	var salud_pct = salud_actual / salud_maxima
	if salud_pct < 0.3:
		var alejarse = (global_position - nexus.global_position).normalized()
		velocity = alejarse * velocidad * 2.0
	else:
		angulo_actual += VELOCIDAD_ORBITAL * delta
		var dir = Vector2(cos(angulo_actual), sin(angulo_actual))
		var objetivo = nexus.global_position + dir * DISTANCIA_ORBITAL
		velocity = (objetivo - global_position).normalized() * velocidad

	move_and_slide()

# ────────────────────────────────────────────────
# ANÁLISIS TÁCTICO
# ────────────────────────────────────────────────

func _puede_spawnear() -> bool:
	if en_advertencia: return false
	var vivos = get_tree().get_nodes_in_group("espectros").size()
	return vivos < MAX_ESPECTROS_VIVOS

func _analizar_campo() -> String:
	var num = {"basico": 0, "tanque": 0, "kamikaze": 0, "sniper": 0}
	var cerca_nexus: int = 0

	for e in get_tree().get_nodes_in_group("espectros"):
		if not is_instance_valid(e) or e == self: continue
		var tipo = e.get("tipo_espectro")
		if tipo in num:
			num[tipo] += 1
		if nexus and e.global_position.distance_to(nexus.global_position) < 300:
			cerca_nexus += 1

	if cerca_nexus < 2 and num["kamikaze"] < 3:
		return "kamikaze"

	var total = num["basico"] + num["tanque"] + num["kamikaze"] + num["sniper"]
	if total == 0:
		return "basico"

	if float(num["tanque"]) / total < 0.20 and num["tanque"] < 2:
		return "tanque"
	if float(num["kamikaze"]) / total < 0.15:
		return "kamikaze"
	if float(num["sniper"]) / total < 0.10 and Economia.numero_ascension >= 10:
		return "sniper"
	return "basico"

# ────────────────────────────────────────────────
# SPAWN CON ADVERTENCIA VISUAL
# ────────────────────────────────────────────────

func _preparar_spawn(tipo: String) -> void:
	tipo_spawn_pendiente = tipo
	en_advertencia = true
	timer_advertencia = 2.0
	match tipo:
		"basico":   modulate = Color(0.5, 0.5, 2.0)
		"tanque":   modulate = Color(0.3, 1.5, 0.3)
		"kamikaze": modulate = Color(2.0, 0.3, 0.3)
		"sniper":   modulate = Color(2.0, 2.0, 0.3)

func _tick_advertencia(delta: float) -> void:
	timer_advertencia -= delta
	var pulso = sin(timer_advertencia * 10.0) * 0.5 + 0.5
	if sprite: sprite.self_modulate = Color(1, 1, 1, 0.5 + pulso * 0.5)
	if timer_advertencia <= 0.0:
		_ejecutar_spawn()

func _ejecutar_spawn() -> void:
	var escena: PackedScene
	var datos: Dictionary

	match tipo_spawn_pendiente:
		"basico":
			escena = ESCENA_BASICO
			datos = {"hp": 100.0, "atk": 5.0, "spd_px": 80.0, "recompensa": 5, "tipo": "basico"}
		"tanque":
			escena = ESCENA_TANQUE
			datos = {"hp": 500.0, "atk": 5.0, "spd_px": 48.0, "recompensa": 12, "tipo": "tanque"}
		"kamikaze":
			escena = ESCENA_KAMIKAZE
			datos = {"hp": 30.0, "atk": 15.0, "spd_px": 200.0, "recompensa": 8, "tipo": "kamikaze"}
		"sniper":
			escena = ESCENA_SNIPER
			datos = {"hp": 60.0, "atk": 8.0, "spd_px": 100.0, "recompensa": 15, "tipo": "sniper"}

	if escena:
		var invocado = escena.instantiate()
		get_parent().add_child(invocado)
		invocado.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		if invocado.has_method("configurar"):
			invocado.configurar(datos)
		if invocado.has_signal("espectro_destruido"):
			invocado.espectro_destruido.connect(_on_invocado_destruido)

	cooldown_spawn = COOLDOWN_BASE_SPAWN
	_reiniciar_spawn()

func _reiniciar_spawn() -> void:
	en_advertencia = false
	tipo_spawn_pendiente = ""
	modulate = Color.WHITE
	if sprite: sprite.self_modulate = Color.WHITE

func _on_invocado_destruido(_pos: Vector2, _recompensa: int) -> void:
	pass

# ────────────────────────────────────────────────
# SISTEMA DE DAÑO
# ────────────────────────────────────────────────

func recibir_dano(cantidad: float, es_critico: bool = false) -> void:
	if esta_destruido: return
	salud_actual -= cantidad
	_efecto_dano(es_critico)
	if salud_actual <= 0.0:
		_destruir()

func _efecto_dano(es_critico: bool) -> void:
	if not sprite: return
	var color = Color(2.0, 1.5, 0.1) if es_critico else Color(2.0, 0.5, 0.5)
	var tw = create_tween()
	tw.tween_property(sprite, "self_modulate", color, 0.05)
	tw.tween_property(sprite, "self_modulate", Color.WHITE, 0.10)

func _destruir() -> void:
	if esta_destruido: return
	esta_destruido = true
	set_physics_process(false)
	set_process(false)
	remove_from_group("espectros")

	var texto_energia = ESCENA_TEXTO.instantiate()
	texto_energia.set_energia(recompensa_energia)
	texto_energia.global_position = global_position
	get_tree().current_scene.add_child(texto_energia)

	var explosion = ESCENA_EXPLOSION.instantiate()
	explosion.global_position = global_position
	explosion.scale = Vector2(2.5, 2.5)
	get_tree().current_scene.add_child(explosion)

	for i in range(4):
		var fragmento = ESCENA_FRAGMENTO.instantiate()
		fragmento.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		get_tree().current_scene.add_child(fragmento)

	Economia.procesar_drop_espectro({
		"recompensa": recompensa_energia,
		"tipo": tipo_espectro,
		"posicion": global_position
	})
	espectro_destruido.emit(global_position, recompensa_energia)

	var tw = create_tween()
	if sprite:
		tw.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.40)
		tw.parallel().tween_property(sprite, "self_modulate", Color(0.8, 0.2, 1.0, 0.0), 0.40)
	tw.tween_callback(queue_free)

# ────────────────────────────────────────────────
# ESCAPE DEL COMMANDER
# ────────────────────────────────────────────────

func _escapar() -> void:
	if esta_destruido: return

	print("🚀 COMMANDER ESCAPA!")
	escapando = true
	set_physics_process(false)

	var dir_huida = (global_position - nexus.global_position).normalized()

	var tw = create_tween()
	tw.tween_property(self, "global_position",
		global_position + dir_huida * 500, 2.0)
	if sprite:
		tw.parallel().tween_property(sprite, "self_modulate",
			Color(1, 1, 1, 0), 2.0)

	await tw.finished

	esta_destruido = true
	queue_free()
