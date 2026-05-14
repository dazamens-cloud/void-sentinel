extends Area2D

@export var escena_proyectil: PackedScene
@onready var timer_disparo: Timer = $TimerAutoDisparo
@onready var sprite: Sprite2D = $Sprite2D

var esta_muerto: bool = false

func _ready() -> void:
	add_to_group("nucleo")
	
	if timer_disparo == null:
		print("ERROR: TimerAutoDisparo no encontrado")
		return
	
	timer_disparo.timeout.connect(_disparar)
	timer_disparo.wait_time = TorreStats.get_cadencia_timer()
	timer_disparo.start()
	
	print("Núcleo listo. Timer iniciado con wait_time = ", timer_disparo.wait_time)

func _process(delta: float) -> void:
	if esta_muerto: return
	rotation += 0.2 * delta
	
	var regen = TorreStats.get_regeneracion()
	if regen > 0.0:
		TorreStats.curar(regen * delta)
	
	_actualizar_color_por_vida()

func _actualizar_color_por_vida() -> void:
	if not is_instance_valid(sprite): return
	
	if TorreStats.vida_actual <= 0:
		sprite.modulate = Color(0.2, 0.2, 0.2)
	elif TorreStats.vida_actual < TorreStats.get_salud() * 0.3:
		sprite.modulate = Color(1.0, 0.2, 0.2)
	else:
		sprite.modulate = Color.WHITE

func _disparar() -> void:
	if esta_muerto:
		return
		
	if not escena_proyectil:
		print("ERROR: escena_proyectil no asignada")
		return
	
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	
	if enemigos.size() == 0:
		return
	
	var objetivo = null
	var dist_min = TorreStats.get_rango_escaneo()
	
	for e in enemigos:
		if is_instance_valid(e):
			var d = global_position.distance_to(e.global_position)
			if d < dist_min:
				dist_min = d
				objetivo = e
				
	if objetivo:
		var bala = escena_proyectil.instantiate()
		get_tree().root.add_child(bala)
		bala.global_position = global_position
		bala.direccion = (objetivo.global_position - global_position).normalized()
		bala.rotation = bala.direccion.angle()
		bala.danio = TorreStats.get_dano()

func recibir_dano(cantidad: float) -> void:
	print("nucleo.gd: recibir_dano llamado con cantidad = ", cantidad)
	
	if esta_muerto:
		print("Núcleo ya está muerto, ignorando daño")
		return
	
	var dano_final = cantidad
	var def_pct = Economia.get_defensa()
	if def_pct > 0.0:
		dano_final = max(1.0, cantidad * (1.0 - def_pct))
		print("Defensa aplicada: ", def_pct, "%, daño final: ", dano_final)
	
	# Registrar en Economia (si existe)
	if Economia.has_method("registrar_dano_recibido"):
		Economia.registrar_dano_recibido(dano_final)
	
	# ✅ Aplicar daño a TorreStats
	var sigue_vivo = TorreStats.recibir_dano(dano_final)
	print("Vida después del daño: ", TorreStats.vida_actual, "/", TorreStats.get_salud())
	
	_parpadeo_dano()
	
	if not sigue_vivo:
		print("El núcleo ha muerto!")
		_morir()

func _morir() -> void:
	if esta_muerto: return
	esta_muerto = true
	timer_disparo.stop()
	sprite.modulate = Color(0.2, 0.2, 0.2)
	Economia.terminar_juego("Núcleo Destruido")
	print("Núcleo destruido. Juego terminado.")

func _parpadeo_dano() -> void:
	if not is_instance_valid(sprite): return
	var t = create_tween()
	t.tween_property(sprite, "self_modulate", Color(1.5, 0.2, 0.2), 0.05)
	t.tween_property(sprite, "self_modulate", Color.WHITE, 0.1)
