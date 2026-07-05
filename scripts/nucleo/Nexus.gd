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
		push_error("❌ ERROR: TimerAutoDisparo no encontrado en Nexus")
		return

	timer_disparo.timeout.connect(_disparar)
	NexusStats.stats_actualizadas.connect(_on_stats_actualizadas)
	timer_disparo.wait_time = NexusStats.get_cadencia_timer()
	timer_disparo.start()


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
		push_error("❌ ERROR: escena_proyectil no asignada en Nexus")
		return

	var espectros = get_tree().get_nodes_in_group("espectros")
	if espectros.size() == 0: return

	# Recoge los espectros en rango (excluye Commanders) con su distancia.
	var rango := NexusStats.get_rango_escaneo()
	var candidatos: Array = []
	for e in espectros:
		if not is_instance_valid(e): continue
		if e.get("tipo_espectro") == "commander": continue
		var d: float = global_position.distance_to(e.global_position)
		if d <= rango:
			candidatos.append({"e": e, "d": d})

	if candidatos.is_empty(): return

	# Más cercanos primero.
	candidatos.sort_custom(func(a, b): return a["d"] < b["d"])

	# ✅ Multidisparo = nº de OBJETIVOS distintos atacados a la vez (el más
	# cercano + uno extra por nivel), no proyectiles al mismo enemigo.
	var num_objetivos: int = min(1 + NexusStats.get_multidisparo(), candidatos.size())

	AudioManager.sfx("disparo")
	var danio: float = NexusStats.get_danio()
	for i in range(num_objetivos):
		var objetivo: Node2D = candidatos[i]["e"]
		# Crítico se tira por cada objetivo (cada proyectil su tirada).
		var critico := randf() < NexusStats.get_critico_chance()
		var danio_obj := danio * NexusStats.get_critico_factor() if critico else danio
		var dir: Vector2 = (objetivo.global_position - global_position).normalized()
		_crear_proyectil(dir, danio_obj, critico)

func _crear_proyectil(direccion: Vector2, danio_val: float, critico: bool) -> void:
	var proyectil = escena_proyectil.instantiate()
	# Hijo de la escena del mundo (no de root) para que se libere al salir.
	var padre := get_tree().current_scene
	if padre == null:
		padre = get_tree().root
	padre.add_child(proyectil)
	proyectil.global_position = global_position
	proyectil.direccion = direccion
	proyectil.rotation = direccion.angle()
	proyectil.danio = danio_val
	proyectil.es_critico = critico
	# ✅ Rebote (si la mejora está activa y el proyectil lo soporta)
	if proyectil.get("rebotes_restantes") != null:
		proyectil.rebotes_restantes = NexusStats.get_rebote_cantidad()
		proyectil.alcance_rebote = NexusStats.get_rebote_alcance()

var _ultimo_atacante: String = ""

func recibir_ataque(cantidad: float, tipo_atacante: String = "") -> void:
	if esta_destruido: return
	if HabilidadEjecutor.manto_activo: return  # Manto: ataques ignorados

	if tipo_atacante != "":
		_ultimo_atacante = tipo_atacante

	var dano_final = cantidad
	var def_pct = NexusStats.get_defensa()
	if def_pct > 0.0:
		dano_final = max(1.0, cantidad * (1.0 - def_pct))

	NexusStats.recibir_ataque(dano_final)
	_parpadeo_dano()
	# 🎇 Juice: sacudida media + sonido cuando el Nexus encaja un golpe.
	FX.sacudir(0.30)
	AudioManager.sfx("dano_nexus")

	var texto_dano = ESCENA_TEXTO.instantiate()
	texto_dano.set_valor(dano_final, "dano")
	texto_dano.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	texto_dano.global_position = global_position
	get_tree().current_scene.add_child(texto_dano)

	if NexusStats.salud_actual <= 0.0:
		_destruir()

func _destruir() -> void:
	if esta_destruido: return
	esta_destruido = true
	timer_disparo.stop()
	sprite.modulate = Color(0.2, 0.2, 0.2)
	# 🎇 Juice: sacudida fuerte + estallido + sonido al caer el Nexus.
	FX.impacto(global_position, Color(1.0, 0.3, 0.2), 28, 280.0)
	FX.sacudir(0.9)
	AudioManager.sfx("game_over", false)
	# Pasa el tipo del último enemigo que golpeó para el mensaje de Game Over.
	var causa := _ultimo_atacante if _ultimo_atacante != "" else "Nexus Destruido"
	Economia.juego_terminado.emit(causa)

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
	else:
		disparando_especial = false

func _actualizar_apuntado(_posicion_actual: Vector2) -> void:
	pass

func _finalizar_drag_especial() -> void:
	if not disparando_especial: return
	disparando_especial = false

	if not Sistemadisparosespeciales.hay_disparos_disponibles():
		objetivo_especial = null
		return

	if objetivo_especial and is_instance_valid(objetivo_especial):
		_disparar_especial(objetivo_especial)

	objetivo_especial = null

func _disparar_especial(objetivo: Node2D) -> void:
	if esta_destruido or not objetivo or not is_instance_valid(objetivo): return
	if not escena_proyectil:
		push_error("❌ ERROR: escena_proyectil no asignada")
		return

	var proyectil = escena_proyectil.instantiate()
	var padre := get_tree().current_scene
	if padre == null:
		padre = get_tree().root
	padre.add_child(proyectil)
	proyectil.global_position = global_position
	proyectil.direccion = (objetivo.global_position - global_position).normalized()
	proyectil.rotation = proyectil.direccion.angle()
	proyectil.danio = NexusStats.get_danio()

	if proyectil.get("es_especial") != null:
		proyectil.es_especial = true


	Sistemadisparosespeciales.usar_disparo_especial()
