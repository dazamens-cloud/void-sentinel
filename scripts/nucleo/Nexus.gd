extends Area2D
# ═══════════════════════════════════════════════════
# NEXUS — Torre principal de Void Sentinel
# ═══════════════════════════════════════════════════

@export var escena_proyectil: PackedScene
@onready var timer_disparo: Timer = $TimerAutoDisparo
@onready var sprite: Sprite2D = $Sprite2D

var esta_destruido: bool = false

# Sistema de disparos especiales
var disparando_especial: bool = false
var punto_inicio_drag: Vector2 = Vector2.ZERO
var objetivo_especial: Node2D = null

const ESCENA_TEXTO = preload("res://escenas/Objetos/TextoFlotante.tscn")

# Pulso de Quartz (onda defensiva periódica)
const PULSO_INTERVALO: float = 50.0
const PULSO_EMPUJE_BASE: float = 250.0
const PULSO_LENTITUD_DURACION: float = 2.0
var _pulso_cooldown: float = PULSO_INTERVALO

func _ready() -> void:
	add_to_group("nexus")

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

	# ✅ Pulso de Quartz (solo si la mejora está activa)
	if NexusStats.get_pulso_radio() > 0.0:
		_pulso_cooldown -= delta
		if _pulso_cooldown <= 0.0:
			_pulso_cooldown = PULSO_INTERVALO
			_emitir_pulso()

	_actualizar_color()

func _emitir_pulso() -> void:
	var radio := NexusStats.get_pulso_radio()
	if radio <= 0.0: return
	var lentitud := NexusStats.get_pulso_lentitud()
	var empuje_px := NexusStats.get_pulso_empuje() * PULSO_EMPUJE_BASE

	_efecto_visual_pulso(radio)

	for e in get_tree().get_nodes_in_group("espectros"):
		if not is_instance_valid(e): continue
		var dir: Vector2 = e.global_position - global_position
		if dir.length() > radio: continue
		# Empuje radial (aleja del Nexus)
		if empuje_px > 0.0 and dir.length() > 0.01:
			e.global_position += dir.normalized() * empuje_px
		# Lentitud temporal
		if lentitud > 0.0 and e.has_method("aplicar_lentitud"):
			e.aplicar_lentitud(lentitud, PULSO_LENTITUD_DURACION)
	print("🌀 Pulso de Quartz emitido (r=", int(radio), ")")

func _efecto_visual_pulso(radio: float) -> void:
	var poligono := Polygon2D.new()
	poligono.color = Color(0.3, 0.8, 1.0, 0.35)
	poligono.z_index = -1
	var puntos: PackedVector2Array = []
	for i in range(32):
		var ang := (float(i) / 32.0) * TAU
		puntos.append(Vector2(cos(ang), sin(ang)) * radio)
	poligono.polygon = puntos
	poligono.global_position = global_position
	poligono.scale = Vector2(0.1, 0.1)
	get_tree().current_scene.add_child(poligono)
	var tw := create_tween()
	tw.tween_property(poligono, "scale", Vector2.ONE, 0.4)
	tw.parallel().tween_property(poligono, "color", Color(0.3, 0.8, 1.0, 0.0), 0.4)
	tw.tween_callback(poligono.queue_free)

func _actualizar_color() -> void:
	if NexusStats.salud_actual <= 0:
		sprite.modulate = Color(0.2, 0.2, 0.2)
	elif NexusStats.salud_actual < NexusStats.get_salud() * 0.3:
		sprite.modulate = Color(1.0, 0.2, 0.2)
	else:
		sprite.modulate = Color.WHITE

func _disparar() -> void:
	if esta_destruido: return

	if not escena_proyectil:
		print("❌ ERROR: escena_proyectil no asignada en Nexus")
		return

	var espectros = get_tree().get_nodes_in_group("espectros")
	if espectros.size() == 0: return

	var objetivo = null
	var dist_min = NexusStats.get_rango_escaneo()

	for e in espectros:
		if not is_instance_valid(e): continue
		# Ignorar Commanders en disparo automático
		if e.get("tipo_espectro") == "commander": continue
		var d = global_position.distance_to(e.global_position)
		if d < dist_min:
			dist_min = d
			objetivo = e

	if objetivo:
		# ✅ Crítico: se tira una vez por disparo
		var critico := randf() < NexusStats.get_critico_chance()
		var danio_base := NexusStats.get_danio()
		if critico:
			danio_base *= NexusStats.get_critico_factor()

		var dir_base: Vector2 = (objetivo.global_position - global_position).normalized()
		# ✅ Multidisparo: proyectil principal + extras en abanico
		var total := 1 + NexusStats.get_multidisparo()
		for i in range(total):
			var dir := dir_base
			if total > 1:
				var paso := deg_to_rad(12.0)
				var offset := (float(i) - float(total - 1) / 2.0) * paso
				dir = dir_base.rotated(offset)
			_crear_proyectil(dir, danio_base, critico)

