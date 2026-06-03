extends Node
# ═══════════════════════════════════════════════════
# FX — Juice central de Void Sentinel (autoload).
#
# Dos responsabilidades:
#   1. SCREEN SHAKE basado en "trauma": cada golpe suma trauma (0..1) y el
#      sacudido = trauma². Así los impactos pequeños apenas se notan y los
#      grandes pegan fuerte, decayendo suave. Se aplica como offset+roll
#      sobre la cámara activa (que mundo.gd registra al entrar a partida).
#   2. PARTÍCULAS por código (burst one-shot) para impactos/muertes, sin
#      depender de escenas .tscn.
#
# process_mode = ALWAYS para que la sacudida de muerte del Nexus se vea
# aunque el árbol se pause en el game over.
# ═══════════════════════════════════════════════════

# ── Tuning del shake ──────────────────────────────
const MAX_OFFSET: float = 14.0   # px de desplazamiento con trauma máximo
const MAX_ROLL: float = 0.06     # rad de rotación con trauma máximo
const DECAY: float = 1.6         # cuánto trauma se pierde por segundo

var _camara: Camera2D = null
var _trauma: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# mundo.gd llama esto al configurar la cámara de la partida.
func registrar_camara(cam: Camera2D) -> void:
	_camara = cam
	_trauma = 0.0
	if is_instance_valid(_camara):
		_camara.offset = Vector2.ZERO
		_camara.rotation = 0.0


# Suma trauma (clamp a 1.0). Llamar en cada golpe que merezca sacudida.
func sacudir(trauma: float) -> void:
	_trauma = minf(1.0, _trauma + trauma)


func _process(delta: float) -> void:
	if not is_instance_valid(_camara):
		return
	if _trauma <= 0.0:
		# Asegura que la cámara quede limpia al terminar la sacudida.
		if _camara.offset != Vector2.ZERO or _camara.rotation != 0.0:
			_camara.offset = Vector2.ZERO
			_camara.rotation = 0.0
		return

	var shake := _trauma * _trauma
	_camara.offset = Vector2(
		randf_range(-1.0, 1.0) * MAX_OFFSET * shake,
		randf_range(-1.0, 1.0) * MAX_OFFSET * shake
	)
	_camara.rotation = randf_range(-1.0, 1.0) * MAX_ROLL * shake
	_trauma = maxf(0.0, _trauma - DECAY * delta)


# ── Partículas de impacto/muerte (burst one-shot, auto-libera) ──
func impacto(pos: Vector2, color: Color = Color(1.0, 0.85, 0.3), cantidad: int = 10, fuerza: float = 140.0) -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return

	var p := CPUParticles2D.new()
	p.global_position = pos
	p.z_index = 50
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = cantidad
	p.lifetime = 0.45
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = fuerza * 0.4
	p.initial_velocity_max = fuerza
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = color
	# Se desvanece y encoge a lo largo de la vida.
	p.scale_amount_curve = _curva_fade()
	tree.current_scene.add_child(p)

	# Auto-liberación tras la vida + margen.
	var t := tree.create_timer(p.lifetime + 0.2)
	t.timeout.connect(p.queue_free)


func _curva_fade() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(1.0, 0.0))
	return c
