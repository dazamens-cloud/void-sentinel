extends Area2D
# ═══════════════════════════════════════════════════
# PROYECTIL — Proyectil del Nexus (antes bala.gd)
# ═══════════════════════════════════════════════════

var direccion: Vector2 = Vector2.RIGHT
var velocidad: float = 600.0
var danio: float = 10.0
var es_critico: bool = false

# Rebote (mejora "rebote" / "alcance_rebote")
var rebotes_restantes: int = 0
var alcance_rebote: float = 0.0
var _ya_golpeados: Array = []

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
	if not body.is_in_group("espectros"): return

	# El daño ya incluye el factor crítico (lo aplica el Nexus al disparar)
	if es_especial:
		# Disparo especial: solo daña al Commander, atraviesa al resto
		if body.get("tipo_espectro") == "commander":
			if body.has_method("recibir_dano"):
				body.recibir_dano(danio, es_critico)
			_destruir()
		return

	# Disparo normal: daña al objetivo
	if body.has_method("recibir_dano"):
		body.recibir_dano(danio, es_critico)
	_ya_golpeados.append(body)

	# ✅ Rebote: salta al enemigo más cercano que no haya sido golpeado
	if rebotes_restantes > 0:
		var siguiente := _buscar_objetivo_rebote(body)
		if siguiente:
			rebotes_restantes -= 1
			direccion = (siguiente.global_position - global_position).normalized()
			rotation = direccion.angle()
			return
	_destruir()

func _buscar_objetivo_rebote(actual: Node) -> Node2D:
	var mejor: Node2D = null
	var dist_min := alcance_rebote
	for e in get_tree().get_nodes_in_group("espectros"):
		if not is_instance_valid(e) or e == actual: continue
		if e in _ya_golpeados: continue
		if e.get("tipo_espectro") == "commander": continue
		var d := global_position.distance_to(e.global_position)
		if d < dist_min:
			dist_min = d
			mejor = e
	return mejor

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
