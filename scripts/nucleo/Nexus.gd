extends Area2D
# ═══════════════════════════════════════════════════
# NEXUS — Torre principal de Void Sentinel
# ═══════════════════════════════════════════════════

@export var escena_proyectil: PackedScene
@onready var timer_disparo: Timer = $TimerAutoDisparo
@onready var sprite: Sprite2D = $Sprite2D

var esta_destruido: bool = false

func _ready() -> void:
	add_to_group("nexus")
	
	# ✅ Verificar que el Timer existe
	if timer_disparo == null:
		print("❌ ERROR: TimerAutoDisparo no encontrado en Nexus")
		return
	
	timer_disparo.timeout.connect(_disparar)
	NexusStats.stats_actualizadas.connect(_on_stats_actualizadas)

	timer_disparo.wait_time = NexusStats.get_cadencia_timer()
	timer_disparo.start()

	print("✅ Nexus iniciado. Cadencia: ", timer_disparo.wait_time, "s")
	
	await get_tree().process_frame
	queue_redraw()

func _process(delta: float) -> void:
	if esta_destruido: return
	rotation += 0.2 * delta
	
	var regen = NexusStats.get_regeneracion()
	if regen > 0.0:
		NexusStats.curar(regen * delta)
	
	_actualizar_color()

func _actualizar_color() -> void:
	if NexusStats.salud_actual <= 0:
		sprite.modulate = Color(0.2, 0.2, 0.2)
	elif NexusStats.salud_actual < NexusStats.get_salud() * 0.3:
		sprite.modulate = Color(1.0, 0.2, 0.2)
	else:
		sprite.modulate = Color.WHITE

func _disparar() -> void:
	if esta_destruido:
		return
		
	if not escena_proyectil:
		print("❌ ERROR: escena_proyectil no asignada en Nexus")
		return
	
	var espectros = get_tree().get_nodes_in_group("espectros")
	
	if espectros.size() == 0:
		return
	
	var objetivo = null
	var dist_min = NexusStats.get_rango_escaneo()
	
	for e in espectros:
		if is_instance_valid(e):
			var d = global_position.distance_to(e.global_position)
			if d < dist_min:
				dist_min = d
				objetivo = e
				
	if objetivo:
		var proyectil = escena_proyectil.instantiate()
		get_tree().root.add_child(proyectil)
		proyectil.global_position = global_position
		proyectil.direccion = (objetivo.global_position - global_position).normalized()
		proyectil.rotation = proyectil.direccion.angle()
		proyectil.danio = NexusStats.get_danio()
		# print("🔫 Nexus disparando. Espectros en rango: ", espectros.size())  # Descomentar para debug

func recibir_ataque(cantidad: float) -> void:
	if esta_destruido: return
	
	var dano_final = cantidad
	var def_pct = Economia.get_defensa()
	if def_pct > 0.0:
		dano_final = max(1.0, cantidad * (1.0 - def_pct))
	
	NexusStats.recibir_ataque(dano_final)

	_parpadeo_dano()

	var texto_dano = preload("res://escenas/Objetos/TextoFlotante.tscn").instantiate()
	texto_dano.set_valor(dano_final, "dano")
	texto_dano.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	texto_dano.global_position = global_position
	get_tree().current_scene.add_child(texto_dano)

	if NexusStats.salud_actual <= 0.0:
		print("💥 Nexus destruido!")
		_destruir()

func _destruir() -> void:
	if esta_destruido: return
	esta_destruido = true
	timer_disparo.stop()
	sprite.modulate = Color(0.2, 0.2, 0.2)
	Economia.juego_terminado.emit("Nexus Destruido")

func _on_stats_actualizadas() -> void:
	if not esta_destruido:
		timer_disparo.wait_time = NexusStats.get_cadencia_timer()

func _parpadeo_dano() -> void:
	var t = create_tween()
	t.tween_property(sprite, "self_modulate", Color(1.5, 0.2, 0.2), 0.05)
	t.tween_property(sprite, "self_modulate", Color.WHITE, 0.1)

func _draw() -> void:
	var rango: float = NexusStats.get_rango_escaneo()
	var pulso := 0.70 + 0.30 * sin(Time.get_ticks_msec() * 0.003)

	draw_circle(Vector2.ZERO, rango,
		Color(0.0, 0.85, 1.0, 0.05 * pulso))
	
	draw_arc(Vector2.ZERO, rango, 0.0, TAU, 72,
		Color(0.0, 0.85, 1.0, 0.55 * pulso), 2.5)
