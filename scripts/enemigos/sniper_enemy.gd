extends CharacterBody2D

# Referencias
@export var nucleus: Node2D  # Asignar el núcleo desde el editor
@export var projectile_scene: PackedScene  # Escena de la bala del sniper

# Configuración de movimiento
@export var speed: float = 100.0
@export var orbit_speed: float = 1.0  # radianes por segundo
@export var orbit_duration: float = 2.0  # segundos orbitando entre disparos

# Configuración de combate
@export var initial_distance: float = 600.0
@export var distance_step: float = 150.0  # Cuánto se acerca cada vez
@export var min_distance: float = 200.0  # Distancia mortal (rango del núcleo)
@export var max_shots: int = 4  # Número de disparos antes de llegar al rango mortal
@export var shot_cooldown: float = 1.0

# Estado interno
enum State { ENTERING, SHOOT, COOLDOWN, ORBIT, ADVANCE, IN_DANGER }
var state: State = State.ENTERING
var current_angle: float = 0.0
var target_distance: float
var shots_fired: int = 0

# Timers
var cooldown_timer: float = 0.0
var orbit_timer: float = 0.0
var evasion_timer: float = 0.0

# Salud
@export var max_health: int = 3
var current_health: int

func _ready():
	current_health = max_health
	target_distance = initial_distance
	
	# Calcular ángulo inicial basado en posición de spawn
	if nucleus:
		var to_self = global_position - nucleus.global_position
		current_angle = to_self.angle()
	
	# Empezar directamente disparando cuando aparece
	state = State.SHOOT

func _process(delta):
	if not nucleus or not is_instance_valid(nucleus):
		queue_free()
		return
	
	match state:
		State.SHOOT:
			_shoot()
		
		State.COOLDOWN:
			_cooldown(delta)
		
		State.ORBIT:
			_orbit(delta)
		
		State.ADVANCE:
			_advance()
		
		State.IN_DANGER:
			_evade(delta)

func _physics_process(delta):
	# Mantener posición orbital
	if state != State.IN_DANGER:
		_maintain_orbit(delta)

func _maintain_orbit(delta):
	"""Mantiene al sniper en órbita circular alrededor del núcleo"""
	var direction = Vector2(cos(current_angle), sin(current_angle))
	var target_pos = nucleus.global_position + direction * target_distance
	
	# Moverse suavemente hacia la posición orbital objetivo
	global_position = global_position.move_toward(target_pos, speed * delta)

func _shoot():
	"""Dispara al núcleo"""
	if projectile_scene and nucleus:
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position
		
		# Dirección hacia el núcleo
		var direction = (nucleus.global_position - global_position).normalized()
		
		# Si tu bala tiene un método set_direction o similar
		if projectile.has_method("set_direction"):
			projectile.set_direction(direction)
		elif "direction" in projectile:
			projectile.direction = direction
	
	shots_fired += 1
	cooldown_timer = shot_cooldown
	state = State.COOLDOWN

func _cooldown(delta):
	"""Espera después de disparar"""
	cooldown_timer -= delta
	if cooldown_timer <= 0:
		orbit_timer = orbit_duration
		state = State.ORBIT

func _orbit(delta):
	"""Se mueve lateralmente alrededor del núcleo"""
	# Incrementar el ángulo (movimiento circular)
	current_angle += orbit_speed * delta
	
	orbit_timer -= delta
	if orbit_timer <= 0:
		state = State.ADVANCE

func _advance():
	"""Se acerca al núcleo"""
	if shots_fired >= max_shots or target_distance <= min_distance:
		# Ya está en rango mortal, solo sigue disparando
		state = State.SHOOT
	else:
		# Acercarse más
		target_distance -= distance_step
		target_distance = max(target_distance, min_distance)
		state = State.SHOOT

func _evade(delta):
	"""Movimiento evasivo cuando el núcleo le dispara"""
	# Acelerar la órbita temporalmente
	current_angle += orbit_speed * 3.0 * delta
	
	evasion_timer -= delta
	if evasion_timer <= 0:
		# Volver al estado anterior
		state = State.ORBIT
		orbit_timer = orbit_duration * 0.5  # Menos tiempo orbitando

func on_nucleus_shooting():
	"""Llamar esta función cuando detectes que el núcleo está disparando"""
	if state != State.IN_DANGER:
		evasion_timer = 0.5  # Medio segundo de evasión
		state = State.IN_DANGER

func take_damage(amount: int):
	"""Recibe daño"""
	current_health -= amount
	if current_health <= 0:
		die()

func die():
	"""Muerte del sniper"""
	# Aquí puedes añadir animación de muerte, partículas, etc.
	queue_free()

# Función auxiliar para debugging
func _draw():
	if Engine.is_editor_hint():
		return
	
	# Dibujar línea hacia el núcleo (opcional, para debug)
	if nucleus and is_instance_valid(nucleus):
		var to_nucleus = nucleus.global_position - global_position
		draw_line(Vector2.ZERO, to_nucleus, Color.RED, 1.0)
		
		# Dibujar círculo de órbita objetivo
		var local_nucleus = to_global(nucleus.global_position)
		draw_arc(Vector2.ZERO, target_distance, 0, TAU, 32, Color.YELLOW, 1.0)
