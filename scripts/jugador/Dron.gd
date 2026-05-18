extends CharacterBody2D
# ═══════════════════════════════════════════════════════
# DRON — Nave recolectora de fragmentos
# ═══════════════════════════════════════════════════════

signal fragmentos_actualizados(actual: int, maximo: int)
signal depositando_progreso(pct: float)

@export var explosion_escena: PackedScene = preload("res://escenas/Objetos/Explosion.tscn")

const VELOCIDAD_NORMAL: float = 220.0
const VELOCIDAD_DEPOSITO: float = 350.0
const RADIO_CAMPO: float = 320.0
const DISTANCIA_LLEGADA: float = 35.0

const CAPACIDAD_BASE: int = 50
var capacidad_actual: int = CAPACIDAD_BASE
var fragmentos_en_dron: int = 0
var _juego_terminado_ya_emitido: bool = false

const VELOCIDAD_ATRACCION_BASE: float = 280.0

func get_radio_atraccion() -> float:
	return 140.0

enum Estado { VAGANDO, YENDO_NEXUS, EN_RECARGA }
var estado: Estado = Estado.VAGANDO

var _tiempo_recarga: float = 0.0
const TIEMPO_RECARGA: float = 3.0
var _destino_vago: Vector2 = Vector2.ZERO
var _timer_nuevo_destino: float = 0.0
var _nexus: Node2D = null

var barra_descarga: ProgressBar

@onready var sprite: Sprite2D = $Sprite2D

# ═══════════════════════════════════════════════════════
func _ready() -> void:
	print("🤖 Dron: Inicializando...")
	add_to_group("drones")
	
	barra_descarga = ProgressBar.new()
	barra_descarga.size = Vector2(50, 8)
	barra_descarga.position = Vector2(-25, -30)
	barra_descarga.max_value = 1.0
	barra_descarga.value = 0.0
	barra_descarga.visible = false
	add_child(barra_descarga)
	
	await get_tree().process_frame
	_nexus = get_tree().current_scene.find_child("Nexus", true, false)
	if _nexus:
		print("🤖 Dron: Nexus encontrado")
	else:
		print("🤖 Dron: ERROR - Nexus no encontrado")
	
	_actualizar_capacidad()
	Economia.ascension_cambiada.connect(_on_ascension_cambiada)
	Economia.juego_terminado.connect(_on_juego_terminado)
	fragmentos_actualizados.emit(fragmentos_en_dron, capacidad_actual)
	depositando_progreso.connect(_actualizar_barra_descarga)

# ═══════════════════════════════════════════════════════
func _physics_process(delta: float) -> void:
	match estado:
		Estado.VAGANDO:
			_tick_vagando(delta)
			_buscar_y_atraer_fragmentos(delta)
		Estado.YENDO_NEXUS:
			_tick_yendo_nexus(delta)
		Estado.EN_RECARGA:
			_tick_recarga(delta)

# ═══════════════════════════════════════════════════════
func _buscar_y_atraer_fragmentos(delta: float) -> void:
	if fragmentos_en_dron >= capacidad_actual:
		return
	
	var fragmento_mas_cercano = null
	var dist_min = INF
	
	for frag in get_tree().get_nodes_in_group("fragmentos"):
		if not is_instance_valid(frag):
			continue
		var d = global_position.distance_to(frag.global_position)
		if d < dist_min:
			dist_min = d
			fragmento_mas_cercano = frag
	
	if fragmento_mas_cercano and dist_min < 250:
		var direccion = (fragmento_mas_cercano.global_position - global_position).normalized()
		velocity = velocity.lerp(direccion * VELOCIDAD_NORMAL, 3.0 * delta)
		rotation = lerp_angle(rotation, direccion.angle(), 6.0 * delta)
		move_and_slide()
		_atraer_fragmentos_cercanos(delta)
	else:
		_tick_vagando(delta)
		_atraer_fragmentos_cercanos(delta)

func _atraer_fragmentos_cercanos(delta: float) -> void:
	var radio_actual: float = get_radio_atraccion()
	var fragmentos: Array = get_tree().get_nodes_in_group("fragmentos")

	for frag in fragmentos:
		if not is_instance_valid(frag):
			continue
		var distancia: float = global_position.distance_to(frag.global_position)
		if distancia < radio_actual:
			var direccion: Vector2 = (global_position - frag.global_position).normalized()
			var multiplicador: float = clamp(1.0 - (distancia / radio_actual), 0.2, 1.0)
			var velocidad_succion: float = VELOCIDAD_ATRACCION_BASE * (1.0 + multiplicador * 2.0)
			frag.global_position += direccion * velocidad_succion * delta
			if distancia < 25.0:
				_recoger_fragmento(frag)

func _recoger_fragmento(frag: Node) -> void:
	fragmentos_en_dron += 1
	frag.queue_free()
	print("🤖 Dron: Fragmento recogido. Total: ", fragmentos_en_dron, "/", capacidad_actual)

	if explosion_escena:
		var exp: Node = explosion_escena.instantiate()
		exp.global_position = global_position
		exp.scale = Vector2(0.3, 0.3)
		exp.self_modulate = Color(0.5, 1.0, 0.5)
		get_tree().current_scene.add_child(exp)

	fragmentos_actualizados.emit(fragmentos_en_dron, capacidad_actual)

	if fragmentos_en_dron >= capacidad_actual:
		print("🤖 Dron: ¡Capacidad máxima alcanzada! Activando láser 360°")
		_activar_laser_360()
		estado = Estado.YENDO_NEXUS

