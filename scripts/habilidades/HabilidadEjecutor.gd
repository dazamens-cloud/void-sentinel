extends Node
# ═══════════════════════════════════════════════════
# HABILIDAD EJECUTOR — Efectos in-combat de la Forja
# Autoload. Lee parámetros de HabilidadManager, ejecuta efectos
# en la escena activa y gestiona cooldowns.
# ═══════════════════════════════════════════════════

signal cooldown_tick  # cada 0.25 s → refresca la barra de habilidades en Interfaz

const ESCENA_PROYECTIL := preload("res://escenas/proyectiles/Proyectil.tscn")
const ESCENA_EXPLOSION  := preload("res://escenas/Objetos/Explosion.tscn")

const NOMBRES_CORTOS := {
	"enjambre":       "ENJAMBRE",
	"singularidad":   "SINGUL.",
	"pulso_emp":      "P·EMP",
	"detonacion":     "CADENA",
	"escudo_colapso": "ESCUDO",
	"protocolo":      "PROTO.",
	"campo_tiempo":   "TIEMPO",
	"manto":          "MANTO",
}

# Cooldowns activos (id → segundos restantes)
var _cooldowns: Dictionary = {}

# ── Estado de efectos con duración ──────────────────
var manto_activo: bool = false  # Nexus.recibir_ataque() lo consulta

var _singularidad_activa: bool = false
var _singularidad_centro: Vector2 = Vector2.ZERO
var _singularidad_fuerza: float = 8.0
var _singularidad_timer: float = 0.0
var _singularidad_danio_impl: float = 0.0
var _singularidad_radio_exp: float = 80.0
var _singularidad_danio_exp: float = 0.0

func _ready() -> void:
	for id in HabilidadManager.habilidades.keys():
		_cooldowns[id] = 0.0
	var t := Timer.new()
	t.wait_time = 0.25
	t.autostart = true
	t.one_shot = false
	t.timeout.connect(func(): cooldown_tick.emit())
	add_child(t)
	# Resetear cooldowns y efectos activos al iniciar o reiniciar una partida
	if Economia.has_signal("juego_terminado"):
		Economia.juego_terminado.connect(_on_juego_terminado)

func _process(delta: float) -> void:
	for id in _cooldowns.keys():
		if _cooldowns[id] > 0.0:
			_cooldowns[id] = maxf(0.0, _cooldowns[id] - delta)

	if _singularidad_activa:
		_singularidad_timer -= delta
		_tick_singularidad(delta)
		if _singularidad_timer <= 0.0:
			_finalizar_singularidad()

func _on_juego_terminado(_causa: String) -> void:
	# Limpiar estado de efectos activos y resetear cooldowns para la próxima run
	_singularidad_activa = false
	manto_activo = false
	for id in _cooldowns.keys():
		_cooldowns[id] = 0.0

# ═══════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════
func get_cooldown_restante(id: String) -> float:
	return _cooldowns.get(id, 0.0)

func esta_lista(id: String) -> bool:
	return _cooldowns.get(id, 0.0) <= 0.0

func nombre_corto(id: String) -> String:
	return NOMBRES_CORTOS.get(id, id.to_upper())

func activar(id: String) -> bool:
	if not HabilidadManager.esta_activa(id): return false
	if not esta_lista(id): return false

	var ejecutado := false
	match id:
		"enjambre":        ejecutado = _activar_enjambre()
		"singularidad":    ejecutado = _activar_singularidad()
		"pulso_emp":       ejecutado = _activar_pulso_emp()
		"detonacion":      ejecutado = _activar_detonacion()
		"escudo_colapso":  ejecutado = _activar_escudo_colapso()
		"protocolo":       ejecutado = _activar_protocolo()
		"campo_tiempo":    ejecutado = _activar_campo_tiempo()
		"manto":           ejecutado = _activar_manto()

	if ejecutado:
		_cooldowns[id] = HabilidadManager.get_cooldown(id)
	return ejecutado

