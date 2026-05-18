extends Area2D
# ═══════════════════════════════════════════════════════
# FRAGMENTO — Recolectable que dejan los espectros
# ═══════════════════════════════════════════════════════

var valor: int = 5
var tiempo_vida: float = 8.0
var tiempo_transcurrido: float = 0.0

# ── Movimiento y animación ─────────────────────────────
var velocidad_flotacion: float = 2.0
var amplitud_flotacion: float = 3.0
var tiempo: float = 0.0
var direccion_deriva: Vector2 = Vector2.ZERO
var velocidad_deriva: float = 40.0

var _posicion_base_y: float = 0.0

# ═══════════════════════════════════════════════════════
func _ready() -> void:
	add_to_group("fragmentos")
	
	# Guardar Y base para flotación
	_posicion_base_y = position.y
	
	# Dirección aleatoria de deriva
	direccion_deriva = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()

# ═══════════════════════════════════════════════════════
func _process(delta: float) -> void:
	tiempo += delta
	tiempo_transcurrido += delta

	# Flotación suave (arriba y abajo)
	position.y = _posicion_base_y + sin(tiempo * velocidad_flotacion) * amplitud_flotacion

	# Deriva horizontal suave
	position += direccion_deriva * velocidad_deriva * delta

	# Rotación sutil
	rotation += 1.5 * delta

	# Auto-destrucción
	if tiempo_transcurrido >= tiempo_vida:
		queue_free()
	
	# Limitar área (opcional)
	var viewport = get_viewport_rect().size
	position.x = clamp(position.x, -100, viewport.x + 100)
	position.y = clamp(position.y, -100, viewport.y + 100)
	

# ═══════════════════════════════════════════════════════
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("drones"):
		if area.has_method("_recoger_fragmento"):
			area._recoger_fragmento(self)
		else:
			queue_free()