func _crear_proyectil(direccion: Vector2, danio_val: float, critico: bool) -> void:
	var proyectil = escena_proyectil.instantiate()
	get_tree().root.add_child(proyectil)
	proyectil.global_position = global_position
	proyectil.direccion = direccion
	proyectil.rotation = direccion.angle()
	proyectil.danio = danio_val
	proyectil.es_critico = critico
	# ✅ Rebote (si la mejora está activa y el proyectil lo soporta)
	if proyectil.get("rebotes_restantes") != null:
		proyectil.rebotes_restantes = NexusStats.get_rebote_cantidad()
		proyectil.alcance_rebote = NexusStats.get_rebote_alcance()

func recibir_ataque(cantidad: float) -> void:
	if esta_destruido: return

	var dano_final = cantidad
	var def_pct = NexusStats.get_defensa()
	if def_pct > 0.0:
		dano_final = max(1.0, cantidad * (1.0 - def_pct))

	NexusStats.recibir_ataque(dano_final)
	_parpadeo_dano()
	# 🎇 Juice: sacudida media cuando el Nexus encaja un golpe.
	FX.sacudir(0.30)

	var texto_dano = ESCENA_TEXTO.instantiate()
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
	# 🎇 Juice: sacudida fuerte + estallido al caer el Nexus.
	FX.impacto(global_position, Color(1.0, 0.3, 0.2), 28, 280.0)
	FX.sacudir(0.9)
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
	draw_circle(Vector2.ZERO, rango, Color(0.0, 0.85, 1.0, 0.05 * pulso))
	draw_arc(Vector2.ZERO, rango, 0.0, TAU, 72,
		Color(0.0, 0.85, 1.0, 0.55 * pulso), 2.5)

# ────────────────────────────────────────────────
# SISTEMA DE DISPAROS ESPECIALES
# ────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if esta_destruido: return

	# Solo si hay Commander activo
	if not Sistemadisparosespeciales.get_commander_activo(): return

	if event is InputEventMouseButton:
		if event.pressed:
			_iniciar_drag_especial(event.position)
		else:
			_finalizar_drag_especial()

	elif event is InputEventMouseMotion and disparando_especial:
		_actualizar_apuntado(event.position)

func _iniciar_drag_especial(posicion: Vector2) -> void:
	disparando_especial = true
	punto_inicio_drag = posicion

	var commanders = get_tree().get_nodes_in_group("commanders")
	if commanders.size() > 0:
		objetivo_especial = commanders[0]
		print("🎯 Apuntando a Commander")
	else:
		disparando_especial = false

func _actualizar_apuntado(_posicion_actual: Vector2) -> void:
	pass

func _finalizar_drag_especial() -> void:
	if not disparando_especial: return
	disparando_especial = false

	if not Sistemadisparosespeciales.hay_disparos_disponibles():
		print("❌ Sin disparos especiales")
		objetivo_especial = null
		return

	if objetivo_especial and is_instance_valid(objetivo_especial):
		_disparar_especial(objetivo_especial)

	objetivo_especial = null

func _disparar_especial(objetivo: Node2D) -> void:
	if esta_destruido or not objetivo or not is_instance_valid(objetivo): return
	if not escena_proyectil:
		print("❌ ERROR: escena_proyectil no asignada")
		return

	var proyectil = escena_proyectil.instantiate()
	get_tree().root.add_child(proyectil)
	proyectil.global_position = global_position
	proyectil.direccion = (objetivo.global_position - global_position).normalized()
	proyectil.rotation = proyectil.direccion.angle()
	proyectil.danio = NexusStats.get_danio()

	if proyectil.get("es_especial") != null:
		proyectil.es_especial = true

	print("💥 DISPARO ESPECIAL lanzado")

	Sistemadisparosespeciales.usar_disparo_especial()
