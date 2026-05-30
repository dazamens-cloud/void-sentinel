extends CharacterBody2D
# ═══════════════════════════════════════════════════
# ESPECTRO KAMIKAZE — Enemigo suicida de alta velocidad
# ═══════════════════════════════════════════════════

signal espectro_destruido(posicion: Vector2, recompensa: int)

var salud_maxima: float = 30.0
var salud_actual: float = 30.0
var velocidad_base: float = 200.0
var danio_explosion: float = 15.0
var recompensa_energia: int = 8
var tipo_espectro: String = "kamikaze"

const RADIO_EXPLOSION: float = 60.0
const ACELERACION_POR_SEG: float = 0.1
const MAX_MULTIPLICADOR_VELOCIDAD: float = 2.5
const ESCENA_TEXTO     = preload("res://escenas/Objetos/TextoFlotante.tscn")
const ESCENA_EXPLOSION = preload("res://escenas/Objetos/Explosion.tscn")
const ESCENA_FRAGMENTO = preload("res://escenas/Objetos/fragmento.tscn")

var tiempo_vivo: float = 0.0
var esta_destruido: bool = false
var parpadeo_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
var nexus: Node2D = null

func _ready() -> void:
	add_to_group("espectros")
	await get_tree().process_frame
	nexus = get_tree().get_first_node_in_group("nexus")
	salud_actual = salud_maxima

func configurar(datos: Dictionary) -> void:
	salud_maxima = datos.get("hp", 30.0)
	salud_actual = salud_maxima
	velocidad_base = datos.get("spd_px", 200.0)
	danio_explosion = datos.get("atk", 15.0)
	recompensa_energia = datos.get("recompensa", 8)
	tipo_espectro = datos.get("tipo", "kamikaze")

func _physics_process(delta: float) -> void:
	if esta_destruido or not is_instance_valid(nexus): return

	tiempo_vivo += delta
	var multiplicador = min(1.0 + tiempo_vivo * ACELERACION_POR_SEG, MAX_MULTIPLICADOR_VELOCIDAD)
	var velocidad_actual = velocidad_base * multiplicador

	var distancia = global_position.distance_to(nexus.global_position)
	if distancia <= RADIO_EXPLOSION:
		_explotar_en_nexus()
		return

	var direccion = (nexus.global_position - global_position).normalized()
	velocity = direccion * velocidad_actual
	rotation = direccion.angle()
	move_and_slide()

	_actualizar_parpadeo(delta, distancia)

func _actualizar_parpadeo(delta: float, distancia: float) -> void:
	if not sprite: return
	var ratio = clamp(1.0 - distancia / 800.0, 0.0, 1.0)
	var vel_parpadeo = lerp(2.0, 10.0, ratio)
	parpadeo_timer = fmod(parpadeo_timer + delta * vel_parpadeo, 1.0)
	var intensidad = sin(parpadeo_timer * TAU) * 0.5 + 0.5
	sprite.self_modulate = Color.WHITE.lerp(Color(1.0, 0.2, 0.0), intensidad)

func recibir_dano(cantidad: float, es_critico: bool = false) -> void:
	if esta_destruido: return
	salud_actual -= cantidad
	_efecto_dano(es_critico)
	if salud_actual <= 0.0:
		_destruir()

func _efecto_dano(es_critico: bool) -> void:
	if not sprite: return
	var color = Color(2.0, 1.5, 0.1) if es_critico else Color(1.8, 0.3, 0.3)
	var tw = create_tween()
	tw.tween_property(sprite, "self_modulate", color, 0.05)
	tw.tween_property(sprite, "self_modulate", Color.WHITE, 0.10)

# Llega al nexus: daño alto, sin recompensa
func _explotar_en_nexus() -> void:
	if esta_destruido: return
	esta_destruido = true
	set_physics_process(false)
	remove_from_group("espectros")

	if nexus and nexus.has_method("recibir_ataque"):
		nexus.recibir_ataque(danio_explosion)

	var explosion = ESCENA_EXPLOSION.instantiate()
	explosion.global_position = global_position
	explosion.scale = Vector2(1.5, 1.5)
	get_tree().current_scene.add_child(explosion)

	Economia.procesar_drop_espectro({
		"recompensa": recompensa_energia,
		"tipo": tipo_espectro,
		"posicion": global_position
	})
	espectro_destruido.emit(global_position, recompensa_energia)
	queue_free()

# Muere antes de llegar: recompensa normal
func _destruir() -> void:
	if esta_destruido: return
	esta_destruido = true
	set_physics_process(false)
	remove_from_group("espectros")

	var texto_energia = ESCENA_TEXTO.instantiate()
	texto_energia.set_energia(recompensa_energia)
	texto_energia.global_position = global_position
	get_tree().current_scene.add_child(texto_energia)

	var explosion = ESCENA_EXPLOSION.instantiate()
	explosion.global_position = global_position
	explosion.scale = Vector2(0.8, 0.8)
	get_tree().current_scene.add_child(explosion)

	var fragmento = ESCENA_FRAGMENTO.instantiate()
	fragmento.global_position = global_position
	get_tree().current_scene.add_child(fragmento)

	Economia.procesar_drop_espectro({
		"recompensa": recompensa_energia,
		"tipo": tipo_espectro,
		"posicion": global_position
	})
	espectro_destruido.emit(global_position, recompensa_energia)

	var tw = create_tween()
	if sprite:
		tw.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.15)
		tw.parallel().tween_property(sprite, "self_modulate", Color(1.0, 0.3, 0.0, 0.0), 0.20)
	tw.tween_callback(queue_free)
