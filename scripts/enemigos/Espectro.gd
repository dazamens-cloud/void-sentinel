extends CharacterBody2D
# ═══════════════════════════════════════════════════
# ESPECTRO — Enemigo básico de Void Sentinel
# ═══════════════════════════════════════════════════

signal espectro_destruido(posicion: Vector2, recompensa: int)

var salud_maxima: float = 100.0
var salud_actual: float = 100.0
var velocidad: float = 80.0
var danio_ataque: float = 5.0
var recompensa_energia: int = 5
var tipo_espectro: String = "basico"

const DISTANCIA_ATAQUE: float = 85.0
const INTERVALO_ATAQUE: float = 1.0
var temporizador_ataque: float = 0.0
var esta_destruido: bool = false

@onready var sprite: Sprite2D = $Sprite2D
var nexus: Node2D = null

func _ready() -> void:
	add_to_group("espectros")
	await get_tree().process_frame
	nexus = get_tree().get_first_node_in_group("nexus")
	salud_actual = salud_maxima
	print("👾 Espectro creado. Tipo: ", tipo_espectro, " | Salud: ", salud_actual)

func configurar(datos: Dictionary) -> void:
	salud_maxima = datos.get("hp", 100.0)
	salud_actual = salud_maxima
	velocidad = datos.get("spd_px", 80.0)
	danio_ataque = datos.get("atk", 5.0)
	recompensa_energia = datos.get("recompensa", 5)
	tipo_espectro = datos.get("tipo", "basico")
	if sprite:
		scale = Vector2.ONE * clamp(salud_maxima / 100.0, 0.55, 2.2)

func _physics_process(delta: float) -> void:
	if esta_destruido or not is_instance_valid(nexus): return
	
	var distancia = global_position.distance_to(nexus.global_position)
	
	if distancia > DISTANCIA_ATAQUE:
		var direccion = (nexus.global_position - global_position).normalized()
		velocity = direccion * velocidad
		rotation += 3.0 * delta
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
	print("⚔️ Espectro recibe daño: ", cantidad, " | Salud restante: ", salud_actual)
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
	remove_from_group("espectros")
	print("💀 Espectro muere")

	# 📝 TEXTO FLOTANTE de energía
	var texto_energia = preload("res://escenas/Objetos/TextoFlotante.tscn").instantiate()
	texto_energia.set_energia(recompensa_energia)
	texto_energia.global_position = global_position
	get_tree().current_scene.add_child(texto_energia)

	# 💥 EXPLOSIÓN
	var explosion = preload("res://escenas/Objetos/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)

	# 💰 ECONOMÍA (con posición para los ecos)
	Economia.procesar_drop_espectro({
		"recompensa": recompensa_energia,
		"tipo": tipo_espectro,
		"posicion": global_position
	})
	espectro_destruido.emit(global_position, recompensa_energia)

	# ✨ ANIMACIÓN DE MUERTE
	var tw = create_tween()
	if sprite:
		tw.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.22)
		tw.parallel().tween_property(sprite, "self_modulate", Color(1.0, 0.5, 0.1, 0.0), 0.28)
	tw.tween_callback(queue_free)
	
	# ✅ Fragmento al morir (ruta corregida)
	var fragmento = preload("res://escenas/Objetos/fragmento.tscn").instantiate()
	fragmento.global_position = global_position
	get_tree().current_scene.add_child(fragmento)
	
