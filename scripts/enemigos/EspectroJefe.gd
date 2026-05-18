extends CharacterBody2D
# ═══════════════════════════════════════════════════
# ESPECTRO JEFE — Enemigo jefe (cada 15 ascensiones)
# ═══════════════════════════════════════════════════

signal espectro_destruido(posicion: Vector2, recompensa: int)

var salud_maxima: float = 1000.0
var salud_actual: float = 1000.0
var velocidad: float = 40.0  # Más lento
var danio_ataque: float = 15.0  # Más daño
var recompensa_energia: int = 100
var tipo_espectro: String = "jefe"

const DISTANCIA_ATAQUE: float = 85.0
const INTERVALO_ATAQUE: float = 1.5
var temporizador_ataque: float = 0.0
var esta_destruido: bool = false

@onready var sprite: Sprite2D = $Sprite2D
var nexus: Node2D = null

func _ready() -> void:
	add_to_group("espectros")
	await get_tree().process_frame
	nexus = get_tree().get_first_node_in_group("nexus")
	salud_actual = salud_maxima
	print("👾 JEFE aparecido! Salud: ", salud_actual)

func configurar(datos: Dictionary) -> void:
	salud_maxima = datos.get("hp", 1000.0)
	salud_actual = salud_maxima
	velocidad = datos.get("spd_px", 40.0)
	danio_ataque = datos.get("atk", 15.0)
	recompensa_energia = datos.get("recompensa", 100)
	tipo_espectro = datos.get("tipo", "jefe")
	if sprite:
		scale = Vector2.ONE * clamp(salud_maxima / 1000.0, 1.0, 3.0)

func _physics_process(delta: float) -> void:
	if esta_destruido or not is_instance_valid(nexus): return
	
	var distancia = global_position.distance_to(nexus.global_position)
	
	if distancia > DISTANCIA_ATAQUE:
		var direccion = (nexus.global_position - global_position).normalized()
		velocity = direccion * velocidad
		rotation += 1.0 * delta
		temporizador_ataque = 0.0
	else:
		velocity = Vector2.ZERO
		temporizador_ataque -= delta
		if temporizador_ataque <= 0.0:
			if nexus.has_method("recibir_ataque"):
				nexus.recibir_ataque(danio_ataque)
			temporizador_ataque = INTERVALO_ATAQUE
			
	move_and_slide()

func recibir_dano(cantidad: float, es_critico: bool = false) -> void:
	if esta_destruido: return
	salud_actual -= cantidad
	_efecto_dano(es_critico)
	if salud_actual <= 0.0:
		_destruir()
	print("💥 JEFE recibe daño: ", cantidad, " | Salud restante: ", salud_actual)

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
	remove_from_group("espectros")
	
	# Texto flotante de energía
	var texto_energia = preload("res://escenas/objetos/TextoFlotante.tscn").instantiate()
	texto_energia.set_energia(recompensa_energia)
	texto_energia.global_position = global_position
	get_tree().current_scene.add_child(texto_energia)
	
	# Explosión más grande
	var explosion = preload("res://escenas/Objetos/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.scale = Vector2(2.0, 2.0)
	get_tree().current_scene.add_child(explosion)
	
	# 5 fragmentos al morir
	for i in range(5):
		var fragmento = preload("res://escenas/objetos/Fragmento.tscn").instantiate()
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
		tw.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.35)
		tw.parallel().tween_property(sprite, "self_modulate", Color(1.0, 0.5, 0.1, 0.0), 0.35)
	tw.tween_callback(queue_free)
	
