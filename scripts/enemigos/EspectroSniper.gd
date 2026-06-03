extends CharacterBody2D
# ═══════════════════════════════════════════════════
# ESPECTRO SNIPER — Enemigo de largo alcance orbital
# ═══════════════════════════════════════════════════

signal espectro_destruido(posicion: Vector2, recompensa: int)

var salud_maxima: float = 60.0
var salud_actual: float = 60.0
var velocidad: float = 100.0
var danio_ataque: float = 8.0
var recompensa_energia: int = 15
var tipo_espectro: String = "sniper"

const ESCENA_TEXTO     = preload("res://escenas/Objetos/TextoFlotante.tscn")
const ESCENA_EXPLOSION = preload("res://escenas/Objetos/Explosion.tscn")
const ESCENA_FRAGMENTO = preload("res://escenas/Objetos/fragmento.tscn")

# Posicionamiento orbital
var angulo_actual: float = 0.0
const VELOCIDAD_ORBITAL: float = 1.0
const DISTANCIA_INICIAL: float = 600.0
const DISTANCIA_MINIMA: float = 250.0
const PASO_AVANCE: float = 100.0

# Cadencia de disparo
const COOLDOWN_DISPARO: float = 2.5
const DURACION_ORBITA: float = 2.0
const DISPAROS_ANTES_AVANZAR: int = 3

var distancia_objetivo: float = DISTANCIA_INICIAL
var disparos_realizados: int = 0
var timer_estado: float = 0.0
var esta_destruido: bool = false

enum Estado { DISPARANDO, ENFRIAMIENTO, ORBITANDO }
var estado: Estado = Estado.DISPARANDO

@onready var sprite: Sprite2D = $Sprite2D
var nexus: Node2D = null

func _ready() -> void:
	add_to_group("espectros")
	await get_tree().process_frame
	nexus = get_tree().get_first_node_in_group("nexus")
	salud_actual = salud_maxima
	if nexus:
		angulo_actual = (global_position - nexus.global_position).angle()

func configurar(datos: Dictionary) -> void:
	salud_maxima = datos.get("hp", 60.0)
	salud_actual = salud_maxima
	velocidad = datos.get("spd_px", 100.0)
	danio_ataque = datos.get("atk", 8.0)
	recompensa_energia = datos.get("recompensa", 15)
	tipo_espectro = datos.get("tipo", "sniper")

func _process(delta: float) -> void:
	if esta_destruido or not is_instance_valid(nexus): return

	match estado:
		Estado.DISPARANDO:
			_disparar()
			disparos_realizados += 1
			if disparos_realizados >= DISPAROS_ANTES_AVANZAR:
				disparos_realizados = 0
				distancia_objetivo = max(distancia_objetivo - PASO_AVANCE, DISTANCIA_MINIMA)
			timer_estado = COOLDOWN_DISPARO
			estado = Estado.ENFRIAMIENTO

		Estado.ENFRIAMIENTO:
			timer_estado -= delta
			if timer_estado <= 0.0:
				timer_estado = DURACION_ORBITA
				estado = Estado.ORBITANDO

		Estado.ORBITANDO:
			angulo_actual += VELOCIDAD_ORBITAL * delta
			timer_estado -= delta
			if timer_estado <= 0.0:
				estado = Estado.DISPARANDO

func _physics_process(delta: float) -> void:
	if esta_destruido or not is_instance_valid(nexus): return

	var dir = Vector2(cos(angulo_actual), sin(angulo_actual))
	var objetivo = nexus.global_position + dir * distancia_objetivo
	velocity = (objetivo - global_position).normalized() * velocidad
	rotation = (nexus.global_position - global_position).angle()
	velocity *= _mult_lentitud(delta)
	move_and_slide()

func _disparar() -> void:
	if not nexus: return
	if nexus.has_method("recibir_ataque"):
		nexus.recibir_ataque(danio_ataque, tipo_espectro)
	_efecto_disparo()

func _efecto_disparo() -> void:
	if not sprite: return
	var tw = create_tween()
	tw.tween_property(sprite, "self_modulate", Color(3.0, 3.0, 0.5), 0.05)
	tw.tween_property(sprite, "self_modulate", Color.WHITE, 0.25)

var _lentitud_factor: float = 0.0
var _lentitud_timer: float = 0.0

func aplicar_lentitud(factor: float, duracion: float) -> void:
	_lentitud_factor = maxf(_lentitud_factor, factor)
	_lentitud_timer = maxf(_lentitud_timer, duracion)

func _mult_lentitud(delta: float) -> float:
	if _lentitud_timer > 0.0:
		_lentitud_timer -= delta
		if _lentitud_timer <= 0.0:
			_lentitud_factor = 0.0
			return 1.0
		return 1.0 - _lentitud_factor
	return 1.0

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
		tw.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.22)
		tw.parallel().tween_property(sprite, "self_modulate", Color(1.0, 1.0, 0.2, 0.0), 0.28)
	tw.tween_callback(queue_free)