# ═══════════════════════════════════════════════════
# ENJAMBRE DE FRAGMENTOS
# Tormenta de proyectiles en todas las direcciones.
# ═══════════════════════════════════════════════════
func _activar_enjambre() -> bool:
	var nexus := _get_nexus()
	if not nexus: return false

	var n       := int(HabilidadManager.get_param("enjambre", "proyectiles"))
	var d_pct   := HabilidadManager.get_param("enjambre", "danio_pct")
	var vel     := HabilidadManager.get_param("enjambre", "velocidad")
	var pen     := int(HabilidadManager.get_param("enjambre", "penetracion"))
	var danio   := NexusStats.get_danio() * d_pct

	FX.impacto(nexus.global_position, Color(0.6, 0.9, 1.0), 20, 180.0)
	FX.sacudir(0.15)
	AudioManager.sfx("disparo")

	var mundo := _get_mundo()
	for i in range(n):
		var ang := (float(i) / float(n)) * TAU
		var dir := Vector2(cos(ang), sin(ang))
		var critico := randf() < NexusStats.get_critico_chance()
		var d_final := danio * NexusStats.get_critico_factor() if critico else danio

		var p := ESCENA_PROYECTIL.instantiate()
		mundo.add_child(p)
		p.global_position = nexus.global_position
		p.direccion = dir
		p.rotation = dir.angle()
		p.danio = d_final
		p.velocidad = vel
		p.es_critico = critico
		if "penetraciones_restantes" in p:
			p.penetraciones_restantes = pen
		var sprite := p.get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = Color(0.5, 0.9, 1.0)  # cian para distinguirlos
	return true

# ═══════════════════════════════════════════════════
# SINGULARIDAD
# Agujero negro que atrae enemigos; implosión final.
# ═══════════════════════════════════════════════════
func _activar_singularidad() -> bool:
	if _singularidad_activa: return false
	var nexus := _get_nexus()
	if not nexus: return false

	_singularidad_centro   = nexus.global_position
	_singularidad_fuerza   = HabilidadManager.get_param("singularidad", "fuerza")
	_singularidad_timer    = HabilidadManager.get_param("singularidad", "duracion")
	_singularidad_danio_impl = NexusStats.get_danio() * HabilidadManager.get_param("singularidad", "danio_implosion")
	_singularidad_radio_exp  = HabilidadManager.get_param("singularidad", "radio_explosion")
	_singularidad_danio_exp  = NexusStats.get_danio() * HabilidadManager.get_param("singularidad", "danio_explosion")
	_singularidad_activa = true

	FX.impacto(_singularidad_centro, Color(0.6, 0.1, 0.9), 30, 260.0)
	AudioManager.sfx("disparo")
	return true

func _tick_singularidad(delta: float) -> void:
	for e in get_tree().get_nodes_in_group("espectros"):
		if not is_instance_valid(e): continue
		var dir: Vector2 = _singularidad_centro - e.global_position
		if dir.length() > 0.01:
			e.global_position += dir.normalized() * _singularidad_fuerza * delta * 60.0

func _finalizar_singularidad() -> void:
	_singularidad_activa = false
	if not _get_nexus(): return  # Partida ya terminada
	var mundo := _get_mundo()
	for e in get_tree().get_nodes_in_group("espectros"):
		if not is_instance_valid(e): continue
		if e.has_method("recibir_dano"):
			e.recibir_dano(_singularidad_danio_impl)
	# Explosión final
	FX.impacto(_singularidad_centro, Color(1.0, 0.3, 1.0), 45, 340.0)
	FX.sacudir(0.45)
	var exp := ESCENA_EXPLOSION.instantiate()
	exp.global_position = _singularidad_centro
	mundo.add_child(exp)
	# Radio de explosión exterior
	for e in get_tree().get_nodes_in_group("espectros"):
		if not is_instance_valid(e): continue
		if e.global_position.distance_to(_singularidad_centro) <= _singularidad_radio_exp:
			if e.has_method("recibir_dano"):
				e.recibir_dano(_singularidad_danio_exp)

