# res://scripts/enemigos/EnemigoBasico.gd
# Enemigo básico: persigue, ataca y da recompensa.

extends CharacterBody2D

signal enemigo_muerto(posicion: Vector2)

var vida_maxima: float = 5.0
var vida_actual: float = 5.0
var velocidad: float = 80.0
var danio: float = 1.0
var recompensa: int = 5
var tipo: String = "basico"

const DISTANCIA_ATAQUE: float = 45.0
const INTERVALO_ATAQUE: float = 1.0
var timer_ataque: float = 0.0
var esta_muerto: bool = false
var nucleo: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemigos")
	await get_tree().process_frame
	nucleo = get_tree().get_first_node_in_group("nucleo")
	vida_actual = vida_maxima
	print("Enemigo listo, núcleo encontrado: ", nucleo != null)

func configurar(datos: Dictionary) -> void:
	vida_maxima = datos.get("hp", vida_maxima)
	vida_actual = vida_maxima
	velocidad   = datos.get("spd_px", velocidad)
	danio       = datos.get("atk", danio)
	recompensa  = datos.get("recompensa", recompensa)
	tipo        = datos.get("tipo", tipo)
	if sprite: scale = Vector2.ONE * clamp(vida_maxima / 5.0, 0.8, 1.5)

func _physics_process(delta: float) -> void:
	if esta_muerto or not is_instance_valid(nucleo): return
	
	var dist = global_position.distance_to(nucleo.global_position)
	if dist > DISTANCIA_ATAQUE:
		var dir = (nucleo.global_position - global_position).normalized()
		velocity = dir * velocidad
		rotation = dir.angle() + PI/2.0
		timer_ataque = 0.0
	else:
		velocity = Vector2.ZERO
		timer_ataque -= delta
		if timer_ataque <= 0.0:
			if nucleo.has_method("recibir_dano"):
				nucleo.recibir_dano(danio)
			timer_ataque = INTERVALO_ATAQUE
			
	move_and_slide()

func recibir_dano(cantidad: float, _es_critico: bool = false) -> void:
	if esta_muerto: return
	vida_actual -= cantidad
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.05).timeout
		if is_instance_valid(sprite): sprite.modulate = Color.WHITE
		
	if vida_actual <= 0.0: morir()

func morir() -> void:
	if esta_muerto: return
	esta_muerto = true
	set_physics_process(false)
	remove_from_group("enemigos")
	
	# 🔥 CREAR EXPLOSIÓN
	var explosion = preload("res://escenas/objetos/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	
	Economia.procesar_drop_enemigo({"recompensa": recompensa, "tipo": tipo})
	enemigo_muerto.emit(global_position)
	
	var tw = create_tween()
	if sprite:
		tw.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.2)
		tw.parallel().tween_property(sprite, "modulate", Color.TRANSPARENT, 0.2)
	tw.tween_callback(queue_free)

# Mantenida para compatibilidad
func _on_area_deteccion_area_entered(_area: Area2D) -> void:
	pass
