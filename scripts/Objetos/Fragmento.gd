extends Area2D
# ═══════════════════════════════════════════════════════
# FRAGMENTO — Recolectable que dejan los espectros
# (antes "fragmentos.gd")
# ═══════════════════════════════════════════════════════

# ── VALOR DEL FRAGMENTO ─────────────────────────────────
var valor: int = 5

# ── MOVIMIENTO Y ANIMACIÓN ─────────────────────────────
var velocidad_flotacion: float = 2.0
var amplitud_flotacion: float = 3.0
var tiempo: float = 0.0
var direccion: Vector2 = Vector2.ZERO
var velocidad_movimiento: float = 40.0

# ── DURACIÓN ───────────────────────────────────────────
var tiempo_vida: float = 8.0
var tiempo_transcurrido: float = 0.0

# ── POSICIÓN BASE (para flotación correcta) ────────────
var _posicion_base_y: float = 0.0

# ═══════════════════════════════════════════════════════
# READY
# ═══════════════════════════════════════════════════════
func _ready() -> void:
	add_to_group("fragmentos")
	
	# Guardar Y base para que la flotación oscile sobre este punto
	_posicion_base_y = position.y

	# Dirección aleatoria de deriva
	direccion = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()

# ═══════════════════════════════════════════════════════
# PROCESS
# ═══════════════════════════════════════════════════════
func _process(delta: float) -> void:
	tiempo += delta
	tiempo_transcurrido += delta

	# Flotación: oscila alrededor de _posicion_base_y
	position.y = _posicion_base_y + sin(tiempo * velocidad_flotacion) * amplitud_flotacion

	# Deriva suave
	position += direccion * velocidad_movimiento * delta

	# Rotación sutil
	rotation += 1.5 * delta

	# Auto-destrucción
	if tiempo_transcurrido >= tiempo_vida:
		queue_free()

# ═══════════════════════════════════════════════════════
# COLISIÓN (backup — la recolección principal ocurre
# por proximidad en Recolector.gd)
# ═══════════════════════════════════════════════════════
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("recolector"):
		if area.has_method("_recoger_fragmento"):
			area._recoger_fragmento(self)
		else:
			queue_free()