# ═══════════════════════════════════════════════════
# PULSO EMP
# AOE instantáneo; stun a blindados.
# ═══════════════════════════════════════════════════
func _activar_pulso_emp() -> bool:
	var nexus := _get_nexus()
	var d_pct  := HabilidadManager.get_param("pulso_emp", "danio_pct")
	var danio  := NexusStats.get_danio() * d_pct
	var stun   := HabilidadManager.get_param("pulso_emp", "stun_escudo")

	FX.impacto(nexus.global_position if nexus else Vector2(360, 640), Color(0.2, 0.8, 1.0), 35, 380.0)
	FX.sacudir(0.22)
	AudioManager.sfx("disparo")

	for e in get_tree().get_nodes_in_group("espectros"):
		if not is_instance_valid(e): continue
		if e.has_method("recibir_dano"):
			e.recibir_dano(danio)
		var tipo: String = e.get("tipo_espectro") if e.get("tipo_espectro") != null else ""
		if tipo in ["tanque", "jefe"] and e.has_method("aplicar_lentitud"):
			e.aplicar_lentitud(0.99, stun)  # 99% = stun efectivo
	return true

# ═══════════════════════════════════════════════════
# DETONACIÓN EN CADENA
# Explota al enemigo más cercano y encadena a los demás.
# ═══════════════════════════════════════════════════
func _activar_detonacion() -> bool:
	var nexus := _get_nexus()
	if not nexus: return false

	var objetivo: Node2D = null
	var dist_min: float = 999999.0
	for e in get_tree().get_nodes_in_group("espectros"):
		if not is_instance_valid(e): continue
		if e.get("tipo_espectro") == "commander": continue
		var d: float = nexus.global_position.distance_to(e.global_position)
		if d < dist_min:
			dist_min = d
			objetivo = e
	if not objetivo: return false

	var d_pct    := HabilidadManager.get_param("detonacion", "danio_pct")
	var radio    := HabilidadManager.get_param("detonacion", "radio")
	var saltos   := int(HabilidadManager.get_param("detonacion", "saltos"))
	var reduccion := HabilidadManager.get_param("detonacion", "reduccion")
	var danio    := NexusStats.get_danio() * d_pct

	AudioManager.sfx("disparo")
	_detonar_cadena(objetivo, danio, radio, saltos, reduccion, [objetivo])
	return true

func _detonar_cadena(objetivo: Node2D, danio: float, radio: float, saltos: int, reduccion: float, ya: Array) -> void:
	if not is_instance_valid(objetivo): return
	if not _get_nexus(): return  # Partida ya terminada (timer tardío)
	var pos := objetivo.global_position
	if objetivo.has_method("recibir_dano"):
		objetivo.recibir_dano(danio)
	var exp := ESCENA_EXPLOSION.instantiate()
	exp.global_position = pos
	_get_mundo().add_child(exp)
	FX.impacto(pos, Color(1.0, 0.6, 0.1), 14, radio * 0.8)

	if saltos <= 0: return
	var siguiente: Node2D = null
	var d_min := radio
	for e in get_tree().get_nodes_in_group("espectros"):
		if not is_instance_valid(e) or e in ya: continue
		if e.get("tipo_espectro") == "commander": continue
		var d := pos.distance_to(e.global_position)
		if d < d_min:
			d_min = d
			siguiente = e
	if siguiente:
		ya.append(siguiente)
		var d_siguiente := danio * (1.0 - reduccion)
		get_tree().create_timer(0.12).timeout.connect(
			func(): _detonar_cadena(siguiente, d_siguiente, radio, saltos - 1, reduccion, ya)
		)

