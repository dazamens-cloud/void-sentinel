extends Area2D
# ═══════════════════════════════════════════════════
# PROYECTIL — Proyectil del Nexus (antes bala.gd)
# ═══════════════════════════════════════════════════

var direccion: Vector2 = Vector2.RIGHT
var velocidad: float = 600.0
var danio: float = 10.0
var es_critico: bool = false

# ✨ NUEVO: Sistema de disparos especiales
var es_especial: bool = false
var color_especial: Color = Color.GOLDENROD
var escala_especial: float = 1.5
var velocidad_especial: float = 200.0

@onready var timer_vida: Timer = $TimerVida
@onready var sprite: Sprite2D = $Sprite2D

var _visual_especial_aplicado: bool = false

func _ready() -> void:
	add_to_group("proyectiles")
	timer_vida.wait_time = 4.0
	timer_vida.timeout.connect(queue_free)
	timer_vida.start()

func _aplicar_visual_especial() -> void:
	"""Aplica visuales especiales al proyectil."""
	if sprite:
		sprite.modulate = color_especial
		sprite.scale *= escala_especial
	
	# Reducir velocidad para que sea visible
	velocidad_especial = 200.0  # Más lento que normal
	print("✨ Proyectil especial activado (Dorado, 1.5×)")

func _physics_process(delta: float) -> void:
	if es_especial and not _visual_especial_aplicado:
		_aplicar_visual_especial()
		_visual_especial_aplicado = true

	var velocidad_actual = velocidad_especial if es_especial else velocidad
	position += direccion * velocidad_actual * delta

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(body): return
	if body.is_in_group("espectros"):
		# ✨ NUEVO: Disparos especiales NO atraviesan, solo dañan Commander
		if es_especial:
			# Solo daña si es Commander
			if body.tipo_espectro == "commander":
				var dano_final = danio
				if es_critico:
					dano_final *= 1.5
				if body.has_method("recibir_dano"):
					body.recibir_dano(dano_final, es_critico)
				_destruir()
			# Si no es Commander, lo atraviesa
		else:
			# Disparo normal: daña y se destruye
			var dano_final = danio
			if es_critico:
				dano_final *= 1.5
			if body.has_method("recibir_dano"):
				body.recibir_dano(dano_final, es_critico)
			_destruir()

func _destruir() -> void:
	"""Destruye el proyectil con efecto."""
	if sprite:
		sprite.visible = false
	
	# ✨ Efecto de impacto si es especial
	if es_especial:
		# Crear pequeña explosión
		if get_tree():
			var temp_node = Node2D.new()
			temp_node.global_position = global_position
			get_tree().current_scene.add_child(temp_node)
			var tw = create_tween()
			tw.tween_callback(temp_node.queue_free).set_delay(0.1)
	
	queue_free()
