extends Area2D

var direccion: Vector2 = Vector2.RIGHT
var velocidad: float = 400.0
var danio: float = 10.0
var es_critico: bool = false

@onready var timer_vida: Timer = $TimerVida

func _ready() -> void:
	timer_vida.wait_time = 4.0
	timer_vida.timeout.connect(queue_free)
	timer_vida.start()

func _physics_process(delta: float) -> void:
	position += direccion * velocidad * delta

func _on_body_entered(body: Node) -> void:
	# ✅ Verificar que el body siga existiendo
	if not is_instance_valid(body):
		return
		
	if body.is_in_group("enemigos"):
		var dano_final = danio
		if es_critico:
			dano_final *= 1.5
			
		if body.has_method("recibir_dano"):
			# ✅ CORREGIDO: Pasar ambos parámetros
			body.recibir_dano(dano_final, es_critico)
		
		queue_free()