# ═══════════════════════════════════════════════════
# ESCUDO DE COLAPSO
# Escudo temporal que absorbe daño durante unos segundos.
# ═══════════════════════════════════════════════════
func _activar_escudo_colapso() -> bool:
	var absorcion_pct := HabilidadManager.get_param("escudo_colapso", "absorcion_pct")
	var duracion      := HabilidadManager.get_param("escudo_colapso", "duracion")
	var escudo_val    := NexusStats.get_salud() * absorcion_pct

	NexusStats.escudo_actual += escudo_val
	var nexus := _get_nexus()
	FX.impacto(nexus.global_position if nexus else Vector2(360, 640), Color(0.3, 0.7, 1.0), 22, 190.0)

	get_tree().create_timer(duracion).timeout.connect(func():
		NexusStats.escudo_actual = maxf(0.0, NexusStats.escudo_actual - escudo_val)
	)
	return true

# ═══════════════════════════════════════════════════
# PROTOCOLO DE EMERGENCIA
# Cura instantánea del Nexus.
# ═══════════════════════════════════════════════════
func _activar_protocolo() -> bool:
	var curacion_pct := HabilidadManager.get_param("protocolo", "curacion_pct")
	var curacion     := NexusStats.get_salud() * curacion_pct

	var doble := HabilidadManager.tiene_feature("protocolo", "doble_pulso")
	NexusStats.curar(curacion * (2.0 if doble else 1.0))

	var nexus := _get_nexus()
	FX.impacto(nexus.global_position if nexus else Vector2(360, 640), Color(0.3, 1.0, 0.5), 18, 150.0)

	if HabilidadManager.tiene_feature("protocolo", "regen_pasiva"):
		# Boost temporal de regeneración durante 10 s
		NexusStats.mejora_regeneracion += 2.0
		get_tree().create_timer(10.0).timeout.connect(func():
			# maxf evita que quede negativo si reiniciar_partida() se llamó antes
			NexusStats.mejora_regeneracion = maxf(0.0, NexusStats.mejora_regeneracion - 2.0)
		)
	return true

# ═══════════════════════════════════════════════════
# CAMPO DE TIEMPO
# Ralentiza a todos los enemigos en pantalla.
# ═══════════════════════════════════════════════════
func _activar_campo_tiempo() -> bool:
	var slow_pct := HabilidadManager.get_param("campo_tiempo", "slow_pct")
	var duracion := HabilidadManager.get_param("campo_tiempo", "duracion")
	# slow_pct = fracción de velocidad restante → lentitud = 1 - slow_pct
	var lentitud := clampf(1.0 - slow_pct, 0.0, 0.99)

	var nexus := _get_nexus()
	FX.impacto(nexus.global_position if nexus else Vector2(360, 640), Color(0.5, 0.5, 1.0), 28, 320.0)

	for e in get_tree().get_nodes_in_group("espectros"):
		if not is_instance_valid(e): continue
		if e.has_method("aplicar_lentitud"):
			e.aplicar_lentitud(lentitud, duracion)
	return true

# ═══════════════════════════════════════════════════
# MANTO DE INTERFERENCIA
# Los ataques enemigos no penetran el Nexus mientras esté activo.
# Nexus.gd comprueba HabilidadEjecutor.manto_activo en recibir_ataque().
# ═══════════════════════════════════════════════════
func _activar_manto() -> bool:
	var duracion := HabilidadManager.get_param("manto", "duracion")
	manto_activo = true

	# Slow visual (enemigos confundidos)
	for e in get_tree().get_nodes_in_group("espectros"):
		if not is_instance_valid(e): continue
		if e.has_method("aplicar_lentitud"):
			e.aplicar_lentitud(0.70, duracion)

	var nexus := _get_nexus()
	FX.impacto(nexus.global_position if nexus else Vector2(360, 640), Color(0.8, 0.2, 0.9), 16, 210.0)

	get_tree().create_timer(duracion).timeout.connect(func(): manto_activo = false)
	return true

# ═══════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════
func _get_nexus() -> Node2D:
	return get_tree().get_first_node_in_group("nexus") as Node2D

func _get_mundo() -> Node:
	var s := get_tree().current_scene
	return s if s else get_tree().root