# ═══════════════════════════════════════════════════════
func _activar_laser_360() -> void:
	print("🤖 Dron: ACTIVANDO LÁSER 360°")
	var danio: int = int(Economia.get_danio() * 5.0)

	if _nexus:
		var poligono = Polygon2D.new()
		poligono.color = Color(1.0, 0.2, 0.2, 0.5)
		poligono.z_index = 100
		var puntos: PackedVector2Array = []
		for i in range(24):
			var ang = (float(i) / 24.0) * TAU
			puntos.append(Vector2(cos(ang), sin(ang)) * 50.0)
		poligono.polygon = puntos
		get_tree().current_scene.add_child(poligono)
		poligono.global_position = _nexus.global_position

		var tween = create_tween()
		tween.tween_property(poligono, "scale", Vector2(8.0, 8.0), 0.4)
		tween.tween_property(poligono, "color", Color(1.0, 0.0, 0.0, 0.0), 0.1)
		tween.tween_callback(poligono.queue_free)
	
	# Daño a espectros
	for espectro in get_tree().get_nodes_in_group("espectros"):
		if is_instance_valid(espectro) and espectro.has_method("recibir_dano"):
			espectro.recibir_dano(danio, true)
	
	_sacudir_camara(12.0)

# ═══════════════════════════════════════════════════════
func _tick_vagando(delta: float) -> void:
	_timer_nuevo_destino -= delta
	if _timer_nuevo_destino <= 0.0 or global_position.distance_to(_destino_vago) < DISTANCIA_LLEGADA:
		_elegir_destino_vago()
	var direccion: Vector2 = (_destino_vago - global_position).normalized()
	velocity = velocity.lerp(direccion * VELOCIDAD_NORMAL, 5.0 * delta)
	rotation = lerp_angle(rotation, direccion.angle(), 6.0 * delta)
	move_and_slide()

func _tick_yendo_nexus(delta: float) -> void:
	if not _nexus:
		return
	var direccion: Vector2 = (_nexus.global_position - global_position).normalized()
	velocity = velocity.lerp(direccion * VELOCIDAD_DEPOSITO, 8.0 * delta)
	rotation = lerp_angle(rotation, direccion.angle(), 10.0 * delta)
	move_and_slide()
	var distancia: float = global_position.distance_to(_nexus.global_position)
	depositando_progreso.emit(1.0 - clamp(distancia / 400.0, 0.0, 1.0))
	if distancia < DISTANCIA_LLEGADA:
		_depositar()

func _tick_recarga(delta: float) -> void:
	velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
	_tiempo_recarga -= delta
	depositando_progreso.emit(max(0.0, _tiempo_recarga / TIEMPO_RECARGA))
	if _tiempo_recarga <= 0.0:
		print("🤖 Dron: Recarga completada, volviendo a vagar")
		estado = Estado.VAGANDO
		depositando_progreso.emit(0.0)

func _depositar() -> void:
	var ganancia: int = fragmentos_en_dron * 10
	Economia.añadir_energia(ganancia)
	print("🤖 Dron: DEPOSITANDO ", fragmentos_en_dron, " fragmentos → +", ganancia, " ⚡")
	fragmentos_en_dron = 0
	_tiempo_recarga = TIEMPO_RECARGA
	estado = Estado.EN_RECARGA
	fragmentos_actualizados.emit(0, capacidad_actual)
	depositando_progreso.emit(1.0)

# ═══════════════════════════════════════════════════════
func _on_ascension_cambiada(_n: int) -> void:
	_actualizar_capacidad()

func _elegir_destino_vago() -> void:
	var centro: Vector2 = _nexus.global_position if _nexus else Vector2(360, 450)
	var angulo: float = randf() * TAU
	var radio: float = randf_range(80.0, RADIO_CAMPO)
	_destino_vago = centro + Vector2(cos(angulo), sin(angulo)) * radio
	_timer_nuevo_destino = 2.5

func _actualizar_capacidad() -> void:
	capacidad_actual = CAPACIDAD_BASE + (Economia.numero_ascension / 3)
	fragmentos_actualizados.emit(fragmentos_en_dron, capacidad_actual)
	print("🤖 Dron: Capacidad actualizada a ", capacidad_actual)

func _sacudir_camara(fuerza: float) -> void:
	var camara: Node = get_tree().current_scene.find_child("CamaraJuego", true, false)
	if camara and camara.has_method("sacudir"):
		camara.sacudir(fuerza)

func _actualizar_barra_descarga(pct: float) -> void:
	if barra_descarga:
		barra_descarga.value = pct
		barra_descarga.visible = pct > 0

# ✅ Game Over: explosión lenta
func _on_juego_terminado(_causa: String) -> void:
	if _juego_terminado_ya_emitido:
		return
	_juego_terminado_ya_emitido = true
	print("🤖 Dron: JUEGO TERMINADO - Explosión lenta")
	estado = Estado.EN_RECARGA
	set_physics_process(false)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 1.0)
	tween.parallel().tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2, 0.0), 1.0)
	tween.tween_callback(queue_free)

# ✅ Explosión lenta (pública para llamar desde fuera)
func explosion_lenta() -> void:
	_on_juego_terminado("")
	
