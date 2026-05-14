# res://scripts/utils/GestorOleadas.gd
# Controla oleadas, spawn y transiciones.

extends Node

@export var escena_enemigo: PackedScene

var enemigos_vivos: int = 0
var enemigos_a_spawnear: int = 0
var timer_spawn: float = 0.0
var timer_pausa: float = 5.0
var en_combate: bool = false

const INTERVALO_SPAWN: float = 1.5
const BASE_ENEMIGOS: int = 3

func _process(delta: float) -> void:
	if not en_combate:
		timer_pausa -= delta
		if timer_pausa <= 0.0: _iniciar_oleada()
	else:
		timer_spawn -= delta
		if timer_spawn <= 0.0 and enemigos_a_spawnear > 0:
			_spawn_enemigo()
			timer_spawn = INTERVALO_SPAWN

func _iniciar_oleada() -> void:
	en_combate = true
	Economia.avanzar_oleada()
	enemigos_a_spawnear = BASE_ENEMIGOS + Economia.numero_oleada
	timer_spawn = 0.0

func _spawn_enemigo() -> void:
	if not escena_enemigo: 
		print("ERROR: escena_enemigo no asignada en GestorOleadas")
		return
	
	var e = escena_enemigo.instantiate()
	
	# Verificar que el enemigo tenga el script antes de añadirlo
	if not e.has_method("configurar"):
		print("ERROR: El enemigo no tiene el método configurar. Revisa el script EnemigoBasico.gd")
		e.queue_free()
		return
	
	get_tree().root.add_child(e)
	
	# ✅ Obtener tamaño de viewport de forma segura
	var viewport = get_viewport()
	if not viewport:
		viewport = Engine.get_main_loop().root
	var vp_size = viewport.get_visible_rect().size
	
	var lado = randi() % 4
	match lado:
		0: e.global_position = Vector2(randf_range(0, vp_size.x), -50)
		1: e.global_position = Vector2(randf_range(0, vp_size.x), vp_size.y + 50)
		2: e.global_position = Vector2(-50, randf_range(0, vp_size.y))
		3: e.global_position = Vector2(vp_size.x + 50, randf_range(0, vp_size.y))
	
	var oleada = Economia.numero_oleada
	e.configurar({
		"hp": 10.0 + (oleada * 2.0),
		"spd_px": 70.0 + (oleada * 3.0),
		"atk": 2.0 + (oleada * 0.5),
		"recompensa": 5 + oleada,
		"tipo": "basico"
	})
	e.enemigo_muerto.connect(_on_enemigo_muerto)
	enemigos_a_spawnear -= 1
	enemigos_vivos += 1

func _on_enemigo_muerto(_pos: Vector2) -> void:
	enemigos_vivos -= 1
	if enemigos_a_spawnear == 0 and enemigos_vivos <= 0:
		en_combate = false
		timer_pausa = 5.0
